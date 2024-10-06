
`timescale 1 ns / 1 ps

	module net_engine_v1_0_S00_AXIS_1 #
	(
	    parameter integer C_POINTER_WIDTH       = 32,
        // AXIS Slave parameters
		parameter integer C_S_AXIS_TDATA_WIDTH	= 32, // AXI4Stream sink: Data Width
		
		// Net Engine parameters
		parameter integer C_NET_CELL_COUNT      = 2,  // CNN / Maxpooling Cell Count
		parameter integer C_NET_KERNAL_SIZE     = 3,   // Kernal Size
		
		// AXIS master parameters
		parameter integer C_M_START_COUNT       = 32
	)
	(
	    // AXIS Slave ports
		input wire  S_AXIS_ACLK,                                  // AXI4Stream sink: Clock
		input wire  S_AXIS_ARESETN,                               // AXI4Stream sink: Reset
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0]     S_AXIS_TDATA, // Data in
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB, // Byte qualifier
		input wire  S_AXIS_TLAST,                                 // Indicates boundary of last packet
		input wire  S_AXIS_TVALID,                                // Data is in valid
		
		output wire S_AXIS_TREADY,                                // Ready to accept data in
		output wire S_AXIS_WRITE_COMPLETE,                        // write completed
		
	    // AXIS Net Engine Control Ports
	    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0]     D_IN_BIAS,    // Bias input
	    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0]     D_IN_KERNAL_1,// Kernal Data
	    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0]     D_IN_KERNAL_2,
	    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0]     D_IN_KERNAL_3,
	    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0]     D_IN_KERNAL_4,
	    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0]     D_IN_KERNAL_5,
	    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0]     D_IN_KERNAL_6,
	    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0]     D_IN_KERNAL_7,
	    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0]     D_IN_KERNAL_8,
	    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0]     D_IN_KERNAL_9,
	    
        output wire [C_S_AXIS_TDATA_WIDTH - 1:0]    D_CNN_NET_OUT,       // Net Engine Output
        output wire [C_NET_CELL_COUNT-1:0]          D_CNN_NET_VALID_OUT, // Cell Valid Output
        
	    // AXIS Master data ports
		input wire                                  M_AXIS_ACLK,     // Master clock
		input wire                                  M_AXIS_ARESETN,  // Master reset
		input wire                                  M_AXIS_TREADY,   // Master ready
		
		output wire                                 M_AXIS_TVALID,   // Master data valid
		output wire [C_S_AXIS_TDATA_WIDTH-1 : 0]    M_AXIS_TDATA,    // Mastr data
		output wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TSTRB,   // byte qualifier
		output wire                                 M_AXIS_TLAST,    // Mastter last data
		
		// input configuration 
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0]    CELL_SELECT_CONFIG,  // cell select register
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0]    CONFIG_ROW_WIDTH,    // config Row width
		input wire                                 SOFT_NRESET_SIGNAL,  // internal reset
		// IP status
		output wire [C_S_AXIS_TDATA_WIDTH-1 : 0] D_STATUS_1,
		output wire [C_S_AXIS_TDATA_WIDTH-1 : 0] D_STATUS_2,
	   
	    // Debug Ports
        output wire [C_POINTER_WIDTH-1:0] D_OUT_WRITE_POINTER, // Write pointer
        output wire [C_POINTER_WIDTH-1:0] D_OUT_READ_POINTER   // Read pointer

	);
	// function called clogb2 that returns an integer which has the 
	// value of the ceiling of the log base 2.
	function integer clogb2 (input integer bit_depth);
	  begin
	    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
	      bit_depth = bit_depth >> 1;
	  end
	endfunction
	
	// Calculating no of words need for cells
	localparam NUMBER_OF_INPUT_WORDS  = C_NET_CELL_COUNT;
	localparam NUMBER_OF_OUTPUT_WORDS = NUMBER_OF_INPUT_WORDS - 2;
	// bit_num gives the minimum number of bits needed to address 'NUMBER_OF_INPUT_WORDS' size of FIFO.
	localparam bit_num   = C_POINTER_WIDTH;//clogb2(NUMBER_OF_INPUT_WORDS-1);
	localparam m_bit_num = C_POINTER_WIDTH;//clogb2(NUMBER_OF_OUTPUT_WORDS-1);
	
	localparam WAIT_COUNT_BITS = clogb2(C_M_START_COUNT-1);       
	
	// Define the states of state machine
	// The control state machine oversees the writing of input streaming data to the FIFO,
	// and outputs the streaming data from the FIFO
	localparam [1:0] S_IDLE        = 1'b0, // This is the initial/idle state 
	                 S_WRITE_FIFO  = 1'b1; // In this state FIFO is written with the
	                                    // input stream data S_AXIS_TDATA 	                                                                 	                                   
	
//	parameter [2:0] G_IDLE            = 3'b000,   
//	                G_DATA_RECEIVING  = 3'b001,  
//	                G_DATA_PROCESSING = 3'b010,  
//	                G_DATA_SENDING    = 3'b011,
//	                G_COMPLETED       = 3'b100;    
	                                                
	// AXIS Slave variables
	wire axis_tready;    // slave ready signal
	wire fifo_wren;      // FIFO write enable

	reg mst_exec_state;              // State variable
	reg fifo_full_flag;              // FIFO full flag
	reg [bit_num-1:0] write_pointer; // FIFO write pointer
	reg writes_done;                 // sink has accepted all the streaming data and stored in FIFO
	reg writes_done_delay;
	
	// AXIS Net Engine Control variables
	wire  [C_S_AXIS_TDATA_WIDTH-1:0] CNN_out_data;           // CNN cell output signal
	wire                             CNN_out_data_valid;     // CNN cell output valid signal
	wire  [C_S_AXIS_TDATA_WIDTH-1:0] MaxPool_out_data;       // MaxPool cell output signal
	wire                             MaxPool_out_data_valid; // MaxPool cell output valid signal
	wire  [C_S_AXIS_TDATA_WIDTH-1:0] out_data;               // cell output signal
	wire                             out_data_valid;         // cell output valid signal
	
	// Process Controlling Variables
	reg [m_bit_num-1:0] process_pointer;
	reg                 process_done;
	
	//  master control wires
	wire m_axis_tvalid_temp;
    reg out_data_valid_mready;
	
    reg [3:0] data_row_status;
    reg process_begin;
    
    // Row buffers
    reg  [C_S_AXIS_TDATA_WIDTH-1:0] row_data_fifo_1   [0 : NUMBER_OF_INPUT_WORDS-1];
    reg  [C_S_AXIS_TDATA_WIDTH-1:0] row_data_fifo_2   [0 : NUMBER_OF_INPUT_WORDS-1];
    reg  [C_S_AXIS_TDATA_WIDTH-1:0] row_data_fifo_3   [0 : NUMBER_OF_INPUT_WORDS-1];
    reg  [C_S_AXIS_TDATA_WIDTH-1:0] row_data_fifo_4   [0 : NUMBER_OF_INPUT_WORDS-1];
    reg  [C_S_AXIS_TDATA_WIDTH-1:0] row_data_out_fifo [0 : NUMBER_OF_OUTPUT_WORDS-1];
    
    reg [C_S_AXIS_TDATA_WIDTH-1 : 0]   config_out_row_count;
    reg [15:0] data_row_count;
    reg [3:0] data_row_count_prev;
    reg [3:0] data_row_filled;
    reg [3:0] data_row_filled_copy;
	
	// I/O Connections assignments
	// AXIS Slave assignments
	assign D_OUT_WRITE_POINTER   = write_pointer;
	assign S_AXIS_TREADY	     = axis_tready;
	assign S_AXIS_WRITE_COMPLETE = process_done;
	
	// AXIS Net Engine Control assignments
	assign D_STATUS_1 = {data_row_filled, data_row_filled, data_row_count, 12'b0};
	
	assign D_OUT_READ_POINTER  = process_pointer;
	
	// soft config row width
	always @(posedge S_AXIS_ACLK) begin
        config_out_row_count <= 'd100;//CONFIG_ROW_WIDTH;
	end 
	
	// AXIS Slave control
	// Control state machine implementation
	always @(posedge S_AXIS_ACLK) 
	begin  
	  if (!S_AXIS_ARESETN) 
	  // Synchronous reset (active low)
	    begin
	      mst_exec_state <= S_IDLE;
	    end  
	  else
	    case (mst_exec_state)
	      S_IDLE: 
	        // The sink starts accepting tdata when 
	        // there tvalid is asserted to mark the
	        // presence of valid streaming data 
	          if (S_AXIS_TVALID)
	            begin
	              mst_exec_state <= S_WRITE_FIFO;
	            end
	          else
	            begin
	              mst_exec_state <= S_IDLE;
	            end
	      S_WRITE_FIFO: 
	        // When the sink has accepted all the streaming input data,
	        // the interface swiches functionality to a streaming master
	        if (writes_done)
	          begin
	            mst_exec_state <= S_IDLE;
	          end
	        else
	          begin
	            // The sink accepts and stores tdata 
	            // into FIFO
	            mst_exec_state <= S_WRITE_FIFO;
	          end

	    endcase
	end
	// AXI Streaming Sink 
	// 
	// The example design sink is always ready to accept the S_AXIS_TDATA  until
	// the FIFO is not filled with NUMBER_OF_INPUT_WORDS/ config_out_row_count number of input words.
	assign axis_tready = ((mst_exec_state == S_WRITE_FIFO) && !process_begin && !M_AXIS_TVALID && (write_pointer <= config_out_row_count - 1)) ;
    
	always@(negedge S_AXIS_ACLK)
	begin
	  if (writes_done) begin
        writes_done   <= 1'b0;
	  end
	  
	  if(!S_AXIS_ARESETN || !SOFT_NRESET_SIGNAL)
	    begin
	      write_pointer  <= 0;
	      data_row_count <= 0;
	      writes_done    <= 1'b0;
	      data_row_filled<= 4'b0000;
	    end  
	  else
	    if (write_pointer <= config_out_row_count - 1)
	      begin
	        if (fifo_wren)
	          begin
	            // write pointer is incremented after every write to the FIFO
	            // when FIFO write signal is enabled.
	            write_pointer <= write_pointer + 1;
	            writes_done <= 1'b0;
	            
	          end
	          if ((write_pointer == config_out_row_count - 1))
	            begin
	              // reads_done is asserted when NUMBER_OF_INPUT_WORDS/ config_out_row_count numbers of streaming data 
	              // has been written to the FIFO which is also marked by S_AXIS_TLAST(kept for optional usage).
	              writes_done     <= 1'b1;
	              write_pointer   <= 0;
	              data_row_count  <= data_row_count + 1;
	              
	              if (data_row_filled == 4'b0111)
	                   data_row_filled <= {data_row_filled[2:0], 1'b0};
	              else
	                   data_row_filled <= {data_row_filled[2:0], 1'b1};
	            end
	      end  
	end

	// FIFO write enable generation
	assign fifo_wren = S_AXIS_TVALID && axis_tready;// && !process_begin;// && (!M_AXIS_TVALID && !M_AXIS_TREADY);
    
    
	// FIFO Implementation
	always @( negedge S_AXIS_ACLK ) begin
       if (fifo_wren) begin
        case (data_row_filled)
          4'b0000: begin
            row_data_fifo_1[write_pointer] <= S_AXIS_TDATA;
          end
          4'b0001: begin
            row_data_fifo_2[write_pointer] <= S_AXIS_TDATA;
          end
          4'b0011: begin
            row_data_fifo_3[write_pointer] <= S_AXIS_TDATA;
          end          
          4'b0111: begin
            row_data_fifo_4[write_pointer] <= S_AXIS_TDATA;
          end
          4'b1110: begin
            row_data_fifo_1[write_pointer] <= S_AXIS_TDATA;
          end
          4'b1101: begin
            row_data_fifo_2[write_pointer] <= S_AXIS_TDATA;
          end	
          4'b1011: begin
            row_data_fifo_3[write_pointer] <= S_AXIS_TDATA;
          end    	       
        endcase
      end
	end 

	always @( posedge S_AXIS_ACLK ) begin
	    
        if(!S_AXIS_ARESETN || !SOFT_NRESET_SIGNAL) begin
           data_row_count_prev <= 0;
           process_begin       <= 1'b0;
        end
        
        if (process_done) begin
            process_begin <= 1'b0;
        end
        
        if (data_row_count >= 3 && writes_done) begin
            process_begin <= 1'b1;
        end
        else begin 
            data_row_count_prev   <= data_row_count;
            
        end
	end

	reg  [C_S_AXIS_TDATA_WIDTH-1:0] data_in_1;
	reg  [C_S_AXIS_TDATA_WIDTH-1:0] data_in_2;
	reg  [C_S_AXIS_TDATA_WIDTH-1:0] data_in_3;
	reg  [C_S_AXIS_TDATA_WIDTH-1:0] data_in_4;
	reg  [C_S_AXIS_TDATA_WIDTH-1:0] data_in_5;
	reg  [C_S_AXIS_TDATA_WIDTH-1:0] data_in_6;
	reg  [C_S_AXIS_TDATA_WIDTH-1:0] data_in_7;
	reg  [C_S_AXIS_TDATA_WIDTH-1:0] data_in_8;
	reg  [C_S_AXIS_TDATA_WIDTH-1:0] data_in_9;

    always @(*) begin
        if(!process_begin) begin
            data_row_filled_copy <= data_row_filled;
        end
    end
    
	always @( posedge S_AXIS_ACLK ) begin
        case (data_row_filled_copy)     
          4'b0111: begin
            data_in_1 <= row_data_fifo_1[process_pointer];
            data_in_2 <= row_data_fifo_1[process_pointer + 1];
            data_in_3 <= row_data_fifo_1[process_pointer + 2];
            data_in_4 <= row_data_fifo_2[process_pointer];
            data_in_5 <= row_data_fifo_2[process_pointer + 1];
            data_in_6 <= row_data_fifo_2[process_pointer + 2];
            data_in_7 <= row_data_fifo_3[process_pointer];
            data_in_8 <= row_data_fifo_3[process_pointer + 1];
            data_in_9 <= row_data_fifo_3[process_pointer + 2];
          end
          4'b1110: begin
            data_in_1 <= row_data_fifo_2[process_pointer];
            data_in_2 <= row_data_fifo_2[process_pointer + 1];
            data_in_3 <= row_data_fifo_2[process_pointer + 2];
            data_in_4 <= row_data_fifo_3[process_pointer];
            data_in_5 <= row_data_fifo_3[process_pointer + 1];
            data_in_6 <= row_data_fifo_3[process_pointer + 2];
            data_in_7 <= row_data_fifo_4[process_pointer];
            data_in_8 <= row_data_fifo_4[process_pointer + 1];
            data_in_9 <= row_data_fifo_4[process_pointer + 2];
          end
          4'b1101: begin
            data_in_1 <= row_data_fifo_3[process_pointer];
            data_in_2 <= row_data_fifo_3[process_pointer + 1];
            data_in_3 <= row_data_fifo_3[process_pointer + 2];
            data_in_4 <= row_data_fifo_4[process_pointer];
            data_in_5 <= row_data_fifo_4[process_pointer + 1];
            data_in_6 <= row_data_fifo_4[process_pointer + 2];
            data_in_7 <= row_data_fifo_1[process_pointer];
            data_in_8 <= row_data_fifo_1[process_pointer + 1];
            data_in_9 <= row_data_fifo_1[process_pointer + 2];
          end	
          4'b1011: begin
            data_in_1 <= row_data_fifo_4[process_pointer];
            data_in_2 <= row_data_fifo_4[process_pointer + 1];
            data_in_3 <= row_data_fifo_4[process_pointer + 2];
            data_in_4 <= row_data_fifo_1[process_pointer];
            data_in_5 <= row_data_fifo_1[process_pointer + 1];
            data_in_6 <= row_data_fifo_1[process_pointer + 2];
            data_in_7 <= row_data_fifo_2[process_pointer];
            data_in_8 <= row_data_fifo_2[process_pointer + 1];
            data_in_9 <= row_data_fifo_2[process_pointer + 2];
          end    	       
        endcase
	end 
		
    assign out_data       = (CELL_SELECT_CONFIG[31] == 1'b1)?  CNN_out_data       : MaxPool_out_data;
    assign out_data_valid = (CELL_SELECT_CONFIG[31] == 1'b1)?  CNN_out_data_valid : MaxPool_out_data_valid;

    always @(posedge S_AXIS_ACLK ) begin
        if(!S_AXIS_ARESETN || !SOFT_NRESET_SIGNAL) begin
            process_pointer <= 0;
            process_done    <= 1'b0;
        end else begin
            if (process_pointer == config_out_row_count - 3) begin
                process_pointer <= 0;
                process_done    <= 1'b1;
            end else if (process_begin && M_AXIS_TREADY && !process_done) begin
                process_pointer <= process_pointer + 1;                
            end
            else begin
                process_done    <= 1'b0;
            end
        end
    end
    
    maxpooling_cell #(
        .DATA_WIDTH(C_S_AXIS_TDATA_WIDTH)
    )maxpooling_cell_inst(
        .C_IN_CLK(S_AXIS_ACLK),
        .C_IN_RST(!S_AXIS_ARESETN),
        .C_IN_DATA_VALID(process_begin),
        .D_IN_DATA_1(data_in_1),
        .D_IN_DATA_2(data_in_2),
        .D_IN_DATA_3(data_in_3),
        .D_IN_DATA_4(data_in_4),
        .D_IN_DATA_5(data_in_5),
        .D_IN_DATA_6(data_in_6),
        .D_IN_DATA_7(data_in_7),
        .D_IN_DATA_8(data_in_8),
        .D_IN_DATA_9(data_in_9),
        .C_OUT_DATA_VALID(MaxPool_out_data_valid),
        .C_OUT_DATA(MaxPool_out_data)
    );

    conv_cell #(
        .DATA_WIDTH(C_S_AXIS_TDATA_WIDTH),
        .KERNAL_SIZE(3)
    ) conv_cell_inst (
        .C_IN_CLK(S_AXIS_ACLK),
        .C_IN_RST(!S_AXIS_ARESETN),
        .C_IN_DATA_VALID(process_begin),
        .D_IN_BIAS(D_IN_BIAS),
        .D_IN_KERNAL_1(D_IN_KERNAL_1),
        .D_IN_KERNAL_2(D_IN_KERNAL_2),
        .D_IN_KERNAL_3(D_IN_KERNAL_3),
        .D_IN_KERNAL_4(D_IN_KERNAL_4),
        .D_IN_KERNAL_5(D_IN_KERNAL_5),
        .D_IN_KERNAL_6(D_IN_KERNAL_6),
        .D_IN_KERNAL_7(D_IN_KERNAL_7),
        .D_IN_KERNAL_8(D_IN_KERNAL_8),
        .D_IN_KERNAL_9(D_IN_KERNAL_9),
        .D_IN_DATA_1(data_in_1),
        .D_IN_DATA_2(data_in_2),
        .D_IN_DATA_3(data_in_3),
        .D_IN_DATA_4(data_in_4),
        .D_IN_DATA_5(data_in_5),
        .D_IN_DATA_6(data_in_6),
        .D_IN_DATA_7(data_in_7),
        .D_IN_DATA_8(data_in_8),
        .D_IN_DATA_9(data_in_9),
        .C_OUT_DATA_VALID(CNN_out_data_valid),
        .C_OUT_DATA(CNN_out_data)
    );

    reg process_done_delay_1;
    reg process_done_delay_2;
    
    always @(posedge S_AXIS_ACLK) begin
        if (!S_AXIS_ARESETN || !SOFT_NRESET_SIGNAL) begin 
            process_done_delay_1 <= 0;
            process_done_delay_2 <= 0;
        end else begin
            if (process_done) begin
                process_done_delay_1 <= process_done;
            end else if (process_done_delay_1) begin
                process_done_delay_2 <= process_done_delay_1;
                process_done_delay_1 <= 0;
            end else begin
                process_done_delay_2 <= 0;                
            end
        end
    end

    reg [bit_num-1:0] read_pointer; 
    master_fifo_out master_fifo_out_ins (
      .wr_rst_busy(),                          // output wire wr_rst_busy
      .rd_rst_busy(),                          // output wire rd_rst_busy
      .s_aclk(S_AXIS_ACLK),                    // input wire s_aclk
      .s_aresetn(S_AXIS_ARESETN),              // input wire s_aresetn
      .s_axis_tvalid(out_data_valid),   // input wire s_axis_tvalid
      .s_axis_tready(),                        // output wire s_axis_tready
      .s_axis_tdata(out_data),                 // input wire [31 : 0] s_axis_tdata
      .s_axis_tlast(process_done_delay_2),     // last data slave
      .m_axis_tvalid(M_AXIS_TVALID),      // output wire m_axis_tvalid
      .m_axis_tready(M_AXIS_TREADY),           // input wire m_axis_tready
      .m_axis_tdata(M_AXIS_TDATA),             // output wire [31 : 0] m_axis_tdata
      .m_axis_tlast(M_AXIS_TLAST)              // last data master
    );
    
    always @(negedge S_AXIS_ACLK) begin
        if (out_data_valid) begin
            row_data_out_fifo[read_pointer] <= out_data;
        end
    end
    
    always @(negedge S_AXIS_ACLK) begin
        if (!S_AXIS_ARESETN) begin
            out_data_valid_mready <= 1'b0;
            read_pointer          <= 1'b0;
        end else if (out_data_valid) begin 
            if(read_pointer >= (config_out_row_count - 2)) begin
                read_pointer           <= 1'b0;
                out_data_valid_mready  <= 1'b0;
            end else begin
                read_pointer <= read_pointer + 1;
                out_data_valid_mready  <= 1'b1;
            end
        end 
        else begin
            out_data_valid_mready  <= 1'b0;
        end
    end
    
endmodule