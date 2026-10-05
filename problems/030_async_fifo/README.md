# 030 异步 FIFO Asynchronous FIFO

**难度**：Hard ｜ **类型**：CDC + 存储 ｜ **来源**：兆芯二面手撕「异步 FIFO（只写控制逻辑），为什么用格雷码」；英伟达、AMD、寒武纪、OPPO、汇顶、全志…几乎所有公司都问；CSDN 百题斩 #31

## 题目
实现读写时钟异步的 FIFO，数据宽度 `W`，深度 `2^AW`：
- **写侧（wclk 域）**：`winc=1` 且 `wfull=0` 时在 `wclk` 上升沿写入 `wdata`；满时的写被忽略
- **读侧（rclk 域）**：`rempty=0` 时 `rdata` 直接显示队头数据（show-ahead / FWFT）；`rinc=1` 且 `rempty=0` 时在 `rclk` 上升沿弹出队头
- `wfull` 只能"保守"：允许真实已经不满时仍报满（同步延迟导致），但**绝不能**在真实已满时报不满（否则溢出）
- `rempty` 同理：允许已有数据时仍报空，但**绝不能**在真实为空时报不空（否则读到垃圾）
- 两侧各自有异步复位；不能长期"假满 / 假空"（tb 会检查最终能读写完）

## 接口
```systemverilog
module async_fifo #(
  parameter int W  = 8,
  parameter int AW = 4          // 深度 = 2^AW
) (
  input  logic         wclk,
  input  logic         wrst_n,
  input  logic         winc,
  input  logic [W-1:0] wdata,
  output logic         wfull,
  input  logic         rclk,
  input  logic         rrst_n,
  input  logic         rinc,
  output logic [W-1:0] rdata,
  output logic         rempty
);
```

## 测试
两个实例：写快读慢（wclk 10ns / rclk 17.3ns）和写慢读快（wclk 23.1ns / rclk 7ns），分阶段偏写 / 偏读 / 平衡随机读写，计分板比对顺序，检查溢出/下溢，最后排空。

## 追问
1. 为什么指针要用格雷码同步？二进制指针打两拍会出什么问题？
2. 为什么指针要比地址多一位？格雷码下"满"的判断条件是什么？
3. 同步过来的指针是"旧"的，为什么只会造成假满 / 假空，而不会出错？
4. 写时钟比读时钟快很多（比如 10 倍），慢时钟采快时钟的格雷码，会漏掉中间值，有问题吗？
5. 深度不是 2 的幂怎么办？
6. 需要哪些 SDC 约束？（set_max_delay / set_false_path、同步器 ASYNC_REG 属性……）

```bash
./run.sh 030
```
