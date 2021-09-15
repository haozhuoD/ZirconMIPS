`define TLBNUM  16
`define TLBIDX_NUM 3:0

module mmu_V2
(
    input clk,
//    input rst_n,
  //  input [`AsidBus]asid,
    input [31:0] inst_vaddr,
    input [31:0] data_vaddr,
    input kseg0_uncache,     //�ӵ�cp0 config�Ĵ����� K0��   , ֱ��ӳ���ʱ������ 0 �ź�
    
    input data_req,
    

    output inst_found,
    output data_found,
    output inst_d,
    output data_d,
    output inst_v,
    output data_v,
    //to cache
    output [31:0] inst_vaddr_o,  //and to cpu
    output [31:0] data_vaddr_o,  //and to cpu 
//    output [31:0] inst_paddr,
    output reg [19:0] inst_pfn,
    output [11:0]inst_index,
    output reg [19:0] data_pfn,
    output [11:0]data_index,
//    output reg inst_uncache_o ,   /////  0x2 : Uncache  0x3: cache   (�������������鵱��Uncache����)
//    output reg data_uncache_o ,   // Ϊ 1 ��ʾ���� cache
    output inst_uncache_o ,   /////  0x2 : Uncache  0x3: cache   (�������������鵱��Uncache����)
    output data_uncache_o , 


    input [31:0] c0_entryhi,
    input [31:0] c0_index,
    input [31:0] c0_random,
    input [31:0] c0_entrylo0,
    input [31:0] c0_entrylo1,

  //to cpu  
    output [31:0] entryhi,
    output [31:0] entrylo0,
    output [31:0] entrylo1,

   // output [`C0regBus] badVaddr,

     //TLBP
//    input [31:0] entryhi_tlbp,
    input is_tlbp,
    output [31:0] tlbp_index,

    //TLBWI �� TLBWR
    input [1:0]tlbw_choose

   
);
// mapped ?
    wire inst_is_vaddr_unmapped;
    // useg (0xxx) , kseg2(110x) ,kseg3(111x) 
    assign inst_is_vaddr_unmapped = (inst_vaddr[31:30] == 2'b10);

    wire data_is_vaddr_unmapped;
    // useg (0xxx) , kseg2(110x) ,kseg3(111x) 
    assign data_is_vaddr_unmapped = ( data_vaddr[31:30] == 2'b10);


//uncache ?
    //wire inst_uncache;//8,14朱旗把这里、注释掉了，这一部分的判断逻辑交给ICache来做
    // kseg1 (101) , kseg0(100) �� config K0 
//    assign inst_uncache = (inst_vaddr[31:29] == 3'b101) | ((inst_vaddr[31:29] == 3'b100) & kseg0_uncache);
    //assign inst_uncache = (inst_vaddr[31]&(~inst_vaddr[30])&inst_vaddr[29]) /* | (inst_vaddr[31]&(~inst_vaddr[30])&(~inst_vaddr[29]))*/;
    // [31:29] = 101  ([31]&(~[30])&[29])      [31:29] = 100  ([31]&(~[30])&(~[29])) 
    wire data_uncache;
    // kseg1 (101) , kseg0(100) �� config K0 
//    assign data_uncache = (data_vaddr[31:29] == 3'b101) | ((data_vaddr[31:29] == 3'b100) & kseg0_uncache);
    assign data_uncache = (data_vaddr[31]&(~data_vaddr[30])&data_vaddr[29]) /* | (data_vaddr[31]&(~data_vaddr[30])&(~data_vaddr[29]))*/;
    

                // unmapped
                wire [31:0]ummapped_inst_addr;
                assign ummapped_inst_addr = {3'b000,inst_vaddr[28:0]};

                wire [31:0]ummapped_data_addr;
                assign ummapped_data_addr = {3'b000,data_vaddr[28:0]};


//generate if (1) 
//        begin: generate_mmu_with_tlb_code

        //mapped with tlb
                wire [31:0] mapped_inst_addr;
                assign mapped_inst_addr[11:0] = inst_vaddr[11:0];
                wire [31:0] mapped_data_addr;
                assign mapped_data_addr[11:0] = data_vaddr[11:0];

                //TLBWR��I
                wire [2:0]inst_c_tlb;
                wire [2:0]data_c_tlb;

                wire we ;
                assign we = |tlbw_choose ;
                wire [$clog2(`TLBNUM)-1:0] w_index ;
                assign w_index = tlbw_choose[1] ? c0_random[$clog2(`TLBNUM)-1:0] : 
                                tlbw_choose[0] ? c0_index[$clog2(`TLBNUM)-1:0]   : 0 ; 
//                wire w_g;
//                assign entrylo0[0] = w_g;
//                assign entrylo1[0] = w_g;

                //tlbp or mem
                wire [18:0] s2_vpn2;
                assign s2_vpn2 = is_tlbp ? c0_entryhi[31:13] : data_vaddr[31:13] ; 
                
                wire    inst_found0;
                wire    data_found1;
                wire    inst_d0;   
                wire    data_d1;   
                wire    inst_v0;   
                wire    data_v1 ;  
                wire [$clog2(`TLBNUM)-1:0] tlbp_ix; 
                
//                tlb 
//                #(
//                    .TLBNUM (16 )
//                )
                tlb u_tlb(
                    .clk         (clk                           ),
                    //inst
                    .s0_vpn2     (inst_vaddr[31:13]             ),
                    .s0_odd_page (inst_vaddr[12]                ),
                    .s0_asid     (c0_entryhi[7:0]               ),
                    .s0_pfn      (mapped_inst_addr[31:12]       ),
                    .s0_v        (inst_v0                        ),
                    .s0_d        (inst_d0                        ),
                    .s0_c        (inst_c_tlb                    ),
                    .s0_found    (inst_found0                    ),
                    .s0_index    (    ),
                    //data  TLBP
                    .s1_vpn2     (s2_vpn2 /*data_vaddr[31:13] */            ),
                    .s1_odd_page (data_vaddr[12]                ),
                    .s1_asid     (c0_entryhi[7:0]               ),
                    .s1_pfn      (mapped_data_addr[31:12]       ),
                    .s1_v        (data_v1                        ),
                    .s1_d        (data_d1                        ),
                    .s1_c        (data_c_tlb                    ),
                    .s1_found    (data_found1                    ),
                    .s1_index    (tlbp_ix                       ),
                    //TLBWI TLBWR
                    .we          (we                            ),
                    .w_index     (w_index                       ),
                    .w_vpn2      (c0_entryhi[31:13]             ),
                    .w_asid      (c0_entryhi[7:0]               ),
                    .w_g         (c0_entrylo0[0]& c0_entrylo1[0]),
                    .w_pfn0      (c0_entrylo0[25:6]             ),
                    .w_c0        (c0_entrylo0[5:3]              ),
                    .w_d0        (c0_entrylo0[2]                ),
                    .w_v0        (c0_entrylo0[1]                ),
                    .w_pfn1      (c0_entrylo1[25:6]             ),


                    .w_c1        (c0_entrylo1[5:3]              ),
                    .w_d1        (c0_entrylo1[2]                ),
                    .w_v1        (c0_entrylo1[1]                ),
                    //TLBR д��wbʱ��
                    .r_index     (c0_index[$clog2(`TLBNUM)-1:0]  ),
                    .r_vpn2      (entryhi[31:13]                ),
                    .r_asid      (entryhi[7:0]                  ),
                    .r_g         (r_g                           ),
                    .r_pfn0      (entrylo0[25:6]                ),
                    .r_c0        (entrylo0[5:3]                 ),
                    .r_d0        (entrylo0[2]                   ),
                    .r_v0        (entrylo0[1]                   ),
                    .r_pfn1      (entrylo1[25:6]                ),
                    .r_c1        (entrylo1[5:3]                 ),
                    .r_d1        (entrylo1[2]                   ),
                    .r_v1        (entrylo1[1]                   )
                );
                
            //TLBP
            assign tlbp_index[31] = data_found ? 0 : 1 ;
            assign tlbp_index[$clog2(`TLBNUM)-1 :   0               ]   = data_found ? tlbp_ix : 0 ;
            assign tlbp_index[30                :   $clog2(`TLBNUM) ]   =  0  ;
            /////  0x2 : Uncache  0x3: cache   (�������������鵱��Uncache����)
            //to cache
            // wire [2:0] inst_c ;
            // wire [2:0] data_c ;
            // assign inst_c = inst_uncache ? 3'b010 : inst_c_tlb ;
            // assign data_c = data_uncache ? 3'b010 : data_c_tlb ; 

            // assign inst_uncache_o = (inst_c == 3'b010) ? 1 : 0;
            // assign data_uncache_o = (data_c == 3'b010) ? 1 : 0; 
//               reg data_valid_f;
//   always @(posedge clk) begin 
//        data_valid_f <= data_req;
//   end
    
//  ~stallreq_from_dcache && (data_uncache_r || data_uncache_w) ;          
            
            
//            assign inst_uncache_o =  inst_uncache           ? 1     :
//                                    inst_is_vaddr_unmapped  ? 0     :
//                                    (inst_c_tlb==3'b011)    ? 0     : 1 ;
            wire inst_uncache_bf  ; 
            assign inst_uncache_o =   ( (~inst_is_vaddr_unmapped)&(~((~inst_c_tlb[2])&inst_c_tlb[1]&inst_c_tlb[0])) )    ; 
                 //inst_c_tlb!=3'b011    
             wire  data_uncache_bf  ;                   
              assign data_uncache_o =  data_uncache | ( (~data_is_vaddr_unmapped)&(~((~data_c_tlb[2])&data_c_tlb[1]&data_c_tlb[0])) )    ;                        
//            assign data_uncache_o = data_uncache            ? 1     : 
//                                    data_is_vaddr_unmapped  ? 0     :
//                                     (data_c_tlb==3'b011)   ? 0     : 1 ;
            wire [19:0] inst_pfn_bf ;
            assign inst_pfn_bf = inst_is_vaddr_unmapped ? ummapped_inst_addr[31:12] : mapped_inst_addr[31:12]  ;
            assign inst_index = inst_vaddr[11:0];
            
//            assign inst_paddr = inst_is_vaddr_unmapped ? ummapped_inst_addr :mapped_inst_addr  ;
            wire [19:0] data_pfn_bf ;
            assign data_pfn_bf = data_is_vaddr_unmapped ? ummapped_data_addr[31:12] : mapped_data_addr[31:12]  ;
            
            assign data_index = data_vaddr[11:0] ; 
      always@(posedge clk)begin
           data_pfn <=  data_pfn_bf;
           inst_pfn <=  inst_pfn_bf;
//           inst_uncache_o <= inst_uncache_bf;
//           data_uncache_o <= data_uncache_bf;
      end
              
                                              
            assign inst_found = inst_is_vaddr_unmapped ? 1'b1 : inst_found0 ;
            assign data_found = data_is_vaddr_unmapped ? 1'b1 : data_found1 ;
            assign inst_d     = inst_is_vaddr_unmapped ? 1'b1 : inst_d0     ;
            assign data_d     = data_is_vaddr_unmapped ? 1'b1 : data_d1     ;
            assign inst_v     = inst_is_vaddr_unmapped ? 1'b1 : inst_v0     ;
            assign data_v     = data_is_vaddr_unmapped ? 1'b1 : data_v1     ;
 

//        end else begin: generate_mmu_without_tlb_code

//            assign inst_paddr = inst_is_vaddr_unmapped ? ummapped_inst_addr : inst_vaddr ;
//            assign data_paddr = data_is_vaddr_unmapped ? ummapped_data_addr : data_vaddr ;
//            assign inst_uncache_o =  inst_uncache ;
//            assign data_uncache_o =  data_uncache ;
//        end
    
//endgenerate

//�������ַ
assign inst_vaddr_o = inst_vaddr;
assign data_vaddr_o = data_vaddr;

assign entryhi[12:8] = 5'b0;
assign entrylo0[31:26] = 6'b0;
assign entrylo1[31:26] = 6'b0;

assign entrylo0[0] = r_g ;
assign entrylo1[0] = r_g ;

endmodule