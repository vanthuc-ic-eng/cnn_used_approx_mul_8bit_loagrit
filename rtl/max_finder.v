`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2025 02:54:32 PM
// Design Name: 
// Module Name: max_finder
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


module max_finder (
    input wire clk,
    input wire reset,
    input wire start,
    output reg [9:0] addr, //DONE
    input wire [31:0] din,
    output reg [31:0] max_val, //DONE
    output reg done //DONE
);
    localparam IDLE = 0, READ = 1, COMPARE = 2, NEXT = 3, FINISH = 4;
    reg [2:0] state; //DONE
    reg [9:0] index; //DONE

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            addr <= 0;
            max_val <= 0;
            done <= 0;
            index <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    max_val <= 0;
                    index <= 0;
                    addr <= 0;
                    if (start)
                        state <= READ;
                end
                
                READ: begin
                    state <= COMPARE;
                end
                
                COMPARE: begin
                    if (din > max_val)
                        max_val <= din;
                    state <= NEXT;
                end
                
                NEXT: begin
                    if (index == 783)
                        state <= FINISH;
                    else begin
                        /*index se lay gia tri hien tai + 1.
                        addr se lay gia tri hien tai cua index + 1 chu
                        khong phai lay gia tri cua (index da~ +1) cong. cho 1.*/
                        index <= index + 1;
                        addr <= index + 1;
                        state <= READ;
                    end
                end
                
                FINISH: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
       end
    end
endmodule
