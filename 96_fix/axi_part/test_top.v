`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/15 17:45:36
// Design Name: 
// Module Name: test_top
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


module test_top(
    input   clk,
    input   resetn,
    input   flush,
    input   [5:0]stall,
    
    input               i_rd_req_i     ,
    input  [ 2:0]       i_rd_type_i    ,
    input  [31:0]       i_rd_addr_i    ,
    output              i_rd_finish_o  ,

    input               d_rd_req_i     ,
    input  [ 2:0]       d_rd_type_i    ,
    input  [31:0]       d_rd_addr_i    ,
    output              d_rd_finish_o  ,
    
    input               LB_flag        ,
    
    input               d_wr_req_i     ,
    input  [ 2:0]       d_wr_type_i    ,
    input  [31:0]       d_wr_addr_i    ,
    input  [ 3:0]       d_wr_wstrb_i   ,
    input  [255:0]      d_wr_data_i    ,
    output              d_wr_finish_o  ,
    output [255:0]      read_data      ,

    input                   rlast     ,
    input             [31:0]rdata     ,

    input                   wready    ,
    output                  rready    ,
    input                   awready   ,
    input                   arready   ,
    output                  bready    ,

    input                   bvalid    ,
    output                  arvalid   ,
    output                  awvalid   ,
    input                   rvalid    ,
    output                  wvalid    ,

    output             [31:0]araddr   ,
    output             [ 2:0]arsize   ,

    output             [ 2:0]awsize   ,
    output             [31:0]awaddr   ,

    output                   wlast    ,
    output             [31:0]wdata    ,
    output             [ 3:0]wstrb    ,
    //!
    output             [ 3:0]awid     ,
    output             [ 7:0]awlen    ,
    output             [ 1:0]awburst  ,

    input              [ 3:0]bid      ,
    input              [ 1:0]bresp    ,
    
    output             [ 3:0]arid     ,
    output             [ 7:0]arlen    ,
    output             [ 1:0]arburst  ,                       

    input              [ 3:0]rid      ,
    input              [ 1:0]rresp       
    );
    //axi_cache switch
    wire                rd_rdy         ;
    wire                ret_valid      ;
    wire                ret_last       ;
    wire          [31:0]ret_data       ;          

    wire                rd_req         ;
    wire          [ 2:0]rd_type        ;
    wire          [31:0]rd_addr        ;

    wire                wr_req         ;
    wire          [ 2:0]wr_type        ;
    wire          [31:0]wr_addr        ;
    wire          [ 3:0]wr_wstrb       ;
    wire         [255:0]wr_data        ;
    wire                wr_resp        ;
    wire                wr_rdy         ;

    wire         [255:0]rd_data_oops   ;
    wire                rd_oops        ;

    
    wire                   rd_lb       ;
    
    Cache_AXI_switch bridge(.clk(clk),
                            .resetn(resetn),
                            .flush(flush),
                            .stall(stall),
                            
                            .i_rd_req_i(i_rd_req_i),
                            .i_rd_type_i(i_rd_type_i),
                            .i_rd_addr_i(i_rd_addr_i),
                            .i_rd_finish_o(i_rd_finish_o),
                            
                            .d_rd_req_i(d_rd_req_i),
                            .d_rd_type_i(d_rd_type_i),
                            .d_rd_addr_i(d_rd_addr_i),
                            .d_rd_finish_o(d_rd_finish_o),
                            
                            .LB_flag(LB_flag),
                            .rd_lb(rd_lb),
                            
                            .rd_rdy_i(rd_rdy),
                            .ret_valid_i(ret_valid),
                            .ret_last_i(ret_last),
                            .ret_data_i(ret_data),

                            .rd_req_o(rd_req),
                            .rd_type_o(rd_type),
                            .rd_addr_o(rd_addr),
                            .read_buffer_alter(read_data),
                            .rd_oops(1'b0),
                            .rd_data_oops(32'h00000000),

                            .d_wr_req_i(d_wr_req_i),
                            .d_wr_type_i(d_wr_type_i),
                            .d_wr_addr_i(d_wr_addr_i),
                            .d_wr_wstrb_i(d_wr_wstrb_i),
                            .d_wr_data_i(d_wr_data_i),
                            .d_wr_finish_o(d_wr_finish_o),
                            .d_wr_finish_pro(wlast),

                            .wr_req_o(wr_req),
                            .wr_type_o(wr_type),
                            .wr_addr_o(wr_addr),
                            .wr_wstrb_o(wr_wstrb),
                            .wr_data_o(wr_data),

                            .wr_resp_i(wr_resp),
                            .wr_rdy_i(wr_rdy)
                            );


    simple_axi TEST(.clk(clk),
                   .resetn(resetn),
                   .flush(flush),
                   .rd_req_i(rd_req),
                   .rd_rdy_o(rd_rdy),
                   .rd_addr_i(rd_addr),
                   .rd_type_i(rd_type),
                   .ret_valid_o(ret_valid),
                   .ret_last_o(ret_last),
                   .ret_data_o(ret_data),

                   .wr_req_i(wr_req),
                   .wr_type_i(wr_type),
                   .wr_addr_i(wr_addr),
                   .wr_wstrb_i(wr_wstrb),
                   .wr_data_i(wr_data),
                   .wr_rdy_o(wr_rdy),
                   .wr_resp_o(wr_resp),
                   
                   .rd_lb(rd_lb),
                   
                   .arid(arid),
                   .araddr(araddr),
                   .arlen(arlen),
                   .arsize(arsize),
                   .arburst(arburst),
                   
                   .arvalid(arvalid),
                   .arready(arready),

                   .rid(rid),
                   .rresp(rresp),
                   .rlast(rlast),
                   .rdata(rdata),
                   
                   .rvalid(rvalid),
                   .rready(rready),

                   .awid(awid),
                   .awaddr(awaddr),
                   .awlen(awlen),
                   .awsize(awsize),
                   .awburst(awburst),

                   .awvalid(awvalid),
                   .awready(awready),

                   .wdata(wdata),
                   .wstrb(wstrb),
                   .wlast(wlast),

                   .wvalid(wvalid),
                   .wready(wready),

                   .bid(bid),
                   .bresp(bresp),
                   .bvalid(bvalid),
                   .bready(bready)
                    );
                    
endmodule
