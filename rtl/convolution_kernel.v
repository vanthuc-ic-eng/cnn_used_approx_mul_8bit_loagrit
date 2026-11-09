`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:26:06 03/19/2025 
// Design Name: 
// Module Name:    convolution_kernel 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module convolution_kernel (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [1:0] kernel_id,
    output reg done, //DONE

    output reg [9:0] addr_read, //DONE
    input wire signed [7:0] din_read,

    output reg [9:0] addr_write, //DONE
    output reg signed [31:0] dout_write, //DONE
    output reg we_write, //DONE

    output reg [5:0] addr_kernel, //DONE
    input wire signed [7:0] din_kernel
);

    localparam IDLE = 0,
               WAIT_STABLE = 1,
               LOAD_KERNEL = 2,
               WAIT_LOAD_KERNEL = 3,
               WAIT_KERNEL = 4,
               LOAD_PIXEL = 5,
               WAIT_READ_PIXEL = 6,
               WAIT_PIXEL = 7,
               COMPUTE = 8,
               WRITE = 9,
               NEXT = 10,
               FINISH = 11;
    

    reg [3:0] state; //DONE

    reg [4:0] row, col; //DONE
    reg [3:0] pixel_counter; //DONE
    reg [3:0] kernel_counter; //DONE
    reg [8*9-1:0] pixel_bus; //DONE
    reg [8*9-1:0] kernel_weights; //DONE
    reg signed [31:0] reg_conv_out; //DONE //Thanh ghi de chot gia tri conv_out moi lan ghi.
    
    wire signed [31:0] conv_out;

    convolution_unit conv_unit (
        .pixel_bus(pixel_bus),
        .kernel_weights(kernel_weights),
        .conv_out(conv_out)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            done <= 0;
            addr_read <= 0;
            addr_write <= 0;
            dout_write <= 0;
            we_write <= 0;
            addr_kernel <= 0;
            row <= 0;
            col <= 0;
            pixel_counter <= 0;
            kernel_counter <= 0;
            pixel_bus <= 0;
            kernel_weights <= 0;
            reg_conv_out <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    row <= 0;
                    col <= 0;
                    pixel_counter <= 0;
                    kernel_counter <= 0;
                    we_write <= 0;
                    if (start)
                        state <= WAIT_STABLE;
                end
                
                WAIT_STABLE: begin
                    state <= LOAD_KERNEL;
                end
    
                LOAD_KERNEL: begin
                    addr_kernel <= kernel_id * 9 + kernel_counter;
                    state <= WAIT_LOAD_KERNEL;
                end
    
                WAIT_LOAD_KERNEL: begin
                    state <= WAIT_KERNEL;
                end
                
                WAIT_KERNEL: begin
                    kernel_weights[(8*9 - 1) - kernel_counter*8 -: 8] <= din_kernel;
                    if (kernel_counter == 8) begin
                        kernel_counter <= 0;
                        state <= LOAD_PIXEL;
                    end else begin
                        kernel_counter <= kernel_counter + 1;
                        state <= LOAD_KERNEL;
                    end
                end
    
                    LOAD_PIXEL: begin
                        case (pixel_counter)
                            0: addr_read <= row * 30 + col;
                            1: addr_read <= row * 30 + col + 1;
                            2: addr_read <= row * 30 + col + 2;
                            3: addr_read <= (row + 1) * 30 + col;
                            4: addr_read <= (row + 1) * 30 + col + 1;
                            5: addr_read <= (row + 1) * 30 + col + 2;
                            6: addr_read <= (row + 2) * 30 + col;
                            7: addr_read <= (row + 2) * 30 + col + 1;
                            8: addr_read <= (row + 2) * 30 + col + 2;
                        endcase
                        state <= WAIT_READ_PIXEL; // mới thêm
                    end
                
                /*LUU Y: BAT CU GIAO TIEP NAO VOI BRAM, O LOAD PIXEL LA THAY DOI DIA CHI
                DE READ, THI CAN 1 CHU KY XUNG DE CAP NHAT DIA CHI. addr_read DONG` THOI`, BRAM CAN` 
                1 CHU KY XUNG DE CAP NHAT DU LIEU VAO dout THI KHI DO din_read MOI CO GIA TRI.
                CHO NEN PHAI CO 1 STATE DOI BRAM DUA DU LIEU RA, O DAY LA WAIT_READ_PIXEL! */
                    WAIT_READ_PIXEL: begin
                        state <= WAIT_PIXEL;
                    end
                
                    WAIT_PIXEL: begin
                        pixel_bus[(8*9 - 1) - pixel_counter*8 -: 8] <= din_read;
                        if (pixel_counter == 8) begin
                            pixel_counter <= 0;
                            state <= COMPUTE;
                        end else begin
                            pixel_counter <= pixel_counter + 1;
                            state <= LOAD_PIXEL;
                        end
                    end 
    
                
    
    
                    COMPUTE: begin
                        reg_conv_out <= conv_out;
                        state <= WRITE;
                        //========= DUNG CHO DEBUG ============
    //                    $display("==== DEBUG ====");
    //                    $display("Time: %0t", $time);
    //                    $display("kernel_id = %0d", kernel_id);
    //                    $display("pixel_bus = %h", pixel_bus);
    //                    $display("kernel_weights = %h", kernel_weights);
    //                    $display("conv_out = %0d", conv_out);
                    end
                
    
                WRITE: begin
                    addr_write <= row * 28 + col;
                    dout_write <= reg_conv_out;  // dùng kết quả đã chốt
                    we_write <= 1;
                    state <= NEXT;
    
                end
    
    
    
                NEXT: begin
                    we_write <= 0;
                    if (row == 27 && col == 27) begin
                        state <= FINISH;
                    end else begin
                        if (col == 27) begin
                            col <= 0;
                            row <= row + 1;
                        end else begin
                            col <= col + 1;
                        end
                        state <= LOAD_PIXEL;
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










