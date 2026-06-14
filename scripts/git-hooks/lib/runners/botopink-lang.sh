#!/usr/bin/env bash
# botopink-lang.sh — gate for the botopink-lang compiler tree.
#
# Same gate the meta hook runs against repository/botopink-lang/, but reusable
# from a standalone clone (lib's own CI, partial checkout). Runs:
#   1. zig build
#   2. zig build test
#   3. botopink test in every libs/<name>/ with .bp sources
#
# `zig build test-libs` is **not** in the default gate: it needs node/escript/
# wasmtime and is gated by scripts/test-libs.sh's pre-flight. Run it manually
# (or via the meta gate at the workspace root) when those runtimes are present.

botopinkLangGate() {
    local root="$1"
    cd "$root"

    echo -n "  Building ($(basename "$root"))... "
    if ! ( cd "$root" && zig build ) 2>&1; then
        fail "zig build failed"
    fi
    pass "zig build OK"

    echo -n "  Testing (zig build test)... "
    if ! ( cd "$root" && zig build test ) 2>&1; then
        fail "zig build test failed"
    fi
    pass "zig build test OK"

    local bin="$root/zig-out/bin/botopink"
    if [ ! -x "$bin" ]; then
        fail "botopink binary not found at $bin (zig build should produce it)"
    fi

    local lib_fail=""
    for cfg in "$root"/libs/*/botopink.json; do
        [ -e "$cfg" ] || continue
        local dir
        dir=$(dirname "$cfg")
        # Skip scaffold-only packages with no testable .bp sources (declaration
        # files `*.d.bp` are skipped by the compiler scanner, so they don't count).
        if [ -z "$(find "$dir/src" "$dir/test" 2>/dev/null -name '*.bp' ! -name '*.d.bp' | head -1)" ]; then
            echo "  Skipping $dir (no .bp sources)"
            continue
        fi
        echo -n "  Testing $dir (.bp)... "
        if ( cd "$dir" && "$bin" test ) >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
            lib_fail="$lib_fail $dir"
        fi
    done
    if [ -n "$lib_fail" ]; then
        fail "botopink .bp tests failed in:$lib_fail"
    fi
}
