`timescale 1ns/1ps
// 思路：两级流水 6 → 3 → 1。
//   第 1 级：三个加法器两两相加 s0=d0+d1, s1=d2+d3, s2=d4+d5，寄存
//   第 2 级：s0+s1+s2，寄存输出
//   每级一个 valid 位，ready 从后往前组合传递：
//     rdy2 = ~v2 | out_ready;   rdy1 = ~v1 | rdy2;   in_ready = rdy1
//   某级 ready 为 1 时，该级接收上一级的 valid/data（同第 022 题的 pipe_stage）。
// 追问：
//   1. 直接相加是 5 个 32bit 加法器的串联（或 3 级加法树），关键路径 = 3 条进位链；
//      6→3→1 每级最多 2 个加法串联（第二级 s0+s1+s2）；更激进可以 6→3→2→1 三级。
//   2. CSA：6 个数经过 3:2 压缩器树压到 2 个数（只有全加器延迟，没有进位传播），
//      最后只需要 1 个 32bit 进位传播加法器，总延迟 ≈ 3 级全加器 + 1 条进位链。
//   3. data/valid 是一级一级寄存的；ready 是从输出端组合反传到输入端的（级数多时可加 skid buffer 切断）。
//   4. 握手的意义是流控：下游没处理完（ready=0）时，本级要保持数据不被覆盖，上游也要停住。
module sum6 (
  input  logic             clk,
  input  logic             rst_n,
  input  logic             in_valid,
  output logic             in_ready,
  input  logic [5:0][31:0] in_data,
  output logic             out_valid,
  input  logic             out_ready,
  output logic [31:0]      out_sum
);
  logic        v1, rdy1, rdy2;
  logic [31:0] s0, s1, s2;

  assign rdy2     = ~out_valid | out_ready;
  assign rdy1     = ~v1 | rdy2;
  assign in_ready = rdy1;

  // 第 1 级
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)    v1 <= 1'b0;
    else if (rdy1) v1 <= in_valid;

  always_ff @(posedge clk)
    if (rdy1 && in_valid) begin
      s0 <= in_data[0] + in_data[1];
      s1 <= in_data[2] + in_data[3];
      s2 <= in_data[4] + in_data[5];
    end

  // 第 2 级
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)    out_valid <= 1'b0;
    else if (rdy2) out_valid <= v1;

  always_ff @(posedge clk)
    if (rdy2 && v1) out_sum <= s0 + s1 + s2;
endmodule
