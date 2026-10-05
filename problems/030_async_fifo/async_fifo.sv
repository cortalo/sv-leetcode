`timescale 1ns/1ps
module async_fifo #(
  parameter int W  = 8,
  parameter int AW = 4
) (
  input  logic         wclk,
  input  logic         wrst_n,
  input  logic         winc,
  input  logic [W-1:0] wdata,
  output logic         wfull,
  input  logic         rclk,
  input  logic         rrst_n,
  input  logic         rinc,
  output logic [W-1:0] rdata,
  output logic         rempty
);
  // TODO: 在这里写你的实现
  assign wfull  = 1'b1;
  assign rempty = 1'b1;
  assign rdata  = '0;
endmodule
