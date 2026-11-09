`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2025 12:36:05 PM
// Design Name: 
// Module Name: relu_bram
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


module relu_bram (
    input wire clk,
    input wire reset,
    input wire start,
    output reg done, //DONE

    // interface to BRAM output 28x28x32
    output reg [9:0] addr, //DONE
    input wire signed [31:0] din,    // đầu vào từ BRAM
    output reg signed [31:0] dout, //DONE          // đầu ra ghi vào BRAM
    output reg we //DONE                   // tín hiệu ghi
);

    localparam IDLE = 0, WAIT_STABLE = 1, LOAD = 2, WAIT_LOAD = 3, CHECK_SIGNED_BIT = 4, WRITE = 5, NEXT = 6, FINISH = 7;
    reg [2:0] state; //DONE

    reg [9:0] index; //DONE    // địa chỉ từ 0 đến 783
        
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            done <= 0;
            addr <= 0;
            dout <= 0;
            we <= 0;
            index <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    we <= 0;
                    addr <= 0;
                    index <= 0;
                    if (start)
                        state <= WAIT_STABLE;
                end
                
                WAIT_STABLE: begin
                    state <= LOAD;
                end
    
                LOAD: begin
                    addr <= index;
                    state <= WAIT_LOAD;
                end
    
                WAIT_LOAD: begin //Doi 1 chu ky de dout cua bram cap nhat vao din cua relu_bram.
                    state <= CHECK_SIGNED_BIT;
                end
    
                CHECK_SIGNED_BIT: begin
                    if (din[31] == 1) begin
                        dout <= 0;
                        we <= 1;
    //                    $display("ReLU at addr=%0d: input=%0d -> output=0", index, $signed(din));
                        state <= WRITE;
                    end else begin
                        // Không cần ghi nếu không âm
    //                    $display("ReLU at addr=%0d: input=%0d -> GIU NGUYEN", index, $signed(din));
                        state <= NEXT;
                    end
                end
    
                WRITE: begin
                    we <= 0;  // ghi xong rồi tắt write enable
                    state <= NEXT;
                end
    
                NEXT: begin
                    if (index == 783)
                        state <= FINISH;
                    else begin
                        index <= index + 1;
                        state <= LOAD;
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


