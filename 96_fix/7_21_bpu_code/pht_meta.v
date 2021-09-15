`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/29 11:36:00
// Design Name: 
// Module Name: pht_meta
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
/*
2'b11 :strong_Jump
2'b00 :weak_Jump
2'b01 :weak_notJump
2'b10 :strong_notJump
*/

module pht_meta(
    input           clk         ,
    input           resetn      ,
    input           stallreq    ,
    input [ 7: 0]   pht_addr    ,
    input           pred_true   ,
    input           pred_flag   ,
    input           update_valid,//only update while information is valid(branch_inst in ex_period)
    input [ 7: 0]   update_addr ,

    output          pred_direct        
    );

    reg   [ 1: 0]   pht_reg [255:0]     ;
    //reg   [ 9: 0]   pht_buffer [ 6: 0]  ;//[9:2][1:0]:predDirect_pht_addr[8]_pht[2]
    //reg   [ 2: 0]   pht_buffer_pointer  ;
    reg   [255:0]   pht_valid_list      ;
    //reg   [12: 0]   pht_buffer_second   ;//before predit!!!

    //READ
    assign          pred_direct =   resetn & (pht_reg[pht_addr][0] ^ pht_reg[pht_addr][1]) & pht_valid_list[pht_addr]  ;//because of the decoding rule

    //UPDATE
    always @(posedge clk ) begin
        if (~resetn ) begin
            pht_valid_list      <= 256'h00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000 ;
            //pht_buffer[0]       <=  10'b0000000000                                                              ;
            //pht_buffer[1]       <=  10'b0000000000                                                              ;
            //pht_buffer[2]       <=  10'b0000000000                                                              ;
            //pht_buffer[3]       <=  10'b0000000000                                                              ;
            //pht_buffer[4]       <=  10'b0000000000                                                              ;
            //pht_buffer[5]       <=  10'b0000000000                                                              ;
            //pht_buffer[6]       <=  10'b0000000000                                                              ;
            //pht_buffer_pointer  <=   3'b000                                                                     ;
        end
        else
        if (stallreq) begin
            
        end
        else          begin
            if (pred_flag) begin
                case (pht_reg[update_addr])
                    2'b11:  begin
                        pht_reg[update_addr]    <= 2'b00;
                    end 
                    2'b00:  begin
                        pht_reg[update_addr]    <= 2'b01;
                    end
                    2'b01:  begin
                        pht_reg[update_addr]    <= 2'b00;
                    end
                    2'b10:  begin
                        pht_reg[update_addr]    <= 2'b01;
                    end
                    default:begin
                        pht_reg[update_addr]    <= 2'b11;
                    end 
                endcase
            end
            else
            if (pred_true) begin
                case (pht_reg[update_addr])
                    2'b11:  begin
                    end 
                    2'b00:  begin
                        pht_reg[update_addr]    <= 2'b11;
                    end
                    2'b01:  begin
                        pht_reg[update_addr]    <= 2'b10;
                    end
                    2'b10:  begin
                    end
                    default:begin
                        pht_reg[update_addr]    <= 2'b11;
                    end
                endcase
            end
            
            if (update_valid) begin
                if (pht_valid_list[pht_addr]) begin
                end
                else                          begin
                    pht_reg[pht_addr]           <= 2'b11;
                    pht_valid_list[pht_addr]    <= 1'b1 ;
                end
            end
            else              begin  
            end    
        end
    end        
endmodule


        //!!!more simple

        /*
        case0:update_valid
            case0_1:update_valid & pred_flag
                case0_1_1:update_valid & pred_flag & address_conflicttion
                case0_1_2:update_valid & pred_flag & list_invalid
            case0_2:update_valid & pred_true
                case0_2_1:update_valid & pred_true & list_invalid
            case_0_3:update_valid & list_invalid
        case1:pred_flag
        case2:pred_true
        case3:nope
        !!!simplify
        !!!don't immediately update?
        */
        /*
        if (pred_flag) begin
            if (update_valid) begin
                if (pht_valid_list[pht_addr]) begin
                    pht_buffer[0]                   <= {pht_addr,pht_reg[pht_addr]} ;
                end
                else                          begin
                    pht_reg[pht_addr]               <= 2'b11                        ;
                    pht_valid_list[pht_addr]        <= 1'b1                         ;
                    pht_buffer[0]                   <= {pht_addr,2'b11}             ;
                end
                pht_buffer_pointer                  <= 3'b001                       ;//clear and add newest
            end
            else              begin
                pht_buffer_pointer                  <= 3'b000                       ;//clear
            end
            case (pht_buffer[0][ 1: 0])//adjust
                2'b11:  begin
                    pht_reg[pht_buffer[0][ 9: 2]]   <= 2'b00;
                end
                2'b00:  begin
                    pht_reg[pht_buffer[0][ 9: 2]]   <= 2'b01;
                end
                2'b01:  begin
                    pht_reg[pht_buffer[0][ 9: 2]]   <= 2'b00;
                end
                2'b10:  begin
                    pht_reg[pht_buffer[0][ 9: 2]]   <= 2'b01;
                end 
                default:begin
                    //do nothing
                end 
            endcase
        end
        else
        if (pred_true) begin
            if (update_valid) begin
                if (pht_valid_list[pht_addr]) begin
                    if (|pht_buffer_pointer) begin
                        pht_buffer[pht_buffer_pointer - 1'b1]   <= {pht_addr,pht_reg[pht_addr]} ;
                    end
                    else                     begin
                        pht_buffer[pht_buffer_pointer]          <= {pht_addr,pht_reg[pht_addr]} ;                        
                    end
                end
                else                          begin
                    pht_reg[pht_addr]                           <= 2'b11                        ;
                    pht_valid_list[pht_addr]                    <= 1'b1                         ;
                    if (|pht_buffer_pointer) begin
                        pht_buffer[pht_buffer_pointer - 1'b1]   <= {pht_addr,2'b11}             ;
                    end
                    else                     begin
                        pht_buffer[pht_buffer_pointer]          <= {pht_addr,2'b11}             ;                        
                    end
                end
                case (pht_buffer_pointer)
                    3'b000: begin
                    //base:do nothing
                    end
                    3'b001: begin
                    end 
                    3'b010: begin
                        pht_buffer[0]   <= pht_buffer[1];
                    end
                    3'b011: begin
                        pht_buffer[0]   <= pht_buffer[1];
                        pht_buffer[1]   <= pht_buffer[2];
                    end
                    3'b100: begin
                        pht_buffer[0]   <= pht_buffer[1];
                        pht_buffer[1]   <= pht_buffer[2];
                        pht_buffer[2]   <= pht_buffer[3];
                    end
                    3'b101: begin
                        pht_buffer[0]   <= pht_buffer[1];
                        pht_buffer[1]   <= pht_buffer[2];
                        pht_buffer[2]   <= pht_buffer[3];
                        pht_buffer[3]   <= pht_buffer[4];
                    end
                    3'b110: begin
                        pht_buffer[0]   <= pht_buffer[1];
                        pht_buffer[1]   <= pht_buffer[2];
                        pht_buffer[2]   <= pht_buffer[3];
                        pht_buffer[3]   <= pht_buffer[4];
                        pht_buffer[4]   <= pht_buffer[5];
                    end
                    default:begin
                        //do nothing
                    end 
                endcase
            end
            else       begin
                pht_buffer[0]           <= pht_buffer[1];
                pht_buffer[1]           <= pht_buffer[2];
                pht_buffer[3]           <= pht_buffer[3];
                pht_buffer[4]           <= pht_buffer[5];
                pht_buffer[5]           <= pht_buffer[6];
                if (|pht_buffer_pointer) begin
                    pht_buffer_pointer  <= pht_buffer_pointer + 3'b111  ;
                end
                else                     begin
                end
            end
            case (pht_buffer[0][ 1: 0])//update
                2'b11:  begin
                    //do nothing
                end
                2'b00:  begin
                    pht_reg[pht_buffer[0][ 9: 2]]   <= 2'b11;
                end
                2'b01:  begin
                    pht_reg[pht_buffer[0][ 9: 2]]   <= 2'b10;
                end
                2'b10:  begin
                    //do nothing
                end 
                default:begin
                    //do nothing
                end
            endcase
        end
        else
        if (update_valid) begin
            if (pht_valid_list[pht_addr]) begin
                pht_buffer[pht_buffer_pointer]      <= {pht_addr,pht_reg[pht_addr]} ;
            end
            else                          begin
                pht_buffer[pht_buffer_pointer]      <= {pht_addr,2'b11}             ;
                pht_reg[pht_addr]                   <= 2'b11                        ;
                pht_valid_list[pht_addr]            <= 2'b1                         ;
            end
            if (&pht_buffer_pointer) begin
            end
            else                     begin
                pht_buffer_pointer                  <= pht_buffer_pointer + 3'b001  ;
            end
        end
        else              begin
            //do nothing
        end
        */

