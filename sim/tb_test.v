`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/03/2025 07:09:49 PM
// Design Name: 
// Module Name: tb_test
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


module tb_test;
    reg reset = 0;
    reg clk = 0;
    reg lock_pixel = 0;
    reg signed [7:0] pixel = 0;
    wire ready, calculating;
    wire [3:0] predict;

    // Instantiate DUT
    top_cnn dut (
        .clk(clk),
        .reset(reset),
        .lock_pixel(lock_pixel),
        .pixel(pixel),
        .ready(ready),
        .calculating(calculating),
        .predict(predict)
    );

    // Clock generation: 100 MHz
    always #5 clk = ~clk;

    // Load image
    reg signed [7:0] image [0:783];
    integer i, img_index;
    integer file;

    // Tạo tên file từ index
    task load_image(input integer idx);
        reg [255*8:0] filename;
        begin
            $sformat(filename, "data/MNIST_Images/image_%04d_bin.txt", idx);
            $readmemb(filename, image);
        end
    endtask

    integer max_images = 1000;
    reg [255*8:0] out_csv_path;

    initial begin
        out_csv_path = "results/predict_output.csv";
        if ($value$plusargs("OUT_CSV=%s", out_csv_path)) begin
            $display("[INFO] Output CSV will be written to: %0s", out_csv_path);
        end
        if ($value$plusargs("NUM_IMAGES=%d", max_images)) begin
            $display("[INFO] Running with NUM_IMAGES = %0d", max_images);
        end else begin
            max_images = 1000;
        end

        #10 @(posedge clk);
        $display("[INFO] Da gui tin hieu reset de bat dau padding tai thoi diem %0t", $time);
        reset = 1;
        @(posedge clk);
        reset = 0;
        
        // Mở file CSV để ghi kết quả
        file = $fopen(out_csv_path, "w");
        if (!file) begin
            $display("[ERROR] Khong mo duoc file: %0s!", out_csv_path);
            $finish;
        end
        $fwrite(file, "ImageIndex,Predict\n"); // Header

        // Lặp qua max_images ảnh từ image_0000
        for (img_index = 0; img_index < max_images; img_index = img_index + 1) begin
            if (img_index % 100 == 0 || img_index == max_images - 1) begin
                $display("[PROGRESS] Simulating image %0d / %0d...", img_index, max_images);
            end
            i = 0;
            load_image(img_index);
            

            // Đợi hệ thống sẵn sàng
            wait (ready == 1);

            // Gửi từng pixel
            while (i < 784) begin
                @(posedge clk);
                if (ready) begin
                    pixel <= image[i];
                    lock_pixel <= 1;
                    @(posedge clk);
                    lock_pixel <= 0;
                    i = i + 1;
                    wait (ready == 1);
                end
            end

            // Đợi tính toán
            wait (calculating == 1);
            wait (calculating == 0);

            $fwrite(file, "%0d,%0d\n", img_index, predict);
        end

        $fclose(file);
        $display("\n[INFO] Simulation complete for %0d images. Results in: %0s", max_images, out_csv_path);
        $finish;
    end

endmodule
