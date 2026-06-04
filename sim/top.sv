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
  fixed_point_if dut_out(clk);

  sigmoid_lut dut (
    .clk(clk),
    .rst_n(~rst),
    .x_in(dut_in.val),
    .y_out(dut_out.val)
  );

  test t1(clk, rst, dut_in, dut_out);
endmodule : top
