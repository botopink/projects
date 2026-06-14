#!/usr/bin/env bash
# vscode-extension.sh — gate for repository/vscode-extension/.
#
# Mirrors scripts/test-vscode.sh: `npm ci` once on first run (marker under
# node_modules/.botopink-installed), then `npm test --silent`. Skips with a
# yellow warning when `npm` is missing.

vscodeExtensionGate() {
    local root="$1"
    cd "$root"

    if ! command -v npm >/dev/null 2>&1; then
        warn "npm missing — skipping vscode-extension gate at $root"
        return 0
    fi

    local marker="$root/node_modules/.botopink-installed"
    if [ ! -f "$marker" ]; then
        echo "  ==> first run: npm ci ($root)"
        if ! ( cd "$root" && npm ci ) 2>&1; then
            fail "vscode-extension: npm ci failed"
        fi
        mkdir -p "$root/node_modules"
        : > "$marker"
    fi

    echo -n "  Testing vscode-extension (npm test)... "
    if ( cd "$root" && npm test --silent ) >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    fi

    echo -e "${RED}✗${NC}"
    echo
    echo "  Re-run for the failure output:"
    echo "    ( cd $root && npm test )"
    fail "vscode-extension: npm test failed"
}
