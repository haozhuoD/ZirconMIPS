`define TLBNUM  16
`define TLBIDX_NUM 3:0
// #
//(
//    localparam TLBNUM = 16
//)
module tlb
(
    input clk,
//    input rst,
    
    //s0 seach port
    input [18:0] s0_vpn2,
    input        s0_odd_page,
    input [7:0] s0_asid,
    
    output [19:0] s0_pfn,
  //  output s0_G,
    output s0_v,
    output s0_d,
    output [2:0]s0_c,
    output s0_found,
    output [$clog2(`TLBNUM)-1 :0]s0_index,

    //s1 seach port
    input [18:0] s1_vpn2,
    input           s1_odd_page,
    input [7:0] s1_asid,
    
    output [19:0] s1_pfn,
 //   output s1_G,
    output s1_v,
    output s1_d,
    output [2:0]s1_c,
    output s1_found,//是否产生refill，
    output [$clog2(`TLBNUM)-1 :0]s1_index,

    //write port
    input we,
    input [$clog2(`TLBNUM)-1 :0] w_index,
    input [18:0] w_vpn2,
    input [7:0] w_asid,
    input w_g,
    input [19:0]w_pfn0,
    input [2:0] w_c0,
    input w_d0,
    input w_v0,
    input [19:0]w_pfn1,
    input [2:0]w_c1,
    input w_d1,
    input w_v1,

    //read port
    input [$clog2(`TLBNUM)-1 :0] r_index,
    output [18:0] r_vpn2,
    output [7:0] r_asid,
    output r_g,
    output [19:0]r_pfn0,
    output [2:0]r_c0,
    output r_d0,
    output r_v0,
    output [19:0]r_pfn1,
    output [2:0]r_c1,
    output r_d1,
    output r_v1

);


reg [18:0]  tlb_vpn2    [`TLBNUM-1:0];
reg [7:0]   tlb_asid    [`TLBNUM-1:0];
reg         tlb_g       [`TLBNUM-1:0];
reg [19:0]  tlb_pfn0    [`TLBNUM-1:0];
reg [2:0]   tlb_c0      [`TLBNUM-1:0];
reg         tlb_d0      [`TLBNUM-1:0];
reg         tlb_v0      [`TLBNUM-1:0];
reg [19:0]  tlb_pfn1    [`TLBNUM-1:0];
reg [2:0]   tlb_c1      [`TLBNUM-1:0];
reg         tlb_d1      [`TLBNUM-1:0];
reg         tlb_v1      [`TLBNUM-1:0];

integer j = 0;
initial begin     
        for(j = 0; j < `TLBNUM; j = j + 1)begin 
            tlb_vpn2[j] <= 0;
            tlb_asid[j] <= 0;
            tlb_g[j] <= 0;
            tlb_pfn0[j] <= 0;
            tlb_c0[j] <= 0;
            tlb_d0[j] <= 0;
            tlb_v0[j] <= 0;
            tlb_pfn1[j] <= 0;
            tlb_c1[j] <= 0;
            tlb_d1[j] <= 0;
            tlb_v1[j] <= 0;    
        end
end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire   [`TLBNUM-1:0]  match0     ;     //s0
wire   [`TLBNUM-1:0] match1     ;     //s1

