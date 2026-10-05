# 021 同步 FIFO Synchronous FIFO

**难度**：Medium ｜ **类型**：存储 / 控制 ｜ **来源**：海思一面手撕同步 FIFO；字节二面「FIFO 有哪些实现方式」；Apple「FIFO 原理与深度计算」；阿里云手撕系列；CSDN 百题斩 #19、#39

## 题目
实现一个读写同时钟的 FIFO，数据宽度 `W`，深度 `DEPTH`（2 的幂）：
- **写**：`wr_en=1` 且 `full=0` 时，在上升沿写入 `din`；满时的写请求被忽略
- **读**：`rd_en=1` 且 `empty=0` 时，在上升沿读出，`dout` 在**这个上升沿之后**更新为读出的数据（寄存器输出，即读数据比 `rd_en` 晚一拍）；空时的读请求被忽略
- 同一拍可以同时读写
- `full` / `empty` 反映当前 FIFO 的状态（上升沿之后更新）
- 只在发生读操作的下一拍检查 `dout`，其他时候 `dout` 不做要求

## 接口
```systemverilog
module sync_fifo #(
  parameter int W     = 8,
  parameter int DEPTH = 16
) (
  input  logic         clk,
  input  logic         rst_n,   // 异步复位，低有效
  input  logic         wr_en,
  input  logic [W-1:0] din,
  output logic         full,
  input  logic         rd_en,
  output logic [W-1:0] dout,
  output logic         empty
);
```

## 测试
(W=8, DEPTH=16) 和 (W=5, DEPTH=4) 两个实例，分"偏写 / 偏读 / 平衡"三种阶段随机读写，覆盖写满、读空、满时写、空时读、同时读写。

## 追问
1. 空满怎么判断？至少说两种方法（计数器 / 指针多一位）。
2. DEPTH 不是 2 的幂时怎么改？
3. 改成 First-Word-Fall-Through（`dout` 直接显示队头，`rd_en` 当作"弹出"）怎么做？
4. 用寄存器堆和用 SRAM 实现有什么区别？SRAM 读有一拍延迟时怎么保证满吞吐？
5. FIFO 深度怎么计算？（例：写 100MHz 突发 80 个数据，读 50MHz，求最小深度）

```bash
./run.sh 021
```
