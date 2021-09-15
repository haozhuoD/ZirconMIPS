`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/29 10:30:49
// Design Name: 
// Module Name: naive_bht
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
//!!!7.9
//!!!a simple update strategy
//!!!while update,ex_info can easily calculate the bht'hash(address) for updating
//!!!don't use FIFO
 
module naive_bht(
    input           clk         ,
    input           resetn      ,
    input           stallreq    ,
    input           pred_true   ,
    input           update_addr ,
    input [ 5: 0]   bht_address ,
    input           pred_flag   ,
    input           pred_direct ,//form pht
    input           real_direct ,//
    input           update_valid,//current inst is branch inst,equal to bht_address valid

    output[ 3: 0]   update_bhr  ,
    output[ 3: 0]   bhr         
    );

    reg   [ 3: 0]   bht_reg     [63: 0] ;
    //stack
    //reg   [ 9: 0]   bht_buffer  [ 6: 0] ;//[9:4][3:0]:hash_addr[6]_bhr[4]//FIRST OUT
    //reg   [ 2: 0]   bht_buffer_pointer  ;

    reg   [63: 0]   bht_valid_list      ;//!
    //reg   [ 9: 0]   bht_buffer_second   ;

    //READ
    assign  bhr         = resetn & bht_valid_list[bht_address] ? bht_reg[bht_address] : 4'b0000                 ;//!!
    assign  update_bhr  = resetn ? bht_reg[update_addr] : 4'b0000                                               ;

    always @(posedge clk ) begin
        if (~resetn ) begin
            bht_valid_list  <= 64'h00000000_00000000;//!
            
            //bht_buffer[0]   <= 10'b0000000000       ;//
            //bht_buffer[1]   <= 10'b0000000000       ;
            //bht_buffer[2]   <= 10'b0000000000       ;
            //bht_buffer[3]   <= 10'b0000000000       ;
            //bht_buffer[4]   <= 10'b0000000000       ;
            //bht_buffer[5]   <= 10'b0000000000       ;
            //bht_buffer[6]   <= 10'b0000000000       ;
            //bht_buffer_pointer  <= 3'b000           ;
            
        end
        else
        if (stallreq) begin
            
        end
        else          begin
        
            if (pred_flag) begin
                bht_reg[update_addr]                        <= {bht_reg[bht_address][ 2: 0],real_direct}            ;
            end
            else           
            if (pred_true) begin
                bht_reg[update_addr]                        <= {bht_reg[bht_address][ 2: 0],real_direct}            ;
            end
            else           begin
            end

            if (bht_valid_list[bht_address]) begin
                
            end
            else                             begin
                bht_reg[bht_address]                        <= 4'b0000                                              ;
                bht_valid_list[bht_address]                 <= 1'b1                                                 ;
            end
        
        //!!also too complicated
            /*
            if (pred_flag) begin
                if (update_valid) begin
                    if (update_addr == bht_address) begin
                        bht_reg[bht_address]                <= {bht_reg[bht_address][ 1: 0],real_direct,pred_direct};
                    end
                    else
                    if (bht_valid_list[bht_address])    begin
                        bht_reg[bht_address]                <= {bht_reg[bht_address][ 2: 0],pred_direct}            ;
                        bht_reg[update_addr]                <= {bht_reg[update_addr][ 2: 0],real_direct}            ;
                    end
                    else                            begin
                        bht_reg[bht_address]                <= 4'b0000                                              ;
                        bht_valid_list[bht_address]         <= 1'b1                                                 ;
                        bht_reg[update_addr]                <= {bht_reg[update_addr][ 2: 0],real_direct}            ;
                    end
                end
            end
            else
            if (update_valid) begin
                if (bht_valid_list[bht_address]) begin
                    bht_reg[bht_address]                    <= {bht_reg[bht_address][ 2: 0],pred_direct}            ;
                end
                else                             begin
                    bht_reg[bht_address]                    <= 4'b0000                                              ;
                    bht_valid_list[bht_address]             <= 1'b1                                                 ;
                end 
            end
            else              begin
            end
            */

            //!!!too complicated
            /*if (pred_flag) begin//pred-fail
                if (update_valid) begin
                    if (~|(bht_address ^ bht_buffer[0][ 9: 4])) begin//confliction situation
                        bht_reg[bht_address]            <= {bht_buffer[0][ 1: 0],real_direct,pred_direct}   ;//update old/now
                        bht_buffer[0]                   <= {bht_address,bht_buffer[0][ 2: 0],real_direct}   ;//push in FIFO
                    end
                    else 
                    if (bht_valid_list[bht_address])            begin
                        bht_reg[bht_buffer[0][ 9: 4]]   <= {bht_buffer[0][ 2: 0],1'b0                   }   ;//update old
                        //at the same time,update by prediction
                        bht_reg[bht_address]            <= {bht_reg[bht_address][ 2: 0],pred_direct     }   ;//update now
                        bht_buffer[0]                   <= {bht_address,bht_reg[bht_address]            }   ;//push in FIFO
                    end
                    else                                        begin
                        bht_reg[bht_buffer[0][ 9: 4]]   <= {bht_buffer[0][ 2: 0],1'b0                   }   ;//update old
                        //at the same time,initial
                        bht_reg[bht_address]            <= 4'b0000                                          ;//initial now
                        bht_valid_list[bht_address]     <= 1'b1                                             ;//enable
                        bht_buffer[0]                   <= {bht_address,4'b0000                         }   ;//push in FIFO
                    end
                    bht_buffer_pointer                  <= 3'b001                                           ;//clear up buffer
                end
                else              begin
                    bht_reg[bht_buffer[0][ 9: 4]]       <= {bht_buffer[0][ 2: 0],1'b0}                      ;//update old
                    bht_buffer_pointer                  <= 3'b000                                           ;//clear up buffer
                end
            end
            else
            if (pred_true) begin
                if (update_valid) begin
                    if (bht_valid_list[bht_address]) begin
                        bht_reg[bht_address]            <= {bht_reg[bht_address][ 2: 0],pred_direct     }   ;//update now
                        if (|bht_buffer_pointer) begin
                            bht_buffer[bht_buffer_pointer - 1'b1]   <= {bht_address,bht_reg[bht_address]}   ;
                        end
                        else                     begin
                            bht_buffer[bht_buffer_pointer]          <= {bht_address,bht_reg[bht_address]}   ;//push in FIFO                            
                        end
                    end
                    else                             begin
                        bht_reg[bht_address]            <= 4'b0000                                          ;//initial now
                        bht_valid_list[bht_address]     <= 1'b1                                             ;//enable
                        if (|bht_buffer_pointer) begin
                            bht_buffer[bht_buffer_pointer - 1'b1]   <= {bht_address,4'b0000             }   ;
                        end
                        else                     begin
                            bht_buffer[bht_buffer_pointer]          <= {bht_address,4'b0000             }   ;//push in FIFO                        
                        end
                    end
                    case (bht_buffer_pointer)
                        3'b000: begin
                            //base:do nothing
                        end
                        3'b001: begin
                            //do nothing
                        end
                        3'b010: begin
                            bht_buffer[0]   <= bht_buffer[1];
                        end
                        3'b011: begin
                            bht_buffer[0]   <= bht_buffer[1];
                            bht_buffer[1]   <= bht_buffer[2];
                        end
                        3'b100: begin
                            bht_buffer[0]   <= bht_buffer[1];
                            bht_buffer[1]   <= bht_buffer[2];
                            bht_buffer[2]   <= bht_buffer[3];
                        end
                        3'b101: begin
                            bht_buffer[0]   <= bht_buffer[1];
                            bht_buffer[1]   <= bht_buffer[2];
                            bht_buffer[2]   <= bht_buffer[3];
                            bht_buffer[3]   <= bht_buffer[4];
                        end
                        3'b110: begin
                            bht_buffer[0]   <= bht_buffer[1];
                            bht_buffer[1]   <= bht_buffer[2];
                            bht_buffer[2]   <= bht_buffer[3];
                            bht_buffer[3]   <= bht_buffer[4];
                            bht_buffer[4]   <= bht_buffer[5];
                        end
                        default:begin
                            //do nothing
                        end
                    endcase
                end
                else                                 begin//rolling
                    bht_buffer[0]       <= bht_buffer[1];
                    bht_buffer[1]       <= bht_buffer[2];
                    bht_buffer[2]       <= bht_buffer[3];
                    bht_buffer[3]       <= bht_buffer[4];
                    bht_buffer[4]       <= bht_buffer[5];
                    bht_buffer[5]       <= bht_buffer[6];
                    if (|bht_buffer_pointer) begin
                        bht_buffer_pointer  <= bht_buffer_pointer + 3'b111  ;
                    end
                    else                     begin
                    end
                end
            end
            else           begin
                if (update_valid) begin
                    if (bht_valid_list[bht_address]) begin
                        bht_buffer[bht_buffer_pointer]  <= {bht_address,bht_reg[bht_address]       };
                        bht_reg[bht_address]            <= {bht_reg[bht_address][ 2: 0],pred_direct};
                    end
                    else                             begin
                        bht_buffer[bht_buffer_pointer]  <= {bht_address,4'b0000                    };
                        bht_reg[bht_address]            <= 4'b0000                                  ;
                        bht_valid_list[bht_address]     <= 1'b1                                     ;
                    end
                    bht_buffer_pointer                  <= bht_buffer_pointer + 3'b001              ;
                end
                else               begin
                    //do nothing
                end
            end*/
        end
    end
endmodule
