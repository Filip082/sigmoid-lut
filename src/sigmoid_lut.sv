module sigmoid_lut #(
    parameter int DATA_W   = 16,
    parameter int FRACTIONAL_BITS = 12,
    localparam int INTEGER_BITS = DATA_W - FRACTIONAL_BITS,
    parameter int LUT_BITS = 8
)(
    input  logic                clk,
    input  logic                rst_n,
    input  logic [INTEGER_BITS-1:-FRACTIONAL_BITS]   x_in,
    output logic [INTEGER_BITS-1:-FRACTIONAL_BITS]   y_out
);

    logic [DATA_W-1:0] rom [0:(1<<LUT_BITS)-1];

    initial begin
        $readmemh("data/sigmoid.hex", rom);
    end

    logic [LUT_BITS-1:0] addr;
    always_comb begin
        addr = x_in[INTEGER_BITS-1:INTEGER_BITS-LUT_BITS] ^ {1'b1, {(LUT_BITS-1){1'b0}}};
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_out <= {4'b0, 1'b1, {(DATA_W-5){1'b0}}};
        end else begin
            y_out <= rom[addr];
        end
    end

endmodule
