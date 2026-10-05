`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic [3:0] a4, b4, c4, d4; logic [4:0] s4;
  logic [7:0] a8, b8, c8, d8; logic [8:0] s8;

  mid2_sum #(.W(4)) u4 (.a(a4), .b(b4), .c(c4), .d(d4), .sum(s4));
  mid2_sum #(.W(8)) u8 (.a(a8), .b(b8), .c(c8), .d(d8), .sum(s8));

  function automatic int ref_mid2(input int x0, input int x1, input int x2, input int x3);
    int v[4];
    int t;
    v[0] = x0; v[1] = x1; v[2] = x2; v[3] = x3;
    for (int i = 0; i < 4; i++)
      for (int j = 0; j < 3 - i; j++)
        if (v[j] > v[j+1]) begin t = v[j]; v[j] = v[j+1]; v[j+1] = t; end
    return v[1] + v[2];
  endfunction

  int e;
  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    for (int i = 0; i < 65536; i++) begin
      {a4, b4, c4, d4} = i[15:0]; #1;
      e = ref_mid2(a4, b4, c4, d4);
      `TB_CHECK(s4 === e, ("ERROR W=4 a=%0d b=%0d c=%0d d=%0d -> sum=%0d, 期望 %0d", a4, b4, c4, d4, s4, e))
    end
    for (int i = 0; i < 20000; i++) begin
      a8 = $urandom; b8 = $urandom; c8 = $urandom; d8 = $urandom;
      if (i % 4 == 0) c8 = a8;          // 制造相等的情况
      #1;
      e = ref_mid2(a8, b8, c8, d8);
      `TB_CHECK(s8 === e, ("ERROR W=8 a=%0d b=%0d c=%0d d=%0d -> sum=%0d, 期望 %0d", a8, b8, c8, d8, s8, e))
    end

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
