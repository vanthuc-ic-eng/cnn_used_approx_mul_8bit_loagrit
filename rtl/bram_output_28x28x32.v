`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2025 12:19:24 PM
// Design Name: 
// Module Name: bram_output_28x28x32
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


module bram_output_28x28x32 (
    input wire clk,
    input wire we,
    input wire [9:0] addr,         // 0 - 783
    input wire signed [31:0] din,
    output reg signed [31:0] dout

);
    (* ram_style = "block" *) reg signed [31:0] mem [0:783];

    
    always @(posedge clk) begin
            if (we)
                mem[addr] <= din;
            dout <= mem[addr];
//            if (!we)
//                $display("Read BRAM 28x28x32[addr=%0d] => data=%0d", addr, mem[addr]);

        end
endmodule
