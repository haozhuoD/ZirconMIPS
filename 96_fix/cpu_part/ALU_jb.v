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
        

        

        
        output  reg[`RegAddrBus]     waddr_o,
        output  reg                                 we_o,
        output  reg[`RegBus]              wdata_o,
        output  reg[`RegBus]              hi_o,
        output  reg[`RegBus]              lo_o,
        output  reg                                 whilo_o,                                     
         
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
        
        
        wire    ov_sum;   //保存溢出情况
        wire [`RegBus]   result_sum;
        
        //reg stallreq_for_div;    
        reg ovassert;
        
        wire reg1_lt_reg2;
        
        assign exception_type_o = {exception_type_i[31:13],ovassert,exception_type_i[11:0]};
   
        
   
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
            
            default: begin  moveres = `ZeroWord;
            end
        endcase
    end
end

wire [`RegBus]  reg2_i_mux;
assign reg2_i_mux =((aluop_i ==`EXE_SUB_OP) || 
                    (aluop_i ==`EXE_SUBU_OP)||
                    (aluop_i ==`EXE_SLT_OP))?
                    (~reg2_i)+1 : reg2_i;
                    
assign result_sum = reg1_i +reg2_i_mux;

//�����Ƿ����?  ͨ���������ͽ�������������ж�?
assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31] && result_sum[31])
                || (reg1_i[31] && reg2_i_mux[31] && !result_sum[31]));

assign reg1_lt_reg2 = ((aluop_i == `EXE_SLT_OP)) ?
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
            
            default:begin
                arithmeticres = `ZeroWord;
            end 
        endcase     //end case aluop_i
    end
end
        

   
//still need to be fixed    
always @(*) begin
    if (rst == `RstEnable) begin
        whilo_o = `WriteDisable;
        hi_o = `ZeroWord;
        lo_o = `ZeroWord;
        is_to_hi = 1'b0;
         is_to_lo =1'b0 ; 
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
                npc_actual = bru_addr;
                predict_flag = bpu_predict_info_i[32] == `Branch && bpu_predict_info_i[31:0] == bru_addr ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_CAL};
                predict_true = bpu_predict_info_i[32] == `Branch && bpu_predict_info_i[31:0] == bru_addr ? `ValidPrediction : `InValidPrediction;
             end         
            `EXE_JAL_OP: begin
                branch_flag_actual = `Branch;
                npc_actual = bru_addr;
                predict_flag = bpu_predict_info_i[32] == `Branch && bpu_predict_info_i[31:0] == bru_addr ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_CAL};
                predict_true = bpu_predict_info_i[32] == `Branch && bpu_predict_info_i[31:0] == bru_addr ? `ValidPrediction : `InValidPrediction;
             end   
            `EXE_JR_OP: begin
                branch_flag_actual = `Branch;
                npc_actual = bru_addr;
                predict_flag = bpu_predict_info_i[32] == `Branch && bpu_predict_info_i[31:0] == bru_addr ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_RET};
                predict_true = bpu_predict_info_i[32] == `Branch && bpu_predict_info_i[31:0] == bru_addr ? `ValidPrediction : `InValidPrediction;
             end 
            `EXE_JALR_OP: begin
                branch_flag_actual = `Branch;
                npc_actual = bru_addr;
                predict_flag = bpu_predict_info_i[32] == `Branch && bpu_predict_info_i[31:0] == bru_addr ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_CAL};
                predict_true = bpu_predict_info_i[32] == `Branch && bpu_predict_info_i[31:0] == bru_addr ? `ValidPrediction : `InValidPrediction;
             end 
            `EXE_BEQ_OP: begin
                branch_flag_actual = (reg1_i == reg2_i) ? `Branch : `NotBranch;
                npc_actual = bru_addr;
                predict_flag = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_NUL};       
                predict_true = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;  
             end
             `EXE_BGTZ_OP: begin
                branch_flag_actual = (reg1_i[31] == 1'b0)&&(reg1_i != 32'b0) ? `Branch : `NotBranch;
                npc_actual = bru_addr;
                predict_flag = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_NUL};  
                predict_true = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;     
             end
             `EXE_BLEZ_OP: begin
                branch_flag_actual = (reg1_i[31] == 1'b1)||(reg1_i == 32'b0) ? `Branch : `NotBranch;
                npc_actual = bru_addr;
                predict_flag = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_NUL};                
                predict_true = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;       
             end
             `EXE_BNE_OP: begin
                branch_flag_actual = (reg1_i != reg2_i) ? `Branch : `NotBranch;
                npc_actual = bru_addr;
                predict_flag = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_NUL}; 
                predict_true = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
             end
             `EXE_BGEZ_OP: begin
                branch_flag_actual = (reg1_i[31] == 1'b0) ? `Branch : `NotBranch;
                npc_actual = bru_addr;
                predict_flag = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_NUL};      
                predict_true = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;          
             end
             `EXE_BGEZAL_OP: begin
                branch_flag_actual = (reg1_i[31] == 1'b0) ? `Branch : `NotBranch;
                npc_actual = bru_addr;
                predict_flag = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_CAL};                
                predict_true = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
             end 
             `EXE_BLTZ_OP: begin
                branch_flag_actual = (reg1_i[31] == 1'b1) ? `Branch : `NotBranch;
                npc_actual = bru_addr;
                predict_flag = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_NUL};    
                predict_true = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;                         
             end  
             `EXE_BLTZAL_OP: begin
                branch_flag_actual = (reg1_i[31] == 1'b1) ? `Branch : `NotBranch;
                npc_actual = bru_addr;
                predict_flag = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
                branch_info = {pc_i,branch_flag_actual,bru_addr,`BTYPE_CAL};                
                predict_true = bpu_predict_info_i[32] == `Branch && branch_flag_actual == `Branch && bpu_predict_info_i[31:0] == bru_addr ||
                                bpu_predict_info_i[32] == `NotBranch && branch_flag_actual == `NotBranch ? `ValidPrediction : `InValidPrediction;
             end  
             default: begin
                npc_actual = `ZeroWord;
                branch_flag_actual = `NotBranch;
                predict_flag = ~bpu_predict_info_i[32];//7.26_dqy   
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
