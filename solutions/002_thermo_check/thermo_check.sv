`timescale 1ns/1ps
// 思路一（加法）：合法温度计码 +1 之后变成只有 1 个 bit 为 1 的数（或全 0 溢出），
//   和原数按位与一定为 0：  is_thermo = ((in & (in + 1)) == 0)
//   和 "判断是不是 2 的幂：x & (x-1) == 0" 是同一个技巧。
// 思路二（相邻位，不用加法器）：非法 <=> 存在某一位 i 满足 in[i+1]=1 且 in[i]=0（1 的下面出现 0）
//   is_thermo = ~|(in[W-1:1] & ~in[W-2:0])
//   这是 W-1 个与门 + 一棵或树，深度 log2(W)，比加法器的进位链更快，下面用的是这种。
// 追问：
//   2. 1 从最高位开始排：把条件反过来，非法 <=> 存在 in[i+1]=0 且 in[i]=1
//      即 ~|(~in[W-1:1] & in[W-2:0])；或者 (~in & (~in + 1)) == 0。
//   4. 加法写法综合出来主要是进位链（综合器可能优化成前缀结构）；相邻位写法固定 log2(W) 级。
module thermo_check #(parameter int W = 8) (
  input  logic [W-1:0] in,
  output logic         is_thermo
);
  generate
    if (W == 1) begin : g_w1
      assign is_thermo = 1'b1;                 // 0 和 1 都合法
    end else begin : g_wn
      assign is_thermo = ~|(in[W-1:1] & ~in[W-2:0]);
    end
  endgenerate
endmodule
