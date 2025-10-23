#!/usr/bin/env bash
# compile-fennel.sh - Compile Fennel source to Lua with parallel processing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

FNL_DIR="$PROJECT_ROOT/fnl"
LUA_DIR="$PROJECT_ROOT/lua"

# 并行进程数（默认为CPU核心数的一半，避免资源耗尽）
MAX_JOBS=${MAX_JOBS:-$(( $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4) / 2 + 1 ))}

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 统计信息
TOTAL_FILES=0
COMPILED_FILES=0
FAILED_FILES=0
START_TIME=$(date +%s)

# 创建lua目录
mkdir -p "$LUA_DIR"

echo -e "${BLUE}🔄 开始并行编译 Fennel 文件...${NC}"
echo -e "${BLUE}📊 使用 $MAX_JOBS 个并行进程${NC}"

# 编译单个Fennel文件的函数
compile_fennel() {
    local fnl_file="$1"
    local lua_file="${fnl_file/$FNL_DIR/$LUA_DIR}"
    lua_file="${lua_file%.fnl}.lua"
    
    # 创建目录
    mkdir -p "$(dirname "$lua_file")"
    
    # 使用nvim与Aniseed编译
    if nvim --headless --clean -c "
        set rtp+=~/.local/share/nvim/lazy/aniseed
        lua require('aniseed.compile').compile('$fnl_file', '$lua_file')
        quit
    " 2>/dev/null; then
        echo -e "${GREEN}✅${NC} $(basename "$fnl_file")"
        return 0
    else
        echo -e "${RED}❌${NC} $(basename "$fnl_file")"
        return 1
    fi
}

# 导出函数供并行使用
export -f compile_fennel
export FNL_DIR LUA_DIR GREEN RED NC

# 查找所有Fennel文件
echo -e "${YELLOW}🔍 查找 Fennel 文件...${NC}"
mapfile -t FNL_FILES < <(find "$FNL_DIR" -name "*.fnl" -type f)
TOTAL_FILES=${#FNL_FILES[@]}

if [[ $TOTAL_FILES -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  未找到 Fennel 文件${NC}"
    exit 0
fi

echo -e "${BLUE}📁 找到 $TOTAL_FILES 个 Fennel 文件${NC}"

# 使用xargs进行并行编译（更稳定的方式）
echo -e "${BLUE}🚀 开始并行编译...${NC}"

# 创建临时文件存储结果
TEMP_RESULT=$(mktemp)

# 使用xargs进行并行编译，限制参数长度
printf '%s\0' "${FNL_FILES[@]}" | xargs -0 -P "$MAX_JOBS" -n 1 bash -c '
    fnl_file="$1"
    if compile_fennel "$fnl_file"; then
        echo "success" >> "'$TEMP_RESULT'"
    else
        echo "failed" >> "'$TEMP_RESULT'"
    fi
' _ {}

# 统计结果
if [[ -f "$TEMP_RESULT" ]]; then
    mapfile -t RESULTS < "$TEMP_RESULT"
    for result in "${RESULTS[@]}"; do
        if [[ "$result" == "success" ]]; then
            ((COMPILED_FILES++))
        else
            ((FAILED_FILES++))
        fi
    done
    rm -f "$TEMP_RESULT"
fi

# 计算耗时
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# 输出统计信息
echo -e "\n${BLUE}📈 编译统计：${NC}"
echo -e "${GREEN}✅ 成功：$COMPILED_FILES${NC}"
echo -e "${RED}❌ 失败：$FAILED_FILES${NC}"
echo -e "${BLUE}⏱️  耗时：${DURATION}秒${NC}"

if [[ $FAILED_FILES -gt 0 ]]; then
    echo -e "${RED}⚠️  有 $FAILED_FILES 个文件编译失败${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Fennel 并行编译完成！${NC}"