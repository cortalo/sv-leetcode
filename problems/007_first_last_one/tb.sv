`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic [15:0] in16, f16, l16;
  logic [32:0] in33, f33, l33;

  first_last_one #(.W(16)) u16 (.in(in16), .first_oh(f16), .last_oh(l16));
  first_last_one #(.W(33)) u33 (.in(in33), .first_oh(f33), .last_oh(l33));

  function automatic logic [63:0] ref_first(input logic [63:0] v);
    for (int i = 0; i < 64; i++) if (v[i]) return 64'd1 << i;
    return '0;
  endfunction
  function automatic logic [63:0] ref_last(input logic [63:0] v);
    for (int i = 63; i >= 0; i--) if (v[i]) return 64'd1 << i;
    return '0;
  endfunction

  logic [63:0] ef, el;
  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    for (int i = 0; i < 65536; i++) begin
      in16 = i[15:0]; #1;
      ef = ref_first({48'b0, in16}); el = ref_last({48'b0, in16});
      `TB_CHECK(f16 === ef[15:0], ("ERROR W=16 in=%b -> first_oh=%b, 期望 %b", in16, f16, ef[15:0]))
      `TB_CHECK(l16 === el[15:0], ("ERROR W=16 in=%b -> last_oh=%b, 期望 %b",  in16, l16, el[15:0]))
    end
    for (int i = 0; i < 20000; i++) begin
      in33 = {$urandom, $urandom} >> ($urandom % 33);
      if (i % 3 == 0) in33 = in33 << ($urandom % 33);
      #1;
      ef = ref_first({31'b0, in33}); el = ref_last({31'b0, in33});
      `TB_CHECK(f33 === ef[32:0], ("ERROR W=33 in=%b -> first_oh=%b, 期望 %b", in33, f33, ef[32:0]))
      `TB_CHECK(l33 === el[32:0], ("ERROR W=33 in=%b -> last_oh=%b, 期望 %b",  in33, l33, el[32:0]))
    end

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
