`timescale 1ns/1ps
module afifo_tester #(parameter real TW = 10.0, parameter real TR = 17.3, parameter int ID = 0) (
  input  logic rst_n,
  input  int   phase,       // 0 偏写 1 偏读 2 平衡 3 排空（只读不写）
  output int   errs,
  output int   nw,
  output int   nr,
  output int   nfull,
  output int   nempty
);
  localparam int W = 8, AW = 4, DEPTH = 1 << AW;
  logic         wclk = 0, rclk = 0;
  logic         winc = 0, rinc = 0, wfull, rempty;
  logic [W-1:0] wdata = 0, rdata;
  initial forever #(TW / 2) wclk = ~wclk;
  initial begin #(TR / 3); forever #(TR / 2) rclk = ~rclk; end

  async_fifo #(.W(W), .AW(AW)) dut (
    .wclk(wclk), .wrst_n(rst_n), .winc(winc), .wdata(wdata), .wfull(wfull),
    .rclk(rclk), .rrst_n(rst_n), .rinc(rinc), .rdata(rdata), .rempty(rempty));

  // 参考模型：环形队列（两个时钟域共用，仿真里没有竞争问题）
  logic [W-1:0] mq [DEPTH];
  int head, cnt;
  initial begin errs = 0; nw = 0; nr = 0; nfull = 0; nempty = 0; head = 0; cnt = 0; end

  task automatic err(input string s);
    errs++; if (errs <= 6) $display("[%0t] ERROR 实例%0d: %s", $time, ID, s);
  endtask

  // 写侧：下降沿驱动，驱动后判断下一个上升沿是否真的写入
  always @(negedge wclk) if (rst_n) begin
    if ((^wfull) === 1'bx) err("wfull 为 X");
    winc  = ($urandom % 100) < (phase == 0 ? 90 : phase == 1 ? 10 : phase == 2 ? 55 : 0);
    wdata = $urandom;
    #0.1;
    if (wfull) nfull++;
    if (winc && !wfull) begin
      if (cnt >= DEPTH) err("溢出：FIFO 已经有 DEPTH 个数据，wfull 却为 0");
      else begin mq[(head + cnt) % DEPTH] = wdata; cnt++; nw++; end
    end
  end

  // 读侧：下降沿驱动，驱动后判断下一个上升沿是否真的读出
  always @(negedge rclk) if (rst_n) begin
    if ((^rempty) === 1'bx) err("rempty 为 X");
    rinc = ($urandom % 100) < (phase == 0 ? 10 : phase == 1 ? 90 : phase == 2 ? 55 : 100);
    #0.1;
    if (rempty) nempty++;
    if (!rempty) begin
      if (cnt == 0) err("下溢：FIFO 实际为空，rempty 却为 0");
      else if (rdata !== mq[head]) err($sformatf("rdata=0x%h，期望队头 0x%h（第 %0d 个数据）", rdata, mq[head], nr));
      else if (rinc) begin head = (head + 1) % DEPTH; cnt--; nr++; end
    end
  end
endmodule

module tb;
  int errors = 0;
  int unsigned seed = 1;
  logic rst_n = 0;
  int phase = 2;

  int e1, w1, r1, f1, m1, e2, w2, r2, f2, m2;
  afifo_tester #(.TW(10.0), .TR(17.3), .ID(1)) t1 (.rst_n(rst_n), .phase(phase), .errs(e1), .nw(w1), .nr(r1), .nfull(f1), .nempty(m1));
  afifo_tester #(.TW(23.1), .TR(7.0),  .ID(2)) t2 (.rst_n(rst_n), .phase(phase), .errs(e2), .nw(w2), .nr(r2), .nfull(f2), .nempty(m2));

  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    #100 rst_n = 1;
    for (int n = 0; n < 60; n++) begin
      phase = n % 3;
      #3us;
    end
    phase = 3;            // 排空
    #3us;

    errors = e1 + e2;
    if (w1 != r1) begin errors++; $display("ERROR 实例1: 写入 %0d 个，排空后只读出 %0d 个（假空卡住？）", w1, r1); end
    if (w2 != r2) begin errors++; $display("ERROR 实例2: 写入 %0d 个，排空后只读出 %0d 个（假空卡住？）", w2, r2); end
    if (w1 < 2000 || w2 < 2000 || f1 < 50 || f2 < 50 || m1 < 50 || m2 < 50) begin
      errors++;
      $display("ERROR 覆盖不足：实例1 写 %0d / 满 %0d 拍 / 空 %0d 拍；实例2 写 %0d / 满 %0d 拍 / 空 %0d 拍", w1, f1, m1, w2, f2, m2);
    end
    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
