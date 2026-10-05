`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic        in1,  o1;
  logic [7:0]  in8;  logic o8;
  logic [15:0] in16; logic o16;

  thermo_check #(.W(1))  u1  (.in(in1),  .is_thermo(o1));
  thermo_check #(.W(8))  u8  (.in(in8),  .is_thermo(o8));
  thermo_check #(.W(16)) u16 (.in(in16), .is_thermo(o16));

  // 参考模型：数 1 的个数 k，合法当且仅当 in == 低 k 位全 1
  function automatic logic ref_thermo(input logic [31:0] v, input int w);
    int k = 0;
    logic [31:0] mask;
    for (int i = 0; i < w; i++) k += v[i];
    mask = (k == 32) ? '1 : ((32'd1 << k) - 1);
    return v == mask;
  endfunction

  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    for (int i = 0; i < 2; i++) begin
      in1 = i[0]; #1;
      `TB_CHECK(o1 === ref_thermo(i, 1), ("ERROR W=1  in=%b -> is_thermo=%b, 期望 %b", in1, o1, ref_thermo(i, 1)))
    end
    for (int i = 0; i < 256; i++) begin
      in8 = i[7:0]; #1;
      `TB_CHECK(o8 === ref_thermo(i, 8), ("ERROR W=8  in=%b -> is_thermo=%b, 期望 %b", in8, o8, ref_thermo(i, 8)))
    end
    for (int i = 0; i < 65536; i++) begin
      in16 = i[15:0]; #1;
      `TB_CHECK(o16 === ref_thermo(i, 16), ("ERROR W=16 in=%b -> is_thermo=%b, 期望 %b", in16, o16, ref_thermo(i, 16)))
    end

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
