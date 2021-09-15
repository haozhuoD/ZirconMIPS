`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/01 11:42:48
// Design Name: 
// Module Name: LLbit_reg
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


`include "defines.v"

module LLbit_reg (
    input  rst,
    input  clk,

    input  flush,
    input  flush_cause,

    input  we,
    input  LLbit_i,

    output reg LLbit_o
);

always @(posedge clk) begin
    if (rst == `RstEnable) begin
        LLbit_o <= 1'b0;
    end else if (flush == 1'b1 && flush_cause == `Exception) begin //���쳣����
        LLbit_o <= 1'b0;
    end else if (we == `WriteEnable) begin
        LLbit_o <= LLbit_i;
    end
end
    
endmodule