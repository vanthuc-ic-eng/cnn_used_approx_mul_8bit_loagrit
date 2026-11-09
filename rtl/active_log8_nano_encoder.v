`timescale 1ns / 1ps
// ==============================================================================
// Active Log8-Nano Pixel Encoder
// Team: Conquerors (NGUYEN VAN THUC - 24161421)
// Function: Converts 8-bit signed integer pixel [-128, 127] to 8-bit Log8-Nano code:
//   code[7]   : sign (1 if negative, 0 if positive)
//   code[6]   : zero flag (1 if pixel == 0, 0 otherwise)
//   code[5:4] : 2'b00 (reserved)
//   code[3:1] : exponent k[2:0] in [0, 6]
//   code[0]   : fraction f (1-bit mantissa)
// ==============================================================================

module active_log8_nano_encoder (
    input  wire signed [7:0] data_i,
    output wire [7:0]        log8_o
);

    wire sign = data_i[7];
    wire [6:0] mag = sign ? ~data_i[6:0] : data_i[6:0];
    wire zero = (data_i[6:0] == 7'd0);

    reg [2:0] k;
    reg       f;

    always @(*) begin
        if      (mag[6]) begin k = 3'd6; f = mag[5]; end
        else if (mag[5]) begin k = 3'd5; f = mag[4]; end
        else if (mag[4]) begin k = 3'd4; f = mag[3]; end
        else if (mag[3]) begin k = 3'd3; f = mag[2]; end
        else if (mag[2]) begin k = 3'd2; f = mag[1]; end
        else if (mag[1]) begin k = 3'd1; f = mag[0]; end
        else             begin k = 3'd0; f = 1'b0;   end
    end

    assign log8_o = {sign, zero, 2'b00, k, f};

endmodule
