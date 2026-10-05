# 018 交通灯 Traffic Light

**难度**：Medium ｜ **类型**：状态机 + 计数器 ｜ **来源**：华为上海海思一面手撕（面试者"忘记时钟是 1MHz，计数器写错了"）

## 题目
实现一个单方向交通灯控制器，按 **红 → 绿 → 黄 → 红 → ...** 循环：
- 红灯持续 `R` 个时钟周期，绿灯 `G` 个周期，黄灯 `Y` 个周期（参数，均 ≥ 1）
- 任意时刻**恰好一个**灯亮（`red/green/yellow` 独热）
- 复位期间及复位后红灯亮（复位后的第一段红灯长度不检查，从第一次变绿开始严格检查每段长度）

## 接口
```systemverilog
module traffic_light #(
  parameter int R = 5,
  parameter int G = 4,
  parameter int Y = 2
) (
  input  logic clk,
  input  logic rst_n,    // 异步复位，低有效
  output logic red,
  output logic green,
  output logic yellow
);
```

## 测试
两组参数（R=5,G=4,Y=2 和 R=3,G=7,Y=1），每组跑若干个完整循环，检查独热、顺序和每段持续的周期数。

## 追问
1. 实际场景：时钟 1MHz，红灯 30s、绿灯 27s、黄灯 3s，计数器要几位？
2. 十字路口两个方向（东西 / 南北）怎么设计？哪些状态组合是绝对不允许的？
3. 加一个行人按钮：按下后如果是绿灯，提前进入黄灯，怎么改？
4. 需要数码管显示倒计时，怎么设计？

```bash
./run.sh 018
```
