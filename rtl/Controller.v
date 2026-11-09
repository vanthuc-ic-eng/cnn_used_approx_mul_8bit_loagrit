`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2025 01:09:19 AM
// Design Name: 
// Module Name: Controller
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


module controller (
    input wire clk,
    input wire reset,
    input wire start,               // Tín hiệu bắt đầu từ pre_processing gui toi'.
    input wire done_maxpool,        // Tín hiệu tu maxpool gui den bao' da~ xong 1 kernel.
    output reg [1:0] kernel_id,     // Thứ tự kernel 0 -> 3
    output reg start_kernel,        // Tin hieu Start gui den cho module Conv2d.
    output reg done_all             // Tin hieu Start gui den module Dense báo đã xong 4 kernel để đi vào Dense.
);

    localparam IDLE = 0,
               START_KERNEL = 1,
               WAIT_DONE = 2,
               FINISH = 3;

    reg [1:0] state; //DONE

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            kernel_id <= 0;
            start_kernel <= 0;
            done_all <= 0;
        end else begin
            case (state)
                IDLE: begin
                    start_kernel <= 0;
                    done_all <= 0;
                    kernel_id <= 0;
                    if (start)
                        state <= START_KERNEL;
                end
    
                START_KERNEL: begin
                    start_kernel <= 1;
                    state <= WAIT_DONE;
                end
    
                WAIT_DONE: begin
                    start_kernel <= 0;
                    if (done_maxpool) begin
                        if (kernel_id == 3) begin
                            state <= FINISH;
                        end else begin
                            kernel_id <= kernel_id + 1;
                            state <= START_KERNEL;
                        end
                    end
                end
    
                FINISH: begin
                    done_all <= 1;
                    state <= IDLE;
                end
            endcase
       end
    end

endmodule

