`timescale 1ns/1ps
// 思路：两相（翻转）握手。
//   A 域：a_ready = (req == ack_sync)。握手成功时把数据锁进 data_q（之后保持不变），req 翻转。
//   B 域：req 打两拍得到 req_sync，与上一拍比较发现变化 → 采样 data_q 输出（b_valid 一拍），
//         ack 翻转（ack 就是 req_sync 的寄存值）。
//   A 域：ack 打两拍得到 ack_sync，等于 req 时说明 B 已收到，a_ready 恢复为 1。
//   data_q 在 req 翻转之前就已稳定，并且直到 ack 回来之前都不变；B 域在 req_sync 变化时（至少两拍之后）
//   才采样它，所以多 bit 数据不需要同步器，也不会采到中间值。
// 追问：
//   1. 采样时数据已经稳定了好几个周期，不会有建立/保持问题。约束：data_q → b_data 设 max_delay
//      （小于同步链的延迟）或 set_false_path 加上设计说明；控制信号 req/ack 必须走同步器。
//   2. 四相：req 拉高 → ack 拉高 → req 拉低 → ack 拉低，一次传输要过 4 次同步；
//      两相：每次传输只翻转一次，过 2 次同步，速度约快一倍，但需要比较电平变化。
//   3. 一次传输 ≈ 2~3 个 clk_b（req 同步）+ 2~3 个 clk_a（ack 同步），吞吐很低；
//      要高吞吐就用异步 FIFO（第 030 题）。
//   4. 3M 周期 ≈ 333ns，20M 周期 50ns：在 3M 域产生一个 "数据有效" 翻转信号，20M 域打两拍检测到变化后
//      再采数据（此时数据已稳定 2~3 个快周期，且离下次变化还有 ~4 个快周期），即 "数据 + 使能同步"。
module cdc_handshake #(parameter int W = 8) (
  input  logic         clk_a,
  input  logic         rst_a_n,
  input  logic         a_valid,
  output logic         a_ready,
  input  logic [W-1:0] a_data,
  input  logic         clk_b,
  input  logic         rst_b_n,
  output logic         b_valid,
  output logic [W-1:0] b_data
);
  // ---------------- A 域 ----------------
  logic         req;
  logic [W-1:0] data_q;
  logic         ack_s1, ack_s2;
  logic         ack;          // 来自 B 域

  assign a_ready = (req == ack_s2);

  always_ff @(posedge clk_a or negedge rst_a_n)
    if (!rst_a_n) begin
      req <= 1'b0; ack_s1 <= 1'b0; ack_s2 <= 1'b0;
    end else begin
      ack_s1 <= ack;
      ack_s2 <= ack_s1;
      if (a_valid && a_ready) begin
        data_q <= a_data;
        req    <= ~req;
      end
    end

  // ---------------- B 域 ----------------
  logic req_s1, req_s2;

  always_ff @(posedge clk_b or negedge rst_b_n)
    if (!rst_b_n) begin
      req_s1 <= 1'b0; req_s2 <= 1'b0; ack <= 1'b0; b_valid <= 1'b0;
    end else begin
      req_s1  <= req;
      req_s2  <= req_s1;
      ack     <= req_s2;
      b_valid <= (req_s2 != ack);
      if (req_s2 != ack) b_data <= data_q;
    end
endmodule
