`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/08/14 13:46:32
// Design Name: 
// Module Name: rst_ctrl
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


module rst_ctrl(
    input   rstn                    ,
    input   clk                     ,
    
    output reg  cpu_rst1            ,
    output reg  cpu_rst2            ,
    output reg  cpu_rst3            ,
    output reg  cpu_rst4            ,
    output reg  cpu_rst5            ,
    output reg  cpu_rst6            ,
    output reg  icache_rst          ,
    output reg  dcache_rst          ,
    output reg  bpu_rst             ,
    output reg  axi_rst
    
    );
    
/// AXI,BPU为低电平有效，CPU和CACHE是高电平有效///
    
localparam IDLE = 0,RESET1 = 1,RESET2 = 2,RESET3 = 3,RESET4 = 4,RESET5 = 5,RESET6 = 6,RESET7 = 7,RESET8 = 8,RESET9 = 9,RESET10 = 10,WAIT = 12;  
    
reg [3:0]state;
reg [3:0]next_state;   
    
    
always @(posedge clk) begin
    if (rstn) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always @(*) begin
    if(rstn) begin
        next_state = IDLE;
    end else begin
      case(state)  
        IDLE:   begin
            next_state = RESET1;
          //  else    next_state = IDLE;
        end
        RESET1: begin
            next_state = RESET2;
        end
        RESET2:  begin
            next_state =  RESET3;
        end
        RESET3:  begin
            next_state = RESET4;
        end
        RESET4:  begin
            next_state = RESET5;
        end
        RESET5:  next_state = RESET6;
        RESET6:  next_state = RESET7;
        RESET7:  next_state = RESET8;
        RESET8:  next_state = RESET9;
        RESET9:  next_state = RESET10;
        RESET10: next_state = WAIT;
        WAIT :   begin
            next_state = WAIT;
        end    
        default: begin
            next_state = IDLE;
        end
    endcase
    
  end
end
                                       
    

always @(posedge clk) begin
    if(rstn) begin
        cpu_rst1            <= 0;
        cpu_rst2            <= 0;
        cpu_rst3            <= 0;
        cpu_rst4            <= 0;
        cpu_rst5            <= 0;
        cpu_rst6            <= 0;
        icache_rst          <= 0;
        dcache_rst          <= 0;
        bpu_rst             <= 1'b1;
        axi_rst             <= 1'b1;
          
    end else begin
        case(state)          
            IDLE: begin
//                cpu_rst <= 1'b1; 
//                cache_rst <= 1'b1;
//                bpu_rst <= 0; 
//                axi_rst <= 0;
            end
            RESET1:         cpu_rst1 <= 1'b1;
            RESET2:         cpu_rst2 <= 1'b1;
            RESET3:         cpu_rst3 <= 1'b1;
            RESET4:         cpu_rst4 <= 1'b1;
            RESET5:         cpu_rst5 <= 1'b1;
            RESET6:         cpu_rst6 <= 1'b1;

            RESET7:  begin
                   icache_rst <= 1'b1;
                   //cpu_rst <= 1'b0;
                   end
            RESET8:  begin
                   dcache_rst<= 1'b1 ;
                   end       
            RESET9:  begin
                   bpu_rst <= 1'b0;
                   //cache_rst <= 1'b0;
                   end
            RESET10:  begin
                   axi_rst <= 1'b0;     
                   //bpu_rst <= 1'b1;
                   end      
            default:  ;
            endcase
        end
 end           
                    
        
endmodule
