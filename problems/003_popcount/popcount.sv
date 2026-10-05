`timescale 1ns/1ps
module popcount #(parameter int W = 16) (
  input  logic [W-1:0]           in,
  output logic [$clog2(W+1)-1:0] cnt
);
  // TODO: 在这里写你的实现
  assign cnt = '0;
endmodule
