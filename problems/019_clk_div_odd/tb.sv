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

  logic o3, o5, o7, o9;
  int e3, e5, e7, e9, p3, p5, p7, p9;
  clk_div_odd #(.N(3)) d3 (.clk(clk), .rst_n(rst_n), .clk_out(o3));
  clk_div_odd #(.N(5)) d5 (.clk(clk), .rst_n(rst_n), .clk_out(o5));
  clk_div_odd #(.N(7)) d7 (.clk(clk), .rst_n(rst_n), .clk_out(o7));
  clk_div_odd #(.N(9)) d9 (.clk(clk), .rst_n(rst_n), .clk_out(o9));
  clk_meas #(.PERIOD(30.0), .HIGH(15.0), .ID(3)) m3 (.clk_mon(o3), .en(en), .errs(e3), .nper(p3));
  clk_meas #(.PERIOD(50.0), .HIGH(25.0), .ID(5)) m5 (.clk_mon(o5), .en(en), .errs(e5), .nper(p5));
  clk_meas #(.PERIOD(70.0), .HIGH(35.0), .ID(7)) m7 (.clk_mon(o7), .en(en), .errs(e7), .nper(p7));
  clk_meas #(.PERIOD(90.0), .HIGH(45.0), .ID(9)) m9 (.clk_mon(o9), .en(en), .errs(e9), .nper(p9));

  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    repeat (2) @(posedge clk);
    #1;
    if ({o3, o5, o7, o9} !== 4'b0) begin errors++; $display("ERROR 复位期间 clk_out 应为 0，实际 N=3/5/7/9: %b%b%b%b", o3, o5, o7, o9); end
    @(negedge clk) rst_n = 1;
    repeat (30) @(posedge clk);
    en = 1;
    repeat (900) @(negedge clk)
      if ((^{o3, o5, o7, o9}) === 1'bx) begin errors++; if (errors <= 5) $display("[%0t] ERROR clk_out 出现 X/Z", $time); end
    en = 0;

    errors += e3 + e5 + e7 + e9;
    if (p3 < 290 || p5 < 170 || p7 < 120 || p9 < 95) begin
      errors++; $display("ERROR 测到的完整周期数太少（N=3:%0d N=5:%0d N=7:%0d N=9:%0d），clk_out 没有正常翻转？", p3, p5, p7, p9);
    end
    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
