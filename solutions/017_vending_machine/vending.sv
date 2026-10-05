`timescale 1ns/1ps
// 思路：状态 = 已投入金额（0、0.5、1 元，三个状态 S0/S05/S10）。
//   S0  : +0.5→S05            +1→S10
//   S05 : +0.5→S10            +1→S0 出货
//   S10 : +0.5→S0 出货         +1→S0 出货并找零
//   drink/change 用寄存器输出：在跳回 S0 的同一个上升沿置 1，下一拍自动清 0。
//   （这相当于 Mealy 型的跳转条件 + 输出寄存一拍，输出干净无毛刺。）
// 追问：
//   2. 单价 2.5 元：状态为 0~2 元（5 个状态），找零输出改成 2bit 的金额编码。
//   3. 退币：refund 有效时输出 return_amount = 当前金额，状态回 S0。
module vending (
  input  logic       clk,
  input  logic       rst_n,
  input  logic [1:0] coin,
  output logic       drink,
  output logic       change
);
  typedef enum logic [1:0] {S0, S05, S10} state_t;
  state_t state;

  logic half, one;
  assign half = (coin == 2'b01);
  assign one  = (coin == 2'b10);

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      state <= S0; drink <= 1'b0; change <= 1'b0;
    end else begin
      drink  <= 1'b0;
      change <= 1'b0;
      case (state)
        S0:  if (half) state <= S05; else if (one) state <= S10;
        S05: if (half) state <= S10;
             else if (one) begin state <= S0; drink <= 1'b1; end
        S10: if (half) begin state <= S0; drink <= 1'b1; end
             else if (one) begin state <= S0; drink <= 1'b1; change <= 1'b1; end
        default: state <= S0;
      endcase
    end
endmodule
