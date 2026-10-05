`timescale 1ns/1ps
module thermo_check #(parameter int W = 8) (
  input  logic [W-1:0] in,
  output logic         is_thermo
);
  // TODO: 在这里写你的实现
  assign is_thermo = 1'b0;
endmodule
