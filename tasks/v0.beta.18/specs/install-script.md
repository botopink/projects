# install-script — one-line bootstrap for the botopink toolchain

**Slug**: install-script
**Depends on**: [release-workflows](release-workflows.md), [bpmp](bpmp.md)
**Files**: `repository/botopink-lang/scripts/install.sh`, `repository/botopink-lang/scripts/install.ps1`, `repository/botopink-lang/scripts/AGENTS.md`
**Touches docs**: `repository/botopink-lang/README.md` (the "Installation" section becomes a one-liner), `repository/botopink-lang/docs.md`, root `AGENTS.md` (link to installation), this set's `README.md`
**Status**: pending

## Problem

The user has nothing — no Zig, no bpmp, no botopink. They want all of it on
their machine with one shell command. The rust precedent is now muscle memory
in every developer:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

We replicate that experience for botopink. After this spec lands, a fresh-OS
user runs:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://botopink.dev/install.sh | sh
```

and gets `~/.bpmp/` populated with the latest stable botopink + bpmp +
botopink-lsp + botopink-lib-test, plus a printed line telling them to add
`~/.bpmp/bin` to `PATH`. On Windows the equivalent is

```powershell
iex (irm 'https://botopink.dev/install.ps1')
```

(or the literal GitHub raw URL while the `botopink.dev` redirect is not yet
configured — see Notes).

## Target — install.sh contract

### Detection

```text
os    = case `uname -s` of
          Linux      → "linux"
          Darwin     → "macos"
          *          → fail with "unsupported OS"
arch  = case `uname -m` of
          x86_64     → "x86_64"
          aarch64|arm64 → "aarch64"
          *          → fail with "unsupported arch"
target = "${os}-${arch}"
```

Must match one of the five tuples in [release-workflows §"Cross-compile
matrix"](release-workflows.md). If not, refuse with the list of supported
tuples and a `--target <t>` override for manual selection.

### Version selection

```text
version =
   $BOTOPINK_VERSION                                  # explicit override (e.g. "v0.0.1")
   else "latest"                                       # use github's redirect
url_base = case version of
   "latest"  → "https://github.com/botopink/botopink-lang/releases/latest/download"
   "v<x>"    → "https://github.com/botopink/botopink-lang/releases/download/v<x>"
```

GitHub's `releases/latest/download/<file>` alias gives us the latest stable
without an API call (no rate limit hits, no network round-trip beyond the
single redirect). The `BOTOPINK_VERSION` env var lets reproducible bootstraps
(CI, container images) pin a version.

### Files fetched

For the resolved target + version, four archives + their sha256 sidecars:

```text
${url_base}/botopink-${version}-${target}.${ext}
${url_base}/botopink-${version}-${target}.${ext}.sha256
${url_base}/botopink-lsp-${version}-${target}.${ext}
${url_base}/botopink-lsp-${version}-${target}.${ext}.sha256
${url_base}/botopink-lib-test-${version}-${target}.${ext}
${url_base}/botopink-lib-test-${version}-${target}.${ext}.sha256
${url_base}/bpmp-${version}-${target}.${ext}
${url_base}/bpmp-${version}-${target}.${ext}.sha256
```

where `${ext} = tar.gz` on linux/macos, `zip` on windows. The script downloads
each archive into a temp dir, verifies its sha256 against the sidecar, then
extracts.

### Disk layout

Mirrors [`bpmp` §"Storage"](bpmp.md). Concretely:

```text
$BPMP_HOME = ${BOTOPINK_INSTALL_DIR:-$HOME/.bpmp}        # POSIX
              ${env:BOTOPINK_INSTALL_DIR:-$env:USERPROFILE\.bpmp}   # Windows

$BPMP_HOME/botopink/versions/${version}/{botopink, botopink-lsp, botopink-lib-test, bpmp}
$BPMP_HOME/botopink/versions/stable                      → symlink → ${version}
$BPMP_HOME/bin/bpmp                                      → symlink → ../botopink/versions/stable/bpmp
```

The shim `$BPMP_HOME/bin/bpmp` is what the user adds to `PATH`. It points
through `stable` so a future `bpmp self update` swap-by-symlink picks up
automatically.

### Clobber refusal

If `$BPMP_HOME` already exists **and** is non-empty, the install script
**fails with exit 1** and prints:

```text
error: $BPMP_HOME (~/.bpmp) already exists.
       To upgrade, run:    bpmp self update
       To start over, run: bpmp self uninstall   (then re-run this installer)
       To force overwrite: BOTOPINK_INSTALL_FORCE=1 sh install.sh
