`timescale 1ns/1ps
// 思路：每个时钟一个使能 en0 / en1，clk_out = (clk0 & en0) | (clk1 & en1)。
//   1) 互锁：clk0 的使能只有在 en1 已经关掉之后才能打开（~sel & ~en1），反之亦然 → 先关后开，不会两路同时输出。
//   2) 同步：sel 和对方的 en 都与本时钟异步，先在本时钟上升沿打一拍（第一级同步）……
//   3) ……再在本时钟**下降沿**打一拍得到 en：en 只在时钟为低时变化，和 clk 相与就不会截断高电平。
//   切换过程：sel 变化 → 旧时钟在它的下降沿关闭 en → 新时钟同步到 "对方已关闭" → 新时钟在下降沿打开 en。
// 追问：
//   1. sel 变化的瞬间如果 clk0=1、clk1=0，输出会从高突然变低（截短的高脉冲）；或者 clk0=0、clk1=1 时
//      突然变高，产生窄脉冲，下游触发器可能误触发。
//   2. 在下降沿更新时，clk 正处于低电平，clk & en 的结果在 en 变化前后都是 0，不会产生毛刺；
//      如果在上升沿更新，en 的变化与 clk 的上升几乎同时，会产生窄脉冲。
//   3. 同步时钟不需要两级同步器（没有亚稳态问题），每路只需一个下降沿触发器 + 互锁。
//   4. 旧时钟停了，它的 en 永远关不掉，新时钟永远等不到 → 切换卡死。
//      解决：带超时的强制切换、或者用可以检测时钟丢失的电路（clock monitor）。
//   5. 两侧根据 "对方是否已关闭" 做决定，但看到的是同步后（晚几拍）的状态。如果 sel 在一侧正在打开、
//      另一侧还没察觉时又翻回去，两侧可能都认为对方已关闭而同时打开，产生毛刺。
//      所以 sel 必须在一次切换完成后才能再变（或者在 sel 前面加一级状态机，忙时忽略新的请求）。
//   实际芯片中这里要用标准单元库里的时钟门控 / 时钟选择单元，并做好约束。
module clk_switch (
  input  logic clk0,
  input  logic clk1,
  input  logic rst_n,
  input  logic sel,
  output logic clk_out
);
  logic s0, en0, s1, en1;

  // clk0 一侧
  always_ff @(posedge clk0 or negedge rst_n)
    if (!rst_n) s0 <= 1'b0;
    else        s0 <= ~sel & ~en1;
  always_ff @(negedge clk0 or negedge rst_n)
    if (!rst_n) en0 <= 1'b0;
    else        en0 <= s0;

  // clk1 一侧
  always_ff @(posedge clk1 or negedge rst_n)
    if (!rst_n) s1 <= 1'b0;
    else        s1 <= sel & ~en0;
  always_ff @(negedge clk1 or negedge rst_n)
    if (!rst_n) en1 <= 1'b0;
    else        en1 <= s1;

  assign clk_out = (clk0 & en0) | (clk1 & en1);
endmodule
