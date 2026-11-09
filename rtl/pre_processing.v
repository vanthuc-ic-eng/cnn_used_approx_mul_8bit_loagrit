`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2025 12:54:39 AM
// Design Name: 
// Module Name: pre_processing
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


module pre_processing (
    input wire clk,
    input wire reset,
    input wire start, // Tín hiệu Start từ module Top gửi đến.
    input wire signed [7:0] pixel, // Dữ liệu pixel được locked từ bên ngoài
    input wire write,              // Tín hiệu ghi pixel mới
    output reg done_write, //DONE       // Báo đã ghi xong 1 pixel
    output reg done_padding, //DONE
    output reg got_full_image, //DONE    // Báo đã ghi đủ 784 pixel
    output reg done, //DONE

    output reg we, //DONE
    output reg [9:0] addr, //DONE
    output reg signed [7:0] dout //DONE
);

    localparam IDLE = 0,
               WAIT_STABLE = 1,
               SET_PAD = 2,
               WRITE_PAD = 3,
               WAIT_PIXEL = 4,
               WRITE_PIXEL = 5,
               CHECK_FULL_IMAGE = 6,
               FINISH = 7;

    reg [2:0] state; //DONE //DAM BAO KHI TAT FPGA VA MO LAI THI STATE VE IDLE
    reg [9:0] i; //DONE
    reg [9:0] pad_index; //DONE

    wire [5:0] row = i / 28;
    wire [5:0] col = i % 28;
    wire [9:0] padded_addr = (row + 1) * 30 + (col + 1);

    // List of padding addresses
    function [9:0] get_pad_addr;
        input [9:0] idx;
        begin
            case (idx)
                0: get_pad_addr = 10'd0;
                1: get_pad_addr = 10'd1;
                2: get_pad_addr = 10'd2;
                3: get_pad_addr = 10'd3;
                4: get_pad_addr = 10'd4;
                5: get_pad_addr = 10'd5;
                6: get_pad_addr = 10'd6;
                7: get_pad_addr = 10'd7;
                8: get_pad_addr = 10'd8;
                9: get_pad_addr = 10'd9;
                10: get_pad_addr = 10'd10;
                11: get_pad_addr = 10'd11;
                12: get_pad_addr = 10'd12;
                13: get_pad_addr = 10'd13;
                14: get_pad_addr = 10'd14;
                15: get_pad_addr = 10'd15;
                16: get_pad_addr = 10'd16;
                17: get_pad_addr = 10'd17;
                18: get_pad_addr = 10'd18;
                19: get_pad_addr = 10'd19;
                20: get_pad_addr = 10'd20;
                21: get_pad_addr = 10'd21;
                22: get_pad_addr = 10'd22;
                23: get_pad_addr = 10'd23;
                24: get_pad_addr = 10'd24;
                25: get_pad_addr = 10'd25;
                26: get_pad_addr = 10'd26;
                27: get_pad_addr = 10'd27;
                28: get_pad_addr = 10'd28;
                29: get_pad_addr = 10'd29;
                30: get_pad_addr = 10'd30;
                31: get_pad_addr = 10'd59;
                32: get_pad_addr = 10'd60;
                33: get_pad_addr = 10'd89;
                34: get_pad_addr = 10'd90;
                35: get_pad_addr = 10'd119;
                36: get_pad_addr = 10'd120;
                37: get_pad_addr = 10'd149;
                38: get_pad_addr = 10'd150;
                39: get_pad_addr = 10'd179;
                40: get_pad_addr = 10'd180;
                41: get_pad_addr = 10'd209;
                42: get_pad_addr = 10'd210;
                43: get_pad_addr = 10'd239;
                44: get_pad_addr = 10'd240;
                45: get_pad_addr = 10'd269;
                46: get_pad_addr = 10'd270;
                47: get_pad_addr = 10'd299;
                48: get_pad_addr = 10'd300;
                49: get_pad_addr = 10'd329;
                50: get_pad_addr = 10'd330;
                51: get_pad_addr = 10'd359;
                52: get_pad_addr = 10'd360;
                53: get_pad_addr = 10'd389;
                54: get_pad_addr = 10'd390;
                55: get_pad_addr = 10'd419;
                56: get_pad_addr = 10'd420;
                57: get_pad_addr = 10'd449;
                58: get_pad_addr = 10'd450;
                59: get_pad_addr = 10'd479;
                60: get_pad_addr = 10'd480;
                61: get_pad_addr = 10'd509;
                62: get_pad_addr = 10'd510;
                63: get_pad_addr = 10'd539;
                64: get_pad_addr = 10'd540;
                65: get_pad_addr = 10'd569;
                66: get_pad_addr = 10'd570;
                67: get_pad_addr = 10'd599;
                68: get_pad_addr = 10'd600;
                69: get_pad_addr = 10'd629;
                70: get_pad_addr = 10'd630;
                71: get_pad_addr = 10'd659;
                72: get_pad_addr = 10'd660;
                73: get_pad_addr = 10'd689;
                74: get_pad_addr = 10'd690;
                75: get_pad_addr = 10'd719;
                76: get_pad_addr = 10'd720;
                77: get_pad_addr = 10'd749;
                78: get_pad_addr = 10'd750;
                79: get_pad_addr = 10'd779;
                80: get_pad_addr = 10'd780;
                81: get_pad_addr = 10'd809;
                82: get_pad_addr = 10'd810;
                83: get_pad_addr = 10'd839;
                84: get_pad_addr = 10'd840;
                85: get_pad_addr = 10'd869;
                86: get_pad_addr = 10'd870;
                87: get_pad_addr = 10'd871;
                88: get_pad_addr = 10'd872;
                89: get_pad_addr = 10'd873;
                90: get_pad_addr = 10'd874;
                91: get_pad_addr = 10'd875;
                92: get_pad_addr = 10'd876;
                93: get_pad_addr = 10'd877;
                94: get_pad_addr = 10'd878;
                95: get_pad_addr = 10'd879;
                96: get_pad_addr = 10'd880;
                97: get_pad_addr = 10'd881;
                98: get_pad_addr = 10'd882;
                99: get_pad_addr = 10'd883;
                100: get_pad_addr = 10'd884;
                101: get_pad_addr = 10'd885;
                102: get_pad_addr = 10'd886;
                103: get_pad_addr = 10'd887;
                104: get_pad_addr = 10'd888;
                105: get_pad_addr = 10'd889;
                106: get_pad_addr = 10'd890;
                107: get_pad_addr = 10'd891;
                108: get_pad_addr = 10'd892;
                109: get_pad_addr = 10'd893;
                110: get_pad_addr = 10'd894;
                111: get_pad_addr = 10'd895;
                112: get_pad_addr = 10'd896;
                113: get_pad_addr = 10'd897;
                114: get_pad_addr = 10'd898;
                115: get_pad_addr = 10'd899;
                default: get_pad_addr = 10'd0;
            endcase
        end
    endfunction

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            done_write <= 0;
            done_padding <= 0;
            got_full_image <= 0;
            done <= 0;
            we <= 0;
            addr <= 0;
            dout <= 0;
            i <= 0;
            pad_index <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    got_full_image <= 0;
                    done_write <= 0;
                    done_padding <= 0;
                    we <= 0;
                    addr <= 0;
                    i <= 0;
                    pad_index <= 0;
                    if (start)
                        state <= WAIT_STABLE;
                end
                
                WAIT_STABLE: begin
                    state <= SET_PAD;
                end
    
                SET_PAD: begin
                    addr <= get_pad_addr(pad_index);
                    dout <= 0;
                    we <= 1;
                    state <= WRITE_PAD;
                end
    
                WRITE_PAD: begin
                    we <= 0;
                    if (pad_index == 115) begin
                        done_padding <= 1;
                        state <= WAIT_PIXEL;
                        end
                    else begin
                        pad_index <= pad_index + 1;
                        state <= SET_PAD;
                    end
                end
                
                
                WAIT_PIXEL: begin
                    done <= 0;
                    done_padding <= 0;
                    done_write <= 0;
                    if (write) begin
                        addr <= (i / 28 + 1) * 30 + (i % 28 + 1);
                        dout <= pixel;
                        state <= WRITE_PIXEL;
                    end
                end
    
                WRITE_PIXEL: begin
                    we <= 1;
                    state <= CHECK_FULL_IMAGE;
                end
    
    
                CHECK_FULL_IMAGE: begin
                    we <= 0;
                    done_write <= 1;
                    if (i == 783) begin
                        got_full_image <= 1;
                        state <= FINISH;
                    end else begin
                        i <= i + 1;
                        state <= WAIT_PIXEL;
                    end
                end
    
                FINISH: begin
                    done <= 1;
                    done_write <= 0;
                    got_full_image <= 0;
                    i <= 0;
                    
                    state <= WAIT_PIXEL;
                end
            endcase
       end
    end
endmodule




