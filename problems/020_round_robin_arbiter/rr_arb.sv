`timescale 1ns/1ps
module rr_arb #(parameter int N = 4) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic [N-1:0] req,
  output logic [N-1:0] gnt
);
  // TODO: 在这里写你的实现
  assign gnt = '0;
endmodule
