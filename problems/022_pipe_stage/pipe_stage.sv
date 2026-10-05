`timescale 1ns/1ps
module pipe_stage #(parameter int W = 8) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         in_valid,
  output logic         in_ready,
  input  logic [W-1:0] in_data,
  output logic         out_valid,
  input  logic         out_ready,
  output logic [W-1:0] out_data
);
  // TODO: 在这里写你的实现
  assign in_ready  = 1'b0;
  assign out_valid = 1'b0;
  assign out_data  = '0;
endmodule
