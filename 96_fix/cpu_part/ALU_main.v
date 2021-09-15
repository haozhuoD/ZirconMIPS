//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/08/03 16:11:57
// Design Name: 
// Module Name: ALU_main
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

module ALU_main(
input       rst,

        input[`AluOpBus]             aluop_i,
        input[`AluSelBus]             alusel_i,
        input[`RegBus]                  reg1_i,
        input[`RegBus]                  reg2_i,
        input[`RegAddrBus]         waddr_i,
        input                                     we_i,
        
        input[`RegBus]          hi_i,
        input[`RegBus]          lo_i,

        input[`DoubleRegBus]    div_result_i,
        input                   div_ready_i,
        input[`DoubleRegBus]    mult_result_i,
        input                   mult_ready_i    ,
        
        input[`RegBus]                  imm_i,

        input                        LLbit_i,
        
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
        input[31:0]              exception_type_i,
        
        output  reg[`RegAddrBus]     waddr_o,
        output  reg                                 we_o,
        output  reg[`RegBus]              wdata_o,
        output  reg[`RegBus]              hi_o,
        output  reg[`RegBus]              lo_o,
        output  reg                                 whilo_o,                                     
         
        output  reg[`RegBus]            div_opdata1_o,
        output  reg[`RegBus]            div_opdata2_o,
        output  reg                               div_start_o,
        output  reg                               signed_div_o,
        
        output  reg[`RegBus]            mult_opdata1_o,
        output  reg[`RegBus]            mult_opdata2_o,
        output  reg                     mult_start_o,
        output  reg                     signed_mult_o,
        

        
        output[`RegBus]                    mem_addr_o,
        output  reg[`RegBus]                               mem_raddr_o,
        output  reg[`RegBus]                               mem_waddr_o,
        output  reg                               mem_we_o,
        output  reg [3:0]                              mem_sel_o,
        output  reg [`RegBus]                              mem_data_o,
        output  reg                               mem_re_o,
        
        output   reg                              LLbit_o,
        output   reg                              LLbit_we_o,
        
        output  reg[`RegAddrBus]                cp0_raddr_o,
        output  reg                             cp0_we_o,
        output  reg[`RegAddrBus]                cp0_waddr_o,
        output  reg[`RegBus]                    cp0_wdata_o,
        
        output[31:0]                            exception_type_o,
        output  reg                                 lb_type,

        output reg main_whi,
        output reg main_wlo,
        output                                       stallreq 
         
    );
        

        
        reg[`RegBus]        logicout;
        reg[`RegBus]        shiftres;
        reg[`RegBus]        moveres;
        reg[`RegBus]        arithmeticres;
        reg[`RegBus]        scres;

        
        wire    ov_sum;   //保存溢出情况 加法溢出
        wire [`RegBus]   result_sum;
        
        reg stallreq_for_div;    
        reg stallreq_for_mfc0;
        reg stallreq_for_mult;
        
        reg trapassert;  //自陷异常
        reg ovassert;    //溢出异常
        reg mem_re;
        reg mem_we;
        reg adel_exception;
        reg ades_exception;
        
        wire[`InstAddrBus] pc_4;
        wire[`InstAddrBus] pc_8;
        
        wire reg1_lt_reg2;
        
              
        
        assign stallreq = stallreq_for_div|stallreq_for_mfc0|stallreq_for_mult ; //⛵还有异常相关指令需要添�?
        assign mem_addr_o = reg1_i+imm_i;
        
        assign exception_type_o = {exception_type_i[31:14],trapassert,ovassert,exception_type_i[11:6],ades_exception,adel_exception | exception_type_i[4],exception_type_i[3:0]};
        
   always @(*) mem_re_o = mem_re && ~|exception_type_o && mem_exception_flag_i == `ExceptionNotInduced;
   always @(*) mem_we_o = mem_we && ~|exception_type_o && mem_exception_flag_i == `ExceptionNotInduced;     
        
       
   
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
    
//移位运算符会增加组合逻辑延迟吗？    
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
    stallreq_for_mfc0 = `NoStop;
    cp0_raddr_o = 5'b00000;
    if (rst ==`RstEnable) begin
        moveres = `ZeroWord;
    end else begin
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
            `EXE_MFC0_OP:begin
                cp0_raddr_o = cp0_addr_i;
                moveres = cp0_data_i;
                // slove cp0_regs data relate
                if (mem_cp0_we_i == `WriteEnable && mem_cp0_waddr_i == cp0_addr_i && mem_cp0_wsel_i == cp0_sel_i) begin
                    stallreq_for_mfc0 = `Stop;
                    moveres = mem_cp0_wdata_i;
                end else if (commit_cp0_we_i == `WriteEnable && commit_cp0_waddr_i == cp0_addr_i && commit_cp0_wsel_i == cp0_sel_i) begin
                    stallreq_for_mfc0 = `Stop;
                    moveres = commit_cp0_wdata_i;
                end
            end
            default: begin  moveres = `ZeroWord;
            end
        endcase
    end
end

wire [`RegBus]  reg2_i_mux;
assign reg2_i_mux =((aluop_i ==`EXE_SUB_OP) || 
                    (aluop_i ==`EXE_SUBU_OP)||
                    (aluop_i ==`EXE_SLT_OP) ||
                    (aluop_i ==`EXE_TLT_OP) ||
                    (aluop_i ==`EXE_TLTI_OP)||
                    (aluop_i ==`EXE_TGE_OP) ||
                    (aluop_i ==`EXE_TGEI_OP)) ?
                    (~reg2_i)+1 : reg2_i;
                    
