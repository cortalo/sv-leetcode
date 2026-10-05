`timescale 1ns/1ps
// 思路：先两两比较：(a,b) 得到 hi1/lo1，(c,d) 得到 hi2/lo2（2 个比较器）。
//   最大值 = max(hi1, hi2)，所以 min(hi1, hi2) 一定是第 2 大或第 3 大；
//   最小值 = min(lo1, lo2)，所以 max(lo1, lo2) 一定是第 2 大或第 3 大；
//   sum = min(hi1, hi2) + max(lo1, lo2)   —— 共 4 个比较器 + 1 个加法器。
//   （另一种思路：a+b+c+d - max - min，但需要更多加法器。）
// 追问：
//   2. 8 个数：用排序网络（Batcher 奇偶归并 19 个比较交换单元），或者只求 top2 / bottom2 再相减。
module mid2_sum #(parameter int W = 8) (
  input  logic [W-1:0] a, b, c, d,
  output logic [W:0]   sum
);
  logic [W-1:0] hi1, lo1, hi2, lo2, m_hi, m_lo;

  assign hi1  = (a > b) ? a : b;
  assign lo1  = (a > b) ? b : a;
  assign hi2  = (c > d) ? c : d;
  assign lo2  = (c > d) ? d : c;
  assign m_hi = (hi1 < hi2) ? hi1 : hi2;   // min of maxes
  assign m_lo = (lo1 > lo2) ? lo1 : lo2;   // max of mins
  assign sum  = m_hi + m_lo;
endmodule
