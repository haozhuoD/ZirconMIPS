`timescale                              1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/20 16:25:38
// Design Name: 
// Module Name: Instbuffer
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

module Instbuffer(
    input   clk,
    input   rst,
    input   flush,
    //issue
    input   wire    issue_mode_i,   //issue mode of issue stage
    input   wire    issue_i,        //whether issue stage has issued inst    发射阶段是否已经发出了指令
    output  wire[`InstBus]  issue_inst1_o, 
    output  wire[`InstBus]  issue_inst2_o,
    output  wire[`InstAddrBus]  issue_inst1_addr_o,
    output  wire[`InstAddrBus]  issue_inst2_addr_o,
    output wire[32:0]          issue_bpu_predict_info_o,
    output wire issue_ok_o,       //?
    
    //Fetch inst
        input   wire[`InstBus]  ICache_inst1_i,
        input   wire[`InstBus]  ICache_inst2_i,
        input   wire[`InstAddrBus]  ICache_inst1_addr_i,
        input   wire[`InstAddrBus]  ICache_inst2_addr_i, 
        input   wire                ICache_inst1_valid_i,
        input   wire                ICache_inst2_valid_i,
        input   wire[32:0]          bpu_predict_info_i,
        input   wire                bpu_select_i,
        output  wire                buffer_full_o,
        
        
        input only_delayslot_inst_i
    
  
    );
    
    
    //7.30
    wire[32:0]    issue_bpu_predict_info_o1     ;
        //队列本体
    reg [`InstBus]FIFO_data[`InstBufferSize-1:0];
    reg [64:0]FIFO_addr[`InstBufferSize-1:0];
	
    //头尾指针维护
    reg [`InstBufferSizeLog2-1:0]tail;//表征当前正在写入的数据位置
    reg [`InstBufferSizeLog2-1:0]head;//表征最后需要写入数据位置的后一位
    reg [`InstBufferSize-1:0]FIFO_valid;//表征buffer中的数据是否有效（高电平有效）
    always@(posedge clk)begin
        if(rst|flush)begin
            head <= `InstBufferSizeLog2'h0;
			FIFO_valid <= `InstBufferSize'h0;
        end
		//pop
        else if( issue_i == `Valid && issue_mode_i == `SingleIssue )begin//Issue one inst
            FIFO_valid[head] <= `Invalid;
			head <= head + 1;
            
		end
        else if( issue_i == `Valid && issue_mode_i == `DualIssue )begin//Issue two inst
			FIFO_valid[head] <= `Invalid;
			FIFO_valid[head+`InstBufferSizeLog2'h1] <= `Invalid;
            head <= head + 2;
		end
		
        if(rst|flush)begin
            tail <= `InstBufferSizeLog2'h0;
        end

        else if( ICache_inst1_valid_i == `Valid || ICache_inst2_valid_i == `Valid )begin//ICache return two inst
            if(only_delayslot_inst_i) begin
                FIFO_valid[tail] <= `Valid;
                tail <= tail + 1;
            end else begin
                FIFO_valid[tail] <= `Valid;
		  	    FIFO_valid[tail+`InstBufferSizeLog2'h1] <= `Valid;
                tail <= tail + 2;
		    end
		end
    end
	
	
	//Write
    always@(posedge clk)begin
  
        if(ICache_inst1_valid_i == `Valid || ICache_inst2_valid_i == `Valid) begin
            if(only_delayslot_inst_i)begin
                FIFO_data[tail] <= ICache_inst1_i;
                FIFO_addr[tail] <= bpu_select_i ? {ICache_inst1_addr_i,33'd0} : {ICache_inst1_addr_i,bpu_predict_info_i};
            end else begin 
            
		  FIFO_data[tail] <= ICache_inst1_i;
		  FIFO_data[tail+`InstBufferSizeLog2'h1] <= ICache_inst2_i;
		  FIFO_addr[tail] <= bpu_select_i ? {ICache_inst1_addr_i,33'd0} : {ICache_inst1_addr_i,bpu_predict_info_i};
		  FIFO_addr[tail+`InstBufferSizeLog2'h1] <= bpu_select_i ? {ICache_inst2_addr_i,bpu_predict_info_i} : {ICache_inst2_addr_i,33'd0};
		  
		     end
	   end	
		
    end
	   
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Output//////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

	
	assign issue_inst1_o =  FIFO_data[head]                           ; 
	assign issue_inst2_o =  FIFO_data[head+`InstBufferSizeLog2'h1]   ;
	
	assign issue_inst1_addr_o =  FIFO_addr[head][64:33]                        ;
	assign issue_inst2_addr_o =  FIFO_addr[head+`InstBufferSizeLog2'h1][64:33] ;
	assign issue_bpu_predict_info_o1 =  FIFO_addr[head][32:0] ;


	assign issue_bpu_predict_info_o = (issue_bpu_predict_info_o1 ) ? issue_bpu_predict_info_o1 :0;

 	assign issue_ok_o = FIFO_valid[head+`InstBufferSizeLog2'h1];
    //full
	assign buffer_full_o = FIFO_valid[tail+`InstBufferSizeLog2'h5];

    
    
    
    
endmodule
