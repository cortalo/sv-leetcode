`timescale 1ns/1ps
module traffic_light #(
  parameter int R = 5,
  parameter int G = 4,
  parameter int Y = 2
) (
  input  logic clk,
  input  logic rst_n,
  output logic red,
  output logic green,
  output logic yellow
);
  // TODO: 在这里写你的实现
  assign red    = 1'b1;
  assign green  = 1'b0;
  assign yellow = 1'b0;
endmodule
