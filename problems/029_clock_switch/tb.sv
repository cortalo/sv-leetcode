`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic clk0 = 0, clk1 = 0, rst_n = 0, sel = 0, en = 0;
  logic clk_out;
  initial forever #5 clk0 = ~clk0;                    // 10 ns，高 5 ns
  initial begin #3.3; forever #13 clk1 = ~clk1; end   // 26 ns，高 13 ns

  clk_switch dut (.clk0(clk0), .clk1(clk1), .rst_n(rst_n), .sel(sel), .clk_out(clk_out));

  realtime t_rise, t_fall, t_prev_rise, t_sel;
  realtime w;
  int nrise, nper_checked;

  initial begin t_rise = -1; t_fall = -1; t_prev_rise = -1; t_sel = 0; nrise = 0; nper_checked = 0; end

  function automatic logic close(input realtime a, input realtime b);
    return (a - b < 0.01) && (b - a < 0.01);
  endfunction

  always @(posedge clk_out) if (en) begin
    if (t_fall >= 0) begin
      w = $realtime - t_fall;
      `TB_CHECK(w > 5.0 - 0.01, ("[%0t] ERROR 低电平只有 %0.2f ns（毛刺！至少应为 5 ns）", $time, w))
    end
    // sel 稳定 150ns 以上时，检查输出周期
    if (t_prev_rise >= 0 && t_prev_rise - t_sel > 150.0) begin
      w = $realtime - t_prev_rise;
      `TB_CHECK(close(w, sel ? 26.0 : 10.0), ("[%0t] ERROR sel=%0d 已稳定，clk_out 周期 = %0.2f ns，期望 %0.1f ns", $time, sel, w, sel ? 26.0 : 10.0))
      nper_checked++;
    end
    t_prev_rise = $realtime;
    t_rise = $realtime;
    nrise++;
  end

  always @(negedge clk_out) if (en && t_rise >= 0) begin
    w = $realtime - t_rise;
    `TB_CHECK(close(w, 5.0) || close(w, 13.0), ("[%0t] ERROR 高电平宽度 %0.2f ns，应为 5 ns（clk0）或 13 ns（clk1）——出现了毛刺/截短的脉冲", $time, w))
    t_fall = $realtime;
  end

  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    #40;
    `TB_CHECK(clk_out === 1'b0, ("[%0t] ERROR 复位期间 clk_out 应为 0", $time))
    #7.7 rst_n = 1;
    #100 en = 1;
    for (int n = 0; n < 300; n++) begin
      #(150 + $urandom % 250 + ($urandom % 1000) / 1000.0);
      sel = ~sel;
      t_sel = $realtime;
    end
    #500;
    en = 0;
    `TB_CHECK(nrise > 5000 && nper_checked > 2000, ("ERROR clk_out 翻转次数太少（上升沿 %0d 个，检查过周期的 %0d 个）", nrise, nper_checked))

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
