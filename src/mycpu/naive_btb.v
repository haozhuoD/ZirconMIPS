`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/30 17:00:19
// Design Name: 
// Module Name: naive_btb
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


module naive_btb(
    input           clk             ,
    input           resetn          ,
    input           stallreq        ,

    input [31: 0]   pc              ,//real pc
    input [31: 0]   pc_plus         ,
    input [31: 0]   update_pc       ,
    input           update_valid    ,
    //update info
    input           pred_flag       ,
    input           pred_true       ,
    input           real_direct     ,
    input [31: 0]   real_address    ,
    input           update_type     ,

    output[31: 0]   pred_address    ,
    output[31: 0]   pred_address_if ,
    output          pred_direct     ,
    output          pred_direct_if  ,
    output          hit0            ,
    output          hit1            
    );

    reg   [54: 0]   btb_reg [511:0] ;//[54:53][52:32][31: 0]:direction[2],tag[21],TargetAddr[32]
    //reg   [23: 0]   btb_buffer      ;//[23: 9][ 8: 0]:tag[15],index[9]
    reg   [511:0]   btb_valid_list  ;

    wire  [20: 0]   tag             ;
    wire  [20: 0]   tag2            ;
    wire  [ 8: 0]   index           ;
    wire  [ 8: 0]   index_plus      ;
    wire  [20: 0]   update_tag      ;
    wire  [ 8: 0]   update_index    ;

    assign          tag             = pc[31:11]         ;
    assign          tag2            = pc_plus[31:11]    ;
    assign          index           = pc[10: 2]         ;
    assign          index_plus      = pc_plus[10: 2]    ;
    assign          update_tag      = update_pc[31:11]  ;
    assign          update_index    = update_pc[10: 2]  ;

    assign          pred_address    = resetn & btb_valid_list[index] ? (btb_reg[index][52:32] == tag ? btb_reg[index][31: 0] 
                                                                     :  pc + 32'h00000008) 
                                                                     :  pc + 32'h00000008           ;
    
    assign          pred_address_if = resetn & btb_valid_list[index_plus] ? (btb_reg[index_plus][52:32] == tag ? btb_reg[index_plus][31: 0] 
                                                                     :  pc + 32'h00000008) 
                                                                     :  pc + 32'h00000008           ;
    
    assign          pred_direct     = resetn & btb_valid_list[index]      & (btb_reg[index][53]      ^ btb_reg[index][54])      ;
    assign          pred_direct_if  = resetn & btb_valid_list[index_plus] & (btb_reg[index_plus][53] ^ btb_reg[index_plus][54]) ;
    
    assign          hit0            = resetn & (btb_valid_list[index]      & btb_reg[index][52:32] == tag)                      ;
    assign          hit1            = resetn & (btb_valid_list[index_plus] & btb_reg[index_plus][52:32] == tag2)                ;

    //update
    always @(posedge clk ) begin
        if (~resetn ) begin
            btb_valid_list  <= 512'h00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000;
        end
        else
        if (stallreq) begin
            
        end
        else          begin
            if (pred_flag) begin
                btb_valid_list[update_index]   <= 1'b1                                 ;
                if (update_type) begin
                    btb_reg[update_index]      <= {2'b10,update_tag,real_address}      ;
                end
                else             begin
                    case(btb_reg[update_index][54:53])
                        2'b11:  begin
                            btb_reg[update_index]  <= {2'b00,update_tag,real_address}  ;
                        end
                        2'b00:  begin
                            btb_reg[update_index]  <= {2'b01,update_tag,real_address}  ;
                        end
                        2'b01:  begin
                            btb_reg[update_index]  <= {2'b00,update_tag,real_address}  ;
                        end
                        2'b10:  begin
                            btb_reg[update_index]  <= {2'b01,update_tag,real_address}  ;
                        end
                        default:begin
                            btb_reg[update_index]  <= {2'b00,update_tag,real_address}  ;
                        end                    
                    endcase
                end
            end
            else
            if (pred_true) begin
                btb_valid_list[update_index]   <= 1'b1                             ;
                case(btb_reg[update_index][54:53])
                    2'b11:  begin
                        btb_reg[update_index]  <= {2'b11,update_tag,real_address}  ;
                    end
                    2'b00:  begin
                        btb_reg[update_index]  <= {2'b11,update_tag,real_address}  ;
                    end
                    2'b01:  begin
                        btb_reg[update_index]  <= {2'b10,update_tag,real_address}  ;
                    end
                    2'b10:  begin
                        btb_reg[update_index]  <= {2'b10,update_tag,real_address}  ;
                    end
                    default:begin
                        btb_reg[update_index]  <= {2'b00,update_tag,real_address}  ;
                    end                    
                endcase
            end
            else           begin
            end
        end
    end
endmodule
