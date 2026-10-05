`timescale 1ns/1ps
// 一个 FIFO 实例 + 参考模型
module fifo_tester #(parameter int W = 8, parameter int DEPTH = 16) (
  input  logic clk,
  input  logic rst_n,
  input  int   phase,       // 0 偏写 1 偏读 2 平衡
  output int   errs,
  output int   nread,
  output int   nfull,
  output int   nempty
);
  logic         wr_en = 0, rd_en = 0, full, empty;
  logic [W-1:0] din = 0, dout;

  sync_fifo #(.W(W), .DEPTH(DEPTH)) dut (
    .clk(clk), .rst_n(rst_n), .wr_en(wr_en), .din(din), .full(full),
    .rd_en(rd_en), .dout(dout), .empty(empty));

  // 参考模型：环形缓冲
  logic [W-1:0] mq [DEPTH];
  int head, cnt;
  logic exp_rd; logic [W-1:0] exp_dout;
  initial begin errs = 0; nread = 0; nfull = 0; nempty = 0; end

  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin head = 0; cnt = 0; exp_rd = 0; end
    else begin
      logic do_rd, do_wr;
      do_rd = rd_en && (cnt > 0);
      do_wr = wr_en && (cnt < DEPTH);
      if (do_wr) mq[(head + cnt) % DEPTH] = din;
      if (do_rd) begin exp_dout = mq[head]; head = (head + 1) % DEPTH; nread++; end
      cnt = cnt + do_wr - do_rd;
      exp_rd = do_rd;
    end

  always @(negedge clk) if (rst_n) begin
    if (full !== (cnt == DEPTH)) begin
      errs++; if (errs <= 5) $display("[%0t] ERROR DEPTH=%0d: FIFO 中有 %0d 个数据，full=%b，期望 %b", $time, DEPTH, cnt, full, cnt == DEPTH);
    end
    if (empty !== (cnt == 0)) begin
      errs++; if (errs <= 5) $display("[%0t] ERROR DEPTH=%0d: FIFO 中有 %0d 个数据，empty=%b，期望 %b", $time, DEPTH, cnt, empty, cnt == 0);
    end
    if (exp_rd && dout !== exp_dout) begin
      errs++; if (errs <= 5) $display("[%0t] ERROR DEPTH=%0d: 读出 dout=0x%h，期望 0x%h", $time, DEPTH, dout, exp_dout);
    end
    if (cnt == DEPTH) nfull++;
    if (cnt == 0) nempty++;
    // 下一拍的激励
    wr_en = ($urandom % 100) < (phase == 0 ? 80 : phase == 1 ? 20 : 50);
    rd_en = ($urandom % 100) < (phase == 0 ? 20 : phase == 1 ? 80 : 50);
    din   = $urandom;
  end
endmodule

module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic clk = 0, rst_n = 0;
  int phase = 2;
  always #5 clk = ~clk;

  int e1, r1, f1, m1, e2, r2, f2, m2;
  fifo_tester #(.W(8), .DEPTH(16)) t1 (.clk(clk), .rst_n(rst_n), .phase(phase), .errs(e1), .nread(r1), .nfull(f1), .nempty(m1));
  fifo_tester #(.W(5), .DEPTH(4))  t2 (.clk(clk), .rst_n(rst_n), .phase(phase), .errs(e2), .nread(r2), .nfull(f2), .nempty(m2));

  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    repeat (3) @(posedge clk);
    @(negedge clk) rst_n = 1;
    for (int n = 0; n < 12000; n++) begin
      @(posedge clk);
      phase = (n / 200) % 3;
    end

    errors = e1 + e2;
    if (r1 < 3000 || f1 < 50 || m1 < 50 || r2 < 3000 || f2 < 50 || m2 < 50) begin
      errors++;
      $display("ERROR 覆盖不足：DEPTH=16 读 %0d 次/满 %0d 拍/空 %0d 拍；DEPTH=4 读 %0d 次/满 %0d 拍/空 %0d 拍", r1, f1, m1, r2, f2, m2);
    end
    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
