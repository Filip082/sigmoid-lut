module sigmoid_lut_optimized #(
    parameter int DATA_W   = 16,
    parameter int FRACTIONAL_BITS = 12,
    parameter int LUT_BITS = 8,
    localparam int INTEGER_BITS = DATA_W - FRACTIONAL_BITS,
    localparam MSB = INTEGER_BITS - 1,
    localparam LSB = -FRACTIONAL_BITS
)(
    input  logic clk,
    input  logic rst_n,
    input  logic signed [MSB:LSB] x_in,
    output logic signed [MSB:LSB] y_out
);
    logic [DATA_W-1:0] rom [0:(1<<LUT_BITS)-1];

    initial begin
        $readmemh("data/sigmoid_optimized.hex", rom);
    end

    logic signed [MSB:LSB] xn;
    always_comb begin
        xn = x_in[MSB] ? x_in : -x_in;
    end

    logic [LUT_BITS-1:0] addr;
    always_comb begin
        unique casex (xn[MSB:MSB-2])
            3'b10?: addr = {2'b0, xn[MSB-2:MSB-LUT_BITS+1]};
            3'b110: addr = {2'b1, xn[MSB-3:MSB-LUT_BITS]};
            3'b111: addr = {1'b1, xn[MSB-3:MSB-LUT_BITS-1]};
            default: addr = 0;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_out <= {4'b0, 1'b1, {(DATA_W-5){1'b0}}};
        end else begin
            if (x_in == 0) y_out <= {{INTEGER_BITS{1'b0}}, 1'b1, {(FRACTIONAL_BITS - 1){1'b0}}};
            else if (x_in[MSB]) y_out <= rom[addr];
            else y_out <= {{(INTEGER_BITS-1){1'b0}}, 1'b1, {FRACTIONAL_BITS{1'b0}}} - rom[addr];
        end
    end

endmodule
