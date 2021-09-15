`include "defines.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/24 18:01:22
// Design Name: 
// Module Name: test
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


module DCache(
     // 
    input  wire              clk_g,
    input  wire              resetn,
    // Cache与CPU流水线的交互接口
    input  wire              D_UnCache,
    input  wire              LB_req,  
    input  wire              valid,
    input  wire              op,    //op=1,Write
    input  wire [`IndexBus]  index,
    input  wire [`TagBus]    tag,
    input  wire [`OffsetBus] offset,
    input  wire [`WstrbBus]  wstrb,
    input  wire [`DataBus]   wdata,
    
    output wire              addr_ok,
    output wire              data_ok,
    output wire [`DataBus]   rdata,
    // Cache与AXI总线接口的交互接�?
    output wire              LB_flag,
    output wire              rd_req,//zhe san ge tong shi
    output wire [`TypeBus]   rd_type,
    output wire [`AddrBus]   rd_addr,
    input  wire              rd_finish,
    input  wire [`LineBus]   rd_data,
    
    output wire              wr_req,//tong shi
    output wire [`TypeBus]   wr_type,
    output wire [`AddrBus]   wr_addr,
    output wire [`WstrbBus]  wr_wstrb,
    output wire [`LineBus]   wr_data,
    input  wire              wr_finish
    
);
    

    
    parameter DLY = 0;
   
    // Dirty Table
    reg [127:0]       dirty_table [1:0];
    
    // Requset Buffer
    reg               buffer_op0;
    reg               buffer_LB;
    reg  [`IndexBus]  buffer_index0;
    reg  [`TagBus]    buffer_tag0;
    reg  [`OffsetBus] buffer_offset0;
    reg  [`WstrbBus]  buffer_wstrb0;
    reg  [`DataBus]   buffer_data0;
    reg               buffer_op1;
    reg  [`IndexBus]  buffer_index1;
    reg  [`TagBus]    buffer_tag1;
    reg  [`OffsetBus] buffer_offset1;
    
    // PLRU
    reg [127:0] PLRU; // 寄存器的个数即为bram中数据块的个�?
    reg         PLRU_buffer;
    
    // Write Buffer
//    reg              Write_Way0;
//    reg              Write_Way1;
//    reg [`IndexBus]  Write_Index;
//    reg [`DataBus]   Write_Data;
//    reg [`WstrbBus]  Write_Wstrb;
//    reg [`OffsetBus] Write_Offset;
//    reg [`TagBus]    Write_Tag;
    
    // Miss Buffer 
    reg [`LineBus]   miss_data0;
    reg [`LineBus]   miss_data1;
    reg [`TagBus]    miss_tag0;
    reg [`TagBus]    miss_tag1;
    
    // rd_finish buffer
    reg              miss_rd_finish;
    
    // Tag Compare
    wire             way0_hit;
    wire             way1_hit;
    wire             cache_hit;
    
    // Hit Write 读写地址冲突
 //   wire             hit_write; // 主状态机处于LOOKUP，且有Store指令命中，�?�此时流水线发来�?个与该Store指令地址相同的Load指令
