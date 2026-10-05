`timescale 1ns/1ps
// 思路：恢复余数法（和手算长除法一样），每拍处理 1 bit，共 W 拍。
//   rem 初始为 0，quo 初始为被除数。每拍：
//     把 quo 的最高位移进 rem：      sh   = {rem, quo[W-1]}
//     试减：                         diff = sh - divisor
//     够减（diff >= 0）：rem = diff，商位 1；不够减：rem = sh，商位 0
//     quo 左移，把商位从最低位移进来（quo 同时充当 "剩余被除数" 和 "商" 的寄存器）
//   W 拍之后 quo 就是商，rem 就是余数。除数为 0 时每次都够减，商全 1、余数等于被除数，自然满足约定。
// 追问：
//   1. 不恢复余数法：不够减时不把余数加回来，下一拍改做加法，省掉一个 MUX（但最后可能要修正一次余数）。
//   2. radix-4：每拍试减 1×、2×、3× 除数（3 个减法器并行）选一个，拍数减半，面积和关键路径增加；
//      更高级的做法是 SRT 除法（冗余商位 + 查表）。
//   3. 先取绝对值做无符号除法，再修正符号：商的符号 = 两数符号异或，余数符号 = 被除数符号。
//   4. x/3 ≈ (x × 0xAAAB) >> 17（乘以倒数再移位，再做一次修正），或者用模 3 的规律逐位计算。
module divider #(parameter int W = 8) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start,
  input  logic [W-1:0] dividend,
  input  logic [W-1:0] divisor,
  output logic         busy,
  output logic         done,
  output logic [W-1:0] quotient,
  output logic [W-1:0] remainder
);
  localparam int CW = $clog2(W + 1);

  logic [W-1:0]  rem, quo, dvs;
  logic [CW-1:0] cnt;
  logic [W:0]    sh, diff;

  assign sh   = {rem, quo[W-1]};
  assign diff = sh - {1'b0, dvs};

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      busy <= 1'b0; done <= 1'b0; cnt <= '0;
      rem <= '0; quo <= '0; dvs <= '0;
    end else begin
      done <= 1'b0;
      if (start && !busy) begin
        busy <= 1'b1;
        cnt  <= CW'(W);
        rem  <= '0;
        quo  <= dividend;
        dvs  <= divisor;
      end else if (busy) begin
        if (!diff[W]) begin rem <= diff[W-1:0]; quo <= {quo[W-2:0], 1'b1}; end
        else          begin rem <= sh[W-1:0];   quo <= {quo[W-2:0], 1'b0}; end
        cnt <= cnt - 1'b1;
        if (cnt == 1) begin busy <= 1'b0; done <= 1'b1; end
      end
    end

  assign quotient  = quo;
  assign remainder = rem;
endmodule