assign result_sum = reg1_i + reg2_i_mux;

//�����Ƿ����?  ͨ���������ͽ�������������ж�?
assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31] && result_sum[31])
                || (reg1_i[31] && reg2_i_mux[31] && !result_sum[31]));

assign reg1_lt_reg2 = ((aluop_i == `EXE_SLT_OP) ||
                        (aluop_i ==`EXE_TLT_OP) ||
                        (aluop_i ==`EXE_TLTI_OP)||
                        (aluop_i ==`EXE_TGE_OP) ||
                        (aluop_i ==`EXE_TGEI_OP)) ?
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
                arithmeticres = reg1_lt_reg2;             // need to be fixed?
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

         
            
always @(*) begin
    if(rst == `RstEnable)begin
        trapassert = `TrapNotAssert;
    end else begin
        trapassert = `TrapNotAssert;
        case (aluop_i)
            `EXE_TEQ_OP,`EXE_TEQI_OP:begin
                if(reg1_i == reg2_i )begin
                    trapassert = `TrapAssert;
                end
            end
            `EXE_TGE_OP,`EXE_TGEI_OP,`EXE_TGEIU_OP,`EXE_TGEU_OP:begin
                if (~reg1_lt_reg2)begin
                    trapassert = `TrapAssert;
                end
            end
            `EXE_TLT_OP,`EXE_TLTI_OP,`EXE_TLTIU_OP,`EXE_TLTU_OP:begin
                if(reg1_lt_reg2)begin
                    trapassert = `TrapAssert;
                end
            end
            `EXE_TNE_OP,`EXE_TNEI_OP:begin
                if(reg2_i != reg1_i)begin
                    trapassert = `TrapAssert;
                end
            end
            default:begin
                trapassert = `TrapNotAssert;
            end 
        endcase
    end
end            
            
            
        

always @(*) begin
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

always @(*) begin
  if(rst) begin
    stallreq_for_mult = `NoStop;
    mult_opdata1_o = `ZeroWord;
    mult_opdata2_o = `ZeroWord;
    mult_start_o = 1'b0;      
    signed_mult_o = 1'b0;
  end else begin
    stallreq_for_mult = `NoStop;
    mult_opdata1_o = `ZeroWord;
    mult_opdata2_o = `ZeroWord;
    mult_start_o = 1'b0;
    signed_mult_o = 1'b0;  
    case(aluop_i)
        `EXE_MUL_OP,`EXE_MULT_OP: begin
            mult_opdata1_o = reg1_i;  
            mult_opdata2_o = reg2_i;  
            mult_start_o = 1'b1;         
            signed_mult_o = 1'b1;         
            if(~mult_ready_i) begin     
                stallreq_for_mult = `Stop;
                mult_start_o = 1'b1; 
            end else  begin   
                stallreq_for_mult = `NoStop; 
                mult_start_o = 1'b0; 
            end
         end    
         `EXE_MULTU_OP:  begin
             mult_opdata1_o = reg1_i;  
             mult_opdata2_o = reg2_i;  
             mult_start_o = 1'b1;         
             signed_mult_o = 1'b0;            
             if(~mult_ready_i) begin                       
                stallreq_for_mult = `Stop;
                mult_start_o = 1'b1;
             end else  begin   
                stallreq_for_mult = `NoStop; 
                mult_start_o = 1'b0;
            end
         end    
         default: begin
         end   
         endcase   
      end      
 end           
   
    
  
    
    always @ (*) begin
        if (rst == `RstEnable) begin
             mem_raddr_o = `ZeroWord;
             mem_waddr_o = `ZeroWord;
            mem_we = `WriteDisable;
            mem_sel_o = 4'b0000;
            mem_data_o = `ZeroWord;
            mem_re = `ReadDisable;
            scres = `ZeroWord;
            LLbit_o = 1'b0;
            LLbit_we_o = `WriteDisable;
            adel_exception = 1'b0;
            ades_exception = 1'b0;
            lb_type = 1'b0;
        end else begin
             mem_raddr_o = `ZeroWord;
             mem_waddr_o = `ZeroWord;
            mem_we = `WriteDisable;
            mem_sel_o = 4'b0000;
            mem_data_o = `ZeroWord;
            mem_re = `ReadDisable;
            scres = `ZeroWord;
            LLbit_o = 1'b0;
            LLbit_we_o = `WriteDisable;
            adel_exception = 1'b0;
            ades_exception = 1'b0;
            lb_type = 1'b0;
            case (aluop_i)
            `EXE_LB_OP: begin
                 mem_raddr_o = mem_addr_o;
                mem_we = `WriteDisable;
                mem_re = `ReadEnable;
                lb_type = 1'b1;
              
            end
            `EXE_LBU_OP: begin
                 mem_raddr_o = mem_addr_o;
                mem_we = `WriteDisable;
                mem_re = `ReadEnable;
                lb_type = 1'b1;
             
            end
            `EXE_LH_OP: begin
                 mem_raddr_o = mem_addr_o;

                mem_we = `WriteDisable;
                mem_re = `ReadEnable;
                adel_exception = mem_addr_o[0];
                
            end
            `EXE_LHU_OP: begin
                 mem_raddr_o = mem_addr_o;

                mem_we = `WriteDisable;
                mem_re = `ReadEnable;
                adel_exception = mem_addr_o[0];
            
            end
            `EXE_LW_OP: begin
                 mem_raddr_o = mem_addr_o;
                mem_we = `WriteDisable;
                mem_re = `ReadEnable;
                adel_exception = mem_addr_o[1:0] != 2'b00;
            end
            `EXE_LWL_OP: begin
				 mem_raddr_o = {mem_addr_o[31:2], 2'b00};
				mem_we = `WriteDisable;
				mem_re = `ReadEnable;
            end
            `EXE_LWR_OP: begin
				 mem_raddr_o = {mem_addr_o[31:2], 2'b00};
				mem_we = `WriteDisable;
				mem_re = `ReadEnable;
            end
            `EXE_SB_OP: begin
                 mem_waddr_o = mem_addr_o;
                mem_we = `WriteEnable;
                mem_data_o = {reg2_i[7:0], reg2_i[7:0], reg2_i[7:0], reg2_i[7:0]};
                case (mem_addr_o[1:0])
                    2'b00: mem_sel_o = 4'b0001;
                    2'b01: mem_sel_o = 4'b0010;
                    2'b10: mem_sel_o = 4'b0100;
                    2'b11: mem_sel_o = 4'b1000;
                    default: ;
                endcase
            end
            `EXE_SH_OP: begin
                 mem_waddr_o = mem_addr_o;
                mem_we = `WriteEnable;
                mem_data_o = {reg2_i[15:0], reg2_i[15:0]};
                case (mem_addr_o[1:0])
                    2'b00: mem_sel_o = 4'b0011;
                    2'b10: mem_sel_o = 4'b1100;
                    default: begin
                        mem_sel_o = 4'b0000;
                        ades_exception = 1'b1;
                    end
                endcase
            end
            `EXE_SW_OP: begin
                 mem_waddr_o = mem_addr_o;
                mem_we = `WriteEnable;
                mem_data_o = reg2_i[31:0];
                mem_sel_o = 4'b1111;
                ades_exception = mem_addr_o[1:0] != 2'b00;
            end
            `EXE_SWL_OP: begin
				 mem_waddr_o = {mem_addr_o[31:2], 2'b00};
				mem_we = `WriteEnable;
				case (mem_addr_o[1:0])
                    2'b00: begin
                        mem_sel_o = 4'b0001;
                        mem_data_o = {24'b0, reg2_i[31:24]};
                    end
                    2'b01: begin
                        mem_sel_o = 4'b0011;
                        mem_data_o = {16'b0, reg2_i[31:16]};
                    end
                    2'b10: begin
                        mem_sel_o = 4'b0111;
                        mem_data_o = {8'b0, reg2_i[31:8]};
                    end
                    2'b11: begin
                        mem_sel_o = 4'b1111;
                        mem_data_o = reg2_i;
                    end
                    default: ;
                endcase				
            end
            `EXE_SWR_OP: begin
				 mem_waddr_o = {mem_addr_o[31:2], 2'b00};
				mem_we = `WriteEnable;
				case (mem_addr_o[1:0])
                    2'b00: begin
                        mem_sel_o = 4'b1111;
                        mem_data_o = reg2_i;
                    end
                    2'b01: begin
                        mem_sel_o = 4'b1110;
                        mem_data_o = {reg2_i[23:0], 8'b0};
                    end
                    2'b10: begin
                        mem_sel_o = 4'b1100;
                        mem_data_o = {reg2_i[15:0], 16'b0};
                    end
                    2'b11: begin
                        mem_sel_o = 4'b1000;
                        mem_data_o = {reg2_i[7:0], 24'b0};
                    end
                    default: ;
                endcase				
            end
            `EXE_LL_OP: begin
                 mem_waddr_o = mem_addr_o;
                mem_we = `WriteDisable;
                mem_re = `ReadEnable;
                LLbit_o = 1'b1;
                LLbit_we_o = `WriteEnable;
            end
            `EXE_SC_OP: begin
                if (LLbit_i == 1'b1) begin
                     mem_waddr_o = mem_addr_o;
                    mem_we = `WriteEnable;
                    scres = 32'b1;
                    mem_sel_o = 4'b1111;
                    mem_data_o = reg2_i;
                    LLbit_o = 1'b0;
                    LLbit_we_o = `WriteEnable;
                end else scres = 32'b0;
            end
            default: ;
            endcase
        end
    end
    
    
            
//still need to be fixed    
always @(*) begin
    if (rst == `RstEnable) begin
        whilo_o = `WriteDisable;
        hi_o = `ZeroWord;
        lo_o = `ZeroWord;
        main_whi = 1'b0;
        main_wlo = 1'b0;
    end else if ((aluop_i == `EXE_DIV_OP) || (aluop_i == `EXE_DIVU_OP)) begin
        whilo_o = `WriteEnable;
        hi_o = div_result_i[63:32];
        lo_o = div_result_i[31:0];
        main_whi = 1'b1;
        main_wlo = 1'b1;
    end else if ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MULTU_OP)) begin
        whilo_o = `WriteEnable;
        hi_o = mult_result_i[63:32];
        lo_o = mult_result_i[31:0];
        main_whi = 1'b1;
        main_wlo = 1'b1;
    end else if (aluop_i == `EXE_MTHI_OP) begin
        whilo_o = `WriteEnable;
        main_whi = 1'b1;
        main_wlo = 1'b0;
        hi_o = reg1_i;
        lo_o = lo_i;
    end else if (aluop_i == `EXE_MTLO_OP) begin
        whilo_o = `WriteEnable;
        main_whi = 1'b0;
        main_wlo = 1'b1;
        hi_o = hi_i;
        lo_o = reg1_i;
    end else begin
        whilo_o = `WriteDisable;
        main_whi = 1'b0;
        main_wlo = 1'b0;
        hi_o = `ZeroWord;
        lo_o = `ZeroWord;
    end
end

always @(*) begin
    if(rst == `RstEnable) begin
        cp0_we_o = `WriteDisable;
        cp0_waddr_o = `NOPRegAddr;
        cp0_wdata_o = `ZeroWord;
    end else if(aluop_i == `EXE_MTC0_OP) begin
        cp0_we_o = `WriteEnable;
        cp0_waddr_o = cp0_addr_i;
        cp0_wdata_o = reg2_i;
    end else begin
        cp0_we_o = `WriteDisable;
        cp0_waddr_o = `NOPRegAddr;
        cp0_wdata_o = `ZeroWord;
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
        `EXE_RES_MUL: begin
            wdata_o = mult_result_i[31:0];

            end       
        `EXE_RES_MOVE: begin
            wdata_o = moveres;
            case(aluop_i)
                `EXE_MOVZ_OP: if(reg2_i != `ZeroWord) we_o = `WriteDisable;
                `EXE_MOVN_OP: if(reg2_i == `ZeroWord) we_o = `WriteDisable;   
                default:   ;
            endcase
         end    

        `EXE_RES_LOAD_STORE: begin
            wdata_o = scres;
            end
        default: begin
            wdata_o =`ZeroWord;
        end
    endcase
end

    
endmodule