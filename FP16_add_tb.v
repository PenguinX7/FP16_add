`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/23 21:34:23
// Design Name: 
// Module Name: FP16_add_tb
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


module FP16_add_tb(

    );
    reg clk;
    reg input_valid;
    reg [15:0]data1;
    reg [15:0]data2;
    reg rst;
    wire [15:0]data_o;
    wire output_update;
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 0;
        input_valid = 0;
        rst = 0;
        #10
        input_valid = 1; 
        data1 = 16'h5bf0;   //254 + 7.6836 = 261.75(0x5c17)
        data2 = 16'h47af;
        #10
        data2 = 16'h5bf0;
        data1 = 16'h47af;
        #10
        data1 = 16'h5bf0;   //254 - 254.125 = -0.125(0xb000)
        data2 = 16'hdbf1;
        #10
        data1 = 16'h0000;   //0 + 7.6836 = 7.6836(0x47af)
        data2 = 16'h47af;
        #10
        data1 = 16'h47af;
        data2 = 16'h0000;
        #10
        data1 = 16'h7bff;   //65504 + min = 65504(0x7bff)
        data2 = 16'h0400;
        #10
        data1 = 16'h7bff;
        data2 = 16'h8400;   //65504 - min = 65504(0x7bff)
        #10
        data1 = 16'h0400;   //min - min = 0(0x0000)
        data2 = 16'h8400;
        #10
        data1 = 16'h0000;   //0 + 0 = 0(0x0000)
        data2 = 16'h0000;
        #10
        data1 = 16'hffff;   //Inf + 254 = Inf(0xffff)
        data2 = 16'h5bf0;
        #10
        data1 = 16'h0000;   //0 + Inf = Inf(0xffff)
        data2 = 16'hffff;
        #90 rst = 1;
    end
    
    FP16_add U1 (
    .clk(clk),
    .rst(rst),
    .input_valid(input_valid),
    .data1(data1),
    .data2(data2),
    .data_o(data_o),
    .output_update(output_update)
    );
endmodule
