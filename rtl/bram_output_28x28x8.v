`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2025 03:07:50 PM
// Design Name: 
// Module Name: bram_output_28x28x8
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


module bram_output_28x28x8 (
    input wire clk,
    input wire we,
    input wire [9:0] addr,        // 0 - 783
    input wire signed [7:0] din,
    output reg signed [7:0] dout
);
    (* ram_style = "block" *) reg signed [7:0] mem [0:783];

    
    always @(posedge clk) begin
            if (we)
                mem[addr] <= din;
            dout <= mem[addr];
            // Debug monitor for read-only cycles (commented out for synthesis)
        end

endmodule

