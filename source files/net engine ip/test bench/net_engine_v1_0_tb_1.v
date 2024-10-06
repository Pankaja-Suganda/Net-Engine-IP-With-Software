`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/08/2024 06:21:41 PM
// Design Name: Net Engine
// Module Name: net_engine_v1_0_tb_1
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


module net_engine_v1_0_tb_1();

    // Parameters
    parameter integer C_S00_AXI_DATA_WIDTH   = 32;
    parameter integer C_S00_AXI_ADDR_WIDTH   = 7;
    parameter integer C_S00_AXIS_TDATA_WIDTH = 32;
    parameter integer C_M00_AXIS_TDATA_WIDTH = 32;
    parameter integer C_M00_AXIS_START_COUNT = 16;
    parameter integer C_NET_CELL_COUNT       = 100;

    // Signals
    reg s00_axi_aclk;
    reg s00_axi_aresetn;
    reg [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr;
    reg [2 : 0] s00_axi_awprot;
    reg s00_axi_awvalid;
    wire s00_axi_awready;
    reg [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata;
    reg [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb;
    reg s00_axi_wvalid;
    wire s00_axi_wready;
    wire [1 : 0] s00_axi_bresp;
    wire s00_axi_bvalid;
    reg s00_axi_bready;
    reg [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr;
    reg [2 : 0] s00_axi_arprot;
    reg s00_axi_arvalid;
    wire s00_axi_arready;
    wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata;
    wire [1 : 0] s00_axi_rresp;
    wire s00_axi_rvalid;
    reg s00_axi_rready;

    reg s00_axis_aclk;
    reg s00_axis_aresetn;
    wire s00_axis_tready;
    reg [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata;
    reg [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb;
    reg s00_axis_tlast;
    reg s00_axis_tvalid;

    reg m00_axis_aclk;
    reg m00_axis_aresetn;
    wire m00_axis_tvalid;
    wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata;
    wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb;
    wire m00_axis_tlast;
    reg m00_axis_tready;
    
    wire [31:0] OUT_READ_POINTER;
    wire [31:0] OUT_WRITE_POINTER;
    wire completed;
    wire S_WRITE_COMPLETE;
    wire [2:0] status;
    integer i, k;
    reg done;

    // Instantiate the Unit Under Test (UUT)
    net_engine_v1_0 # (
        .C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),
        .C_S00_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
        .C_M00_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
        .C_M00_AXIS_START_COUNT(C_M00_AXIS_START_COUNT),
        .C_NET_CELL_COUNT(C_NET_CELL_COUNT)
    ) uut (
        .s00_axi_aclk(s00_axi_aclk),
        .s00_axi_aresetn(s00_axi_aresetn),
        .s00_axi_awaddr(s00_axi_awaddr),
        .s00_axi_awprot(s00_axi_awprot),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata(s00_axi_wdata),
        .s00_axi_wstrb(s00_axi_wstrb),
        .s00_axi_wvalid(s00_axi_wvalid),
        .s00_axi_wready(s00_axi_wready),
        .s00_axi_bresp(s00_axi_bresp),
        .s00_axi_bvalid(s00_axi_bvalid),
        .s00_axi_bready(s00_axi_bready),
        .s00_axi_araddr(s00_axi_araddr),
        .s00_axi_arprot(s00_axi_arprot),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready),
        .s00_axi_rdata(s00_axi_rdata),
        .s00_axi_rresp(s00_axi_rresp),
        .s00_axi_rvalid(s00_axi_rvalid),
        .s00_axi_rready(s00_axi_rready),
        .s00_axis_aclk(s00_axis_aclk),
        .s00_axis_aresetn(s00_axis_aresetn),
        .s00_axis_tready(s00_axis_tready),
        .s00_axis_tdata(s00_axis_tdata),
        .s00_axis_tstrb(s00_axis_tstrb),
        .s00_axis_tlast(s00_axis_tlast),
        .s00_axis_tvalid(s00_axis_tvalid),
        .m00_axis_aclk(m00_axis_aclk),
        .m00_axis_aresetn(m00_axis_aresetn),
        .m00_axis_tvalid(m00_axis_tvalid),
        .m00_axis_tdata(m00_axis_tdata),
        .m00_axis_tstrb(m00_axis_tstrb),
        .m00_axis_tlast(m00_axis_tlast),
        .m00_axis_tready(m00_axis_tready),
        .S_WRITE_COMPLETE(S_WRITE_COMPLETE),
		.DEBUG_WRITE_POINTER(OUT_WRITE_POINTER),
		.DEBUG_READ_POINTER(OUT_READ_POINTER)
    );

    // Clock generation
    always #5 s00_axi_aclk = ~s00_axi_aclk;
    always #5 s00_axis_aclk = ~s00_axis_aclk;
    always #5 m00_axis_aclk = ~m00_axis_aclk;
    
    integer ifile, ofile;
    reg [7:0] imgData;
    integer sentSize;
    integer receiveSize;
    integer row;
    integer j;
    initial begin
        // Initialize Inputs
        s00_axi_aclk = 0;
        s00_axi_aresetn = 0;
        s00_axi_awaddr = 0;
        s00_axi_awprot = 0;
        s00_axi_awvalid = 0;
        s00_axi_wdata = 0;
        s00_axi_wstrb = 0;
        s00_axi_wvalid = 0;
        s00_axi_bready = 0;
        s00_axi_araddr = 0;
        s00_axi_arprot = 0;
        s00_axi_arvalid = 0;
        s00_axi_rready = 0;

        s00_axis_aclk = 0;
        s00_axis_aresetn = 0;
        s00_axis_tdata = 0;
        s00_axis_tstrb = 0;
        s00_axis_tlast = 0;
        s00_axis_tvalid = 0;

        m00_axis_aclk = 0;
        m00_axis_aresetn = 0;
        m00_axis_tready = 0;

        // Reset sequence
        #100;
        s00_axi_aresetn = 1;
        s00_axis_aresetn = 1;
        m00_axis_aresetn = 1;
        
        done = 0;

        ofile = $fopen("test.txt", "wb");
        
        m00_axis_tready = 1;
        #100;
        s00_axis_tvalid = 1;
        
//        axis_slave_write({32'b0});
        for(j=0;j<101;j=j+1) begin
            for(i=0;i<101;i=i+1) begin
//                axis_slave_write({24'b0, i});   
                axis_slave_write(int_to_float(i));  
            end
            if (j > 3) begin
                @(posedge S_WRITE_COMPLETE);
            end
        end
        m00_axis_tready = 0;
        s00_axis_tvalid = 0;
        done = 1;
        
    end
        

//        ifile = $fopen("lena_gray.bmp", "rb");
//        ofile = $fopen("test.txt", "wb");
//        for(i=0;i<1080;i=i+1) begin
//            $fscanf(ifile,"%c",imgData);
//            $fwrite(ofile,"%c",imgData);
//        end
//        // Wait for reset to be released
//        #100;
//        m00_axis_tready = 1;
//        s00_axis_tvalid = 1;
//        // first 300 data
//        for ( k = 0; k <= 3*512; k = k + 1) begin
//            $fscanf(ifile,"%c",imgData);
//            axis_slave_write({24'h0, imgData});    
//        end
//        sentSize = 3 * 512;
//        @(posedge s00_axis_aclk);
//        s00_axis_tvalid = 0;
        
//        while(sentSize < (512*512)) begin
//            @(posedge S_WRITE_COMPLETE);
//            s00_axis_tvalid = 1;
//            for ( k = 0; k <= 512; k = k + 1) begin
//                $fscanf(ifile,"%c",imgData);
//                axis_slave_write({24'h0, imgData});    
//            end
//            s00_axis_tvalid = 0;
//            sentSize = sentSize + 512;
//            row = row + 1;
//        end
        
//        @(posedge s00_axis_aclk);
//        @(posedge S_WRITE_COMPLETE);
////        for ( k = 0; k <= 512; k = k + 1) begin
////            axis_slave_write({24'h0, 0});    
////        end
//        @(posedge s00_axis_aclk);
        
////        for ( k = 0; k <= 5; k = k + 1) begin
////            s00_axis_tvalid = 1;
////            for ( i = 0; i < 100; i = i + 1) begin;
////                axis_slave_write({24'h0, i});
////            end
////            s00_axis_tvalid = 0;
////        end
//        m00_axis_tready = 0;
//        done = 1;
//        $fclose(ifile);
//    end

    always @(posedge s00_axis_aclk) begin
        if (m00_axis_tvalid) begin
            $fwrite(ofile, "%c%c%c%c", 
                m00_axis_tdata[31:24], 
                m00_axis_tdata[23:16], 
                m00_axis_tdata[15:8], 
                m00_axis_tdata[7:0]);
            receiveSize = receiveSize + 1;
        end
        if(done) begin 
            $fclose(ofile);
            $stop;
        end
    end

    // AXIS Slave Write Task
    task axis_slave_write(input [C_S00_AXIS_TDATA_WIDTH-1:0] data);
        begin
            @(posedge s00_axis_aclk);
//            wait (s00_axis_tready);
            s00_axis_tdata = data;
            s00_axis_tstrb = 4'b1111;
            s00_axis_tlast = 0;
            wait (s00_axis_tready);
            s00_axis_tstrb = 0;
            s00_axis_tlast = 0;
        end
    endtask
    
    // Function to convert integer to IEEE 754 floating-point
    function [31:0] int_to_float(input integer i);
        reg [31:0] result;
        reg [7:0] exponent;
        reg [23:0] mantissa;
        integer j;

        begin
            if (i == 0) begin
                result = 32'b0;
            end else begin
                // Determine the sign bit (0 for positive, 1 for negative)
                result[31] = (i < 0) ? 1 : 0;

                // If negative, take absolute value
                if (i < 0) i = -i;

                // Find the position of the most significant bit
                j = 31;
                while (i[j] == 0) j = j - 1;

                // Calculate exponent and mantissa
                exponent = j + 127;
                mantissa = (i << (31 - j)) >> 8;

                result[30:23] = exponent;
                result[22:0] = mantissa[22:0];
            end

            int_to_float = result;
        end
    endfunction

endmodule
