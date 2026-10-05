`timescale 1ns/1ps
// 思路：移位寄存器 + 计数器。
//   din_valid 时：sh <= {sh[6:0], din}，cnt <= cnt + 1；
//   cnt == 7 且 din_valid（第 8 个 bit 到来）时：dout <= {sh[6:0], din}，dout_valid <= 1。
//   注意第 8 个 bit 要直接拼进去，不能等它进 sh 之后再取（那样会晚一拍）。
// 追问：
//   1. LSB first：sh <= {din, sh[7:1]}。
//   2. 并转串：load 时把字节装进移位寄存器，busy 期间 ready=0，计满 8 位再拉高 ready。
//   3. 组合输出：dout = {sh[6:0], din}，dout_valid = din_valid && cnt == 7；输出会有组合路径，
//      下游时序更紧。
module s2p (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       din,
  input  logic       din_valid,
  output logic [7:0] dout,
  output logic       dout_valid
);
  logic [6:0] sh;
  logic [2:0] cnt;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      sh <= '0; cnt <= '0; dout <= '0; dout_valid <= 1'b0;
    end else begin
      dout_valid <= 1'b0;
      if (din_valid) begin
        sh  <= {sh[5:0], din};
        cnt <= cnt + 1'b1;               // 3 bit，计到 7 后自然回到 0
        if (cnt == 3'd7) begin
          dout       <= {sh, din};
          dout_valid <= 1'b1;
        end
      end
    end
endmodule