//    wire             hit_write1; // Write Buffer处于WRITE，此时流水线发来�?个Load指令且Load指令地址与Store地址重叠 
    reg              buffer_hit_write; // 
    wire [`DataBus]  wsel_expand0;      // hit_write0数据前推时的拼接信号
//    wire [`DataBus]  wsel_expand1;      // hit_write1数据前推时的拼接信号
    
    // Read from Data_ram and Tagv_ram
    wire             enb;
    wire [`DataBus]  rdata_way0_bank0;
    wire [`DataBus]  rdata_way0_bank1;
    wire [`DataBus]  rdata_way0_bank2;
    wire [`DataBus]  rdata_way0_bank3;
    wire [`DataBus]  rdata_way0_bank4;
    wire [`DataBus]  rdata_way0_bank5;
    wire [`DataBus]  rdata_way0_bank6;
    wire [`DataBus]  rdata_way0_bank7;
    wire [`DataBus]  rdata_way1_bank0;
    wire [`DataBus]  rdata_way1_bank1;
    wire [`DataBus]  rdata_way1_bank2;
    wire [`DataBus]  rdata_way1_bank3;
    wire [`DataBus]  rdata_way1_bank4;
    wire [`DataBus]  rdata_way1_bank5;
    wire [`DataBus]  rdata_way1_bank6;
    wire [`DataBus]  rdata_way1_bank7;
    wire [`TagvBus]  rtagv_way0;
    wire [`TagvBus]  rtagv_way1;
    
    // Write to Data_ram and Tagv_ram
    wire             dena00;
    wire             dena01;
    wire             dena02;
    wire             dena03;
    wire             dena04;
    wire             dena05;
    wire             dena06;
    wire             dena07;
    wire             dena10;
    wire             dena11;
    wire             dena12;
    wire             dena13;
    wire             dena14;
    wire             dena15;
    wire             dena16;
    wire             dena17;
    wire             ena0;
    wire             ena1;
    wire [`DataBus]  write_data0;
    wire [`DataBus]  write_data1;
    wire [`DataBus]  write_data2;
    wire [`DataBus]  write_data3;
    wire [`DataBus]  write_data4;
    wire [`DataBus]  write_data5;
    wire [`DataBus]  write_data6;
    wire [`DataBus]  write_data7;
    wire [`TagvBus]  wtagv;
    wire [`IndexBus] waddr;
    wire [`WstrbBus] dwea;
    wire             wea; // tagv的字节�?�择信号
    
    // Select Data and Judge Data
    
    wire [`DataBus]  way0_data;
    wire [`DataBus]  way1_data;
    reg  [`DataBus]  rddata_buffer;
    reg  [`DataBus]  way0_data_buffer;
    reg  [`DataBus]  way1_data_buffer;
    
    // Variable of StateMachine
    
    reg [`DMStateBus] current_mstate;
    reg [`DMStateBus] next_mstate;
//    reg [`WStateBus] current_wstate;
//    reg [`WStateBus] next_wstate;
    localparam MIDLE   = 7'b0000001;
    localparam LOOKUP  = 7'b0000010;
    localparam MISS    = 7'b0000100;
    localparam REPLACE = 7'b0001000;
    localparam REFILL  = 7'b0010000;
    localparam UNREAD  = 7'b0100000;
    localparam UNWRITE = 7'b1000000;
