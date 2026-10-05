`timescale 1ns/1ps
module first_last_one #(parameter int W = 16) (
  input  logic [W-1:0] in,
  output logic [W-1:0] first_oh,
  output logic [W-1:0] last_oh
);
  // TODO: 在这里写你的实现
  assign first_oh = '0;
  assign last_oh  = '0;
endmodule
