`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/30 21:20:40
// Design Name: 
// Module Name: Cache_AXI_siwtch
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
READ_STATE

free    :00
d_read  :01
i_read  :10
default :11
*/
/*
!!!cache should not cancel thr REQ signal until the transmission has finished!!!
*/
module Cache_AXI_switch(
    input               clk            ,   
    input               resetn         ,  //low active
    input               flush          ,  //todo
    input  [ 5:0]       stall          ,  //todo
    //i_cache_read
    input               i_rd_req_i     ,
    input  [ 2:0]       i_rd_type_i    ,
    input  [31:0]       i_rd_addr_i    ,
    output              i_rd_finish_o  ,
    //d_cache_read
    
    input               LB_flag        ,
    output              rd_lb          ,
    
    input               d_rd_req_i     ,
    input  [ 2:0]       d_rd_type_i    ,
    input  [31:0]       d_rd_addr_i    ,
    output              d_rd_finish_o  ,
    //read
    input               rd_rdy_i       ,//
    input               ret_valid_i    ,
    input               ret_last_i     ,//
    input  [31:0]       ret_data_i     ,
    
    output              rd_req_o       ,
    output [ 2:0]       rd_type_o      ,
    output [31:0]       rd_addr_o      ,

    output reg [255:0]  read_buffer_alter   ,
    //d_cache_write
    input               d_wr_req_i     ,
    input  [ 2:0]       d_wr_type_i    ,
    input  [31:0]       d_wr_addr_i    ,
    input  [ 3:0]       d_wr_wstrb_i   ,
    input  [255:0]      d_wr_data_i    ,
    output              d_wr_finish_o  ,
    input               d_wr_finish_pro,

    output              wr_req_o       ,
    output [ 2:0]       wr_type_o      ,
    output [31:0]       wr_addr_o      ,
    output [ 3:0]       wr_wstrb_o     ,
    output [255:0]      wr_data_o      ,
    
    input               wr_resp_i      ,
    input               wr_rdy_i       ,
    //oops
    input  [127:0]      rd_data_oops   ,
    input               rd_oops        
    );

    reg    [ 1:0]       read_state      ;
    wire   [ 1:0]       next_read_state ;
    reg                 write_state     ;
    wire                next_write_state;
    reg    [31:0]       ocupied_address ;
    reg                 ocupied_flag    ;
    //reg    [127:0]      read_buffer     ;

    reg    [ 2:0]      read_cnt         ;
    //reg   [127:0]      read_buffer_alter;
    reg                ret_last_ff      ;
    reg                i_rd_finish_ff   ;
    reg                d_rd_finish_ff   ;
    //reg   [127:0]      rd_data_ff       ;
    wire               rd_free          ;

    assign  rd_free             = read_state == 2'b00                                               ;

    always @(posedge clk ) begin
       if (~resetn) begin
           read_state   <= 2'b00            ;
           write_state  <= 1'b0             ;
       end
       else begin
           read_state   <= next_read_state  ;
           write_state  <= next_write_state ;
       end 
    end

    assign  next_write_state    = resetn ? (write_state ? ~wr_resp_i : d_wr_req_i) : 1'b0           ;

    assign  next_read_state     = resetn ? (rd_free & ~rd_oops  ? (d_rd_req_i                          ? 2'b01           //priority
                                                                : (i_rd_req_i                          ? 2'b10 : 2'b00))
                                         : ((read_state == 2'b01 || read_state == 2'b10) && ret_last_i ? 2'b00 
                                         : read_state))
                                         : 2'b00                                                    ;

    assign  rd_req_o            = resetn & (d_rd_req_i || i_rd_req_i) & rd_rdy_i & (ocupied_flag | ocupied_address != d_rd_addr_i);
    assign  rd_lb               = resetn & LB_flag & d_rd_req_i                                     ;
    assign  rd_type_o           = resetn ? (d_rd_req_i ? d_rd_type_i 
                                         : (i_rd_req_i ? i_rd_type_i : 3'b000))
                                         : 3'b000                                                   ;
    
    assign  rd_addr_o           = resetn ? (d_rd_req_i ? d_rd_addr_i 
                                         : (i_rd_req_i ? i_rd_addr_i : 32'h00000000))
                                         : 32'h00000000                                             ;

        //8_15new
    always @(posedge clk)begin
        if  (~resetn) begin
            ocupied_address <= 32'd0                                                                ;
            ocupied_flag    <= 1'b1                                                                 ;
        end
        else
        if  (wr_resp_i)begin
            ocupied_flag    <= 1'b1                                                                 ;
        end
        else
        if  (d_wr_req_i & ocupied_flag) begin
            ocupied_address <= d_wr_addr_i                                                          ;
            ocupied_flag    <= 1'b0                                                                 ;
        end
    end
    
//    always @(posedge clk)begin
//        if  (~resetn) begin
//            d_wr_finish_ff  <= 1'b0                                                                 ;
//        end
//        else          begin
//            d_wr_finish_ff  <= d_wr_finish_pro                                                      ;
//        end
//    end
    //8_15end
    //assign  d_rd_finish_o       = (read_state == 2'b01) & ret_last_i                                ;
    //assign  i_rd_finish_o       = (read_state == 2'b10) & ret_last_i                                ;
    
    assign  d_rd_finish_o       = d_rd_finish_ff                                                    ;
    assign  i_rd_finish_o       = i_rd_finish_ff                                                    ;
    
    
    assign  d_wr_finish_o       = resetn & d_wr_finish_pro                                          ;
    //assign  rd_data_o           = resetn & (ret_last_i || rd_oops) ? read_buffer_alter              
    //                                                    : 128'h00000000_00000000_00000000_00000000  ;
    
    //assign  rd_data_o           = rd_data_ff                                                        ;
    
    assign  wr_req_o            = resetn & d_wr_req_i & wr_rdy_i                                    ;
    assign  wr_type_o           = resetn ? d_wr_type_i  : 3'b000                                    ;
    assign  wr_wstrb_o          = resetn ? d_wr_wstrb_i : 4'b1111                                   ;
    assign  wr_data_o           = resetn ? d_wr_data_i  : 256'd0                                    ;
    assign  wr_addr_o           = resetn ? d_wr_addr_i  : 32'h00000000                              ;

    always @(posedge clk ) begin
        if ( ~resetn | rd_free ) begin
            read_cnt           <= 3'b000                                                            ;
            //read_buffer        <= {ret_data_i,96'h00000000_00000000_00000000_00000000}              ;
        end
        else 
        if ( ret_valid_i ) begin
            read_cnt           <= read_cnt + 3'b001                                                 ;
            //read_buffer        <= {ret_data_i,read_buffer[127:32]}                                  ;
        end
    end
    
    always @(posedge clk) begin
        if (resetn) begin
            if (~rd_free & ret_valid_i) begin
                case(read_cnt)
                    3'b111: begin
                        read_buffer_alter[255:224]  <= ret_data_i   ;
                    end
                    3'b110: begin
                        read_buffer_alter[223:192]  <= ret_data_i   ;
                    end
                    3'b101: begin
                        read_buffer_alter[191:160]  <= ret_data_i   ;
                    end
                    3'b100: begin
                        read_buffer_alter[159:128]  <= ret_data_i   ;
                    end
                    3'b011: begin
                        read_buffer_alter[127: 96]  <= ret_data_i   ;
                    end
                    3'b010: begin
                        read_buffer_alter[ 95: 64]  <= ret_data_i   ;
                    end
                    3'b001: begin
                        read_buffer_alter[ 63: 32]  <= ret_data_i   ;
                    end
                    3'b000: begin
                        read_buffer_alter[ 31:  0]  <= ret_data_i   ;
                    end
                    default:begin
                        read_buffer_alter   <= 256'd0                       ;
                    end
                endcase
                ret_last_ff         <= ret_last_i                           ;
            end
            else
            if (~rd_free) begin
            end
            else    begin
                read_buffer_alter   <= 256'd0                               ;
                ret_last_ff         <= 1'b0                                 ;
            end
            i_rd_finish_ff          <= (read_state == 2'b10) & ret_last_i   ; 
            d_rd_finish_ff          <= (read_state == 2'b01) & ret_last_i   ;
            //rd_data_ff              <= resetn & (ret_last_i || rd_oops) ? read_buffer_alter              
            //                                            : 128'h00000000_00000000_00000000_00000000  ;
        end
        else    begin
            read_buffer_alter       <= 256'd0                               ;
            ret_last_ff             <= 1'b0                                 ;
            i_rd_finish_ff          <= 1'b0                                 ;
            d_rd_finish_ff          <= 1'b0                                 ;
            //rd_data_ff              <= 128'h00000000000000000000000000000000;
        end
    end

endmodule