//    localparam WIDLE   = 2'b01;
//    localparam WRITE   = 2'b10;
    

    // Cache Memory
    Data_RAM data_ram_way0_bank0 (
        .clka(clk_g),    // input wire clka
        .ena(dena00),      // input wire ena
        .wea(dwea),      // input wire [3 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(write_data0),    // input wire [31 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rdata_way0_bank0)  // output wire [31 : 0] doutb
    );
    Data_RAM data_ram_way0_bank1 (
        .clka(clk_g),    // input wire clka
        .ena(dena01),      // input wire ena
        .wea(dwea),      // input wire [3 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(write_data1),    // input wire [31 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rdata_way0_bank1)  // output wire [31 : 0] doutb
    );
    Data_RAM data_ram_way0_bank2 (
        .clka(clk_g),    // input wire clka
        .ena(dena02),      // input wire ena
        .wea(dwea),      // input wire [3 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(write_data2),    // input wire [31 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rdata_way0_bank2)  // output wire [31 : 0] doutb
    );
    Data_RAM data_ram_way0_bank3 (
        .clka(clk_g),    // input wire clka
        .ena(dena03),      // input wire ena
        .wea(dwea),      // input wire [3 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(write_data3),    // input wire [31 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rdata_way0_bank3)  // output wire [31 : 0] doutb
    );
    Data_RAM data_ram_way0_bank4 (
        .clka(clk_g),    // input wire clka
        .ena(dena04),      // input wire ena
        .wea(dwea),      // input wire [3 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(write_data4),    // input wire [31 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rdata_way0_bank4)  // output wire [31 : 0] doutb
    );
    Data_RAM data_ram_way0_bank5 (
        .clka(clk_g),    // input wire clka
        .ena(dena05),      // input wire ena
        .wea(dwea),      // input wire [3 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(write_data5),    // input wire [31 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rdata_way0_bank5)  // output wire [31 : 0] doutb
    );
    Data_RAM data_ram_way0_bank6 (
        .clka(clk_g),    // input wire clka
        .ena(dena06),      // input wire ena
        .wea(dwea),      // input wire [3 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(write_data6),    // input wire [31 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rdata_way0_bank6)  // output wire [31 : 0] doutb
    );
    Data_RAM data_ram_way0_bank7 (
        .clka(clk_g),    // input wire clka
        .ena(dena07),      // input wire ena
        .wea(dwea),      // input wire [3 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(write_data7),    // input wire [31 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rdata_way0_bank7)  // output wire [31 : 0] doutb
    );
    
    Data_RAM data_ram_way1_bank0 (
        .clka(clk_g),    // input wire clka
        .ena(dena10),      // input wire ena
        .wea(dwea),      // input wire [3 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(write_data0),    // input wire [31 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rdata_way1_bank0)  // output wire [31 : 0] doutb
    );
    Data_RAM data_ram_way1_bank1 (
        .clka(clk_g),    // input wire clka
        .ena(dena11),      // input wire ena
        .wea(dwea),      // input wire [3 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(write_data1),    // input wire [31 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rdata_way1_bank1)  // output wire [31 : 0] doutb
    );
    Data_RAM data_ram_way1_bank2 (
        .clka(clk_g),    // input wire clka
        .ena(dena12),      // input wire ena
        .wea(dwea),      // input wire [3 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(write_data2),    // input wire [31 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rdata_way1_bank2)  // output wire [31 : 0] doutb
    );
    Data_RAM data_ram_way1_bank3 (
        .clka(clk_g),    // input wire clka
        .ena(dena13),      // input wire ena
        .wea(dwea),      // input wire [3 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(write_data3),    // input wire [31 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rdata_way1_bank3)  // output wire [31 : 0] doutb
    );
    Data_RAM data_ram_way1_bank4 (
        .clka(clk_g),    // input wire clka
        .ena(dena14),      // input wire ena
        .wea(dwea),      // input wire [3 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(write_data4),    // input wire [31 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rdata_way1_bank4)  // output wire [31 : 0] doutb
    );
    Data_RAM data_ram_way1_bank5 (
        .clka(clk_g),    // input wire clka
        .ena(dena15),      // input wire ena
        .wea(dwea),      // input wire [3 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(write_data5),    // input wire [31 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rdata_way1_bank5)  // output wire [31 : 0] doutb
    );
    Data_RAM data_ram_way1_bank6 (
        .clka(clk_g),    // input wire clka
        .ena(dena16),      // input wire ena
        .wea(dwea),      // input wire [3 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(write_data6),    // input wire [31 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rdata_way1_bank6)  // output wire [31 : 0] doutb
    );
    Data_RAM data_ram_way1_bank7 (
        .clka(clk_g),    // input wire clka
        .ena(dena17),      // input wire ena
        .wea(dwea),      // input wire [3 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(write_data7),    // input wire [31 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rdata_way1_bank7)  // output wire [31 : 0] doutb
    );
    Tagv_RAM tagv_ram_way0 (
        .clka(clk_g),    // input wire clka
        .ena(ena0),      // input wire ena
        .wea(wea),      // input wire [0 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(wtagv),    // input wire [20 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rtagv_way0)  // output wire [20 : 0] doutb
    );
    Tagv_RAM tagv_ram_way1 (
        .clka(clk_g),    // input wire clka
        .ena(ena1),      // input wire ena
        .wea(wea),      // input wire [0 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(wtagv),    // input wire [20 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(index),  // input wire [3 : 0] addrb
        .doutb(rtagv_way1)  // output wire [20 : 0] doutb
    );
    
    
    // Register
    always@(posedge clk_g) begin
      if(resetn == `RstEnable) begin
        buffer_op0     <= #DLY 1'b0 ;
        buffer_LB      <= #DLY 1'b0 ;
        buffer_index0  <= #DLY 7'b0 ;
        buffer_tag0    <= #DLY 20'b0;
        buffer_offset0 <= #DLY 5'b0 ;
        buffer_op1     <= #DLY 1'b0 ;
        buffer_index1  <= #DLY 7'b0 ;
        buffer_tag1    <= #DLY 20'b0;
        buffer_offset1 <= #DLY 5'b0 ;
      //end else if(next_mstate[1] || current_mstate[0]) begin 
      end else if(current_mstate[1] || current_mstate[0] || D_UnCache) begin 
      // 包含两种情况，主状�?�机处于MIDLE状�?�以及主状�?�机处于LOOKUP状�?�且下一周期的主状�?�机仍处于LOOKUP状�??
        buffer_op0     <= #DLY op    ;
        buffer_LB      <= #DLY LB_req;
        buffer_index0  <= #DLY index ;
        buffer_tag0    <= #DLY tag   ;
        buffer_offset0 <= #DLY offset;
        buffer_op1     <= #DLY buffer_op0    ;
        buffer_index1  <= #DLY buffer_index0 ;
        buffer_tag1    <= #DLY buffer_tag0   ;
        buffer_offset1 <= #DLY buffer_offset0;
      end else begin
        buffer_op0     <= #DLY buffer_op0    ;
        buffer_LB      <= #DLY buffer_LB     ;
        buffer_index0  <= #DLY buffer_index0 ;
        buffer_tag0    <= #DLY buffer_tag0   ;
        buffer_offset0 <= #DLY buffer_offset0;
        buffer_op1     <= #DLY buffer_op1    ;
        buffer_index1  <= #DLY buffer_index1 ;
        buffer_tag1    <= #DLY buffer_tag1   ;
        buffer_offset1 <= #DLY buffer_offset1;
      end
    end

    
    
    always@(posedge clk_g) begin
      if(resetn == `RstEnable) begin
        buffer_wstrb0  <= #DLY 4'b0;
        buffer_data0   <= #DLY 32'b0;
      end else if(op && (next_mstate[1] || current_mstate[0] || D_UnCache)) begin 
      //end else if(op && (current_mstate[1] || current_mstate[0])) begin 
      // 包含两种情况，主状�?�机处于MIDLE状�?�以及主状�?�机处于LOOKUP状�?�且下一周期的主状�?�机仍处于LOOKUP状�??
        buffer_wstrb0  <= #DLY wstrb ;
        buffer_data0   <= #DLY wdata ;
      end else begin
        buffer_wstrb0  <= #DLY buffer_wstrb0 ;
        buffer_data0   <= #DLY buffer_data0  ;
      end
    end
    // PLRU   
    always@(posedge clk_g) begin
      if(resetn == `RstEnable) begin
        PLRU <= #DLY 255'b0;
      end else if(cache_hit) begin
        PLRU[buffer_index0] <= #DLY way0_hit; // 第一路的命中结果决定哪一路命中，例如way0_hit=1,way1_hit=0，则表示�?0路命�?,PLRU中记录的是最近没有使用的�?
      end else if(rd_finish && current_mstate[4]) begin // 在将缺失的数据写入cache后将新写入的块标记为�?近使用过
        PLRU[buffer_index1] <= #DLY ~PLRU[buffer_index1]; 
      end else begin
        PLRU <= #DLY PLRU;
      end
    end
    
    always@(posedge clk_g) begin
      if(resetn == `RstEnable) begin
        PLRU_buffer <= #DLY 1'b0;
      end else if(current_mstate[0] || current_mstate[1]) begin
        PLRU_buffer <= #DLY PLRU[buffer_index0];
      end else begin
        PLRU_buffer <= #DLY PLRU_buffer;
      end
    end
    
    // Write Buffer
