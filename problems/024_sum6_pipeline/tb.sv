`timescale 1ns/1ps
`define TB_CHECK(cond, msg) if (!(cond)) begin errors++; if (errors <= 10) $display msg; end
module tb;
  int errors = 0;
  int unsigned seed = 1;

  logic clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  logic             in_valid = 0, in_ready, out_valid, out_ready = 0;
  logic [5:0][31:0] in_data = 0;
  logic [31:0]      out_data;

  sum6 dut (
    .clk(clk), .rst_n(rst_n),
    .in_valid(in_valid), .in_ready(in_ready), .in_data(in_data),
    .out_valid(out_valid), .out_ready(out_ready), .out_sum(out_data));

  function automatic logic [31:0] ref_sum(input logic [5:0][31:0] d);
    logic [31:0] s = 0;
    for (int i = 0; i < 6; i++) s += d[i];
    return s;
  endfunction

  // 计分板（存期望的和）
  logic [31:0] sent [200000];
  int         sent_cyc [200000];
  int nsent, nrecv, cyc, mode, p_valid, p_ready, warm;
  logic in_fire, out_fire, prev_stall;
  logic [31:0] prev_od;

  initial begin
    if ($value$plusargs("seed=%d", seed)) ;
    void'($urandom(seed));
    $timeformat(-9, 1, " ns", 0);
    if ($test$plusargs("dump")) begin $dumpfile("wave.vcd"); $dumpvars(0, tb); end

    nsent = 0; nrecv = 0; in_fire = 0; prev_stall = 0; warm = 0;
    repeat (3) @(posedge clk);
    @(negedge clk) rst_n = 1;
    for (cyc = 0; cyc < 12000; cyc++) begin
      // 阶段：0 随机 / 1 满吞吐 / 2 重反压 / 3 排空
      mode = (cyc >= 11900) ? 3 : (cyc % 3000 < 1000) ? 0 : (cyc % 3000 < 2000) ? 1 : 2;
      p_valid = (mode == 0) ? 60 : (mode == 1) ? 100 : (mode == 2) ? 70 : 0;
      p_ready = (mode == 0) ? 60 : (mode == 1) ? 100 : (mode == 2) ? 20 : 100;
      warm = (mode == 1) ? warm + 1 : 0;

      @(posedge clk); #1;
      // 上游：没有 valid 或上一拍已被接收时才换新数据，否则保持
      if (!in_valid || in_fire) begin
        in_valid = ($urandom % 100) < p_valid;
        for (int i = 0; i < 6; i++) in_data[i] = ($urandom % 4 == 0) ? 32'hFFFF_FFFF - ($urandom % 8) : $urandom;
      end
      out_ready = ($urandom % 100) < p_ready;

      @(negedge clk);
      // 本拍（下一个上升沿）是否发生传输
      `TB_CHECK((^{in_ready, out_valid}) !== 1'bx, ("[%0t] ERROR in_ready/out_valid 出现 X", $time))
      in_fire  = in_valid && in_ready;
      out_fire = out_valid && out_ready;
      if (prev_stall) begin
        `TB_CHECK(out_valid === 1'b1, ("[%0t] ERROR 协议错误：out_valid 在被接收之前撤销了", $time))
        `TB_CHECK(out_data === prev_od, ("[%0t] ERROR 协议错误：反压期间 out_sum 从 0x%h 变成了 0x%h", $time, prev_od, out_data))
      end
      if (out_fire) begin
        if (nrecv >= nsent) begin
          errors++; if (errors <= 10) $display("[%0t] ERROR 输出了多余的数据 0x%h（上游没有发过）", $time, out_data);
        end else begin
          `TB_CHECK(out_data === sent[nrecv], ("[%0t] ERROR 第 %0d 个结果 out_sum = 0x%h，期望 0x%h", $time, nrecv, out_data, sent[nrecv]))
          `TB_CHECK(cyc >= sent_cyc[nrecv] + 2, ("[%0t] ERROR 第 %0d 个结果在输入后 %0d 拍就输出了，要求至少两级流水（延迟 >= 2 拍）", $time, nrecv, cyc - sent_cyc[nrecv]))
          nrecv++;
        end
      end
      if (in_fire) begin sent[nsent] = ref_sum(in_data); sent_cyc[nsent] = cyc; nsent++; end
      if (mode == 1 && warm > 5)
        `TB_CHECK(in_ready === 1'b1, ("[%0t] ERROR 满吞吐阶段（上游一直 valid、下游一直 ready）in_ready 不应为 0", $time))
      prev_stall = out_valid && !out_ready;
      prev_od    = out_data;
    end

    `TB_CHECK(nrecv == nsent, ("ERROR 排空后输入了 %0d 个数据，只输出了 %0d 个（数据丢失或卡住）", nsent, nrecv))
    `TB_CHECK(nsent > 6000, ("ERROR 只传输了 %0d 个数据，吞吐太低", nsent))
    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d error(s)", errors);
    $finish;
  end
endmodule
