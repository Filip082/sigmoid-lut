module top;
  // timeunit 1ns;
  // timeprecision 1ps;

  logic rst, clk;

  initial begin
    rst = 0; clk = 0;
    #5 rst = 1;
    #5 clk = 1;
    #5 rst = 0; clk = 0;
    forever 
      #5 clk = ~clk;
  end

  fixed_point_if dut_in(clk);
  fixed_point_if dut_out_uniform(clk);
  fixed_point_if dut_out_opt(clk);

  sigmoid_lut           dut0 (.clk, .rst_n(~rst), .x_in(dut_in.val), .y_out(dut_out_uniform.val));
  sigmoid_lut_optimized dut1 (.clk, .rst_n(~rst), .x_in(dut_in.val), .y_out(dut_out_opt.val));

  test t1 (clk, rst, dut_in, dut_out_uniform, dut_out_opt);
endmodule : top
