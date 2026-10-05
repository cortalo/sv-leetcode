# 028 多 bit 握手跨时钟域 CDC Handshake

**难度**：Hard ｜ **类型**：CDC ｜ **来源**：芯动科技二面「3M 到 20M 跨时钟域，不用握手不用异步 FIFO 传 8bit」（本题是用握手的标准做法）；英伟达「握手协议需要几个 cycle」；OPPO「打两拍和握手分别在什么场合用」

## 题目
把 W bit 数据从 `clk_a` 域可靠地传到 `clk_b` 域（两个时钟频率任意、相位无关）：
- A 侧是 valid/ready 接口：上升沿 `a_valid && a_ready` 时接收一个数据 `a_data`
- B 侧没有反压：每收到一个数据，`b_valid` 拉高**一个** clk_b 周期，同时 `b_data` 有效
- 数据不能丢、不能重复、不能错（不能采到变化中的多 bit 数据）
- 上一个数据还没传完时 `a_ready = 0`
- **不允许**用异步 FIFO

## 接口
```systemverilog
module cdc_handshake #(parameter int W = 8) (
  input  logic         clk_a,
  input  logic         rst_a_n,   // clk_a 域异步复位，低有效
  input  logic         a_valid,
  output logic         a_ready,
  input  logic [W-1:0] a_data,
  input  logic         clk_b,
  input  logic         rst_b_n,   // clk_b 域异步复位，低有效
  output logic         b_valid,
  output logic [W-1:0] b_data
);
```

## 测试
两个实例：clk_a 10ns / clk_b 13.7ns，以及 clk_a 31ns / clk_b 7ns。随机发送，计分板比对顺序和内容，最后排空检查。

## 追问
1. 为什么 `a_data` 可以不经过同步器直接被 B 域采样？需要满足什么条件？要加什么约束？
2. 四相握手和两相（翻转）握手的区别？各需要多少个周期？
3. 吞吐量大概是多少？想提高吞吐怎么办？
4. 芯动的原题：3MHz → 20MHz，数据每个 3M 周期变一次，不用握手不用 FIFO 怎么传？

```bash
./run.sh 028
```
