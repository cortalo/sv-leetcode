# 010 饱和计数器 Saturating Counter

**难度**：Easy ｜ **类型**：时序逻辑 ｜ **来源**：华为一面「计数器，高电平复位，要求有计数清零端，计满保持」；华为 2024 校招手撕计数器

## 题目
实现一个 W bit 计数器：
- `rst`：**高电平有效的异步复位**，复位时 `cnt = 0`
- `clr`：同步清零，时钟上升沿时 `clr=1` 则 `cnt` 变为 0（优先级高于 `en`）
- `en` ：计数使能，`en=1` 时每个上升沿加 1
- 计到最大值 `2^W - 1` 后**保持**不变（不回绕），直到被清零或复位
- `full`：`cnt` 等于最大值时为 1（组合输出即可）

## 接口
```systemverilog
module counter_sat #(parameter int W = 4) (
  input  logic         clk,
  input  logic         rst,    // 异步复位，高有效
  input  logic         clr,    // 同步清零
  input  logic         en,
  output logic [W-1:0] cnt,
  output logic         full
);
```

## 测试
W=3 和 W=4 两个实例，随机 en / clr，并在时钟周期中间随机插入异步复位脉冲（检查复位是否立即生效）。

## 追问
1. 同步复位和异步复位各有什么优缺点？
2. 如果要求 `full` 是寄存器输出，并且和 `cnt` 同一拍有效，怎么写？
3. 计数器位宽很大（比如 64 bit）跑不到频率怎么办？

```bash
./run.sh 010
```
