//`timescale 1ns / 1ps
`include "defines.v" 
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/08/03 16:09:47
// Design Name: 
// Module Name: ALU_jb
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


module ALU_jb(
input       rst,
        
        input[`AluOpBus]             aluop_i,
        input[`AluSelBus]             alusel_i,
        input[`RegBus]                  reg1_i,
        input[`RegBus]                  reg2_i,
        input[`RegAddrBus]         waddr_i,
        input                                     we_i,
        
        input[`RegBus]          hi_i,
        input[`RegBus]          lo_i,
        input[31:0]             exception_type_i,
        
        //input[`DoubleRegBus]    div_result_i,
        //input                                    div_ready_i,
        

        
        output  reg[`RegAddrBus]     waddr_o,
        output  reg                                 we_o,
        output  reg[`RegBus]              wdata_o,
        output  reg[`RegBus]              hi_o,
        output  reg[`RegBus]              lo_o,
        output  reg                                 whilo_o,                                     
         
        //output  reg[`RegBus]            div_opdata1_o,
        //output  reg[`RegBus]            div_opdata2_o,
        //output  reg                               div_start_o,
        //output  reg                               signed_div_o,
        
        //output  reg[`InstAddrBus]       
        
//        output[`RegBus]                    mem_addr_o,
        
//        output  reg                               mem_raddr_o,
//        output  reg                               mem_waddr_o,
//        output  reg                               mem_we_o,
//        output  reg                               mem_sel_o,
//        output  reg                               mem_data_o,
//        output  reg                               mem_re_o,
        
//        output                                       stallreq 
//        input[`SIZE_OF_CORR_PACK]       inst_bpu_corr_i,
        input[`InstAddrBus]             pc_i,
        input[32:0]                 bpu_predict_info_i,
        output  reg[`InstAddrBus]       npc_actual,
        output reg                      branch_flag_actual,
        output reg                      predict_flag,
        output reg[`SIZE_OF_BRANCH_INFO]    branch_info,
        output  reg                    predict_true,
        input [`RegBus] bru_addr,
        output reg is_to_hi,
        output reg is_to_lo,
          output [31:0]                         exception_type_o         
    );
        
        
        reg[`RegBus]        jbres;
        reg[`RegBus]        logicout;
        reg[`RegBus]        shiftres;
        reg[`RegBus]        moveres;
        reg[`RegBus]        arithmeticres;
        
       // wire[`DoubleRegBus]     mulres;
        //wire[`DoubleRegBus]     mulres_u;
       
        
        wire    ov_sum;   //保存溢出情况
        wire [`RegBus]   result_sum;
        
        //reg stallreq_for_div;    
        reg ovassert;
        
        wire reg1_lt_reg2;
        
        assign exception_type_o = {exception_type_i[31:13],ovassert,exception_type_i[11:0]};
   
//   mult_gen_0 mul(.A(reg1_i),.B(reg2_i),.P(mulres));
//   mult_gen_0_1 mul_u(.A(reg1_i),.B(reg2_i),.P(mulres_u));  //无符号乘�?     
   
//        assign mem_addr_o = reg1_i+imm_i;
        
   
always @(*) begin
    if (rst == `RstEnable) begin
        logicout = `ZeroWord;
    end else begin
        case (aluop_i)
            `EXE_OR_OP:begin
                logicout = reg1_i | reg2_i ;
            end
            `EXE_AND_OP:begin
                logicout = reg1_i & reg2_i;
            end
            `EXE_NOR_OP:begin          //�߼��������?
                logicout = ~(reg1_i | reg2_i);
            end
            `EXE_XOR_OP:begin          //�߼��������?
                logicout = reg1_i ^ reg2_i;
            end
        default:begin
            logicout = `ZeroWord;
        end
        endcase
    end
