`timescale 1ns/1ps
module cdc_handshake #(parameter int W = 8) (
  input  logic         clk_a,
  input  logic         rst_a_n,
  input  logic         a_valid,
  output logic         a_ready,
  input  logic [W-1:0] a_data,
  input  logic         clk_b,
  input  logic         rst_b_n,
  output logic         b_valid,
  output logic [W-1:0] b_data
);
  // TODO: 在这里写你的实现
  assign a_ready = 1'b0;
  assign b_valid = 1'b0;
  assign b_data  = '0;
endmodule
