`timescale 1ns/1ps
// 思路：用一个触发器寄存上一拍的 din（din_q），当前值与上一拍比较：
//   rise = din & ~din_q;  fall = ~din & din_q;  both = din ^ din_q
// 追问：
//   1. 异步输入要先过两级同步器（打两拍）消除亚稳态，再对同步后的信号做边沿检测：
//        sync1 <= din; sync2 <= sync1; sync3 <= sync2;  rise = sync2 & ~sync3;
//      输出比原信号晚 2~3 拍。
//   2. 寄存器输出：rise_q <= din & ~din_q; 输出再晚一拍，但没有从 din 到输出的组合路径。
module edge_detect (
  input  logic clk,
  input  logic rst_n,
  input  logic din,
  output logic rise,
  output logic fall,
  output logic both
);
  logic din_q;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) din_q <= 1'b0;
    else        din_q <= din;

  assign rise = din & ~din_q;
  assign fall = ~din & din_q;
  assign both = din ^ din_q;
endmodule
