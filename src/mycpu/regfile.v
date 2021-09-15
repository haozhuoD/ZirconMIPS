`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/24 22:11:53
// Design Name: 
// Module Name: regfile
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

module regfile(
        input   clk,
        input   rst,
        
        //write
        input wire we1,
        input wire[`RegAddrBus] waddr1,
        input wire[`RegBus] wdata1, 
        
        input wire we2,
        input wire[`RegAddrBus] waddr2,
        input wire[`RegBus] wdata2, 

        //read
        input wire[`RegAddrBus] raddr1,
        output reg[`RegBus] rdata1,
        //input wire re1,

        input wire[`RegAddrBus] raddr2,
        output reg[`RegBus] rdata2,
        //input wire re2,
        
        input wire[`RegAddrBus] raddr3,
        output reg[`RegBus] rdata3,
        //input wire re3,
        
        input wire[`RegAddrBus] raddr4,
        output reg[`RegBus] rdata4,
        //input wire re4
                
        output  wire[`RegBus]   reg31     //??
        
    );
    
    reg[`RegBus] regs[0:`RegNum-1] ; //寄存器需要初始化
    
//    //initial begin   $readmemb("123.txt",regs); end
//    genvar i;
//    generate 
//        for(i = 0; i < 32; i = i + 1) begin: reg_loop
//            always@(*) begin
//                if(rst)
//                    regs[i] <= 32'b0;
//                end
//            end
//    endgenerate
    
    integer j = 0;
    initial
        for(j = 0; j < 32; j = j + 1)
            regs[j] <= 0;
            
    
    assign reg31 = regs[31];
    
    //write
    always@(posedge clk)    begin
        if(rst == `RstDisable)   begin
            case({we2,we1})
                2'b01:    if(waddr1 != `NOPRegAddr)   regs[waddr1] <= wdata1;
                2'b10:    if(waddr2 != `NOPRegAddr)   regs[waddr2] <= wdata2;
                2'b11:    begin
                    if(waddr2 != `NOPRegAddr)   regs[waddr2] <= wdata2;
                    if(waddr1 != waddr2 && waddr1 != `NOPRegAddr)   begin       // prevent   (WAW) 
                        regs[waddr1] <= wdata1;
                        end
                    end
                    default: ;
                    endcase
             end
       end
       
     //read     
    always@ (*) begin
        if(rst == `RstEnable)   begin
            rdata1 = `ZeroWord;
            end else if(raddr1 == `RegNumLog2'h0)   begin
                rdata1 = `ZeroWord;
            end else begin                          // add if( re == RstEnable) ??      then add "else rdata1 = `ZeroWord" 
                case({we2,we1})
                    2'b01:  rdata1 = (raddr1 == waddr1) ? wdata1 : regs[raddr1];
                    2'b10:  rdata1 = (raddr1 == waddr2) ? wdata2:  regs[raddr1];
                    2'b11:  begin
                        if(raddr1 == waddr2)    rdata1 = wdata2;
                        else if(raddr1 == waddr1)   rdata1 = wdata1;
                        else    rdata1 = regs[raddr1];
                    end
                    default:    rdata1 = regs[raddr1];
                    endcase
                end                                     
    end
    
    always@ (*) begin
        if(rst == `RstEnable)   begin
            rdata2 = `ZeroWord;
            end else if(raddr2 == `RegNumLog2'h0)   begin
                rdata2 = `ZeroWord;
            end else begin
                case({we2,we1})
                    2'b01:  rdata2 = (raddr2 == waddr1) ? wdata1 : regs[raddr2];
                    2'b10:  rdata2 = (raddr2 == waddr2) ? wdata2:  regs[raddr2];
                    2'b11:  begin
                        if(raddr2 == waddr2)    rdata2 = wdata2;
                        else if(raddr2 == waddr1)   rdata2 = wdata1;
                        else    rdata2 = regs[raddr2];
                    end
                    default:    rdata2 = regs[raddr2];
                    endcase
                end                                     
    end
    
    always@ (*) begin
        if(rst == `RstEnable)   begin
            rdata3 = `ZeroWord;
            end else if(raddr3 == `RegNumLog2'h0)   begin
                rdata3 = `ZeroWord;
            end else begin                                              
                case({we2,we1})
                    2'b01:  rdata3 = (raddr3 == waddr1) ? wdata1 : regs[raddr3];
                    2'b10:  rdata3 = (raddr3 == waddr2) ? wdata2:  regs[raddr3];
                    2'b11:  begin
                        if(raddr3 == waddr2)    rdata3 = wdata2;
                        else if(raddr3 == waddr1)   rdata3 = wdata1;
                        else    rdata3 = regs[raddr3];
                    end
                    default:    rdata3 = regs[raddr3];
                    endcase
                end                                     
    end
    
    always@ (*) begin
        if(rst == `RstEnable)   begin
            rdata4 = `ZeroWord;
            end else if(raddr4 == `RegNumLog2'h0)   begin
                rdata4 = `ZeroWord;
            end else begin
                case({we2,we1})
                    2'b01:  rdata4 = (raddr4 == waddr1) ? wdata1 : regs[raddr4];
                    2'b10:  rdata4 = (raddr4 == waddr2) ? wdata2:  regs[raddr4];
                    2'b11:  begin
                        if(raddr4 == waddr2)    rdata4 = wdata2;
                        else if(raddr4 == waddr1)   rdata4 = wdata1;
                        else    rdata4 = regs[raddr4];
                    end
                    default:    rdata4 = regs[raddr4];
                    endcase
                end                                     
    end
    
    
    
endmodule
