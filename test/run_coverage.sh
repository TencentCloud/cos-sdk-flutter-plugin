#!/bin/bash

# COS Flutter Plugin 单元测试覆盖率脚本
#
# 使用方法:
#   ./test/run_coverage.sh
#
# 此脚本会:
#   1. 运行所有单元测试
#   2. 收集覆盖率数据
#   3. 排除自动生成的代码（pigeon.dart）
#   4. 生成 HTML 格式的覆盖率报告

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  COS Flutter Plugin 单元测试覆盖率  ${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# 获取脚本所在目录的上级目录（项目根目录）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

echo -e "${GREEN}[1/5] 清理旧的覆盖率数据...${NC}"
rm -rf coverage/
mkdir -p coverage

echo -e "${GREEN}[2/5] 运行单元测试并收集覆盖率...${NC}"
# 使用 || true 避免测试失败导致脚本中断
flutter test --coverage || true

if [ ! -f "coverage/lcov.info" ]; then
    echo -e "${RED}错误: 未生成覆盖率数据文件${NC}"
    exit 1
fi

echo -e "${GREEN}[3/5] 处理覆盖率数据（排除 pigeon.dart）...${NC}"

# 检查是否安装了 lcov
if command -v lcov &> /dev/null; then
    # 排除 pigeon.dart 自动生成的代码
    lcov --remove coverage/lcov.info \
        'lib/pigeon.dart' \
        -o coverage/lcov.info \
        --ignore-errors unused 2>/dev/null
    
    echo -e "${GREEN}[4/5] 生成 HTML 覆盖率报告...${NC}"
    genhtml coverage/lcov.info \
        -o coverage/html \
        --ignore-errors source 2>/dev/null
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  覆盖率报告生成完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "HTML 报告位置: coverage/html/index.html"
    echo ""
    echo "打开报告: open coverage/html/index.html"
    
    echo ""
    echo -e "${BLUE}[5/5] 覆盖率详情:${NC}"
    echo ""
    
    # 显示每个文件的覆盖率
    echo "各文件覆盖率:"
    echo "----------------------------------------"
    cat coverage/lcov.info | grep -E "^SF:|^LF:|^LH:" | paste - - - | while read line; do
        sf=$(echo "$line" | grep -o "SF:[^ ]*" | sed 's/SF://')
        lf=$(echo "$line" | grep -o "LF:[0-9]*" | sed 's/LF://')
        lh=$(echo "$line" | grep -o "LH:[0-9]*" | sed 's/LH://')
        if [ -n "$lf" ] && [ "$lf" -gt 0 ]; then
            pct=$(echo "scale=1; $lh*100/$lf" | bc)
            printf "  %-40s %3d/%3d 行  (%5.1f%%)\n" "$sf" "$lh" "$lf" "$pct"
        fi
    done
    echo "----------------------------------------"
    
    # 计算总覆盖率
    total_lf=$(cat coverage/lcov.info | grep "^LF:" | sed 's/LF://' | paste -sd+ | bc)
    total_lh=$(cat coverage/lcov.info | grep "^LH:" | sed 's/LH://' | paste -sd+ | bc)
    total_pct=$(echo "scale=1; $total_lh*100/$total_lf" | bc)
    echo ""
    echo -e "  ${BLUE}总计: $total_lh/$total_lf 行 ($total_pct%)${NC}"
    echo ""
    
    # 检查是否达到目标
    if (( $(echo "$total_pct >= 80" | bc -l) )); then
        echo -e "  ${GREEN}✓ 覆盖率已达到 80% 目标${NC}"
    else
        echo -e "  ${YELLOW}⚠ 覆盖率未达到 80% 目标${NC}"
    fi
    
else
    echo -e "${YELLOW}警告: 未安装 lcov，跳过 HTML 报告生成${NC}"
    echo ""
    echo "安装 lcov:"
    echo "  macOS: brew install lcov"
    echo "  Ubuntu: sudo apt-get install lcov"
    echo ""
    echo "覆盖率数据文件位置: coverage/lcov.info"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  完成！${NC}"
echo -e "${GREEN}========================================${NC}"