`timescale 1ns/1ps
module fixed_arb #(parameter int N = 8) (
  input  logic [N-1:0] req,
  output logic [N-1:0] gnt
);
  // TODO: 在这里写你的实现
  assign gnt = '0;
endmodule
