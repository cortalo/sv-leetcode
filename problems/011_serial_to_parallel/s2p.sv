`timescale 1ns/1ps
module s2p (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       din,
  input  logic       din_valid,
  output logic [7:0] dout,
  output logic       dout_valid
);
  // TODO: 在这里写你的实现
  assign dout       = '0;
  assign dout_valid = 1'b0;
endmodule
