`ifndef SIGMOID_SV
  `define SIGMOID_SV

class sigmoid #(
    parameter int DATA_W   = 16,
    parameter int FRACTIONAL_BITS = 12,
    localparam int INTEGER_BITS = DATA_W - FRACTIONAL_BITS
);
  rand bit signed [INTEGER_BITS-1:-FRACTIONAL_BITS] x_in; // Q4.12 signed
  bit signed [INTEGER_BITS-1:-FRACTIONAL_BITS] y_out; // Q4.12 unsigned

  real x_in_real;
  real y_out_real;

  extern function new();
  extern function sigmoid copy();
  extern function void post_randomize();
  extern function void display();
endclass : sigmoid

function sigmoid::new();
  x_in = 0;
  y_out = 0;
  x_in_real = 0.0;
  y_out_real = 0.0;
endfunction : new

function sigmoid sigmoid::copy();
  sigmoid cpy = new();
  cpy.x_in = this.x_in;
  cpy.y_out = this.y_out;
  cpy.x_in_real = this.x_in_real;
  cpy.y_out_real = this.y_out_real;
  return cpy;
endfunction : copy

function void sigmoid::post_randomize();
  x_in_real = $itor(x_in) / (2 ** FRACTIONAL_BITS);
  y_out_real = 1.0 / (1.0 + $exp(-x_in_real));
  y_out = $rtoi($floor(y_out_real * (2 ** FRACTIONAL_BITS)));
endfunction : post_randomize

function void sigmoid::display();
  $display("x_in: %0f (0x%0h), y_out: %0f (0x%0h)", x_in_real, x_in, y_out_real, y_out);
endfunction : display

class discrete_sigmoid #(
    parameter int DISCRETISATION_BITS = 8
) extends sigmoid;

  constraint discretisation {
    x_in[INTEGER_BITS-DISCRETISATION_BITS-1:-FRACTIONAL_BITS] == 0;
  }

  function new();
    super.new();
  endfunction
endclass : discrete_sigmoid

class edge_case_sigmoid extends sigmoid;
  randc bit [2:0] sel;

  constraint edge_cases {
    sel < 5;
  }

  function void post_randomize();
    case (sel)
      0: x_in = 16'b0000;
      1: x_in = 16'h8000;
      2: x_in = 16'h7FFF;
      3: x_in = 16'h4000;
      4: x_in = 16'hC000;
    endcase;
    super.post_randomize();
  endfunction

  function new();
    super.new();
  endfunction
endclass : edge_case_sigmoid

program automatic test_sigmoid;
  sigmoid s;
  discrete_sigmoid ds;
  general_sigmoid gs;

  initial begin
    $display("Random sigmoid transactions:");
    repeat(5) begin
      s = new();
      if (s.randomize()) begin
        s.display();
      end else begin
        $display("Failed to randomize sigmoid");
      end
    end
    $display("\nRandom discrete sigmoid transactions:");
    repeat(5) begin
      ds = new();
      if (ds.randomize()) begin
        ds.display();
      end else begin
        $display("Failed to randomize discrete_sigmoid");
      end
    end
  end 
endprogram : test_sigmoid

`endif // SIGMOID_SV
