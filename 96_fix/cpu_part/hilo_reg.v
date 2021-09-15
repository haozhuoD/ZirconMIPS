`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/28 20:44:43
// Design Name: 
// Module Name: hilo_reg
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
`include  "defines.v" 

module hilo_reg(
    input clk,
    input rst,
    
    input we,
    input[`RegBus] hi_i,
    input[`RegBus] lo_i,
    
    output reg[`RegBus] hi_o,
    output reg[`RegBus] lo_o

    );
    
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end else if(we == `WriteEnable) begin
            hi_o <= hi_i;
            lo_o <= lo_i;    
        end
    end
        
    
    
    
    
endmodule
