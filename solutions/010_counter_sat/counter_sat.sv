`timescale 1ns/1ps
// 思路：异步复位放在敏感列表里（posedge rst），同步清零放在时钟分支里并且优先于 en。
//   计满保持：只有 en && cnt != 最大值 时才加 1。
// 追问：
//   1. 同步复位：只在时钟沿生效，不怕复位信号上的毛刺，时序分析简单，但需要时钟在跑、
//      复位会占用数据通路的逻辑；异步复位：不依赖时钟、省数据通路逻辑，但释放时可能亚稳态，
//      需要"异步复位同步释放"（第 013 题），且要做 recovery/removal 检查。
//   2. full_q <= 下一拍的 cnt 是否等于最大值：(clr) ? 0 : (en && cnt == MAX-1) ? 1 : full_q。
//   3. 拆分成高低两段，低段的进位寄存一拍再给高段（流水计数器），或者用超前进位。
module counter_sat #(parameter int W = 4) (
  input  logic         clk,
  input  logic         rst,
  input  logic         clr,
  input  logic         en,
  output logic [W-1:0] cnt,
  output logic         full
);
  assign full = &cnt;

  always_ff @(posedge clk or posedge rst)
    if (rst)               cnt <= '0;
    else if (clr)          cnt <= '0;
    else if (en && !full)  cnt <= cnt + 1'b1;
endmodule
