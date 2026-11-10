`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/24/2025 02:29:40 PM
// Design Name: 
// Module Name: convolution_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module convolution_unit (
    input  [8*9-1:0] pixel_bus,       // Flattened 3x3 pixel window (9 bytes)
    input  [8*9-1:0] kernel_weights,   // Flattened 3x3 kernel weights (9 bytes)
    output signed [31:0] conv_out
);
    wire signed [7:0] pixel [8:0];
    wire signed [7:0] kernel [8:0];
    wire signed [15:0] mult_out [8:0];

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

    TheMultiplier mult0 (pixel[0], kernel[0], mult_out[0]);
    TheMultiplier mult1 (pixel[1], kernel[1], mult_out[1]);
    TheMultiplier mult2 (pixel[2], kernel[2], mult_out[2]);
    TheMultiplier mult3 (pixel[3], kernel[3], mult_out[3]);
    TheMultiplier mult4 (pixel[4], kernel[4], mult_out[4]);
    TheMultiplier mult5 (pixel[5], kernel[5], mult_out[5]);
    TheMultiplier mult6 (pixel[6], kernel[6], mult_out[6]);
    TheMultiplier mult7 (pixel[7], kernel[7], mult_out[7]);
    TheMultiplier mult8 (pixel[8], kernel[8], mult_out[8]);

    assign conv_out = mult_out[0] + mult_out[1] + mult_out[2] +
                      mult_out[3] + mult_out[4] + mult_out[5] +
                      mult_out[6] + mult_out[7] + mult_out[8];
endmodule
