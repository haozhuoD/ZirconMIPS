`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/21 22:10:47
// Design Name: 
// Module Name: ex_top
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

module ex_top(
        input   rst,
        
        input[`InstAddrBus]     inst1_addr_i,
        input[`InstAddrBus]     inst2_addr_i,
//        input[`SIZE_OF_CORR_PACK] inst1_bpu_corr_i,
//        input[`SIZE_OF_CORR_PACK] inst2_bpu_corr_i,
        input[32:0]             bpu_predict_info_i,
        input[`AluOpBus]     aluop1_i,
        input[`AluSelBus]     alusel1_i,
        input[`AluOpBus]     aluop2_i,
        input[`AluSelBus]     alusel2_i,
        input[`RegBus]          reg1_i,
        input[`RegBus]          reg2_i,
        input[`RegBus]          reg3_i,
        input[`RegBus]          reg4_i,
        input[`RegAddrBus]      waddr1_i,
        input[`RegAddrBus]      waddr2_i,
        input                                   we1_i,
        input                                   we2_i,
        
 
        input[`DoubleRegBus]    div_result_i,
        input                   div_ready_i,
        input[`DoubleRegBus]    mult_result_i,
        input                   mult_ready_i,
        
        input[`RegBus]                  hi_i,
        input[`RegBus]                  lo_i,
        
        //jump and branch
            
        input[`RegBus]                  imm_fnl1_i,
        input                   issue_i,
//        input                   is_jb_
                
        input                   is_in_delayslot1_i,
        input                   is_in_delayslot2_i,
        
        input                   LLbit_i,
        input                   mem_LLbit_i,
        input                   mem_LLbit_we_i,
        input                   commit_LLbit_i,
        input                   commit_LLbit_we_i,        
        
        input[2:0]               cp0_sel_i,
    	input[`RegAddrBus]       cp0_addr_i,
    	input[`RegBus]           cp0_data_i,
    	input[2:0]               mem_cp0_wsel_i,
    	input                    mem_cp0_we_i,
    	input[`RegAddrBus]       mem_cp0_waddr_i,
    	input[`RegBus]           mem_cp0_wdata_i,
    	input[2:0]               commit_cp0_wsel_i,
    	input                    commit_cp0_we_i,
    	input[`RegAddrBus]       commit_cp0_waddr_i,
    	input[`RegBus]           commit_cp0_wdata_i,
    	
    	input                    mem_exception_flag_i,
    	input[31:0]              exception_type1_i,
    	input[31:0]              exception_type2_i,
        
        
       output[`InstAddrBus]     inst1_addr_o,
       output[`InstAddrBus]     inst2_addr_o,
//       output[`SIZE_OF_CORR_PACK] inst1_bpu_corr_o,
//       output[`SIZE_OF_CORR_PACK] inst2_bpu_corr_o,
       output[`RegAddrBus]     waddr1_o,
       output[`RegAddrBus]     waddr2_o,
       output                                 we1_o,
       output                                 we2_o,
       output[`RegBus]              wdata1_o,
       output[`RegBus]              wdata2_o,
       

      output  reg[`RegBus]    hi_o,
      output  reg[`RegBus]    lo_o,
      output  reg                       whilo_o,
      
      output[`InstAddrBus]          npc_actual,
      output                        branch_flag_actual,
      output                        predict_flag,
      output[`SIZE_OF_BRANCH_INFO]                        branch_info,
      output                        predict_true,
      
      output                        issue_mode,
      output                        is_in_delayslot1_o,
      output                        is_in_delayslot2_o,
      
      
      //div
      output[`RegBus]               div_opdata1_o,
      output[`RegBus]               div_opdata2_o,
      output                        div_start_o,
      output                        signed_div_o,
      
      //mult
      output[`RegBus]               mult_opdata1_o,
      output[`RegBus]               mult_opdata2_o,
      output                        mult_start_o,
      output                        signed_mult_o,
      
      output[`AluOpBus]             aluop1_o,
      output[`RegBus]               mem_addr_o,
      output[`RegBus]               reg2_o,
      
      output[`RegBus]               mem_raddr_o,
      output[`RegBus]               mem_waddr_o,
      output                        mem_we_o,
      output[3:0]                   mem_sel_o,
      output[`RegBus]               mem_data_o,
      output                        mem_re_o,
      
      output                        LLbit_o,
      output                        LLbit_we_o,
      
	  output[2:0]                   cp0_rsel_o,
      output[`RegAddrBus]           cp0_raddr_o,
	  output[2:0]                   cp0_wsel_o,
      output                        cp0_we_o,
	  output[`RegAddrBus]           cp0_waddr_o,
	  output[`RegBus]               cp0_wdata_o,
	  output[31:0]                  exception_type1_o,
	  output[31:0]                  exception_type2_o,
      output                        lb_type_o,
      
      output                                 stallreq    ,
      
      input [`RegBus] bru_addr_i,
      
      output debug_is_time_addr            
            
    );
    

    assign debug_is_time_addr = (mem_raddr_o == 32'hbfaf_e000) | (cp0_raddr_o == 32'h9);
    
    
    
    wire[`RegBus]   ex_sub_1_hi_o;
    wire[`RegBus]   ex_sub_1_lo_o;
    wire    ex_sub_1_whilo_o;    
    wire[`RegBus]   ex_sub_2_hi_o;
    wire[`RegBus]   ex_sub_2_lo_o;
    wire    ex_sub_2_whilo_o;
    reg     LLbit;
    
    assign issue_mode = issue_i;
    assign is_in_delayslot1_o = is_in_delayslot1_i;
    assign is_in_delayslot2_o = is_in_delayslot2_i;
    assign inst1_addr_o = inst1_addr_i;
    assign inst2_addr_o = inst2_addr_i;
