# Front 132 — gate-otp-pin: the OTP the compiler emits for, checked on every erlang and beam run

**Priority:** high — decision 228: the gate on this machine ran OTP 29 while CI pins 28, so an
emitted module OTP 28 refuses was green here and red only on GitHub.
**Depends on:** nothing; lands after the gate is green on `feat` (it adds a refusal every erlang and
beam stage passes through).
**Owns:** `modules/manifest/src/root.zig` (the `"otp"` field), the compiler's supported-OTP constant
and its check in `modules/compiler-cli/src/cli/{build,run,test_cmd}.zig` (wherever `erl` / `erlc`
is first spawned for a target), `botopink --version`, `scripts/gate.sh` (the check before stage 2),
`.github/workflows/test.yml` of botopink-lang and of the five libraries (the OTP they install is
read from the compiler, not written twice), `modules/compiler-cli/tests/cli_contract.sh` (the
refusal cases), `docs.md` § the manifest, and the `AGENTS.md` of each directory touched.
**Does not touch:** the emitters (a construct OTP 28 refuses is a codegen defect, fixed where it is
emitted); the comptime node's own OTP use beyond the same check.

---

## Problem

`erl` / `erlc` on `PATH` decide which Erlang the build is checked and run against; nothing compares
that with what CI runs. Measured on 2026-10-02: this machine has OTP 29 (`erl -noshell -eval
'io:format("~s",[erlang:system_info(otp_release)]),halt().'` → `29`); botopink-lang's ubuntu row
pins `otp-version: '28'`; the libraries' macOS rows installed Homebrew's latest (29.0.5) until
decision 227. The emitter wrote `erlang:element(2, C)(9)`, accepted by OTP 29 and refused by 28
(`syntax error before: '('`), and the local gate stayed green.

## Decision 228

1. **The compiler declares the OTP release it emits for** — one exact release, today `28` — in one
   constant. `botopink --version` prints it (`otp: 28`).
2. **Every erlang or beam run checks it.** Before `botopink build|run|test --target erlang|beam`
   spawns `erlc` or `erl`, it reads the release of the `erl` on `PATH`; another release is refused:
   ```
   error: botopink emits Erlang for OTP 28, and `erl` on PATH is OTP 29 — install OTP 28 and put it on PATH
   ```
   No flag, variable or manifest value turns the refusal into a warning (decision 67).
3. **`botopink.json` may pin it too**, inside what the compiler supports:
   ```json
   { "name": "rakun", "otp": "28" }
   ```
   A value the compiler does not support is a manifest error located at the value. Every package of
   a build's closure that declares `"otp"` must declare the same release; a mismatch is refused,
   naming both manifests. Without the field, the compiler's release applies.
4. **The gate and the workflows read it from the compiler.** `scripts/gate.sh` runs the check before
   stage 2 and stops with the same message; each workflow installs the release `botopink --version`
   prints (or the root manifest's `"otp"`), and its assertion step compares `erl` against it — the
   release is written once, in the compiler.

## Steps

### Step 1 — the constant, `--version`, and the run-time check

**Acceptance:**
- [ ] `botopink --version` prints `otp: 28`
- [ ] with OTP 29 first on `PATH`, `botopink build --target erlang` and `--target beam` exit 1 with
      the message above, before any `.erl` is written; with 28, they build
- [ ] `cli_contract.sh`: both cases, with a fake `erl` on `PATH` answering 29 and 28

### Step 2 — the manifest field

**Acceptance:**
- [ ] `"otp": "26"` → `error: botopink emits Erlang for OTP 28; "otp" names 26` located at the value
- [ ] a closure where `rakun` says `"28"` and a dependency says `"29"` → refused, naming both files
- [ ] the field documented in `docs.md` § the manifest; the five libraries' root manifests say `"otp": "28"`

### Step 3 — the gate and the seven workflows

**Acceptance:**
- [ ] `scripts/gate.sh --cold` with OTP 29 on `PATH` stops before stage 2 with the message
- [ ] every workflow's install step takes the release from the compiler (or the root manifest); its
      "Assert Erlang/OTP" step compares against the same value (decision 227's literal `28` goes)
- [ ] the meta `hook-integrity` check 4 still finds the five library workflows' shared steps identical

## Gate

- [ ] `scripts/gate.sh --cold` green **with OTP 28 on `PATH`** — this machine installs it first
      (`mise install erlang@28` and `mise use`, or kerl; OTP 29 stays installed but not first on `PATH`)
- [ ] every `AGENTS.md` of a touched directory updated in the same commit
- [ ] commits on `front/132-gate-otp-pin`; no push, no merge — landing is the coordinator's step

## Blast radius

- Every developer and CI row needs exactly OTP 28 for erlang and beam; a machine with only 29 can no
  longer build those targets. That is the decision, not a side effect.
- The comptime node (`persistent_beam.zig`, `erl`) runs under the same check.
- Moving to OTP 29 later is one constant, the libraries' `"otp"` lines and nothing in the workflows.

## Notes

- Decision 227 (OTP 28 on the macOS rows) stays; this front makes its literal come from the compiler.