```

This is the single biggest difference from rustup: rustup's installer is
interactive (asks "default/customize/cancel"). Eric's installer is
**non-interactive by default** — a one-liner piped into `sh` should not
require terminal input. `BOTOPINK_INSTALL_FORCE=1` reproduces the "yes,
clobber it" answer.

### PATH instructions

After successful install, print:

```text
botopink ${version} installed at ${BPMP_HOME}.

Add to your shell rc:
  POSIX (bash, zsh):  export PATH="$HOME/.bpmp/bin:$PATH"
  fish:               fish_add_path $HOME/.bpmp/bin
  pwsh:               $env:PATH = "$env:USERPROFILE\.bpmp\bin;$env:PATH"

Then verify with:
  bpmp version
  botopink --version
```

A `--modify-path` flag (off by default) appends the export line to the
detected shell rc. Off by default because silently editing a user's rc file
is a footgun — the rust installer asks first; we just print.

### Flags + env

| Flag | Env | Effect |
|---|---|---|
| `--target <tuple>` | — | Override OS/arch detection |
| `--version <v>` | `BOTOPINK_VERSION` | Pin a specific version (default: latest) |
| `--install-dir <path>` | `BOTOPINK_INSTALL_DIR` | Override `$BPMP_HOME` (default: `$HOME/.bpmp`) |
| `--force` | `BOTOPINK_INSTALL_FORCE=1` | Overwrite an existing install |
| `--modify-path` | — | Append PATH export to `$SHELL`'s rc (off by default) |
| `--no-modify-path` | — | Default; explicit form for scripts |
| `--quiet` | — | Suppress non-error output |
| `--help` | — | Print usage and exit 0 |

### macOS quarantine note

After install on macOS, print:

```text
note: macOS may quarantine downloaded binaries. If `botopink --version`
      shows "killed: 9" or a Gatekeeper popup, run:
        xattr -d com.apple.quarantine ~/.bpmp/botopink/versions/stable/*
      v0.beta.18 does not codesign the binaries; notarisation is on the
      roadmap.
```

## Target — install.ps1 contract

Same behaviour, PowerShell-native:

```powershell
# arch detection
$arch = switch ($env:PROCESSOR_ARCHITECTURE) {
  'AMD64' { 'x86_64' }
  'ARM64' { fail "windows-aarch64 is not a supported target" }
  default { fail "unsupported arch: $_" }
}
$target = "windows-$arch"

# version selection (same logic, env vars)
# download — Invoke-WebRequest with explicit -UseBasicParsing
# sha256 — Get-FileHash -Algorithm SHA256
# extract — Expand-Archive
# disk layout — same $BPMP_HOME = $env:BOTOPINK_INSTALL_DIR or "$env:USERPROFILE\.bpmp"
# refuse clobber unless $env:BOTOPINK_INSTALL_FORCE -eq '1'
```

PowerShell symlink fallback: on Windows without developer mode or admin,
`New-Item -ItemType SymbolicLink` fails. The script falls back to a
**copy** (and prints a one-line note that future `bpmp self update` may take
a tick longer to swap). This mirrors how rustup-init.exe handles the same
case.

## Examples

### default install (Linux, current latest)
```bash
$ curl --proto '=https' --tlsv1.2 -sSf https://botopink.dev/install.sh | sh
detected target: linux-x86_64
resolving latest version … v0.0.1
downloading botopink … verified sha256 (a1b2c3d4…)
downloading botopink-lsp … verified sha256 (e4d909c2…)
downloading botopink-lib-test … verified sha256 (9f8e7d6c…)
downloading bpmp … verified sha256 (1234abcd…)
installing to ~/.bpmp/botopink/versions/v0.0.1/
linking ~/.bpmp/botopink/versions/stable → v0.0.1
linking ~/.bpmp/bin/bpmp → ../botopink/versions/stable/bpmp

botopink v0.0.1 installed at ~/.bpmp.

Add to your shell rc:
  export PATH="$HOME/.bpmp/bin:$PATH"
…
```

### pinned bootstrap (CI, container image)
```bash
$ BOTOPINK_VERSION=v0.0.1 BOTOPINK_INSTALL_DIR=/opt/botopink \
    sh install.sh --no-modify-path --quiet
$ /opt/botopink/bin/bpmp version
bpmp v0.0.1 · botopink v0.0.1
```

### re-running on existing install — refuses
```bash
$ sh install.sh
error: $BPMP_HOME (~/.bpmp) already exists.
       To upgrade, run:    bpmp self update
       …
$ echo $?
1
```

### overriding the clobber refusal
```bash
$ BOTOPINK_INSTALL_FORCE=1 sh install.sh
warning: $BPMP_HOME exists — overwriting
…
```

### Windows (PowerShell)
```powershell
PS> iex (irm 'https://botopink.dev/install.ps1')
detected target: windows-x86_64
resolving latest version … v0.0.1
downloading bpmp … verified sha256 (1234abcd…)
…
botopink v0.0.1 installed at C:\Users\user\.bpmp.

Add to your PowerShell profile:
  $env:PATH = "$env:USERPROFILE\.bpmp\bin;$env:PATH"
```

### unsupported arch
```bash
$ uname -m
riscv64
$ sh install.sh
error: unsupported arch: riscv64
supported targets:
  linux-x86_64    linux-aarch64
  macos-x86_64    macos-aarch64
  windows-x86_64
to override: sh install.sh --target <tuple>
```

## Steps

### F0 — write install.sh (POSIX)
- [ ] `scripts/install.sh` — `#!/bin/sh`, POSIX-compatible, **no
      bashisms** (so `dash`/`busybox sh` work). Strict mode: `set -eu`.
- [ ] OS/arch detection table. Five-tuple match; explicit error on
      miss with `--target` override.
- [ ] Version resolver — env > "latest". Build URL bases.
- [ ] Download function — prefers `curl --proto '=https' --tlsv1.2
      -sSfL`, falls back to `wget --https-only -qO-` if curl absent.
      Resolves to a tmp file under `$(mktemp -d)`.
- [ ] sha256 verify — `sha256sum` (linux) / `shasum -a 256` (macOS),
      detected at runtime. Fails loudly with both digests on mismatch.
- [ ] Extract — `tar -xzf` for tar.gz; on macOS, the same `tar`
      invocation works. The script never sees `.zip` (Windows path).
- [ ] Disk layout — mkdir -p the version dir; place binaries with
      `+x` perms; ln -s the stable and bin symlinks.
- [ ] Clobber refusal — single readable error with three remediation
      lines + force-flag instruction.
- [ ] PATH printer — detect `$SHELL`, print matching rc snippet.
- [ ] `--modify-path` implementation — append, but verify the line
      isn't already there (idempotent).
- [ ] Tested on: Debian (sh = dash), Ubuntu (sh = dash), Alpine
      (sh = busybox), macOS (sh = bash in posix mode). All five
      shells must execute the same code path.

### F1 — write install.ps1 (Windows)
- [ ] `scripts/install.ps1` — `Set-StrictMode -Version Latest`,
      `$ErrorActionPreference = 'Stop'`.
- [ ] Arch detection.
- [ ] Version resolver — same env var conventions.
- [ ] Download — `Invoke-WebRequest -UseBasicParsing`.
- [ ] sha256 verify — `Get-FileHash -Algorithm SHA256`.
- [ ] Extract — `Expand-Archive`.
- [ ] Disk layout — symlink with junction fallback if `New-Item
      -ItemType SymbolicLink` errors (no developer mode).
- [ ] PATH printer — pwsh + cmd snippets.
- [ ] Tested on: windows-2022 GitHub runner (PowerShell 5.1 and 7.x).

### F2 — scripts/AGENTS.md
- [ ] New `repository/botopink-lang/scripts/AGENTS.md` documenting both
      installer scripts: their contract (env vars, flags, exit codes),
      the URL convention they consume, and the integrity model (sha256
      sidecar). Pointers to release-workflows for "where the assets
      come from" and to bpmp for "what the user does next".

### F3 — README + docs
- [ ] `repository/botopink-lang/README.md` gets a top-of-file
      "Installation" section: the curl one-liner + the PowerShell
      one-liner + a "see scripts/AGENTS.md" pointer + a "manual
      install" section for users who don't want to pipe to sh.
- [ ] `repository/botopink-lang/docs.md` documents the same plus the
      `BOTOPINK_VERSION` reproducible-install workflow.

### F4 — hosting (optional, post-merge)
- [ ] Configure `botopink.dev/install.sh` (and `.ps1`) as a redirect
      to the corresponding raw GitHub URL on `main`. Out of scope
      for the spec itself — but the spec documents the redirect-name
      contract so it can be set up later without re-spec'ing.
- [ ] Until that redirect exists, the docs point at the raw GitHub
      URL: `https://raw.githubusercontent.com/botopink/botopink-lang/main/scripts/install.sh`.

## Test scenarios

```
detect ---- linux-x86_64 host detects target = linux-x86_64
detect ---- macOS arm host detects target = macos-aarch64
detect ---- riscv64 host errors with supported-target list + override hint
detect ---- --target macos-x86_64 overrides detection on a linux host (manual install scenario)
ver    ---- BOTOPINK_VERSION=v0.0.1 builds the explicit-tag URL
ver    ---- default uses releases/latest/download/ alias
dl     ---- curl present → curl used
dl     ---- curl absent, wget present → wget used
dl     ---- neither present → error with both names
ver    ---- sha256 mismatch aborts with both digests in the error
inst   ---- fresh dir → all five binaries land, stable + bin symlinks created
inst   ---- exists → exits 1 with the three remediation lines
inst   ---- BOTOPINK_INSTALL_FORCE=1 → overwrites with a one-line warning
inst   ---- BOTOPINK_INSTALL_DIR=/opt/bp → installs to /opt/bp instead of $HOME/.bpmp
path   ---- --modify-path on a bash user → appends `export PATH=…` to ~/.bashrc, idempotent
path   ---- --modify-path on a fish user → uses fish_add_path syntax
post   ---- post-install run: bpmp version reports a sane version + active toolchain
ps     ---- install.ps1 on windows-2022: same five binaries land at %USERPROFILE%\.bpmp
ps     ---- install.ps1 without developer mode → falls back to copy + prints note
shells ---- the same script runs identically under dash, bash-posix, busybox, ash
```

## Notes

- **Why not interactive prompts like rustup?** Piping `curl | sh`
  routinely happens in non-terminal contexts (CI, Dockerfile, headless
  bootstrap). The non-interactive default is friendlier there; users
  who want a prompt are typically already in a position to read the
  script and pass flags. The script is small enough to read end-to-end
  (target: under 300 lines POSIX).
- **Why `--proto '=https' --tlsv1.2` in the example?** Two `curl` flags
  with strong opinions: `--proto '=https'` refuses any redirect off
  HTTPS, `--tlsv1.2` is the lowest version we trust. Rust's installer
  popularised this and it is the right default for piped-to-sh
  scripts. The script itself prints the same incantation in its docs.
- **Why fall back to a copy on Windows without symlinks?** Because the
  default Windows install (no developer mode, no admin) blocks
  symlinks. A junction works for directories but not for files
  (`bpmp` shim). Copying gives the right behaviour at the cost of an
  extra file write per `self update`. Acceptable.
- **Idempotency of `--modify-path`.** The append step greps the rc
  file for an existing `# botopink` marker line and a literal
  `$HOME/.bpmp/bin` substring before writing. Either match → no-op.
- **Why a `--quiet` flag but no `--verbose`?** The default *is*
  verbose-enough (per-step status lines). `--quiet` suppresses
  progress for CI use. Pure-error mode is the only thing scripts ever
  need beyond default.
- **Hosting at `botopink.dev`.** Not part of the spec's acceptance
  gate. The contract documented here is *which URL the script lives
  at* — once the spec lands, a separate ops step sets the redirect.
  Until then, every doc points at the raw-GitHub URL on `main`.
- **The Windows path is not yet in the release matrix's defaults.**
  [release-workflows](release-workflows.md) includes `windows-x86_64`;
  this script must be tested against that target's zip archive
  shape. The PowerShell test in §F1 closes that loop.
- **Cross-spec coordination.**
  - [`release-workflows`](release-workflows.md) — assets must exist
    at the documented URLs before this script does anything useful.
  - [`bpmp`](bpmp.md) — owns the `$BPMP_HOME` layout this script
    populates; the script's only contract is "leave a working bpmp
    at `$BPMP_HOME/bin/bpmp`". Everything beyond that is bpmp's
    territory.
  - This script writes the **same** `stable` symlink that `bpmp self
    update` will subsequently replace. Both must agree on the layout
    (D5).
