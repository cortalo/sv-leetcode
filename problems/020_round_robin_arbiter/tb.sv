`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  logic [3:0] req4 = 0, gnt4;
  logic [6:0] req7 = 0, gnt7;
  rr_arb #(.N(4)) u4 (.clk(clk), .rst_n(rst_n), .req(req4), .gnt(gnt4));
  rr_arb #(.N(7)) u7 (.clk(clk), .rst_n(rst_n), .req(req7), .gnt(gnt7));

  // 参考模型：ptr = 当前最高优先级的编号
  int ptr4, ptr7;
  function automatic int ref_idx(input logic [31:0] r, input int n, input int ptr);
    for (int k = 0; k < n; k++) if (r[(ptr + k) % n]) return (ptr + k) % n;
    return -1;
  endfunction
  function automatic logic [31:0] gen_req(input int n, input int mode);
    logic [31:0] r;
    case (mode)
      0: r = 0;
      1: r = '1;
      2: r = 32'd1 << ($urandom % n);
      3: r = $urandom & $urandom;
      default: r = $urandom;
    endcase
    return r & ((32'd1 << n) - 1);
  endfunction

  int i4, i7;
  logic [31:0] e4, e7;
  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    ptr4 = 0; ptr7 = 0;
    repeat (3) @(posedge clk);
    @(negedge clk) rst_n = 1;
    for (int n = 0; n < 10000; n++) begin
      @(posedge clk);
      // 时钟沿：按当前 req 更新模型的优先级
      i4 = ref_idx(req4, 4, ptr4); if (i4 >= 0) ptr4 = (i4 + 1) % 4;
      i7 = ref_idx(req7, 7, ptr7); if (i7 >= 0) ptr7 = (i7 + 1) % 7;
      #1;
      e4 = gen_req(4, (n % 50 < 10) ? 1 : $urandom % 6); req4 = e4[3:0];
      e7 = gen_req(7, (n % 50 < 10) ? 1 : $urandom % 6); req7 = e7[6:0];
      @(negedge clk);
      i4 = ref_idx(req4, 4, ptr4); e4 = (i4 >= 0) ? (32'd1 << i4) : 0;
      i7 = ref_idx(req7, 7, ptr7); e7 = (i7 >= 0) ? (32'd1 << i7) : 0;
      `TB_CHECK(gnt4 === e4[3:0], ("[%0t] ERROR N=4 req=%b 当前最高优先级=%0d: gnt=%b, 期望 %b", $time, req4, ptr4, gnt4, e4[3:0]))
      `TB_CHECK(gnt7 === e7[6:0], ("[%0t] ERROR N=7 req=%b 当前最高优先级=%0d: gnt=%b, 期望 %b", $time, req7, ptr7, gnt7, e7[6:0]))
    end

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
