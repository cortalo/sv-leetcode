`timescale 1ns/1ps
// 检查一个交通灯实例：独热、顺序 R->G->Y->R、每段长度
module light_checker #(parameter int R = 5, parameter int G = 4, parameter int Y = 2, parameter int ID = 0) (
  input  logic clk,
  input  logic en,
  input  logic red, green, yellow,
  output int   errs,
  output int   nseg
);
  // 0=red 1=green 2=yellow
  int cur, run, started;
  int lens[3];
  initial begin errs = 0; nseg = 0; cur = 0; run = 0; started = 0; lens[0] = R; lens[1] = G; lens[2] = Y; end

  always @(negedge clk) if (en) begin
    int c;
    if ({red, green, yellow} == 3'b100) c = 0;
    else if ({red, green, yellow} == 3'b010) c = 1;
    else if ({red, green, yellow} == 3'b001) c = 2;
    else begin
      c = -1;
      errs++; if (errs <= 5) $display("[%0t] ERROR 实例%0d: 灯不是独热 red=%b green=%b yellow=%b", $time, ID, red, green, yellow);
    end
    if (c >= 0) begin
      if (c == cur) run++;
      else begin
        if (c != (cur + 1) % 3) begin
          errs++; if (errs <= 5) $display("[%0t] ERROR 实例%0d: 顺序错误，从 %0d 跳到 %0d（0红 1绿 2黄）", $time, ID, cur, c);
        end
        if (started && run != lens[cur]) begin
          errs++; if (errs <= 5) $display("[%0t] ERROR 实例%0d: %s 灯持续了 %0d 个周期，期望 %0d", $time, ID,
                                          cur == 0 ? "红" : cur == 1 ? "绿" : "黄", run, lens[cur]);
        end
        if (c == 1) started = 1;      // 第一次变绿之后开始严格检查
        if (started) nseg++;
        cur = c; run = 1;
      end
    end
  end
endmodule

module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic clk = 0, rst_n = 0, en = 0;
  always #5 clk = ~clk;

  logic r1, g1, y1, r2, g2, y2;
  int e1, e2, n1, n2;
  traffic_light #(.R(5), .G(4), .Y(2)) u1 (.clk(clk), .rst_n(rst_n), .red(r1), .green(g1), .yellow(y1));
  traffic_light #(.R(3), .G(7), .Y(1)) u2 (.clk(clk), .rst_n(rst_n), .red(r2), .green(g2), .yellow(y2));
  light_checker #(.R(5), .G(4), .Y(2), .ID(1)) c1 (.clk(clk), .en(en), .red(r1), .green(g1), .yellow(y1), .errs(e1), .nseg(n1));
  light_checker #(.R(3), .G(7), .Y(1), .ID(2)) c2 (.clk(clk), .en(en), .red(r2), .green(g2), .yellow(y2), .errs(e2), .nseg(n2));

  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    repeat (2) @(posedge clk);
    #1;
    if (!(r1 === 1'b1 && g1 === 1'b0 && y1 === 1'b0 && r2 === 1'b1 && g2 === 1'b0 && y2 === 1'b0)) begin
      errors++; $display("ERROR 复位期间应该只有红灯亮");
    end
    @(negedge clk) rst_n = 1;
    en = 1;
    repeat (600) @(posedge clk);
    en = 0;

    errors += e1 + e2;
    if (n1 < 100 || n2 < 100) begin errors++; $display("ERROR 灯没有正常循环（检查到的段数：%0d / %0d）", n1, n2); end
    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
