`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic clk = 0, rst_n = 0, din = 0;
  logic match;
  always #5 clk = ~clk;

  seq_detect dut (.clk(clk), .rst_n(rst_n), .din(din), .match(match));

  // 参考模型：记录最近 5 位，以及复位后收到的位数
  logic [4:0] hist; int nbits, nmatch; logic exp_m;
  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin hist = 0; nbits = 0; exp_m = 0; end
    else begin
      hist = {hist[3:0], din};
      nbits++;
      exp_m = (nbits >= 5) && (hist == 5'b10110);
      if (exp_m) nmatch++;
    end

  // 待发送的比特流：随机比特 + 插入目标序列/重叠序列
  logic [15:0] chunk; int clen;
  task automatic next_chunk();
    case ($urandom % 6)
      0: begin chunk = 16'b10110;    clen = 5; end
      1: begin chunk = 16'b10110110; clen = 8; end     // 重叠
      2: begin chunk = 16'b1011;     clen = 4; end     // 差一位
      3: begin chunk = 16'b101;      clen = 3; end
      default: begin chunk = $urandom; clen = 1 + $urandom % 6; end
    endcase
  endtask

  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    nmatch = 0; clen = 0;
    repeat (3) @(posedge clk);
    @(negedge clk) rst_n = 1;
    for (int n = 0; n < 10000; n++) begin
      @(negedge clk);
      `TB_CHECK(match === exp_m, ("[%0t] ERROR 最近输入(旧→新)=%b: match=%b, 期望 %b", $time, hist, match, exp_m))
      if (n == 5000) begin                 // 中途再复位一次
        rst_n = 0; #1 rst_n = 1;
      end
      if (clen == 0) next_chunk();
      clen--;
      din = chunk[clen];
    end
    `TB_CHECK(nmatch > 200, ("ERROR 测试中只出现 %0d 次匹配，覆盖不足", nmatch))

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
