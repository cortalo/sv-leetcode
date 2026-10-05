# 027 Skid Buffer（寄存器化的 ready）

**难度**：Hard ｜ **类型**：握手协议 / 时序优化 ｜ **来源**：第 022 题的追问；CSDN 百题斩 #13「流水握手解决反压问题」；Nvidia / Apple 面经里常见的 pipeline 反压题

## 题目
在第 022 题的基础上，增加一个时序要求：**`in_ready` 必须是寄存器输出**，不能组合依赖于 `out_ready`（也不能依赖 `in_valid`）。

其余要求不变：
- valid/ready 握手，`out_valid`/`out_data` 为寄存器输出（至少延迟 1 拍）
- 满吞吐：上游一直有数据、下游一直 ready 时每拍传一个
- 反压时不丢、不重复，输出端满足协议（`out_valid` 拉高后被接收前不撤销，数据不变）

tb 会在每个周期中间改变 `out_ready`，检查 `in_ready` 有没有跟着变（有就说明存在组合路径）。

## 接口
```systemverilog
module skid_buffer #(parameter int W = 8) (
  input  logic         clk,
  input  logic         rst_n,     // 异步复位，低有效
  input  logic         in_valid,
  output logic         in_ready,
  input  logic [W-1:0] in_data,
  output logic         out_valid,
  input  logic         out_ready,
  output logic [W-1:0] out_data
);
```

## 测试
同第 022 题（随机 / 满吞吐 / 重反压 / 排空 + 计分板 + 协议检查），另加"周期中途翻转 out_ready"检查组合路径。

## 追问
1. 为什么需要额外的一个寄存器（skid 寄存器）？只有一个寄存器、`in_ready` 又是寄存器输出时，为什么做不到满吞吐？
2. 画出这个模块的状态（空 / 半满 / 满）和转移条件。
3. 长流水线里每一级都用 skid buffer，和只在几个地方插 skid buffer 有什么权衡？

```bash
./run.sh 027
```
