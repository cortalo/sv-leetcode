`timescale 1ns/1ps
module thermo2bin #(parameter int W = 15) (
  input  logic [W-1:0]           thermo,
  output logic [$clog2(W+1)-1:0] bin,
  output logic                   valid
);
  // TODO: 在这里写你的实现
  assign bin   = '0;
  assign valid = 1'b0;
endmodule
