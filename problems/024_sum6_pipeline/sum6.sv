`timescale 1ns/1ps
module sum6 (
  input  logic             clk,
  input  logic             rst_n,
  input  logic             in_valid,
  output logic             in_ready,
  input  logic [5:0][31:0] in_data,
  output logic             out_valid,
  input  logic             out_ready,
  output logic [31:0]      out_sum
);
  // TODO: 在这里写你的实现
  assign in_ready  = 1'b0;
  assign out_valid = 1'b0;
  assign out_sum   = '0;
endmodule
