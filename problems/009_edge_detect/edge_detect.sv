`timescale 1ns/1ps
module edge_detect (
  input  logic clk,
  input  logic rst_n,
  input  logic din,
  output logic rise,
  output logic fall,
  output logic both
);
  // TODO: 在这里写你的实现
  assign rise = 1'b0;
  assign fall = 1'b0;
  assign both = 1'b0;
endmodule
