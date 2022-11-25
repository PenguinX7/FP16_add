`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/23 16:23:45
// Design Name: 
// Module Name: FP16_add
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


module FP16_add(
    input data1,
    input data2,
    input clk,
    input rst,
    input input_valid,
    output data_o,
    output output_update
    );
    
    wire [15:0]data1;
    wire [15:0]data2;
    wire clk;
    wire rst;
    wire input_valid;
    reg [15:0]data_o;
    reg output_update;
    
    reg pre_over;       //for step1:pre_operation
    reg overflow1;
    reg sign_high;
    reg sign_low;
    reg [4:0]exp_high;
    reg [4:0]exp_low;
    reg [22:0]rm_high;
    reg [22:0]rm_low;
    reg align_over;     //for step2:shift to align
    reg overflow2;
    reg sign_high2;
    reg sign_low2;
    reg [4:0]exp_high2;
    reg [4:0]exp_low2;
    reg [22:0]rm_high2;
    reg [22:0]rm_low2;
    reg cal_over;       //for step3:calculate
    reg overflow3;
    reg sign_cache;
    reg [5:0]exp_cache;
    reg [22:0]rm_cache;
    reg norpre_over;     //for step4:normalize_pre
    reg overflow4;
    reg sign_new;
    reg [6:0]exp_new;
    reg [11:0]rm_new;
    reg ifround;
    reg norround_over;   //for step5:normalize_round to nearest even
    reg overflow5;
    reg sign_new2;
    reg [6:0]exp_new2;
    reg [11:0]rm_new2;
    reg norcarry_over;      //for step6:normalize_carry
    reg overflow6;
    reg sign_new3;
    reg [6:0]exp_new3;
    reg [11:0]rm_new3;
    
    //step1:pre_operation
    always @ (posedge clk or posedge rst)   begin
        if(rst) begin                   //rst
            pre_over <= 1'b0;
            overflow1 <= 1'b0;
            sign_high <= 1'b0;
            sign_low <= 1'b0;
            exp_high <= 4'd0;
            exp_low <= 4'd0;
            rm_high <= 23'd0;
            rm_low <= 23'd0;
        end
        else if(input_valid)    begin           //work
            pre_over <= 1'b1;
            if((&data1) || (&data2))    begin
                overflow1 <= 1'b1;
                sign_high <= sign_high;
                sign_low <= sign_low;
                exp_high <= exp_high;
                exp_low <= exp_low;
                rm_high <= rm_high;
                rm_low <= rm_low;
            end
            else begin
                if(data1[14:10] > data2[14:10]) begin
                    exp_high <= data1[14:10];
                    exp_low <= data2[14:10];
                    sign_high <= data1[15];
                    sign_low <= data2[15];
                    rm_high <= {2'b01,data1[9:0],11'd0};
                    if(|data2[14:10])
                        rm_low <= {2'd1,data2[9:0],11'd0};
                    else
                        rm_low <= 23'd0;
                end
                else if(data1[14:10] < data2[14:10])    begin
                    exp_high <= data2[14:10];
                    exp_low <= data1[14:10];
                    sign_high <= data2[15];
                    sign_low <= data1[15];
                    rm_high <= {2'b01,data2[9:0],11'd0};
                    if(|data1[14:10])
                        rm_low <= {2'd1,data1[9:0],11'd0};
                    else
                        rm_low <= 23'd0;
                end
                else if(data1[9:0] > data2[9:0])    begin
                    exp_high <= data1[14:10];
                    exp_low <= data2[14:10];
                    sign_high <= data1[15];
                    sign_low <= data2[15];
                    rm_high <= {2'd1,data1[9:0],11'd0};
                    rm_low <= {2'd1,data2[9:0],11'd0};
                end
                else    begin
                    exp_high <= data2[14:10];
                    exp_low <= data1[14:10];
                    sign_high <= data2[15];
                    sign_low <= data1[15];
                    if(|data1[14:10])   begin
                        rm_high <= {2'b01,data2[9:0],11'd0};
                        rm_low <= {2'b01,data1[9:0],11'd0};
                    end
                    else    begin
                        rm_high <= 23'd0;
                        rm_low <= 23'd0;
                    end
                end
            end
        end
        else    begin               //invalid
            pre_over <= 1'b0;
            overflow1 <= overflow1;
            sign_high <= sign_high;
            sign_low <= sign_low;
            exp_high <= exp_high;
            exp_low <= exp_low;
            rm_high <= rm_high;
            rm_low <= rm_low;
        end
    end
    
    //step2:shift to align
    always@(posedge clk or posedge rst) begin
        if(rst) begin                           //rst
            align_over <= 1'b0;
            overflow2 <= 1'b0;
            sign_high2 <= 1'b0;
            sign_low2 <= 1'b0;
            exp_high2 <= 5'd0;
            exp_low2 <= 5'd0;
            rm_high2 <= 23'd0;
            rm_low2 <= 23'd0;
        end
        else if(pre_over)   begin               //work
            align_over <= 1'b1;
            overflow2 <= overflow1;
            if(overflow1)   begin
                sign_high2 <= sign_high2;
                sign_low2 <= sign_low2;
                exp_high2 <= exp_high2;
                exp_low2 <= exp_low2;
                rm_high2 <= rm_high2;
                rm_low2 <= rm_low2;
            end
            else begin
                sign_high2 <= sign_high;
                sign_low2 <= sign_low;
                exp_high2 <= exp_high;
                exp_low2 <= exp_low;
                rm_high2 <= rm_high;
                case(exp_high - exp_low)
                    5'd0 : rm_low2 <= rm_low;
                    5'd1 : rm_low2 <= rm_low >> 1;
                    5'd2 : rm_low2 <= rm_low >> 2;
                    5'd3 : rm_low2 <= rm_low >> 3;
                    5'd4 : rm_low2 <= rm_low >> 4;
                    5'd5 : rm_low2 <= rm_low >> 5;
                    5'd6 : rm_low2 <= rm_low >> 6;
                    5'd7 : rm_low2 <= rm_low >> 7;
                    5'd8 : rm_low2 <= rm_low >> 8;
                    5'd9 : rm_low2 <= rm_low >> 9;
                    5'd10 : rm_low2 <= rm_low >> 10;
                    5'd11 : rm_low2 <= rm_low >> 11;
                    5'd12 : rm_low2 <= rm_low >> 12;
                    default  : rm_low2 <= 23'd0;
                endcase 
            end
        end
        else    begin                       //invalid
            align_over <= 1'b0;
            overflow2 <= overflow2;
            sign_high2 <= sign_high2;
            sign_low2 <= sign_low2;
            exp_high2 <= exp_high2;
            exp_low2 <= exp_low2;
            rm_high2 <= rm_high2;
            rm_low2 <= rm_low2;
        end
    end
    
    //step3:calculate
    always @(posedge clk or posedge rst)    begin
        if(rst) begin                           //rst
            cal_over <= 1'b0;
            overflow3 <= 1'b0;
            sign_cache <= 1'b0;
            exp_cache <= 6'd0;
            rm_cache <= 23'd0;
        end
        else if(align_over) begin               //work
            cal_over <= 1'b1;
            overflow3 <= overflow2;
            if(overflow2)   begin
                sign_cache <= sign_cache;
                exp_cache <= exp_cache;
                rm_cache <= rm_cache;
            end
            else    begin
                sign_cache <= sign_high2;
                exp_cache <= exp_high2;
                if(sign_high2 ^ sign_low2)
                    rm_cache <= rm_high2 - rm_low2;
                else
                    rm_cache <= rm_high2 + rm_low2;
            end
        end
        else    begin                           //invalid
            cal_over <= 1'b0;
            overflow3 <= overflow3;
            sign_cache <= sign_cache;
            exp_cache <= exp_cache;
            rm_cache <= rm_cache;
        end
    end
    
    //step4:normalize_pre
    always @(posedge clk or posedge rst)    begin
        if(rst) begin                           //rst
            norpre_over <= 1'b0;
            overflow4 <= 1'b0;
            exp_new <= 7'd0;
            rm_new <= 12'd0;
            sign_new <= 1'b0;
            ifround <= 1'b0;          
        end
        else if(cal_over)   begin               //work
            norpre_over <= 1'b1;
            overflow4 <= overflow3;
            if(overflow3)   begin
                sign_new <= sign_new;
                exp_new <= exp_new;
                rm_new <= rm_new;
                ifround <= ifround;
            end
            else    begin
                sign_new <= sign_cache;
                casex(rm_cache)
                    23'b1xx_xxxx_xxxx_xxxx_xxxx_xxxx : begin
                        exp_new <= exp_cache + 7'd1;
                        rm_new <= {1'b0,rm_cache[22:12]};
                        ifround <= rm_cache[11] & (rm_cache[12] | (|rm_cache[10:0]));
                    end
                    23'b01x_xxxx_xxxx_xxxx_xxxx_xxxx : begin
                        exp_new <= exp_cache;
                        rm_new <= {1'b0,rm_cache[21:11]};
                        ifround <= rm_cache[10] & (rm_cache[11] | (|rm_cache[9:0]));
                    end
                    23'b001_xxxx_xxxx_xxxx_xxxx_xxxx : begin
                        exp_new <= exp_cache - 7'd1;
                        rm_new <= {1'b0,rm_cache[20:10]};
                        ifround <= rm_cache[9] & (rm_cache[10] | (|rm_cache[8:0]));
                    end
                    23'b000_1xxx_xxxx_xxxx_xxxx_xxxx : begin
                        exp_new <= exp_cache - 7'd2;
                        rm_new <= {1'b0,rm_cache[19:9]};
                        ifround <= rm_cache[8] & (rm_cache[9] | (|rm_cache[7:0]));
                    end
                    23'b000_01xx_xxxx_xxxx_xxxx_xxxx : begin
                        exp_new <= exp_cache - 7'd3;
                        rm_new <= {1'b0,rm_cache[18:8]};
                        ifround <= rm_cache[7] & (rm_cache[8] | (|rm_cache[6:0]));
                    end
                    23'b000_001x_xxxx_xxxx_xxxx_xxxx : begin
                        exp_new <= exp_cache - 7'd4;
                        rm_new <= {1'b0,rm_cache[17:7]};
                        ifround <= rm_cache[6] & (rm_cache[7] | (|rm_cache[5:0]));
                    end
                    23'b000_0001_xxxx_xxxx_xxxx_xxxx : begin
                        exp_new <= exp_cache - 7'd5;
                        rm_new <= {1'b0,rm_cache[16:6]};
                        ifround <= rm_cache[5] & (rm_cache[6] | (|rm_cache[4:0]));
                    end
                    23'b000_0000_1xxx_xxxx_xxxx_xxxx : begin
                        exp_new <= exp_cache - 7'd6;
                        rm_new <= {1'b0,rm_cache[15:5]};
                        ifround <= rm_cache[4] & (rm_cache[5] | (|rm_cache[3:0]));
                    end
                    23'b000_0000_01xx_xxxx_xxxx_xxxx : begin
                        exp_new <= exp_cache - 7'd7;
                        rm_new <= {1'b0,rm_cache[14:4]};
                        ifround <= rm_cache[3] & (rm_cache[4] | (|rm_cache[2:0]));
                    end
                    23'b000_0000_001x_xxxx_xxxx_xxxx : begin
                        exp_new <= exp_cache - 7'd8;
                        rm_new <= {1'b0,rm_cache[13:3]};
                        ifround <= rm_cache[2] & (rm_cache[3] | (|rm_cache[1:0]));
                    end
                    23'b000_0000_0001_xxxx_xxxx_xxxx : begin
                        exp_new <= exp_cache - 7'd9;
                        rm_new <= {1'b0,rm_cache[12:2]};
                        ifround <= rm_cache[1] & (rm_cache[2] | rm_cache[0]);
                    end
                    23'b000_0000_0000_1xxx_xxxx_xxxx : begin
                        exp_new <= exp_cache - 7'd10;
                        rm_new <= {1'b0,rm_cache[11:1]};
                        ifround <= rm_cache[0] & rm_cache[1];
                    end
                    default : begin
                        exp_new <= 12'd0;
                        rm_new <= 7'd0;
                        ifround <= 1'b0;
                    end
                endcase
            end
        end
        else    begin               //invalid
            norpre_over <= 1'b0;
            overflow4 <= 1'b0;
            sign_new <= sign_new;
            exp_new <= exp_new;
            rm_new <= rm_new;
            ifround <= ifround;
        end
    end
    
    //step5:normalize_round to nearest even
    always@(posedge clk or posedge rst) begin
        if(rst) begin           //rst
            norround_over <= 1'b0;
            overflow5 <= 1'b0;
            rm_new2 <= 12'd0;
            sign_new2 <= 1'b0;
            exp_new2 <= 7'd0;
        end
        else if(norpre_over)    begin       //work
            norround_over <= 1'b1;
            overflow5 <= overflow4;
            if(overflow4)   begin
                rm_new2 <= rm_new2;
                sign_new2 <= sign_new2;
                exp_new2 <= exp_new2;
            end
            else    begin
                rm_new2 <= ifround ? rm_new + 12'd1 : rm_new;
                sign_new2 <= sign_new;
                exp_new2 <= exp_new;
            end
        end
        else    begin           //invalid
            norround_over <= 1'b0;
            overflow5 <= overflow5;
            rm_new2 <= rm_new2;
            sign_new2 <= sign_new2;
            exp_new2 <= exp_new2;
        end
    end
    
    //step6: normalize_carry
    always @ (posedge clk or posedge rst)   begin
        if(rst) begin       //rst
            norcarry_over <= 1'b0;
            overflow6 <= 1'b0;
            sign_new3 <= 1'b0;
            exp_new3 <= 7'd0;
            rm_new3 <= 12'd0;
        end
        else if(norround_over)  begin       //work
            norcarry_over <= 1'b1;
            overflow6 <= overflow5;
            if(overflow5)   begin
                sign_new3 <= sign_new3;
                exp_new3 <= exp_new3;
                rm_new3 <= rm_new3;
            end
            else begin
                sign_new3 <= sign_new2;
                if(rm_new2[11]) begin
                    exp_new3 <= exp_new2 + 7'd1;
                    rm_new3 <= rm_new2 >> 1;
                end
                else begin
                    exp_new3 <= exp_new2;
                    rm_new3 <= rm_new2;
                end
            end
        end
        else    begin                   //invalid
            norcarry_over <= 1'b0;
            overflow6 <= overflow6;
            sign_new3 <= sign_new3;
            exp_new3 <= exp_new3;
            rm_new3 <= rm_new3;
        end
    end
    
    //step7:result
    always @(posedge clk or posedge rst)    begin
        if(rst) begin           //rst
            data_o <= 16'd0;
            output_update <= 1'b0;
        end
        else if(norcarry_over)  begin           //work
            output_update <= 1'b1;
            if(overflow6 | (exp_new3[6:5] == 2'b01))
                data_o <= 16'hffff;
            else if( ~(|rm_new3[11:0]) | (exp_new3[6]))
                data_o <= 16'h0000;
            else
                data_o <= {sign_new3,exp_new3[4:0],rm_new3[9:0]};
        end
        else    begin               //invalid
            data_o <= data_o;
            output_update <= 1'b0;
        end
    end
    
endmodule
