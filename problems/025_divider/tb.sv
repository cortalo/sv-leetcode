`timescale 1ns/1ps
module div_tester #(parameter int W = 8) (
  input  logic clk,
  input  logic rst_n,
  output int   errs,
  output int   nops
);
  logic         start = 0, busy, done;
  logic [W-1:0] dividend = 0, divisor = 0, quotient, remainder;

  divider #(.W(W)) dut (
    .clk(clk), .rst_n(rst_n), .start(start), .dividend(dividend), .divisor(divisor),
    .busy(busy), .done(done), .quotient(quotient), .remainder(remainder));

  localparam logic [W-1:0] ALL1 = '1;
  logic         pending, have_res;
  logic [W-1:0] p_a, p_b, eq, er;
  int           wait_cyc;
  initial begin errs = 0; nops = 0; pending = 0; have_res = 0; end

  task automatic err(input string s);
    errs++; if (errs <= 6) $display("[%0t] ERROR W=%0d: %s", $time, W, s);
  endtask

  always @(negedge clk) if (rst_n) begin
    // ---------- 检查当前拍 ----------
    if ((^{busy, done}) === 1'bx) err("busy/done 出现 X");
    if (done) begin
      if (!pending) err("没有正在进行的运算却出现 done");
      else begin
        if (busy) err("done 那一拍 busy 应为 0");
        if (quotient !== eq || remainder !== er)
          err($sformatf("%0d / %0d: quotient=%0d remainder=%0d，期望 %0d 和 %0d", p_a, p_b, quotient, remainder, eq, er));
        pending = 0; have_res = 1; nops++;
      end
    end else if (pending) begin
      wait_cyc++;
      if (!busy) err($sformatf("%0d / %0d 计算期间 busy 应为 1", p_a, p_b));
      if (wait_cyc > W + 2) begin err($sformatf("%0d / %0d 超过 W+2 拍还没有 done", p_a, p_b)); pending = 0; end
    end else begin
      if (busy) err("空闲时 busy 应为 0");
      if (have_res && (quotient !== eq || remainder !== er))
        err($sformatf("done 之后结果应保持：quotient=%0d remainder=%0d，期望 %0d 和 %0d", quotient, remainder, eq, er));
    end
    // ---------- 下一拍的激励 ----------
    #1;
    start = ($urandom % 100) < 40;
    case ($urandom % 8)
      0: begin dividend = $urandom; divisor = 0; end
      1: begin dividend = $urandom; divisor = 1; end
      2: begin dividend = $urandom % 16; divisor = $urandom; end
      3: begin dividend = '1; divisor = $urandom; end
      4: begin divisor = $urandom % 8 + 1; dividend = $urandom; end
      default: begin dividend = $urandom; divisor = $urandom >> ($urandom % W); end
    endcase
    // 下一个上升沿 start 会不会被接收（busy 在两个上升沿之间不变）
    if (start && !busy) begin
      pending = 1; wait_cyc = 1; p_a = dividend; p_b = divisor;
      eq = (divisor == 0) ? ALL1 : dividend / divisor;
      er = (divisor == 0) ? dividend : dividend % divisor;
    end
  end
endmodule

module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  int e8, n8, e13, n13;
  div_tester #(.W(8))  t8  (.clk(clk), .rst_n(rst_n), .errs(e8),  .nops(n8));
  div_tester #(.W(13)) t13 (.clk(clk), .rst_n(rst_n), .errs(e13), .nops(n13));

  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    repeat (3) @(posedge clk);
    @(negedge clk) rst_n = 1;
    repeat (20000) @(posedge clk);

    errors = e8 + e13;
    if (n8 < 500 || n13 < 500) begin errors++; $display("ERROR 完成的运算太少（W=8: %0d, W=13: %0d）", n8, n13); end
    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
