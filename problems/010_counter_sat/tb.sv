`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic clk = 0, rst = 1, clr = 0, en = 0;
  logic [2:0] cnt3; logic full3;
  logic [3:0] cnt4; logic full4;
  always #5 clk = ~clk;

  counter_sat #(.W(3)) u3 (.clk(clk), .rst(rst), .clr(clr), .en(en), .cnt(cnt3), .full(full3));
  counter_sat #(.W(4)) u4 (.clk(clk), .rst(rst), .clr(clr), .en(en), .cnt(cnt4), .full(full4));

  // 参考模型
  int m3, m4;
  always @(posedge clk or posedge rst)
    if (rst) begin m3 <= 0; m4 <= 0; end
    else begin
      if (clr) m3 <= 0; else if (en && m3 != 7)  m3 <= m3 + 1;
      if (clr) m4 <= 0; else if (en && m4 != 15) m4 <= m4 + 1;
    end

  task automatic check(input string where);
    `TB_CHECK(cnt3 === m3,          ("[%0t] ERROR W=3 %s: cnt=%0d, 期望 %0d", $time, where, cnt3, m3))
    `TB_CHECK(full3 === (m3 == 7),  ("[%0t] ERROR W=3 %s: full=%b, 期望 %b", $time, where, full3, m3 == 7))
    `TB_CHECK(cnt4 === m4,          ("[%0t] ERROR W=4 %s: cnt=%0d, 期望 %0d", $time, where, cnt4, m4))
    `TB_CHECK(full4 === (m4 == 15), ("[%0t] ERROR W=4 %s: full=%b, 期望 %b", $time, where, full4, m4 == 15))
  endtask

  int phase_en;
  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    repeat (3) @(posedge clk);
    @(negedge clk) rst = 0;
    for (int n = 0; n < 6000; n++) begin
      @(negedge clk);
      check("正常计数");
      // 偶尔在周期中间打一个异步复位脉冲
      if ($urandom % 100 < 2) begin
        #1 rst = 1;
        #1 check("异步复位应立即生效（不等时钟沿）");
        #1 rst = 0;
      end
      phase_en = (n / 300) % 3;              // 不同阶段 en 的密度不同，保证能计满
      en  = ($urandom % 100) < (phase_en == 0 ? 95 : phase_en == 1 ? 60 : 20);
      clr = ($urandom % 100) < 3;
    end

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
