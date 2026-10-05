`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic clk = 0, rst_n = 0, din = 0, din_valid = 0;
  logic div3;
  always #5 clk = ~clk;

  mod3_detect dut (.clk(clk), .rst_n(rst_n), .din(din), .din_valid(din_valid), .div3(div3));

  int rem, nbits;
  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin rem = 0; nbits = 0; end
    else if (din_valid) begin rem = (rem * 2 + din) % 3; nbits++; end

  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    repeat (3) @(posedge clk);
    @(negedge clk) rst_n = 1;
    for (int n = 0; n < 10000; n++) begin
      @(negedge clk);
      `TB_CHECK(div3 === (rem == 0), ("[%0t] ERROR 已收到 %0d 位，当前余数 %0d: div3=%b, 期望 %b", $time, nbits, rem, div3, rem == 0))
      if ($urandom % 200 == 0) begin rst_n = 0; #1 rst_n = 1; #1
        `TB_CHECK(div3 === 1'b1, ("[%0t] ERROR 复位后 div3=%b, 期望 1", $time, div3))
      end
      din_valid = (n < 3000) ? 1'b1 : (($urandom % 100) < 60);
      din = $urandom;
    end

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
