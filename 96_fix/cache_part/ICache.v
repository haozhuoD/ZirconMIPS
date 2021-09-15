`include "defines.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/05 08:27:42
// Design Name: 
// Module Name: ICache
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

module ICache(
     // 
    input  wire              clk_g,
    input  wire              resetn,
    // Cache与CPU流水线的交互接口
    input  wire              flush,
    input  wire              I_UnCache,
    input  wire              pred_dly,
    input  wire              cpu_req,
    input  wire [`IndexBus]  index,
    input  wire [`TagBus]    ptag,
    input  wire [`TagBus]    vtag,
    input  wire [`OffsetBus] offset,
    
    output wire              stallreq,
    output wire              only_delayslot_inst_o,
    output wire              inst0_valid,
    output wire              inst1_valid,
    output wire [`InstBus]   inst0,
    output wire [`InstBus]   inst1,
    output wire [`AddrBus]   inst0_addr,
    output wire [`AddrBus]   inst1_addr,
    
    // Cache与AXI总线接口的交互接�?
    
    output wire              rd_req,
    output wire [`TypeBus]   rd_type,
    output wire [`AddrBus]   rd_addr,
    input  wire              rd_finish,
    input  wire [`LineBus]   rd_data,
    
    // 命中�?
    output wire [`DataBus]   ICache_sum_req,
    output wire [`DataBus]   ICache_sum_hit
    
);
    // 命中�?
    reg [`DataBus]     SUM_HIT;
    reg [`DataBus]     SUM_REQ;
    
    
    parameter DLY = 0;
    
    // Requset Buffer
    reg               buffer_preddly0;
    reg  [`IndexBus]  buffer_index0;
    reg  [`TagBus]    buffer_ptag0;
    reg  [`TagBus]    buffer_vtag0;
    reg  [`OffsetBus] buffer_offset0;
    reg  [`IndexBus]  inst1_index_buffer0;
    reg  [`OffsetBus] inst1_offset_buffer0;
    reg  [`TagBus]    inst1_vtag_buffer0;
    reg  [`TagBus]    inst1_ptag_buffer0;
    
    reg               buffer_preddly1;
    reg  [`IndexBus]  buffer_index1;
    reg  [`TagBus]    buffer_ptag1;
    reg  [`TagBus]    buffer_vtag1;
    reg  [`OffsetBus] buffer_offset1;
    reg  [`IndexBus]  inst1_index_buffer1;
    reg  [`OffsetBus] inst1_offset_buffer1;
    reg  [`TagBus]    inst1_vtag_buffer1;
    reg  [`TagBus]    inst1_ptag_buffer1;
    
    wire [`IndexBus]  buffer_index;
    wire [`TagBus]    buffer_ptag;
    wire [`TagBus]    buffer_vtag;
    wire [`OffsetBus] buffer_offset;
    wire [`IndexBus]  inst1_index_buffer;
    wire [`OffsetBus] inst1_offset_buffer;
    wire [`TagBus]    inst1_vtag_buffer;
    
    reg  [`InstBus]  inst0_buffer;
    
    // FIFO
    reg [127:0] QUEUE [1:0];
    reg         QUEUE_buffer0;
    reg         QUEUE_buffer1;
    
    // Tag Compare
    wire             way0_hit0;
    wire             way1_hit0;
    wire             way2_hit0;
    wire             way3_hit0;
    wire             cache_hit0;
    
    
    wire             way0_hit1;
    wire             way1_hit1;
    wire             way2_hit1;
    wire             way3_hit1;
    wire             cache_hit1;
    
    // Read from Data_ram and Tagv_ram
    wire             enb;
    wire [`IndexBus] addrb;
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
    wire [`DataBus]  rdata_way2_bank0;
    wire [`DataBus]  rdata_way2_bank1;
    wire [`DataBus]  rdata_way2_bank2;
    wire [`DataBus]  rdata_way2_bank3;
    wire [`DataBus]  rdata_way2_bank4;
    wire [`DataBus]  rdata_way2_bank5;
    wire [`DataBus]  rdata_way2_bank6;
    wire [`DataBus]  rdata_way2_bank7;
    wire [`DataBus]  rdata_way3_bank0;
    wire [`DataBus]  rdata_way3_bank1;
    wire [`DataBus]  rdata_way3_bank2;
    wire [`DataBus]  rdata_way3_bank3;
    wire [`DataBus]  rdata_way3_bank4;
    wire [`DataBus]  rdata_way3_bank5;
    wire [`DataBus]  rdata_way3_bank6;
    wire [`DataBus]  rdata_way3_bank7;
    wire [`TagBus]   rtag_way0;
    wire [`TagBus]   rtag_way1;
    wire [`TagBus]   rtag_way2;
    wire [`TagBus]   rtag_way3;
    
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
    wire             dena20;
    wire             dena21;
    wire             dena22;
    wire             dena23;
    wire             dena24;
    wire             dena25;
    wire             dena26;
    wire             dena27;
    wire             dena30;
    wire             dena31;
    wire             dena32;
    wire             dena33;
    wire             dena34;
    wire             dena35;
    wire             dena36;
    wire             dena37;
    wire             ena0;
    wire             ena1;
    wire             ena2;
    wire             ena3;
    wire [`DataBus]  write_data0;
    wire [`DataBus]  write_data1;
    wire [`DataBus]  write_data2;
    wire [`DataBus]  write_data3;
    wire [`DataBus]  write_data4;
    wire [`DataBus]  write_data5;
    wire [`DataBus]  write_data6;
    wire [`DataBus]  write_data7;
    wire [`TagBus]   wtag;
    wire [`IndexBus] waddr;
    wire             dwea;
    wire             wea; // tagv的字节选择信号
    
    // Select Data and Judge Data
    
    wire [`InstBus]  inst0_way0_data;
    wire [`InstBus]  inst0_way1_data;
    wire [`InstBus]  inst0_way2_data;
    wire [`InstBus]  inst0_way3_data;
    wire [`InstBus]  inst0_way4_data;
    wire [`InstBus]  inst0_way5_data;
    wire [`InstBus]  inst0_way6_data;
    wire [`InstBus]  inst0_way7_data;
    wire [`InstBus]  inst1_way0_data;
    wire [`InstBus]  inst1_way1_data;
    wire [`InstBus]  inst1_way2_data;
    wire [`InstBus]  inst1_way3_data;
    wire [`InstBus]  inst1_way4_data;
    wire [`InstBus]  inst1_way5_data;
    wire [`InstBus]  inst1_way6_data;
    wire [`InstBus]  inst1_way7_data;
    wire [`InstBus]  inst0_data;
    wire [`InstBus]  inst1_data;
    
    // Variable of StateMachine
    
    reg [`IMStateBus] current_mstate;
    reg [`IMStateBus] next_mstate;
    localparam MIDLE    = 7'b0000001;
    localparam LOOKUP   = 7'b0000010;
    localparam REFILL   = 7'b0000100;
    localparam SEARCH   = 7'b0001000;
    localparam MISS     = 7'b0010000;
    localparam CONFLICT = 7'b0100000;
    localparam UNCACHE  = 7'b1000000;
    
    // Cache Memory
    Instructions_RAM data_ram_way0_bank0 (.clka(clk_g),.ena(dena00),.wea(dwea),.addra(waddr),.dina(write_data0),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way0_bank0));
    Instructions_RAM data_ram_way0_bank1 (.clka(clk_g),.ena(dena01),.wea(dwea),.addra(waddr),.dina(write_data1),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way0_bank1));
    Instructions_RAM data_ram_way0_bank2 (.clka(clk_g),.ena(dena02),.wea(dwea),.addra(waddr),.dina(write_data2),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way0_bank2));
    Instructions_RAM data_ram_way0_bank3 (.clka(clk_g),.ena(dena03),.wea(dwea),.addra(waddr),.dina(write_data3),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way0_bank3));
    Instructions_RAM data_ram_way0_bank4 (.clka(clk_g),.ena(dena04),.wea(dwea),.addra(waddr),.dina(write_data4),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way0_bank4));
    Instructions_RAM data_ram_way0_bank5 (.clka(clk_g),.ena(dena05),.wea(dwea),.addra(waddr),.dina(write_data5),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way0_bank5));
    Instructions_RAM data_ram_way0_bank6 (.clka(clk_g),.ena(dena06),.wea(dwea),.addra(waddr),.dina(write_data6),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way0_bank6));
    Instructions_RAM data_ram_way0_bank7 (.clka(clk_g),.ena(dena07),.wea(dwea),.addra(waddr),.dina(write_data7),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way0_bank7));
    
    Instructions_RAM data_ram_way1_bank0 (.clka(clk_g),.ena(dena10),.wea(dwea),.addra(waddr),.dina(write_data0),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way1_bank0));
    Instructions_RAM data_ram_way1_bank1 (.clka(clk_g),.ena(dena11),.wea(dwea),.addra(waddr),.dina(write_data1),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way1_bank1));
    Instructions_RAM data_ram_way1_bank2 (.clka(clk_g),.ena(dena12),.wea(dwea),.addra(waddr),.dina(write_data2),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way1_bank2));
    Instructions_RAM data_ram_way1_bank3 (.clka(clk_g),.ena(dena13),.wea(dwea),.addra(waddr),.dina(write_data3),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way1_bank3));
    Instructions_RAM data_ram_way1_bank4 (.clka(clk_g),.ena(dena14),.wea(dwea),.addra(waddr),.dina(write_data4),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way1_bank4));
    Instructions_RAM data_ram_way1_bank5 (.clka(clk_g),.ena(dena15),.wea(dwea),.addra(waddr),.dina(write_data5),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way1_bank5));
    Instructions_RAM data_ram_way1_bank6 (.clka(clk_g),.ena(dena16),.wea(dwea),.addra(waddr),.dina(write_data6),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way1_bank6));
    Instructions_RAM data_ram_way1_bank7 (.clka(clk_g),.ena(dena17),.wea(dwea),.addra(waddr),.dina(write_data7),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way1_bank7));
    
    Instructions_RAM data_ram_way2_bank0 (.clka(clk_g),.ena(dena20),.wea(dwea),.addra(waddr),.dina(write_data0),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way2_bank0));
    Instructions_RAM data_ram_way2_bank1 (.clka(clk_g),.ena(dena21),.wea(dwea),.addra(waddr),.dina(write_data1),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way2_bank1));
    Instructions_RAM data_ram_way2_bank2 (.clka(clk_g),.ena(dena22),.wea(dwea),.addra(waddr),.dina(write_data2),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way2_bank2));
    Instructions_RAM data_ram_way2_bank3 (.clka(clk_g),.ena(dena23),.wea(dwea),.addra(waddr),.dina(write_data3),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way2_bank3));
    Instructions_RAM data_ram_way2_bank4 (.clka(clk_g),.ena(dena24),.wea(dwea),.addra(waddr),.dina(write_data4),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way2_bank4));
    Instructions_RAM data_ram_way2_bank5 (.clka(clk_g),.ena(dena25),.wea(dwea),.addra(waddr),.dina(write_data5),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way2_bank5));
    Instructions_RAM data_ram_way2_bank6 (.clka(clk_g),.ena(dena26),.wea(dwea),.addra(waddr),.dina(write_data6),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way2_bank6));
    Instructions_RAM data_ram_way2_bank7 (.clka(clk_g),.ena(dena27),.wea(dwea),.addra(waddr),.dina(write_data7),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way2_bank7));
    
    Instructions_RAM data_ram_way3_bank0 (.clka(clk_g),.ena(dena30),.wea(dwea),.addra(waddr),.dina(write_data0),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way3_bank0));
    Instructions_RAM data_ram_way3_bank1 (.clka(clk_g),.ena(dena31),.wea(dwea),.addra(waddr),.dina(write_data1),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way3_bank1));
    Instructions_RAM data_ram_way3_bank2 (.clka(clk_g),.ena(dena32),.wea(dwea),.addra(waddr),.dina(write_data2),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way3_bank2));
    Instructions_RAM data_ram_way3_bank3 (.clka(clk_g),.ena(dena33),.wea(dwea),.addra(waddr),.dina(write_data3),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way3_bank3));
    Instructions_RAM data_ram_way3_bank4 (.clka(clk_g),.ena(dena34),.wea(dwea),.addra(waddr),.dina(write_data4),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way3_bank4));
    Instructions_RAM data_ram_way3_bank5 (.clka(clk_g),.ena(dena35),.wea(dwea),.addra(waddr),.dina(write_data5),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way3_bank5));
    Instructions_RAM data_ram_way3_bank6 (.clka(clk_g),.ena(dena36),.wea(dwea),.addra(waddr),.dina(write_data6),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way3_bank6));
    Instructions_RAM data_ram_way3_bank7 (.clka(clk_g),.ena(dena37),.wea(dwea),.addra(waddr),.dina(write_data7),.clkb(clk_g),.enb(enb),.addrb(addrb),.doutb(rdata_way3_bank7));
    
    Tag_RAM tag_ram_way0 (
        .clka(clk_g),    // input wire clka
        .ena(ena0),      // input wire ena
        .wea(wea),      // input wire [0 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(wtag),    // input wire [20 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(addrb),  // input wire [3 : 0] addrb
        .doutb(rtag_way0)  // output wire [20 : 0] doutb
    );
    Tag_RAM tag_ram_way1 (
        .clka(clk_g),    // input wire clka
        .ena(ena1),      // input wire ena
        .wea(wea),      // input wire [0 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(wtag),    // input wire [20 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(addrb),  // input wire [3 : 0] addrb
        .doutb(rtag_way1)  // output wire [20 : 0] doutb
    );
    Tag_RAM tag_ram_way2 (
        .clka(clk_g),    // input wire clka
        .ena(ena2),      // input wire ena
        .wea(wea),      // input wire [0 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(wtag),    // input wire [20 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(addrb),  // input wire [3 : 0] addrb
        .doutb(rtag_way2)  // output wire [20 : 0] doutb
    );
    Tag_RAM tag_ram_way3 (
        .clka(clk_g),    // input wire clka
        .ena(ena3),      // input wire ena
        .wea(wea),      // input wire [0 : 0] wea
        .addra(waddr),  // input wire [3 : 0] addra
        .dina(wtag),    // input wire [20 : 0] dina
        .clkb(clk_g),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(addrb),  // input wire [3 : 0] addrb
        .doutb(rtag_way3)  // output wire [20 : 0] doutb
    );
    
    // 命中�?
    always@(posedge clk_g) begin
      if(resetn == `RstEnable) begin
        SUM_REQ  <= 32'b0;
      end else if(cpu_req && !I_UnCache && !stallreq) begin
        SUM_REQ  <= SUM_REQ + 1;
      end else begin
        SUM_REQ  <= SUM_REQ;
      end
    end
    
    always@(posedge clk_g) begin
      if(resetn == `RstEnable) begin
        SUM_HIT  <= 32'b0;
      end else if((cache_hit1 && buffer_offset1[3:2] == 2'b11) || (cache_hit0 && buffer_offset0[3:2] != 2'b11)) begin
        SUM_HIT  <= SUM_HIT + 1;
      end else begin
        SUM_HIT  <= SUM_HIT;
      end
    end
    
    assign ICache_sum_req = SUM_REQ;
    assign ICache_sum_hit = SUM_HIT;
    
    
    // Register
    always@(posedge clk_g) begin
      if(resetn == `RstEnable || flush == `RstEnable) begin
        
        buffer_index0        <= #DLY 7'b0 ;
        buffer_ptag0         <= #DLY 20'b0;
        buffer_vtag0         <= #DLY 20'b0;
        buffer_offset0       <= #DLY 5'b0 ;
        inst1_index_buffer0  <= #DLY 7'b0;
        inst1_offset_buffer0 <= #DLY 5'b0;
        inst1_vtag_buffer0   <= #DLY 20'b0;
        inst1_ptag_buffer0   <= #DLY 20'h0;
        
        buffer_index1        <= #DLY 8'b0 ;
        buffer_ptag1         <= #DLY 20'b0;
        buffer_vtag1         <= #DLY 20'b0;
        buffer_offset1       <= #DLY 4'b0 ;
        inst1_index_buffer1  <= #DLY 8'b0;
        inst1_offset_buffer1 <= #DLY 4'b0;
        inst1_vtag_buffer1   <= #DLY 20'b0;
        inst1_ptag_buffer1   <= #DLY 20'h0;
      end else if(current_mstate[1] || current_mstate[0] || I_UnCache) begin 
      // 包含两种情况，主状�?�机处于MIDLE状�?�以及主状�?�机处于LOOKUP状�?�且下一周期的主状�?�机仍处于LOOKUP状�??
        buffer_preddly0      <= #DLY pred_dly;
        buffer_index0        <= #DLY index ;
        buffer_ptag0         <= #DLY ptag  ;
        buffer_vtag0         <= #DLY vtag  ;
        buffer_offset0       <= #DLY offset;
        inst1_index_buffer0  <= #DLY index+1;
        inst1_offset_buffer0 <= #DLY offset+4;
        inst1_vtag_buffer0   <= #DLY vtag+1;
        inst1_ptag_buffer0   <= #DLY ptag+1;
        
        buffer_preddly1      <= #DLY buffer_preddly0     ;
        buffer_index1        <= #DLY buffer_index0       ;
        buffer_ptag1         <= #DLY buffer_ptag0        ;
        buffer_vtag1         <= #DLY buffer_vtag0        ;
        buffer_offset1       <= #DLY buffer_offset0      ;
        inst1_index_buffer1  <= #DLY inst1_index_buffer0 ;
        inst1_offset_buffer1 <= #DLY inst1_offset_buffer0;
        inst1_vtag_buffer1   <= #DLY inst1_vtag_buffer0;
        inst1_ptag_buffer1   <= #DLY inst1_ptag_buffer0;
      end else begin
        buffer_preddly0      <= #DLY buffer_preddly0;
        buffer_index0        <= #DLY buffer_index0 ;
        buffer_ptag0         <= #DLY buffer_ptag0  ;
        buffer_vtag0         <= #DLY buffer_vtag0  ;
        buffer_offset0       <= #DLY buffer_offset0;
        inst1_index_buffer0  <= #DLY inst1_index_buffer0 ;
        inst1_offset_buffer0 <= #DLY inst1_offset_buffer0;
        inst1_vtag_buffer0   <= #DLY inst1_vtag_buffer0;
        inst1_ptag_buffer0   <= #DLY inst1_ptag_buffer0;
        
        buffer_preddly1      <= #DLY buffer_preddly1     ;
        buffer_index1        <= #DLY buffer_index1       ;
        buffer_ptag1         <= #DLY buffer_ptag1        ;
        buffer_vtag1         <= #DLY buffer_vtag1        ;
        buffer_offset1       <= #DLY buffer_offset1      ;
        inst1_index_buffer1  <= #DLY inst1_index_buffer1 ;
        inst1_offset_buffer1 <= #DLY inst1_offset_buffer1;
        inst1_vtag_buffer1   <= #DLY inst1_vtag_buffer1  ;
        inst1_ptag_buffer1   <= #DLY inst1_ptag_buffer1  ;
      end
    end
    
    assign buffer_index        = (current_mstate[0] || current_mstate[1] || current_mstate[6]) ? buffer_index0        : buffer_index1       ;
    assign buffer_ptag         = (current_mstate[0] || current_mstate[1] || current_mstate[6]) ? buffer_ptag0         : buffer_ptag1        ;
    assign buffer_vtag         = (current_mstate[0] || current_mstate[1] || current_mstate[6]) ? buffer_vtag0         : buffer_vtag1        ;
    assign buffer_offset       = (current_mstate[0] || current_mstate[1] || current_mstate[6]) ? buffer_offset0       : buffer_offset1      ;
    assign inst1_index_buffer  = (current_mstate[0] || current_mstate[1] || current_mstate[6]) ? inst1_index_buffer0  : inst1_index_buffer1 ;
    assign inst1_offset_buffer = (current_mstate[0] || current_mstate[1] || current_mstate[6]) ? inst1_offset_buffer0 : inst1_offset_buffer1;
    assign inst1_vtag_buffer   = (current_mstate[0] || current_mstate[1] || current_mstate[6]) ? inst1_vtag_buffer0   : inst1_vtag_buffer1  ;
    
    // PLRU   
    always@(posedge clk_g) begin
      if(resetn == `RstEnable) begin
        QUEUE[0] <= #DLY 128'b0;
        QUEUE[1] <= #DLY 128'b0;
        QUEUE_buffer0 <= #DLY 1'b0;
        QUEUE_buffer1 <= #DLY 1'b0;
      end else if(current_mstate[1] && !cache_hit0) begin
        QUEUE[0] [buffer_index0] <= #DLY ~QUEUE[0] [buffer_index0];
        QUEUE[1] [buffer_index0] <= #DLY ((QUEUE[0][buffer_index0]) ^ (QUEUE[1] [buffer_index0])); 
        QUEUE_buffer0 <= #DLY QUEUE[0][buffer_index0];
        QUEUE_buffer1 <= #DLY QUEUE[1][buffer_index0];
      end else if(current_mstate[3] && !cache_hit1) begin
        QUEUE[0] [buffer_index1] <= #DLY ~QUEUE[0] [buffer_index1];
        QUEUE[1] [buffer_index1] <= #DLY ((QUEUE[0][buffer_index1]) ^ (QUEUE[1] [buffer_index1])); 
        QUEUE_buffer0 <= #DLY QUEUE[0][buffer_index1];
        QUEUE_buffer1 <= #DLY QUEUE[1][buffer_index1];
      end else begin
        QUEUE[0] <= #DLY QUEUE[0];
        QUEUE[1] <= #DLY QUEUE[1];
        QUEUE_buffer0 <= #DLY QUEUE_buffer0;
        QUEUE_buffer1 <= #DLY QUEUE_buffer1;
      end
    end
    
    // Main State Machine
    always@(posedge clk_g) begin
      if(resetn == `RstEnable) begin
        current_mstate <= #DLY MIDLE;
      end else if(flush == `RstEnable && rd_req) begin
        current_mstate <= #DLY CONFLICT;
      end else if(flush == `RstEnable && !current_mstate[5]) begin
        current_mstate <= #DLY MIDLE;
      end else if(I_UnCache == `RstEnable) begin
        current_mstate <= #DLY UNCACHE;
      end else begin
        current_mstate <= #DLY next_mstate;
      end
    end
    
    always@(*) begin
      case(current_mstate)
        MIDLE : begin
          if(cpu_req)
            next_mstate <= #DLY LOOKUP;
          else
            next_mstate <= #DLY MIDLE;
        end
        LOOKUP : begin
          if(cache_hit0) begin
            if(buffer_offset0[4:2] == 3'b111) begin
              next_mstate <= #DLY SEARCH;
            end else if(cpu_req) begin
              next_mstate <= #DLY LOOKUP;
            end else begin
              next_mstate <= #DLY MIDLE;
            end
          end else
            next_mstate <= #DLY REFILL;
        end
        REFILL : begin
          if(!rd_finish) begin
            next_mstate <= #DLY REFILL;
          end else if(buffer_offset1[4:2] == 3'b111) begin
            next_mstate <= #DLY SEARCH;
          end else begin
            next_mstate <= #DLY MIDLE;
          end
        end
        SEARCH : begin
          if(cache_hit1)
            next_mstate <= #DLY MIDLE;
          else
            next_mstate <= #DLY MISS;
        end
        MISS : begin
          if(!rd_finish) begin
            next_mstate <= #DLY MISS;
          end else begin
            next_mstate <= #DLY MIDLE;
          end
        end
        CONFLICT : begin
          if(rd_finish) begin
            next_mstate <= #DLY MIDLE;
          end else begin
            next_mstate <= #DLY CONFLICT;
          end
        end
        UNCACHE : begin
          if(rd_finish) begin
            next_mstate <= #DLY MIDLE;
          end else begin
            next_mstate <= #DLY UNCACHE;
          end
        end
        default : begin
          next_mstate <= #DLY MIDLE;
        end
      endcase
    end
    
    // Cache_Hit
    
    assign way0_hit0  = current_mstate[1] && rtag_way0[19:0] == buffer_ptag0 ;
    assign way1_hit0  = current_mstate[1] && rtag_way1[19:0] == buffer_ptag0 ;
    assign way2_hit0  = current_mstate[1] && rtag_way2[19:0] == buffer_ptag0 ;
    assign way3_hit0  = current_mstate[1] && rtag_way3[19:0] == buffer_ptag0 ;
    assign cache_hit0 = way0_hit0 || way1_hit0 || way2_hit0 || way3_hit0;
    assign way0_hit1  = (buffer_index1 != 7'b1111111) && current_mstate[3] ? rtag_way0[19:0] == buffer_ptag1 : 
                        (buffer_index1 == 7'b1111111) && current_mstate[3] ? rtag_way0[19:0] == inst1_ptag_buffer1 :`HitFail;
    assign way1_hit1  = (buffer_index1 != 7'b1111111) && current_mstate[3] ? rtag_way1[19:0] == buffer_ptag1 : 
                        (buffer_index1 == 7'b1111111) && current_mstate[3] ? rtag_way1[19:0] == inst1_ptag_buffer1 :`HitFail;
    assign way2_hit1  = (buffer_index1 != 7'b1111111) && current_mstate[3] ? rtag_way2[19:0] == buffer_ptag1 : 
                        (buffer_index1 == 7'b1111111) && current_mstate[3] ? rtag_way2[19:0] == inst1_ptag_buffer1 :`HitFail;
    assign way3_hit1  = (buffer_index1 != 7'b1111111) && current_mstate[3] ? rtag_way3[19:0] == buffer_ptag1 : 
                        (buffer_index1 == 7'b1111111) && current_mstate[3] ? rtag_way3[19:0] == inst1_ptag_buffer1 :`HitFail;
    assign cache_hit1 = way0_hit1 || way1_hit1 || way2_hit1 || way3_hit1;
    
    // READ
    
    // Rdata Bufferrd_addr
    
    assign enb = 1'b1 ;
    assign addrb = (current_mstate[1] && buffer_offset0[4] && buffer_offset0[3] && buffer_offset0[2]) ? inst1_index_buffer0 : 
                   (current_mstate[2] && buffer_offset1[4] && buffer_offset1[3] && buffer_offset1[2]) ? inst1_index_buffer1 :
                   index;
    
    assign inst0_way0_data = buffer_offset[4:2] == 3'b000 ? rdata_way0_bank0 :
                             buffer_offset[4:2] == 3'b001 ? rdata_way0_bank1 :
                             buffer_offset[4:2] == 3'b010 ? rdata_way0_bank2 :
                             buffer_offset[4:2] == 3'b011 ? rdata_way0_bank3 :
                             buffer_offset[4:2] == 3'b100 ? rdata_way0_bank4 :
                             buffer_offset[4:2] == 3'b101 ? rdata_way0_bank5 :
                             buffer_offset[4:2] == 3'b110 ? rdata_way0_bank6 :
                             buffer_offset[4:2] == 3'b111 ? rdata_way0_bank7 :
                             32'b0;
    assign inst0_way1_data = buffer_offset[4:2] == 3'b000 ? rdata_way1_bank0 :
                             buffer_offset[4:2] == 3'b001 ? rdata_way1_bank1 :
                             buffer_offset[4:2] == 3'b010 ? rdata_way1_bank2 :
                             buffer_offset[4:2] == 3'b011 ? rdata_way1_bank3 :
                             buffer_offset[4:2] == 3'b100 ? rdata_way1_bank4 :
                             buffer_offset[4:2] == 3'b101 ? rdata_way1_bank5 :
                             buffer_offset[4:2] == 3'b110 ? rdata_way1_bank6 :
                             buffer_offset[4:2] == 3'b111 ? rdata_way1_bank7 :
                             32'b0;
    assign inst0_way2_data = buffer_offset[4:2] == 3'b000 ? rdata_way2_bank0 :
                             buffer_offset[4:2] == 3'b001 ? rdata_way2_bank1 :
                             buffer_offset[4:2] == 3'b010 ? rdata_way2_bank2 :
                             buffer_offset[4:2] == 3'b011 ? rdata_way2_bank3 :
                             buffer_offset[4:2] == 3'b100 ? rdata_way2_bank4 :
                             buffer_offset[4:2] == 3'b101 ? rdata_way2_bank5 :
                             buffer_offset[4:2] == 3'b110 ? rdata_way2_bank6 :
                             buffer_offset[4:2] == 3'b111 ? rdata_way2_bank7 :
                             32'b0;
    assign inst0_way3_data = buffer_offset[4:2] == 3'b000 ? rdata_way3_bank0 :
                             buffer_offset[4:2] == 3'b001 ? rdata_way3_bank1 :
                             buffer_offset[4:2] == 3'b010 ? rdata_way3_bank2 :
                             buffer_offset[4:2] == 3'b011 ? rdata_way3_bank3 :
                             buffer_offset[4:2] == 3'b100 ? rdata_way3_bank4 :
                             buffer_offset[4:2] == 3'b101 ? rdata_way3_bank5 :
                             buffer_offset[4:2] == 3'b110 ? rdata_way3_bank6 :
                             buffer_offset[4:2] == 3'b111 ? rdata_way3_bank7 :
                             32'b0;
    assign inst1_way0_data = (buffer_offset[4:2] == 3'b111 && current_mstate[3]) ? rdata_way0_bank0 :
                             buffer_offset[4:2] == 3'b000 ? rdata_way0_bank1 :
                             buffer_offset[4:2] == 3'b001 ? rdata_way0_bank2 :
                             buffer_offset[4:2] == 3'b010 ? rdata_way0_bank3 :
                             buffer_offset[4:2] == 3'b011 ? rdata_way0_bank4 :
                             buffer_offset[4:2] == 3'b100 ? rdata_way0_bank5 :
                             buffer_offset[4:2] == 3'b101 ? rdata_way0_bank6 :
                             buffer_offset[4:2] == 3'b110 ? rdata_way0_bank7 :
                             32'b0;
    assign inst1_way1_data = (buffer_offset[4:2] == 3'b111 && current_mstate[3]) ? rdata_way1_bank0 :
                             buffer_offset[4:2] == 3'b000 ? rdata_way1_bank1 :
                             buffer_offset[4:2] == 3'b001 ? rdata_way1_bank2 :
                             buffer_offset[4:2] == 3'b010 ? rdata_way1_bank3 :
                             buffer_offset[4:2] == 3'b011 ? rdata_way1_bank4 :
                             buffer_offset[4:2] == 3'b100 ? rdata_way1_bank5 :
                             buffer_offset[4:2] == 3'b101 ? rdata_way1_bank6 :
                             buffer_offset[4:2] == 3'b110 ? rdata_way1_bank7 :
                             32'b0;
    assign inst1_way2_data = (buffer_offset[4:2] == 3'b111 && current_mstate[3]) ? rdata_way2_bank0 :
                             buffer_offset[4:2] == 3'b000 ? rdata_way2_bank1 :
                             buffer_offset[4:2] == 3'b001 ? rdata_way2_bank2 :
                             buffer_offset[4:2] == 3'b010 ? rdata_way2_bank3 :
                             buffer_offset[4:2] == 3'b011 ? rdata_way2_bank4 :
                             buffer_offset[4:2] == 3'b100 ? rdata_way2_bank5 :
                             buffer_offset[4:2] == 3'b101 ? rdata_way2_bank6 :
                             buffer_offset[4:2] == 3'b110 ? rdata_way2_bank7 :
                             32'b0;
    assign inst1_way3_data = (buffer_offset[4:2] == 3'b111 && current_mstate[3]) ? rdata_way3_bank0 :
                             buffer_offset[4:2] == 3'b000 ? rdata_way3_bank1 :
                             buffer_offset[4:2] == 3'b001 ? rdata_way3_bank2 :
                             buffer_offset[4:2] == 3'b010 ? rdata_way3_bank3 :
                             buffer_offset[4:2] == 3'b011 ? rdata_way3_bank4 :
                             buffer_offset[4:2] == 3'b100 ? rdata_way3_bank5 :
                             buffer_offset[4:2] == 3'b101 ? rdata_way3_bank6 :
                             buffer_offset[4:2] == 3'b110 ? rdata_way3_bank7 :
                             32'b0;
    // UNCache改了这里
    assign inst0_data = current_mstate[6]              ? rd_data[31:0]    :
                        (buffer_offset[4:2] == 3'b000) ? rd_data[31:0]    :
                        (buffer_offset[4:2] == 3'b001) ? rd_data[63:32]   :
                        (buffer_offset[4:2] == 3'b010) ? rd_data[95:64]   :
                        (buffer_offset[4:2] == 3'b011) ? rd_data[127:96]  :
                        (buffer_offset[4:2] == 3'b100) ? rd_data[159:128] :
                        (buffer_offset[4:2] == 3'b101) ? rd_data[191:160] :
                        (buffer_offset[4:2] == 3'b110) ? rd_data[223:192] :
                        (buffer_offset[4:2] == 3'b111) ? rd_data[255:224] :
                        32'b0;
    assign inst1_data = current_mstate[6]              ? rd_data[63:32]   :
                        (buffer_offset[4:2] == 3'b000) ? rd_data[63:32]   :
                        (buffer_offset[4:2] == 3'b001) ? rd_data[95:64]   :
                        (buffer_offset[4:2] == 3'b010) ? rd_data[127:96]  :
                        (buffer_offset[4:2] == 3'b011) ? rd_data[159:128] :
                        (buffer_offset[4:2] == 3'b100) ? rd_data[191:160] :
                        (buffer_offset[4:2] == 3'b101) ? rd_data[223:192] :
                        (buffer_offset[4:2] == 3'b110) ? rd_data[255:224] :
                        (buffer_offset[4:2] == 3'b111) ? rd_data[31:0]    :
                        32'b0;
    
    
    // WRITE
    assign dena00 = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) && (~QUEUE_buffer0));
    assign dena01 = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) && (~QUEUE_buffer0));
    assign dena02 = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) && (~QUEUE_buffer0));
    assign dena03 = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) && (~QUEUE_buffer0));
    assign dena04 = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) && (~QUEUE_buffer0));
    assign dena05 = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) && (~QUEUE_buffer0));
    assign dena06 = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) && (~QUEUE_buffer0));
    assign dena07 = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) && (~QUEUE_buffer0));
                                                                                             
    assign dena10 = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) &&   QUEUE_buffer0) ;
    assign dena11 = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) &&   QUEUE_buffer0) ;
    assign dena12 = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) &&   QUEUE_buffer0) ;
    assign dena13 = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) &&   QUEUE_buffer0) ;
    assign dena14 = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) &&   QUEUE_buffer0) ;
    assign dena15 = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) &&   QUEUE_buffer0) ;
    assign dena16 = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) &&   QUEUE_buffer0) ;
    assign dena17 = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) &&   QUEUE_buffer0) ;
                                                                                               
    assign dena20 = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   && (~QUEUE_buffer0));                        
    assign dena21 = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   && (~QUEUE_buffer0));                          
    assign dena22 = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   && (~QUEUE_buffer0));                          
    assign dena23 = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   && (~QUEUE_buffer0));
    assign dena24 = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   && (~QUEUE_buffer0));                        
    assign dena25 = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   && (~QUEUE_buffer0));                          
    assign dena26 = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   && (~QUEUE_buffer0));                          
    assign dena27 = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   && (~QUEUE_buffer0));
                                                                                             
    assign dena30 = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   &&  QUEUE_buffer0) ;                           
    assign dena31 = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   &&  QUEUE_buffer0) ;                           
    assign dena32 = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   &&  QUEUE_buffer0) ;                           
    assign dena33 = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   &&  QUEUE_buffer0) ;
    assign dena34 = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   &&  QUEUE_buffer0) ;                           
    assign dena35 = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   &&  QUEUE_buffer0) ;                           
    assign dena36 = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   &&  QUEUE_buffer0) ;                           
    assign dena37 = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   &&  QUEUE_buffer0) ;
                                                      
    assign ena0   = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) && (~QUEUE_buffer0));
    assign ena1   = (rd_finish && (current_mstate[2] || current_mstate[4]) && (~QUEUE_buffer1) &&  QUEUE_buffer0)  ;
    assign ena2   = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   && (~QUEUE_buffer0));
    assign ena3   = (rd_finish && (current_mstate[2] || current_mstate[4]) &&  QUEUE_buffer1   &&  QUEUE_buffer0)  ;
    
    assign write_data0 =  rd_finish ? rd_data[31:0]    : 32'b0;
    assign write_data1 =  rd_finish ? rd_data[63:32]   : 32'b0;
    assign write_data2 =  rd_finish ? rd_data[95:64]   : 32'b0;                  
    assign write_data3 =  rd_finish ? rd_data[127:96]  : 32'b0;
    assign write_data4 =  rd_finish ? rd_data[159:128] : 32'b0;
    assign write_data5 =  rd_finish ? rd_data[191:160] : 32'b0;
    assign write_data6 =  rd_finish ? rd_data[223:192] : 32'b0;                  
    assign write_data7 =  rd_finish ? rd_data[255:224] : 32'b0;
    
    assign wtag  = (current_mstate[4] && buffer_index == 7'b1111111) ? inst1_ptag_buffer1 :
                   rd_finish  ? buffer_ptag : 21'b0;

    assign waddr = (rd_finish && current_mstate[2]) ? buffer_index : 
                   (rd_finish && current_mstate[4]) ? inst1_index_buffer : 7'b0;
    assign dwea = rd_finish ? 1'b1 : 1'b0;
    assign wea  = rd_finish;
    
    // Signal to CPU
    
    always@(posedge clk_g) begin
      if(resetn == `RstEnable || flush == `RstEnable) begin
        inst0_buffer <= 32'b0;
      end else if(cache_hit0) begin
        inst0_buffer <= way0_hit0 ? inst0_way0_data :
                        way1_hit0 ? inst0_way1_data :
                        way2_hit0 ? inst0_way2_data :
                        way3_hit0 ? inst0_way3_data : 
                        32'b0;
      end else if(current_mstate[2] && rd_finish) begin
        inst0_buffer <= inst0_data;
      end else begin
        inst0_buffer <= inst0_buffer;
      end
    end
    
    assign inst0 = current_mstate[4] && rd_finish  ? inst0_buffer :
                   current_mstate[3] && cache_hit1 ? inst0_buffer :
                   rd_finish && !current_mstate[5] ? inst0_data :
                   (way0_hit0 || way0_hit1) ? inst0_way0_data :
                   (way1_hit0 || way1_hit1) ? inst0_way1_data :
                   (way2_hit0 || way2_hit1) ? inst0_way2_data :
                   (way3_hit0 || way3_hit1) ? inst0_way3_data : 
                   32'b0;
    assign inst1 = rd_finish && !current_mstate[5] ? inst1_data :
                   (way0_hit0 || way0_hit1) ? inst1_way0_data :
                   (way1_hit0 || way1_hit1) ? inst1_way1_data :
                   (way2_hit0 || way2_hit1) ? inst1_way2_data :
                   (way3_hit0 || way3_hit1) ? inst1_way3_data :
                   32'b0;           
    assign inst0_valid = (buffer_offset[4:2]  != 3'b111) && (cache_hit0 || (current_mstate[2] && rd_finish) || 
                         (current_mstate[6] && rd_finish));
    assign inst1_valid = (buffer_offset[4:2] == 3'b111)  && (cache_hit1 || (current_mstate[4] && rd_finish) ||
                         (current_mstate[6] && rd_finish));
    assign inst0_addr  = {buffer_vtag,buffer_index,buffer_offset};
    assign inst1_addr  = (buffer_offset[4:2] == 3'b111 && inst1_index_buffer == 7'b0) ? {inst1_vtag_buffer,inst1_index_buffer,5'b0000} :
                         (buffer_offset[4:2] == 3'b111) ? {buffer_vtag,inst1_index_buffer,5'b0000} : 
                         {buffer_vtag,buffer_index,inst1_offset_buffer};
    assign stallreq = current_mstate[2] || current_mstate[3] || current_mstate[4] || 
                      current_mstate[5] || current_mstate[6] ||
                      (current_mstate[1] && !cache_hit0) || (current_mstate[1] && buffer_offset0[4] && buffer_offset0[3] && buffer_offset0[2]);
    assign only_delayslot_inst_o = (buffer_preddly0 && (current_mstate[1] || current_mstate[6])) || 
                                   (buffer_preddly1 && (current_mstate[2] || current_mstate[3] || current_mstate[4]));
    // Signal to AXI
    
    assign rd_addr  = (I_UnCache && cpu_req) ? {ptag,index,offset} :
                      (current_mstate[6]) ? {buffer_ptag0,buffer_index0,buffer_offset0} :
                      (current_mstate[1] && !cache_hit0) ? {buffer_ptag0,buffer_index0,5'b0000} :
                      ((current_mstate[3] && !cache_hit1) || current_mstate[4]) && buffer_index1 != 7'b1111111 ? {buffer_ptag1,inst1_index_buffer1,5'b0000} : 
                      ((current_mstate[3] && !cache_hit1) || current_mstate[4]) && buffer_index1 == 7'b1111111 ? {inst1_ptag_buffer1,inst1_index_buffer1,5'b0000} :
                      {buffer_ptag1,buffer_index1,5'b0000};
    assign rd_req   = (I_UnCache && cpu_req) || (current_mstate[1] && (~cache_hit0)) || (current_mstate[3] && (~cache_hit1)) ||
                      ((current_mstate[2] || current_mstate[4] || current_mstate[6]) && (~rd_finish));
    assign rd_type  = ((I_UnCache && cpu_req) || (current_mstate[6] && ~rd_finish)) ? 3'b111 : 3'b100;
endmodule