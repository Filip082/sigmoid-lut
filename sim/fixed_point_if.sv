interface fixed_point_if #(
    parameter DATA_W = 16,
    parameter FRACTIONAL_BITS = 12
) (input logic clk);
    localparam INTEGER_BITS = DATA_W - FRACTIONAL_BITS;

    logic [INTEGER_BITS-1:-FRACTIONAL_BITS] val;

    modport DUT_in (
        input val
    );

    modport DUT_out (
        output val
    );

    clocking cbd @(posedge clk);
        output val;
    endclocking : cbd
    modport driver (clocking cbd);

    clocking cbm @(negedge clk);
        input val;
    endclocking : cbm
    modport monitor (clocking cbm);

endinterface : fixed_point_if