//    assign inst1_bpu_corr_o = inst1_bpu_corr_i;
//    assign inst2_bpu_corr_o = inst2_bpu_corr_i;
    assign cp0_rsel_o = cp0_sel_i;
    assign cp0_wsel_o = cp0_sel_i;
    
    always @(*) begin
        if(rst == `RstEnable) LLbit = 1'b0;
        else if(mem_LLbit_we_i == `WriteEnable) LLbit = mem_LLbit_i;
        else if(commit_LLbit_we_i == `WriteEnable) LLbit = commit_LLbit_i;
        else LLbit = LLbit_i;
    end    
    
    
    ex  u_ex1(
            .rst(rst),
            .bpu_predict_info_i(bpu_predict_info_i),
            .aluop_i(aluop1_i),            
            .alusel_i(alusel1_i),           
            .reg1_i(reg1_i),          
            .reg2_i(reg2_i),          
            .waddr_i(waddr1_i),              
            .we_i (we1_i), 
             .hi_i(hi_i),
             .lo_i(lo_i),       
            .div_result_i(div_result_i),            
            .div_ready_i(div_ready_i),
            .mult_result_i(mult_result_i),
            .mult_ready_i(mult_ready_i),
            .imm_i(imm_fnl1_i),
            .pc_i(inst1_addr_i),
            .LLbit_i(LLbit),
            .cp0_sel_i(cp0_sel_i),
            .cp0_addr_i(cp0_addr_i),
            .cp0_data_i(cp0_data_i),
            .mem_cp0_wsel_i(mem_cp0_wsel_i),
            .mem_cp0_we_i(mem_cp0_we_i),
            .mem_cp0_waddr_i(mem_cp0_waddr_i),
            .mem_cp0_wdata_i(mem_cp0_wdata_i),
            .commit_cp0_wsel_i(commit_cp0_wsel_i),
            .commit_cp0_we_i(commit_cp0_we_i),
            .commit_cp0_waddr_i(commit_cp0_waddr_i),
            .commit_cp0_wdata_i(commit_cp0_wdata_i),
            .mem_exception_flag_i(mem_exception_flag_i),
            .exception_type_i(exception_type1_i),
            
            .waddr_o(waddr1_o),                     
            . we_o(we1_o),         
            .wdata_o(wdata1_o),                
            .hi_o(ex_sub_1_hi_o),                   
            .lo_o(ex_sub_1_lo_o),                   
            .whilo_o(ex_sub_1_whilo_o),                           
            .div_opdata1_o(div_opdata1_o),            
            .div_opdata2_o(div_opdata2_o),            
            .div_start_o(div_start_o),    
            .signed_div_o(signed_div_o),
            .mult_opdata1_o(mult_opdata1_o),
            .mult_opdata2_o(mult_opdata2_o),
            .mult_start_o(mult_start_o),
            .signed_mult_o(signed_mult_o),
            .npc_actual(npc_actual),
            .branch_flag_actual(branch_flag_actual),   //
            .predict_flag(predict_flag),    //
            .branch_info(branch_info),
            .predict_true(predict_true),
                    
            .mem_addr_o(mem_addr_o),                                                
            .mem_raddr_o(mem_raddr_o),              
            .mem_waddr_o(mem_waddr_o),              
            .mem_we_o(mem_we_o),                 
            .mem_sel_o(mem_sel_o),                
            .mem_data_o(mem_data_o),               
            .mem_re_o(mem_re_o),                 
              
            .LLbit_o(LLbit_o),
            .LLbit_we_o(LLbit_we_o),
            .cp0_raddr_o(cp0_raddr_o),
            .cp0_we_o(cp0_we_o),
            .cp0_waddr_o(cp0_waddr_o),
            .cp0_wdata_o(cp0_wdata_o),
            .exception_type_o(exception_type1_o),   
            .lb_type(lb_type_o),    
            
             .bru_addr(bru_addr_i),                   
            . stallreq(stallreq)                  

            );          
                    
    ex_sub  u_ex2(
            .rst(rst),

            .aluop_i(aluop2_i),            
            .alusel_i(alusel2_i),           
            .reg1_i(reg3_i),          
            .reg2_i(reg4_i),          
            .waddr_i(waddr2_i),              
            .we_i (we2_i), 
            .hi_i(hi_i),
            .lo_i(lo_i),
            .exception_type_i(exception_type2_i),
            .waddr_o(waddr2_o),                     
            . we_o(we2_o),         
            .wdata_o(wdata2_o),                
            .hi_o(ex_sub_2_hi_o),                   
            .lo_o(ex_sub_2_lo_o),                   
            .whilo_o(ex_sub_2_whilo_o),
            .exception_type_o(exception_type2_o)
    
    
    );             
 
 always @(*)    begin
        if(rst == `RstEnable)   begin
                whilo_o = `WriteDisable;
                hi_o = `ZeroWord;
                lo_o = `ZeroWord;
        end else if(ex_sub_2_whilo_o == `WriteEnable) begin     //乘法指令双发优先保存第二条指令的结果？ 不合理
                whilo_o = `WriteEnable;
                hi_o = ex_sub_2_hi_o;
                lo_o = ex_sub_2_lo_o;
        end else if(ex_sub_1_whilo_o == `WriteEnable) begin
                whilo_o = `WriteEnable;
                hi_o = ex_sub_1_hi_o;
                lo_o = ex_sub_1_lo_o;                              
        end else begin
                whilo_o = `WriteDisable;
                hi_o = `ZeroWord;
                lo_o = `ZeroWord;   
                end                                               
    end
    
assign reg2_o = reg2_i;
assign aluop1_o = aluop1_i;    
    
    
endmodule
