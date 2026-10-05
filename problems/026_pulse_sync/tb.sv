`timescale 1ns/1ps
module ps_tester #(parameter real TA = 10.0, parameter real TB = 27.0, parameter int ID = 0) (
  input  logic rst_n,
  input  logic run,
  output int   errs,
  output int   na,
  output int   nb
);
  logic clk_a = 0, clk_b = 0, pulse_a = 0, pulse_b;
  initial forever #(TA / 2) clk_a = ~clk_a;
  initial begin #(TB / 3); forever #(TB / 2) clk_b = ~clk_b; end

  pulse_sync dut (.clk_a(clk_a), .rst_a_n(rst_n), .pulse_a(pulse_a),
                  .clk_b(clk_b), .rst_b_n(rst_n), .pulse_b(pulse_b));

  localparam real TSLOW = (TA > TB) ? TA : TB;
  realtime ta [10000];
  realtime lat;
  logic prev_b;
  initial begin errs = 0; na = 0; nb = 0; prev_b = 0; end

  // 发送：在 clk_a 下降沿拉高一个周期
  initial begin
    wait (rst_n);
    while (1) begin
      #(5 * TSLOW + ($urandom % 100) * TSLOW / 30.0);
      if (!run) break;
      @(negedge clk_a) pulse_a = 1;
      @(negedge clk_a) pulse_a = 0;
    end
  end
  always @(posedge clk_a) if (pulse_a) begin ta[na] = $realtime; na++; end

  // 接收：在 clk_b 下降沿采样
  always @(negedge clk_b) if (rst_n) begin
    if ((^pulse_b) === 1'bx) begin
      errs++; if (errs <= 5) $display("[%0t] ERROR 实例%0d: pulse_b 为 X/Z", $time, ID);
    end else if (pulse_b && prev_b) begin
      errs++; if (errs <= 5) $display("[%0t] ERROR 实例%0d: pulse_b 宽度超过 1 个 clk_b 周期", $time, ID);
    end else if (pulse_b) begin
      if (nb >= na) begin
        errs++; if (errs <= 5) $display("[%0t] ERROR 实例%0d: 多出来一个 pulse_b（输入只有 %0d 个脉冲）", $time, ID, na);
      end else begin
        lat = $realtime - ta[nb];
        if (lat > 4 * TB + TA + TB / 2) begin
          errs++; if (errs <= 5) $display("[%0t] ERROR 实例%0d: 第 %0d 个脉冲延迟 %0.1f ns，超过 4*Tb+Ta", $time, ID, nb, lat);
        end
      end
      nb++;
    end
    prev_b = pulse_b;
  end
endmodule

module tb;
  int errors = 0;
  int unsigned seed = 1;
  logic rst_n = 0, run = 1;

  int e1, a1, b1, e2, a2, b2;
  ps_tester #(.TA(10.0), .TB(27.0), .ID(1)) t1 (.rst_n(rst_n), .run(run), .errs(e1), .na(a1), .nb(b1));  // 快 -> 慢
  ps_tester #(.TA(27.0), .TB(10.0), .ID(2)) t2 (.rst_n(rst_n), .run(run), .errs(e2), .na(a2), .nb(b2));  // 慢 -> 快

  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    #100 rst_n = 1;
    #120us run = 0;
    #2us;
    errors = e1 + e2;
    if (a1 != b1) begin errors++; $display("ERROR 实例1（快→慢）: 输入 %0d 个脉冲，输出 %0d 个", a1, b1); end
    if (a2 != b2) begin errors++; $display("ERROR 实例2（慢→快）: 输入 %0d 个脉冲，输出 %0d 个", a2, b2); end
    if (a1 < 300 || a2 < 300) begin errors++; $display("ERROR 发送的脉冲太少"); end
    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
