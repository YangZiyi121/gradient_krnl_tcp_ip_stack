`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/22/2022 12:43:48 PM
// Design Name: 
// Module Name: packet_state
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


module packet_state(
    input wire clk,
    input wire rst,
    input wire rx_data_TVALID,
    input wire tx_data_TREADY, //from adder
    output wire rx_data_TREADY,
    input wire [511:0] rx_data_TDATA,
    output wire [511:0] tx_data_TDATA,
    output wire tx_data_TVALID,
    output wire [31:0] N,
    output wire batch_ending
    );
    parameter waitingState = 1'b0, addingState = 1'b1;
    reg [2:0] st;
    reg [31:0] lineNum, remainder;
    reg [31:0] N_cur;
    reg [511:0] tx_data_TDATA_reg;
    reg tx_data_TVALID_reg;
    reg batch_ending_reg;
    reg ready;
    
    assign tx_data_TDATA = tx_data_TDATA_reg;
    assign tx_data_TVALID = tx_data_TVALID_reg;
    assign N =  (st==waitingState) ? N_cur : N;
    assign batch_ending = batch_ending_reg;
    assign rx_data_TREADY = tx_data_TREADY;
    //assign rx_data_TREADY = 1'b1;
 
    always @(posedge clk) begin
        if (rst) begin
         st <= waitingState;
         batch_ending_reg = 1'b0;
         tx_data_TVALID_reg = 1'b0;
         tx_data_TDATA_reg = 512'b0;
        end
        else begin 
        
            tx_data_TVALID_reg = 0;
            batch_ending_reg = 0;
            
            case(st)   
                waitingState:
                begin
                    if (rx_data_TVALID == 1 && tx_data_TREADY == 1) begin
                        N_cur = rx_data_TDATA[31:0]; //get the N
                        remainder = (N_cur + 1) % 16;
                        lineNum = (remainder == 0)?((N_cur + 1) - remainder) / 16:(((N_cur + 1) - remainder) / 16)+1; //calculate line number
                        tx_data_TDATA_reg <= {32'b0, rx_data_TDATA[479:0]};  
                        tx_data_TVALID_reg <= rx_data_TVALID;
                        if (lineNum == 1) begin    //end of the batch
                           st <= waitingState;
                           batch_ending_reg <= 1'b1;
                        end
                        else begin
                            st <= addingState;
                        end
                    end
                    else begin
                        st <= waitingState;
                        batch_ending_reg <= 1'b0;
                        tx_data_TVALID_reg <= 1'b0;
                        tx_data_TDATA_reg <= 512'b0;                   
                    end
                end 
                   
                addingState:
                begin
                    if (rx_data_TVALID == 1&& tx_data_TREADY == 1) begin
                        lineNum <= lineNum - 1'b1;
                        tx_data_TDATA_reg <= rx_data_TDATA;
                        tx_data_TVALID_reg <= rx_data_TVALID;   
                        if (lineNum > 2) begin 
                            st <= addingState;
                            tx_data_TDATA_reg <= rx_data_TDATA;
                            tx_data_TVALID_reg <= rx_data_TVALID;         
                        end    
                        else begin
                            st <= waitingState;
                            batch_ending_reg <= 1'b1;
                        end
                    end
                    else begin
                        st <= addingState;
                        batch_ending_reg <= 1'b0;
                        tx_data_TVALID_reg <= 1'b0;
                        tx_data_TDATA_reg <= 512'b0;                   
                    end
                end
                default: st <= waitingState;
            endcase
        end
     end
        
    
endmodule
