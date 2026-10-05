`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic [7:0]  b8,  g8,  go8,  bo8;
  logic [12:0] b13, g13, go13, bo13;

  gray_code #(.W(8))  u8  (.bin_i(b8),  .gray_o(go8),  .gray_i(g8),  .bin_o(bo8));
  gray_code #(.W(13)) u13 (.bin_i(b13), .gray_o(go13), .gray_i(g13), .bin_o(bo13));

  function automatic logic [31:0] ref_b2g(input logic [31:0] b);
    return b ^ (b >> 1);
  endfunction
  function automatic logic [31:0] ref_g2b(input logic [31:0] g);
    logic [31:0] b;
    b = g;
    for (int s = 1; s < 32; s = s * 2) b = b ^ (b >> s);
    return b;
  endfunction

  logic [31:0] e1, e2;
  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    for (int i = 0; i < 256; i++) begin
      b8 = i[7:0]; g8 = i[7:0]; #1;
      e1 = ref_b2g({24'b0, b8}); e2 = ref_g2b({24'b0, g8});
      `TB_CHECK(go8 === e1[7:0], ("ERROR W=8  bin_i=%b -> gray_o=%b, 期望 %b", b8, go8, e1[7:0]))
      `TB_CHECK(bo8 === e2[7:0], ("ERROR W=8  gray_i=%b -> bin_o=%b, 期望 %b", g8, bo8, e2[7:0]))
    end
    for (int i = 0; i < 5000; i++) begin
      b13 = $urandom; g13 = $urandom; #1;
      e1 = ref_b2g({19'b0, b13}); e2 = ref_g2b({19'b0, g13});
      `TB_CHECK(go13 === e1[12:0], ("ERROR W=13 bin_i=%b -> gray_o=%b, 期望 %b", b13, go13, e1[12:0]))
      `TB_CHECK(bo13 === e2[12:0], ("ERROR W=13 gray_i=%b -> bin_o=%b, 期望 %b", g13, bo13, e2[12:0]))
    end

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
