`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic clk = 0, rst_n = 0, din = 0;
  logic rise, fall, both;
  always #5 clk = ~clk;

  edge_detect dut (.clk(clk), .rst_n(rst_n), .din(din), .rise(rise), .fall(fall), .both(both));

  logic prev, er, ef;
  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    repeat (3) @(posedge clk);
    @(negedge clk) rst_n = 1;
    for (int n = 0; n < 5000; n++) begin
      @(posedge clk); prev = din;            // 上升沿时刻寄存的旧值
      #1 if ($urandom % 3 == 0) din = ~din;  // 上升沿之后 din 变化
      @(negedge clk);
      er = din & ~prev; ef = ~din & prev;
      `TB_CHECK(rise === er,        ("[%0t] ERROR din %b->%b: rise=%b, 期望 %b", $time, prev, din, rise, er))
      `TB_CHECK(fall === ef,        ("[%0t] ERROR din %b->%b: fall=%b, 期望 %b", $time, prev, din, fall, ef))
      `TB_CHECK(both === (er | ef), ("[%0t] ERROR din %b->%b: both=%b, 期望 %b", $time, prev, din, both, er | ef))
    end

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
