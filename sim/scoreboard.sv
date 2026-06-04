`ifndef SCOREBOARD__SV
 `define SCOREBOARD__SV

`include "sigmoid.sv"

class Scoreboard;
  sigmoid expected[$];
  real checker_tolerance = 0.0;
  int total_checks;
  int failed_checks;
  real mean_error;
  real max_error;

  extern function new();
  extern virtual function void wrap_up();
  extern function void save_expected(sigmoid trans);
  extern function void check_actual(input sigmoid trans);
endclass : Scoreboard

function Scoreboard::new();
  total_checks = 0;
  failed_checks = 0;
  mean_error = 0.0;
  max_error = 0.0;
endfunction

function void Scoreboard::save_expected(sigmoid trans);
  expected.push_back(trans.copy());

  $display("@%0t: Scoreboard saved expected transaction: x_in: %0f (0x%0h), y_out: %0f (0x%0h)",
           $time, trans.x_in_real, trans.x_in, trans.y_out_real, trans.y_out);
endfunction : save_expected

function void Scoreboard::check_actual(input sigmoid trans);
  sigmoid exp;
  real error;

  if (expected.size() == 0) return;

  total_checks++;
  exp = expected.pop_front();

  error = (exp.y_out - trans.y_out) / (2.0 ** trans.FRACTIONAL_BITS);
  if (error < 0) error = -error;

  mean_error += error;
  if (error > max_error) max_error = error;

  if (error > checker_tolerance) begin
    failed_checks++;
    $display("@%0t: Scoreboard check FAILED: x_in: %0f (0x%0h), y_out: %0f (0x%0h), expected: %0f (0x%0h), error: %e",
             $time, trans.x_in_real, trans.x_in, trans.y_out_real, trans.y_out, exp.y_out_real, exp.y_out, error);
    return;
  end

  $display("@%0t: Scoreboard check PASSED: x_in: %0f (0x%0h), y_out: %0f (0x%0h), error: %e",
           $time, exp.x_in_real, trans.x_in, exp.y_out_real, trans.y_out,
           (trans.y_out - exp.y_out) / (2.0 ** trans.FRACTIONAL_BITS));
endfunction : check_actual

function void Scoreboard::wrap_up();
  $display("@%0t: Scoreboard summary: Total checks=%0d, Failed checks=%0d, Pass rate=%.2f%%",
           $time, total_checks, failed_checks, (total_checks > 0) ? (100.0 * (total_checks - failed_checks) / total_checks) : 100.0);
  if (total_checks > 0) begin
    mean_error /= total_checks;
    $display("@%0t: Scoreboard error summary: Mean error=%e, Max error=%e",
             $time, mean_error, max_error);
  end
endfunction : wrap_up

`endif // SCOREBOARD__SV
