# 005 温度计码转二进制 Thermometer to Binary

**难度**：Easy ｜ **类型**：组合逻辑 ｜ **来源**：Glassdoor（STMicro / Oppo 等，追问流水线）；Flash ADC 输出编码；第 002 题的延伸

## 题目
输入 W bit 的温度计码 `thermo`（从最低位开始连续的 1，见第 002 题），输出：
- `valid`：输入是否为合法温度计码
- `bin`：合法时输出 1 的个数（即温度计码表示的数值）。`valid=0` 时 `bin` 的值不做要求。

## 接口
```systemverilog
module thermo2bin #(parameter int W = 15) (
  input  logic [W-1:0]           thermo,
  output logic [$clog2(W+1)-1:0] bin,
  output logic                   valid
);
```

## 示例（W=7）
| thermo | bin | valid |
|---|---|---|
| 000_0000 | 0 | 1 |
| 000_0111 | 3 | 1 |
| 111_1111 | 7 | 1 |
| 000_1011 | - | 0 |

## 测试
W=7、W=8、W=15 穷举。

## 追问
1. 除了"数 1 的个数"，还有什么更省面积的写法？（提示：合法码里 `1→0` 的跳变位置只有一个）
2. Flash ADC 的比较器输出可能有"气泡"（如 `0010111`），怎么设计才能容错？
3. 反过来，二进制 → 温度计码怎么写？
4. W=255 时怎么流水？

```bash
./run.sh 005
```
