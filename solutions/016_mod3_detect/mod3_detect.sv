`timescale 1ns/1ps
// 思路：只需要记住当前数除以 3 的余数（3 个状态 R0/R1/R2）。
//   新余数 = (旧余数 * 2 + din) mod 3：
//     R0: din=0→R0  din=1→R1
//     R1: din=0→R2  din=1→R0
//     R2: din=0→R1  din=1→R2
//   div3 = (state == R0)。
// 追问：
//   2. 低位在前：第 k 位的权重 2^k mod 3 交替为 1, 2, 1, 2 ...，
//      多记一个 "当前权重" 标志位：rem <= (rem + (w ? 2 : 1) * din) mod 3，w <= ~w。共 6 个状态。
//   3. 模 N：余数状态 N 个，rem <= (2*rem + din) mod N。
//   4. 并行：奇数位 1 的个数 - 偶数位 1 的个数 能被 3 整除（因为 2 ≡ -1 mod 3），
//      或者把数按 2bit 分组累加（4 ≡ 1 mod 3），递归缩小。
module mod3_detect (
  input  logic clk,
  input  logic rst_n,
  input  logic din,
  input  logic din_valid,
  output logic div3
);
  logic [1:0] rem;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) rem <= 2'd0;
    else if (din_valid)
      case (rem)
        2'd0:    rem <= din ? 2'd1 : 2'd0;
        2'd1:    rem <= din ? 2'd0 : 2'd2;
        2'd2:    rem <= din ? 2'd2 : 2'd1;
        default: rem <= 2'd0;
      endcase

  assign div3 = (rem == 2'd0);
endmodule
