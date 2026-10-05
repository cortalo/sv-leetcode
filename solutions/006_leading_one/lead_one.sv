`timescale 1ns/1ps
// 思路：for 循环从低位扫到高位，遇到 1 就覆盖 idx —— 最后一次赋值生效，所以高位优先。
//   综合结果是一条优先级 MUX 链（综合器会做一定优化）。
// 追问：
//   2. 树形：把 in 分成高低两半，分别求 (valid_h, idx_h) 和 (valid_l, idx_l)，
//      合并：valid = valid_h | valid_l；idx = valid_h ? {1'b1, idx_h} : {1'b0, idx_l}。
//      递归 log2(W) 层，每层一个 2 选 1，延迟 O(log W)。
//   3. 最高位的 0 = 对 ~in 求最高位的 1。
//   4. LZC（前导零个数）= W-1-idx（in 非 0 时），浮点加法后的规格化就靠它。
module lead_one #(parameter int W = 16) (
  input  logic [W-1:0]         in,
  output logic [$clog2(W)-1:0] idx,
  output logic                 valid
);
  always_comb begin
    idx = '0;
    for (int i = 0; i < W; i++)
      if (in[i]) idx = i[$clog2(W)-1:0];
  end
  assign valid = |in;
endmodule
