program automatic test (
    input logic clk,
    input logic rst,
    fixed_point_if duts_in,
    fixed_point_if dut_out_uniform,
    fixed_point_if dut_out_opt
  );

  `include "environment.sv"
  Environment env;

  task automatic run_phase(virtual fixed_point_if dut_in,
                           virtual fixed_point_if dut_out,
                           sigmoid blueprint,
                           real tolerance,
                           int num_tests,
                           string test_name
                           );
    $display("Running [%s] tests...\n", test_name);
    env = new(dut_in, dut_out, num_tests);
    env.build();
    begin
      env.gen.blueprint = blueprint;
      env.scb.checker_tolerance = tolerance;
    end
    env.run();
    $display("Test [%s] completed with result:", test_name);
    env.wrap_up();
  endtask

  // Blueprints
  discrete_sigmoid discrete_blueprint;
  edge_case_sigmoid edge_case_blueprint;
  sigmoid general_blueprint;

  initial begin
    $display("Simulation start!");

    $display("\n\nStarting tests for DUT [sigmoid_lut]");
    discrete_blueprint = new();
    edge_case_blueprint = new();
    general_blueprint = new();
    run_phase(duts_in, dut_out_uniform, discrete_blueprint, 0.0, 5, "Discrete sigmoid");
    run_phase(duts_in, dut_out_uniform, edge_case_blueprint, 2.0 ** -12, 5, "Edge case sigmoid");
    run_phase(duts_in, dut_out_uniform, general_blueprint, 0.02, 100, "General sigmoid");

    $display("\n\nStarting tests for DUT [sigmoid_lut_optimized]");
    discrete_blueprint = new();
    edge_case_blueprint = new();
    general_blueprint = new();
    run_phase(duts_in, dut_out_opt, discrete_blueprint, 2.0 ** -12, 5, "Discrete sigmoid");
    run_phase(duts_in, dut_out_opt, edge_case_blueprint, 2.0 ** -12, 5, "Edge case sigmoid");
    run_phase(duts_in, dut_out_opt, general_blueprint, 0.02, 100, "General sigmoid");

    $display("@%0t: End of simulation", $time);
  end
endprogram : test
