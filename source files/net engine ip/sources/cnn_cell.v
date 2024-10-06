`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/26/2024 05:39:35 PM
// Design Name: 
// Module Name: conv_cell
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

module conv_cell
#(
    parameter DATA_WIDTH  = 32,
    parameter KERNAL_SIZE = 3
)(
    // input ports
    input wire C_IN_CLK,
    input wire C_IN_RST,
    input wire C_IN_DATA_VALID,
    input wire [DATA_WIDTH-1:0] D_IN_BIAS,
    
    // input kernal 
    input wire [DATA_WIDTH-1:0]	D_IN_KERNAL_1,
    input wire [DATA_WIDTH-1:0]	D_IN_KERNAL_2,
    input wire [DATA_WIDTH-1:0]	D_IN_KERNAL_3,
    input wire [DATA_WIDTH-1:0]	D_IN_KERNAL_4,
    input wire [DATA_WIDTH-1:0]	D_IN_KERNAL_5,
    input wire [DATA_WIDTH-1:0]	D_IN_KERNAL_6,
    input wire [DATA_WIDTH-1:0]	D_IN_KERNAL_7,
    input wire [DATA_WIDTH-1:0]	D_IN_KERNAL_8,
    input wire [DATA_WIDTH-1:0]	D_IN_KERNAL_9,
    
    // input data
    input wire [DATA_WIDTH-1:0]	D_IN_DATA_1,
    input wire [DATA_WIDTH-1:0]	D_IN_DATA_2,
    input wire [DATA_WIDTH-1:0]	D_IN_DATA_3,
    input wire [DATA_WIDTH-1:0]	D_IN_DATA_4,
    input wire [DATA_WIDTH-1:0]	D_IN_DATA_5,
    input wire [DATA_WIDTH-1:0]	D_IN_DATA_6,
    input wire [DATA_WIDTH-1:0]	D_IN_DATA_7,
    input wire [DATA_WIDTH-1:0]	D_IN_DATA_8,
    input wire [DATA_WIDTH-1:0]	D_IN_DATA_9,
    // output ports
    output                 C_OUT_DATA_VALID,
    output[DATA_WIDTH-1:0] C_OUT_DATA
);

// internal params
integer sum_i, mul_i;

// Internal registers
wire [DATA_WIDTH-1:0] multiply_reg [(KERNAL_SIZE * KERNAL_SIZE) - 1:0];
wire [DATA_WIDTH-1:0] stage_1_sum_reg [4:0];
wire [DATA_WIDTH-1:0] stage_2_sum_reg [2:0];
wire [DATA_WIDTH-1:0] stage_3_sum_reg;
wire [DATA_WIDTH-1:0] o_data_reg;
wire [DATA_WIDTH-1:0] bias_stage_2_sum;
reg [DATA_WIDTH-1:0] o_data_reg_temp;

// Control registers
reg o_data_valid_reg;
reg o_data_valid_reg_delay;
reg multiply_data_valid;
reg sum_stage_1_data_valid;
reg sum_stage_2_data_valid;
reg sum_stage_3_data_valid;
reg sum_stage_4_data_valid;
wire adder_data_valid;

// Instantiate the multiplication modules
generate
    genvar i;
    for (i = 0; i < 9; i = i + 1) begin : gen_mult
        float32_multiply multiply_cell (
            .in_clk(C_IN_CLK),
            .in_A((i == 0) ? D_IN_DATA_1 : 
                  (i == 1) ? D_IN_DATA_2 : 
                  (i == 2) ? D_IN_DATA_3 : 
                  (i == 3) ? D_IN_DATA_4 : 
                  (i == 4) ? D_IN_DATA_5 : 
                  (i == 5) ? D_IN_DATA_6 : 
                  (i == 6) ? D_IN_DATA_7 : 
                  (i == 7) ? D_IN_DATA_8 : 
                             D_IN_DATA_9),
            .in_B((i == 0) ? D_IN_KERNAL_1 : 
                  (i == 1) ? D_IN_KERNAL_2 : 
                  (i == 2) ? D_IN_KERNAL_3 : 
                  (i == 3) ? D_IN_KERNAL_4 : 
                  (i == 4) ? D_IN_KERNAL_5 : 
                  (i == 5) ? D_IN_KERNAL_6 : 
                  (i == 6) ? D_IN_KERNAL_7 : 
                  (i == 7) ? D_IN_KERNAL_8 : 
                             D_IN_KERNAL_9),
            .in_valid(C_IN_DATA_VALID),
            .out_result(multiply_reg[i])
        );
    end
endgenerate

// Multiply operation
always @(posedge C_IN_CLK or posedge C_IN_RST) begin
    if (C_IN_RST) begin
        multiply_data_valid <= 0;
    end else if (C_IN_DATA_VALID) begin
        multiply_data_valid <= 1;
    end else begin
        multiply_data_valid <= 0;
    end
end

// Instantiate the addition modules
generate
    for (i = 0; i < 4; i = i + 1) begin : gen_add_s1
        float32_add adder_cell_s1 (
            .in_clk(C_IN_CLK),
            .in_A(multiply_reg[i * 2]),
            .in_B(multiply_reg[(i * 2) + 1]),
            .in_valid(multiply_data_valid || o_data_valid_reg),
            .out_result(stage_1_sum_reg[i])
        );
    end
endgenerate

float32_add adder_cell_s1_4 (
    .in_clk(C_IN_CLK),
    .in_A(multiply_reg[8]),
    .in_B(32'b0), // Adding zero for the last odd element
    .in_valid(sum_stage_1_data_valid || o_data_valid_reg),
    .out_result(stage_1_sum_reg[4])
);

// Sum operation stage 1
always @(posedge C_IN_CLK or posedge C_IN_RST) begin
    if (C_IN_RST) begin
        sum_stage_1_data_valid <= 0;
    end else if (multiply_data_valid) begin
        sum_stage_1_data_valid <= 1;
    end else begin
        sum_stage_1_data_valid <= 0;
    end
end

generate
    for (i = 0; i < 2; i = i + 1) begin : gen_add_s2
        float32_add adder_cell_s2 (
            .in_clk(C_IN_CLK),
            .in_A(stage_1_sum_reg[i * 2]),
            .in_B(stage_1_sum_reg[i * 2 + 1]),
            .in_valid(sum_stage_2_data_valid || o_data_valid_reg),
            .out_result(stage_2_sum_reg[i])
        );
    end
endgenerate

float32_add adder_cell_s2_2 (
    .in_clk(C_IN_CLK),
    .in_A(stage_1_sum_reg[4]),
    .in_B(32'b0), // Adding zero for the last odd element
    .in_valid(sum_stage_2_data_valid || o_data_valid_reg),
    .out_result(stage_2_sum_reg[2])
);

// Sum operation stage 2
always @(posedge C_IN_CLK) begin
    if (C_IN_RST) begin
        sum_stage_2_data_valid <= 0;
    end else if (sum_stage_1_data_valid) begin
        sum_stage_2_data_valid <= 1;
    end else begin
        sum_stage_2_data_valid <= 0;
    end
end

float32_add adder_cell_s3 (
    .in_clk(C_IN_CLK),
    .in_A(stage_2_sum_reg[0]),
    .in_B(stage_2_sum_reg[1]),
    .in_valid(sum_stage_3_data_valid || o_data_valid_reg),
    .out_result(stage_3_sum_reg)
);

// Sum operation stage 3
always @(posedge C_IN_CLK) begin
    if (C_IN_RST) begin
        sum_stage_3_data_valid <= 0;
    end else if (sum_stage_2_data_valid) begin
        sum_stage_3_data_valid <= 1;
    end else begin
        sum_stage_3_data_valid <= 0;
    end
end

float32_add adder_cell_bias (
    .in_clk(C_IN_CLK),
    .in_A(stage_2_sum_reg[2]),
    .in_B(D_IN_BIAS),
    .in_valid(sum_stage_3_data_valid || o_data_valid_reg),
    .out_result(bias_stage_2_sum)
);

// Sum operation stage 4
always @(posedge C_IN_CLK) begin
    if (C_IN_RST) begin
        sum_stage_4_data_valid <= 0;
    end else if (sum_stage_3_data_valid) begin
        sum_stage_4_data_valid <= 1;
    end else begin
        sum_stage_4_data_valid <= 0;
    end
end

float32_add adder_last (
    .in_clk(C_IN_CLK),
    .in_A(stage_3_sum_reg),
    .in_B(bias_stage_2_sum),
    .in_valid(sum_stage_4_data_valid || o_data_valid_reg),
    .out_result(o_data_reg)
);

// Sum operation
always @(posedge C_IN_CLK or posedge C_IN_RST) begin
    if (C_IN_RST) begin
        o_data_valid_reg <= 0;
    end else begin
        o_data_valid_reg <= sum_stage_4_data_valid;
    end
end

// output valid delay
always @(posedge C_IN_CLK or posedge C_IN_RST) begin
    if (C_IN_RST) begin
        o_data_valid_reg_delay <= 0;
    end else begin
        o_data_valid_reg_delay <= o_data_valid_reg;
    end
end

//// bit reversing
//integer j;
//always @(*) begin
//    for (j = 0; j < 4; j = j + 1) begin 
//        o_data_reg_temp[j*8 + 7] = o_data_reg[j*8 + 0];
//        o_data_reg_temp[j*8 + 6] = o_data_reg[j*8 + 1];
//        o_data_reg_temp[j*8 + 5] = o_data_reg[j*8 + 2];
//        o_data_reg_temp[j*8 + 4] = o_data_reg[j*8 + 3];
//        o_data_reg_temp[j*8 + 3] = o_data_reg[j*8 + 4];
//        o_data_reg_temp[j*8 + 2] = o_data_reg[j*8 + 5];
//        o_data_reg_temp[j*8 + 1] = o_data_reg[j*8 + 6];
//        o_data_reg_temp[j*8 + 0] = o_data_reg[j*8 + 7];
//    end
//end

// assigning
assign C_OUT_DATA       = o_data_reg;
assign C_OUT_DATA_VALID = o_data_valid_reg && sum_stage_4_data_valid;
//assign C_OUT_DATA       = { o_data_reg[7:0], 
//                            o_data_reg[15:8], 
//                            o_data_reg[23:16], 
//                            o_data_reg[31:24]};

endmodule
