`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic clk = 0, rst_n = 0;
  logic [7:0] n = 1;
  logic clk_out;
  always #5 clk = ~clk;      // 10 ns

  clk_div_n dut (.clk(clk), .rst_n(rst_n), .n(n), .clk_out(clk_out));

  initial begin
    #3ms;
    $display("FAIL: 超时（n=%0d 时 clk_out 没有正常翻转？）", n);
    $finish;
  end

  function automatic logic close(input realtime a, input realtime b);
    return (a - b < 0.01) && (b - a < 0.01);
  endfunction

  task automatic test_n(input int nn);
    realtime t_r0, t_f, t_r1;
    @(negedge clk) rst_n = 0; n = nn;
    repeat (3) @(posedge clk);
    @(negedge clk) rst_n = 1;
    repeat (3 * nn + 10) @(posedge clk);
    @(posedge clk_out); t_r0 = $realtime;
    for (int k = 0; k < 6; k++) begin
      @(negedge clk_out); t_f  = $realtime;
      @(posedge clk_out); t_r1 = $realtime;
      `TB_CHECK(close(t_r1 - t_r0, nn * 10.0), ("[%0t] ERROR n=%0d: 周期 = %0.2f ns，期望 %0.2f ns", $time, nn, t_r1 - t_r0, nn * 10.0))
      `TB_CHECK(close(t_f - t_r0, nn * 5.0),   ("[%0t] ERROR n=%0d: 高电平 = %0.2f ns，期望 %0.2f ns", $time, nn, t_f - t_r0, nn * 5.0))
      t_r0 = t_r1;
    end
  endtask

  int list [18] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 16, 17, 100, 127, 128, 254, 255};
  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    foreach (list[i]) test_n(list[i]);
    repeat (4) test_n(2 + $urandom % 60);

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
