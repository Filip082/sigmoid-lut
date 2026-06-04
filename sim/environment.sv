`ifndef ENVIRONMENT__SV
`define ENVIRONMENT__SV

`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "coverage.sv"
`include "scoreboard.sv"

class Scb_Driver_cbs extends Driver_cbs;
  Scoreboard scb;

  function new(Scoreboard scb);
    this.scb = scb;
  endfunction

  virtual task pre_trans(input sigmoid_driver drv, input sigmoid transaction);
    scb.save_expected(transaction);
  endtask
endclass

class Scb_Monitor_cbs extends Monitor_cbs;
  Scoreboard scb;

  function new(Scoreboard scb);
    this.scb = scb;
  endfunction

  virtual task post_trans(input sigmoid_monitor mon, input sigmoid transaction);
    scb.check_actual(transaction);
  endtask
endclass

class Environment;
  sigmoid_generator gen;
  mailbox #(sigmoid) gen2drv;
  event drv2gen;
  sigmoid_driver drv;
  sigmoid_monitor mon;
  sigmoid_coverage cov;
  Scoreboard scb;
  int num_transactions;

  virtual fixed_point_if dut_in;
  virtual fixed_point_if dut_out;

  extern function new(
        virtual fixed_point_if dut_in,
        virtual fixed_point_if dut_out,
        int num_transactions
      );
  extern virtual function void build();
  extern virtual task run();
  extern virtual function void wrap_up();

endclass : Environment

function Environment::new(
  virtual fixed_point_if dut_in,
  virtual fixed_point_if dut_out,
  int num_transactions
);
  this.dut_in = dut_in;
  this.dut_out = dut_out;
  this.num_transactions = num_transactions;
endfunction

function void Environment::build();
  gen2drv = new(1);
  gen = new(gen2drv, drv2gen, num_transactions);
  drv = new(dut_in.driver, gen2drv, drv2gen);
  mon = new(dut_in.monitor, dut_out.monitor);
  cov = new();
  scb = new();
  begin
    automatic Scb_Driver_cbs sdc = new(scb);
    automatic Scb_Monitor_cbs smc = new(scb);
    automatic Cov_Monitor_cbs cmc = new(cov);
    drv.cbsq.push_back(sdc);
    mon.cbsq.push_back(smc);
    mon.cbsq.push_back(cmc);
  end
endfunction

task Environment::run();
  fork
    gen.run();
    drv.run();
    mon.run();
  join_none

  fork : timeout_block
    wait (gen.transaction_count == 0);
    begin
      repeat (1_000) @(dut_out.cbm);
      $display("@%0t: %m ERROR: Timeout while waiting for generator to finish", $time);
    end
  join_any
  disable timeout_block;

  repeat (5) @(dut_out.cbm);
endtask

function void Environment::wrap_up();
  scb.wrap_up();
  cov.report();
endfunction

`endif // ENVIRONMENT__SV
