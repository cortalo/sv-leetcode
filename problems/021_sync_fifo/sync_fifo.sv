`timescale 1ns/1ps
module sync_fifo #(
  parameter int W     = 8,
  parameter int DEPTH = 16
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         wr_en,
  input  logic [W-1:0] din,
  output logic         full,
  input  logic         rd_en,
  output logic [W-1:0] dout,
  output logic         empty
);
  // TODO: 在这里写你的实现
  assign full  = 1'b0;
  assign empty = 1'b1;
  assign dout  = '0;
endmodule
