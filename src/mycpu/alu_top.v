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

module alu_top(
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
        input[`RegBus]                  imm_fnl2_i,
//        input                   issue_i,
        
        input                   is_in_delayslot1_i,
        input                   is_in_delayslot2_i,
        
        input                   LLbit_i,
        input                   mem_LLbit_i,
        input                   mem_LLbit_we_i,
        input                   commit_LLbit_i,
        input                   commit_LLbit_we_i,        
        
        input[2:0]               cp0_sel1_i,
    	input[`RegAddrBus]       cp0_addr1_i,
    	input[2:0]               cp0_sel2_i,
    	input[`RegAddrBus]       cp0_addr2_i,    	
    	input[`RegBus]           cp0_data_i,
    	input[2:0]               mem_cp0_wsel_i,
    	input                    mem_cp0_we_i,
    	input[`RegAddrBus]       mem_cp0_waddr_i,
    	input[`RegBus]           mem_cp0_wdata_i,
    	input[2:0]               commit_cp0_wsel_i,
    	input                    commit_cp0_we_i,
    	input[`RegAddrBus]       commit_cp0_waddr_i,
    	input[`RegBus]           commit_cp0_wdata_i,
    	
    	input                    mem_exception_flag_i,     //原来默认是第一条？ 确实
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
      
//      output                        issue_mode,
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
      output[`AluOpBus]             aluop2_o,
      output[`RegBus]               mem_addr_o,
      output[`RegBus]               reg2_o,
      output[`RegBus]               reg4_o,
      
      output[`RegBus]               mem_raddr_o,
      output[`RegBus]               mem_waddr_o,
//        output[`RegBus]               mem_addr_to_dcache,
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
      input is_jb,
      
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
    
//    assign issue_mode = issue_i;
   
//    assign inst1_bpu_corr_o = inst1_bpu_corr_i;
//    assign inst2_bpu_corr_o = inst2_bpu_corr_i;

    always @(*) begin
        if(rst == `RstEnable) LLbit = 1'b0;
        else if(mem_LLbit_we_i == `WriteEnable) LLbit = mem_LLbit_i;
        else if(commit_LLbit_we_i == `WriteEnable) LLbit = commit_LLbit_i;
        else LLbit = LLbit_i;
    end    
    
    //redistribution
    //need is_jb
    wire [`AluOpBus] main_aluop_i;
    wire [`AluSelBus]main_alusel_i;
    wire [`RegBus]  main_reg1_i;
    wire [`RegBus]  main_reg2_i;
    wire [`RegAddrBus] main_waddr_i;
    wire main_we_i;
    wire [31:0] main_exception_type_i;
    wire [31:0] main_fnl_i;
    wire[`RegAddrBus] main_cp0_addr_i;
    wire [2:0]      main_cp0_sel_i;
            
    wire [31:0] alujb_exception_type_i;
    wire [`AluOpBus] alujb_aluop_i;
    wire [`AluSelBus]alujb_alusel_i;
    wire [`RegBus]  alujb_reg1_i;
    wire [`RegBus]  alujb_reg2_i;
    wire [`RegAddrBus] alujb_waddr_i;
    wire alujb_we_i;
//    wire alujb_hi_i;
//    wire alujb_lo_i;

      /////////////////////////
      
    assign is_in_delayslot1_o =  is_in_delayslot1_i;
    assign is_in_delayslot2_o =  is_in_delayslot2_i;
    assign inst1_addr_o = inst1_addr_i;
    assign inst2_addr_o = inst2_addr_i;    
    assign cp0_rsel_o = main_cp0_sel_i;
    assign cp0_wsel_o = main_cp0_sel_i;
    
    ////
     
    assign main_aluop_i             =is_jb ?  aluop2_i      :  aluop1_i   ;           
    assign main_alusel_i           =is_jb ?  alusel2_i      :  alusel1_i  ;         
    assign main_reg1_i              =is_jb ?  reg3_i        :  reg1_i   ;            
    assign main_reg2_i              =is_jb ?  reg4_i        :  reg2_i  ;            
    assign main_waddr_i            =is_jb ?  waddr2_i:         waddr1_i;          
    assign main_we_i               =is_jb ?   we2_i:    we1_i;                     
    assign main_exception_type_i    =is_jb ?   exception_type2_i:     exception_type1_i  ;  
    assign main_fnl_i              = is_jb ?  imm_fnl2_i        :     imm_fnl1_i;                              
    assign main_cp0_addr_i          = is_jb?   cp0_addr2_i      :     cp0_addr1_i   ;
    assign main_cp0_sel_i           = is_jb?   cp0_sel2_i       :     cp0_sel1_i    ;
    
    assign alujb_aluop_i             =is_jb ?  aluop1_i      :  aluop2_i   ;           
    assign alujb_alusel_i           =is_jb ?  alusel1_i      :  alusel2_i  ;         
    assign alujb_reg1_i              =is_jb ?  reg1_i        :  reg3_i   ;            
    assign alujb_reg2_i              =is_jb ?  reg2_i        :  reg4_i  ;            
    assign alujb_waddr_i            =is_jb ?  waddr1_i:         waddr2_i;          
    assign alujb_we_i               =is_jb ?   we1_i           :    we2_i;                     
    assign alujb_exception_type_i    =is_jb ?   exception_type1_i:     exception_type2_i  ;  
//    assign alujb_fnl_i              = is_jb ?  imm_fnl1_i       :       imm_fnl2_i  ;
    
    
///////////

//       output[`RegAddrBus]     waddr1_o,
//       output[`RegAddrBus]     waddr2_o,
//       output                                 we1_o,
//       output                                 we2_o,
//       output[`RegBus]              wdata1_o,
//       output[`RegBus]              wdata2_o,
            
//     	  output[31:0]                  exception_type1_o,
//	  output[31:0]                  exception_type2_o,       
	  
//	  wire [31:0]main_exception_type_o;
	  wire [`RegAddrBus]alujb_waddr_o;
	  wire [`RegAddrBus]main_waddr_o;
	  wire alujb_we_o;
	  wire main_we_o;
	  wire [31:0]alujb_wdata_o;
	  wire [31:0]main_wdata_o;
	  wire [31:0]alujb_exception_type_o;
	  wire [31:0]main_exception_type_o;
          wire [`RegBus]main_hi_o;
	  wire [`RegBus]alujb_hi_o;
	  wire [`RegBus]main_lo_o;
	  wire [`RegBus]alujb_lo_o;
	  wire main_whilo_o;
	  wire alujb_whilo_o;
	  
	  
	  wire main_whi;
	  wire main_wlo;
	  wire alujb_whi;
	  wire alujb_wlo;
	  
	  
	  assign waddr1_o = is_jb?     alujb_waddr_o : main_waddr_o;
      assign waddr2_o = is_jb?   main_waddr_o  : alujb_waddr_o;
      assign we1_o = is_jb? alujb_we_o: main_we_o ;
      assign we2_o = is_jb? main_we_o :  alujb_we_o ;
      assign wdata1_o           = is_jb? alujb_wdata_o   :main_wdata_o  ;
      assign wdata2_o           = is_jb?  main_wdata_o  :  alujb_wdata_o;
      assign exception_type1_o  = is_jb?  alujb_exception_type_o  : main_exception_type_o ;
      assign exception_type2_o  = is_jb?   main_exception_type_o :  alujb_exception_type_o;
      assign ex_sub_1_hi_o      = is_jb?  alujb_hi_o            :   main_hi_o           ;
      assign ex_sub_2_hi_o      = is_jb?  main_hi_o             :   alujb_hi_o          ;
      assign ex_sub_1_lo_o      = is_jb?  alujb_lo_o            :   main_lo_o          ;
      assign ex_sub_2_lo_o      = is_jb?  main_lo_o             :   alujb_lo_o          ;
      assign ex_sub_1_whilo_o   = is_jb?  alujb_whilo_o         :   main_whilo_o       ;
      assign ex_sub_2_whilo_o   = is_jb?   main_whilo_o         :   alujb_whilo_o       ;
      
      
      wire whi_1,whi_2,wlo_1,wlo_2;
      assign whi_1 =is_jb?  alujb_whi        :   main_whi      ;
      assign whi_2 = is_jb? main_whi          :   alujb_whi     ;
      assign wlo_1 = is_jb?  alujb_wlo        :   main_wlo      ;
      assign wlo_2 = is_jb? main_wlo          :   alujb_wlo     ;
    ALU_main  u_ex_main(
            .rst(rst),
//            .bpu_predict_info_i(bpu_predict_info_i),
            .aluop_i(main_aluop_i),            
            .alusel_i(main_alusel_i),           
            .reg1_i(main_reg1_i),          
            .reg2_i(main_reg2_i),          
            .waddr_i(main_waddr_i),              
            .we_i (main_we_i), 
             .hi_i(hi_i),
             .lo_i(lo_i),       
            .div_result_i(div_result_i),            
            .div_ready_i(div_ready_i),
            .mult_result_i(mult_result_i),
            .mult_ready_i(mult_ready_i),
            .imm_i(main_fnl_i),
//            .pc_i(inst1_addr_i),
            .LLbit_i(LLbit),
            .cp0_sel_i(main_cp0_sel_i),
            .cp0_addr_i(main_cp0_addr_i),
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
            .exception_type_i(main_exception_type_i),
            
            .waddr_o(main_waddr_o),                     
            . we_o(main_we_o),         
            .wdata_o(main_wdata_o),                
        //     .hi_o(ex_sub_1_hi_o),                   
        //     .lo_o(ex_sub_1_lo_o),                   
        //     .whilo_o(ex_sub_1_whilo_o),    
            .hi_o(main_hi_o),                   
            .lo_o(main_lo_o),                   
            .whilo_o(main_whilo_o),                        
            .div_opdata1_o(div_opdata1_o),            
            .div_opdata2_o(div_opdata2_o),            
            .div_start_o(div_start_o),    
            .signed_div_o(signed_div_o),
            .mult_opdata1_o(mult_opdata1_o),
            .mult_opdata2_o(mult_opdata2_o),
            .mult_start_o(mult_start_o),
            .signed_mult_o(signed_mult_o),
//            .npc_actual(npc_actual),
//            .branch_flag_actual(branch_flag_actual),   //
//            .predict_flag(predict_flag),    //
//            .branch_info(branch_info),
//            .predict_true(predict_true),
                    
            .mem_addr_o(mem_addr_o),                                                
             .mem_raddr_o(mem_raddr_o),              
             .mem_waddr_o(mem_waddr_o),              
//                .mem_addr_to_dcache(mem_addr_to_dcache),
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
            .exception_type_o(main_exception_type_o),   
            .lb_type(lb_type_o),    
            
//             .bru_addr(bru_addr_i),   
            .main_whi(main_whi),
            .main_wlo(main_wlo),                
            . stallreq(stallreq)                  

            );          
                    
    ALU_jb  u_exjb(
            .rst(rst),
            .bpu_predict_info_i(bpu_predict_info_i),
            .aluop_i(alujb_aluop_i),            
            .alusel_i(alujb_alusel_i),           
            .reg1_i(alujb_reg1_i),          
            .reg2_i(alujb_reg2_i),          
            .waddr_i(alujb_waddr_i),              
            .we_i (alujb_we_i), 
            .hi_i(hi_i),
            .lo_i(lo_i),
            .pc_i(inst1_addr_i),
            .exception_type_i(alujb_exception_type_i),
            .waddr_o(alujb_waddr_o),     //                
            . we_o(alujb_we_o),        //// 
            .wdata_o(alujb_wdata_o),     //           
        //     .hi_o(ex_sub_2_hi_o),    //               
        //     .lo_o(ex_sub_2_lo_o),      //             
        //     .whilo_o(ex_sub_2_whilo_o), //
            .hi_o(alujb_hi_o),    //               
            .lo_o(alujb_lo_o),      //             
            .whilo_o(alujb_whilo_o), //
            .npc_actual(npc_actual),
            .branch_flag_actual(branch_flag_actual),   //
            .predict_flag(predict_flag),    //
            .branch_info(branch_info),
            .predict_true(predict_true),
            .bru_addr(bru_addr_i),   
             .is_to_hi(alujb_whi),
            .is_to_lo(alujb_wlo),
            
            .exception_type_o(alujb_exception_type_o)
    
    
    );             
 
//  always @(*)    begin
//         if(rst == `RstEnable)   begin
//                 whilo_o = `WriteDisable;
//                 hi_o = `ZeroWord;
//                 lo_o = `ZeroWord;
//         end else if(ex_sub_2_whilo_o == `WriteEnable) begin     //乘法指令双发优先保存第二条指令的结果？ 不合理
//                 whilo_o = `WriteEnable;
//                 hi_o = ex_sub_2_hi_o;
//                 lo_o = ex_sub_2_lo_o;
//         end else if(ex_sub_1_whilo_o == `WriteEnable) begin
//                 whilo_o = `WriteEnable;
//                 hi_o = ex_sub_1_hi_o;
//                 lo_o = ex_sub_1_lo_o;                              
//         end else begin
//                 whilo_o = `WriteDisable;
//                 hi_o = `ZeroWord;
//                 lo_o = `ZeroWord;   
//                 end                                               
//     end
 always @(*)    begin
        if(rst == `RstEnable)   begin
                whilo_o = `WriteDisable;
                hi_o = `ZeroWord;
                lo_o = `ZeroWord;
        end 
        else if(ex_sub_2_whilo_o == `WriteEnable ) begin     
                whilo_o = `WriteEnable;
                hi_o = whi_2 ? ex_sub_2_hi_o :
                       whi_1 ? ex_sub_1_hi_o : hi_i;
                lo_o = wlo_2 ? ex_sub_2_lo_o : 
                       wlo_1 ? ex_sub_1_lo_o : lo_i ;
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
assign reg4_o = reg4_i;
assign aluop1_o = aluop1_i; 
assign aluop2_o = aluop2_i;   
    
    
endmodule
