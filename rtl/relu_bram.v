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

    // Interface to BRAM output 28x28x32
    output reg [9:0] addr,
    input wire signed [31:0] din,    // Data input from BRAM
    output reg signed [31:0] dout,   // Data output written to BRAM
    output reg we                    // Write enable strobe
);

    localparam IDLE = 0, WAIT_STABLE = 1, LOAD = 2, WAIT_LOAD = 3, CHECK_SIGNED_BIT = 4, WRITE = 5, NEXT = 6, FINISH = 7;
    reg [2:0] state;

    reg [9:0] index;                 // Pixel address index (0 to 783)
        
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
    
                WAIT_LOAD: begin // 1-cycle latency wait for BRAM read port stability
                    state <= CHECK_SIGNED_BIT;
                end
    
                CHECK_SIGNED_BIT: begin
                    if (din[31] == 1) begin
                        dout <= 0;
                        we <= 1;
                        state <= WRITE;
                    end else begin
                        // Non-negative values remain unaltered; bypass write operation
                        state <= NEXT;
                    end
                end
    
                WRITE: begin
                    we <= 0;  // De-assert write enable upon write completion
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


