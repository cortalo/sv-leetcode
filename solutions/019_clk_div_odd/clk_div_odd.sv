`timescale 1ns/1ps
// 思路：上升沿计数器 cnt 循环 0..N-1；
//   p：上升沿寄存器，在 cnt 的前 (N-1)/2 拍为高 → 高电平 (N-1)/2 个周期；
//   n：下降沿寄存器，n <= p，即 p 延迟半个周期；
//   clk_out = p | n → 高电平 (N-1)/2 + 0.5 = N/2 个周期，占空比 50%。
//   （也可以 p 高 (N+1)/2 拍，然后用 p & n，得到同样结果。）
// 追问：
//   1. 只用上升沿时，所有边沿都对齐 clk 上升沿，高电平只能是整数个周期，N 为奇数时做不到 N/2。
//   2. p 下降时 n 仍为高，n 上升时 p 已为高，两个输入不会同时翻转，或门输出无毛刺。
//      但它仍是组合逻辑产生的时钟，实际芯片里要用专门的时钟单元并约束好。
//   3. 不是。下降沿相对上升沿的位置决定了半周期的长度，输入占空比偏多少，输出就偏多少。
//   4. 2.5 分频：计数 0..4 产生 5 分频的两个错开半周期的脉冲，再合成 —— 输出占空比通常不是 50%。
module clk_div_odd #(parameter int N = 3) (
  input  logic clk,
  input  logic rst_n,
  output logic clk_out
);
  localparam int CW = $clog2(N);
  localparam int H  = (N - 1) / 2;

  logic [CW-1:0] cnt, cnt_nxt;
  logic          p, n;

  assign cnt_nxt = (cnt == CW'(N - 1)) ? '0 : cnt + 1'b1;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      cnt <= '0;
      p   <= 1'b0;
    end else begin
      cnt <= cnt_nxt;
      p   <= (cnt_nxt < CW'(H));
    end

  always_ff @(negedge clk or negedge rst_n)
    if (!rst_n) n <= 1'b0;
    else        n <= p;

  assign clk_out = p | n;
endmodule
