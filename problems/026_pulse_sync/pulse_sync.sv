`timescale 1ns/1ps
module pulse_sync (
  input  logic clk_a,
  input  logic rst_a_n,
  input  logic pulse_a,
  input  logic clk_b,
  input  logic rst_b_n,
  output logic pulse_b
);
  // TODO: 在这里写你的实现
  assign pulse_b = 1'b0;
endmodule
