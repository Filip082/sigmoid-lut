`ifndef TDC_MONITOR__SV
 `define TDC_MONITOR__SV

`include "sigmoid.sv"

typedef class sigmoid_monitor;

class Monitor_cbs;
   virtual task post_trans(input sigmoid_monitor mon,
		        input sigmoid transaction);
   endtask : post_trans
endclass : Monitor_cbs

class sigmoid_monitor;
  virtual fixed_point_if x_in_if;
  virtual fixed_point_if y_out_if;
  Monitor_cbs cbsq[$];

  localparam L = 1;

  extern function new(virtual fixed_point_if.monitor x_in_if, virtual fixed_point_if.monitor y_out_if);
  extern task run();
endclass : sigmoid_monitor

function sigmoid_monitor::new(virtual fixed_point_if.monitor x_in_if, virtual fixed_point_if.monitor y_out_if);
  this.x_in_if = x_in_if;
  this.y_out_if = y_out_if;
endfunction

task sigmoid_monitor::run();
  sigmoid trans;

  repeat (L) @(x_in_if.cbm);
  forever begin
    trans = new();

    trans.x_in = x_in_if.val;
    @(x_in_if.cbm);
    trans.y_out = y_out_if.val;

    foreach (cbsq[i])
      cbsq[i].post_trans(this, trans);
  end
endtask : run
`endif // TDC_MONITOR__SV