assign match0[0] = {s0_vpn2==tlb_vpn2[0]} && ( (s0_asid == tlb_asid[0]) || tlb_g[0] );
assign match0[1] = {s0_vpn2==tlb_vpn2[1]} && ( (s0_asid == tlb_asid[1]) || tlb_g[1] );
assign match0[2] = {s0_vpn2==tlb_vpn2[2]} && ( (s0_asid == tlb_asid[2]) || tlb_g[2] );
assign match0[3] = {s0_vpn2==tlb_vpn2[3]} && ( (s0_asid == tlb_asid[3]) || tlb_g[3] );
assign match0[4] = {s0_vpn2==tlb_vpn2[4]} && ( (s0_asid == tlb_asid[4]) || tlb_g[4] );
assign match0[5] = {s0_vpn2==tlb_vpn2[5]} && ( (s0_asid == tlb_asid[5]) || tlb_g[5] );
assign match0[6] = {s0_vpn2==tlb_vpn2[6]} && ( (s0_asid == tlb_asid[6]) || tlb_g[6] );
assign match0[7] = {s0_vpn2==tlb_vpn2[7]} && ( (s0_asid == tlb_asid[7]) || tlb_g[7] );
assign match0[8] = {s0_vpn2==tlb_vpn2[8]} && ( (s0_asid == tlb_asid[8]) || tlb_g[8] );
assign match0[9] = {s0_vpn2==tlb_vpn2[9]} && ( (s0_asid == tlb_asid[9]) || tlb_g[9] );
assign match0[10] = {s0_vpn2==tlb_vpn2[10]} && ( (s0_asid == tlb_asid[10]) || tlb_g[10] );
assign match0[11] = {s0_vpn2==tlb_vpn2[11]} && ( (s0_asid == tlb_asid[11]) || tlb_g[11] );
assign match0[12] = {s0_vpn2==tlb_vpn2[12]} && ( (s0_asid == tlb_asid[12]) || tlb_g[12] );
assign match0[13] = {s0_vpn2==tlb_vpn2[13]} && ( (s0_asid == tlb_asid[13]) || tlb_g[13] );
assign match0[14] = {s0_vpn2==tlb_vpn2[14]} && ( (s0_asid == tlb_asid[14]) || tlb_g[14] );
assign match0[15] = {s0_vpn2==tlb_vpn2[15]} && ( (s0_asid == tlb_asid[15]) || tlb_g[15] );
/*
assign match0[16] = {s0_vpn2==tlb_vpn2[16]} && ( (s0_asid == tlb_asid[16]) || tlb_g[16] );
assign match0[17] = {s0_vpn2==tlb_vpn2[17]} && ( (s0_asid == tlb_asid[17]) || tlb_g[17] );
assign match0[18] = {s0_vpn2==tlb_vpn2[18]} && ( (s0_asid == tlb_asid[18]) || tlb_g[18] );
assign match0[19] = {s0_vpn2==tlb_vpn2[19]} && ( (s0_asid == tlb_asid[19]) || tlb_g[19] );
assign match0[20] = {s0_vpn2==tlb_vpn2[20]} && ( (s0_asid == tlb_asid[20]) || tlb_g[20] );
assign match0[21] = {s0_vpn2==tlb_vpn2[21]} && ( (s0_asid == tlb_asid[21]) || tlb_g[21] );
assign match0[22] = {s0_vpn2==tlb_vpn2[22]} && ( (s0_asid == tlb_asid[22]) || tlb_g[22] );
assign match0[23] = {s0_vpn2==tlb_vpn2[23]} && ( (s0_asid == tlb_asid[23]) || tlb_g[23] );
assign match0[24] = {s0_vpn2==tlb_vpn2[24]} && ( (s0_asid == tlb_asid[24]) || tlb_g[24] );
assign match0[25] = {s0_vpn2==tlb_vpn2[25]} && ( (s0_asid == tlb_asid[25]) || tlb_g[25] );
assign match0[26] = {s0_vpn2==tlb_vpn2[26]} && ( (s0_asid == tlb_asid[26]) || tlb_g[26] );
assign match0[27] = {s0_vpn2==tlb_vpn2[27]} && ( (s0_asid == tlb_asid[27]) || tlb_g[27] );
assign match0[28] = {s0_vpn2==tlb_vpn2[28]} && ( (s0_asid == tlb_asid[28]) || tlb_g[28] );
assign match0[29] = {s0_vpn2==tlb_vpn2[29]} && ( (s0_asid == tlb_asid[29]) || tlb_g[29] );
assign match0[30] = {s0_vpn2==tlb_vpn2[30]} && ( (s0_asid == tlb_asid[30]) || tlb_g[30] );
assign match0[31] = {s0_vpn2==tlb_vpn2[31]} && ( (s0_asid == tlb_asid[31]) || tlb_g[31] );
*/

