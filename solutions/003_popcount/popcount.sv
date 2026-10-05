`timescale 1ns/1ps
// 思路：最直接的是 for 循环累加。
//   综合器会把 "cnt = cnt + in[i]" 展开成一串加法器（链状），延迟约 W 级 1bit 加法，
//   不过现代综合工具通常会自动重排成加法树 / CSA 压缩树。
// 追问：
//   2. 加法树：先两两相加得到 W/2 个 2bit 数，再两两相加得到 W/4 个 3bit 数……共 log2(W) 层。
//      更好的做法是用全加器(3:2 压缩器)组成 Wallace 树，最后一级再用一个加法器。
//   3. 在加法树的中间层插寄存器即可，例如 64bit 分成 4 组 16bit 各自统计（第一拍），再相加（第二拍）。
//   4. 汉明距离 = popcount(a ^ b)。
module popcount #(parameter int W = 16) (
  input  logic [W-1:0]           in,
  output logic [$clog2(W+1)-1:0] cnt
);
  always_comb begin
    cnt = '0;
    for (int i = 0; i < W; i++)
      cnt = cnt + in[i];
  end
endmodule
