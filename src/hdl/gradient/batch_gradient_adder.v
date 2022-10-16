`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/28/2022 04:59:51 PM
// Design Name: 
// Module Name: batch_gradient_adder
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


module batch_gradient_adder#(
    FLOAT_SIZE = 32,
    PIPE_SIZE = 16
)(
    input wire clk,
    input wire rst,
    input wire [31:0] s_axis_rx_TDATA,
    input wire s_axis_rx_TVALID,
    input wire s_axis_rx_TLAST,
    output reg [31:0] m_axis_tx_TDATA,
    output reg m_axis_tx_TVALID
    );
    
    //state machine 
    parameter  packetWaiting = 2'b00, packetValid = 2'b01; 
    reg [1:0] st;
    reg [3:0] counter;
    
    //For four dataline addersc
    reg [511:0] reg_data_input_layer_1;
    
    reg packet_sum_input_TVALID; //input of the four dataline adder
    reg batch_sum_input_TLAST; //input of the four dataline adder
    
    //For adding logic
    wire [FLOAT_SIZE-1:0]L1_sum[PIPE_SIZE/2-1 :0];
    wire [FLOAT_SIZE-1:0]L2_sum[PIPE_SIZE/4-1 :0];
    wire [FLOAT_SIZE-1:0]L3_sum[PIPE_SIZE/8-1 :0];
    
    //for pipelining
    reg [FLOAT_SIZE-1:0]L1_reg[PIPE_SIZE/2-1 :0];
    reg [FLOAT_SIZE-1:0]L2_reg[PIPE_SIZE/4-1 :0];
    reg [FLOAT_SIZE-1:0]L3_reg[PIPE_SIZE/8-1 :0];
    
    //for calculating delay 
    wire [PIPE_SIZE/2-1 :0]result_TVALID_L1;
    wire [PIPE_SIZE/4-1 :0]result_TVALID_L2;
    wire [PIPE_SIZE/8-1 :0]result_TVALID_L3;
    wire [PIPE_SIZE/2-1 :0]result_TLAST_L1;
    wire [PIPE_SIZE/4-1 :0]result_TLAST_L2;
    wire [PIPE_SIZE/8-1 :0]result_TLAST_L3; 
    reg  [PIPE_SIZE/2-1 :0]reg_result_TVALID_L1;
    reg  [PIPE_SIZE/4-1 :0]reg_result_TVALID_L2;
    reg  [PIPE_SIZE/8-1 :0]reg_result_TVALID_L3;
    reg  [PIPE_SIZE/2-1 :0]reg_result_TLAST_L1;
    reg  [PIPE_SIZE/4-1 :0]reg_result_TLAST_L2;
    reg  [PIPE_SIZE/8-1 :0]reg_result_TLAST_L3;
    
    //For summing up the whole batch
    reg [31:0] reg_sum_batch_total; //input of the adder
    wire [31:0] sum_batch_total; //output the the adder
    reg [31:0] reg_sum_current; //input of batch adder
    wire [31:0] sum_current; //the output of the four dataline adders
    reg reg_adderTree_sum_TVALID; //input of batch adder
    wire adderTree_sum_TVALID; //the output of the four dataline adders
    wire adderTree_batch_tlast;//the output of the four dataline adders
    reg reg_adderTree_batch_tlast; //input of batch adder
    wire batchResult_done; //last signal of the batch adder
    
    
    always @(posedge clk) begin
        if(reg_batch_last && cycle_adding_end_valid) begin
            m_axis_tx_TDATA <= sum_batch_total;
        end
        m_axis_tx_TVALID <= reg_batch_last && cycle_adding_end_valid;
    end
     
     
    //pipeling logic   
    genvar i;
    generate 
        for (i = 0; i< PIPE_SIZE/2; i=i+1) begin
           always @(posedge clk) begin
             if(result_TVALID_L1[i] == 1'b1)  begin
                L1_reg[i] <= L1_sum[i];
             end
             reg_result_TVALID_L1[i] <= result_TVALID_L1[i];
             reg_result_TLAST_L1[i] <= result_TLAST_L1[i];
           end
        end
        for (i = 0; i<  PIPE_SIZE/4; i=i+1) begin
            always @(posedge clk) begin
                if(result_TVALID_L2[i] ==1'b1) begin
                    L2_reg[i] <= L2_sum[i];
                end
                reg_result_TVALID_L2[i] <= result_TVALID_L2[i];
                reg_result_TLAST_L2[i] <= result_TLAST_L2[i];
            end
        end
        for (i = 0; i<  PIPE_SIZE/8; i=i+1) begin
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
        if(adderTree_sum_TVALID == 1'b1)  begin
            reg_sum_current <= sum_current;
        end
        reg_adderTree_sum_TVALID <= adderTree_sum_TVALID;
        reg_adderTree_batch_tlast <= adderTree_batch_tlast;
     end

    //Generate BLock for each layer adder
    //layer1 with 8 adders
    genvar layer1_i;
    generate 
        for (layer1_i=0; layer1_i < PIPE_SIZE/2; layer1_i=layer1_i+1) begin
             floating_point_0 float_adder_layer1 ( .s_axis_a_tdata(reg_data_input_layer_1[layer1_i* 2 * FLOAT_SIZE +31:layer1_i* 2 * FLOAT_SIZE]), 
            .s_axis_b_tdata(reg_data_input_layer_1[layer1_i* 2 * FLOAT_SIZE + 63:layer1_i* 2 * FLOAT_SIZE + 32]), 
            .m_axis_result_tdata(L1_sum[layer1_i]), 
            .s_axis_a_tlast(batch_sum_input_TLAST), 
            .s_axis_a_tvalid(packet_sum_input_TVALID), .s_axis_b_tvalid(packet_sum_input_TVALID), .m_axis_result_tready(1'b1),
            .m_axis_result_tvalid(result_TVALID_L1[layer1_i]), .m_axis_result_tlast(result_TLAST_L1[layer1_i]),
            .aclk(clk)
            );
        end
    endgenerate
    
    //layer2 with 4 adders
    genvar layer2_i;
    generate 
        for (layer2_i=0; layer2_i < PIPE_SIZE/4; layer2_i=layer2_i+1) begin
             floating_point_0 float_adder_layer2 ( .s_axis_a_tdata(L1_reg[layer2_i*2]), .s_axis_b_tdata(L1_reg[layer2_i*2+1]), .m_axis_result_tdata(L2_sum[layer2_i]),
             .s_axis_a_tvalid(reg_result_TVALID_L1[layer2_i*2]),.s_axis_b_tvalid(reg_result_TVALID_L1[layer2_i*2 + 1]),
              .m_axis_result_tready(1'b1),
             .s_axis_a_tlast(reg_result_TLAST_L1[layer2_i*2]),
             .m_axis_result_tvalid(result_TVALID_L2[layer2_i]), .m_axis_result_tlast(result_TLAST_L2[layer2_i]),
             .aclk(clk)
            );
        end
   endgenerate   
   
   //layer3 with 2 adders
   genvar layer3_i;
   generate 
        for (layer3_i=0; layer3_i < PIPE_SIZE/8; layer3_i=layer3_i+1) begin
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
   floating_point_0 float_sum_out ( .s_axis_a_tdata(L3_reg[1]), .s_axis_b_tdata(L3_reg[0]), .m_axis_result_tdata(sum_current), 
                                    .s_axis_a_tvalid(reg_result_TVALID_L3[0]),.s_axis_b_tvalid(reg_result_TVALID_L3[1]),
                                    .s_axis_a_tlast(reg_result_TLAST_L3[0]), 
                                    .m_axis_result_tready(1'b1),
                                    .m_axis_result_tvalid(adderTree_sum_TVALID), .m_axis_result_tlast(adderTree_batch_tlast),
                                    .aclk(clk)
                                     );
  
    
    wire [31 + 1:0] new_FIFO_output; //batch_last_signal
    wire new_FIFO_output_valid;
    wire cycle_adding_end_valid; 
    reg  reg_cycle_adding_end_valid; 
    wire ready_for_next_sum, ready_for_next_FIFO;
    reg reg_batch_last = 0;
                   
    FIFO_stream summing_flow_control (
                .clk(clk),
                .rst(rst),
                .s_axis_tvalid(reg_adderTree_sum_TVALID),
                //.s_axis_tready(), //can always accept new value
                .s_axis_tdata({reg_adderTree_batch_tlast, reg_sum_current}),  
                .m_axis_tvalid(new_FIFO_output_valid),
                .m_axis_tready(ready_for_next_FIFO & ready_for_next_sum),
                .m_axis_tdata(new_FIFO_output)
                ); 	
                
    wire [31: 0] new_accumulation_output;
    wire new_accumulation_output_valid;
    			
    nukv_fifogen #(
            .DATA_SIZE(32),
            .ADDR_BITS(5)
        )summing_accumulation_control (
                .clk(clk),
                .rst(rst),
                .s_axis_tvalid(reg_cycle_adding_end_valid && new_FIFO_output > 0),
                //.s_axis_tready(1'b1),
                .s_axis_tdata(reg_sum_batch_total),  
                .m_axis_tvalid(new_accumulation_output_valid),
                .m_axis_tready(ready_for_next_sum),
                .m_axis_tdata(new_accumulation_output)
                ); 		                
    
   //logic for clear to zero if sum_batch_total      
   always @ (posedge clk) begin
     reg_cycle_adding_end_valid<= cycle_adding_end_valid;
     if(new_FIFO_output== 0) begin //starts
        reg_sum_batch_total <= 0;
        reg_cycle_adding_end_valid <= 1;
     end
     else if(reg_batch_last == 1 & cycle_adding_end_valid == 1) begin //clear
        reg_sum_batch_total<= 0;
     end
     else begin
        reg_sum_batch_total <= sum_batch_total;
     end
   end
   
   always @(posedge clk) begin
        if (batchResult_done == 1) begin
            reg_batch_last <= 1;
        end
        if(reg_batch_last == 1 && batchResult_done == 0 && cycle_adding_end_valid == 1) begin
             reg_batch_last <= 0;
        end
   end
  
   
   //wire sum_input_valid;
   //assign sum_input_valid = new_FIFO_output_valid & ready_for_next;      
   wire tlast;
   assign tlast = new_FIFO_output[32]& new_FIFO_output_valid & ready_for_next_FIFO;  
                        
   floating_point_0 float_batch_sum ( .s_axis_a_tdata(new_accumulation_output), .s_axis_b_tdata(new_FIFO_output[31:0]), .m_axis_result_tdata(sum_batch_total), 
                                    .s_axis_a_tvalid(new_accumulation_output_valid),
                                    .s_axis_b_tvalid(new_FIFO_output_valid),
                                    .s_axis_a_tready(ready_for_next_sum),
                                    .s_axis_b_tready(ready_for_next_FIFO),
                                    .s_axis_a_tlast(tlast),
                                    .s_axis_b_tlast(tlast),
                                    .m_axis_result_tready(1'b1),
                                    .m_axis_result_tvalid(cycle_adding_end_valid),
                                    .m_axis_result_tlast(batchResult_done),
                                    .aclk(clk)
                                    );         
   
                          
   always @(posedge clk) begin
    if(rst) begin
        packet_sum_input_TVALID <= 1'b0;
        st <= packetWaiting;
    end
    else begin
        packet_sum_input_TVALID = 1'b0;
        batch_sum_input_TLAST =  1'b0;
        case(st) 
            packetWaiting: begin
                if (s_axis_rx_TVALID == 1 && s_axis_rx_TLAST == 1) begin //one dataline batch
                    reg_data_input_layer_1 = {s_axis_rx_TDATA, 480'b0};    
                    packet_sum_input_TVALID <= 1'b1;
                    batch_sum_input_TLAST <=  1'b1;
                    st <= packetWaiting;
                end
                else if (s_axis_rx_TVALID == 1) begin //first dataline of the batch
                    counter <= counter + 1;
                    reg_data_input_layer_1 = {s_axis_rx_TDATA, 480'b0};    
                    st <= packetValid;
                end
                else begin //waiting
                     st <= packetWaiting;
                     reg_data_input_layer_1 <= 1;
                     packet_sum_input_TVALID <= 1'b0;
                     counter <= 4'b0;
                end
            end
        
            packetValid: begin
                counter <= counter + 1;
                if (s_axis_rx_TLAST == 1 && s_axis_rx_TVALID == 1) begin 
                    reg_data_input_layer_1 = {s_axis_rx_TDATA, reg_data_input_layer_1[511:32]};     
                    packet_sum_input_TVALID <= 1'b1;
                    batch_sum_input_TLAST <=  1'b1;
                    st <= packetWaiting;         
                end           
                else if (s_axis_rx_TVALID == 1) begin
                    reg_data_input_layer_1 = {s_axis_rx_TDATA, reg_data_input_layer_1[511:32]};   
                    if(counter == 15) begin
                        counter <= 0;
                        packet_sum_input_TVALID <= 1'b1;
                        st <= packetWaiting;
                    end
                    else begin
                        st <= packetValid;
                    end
                end
                else begin
                    packet_sum_input_TVALID <= 1'b1;
                    st <= packetWaiting;
                end
            end 
                        
        endcase
    end
    end
endmodule