//    always@(posedge clk_g) begin
//      if(resetn == `RstEnable || !buffer_op0) begin
//        Write_Way0  <= #DLY 1'b0;
//        Write_Way1  <= #DLY 1'b0;
//        Write_Index <= #DLY 8'b0;
//        Write_Data  <= #DLY 32'b0;
//        Write_Wstrb <= #DLY 4'b0;
//        Write_Tag   <= #DLY 20'b0;
//        Write_Offset<= #DLY 4'b0;
//      //end else if((next_wstate[1] || current_wstate[0]) && buffer_op0) begin
//      end else if(buffer_op0) begin
//        Write_Way0  <= #DLY way0_hit;
//        Write_Way1  <= #DLY way1_hit;
//        Write_Index <= #DLY buffer_index0;
//        Write_Data  <= #DLY buffer_data0;
//        Write_Wstrb <= #DLY buffer_wstrb0;
//        Write_Tag   <= #DLY buffer_tag0;
//        Write_Offset<= #DLY buffer_offset0;
//      end else begin
//        Write_Way0  <= #DLY Write_Way0  ;
//        Write_Way1  <= #DLY Write_Way1  ;
//        Write_Index <= #DLY Write_Index ;
//        Write_Data  <= #DLY Write_Data  ;
//        Write_Wstrb <= #DLY Write_Wstrb ;
//        Write_Tag   <= #DLY Write_Tag   ;
//        Write_Offset<= #DLY Write_Offset;
//      end
//    end
    
    // Miss Buffer // Icache用不�?
    
    always@(posedge clk_g) begin
      if(resetn == `RstEnable) begin
        miss_data0 <= #DLY 256'b0;
        miss_data1 <= #DLY 236'b0;
        miss_tag0  <= #DLY 20'b0;
        miss_tag1  <= #DLY 20'b0;
      end else if(current_mstate[1])begin//可能会有问题
        miss_data0 <= #DLY {rdata_way0_bank7,rdata_way0_bank6,rdata_way0_bank5,rdata_way0_bank4,rdata_way0_bank3,rdata_way0_bank2,rdata_way0_bank1,rdata_way0_bank0};
        miss_data1 <= #DLY {rdata_way1_bank7,rdata_way1_bank6,rdata_way1_bank5,rdata_way1_bank4,rdata_way1_bank3,rdata_way1_bank2,rdata_way1_bank1,rdata_way1_bank0};
        miss_tag0  <= #DLY rtagv_way0[19:0];
        miss_tag1  <= #DLY rtagv_way1[19:0];
      end else begin
        miss_data0 <= #DLY miss_data0;
        miss_data1 <= #DLY miss_data1;
        miss_tag0  <= #DLY miss_tag0;
        miss_tag1  <= #DLY miss_tag1;
      end
    end
    
    
    always@(posedge clk_g) begin
      if(resetn == `RstEnable) begin
        dirty_table[0] <= #DLY 256'b0;
        dirty_table[1] <= #DLY 256'b0;
      end else if(cache_hit && buffer_op0) begin
        dirty_table[way1_hit][buffer_index0] <= #DLY 1'b1;
      end else if(rd_finish && current_mstate[4]) begin
        dirty_table[PLRU_buffer][buffer_index1] <= #DLY buffer_op1;
      end else begin
        dirty_table[0] <= #DLY dirty_table[0];
        dirty_table[1] <= #DLY dirty_table[1]; 
      end
    end
    
    
    // Main State Machine
    always@(posedge clk_g) begin
      if(resetn == `RstEnable) begin
        current_mstate <= #DLY MIDLE;
      end else if(op && D_UnCache) begin
        current_mstate <= #DLY UNWRITE;
      end else if(!op && D_UnCache) begin
        current_mstate <= #DLY UNREAD;
      end else begin
        current_mstate <= #DLY next_mstate;
      end
    end
    
    always@(*) begin
      case(current_mstate)
        MIDLE : begin
          if(valid)
            next_mstate <= #DLY LOOKUP;
          else
            next_mstate <= #DLY MIDLE;
        end
        LOOKUP : begin
          if(cache_hit) begin
            if(valid) begin
              next_mstate <= #DLY LOOKUP;
            end else begin
              next_mstate <= #DLY MIDLE;
            end
          end else
            next_mstate <= #DLY MISS;
        end
        MISS : begin
          if(dirty_table[PLRU_buffer][buffer_index1])
            next_mstate <= #DLY REPLACE;
          else 
            next_mstate <= #DLY REFILL;
        end
        REPLACE : begin
          if(wr_finish)
            next_mstate <= #DLY REFILL;
          else
            next_mstate <= #DLY REPLACE;
        end
        REFILL : begin
          if(!rd_finish)
            next_mstate <= #DLY REFILL;
          else
            next_mstate <= #DLY MIDLE;
        end
        UNREAD : begin
          if(!rd_finish)
            next_mstate <= #DLY UNREAD;
          else
            next_mstate <= #DLY MIDLE;
        end
        UNWRITE : begin
          if(!wr_finish)
            next_mstate <= #DLY UNWRITE;
          else
            next_mstate <= #DLY MIDLE;
        end
        default : begin
          next_mstate <= #DLY MIDLE;
        end
      endcase
    end
    
    // Write State Machine
//    always@(posedge clk_g) begin
//      if(resetn == `RstEnable) begin
//        current_wstate <= #DLY WIDLE;
//      end else begin
//        current_wstate <= #DLY next_wstate;
//      end
//    end
    
