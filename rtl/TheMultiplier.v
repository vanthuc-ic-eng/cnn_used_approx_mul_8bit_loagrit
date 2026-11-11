`timescale 1ns / 1ps
// ==============================================================================
// Parameterized Multiplier Wrapper for CNN Accelerator
// Substituted with LUT-ALM V11-Lean Flex Architecture (Team Conquerors)
// Multiplier Core: v0.2.0 (47 Slice LUTs, 2 CARRY4, MRED = 5.5861%)
//
// Operational Modes (selectable via parameter MODE):
//   MODE = 0 : V9-Ultra Balanced (62 Slice LUTs, 3 CARRY4, MRED = 3.7660%)
//   MODE = 1 : V11-Lean Flex     (47 Slice LUTs, 2 CARRY4, MRED = 5.5861%) -> Active
//   MODE = 2 : V10-Nano Extreme  (34 Slice LUTs, 0 CARRY4, MRED = 16.5127%)
// ==============================================================================

module TheMultiplier #(
    parameter integer MODE              = 1, // Default: 47 LUT Sweet-Spot
    parameter integer OPERAND_ISOLATION = 1  // Active Input Operand Isolation (Glitch Reduction)
)(
    input  wire signed [7:0]  a,
    input  wire signed [7:0]  b,
    output wire signed [15:0] S
);

    lutalm_mul_s8 #(
        .MODE(MODE),
        .OPERAND_ISOLATION(OPERAND_ISOLATION)
    ) u_lutalm_core (
        .a_i(a),
        .b_i(b),
        .p_o(S)
    );

endmodule
