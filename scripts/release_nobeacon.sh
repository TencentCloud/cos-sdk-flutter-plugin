#!/usr/bin/env bash
# ==============================================================================
# release_nobeacon.sh
#
# 用途：
#   以当前 master HEAD 为基础，自动生成 tencentcloud_cos_sdk_plugin_nobeacon
#   变体（仅替换包名 / Android artifact / iOS pod subspec / README 示例 /
#   鸿蒙 ohos 包名与模块名），并产出可用于 `flutter pub publish` 的工作树。
#
# 设计原则：
#   1. master 是唯一开发分支，所有功能性改动都在 master 上。
#   2. nobeacon 不再单独维护，每次发版即时生成。
#   3. 脚本只动 7 个文件，且全部为机械式替换，无业务语义。
#
# 用法：
#   ./scripts/release_nobeacon.sh                # 仅生成临时分支，停在该分支供人工核对
#   ./scripts/release_nobeacon.sh --publish      # 在临时分支上跑 flutter pub publish
#   ./scripts/release_nobeacon.sh --update-nobeacon  # 同步更新长期分支 nobeacon（force push）
#
# 注意：
#   - 必须在干净工作区（无未提交改动）上运行。
#   - 必须在 master 分支上运行。
#   - 不会修改 master 上的任何文件。
# ==============================================================================

set -euo pipefail

# ---- 颜色输出 ----------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[release]${NC} $*"; }
warn() { echo -e "${YELLOW}[release]${NC} $*"; }
die()  { echo -e "${RED}[release]${NC} $*" >&2; exit 1; }

# ---- 参数解析 ----------------------------------------------------------------
DO_PUBLISH=0
DO_UPDATE_NOBEACON=0
for arg in "$@"; do
  case "$arg" in
    --publish)         DO_PUBLISH=1 ;;
    --update-nobeacon) DO_UPDATE_NOBEACON=1 ;;
    -h|--help)
      sed -n '2,25p' "$0"; exit 0 ;;
    *) die "未知参数: $arg" ;;
  esac
done

# ---- 前置检查 ----------------------------------------------------------------
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

[ -d .git ] || die "当前目录不是 git 仓库根目录"

CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[ "${CUR_BRANCH}" = "master" ] || die "请在 master 分支上运行(当前: ${CUR_BRANCH})"

if ! git diff-index --quiet HEAD --; then
  die "工作区不干净，请先 commit / stash"
fi

# ---- 读取版本号 --------------------------------------------------------------
VERSION="$(grep -E '^version:' pubspec.yaml | head -n1 | awk '{print $2}')"
[ -n "${VERSION}" ] || die "无法从 pubspec.yaml 读取 version"
log "master 当前版本: ${VERSION}"

TMP_BRANCH="nobeacon-release/${VERSION}"

# 若临时分支已存在则先清理
if git show-ref --verify --quiet "refs/heads/${TMP_BRANCH}"; then
  warn "本地已存在分支 ${TMP_BRANCH}，先删除"
  git branch -D "${TMP_BRANCH}"
fi

# ---- 切到临时分支 ------------------------------------------------------------
log "基于 master 创建临时分支: ${TMP_BRANCH}"
git checkout -b "${TMP_BRANCH}"

# ---- 替换点 1：pubspec.yaml 顶部 name -----------------------------------------
log "patch pubspec.yaml -> name"
# 仅匹配文件最顶层那一行，避免误伤 description 等
# 旧: name: tencentcloud_cos_sdk_plugin
# 新: name: tencentcloud_cos_sdk_plugin_nobeacon
sed -i.bak -E '1,5 s/^name:[[:space:]]+tencentcloud_cos_sdk_plugin$/name: tencentcloud_cos_sdk_plugin_nobeacon/' pubspec.yaml
rm -f pubspec.yaml.bak
grep -q '^name: tencentcloud_cos_sdk_plugin_nobeacon$' pubspec.yaml \
  || die "pubspec.yaml name 替换失败"

# ---- 替换点 2：android/build.gradle 依赖 --------------------------------------
log "patch android/build.gradle -> cos-android -> cos-android-nobeacon"
# 旧: implementation 'com.qcloud.cos:cos-android:5.9.50'
# 新: implementation 'com.qcloud.cos:cos-android-nobeacon:5.9.50'
sed -i.bak -E "s/com\.qcloud\.cos:cos-android:/com.qcloud.cos:cos-android-nobeacon:/g" android/build.gradle
rm -f android/build.gradle.bak
grep -q "cos-android-nobeacon:" android/build.gradle \
  || die "android/build.gradle 依赖替换失败"

