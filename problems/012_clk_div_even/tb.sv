`timescale 1ns/1ps
// 测量一个时钟信号的周期和高电平宽度
module clk_meas #(parameter real PERIOD = 40.0, parameter real HIGH = 20.0, parameter int ID = 0) (
  input  logic clk_mon,
  input  logic en,
  output int   errs,
  output int   nper
);
  realtime tr, d;
  bit have_r = 0;
  initial begin errs = 0; nper = 0; end
  always @(posedge clk_mon) if (en) begin
    if (have_r) begin
      d = $realtime - tr;
      if (d - PERIOD > 0.01 || PERIOD - d > 0.01) begin
        errs++; if (errs <= 5) $display("[%0t] ERROR N=%0d: 周期 = %0.2f ns，期望 %0.2f ns", $time, ID, d, PERIOD);
      end
      nper++;
    end
    tr = $realtime; have_r = 1;
  end
  always @(negedge clk_mon) if (en && have_r) begin
    d = $realtime - tr;
    if (d - HIGH > 0.01 || HIGH - d > 0.01) begin
      errs++; if (errs <= 5) $display("[%0t] ERROR N=%0d: 高电平宽度 = %0.2f ns，期望 %0.2f ns", $time, ID, d, HIGH);
    end
  end
endmodule

module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic clk = 0, rst_n = 0, en = 0;
  always #5 clk = ~clk;      // 10 ns

  logic o2, o4, o6, o10;
  int e2, e4, e6, e10, p2, p4, p6, p10;
  clk_div_even #(.N(2))  d2  (.clk(clk), .rst_n(rst_n), .clk_out(o2));
  clk_div_even #(.N(4))  d4  (.clk(clk), .rst_n(rst_n), .clk_out(o4));
  clk_div_even #(.N(6))  d6  (.clk(clk), .rst_n(rst_n), .clk_out(o6));
  clk_div_even #(.N(10)) d10 (.clk(clk), .rst_n(rst_n), .clk_out(o10));
  clk_meas #(.PERIOD(20.0),  .HIGH(10.0), .ID(2))  m2  (.clk_mon(o2),  .en(en), .errs(e2),  .nper(p2));
  clk_meas #(.PERIOD(40.0),  .HIGH(20.0), .ID(4))  m4  (.clk_mon(o4),  .en(en), .errs(e4),  .nper(p4));
  clk_meas #(.PERIOD(60.0),  .HIGH(30.0), .ID(6))  m6  (.clk_mon(o6),  .en(en), .errs(e6),  .nper(p6));
  clk_meas #(.PERIOD(100.0), .HIGH(50.0), .ID(10)) m10 (.clk_mon(o10), .en(en), .errs(e10), .nper(p10));

  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    repeat (2) @(posedge clk);
    #1;
    if ({o2, o4, o6, o10} !== 4'b0) begin errors++; $display("ERROR 复位期间 clk_out 应为 0，实际 N=2/4/6/10: %b%b%b%b", o2, o4, o6, o10); end
    @(negedge clk) rst_n = 1;
    repeat (30) @(posedge clk);
    en = 1;
    repeat (1000) @(negedge clk)
      if ((^{o2, o4, o6, o10}) === 1'bx) begin errors++; if (errors <= 5) $display("[%0t] ERROR clk_out 出现 X/Z", $time); end
    en = 0;

    errors += e2 + e4 + e6 + e10;
    if (p2 < 490 || p4 < 240 || p6 < 160 || p10 < 95) begin
      errors++; $display("ERROR 测到的完整周期数太少（N=2:%0d N=4:%0d N=6:%0d N=10:%0d），clk_out 没有正常翻转？", p2, p4, p6, p10);
    end
    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
