`timescale 1ns/1ps
module clk_div_even #(parameter int N = 4) (
  input  logic clk,
  input  logic rst_n,
  output logic clk_out
);
  // TODO: 在这里写你的实现
  assign clk_out = 1'b0;
endmodule
