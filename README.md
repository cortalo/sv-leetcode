# sv-leetcode

数字 IC / FPGA 面试「手撕代码」练习题库。题目来自国内外面经（字节、海思、平头哥、英伟达、联发科……），每道题都有自动判分的 testbench。

## 目录结构

```
problems/NNN_xxx/
  README.md     题目描述、接口、时序要求、测试内容、面试追问
  xxx.sv        代码模板（在这里写你的答案）
  tb.sv         自动 testbench（随机 + 定向测试，与参考模型逐拍比对）
solutions/NNN_xxx/
  xxx.sv        参考答案，开头注释里有思路和追问的参考回答
run.sh          运行脚本
```

## 使用

需要 [Icarus Verilog](https://github.com/steveicarus/iverilog)（默认）或 [Verilator](https://verilator.org)（`-V`）。

跑某一道题（用你写在 `problems/` 里的代码）：

```bash
./run.sh 002
```

对照参考答案：

```bash
./run.sh 002 -s
```

导出波形（`build/<题目>/wave.vcd`，可用 GTKWave / Surfer 打开）：

```bash
./run.sh 002 -w
```

换随机种子多跑几次、或换 verilator 仿真：

```bash
./run.sh 021 --seed 42 -V
```

一次跑全部题目：

```bash
./run.sh all
```

输出 `PASS` 即通过；失败时会打印前 10 条错误（时间、输入、实际值、期望值）。

## 题目列表

| # | 题目 | 难度 | 类型 | 面经来源 |
|---|---|---|---|---|
| 001 | [格雷码转换](problems/001_gray_code/README.md) | Easy | 组合 | 异步 FIFO 基础 |
| 002 | [判断温度计码](problems/002_thermo_check/README.md) | Easy | 组合 | **字节跳动** |
| 003 | [统计 1 的个数](problems/003_popcount/README.md) | Easy | 组合 | 基础 |
| 004 | [固定优先级仲裁器](problems/004_fixed_priority_arbiter/README.md) | Easy | 组合 | 海思、平头哥、芯动 |
| 005 | [温度计码转二进制](problems/005_thermo2bin/README.md) | Easy | 组合 | Glassdoor（STMicro / Oppo） |
| 006 | [最高位 1 的位置](problems/006_leading_one/README.md) | Easy | 组合 | rsxk |
| 007 | [第一个 1 和最后一个 1](problems/007_first_last_one/README.md) | Easy | 组合 / 位运算 | 平头哥、**字节跳动** |
| 008 | [四个数中第 2、3 大之和](problems/008_mid2_sum/README.md) | Easy | 组合 | 全志 |
| 009 | [边沿检测](problems/009_edge_detect/README.md) | Easy | 时序 | 兆易创新、AMD、兆芯 |
| 010 | [饱和计数器](problems/010_counter_sat/README.md) | Easy | 时序 | 华为 |
| 011 | [串转并](problems/011_serial_to_parallel/README.md) | Easy | 时序 | 兆易创新 |
| 012 | [偶数分频](problems/012_clk_div_even/README.md) | Easy | 时钟 | 必考 |
| 013 | [异步复位同步释放](problems/013_reset_sync/README.md) | Easy | 复位 | OPPO、芯动、汇顶 |
| 014 | [序列检测](problems/014_seq_detect/README.md) | Medium | 状态机 | **字节跳动**、平头哥、兆芯、华为 |
| 015 | [毛刺滤波](problems/015_glitch_filter/README.md) | Medium | 时序 | 兆易创新 |
| 016 | [模 3 检测](problems/016_mod3_detect/README.md) | Medium | 状态机 | 平头哥终面 |
| 017 | [自动售货机](problems/017_vending_machine/README.md) | Medium | 状态机 | 经典 |
| 018 | [交通灯](problems/018_traffic_light/README.md) | Medium | 状态机 | 海思 |
| 019 | [奇数分频（50% 占空比）](problems/019_clk_div_odd/README.md) | Medium | 时钟 | **字节 AI Lab**、OPPO、芯源 |
| 020 | [轮询仲裁器](problems/020_round_robin_arbiter/README.md) | Medium | 仲裁 | 睿思芯科、**字节跳动**、海思 |
| 021 | [同步 FIFO](problems/021_sync_fifo/README.md) | Medium | 存储 | 海思、**字节跳动**、Apple |
| 022 | [带反压的流水级](problems/022_pipe_stage/README.md) | Medium | 握手 | valid/ready 基础 |
| 023 | [任意整数分频 1~255](problems/023_clk_div_any/README.md) | Medium | 时钟 | 海思 |
| 024 | [六数求和流水线](problems/024_sum6_pipeline/README.md) | Medium | 流水线 + 握手 | **字节 AI Lab** |
| 025 | [多周期除法器](problems/025_divider/README.md) | Medium | 数据通路 | 小米 |
| 026 | [单 bit 脉冲跨时钟域](problems/026_pulse_sync/README.md) | Hard | CDC | 海思巴龙、全志、**字节跳动** |
| 027 | [Skid Buffer](problems/027_skid_buffer/README.md) | Hard | 握手 / 时序 | Nvidia / Apple |
| 028 | [多 bit 握手跨时钟域](problems/028_cdc_handshake/README.md) | Hard | CDC | 芯动、英伟达、OPPO |
| 029 | [无毛刺时钟切换](problems/029_clock_switch/README.md) | Hard | 时钟 | 英伟达、复旦微 |
| 030 | [异步 FIFO](problems/030_async_fifo/README.md) | Hard | CDC + 存储 | 兆芯、英伟达、几乎所有公司 |

## 约定与提示

- 所有 testbench 同时支持 iverilog 和 verilator；参考答案在两者上都通过。
- 复位一律是异步复位、低有效（`rst_n`），010 题例外（题目要求高电平复位）。
- 时序题的 tb 在时钟下降沿检查输出、改变输入，所以你的寄存器输出要在上升沿之后稳定。
- iverilog 的几个坑：
  - enum 变量不能直接用三目运算赋值（`next = din ? S1 : S0;` 会报 explicit cast），改用 `if/else`。
  - 信号要先声明再使用。
  - 函数返回值不能直接取位选（`f(x)[3:0]`），先赋给变量。
- 仿真只能验证功能。CDC 题（026、028、030）里亚稳态、多 bit 偏斜这类问题在 RTL 仿真里看不出来，结构是否正确还需要自己按追问检查。

## 加新题

复制一个已有题目的目录结构即可。`run.sh` 会把 `tb.sv` 和目录下其余所有 `.sv` 一起编译，顶层模块名必须是 `tb`，结束时打印以 `PASS` 开头的一行表示通过。
