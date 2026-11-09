`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2025 04:44:51 AM
// Design Name: 
// Module Name: top_cnn
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


// Top-level CNN module connecting all submodules
module top_cnn(
    input wire clk,
    input wire reset,
    input wire lock_pixel,
    input wire signed [7:0] pixel,
    output reg ready, calculating, //DONE
    output wire [3:0] predict
);
    /*QUY UOC: DIN la DATA vao Module do'
               DOUT la DATA ra khoi Module do'
   */
    /* Assign a = b Khac' Assign b = a
    
    assign <output> = <nguon dieu khien>
    VD: assign a = b nghia la a bi dieu khien boi b
        assign b = a nghia la b bi dieu khien boi a
    => assign khong phai la 2 chieu, ma la 1 CHIEU`
    */       
    
    //===========================PRE_PROCESSING=============================
        //WRITE-ONLY (TO 30x30x8)
    wire [9:0] addr_write_pre_processing;
    wire signed [7:0] dout_write_pre_processing;
    wire we_write_pre_processing;
    //=======================================================================
    
    //==========================CONVOLUTION_KERNEL===========================
        //READ-ONLY (FROM 30x30x8)
    wire [9:0] addr_read_convolution_kernel;
    wire signed [7:0] din_read_convolution_kernel;
    
        //WRITE-ONLY (TO 28x28x32)
    wire [9:0] addr_write_convolution_kernel;
    wire signed [31:0] dout_write_convolution_kernel;
    wire we_write_convolution_kernel;

    //=======================================================================
    
    
    //==============================RELU_BRAM=================================
        //READ-WRITE
    wire [9:0] addr_read_write_relu_bram;
    wire signed [31:0] din_read_write_relu_bram, dout_read_write_relu_bram;
    wire we_read_write_relu_bram;    
    //========================================================================
    
    
    //===========================REQUANTIZER==================================
    wire [9:0] addr_read_write_requantizer;
        //WRITE-ONLY (TO 28x28x8)
    wire signed [7:0] dout_write_requantizer;
    wire we_write_requantizer;

    
        //READ-ONLY (FROM 28x28x32)
    wire signed [31:0] din_read_requantizer;
 
    //=======================================================================
    
    
    //==========================MAX_POOLING===========================
        //READ-ONLY (FROM 28x28x8)
    wire [9:0] addr_read_max_pooling;
    wire signed [7:0] din_read_max_pooling;
    
        //WRITE-ONLY (TO 9x9x4x8)
    wire [8:0] addr_write_max_pool;
    wire signed [7:0] dout_write_max_pool;
    wire we_write_max_pool;
    //=======================================================================
    
    
    //===========================DENSE=============================
        //READ-ONLY (FROM 9x9x4x8)
    wire [8:0] addr_read_dense;
    wire signed [7:0] din_read_dense;
    //=======================================================================
    
    
        
    //==========================ROM====================================
    wire [5:0] addr_conv2d_kernel_rom;
    wire [11:0] addr_dense_weights_rom;
    wire signed [7:0] data_conv2d_kernel_rom, data_dense_weights_rom;
    //=================================================================
    
    // FSM states
    localparam IDLE = 0, WAIT_PIXEL = 1, WRITE_PIXEL = 2,
               CONVOLUTION_STATE = 3, RELU_STATE = 4, REQUANTIZE_STATE = 5, 
               MAXPOOL_STATE = 6, DENSE_STATE = 7;
    reg [3:0] state; //DONE
    reg convolution, relu, requantize, maxpool, dens; //DONE
    reg [1:0] kernel_counter; //DONE

    // Internal signals
    wire [1:0] kernel_id;
    reg signed [7:0] current_pixel; //DONE
    reg write_pixel; //DONE
    reg lock_pixel_prev; //DONE
    wire done_write, done_padding, got_full_image;
    wire done_pre_processing, done_convolution_kernel,
        done_max_pooling_3x3, done_requantizer, done_relu_bram,
        done_all_controller, start_kernel, dense_done;
       
    
    //===============BRAM_IMAGE_30x30x8================
    wire we_bram_image_30x30x8;
    wire [9:0] addr_bram_image_30x30x8; 
    wire signed [7:0] din_bram_image_30x30x8;
    wire signed [7:0] dout_bram_image_30x30x8;
    
    //=================================================


    //===============BRAM_OUTPUT_28x28x32================
    wire we_bram_output_28x28x32;
    wire [9:0] addr_bram_output_28x28x32;
    wire signed [31:0] din_bram_output_28x28x32;
    wire signed [31:0] dout_bram_output_28x28x32;  
    
    
    //================================================= 
    
    
    //===============BRAM_OUTPUT_28x28x8================
    wire we_bram_output_28x28x8;
    wire [9:0] addr_bram_output_28x28x8;
    wire signed [7:0] din_bram_output_28x28x8;
    wire signed [7:0] dout_bram_output_28x28x8;
    
    //=================================================
    
    
    //===============BRAM_FLATTEN_9x9x4x8================
    wire we_bram_flatten_9x9x4x8;
    wire [8:0] addr_bram_flatten_9x9x4x8;
    wire signed [7:0] din_bram_flatten_9x9x4x8;
    wire signed [7:0] dout_bram_flatten_9x9x4x8;
      
    //===================================================
    
    //=============================== SIGNALS SEQUENTIALLY CONNECT TO BRAMS =================================
    
            // IMAGE 30x30x8
    assign we_bram_image_30x30x8 = we_write_pre_processing; //DONE
    assign addr_bram_image_30x30x8 = (convolution == 1'b1)? addr_read_convolution_kernel : addr_write_pre_processing; //DONE
    
    // Active Log8-Nano Pixel Encoder: converts INT8 pixels to Log8-Nano before storing in BRAM
    wire [7:0] dout_write_pre_processing_log8;
    active_log8_nano_encoder u_active_pixel_encoder (
        .data_i(dout_write_pre_processing),
        .log8_o(dout_write_pre_processing_log8)
    );
    assign din_bram_image_30x30x8 = dout_write_pre_processing_log8; // Pre-encoded Log8-Nano
    assign din_read_convolution_kernel = dout_bram_image_30x30x8; //DONE
    
    // BRAM_OUTPUT_28x28x32
    assign we_bram_output_28x28x32 = (relu == 1'b1)? we_read_write_relu_bram : we_write_convolution_kernel; //DONE
    assign addr_bram_output_28x28x32 = (requantize == 1'b1)? addr_read_write_requantizer :
                                      (relu == 1'b1)? addr_read_write_relu_bram : addr_write_convolution_kernel; //DONE
    assign din_bram_output_28x28x32 = (relu == 1'b1)? dout_read_write_relu_bram : dout_write_convolution_kernel; //DONE
    assign din_read_requantizer = (requantize == 1'b1)? dout_bram_output_28x28x32 : 32'b0; //DONE
    assign din_read_write_relu_bram = (relu == 1'b1)? dout_bram_output_28x28x32 : 32'b0; //DONE
    // BRAM_OUTPUT_28x28x8
    assign we_bram_output_28x28x8 = we_write_requantizer; //DONE
    assign addr_bram_output_28x28x8 = (maxpool == 1'b1)? addr_read_max_pooling :addr_read_write_requantizer; //DONE
    assign din_bram_output_28x28x8 = dout_write_requantizer; //DONE
    assign din_read_max_pooling = dout_bram_output_28x28x8; //DONE 

    // BRAM_FLATTEN_9x9x4x8
    assign we_bram_flatten_9x9x4x8 = we_write_max_pool; //DONE
    assign addr_bram_flatten_9x9x4x8 = (dens == 1'b1)? addr_read_dense :addr_write_max_pool; //DONE
    assign din_bram_flatten_9x9x4x8 = dout_write_max_pool; //DONE
    assign din_read_dense = dout_bram_flatten_9x9x4x8; //DONE
    
    // =================================================================================================================
    
    //=============FSM====================================
    always @(posedge clk or posedge reset) begin
//        $display("[FSM] clk=%0t, state=%0d, ready=%b, calc=%b, write_pixel=%b, convolution=%b, relu=%b, requantize=%b, maxpool=%b, dens=%b", 
//         $time, state, ready, calculating, write_pixel, convolution, relu, requantize, maxpool, dens);
        if (reset) begin
            state <= IDLE;
            ready <= 0;
            calculating <= 0;
            convolution <= 0;
            relu <= 0;
            requantize <= 0;
            maxpool <= 0;
            dens <= 0;
            kernel_counter <= 0;
            current_pixel <= 0;
            write_pixel <= 0;
            lock_pixel_prev <= 0;
        end else begin
            lock_pixel_prev <= lock_pixel;
            case (state)
                IDLE: begin
                    ready <= 0;
                    calculating <= 0;
                    write_pixel <= 0;
                    kernel_counter <= 0;
                    convolution <= 0;
                    relu <= 0;
                    requantize <= 0;
                    maxpool <= 0;
                    dens <= 0;
                    if (done_padding) begin
                        ready <= 1;
                        state <= WAIT_PIXEL;
                    end
                end
                WAIT_PIXEL: begin
                    write_pixel <= 0;
                    if (lock_pixel && !lock_pixel_prev) begin
                        current_pixel <= pixel;
                        ready <= 0;
                        write_pixel <= 1;
                        state <= WRITE_PIXEL;
                    end
                end
                WRITE_PIXEL: begin
                    write_pixel <= 0;
                    if (got_full_image) begin 
                        ready <= 0;
                        calculating <= 1;
                        state <= CONVOLUTION_STATE;
                    end
                    else if (done_write) begin
                        ready <= 1;
                        state <= WAIT_PIXEL;
                    end
                end
                CONVOLUTION_STATE: begin
                    if (start_kernel)
                        convolution <= 1;
                    else if (done_convolution_kernel) begin
                        convolution <= 0;
                        relu <= 1;
                        state <= RELU_STATE;
                    end
                end
                RELU_STATE: begin
                    if (done_relu_bram) begin
                        relu <= 0;
                        requantize <= 1; 
                        state <= REQUANTIZE_STATE;
                    end
                end
                REQUANTIZE_STATE: begin
                    if (done_requantizer) begin
                        requantize <= 0;
                        maxpool <= 1; 
                        state <= MAXPOOL_STATE;
                    end
                end
                
                MAXPOOL_STATE: begin
                    if (done_all_controller) begin
                        dens <= 1; 
                        maxpool <= 0;
                        state <= DENSE_STATE;
                    end else if (done_max_pooling_3x3) begin
                        maxpool <= 0;
                        if (kernel_counter < 3) begin 
                            kernel_counter <= kernel_counter + 1; 
                            state <= CONVOLUTION_STATE;
                        end
              /* Dung 1 kernel_counter de xet viec co cho ve CONVOLUTION_STATE chay tiep hay khong. Boi vi done_all_controller den muon. hon
              done_max_pooling_3x3 tan. 2 chu ky` xung nen moi phai viet dieu` kien. nhu vay. */
                    end
                end
                
                DENSE_STATE: begin
                    if (dense_done) begin
                        dens <= 0;
                        kernel_counter <= 0; 
                        calculating <= 0;
                        ready <= 1;
                        state <= WAIT_PIXEL;
                    end
                end
            endcase
       end
    end

    
    
    // ---------------- Module Instantiations ----------------


    pre_processing pre (
        .clk(clk), .reset(reset), .start(1'b1), .pixel(current_pixel), .write(write_pixel), .done(done_pre_processing),
        .done_write(done_write), .done_padding(done_padding), .got_full_image(got_full_image),
        .we(we_write_pre_processing), .addr(addr_write_pre_processing), .dout(dout_write_pre_processing)
    );

    controller ctrl (
        .clk(clk), .reset(reset), .start(done_pre_processing), .done_maxpool(done_max_pooling_3x3),
        .kernel_id(kernel_id), .start_kernel(start_kernel), .done_all(done_all_controller)
    );

    convolution_kernel conv (
        .clk(clk), .reset(reset), .start(start_kernel), .kernel_id(kernel_id), .done(done_convolution_kernel),
        .addr_read(addr_read_convolution_kernel), .din_read(din_read_convolution_kernel),
        .addr_write(addr_write_convolution_kernel), .dout_write(dout_write_convolution_kernel), .we_write(we_write_convolution_kernel),
        .addr_kernel(addr_conv2d_kernel_rom), .din_kernel(data_conv2d_kernel_rom)
    );

    relu_bram relu_activation (
        .clk(clk), .reset(reset), .start(done_convolution_kernel), .done(done_relu_bram),
        .addr(addr_read_write_relu_bram), .din(din_read_write_relu_bram), .dout(dout_read_write_relu_bram), .we(we_read_write_relu_bram)
    );

    requantizer rq (
        .clk(clk), .reset(reset), .start(done_relu_bram), .done(done_requantizer),
        .addr(addr_read_write_requantizer), .din(din_read_requantizer), .we(we_write_requantizer), .dout(dout_write_requantizer)
    );

    max_pooling_3x3 max_pooling_layer (
        .clk(clk), .reset(reset), .start(done_requantizer), .kernel_id(kernel_id), .done(done_max_pooling_3x3),
        .addr_read(addr_read_max_pooling), .din_read(din_read_max_pooling),
        .addr_write(addr_write_max_pool), .dout_write(dout_write_max_pool), .we_write(we_write_max_pool)
    );

    dense dense_layer (
        .clk(clk), .reset(reset), .start(done_all_controller), .predict(predict), .done(dense_done),
        .addr_read(addr_read_dense), .din_read(din_read_dense),
        .addr_weights(addr_dense_weights_rom), .din_weights(data_dense_weights_rom)
    );

    // ---------------- BRAM Instantiations ----------------

    bram_image_30x30x8 img_padded_bram (
        .clk(clk), .we(we_bram_image_30x30x8), .addr(addr_bram_image_30x30x8), .din(din_bram_image_30x30x8), .dout(dout_bram_image_30x30x8)
    );

    bram_output_28x28x32 bram_28x28x32 (
        .clk(clk), .we(we_bram_output_28x28x32), .addr(addr_bram_output_28x28x32),
        .din(din_bram_output_28x28x32), .dout(dout_bram_output_28x28x32)
    );

    bram_output_28x28x8 bram_28x28x8 (
        .clk(clk), .we(we_bram_output_28x28x8), .addr(addr_bram_output_28x28x8), .din(din_bram_output_28x28x8), .dout(dout_bram_output_28x28x8)
    );

    bram_flatten_9x9x4x8 flatten_bram (
        .clk(clk), .we(we_bram_flatten_9x9x4x8), .addr(addr_bram_flatten_9x9x4x8), .din(din_bram_flatten_9x9x4x8), .dout(dout_bram_flatten_9x9x4x8)
    );


    //==================ROM==================================
    conv2d_kernel_rom conv_rom (
        .clk(clk), .addr(addr_conv2d_kernel_rom), .data(data_conv2d_kernel_rom)
    );

    dense_weights_rom dense_rom (
        .clk(clk), .addr(addr_dense_weights_rom), .data(data_dense_weights_rom)
    );
    
    
endmodule
