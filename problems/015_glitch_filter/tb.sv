`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic clk = 0, rst_n = 0, din = 0;
  logic dout;
  always #5 clk = ~clk;

  glitch_filter dut (.clk(clk), .rst_n(rst_n), .din(din), .dout(dout));

  // 参考模型
  logic s1, s2, m_dout; int ntoggle;
  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin s1 = 0; s2 = 0; m_dout = 0; end
    else begin
      if (din == s1 && s1 == s2 && din != m_dout) begin m_dout = din; ntoggle++; end
      s2 = s1; s1 = din;
    end

  int run, level;
  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    ntoggle = 0; run = 0; level = 0;
    repeat (3) @(posedge clk);
    @(negedge clk) rst_n = 1;
    for (int n = 0; n < 8000; n++) begin
      @(negedge clk);
      `TB_CHECK(dout === m_dout, ("[%0t] ERROR 最近三次采样(新→旧)=%b%b%b: dout=%b, 期望 %b", $time, s1, s2, din, dout, m_dout))
      if (run == 0) begin
        // 下一段：有时是长电平（真实翻转），有时是 1~2 拍毛刺，有时是恰好 3 拍
        case ($urandom % 4)
          0:       begin level = ~level; run = 4 + $urandom % 10; end
          1:       begin level = ~level; run = 3; end
          default: begin level = ~level; run = 1 + $urandom % 2; end
        endcase
      end
      din = level[0];
      run--;
    end
    `TB_CHECK(ntoggle > 300, ("ERROR dout 只翻转了 %0d 次，覆盖不足", ntoggle))

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
