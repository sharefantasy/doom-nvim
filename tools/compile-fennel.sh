#!/usr/bin/env bash
# compile-fennel.sh - Compile Fennel source to Lua with incremental build support

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

FNL_DIR="$PROJECT_ROOT/fnl"
LUA_DIR="$PROJECT_ROOT/lua"

# 创建lua目录
mkdir -p "$LUA_DIR"

echo "🔄 开始编译 Fennel 文件..."

# 统计信息
TOTAL_FILES=0
COMPILED_FILES=0
SKIPPED_FILES=0
FAILED_FILES=0
START_TIME=$(date +%s)

compile_all_fennel() {
    echo "编译全部 Fennel 文件..."

    if nvim --headless --clean \
        -c "set rtp+=~/.local/share/nvim/lazy/nfnl" \
        -c "lua require('nfnl.api')['compile-all-files']('$PROJECT_ROOT')" \
        -c "quit"; then
        return 0
    else
        return 1
    fi
}

# 查找所有Fennel文件
echo "🔍 查找 Fennel 文件..."
FNL_FILES=($(find "$FNL_DIR" -name "*.fnl" -type f | sort))
TOTAL_FILES=${#FNL_FILES[@]}

if [[ $TOTAL_FILES -eq 0 ]]; then
    echo "⚠️  未找到 Fennel 文件"
    exit 0
fi

echo "📁 找到 $TOTAL_FILES 个 Fennel 文件"

# 开始编译
echo "🚀 开始编译..."

# 统一编译所有文件
if compile_all_fennel; then
    COMPILED_FILES=$TOTAL_FILES
else
    FAILED_FILES=$TOTAL_FILES
fi

# 计算耗时
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# 输出统计信息
echo ""
echo "📈 编译统计："
echo "✅ 成功编译：$COMPILED_FILES"
echo "⏭️  跳过：$SKIPPED_FILES"
echo "❌ 失败：$FAILED_FILES"
echo "⏱️  总耗时：${DURATION}秒"

if [[ $FAILED_FILES -gt 0 ]]; then
    echo "⚠️  有 $FAILED_FILES 个文件编译失败"
    exit 1
fi

echo "🎉 Fennel 编译完成！"
