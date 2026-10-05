`timescale 1ns/1ps
module vending (
  input  logic       clk,
  input  logic       rst_n,
  input  logic [1:0] coin,
  output logic       drink,
  output logic       change
);
  // TODO: 在这里写你的实现
  assign drink  = 1'b0;
  assign change = 1'b0;
endmodule
