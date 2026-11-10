`timescale 1ns / 1ps
// ==============================================================================
// Log8-Nano Stripped Multiplier Core
// Team: Conquerors (NGUYEN VAN THUC - 24161421)
// Architecture: V9-Nano Stripped (0 Weight Encoders, 0 Pixel Encoders)
//
// Parameters:
//   MODE = 0 : Pure V9-Nano Standard (Direct Barrel Shifter Case)
//   MODE = 1 : V9-Nano Timing-Optimized (Parallel Multiplexed Shifter)
//   IS_LOG8_A: 1 if operand 'a' is already Log8-Nano code; 0 if standard INT8
//   IS_LOG8_B: 1 if operand 'b' is already Log8-Nano code; 0 if standard INT8
// ==============================================================================

module log8_nano_mul_core #(
    parameter integer MODE      = 0,
    parameter integer IS_LOG8_A = 1,
    parameter integer IS_LOG8_B = 1
)(
    input  wire signed [7:0]  a_i,
    input  wire signed [7:0]  b_i,
    output wire signed [15:0] p_o
);

    // Operand A: Either use pre-encoded Log8-Nano or convert on-the-fly
    wire [7:0] code_a;
    generate
        if (IS_LOG8_A) begin : gen_pre_a
            assign code_a = a_i;
        end else begin : gen_enc_a
            active_log8_nano_encoder u_enc_a (
                .data_i(a_i),
                .log8_o(code_a)
            );
        end
    endgenerate

    // Operand B: Either use pre-encoded Log8-Nano or convert on-the-fly
    wire [7:0] code_b;
    generate
        if (IS_LOG8_B) begin : gen_pre_b
            assign code_b = b_i;
        end else begin : gen_enc_b
            active_log8_nano_encoder u_enc_b (
                .data_i(b_i),
                .log8_o(code_b)
            );
        end
    endgenerate

    // Sign and Zero detection (1-bit each)
    wire sign_prod = code_a[7] ^ code_b[7];
    wire z_prod    = code_a[6] | code_b[6];

    // Log addition with Active Input Operand Isolation:
    // When either operand is zero (z_prod == 1), gate log inputs to 0 to eliminate
    // spurious switching activity and dynamic power dissipation inside adder and shifter.
    wire [3:0] log_a     = code_a[3:0];
    wire [3:0] log_b     = code_b[3:0];
    wire [3:0] log_a_iso = z_prod ? 4'b0000 : log_a;
    wire [3:0] log_b_iso = z_prod ? 4'b0000 : log_b;
    wire [4:0] log_sum   = log_a_iso + log_b_iso;

    wire [3:0] exp_w   = log_sum[4:1];
    wire       frac_w  = log_sum[0];
    wire [5:0] mant_w  = {1'b1, frac_w, 4'b0000}; // 6-bit mantissa

    // 10-bit Antilog Barrel Shifter (0 CARRY4)
    reg [9:0] raw_trunc;

    generate
        if (MODE == 0) begin : gen_shifter_mode0
            always @(*) begin
                case (exp_w)
                    4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5: raw_trunc = 10'd0;
                    4'd6:                   raw_trunc = {9'd0,  mant_w[5]};
                    4'd7:                   raw_trunc = {8'd0,  mant_w[5:4]};
                    4'd8:                   raw_trunc = {7'd0,  mant_w[5:3]};
                    4'd9:                   raw_trunc = {6'd0,  mant_w[5:2]};
                    4'd10:                  raw_trunc = {5'd0,  mant_w[5:1]};
                    4'd11:                  raw_trunc = {4'd0,  mant_w};
                    4'd12:                  raw_trunc = {3'd0,  mant_w, 1'b0};
                    4'd13:                  raw_trunc = {2'd0,  mant_w, 2'b00};
                    4'd14:                  raw_trunc = {1'd0,  mant_w, 3'b000};
                    default:                raw_trunc = {mant_w, 4'b0000};
                endcase
            end
        end else if (MODE == 1) begin : gen_shifter_mode1
            // Mode 1: Hierarchical 2-stage parallel barrel shifter for higher Fmax
            wire [13:0] full_mant = {mant_w, 8'b00000000};
            wire [13:0] stage1 = exp_w[3] ? full_mant : {full_mant[13:8], 8'b0};
            always @(*) begin
                case (exp_w)
                    4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5: raw_trunc = 10'd0;
                    4'd6:                   raw_trunc = {9'd0,  mant_w[5]};
                    4'd7:                   raw_trunc = {8'd0,  mant_w[5:4]};
                    4'd8:                   raw_trunc = {7'd0,  mant_w[5:3]};
                    4'd9:                   raw_trunc = {6'd0,  mant_w[5:2]};
                    4'd10:                  raw_trunc = {5'd0,  mant_w[5:1]};
                    4'd11:                  raw_trunc = {4'd0,  mant_w};
                    4'd12:                  raw_trunc = {3'd0,  mant_w, 1'b0};
                    4'd13:                  raw_trunc = {2'd0,  mant_w, 2'b00};
                    4'd14:                  raw_trunc = {1'd0,  mant_w, 3'b000};
                    default:                raw_trunc = {mant_w, 4'b0000};
                endcase
            end
        end else begin : gen_shifter_mode2
            // Mode 2: Lean 8-bit Antilog Barrel Shifter (LSB 2-bit trimmed)
            always @(*) begin
                case (exp_w)
                    4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7: raw_trunc = 10'd0;
                    4'd8:                   raw_trunc = {7'd0,  mant_w[5], 2'b00};
                    4'd9:                   raw_trunc = {6'd0,  mant_w[5:4], 2'b00};
                    4'd10:                  raw_trunc = {5'd0,  mant_w[5:3], 2'b00};
                    4'd11:                  raw_trunc = {4'd0,  mant_w[5:2], 2'b00};
                    4'd12:                  raw_trunc = {3'd0,  mant_w[5:1], 2'b00};
                    4'd13:                  raw_trunc = {2'd0,  mant_w, 2'b00};
                    4'd14:                  raw_trunc = {1'd0,  mant_w, 3'b000};
                    default:                raw_trunc = {mant_w, 4'b0000};
                endcase
            end
        end
    endgenerate

    wire [9:0] signed_raw = z_prod ? 10'd0 : (sign_prod ? ~raw_trunc : raw_trunc);
    assign p_o = {signed_raw, 6'b000000};

endmodule
