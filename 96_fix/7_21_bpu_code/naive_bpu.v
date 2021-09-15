`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/01 21:46:31
// Design Name: 
// Module Name: naive_bpu
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
//todo list:
//todo1    : simplify update strategy(bht & pht)
//todo2    : remember that J-type don't need update bht & pht


//!!!if I fetch two insts while they unfortunately both are branch insts,then the second inst won't do ant thing to the bpu

//*REMAMBER THAT J TYPE DON'T NEED UPDATE
//*if the second inst is branch/J,then don't send it immediately
module naive_bpu(
    input           clk                 ,
    input           resetn              ,
    input           stallreq            ,
    input [31: 0]   pc                  ,
    input           flush               ,
    //from EX
    input [65: 0]   ex_branch_info      ,//[65][64:33][32][31:0]:direction_Jump_Addr[32]_type_PC[32]
    input           pred_flag           ,//1 for fail
    input           pred_true           ,//

    output          pred_dely_stream    ,
    output          pred_dely_o         ,//!!!
    output[32: 0]   pred_info_stream    ,
    output[32: 0]   pred_info_o      //0 for not-jump
    );

    wire  [32: 0]   pred_info           ;
    wire            pred_dely           ;
    wire  [31: 0]   pc_plus4            ;
    wire  [31: 0]   pc_real             ;//selected pc
    wire  [31: 0]   pc_last             ;
    wire  [31: 0]   pc_real_plus        ;

    reg   [32: 0]   pred_info_ff        ;
    reg             pred_dely_ff        ;
    reg             stallreq_ff         ;
    reg   [31: 0]   pred_address_buffer ;
    reg   [31: 0]   pred_address_buffer_if  ;
    reg             pred_direct_ff      ;
    reg             pred_direct_if_ff   ;
    reg             hit0_ff             ;
    reg             hit1_ff             ;
    
    wire            pred_direct         ;
    wire            pred_direct_if      ;
    //for update
    wire            real_direct         ;
    wire  [31: 0]   real_address        ;
    
    wire            hit0                ;
    wire            hit1                ;
    wire  [31: 0]   pred_address        ;
    wire  [31: 0]   pred_address_if     ;

    assign          pc_plus4    = pc + 32'h04                                        ;
    
    assign          pred_info   = pred_direct_ff & hit0_ff ? {1'b1,pred_address_buffer} : (pred_direct_if_ff & hit1_ff & (~pred_dely_ff | stallreq_ff) ? {1'b1,pred_address_buffer_if} : {1'b0,32'h00000000});//7.28dqy
    assign          pred_dely   = (~hit0_ff) & pred_direct_if_ff & hit1_ff & (~pred_dely_ff | stallreq_ff)  ;
    
    //tmp

    //update info
    assign          real_direct = resetn & ex_branch_info[65:65]                     ;
    assign          real_address= resetn ? ex_branch_info[64:33] : 32'h00000000      ;
    assign          pc_update   = resetn ? ex_branch_info[31: 0] : 32'h00000000      ;
    assign          update_type = resetn & ex_branch_info[32:32]                     ;
    assign          pc_last     = resetn ? ex_branch_info[31: 0] : 32'h00000000      ;

    assign          pred_info_stream    = pred_info                                  ;
    assign          pred_info_o = stallreq_ff        ? pred_info_ff       : pred_info; 
    assign          pc_real     = pc       ;//7.27
    assign          pc_real_plus= pred_dely_o ? 32'hffffffff : pc_real + 32'h00000004;
    
    //delay
    assign          pred_dely_stream    = pred_dely                                  ;
    assign          pred_dely_o         = stallreq_ff   ? pred_dely_ff : pred_dely   ;
   
    naive_btb   btb (.clk(clk)                          ,
                     .resetn(resetn)                    ,
                     .stallreq(1'b0)                    ,

                     .pc(pc_real)                       ,
                     .pc_plus(pc_real_plus)             ,
                     .update_pc(pc_last)                ,
                     .pred_flag(pred_flag)              ,
                     .pred_true(pred_true)              ,
                     .real_address(real_address)        ,
                     .pred_address(pred_address)        ,
                     .pred_address_if(pred_address_if)  ,
                     .pred_direct(pred_direct)          ,
                     .real_direct(real_direct)          ,
                     .update_type(update_type)          ,
                     .pred_direct_if(pred_direct_if)    ,
                     .hit0(hit0)                        ,
                     .hit1(hit1)
                    );

    always @(posedge clk ) begin
        if (~resetn ) begin
            pred_address_buffer     <= 32'h00000000         ;
            pred_address_buffer_if  <= 32'h00000000         ;
            hit0_ff                 <= 1'b0                 ;
            hit1_ff                 <= 1'b0                 ;
            pred_direct_ff          <= 1'b0                 ;
            pred_direct_if_ff       <= 1'b0                 ;
            pred_info_ff            <= {1'b0,32'h00000000}  ;
            pred_dely_ff            <= 1'b0                 ;
            stallreq_ff             <= 1'b0                 ;
        end
        else
        if (flush)    begin
            pred_info_ff            <= {1'b0,32'h00000000}  ;
            pred_dely_ff            <= 1'b0                 ;
            pred_direct_ff          <= 1'b0                 ;
            pred_direct_if_ff       <= 1'b0                 ;
            pred_address_buffer     <= 32'h00000000         ;
            pred_address_buffer_if  <= 32'h00000000         ;
        end
        else
        if (stallreq) begin
            stallreq_ff             <= stallreq         ;
            pred_info_ff            <= pred_info        ;
            pred_dely_ff            <= pred_dely        ;
        end
        else          begin
            pred_address_buffer     <= pred_address     ;
            pred_address_buffer_if  <= pred_address_if  ;
            hit0_ff                 <= hit0             ;
            hit1_ff                 <= hit1             ;
            pred_direct_ff          <= pred_direct      ;
            pred_direct_if_ff       <= pred_direct_if   ;
            pred_info_ff            <= pred_info        ;
            pred_dely_ff            <= pred_dely        ;
            stallreq_ff             <= stallreq         ;                         
        end
    end
    
endmodule