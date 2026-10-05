`timescale 1ns/1ps
module clk_switch (
  input  logic clk0,
  input  logic clk1,
  input  logic rst_n,
  input  logic sel,
  output logic clk_out
);
  // TODO: 在这里写你的实现
  assign clk_out = 1'b0;
endmodule
