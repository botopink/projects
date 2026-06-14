#!/usr/bin/env bash
# test-vscode.sh — wrapper for `zig build test-vscode` that lazy-runs
# `npm ci` on first invocation (gated on a marker file under
# `repository/vscode-extension/node_modules/`). Once the marker is
# present, subsequent invocations skip the install and go straight to
# `npm test --silent`.
#
# Marker rationale (K2 of v0.beta.19 frente-c-distribution): the test
# suite is `tsc` + Node's built-in test runner — no Electron host — so
# `npm install` is the one-shot cost a fresh clone pays. The marker is
# created after `npm ci` lands so re-running the build doesn't reinstall.
# Delete the marker (or wipe `node_modules`) to force a reinstall.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

ext_dir="repository/vscode-extension"
[ -d "$ext_dir" ] || {
    echo "test-vscode: extension dir not found at $ext_dir" >&2
    exit 1
}

marker="$ext_dir/node_modules/.botopink-installed"

if [ ! -f "$marker" ]; then
    if ! command -v npm >/dev/null 2>&1; then
        cat >&2 <<EOF
test-vscode: \`npm\` missing — required to install the extension's
            pure-fn test dependencies. Install Node.js 20+:
              https://nodejs.org/en/download
EOF
        exit 1
    fi
    echo "==> first run: npm ci ($ext_dir)"
    ( cd "$ext_dir" && npm ci )
    mkdir -p "$ext_dir/node_modules"
    : > "$marker"
fi

if ! command -v npm >/dev/null 2>&1; then
    cat >&2 <<EOF
test-vscode: \`npm\` missing — required to run the test suite.
EOF
    exit 1
fi

exec npm --prefix "$ext_dir" test --silent