end    
    
    
always @(*) begin
    if(rst == `RstEnable)begin
        shiftres = `ZeroWord;
    end else begin
        case (aluop_i)
            `EXE_SLL_OP:begin        //�߼�����
                shiftres = reg2_i << reg1_i[4:0];   //???
            end 
            `EXE_SRL_OP:begin        //�߼�����
                shiftres = reg2_i >> reg1_i[4:0];
            end
            `EXE_SRA_OP:begin        //��������
//                shiftres = ({32{reg2_i[31]}}<<(6'd32-{1'b0,reg1_i[4:0]})) | reg2_i>>reg1_i[4:0];       //bangbang ?
                  shiftres = $signed(reg2_i)  >>> reg1_i[4:0];
            end
            default: begin
                shiftres =`ZeroWord;
            end
        endcase
    end //if
end  //always

    
always @(*) begin
    if (rst ==`RstEnable) begin
        moveres = `ZeroWord;
    end else begin
        moveres = `ZeroWord;
        case (aluop_i)
            `EXE_MFHI_OP:begin
                moveres = hi_i;
            end 
            `EXE_MFLO_OP:begin
                moveres = lo_i;
            end
            `EXE_MOVZ_OP:begin
                moveres =reg1_i;
            end
            `EXE_MOVN_OP:begin
                moveres =reg1_i;
            end
            ////////////////////
            //get infomation from cp0's regs
            /////////
            /*`EXE_MFC0_OP:begin
                cp0_reg_addr_o <= inst_i[15:11];
                moveres <= cp0_reg_data_i;
                // slove cp0_regs data relate
                if (mem_cp0_reg_we == `WriteEnable && mem_cp0_reg_write_addr == inst_i[15:11]) begin
                    moveres <= mem_cp0_reg_data;
                end else if (wb_cp0_reg_we == `WriteEnable && wb_cp0_reg_write_addr == inst_i[15:11]) begin
                    moveres <= wb_cp0_reg_data;
                end
            end*/
            default: begin  moveres = `ZeroWord;
            end
        endcase
    end
end

wire [`RegBus]  reg2_i_mux;
assign reg2_i_mux =((aluop_i ==`EXE_SUB_OP) || 
                    (aluop_i ==`EXE_SUBU_OP)||
                    (aluop_i ==`EXE_SLT_OP))/* ||
                    (aluop_i ==`EXE_TLT_OP) ||
                    //(aluop_i ==`EXE_TLTI_OP)||
                    //(aluop_i ==`EXE_TGE_OP) ||
                    (aluop_i ==`EXE_TGEI_OP))*/ ?
                    (~reg2_i)+1 : reg2_i;
                    
assign result_sum = reg1_i +reg2_i_mux;

//�����Ƿ����?  ͨ���������ͽ�������������ж�?
assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31] && result_sum[31])
                || (reg1_i[31] && reg2_i_mux[31] && !result_sum[31]));

assign reg1_lt_reg2 = ((aluop_i == `EXE_SLT_OP) /*||
                        (aluop_i ==`EXE_TLT_OP) ||
                        (aluop_i ==`EXE_TLTI_OP)||
                        (aluop_i ==`EXE_TGE_OP) ||
                        (aluop_i ==`EXE_TGEI_OP)*/) ?
                        ((reg1_i[31] && !reg2_i[31])) ||
                        (!reg1_i[31] && !reg2_i[31] && result_sum[31]) ||
                        (reg1_i[31] && reg2_i[31] && result_sum[31]) 
                        : (reg1_i < reg2_i);     
    
always @(*) begin
    if(rst == `RstEnable) begin
        arithmeticres = `ZeroWord;
    end else begin
        case (aluop_i)
            `EXE_SLT_OP, `EXE_SLTU_OP:begin      //�Ƚ�����
                arithmeticres = reg1_lt_reg2;             // need to be fixed
            end           
            `EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP, `EXE_SUB_OP, `EXE_SUBU_OP:begin  //�ӷ�����
                arithmeticres = result_sum;
            end
            
            /*`EXE_CLZ_OP:begin    //��������  clz zero 0
                arithmeticres = reg1_i[31] ? 0 : reg1_i[30] ? 1 :
                                reg1_i[29] ? 2 : reg1_i[28] ? 3 :
                                reg1_i[27] ? 4 : reg1_i[26] ? 5 :
                                reg1_i[25] ? 6 : reg1_i[24] ? 7 :
                                reg1_i[23] ? 8 : reg1_i[22] ? 9 :
                                reg1_i[21] ? 10 : reg1_i[20] ? 11 :
                                reg1_i[19] ? 12 : reg1_i[18] ? 13 :
                                reg1_i[17] ? 14 : reg1_i[16] ? 15 :
                                reg1_i[15] ? 16 : reg1_i[14] ? 17 :
                                reg1_i[13] ? 18 : reg1_i[12] ? 19 :
                                reg1_i[11] ? 20 : reg1_i[10] ? 21 :
                                reg1_i[9] ? 22 : reg1_i[8] ? 23 :
                                reg1_i[7] ? 24 : reg1_i[6] ? 25 :
                                reg1_i[5] ? 26 : reg1_i[4] ? 27 :
                                reg1_i[3] ? 28 : reg1_i[2] ? 29 :
                                reg1_i[1] ? 30 : reg1_i[0] ? 31 : 32;
            end
            `EXE_CLO_OP:begin
                arithmeticres = ~reg1_i[31] ? 0 : ~reg1_i[30] ? 1 :
                                ~reg1_i[29] ? 2 : ~reg1_i[28] ? 3 :
                                ~reg1_i[27] ? 4 : ~reg1_i[26] ? 5 :
                                ~reg1_i[25] ? 6 : ~reg1_i[24] ? 7 :
                                ~reg1_i[23] ? 8 : ~reg1_i[22] ? 9 :
                                ~reg1_i[21] ? 10 : ~reg1_i[20] ? 11 :
                                ~reg1_i[19] ? 12 : ~reg1_i[18] ? 13 :
                                ~reg1_i[17] ? 14 : ~reg1_i[16] ? 15 :
                                ~reg1_i[15] ? 16 : ~reg1_i[14] ? 17 :
                                ~reg1_i[13] ? 18 : ~reg1_i[12] ? 19 :
                                ~reg1_i[11] ? 20 : ~reg1_i[10] ? 21 :
                                ~reg1_i[9] ? 22 : ~reg1_i[8] ? 23 :
                                ~reg1_i[7] ? 24 : ~reg1_i[6] ? 25 :
                                ~reg1_i[5] ? 26 : ~reg1_i[4] ? 27 :
                                ~reg1_i[3] ? 28 : ~reg1_i[2] ? 29 :
                                ~reg1_i[1] ? 30 : ~reg1_i[0] ? 31 : 32;
            end*/
            default:begin
                arithmeticres = `ZeroWord;
            end 
        endcase     //end case aluop_i
    end
end
        

/*always @(*) begin
    if(rst == `RstEnable) begin
        stallreq_for_div = `NoStop;
        div_opdata1_o = `ZeroWord;
        div_opdata2_o = `ZeroWord;
        div_start_o = `DivStop;
        signed_div_o = 1'b0;
    end else begin
        stallreq_for_div = `NoStop;
        div_opdata1_o = `ZeroWord;
        div_opdata2_o = `ZeroWord;
        div_start_o = `DivStop;
        signed_div_o = 1'b0;
        case (aluop_i)
            `EXE_DIV_OP:begin
                if(div_ready_i == `DivResultNotReady)begin
                    div_opdata1_o = reg1_i;
                    div_opdata2_o = reg2_i;
                    div_start_o = `DivStart;
                    signed_div_o = 1'b1 ;
                    stallreq_for_div = `Stop;
                end else if(div_ready_i == `DivResultReady) begin
                    div_opdata1_o = reg1_i;
                    div_opdata2_o = reg2_i;
                    div_start_o = `DivStop;
                    signed_div_o = 1'b1 ;
                    stallreq_for_div = `NoStop;
                end else begin
                    div_opdata1_o = `ZeroWord;
                    div_opdata2_o = `ZeroWord;
                    div_start_o = `DivStop;
                    signed_div_o = 1'b0 ;
                    stallreq_for_div = `NoStop;
                end
            end 
            `EXE_DIVU_OP:begin
                if(div_ready_i == `DivResultNotReady)begin
                    div_opdata1_o = reg1_i;
                    div_opdata2_o = reg2_i;
                    div_start_o = `DivStart;
                    signed_div_o = 1'b0 ;
                    stallreq_for_div = `Stop;
                end else if(div_ready_i == `DivResultReady) begin
                    div_opdata1_o = reg1_i;
                    div_opdata2_o = reg2_i;
                    div_start_o = `DivStop;
                    signed_div_o = 1'b0 ;
                    stallreq_for_div = `NoStop;
                end else begin
                    div_opdata1_o = `ZeroWord;
                    div_opdata2_o = `ZeroWord;
                    div_start_o = `DivStop;
                    signed_div_o = 1'b0 ;
                    stallreq_for_div = `NoStop;
                end
            end
            default: begin
            end
        endcase
    end
end
*/   
   
//still need to be fixed    
always @(*) begin
    if (rst == `RstEnable) begin
        whilo_o = `WriteDisable;
        hi_o = `ZeroWord;
        lo_o = `ZeroWord;
        is_to_hi = 1'b0;
         is_to_lo =1'b0 ;
    /*end else if ((aluop_i == `EXE_DIV_OP) || (aluop_i == `EXE_DIVU_OP)) begin
        whilo_o = `WriteEnable;
        hi_o = div_result_i[63:32];
        lo_o = div_result_i[31:0]; */
//    end else if (aluop_i == `EXE_MULT_OP) begin
//        whilo_o = `WriteEnable;
//        hi_o = mulres[63:32];
//        lo_o = mulres[31:0];
//    end else if(aluop_i == `EXE_MULTU_OP) begin
//        whilo_o = `WriteEnable;
//        hi_o = mulres_u[63:32];
//        lo_o = mulres_u[31:0];  
    end else if (aluop_i == `EXE_MTHI_OP) begin
        whilo_o = `WriteEnable;
        is_to_hi = 1'b1;
        is_to_lo =1'b0 ;
        hi_o = reg1_i;
        lo_o = lo_i;
    end else if (aluop_i == `EXE_MTLO_OP) begin
        whilo_o = `WriteEnable;
        is_to_hi = 1'b1;
        is_to_lo =1'b1 ;
        hi_o = hi_i;
        lo_o = reg1_i;
    end else begin
        whilo_o = `WriteDisable;
         is_to_hi = 1'b0;
         is_to_lo =1'b0 ;
        hi_o = `ZeroWord;
        lo_o = `ZeroWord;
    end
end
    
    
always @(*) begin
    waddr_o = waddr_i;
    we_o = we_i;
    ovassert = 1'b0;
    //���Ϊadd��addi��sub��subi�����������д��Ĵ���
    
    case (alusel_i)
        `EXE_RES_LOGIC:begin
            wdata_o = logicout;   //��wdata_o�д��������?

        end 
        `EXE_RES_SHIFT:begin
            wdata_o = shiftres;
        end
        `EXE_RES_ARITHMETIC:begin       //���˷�������м�����ָ��?
            wdata_o =arithmeticres;
        //     if (((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) || (aluop_i == `EXE_SUB_OP) ||
        // (aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1) ) begin
        //     we_o = `WriteDisable;
        //     ovassert = 1'b1;           //���������?
        // end else begin
        //     we_o = we_i;
        //     ovassert = 1'b0;
        //     end
        case(aluop_i)
                `EXE_ADD_OP,`EXE_ADDI_OP,`EXE_SUB_OP:   begin
                    if(ov_sum) begin
                        we_o = `WriteDisable;
                        ovassert = 1'b1;
                    end else begin
                        we_o = we_i;
                        ovassert = 1'b0;
                    end
                  end
                  default: begin
                        we_o = we_i;
                        ovassert = 1'b0;
                    end
                  endcase

        end        
//        `EXE_RES_MUL: begin
//            case(aluop_i)
//                `EXE_MULT:    wdata_o = mulres[31:0];
//                `EXE_MULTU:   wdata_o = mulres_u[31:0];
//                 default:   wdata_o =`ZeroWord;
//               endcase
//         end
        `EXE_RES_JUMP_BRANCH: begin;
            wdata_o = jbres;
         end
        `EXE_RES_MOVE: begin
            wdata_o = moveres;
            case(aluop_i)
                `EXE_MOVZ_OP: if(reg2_i != `ZeroWord) we_o = `WriteDisable; 
                `EXE_MOVN_OP: if(reg2_i == `ZeroWord) we_o = `WriteDisable;     
                default:  ;
            endcase
         end    
        default: begin
            wdata_o =`ZeroWord;
        end
    endcase
end
    


//JB  
  
   always@ (*) begin
    if(rst == `RstEnable) begin
        npc_actual = `ZeroWord;
        branch_flag_actual = `NotBranch;
        predict_flag = `ValidPrediction;
        branch_info = {`ZeroWord,`NotBranch,`ZeroWord,2'b00};    
        predict_true = 1'b0;
    end else begin
        case(aluop_i)
            `EXE_J_OP: begin
                branch_flag_actual = `Branch;
//                npc_actual = {pc_4[31:28],imm_i[27:0]};
                npc_actual = bru_addr;
                //npc_actual = pc_4;
                predict_flag = bpu_predict_info_i[32] == `Branch && bpu_predict_info_i[31:0] == bru_addr ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_CAL};
                predict_true = bpu_predict_info_i[32] == `Branch && bpu_predict_info_i[31:0] == bru_addr ? `ValidPrediction : `InValidPrediction;
             end         
            `EXE_JAL_OP: begin
                branch_flag_actual = `Branch;
//               npc_actual = {pc_4[31:28],imm_i[27:0]};
                npc_actual = bru_addr;
               // npc_actual = pc_4;
                predict_flag = bpu_predict_info_i[32] == `Branch && bpu_predict_info_i[31:0] == bru_addr ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_CAL};
                predict_true = bpu_predict_info_i[32] == `Branch && bpu_predict_info_i[31:0] == bru_addr ? `ValidPrediction : `InValidPrediction;
             end   
            `EXE_JR_OP: begin
                branch_flag_actual = `Branch;
//                npc_actual = reg1_i;
                npc_actual = bru_addr;
                predict_flag = bpu_predict_info_i[32] == `Branch && bpu_predict_info_i[31:0] == bru_addr ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_RET};
                predict_true = bpu_predict_info_i[32] == `Branch && bpu_predict_info_i[31:0] == bru_addr ? `ValidPrediction : `InValidPrediction;
             end 
            `EXE_JALR_OP: begin
                branch_flag_actual = `Branch;
//                npc_actual = reg1_i;
                npc_actual = bru_addr;
                predict_flag = bpu_predict_info_i[32] == `Branch && bpu_predict_info_i[31:0] == bru_addr ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_CAL};
                predict_true = bpu_predict_info_i[32] == `Branch && bpu_predict_info_i[31:0] == bru_addr ? `ValidPrediction : `InValidPrediction;
             end 
            `EXE_BEQ_OP: begin
                branch_flag_actual = (reg1_i == reg2_i) ? `Branch : `NotBranch;
//                npc_actual = pc_4 + imm_i;
                npc_actual = bru_addr;
               // npc_actual = pc_4;
                predict_flag = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_NUL};       
                predict_true = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;  
             end
             `EXE_BGTZ_OP: begin
                branch_flag_actual = (reg1_i[31] == 1'b0)&&(reg1_i != 32'b0) ? `Branch : `NotBranch;
//                npc_actual = pc_4 + imm_i;
                npc_actual = bru_addr;
                //npc_actual = pc_4;
                predict_flag = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_NUL};  
                predict_true = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;     
             end
             `EXE_BLEZ_OP: begin
                branch_flag_actual = (reg1_i[31] == 1'b1)||(reg1_i == 32'b0) ? `Branch : `NotBranch;
//                npc_actual = pc_4 + imm_i;
                npc_actual = bru_addr;
                //npc_actual = pc_4;
                predict_flag = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_NUL};                
                predict_true = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;       
             end
             `EXE_BNE_OP: begin
                branch_flag_actual = (reg1_i != reg2_i) ? `Branch : `NotBranch;
//                npc_actual = pc_4 + imm_i;
                npc_actual = bru_addr;
                //npc_actual = pc_4;
                predict_flag = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_NUL}; 
                predict_true = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
             end
             `EXE_BGEZ_OP: begin
                branch_flag_actual = (reg1_i[31] == 1'b0) ? `Branch : `NotBranch;
//                npc_actual = pc_4 + imm_i;
                npc_actual = bru_addr;
                //npc_actual = pc_4;
                predict_flag = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_NUL};      
                predict_true = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;          
             end
             `EXE_BGEZAL_OP: begin
                branch_flag_actual = (reg1_i[31] == 1'b0) ? `Branch : `NotBranch;
//                npc_actual = pc_4 + imm_i;
                npc_actual = bru_addr;
                //npc_actual = pc_4;
                predict_flag = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_CAL};                
                predict_true = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
             end 
             `EXE_BLTZ_OP: begin
                branch_flag_actual = (reg1_i[31] == 1'b1) ? `Branch : `NotBranch;
//                npc_actual = pc_4 + imm_i;
                npc_actual = bru_addr;
                //npc_actual = pc_4;
                predict_flag = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_NUL};    
                predict_true = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;                         
             end  
             `EXE_BLTZAL_OP: begin
                branch_flag_actual = (reg1_i[31] == 1'b1) ? `Branch : `NotBranch;
//                npc_actual = pc_4 + imm_i;
                npc_actual = bru_addr;
                   //npc_actual = pc_4;
                predict_flag = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_CAL};                
                predict_true = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
             end  
             default: begin
                npc_actual = `ZeroWord;
                branch_flag_actual = `NotBranch;
                predict_flag = ~bpu_predict_info_i[32];//7.26_dqy   ??
                branch_info = {`ZeroWord,`NotBranch,`ZeroWord,2'b00};  
                predict_true = 1'b0;                
            end
          endcase  
         end
      end
      
     
       wire[`InstAddrBus] pc_8;
         assign pc_8 = pc_i + 8;
    always@(*) begin
        if(rst== `RstEnable) jbres = `ZeroWord;
        else if(aluop_i == `EXE_JAL_OP || aluop_i == `EXE_JALR_OP || aluop_i == `EXE_BGEZAL_OP || aluop_i == `EXE_BLTZAL_OP) jbres = pc_8;
        else jbres = `ZeroWord;
    end     
    
  
    
endmodule
