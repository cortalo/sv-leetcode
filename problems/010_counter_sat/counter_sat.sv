`timescale 1ns/1ps
module counter_sat #(parameter int W = 4) (
  input  logic         clk,
  input  logic         rst,
  input  logic         clr,
  input  logic         en,
  output logic [W-1:0] cnt,
  output logic         full
);
  // TODO: 在这里写你的实现
  assign cnt  = '0;
  assign full = 1'b0;
endmodule
