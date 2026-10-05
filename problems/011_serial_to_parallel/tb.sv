`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic clk = 0, rst_n = 0, din = 0, din_valid = 0;
  logic [7:0] dout; logic dout_valid;
  always #5 clk = ~clk;

  s2p dut (.clk(clk), .rst_n(rst_n), .din(din), .din_valid(din_valid), .dout(dout), .dout_valid(dout_valid));

  // 参考模型
  logic [7:0] m_sh, m_dout; int m_cnt; logic m_valid; int n_bytes;
  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin m_sh = 0; m_cnt = 0; m_valid = 0; end
    else begin
      m_valid = 0;
      if (din_valid) begin
        m_sh = {m_sh[6:0], din};
        m_cnt++;
        if (m_cnt == 8) begin m_cnt = 0; m_valid = 1; m_dout = m_sh; n_bytes++; end
      end
    end

  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    n_bytes = 0;
    repeat (3) @(posedge clk);
    @(negedge clk) rst_n = 1;
    for (int n = 0; n < 6000; n++) begin
      @(negedge clk);
      `TB_CHECK(dout_valid === m_valid, ("[%0t] ERROR dout_valid=%b, 期望 %b", $time, dout_valid, m_valid))
      if (m_valid) `TB_CHECK(dout === m_dout, ("[%0t] ERROR dout=0x%h, 期望 0x%h", $time, dout, m_dout))
      // 前 2000 拍连续有效，之后随机间隔
      din_valid = (n < 2000) ? 1'b1 : (($urandom % 100) < 50);
      din = $urandom;
    end
    `TB_CHECK(n_bytes > 400, ("ERROR 测试只产生了 %0d 个字节，覆盖不足", n_bytes))

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
