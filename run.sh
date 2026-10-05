#!/usr/bin/env bash
# 运行题目的自动 testbench。
#
#   ./run.sh 002            用 problems/002_*/ 里你写的代码跑测试
#   ./run.sh 002 -s         用 solutions/002_*/ 里的参考答案跑测试
#   ./run.sh all [-s]       跑全部题目，最后打印汇总
#
# 选项：
#   -s, --solution    测参考答案而不是你的代码
#   -V, --verilator   用 verilator 仿真（默认 iverilog）
#   -w, --wave        导出波形 build/<题号>/wave.vcd（可用 gtkwave / surfer 打开）
#   --seed N          随机种子（默认 1）；换种子能覆盖更多随机场景
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"

usage() { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

target=""; use_sol=0; sim=iverilog; wave=0; seed=1
while [ $# -gt 0 ]; do
  case "$1" in
    -s|--solution)  use_sol=1 ;;
    -V|--verilator) sim=verilator ;;
    -w|--wave)      wave=1 ;;
    --seed)         shift; seed="$1" ;;
    -h|--help)      usage ;;
    -*)             echo "未知选项: $1"; usage ;;
    *)              target="$1" ;;
  esac
  shift
done
[ -z "$target" ] && usage

# 运行单个题目；返回 0 = PASS
run_one() {
  local pdir="$1" id name src_dir bdir dut log
  name="$(basename "$pdir")"; id="${name%%_*}"
  if [ "$use_sol" = 1 ]; then src_dir="$ROOT/solutions/$name"; else src_dir="$pdir"; fi
  dut=$(find "$src_dir" -maxdepth 1 -name '*.sv' ! -name 'tb.sv' | sort)
  if [ -z "$dut" ]; then echo "[$name] 找不到设计文件 ($src_dir/*.sv)"; return 1; fi
  bdir="$ROOT/build/$name"; mkdir -p "$bdir"; log="$bdir/sim.log"

  local plus=("+seed=$seed"); [ "$wave" = 1 ] && plus+=("+dump")
  if [ "$sim" = iverilog ]; then
    iverilog -g2012 -Wall -Wno-timescale -Wno-implicit-dimensions -Wno-portbind \
      -s tb -o "$bdir/sim.vvp" "$pdir/tb.sv" $dut >"$bdir/compile.log" 2>&1 \
      || { echo "[$name] 编译失败:"; cat "$bdir/compile.log"; return 1; }
    (cd "$bdir" && vvp -n sim.vvp "${plus[@]}") >"$log" 2>&1
  else
    local trace=(); [ "$wave" = 1 ] && trace=(--trace)
    verilator --binary --timing -j 0 -Wno-fatal -Wno-lint -Wno-style -Wno-MULTIDRIVEN ${trace[@]+"${trace[@]}"} \
      --top-module tb -Mdir "$bdir/obj" "$pdir/tb.sv" $dut >"$bdir/compile.log" 2>&1 \
      || { echo "[$name] 编译失败:"; grep -E '%(Error|Warning)' "$bdir/compile.log" | head -30; return 1; }
    (cd "$bdir" && ./obj/Vtb "${plus[@]}") >"$log" 2>&1
  fi

  if grep -q '^PASS' "$log"; then
    [ "$TARGET_ALL" = 1 ] || cat "$log" | grep -v -E '^(- |\$finish|.*\$finish called)'
    return 0
  else
    grep -v -E '^(- |.*\$finish)' "$log" | head -40
    return 1
  fi
}

TARGET_ALL=0
if [ "$target" = all ]; then
  TARGET_ALL=1; pass=0; fail=0; failed=()
  for p in "$ROOT"/problems/[0-9]*_*/; do
    p="${p%/}"; n="$(basename "$p")"
    if run_one "$p" >/dev/null 2>&1; then echo "PASS  $n"; pass=$((pass+1));
    else echo "FAIL  $n"; fail=$((fail+1)); failed+=("$n"); fi
  done
  echo "------"; echo "通过 $pass / $((pass+fail))"
  [ "$fail" = 0 ]; exit $?
fi

matches=( "$ROOT"/problems/"$target"*/ )
if [ ! -d "${matches[0]}" ]; then echo "找不到题目: $target"; exit 1; fi
if [ ${#matches[@]} -gt 1 ]; then echo "匹配到多个题目，请写完整一点:"; printf '  %s\n' "${matches[@]}"; exit 1; fi
p="${matches[0]%/}"
echo "== $(basename "$p")  [$([ $use_sol = 1 ] && echo solution || echo 你的代码) / $sim / seed=$seed]"
run_one "$p"; rc=$?
[ "$wave" = 1 ] && echo "波形: build/$(basename "$p")/wave.vcd"
exit $rc
