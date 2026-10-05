`timescale 1ns/1ps
// 思路（掩码法）：用独热码 prio 记录当前最高优先级的位置（复位为 ...0001）。
//   mask       = ~(prio - 1)          // prio 及其以上的位为 1
//   req_masked = req & mask           // 只看优先级 >= 当前起点的请求
//   有 req_masked 时，对 req_masked 做固定优先级仲裁（取最低位的 1）；
//   否则（起点以上没人请求，绕回来）对整个 req 做固定优先级仲裁。
//   授权 g 之后：prio <= g 循环左移一位（g 的下一位成为最高优先级）。
// 追问：
//   1. 方法二（双倍长度）：d = {req, req}; g2 = d & ~(d - prio); gnt = g2[N-1:0] | g2[2N-1:N]。
//      减法会从 prio 位置开始向上借位，找到 >= 起点的第一个 1，超出 N 位的部分折回来。
//   2. 关键路径是固定优先级仲裁（借位链 / 前缀或）+ 选择 + prio 更新。N 大时用并行前缀（log 级）结构，
//      或者分组：先在组内仲裁，再在组间轮询（两级仲裁）。
//   3. 只在 "被授权者撤销请求" 时才更新 prio；或者加一个 lock 信号，lock 期间保持 gnt。
//   4. 加权：每个请求者一个计数器，授权次数达到权重才把优先级让给下一个。
module rr_arb #(parameter int N = 4) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic [N-1:0] req,
  output logic [N-1:0] gnt
);
  logic [N-1:0] prio, mask, req_masked, gnt_masked, gnt_plain;

  assign mask       = ~(prio - 1'b1);
  assign req_masked = req & mask;
  assign gnt_masked = req_masked & (~req_masked + 1'b1);
  assign gnt_plain  = req & (~req + 1'b1);
  assign gnt        = (|req_masked) ? gnt_masked : gnt_plain;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)    prio <= {{(N-1){1'b0}}, 1'b1};
    else if (|req) prio <= {gnt[N-2:0], gnt[N-1]};
endmodule
