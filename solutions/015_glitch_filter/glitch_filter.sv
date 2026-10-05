`timescale 1ns/1ps
// 思路：用两个寄存器保存前两次采样 s1、s2，加上本次的 din 共三次。
//   三者相同时 dout <= din（三者相同且等于 dout 时赋值不变，所以不用额外判断）。
// 追问：
//   1. 参数化：用计数器记录 "din 与 dout 不同" 连续了多少拍，达到 K+1 时翻转 dout，
//      期间只要 din 回到 dout 的值就清零计数器。寄存器数从 K 降到 log2(K)。
//   2. 异步输入：先两级同步（第 009/013 题），再做滤波/消抖，最后边沿检测。
//   3. 20ms × 50MHz = 1,000,000 拍，需要 20 bit 计数器。
module glitch_filter (
  input  logic clk,
  input  logic rst_n,
  input  logic din,
  output logic dout
);
  logic s1, s2;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      s1 <= 1'b0; s2 <= 1'b0; dout <= 1'b0;
    end else begin
      s1 <= din;
      s2 <= s1;
      if (din == s1 && s1 == s2) dout <= din;
    end
endmodule
