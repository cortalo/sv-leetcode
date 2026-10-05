# 026 单 bit 脉冲跨时钟域 Pulse Synchronizer

**难度**：Hard ｜ **类型**：CDC ｜ **来源**：海思巴龙「任意时钟频率的单 bit 跨时钟域」（CSDN 百题斩 #35）；全志「快到慢传输脉冲」；字节二面「慢时钟采快时钟，怎么展宽、怎么保证一定采到」；阿里云手撕系列

## 题目
`pulse_a` 是 `clk_a` 时钟域里宽度为 **1 个 clk_a 周期**的脉冲。把它传到 `clk_b` 时钟域，变成宽度为 **1 个 clk_b 周期**的脉冲 `pulse_b`：
- 每个输入脉冲对应**恰好一个**输出脉冲（不丢、不多）
- 两个时钟频率任意、相位无关（可能快到慢，也可能慢到快）
- 输入保证：相邻两个脉冲间隔 ≥ 5 个**较慢**时钟周期
- 延迟要求：输出脉冲在输入脉冲之后 4 个 clk_b 周期 + 1 个 clk_a 周期之内出现

## 接口
```systemverilog
module pulse_sync (
  input  logic clk_a,
  input  logic rst_a_n,   // clk_a 域异步复位，低有效
  input  logic pulse_a,
  input  logic clk_b,
  input  logic rst_b_n,   // clk_b 域异步复位，低有效
  output logic pulse_b
);
```

## 测试
两个实例：快 → 慢（clk_a 10ns、clk_b 27ns）和 慢 → 快（clk_a 27ns、clk_b 10ns），各发送约 500 个脉冲，检查个数、宽度和延迟。

## 追问
1. 快时钟域的单周期脉冲直接打两拍到慢时钟域会怎样？
2. 你的方案对输入脉冲间隔有什么要求？间隔太近会怎样？如果脉冲可能很密集怎么办？
3. 还有哪些单 bit 跨时钟域的方法？各自适用于什么场景？（打两拍 / 展宽 + 反馈 / 翻转同步 / 握手）
4. 多 bit 数据能不能每一位都打两拍？为什么？

```bash
./run.sh 026
```
