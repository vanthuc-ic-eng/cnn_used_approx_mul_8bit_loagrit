`timescale 1ns / 1ps
// ==============================================================================
// BLOCK FLOATING-POINT (SHARED EXPONENT) CONVOLUTION UNIT - V3 ARCHITECTURE
// Team: Conquerors (NGUYEN VAN THUC - 24161421)
//
// Key Innovations:
//   1. 9-input parallel Log8-Nano exponent & mantissa extraction.
//   2. High-speed 4-bit Maximum Exponent tree (Emax = max(exp0..exp8)).
//   3. Dynamic mantissa right-alignment relative to Emax (0-to-9 bit shifters).
//   4. 9-operand narrow 14-bit signed mantissa accumulation.
//   5. SINGLE SHARED 14-bit Antilog Barrel Shifter (eliminates 8 barrel shifters!).
// ==============================================================================

module convolution_unit (
    input  wire [8*9-1:0]      pixel_bus,      // 9 Log8-Nano pixels from BRAM
    input  wire [8*9-1:0]      kernel_weights, // 9 Log8-Nano weights from ROM
    output wire signed [31:0]  conv_out
);

    wire [7:0] pixel  [8:0];
    wire [7:0] kernel [8:0];

    assign pixel[0]  = pixel_bus[7:0];
    assign pixel[1]  = pixel_bus[15:8];
    assign pixel[2]  = pixel_bus[23:16];
    assign pixel[3]  = pixel_bus[31:24];
    assign pixel[4]  = pixel_bus[39:32];
    assign pixel[5]  = pixel_bus[47:40];
    assign pixel[6]  = pixel_bus[55:48];
    assign pixel[7]  = pixel_bus[63:56];
    assign pixel[8]  = pixel_bus[71:64];

    assign kernel[0] = kernel_weights[7:0];
    assign kernel[1] = kernel_weights[15:8];
    assign kernel[2] = kernel_weights[23:16];
    assign kernel[3] = kernel_weights[31:24];
    assign kernel[4] = kernel_weights[39:32];
    assign kernel[5] = kernel_weights[47:40];
    assign kernel[6] = kernel_weights[55:48];
    assign kernel[7] = kernel_weights[63:56];
    assign kernel[8] = kernel_weights[71:64];

    // Step 1: 9-input Parallel Sign, Zero, Exp, and Mantissa Extraction
    wire [8:0] s, z;
    wire [3:0] exp [8:0];
    wire [8:0] frac;

    genvar k;
    generate
        for (k = 0; k < 9; k = k + 1) begin : gen_pe_extract
            wire [7:0] p = pixel[k];
            wire [7:0] w = kernel[k];
            assign s[k] = p[7] ^ w[7];
            assign z[k] = p[6] | w[6];
            wire [4:0] sum_log = p[3:0] + w[3:0];
            assign exp[k]  = z[k] ? 4'd0 : sum_log[4:1];
            assign frac[k] = sum_log[0];
        end
    endgenerate

    // Step 2: Maximum Exponent Search Tree (Emax)
    wire [3:0] m01   = (exp[0] > exp[1]) ? exp[0] : exp[1];
    wire [3:0] m23   = (exp[2] > exp[3]) ? exp[2] : exp[3];
    wire [3:0] m45   = (exp[4] > exp[5]) ? exp[4] : exp[5];
    wire [3:0] m67   = (exp[6] > exp[7]) ? exp[6] : exp[7];
    wire [3:0] m0123 = (m01 > m23) ? m01 : m23;
    wire [3:0] m4567 = (m45 > m67) ? m45 : m67;
    wire [3:0] m0_7  = (m0123 > m4567) ? m0123 : m4567;
    wire [3:0] emax  = (m0_7 > exp[8]) ? m0_7 : exp[8];

    // Step 3: Align 9 Mantissas to Emax (shift right by delta = emax - exp)
    wire signed [13:0] aligned_signed_mant [8:0];
    generate
        for (k = 0; k < 9; k = k + 1) begin : gen_pe_align
            wire [3:0] shift = emax - exp[k];
            wire [9:0] m_scaled = {1'b1, frac[k], 8'b00000000};
            wire [9:0] m_aligned = (shift >= 4'd10) ? 10'd0 : (m_scaled >> shift);
            assign aligned_signed_mant[k] = z[k] ? 14'sd0 : (s[k] ? -{4'd0, m_aligned} : {4'd0, m_aligned});
        end
    endgenerate

    // Step 4: 9-Operand Mantissa Adder (14-bit signed accumulator)
    wire signed [13:0] mant_sum = aligned_signed_mant[0] + aligned_signed_mant[1] +
                                  aligned_signed_mant[2] + aligned_signed_mant[3] +
                                  aligned_signed_mant[4] + aligned_signed_mant[5] +
                                  aligned_signed_mant[6] + aligned_signed_mant[7] +
                                  aligned_signed_mant[8];

    // Step 5: Single Shared 14-bit Antilog Barrel Shifter
    reg signed [13:0] shifted_raw;
    always @(*) begin
        if (emax <= 4'd5) begin
            shifted_raw = 14'sd0;
        end else begin
            case (emax)
                4'd6:    shifted_raw = mant_sum >>> 9;
                4'd7:    shifted_raw = mant_sum >>> 8;
                4'd8:    shifted_raw = mant_sum >>> 7;
                4'd9:    shifted_raw = mant_sum >>> 6;
                4'd10:   shifted_raw = mant_sum >>> 5;
                4'd11:   shifted_raw = mant_sum >>> 4;
                4'd12:   shifted_raw = mant_sum >>> 3;
                4'd13:   shifted_raw = mant_sum >>> 2;
                4'd14:   shifted_raw = mant_sum >>> 1;
                default: shifted_raw = mant_sum;
            endcase
        end
    end

    // Scale back: append 6 trailing zeros (matching V9-Nano scale)
    assign conv_out = {{12{shifted_raw[13]}}, shifted_raw, 6'b000000};

endmodule
