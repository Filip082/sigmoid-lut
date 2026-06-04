`ifndef GENERATOR__SV
 `define GENERATOR__SV

`include "sigmoid.sv"

class sigmoid_generator;
  sigmoid blueprint;
  mailbox #(sigmoid) gen2drv;
  event drv2gen;
  int transaction_count;

  extern function new(mailbox #(sigmoid) mbox, event ev, int count);
  extern task run();
endclass : sigmoid_generator

function sigmoid_generator::new(mailbox #(sigmoid) mbox, event ev, int count);
  this.gen2drv = mbox;
  this.drv2gen = ev;
  this.transaction_count = count;
  blueprint = new();
endfunction

task sigmoid_generator::run();
  sigmoid transaction;
  
  repeat(transaction_count) begin
    assert(blueprint.randomize());
    $cast(transaction, blueprint.copy());
    gen2drv.put(transaction);
    transaction_count--;
    @drv2gen;
  end
endtask : run

`endif // GENERATOR__SV
