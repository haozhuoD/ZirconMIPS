`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/20 16:28:03
// Design Name: 
// Module Name: id
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

module id(
    input rst,
    input [`InstAddrBus]    pc_i,
    input [`InstBus]              inst_i,
    
    input[`RegBus]              reg1_data_i,
    input[`RegBus]              reg2_data_i,
    
    //前递解决数据相关
    input[`RegAddrBus]      ex_waddr1_i,
    input[`RegAddrBus]      ex_waddr2_i,
    input                                  ex_we1_i,
    input                                  ex_we2_i,
    input[`RegBus]               ex_wdata1_i,
    input[`RegBus]               ex_wdata2_i,
    input[`RegAddrBus]      mem_waddr1_i,
    input[`RegAddrBus]      mem_waddr2_i,
    input                                  mem_we1_i,
    input                                  mem_we2_i,
    input[`RegBus]               mem_wdata1_i,
    input[`RegBus]               mem_wdata2_i,
    
//    input[`RegAddrBus]          commit_waddr1_i,
//    input[`RegAddrBus]          commit_waddr2_i,
//    input                       commit_we1_i,
//    input                       commit_we2_i,
//    input[`RegBus]               commit_wdata1_i,
//    input[`RegBus]               commit_wdata2_i,
    
    
    //访存相关   
    // input is_load,   
    input is_load1,   
    input is_load2,
    //output reg[`RegAddrBus] reg1_addr_o,
    //output reg[`RegAddrBus] reg2_addr_o,

    output reg is_div,  //是否为除法指令
    output reg is_mul,
    output reg is_jb,
    output reg is_ls,
    output reg is_cp0,
   
    output reg[`AluOpBus]   aluop_o, 
    output reg[`AluSelBus]  alusel_o,
    output reg[`RegBus]     reg1_o,
    output reg[`RegBus]     reg2_o,
    output reg                       reg1_read_o,
    output reg                       reg2_read_o,
    output reg[`RegAddrBus]     waddr_o,
    output reg                      we_o,
    output reg              next_inst_in_delayslot,
    
    output reg[`RegAddrBus]     cp0_addr_o,
    output reg[2:0]             cp0_sel_o,
    
    output  reg             hilo_re,
    output  reg             hilo_we,
    //生成的最终立即数    
    output[`RegBus]         imm_fnl_o ,
    output[31:0]            exception_type,
        
    output                  load_dependency ,
    output reg[31:0]           bru_addr       
    );
    
    
    reg[`RegAddrBus]    reg1_raddr_o;
    reg[`RegAddrBus]    reg2_raddr_o;
    wire [5:0]   op = inst_i[31:26];
    wire [5:0]   rs = inst_i[25:21];
    wire [5:0]   rt = inst_i[20:16];
    wire [4:0]   rd = inst_i[15:11];
    wire [4:0]   shamt = inst_i[10:6];
    wire [5:0]   funct = inst_i[5:0];
    wire [15:0]  imm = inst_i[15:0];
    
      wire [`InstAddrBus] pc_4 = pc_i + 4;
    
    
    reg[`RegBus]    imm_ex;
    reg instvalid;
    reg reg1_load_dependency;
    reg reg2_load_dependency;
    reg syscall_exception;
    reg eret_exception;
    reg break_exception;
    wire adel_exception;
    
    assign load_dependency = (reg1_load_dependency == `LoadDependent||reg2_load_dependency == `LoadDependent) ? `LoadDependent:`LoadIndependent;
    assign adel_exception = (pc_i[1:0] != 2'b00);
    assign exception_type = {17'b0,eret_exception,3'b0,instvalid,break_exception,syscall_exception,3'b0,adel_exception,4'b0};
    
    
    always@(*) begin
        if(rst == `RstEnable || adel_exception == 1'b1)   begin
            aluop_o = `EXE_NOP_OP;
            alusel_o = `EXE_RES_NOP;
            waddr_o = `NOPRegAddr;
            we_o = `WriteDisable;
            instvalid = `InstValid;
            reg1_read_o = `ReadDisable;
            reg2_read_o = `ReadDisable;
            reg1_raddr_o = `NOPRegAddr;
            reg2_raddr_o = `NOPRegAddr;
            imm_ex = 32'h0;
            hilo_re = `ReadDisable;
            hilo_we = `ReadDisable;
            next_inst_in_delayslot = `NotInDelaySlot;
            is_mul = 1'b0;
            is_div = 1'b0;
            is_jb = 1'b0;
            is_ls = 1'b0;
            is_cp0 =1'b0;
            cp0_sel_o = 3'b000;
            cp0_addr_o = 5'b00000;
            syscall_exception = 1'b0;
            eret_exception = 1'b0;
            break_exception = 1'b0;
                        
        end else begin    
            aluop_o = `EXE_NOP_OP;
            alusel_o = `EXE_RES_NOP;
            waddr_o = rd;
            we_o = `WriteDisable;
            instvalid = `InstInvalid; //
            reg1_read_o = `ReadDisable;
            reg2_read_o = `ReadDisable;
            reg1_raddr_o = rs;
            reg2_raddr_o = rt;
            imm_ex = `ZeroWord;
            hilo_re = `ReadDisable;
            hilo_we = `ReadDisable;
            next_inst_in_delayslot = `NotInDelaySlot;
            is_mul = 1'b0;
            is_div = 1'b0;
            is_jb = 1'b0;
            is_ls = 1'b0;
            is_cp0 = 1'b0;
            cp0_sel_o = 3'b000;
            cp0_addr_o = 5'b00000;
            syscall_exception = 1'b0;
            eret_exception = 1'b0;
            break_exception = 1'b0;

        case(op)
            `EXE_SPECIAL_INST:  begin
                if(shamt == 5'b00000)begin
                    case(funct)
                        `EXE_OR:begin      //orָ��
                                we_o = `WriteEnable;
                                aluop_o = `EXE_OR_OP;
                                alusel_o = `EXE_RES_LOGIC;
                                reg1_read_o = 1'b1;
                                reg2_read_o = 1'b1;
                                instvalid = `InstValid;
                            end 
                            `EXE_AND:begin     //ANDָ��
                                we_o = `WriteEnable;
                                aluop_o = `EXE_AND_OP;
                                alusel_o = `EXE_RES_LOGIC;
                                reg1_read_o = 1'b1;
                                reg2_read_o = 1'b1;
                                instvalid =`InstValid; 
                            end
                            `EXE_XOR:begin
                                we_o = `WriteEnable;
                                aluop_o =`EXE_XOR_OP;
                                alusel_o =`EXE_RES_LOGIC;
                                reg1_read_o =1'b1;
                                reg2_read_o =1'b1;
                                instvalid =`InstValid;
                            end
                            `EXE_NOR:begin              //norָ��������
                                we_o =`WriteEnable;
                                aluop_o =`EXE_NOR_OP;
                                alusel_o =`EXE_RES_LOGIC;
                                reg1_read_o =1'b1;
                                reg2_read_o =1'b1;
                                instvalid =`InstValid;
                            end
                            `EXE_SLLV:begin         //�߼�����
                                we_o =`WriteEnable;
                                aluop_o =`EXE_SLL_OP;
                                alusel_o =`EXE_RES_SHIFT;
                                reg1_read_o = 1'b1;
                                reg2_read_o = 1'b1;
                                instvalid =`InstValid;
                            end
                            `EXE_SRLV:begin
                                we_o =`WriteEnable;
                                aluop_o =`EXE_SRL_OP;
                                alusel_o =`EXE_RES_SHIFT;
                                reg1_read_o =1'b1;
                                reg2_read_o =1'b1;
                                instvalid =`InstValid;
                            end
                            `EXE_SRAV:begin
                                we_o =`WriteEnable;
                                aluop_o =`EXE_SRA_OP;
                                alusel_o =`EXE_RES_SHIFT;
                                reg1_read_o =1'b1;
                                reg2_read_o =1'b1;
                                instvalid =`InstValid;
                            end
                            `EXE_SYNC:begin             //keep it  or not ?
                                we_o =`WriteDisable;
                                aluop_o =`EXE_NOP_OP;
                                alusel_o =`EXE_RES_NOP;
                                reg1_read_o =1'b0;
                                reg2_read_o =1'b1;
                                instvalid =`InstValid;
                            end
                            
                            `EXE_MFHI: begin
                                we_o = `WriteEnable;
                                aluop_o = `EXE_MFHI_OP;
                                alusel_o = `EXE_RES_MOVE;
                                reg1_read_o = 1'b0;
                                reg2_read_o = 1'b0;
                                instvalid = `InstValid;
                                hilo_re = `ReadEnable;
                             end
                             
                            `EXE_MFLO: begin
                                we_o = `WriteEnable;
                                aluop_o = `EXE_MFLO_OP;
                                alusel_o = `EXE_RES_MOVE;
                                reg1_read_o = 1'b0;
                                reg2_read_o = 1'b0;
                                instvalid = `InstValid;
                                hilo_re = `ReadEnable;
                             end
                             
                             `EXE_MTHI: begin
                                we_o = `WriteDisable;
                                aluop_o = `EXE_MTHI_OP;
                                reg1_read_o = 1'b1;
                                reg2_read_o = 1'b0;
                                instvalid = `InstValid;
                                hilo_we = `ReadEnable;
                             end
                             
                             `EXE_MTLO: begin
                                we_o = `WriteEnable;
                                aluop_o = `EXE_MTLO_OP;
                                reg1_read_o = 1'b1;
                                reg2_read_o = 1'b0;
                                instvalid = `InstValid;
                                hilo_we = `ReadEnable;
                             end
                    //条件移动 ID两自部件存在数据相关（双发射），不能在此立刻判断，先默认条件满足，在执行阶段进一步判断                          
                            `EXE_MOVN: begin
                                we_o = `WriteEnable;
                                aluop_o = `EXE_MOVN_OP;
                                alusel_o = `EXE_RES_MOVE;
                                reg1_read_o = 1'b1;
                                reg2_read_o = 1'b1;
                                instvalid = `InstValid;                       
                             end
                            `EXE_MOVZ: begin
                                we_o = `WriteEnable;
                                aluop_o = `EXE_MOVZ_OP;
                                alusel_o = `EXE_RES_MOVE;
                                reg1_read_o = 1'b1;
                                reg2_read_o = 1'b1;
                                instvalid = `InstValid;                             
                             end 
                                                 
                            
                            `EXE_SLT:begin
                                we_o = `WriteEnable;
                                aluop_o = `EXE_SLT_OP;
                                alusel_o = `EXE_RES_ARITHMETIC;
                                reg1_read_o = 1'b1;
                                reg2_read_o = 1'b1;
                                instvalid = `InstValid;
                            end
                            `EXE_SLTU:begin
                                we_o = `WriteEnable;
                                aluop_o = `EXE_SLTU_OP;
                                alusel_o = `EXE_RES_ARITHMETIC;
                                reg1_read_o = 1'b1;
                                reg2_read_o = 1'b1;
                                instvalid = `InstValid;
                            end
                            `EXE_ADD:begin
                                we_o = `WriteEnable;
                                aluop_o =`EXE_ADD_OP;
                                alusel_o =`EXE_RES_ARITHMETIC;
                                reg1_read_o =1'b1;
                                reg2_read_o =1'b1;
                                instvalid =`InstValid;
                            end
                            `EXE_ADDU:begin
                                we_o = `WriteEnable;
                                aluop_o =`EXE_ADDU_OP;
                                alusel_o =`EXE_RES_ARITHMETIC;
                                reg1_read_o =1'b1;
                                reg2_read_o =1'b1;
                                instvalid =`InstValid;
                            end
                            `EXE_SUB:begin
                                we_o = `WriteEnable;
                                aluop_o =`EXE_SUB_OP;
                                alusel_o =`EXE_RES_ARITHMETIC;
                                reg1_read_o =1'b1;
                                reg2_read_o =1'b1;
                                instvalid =`InstValid;
                            end
                            `EXE_SUBU:begin
                                we_o = `WriteEnable;
                                aluop_o =`EXE_SUBU_OP;
                                alusel_o =`EXE_RES_ARITHMETIC;
                                reg1_read_o =1'b1;
                                reg2_read_o =1'b1;
                                instvalid =`InstValid;
                            end
                            `EXE_MULT: begin
                                we_o =`WriteEnable;
                                aluop_o = `EXE_MULT_OP;
                                reg1_read_o = `ReadEnable;
                                reg2_read_o = `ReadEnable;
                                instvalid = `InstValid;
                                is_mul = 1'b1;
                                hilo_we = `ReadEnable;
                             end
                             `EXE_MULTU: begin   
                                we_o = `WriteEnable;
                                aluop_o = `EXE_MULTU_OP;
                                reg1_read_o = `ReadEnable;
                                reg2_read_o = `ReadEnable;
                                instvalid = `InstValid;
                                is_mul = 1'b1;
                                hilo_we = `ReadEnable;
                             end
                            
                            `EXE_DIV: begin
                                we_o = `WriteDisable;
                                aluop_o = `EXE_DIV_OP;
                                //alusel_o = `EXE_RES_ARITHMETIC;
                                reg1_read_o = 1'b1;
                                reg2_read_o = 1'b1;
                                instvalid = `InstValid;
                                is_div = 1'b1;
                            end
                            `EXE_DIVU: begin
                                we_o = `WriteDisable;
                                aluop_o = `EXE_DIVU_OP;
                                //alusel_o = `EXE_RES_ARITHMETIC;
                                reg1_read_o = 1'b1;
                                reg2_read_o = 1'b1;
                                instvalid = `InstValid;
                                is_div = 1'b1;
                            end
                            
                            `EXE_JR: begin
                                we_o = `WriteDisable;
                                aluop_o = `EXE_JR_OP;
                                alusel_o = `EXE_RES_JUMP_BRANCH;
                                reg1_read_o = 1'b1;
                                reg2_read_o = 1'b0;
                                instvalid = `InstValid;
                                next_inst_in_delayslot = `InDelaySlot;                            
                                is_jb = 1'b1;
                              end  
                            
                            `EXE_JALR: begin
                                we_o = `WriteEnable;
                                aluop_o = `EXE_JALR_OP;
                                alusel_o = `EXE_RES_JUMP_BRANCH;
                                reg1_read_o = 1'b1;
                                reg2_read_o = 1'b0;
                                instvalid = `InstValid;
                                next_inst_in_delayslot = `InDelaySlot;                            
                                is_jb = 1'b1;
                              end      
                                
                            default:    ;
                        endcase
                   end
              case (funct)
		          `EXE_TEQ: begin
		              we_o = `WriteDisable;
		              aluop_o = `EXE_TEQ_OP;
		              alusel_o = `EXE_RES_NOP;
		              reg1_read_o = `ReadEnable;
		              reg2_read_o = `ReadEnable;
		              instvalid = `InstValid;
                      is_cp0 = 1'b1;
		          end
		          `EXE_TGE: begin
		              we_o = `WriteDisable;
		              aluop_o = `EXE_TGE_OP;
		              alusel_o = `EXE_RES_NOP;
		              reg1_read_o = `ReadEnable;
		              reg2_read_o = `ReadEnable;
		              instvalid = `InstValid;
                      is_cp0 = 1'b1;
		          end
		          `EXE_TGEU: begin
		              we_o = `WriteDisable;
		              aluop_o = `EXE_TGEU_OP;
		              alusel_o = `EXE_RES_NOP;
		              reg1_read_o = `ReadEnable;
		              reg2_read_o = `ReadEnable;
		              instvalid = `InstValid;
                      is_cp0 = 1'b1;
		          end
		          `EXE_TLT: begin
		              we_o = `WriteDisable;
		              aluop_o = `EXE_TLT_OP;
		              alusel_o = `EXE_RES_NOP;
		              reg1_read_o = `ReadEnable;
		              reg2_read_o = `ReadEnable;
		              instvalid = `InstValid;
                      is_cp0 = 1'b1;
		          end
		          `EXE_TLTU: begin
		              we_o = `WriteDisable;
		              aluop_o = `EXE_TLTU_OP;
		              alusel_o = `EXE_RES_NOP;
		              reg1_read_o = `ReadEnable;
		              reg2_read_o = `ReadEnable;
		              instvalid = `InstValid;
                      is_cp0 = 1'b1;
		          end
		          `EXE_TNE: begin
		              we_o = `WriteDisable;
		              aluop_o = `EXE_TNE_OP;
		              alusel_o = `EXE_RES_NOP;
		              reg1_read_o = `ReadEnable;
		              reg2_read_o = `ReadEnable;
		              instvalid = `InstValid;
                      is_cp0 = 1'b1;
		          end
		          `EXE_BREAK: begin
		              we_o = `WriteDisable;
		              aluop_o = `EXE_BREAK_OP;
		              alusel_o = `EXE_RES_NOP;
		              reg1_read_o = `ReadDisable;
		              reg2_read_o = `ReadDisable;
		              instvalid = `InstValid;
		              break_exception = 1'b1;
                      is_cp0 = 1'b1;
		          end
		          `EXE_SYSCALL: begin
		              we_o = `WriteDisable;
		              aluop_o = `EXE_SYSCALL_OP;
		              alusel_o = `EXE_RES_NOP;
		              reg1_read_o = `ReadDisable;
		              reg2_read_o = `ReadDisable;
		              instvalid = `InstValid;
		              syscall_exception = 1'b1;
                      is_cp0 = 1'b1;
		          end
		          default: ;
		      endcase     
                   
          
            if(rs == 5'b00000)  begin
                case(funct)
                    `EXE_SLL:   begin
                        we_o = `WriteEnable;
                        aluop_o = `EXE_SLL_OP;
                        alusel_o = `EXE_RES_SHIFT;
                        reg1_read_o = `ReadDisable;
                        reg2_read_o = `ReadEnable;
                        imm_ex = shamt;
                        instvalid = `InstValid;
                        end 
                    `EXE_SRL:   begin
                        we_o = `WriteEnable;
                        aluop_o = `EXE_SRL_OP;
                        alusel_o = `EXE_RES_SHIFT;
                        reg1_read_o = `ReadDisable;
                        reg2_read_o = `ReadEnable;
                        imm_ex = shamt;
                        instvalid = `InstValid;
                        end    
                    `EXE_SRA:   begin
                        we_o = `WriteEnable;
                        aluop_o = `EXE_SRA_OP;
                        alusel_o = `EXE_RES_SHIFT;
                        reg1_read_o = `ReadDisable;
                        reg2_read_o = `ReadEnable;
                        imm_ex = shamt;
                        instvalid = `InstValid;
                        end    
                        default:    ;
                        endcase
                  end
               end
                        
            `EXE_ORI:   begin
                   aluop_o = `EXE_OR_OP;
                   alusel_o = `EXE_RES_LOGIC;
                   waddr_o = rt;
                   we_o =`WriteEnable;
                   instvalid = `InstValid; 
                   reg1_read_o = `ReadEnable;
                   reg2_read_o = `ReadDisable;
           
                   imm_ex = {16'h0,inst_i[15:0]};

            end                        
            
            `EXE_ANDI:begin
                aluop_o =`EXE_AND_OP;
                alusel_o =`EXE_RES_LOGIC;
                waddr_o = rt;
                we_o =`WriteEnable;
                instvalid =`InstValid;
                reg1_read_o =1'b1;
                reg2_read_o =1'b0;
                
                imm_ex ={16'h0,inst_i[15:0]};
                
            end 
            `EXE_XORI:begin
                aluop_o =`EXE_XOR_OP;
                alusel_o =`EXE_RES_LOGIC;
                waddr_o = rt;
                we_o =`WriteEnable;
                instvalid =`InstValid;
                reg1_read_o =1'b1;
                reg2_read_o =1'b0;
                
                imm_ex ={16'h0,inst_i[15:0]};
            
            end
            `EXE_LUI:begin
                we_o =`WriteEnable;
                aluop_o =`EXE_OR_OP;
                alusel_o =`EXE_RES_LOGIC;
                reg1_read_o =1'b1;
                reg2_read_o =1'b0;
                
                imm_ex ={inst_i[15:0],16'h0};
                waddr_o = rt;
                instvalid =`InstValid;
            end
           /* `EXE_PREF:begin                         //keep or not?
                we_o =`WriteDisable;
                aluop_o =`EXE_NOP_OP;
                alusel_o =`EXE_RES_NOP;
                reg1_read_o =1'b0;
                reg2_read_o =1'b0;
                instvalid =`InstValid;
            end*/
            
            `EXE_SLTI:begin
                we_o = `WriteEnable;
                aluop_o =`EXE_SLT_OP;
                alusel_o =`EXE_RES_ARITHMETIC;
                reg1_read_o =1'b1;
                reg2_read_o =1'b0;
                imm_ex = { {16{inst_i[15]}} , inst_i[15:0] };
                waddr_o = inst_i[20:16];
                instvalid =`InstValid;
            end
            `EXE_SLTIU:begin
                we_o = `WriteEnable;
                aluop_o =`EXE_SLTU_OP;
                alusel_o =`EXE_RES_ARITHMETIC;
                reg1_read_o = 1'b1;
                reg2_read_o = 1'b0;
                imm_ex = { {16{inst_i[15]}}, inst_i[15:0] };
                waddr_o = inst_i[20:16];
                instvalid =`InstValid;
            end
            `EXE_ADDI:begin
                we_o = `WriteEnable;
                aluop_o =`EXE_ADDI_OP;
                alusel_o =`EXE_RES_ARITHMETIC;
                reg1_read_o =1'b1;
                reg2_read_o =1'b0;
                imm_ex = { {16{inst_i[15]}}, inst_i[15:0] };
                waddr_o = inst_i[20:16];
                instvalid =`InstValid;
            end
            `EXE_ADDIU:begin
                we_o = `WriteEnable;
                aluop_o =`EXE_ADDIU_OP;
                alusel_o =`EXE_RES_ARITHMETIC;
                reg1_read_o =1'b1;
                reg2_read_o =1'b0;
                imm_ex = { {16{inst_i[15]}}, inst_i[15:0] };
                waddr_o = inst_i[20:16];
                instvalid =`InstValid;
            end
            `EXE_J:begin
                we_o = `WriteDisable;
                aluop_o =`EXE_J_OP;
                alusel_o =`EXE_RES_JUMP_BRANCH;
                reg1_read_o =1'b0;
                reg2_read_o =1'b0;
                imm_ex = {4'b0,inst_i[25:0],2'b0};
                next_inst_in_delayslot = `InDelaySlot;
                instvalid =`InstValid;
                is_jb = 1'b1;
            end
            `EXE_JAL:begin
                we_o = `WriteEnable;
                aluop_o =`EXE_JAL_OP;
                alusel_o =`EXE_RES_JUMP_BRANCH;
                reg1_read_o =1'b0;
                reg2_read_o =1'b0;
                waddr_o = 5'b11111;
                imm_ex = {4'b0,inst_i[25:0],2'b0};
                next_inst_in_delayslot = `InDelaySlot;
                instvalid =`InstValid;
                is_jb = 1'b1;
            end
            `EXE_BEQ:begin
                we_o = `WriteDisable;
                aluop_o =`EXE_BEQ_OP;
                alusel_o =`EXE_RES_JUMP_BRANCH;
                reg1_read_o =1'b1;
                reg2_read_o =1'b1;
                imm_ex = {{14{imm[15]}},imm,2'b0};
                instvalid =`InstValid;
                is_jb = 1'b1;
                next_inst_in_delayslot = `InDelaySlot;
             end
            `EXE_BGTZ:begin
                we_o = `WriteDisable;
                aluop_o =`EXE_BGTZ_OP;
                alusel_o =`EXE_RES_JUMP_BRANCH;
                reg1_read_o =1'b1;
                reg2_read_o =1'b0;
                imm_ex = {{14{imm[15]}},imm,2'h0};
                instvalid =`InstValid;
                is_jb = 1'b1;
                next_inst_in_delayslot = `InDelaySlot;
            end
            `EXE_BLEZ:begin
                we_o = `WriteDisable;
                aluop_o =`EXE_BLEZ_OP;
                alusel_o =`EXE_RES_JUMP_BRANCH;
                reg1_read_o =1'b1;
                reg2_read_o =1'b0;
                imm_ex = {{14{imm[15]}},imm,2'h0};
                instvalid =`InstValid;
                is_jb = 1'b1;
                next_inst_in_delayslot = `InDelaySlot;
            end
            `EXE_BNE:begin
                we_o = `WriteDisable;
                aluop_o =`EXE_BNE_OP;
                alusel_o =`EXE_RES_JUMP_BRANCH;
                reg1_read_o =1'b1;
                reg2_read_o =1'b1;
                imm_ex = {{14{imm[15]}},imm,2'h0};
                instvalid =`InstValid;
                is_jb = 1'b1;
                next_inst_in_delayslot = `InDelaySlot;
            end
            `EXE_LB: begin
              aluop_o = `EXE_LB_OP;
              alusel_o = `EXE_RES_LOAD_STORE;
              waddr_o = rt;
              we_o = `WriteEnable;
              instvalid = `InstValid;
              reg1_read_o = `ReadEnable;
              reg2_read_o = `ReadDisable;
              imm_ex = {{16{imm[15]}},imm};
              is_ls = 1'b1;
              
          end
          `EXE_LBU: begin
              aluop_o = `EXE_LBU_OP;
              alusel_o = `EXE_RES_LOAD_STORE;
              waddr_o = rt;
              we_o = `WriteEnable;
              instvalid = `InstValid;
              reg1_read_o = `ReadEnable;
              reg2_read_o = `ReadDisable;
              imm_ex = {{16{imm[15]}},imm};
              is_ls = 1'b1;
          end
          `EXE_LH: begin
              aluop_o = `EXE_LH_OP;
              alusel_o = `EXE_RES_LOAD_STORE;
              waddr_o = rt;
              we_o = `WriteEnable;
              instvalid = `InstValid;
              reg1_read_o = `ReadEnable;
              reg2_read_o = `ReadDisable;
              imm_ex = {{16{imm[15]}},imm};
              is_ls = 1'b1;
          end
          `EXE_LHU: begin
              aluop_o = `EXE_LHU_OP;
              alusel_o = `EXE_RES_LOAD_STORE;
              waddr_o = rt;
              we_o = `WriteEnable;
              instvalid = `InstValid;
              reg1_read_o = `ReadEnable;
              reg2_read_o = `ReadDisable;
              imm_ex = {{16{imm[15]}},imm};
              is_ls = 1'b1;
          end
          `EXE_LW: begin
              aluop_o = `EXE_LW_OP;
              alusel_o = `EXE_RES_LOAD_STORE;
              waddr_o = rt;
              we_o = `WriteEnable;
              instvalid = `InstValid;
              reg1_read_o = `ReadEnable;
              reg2_read_o = `ReadDisable;
              imm_ex = {{16{imm[15]}},imm};
              is_ls = 1'b1;
          end
          `EXE_LWL: begin
              aluop_o = `EXE_LWL_OP;
              alusel_o = `EXE_RES_LOAD_STORE;
              waddr_o = rt;
              we_o = `WriteEnable;
              instvalid = `InstValid;
              reg1_read_o = `ReadEnable;
              reg2_read_o = `ReadEnable;
              imm_ex = {{16{imm[15]}},imm};
              is_ls = 1'b1;
          end
          `EXE_LWR: begin
              aluop_o = `EXE_LWR_OP;
              alusel_o = `EXE_RES_LOAD_STORE;
              waddr_o = rt;
              we_o = `WriteEnable;
              instvalid = `InstValid;
              reg1_read_o = `ReadEnable;
              reg2_read_o = `ReadEnable;
              imm_ex = {{16{imm[15]}},imm};
              is_ls = 1'b1;
          end
          `EXE_SB: begin
              aluop_o = `EXE_SB_OP;
              alusel_o = `EXE_RES_LOAD_STORE;
              we_o = `WriteDisable;
              instvalid = `InstValid;
              reg1_read_o = `ReadEnable;
              reg2_read_o = `ReadEnable;
              imm_ex = {{16{imm[15]}},imm};
              is_ls = 1'b1;
          end
          `EXE_SH: begin
              aluop_o = `EXE_SH_OP;
              alusel_o = `EXE_RES_LOAD_STORE;
              we_o = `WriteDisable;
              instvalid = `InstValid;
              reg1_read_o = `ReadEnable;
              reg2_read_o = `ReadEnable;
              imm_ex = {{16{imm[15]}},imm};
              is_ls = 1'b1;
          end
          `EXE_SW: begin
              aluop_o = `EXE_SW_OP;
              alusel_o = `EXE_RES_LOAD_STORE;
              we_o = `WriteDisable;
              instvalid = `InstValid;
              reg1_read_o = `ReadEnable;
              reg2_read_o = `ReadEnable;
              imm_ex = {{16{imm[15]}},imm};
              is_ls = 1'b1;
          end
          `EXE_SWL: begin
              aluop_o = `EXE_SWL_OP;
              alusel_o = `EXE_RES_LOAD_STORE;
              we_o = `WriteDisable;
              instvalid = `InstValid;
              reg1_read_o = `ReadEnable;
              reg2_read_o = `ReadEnable;
              imm_ex = {{16{imm[15]}},imm};
              is_ls = 1'b1;
          end
          `EXE_SWR: begin
              aluop_o = `EXE_SWR_OP;
              alusel_o = `EXE_RES_LOAD_STORE;
              we_o = `WriteDisable;
              instvalid = `InstValid;
              reg1_read_o = `ReadEnable;
              reg2_read_o = `ReadEnable;
              imm_ex = {{16{imm[15]}},imm};
              is_ls = 1'b1;
          end
          `EXE_LL: begin
              aluop_o = `EXE_LL_OP;
              alusel_o = `EXE_RES_LOAD_STORE;
              waddr_o = rt;
              we_o = `WriteEnable;
              instvalid = `InstValid;
              reg1_read_o = `ReadEnable;
              reg2_read_o = `ReadDisable;
              imm_ex = {{16{imm[15]}},imm};
              is_ls = 1'b1;
          end
          `EXE_SC: begin
              aluop_o = `EXE_SC_OP;
              alusel_o = `EXE_RES_LOAD_STORE;
              waddr_o = rt;
              we_o = `WriteEnable;
              instvalid = `InstValid;
              reg1_read_o = `ReadEnable;
              reg2_read_o = `ReadEnable;
              imm_ex = {{16{imm[15]}},imm};
              is_ls = 1'b1;
          end
            
            
            
            `EXE_REGIMM_INST: begin
                next_inst_in_delayslot = `InDelaySlot;
                case(rt)
                    `EXE_BGEZ:begin
                        we_o = `WriteDisable;
                        aluop_o =`EXE_BGEZ_OP;
                        alusel_o =`EXE_RES_JUMP_BRANCH;
                        reg1_read_o =1'b1;
                        reg2_read_o =1'b0;
                        imm_ex = {{14{imm[15]}},imm,2'h0};
                        instvalid =`InstValid;
                        is_jb = 1'b1;
                     end
                    `EXE_BGEZAL:begin
                        we_o = `WriteEnable;
                        aluop_o =`EXE_BGEZAL_OP;
                        alusel_o =`EXE_RES_JUMP_BRANCH;
                        reg1_read_o =1'b1;
                        reg2_read_o =1'b0;
                        imm_ex = {{14{imm[15]}},imm,2'h0};
                        instvalid =`InstValid;
                        is_jb = 1'b1;

                        waddr_o = 5'b11111;
                    end 
                     `EXE_BLTZ:begin
                        we_o = `WriteDisable;
                        aluop_o =`EXE_BLTZ_OP;
                        alusel_o =`EXE_RES_JUMP_BRANCH;
                        reg1_read_o =1'b1;
                        reg2_read_o =1'b0;
                        instvalid =`InstValid;
                        imm_ex = {{14{imm[15]}},imm,2'h0};
                        is_jb = 1'b1;  
                    end
                    
                     `EXE_BLTZAL:begin
                        we_o = `WriteEnable;
                        aluop_o =`EXE_BLTZAL_OP;
                        alusel_o =`EXE_RES_JUMP_BRANCH;
                        reg1_read_o =1'b1;
                        reg2_read_o =1'b0;
                        instvalid =`InstValid;
                        imm_ex = {{14{imm[15]}},imm,2'h0};
                        is_jb = 1'b1;  
                        waddr_o = 5'b11111;
                    end
                  `EXE_TEQI: begin
                      aluop_o = `EXE_TEQI_OP;
                      alusel_o = `EXE_RES_NOP;
                      we_o = `WriteDisable;
                      instvalid = `InstValid;
                      reg1_read_o = `ReadEnable;
                      reg2_read_o = `ReadDisable;
                      imm_ex = {{16{inst_i[15]}}, inst_i[15:0]};
                      is_cp0 = 1'b1;
                  end
                  `EXE_TGEI: begin
                      aluop_o = `EXE_TGEI_OP;
                      alusel_o = `EXE_RES_NOP;
                      we_o = `WriteDisable;
                      instvalid = `InstValid;
                      reg1_read_o = `ReadEnable;
                      reg2_read_o = `ReadDisable;
                      imm_ex = {{16{inst_i[15]}}, inst_i[15:0]};
                      is_cp0 = 1'b1;
                  end
                  `EXE_TGEIU: begin
                      aluop_o = `EXE_TGEIU_OP;
                      alusel_o = `EXE_RES_NOP;
                      we_o = `WriteDisable;
                      instvalid = `InstValid;
                      reg1_read_o = `ReadEnable;
                      reg2_read_o = `ReadDisable;
                      imm_ex = {{16{inst_i[15]}}, inst_i[15:0]};
                      is_cp0 = 1'b1;
                  end
                  `EXE_TLTI: begin
                      aluop_o = `EXE_TLTI_OP;
                      alusel_o = `EXE_RES_NOP;
                      we_o = `WriteDisable;
                      instvalid = `InstValid;
                      reg1_read_o = `ReadEnable;
                      reg2_read_o = `ReadDisable;
                      imm_ex = {{16{inst_i[15]}}, inst_i[15:0]};
                      is_cp0 = 1'b1;
                  end
                  `EXE_TLTIU: begin
                      aluop_o = `EXE_TLTIU_OP;
                      alusel_o = `EXE_RES_NOP;
                      we_o = `WriteDisable;
                      instvalid = `InstValid;
                      reg1_read_o = `ReadEnable;
                      reg2_read_o = `ReadDisable;
                      imm_ex = {{16{inst_i[15]}}, inst_i[15:0]};
                      is_cp0 = 1'b1;
                  end
                  `EXE_TNEI: begin
                      aluop_o = `EXE_TNEI_OP;
                      alusel_o = `EXE_RES_NOP;
                      we_o = `WriteDisable;
                      instvalid = `InstValid;
                      reg1_read_o = `ReadEnable;
                      reg2_read_o = `ReadDisable;
                      imm_ex = {{16{inst_i[15]}}, inst_i[15:0]};
                      is_cp0 = 1'b1;
                  end  
                    
                    
                    default: ;                      
                    
                endcase
            end
            
            `EXE_SPECIAL2_INST:  begin
                case (funct)
                    /*`EXE_CLZ:begin
                        we_o = `WriteEnable;
                        aluop_o =`EXE_CLZ_OP;
                        alusel_o =`EXE_RES_ARITHMETIC;
                        reg1_read_o =1'b1;
                        reg2_read_o =1'b0;
                        instvalid =`InstValid;
                    end 
                    `EXE_CLO:begin
                        we_o = `WriteEnable;
                        aluop_o =`EXE_CLO_OP;
                        alusel_o =`EXE_RES_ARITHMETIC;
                        reg1_read_o =1'b1;
                        reg2_read_o =1'b0;
                        instvalid =`InstValid;
                    end */
                    `EXE_MUL:begin           //ֻ�������ĵ�32λ
                        we_o = `WriteEnable;
                        aluop_o =`EXE_MUL_OP;
                        alusel_o =`EXE_RES_MUL;
                        reg1_read_o =1'b1;
                        reg2_read_o =1'b1;
                        instvalid =`InstValid;
                        is_mul = 1'b1;
                    end 
                    
                        default: begin
                            end
                        endcase
                    end        
                    
                    `EXE_COP0: begin
                        if(inst_i[25:21] == 5'b00000 && inst_i[10:3] == 8'b00000000) begin
                            aluop_o = `EXE_MFC0_OP;
                            alusel_o = `EXE_RES_MOVE;
                            waddr_o = rt;
                            we_o = `WriteEnable;
			                instvalid = `InstValid;
                            reg1_read_o = `ReadDisable;
                            reg2_read_o = `ReadDisable;
                            cp0_sel_o = inst_i[2:0];
                            cp0_addr_o = rd;
                            is_cp0 = 1'b1;
		                end else if(inst_i[25:21] == 5'b00100 && inst_i[10:3] == 8'b00000000) begin
                            aluop_o = `EXE_MTC0_OP;
                            alusel_o = `EXE_RES_NOP;
                            we_o = `WriteDisable;
                            instvalid = `InstValid;	   
                            reg1_read_o = `ReadDisable;
                            reg2_read_o = `ReadEnable;
                            cp0_sel_o = inst_i[2:0];
                            cp0_addr_o = rd;
                            is_cp0 = 1'b1;
                        end
                    end
             
                      default: ;
                     endcase
        
                    if (inst_i == `EXE_ERET) begin
		                  aluop_o = `EXE_ERET_OP;
		                  alusel_o = `EXE_RES_NOP;
		                  we_o = `WriteDisable;
		                  reg1_read_o = `ReadDisable;
                          reg2_read_o = `ReadDisable;
                          instvalid = `InstValid;
                          eret_exception = 1'b1;
                          is_cp0 = 1'b1;
		             end     
                end
  
end

// need to solve correlation problems      
always@(*)  begin
        reg1_o = `ZeroWord;
        reg1_load_dependency = `LoadIndependent;
    if(rst == `RstEnable)   begin
        reg1_o = `ZeroWord;    
    // solve the problem of data correlation(hazard)       
    // end else if(reg1_read_o == `ReadEnable && is_load && ex_waddr1_i == reg1_raddr_o)  begin  
  end else if(reg1_read_o == `ReadEnable && ((is_load1&&(ex_waddr1_i == reg1_raddr_o)) || (is_load2&&(ex_waddr2_i == reg1_raddr_o)) ))  begin 
        reg1_load_dependency = `LoadDependent;   
      //  reg1_o = reg1_data_i;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
    end else if(reg1_read_o == `ReadEnable && ex_we2_i == `WriteEnable && ex_waddr2_i == reg1_raddr_o)  begin
        reg1_o = ex_wdata2_i;
    end else if(reg1_read_o == `ReadEnable && ex_we1_i == `WriteEnable && ex_waddr1_i == reg1_raddr_o) begin
        reg1_o = ex_wdata1_i;
    end else if(reg1_read_o ==  `ReadEnable && mem_we2_i == `WriteEnable && mem_waddr2_i == reg1_raddr_o)   begin
        reg1_o = mem_wdata2_i;
//        reg1_load_dependency = `LoadDependent;                             ///////  8.3 DHZ
    end else if(reg1_read_o == `ReadEnable && mem_we1_i == `WriteEnable && mem_waddr1_i == reg1_raddr_o)    begin
        reg1_o = mem_wdata1_i;     
//        reg1_load_dependency = `LoadDependent;                             
       
    end else if(reg1_read_o == `ReadEnable) begin
        reg1_o = reg1_data_i;           //regfile 
    end else if(reg1_read_o == `ReadDisable) begin
        reg1_o = imm_ex;                //imm number
    end else begin
        reg1_o = `ZeroWord;
        end
end          

always@(*)  begin
        reg2_o = `ZeroWord;
        reg2_load_dependency = `LoadIndependent;
    if(rst == `RstEnable)   begin
        reg2_o = `ZeroWord;
     // solve the problem of data correlation
    // end else if(reg2_read_o == `ReadEnable && is_load && ex_waddr1_i == reg2_raddr_o)  begin  
    end else if(reg2_read_o == `ReadEnable &&(( is_load1 && ex_waddr1_i == reg2_raddr_o )||( is_load2 &&ex_waddr2_i == reg2_raddr_o)))  begin   
        reg2_load_dependency = `LoadDependent; 
        //reg2_o = reg2_data_i;  
    end else if(reg2_read_o == `ReadEnable && ex_we2_i == `WriteEnable && ex_waddr2_i == reg2_raddr_o)  begin
        reg2_o = ex_wdata2_i;
    end else if(reg2_read_o == `ReadEnable && ex_we1_i == `WriteEnable && ex_waddr1_i == reg2_raddr_o) begin
        reg2_o = ex_wdata1_i;
    end else if(reg2_read_o ==  `ReadEnable && mem_we2_i == `WriteEnable && mem_waddr2_i == reg2_raddr_o)   begin
        reg2_o = mem_wdata2_i;
    end else if(reg2_read_o == `ReadEnable && mem_we1_i == `WriteEnable && mem_waddr1_i == reg2_raddr_o)    begin
        reg2_o = mem_wdata1_i;               
        
    end else if(reg2_read_o == `ReadEnable) begin
        reg2_o = reg2_data_i;
    end else if(reg2_read_o == `ReadDisable) begin
        reg2_o = imm_ex;  
    end else begin
        reg2_o = `ZeroWord;
        end
end   

assign imm_fnl_o = imm_ex;

always @(*)begin
    case(op[2:0])
    3'b011,3'b010: begin //J,jal
         bru_addr = {pc_4[31:28],imm_ex[27:0]}; 
    end
    3'b000:begin    //JR JAL
         bru_addr = reg1_o;
    end
   default:begin
         bru_addr =  pc_4 + imm_ex;
   end
endcase
end


                
endmodule
