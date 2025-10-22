#!/usr/bin/env bash
# compile-fennel.sh - Compile Fennel source to Lua

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

FNL_DIR="$PROJECT_ROOT/fnl"
LUA_DIR="$PROJECT_ROOT/lua"

# Create lua directory if it doesn't exist
mkdir -p "$LUA_DIR"

echo "Compiling Fennel files from $FNL_DIR to $LUA_DIR..."

# Function to compile a single Fennel file
compile_fennel() {
    local fnl_file="$1"
    local lua_file="${fnl_file/$FNL_DIR/$LUA_DIR}"
    lua_file="${lua_file%.fnl}.lua"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$lua_file")"
    
    echo "Compiling: $fnl_file -> $lua_file"
    
    # Use nvim with Aniseed to compile
    nvim --headless --clean -c "
        set rtp+=~/.local/share/nvim/lazy/aniseed
        lua require('aniseed.compile').compile('$fnl_file', '$lua_file')
        quit
    " 2>/dev/null || {
        echo "Error compiling $fnl_file"
        return 1
    }
}

# Find and compile all Fennel files
find "$FNL_DIR" -name "*.fnl" -type f | while read -r fnl_file; do
    compile_fennel "$fnl_file"
done

echo "Fennel compilation complete!"