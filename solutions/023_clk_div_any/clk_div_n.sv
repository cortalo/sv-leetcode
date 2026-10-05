`timescale 1ns/1ps
// 思路：把奇偶分频统一起来（n >= 2）：
//   上升沿计数器 cnt 循环 0..n-1；p <= (下一拍的 cnt < n/2)，高电平 floor(n/2) 个周期；
//   下降沿寄存器 q <= p（p 延迟半拍）；
//   偶数 n：clk_out = p（高 n/2 个周期）；
//   奇数 n：clk_out = p | q（高 (n-1)/2 + 0.5 = n/2 个周期）；
//   n = 1 ：clk_out = clk。
// 追问：
//   1. 可以，见上：唯一区别是奇数时多 "或" 一个下降沿寄存的副本。
//   2. 动态切换：新 n 先寄存，等当前周期结束（cnt 回到 0、输出为低）时再生效；
//      n=1 与其他值之间切换要用无毛刺时钟切换电路（第 029 题）。
//   3. 要用标准单元库里的时钟 MUX（clock mux cell），并在 SDC 里约束两路时钟、设置 case analysis。
module clk_div_n (
  input  logic       clk,
  input  logic       rst_n,
  input  logic [7:0] n,
  output logic       clk_out
);
  logic [7:0] cnt, cnt_nxt;
  logic       p, q;

  assign cnt_nxt = (cnt >= n - 8'd1) ? 8'd0 : cnt + 8'd1;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      cnt <= '0;
      p   <= 1'b0;
    end else begin
      cnt <= cnt_nxt;
      p   <= (cnt_nxt < (n >> 1));
    end

  always_ff @(negedge clk or negedge rst_n)
    if (!rst_n) q <= 1'b0;
    else        q <= p;

  assign clk_out = (n == 8'd1) ? clk : n[0] ? (p | q) : p;
endmodule
