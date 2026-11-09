`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2025 07:15:36 PM
// Design Name: 
// Module Name: requantizer_unit
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


module requantizer_unit (
    input wire signed [31:0] in_val,
    input wire [4:0] shift,
    output wire signed [7:0] out_val
);
    wire signed [31:0] shifted_val;
    assign shifted_val = in_val >>> shift;

    assign out_val = (shifted_val > 127) ? 127 :
                     (shifted_val < -128) ? -128 :
                     shifted_val[7:0];
endmodule
