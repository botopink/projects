#!/usr/bin/env bash
# test-runner.sh — project detection + dispatch for the tracked pre-commit hook.
#
# Sourced by `scripts/git-hooks/pre-commit` (the wrapper). Exposes:
#   detectProject(root)   echoes one of: meta | botopink-lang | bp-lib | vscode-extension | unknown
#   runProjectGate(root)  detects and runs that project's gate. Exits non-zero on failure.
#
# Detection table (per spec):
#   .gitmodules                       → meta
#   build.zig + modules/              → botopink-lang
#   package.json with vscode markers  → vscode-extension
#   botopink.json only                → bp-lib

# Resolve the directory holding this script so we can source siblings.
__GIT_HOOKS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/colors.sh
. "$__GIT_HOOKS_LIB_DIR/lib/colors.sh"
# shellcheck source=lib/botopink-bin.sh
. "$__GIT_HOOKS_LIB_DIR/lib/botopink-bin.sh"

detectProject() {
    local root="$1"
    if [ -f "$root/.gitmodules" ]; then
        echo meta
        return 0
    fi
    if [ -f "$root/build.zig" ] && [ -d "$root/modules" ]; then
        echo botopink-lang
        return 0
    fi
    if [ -f "$root/package.json" ] && grep -q '"vscode"' "$root/package.json" 2>/dev/null; then
        echo vscode-extension
        return 0
    fi
    if [ -f "$root/botopink.json" ]; then
        echo bp-lib
        return 0
    fi
    echo unknown
    return 0
}

runProjectGate() {
    local root="$1"
    local kind
    kind=$(detectProject "$root")

    case "$kind" in
        meta)
            # shellcheck source=runners/meta.sh
            . "$__GIT_HOOKS_LIB_DIR/runners/meta.sh"
            metaGate "$root"
            ;;
        botopink-lang)
            # shellcheck source=runners/botopink-lang.sh
            . "$__GIT_HOOKS_LIB_DIR/runners/botopink-lang.sh"
            botopinkLangGate "$root"
            ;;
        bp-lib)
            # shellcheck source=runners/bp-lib.sh
            . "$__GIT_HOOKS_LIB_DIR/runners/bp-lib.sh"
            bpLibGate "$root"
            ;;
        vscode-extension)
            # shellcheck source=runners/vscode-extension.sh
            . "$__GIT_HOOKS_LIB_DIR/runners/vscode-extension.sh"
            vscodeExtensionGate "$root"
            ;;
        *)
            warn "unknown project type at $root — skipping gate"
            return 0
            ;;
    esac
}