//    always@(*) begin
//      case(current_wstate)
//        WIDLE : begin
//          if(cache_hit && buffer_op0) begin
//            next_wstate <= #DLY WRITE;
//          end else begin
//            next_wstate <= #DLY WIDLE;
//          end
//        end
//        WRITE : begin
//          if(cache_hit && buffer_op0) begin
//            next_wstate <= #DLY WRITE;
//          end else begin
//            next_wstate <= #DLY WIDLE;
//          end
//        end
//        default : begin
//          next_wstate <= #DLY WIDLE;
//        end
//      endcase
//    end

    assign way0_hit  = (current_mstate[1]) ? (rtagv_way0[19:0] == buffer_tag0 && rtagv_way0[20]) : `HitFail;
    assign way1_hit  = (current_mstate[1]) ? (rtagv_way1[19:0] == buffer_tag0 && rtagv_way1[20]) : `HitFail;
    assign cache_hit = way0_hit || way1_hit;
    
    
    // Hit Write 读写地址冲突 // 该处的buffer应该用哪�?个尚不清�?  
    always@(posedge clk_g) begin
      if(resetn == `RstEnable) begin
        miss_rd_finish <= #DLY 1'b0;
        rddata_buffer  <= #DLY 32'b0;
        buffer_hit_write <= #DLY 1'b0;
        way0_data_buffer <= #DLY 32'h00000000;
        way1_data_buffer <= #DLY 32'h00000000;
      end else begin
        miss_rd_finish <= #DLY rd_finish;
        
        rddata_buffer  <= current_mstate[5]               ? rd_data[31:0]    :
                          (buffer_offset1[4:2] == 3'b000) ? rd_data[31:0]    :
                          (buffer_offset1[4:2] == 3'b001) ? rd_data[63:32]   :
                          (buffer_offset1[4:2] == 3'b010) ? rd_data[95:64]   :
                          (buffer_offset1[4:2] == 3'b011) ? rd_data[127:96]  :
                          (buffer_offset1[4:2] == 3'b100) ? rd_data[159:128] :
                          (buffer_offset1[4:2] == 3'b101) ? rd_data[191:160] :
                          (buffer_offset1[4:2] == 3'b110) ? rd_data[223:192] :
                          (buffer_offset1[4:2] == 3'b111) ? rd_data[255:224] :
                          32'b0;
        buffer_hit_write <= #DLY (current_mstate[1] && buffer_op0 && !op && (buffer_index0 == index) && (buffer_offset0 == offset));//改了这里
        way0_data_buffer <= #DLY (buffer_data0 & wsel_expand0) | (way0_data & (~wsel_expand0));
        way1_data_buffer <= #DLY (buffer_data0 & wsel_expand0) | (way1_data & (~wsel_expand0));
      end
    end
    
    assign wsel_expand0 = {{8{buffer_wstrb0[3]}} , {8{buffer_wstrb0[2]}} , {8{buffer_wstrb0[1]}} , {8{buffer_wstrb0[0]}}};
//    assign wsel_expand1 = {{8{Write_Wstrb[3]}} , {8{Write_Wstrb[2]}} , {8{Write_Wstrb[1]}} , {8{Write_Wstrb[0]}}};
    
    // READ
    
    // Rdata Bufferrd_add
    
    assign enb = 1'b1 ;

    assign way0_data = buffer_offset0[4:2] == 3'b000 ? rdata_way0_bank0 :
                       buffer_offset0[4:2] == 3'b001 ? rdata_way0_bank1 :
                       buffer_offset0[4:2] == 3'b010 ? rdata_way0_bank2 :
                       buffer_offset0[4:2] == 3'b011 ? rdata_way0_bank3 :
                       buffer_offset0[4:2] == 3'b100 ? rdata_way0_bank4 :
                       buffer_offset0[4:2] == 3'b101 ? rdata_way0_bank5 :
                       buffer_offset0[4:2] == 3'b110 ? rdata_way0_bank6 :
                       buffer_offset0[4:2] == 3'b111 ? rdata_way0_bank7 :
                       32'b0;
    assign way1_data = buffer_offset0[4:2] == 3'b000 ? rdata_way1_bank0 :
                       buffer_offset0[4:2] == 3'b001 ? rdata_way1_bank1 :
                       buffer_offset0[4:2] == 3'b010 ? rdata_way1_bank2 :
                       buffer_offset0[4:2] == 3'b011 ? rdata_way1_bank3 :
                       buffer_offset0[4:2] == 3'b100 ? rdata_way1_bank4 :
                       buffer_offset0[4:2] == 3'b101 ? rdata_way1_bank5 :
                       buffer_offset0[4:2] == 3'b110 ? rdata_way1_bank6 :
                       buffer_offset0[4:2] == 3'b111 ? rdata_way1_bank7 :
                       32'b0;
    assign rdata = //miss_rd_finish ? rd_data[31:0] :
                   //miss_rd_finish && (!buffer_op1) ? rddata_buffer :
                   miss_rd_finish ? rddata_buffer :
                   buffer_hit_write && way0_hit && (buffer_tag0 == buffer_tag1) ? way0_data_buffer :
                   buffer_hit_write && way1_hit && (buffer_tag0 == buffer_tag1) ? way1_data_buffer :
                   way0_hit ? way0_data :
                   way1_hit ? way1_data :
                   32'b0;
    
    // WRITE
    assign dena00 = (rd_finish && (!PLRU_buffer) && current_mstate[4]) || (buffer_op0 && way0_hit && buffer_offset0[4:2] == 3'b000);
    assign dena01 = (rd_finish && (!PLRU_buffer) && current_mstate[4]) || (buffer_op0 && way0_hit && buffer_offset0[4:2] == 3'b001);
    assign dena02 = (rd_finish && (!PLRU_buffer) && current_mstate[4]) || (buffer_op0 && way0_hit && buffer_offset0[4:2] == 3'b010);
    assign dena03 = (rd_finish && (!PLRU_buffer) && current_mstate[4]) || (buffer_op0 && way0_hit && buffer_offset0[4:2] == 3'b011);
    assign dena04 = (rd_finish && (!PLRU_buffer) && current_mstate[4]) || (buffer_op0 && way0_hit && buffer_offset0[4:2] == 3'b100);
    assign dena05 = (rd_finish && (!PLRU_buffer) && current_mstate[4]) || (buffer_op0 && way0_hit && buffer_offset0[4:2] == 3'b101);
    assign dena06 = (rd_finish && (!PLRU_buffer) && current_mstate[4]) || (buffer_op0 && way0_hit && buffer_offset0[4:2] == 3'b110);
    assign dena07 = (rd_finish && (!PLRU_buffer) && current_mstate[4]) || (buffer_op0 && way0_hit && buffer_offset0[4:2] == 3'b111);
    assign dena10 = (rd_finish && PLRU_buffer    && current_mstate[4]) || (buffer_op0 && way1_hit && buffer_offset0[4:2] == 3'b000);
    assign dena11 = (rd_finish && PLRU_buffer    && current_mstate[4]) || (buffer_op0 && way1_hit && buffer_offset0[4:2] == 3'b001);
    assign dena12 = (rd_finish && PLRU_buffer    && current_mstate[4]) || (buffer_op0 && way1_hit && buffer_offset0[4:2] == 3'b010);
    assign dena13 = (rd_finish && PLRU_buffer    && current_mstate[4]) || (buffer_op0 && way1_hit && buffer_offset0[4:2] == 3'b011);
    assign dena14 = (rd_finish && PLRU_buffer    && current_mstate[4]) || (buffer_op0 && way1_hit && buffer_offset0[4:2] == 3'b100);
    assign dena15 = (rd_finish && PLRU_buffer    && current_mstate[4]) || (buffer_op0 && way1_hit && buffer_offset0[4:2] == 3'b101);
    assign dena16 = (rd_finish && PLRU_buffer    && current_mstate[4]) || (buffer_op0 && way1_hit && buffer_offset0[4:2] == 3'b110);
    assign dena17 = (rd_finish && PLRU_buffer    && current_mstate[4]) || (buffer_op0 && way1_hit && buffer_offset0[4:2] == 3'b111);
                     
    assign ena0   = (rd_finish && (!PLRU_buffer) && current_mstate[4]);
    assign ena1   = (rd_finish && PLRU_buffer    && current_mstate[4]);
    
    assign write_data0 =  (rd_finish && buffer_op1 && (buffer_offset1[4:2] == 3'b000)) ? (buffer_data0 & wsel_expand0) | (rd_data[31:0]    & (~wsel_expand0)): rd_finish ? rd_data[31:0]   :(cache_hit && buffer_op0) ? buffer_data0 : 32'b0;
    assign write_data1 =  (rd_finish && buffer_op1 && (buffer_offset1[4:2] == 3'b001)) ? (buffer_data0 & wsel_expand0) | (rd_data[63:32]   & (~wsel_expand0)): rd_finish ? rd_data[63:32]  :(cache_hit && buffer_op0) ? buffer_data0 : 32'b0;
    assign write_data2 =  (rd_finish && buffer_op1 && (buffer_offset1[4:2] == 3'b010)) ? (buffer_data0 & wsel_expand0) | (rd_data[95:64]   & (~wsel_expand0)): rd_finish ? rd_data[95:64]  :(cache_hit && buffer_op0) ? buffer_data0 : 32'b0;
    assign write_data3 =  (rd_finish && buffer_op1 && (buffer_offset1[4:2] == 3'b011)) ? (buffer_data0 & wsel_expand0) | (rd_data[127:96]  & (~wsel_expand0)): rd_finish ? rd_data[127:96] :(cache_hit && buffer_op0) ? buffer_data0 : 32'b0;
    assign write_data4 =  (rd_finish && buffer_op1 && (buffer_offset1[4:2] == 3'b100)) ? (buffer_data0 & wsel_expand0) | (rd_data[159:128] & (~wsel_expand0)): rd_finish ? rd_data[159:128]:(cache_hit && buffer_op0) ? buffer_data0 : 32'b0;
    assign write_data5 =  (rd_finish && buffer_op1 && (buffer_offset1[4:2] == 3'b101)) ? (buffer_data0 & wsel_expand0) | (rd_data[191:160] & (~wsel_expand0)): rd_finish ? rd_data[191:160]:(cache_hit && buffer_op0) ? buffer_data0 : 32'b0;
    assign write_data6 =  (rd_finish && buffer_op1 && (buffer_offset1[4:2] == 3'b110)) ? (buffer_data0 & wsel_expand0) | (rd_data[223:192] & (~wsel_expand0)): rd_finish ? rd_data[223:192]:(cache_hit && buffer_op0) ? buffer_data0 : 32'b0;
    assign write_data7 =  (rd_finish && buffer_op1 && (buffer_offset1[4:2] == 3'b111)) ? (buffer_data0 & wsel_expand0) | (rd_data[255:224] & (~wsel_expand0)): rd_finish ? rd_data[255:224]:(cache_hit && buffer_op0) ? buffer_data0 : 32'b0;
    
    assign wtagv = rd_finish ? {1'b1,buffer_tag1} : 21'b0;
    assign waddr = rd_finish ? buffer_index1 :
                   (cache_hit && buffer_op0) ? buffer_index0 : 7'b0;
    assign dwea = rd_finish ? 4'b1111 :
                  (cache_hit && buffer_op0) ? buffer_wstrb0 : 4'b0;
    assign wea  = rd_finish;
    
    // Signal to CPU

    
    assign addr_ok = (current_mstate[1] && !cache_hit)|| current_mstate[2] || current_mstate[3] || current_mstate[4] || current_mstate[5] || current_mstate[6] ;
    assign data_ok = cache_hit|| miss_rd_finish ;
    assign wr_addr  = //D_UnCache    ? {tag,index,offset} :
                      current_mstate[6] ? {buffer_tag0,buffer_index0,buffer_offset0[4:2],2'b00} :
                      !PLRU_buffer ? {miss_tag0,buffer_index1,5'b0} : 
                      PLRU_buffer  ? {miss_tag1,buffer_index1,5'b0} :
                      32'b0;
    assign wr_data  = //D_UnCache ? {wdata,96'b0} :
                      current_mstate[6] ? {buffer_data0,224'b0} :
                      !PLRU_buffer ? miss_data0 : 
                      PLRU_buffer  ? miss_data1 :
                      128'b0;
    assign wr_req   = (current_mstate[2] && dirty_table[PLRU_buffer][buffer_index1]) || 
                      (current_mstate[3] && ~wr_finish) ||
                      //(valid && D_UnCache && op);
                      (current_mstate[6] && ~wr_finish);
    assign wr_wstrb = current_mstate[2] || (current_mstate[3] && ~wr_finish) ? 4'b1111 : buffer_wstrb0;
    assign wr_type  = current_mstate[2] || (current_mstate[3] && ~wr_finish) ? 3'b100 : 3'b010; 
    assign rd_addr  = //D_UnCache         ? {tag,index,offset} :
                      current_mstate[4] ? {buffer_tag1,buffer_index1,5'b0} :
                      current_mstate[5] ? {buffer_tag0,buffer_index0,buffer_offset0} :
                      32'b0;
    assign LB_flag  = //D_UnCache || current_mstate[5] ? buffer_LB : 1'b0;
                      current_mstate[5] ? buffer_LB : 1'b0;
    assign rd_req   = //(current_mstate[4] && (~rd_finish)) || (valid && D_UnCache && !op) ||(current_mstate[5] && (~rd_finish));
                      (current_mstate[4] && (~rd_finish)) || (current_mstate[5] && (~rd_finish));
    assign rd_type  = current_mstate[4] ? 3'b100 : 3'b010; 
endmodule