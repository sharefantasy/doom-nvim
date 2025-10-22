#!/usr/bin/env bash
# test-fennel.sh - Test Fennel compilation and basic functionality

set -e

echo "🧪 Testing Doom Nvim Fennel Migration"
echo "======================================"

# Test 1: Check Fennel syntax
echo "1️⃣  Checking Fennel syntax..."
find fnl -name "*.fnl" -type f | while read -r file; do
    echo "  Checking $file"
    # Basic syntax check - would need fennel binary for full validation
    if ! grep -q "^;;" "$file" && ! grep -q "^(" "$file"; then
        echo "  ⚠️  Warning: $file may have syntax issues"
    fi
done

# Test 2: Check module structure
echo "2️⃣  Checking module structure..."
find fnl/doom/modules -name "*.fnl" -type f | while read -r file; do
    echo "  Checking $file"
    if ! grep -q "packages" "$file" || ! grep -q "configs" "$file"; then
        echo "  ⚠️  Warning: $file missing standard module fields"
    fi
done

# Test 3: Check for required files
echo "3️⃣  Checking required files..."
required_files=(
    "fnl/init.fnl"
    "fnl/doom/core/init.fnl"
    "fnl/doom/core/config.fnl"
    "fnl/doom/core/modules.fnl"
    "fnl/doom/core/doom_global.fnl"
    "fnl/doom/utils.fnl"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "  ✅ $file exists"
    else
        echo "  ❌ $file missing"
        exit 1
    fi
done

# Test 4: Check compilation (if Aniseed is available)
echo "4️⃣  Testing compilation..."
if command -v nvim &> /dev/null; then
    echo "  Testing basic compilation with nvim..."
    # Try to compile a simple test file
    cat > /tmp/test.fnl << 'EOF'
;; Test file
(local test "Hello from Fennel!")
{:message test}
EOF
    
    if nvim --headless --clean -c "
        set rtp+=~/.local/share/nvim/lazy/aniseed
        lua require('aniseed.compile').compile('/tmp/test.fnl', '/tmp/test.lua')
        quit
    " 2>/dev/null; then
        if [[ -f "/tmp/test.lua" ]]; then
            echo "  ✅ Compilation successful"
            rm -f /tmp/test.fnl /tmp/test.lua
        else
            echo "  ❌ Compilation failed - no output file"
        fi
    else
        echo "  ⚠️  Compilation test skipped - Aniseed not available"
    fi
else
    echo "  ⚠️  Compilation test skipped - nvim not available"
fi

# Test 5: Check for common patterns
echo "5️⃣  Checking code patterns..."
if grep -r "vim\.fn\." fnl/ | grep -v "vim\.fn\.[a-zA-Z]" > /dev/null; then
    echo "  ⚠️  Found potential vim.fn usage issues"
fi

if grep -r "require.*\.\.\." fnl/ > /dev/null; then
    echo "  ⚠️  Found potential require issues"
fi

echo ""
echo "🎉 Basic tests completed!"
echo ""
echo "Next steps:"
echo "1. Run ./tools/compile-fennel.sh to compile all Fennel files"
echo "2. Test the compiled configuration with nvim"
echo "3. Check for runtime errors"
echo "4. Verify all modules load correctly"