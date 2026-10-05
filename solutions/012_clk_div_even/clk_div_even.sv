`timescale 1ns/1ps
// 思路：计数器从 0 数到 N/2-1，数满就翻转 clk_out 并清零。翻转 2 次为一个周期 = N 拍。
// 追问：
//   1. 用触发器输出当时钟，会引入额外的时钟偏斜（不在时钟树上），且时钟和数据路径混在一起，
//      STA/DFT 都麻烦。芯片里一般用专门的时钟分频单元（ICG + 计数器），或者用 PLL 输出多路时钟。
//   2. 使能脉冲：cnt == N-1 时 en_pulse = 1，下游触发器仍用原时钟，只在 en_pulse 时更新。
//      所有逻辑同一个时钟域，没有时钟偏斜问题，是 RTL 里最推荐的做法。
//   3. create_generated_clock -name clk_div -source [get_pins .../clk] -divide_by N [get_pins .../Q]
module clk_div_even #(parameter int N = 4) (
  input  logic clk,
  input  logic rst_n,
  output logic clk_out
);
  localparam int HALF = N / 2;
  localparam int CW   = (HALF > 1) ? $clog2(HALF) : 1;

  logic [CW-1:0] cnt;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      cnt     <= '0;
      clk_out <= 1'b0;
    end else if (cnt == CW'(HALF - 1)) begin
      cnt     <= '0;
      clk_out <= ~clk_out;
    end else begin
      cnt     <= cnt + 1'b1;
    end
endmodule
