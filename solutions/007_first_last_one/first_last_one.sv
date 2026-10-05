`timescale 1ns/1ps
// 思路：
//   first_oh = in & (~in + 1)   （同第 004 题固定优先级仲裁器：in & -in 只保留最低位的 1）
//   last_oh：加减法的进位只能从低往高传，所以不能直接用同样的技巧。两种办法：
//     (a) 位反转：把 in 前后颠倒 → 求最低位的 1 → 再颠倒回来。颠倒只是连线，不花逻辑。
//     (b) "抹平"：s = in | in>>1 | in>>2 | ...（log2(W) 步移位或），s 是从最高位的 1 往下全 1，
//         last_oh = s & ~(s >> 1)。
//   下面用 (a)。generate 里的 for 只是连线，不是逐位扫描的逻辑。
// 追问：
//   3. 串行输入：用计数器记当前拍号；first 寄存器在 "还没见过 1 且 din=1" 时锁存拍号；
//      last 寄存器在每次 din=1 时更新拍号。
module first_last_one #(parameter int W = 16) (
  input  logic [W-1:0] in,
  output logic [W-1:0] first_oh,
  output logic [W-1:0] last_oh
);
  logic [W-1:0] rev, rev_first;

  assign first_oh = in & (~in + 1'b1);

  genvar i;
  generate
    for (i = 0; i < W; i++) begin : g_rev
      assign rev[i]     = in[W-1-i];
      assign last_oh[i] = rev_first[W-1-i];
    end
  endgenerate
  assign rev_first = rev & (~rev + 1'b1);
endmodule
