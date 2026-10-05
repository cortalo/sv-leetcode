# 011 串转并 Serial to Parallel

**难度**：Easy ｜ **类型**：时序逻辑 ｜ **来源**：兆易创新「写一个串并转换的 RTL」；CSDN 百题斩 #9、#24

## 题目
`din` 是串行数据，`din_valid=1` 的拍表示 `din` 有效。**高位在前（MSB first）**，每收满 8 个有效 bit 输出一个字节：
- 收到第 8 个有效 bit 的那个时钟上升沿之后，`dout_valid` 拉高**一个周期**，同时 `dout` 输出这个字节
- 有效 bit 之间可以有间隔（`din_valid=0` 的拍不计数），也可以连续
- 其他时候 `dout_valid = 0`，`dout` 的值不做要求

## 接口
```systemverilog
module s2p (
  input  logic       clk,
  input  logic       rst_n,      // 异步复位，低有效
  input  logic       din,
  input  logic       din_valid,
  output logic [7:0] dout,
  output logic       dout_valid
);
```

## 时序示例（连续输入 1010_0011）
```
clk        _|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_
din_valid  _|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾|____
din          1   0   1   0   0   0   1   1
dout_valid _________________________________|‾‾‾|_
dout                                        0xA3
```

## 测试
连续输入、随机间隔输入两种阶段，逐拍比对。

## 追问
1. 改成 LSB first 怎么写？
2. 反过来写并转串：8bit 数据 + valid 进来，逐 bit 输出，忙的时候怎么反压上游？
3. 如果要求 `dout_valid` 和第 8 个 bit 同一拍输出（组合），怎么改？代价是什么？

```bash
./run.sh 011
```
