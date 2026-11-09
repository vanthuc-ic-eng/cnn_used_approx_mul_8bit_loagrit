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
            $sformat(filename, "<...>/MNIST_Images/image_%04d_bin.txt", idx);
//            $display("\n[INFO] Loading image from file: %s", filename);
            $readmemb(filename, image);
        end
    endtask

    initial begin
        #10 @(posedge clk);
        $display("[INFO] Da gui tin hieu reset de bat dau padding tai thoi diem %0t", $time);
        reset = 1;
        @(posedge clk);
        reset = 0;
        
        // Mở file CSV để ghi kết quả
        file = $fopen("D:/<...>.csv", "w");
        if (!file) begin
//            $display("[ERROR] Khong mo duoc file output!");
            $finish;
        end
        $fwrite(file, "ImageIndex,Predict\n"); // Header

        // Lặp qua 1000 ảnh từ image_0000 đến image_0999
        for (img_index = 0; img_index < 1000; img_index = img_index + 1) begin
            i = 0;
            load_image(img_index);
            

            // Đợi hệ thống sẵn sàng
            wait (ready == 1);
//            $display("[INFO] Ready to receive image %0d at time %0t", img_index, $time);

            // Gửi từng pixel (logic đúng như bạn mong muốn)
            while (i < 784) begin
                @(posedge clk);
                if (ready) begin
                    pixel <= image[i];
                    lock_pixel <= 1;
                    @(posedge clk);
                    lock_pixel <= 0;
//                    $display("[PIXEL] image[%0d] = %0d tại %0t", i, image[i], $time);
                    i = i + 1;
                    wait (ready == 1); // Đợi tín hiệu ready được bật lại sau mỗi pixel
                end
            end

            // Đợi tính toán
//            $display("[INFO] Sent full image %0d, waiting for prediction...", img_index);
            wait (calculating == 1);
            wait (calculating == 0);

//            $display("[PREDICT] image %0d → %0d tại thời điểm %0t", img_index, predict, $time);
            $fwrite(file, "%0d,%0d\n", img_index, predict);
        end

        $fclose(file);
//        $display("\n[INFO] Đã mô phỏng xong 1000 ảnh. File kết quả: results/predict_output.csv");
        $finish;
    end

endmodule