assign match1[0] = {s1_vpn2==tlb_vpn2[0]} && ( (s1_asid == tlb_asid[0]) || tlb_g[0] );
assign match1[1] = {s1_vpn2==tlb_vpn2[1]} && ( (s1_asid == tlb_asid[1]) || tlb_g[1] );
assign match1[2] = {s1_vpn2==tlb_vpn2[2]} && ( (s1_asid == tlb_asid[2]) || tlb_g[2] );
assign match1[3] = {s1_vpn2==tlb_vpn2[3]} && ( (s1_asid == tlb_asid[3]) || tlb_g[3] );
assign match1[4] = {s1_vpn2==tlb_vpn2[4]} && ( (s1_asid == tlb_asid[4]) || tlb_g[4] );
assign match1[5] = {s1_vpn2==tlb_vpn2[5]} && ( (s1_asid == tlb_asid[5]) || tlb_g[5] );
assign match1[6] = {s1_vpn2==tlb_vpn2[6]} && ( (s1_asid == tlb_asid[6]) || tlb_g[6] );
assign match1[7] = {s1_vpn2==tlb_vpn2[7]} && ( (s1_asid == tlb_asid[7]) || tlb_g[7] );
assign match1[8] = {s1_vpn2==tlb_vpn2[8]} && ( (s1_asid == tlb_asid[8]) || tlb_g[8] );
assign match1[9] = {s1_vpn2==tlb_vpn2[9]} && ( (s1_asid == tlb_asid[9]) || tlb_g[9] );
assign match1[10] = {s1_vpn2==tlb_vpn2[10]} && ( (s1_asid == tlb_asid[10]) || tlb_g[10] );
assign match1[11] = {s1_vpn2==tlb_vpn2[11]} && ( (s1_asid == tlb_asid[11]) || tlb_g[11] );
assign match1[12] = {s1_vpn2==tlb_vpn2[12]} && ( (s1_asid == tlb_asid[12]) || tlb_g[12] );
assign match1[13] = {s1_vpn2==tlb_vpn2[13]} && ( (s1_asid == tlb_asid[13]) || tlb_g[13] );
assign match1[14] = {s1_vpn2==tlb_vpn2[14]} && ( (s1_asid == tlb_asid[14]) || tlb_g[14] );
assign match1[15] = {s1_vpn2==tlb_vpn2[15]} && ( (s1_asid == tlb_asid[15]) || tlb_g[15] );
/*
assign match1[16] = {s1_vpn2==tlb_vpn2[16]} && ( (s1_asid == tlb_asid[16]) || tlb_g[16] );
assign match1[17] = {s1_vpn2==tlb_vpn2[17]} && ( (s1_asid == tlb_asid[17]) || tlb_g[17] );
assign match1[18] = {s1_vpn2==tlb_vpn2[18]} && ( (s1_asid == tlb_asid[18]) || tlb_g[18] );
assign match1[19] = {s1_vpn2==tlb_vpn2[19]} && ( (s1_asid == tlb_asid[19]) || tlb_g[19] );
assign match1[20] = {s1_vpn2==tlb_vpn2[20]} && ( (s1_asid == tlb_asid[20]) || tlb_g[20] );
assign match1[21] = {s1_vpn2==tlb_vpn2[21]} && ( (s1_asid == tlb_asid[21]) || tlb_g[21] );
assign match1[22] = {s1_vpn2==tlb_vpn2[22]} && ( (s1_asid == tlb_asid[22]) || tlb_g[22] );
assign match1[23] = {s1_vpn2==tlb_vpn2[23]} && ( (s1_asid == tlb_asid[23]) || tlb_g[23] );
assign match1[24] = {s1_vpn2==tlb_vpn2[24]} && ( (s1_asid == tlb_asid[24]) || tlb_g[24] );
assign match1[25] = {s1_vpn2==tlb_vpn2[25]} && ( (s1_asid == tlb_asid[25]) || tlb_g[25] );
assign match1[26] = {s1_vpn2==tlb_vpn2[26]} && ( (s1_asid == tlb_asid[26]) || tlb_g[26] );
assign match1[27] = {s1_vpn2==tlb_vpn2[27]} && ( (s1_asid == tlb_asid[27]) || tlb_g[27] );
assign match1[28] = {s1_vpn2==tlb_vpn2[28]} && ( (s1_asid == tlb_asid[28]) || tlb_g[28] );
assign match1[29] = {s1_vpn2==tlb_vpn2[29]} && ( (s1_asid == tlb_asid[29]) || tlb_g[29] );
assign match1[30] = {s1_vpn2==tlb_vpn2[30]} && ( (s1_asid == tlb_asid[30]) || tlb_g[30] );
assign match1[31] = {s1_vpn2==tlb_vpn2[31]} && ( (s1_asid == tlb_asid[31]) || tlb_g[31] );
*/

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire [50:0]s0_tlb2;
//assign s0_pfn = (~s0_odd_page) ? s0_tlb2[49:30] : s0_tlb2[24:5] ;
assign s0_pfn =(  {20{~s0_odd_page}} & s0_tlb2[49:30]   )
               | ({20{ s0_odd_page}} & s0_tlb2[24:5]    ) ;  

