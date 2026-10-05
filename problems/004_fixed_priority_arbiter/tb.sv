`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic        r1,  g1;
  logic [2:0]  r3,  g3;
  logic [7:0]  r8,  g8;
  logic [31:0] r32, g32;

  fixed_arb #(.N(1))  u1  (.req(r1),  .gnt(g1));
  fixed_arb #(.N(3))  u3  (.req(r3),  .gnt(g3));
  fixed_arb #(.N(8))  u8  (.req(r8),  .gnt(g8));
  fixed_arb #(.N(32)) u32 (.req(r32), .gnt(g32));

  function automatic logic [31:0] ref_gnt(input logic [31:0] r);
    for (int i = 0; i < 32; i++) if (r[i]) return 32'd1 << i;
    return '0;
  endfunction

  logic [31:0] e;
  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    for (int i = 0; i < 2; i++) begin
      r1 = i[0]; #1; e = ref_gnt(i);
      `TB_CHECK(g1 === e[0], ("ERROR N=1 req=%b -> gnt=%b, 期望 %b", r1, g1, e[0]))
    end
    for (int i = 0; i < 8; i++) begin
      r3 = i[2:0]; #1; e = ref_gnt(i);
      `TB_CHECK(g3 === e[2:0], ("ERROR N=3 req=%b -> gnt=%b, 期望 %b", r3, g3, e[2:0]))
    end
    for (int i = 0; i < 256; i++) begin
      r8 = i[7:0]; #1; e = ref_gnt(i);
      `TB_CHECK(g8 === e[7:0], ("ERROR N=8 req=%b -> gnt=%b, 期望 %b", r8, g8, e[7:0]))
    end
    for (int i = 0; i < 20000; i++) begin
      // 让低位的 0 多一些，覆盖"最低的 1 在高位"的情况
      r32 = $urandom & ($urandom << ($urandom % 32)); #1; e = ref_gnt(r32);
      `TB_CHECK(g32 === e, ("ERROR N=32 req=%h -> gnt=%h, 期望 %h", r32, g32, e))
    end

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
