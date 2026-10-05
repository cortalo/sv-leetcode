`timescale 1ns/1ps
// 思路：
//   valid：同第 002 题，不存在 "1 下面是 0" 的相邻位。
//   bin  ：合法码中 1→0 的跳变只出现一次：t[i] = thermo[i] & ~thermo[i+1]（thermo[W] 视为 0），
//          t 是独热码（全 0 输入时 t=0），跳变在第 i 位表示数值 i+1。
//          独热码 → 二进制只需要或门：bin[b] = OR{ t[i] : (i+1) 的第 b 位为 1 }。
//          这比 popcount（一棵加法树）省很多面积，也更快。
// 追问：
//   2. 气泡容错：直接用 popcount（第 003 题），单个气泡只带来 ±1 误差；
//      或者先做 "三输入多数表决" 平滑 t'[i] = maj(thermo[i-1], thermo[i], thermo[i+1]) 再编码。
//   3. 二进制 → 温度计码：thermo[i] = (bin > i)，或 thermo = (1 << bin) - 1。
//   4. 把 W 分成若干段，第一拍各段求局部跳变/段内编码，第二拍合并（类似优先编码器的树形结构）。
module thermo2bin #(parameter int W = 15) (
  input  logic [W-1:0]           thermo,
  output logic [$clog2(W+1)-1:0] bin,
  output logic                   valid
);
  localparam int BW = $clog2(W + 1);

  logic [W:0]   ext;
  logic [W-1:0] t;

  assign ext = {1'b0, thermo};
  assign t   = ext[W-1:0] & ~ext[W:1];

  always_comb begin
    for (int b = 0; b < BW; b++) begin
      bin[b] = 1'b0;
      for (int i = 0; i < W; i++)
        if (((i + 1) >> b) & 1) bin[b] = bin[b] | t[i];
    end
  end

  generate
    if (W == 1) begin : g_w1
      assign valid = 1'b1;
    end else begin : g_wn
      assign valid = ~|(thermo[W-1:1] & ~thermo[W-2:0]);
    end
  endgenerate
endmodule
