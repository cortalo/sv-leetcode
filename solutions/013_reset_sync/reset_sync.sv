`timescale 1ns/1ps
// 思路：两级触发器，都用 arst_n 做异步复位；D 端接常数 1。
//   复位时两级同时清 0 → 输出立即为 0（异步复位）；
//   释放后，1 在两级触发器中逐拍移动，第 2 个上升沿之后输出才变 1（同步释放）。
// 追问：
//   1. 复位释放如果离时钟沿太近，违反 recovery/removal 时间，触发器可能进入亚稳态，
//      而且不同触发器可能在不同拍退出复位，状态机会跑飞。
//   2. 释放时第一级可能亚稳态，但第二级的 D 端在释放前后一直是第一级的输出（0 或 1 都有可能），
//      给了第一级一个周期去稳定；第二级采到的要么 0 要么 1，最多晚一拍释放，不会亚稳。
//      复位拉低的瞬间两级都被强制清 0，与时钟无关，不存在亚稳问题。
//   3. 同步复位依赖时钟、要占用数据通路逻辑（D 端的 MUX），没有时钟时无法复位。
//   4. 每个时钟域各放一个复位同步器；有依赖关系的模块按顺序释放（例如先释放下游再释放上游）。
module reset_sync (
  input  logic clk,
  input  logic arst_n,
  output logic rst_n_sync
);
  logic sync1;

  always_ff @(posedge clk or negedge arst_n)
    if (!arst_n) begin
      sync1      <= 1'b0;
      rst_n_sync <= 1'b0;
    end else begin
      sync1      <= 1'b1;
      rst_n_sync <= sync1;
    end
endmodule
