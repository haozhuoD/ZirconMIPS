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
    //output wire [`SIZE_OF_CORR_PACK] issue_bpu_corr1_o,
//    output wire [`SIZE_OF_CORR_PACK] issue_bpu_corr2_o,
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
        
        //input [3:0]             stall,
        
        //input   cpu_req_i,
//        input ninst_in_delayslot_i,
        
        input only_delayslot_inst_i
    
  
    );
    
//    wire ICache_inst1_valid_o;
//    wire ICache_inst2_valid_o;
    
//    reg cpu_req;
//    always@(posedge clk) begin
//        if(rst)     cpu_req <= `Invalid;
//        //else if(stall == 4'b0011) cpu_req <= cpu_req;
//        else        cpu_req <= cpu_req_i;
//    end
    
//    assign ICache_inst1_valid_o = cpu_req & ~rst;
//    assign ICache_inst2_valid_o = cpu_req & ~rst;
//    /* (ICache_inst2_addr_i[3:2] == 2'b11)? `Invalid:ICache_inst1_valid_o;*/
    
    //7.30
    wire[32:0]    issue_bpu_predict_info_o1     ;
        //队列本体
    reg [`InstBus]FIFO_data[`InstBufferSize-1:0];
    reg [64:0]FIFO_addr[`InstBufferSize-1:0];
    //reg [`SIZE_OF_CORR_PACK]FIFO_bpu_corr[`InstBufferSize-1:0];
	
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
        else if( issue_i == `Valid && issue_mode_i == `SingleIssue /*&& issue_ok_o == `Valid*/)begin//Issue one inst
            FIFO_valid[head] <= `Invalid;
			head <= head + 1;
            
		end
        else if( issue_i == `Valid && issue_mode_i == `DualIssue /*&& issue_ok_o == `Valid*/)begin//Issue two inst
			FIFO_valid[head] <= `Invalid;
			FIFO_valid[head+`InstBufferSizeLog2'h1] <= `Invalid;
            head <= head + 2;
		end
		
        if(rst|flush)begin
            tail <= `InstBufferSizeLog2'h0;
        end
		//push
//        else if( ICache_inst1_valid_o == `Valid && ICache_inst2_valid_o == `Invalid /*&& stall != 4'b0011 && stall!=4'b0001 */)begin//ICache return one inst
//			FIFO_valid[tail] <= (tail==head)? `Invalid:`Valid;
//            tail <= tail + 1;
//		end
//        else if( ICache_inst1_valid_o == `Valid && ICache_inst2_valid_o == `Valid /*&& stall != 4'b0011 */)begin//ICache return two inst
//			FIFO_valid[tail] <= (tail==head)? `Invalid:`Valid;
//			FIFO_valid[tail+`InstBufferSizeLog2'h1] <= (tail==head)? `Invalid:`Valid;
//            tail <= tail + 2;
//		end
//        else if( ICache_inst1_valid_o == `Valid && ICache_inst2_valid_o == `Invalid /*&& stall != 4'b0011 && stall!=4'b0001 */)begin//ICache return one inst
//			FIFO_valid[tail] <= (tail==head)? `Invalid:`Valid;
//            tail <= tail + 1;
//		  end
//		else if( ICache_inst1_valid_o == `Invalid && ICache_inst2_valid_o == `Valid /*&& stall != 4'b0011 && stall!=4'b0001 */)begin//ICache return one inst
//			FIFO_valid[tail] <= (tail==head)? `Invalid:`Valid;
//            tail <= tail + 1;
//		end
        else if( ICache_inst1_valid_i == `Valid || ICache_inst2_valid_i == `Valid /*&& stall != 4'b0011 */)begin//ICache return two inst
//			FIFO_valid[tail] <= (tail==head)? `Invalid:`Valid;
//			FIFO_valid[tail+`InstBufferSizeLog2'h1] <= (tail==head)? `Invalid:`Valid;
//            tail <= tail + 2;
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
        //if(flush) begin     //应该把buffer全清空吗？
          //FIFO_data <=   
        //end else begin    
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
		//FIFO_bpu_corr[tail] <= bpu_corr1_i;
		//FIFO_bpu_corr[tail+`InstBufferSizeLog2'h1] <= bpu_corr2_i;
