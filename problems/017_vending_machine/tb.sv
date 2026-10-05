`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic clk = 0, rst_n = 0;
  logic [1:0] coin = 0;
  logic drink, change;
  always #5 clk = ~clk;

  vending dut (.clk(clk), .rst_n(rst_n), .coin(coin), .drink(drink), .change(change));

  // 参考模型：金额以 0.5 元为单位
  int total, e_drink, e_change, n_drink, n_change;
  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin total = 0; e_drink = 0; e_change = 0; end
    else begin
      e_drink = 0; e_change = 0;
      if (coin == 2'b01) total += 1;
      if (coin == 2'b10) total += 2;
      if (total >= 3) begin
        e_drink = 1; e_change = (total == 4); total = 0;
        n_drink++; n_change += e_change;
      end
    end

  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    n_drink = 0; n_change = 0;
    repeat (3) @(posedge clk);
    @(negedge clk) rst_n = 1;
    for (int n = 0; n < 8000; n++) begin
      @(negedge clk);
      `TB_CHECK(drink  === e_drink[0],  ("[%0t] ERROR drink=%b, 期望 %b",  $time, drink,  e_drink[0]))
      `TB_CHECK(change === e_change[0], ("[%0t] ERROR change=%b, 期望 %b", $time, change, e_change[0]))
      coin = ($urandom % 100 < 40) ? 2'b00 : $urandom;
    end
    `TB_CHECK(n_drink > 500 && n_change > 100, ("ERROR 覆盖不足：出货 %0d 次，找零 %0d 次", n_drink, n_change))

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
