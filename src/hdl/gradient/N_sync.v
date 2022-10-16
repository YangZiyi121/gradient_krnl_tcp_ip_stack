`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/30/2022 04:41:26 PM
// Design Name: 
// Module Name: N_sync
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


module N_sync #(
    ADDR_BITS = 5
)(
    input wire clk,
    input wire rst,
    input wire [31:0] N,
    input wire input_signal,  //put N in the buffer
    output wire N_buffer_ready,
    input wire remove_signal,
    //output reg valid_signal,
    output wire [31:0] m_axis_tx_TDATA
    );
    
//    wire internal_valid;
    
//     always @(posedge clk) begin
//        valid_signal <= remove_signal & internal_valid;
//     end
    
            nukv_fifogen #(
            .DATA_SIZE(32),
            .ADDR_BITS(ADDR_BITS)
        ) fifo_inst (
                .clk(clk),
                .rst(rst),
                .s_axis_tvalid(input_signal),
                .s_axis_tready(N_buffer_ready),
                .s_axis_tdata(N),  
                //.m_axis_tvalid(internal_valid),
                .m_axis_tready(remove_signal),
                .m_axis_tdata(m_axis_tx_TDATA)
                ); 				
  
    
//    reg [POSITION * 32 -1:0]N_buffer;
//    reg [31:0] stop_N_register;
//    reg [31:0] reg_m_axis_tx_TDATA;
//    reg reg_valid_signal;
//    reg reg_N_buffer_ready;

    
//    assign valid_signal = reg_valid_signal;
//    assign m_axis_tx_TDATA = reg_m_axis_tx_TDATA;
//    assign N_buffer_test = N_buffer;
//    assign N_buffer_ready = reg_N_buffer_ready;
    
//    always @(posedge clk) begin
//       if (stop_N_register > 0 && remove_signal == 1)begin
//         {N_buffer, reg_m_axis_tx_TDATA}  <= {stop_N_register, N_buffer};
//          reg_valid_signal <= 1;
//          stop_N_register <= 0;
//          reg_N_buffer_ready <= 1; 
//       end
//       else if(N_buffer[31:0] > 32'b0) begin
//          if(input_signal == 1 && remove_signal == 1) begin
//             {N_buffer, reg_m_axis_tx_TDATA}  <= {N, N_buffer};
//             reg_N_buffer_ready <= 1;
//             reg_valid_signal <= 1;
//          end
//          else if(input_signal == 0 && remove_signal == 1) begin
//             {N_buffer, reg_m_axis_tx_TDATA} <= {32'b0, N_buffer};
//             reg_N_buffer_ready <= 1;
//             reg_valid_signal <= 1;
//          end
//          else if(input_signal == 1 && remove_signal == 0 && stop_N_register == 0) begin
//             reg_N_buffer_ready <= 0;
//             stop_N_register <= N;
//             reg_valid_signal <= 0;
//          end
//          else  reg_valid_signal <= 0; 
//       end
//       else begin
//          reg_valid_signal <= 0;
//          reg_N_buffer_ready <= 1; 
//          stop_N_register <= 0;
//          if(input_signal == 1) begin
//             N_buffer <= {N, N_buffer[POSITION * 32 -1:32]}; 
//          end
////          else begin
////            N_buffer <= {32'b0, N_buffer[POSITION * 32 -1:32]}; 
////          end
//        end
//    end
   
endmodule
