`timescale 1ns/1ps
// 思路：一级寄存器 + valid 位。
//   本级可以接收新数据的条件：本级是空的，或者本级的数据这一拍会被下游取走：
//     in_ready = ~out_valid | out_ready
//   in_valid && in_ready 时把数据打进寄存器、out_valid 置 1；
//   否则如果下游取走了（out_ready），out_valid 清 0。
// 追问：
//   1. in_ready 组合依赖 out_ready，N 级串联后 ready 从最后一级一路组合传回第一级，形成长路径；
//      解决：skid buffer（第 027 题）让 in_ready 变成寄存器输出。
//   2. in_ready = out_ready：本级为空时下游不 ready 也会反压上游，浪费一个空槽，吞吐下降，
//      而且启动时如果下游 ready=0 就永远进不来（看下游实现）；功能上不丢数据但性能差。
//   3. AXI 规定：valid 不能依赖 ready（否则可能死锁），ready 可以依赖 valid。
module pipe_stage #(parameter int W = 8) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         in_valid,
  output logic         in_ready,
  input  logic [W-1:0] in_data,
  output logic         out_valid,
  input  logic         out_ready,
  output logic [W-1:0] out_data
);
  assign in_ready = ~out_valid | out_ready;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)        out_valid <= 1'b0;
    else if (in_ready) out_valid <= in_valid;

  always_ff @(posedge clk)
    if (in_valid && in_ready) out_data <= in_data;
endmodule
