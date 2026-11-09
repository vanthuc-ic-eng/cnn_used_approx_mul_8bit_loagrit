`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2025 01:07:58 AM
// Design Name: 
// Module Name: bram_image_30x30x8
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


module bram_image_30x30x8 (
    input wire clk,
    input wire we,
    input wire [9:0] addr,           // 0 - 899
    input wire signed [7:0] din,
    output reg signed [7:0] dout


);

    (* ram_style = "block" *) reg signed [7:0] mem [0:899];
    
    always @(posedge clk) begin
            if (we)
                mem[addr] <= din;
            dout <= mem[addr];
//            if (!we)
//                $display("Read BRAM 30x30x8[addr=%0d] => data=%0d", addr, $signed(mem[addr]));
            end

endmodule
