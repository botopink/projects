#!/usr/bin/env bash
# bp-lib.sh — gate for a standalone `.bp` lib (erika/jhonstart/onze/rakun).
#
# Runs `botopink test` in the lib's root. Locates the compiler via
# botopink-bin.sh; if absent, warns yellow and exits 0 for the gate (CI runs
# the full suite — a fresh standalone clone shouldn't be blocked on building
# the compiler locally).

bpLibGate() {
    local root="$1"
    cd "$root"

    # Bail out cleanly when there are no .bp sources to test (scaffold-only).
    if [ -z "$(find src test 2>/dev/null -name '*.bp' ! -name '*.d.bp' | head -1)" ]; then
        info "no .bp sources under $root/{src,test} — nothing to test"
        return 0
    fi

    local bin
    if ! bin=$(locateBotopink); then
        warn "botopink binary not found (env BOTOPINK_BIN, ancestor zig-out/bin, or \$PATH) — skipping .bp gate at $root"
        return 0
    fi

    echo -n "  Testing $(basename "$root") (botopink test)... "
    if ( cd "$root" && "$bin" test ) >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    fi

    echo -e "${RED}✗${NC}"
    echo
    echo "  Re-run for the failure output:"
    echo "    ( cd $root && $bin test )"
    fail "$(basename "$root"): botopink test failed"
}