//		  FIFO_data[tail] <= ICache_inst1_valid_o ? ICache_inst1_i : ICache_inst2_i;
//		  FIFO_data[tail+`InstBufferSizeLog2'h1] <= ICache_inst2_i;
//		  FIFO_addr[tail] <= ICache_inst1_valid_o ? ICache_inst1_addr_i :ICache_inst2_addr_i;
//		  FIFO_addr[tail+`InstBufferSizeLog2'h1] <= ICache_inst2_addr_i;
		
		
    end
	   
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Output//////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

	
/*	reg [`InstBufferSizeLog2-1:0]head_o;//记录上一拍的head值，用于给inst_o赋值
	always@(posedge clk) begin
	   if(rst|flush)   head_o <= `InstBufferSizeLog2'h0;
	   else if(issue_mode_i == `SingleIssue)    head_o <= head_o + 1; 
	   else   head_o <= head;
	end
	*/
//	reg ICache_inst1_valid;
//	reg ICache_inst2_valid;
	
//	always@(posedge clk) begin
//	   ICache_inst1_valid <= ICache_inst1_valid_o;
//	   ICache_inst2_valid <= ICache_inst2_valid_o;
//	   end
	
	
//	assign issue_inst1_o =issue_i? FIFO_data[head]                          :   0 ; 2021.7.14
//	assign issue_inst2_o =issue_i? FIFO_data[head+`InstBufferSizeLog2'h1]   :   0;
//	//assign issue_inst2_o = (issue_mode_i)? FIFO_data[head_o+`InstBufferSizeLog2'h1]:issue_inst2_o;
//	assign issue_inst1_addr_o =issue_i ? FIFO_addr[head]                        :   0 ;
//	assign issue_inst2_addr_o =issue_i ? FIFO_addr[head+`InstBufferSizeLog2'h1]  :   0;
//	//assign issue_inst2_addr_o = (issue_mode_i)? FIFO_addr[head_o+`InstBufferSizeLog2'h1]:issue_inst2_addr_o;
	
	assign issue_inst1_o =  FIFO_data[head]                           ; 
	assign issue_inst2_o =  FIFO_data[head+`InstBufferSizeLog2'h1]   ;
	
	assign issue_inst1_addr_o =  FIFO_addr[head][64:33]                        ;
	assign issue_inst2_addr_o =  FIFO_addr[head+`InstBufferSizeLog2'h1][64:33] ;
	assign issue_bpu_predict_info_o1 =  FIFO_addr[head][32:0] ;


	
	
	//think zhijie assign ????????????? 8_3
//	assign issue_inst1_o = (issue_ok_o/*|ninst_in_delayslot_i*/)? FIFO_data[head]                          :   0 ; 
//	assign issue_inst2_o = (issue_ok_o/*|ninst_in_delayslot_i*/)? FIFO_data[head+`InstBufferSizeLog2'h1]   :   0;
	
//	assign issue_inst1_addr_o = (issue_ok_o/*|ninst_in_delayslot_i*/) ? FIFO_addr[head][64:33]                        :   0 ;
//	assign issue_inst2_addr_o = (issue_ok_o/*|ninst_in_delayslot_i*/) ? FIFO_addr[head+`InstBufferSizeLog2'h1][64:33]  :   0;
//	assign issue_bpu_predict_info_o1 = (issue_ok_o/*|ninst_in_delayslot_i*/) ? FIFO_addr[head][32:0] : 0;

	assign issue_bpu_predict_info_o = (issue_bpu_predict_info_o1 ) ? issue_bpu_predict_info_o1 :0;
	
	

//	assign issue_ok_o = FIFO_valid[head+`InstBufferSizeLog2'h2];
//    //full
//	assign buffer_full_o = FIFO_valid[tail+`InstBufferSizeLog2'h7];
 	assign issue_ok_o = FIFO_valid[head+`InstBufferSizeLog2'h1];
    //full
	assign buffer_full_o = FIFO_valid[tail+`InstBufferSizeLog2'h5];

    
    
    
    
endmodule
