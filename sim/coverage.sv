`ifndef COVERAGE__SV
 `define COVERAGE__SV

`include "monitor.sv"

class sigmoid_coverage;
  bit [15:0] x_in;
  covergroup cg;
    addr_cp: coverpoint (x_in[15:8] ^ 8'h80) {
      bins entry[] = {[0:255]};
    }

    region_cp: coverpoint (x_in[15:8] ^ 8'h80) {
      bins tails  = {[0:63], [192:255]};
      bins normal = {[64:95], [160:191]};
      bins center   = {[96:159]};
    }
  endgroup

  function new();
    cg = new();
  endfunction

  function void sample_trans(sigmoid trans);
    this.x_in = trans.x_in;
    cg.sample();
  endfunction

  function void report();
    $display("@%0t: Coverage summary: addr=%.2f%%, region=%.2f%%, total=%.2f%%",
             $time,
             cg.addr_cp.get_coverage(),
             cg.region_cp.get_coverage(),
             cg.get_coverage());
  endfunction

endclass : sigmoid_coverage


class Cov_Monitor_cbs extends Monitor_cbs;
  sigmoid_coverage cov;

  function new(sigmoid_coverage cov);
    this.cov = cov;
  endfunction

  virtual task post_trans(input sigmoid_monitor mon, input sigmoid transaction);
    cov.sample_trans(transaction);
  endtask
endclass : Cov_Monitor_cbs

`endif // COVERAGE__SV
