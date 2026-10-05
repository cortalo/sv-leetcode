`timescale 1ns/1ps
module gray_code #(parameter int W = 8) (
  input  logic [W-1:0] bin_i,
  output logic [W-1:0] gray_o,
  input  logic [W-1:0] gray_i,
  output logic [W-1:0] bin_o
);
  // TODO: 在这里写你的实现
  assign gray_o = '0;
  assign bin_o  = '0;
endmodule
