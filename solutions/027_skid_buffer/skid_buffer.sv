`timescale 1ns/1ps
// 思路：主寄存器（out_valid/out_data）+ 一个 skid 寄存器（skid_valid/skid_data）。
//   in_ready = ~skid_valid（寄存器输出）。
//   问题在于：上一拍给出的 in_ready=1 是 "承诺" 这一拍能收，但下游这一拍可能突然 out_ready=0，
//   主寄存器的数据没被取走，新进来的数据没地方放 —— 就先放进 skid 寄存器（"滑"进去），
//   同时下一拍 in_ready 变 0。下游恢复 ready 后，先把 skid 里的数据补到主寄存器。
//   状态：空（out_valid=0）→ 半满（只有主寄存器有数据）→ 满（skid 也有，in_ready=0）。
// 追问：
//   1. in_ready 是寄存器输出时，它反映的是上一拍的状态，这一拍下游的 ready 变化要到下一拍才能反压上游，
//      中间这一拍上游可能已经送进来一个数据，必须有地方接住；只有一个寄存器就只能在它为空时才 ready，
//      吞吐最多 50%。
//   3. 每级都用 skid：ready 路径全部切断，时序最好，但寄存器面积翻倍；
//      通常只在 ready 组合路径太长的地方（比如每隔几级、或跨模块边界）插一级。
module skid_buffer #(parameter int W = 8) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         in_valid,
  output logic         in_ready,
  input  logic [W-1:0] in_data,
  output logic         out_valid,
  input  logic         out_ready,
  output logic [W-1:0] out_data
);
  logic         skid_valid;
  logic [W-1:0] skid_data;
  logic         in_fire, out_fire;

  assign in_ready = ~skid_valid;
  assign in_fire  = in_valid & in_ready;
  assign out_fire = out_valid & out_ready;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      out_valid  <= 1'b0;
      skid_valid <= 1'b0;
    end else begin
      if (!out_valid || out_ready) begin
        // 主寄存器空了 / 这一拍被取走：优先从 skid 补，其次直接收上游
        if (skid_valid) begin
          out_valid  <= 1'b1;
          out_data   <= skid_data;
          skid_valid <= 1'b0;
        end else begin
          out_valid  <= in_fire;
          if (in_fire) out_data <= in_data;
        end
      end else if (in_fire) begin
        // 主寄存器被堵住，新数据放进 skid
        skid_valid <= 1'b1;
        skid_data  <= in_data;
      end
    end
endmodule
