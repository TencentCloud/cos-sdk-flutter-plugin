#!/bin/bash

# 删除已经存在的覆盖率数据和lib
rm -rf coverage/*
rm -rf coverage
rm -rf ../coverage/*
rm -rf ../coverage
rm -rf lib/lib/*
rm -rf lib/lib

# 将plugin lib复制到example_test的lib中
cp -r ../lib lib

#安装lcov 转换为html
#brew install lcov

# -----------开始跑集成测试 覆盖率------------
# 确保 coverage 目录存在
mkdir -p coverage

# 遍历 integration_test 目录下的所有 test_*.dart 文件
for file in integration_test/test_*.dart
do
  # 获取文件名（不包括扩展名）
  filename=$(basename -- "$file")
  filename="${filename%.*}"

  # 运行测试并生成覆盖率报告
  flutter test --coverage $file

  # 重命名 lcov.info 文件
  mv coverage/lcov.info "coverage/${filename}_lcov.info"

  # 检查 merged_lcov.info 文件是否存在，如果不存在，就复制一份当前的 lcov 文件作为初始的 merged_lcov.info 文件
  if [ ! -f coverage/merged_lcov.info ]; then
    cp "coverage/${filename}_lcov.info" coverage/merged_lcov.info
  else
    # 合并 lcov 文件
    lcov -a coverage/merged_lcov.info -a "coverage/${filename}_lcov.info" -o coverage/temp.info

    # 将合并后的文件重命名为 merged_lcov.info
    mv coverage/temp.info coverage/merged_lcov.info
  fi
done
# -----------结束跑集成测试 覆盖率------------

# 排除对pigeon.dart的覆盖率统计
lcov --remove coverage/merged_lcov.info 'pigeon.dart' -o coverage/filtered_lcov.info

# 转换为html
genhtml coverage/filtered_lcov.info -o coverage/html

# 移动覆盖率数据到根目录
mv coverage ../

# 删除复制过来plugin lib
rm -rf lib/lib/*
rm -rf lib/lib