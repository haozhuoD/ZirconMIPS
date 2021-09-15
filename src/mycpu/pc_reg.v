`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/20 16:20:05
// Design Name: 
// Module Name: pc_reg
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

module pc_reg(
    input clk,
    input rst,
    input[3:0]  stall,
    input   flush,
    input   flush_cause,
    
   
    
    input   stallreq_from_icache,
    input branch_flag,
    input predict_flag,
    input exception_flag,
    input[`InstAddrBus] ex_pc,
    input[`InstAddrBus] npc_actual,
    input[`InstAddrBus] epc,
    input[32:0] bpu_predict_info,
    input       bpu_dely,
//    input[`InstAddrBus] npc_from_cache,
   
    
    input   ibuffer_full,
    
    output   reg [`InstAddrBus] pc,
    output   reg    rreq_to_icache
   
       
    
    );
    
    reg[`InstAddrBus]   npc;
    reg[`InstAddrBus]   bpu_predict_info_ff ;
    reg                 bpu_dely_ff         ;
    
 always@(posedge clk) begin
    if(ibuffer_full /*|| stall == 4'b0011*/|| stallreq_from_icache)begin    
    end
    else              begin
        bpu_dely_ff <= bpu_dely;
    end
end   
    
    
always@(*) begin   //组合逻辑？
        if(rst == `RstEnable || /*flush == `Flush*/!predict_flag || exception_flag || ibuffer_full || stallreq_from_icache)begin
            rreq_to_icache = `ChipDisable;
        end else begin  //stall 控制
            rreq_to_icache =`ChipEnable ;
        end
end

always @(posedge clk)   pc<=npc;
    

always@(*) begin
    if(rst == `RstEnable) begin
        npc = 32'hbfc00000; //bfc00000
    end else if(flush == `Flush && flush_cause == `Exception)begin
         npc = epc;    
    end else if(flush == `Flush && flush_cause == `FailedBranchPrediction && branch_flag == `Branch) begin
         npc = npc_actual;  
    end else if(flush == `Flush && flush_cause == `FailedBranchPrediction && branch_flag == `NotBranch) begin
         npc = ex_pc + 32'h8;   
    end else if(ibuffer_full /*|| stall == 4'b0011*/|| stallreq_from_icache) npc = pc;  
   // else if(stall == 4'b0011)  npc = npc;     
    
    //bpu
    else
    if(bpu_predict_info[32]) begin//7.24/dqy
        if(bpu_dely)             begin
            npc = bpu_predict_info[31: 0]               ;
        end
        else         begin
            npc = bpu_predict_info[31: 0] + 32'h00000008;
        end
    end
    
    else 
         npc = pc + 4'h8;
           
end    
    
    
    
    
endmodule
