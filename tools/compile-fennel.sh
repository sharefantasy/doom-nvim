#!/usr/bin/env bash
# compile-fennel.sh - Compile Fennel source to Lua

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

FNL_DIR="$PROJECT_ROOT/fnl"
LUA_DIR="$PROJECT_ROOT/lua"

if ! command -v fennel >/dev/null 2>&1; then
    echo "❌ 未找到 fennel 可执行文件，请先安装 Fennel（例如：brew install fennel）"
    exit 1
fi

mapfile -t FNL_FILES < <(find "$FNL_DIR" -name "*.fnl" -type f 2>/dev/null | sort)
TOTAL="${#FNL_FILES[@]}"

echo "🔄 开始编译 Fennel 文件..."
echo "📁 Fennel 目录：$FNL_DIR"
echo "📂 Lua 输出目录：$LUA_DIR"
echo "📊 共找到 $TOTAL 个 Fennel 文件"
echo ""

if [[ "$TOTAL" -eq 0 ]]; then
    echo "⚠️ 未找到任何 Fennel 文件，终止编译"
    exit 1
fi

COMPILED=0
FAILED=0

for fnl_file in "${FNL_FILES[@]}"; do
    rel_path="${fnl_file#"$FNL_DIR"/}"
    lua_file="$LUA_DIR/${rel_path%.fnl}.lua"

    # 创建目录
    mkdir -p "$(dirname "$lua_file")"

    # 使用 Fennel CLI 编译并保存
    FENNEL_MACRO_PATH="$FNL_DIR/?.fnl;$FNL_DIR/?/init.fnl"
    FENNEL_PATH="$FNL_DIR/?.fnl;$FNL_DIR/?/init.fnl"
    err_file="$(mktemp)"

    if fennel --add-macro-path "$FENNEL_MACRO_PATH" --add-fennel-path "$FENNEL_PATH" --compile "$fnl_file" > "$lua_file" 2>"$err_file"; then
        # 验证文件非空且包含内容
        if [ -s "$lua_file" ]; then
            COMPILED=$((COMPILED + 1))
        else
            echo "  ⚠️ $rel_path 生成了空文件"
            if [ -s "$err_file" ]; then
                echo "  ↳ 错误输出："
                cat "$err_file"
            fi
            rm -f "$lua_file"
            FAILED=$((FAILED + 1))
        fi
    else
        echo "  ❌ $rel_path"
        if [ -s "$err_file" ]; then
            echo "  ↳ 错误输出："
            cat "$err_file"
        fi
        rm -f "$lua_file"
        FAILED=$((FAILED + 1))
    fi

    rm -f "$err_file"
done

echo ""
echo "📈 编译统计："
echo "✅ 成功：$COMPILED"
echo "❌ 失败：$FAILED"

OUTPUT_COUNT=$(find "$LUA_DIR" -name "*.lua" -type f 2>/dev/null | wc -l | tr -d ' ')
if [[ "$OUTPUT_COUNT" -lt "$TOTAL" ]]; then
    echo "⚠️  生成的 Lua 文件数量($OUTPUT_COUNT) 少于源文件数量($TOTAL)"
fi

if [[ $FAILED -gt 0 ]]; then
    echo "⚠️  有 $FAILED 个文件编译失败"
    exit 1
fi

echo "🎉 Fennel 编译完成！"

# 同步到 Neovim 配置目录
NVIM_LUA_DIR="$HOME/.config/nvim/lua"
echo ""
echo "📦 同步到 Neovim 配置目录..."
mkdir -p "$NVIM_LUA_DIR"
LUA_DIR_RESOLVED="$(realpath "$LUA_DIR")"
NVIM_LUA_DIR_RESOLVED="$(realpath "$NVIM_LUA_DIR")"

if [[ "$NVIM_LUA_DIR_RESOLVED" == "$LUA_DIR_RESOLVED" ]]; then
    echo "ℹ️  输出目录与 Neovim 配置目录指向同一路径，跳过同步"
else
    rm -rf "$NVIM_LUA_DIR/gentlewind" "$NVIM_LUA_DIR/user"
    cp -r "$LUA_DIR/gentlewind" "$NVIM_LUA_DIR/" 2>/dev/null || true
    cp -r "$LUA_DIR/user" "$NVIM_LUA_DIR/" 2>/dev/null || true
    echo "✅ 同步完成"
fi
