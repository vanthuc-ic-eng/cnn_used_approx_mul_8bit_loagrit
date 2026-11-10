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
// Description: Top-level CNN module connecting all submodules
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module top_cnn (
    input  wire              clk,
    input  wire              reset,
    input  wire              lock_pixel,
    input  wire signed [7:0] pixel,
    output reg               ready,
    output reg               calculating,
    output wire        [3:0] predict
);

    // Signal Naming Convention:
    //   DIN  : Data input to the respective submodule
    //   DOUT : Data output from the respective submodule       

    // =========================================================================
    // 1. Interconnect Wires
    // =========================================================================

    // --- PRE_PROCESSING: WRITE-ONLY (TO 30x30x8) ---
    wire        [9:0] addr_write_pre_processing;
    wire signed [7:0] dout_write_pre_processing;
    wire              we_write_pre_processing;

    // --- CONVOLUTION_KERNEL: READ-ONLY (FROM 30x30x8), WRITE-ONLY (TO 28x28x32) ---
    wire        [9:0]  addr_read_convolution_kernel;
    wire signed [7:0]  din_read_convolution_kernel;
    wire        [9:0]  addr_write_convolution_kernel;
    wire signed [31:0] dout_write_convolution_kernel;
    wire               we_write_convolution_kernel;

    // --- RELU_BRAM: READ-WRITE (28x28x32) ---
    wire        [9:0]  addr_read_write_relu_bram;
    wire signed [31:0] din_read_write_relu_bram;
    wire signed [31:0] dout_read_write_relu_bram;
    wire               we_read_write_relu_bram;

    // --- REQUANTIZER: READ-ONLY (FROM 28x28x32), WRITE-ONLY (TO 28x28x8) ---
    wire        [9:0]  addr_read_write_requantizer;
    wire signed [31:0] din_read_requantizer;
    wire signed [7:0]  dout_write_requantizer;
    wire               we_write_requantizer;

    // --- MAX_POOLING: READ-ONLY (FROM 28x28x8), WRITE-ONLY (TO 9x9x4x8) ---
    wire        [9:0] addr_read_max_pooling;
    wire signed [7:0] din_read_max_pooling;
    wire        [8:0] addr_write_max_pool;
    wire signed [7:0] dout_write_max_pool;
    wire              we_write_max_pool;

    // --- DENSE: READ-ONLY (FROM 9x9x4x8) ---
    wire        [8:0] addr_read_dense;
    wire signed [7:0] din_read_dense;

    // --- ROM ---
    wire        [5:0]  addr_conv2d_kernel_rom;
    wire signed [7:0]  data_conv2d_kernel_rom;
    wire        [11:0] addr_dense_weights_rom;
    wire signed [7:0]  data_dense_weights_rom;

    // =========================================================================
    // 2. FSM States & Internal Registers
    // =========================================================================
    localparam IDLE              = 0,
               WAIT_PIXEL        = 1,
               WRITE_PIXEL       = 2,
               CONVOLUTION_STATE = 3,
               RELU_STATE        = 4,
               REQUANTIZE_STATE  = 5,
               MAXPOOL_STATE     = 6,
               DENSE_STATE       = 7;

    reg [3:0]        state;
    reg              convolution;
    reg              relu;
    reg              requantize;
    reg              maxpool;
    reg              dens;
    reg [1:0]        kernel_counter;

    // Internal signals
    wire [1:0]        kernel_id;
    reg  signed [7:0] current_pixel;
    reg               write_pixel;
    reg               lock_pixel_prev;
    wire              done_write;
    wire              done_padding;
    wire              got_full_image;
    wire              done_pre_processing;
    wire              done_convolution_kernel;
    wire              done_max_pooling_3x3;
    wire              done_requantizer;
    wire              done_relu_bram;
    wire              done_all_controller;
    wire              start_kernel;
    wire              dense_done;

    // =========================================================================
    // 3. BRAM Interface Buses
    // =========================================================================

    // --- BRAM_IMAGE_30x30x8 ---
    wire              we_bram_image_30x30x8;
    wire        [9:0] addr_bram_image_30x30x8;
    wire signed [7:0] din_bram_image_30x30x8;
    wire signed [7:0] dout_bram_image_30x30x8;

    // --- BRAM_OUTPUT_28x28x32 ---
    wire               we_bram_output_28x28x32;
    wire        [9:0]  addr_bram_output_28x28x32;
    wire signed [31:0] din_bram_output_28x28x32;
    wire signed [31:0] dout_bram_output_28x28x32;

    // --- BRAM_OUTPUT_28x28x8 ---
    wire              we_bram_output_28x28x8;
    wire        [9:0] addr_bram_output_28x28x8;
    wire signed [7:0] din_bram_output_28x28x8;
    wire signed [7:0] dout_bram_output_28x28x8;

    // --- BRAM_FLATTEN_9x9x4x8 ---
    wire              we_bram_flatten_9x9x4x8;
    wire        [8:0] addr_bram_flatten_9x9x4x8;
    wire signed [7:0] din_bram_flatten_9x9x4x8;
    wire signed [7:0] dout_bram_flatten_9x9x4x8;

    // =========================================================================
    // 4. Signals Sequentially Connect to BRAMs (Multiplexing Logic)
    // =========================================================================

    // --- IMAGE 30x30x8 ---
    assign we_bram_image_30x30x8       = we_write_pre_processing;
    assign addr_bram_image_30x30x8     = (convolution == 1'b1) ? addr_read_convolution_kernel
                                                               : addr_write_pre_processing;
    assign din_bram_image_30x30x8      = dout_write_pre_processing;
    assign din_read_convolution_kernel = dout_bram_image_30x30x8;

    // --- BRAM_OUTPUT_28x28x32 ---
    assign we_bram_output_28x28x32     = (relu == 1'b1) ? we_read_write_relu_bram
                                                        : we_write_convolution_kernel;
    assign addr_bram_output_28x28x32   = (requantize == 1'b1) ? addr_read_write_requantizer
                                       : (relu == 1'b1)       ? addr_read_write_relu_bram
                                                              : addr_write_convolution_kernel;
    assign din_bram_output_28x28x32    = (relu == 1'b1) ? dout_read_write_relu_bram
                                                        : dout_write_convolution_kernel;
    assign din_read_requantizer        = (requantize == 1'b1) ? dout_bram_output_28x28x32 : 32'b0;
    assign din_read_write_relu_bram    = (relu == 1'b1)       ? dout_bram_output_28x28x32 : 32'b0;

    // --- BRAM_OUTPUT_28x28x8 ---
    assign we_bram_output_28x28x8      = we_write_requantizer;
    assign addr_bram_output_28x28x8    = (maxpool == 1'b1) ? addr_read_max_pooling
                                                           : addr_read_write_requantizer;
    assign din_bram_output_28x28x8     = dout_write_requantizer;
    assign din_read_max_pooling        = dout_bram_output_28x28x8;

    // --- BRAM_FLATTEN_9x9x4x8 ---
    assign we_bram_flatten_9x9x4x8     = we_write_max_pool;
    assign addr_bram_flatten_9x9x4x8   = (dens == 1'b1) ? addr_read_dense
                                                        : addr_write_max_pool;
    assign din_bram_flatten_9x9x4x8    = dout_write_max_pool;
    assign din_read_dense              = dout_bram_flatten_9x9x4x8;

    // =========================================================================
    // 5. FSM
    // =========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state           <= IDLE;
            ready           <= 0;
            calculating     <= 0;
            convolution     <= 0;
            relu            <= 0;
            requantize      <= 0;
            maxpool         <= 0;
            dens            <= 0;
            kernel_counter  <= 0;
            current_pixel   <= 0;
            write_pixel     <= 0;
            lock_pixel_prev <= 0;
        end else begin
            lock_pixel_prev <= lock_pixel;
            case (state)
                IDLE: begin
                    ready          <= 0;
                    calculating    <= 0;
                    write_pixel    <= 0;
                    kernel_counter <= 0;
                    convolution    <= 0;
                    relu           <= 0;
                    requantize     <= 0;
                    maxpool        <= 0;
                    dens           <= 0;
                    if (done_padding) begin
                        ready <= 1;
                        state <= WAIT_PIXEL;
                    end
                end

                WAIT_PIXEL: begin
                    write_pixel <= 0;
                    if (lock_pixel && !lock_pixel_prev) begin
                        current_pixel <= pixel;
                        ready         <= 0;
                        write_pixel   <= 1;
                        state         <= WRITE_PIXEL;
                    end
                end

                WRITE_PIXEL: begin
                    write_pixel <= 0;
                    if (got_full_image) begin
                        ready       <= 0;
                        calculating <= 1;
                        state       <= CONVOLUTION_STATE;
                    end else if (done_write) begin
                        ready <= 1;
                        state <= WAIT_PIXEL;
                    end
                end

                CONVOLUTION_STATE: begin
                    if (start_kernel)
                        convolution <= 1;
                    else if (done_convolution_kernel) begin
                        convolution <= 0;
                        relu        <= 1;
                        state       <= RELU_STATE;
                    end
                end

                RELU_STATE: begin
                    if (done_relu_bram) begin
                        relu       <= 0;
                        requantize <= 1;
                        state      <= REQUANTIZE_STATE;
                    end
                end

                REQUANTIZE_STATE: begin
                    if (done_requantizer) begin
                        requantize <= 0;
                        maxpool    <= 1;
                        state      <= MAXPOOL_STATE;
                    end
                end

                MAXPOOL_STATE: begin
                    if (done_all_controller) begin
                        dens    <= 1;
                        maxpool <= 0;
                        state   <= DENSE_STATE;
                    end else if (done_max_pooling_3x3) begin
                        maxpool <= 0;
                        if (kernel_counter < 3) begin
                            kernel_counter <= kernel_counter + 1;
                            state          <= CONVOLUTION_STATE;
                        end
                        // kernel_counter tracks kernel iterations (0 to 3) before transitioning to DENSE_STATE.
                        // This evaluation resolves the 2-cycle latency offset between done_max_pooling_3x3 and done_all_controller.
                    end
                end

                DENSE_STATE: begin
                    if (dense_done) begin
                        dens           <= 0;
                        kernel_counter <= 0;
                        calculating    <= 0;
                        ready          <= 1;
                        state          <= WAIT_PIXEL;
                    end
                end
            endcase
        end
    end

    // =========================================================================
    // 6. Module Instantiations
    // =========================================================================

    pre_processing pre (
        .clk            (clk),
        .reset          (reset),
        .start          (1'b1),
        .pixel          (current_pixel),
        .write          (write_pixel),
        .done           (done_pre_processing),
        .done_write     (done_write),
        .done_padding   (done_padding),
        .got_full_image (got_full_image),
        .we             (we_write_pre_processing),
        .addr           (addr_write_pre_processing),
        .dout           (dout_write_pre_processing)
    );

    controller ctrl (
        .clk            (clk),
        .reset          (reset),
        .start          (done_pre_processing),
        .done_maxpool   (done_max_pooling_3x3),
        .kernel_id      (kernel_id),
        .start_kernel   (start_kernel),
        .done_all       (done_all_controller)
    );

    convolution_kernel conv (
        .clk            (clk),
        .reset          (reset),
        .start          (start_kernel),
        .kernel_id      (kernel_id),
        .done           (done_convolution_kernel),
        .addr_read      (addr_read_convolution_kernel),
        .din_read       (din_read_convolution_kernel),
        .addr_write     (addr_write_convolution_kernel),
        .dout_write     (dout_write_convolution_kernel),
        .we_write       (we_write_convolution_kernel),
        .addr_kernel    (addr_conv2d_kernel_rom),
        .din_kernel     (data_conv2d_kernel_rom)
    );

    relu_bram relu_activation (
        .clk            (clk),
        .reset          (reset),
        .start          (done_convolution_kernel),
        .done           (done_relu_bram),
        .addr           (addr_read_write_relu_bram),
        .din            (din_read_write_relu_bram),
        .dout           (dout_read_write_relu_bram),
        .we             (we_read_write_relu_bram)
    );

    requantizer rq (
        .clk            (clk),
        .reset          (reset),
        .start          (done_relu_bram),
        .done           (done_requantizer),
        .addr           (addr_read_write_requantizer),
        .din            (din_read_requantizer),
        .we             (we_write_requantizer),
        .dout           (dout_write_requantizer)
    );

    max_pooling_3x3 max_pooling_layer (
        .clk            (clk),
        .reset          (reset),
        .start          (done_requantizer),
        .kernel_id      (kernel_id),
        .done           (done_max_pooling_3x3),
        .addr_read      (addr_read_max_pooling),
        .din_read       (din_read_max_pooling),
        .addr_write     (addr_write_max_pool),
        .dout_write     (dout_write_max_pool),
        .we_write       (we_write_max_pool)
    );

    dense dense_layer (
        .clk            (clk),
        .reset          (reset),
        .start          (done_all_controller),
        .predict        (predict),
        .done           (dense_done),
        .addr_read      (addr_read_dense),
        .din_read       (din_read_dense),
        .addr_weights   (addr_dense_weights_rom),
        .din_weights    (data_dense_weights_rom)
    );

    // =========================================================================
    // 7. BRAM Instantiations
    // =========================================================================

    bram_image_30x30x8 img_padded_bram (
        .clk            (clk),
        .we             (we_bram_image_30x30x8),
        .addr           (addr_bram_image_30x30x8),
        .din            (din_bram_image_30x30x8),
        .dout           (dout_bram_image_30x30x8)
    );

    bram_output_28x28x32 bram_28x28x32 (
        .clk            (clk),
        .we             (we_bram_output_28x28x32),
        .addr           (addr_bram_output_28x28x32),
        .din            (din_bram_output_28x28x32),
        .dout           (dout_bram_output_28x28x32)
    );

    bram_output_28x28x8 bram_28x28x8 (
        .clk            (clk),
        .we             (we_bram_output_28x28x8),
        .addr           (addr_bram_output_28x28x8),
        .din            (din_bram_output_28x28x8),
        .dout           (dout_bram_output_28x28x8)
    );

    bram_flatten_9x9x4x8 flatten_bram (
        .clk            (clk),
        .we             (we_bram_flatten_9x9x4x8),
        .addr           (addr_bram_flatten_9x9x4x8),
        .din            (din_bram_flatten_9x9x4x8),
        .dout           (dout_bram_flatten_9x9x4x8)
    );

    // =========================================================================
    // 8. ROM Instantiations
    // =========================================================================

    conv2d_kernel_rom conv_rom (
        .clk            (clk),
        .addr           (addr_conv2d_kernel_rom),
        .data           (data_conv2d_kernel_rom)
    );

    dense_weights_rom dense_rom (
        .clk            (clk),
        .addr           (addr_dense_weights_rom),
        .data           (data_dense_weights_rom)
    );

endmodule
