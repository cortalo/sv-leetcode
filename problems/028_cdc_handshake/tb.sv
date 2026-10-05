`timescale 1ns/1ps
module hs_tester #(parameter real TA = 10.0, parameter real TB = 13.7, parameter int ID = 0) (
  input  logic rst_n,
  input  logic run,
  output int   errs,
  output int   nsent,
  output int   nrecv
);
  logic       clk_a = 0, clk_b = 0;
  logic       a_valid = 0, a_ready, b_valid;
  logic [7:0] a_data = 0, b_data;
  initial forever #(TA / 2) clk_a = ~clk_a;
  initial begin #(TB / 3); forever #(TB / 2) clk_b = ~clk_b; end

  cdc_handshake #(.W(8)) dut (
    .clk_a(clk_a), .rst_a_n(rst_n), .a_valid(a_valid), .a_ready(a_ready), .a_data(a_data),
    .clk_b(clk_b), .rst_b_n(rst_n), .b_valid(b_valid), .b_data(b_data));

  logic [7:0] sent [100000];
  logic       fire, prev_valid_hold;
  initial begin errs = 0; nsent = 0; nrecv = 0; fire = 0; end

  // A 侧：下降沿驱动，驱动后马上判断下一个上升沿是否握手成功
  always @(negedge clk_a) if (rst_n) begin
    if ((^a_ready) === 1'bx) begin errs++; if (errs <= 5) $display("[%0t] ERROR 实例%0d: a_ready 为 X", $time, ID); end
    if (!a_valid || fire) begin
      a_valid = run && (($urandom % 100) < 60);
      a_data  = $urandom;
    end
    #0.1;
    fire = a_valid && a_ready;
    if (fire) begin sent[nsent] = a_data; nsent++; end
  end

  // B 侧：下降沿采样
  always @(negedge clk_b) if (rst_n) begin
    if ((^b_valid) === 1'bx) begin errs++; if (errs <= 5) $display("[%0t] ERROR 实例%0d: b_valid 为 X", $time, ID); end
    else if (b_valid) begin
      if (nrecv >= nsent) begin
        errs++; if (errs <= 5) $display("[%0t] ERROR 实例%0d: B 侧收到多余的数据 0x%h", $time, ID, b_data);
      end else if (b_data !== sent[nrecv]) begin
        errs++; if (errs <= 5) $display("[%0t] ERROR 实例%0d: 第 %0d 个数据 b_data=0x%h，期望 0x%h", $time, ID, nrecv, b_data, sent[nrecv]);
      end
      nrecv++;
    end
  end
endmodule

module tb;
  int errors = 0;
  int unsigned seed = 1;
  logic rst_n = 0, run = 1;

  int e1, s1, r1, e2, s2, r2;
  hs_tester #(.TA(10.0), .TB(13.7), .ID(1)) t1 (.rst_n(rst_n), .run(run), .errs(e1), .nsent(s1), .nrecv(r1));
  hs_tester #(.TA(31.0), .TB(7.0),  .ID(2)) t2 (.rst_n(rst_n), .run(run), .errs(e2), .nsent(s2), .nrecv(r2));

  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    #100 rst_n = 1;
    #150us run = 0;
    #3us;
    errors = e1 + e2;
    if (s1 != r1) begin errors++; $display("ERROR 实例1: A 侧发送 %0d 个，B 侧收到 %0d 个", s1, r1); end
    if (s2 != r2) begin errors++; $display("ERROR 实例2: A 侧发送 %0d 个，B 侧收到 %0d 个", s2, r2); end
    if (s1 < 1000 || s2 < 1000) begin errors++; $display("ERROR 传输的数据太少（实例1: %0d，实例2: %0d），握手卡住了？", s1, s2); end
    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
