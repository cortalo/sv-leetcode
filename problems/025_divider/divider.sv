`timescale 1ns/1ps
module divider #(parameter int W = 8) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start,
  input  logic [W-1:0] dividend,
  input  logic [W-1:0] divisor,
  output logic         busy,
  output logic         done,
  output logic [W-1:0] quotient,
  output logic [W-1:0] remainder
);
  // TODO: 在这里写你的实现
  assign busy      = 1'b0;
  assign done      = 1'b0;
  assign quotient  = '0;
  assign remainder = '0;
endmodule
