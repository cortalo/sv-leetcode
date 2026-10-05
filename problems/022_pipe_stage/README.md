# 022 带反压的流水级 Valid/Ready Pipeline Stage

**难度**：Medium ｜ **类型**：握手协议 ｜ **来源**：CSDN 百题斩 #12「握手信号 READY-VALID」、#13「流水握手：解决流水线断流、反压问题」；字节 AI Lab 手撕题的前置知识

## 题目
实现一级 valid/ready 握手的流水寄存器（register slice），位于上游和下游之间：
- 握手规则：上升沿时 `valid && ready` 同时为 1，表示这一拍完成一次传输
- `out_valid`、`out_data` 必须是**寄存器输出**（数据至少延迟 1 拍才出现在输出端）
- **满吞吐**：上游一直有数据、下游一直 ready 时，每个周期都能传一个数据，不能有气泡
- 下游 `out_ready=0`（反压）时数据不能丢、不能重复，`out_valid` 拉高后在被接收之前不能撤销，`out_data` 不能变
- 本题允许 `in_ready` 组合依赖于 `out_ready`

## 接口
```systemverilog
module pipe_stage #(parameter int W = 8) (
  input  logic         clk,
  input  logic         rst_n,     // 异步复位，低有效
  // 上游
  input  logic         in_valid,
  output logic         in_ready,
  input  logic [W-1:0] in_data,
  // 下游
  output logic         out_valid,
  input  logic         out_ready,
  output logic [W-1:0] out_data
);
```

## 测试
随机 valid / ready（轻反压、重反压）、满吞吐阶段（检查 `in_ready` 一直为 1）、最后排空。计分板检查数据顺序不丢不重，并检查输出端协议和"至少延迟 1 拍"。

## 追问
1. `in_ready = out_ready | ~out_valid` 这条组合路径有什么问题？很多级串起来会怎样？→ 第 027 题 skid buffer
2. 把 `in_ready` 直接写成 `out_ready` 行不行？会丢什么？
3. valid/ready 协议里，valid 能不能依赖 ready？ready 能不能依赖 valid？

```bash
./run.sh 022
```
