#!/usr/bin/env bash
# install-tooling.sh — install or update the Botopink editor tooling.
#
# Two deliverables, both idempotent (re-run to update):
#   1. botopink-lsp     — built via `zig build`, copied to a PATH dir
#                         (default: ~/.local/bin, override with --bin-dir).
#   2. vscode-extension — compiled, packaged to a .vsix, and installed into
#                         VS Code / VSCodium via `code --install-extension`.
#
# Usage:
#   scripts/install-tooling.sh                 # both lsp + extension
#   scripts/install-tooling.sh --lsp-only      # just the binary
#   scripts/install-tooling.sh --ext-only      # just the extension
#   scripts/install-tooling.sh --bin-dir DIR   # install botopink-lsp into DIR
#
# Env:
#   BOTOPINK_BIN_DIR   same as --bin-dir
#   CODE_BIN           editor CLI to use (default: auto-detect code / codium)
#
# Exit code: 0 = success, 1 = a step failed.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

bin_dir="${BOTOPINK_BIN_DIR:-$HOME/.local/bin}"
do_lsp=1
do_ext=1

while [ $# -gt 0 ]; do
    case "$1" in
        --lsp-only) do_ext=0 ;;
        --ext-only) do_lsp=0 ;;
        --bin-dir)
            shift
            [ $# -gt 0 ] || { echo "install-tooling: --bin-dir needs an argument" >&2; exit 1; }
            bin_dir="$1"
            ;;
        -h | --help)
            sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//; $d'
            exit 0
            ;;
        *) echo "install-tooling: unknown argument: $1" >&2; exit 1 ;;
    esac
    shift
done

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "install-tooling: missing required tool: $1" >&2; exit 1; }; }

# ── 1. language-server: build + install botopink-lsp ────────────────────────
if [ "$do_lsp" -eq 1 ]; then
    need zig
    step "Building botopink-lsp (zig build install)"
    zig build install

    src="zig-out/bin/botopink-lsp"
    [ -x "$src" ] || { echo "install-tooling: expected binary not found: $src" >&2; exit 1; }

    step "Installing botopink-lsp → $bin_dir"
    mkdir -p "$bin_dir"
    install -m 0755 "$src" "$bin_dir/botopink-lsp"
    echo "installed: $bin_dir/botopink-lsp"

    case ":$PATH:" in
        *":$bin_dir:"*) ;;
        *) echo "install-tooling: note — $bin_dir is not on your PATH;" >&2
           echo "                add it, or set 'botopink.path' in VS Code settings." >&2 ;;
    esac
fi

# ── 2. vscode-extension: compile + package + install ────────────────────────
if [ "$do_ext" -eq 1 ]; then
    need npm

    code_bin="${CODE_BIN:-}"
    if [ -z "$code_bin" ]; then
        for c in code codium code-insiders; do
            command -v "$c" >/dev/null 2>&1 && { code_bin="$c"; break; }
        done
    fi
    [ -n "$code_bin" ] || { echo "install-tooling: no VS Code CLI found (tried code/codium/code-insiders); set CODE_BIN" >&2; exit 1; }

    ext_dir="modules/vscode-extension"
    step "Building VS Code extension ($ext_dir)"
    (
        cd "$ext_dir"
        npm install
        npm run compile
        npm run vscode:package

        version="$(node -p 'require("./package.json").version')"
        vsix="botopink-${version}.vsix"
        [ -f "$vsix" ] || { echo "install-tooling: vsix not produced: $vsix" >&2; exit 1; }

        printf '\n\033[1m==> Installing extension via %s\033[0m\n' "$code_bin"
        "$code_bin" --install-extension "$vsix" --force
        echo "installed: $vsix"
    )
fi

echo
echo "install-tooling: done."
