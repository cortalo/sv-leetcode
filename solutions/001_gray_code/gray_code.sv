`timescale 1ns/1ps
// 思路：
//   bin -> gray：gray[i] = bin[i] ^ bin[i+1]，最高位不变，即 gray = bin ^ (bin >> 1)
//   gray -> bin：从最高位往下做前缀异或，bin[i] = gray[W-1] ^ ... ^ gray[i] = bin[i+1] ^ gray[i]
// 追问：
//   1. 相邻值只差 1 bit，跨时钟域时就算采到中间态也只会是"旧值或新值"，不会是乱码。
//   2. 直接写是 W-1 级 XOR 链；可以改成并行前缀异或（log2(W) 级），和加法器的超前进位同一个思路。
//   3. 非 2 的幂深度时首尾回绕不再只变 1 bit，需要用对称截取的格雷码区间或者换成其他同步方式。
module gray_code #(parameter int W = 8) (
  input  logic [W-1:0] bin_i,
  output logic [W-1:0] gray_o,
  input  logic [W-1:0] gray_i,
  output logic [W-1:0] bin_o
);
  assign gray_o = bin_i ^ (bin_i >> 1);

  always_comb begin
    bin_o[W-1] = gray_i[W-1];
    for (int i = W - 2; i >= 0; i--)
      bin_o[i] = bin_o[i+1] ^ gray_i[i];
  end
endmodule
