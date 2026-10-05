`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic clk = 0, arst_n = 1;
  logic rst_n_sync;
  always #5 clk = ~clk;     // 上升沿在 5, 15, 25 ... ns

  reset_sync dut (.clk(clk), .arst_n(arst_n), .rst_n_sync(rst_n_sync));

  int off;
  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    #0.1 arst_n = 0;          // 上电后立即复位
    #0.2 `TB_CHECK(rst_n_sync === 1'b0, ("[%0t] ERROR 上电复位期间 rst_n_sync=%b, 期望 0", $time, rst_n_sync))
    for (int n = 0; n < 200; n++) begin
      // 保持复位 1~3 个周期，然后在周期中间随机时刻释放
      repeat (1 + $urandom % 3) @(posedge clk);
      off = 1 + $urandom % 9;
      #(off) arst_n = 1;
      #0.2 `TB_CHECK(rst_n_sync === 1'b0, ("[%0t] ERROR 释放后、第 1 个上升沿之前 rst_n_sync=%b, 期望 0", $time, rst_n_sync))
      @(posedge clk);
      #0.5 `TB_CHECK(rst_n_sync === 1'b0, ("[%0t] ERROR 释放后第 1 个上升沿之后 rst_n_sync=%b, 期望 0（要两级同步）", $time, rst_n_sync))
      @(posedge clk);
      #0.5 `TB_CHECK(rst_n_sync === 1'b1, ("[%0t] ERROR 释放后第 2 个上升沿之后 rst_n_sync=%b, 期望 1", $time, rst_n_sync))
      repeat ($urandom % 6) begin
        @(negedge clk);
        `TB_CHECK(rst_n_sync === 1'b1, ("[%0t] ERROR 正常工作期间 rst_n_sync=%b, 期望 1", $time, rst_n_sync))
      end
      // 在周期中间随机时刻拉低
      @(posedge clk);
      off = 1 + $urandom % 9;
      #(off) arst_n = 0;
      #0.2 `TB_CHECK(rst_n_sync === 1'b0, ("[%0t] ERROR arst_n 拉低后 rst_n_sync=%b, 期望立即为 0（异步复位）", $time, rst_n_sync))
    end

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
