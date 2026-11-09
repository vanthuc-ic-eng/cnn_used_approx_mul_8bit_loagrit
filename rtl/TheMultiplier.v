`timescale 1ns / 1ps
// ==============================================================================
// Parameterized Multiplier Wrapper for CNN Accelerator
// Substituted with LUT-ALM V9 Extreme Architecture (Team Conquerors)
//
// Operational Modes:
//   MODE = 0 : LUT-ALM V9-Ultra Balanced (58-61 LUTs, MRED = 3.7660%, ~7.69 ns)
//   MODE = 1 : LUT-ALM V9-Ultra Lean     (56 LUTs,    MRED = 4.8299%, ~6.89 ns)
//   MODE = 2 : LUT-ALM V9-Nano Extreme   (36-37 LUTs, MRED = 9.0302%, ~4.93 ns)
// ==============================================================================

module TheMultiplier #(
    parameter integer MODE = 2
)(
    input  wire signed [7:0]  a,
    input  wire signed [7:0]  b,
    output wire signed [15:0] S
);

    lutalm_mul_s8 #(
        .MODE(MODE)
    ) u_lutalm_core (
        .a_i(a),
        .b_i(b),
        .p_o(S)
    );

endmodule
