`timescale 1ns/1ps
// 思路：找到 req 中最低位的 1 并保留它，其余清零。
//   gnt = req & (~req + 1)      // 即 req & -req（补码相与）
//   原理：~req + 1 会把 req 最低位的 1 以下的 0 全部变成 0、该位保持 1、其上所有位取反，
//        于是和 req 按位与只剩下最低位那个 1。
//   另一种等价写法：gnt = req & ~(req - 1)。
// 追问：
//   1. if/else if 链综合成优先级 MUX 链，延迟随 N 线性增长；补码写法本质是一个减法器（进位链），
//      综合器可以把它做成前缀树。也可以写成 "前缀或"：gnt[i] = req[i] & ~|req[i-1:0]。
//   3. 可配置起点：把 req 循环右移 k 位 → 固定优先级仲裁 → 结果循环左移 k 位；
//      或者用 "双倍长度" 技巧：{req,req} & ~({req,req} - (1<<k))，见第 020 题。
module fixed_arb #(parameter int N = 8) (
  input  logic [N-1:0] req,
  output logic [N-1:0] gnt
);
  assign gnt = req & (~req + 1'b1);
endmodule
