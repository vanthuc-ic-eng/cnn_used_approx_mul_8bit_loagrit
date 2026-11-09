`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2025 07:13:03 PM
// Design Name: 
// Module Name: requantizer
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


module requantizer (
    input wire clk,
    input wire reset,
    input wire start,
    output reg we, //DONE
    output reg [9:0] addr, //DONE
    output reg signed [7:0] dout, //DONE
    input wire signed [31:0] din,
    output reg done //DONE
);
    localparam IDLE = 0, WAIT_STABLE = 1, WAIT_MAX = 2, CALC_SHIFT = 3, /*WAIT_SHIFT = 4,*/
           LOAD = 4, WAIT_READ = 5, COMPUTE = 6, WAIT_COMPUTE = 7, WRITE = 8, NEXT = 9, FINISH = 10;
    reg [3:0] state; //DONE

    reg [9:0] index; //DONE
    reg [31:0] current_val; //DONE
    wire signed [7:0] result_int8;

    wire [31:0] max_val;
    wire max_done;
    reg [31:0] max_val_reg; //DONE
    wire [4:0] log2_max;
    reg [4:0] shift_val; //DONE

    reg max_start; //DONE
    wire [9:0] max_addr;

    assign log2_max = (max_val_reg[31]) ? 32 :
                      (max_val_reg[30]) ? 31 : //Bo? bit cao nhat vi do la bit dau' (Luon bang 0)
                      (max_val_reg[29]) ? 30 :
                      (max_val_reg[28]) ? 29 :
                      (max_val_reg[27]) ? 28 :
                      (max_val_reg[26]) ? 27 :
                      (max_val_reg[25]) ? 26 :
                      (max_val_reg[24]) ? 25 :
                      (max_val_reg[23]) ? 24 :
                      (max_val_reg[22]) ? 23 :
                      (max_val_reg[21]) ? 22 :
                      (max_val_reg[20]) ? 21 :
                      (max_val_reg[19]) ? 20 :
                      (max_val_reg[18]) ? 19 :
                      (max_val_reg[17]) ? 18 :
                      (max_val_reg[16]) ? 17 :
                      (max_val_reg[15]) ? 16 :
                      (max_val_reg[14]) ? 15 :
                      (max_val_reg[13]) ? 14 :
                      (max_val_reg[12]) ? 13 :
                      (max_val_reg[11]) ? 12 :
                      (max_val_reg[10]) ? 11 :
                      (max_val_reg[9])  ? 10 :
                      (max_val_reg[8])  ? 9  :
                      (max_val_reg[7])  ? 8  :
                      (max_val_reg[6])  ? 7  :
                      (max_val_reg[5])  ? 6  :
                      (max_val_reg[4])  ? 5  :
                      (max_val_reg[3])  ? 4  :
                      (max_val_reg[2])  ? 3  :
                      (max_val_reg[1])  ? 2  : 
                      (max_val_reg[0])  ? 1  : 0;

    requantizer_unit core (
        .in_val(current_val),
        .shift(shift_val),
        .out_val(result_int8)
    );

    max_finder max_unit (
        .clk(clk),
        .reset(reset),
        .start(max_start),
        .addr(max_addr),
        .din(din),
        .max_val(max_val),
        .done(max_done)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            we <= 0;
            addr <= 0;
            dout <= 0;
            done <= 0;
            index <= 0;
            current_val <= 0;
            max_val_reg <= 0;
            shift_val <= 0;
            max_start <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    we <= 0;
                    index <= 0;
                    max_start <= 0;
                    if (start) begin
                        state <= WAIT_STABLE;
                    end
                end
                
                WAIT_STABLE: begin
                    max_start <= 1;
                    state <= WAIT_MAX;
                end
                
                WAIT_MAX: begin
                    max_start <= 0;
                    addr <= max_addr; //Requantizer se doc du lieu tai dia chi ma max_finder muon doc.
                    //Boi vi max_addr la soi day noi vao addr cua max_finder va addr cua 
                    //requantizer se duoc cap nhat moi chu ky xung clock la dia chi ma max_finder muon doc 
                    //du lieu trong BRAM. Giong nhu kieu con trai muon noi chuyen voi nguoi ngoai,
                    //thi` dua day^ cho bo', bo' dua cho nguoi ta, nguoi ta phan hoi ve bo, bo truyen` dat. lai cho con.
                    //Do la cach thuc hoat dong.
                    if (max_done) begin
                        max_val_reg <= max_val;
                        state <= CALC_SHIFT;
                    end
                end
                
                CALC_SHIFT: begin
                    shift_val <= (log2_max > 7) ? (log2_max - 7) : 0;
                    state <= LOAD;
                end
                
                
                LOAD: begin
                    addr <= index;
                    state <= WAIT_READ;
                end
                
                WAIT_READ: begin //Doi 1 chu ky de cap nhat addr.
                    state <= COMPUTE;
                end
                
               COMPUTE: begin
                    current_val <= din;   // Gán current_val
                    state <= WAIT_COMPUTE; // Đợi 1 chu kỳ để result_int8 sẵn sàng
                end
                
                WAIT_COMPUTE: begin //Doi 1 chu ky xung de cho requantizer_unit tinh toan truoc khi doc gia tri dau ra cua no.
                    state <= WRITE;
                end
                
                WRITE: begin
                    dout <= result_int8;    // Giờ mới lấy giá trị đúng của result_int8
                    we <= 1;
                    addr <= index;
                    state <= NEXT;
                end
    
                NEXT: begin
                    we <= 0;
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