# ---- 替换点 3：iOS podspec ---------------------------------------------------
log "patch ios podspec -> rename + s.name + s.dependency"
OLD_PODSPEC="ios/tencentcloud_cos_sdk_plugin.podspec"
NEW_PODSPEC="ios/tencentcloud_cos_sdk_plugin_nobeacon.podspec"
[ -f "${OLD_PODSPEC}" ] || die "找不到 ${OLD_PODSPEC}"

git mv "${OLD_PODSPEC}" "${NEW_PODSPEC}"

# 替换 s.name
sed -i.bak -E "s/s\.name[[:space:]]*=[[:space:]]*'tencentcloud_cos_sdk_plugin'/s.name             = 'tencentcloud_cos_sdk_plugin_nobeacon'/" "$NEW_PODSPEC"
# 替换 s.dependency 'QCloudCOSXML' -> 'QCloudCOSXML/Slim'
sed -i.bak -E "s/s\.dependency[[:space:]]+'QCloudCOSXML'[[:space:]]*,/s.dependency 'QCloudCOSXML\/Slim',/" "$NEW_PODSPEC"
rm -f "${NEW_PODSPEC}.bak"

grep -q "s\.name[[:space:]]*=[[:space:]]*'tencentcloud_cos_sdk_plugin_nobeacon'" "$NEW_PODSPEC" \
  || die "podspec s.name 替换失败"
grep -q "QCloudCOSXML/Slim" "$NEW_PODSPEC" \
  || die "podspec s.dependency 替换失败"

# ---- 替换点 4：README.md 依赖示例 ---------------------------------------------
log "patch README.md -> 依赖示例包名"
# 仅替换 "tencentcloud_cos_sdk_plugin: ^x.y.z" 这一行
sed -i.bak -E "s/^([[:space:]]*)tencentcloud_cos_sdk_plugin:([[:space:]]+\^)/\1tencentcloud_cos_sdk_plugin_nobeacon:\2/" README.md
rm -f README.md.bak

# ---- 替换点 5：鸿蒙 ohos 包名与模块名 -----------------------------------------
# 鸿蒙侧必须同步改，否则 ohpm 找不到 nobeacon 包（GeneratedPluginRegistrant 的
# import 与 ohpm overrides 都用 Dart 包名，必须与 oh-package.json5 的 name 一致）。
# 鸿蒙原生 COS SDK（@tencentcloud/cos）不区分 beacon/nobeacon，依赖保持不变。
log "patch ohos -> oh-package.json5 name + module.json5 module.name"
sed -i.bak -E 's/"name": "tencentcloud_cos_sdk_plugin"/"name": "tencentcloud_cos_sdk_plugin_nobeacon"/' ohos/oh-package.json5
rm -f ohos/oh-package.json5.bak
grep -q '"name": "tencentcloud_cos_sdk_plugin_nobeacon"' ohos/oh-package.json5 \
  || die "ohos/oh-package.json5 name 替换失败"

sed -i.bak -E 's/"name": "tencentcloud_cos_sdk_plugin"/"name": "tencentcloud_cos_sdk_plugin_nobeacon"/' ohos/src/main/module.json5
rm -f ohos/src/main/module.json5.bak
grep -q '"name": "tencentcloud_cos_sdk_plugin_nobeacon"' ohos/src/main/module.json5 \
  || die "ohos/src/main/module.json5 name 替换失败"

# ---- 提交 --------------------------------------------------------------------
log "git add & commit"
git add -A
git commit -m "build(nobeacon): generate nobeacon variant for ${VERSION}" >/dev/null

# ---- 校验 --------------------------------------------------------------------
log "差异预览（vs master）："
git --no-pager diff --stat master.."${TMP_BRANCH}"

# ---- 可选：发布 --------------------------------------------------------------
if [ "$DO_PUBLISH" -eq 1 ]; then
  log "执行 flutter pub publish"
  flutter pub publish
fi

# ---- 可选：同步长期 nobeacon 分支 -------------------------------------------
if [ "$DO_UPDATE_NOBEACON" -eq 1 ]; then
  log "更新长期分支 nobeacon"
  git branch -f nobeacon "${TMP_BRANCH}"
  warn "如需同步到 origin，请手动执行： git push -f origin nobeacon"
fi

# ---- 收尾 --------------------------------------------------------------------
warn "脚本结束。当前位于临时分支 ${TMP_BRANCH}。"
warn "若要回到 master：  git checkout master"
warn "若要清理临时分支：  git branch -D ${TMP_BRANCH}"
