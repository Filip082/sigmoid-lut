`ifndef DRIVER__SV
 `define DRIVER__SV

 `include "sigmoid.sv"

typedef class sigmoid_driver;

virtual class Driver_cbs;
  pure virtual task pre_trans(input sigmoid_driver drv, input sigmoid transaction);
endclass

class sigmoid_driver;
  virtual fixed_point_if vif;
  mailbox #(sigmoid) gen2drv;
  event drv2gen;
  Driver_cbs cbsq[$];

  extern function new(virtual fixed_point_if.driver vif, mailbox #(sigmoid) mbox, event drv2gen);
  extern task run();
endclass

function sigmoid_driver::new(virtual fixed_point_if.driver vif, mailbox #(sigmoid) mbox, event drv2gen);
  this.vif = vif;
  this.gen2drv = mbox;
  this.drv2gen = drv2gen;
endfunction

task sigmoid_driver::run();
  sigmoid transaction;

  vif.val <= 0;

  forever begin
    gen2drv.peek(transaction);

    @(vif.cbd);
    foreach (cbsq[i])
      cbsq[i].pre_trans(this, transaction);

    vif.val <= transaction.x_in;

    gen2drv.get(transaction);
    ->drv2gen;
  end
endtask

`endif // DRIVER__SV
