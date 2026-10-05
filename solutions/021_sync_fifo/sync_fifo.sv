`timescale 1ns/1ps
// 思路：寄存器堆 mem + 读写指针。指针比地址多 1 位：
//   地址相同、最高位相同 → 空；地址相同、最高位不同 → 满（写指针比读指针多绕了一圈）。
//   wr = wr_en & ~full，rd = rd_en & ~empty；dout 在读的时候寄存。
// 追问：
//   1. 计数器法：count 在只写时 +1、只读时 -1，full = (count == DEPTH)，empty = (count == 0)。
//      多一位指针法不需要加减法器，而且可以直接推广到异步 FIFO（第 030 题）。
//   2. 非 2 的幂：指针在 DEPTH-1 处手动回绕到 0，同时翻转额外的"圈数"位；或者直接用计数器法。
//   3. FWFT：dout = mem[rd_addr]（组合读），valid = ~empty，rd_en 表示弹出；
//      想要寄存器输出时，在 FIFO 后面接一级 "预取" 寄存器（类似 skid buffer，第 027 题）。
//   4. SRAM 读有一拍延迟，要么提前一拍发读地址（预取），要么在输出端加 2 级缓冲保持满吞吐。
//   5. 写 80 个数据用时 80 × 10ns = 800ns，期间读走 800ns / 20ns = 40 个，深度至少 80 - 40 = 40。
module sync_fifo #(
  parameter int W     = 8,
  parameter int DEPTH = 16
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         wr_en,
  input  logic [W-1:0] din,
  output logic         full,
  input  logic         rd_en,
  output logic [W-1:0] dout,
  output logic         empty
);
  localparam int AW = $clog2(DEPTH);

  logic [W-1:0] mem [DEPTH];
  logic [AW:0]  wptr, rptr;
  logic         wr, rd;

  assign full  = (wptr[AW] != rptr[AW]) && (wptr[AW-1:0] == rptr[AW-1:0]);
  assign empty = (wptr == rptr);
  assign wr    = wr_en && !full;
  assign rd    = rd_en && !empty;

  always_ff @(posedge clk)
    if (wr) mem[wptr[AW-1:0]] <= din;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      wptr <= '0;
      rptr <= '0;
      dout <= '0;
    end else begin
      if (wr) wptr <= wptr + 1'b1;
      if (rd) begin
        rptr <= rptr + 1'b1;
        dout <= mem[rptr[AW-1:0]];
      end
    end
endmodule
