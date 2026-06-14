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

# The language core lives under repository/botopink-lang/ in the workspace layout
# (build.zig + the modules); fall back to the repo root for a legacy flat tree.
if [ -f repository/botopink-lang/build.zig ]; then
    core_dir="repository/botopink-lang"
else
    core_dir="."
fi

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

# K1 of v0.beta.19 frente-c-distribution: warn (don't fail) about every
# backend runtime that `zig build test-libs` would later need. The user can
# still install the LSP / extension on a partial env; this just preempts
# the cryptic "exec failed" hours later.
warn_missing() {
    local tool="$1" purpose="$2" hint="$3"
    command -v "$tool" >/dev/null 2>&1 && return
    printf '\033[1;33mwarning:\033[0m %s missing — %s.\n' "$tool" "$purpose" >&2
    printf '         install hint: %s\n' "$hint" >&2
}
check_backend_env() {
    step "Probing backend runtimes (advisory — not a gate)"
    warn_missing node     "needed for the commonJS backend (zig build test-libs)" "https://nodejs.org/en/download"
    warn_missing escript  "needed for the erlang/beam backends"                    "apt-get install erlang · brew install erlang"
    warn_missing erlc     "needed for the beam backend"                            "apt-get install erlang · brew install erlang"
    warn_missing wasmtime "needed for the wasm backend"                            "curl https://wasmtime.dev/install.sh | bash"
}

# ── 1. language-server: build + install botopink-lsp ────────────────────────
if [ "$do_lsp" -eq 1 ]; then
    need zig
    step "Building botopink-lsp (zig build install, in $core_dir)"
    ( cd "$core_dir" && zig build install )

    src="$core_dir/zig-out/bin/botopink-lsp"
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

    if [ -d repository/vscode-extension ]; then
        ext_dir="repository/vscode-extension"
    else
        ext_dir="modules/vscode-extension"
    fi
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

check_backend_env

echo
echo "install-tooling: done."
