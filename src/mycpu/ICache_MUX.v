`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/17 13:17:09
// Design Name: 
// Module Name: ICache_MUX
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


module ICache_MUX(
    input           clk             ,
    input           stallreq        ,
    input   [31: 0] addr_from_PC    ,
    input   [31: 0] addr_from_BPU   ,
    input           pred_direct     ,
    input           pred_dely       ,
    output  [31: 0] paddr_to_ICache ,
    output  [31: 0] vaddr_to_ICache 
    );
    
    reg     addr_from_BPU_ff        ;
    
    always @(posedge clk)   begin
        addr_from_BPU_ff    <= addr_from_BPU;
    end
    
    assign  paddr_to_ICache = pred_direct & ~pred_dely ? (addr_from_BPU[31:30] == 2'b10 ? {3'b000,addr_from_BPU[28: 0]} 
                                                                                        : addr_from_BPU) 
                                                       : (addr_from_PC[31:30]  == 2'b10 ? {3'b000,addr_from_PC[28: 0] } 
                                                                                        : addr_from_PC) ;

    assign  vaddr_to_ICache = pred_direct & ~pred_dely ? addr_from_BPU : addr_from_PC                   ;

endmodule
