#!/usr/bin/env bash
# compile-fennel.sh - Compile Fennel source to Lua with optimizations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

FNL_DIR="$PROJECT_ROOT/fnl"
LUA_DIR="$PROJECT_ROOT/lua"

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

echo -e "${BLUE}🔄 开始编译 Fennel 文件...${NC}"

# 查找所有Fennel文件
echo -e "${YELLOW}🔍 查找 Fennel 文件...${NC}"
FNL_FILES=($(find "$FNL_DIR" -name "*.fnl" -type f | sort))
TOTAL_FILES=${#FNL_FILES[@]}

if [[ $TOTAL_FILES -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  未找到 Fennel 文件${NC}"
    exit 0
fi

echo -e "${BLUE}📁 找到 $TOTAL_FILES 个 Fennel 文件${NC}"

# 编译函数
compile_fennel() {
    local fnl_file="$1"
    local lua_file="${fnl_file/$FNL_DIR/$LUA_DIR}"
    lua_file="${lua_file%.fnl}.lua"
    
    # 创建目录
    mkdir -p "$(dirname "$lua_file")"
    
    # 检查是否需要重新编译
    if [[ -f "$lua_file" ]] && [[ "$fnl_file" -ot "$lua_file" ]]; then
        echo -e "${GREEN}✅${NC} $(basename "$fnl_file") (已是最新)"
        ((COMPILED_FILES++))
        return 0
    fi
    
    echo -e "${BLUE}编译:${NC} $(basename "$fnl_file")"
    
    # 使用nvim与Aniseed编译
    if nvim --headless --clean -c "
        set rtp+=~/.local/share/nvim/lazy/aniseed
        lua require('aniseed.compile').compile('$fnl_file', '$lua_file')
        quit
    " 2>/dev/null; then
        echo -e "${GREEN}✅${NC} $(basename "$fnl_file")"
        ((COMPILED_FILES++))
        return 0
    else
        echo -e "${RED}❌${NC} $(basename "$fnl_file")"
        ((FAILED_FILES++))
        return 1
    fi
}

# 开始编译
echo -e "${BLUE}🚀 开始编译...${NC}"

# 顺序编译所有文件
for fnl_file in "${FNL_FILES[@]}"; do
    compile_fennel "$fnl_file"
done

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

echo -e "${GREEN}🎉 Fennel 编译完成！${NC}"