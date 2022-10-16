//---------------------------------------------------------------------------
//--  Copyright 2015 - 2017 Systems Group, ETH Zurich
//-- 
//--  This hardware module is free software: you can redistribute it and/or
//--  modify it under the terms of the GNU General Public License as published
//--  by the Free Software Foundation, either version 3 of the License, or
//--  (at your option) any later version.
//-- 
//--  This program is distributed in the hope that it will be useful,
//--  but WITHOUT ANY WARRANTY; without even the implied warranty of
//--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//--  GNU General Public License for more details.
//-- 
//--  You should have received a copy of the GNU General Public License
//--  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//---------------------------------------------------------------------------


module tcp_top_loopback #(
      parameter IS_SIM = 0
      )
      (

			  input wire	    aclk,
			  input wire	    aresetn,

			  output wire	    m_axis_open_connection_TVALID,
			  input wire	    m_axis_open_connection_TREADY,
			  output wire [47:0]     m_axis_open_connection_TDATA,

			  input wire	    s_axis_open_status_TVALID,
			  output wire	    s_axis_open_status_TREADY,
			  input wire [23:0] 	    s_axis_open_status_TDATA,

			  output wire	    m_axis_close_connection_TVALID,
			  input wire	    m_axis_close_connection_TREADY,
			  output wire [15:0]     m_axis_close_connection_TDATA,

			  output wire	    m_axis_listen_port_TVALID,
			  input wire	    m_axis_listen_port_TREADY,
			  output wire [15:0]     m_axis_listen_port_TDATA,

			  input wire	    s_axis_listen_port_status_TVALID,
			  output wire	    s_axis_listen_port_status_TREADY,
			  input wire [7:0] 	    s_axis_listen_port_status_TDATA,

			  input wire	    s_axis_notifications_TVALID,
			  output wire	    s_axis_notifications_TREADY,
			  input wire [87:0] 	    s_axis_notifications_TDATA,

			  output wire	    m_axis_read_package_TVALID,
			  input wire	    m_axis_read_package_TREADY,
			  output wire [31:0]     m_axis_read_package_TDATA,

			  output wire	    m_axis_tx_data_TVALID,
			  input wire	    m_axis_tx_data_TREADY,
			  output wire [511:0]     m_axis_tx_data_TDATA,
			  output wire [64:0] 	    m_axis_tx_data_TKEEP,
			  output wire 	    m_axis_tx_data_TLAST,

			  output wire 	    m_axis_tx_metadata_TVALID,
			  input wire	    m_axis_tx_metadata_TREADY,
			  output wire[15:0] m_axis_tx_metadata_TDATA,

			  input wire	    s_axis_tx_status_TVALID,
			  output wire	    s_axis_tx_status_TREADY,
			  input wire [63:0] 	    s_axis_tx_status_TDATA,

			  input wire	    s_axis_rx_data_TVALID,
			  output wire	    s_axis_rx_data_TREADY,
			  input wire [511:0] 	    s_axis_rx_data_TDATA,
			  input wire [63:0] 	    s_axis_rx_data_TKEEP,
			  input wire [0:0] 	    s_axis_rx_data_TLAST,

			  input wire	    s_axis_rx_metadata_TVALID,
			  output wire	    s_axis_rx_metadata_TREADY,
			  input wire [15:0] 	    s_axis_rx_metadata_TDATA
			  
			  
			  
			  );

   assign m_axis_close_connection_TVALID = 0;
   assign s_axis_listen_port_status_TREADY = 1;
   assign s_axis_rx_metadata_TREADY = 1;
   assign s_axis_tx_status_TREADY = 1;      
   
   assign m_axis_open_connection_TVALID  = 0;
   assign s_axis_open_status_TREADY = 1;


   (* mark_debug = "true" *) reg 					    port_opened;
   (* mark_debug = "true" *) reg 					    axis_listen_port_valid;
   (* mark_debug = "true" *) reg [15:0] 				    axis_listen_port_data;
   reg 					    reset;
   wire [63:0] 				    meta_output;

   wire 				    s_axis_rx_data_TFULL;

   wire 				    toAdderValid;
   wire [512:0] 				    toAdderData;
   wire 				    toAdderReady;
   
      wire 				    fromAdderValid;
   wire [512:0] 				    fromAdderData;
   wire 				    fromAdderReady;
   
   (* mark_debug = "true" *) wire 				    splitPreValid;
   (* mark_debug = "true" *) wire                     splitPreReady;
   (* mark_debug = "true" *) wire [64+512+1:0]                     splitPreData;   

   wire 				    finalOutValid;
   wire                     finalOutReady;
   wire                     finalOutLast;
   wire [64+512+1:0]                     finalOutData;    

   wire 				    sesspackValid;
   wire             sesspackMetaValid;
   wire             sesspackReady;
   wire 				    sesspackMetaReady;
   wire 				    sesspackLast;
   wire [63:0] 				    sesspackData;
   wire [63:0] 				    sesspackMeta;
   
   
   (* mark_debug = "true" *) wire[511:0] maxis_tx_data;
   (* mark_debug = "true" *) wire maxis_tx_last;
   (* mark_debug = "true" *) wire maxis_tx_ready;
   (* mark_debug = "true" *) wire maxis_tx_valid;
   
   (* mark_debug = "true" *) wire[15:0] maxis_meta_data;   
   (* mark_debug = "true" *) wire maxis_meta_ready;
   (* mark_debug = "true" *) wire maxis_meta_valid;
 
   
   reg [15:0] myClock;
   
   wire clk;

   assign clk = aclk;


   assign m_axis_listen_port_TDATA = axis_listen_port_data;
   assign m_axis_listen_port_TVALID = axis_listen_port_valid;


   //open up server port (2888)
   always @(posedge clk) 
     begin
	reset <= !aresetn;
	
	if (aresetn == 0) begin
           port_opened <= 1'b0;
           axis_listen_port_valid <= 1'b0;
           axis_listen_port_data <= 0;
           myClock <= 0;        
	end
	else begin
           axis_listen_port_valid <= 1'b0;

           //try every half millisecond           
           if (myClock[15]==1'b1 && port_opened==0 && m_axis_listen_port_TREADY==1) begin
              axis_listen_port_valid <= 1'b1;
              axis_listen_port_data <= 16'h0B48; //port = 2888
              port_opened <= 1;
           end
           
           
           myClock <= myClock+1;
	end
     end




        nukv_fifogen #(
            .DATA_SIZE(513),
            .ADDR_BITS(5)
        ) input_firstword_fifo_inst (
                .clk(clk),
                .rst(reset),
                .s_axis_tvalid(s_axis_rx_data_TVALID),
                .s_axis_tready(s_axis_rx_data_TREADY),
                .s_axis_tdata({s_axis_rx_data_TLAST[0], s_axis_rx_data_TDATA}),  
                .m_axis_tvalid(toAdderValid),
                .m_axis_tready(toAdderReady),
                .m_axis_tdata(toAdderData)
                ); 				
  
 //////////////////
 //Adder logic starts here; takes input on "toAdder", gives output on "fromAdder" 
 ////////////////// 
  
  wire[511:0] intData;
  wire[31:0] intCount;
  wire intValid;
  wire intLast;
  wire intReady;
  
  packet_state packet_state_inst (
    .clk(clk),
    .rst(reset),
    .rx_data_TVALID(toAdderValid),
    .rx_data_TREADY(toAdderReady),
    .rx_data_TDATA(toAdderData),
    .tx_data_TDATA(intData),
    .tx_data_TVALID(intValid),
    .tx_data_TREADY(intReady),
    .N(intCount),
    .batch_ending(intLast)
    );

  
  batch_gradient_calculator  #(
    .FLOAT_SIZE(32), //8bits/byte * 4bytes/float = 16 bits/float
    .DATALINE_SIZE(16),
    .N_SIZE(32)
) batch_calc_inst
(
    .clk(clk),
    .rst(reset),
    .N(intCount),
    .s_axis_rx_data_TREADY(intReady),
    .s_axis_rx_data_TVALID(intValid),
    .s_axis_rx_data_TLAST(intLast), //batch last
    .s_axis_rx_data_TDATA(intData),
    .batch_gradient_TDATA(fromAdderData[31:0]),
    .batch_gradient_TVALID(fromAdderValid)
    //.packet_gradient_TLAST(fromAdderData[512])
    );
  assign fromAdderData[512] = 1'b0;
  //////////////////
  //Adder logic ends
  //////////////////
  wire from_acceptor_valid;
  wire from_acceptor_ready;
  wire[63:0] from_acceptor_data;

   event_acceptor  event_acceptor_inst (
					    .clk(clk),
					    .rst(reset),

					    .event_valid(s_axis_notifications_TVALID),
					    .event_ready(s_axis_notifications_TREADY),
					    .event_data(s_axis_notifications_TDATA),
      
					    .readreq_valid(m_axis_read_package_TVALID),
					    .readreq_ready(m_axis_read_package_TREADY),
					    .readreq_data(m_axis_read_package_TDATA),

              .event_out_valid(from_acceptor_valid),
              .event_out_ready(from_acceptor_ready),
              .event_out_data(from_acceptor_data)        
      					    
					    );

   nukv_fifogen #(
            .DATA_SIZE(64),
            .ADDR_BITS(6)
        ) fifo_meta (
                .clk(clk),
                .rst(reset),
                .s_axis_tvalid(from_acceptor_valid),
                .s_axis_tready(from_acceptor_ready),
                .s_axis_tdata(from_acceptor_data),  
                .m_axis_tvalid(sesspackMetaValid),
                .m_axis_tready(sesspackMetaReady),
                .m_axis_tdata(sesspackMeta)
                ); 


    assign splitPreValid = fromAdderValid & sesspackMetaValid;
    assign fromAdderReady = splitPreReady;
    assign sesspackMetaReady = splitPreReady & fromAdderValid & fromAdderData[512];
    //assign sesspackMetaReady = splitPreReady & fromAdderValid & fromAdderData[32];
    assign splitPreData[63+32:0] = {fromAdderData[511:0],sesspackMeta};
    //assign splitPreData[63+32:0] = {fromAdderData[31:0],sesspackMeta};
    assign splitPreData[64+512] = fromAdderData[512]; 
    //assign splitPreData[64+32] = fromAdderData[32]; // last signal
       
   nukv_fifogen #(
            .DATA_SIZE(64+511+1),
            //.DATA_SIZE(64+31+1),
            .ADDR_BITS(6)
        ) fifo_splitprepare (
						    .clk(clk),
						    .rst(reset),
						    .s_axis_tvalid(splitPreValid),
						    .s_axis_tready(splitPreReady),
						    .s_axis_tdata(splitPreData),
						    .m_axis_tvalid(finalOutValid),
						    .m_axis_tready(finalOutReady),
						    .m_axis_tdata(finalOutData)
						    ); 
   
   
   wire ignoreWrites;
   wire ignoreProps;

   assign   finalOutLast = finalOutData[512+64];
   //assign finalOutLast = finalOutData[32+64];
   assign   maxis_tx_valid = finalOutValid & finalOutReady;
   assign   maxis_tx_data = finalOutData[511+64:64];
  //assign   maxis_tx_data = finalOutData[31+64:64];
   assign   m_axis_tx_data_TKEEP = 64'hFFFFFFFFFFFFFFFF;
   assign   maxis_tx_last = finalOutValid & finalOutLast;
   
   assign   finalOutReady = maxis_meta_ready & maxis_tx_ready;
   
   assign   maxis_meta_data = finalOutData[15:0];
   assign   maxis_meta_valid = finalOutValid & finalOutReady & finalOutLast;

   wire [512:0] m_axis_tx_data_COMBINED;
   //wire [32:0] m_axis_tx_data_COMBINED;
   nukv_fifogen #(
                 .DATA_SIZE(512+1),
                 .ADDR_BITS(8)
             ) output_net_data_buffer (
                     .clk(clk),
                     .rst(reset),
                     .s_axis_tvalid(maxis_tx_valid),
                     .s_axis_tready(maxis_tx_ready),
                     .s_axis_tdata({maxis_tx_last,maxis_tx_data}),  
                     .m_axis_tvalid(m_axis_tx_data_TVALID),
                     .m_axis_tready(m_axis_tx_data_TREADY),
                     .m_axis_tdata(m_axis_tx_data_COMBINED)
                     ); 
  assign m_axis_tx_data_TDATA = m_axis_tx_data_COMBINED[511:0];
  //assign m_axis_tx_data_TDATA = m_axis_tx_data_COMBINED[31:0];
  assign m_axis_tx_data_TLAST = m_axis_tx_data_COMBINED[512];     
  //assign m_axis_tx_data_TLAST = m_axis_tx_data_COMBINED[32];             
                    
   nukv_fifogen #(
              .DATA_SIZE(16),
              .ADDR_BITS(4)
          ) output_net_meta_buffer (
                  .clk(clk),
                  .rst(reset),
                  .s_axis_tvalid(maxis_meta_valid),
                  .s_axis_tready(maxis_meta_ready),
                  .s_axis_tdata(maxis_meta_data),  
                  .m_axis_tvalid(m_axis_tx_metadata_TVALID),
                  .m_axis_tready(m_axis_tx_metadata_TREADY),
                  .m_axis_tdata(m_axis_tx_metadata_TDATA)
                  ); 






 


endmodule
