program automatic test (
    input logic clk,
    input logic rst,
    fixed_point_if dut_in,
    fixed_point_if dut_out
  );

  `include "environment.sv"
  Environment env;

  initial begin
    $display("Simulation start!");
  end

  initial begin
    $display("Running edge case sigmoid tests...\n");
    env = new(dut_in, dut_out, 5);
    env.build();
    begin
      edge_case_sigmoid blueprint = new();
      env.gen.blueprint = blueprint;
    end
    env.run();
    env.wrap_up();

    $display("\n\nRunning discrete sigmoid tests...\n");
    env = new(dut_in, dut_out, 5);
    env.build();
    begin
      discrete_sigmoid blueprint = new();
      env.gen.blueprint = blueprint;
    end
    env.run();
    env.wrap_up();

    $display("\n\nRunning general sigmoid tests with tolerance 0.02...\n");
    env = new(dut_in, dut_out, 100);
    env.build();
    begin
      env.scb.checker_tolerance = 0.02;
    end
    env.run();
    env.wrap_up();

    $display("@%0t: End of simulation", $time);
  end
endprogram : test