assign s0_g =   (~s0_tlb2[50]) ;
assign s0_v =   (~s0_odd_page) ? s0_tlb2[25] : s0_tlb2[0] ;   
assign s0_d =   (~s0_odd_page) ? s0_tlb2[26] : s0_tlb2[1];
assign s0_c =   (~s0_odd_page) ? s0_tlb2[29:27] : s0_tlb2[4:2];
assign s0_found = (|match0) ? 1 : 0 ;
assign s0_index = (     {4'h0 }  &   {4{match0[0]}}      )
                    |(  {4'h1 }  &   {4{match0[1]}}      )
                    |(  {4'h2 }  &   {4{match0[2]}}      )
                    |(  {4'h3 }  &   {4{match0[3]}}      )
                    |(  {4'h4 }  &   {4{match0[4]}}      )
                    |(  {4'h5 }  &   {4{match0[5]}}      )
                    |(  {4'h6 }  &   {4{match0[6]}}      )
                    |(  {4'h7 }  &   {4{match0[7]}}      )
                    |(  {4'h8 }  &   {4{match0[8]}}      )
                    |(  {4'h9 }  &   {4{match0[9]}}      )
                    |(  {4'ha }  &   {4{match0[10]}}     )
                    |(  {4'hb }  &   {4{match0[11]}}     )
                    |(  {4'hc }  &   {4{match0[12]}}     )
                    |(  {4'hd }  &   {4{match0[13]}}     )
                    |(  {4'he }  &   {4{match0[14]}}     )
                    |(  {4'hf }  &   {4{match0[15]}}     );
                    /*
                    |( 16 & match0[16])
                    |( 17 & match0[17])
                    |( 18 & match0[18])
                    |( 19 & match0[19])
                    |( 20 & match0[20])
                    |( 21 & match0[21])
                    |( 22 & match0[22])
                    |( 23 & match0[23])
                    |( 24 & match0[24])
                    |( 25 & match0[25])
                    |( 26 & match0[26])
                    |( 27 & match0[27])
                    |( 28 & match0[28])
                    |( 29 & match0[29])
                    |( 30 & match0[30])
                    |( 31 & match0[31]);
                    */


assign s0_tlb2 =  ( {tlb_g[0],tlb_pfn0[0],tlb_c0[0],tlb_d0[0],tlb_v0[0],   tlb_pfn1[0],tlb_c1[0],tlb_d1[0],tlb_v1[0]} & {51{match0[0]}} )
                |   ( {tlb_g[1],tlb_pfn0[1],tlb_c0[1],tlb_d0[1],tlb_v0[1],   tlb_pfn1[1],tlb_c1[1],tlb_d1[1],tlb_v1[1]} & {51{match0[1]}} )
                |   ( {tlb_g[2],tlb_pfn0[2],tlb_c0[2],tlb_d0[2],tlb_v0[2],   tlb_pfn1[2],tlb_c1[2],tlb_d1[2],tlb_v1[2]}  & {51{match0[2]}} )
                |   ( {tlb_g[3],tlb_pfn0[3],tlb_c0[3],tlb_d0[3],tlb_v0[3],   tlb_pfn1[3],tlb_c1[3],tlb_d1[3],tlb_v1[3]}  & {51{match0[3]}} )
                |   ( {tlb_g[4],tlb_pfn0[4],tlb_c0[4],tlb_d0[4],tlb_v0[4],   tlb_pfn1[4],tlb_c1[4],tlb_d1[4],tlb_v1[4]}  & {51{match0[4]}} )
                |   ( {tlb_g[5],tlb_pfn0[5],tlb_c0[5],tlb_d0[5],tlb_v0[5],   tlb_pfn1[5],tlb_c1[5],tlb_d1[5],tlb_v1[5]}  & {51{match0[5]}} )
                |   ( {tlb_g[6],tlb_pfn0[6],tlb_c0[6],tlb_d0[6],tlb_v0[6],   tlb_pfn1[6],tlb_c1[6],tlb_d1[6],tlb_v1[6]}  & {51{match0[6]}} )
                |   ( {tlb_g[7],tlb_pfn0[7],tlb_c0[7],tlb_d0[7],tlb_v0[7],   tlb_pfn1[7],tlb_c1[7],tlb_d1[7],tlb_v1[7]}  & {51{match0[7]}} )
                |   ( {tlb_g[8],tlb_pfn0[8],tlb_c0[8],tlb_d0[8],tlb_v0[8],   tlb_pfn1[8],tlb_c1[8],tlb_d1[8],tlb_v1[8]}  & {51{match0[8]}} )
                |   ( {tlb_g[9],tlb_pfn0[9],tlb_c0[9],tlb_d0[9],tlb_v0[9],   tlb_pfn1[9],tlb_c1[9],tlb_d1[9],tlb_v1[9]}  & {51{match0[9]}} )
                |   ( {tlb_g[10],tlb_pfn0[10],tlb_c0[10],tlb_d0[10],tlb_v0[10],  tlb_pfn1[10],tlb_c1[10],tlb_d1[10],tlb_v1[10]}  & {51{match0[10]}} )
                |   ( {tlb_g[11],tlb_pfn0[11],tlb_c0[11],tlb_d0[11],tlb_v0[11],  tlb_pfn1[11],tlb_c1[11],tlb_d1[11],tlb_v1[11]}  & {51{match0[11]}} )
                |   ( {tlb_g[12],tlb_pfn0[12],tlb_c0[12],tlb_d0[12],tlb_v0[12],  tlb_pfn1[12],tlb_c1[12],tlb_d1[12],tlb_v1[12]}  & {51{match0[12]}} )
                |   ( {tlb_g[13],tlb_pfn0[13],tlb_c0[13],tlb_d0[13],tlb_v0[13],  tlb_pfn1[13],tlb_c1[13],tlb_d1[13],tlb_v1[13]}  & {51{match0[13]}} )
                |   ( {tlb_g[14],tlb_pfn0[14],tlb_c0[14],tlb_d0[14],tlb_v0[14],  tlb_pfn1[14],tlb_c1[14],tlb_d1[14],tlb_v1[14]}  & {51{match0[14]}} )
                |   ( {tlb_g[15],tlb_pfn0[15],tlb_c0[15],tlb_d0[15],tlb_v0[15],  tlb_pfn1[15],tlb_c1[15],tlb_d1[15],tlb_v1[15]}  & {51{match0[15]}} );
                /*
                |   ( {tlb_g[16],tlb_pfn0[16],tlb_c0[16],tlb_d0[16],tlb_v0[16],  tlb_pfn1[16],tlb_c1[16],tlb_d1[16],tlb_v1[16]}  & match0[16] )
                |   ( {tlb_g[17],tlb_pfn0[17],tlb_c0[17],tlb_d0[17],tlb_v0[17],  tlb_pfn1[17],tlb_c1[17],tlb_d1[17],tlb_v1[17]}  & match0[17] )
                |   ( {tlb_g[18],tlb_pfn0[18],tlb_c0[18],tlb_d0[18],tlb_v0[18],  tlb_pfn1[18],tlb_c1[18],tlb_d1[18],tlb_v1[18]}  & match0[18] )
                |   ( {tlb_g[19],tlb_pfn0[19],tlb_c0[19],tlb_d0[19],tlb_v0[19],  tlb_pfn1[19],tlb_c1[19],tlb_d1[19],tlb_v1[19]}  & match0[19] )
                |   ( {tlb_g[20],tlb_pfn0[20],tlb_c0[20],tlb_d0[20],tlb_v0[20],  tlb_pfn1[20],tlb_c1[20],tlb_d1[20],tlb_v1[20]}  & match0[20] )
                |   ( {tlb_g[21],tlb_pfn0[21],tlb_c0[21],tlb_d0[21],tlb_v0[21],  tlb_pfn1[21],tlb_c1[21],tlb_d1[21],tlb_v1[21]}  & match0[21] )
                |   ( {tlb_g[22],tlb_pfn0[22],tlb_c0[22],tlb_d0[22],tlb_v0[22],  tlb_pfn1[22],tlb_c1[22],tlb_d1[22],tlb_v1[22]}  & match0[22] )
                |   ( {tlb_g[23],tlb_pfn0[23],tlb_c0[23],tlb_d0[23],tlb_v0[23],  tlb_pfn1[23],tlb_c1[23],tlb_d1[23],tlb_v1[23]}  & match0[23] )
                |   ( {tlb_g[24],tlb_pfn0[24],tlb_c0[24],tlb_d0[24],tlb_v0[24],  tlb_pfn1[24],tlb_c1[24],tlb_d1[24],tlb_v1[24]}  & match0[24] )
                |   ( {tlb_g[25],tlb_pfn0[25],tlb_c0[25],tlb_d0[25],tlb_v0[25],  tlb_pfn1[25],tlb_c1[25],tlb_d1[25],tlb_v1[25]}  & match0[25] )
                |   ( {tlb_g[26],tlb_pfn0[26],tlb_c0[26],tlb_d0[26],tlb_v0[26],  tlb_pfn1[26],tlb_c1[26],tlb_d1[26],tlb_v1[26]}  & match0[26] )
                |   ( {tlb_g[27],tlb_pfn0[27],tlb_c0[27],tlb_d0[27],tlb_v0[27],  tlb_pfn1[27],tlb_c1[27],tlb_d1[27],tlb_v1[27]}  & match0[27] )
                |   ( {tlb_g[28],tlb_pfn0[28],tlb_c0[28],tlb_d0[28],tlb_v0[28],  tlb_pfn1[28],tlb_c1[28],tlb_d1[28],tlb_v1[28]}  & match0[28] )
                |   ( {tlb_g[29],tlb_pfn0[29],tlb_c0[29],tlb_d0[29],tlb_v0[29],  tlb_pfn1[29],tlb_c1[29],tlb_d1[29],tlb_v1[29]}  & match0[29] )
                |   ( {tlb_g[30],tlb_pfn0[30],tlb_c0[30],tlb_d0[30],tlb_v0[30],  tlb_pfn1[30],tlb_c1[30],tlb_d1[30],tlb_v1[30]}  & match0[30] )
                |   ( {tlb_g[31],tlb_pfn0[31],tlb_c0[31],tlb_d0[31],tlb_v0[31],  tlb_pfn1[31],tlb_c1[31],tlb_d1[31],tlb_v1[31]}  & match0[31] ) ;
                */

wire [50:0]s1_tlb2;
//assign s1_pfn = (~s1_odd_page) ? s1_tlb2[49:30] : s1_tlb2[24:5] ;
assign s1_pfn =(  {20{~s1_odd_page}} & s1_tlb2[49:30]   )
               | ({20{ s1_odd_page}} & s1_tlb2[24:5]    ) ;        
                
assign s1_g = ~s1_tlb2[50] ;
assign s1_v = (~s1_odd_page) ? s1_tlb2[25] : s1_tlb2[0] ;   
assign s1_d = (~s1_odd_page) ? s1_tlb2[26] : s1_tlb2[1];
assign s1_c = (~s1_odd_page) ? s1_tlb2[29:27] : s1_tlb2[4:2];
assign s1_found = (|match1) ? 1 : 0 ;


assign s1_tlb2 =  ( {tlb_g[0],tlb_pfn0[0],tlb_c0[0],tlb_d0[0],tlb_v0[0],   tlb_pfn1[0],tlb_c1[0],tlb_d1[0],tlb_v1[0]}    & {51{match1[0]}} )
                |   ( {tlb_g[1],tlb_pfn0[1],tlb_c0[1],tlb_d0[1],tlb_v0[1],   tlb_pfn1[1],tlb_c1[1],tlb_d1[1],tlb_v1[1]}  & {51{match1[1]}} )
                |   ( {tlb_g[2],tlb_pfn0[2],tlb_c0[2],tlb_d0[2],tlb_v0[2],   tlb_pfn1[2],tlb_c1[2],tlb_d1[2],tlb_v1[2]}  & {51{match1[2]}} )
                |   ( {tlb_g[3],tlb_pfn0[3],tlb_c0[3],tlb_d0[3],tlb_v0[3],   tlb_pfn1[3],tlb_c1[3],tlb_d1[3],tlb_v1[3]}  & {51{match1[3]}} )
                |   ( {tlb_g[4],tlb_pfn0[4],tlb_c0[4],tlb_d0[4],tlb_v0[4],   tlb_pfn1[4],tlb_c1[4],tlb_d1[4],tlb_v1[4]}  & {51{match1[4]}} )
                |   ( {tlb_g[5],tlb_pfn0[5],tlb_c0[5],tlb_d0[5],tlb_v0[5],   tlb_pfn1[5],tlb_c1[5],tlb_d1[5],tlb_v1[5]}  & {51{match1[5]}} )
                |   ( {tlb_g[6],tlb_pfn0[6],tlb_c0[6],tlb_d0[6],tlb_v0[6],   tlb_pfn1[6],tlb_c1[6],tlb_d1[6],tlb_v1[6]}  & {51{match1[6]}} )
                |   ( {tlb_g[7],tlb_pfn0[7],tlb_c0[7],tlb_d0[7],tlb_v0[7],   tlb_pfn1[7],tlb_c1[7],tlb_d1[7],tlb_v1[7]}  & {51{match1[7]}} )
                |   ( {tlb_g[8],tlb_pfn0[8],tlb_c0[8],tlb_d0[8],tlb_v0[8],   tlb_pfn1[8],tlb_c1[8],tlb_d1[8],tlb_v1[8]}  & {51{match1[8]}} )
                |   ( {tlb_g[9],tlb_pfn0[9],tlb_c0[9],tlb_d0[9],tlb_v0[9],   tlb_pfn1[9],tlb_c1[9],tlb_d1[9],tlb_v1[9]}  & {51{match1[9]}} )
                |   ( {tlb_g[10],tlb_pfn0[10],tlb_c0[10],tlb_d0[10],tlb_v0[10],  tlb_pfn1[10],tlb_c1[10],tlb_d1[10],tlb_v1[10]}  & {51{match1[10]}} )
                |   ( {tlb_g[11],tlb_pfn0[11],tlb_c0[11],tlb_d0[11],tlb_v0[11],  tlb_pfn1[11],tlb_c1[11],tlb_d1[11],tlb_v1[11]}  & {51{match1[11]}} )
                |   ( {tlb_g[12],tlb_pfn0[12],tlb_c0[12],tlb_d0[12],tlb_v0[12],  tlb_pfn1[12],tlb_c1[12],tlb_d1[12],tlb_v1[12]}  & {51{match1[12]}} )
                |   ( {tlb_g[13],tlb_pfn0[13],tlb_c0[13],tlb_d0[13],tlb_v0[13],  tlb_pfn1[13],tlb_c1[13],tlb_d1[13],tlb_v1[13]}  & {51{match1[13]}} )
                |   ( {tlb_g[14],tlb_pfn0[14],tlb_c0[14],tlb_d0[14],tlb_v0[14],  tlb_pfn1[14],tlb_c1[14],tlb_d1[14],tlb_v1[14]}  & {51{match1[14]}} )
                |   ( {tlb_g[15],tlb_pfn0[15],tlb_c0[15],tlb_d0[15],tlb_v0[15],  tlb_pfn1[15],tlb_c1[15],tlb_d1[15],tlb_v1[15]}  & {51{match1[15]}} );
                /*                                                                                                                               }}
                |   ( {tlb_g[16],tlb_pfn0[16],tlb_c0[16],tlb_d0[16],tlb_v0[16],  tlb_pfn1[16],tlb_c1[16],tlb_d1[16],tlb_v1[16]}  & match1[16] )
                |   ( {tlb_g[17],tlb_pfn0[17],tlb_c0[17],tlb_d0[17],tlb_v0[17],  tlb_pfn1[17],tlb_c1[17],tlb_d1[17],tlb_v1[17]}  & match1[17] )
                |   ( {tlb_g[18],tlb_pfn0[18],tlb_c0[18],tlb_d0[18],tlb_v0[18],  tlb_pfn1[18],tlb_c1[18],tlb_d1[18],tlb_v1[18]}  & match1[18] )
                |   ( {tlb_g[19],tlb_pfn0[19],tlb_c0[19],tlb_d0[19],tlb_v0[19],  tlb_pfn1[19],tlb_c1[19],tlb_d1[19],tlb_v1[19]}  & match1[19] )
                |   ( {tlb_g[20],tlb_pfn0[20],tlb_c0[20],tlb_d0[20],tlb_v0[20],  tlb_pfn1[20],tlb_c1[20],tlb_d1[20],tlb_v1[20]}  & match1[20] )
                |   ( {tlb_g[21],tlb_pfn0[21],tlb_c0[21],tlb_d0[21],tlb_v0[21],  tlb_pfn1[21],tlb_c1[21],tlb_d1[21],tlb_v1[21]}  & match1[21] )
                |   ( {tlb_g[22],tlb_pfn0[22],tlb_c0[22],tlb_d0[22],tlb_v0[22],  tlb_pfn1[22],tlb_c1[22],tlb_d1[22],tlb_v1[22]}  & match1[22] )
                |   ( {tlb_g[23],tlb_pfn0[23],tlb_c0[23],tlb_d0[23],tlb_v0[23],  tlb_pfn1[23],tlb_c1[23],tlb_d1[23],tlb_v1[23]}  & match1[23] )
                |   ( {tlb_g[24],tlb_pfn0[24],tlb_c0[24],tlb_d0[24],tlb_v0[24],  tlb_pfn1[24],tlb_c1[24],tlb_d1[24],tlb_v1[24]}  & match1[24] )
                |   ( {tlb_g[25],tlb_pfn0[25],tlb_c0[25],tlb_d0[25],tlb_v0[25],  tlb_pfn1[25],tlb_c1[25],tlb_d1[25],tlb_v1[25]}  & match1[25] )
                |   ( {tlb_g[26],tlb_pfn0[26],tlb_c0[26],tlb_d0[26],tlb_v0[26],  tlb_pfn1[26],tlb_c1[26],tlb_d1[26],tlb_v1[26]}  & match1[26] )
                |   ( {tlb_g[27],tlb_pfn0[27],tlb_c0[27],tlb_d0[27],tlb_v0[27],  tlb_pfn1[27],tlb_c1[27],tlb_d1[27],tlb_v1[27]}  & match1[27] )
                |   ( {tlb_g[28],tlb_pfn0[28],tlb_c0[28],tlb_d0[28],tlb_v0[28],  tlb_pfn1[28],tlb_c1[28],tlb_d1[28],tlb_v1[28]}  & match1[28] )
                |   ( {tlb_g[29],tlb_pfn0[29],tlb_c0[29],tlb_d0[29],tlb_v0[29],  tlb_pfn1[29],tlb_c1[29],tlb_d1[29],tlb_v1[29]}  & match1[29] )
                |   ( {tlb_g[30],tlb_pfn0[30],tlb_c0[30],tlb_d0[30],tlb_v0[30],  tlb_pfn1[30],tlb_c1[30],tlb_d1[30],tlb_v1[30]}  & match1[30] )
                |   ( {tlb_g[31],tlb_pfn0[31],tlb_c0[31],tlb_d0[31],tlb_v0[31],  tlb_pfn1[31],tlb_c1[31],tlb_d1[31],tlb_v1[31]}  & match1[31] ) ;
                */

assign s1_index = (     {4'h0 }  &   {4{match1[0]}}      )
                    |(  {4'h1 }  &   {4{match1[1]}}      )
                    |(  {4'h2 }  &   {4{match1[2]}}      )
                    |(  {4'h3 }  &   {4{match1[3]}}      )
                    |(  {4'h4 }  &   {4{match1[4]}}      )
                    |(  {4'h5 }  &   {4{match1[5]}}      )
                    |(  {4'h6 }  &   {4{match1[6]}}      )
                    |(  {4'h7 }  &   {4{match1[7]}}      )
                    |(  {4'h8 }  &   {4{match1[8]}}      )
                    |(  {4'h9 }  &   {4{match1[9]}}      )
                    |(  {4'ha }  &   {4{match1[10]}}     )
                    |(  {4'hb }  &   {4{match1[11]}}     )
                    |(  {4'hc }  &   {4{match1[12]}}     )
                    |(  {4'hd }  &   {4{match1[13]}}     )
                    |(  {4'he }  &   {4{match1[14]}}     )
                    |(  {4'hf }  &   {4{match1[15]}}     );
                    /*
                    |( 16 & match1[16])
                    |( 17 & match1[17])
                    |( 18 & match1[18])
                    |( 19 & match1[19])
                    |( 20 & match1[20])
                    |( 21 & match1[21])
                    |( 22 & match1[22])
                    |( 23 & match1[23])
                    |( 24 & match1[24])
                    |( 25 & match1[25])
                    |( 26 & match1[26])
                    |( 27 & match1[27])
                    |( 28 & match1[28])
                    |( 29 & match1[29])
                    |( 30 & match1[30])
                    |( 31 & match1[31]);
                    */

/////////////////////////////////////////////////////////////////////////////////////////////////////////
///                 write
///////////////////////////////////////////////////////////////////////////////////////

always @(posedge clk or posedge we) begin
    if(we)begin
        tlb_vpn2[w_index] <= w_vpn2;
        tlb_asid[w_index] <= w_asid;
        tlb_g[w_index] <= w_g;
        tlb_pfn0[w_index] <= w_pfn0;
        tlb_c0[w_index] <= w_c0;
        tlb_d0[w_index] <= w_d0;
        tlb_v0[w_index] <= w_v0;
        tlb_pfn1[w_index] <= w_pfn1;
        tlb_c1[w_index] <= w_c1;
        tlb_d1[w_index] <= w_d1;
        tlb_v1[w_index] <= w_v1;
    end 
end

//////////////////////////////////////////////////////////////////////////////////////////////////
////   read                 ???是否真的存在这样的读写冲突呢？???  
//////////////////////////////////////////////////
assign        r_asid = tlb_asid[r_index];
assign        r_vpn2 = tlb_vpn2[r_index];
assign        r_g = tlb_g[r_index];
assign        r_pfn0 = tlb_pfn0[r_index];
assign        r_c0 = tlb_c0[r_index];
assign        r_d0 = tlb_d0[r_index];
assign        r_v0 = tlb_v0[r_index];
assign        r_pfn1 = tlb_pfn1[r_index];
assign        r_c1 = tlb_c1[r_index];
assign        r_d1 = tlb_d1[r_index];
assign        r_v1 = tlb_v1[r_index];

endmodule