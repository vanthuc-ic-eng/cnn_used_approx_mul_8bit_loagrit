`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2025 11:37:42 PM
// Design Name: 
// Module Name: bram_9x9x4x8
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


module bram_flatten_9x9x4x8 (
    input wire clk,
    input wire we,
    input wire [8:0] addr,         // 0 - 323
    input wire signed [7:0] din,
    output reg signed [7:0] dout

);
    (* ram_style = "block" *) reg signed [7:0] mem [0:323];
    

    
    always @(posedge clk) begin
            if (we)
                mem[addr] <= din;
            dout <= mem[addr];
//            if (!we)
//                $display("Read BRAM 9x9x4x8 [addr=%0d] => data=%0d", addr, mem[addr]);

        end
endmodule

