`include  "defines.v"  
module mult(
    input wire clk,
    input wire rst,

    input wire signed_mult_i,
    input wire [31:0] opdata1_i,
    input wire [31:0] opdata2_i,
    input wire start_i,
    input wire flush,
    
    output reg[63:0] result_o,
    output reg ready_o
);
    
localparam IDLE = 0,BUSY = 1,END = 2;

reg [1:0]state;
reg [1:0]next_state;
wire [63:0]mulres;
wire [63:0]mulres_u;
reg sign;
reg [1:0]cnt;
reg [31:0]reg1_i;
reg [31:0]reg2_i;


always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always @(*) begin
    if (rst) begin
        next_state = IDLE;
    end else begin
        case (state)
            IDLE:begin
                if (start_i && (~flush)) begin
                    next_state = BUSY;
                end else begin
                    next_state = IDLE;
                end
            end
            BUSY:begin
                if (flush) begin
                    next_state = IDLE;
                end
                else if (cnt[0]) begin
                    // next_state = END;
                    next_state = IDLE/*END*/;
                end else begin
                    next_state = BUSY;
                end
            end
            // END:begin
            //     if ((~start_i) | flush ) begin
            //         next_state = IDLE;
            //     end else begin
            //         next_state = END;
            //     end
            // end
                default: begin
                    next_state = IDLE;
                end
        endcase
    end
end

always @(posedge clk) begin
    if (flush) begin
        result_o <= 0;
        ready_o <= 0;
        cnt <= 0;
        sign <= 0;
        reg1_i <= 0;
        reg2_i <= 0;
    end else begin
        case (state)
            IDLE:begin
                result_o <= 0;
                ready_o <= 0; 
                if (start_i ) begin
                    reg1_i <= opdata1_i;
                    reg2_i <= opdata2_i;
                    sign <= signed_mult_i;
                    cnt <= 0;
                end  
            end
            BUSY:begin
                cnt <= cnt+1;
                ready_o <= 0; 
            // end
            // END:begin
            //     if (sign) begin
            //         result_o <= mulres;
            //     end else begin
            //         result_o <= mulres_u;
            //     end
                if (cnt[0]) begin
                    result_o <= sign ? mulres : mulres_u ;
                ready_o <= 1;
               end
            end
            default: ;

            
        endcase
    end
end

//////////////////////////////////////////////////////////////////////////////////////////////
     mult_gen_0 mul(.CLK(clk),.A(reg1_i),.B(reg2_i),.P(mulres));  //鏈�?�鍙蜂箻娉�?
     mult_gen_0_1 mul_u(.CLK(clk),.A(reg1_i),.B(reg2_i),.P(mulres_u));  //鏃犵鍙蜂�?�娉�?

endmodule