`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/20/2022 06:31:25 PM
// Design Name: 
// Module Name: batch_gradient_calculator
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


module batch_gradient_calculator #(
    parameter FLOAT_SIZE = 32, //8bits/byte * 4bytes/float = 16 bits/float
    parameter DATALINE_SIZE = 16,
    parameter N_SIZE = 32
)
(
    input clk,
    input rst,
    input [31:0] N,
    input s_axis_rx_data_TVALID,
    input s_axis_rx_data_TLAST, //batch last
    input [511:0] s_axis_rx_data_TDATA,
    output [511:0] batch_gradient_TDATA,
    output batch_gradient_TVALID,
    output batch_gradient_TLAST,
    output s_axis_rx_data_TREADY
    );
    
    wire dividend_TVALID;
    //wire dividend_TVALID_inter;
    wire [31:0] dividend_TDATA;
    //wire [31:0] dividend_TDATA_inter;
    wire N_TVALID_forFIFO;
    wire [31:0] N_TDATA_forFIFO;
    //wire divider_TVALID;
    wire [31:0]divider_TDATA;
    
    wire divider_out_TVALID;

    
    //batch gradient result adder
    batch_gradient_adder batch_gradient_adder_inst(.clk(clk), .rst(rst), .s_axis_rx_TDATA(reg_sum_per_dataline), .s_axis_rx_TVALID(reg_result_TVALID), .s_axis_rx_TLAST(reg_result_TLAST),  
    .m_axis_tx_TDATA(dividend_TDATA), .m_axis_tx_TVALID(dividend_TVALID));
    //N_changeToFloat
    floating_point_2 N_to_float_inst (.aclk(clk), .s_axis_a_tvalid(s_axis_rx_data_TLAST), .s_axis_a_tdata(N), 
    .m_axis_result_tvalid(N_TVALID_forFIFO),.m_axis_result_tdata(N_TDATA_forFIFO), .m_axis_result_tready(1'b1));
    //N_FIFO
    N_sync N_sync_inst (.clk(clk), .rst(rst), .N(N_TDATA_forFIFO), .input_signal(N_TVALID_forFIFO), .N_buffer_ready(s_axis_rx_data_TREADY), .remove_signal(dividend_TVALID), 
    .m_axis_tx_TDATA(divider_TDATA)
    //,.valid_signal(divider_TVALID)
    );
    //divider
    floating_point_1 divider_inst(.aclk(clk), .s_axis_a_tvalid(dividend_TVALID), .s_axis_a_tdata(dividend_TDATA), .s_axis_b_tvalid(dividend_TVALID), .s_axis_b_tdata(divider_TDATA),
     .m_axis_result_tvalid(divider_out_TVALID), .m_axis_result_tdata(batch_gradient_TDATA[31:0]) ,.m_axis_result_tready(1'b1));
    
     assign batch_gradient_TDATA[511: 32] = 480'b0;
     assign batch_gradient_TVALID = divider_out_TVALID;
     assign batch_gradient_TLAST = divider_out_TVALID;
         
//    always@(posedge clk) begin
//        dividend_TVALID <= dividend_TVALID_inter;
//        dividend_TDATA <= dividend_TDATA_inter;
//    end
    
    //For handling packet
    reg [FLOAT_SIZE-1:0] reg_sum_per_dataline;
    wire [FLOAT_SIZE-1:0] sum_per_dataline;
    wire result_TVALID;
    reg reg_result_TVALID;
    wire result_TLAST;
    reg reg_result_TLAST;


    
    //For adding logic
    wire [FLOAT_SIZE-1:0]L1_sum[DATALINE_SIZE/2-1 :0];
    wire [FLOAT_SIZE-1:0]L2_sum[DATALINE_SIZE/4-1 :0];
    wire [FLOAT_SIZE-1:0]L3_sum[DATALINE_SIZE/8-1 :0];
    
    //for pipelining
    reg [FLOAT_SIZE-1:0]L1_reg[DATALINE_SIZE/2-1 :0];
    reg [FLOAT_SIZE-1:0]L2_reg[DATALINE_SIZE/4-1 :0];
    reg [FLOAT_SIZE-1:0]L3_reg[DATALINE_SIZE/8-1 :0];
    
    //for calculating delay 
    wire [DATALINE_SIZE/2-1 :0]result_TVALID_L1;
    wire [DATALINE_SIZE/4-1 :0]result_TVALID_L2;
    wire [DATALINE_SIZE/8-1 :0]result_TVALID_L3;
    wire [DATALINE_SIZE/2-1 :0]result_TLAST_L1;
    wire [DATALINE_SIZE/4-1 :0]result_TLAST_L2;
    wire [DATALINE_SIZE/8-1 :0]result_TLAST_L3; 
    reg  [DATALINE_SIZE/2-1 :0]reg_result_TVALID_L1;
    reg  [DATALINE_SIZE/4-1 :0]reg_result_TVALID_L2;
    reg  [DATALINE_SIZE/8-1 :0]reg_result_TVALID_L3;
    reg  [DATALINE_SIZE/2-1 :0]reg_result_TLAST_L1;
    reg  [DATALINE_SIZE/4-1 :0]reg_result_TLAST_L2;
    reg  [DATALINE_SIZE/8-1 :0]reg_result_TLAST_L3;
    
   
    //pipeling logic   
    genvar i;
    generate 
        for (i = 0; i< DATALINE_SIZE/2; i=i+1) begin
           always @(posedge clk) begin
             if(result_TVALID_L1[i] == 1'b1)  begin
                L1_reg[i] <= L1_sum[i];
             end
             reg_result_TVALID_L1[i] <= result_TVALID_L1[i];
             reg_result_TLAST_L1[i] <= result_TLAST_L1[i];
           end
        end
        for (i = 0; i<  DATALINE_SIZE/4; i=i+1) begin
            always @(posedge clk) begin
                if(result_TVALID_L2[i] ==1'b1) begin
                    L2_reg[i] <= L2_sum[i];
                end
                reg_result_TVALID_L2[i] <= result_TVALID_L2[i];
                reg_result_TLAST_L2[i] <= result_TLAST_L2[i];
            end
        end
        for (i = 0; i<  DATALINE_SIZE/8; i=i+1) begin
            always @(posedge clk) begin
                if(result_TVALID_L3[i] ==1'b1) begin
                    L3_reg[i] <= L3_sum[i];
                end
                reg_result_TVALID_L3[i] <= result_TVALID_L3[i];
                reg_result_TLAST_L3[i] <= result_TLAST_L3[i];
            end
        end
     endgenerate
     
     always @(posedge clk) begin
        if(result_TVALID == 1'b1)  begin
            reg_sum_per_dataline <= sum_per_dataline;
        end
        reg_result_TVALID <= result_TVALID;
        reg_result_TLAST <= result_TLAST;
     end
     
    //Generate BLock for each layer adder
    //layer1 with 8 adders
    genvar layer1_i;
    generate 
        for (layer1_i=0; layer1_i < DATALINE_SIZE/2; layer1_i=layer1_i+1) begin
             floating_point_0 float_adder_layer1 ( .s_axis_a_tdata(s_axis_rx_data_TDATA[layer1_i* 2 * FLOAT_SIZE +31:layer1_i* 2 * FLOAT_SIZE]), 
            .s_axis_b_tdata(s_axis_rx_data_TDATA[layer1_i* 2 * FLOAT_SIZE + 63:layer1_i* 2 * FLOAT_SIZE + 32]), 
            .m_axis_result_tdata(L1_sum[layer1_i]), 
            .s_axis_a_tlast(s_axis_rx_data_TLAST), 
            .s_axis_a_tvalid(s_axis_rx_data_TVALID), .s_axis_b_tvalid(s_axis_rx_data_TVALID), .m_axis_result_tready(1'b1),
            .m_axis_result_tvalid(result_TVALID_L1[layer1_i]), .m_axis_result_tlast(result_TLAST_L1[layer1_i]),
            .aclk(clk)
            );
        end
    endgenerate
    
    //layer2 with 4 adders
    genvar layer2_i;
    generate 
        for (layer2_i=0; layer2_i < DATALINE_SIZE/4; layer2_i=layer2_i+1) begin
             floating_point_0 float_adder_layer2 ( .s_axis_a_tdata(L1_reg[layer2_i*2]), .s_axis_b_tdata(L1_reg[layer2_i*2+1]), .m_axis_result_tdata(L2_sum[layer2_i]),
             .s_axis_a_tvalid(reg_result_TVALID_L1[layer2_i*2]),.s_axis_b_tvalid(reg_result_TVALID_L1[layer2_i*2 + 1]),
              .m_axis_result_tready(1'b1),
             .s_axis_a_tlast(reg_result_TLAST_L1[layer2_i*2]),
             .m_axis_result_tvalid(result_TVALID_L2[layer2_i]),
             .m_axis_result_tlast(result_TLAST_L2[layer2_i]),
             .aclk(clk)
            );
        end
   endgenerate   
   
   //layer3 with 2 adders
   genvar layer3_i;
   generate 
        for (layer3_i=0; layer3_i < DATALINE_SIZE/8; layer3_i=layer3_i+1) begin
             floating_point_0 float_adder_layer3 ( .s_axis_a_tdata(L2_reg[layer3_i*2]), .s_axis_b_tdata(L2_reg[layer3_i*2+1]), .m_axis_result_tdata(L3_sum[layer3_i]),
             .s_axis_a_tvalid(reg_result_TVALID_L2[layer3_i*2]),.s_axis_b_tvalid(reg_result_TVALID_L2[layer3_i*2 + 1]),
             .m_axis_result_tready(1'b1),
             .s_axis_a_tlast(reg_result_TLAST_L2[layer3_i*2]), 
             .m_axis_result_tvalid(result_TVALID_L3[layer3_i]), .m_axis_result_tlast(result_TLAST_L3[layer3_i]),
             .aclk(clk)
            );

        end
   endgenerate
    
   
   //result of sum per pack
//   int_adder int_sum_out (.a(L3_reg[1]), .b(L3_reg[0]), .sum(int_sum_per_pack));   
   floating_point_0 float_sum_out ( .s_axis_a_tdata(L3_reg[1]), .s_axis_b_tdata(L3_reg[0]), .m_axis_result_tdata(sum_per_dataline), 
                                    .s_axis_a_tvalid(reg_result_TVALID_L3[0]),.s_axis_b_tvalid(reg_result_TVALID_L3[1]),
                                    .s_axis_a_tlast(reg_result_TLAST_L3[0]), 
                                    .m_axis_result_tready(1'b1),
                                    .m_axis_result_tvalid(result_TVALID), .m_axis_result_tlast(result_TLAST),
                                    .aclk(clk)
                                    );

//   assign batch_gradient_TDATA = reg_sum_per_dataline;
//   assign batch_gradient_TVALID = reg_result_TVALID;
//   assign batch_gradient_TLAST = reg_result_TLAST;
endmodule
