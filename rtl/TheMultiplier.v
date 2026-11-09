`timescale 1ns / 1ps
// ==============================================================================
// Parameterized Multiplier Wrapper for CNN Accelerator
// Substituted with Log8-Nano Stripped Architecture (Team Conquerors)
//
// Operational Modes:
//   MODE = 0 : Log8-Nano Pure Standard (V9-Nano stripped core, 95.40% Acc)
//   MODE = 1 : Log8-Nano Timing-Optimized (Parallel muxing barrel shifter)
//   MODE = 2 : Log8-Nano Lean 8-bit Shifter (v0.2.2 - LSB 2-bit trimmed, ultra-low LUTs)
// ==============================================================================

module TheMultiplier #(
    parameter integer MODE      = 2,
    parameter integer IS_LOG8_A = 0,
    parameter integer IS_LOG8_B = 1
)(
    input  wire signed [7:0]  a,
    input  wire signed [7:0]  b,
    output wire signed [15:0] S
);

    log8_nano_mul_core #(
        .MODE(MODE),
        .IS_LOG8_A(IS_LOG8_A),
        .IS_LOG8_B(IS_LOG8_B)
    ) u_log8_nano_core (
        .a_i(a),
        .b_i(b),
        .p_o(S)
    );

endmodule
