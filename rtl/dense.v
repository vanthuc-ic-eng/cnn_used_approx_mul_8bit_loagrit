`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2025 04:36:06 PM
// Design Name: 
// Module Name: dense
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


module dense(
    input wire clk,
    input wire reset,
    input wire start,
    output reg [3:0] predict,
    output reg done,
    
    //READ FROM BRAM
    input wire signed [7:0] din_read,
    output reg [8:0] addr_read,
    
    //READ FROM DENSE ROM
    input wire signed [7:0] din_weights,
    output reg [11:0] addr_weights
);

    localparam IDLE = 0,
               WAIT_STABLE = 1,
               LOAD = 2,
               WAIT_LOAD = 3,
               MULT = 4,
               WAIT_MULT = 5,
               ADD = 6,
               NEXT = 7,
               INIT_FIND_MAX = 8,
               FIND_MAX = 9,
               CHECK_WINNER = 10;

    reg [3:0] state; // FSM state register, initialized to IDLE upon reset

    reg signed [7:0] a, b;
    wire signed [15:0] S;
    TheMultiplier mult (.a(a), .b(b), .S(S));
    
    reg signed [255:0] neuron [0:9];
    
    
    reg [3:0] index;  // neuron index: 0 - 9
    reg [8:0] i;      // flatten index: 0 - 323

    reg [3:0] max_idx;
    reg [3:0] compare_idx;
    reg signed [255:0] max_val;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            predict <= 0;
            done <= 0;
            index <= 0;
            i <= 0;
            compare_idx <= 1;
            addr_read <= 0;
            addr_weights <= 0;
            a <= 0;
            b <= 0;
            max_val <= 0;
            max_idx <= 0;
    
            neuron[0] <= 0;
            neuron[1] <= 0;
            neuron[2] <= 0;
            neuron[3] <= 0;
            neuron[4] <= 0;
            neuron[5] <= 0;
            neuron[6] <= 0;
            neuron[7] <= 0;
            neuron[8] <= 0;
            neuron[9] <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    //predict <= 0; 
                    index <= 0;
                    i <= 0;
                    compare_idx <= 1;
                    addr_read <= 0;
                    addr_weights <= 0;
                    neuron[0] <= 0;
                    neuron[1] <= 0;
                    neuron[2] <= 0;
                    neuron[3] <= 0;
                    neuron[4] <= 0;
                    neuron[5] <= 0;
                    neuron[6] <= 0;
                    neuron[7] <= 0;
                    neuron[8] <= 0;
                    neuron[9] <= 0;
                    if (start) state <= WAIT_STABLE;
                end
                
                WAIT_STABLE: begin
                    state <= LOAD;
                end
                
                LOAD: begin
                    addr_read <= i;
                    addr_weights <= index * 324 + i;
                    state <= WAIT_LOAD;
                end
    
                WAIT_LOAD: begin
                    state <= MULT;
                end
                
                MULT: begin
                    a <= din_read;
                    b <= din_weights;
                    state <= WAIT_MULT;
                end
    
                WAIT_MULT: begin
                    state <= ADD;
                end
    
                ADD: begin
                    neuron[index] <= neuron[index] + S;
                    state <= NEXT;
                end
    
                NEXT: begin
                    if (i == 323) begin
                        i <= 0;
                        if (index == 9)
                            state <= INIT_FIND_MAX;
                        else begin
                            index <= index + 1;
                            state <= LOAD;
                        end
                    end else begin
                        i <= i + 1;
                        state <= LOAD;
                    end
                end
    
                INIT_FIND_MAX: begin
                    max_val <= neuron[0];
                    max_idx <= 0;
                    compare_idx <= 1;
//                     ============ DEBUG INSTRUMENTATION ================
//                    $display("Neuron values:");
//                    $display("neuron[0] = %0d", neuron[0]);
//                    $display("neuron[1] = %0d", neuron[1]);
//                    $display("neuron[2] = %0d", neuron[2]);
//                    $display("neuron[3] = %0d", neuron[3]);
//                    $display("neuron[4] = %0d", neuron[4]);
//                    $display("neuron[5] = %0d", neuron[5]);
//                    $display("neuron[6] = %0d", neuron[6]);
//                    $display("neuron[7] = %0d", neuron[7]);
//                    $display("neuron[8] = %0d", neuron[8]);
//                    $display("neuron[9] = %0d", neuron[9]);
                    state <= FIND_MAX;
                end
    
                FIND_MAX: begin
                    if (compare_idx <= 9) begin
                        if (neuron[compare_idx] > max_val) begin
                            max_val <= neuron[compare_idx];
                            max_idx <= compare_idx;
                        end
                        compare_idx <= compare_idx + 1;
                    end else begin
                        state <= CHECK_WINNER;
                    end
                end
    
                CHECK_WINNER: begin
                    predict <= max_idx;
                    done <= 1;
                    state <= IDLE;
                end
    //            default: state <= IDLE;
            endcase
       end
    end
endmodule
