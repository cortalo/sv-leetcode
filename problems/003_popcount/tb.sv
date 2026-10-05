`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic        in1;  logic       c1;
  logic [6:0]  in7;  logic [2:0] c7;
  logic [15:0] in16; logic [4:0] c16;
  logic [31:0] in32; logic [5:0] c32;

  popcount #(.W(1))  u1  (.in(in1),  .cnt(c1));
  popcount #(.W(7))  u7  (.in(in7),  .cnt(c7));
  popcount #(.W(16)) u16 (.in(in16), .cnt(c16));
  popcount #(.W(32)) u32 (.in(in32), .cnt(c32));

  function automatic int ref_pop(input logic [31:0] v);
    int k = 0;
    for (int i = 0; i < 32; i++) k += v[i];
    return k;
  endfunction

  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    for (int i = 0; i < 2; i++) begin
      in1 = i[0]; #1;
      `TB_CHECK(c1 === ref_pop(i), ("ERROR W=1  in=%b -> cnt=%0d, 期望 %0d", in1, c1, ref_pop(i)))
    end
    for (int i = 0; i < 128; i++) begin
      in7 = i[6:0]; #1;
      `TB_CHECK(c7 === ref_pop(i), ("ERROR W=7  in=%b -> cnt=%0d, 期望 %0d", in7, c7, ref_pop(i)))
    end
    for (int i = 0; i < 65536; i++) begin
      in16 = i[15:0]; #1;
      `TB_CHECK(c16 === ref_pop(i), ("ERROR W=16 in=%b -> cnt=%0d, 期望 %0d", in16, c16, ref_pop(i)))
    end
    for (int i = 0; i < 20000; i++) begin
      in32 = (i == 0) ? '1 : (i == 1) ? '0 : $urandom; #1;
      `TB_CHECK(c32 === ref_pop(in32), ("ERROR W=32 in=%h -> cnt=%0d, 期望 %0d", in32, c32, ref_pop(in32)))
    end

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
