# 024 六数求和流水线 Pipelined 6-Input Adder with Valid/Ready

**难度**：Medium ｜ **类型**：流水线 + 握手 ｜ **来源**：字节跳动 AI Lab FPGA 岗现场手撕（追问时序问题，答案是多级加法器中间加流水）

## 题目
前级每次给出 6 个 32 bit 数据（`in_data[0..5]`）和 `in_valid`，本模块求和后输出 32 bit 的 `out_sum`（结果对 2^32 取模，即丢弃进位）。
上下游都是 valid/ready 握手（规则同第 022 题）：
- 上升沿 `in_valid && in_ready` 时接收一组数据；`out_valid && out_ready` 时输出被下游取走
- **至少两级流水**：结果至少在输入被接收 2 拍之后才出现在输出端（tb 会检查）
- **满吞吐**：上游一直有数据、下游一直 ready 时，每拍都要能接收一组新数据
- 反压时不丢数据、不重复，输出端满足 valid/ready 协议

## 接口
```systemverilog
module sum6 (
  input  logic             clk,
  input  logic             rst_n,     // 异步复位，低有效
  input  logic             in_valid,
  output logic             in_ready,
  input  logic [5:0][31:0] in_data,   // in_data[i] 是第 i 个数
  output logic             out_valid,
  input  logic             out_ready,
  output logic [31:0]      out_sum
);
```

## 测试
同第 022 题：随机 / 满吞吐 / 重反压 / 排空，计分板比对求和结果，并检查延迟 ≥ 2 拍。

## 追问
1. 6 个数直接相加，关键路径是什么？流水线怎么切（6→3→1 还是 6→2→1）？
2. 用 CSA（3:2 压缩器）怎么做，能省掉几级进位链？
3. valid/ready 在多级流水里怎么传？哪条路径是组合的？
4. 面试官原话："之所以在 valid 和 ready 同时有效才采样数据，不是为了跨时钟域，而是当前级的数据可能没处理完"——怎么理解？

```bash
./run.sh 024
```
