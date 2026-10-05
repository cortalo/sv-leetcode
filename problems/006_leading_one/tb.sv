`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic [4:0]  in5;  logic [2:0] i5;  logic v5;
  logic [15:0] in16; logic [3:0] i16; logic v16;
  logic [31:0] in32; logic [4:0] i32; logic v32;

  lead_one #(.W(5))  u5  (.in(in5),  .idx(i5),  .valid(v5));
  lead_one #(.W(16)) u16 (.in(in16), .idx(i16), .valid(v16));
  lead_one #(.W(32)) u32 (.in(in32), .idx(i32), .valid(v32));

  function automatic int ref_lo(input logic [31:0] v);
    for (int i = 31; i >= 0; i--) if (v[i]) return i;
    return -1;
  endfunction

  int e;
  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    for (int i = 0; i < 32; i++) begin
      in5 = i[4:0]; #1; e = ref_lo(i);
      `TB_CHECK(v5 === (e >= 0), ("ERROR W=5  in=%b -> valid=%b, 期望 %b", in5, v5, e >= 0))
      if (e >= 0) `TB_CHECK(i5 === e, ("ERROR W=5  in=%b -> idx=%0d, 期望 %0d", in5, i5, e))
    end
    for (int i = 0; i < 65536; i++) begin
      in16 = i[15:0]; #1; e = ref_lo(i);
      `TB_CHECK(v16 === (e >= 0), ("ERROR W=16 in=%b -> valid=%b, 期望 %b", in16, v16, e >= 0))
      if (e >= 0) `TB_CHECK(i16 === e, ("ERROR W=16 in=%b -> idx=%0d, 期望 %0d", in16, i16, e))
    end
    for (int i = 0; i < 20000; i++) begin
      in32 = (i < 32) ? (32'd1 << i) : ($urandom >> ($urandom % 32)); #1; e = ref_lo(in32);
      `TB_CHECK(v32 === (e >= 0), ("ERROR W=32 in=%h -> valid=%b, 期望 %b", in32, v32, e >= 0))
      if (e >= 0) `TB_CHECK(i32 === e, ("ERROR W=32 in=%h -> idx=%0d, 期望 %0d", in32, i32, e))
    end

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
