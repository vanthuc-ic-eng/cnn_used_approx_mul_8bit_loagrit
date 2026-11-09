`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/18/2025 09:59:42 PM
// Design Name: 
// Module Name: max_pooling_3x3
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


module max_pooling_3x3 (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [1:0] kernel_id,
    output reg done, //DONE

    output reg [9:0] addr_read, //DONE
    input wire signed [7:0] din_read,

    output reg [8:0] addr_write, //DONE
    output reg signed [7:0] dout_write, //DONE
    output reg we_write //DONE
);

    localparam IDLE = 0,
               WAIT_STABLE = 1,
               LOAD = 2,
               WAIT = 3,
               STORE = 4,
               CALC_INIT = 5,
               CALC_STEP = 6,
               WRITE = 7,
               NEXT = 8,
               FINISH = 9;

    reg [3:0] state; //DONE
    reg [3:0] load_count; //DONE
    reg [3:0] calc_count; //DONE
    reg signed [7:0] window [0:8]; //DONE
    reg signed [7:0] max_val; //DONE

    reg [4:0] shift_right; //DONE
    reg [4:0] shift_down; //DONE
    reg [6:0] index; //DONE

    reg [9:0] top, mid, bottom; //DONE

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            done <= 0;
            addr_read <= 0;
            addr_write <= 0;
            dout_write <= 0;
            we_write <= 0;
            shift_right <= 0;
            shift_down <= 0;
            load_count <= 0;
            calc_count <= 0;
            index <= 0;
            top <= 0;
            mid <= 0;
            bottom <= 0;
            max_val <= 0;
            window[0] <= 0;
            window[1] <= 0;
            window[2] <= 0;
            window[3] <= 0;
            window[4] <= 0;
            window[5] <= 0;
            window[6] <= 0;
            window[7] <= 0;
            window[8] <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    we_write <= 0;
                    shift_right <= 0;
                    shift_down <= 0;
                    load_count <= 0;
                    calc_count <= 0;
                    index <= 0;
                    top <= 0;
                    mid <= 28;
                    bottom <= 56;
                    if (start)
                        state <= WAIT_STABLE;
                end
                
                WAIT_STABLE: begin
                    state <= LOAD;
                end
                
                LOAD: begin
                    case (load_count)
                        0,1,2: addr_read <= top;
                        3,4,5: addr_read <= mid;
                        6,7,8: addr_read <= bottom;
                    endcase
                    state <= WAIT;
                end
    
                WAIT: begin
                    state <= STORE; //Cho` 1 chu ky xung de BRAM dua data ra.
                end
    
                STORE: begin
                    window[load_count] <= din_read;
                    case (load_count)
                        0,1,2: top <= top + 1;
                        3,4,5: mid <= mid + 1;
                        6,7,8: bottom <= bottom + 1;
                    endcase
                    if (load_count == 8) begin
                        load_count <= 0;
                        state <= CALC_INIT;
                    end else begin
                        load_count <= load_count + 1;
                        state <= LOAD;
                    end
                end
    
                CALC_INIT: begin
                    max_val <= window[0];
                    calc_count <= 1;
                    state <= CALC_STEP;
                end
    
                CALC_STEP: begin
                    if (window[calc_count] > max_val)
                        max_val <= window[calc_count];
                    if (calc_count == 8)
                        state <= WRITE;
                    else
                        calc_count <= calc_count + 1;
                end
    
                WRITE: begin
                    addr_write <= index * 4 + kernel_id;
                    dout_write <= max_val;
                    we_write <= 1;
                    /*FOR DEBUGGING*/
                    //$display("O %0d: %0d", index * 4 + kernel_id, max_val);
                    state <= NEXT; 
                end
    
                NEXT: begin //Chi can sua cai State NEXT de? de~ giai thich code!
                    we_write <= 0;
                    index <= index + 1;
                    if (shift_right == 8 && shift_down == 8)
                        state <= FINISH;
                    else if (shift_right == 8) begin
                        shift_right <= 0;
                        shift_down <= shift_down + 1;
                        top <= top + 57;
                        mid <= mid + 57;
                        bottom <= bottom + 57;
                        state <= LOAD;
                    end
                    else begin
                        shift_right <= shift_right + 1; 
                    /*Sau khi Max Pool voi Write xong xuoi het moi tang flag shift_right len 1. Khac voi cai shift_right dat o STORE, 
                    khi vua LOAD xong la no tang shift_right len 1 lien` thanh` ra dieu kien ban dau` moi' de? la (shift_right == 9) && (shift_down == 8)
                    la` do vay. Vi thuc te shift_right thuc hien 9 lan tu` 1 toi 9. Con` dat shift_right o WRITE la shift_right thuc hien 9 lan` tu` 0 
                    toi 8.*/
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





