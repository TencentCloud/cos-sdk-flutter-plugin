#!/usr/bin/env bash
#
# 三端发版门禁：在 Android / iOS / HarmonyOS 上跑同一组一致性断言。
#
# 为什么需要它：本插件通过 pigeon 桥接三套原生 SDK，有一类缺陷**编译器完全不报**、
# 只在特定取值下才暴露。历史上真实发生过：
#   · iOS ABI 失配（NSNumber* vs BOOL）—— 传 false 因指针恰为 nil 而"碰巧正确"，
#     传 true 时指针为 0x1 → SIGSEGV。只测 false 会全绿。
#   · 指针→BOOL 静默转换 —— `@NO` 也是非空指针，转 BOOL 恒为 true
#     （isTruncated 曾因此恒真，分页逻辑全错）。只测 true 会全绿。
#   · 鸿蒙子请求未继承 region —— 只在跨地域场景 404，同地域一切正常。
# 因此门禁里每个布尔参数都成对测 true/false，且用真实 COS 请求验证。
#
# 用法：
#   scripts/release_gate.sh                      # 三端全跑
#   scripts/release_gate.sh android ios          # 只跑指定端
#   ANDROID_DEVICE=emulator-5554 \
#   IOS_DEVICE=<simulator-udid> \
#   OHOS_DEVICE=127.0.0.1:5557 \
#   OHOS_FLUTTER=/path/to/flutter_flutter \
#     scripts/release_gate.sh
#
# 前置条件：
#   · example/lib/config/config.dart 已配置可用的 STS 服务与 APPID
#   · 目标端的模拟器/真机已启动
#   · 鸿蒙端需要 OpenHarmony 适配版 Flutter（见 README 鸿蒙章节）与 DevEco 工具链
#
# 退出码：0 = 全部通过；非 0 = 有平台未通过（不要发版）
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_DIR="$REPO_ROOT/example"
TEST_FILE="integration_test/cos_consistency_test.dart"

# 可通过环境变量覆盖
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
ANDROID_DEVICE="${ANDROID_DEVICE:-emulator-5554}"
IOS_DEVICE="${IOS_DEVICE:-}"
OHOS_DEVICE="${OHOS_DEVICE:-127.0.0.1:5557}"
OHOS_FLUTTER="${OHOS_FLUTTER:-}"
OHOS_BUNDLE="${OHOS_BUNDLE:-com.tencent.tencentcloud_cos_sdk_plugin_example}"
DEVECO_HOME="${DEVECO_HOME:-/Applications/DevEco-Studio.app/Contents}"
# 鸿蒙侧验证页跑完所需时间（含真实网络请求与 6MB 上传）
OHOS_WAIT_SECONDS="${OHOS_WAIT_SECONDS:-240}"

RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
FAILED_PLATFORMS=()

log()  { printf '%s\n' "$*"; }
head1() { printf '\n%s==== %s ====%s\n' "$BOLD" "$*" "$RESET"; }
ok()   { printf '%s✅ %s%s\n' "$GREEN" "$*" "$RESET"; }
bad()  { printf '%s❌ %s%s\n' "$RED" "$*" "$RESET"; }
warn() { printf '%s⚠️  %s%s\n' "$YELLOW" "$*" "$RESET"; }

# ---------------------------------------------------------------- Android / iOS
# 两端都用 `flutter test integration_test`，断言结果直接回传退出码。
run_flutter_test() {
  local platform="$1" device="$2"
  head1 "$platform ($device)"
  if ! (cd "$EXAMPLE_DIR" && "$FLUTTER_BIN" test "$TEST_FILE" -d "$device"); then
    bad "$platform 门禁未通过"
    FAILED_PLATFORMS+=("$platform")
    return 1
  fi
  ok "$platform 门禁通过"
}

