`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/12/2022 11:10:39 AM
// Design Name: 
// Module Name: FIFO_stream
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

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/12/2022 10:54:32 AM
// Design Name: 
// Module Name: FIFO_stream
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



module FIFO_stream #(
    parameter ADDR_BITS = 5,
    parameter DATA_SIZE = 32+1
)(
    input wire clk,
    input wire rst,
    input wire [31+1:0] s_axis_tdata,
    input wire s_axis_tvalid,  //put N in the buffer
    output wire [31+1:0] m_axis_tdata,
    //output reg valid_signal,
    input wire m_axis_tready,
    output wire m_axis_tvalid
    );
    
    wire m_axis_tvalid_inter;
    reg m_axis_tvalid_latch;
    wire [31+1:0] m_axis_tdata_inter;
    reg [31+1:0] m_axis_tdata_latch;
//    reg m_axis_tready_inter;
//    wire m_axis_tready_input;
    
//    always @ (posedge clk) begin
//        m_axis_tdata_latch <= m_axis_tdata_inter;
//        m_axis_tvalid_latch <= m_axis_tvalid_inter;
//    end
    
//    assign m_axis_tdata = m_axis_tdata_latch;
//    assign m_axis_tvalid = m_axis_tvalid_latch;
      assign m_axis_tvalid = m_axis_tvalid_inter;
      assign m_axis_tdata = m_axis_tdata_inter;
            nukv_fifogen #(
            .DATA_SIZE(DATA_SIZE),
            .ADDR_BITS(ADDR_BITS)
        ) fifo_inst (
                .clk(clk),
                .rst(rst),
                .s_axis_tvalid(s_axis_tvalid),
                //.s_axis_tready(1'b1),
                .s_axis_tdata(s_axis_tdata),  
                .m_axis_tvalid(m_axis_tvalid_inter),
                .m_axis_tready(m_axis_tready),
                .m_axis_tdata(m_axis_tdata_inter)
                ); 				
  
endmodule
