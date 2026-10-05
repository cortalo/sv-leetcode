`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic [6:0]  t7;  logic [2:0] b7;  logic v7;
  logic [7:0]  t8;  logic [3:0] b8;  logic v8;
  logic [14:0] t15; logic [3:0] b15; logic v15;

  thermo2bin #(.W(7))  u7  (.thermo(t7),  .bin(b7),  .valid(v7));
  thermo2bin #(.W(8))  u8  (.thermo(t8),  .bin(b8),  .valid(v8));
  thermo2bin #(.W(15)) u15 (.thermo(t15), .bin(b15), .valid(v15));

  // 返回 1 的个数；若不是合法温度计码返回 -1
  function automatic int ref_t2b(input logic [31:0] v, input int w);
    int k = 0;
    logic [31:0] mask;
    for (int i = 0; i < w; i++) k += v[i];
    mask = (k == 32) ? '1 : ((32'd1 << k) - 1);
    return (v == mask) ? k : -1;
  endfunction

  int e;
  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    for (int i = 0; i < 128; i++) begin
      t7 = i[6:0]; #1; e = ref_t2b(i, 7);
      `TB_CHECK(v7 === (e >= 0), ("ERROR W=7  thermo=%b -> valid=%b, 期望 %b", t7, v7, e >= 0))
      if (e >= 0) `TB_CHECK(b7 === e, ("ERROR W=7  thermo=%b -> bin=%0d, 期望 %0d", t7, b7, e))
    end
    for (int i = 0; i < 256; i++) begin
      t8 = i[7:0]; #1; e = ref_t2b(i, 8);
      `TB_CHECK(v8 === (e >= 0), ("ERROR W=8  thermo=%b -> valid=%b, 期望 %b", t8, v8, e >= 0))
      if (e >= 0) `TB_CHECK(b8 === e, ("ERROR W=8  thermo=%b -> bin=%0d, 期望 %0d", t8, b8, e))
    end
    for (int i = 0; i < 32768; i++) begin
      t15 = i[14:0]; #1; e = ref_t2b(i, 15);
      `TB_CHECK(v15 === (e >= 0), ("ERROR W=15 thermo=%b -> valid=%b, 期望 %b", t15, v15, e >= 0))
      if (e >= 0) `TB_CHECK(b15 === e, ("ERROR W=15 thermo=%b -> bin=%0d, 期望 %0d", t15, b15, e))
    end

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
