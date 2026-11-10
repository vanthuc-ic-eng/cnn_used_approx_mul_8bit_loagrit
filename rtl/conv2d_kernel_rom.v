`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/16/2025 03:57:35 PM
// Design Name: 
// Module Name: conv2d_kernel_rom
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


module conv2d_kernel_rom (
    input clk,
    input  wire [5:0] addr,         // Kernel weight address (0 to 35)
    output reg  signed [7:0] data   // Corresponding 8-bit signed kernel weight
);

    always @(posedge clk) begin
            case (addr)
                6'd0:   data = 8'h80; // Orig:   -1
                6'd1:   data = 8'h8B; // Orig:  -51
                6'd2:   data =  8'h05; // Orig:   +7
                6'd3:   data =  8'h07; // Orig:  +15
                6'd4:   data = 8'h89; // Orig:  -27
                6'd5:   data = 8'h82; // Orig:   -3
                6'd6:   data =  8'h08; // Orig:  +23
                6'd7:   data = 8'h82; // Orig:   -3
                6'd8:   data = 8'h88; // Orig:  -22
                6'd9:   data = 8'h86; // Orig:   -9
                6'd10:  data = 8'h89; // Orig:  -28
                6'd11:  data = 8'h8A; // Orig:  -36
                6'd12:  data = 8'h8B; // Orig:  -49
                6'd13:  data =  8'h07; // Orig:  +12
                6'd14:  data =  8'h06; // Orig:  +10
                6'd15:  data = 8'h87; // Orig:  -13
                6'd16:  data =  8'h05; // Orig:   +7
                6'd17:  data =  8'h08; // Orig:  +16
                6'd18:  data = 8'h8D; // Orig: -127
                6'd19:  data = 8'h87; // Orig:  -14
                6'd20:  data =  8'h03; // Orig:   +3
                6'd21:  data = 8'h8A; // Orig:  -33
                6'd22:  data =  8'h04; // Orig:   +4
                6'd23:  data =  8'h08; // Orig:  +20
                6'd24:  data = 8'h88; // Orig:  -20
                6'd25:  data = 8'h87; // Orig:  -16
                6'd26:  data =  8'h08; // Orig:  +16
                6'd27:  data = 8'h87; // Orig:  -13
                6'd28:  data = 8'h84; // Orig:   -5
                6'd29:  data =  8'h08; // Orig:  +18
                6'd30:  data = 8'h88; // Orig:  -24
                6'd31:  data = 8'h87; // Orig:  -16
                6'd32:  data = 8'h8A; // Orig:  -39
                6'd33:  data =  8'h08; // Orig:  +16
                6'd34:  data =  8'h08; // Orig:  +22
                6'd35:  data = 8'h82; // Orig:   -3
                default: data = 8'sd0;
            endcase
        end

endmodule

