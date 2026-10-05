# 012 偶数分频 Even Clock Divider

**难度**：Easy ｜ **类型**：时序逻辑 ｜ **来源**：几乎所有公司笔试必考；CSDN 百题斩 #1；阿里云手撕系列

## 题目
把输入时钟 `clk` 做 N 分频（N 为偶数，N ≥ 2），输出 `clk_out`：
- 周期 = N 个 `clk` 周期
- 占空比 50%（高电平 N/2 个周期，低电平 N/2 个周期）
- 复位期间 `clk_out = 0`；复位释放后几拍内开始正常翻转即可（不检查相位）

## 接口
```systemverilog
module clk_div_even #(parameter int N = 4) (
  input  logic clk,
  input  logic rst_n,     // 异步复位，低有效
  output logic clk_out
);
```

## 测试
N = 2、4、6、10 四个实例。tb 测量 `clk_out` 每个周期的长度和高电平宽度。

## 追问
1. 分频出来的时钟直接拿去驱动别的触发器有什么问题？实际芯片里一般怎么做？
2. 如果只要一个"每 N 拍一次的使能脉冲"而不是时钟，怎么写？为什么更推荐这样？
3. 分频时钟需要写什么 SDC 约束？

```bash
./run.sh 012
```