# ---------------------------------------------------------------------- 鸿蒙
# 鸿蒙无法直接用 `flutter test integration_test`：它走需签名的安装路径，
# 在未配置调试签名的环境下会失败。所以改为
#   build hap → bm install（unsigned 即可）→ 启动验证页 → 从 hilog 抓断言。
# 验证页 example/lib/test/transfer_verify_page.dart 与集成测试同源。
run_ohos() {
  head1 "HarmonyOS ($OHOS_DEVICE)"

  if [[ -z "$OHOS_FLUTTER" ]]; then
    warn "未设置 OHOS_FLUTTER（OpenHarmony 适配版 Flutter 路径），跳过鸿蒙端"
    warn "官方 Flutter 不支持鸿蒙，见 README「鸿蒙（HarmonyOS）平台说明与差异」"
    FAILED_PLATFORMS+=("HarmonyOS(skipped)")
    return 1
  fi

  local hdc="$DEVECO_HOME/sdk/default/openharmony/toolchains/hdc"
  if [[ ! -x "$hdc" ]]; then
    bad "找不到 hdc：$hdc（请检查 DEVECO_HOME）"
    FAILED_PLATFORMS+=("HarmonyOS")
    return 1
  fi

  export DEVECO_SDK_HOME="$DEVECO_HOME/sdk"
  export PATH="$DEVECO_HOME/tools/ohpm/bin:$DEVECO_HOME/tools/hvigor/bin:$DEVECO_HOME/tools/node/bin:$PATH"

  local hap
  hap="$EXAMPLE_DIR/ohos/entry/build/default/outputs/default/entry-default-unsigned.hap"
  rm -f "$hap"

  log "构建 hap（启用 COS_VERIFY 验证页）..."
  # 注意：`flutter build hap` 即使 assembleHap 成功，也会因为末尾提示
  # "请通过 DevEco Studio 配置调试签名" 而返回非零退出码。
  # 模拟器安装 unsigned hap 并不需要签名，所以这里**以产物是否生成为判据**，
  # 而不是看退出码。
  (cd "$EXAMPLE_DIR" && "$OHOS_FLUTTER/bin/flutter" build hap --debug \
        --dart-define=COS_VERIFY=true >/tmp/ohos_gate_build.log 2>&1) || true

  if [[ ! -f "$hap" ]]; then
    bad "鸿蒙 hap 构建失败（未生成产物），日志见 /tmp/ohos_gate_build.log"
    grep -iE "error|Target .* failed" /tmp/ohos_gate_build.log | head -5 || true
    FAILED_PLATFORMS+=("HarmonyOS")
    return 1
  fi

  local tmpdir="data/local/tmp/cos_release_gate"
  "$hdc" shell aa force-stop "$OHOS_BUNDLE" >/dev/null 2>&1
  "$hdc" shell hilog -r >/dev/null 2>&1
  "$hdc" shell mkdir "$tmpdir" >/dev/null 2>&1
  "$hdc" file send "$hap" "$tmpdir" >/dev/null 2>&1
  if ! "$hdc" shell bm install -p "$tmpdir" 2>&1 | grep -q "install bundle successfully"; then
    bad "鸿蒙 hap 安装失败"
    "$hdc" shell rm -rf "$tmpdir" >/dev/null 2>&1
    FAILED_PLATFORMS+=("HarmonyOS")
    return 1
  fi
  "$hdc" shell rm -rf "$tmpdir" >/dev/null 2>&1
  "$hdc" shell aa start -a EntryAbility -b "$OHOS_BUNDLE" -m entry >/dev/null 2>&1

  log "验证页运行中，等待 ${OHOS_WAIT_SECONDS}s（含真实网络请求与分块上传）..."
  sleep "$OHOS_WAIT_SECONDS"

  local assertions pass_count fail_count
  assertions="$("$hdc" shell hilog -x 2>/dev/null \
    | grep "COSVERIFY" | sed 's/.*COSVERIFY|//' || true)"
  pass_count="$(printf '%s\n' "$assertions" | grep -c '^PASS' || true)"
  fail_count="$(printf '%s\n' "$assertions" | grep -c '^FAIL' || true)"

  printf '%s\n' "$assertions" | grep -E '^(PASS|FAIL)' || true

  if [[ "$pass_count" -eq 0 ]]; then
    bad "鸿蒙端未采集到任何断言（应用可能未启动或崩溃）"
    FAILED_PLATFORMS+=("HarmonyOS")
    return 1
  fi
  if [[ "$fail_count" -ne 0 ]]; then
    bad "鸿蒙门禁未通过：PASS=$pass_count FAIL=$fail_count"
    FAILED_PLATFORMS+=("HarmonyOS")
    return 1
  fi
  ok "鸿蒙门禁通过：PASS=$pass_count FAIL=0"
}

# ------------------------------------------------------------------------ main
TARGETS=("$@")
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS=(android ios ohos)
fi

for t in "${TARGETS[@]}"; do
  case "$t" in
    android) run_flutter_test "Android" "$ANDROID_DEVICE" || true ;;
    ios)
      if [[ -z "$IOS_DEVICE" ]]; then
        # 未指定时自动取第一个已启动的 iOS 模拟器
        IOS_DEVICE="$(xcrun simctl list devices booted 2>/dev/null \
          | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' \
          | head -1 || true)"
      fi
      if [[ -z "$IOS_DEVICE" ]]; then
        warn "没有已启动的 iOS 模拟器，跳过 iOS"
        FAILED_PLATFORMS+=("iOS(skipped)")
      else
        run_flutter_test "iOS" "$IOS_DEVICE" || true
      fi
      ;;
    ohos)    run_ohos || true ;;
    *)       warn "未知目标：$t（可选 android / ios / ohos）" ;;
  esac
done

head1 "门禁结果"
if [[ ${#FAILED_PLATFORMS[@]} -eq 0 ]]; then
  ok "全部通过，可以发版"
  exit 0
fi
bad "未通过：${FAILED_PLATFORMS[*]}"
log "发版前必须三端全绿。跳过的平台也视为未通过 —— 请补齐环境后重跑。"
exit 1
