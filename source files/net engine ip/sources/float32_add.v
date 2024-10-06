`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/18/2024
// Design Name: 
// Module Name: float32_add
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 32-bit floating point addition module based on IEEE 754 standard
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module float32_add(
        input             in_clk,
        input      [31:0] in_A,
        input      [31:0] in_B,
        input             in_valid,
        output     [31:0] out_result
    );
    
    // wrapper for the adder
    floating_point_0 adder (
      .aclk(in_clk),                                  // input wire aclk
      .s_axis_a_tvalid(in_valid),            // input wire s_axis_a_tvalid
      .s_axis_a_tdata(in_A),              // input wire [31 : 0] s_axis_a_tdata
      .s_axis_b_tvalid(in_valid),            // input wire s_axis_b_tvalid
      .s_axis_b_tdata(in_B),              // input wire [31 : 0] s_axis_b_tdata
      .m_axis_result_tvalid(),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata(out_result)    // output wire [31 : 0] m_axis_result_tdata
    );
    
endmodule
