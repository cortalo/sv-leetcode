`timescale 1ns/1ps
// 思路：翻转同步（toggle synchronizer）。
//   A 域：每来一个脉冲，电平寄存器 tog 翻转一次 —— 把 "脉冲" 变成 "电平变化"，电平会一直保持，
//         慢时钟一定能采到。
//   B 域：tog 打两拍（s1、s2）消除亚稳态，再多打一拍 s3，s2 ^ s3 就是一个 clk_b 周期宽的脉冲。
//   这里把输出再寄存一拍，pulse_b 是干净的寄存器输出。
// 追问：
//   1. 慢时钟可能根本采不到快时钟的单周期脉冲（脉冲落在两个慢时钟沿之间），直接丢失。
//   2. tog 两次翻转之间至少要隔 2~3 个 clk_b 周期，否则 B 域看不到中间那次变化（两次翻转抵消）→ 丢脉冲。
//      脉冲密集时：加反馈握手（B 域把收到的信号同步回 A 域，A 域收到确认前不接收新脉冲，给出 busy），
//      或者在 A 域用计数器 / 异步 FIFO 传递脉冲个数。
//   3. 电平信号慢→快：直接打两拍；快→慢的脉冲：展宽到足够宽再打两拍，并用反馈确认展宽结束；
//      翻转同步：本题；需要可靠传递且有流控：握手（第 028 题）。
//   4. 不行：各位经过同步器的延迟可能不同（有的这拍、有的下拍才稳定），会采到新旧混合的错误值。
//      多 bit 要用格雷码（只有 1 位变化）、握手或异步 FIFO。
module pulse_sync (
  input  logic clk_a,
  input  logic rst_a_n,
  input  logic pulse_a,
  input  logic clk_b,
  input  logic rst_b_n,
  output logic pulse_b
);
  logic tog;
  logic s1, s2, s3;

  always_ff @(posedge clk_a or negedge rst_a_n)
    if (!rst_a_n)     tog <= 1'b0;
    else if (pulse_a) tog <= ~tog;

  always_ff @(posedge clk_b or negedge rst_b_n)
    if (!rst_b_n) begin
      s1 <= 1'b0; s2 <= 1'b0; s3 <= 1'b0; pulse_b <= 1'b0;
    end else begin
      s1      <= tog;
      s2      <= s1;
      s3      <= s2;
      pulse_b <= s2 ^ s3;
    end
endmodule
