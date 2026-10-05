`timescale 1ns/1ps
// 思路：Moore 状态机，状态表示"已经匹配到目标序列的前几位"。
//   IDLE   ：什么都没匹配     din=1→S1      din=0→IDLE
//   S1  "1"：                 din=0→S10     din=1→S1
//   S10 "10"：                din=1→S101    din=0→IDLE
//   S101 "101"：              din=1→S1011   din=0→S10   ("1010" 的后缀 "10" 仍是前缀)
//   S1011 "1011"：            din=0→MATCH   din=1→S1    ("10111" 只剩后缀 "1")
//   MATCH "10110"：输出 1     din=1→S101    din=0→IDLE  (重叠：后缀 "10"+"1" = "101")
//   每个状态的跳转 = "当前已匹配串 + 新输入" 的最长后缀，同时也是目标序列的前缀（KMP 的思想）。
// 追问：
//   1. 不重叠：MATCH 之后不复用后缀，din=1→S1，din=0→IDLE。
//   2. Moore 需要 序列长度+1 = 6 个状态，输出只取决于状态，比 Mealy 晚一拍；
//      Mealy 只要 5 个状态，match = (state==S1011 && din==0)，组合输出、同一拍有效。
//   3. 移位寄存器：sh <= {sh[3:0], din}; match <= ({sh[3:0], din} == 5'b10110);
//      写起来简单、改序列方便，但寄存器数 = 序列长度；状态机只要 log2(状态数) 个寄存器。
//   4. 三段式：状态寄存器（时序）+ 次态逻辑（组合）+ 输出逻辑（时序或组合），结构清晰、
//      输出可以寄存避免毛刺，是最推荐的写法；下面就是三段式。
module seq_detect (
  input  logic clk,
  input  logic rst_n,
  input  logic din,
  output logic match
);
  typedef enum logic [2:0] {IDLE, S1, S10, S101, S1011, MATCH} state_t;
  state_t state, next;

  // 1) 状态寄存器
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) state <= IDLE;
    else        state <= next;

  // 2) 次态逻辑
  always_comb begin
    case (state)
      IDLE:    if (din) next = S1; else next = IDLE;
      S1:      if (din) next = S1; else next = S10;
      S10:     if (din) next = S101; else next = IDLE;
      S101:    if (din) next = S1011; else next = S10;
      S1011:   if (din) next = S1; else next = MATCH;
      MATCH:   if (din) next = S101; else next = IDLE;
      default: next = IDLE;
    endcase
  end

  // 3) 输出逻辑（Moore：只取决于当前状态）
  assign match = (state == MATCH);
endmodule
