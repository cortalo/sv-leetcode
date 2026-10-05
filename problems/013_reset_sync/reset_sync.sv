`timescale 1ns/1ps
module reset_sync (
  input  logic clk,
  input  logic arst_n,
  output logic rst_n_sync
);
  // TODO: 在这里写你的实现
  assign rst_n_sync = 1'b0;
endmodule
