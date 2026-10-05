`timescale 1ns/1ps
// 思路（Cummings 经典结构）：
//   1. 读写指针都是 AW+1 位（多一位区分 "满" 和 "空"），各自在本时钟域递增，同时维护格雷码版本。
//   2. 格雷码指针打两拍同步到对方时钟域。
//   3. 空：在读时钟域比较  读指针格雷码 == 同步过来的写指针格雷码
//      满：在写时钟域比较  写指针格雷码 == {~同步过来的读指针格雷码[AW:AW-1], 读指针格雷码[AW-2:0]}
//          （二进制下是 "最高位不同、其余相同"，转成格雷码后变成 "高两位相反、其余相同"）
//   4. empty/full 用 "下一拍的指针" 计算并寄存，输出干净且没有一拍延迟。
//   5. rdata = mem[raddr]（组合读，show-ahead）。
// 追问：
//   1. 二进制指针一次加 1 可能多位同时变化（0111→1000），同步时各位到达时间不同，可能采到任意错误值；
//      格雷码每次只变一位，采到的要么是旧值要么是新值。
//   3. 同步过来的指针比真实值 "落后"：写侧看到的读指针偏小 → 以为没读那么多 → 只会多报满；
//      读侧看到的写指针偏小 → 以为没写那么多 → 只会多报空。都是安全方向。
//   4. 没问题：慢时钟采到的是某个时刻的真实格雷码值（只是跳过了中间值），空满判断依然保守正确。
//   5. 用对称截取的格雷码序列（首尾也只差一位），或者改用握手 / 计数同步；也可以直接用更大的 2 的幂深度。
//   6. 格雷码指针跨域路径 set_max_delay（不超过一个周期，保证各位偏斜小）-datapath_only；
//      同步器触发器标 ASYNC_REG 并放在一起；mem 读路径可 false_path 或 max_delay。
module async_fifo #(
  parameter int W  = 8,
  parameter int AW = 4
) (
  input  logic         wclk,
  input  logic         wrst_n,
  input  logic         winc,
  input  logic [W-1:0] wdata,
  output logic         wfull,
  input  logic         rclk,
  input  logic         rrst_n,
  input  logic         rinc,
  output logic [W-1:0] rdata,
  output logic         rempty
);
  localparam int DEPTH = 1 << AW;

  logic [W-1:0] mem [DEPTH];
  logic [AW:0]  wbin, wgray, wbin_nxt, wgray_nxt;
  logic [AW:0]  rbin, rgray, rbin_nxt, rgray_nxt;
  logic [AW:0]  rq1_wgray, rq2_wgray;     // 写指针同步到读域
  logic [AW:0]  wq1_rgray, wq2_rgray;     // 读指针同步到写域

  // ---------------- 写时钟域 ----------------

  assign wbin_nxt  = wbin + (winc & ~wfull);
  assign wgray_nxt = (wbin_nxt >> 1) ^ wbin_nxt;

  always_ff @(posedge wclk)
    if (winc && !wfull) mem[wbin[AW-1:0]] <= wdata;

  always_ff @(posedge wclk or negedge wrst_n)
    if (!wrst_n) begin
      wbin <= '0; wgray <= '0; wfull <= 1'b0;
      wq1_rgray <= '0; wq2_rgray <= '0;
    end else begin
      wbin      <= wbin_nxt;
      wgray     <= wgray_nxt;
      wq1_rgray <= rgray;
      wq2_rgray <= wq1_rgray;
      wfull     <= (wgray_nxt == {~wq2_rgray[AW:AW-1], wq2_rgray[AW-2:0]});
    end

  // ---------------- 读时钟域 ----------------

  assign rbin_nxt  = rbin + (rinc & ~rempty);
  assign rgray_nxt = (rbin_nxt >> 1) ^ rbin_nxt;
  assign rdata     = mem[rbin[AW-1:0]];

  always_ff @(posedge rclk or negedge rrst_n)
    if (!rrst_n) begin
      rbin <= '0; rgray <= '0; rempty <= 1'b1;
      rq1_wgray <= '0; rq2_wgray <= '0;
    end else begin
      rbin      <= rbin_nxt;
      rgray     <= rgray_nxt;
      rq1_wgray <= wgray;
      rq2_wgray <= rq1_wgray;
      rempty    <= (rgray_nxt == rq2_wgray);
    end
endmodule
