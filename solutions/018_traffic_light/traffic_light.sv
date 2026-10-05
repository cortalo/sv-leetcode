`timescale 1ns/1ps
// 思路：三个状态 + 一个计数器。计数器在每个状态内从 0 数到 (持续时间-1)，到了就切到下一个状态并清零。
//   输出直接由状态译码（Moore），保证独热。
// 追问：
//   1. 30s × 1MHz = 30,000,000 拍，需要 25 bit 计数器（2^25 ≈ 3.3e7）。
//      也可以先做一个 1Hz 的使能脉冲（20 bit 计数器），状态里只数秒（5 bit）。
//   2. 两个方向：状态为 东西绿/南北红 → 东西黄/南北红 → 东西红/南北绿 → 东西红/南北黄；
//      绝不允许两个方向同时为绿或黄。
//   3. 行人按钮：在 GREEN 状态且 btn 有效（先同步+消抖）时直接跳到 YELLOW。
//   4. 倒计时 = 持续时间 - cnt，再转 BCD 驱动数码管。
module traffic_light #(
  parameter int R = 5,
  parameter int G = 4,
  parameter int Y = 2
) (
  input  logic clk,
  input  logic rst_n,
  output logic red,
  output logic green,
  output logic yellow
);
  localparam int MAXD = (R > G) ? ((R > Y) ? R : Y) : ((G > Y) ? G : Y);
  localparam int CW   = (MAXD > 1) ? $clog2(MAXD) : 1;

  typedef enum logic [1:0] {RED, GREEN, YELLOW} state_t;
  state_t        state;
  logic [CW-1:0] cnt;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      state <= RED;
      cnt   <= '0;
    end else begin
      case (state)
        RED:    if (cnt == CW'(R - 1)) begin state <= GREEN;  cnt <= '0; end else cnt <= cnt + 1'b1;
        GREEN:  if (cnt == CW'(G - 1)) begin state <= YELLOW; cnt <= '0; end else cnt <= cnt + 1'b1;
        YELLOW: if (cnt == CW'(Y - 1)) begin state <= RED;    cnt <= '0; end else cnt <= cnt + 1'b1;
        default: begin state <= RED; cnt <= '0; end
      endcase
    end

  assign red    = (state == RED);
  assign green  = (state == GREEN);
  assign yellow = (state == YELLOW);
endmodule
