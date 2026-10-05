`timescale 1ns/1ps
module lead_one #(parameter int W = 16) (
  input  logic [W-1:0]         in,
  output logic [$clog2(W)-1:0] idx,
  output logic                 valid
);
  // TODO: 在这里写你的实现
  assign idx   = '0;
  assign valid = 1'b0;
endmodule
