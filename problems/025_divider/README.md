# 025 多周期除法器 Sequential Divider

**难度**：Medium ｜ **类型**：数据通路 + 控制 ｜ **来源**：小米科技手撕「除法器设计」（CSDN 百题斩 #27）；汇顶「除法怎么做，除以奇数呢？」

## 题目
实现 W bit **无符号**整数除法器，多周期迭代完成：
- `start=1` 且 `busy=0` 时，在上升沿接收 `dividend`、`divisor`，开始计算；`busy=1` 期间的 `start` 被忽略
- 计算期间 `busy=1`
- 计算完成时 `done` 拉高**一个周期**，此时 `busy=0`，`quotient`/`remainder` 有效，并且**保持**到下一次 `start` 被接收
- 从接收 `start` 的上升沿算起，`done` 必须在 **W+2 拍之内**出现
- 除数为 0 时：`quotient` 全 1，`remainder = dividend`（RISC-V 的约定）
- `done` 那一拍可以接收新的 `start`

## 接口
```systemverilog
module divider #(parameter int W = 8) (
  input  logic         clk,
  input  logic         rst_n,     // 异步复位，低有效
  input  logic         start,
  input  logic [W-1:0] dividend,
  input  logic [W-1:0] divisor,
  output logic         busy,
  output logic         done,
  output logic [W-1:0] quotient,
  output logic [W-1:0] remainder
);
```

## 测试
W=8 和 W=13 两个实例，随机操作数（含除数为 0、被除数小于除数、除数为 1 等），随机发起 start（包括 busy 时发 start），检查结果、延迟、busy/done 时序以及结果保持。

## 追问
1. 恢复余数法（restoring）和不恢复余数法（non-restoring）的区别？
2. 每拍算 2 bit（radix-4）怎么做？代价是什么？
3. 有符号除法怎么在这个基础上改？
4. 除以常数 3 有什么快速方法？

```bash
./run.sh 025
```
