# v0.beta.19 — three frentes + prim-op annotation extension

> v0.beta.18 distributed the language; v0.beta.19 **closes every recorded gap**
> still open across v0.beta.12 (`*fn` cleanup), v0.beta.14
> (`backends-parity-tail`), v0.beta.16 (`recorded-gap-sweep` §A6–§G),
> v0.beta.17 (`repo-restructure` ambient deferreds), and v0.beta.18
> (`distribution` online follow-ups + the unshipped `module-auto-tag` spec) —
> organised as **three file-disjoint frentes**, each runnable on its own
> worktree. A satellite spec (`prim-op-annotation`) extends `#[@external]`'s
> grammar so the remaining hardcoded `mem.eql(callee, …)` switches in every
> codegen backend can be authored as annotations, deleting Frente A §A6's
> "irreducible allow-list" carve-out and adjacent surfaces
> (`emitResultOptionOp`, `@todo`/`@panic`/`@block`).

## Scope

| Frente | Slug | Tracks | Files |
|---|---|---|---|
| [frente-a-compiler](specs/frente-a-compiler.md) | `frente-a-compiler` | §A annotation-driven-builtins tail · §B generic-inference · §C wasm-aggregates + wat refactor · §D cross-backend parity · §G erika DSL extensions · §S `*fn` removal · §U unused-builtin sweep | parser · ast · comptime · codegen ×4 (commonJS/erlang/beam_asm/wat) · `libs/std/src/{builtins,primitives}.d.bp` · `libs/erika/src/erika.bp` |
| [frente-b-rules-tooling](specs/frente-b-rules-tooling.md) | `frente-b-rules-tooling` | Rules track §0–§4 (effect-annotation contract: `#[@result]` / `#[@future]` / `#[@generator]` / `#[@iterator]` / `#[@asyncGenerator]` / `#[@context]` + default generic parameters §1G; §1/§1F/§1I/§1C carry the user's hand-supplied addenda verbatim) · §E LSP definition tail · §F TS `.d.ts` template skip · §T test-run-log | `comptime/{infer,transform,contextStack}.zig` · `parser/decls.zig` · `language-server/src/engine.zig` · `codegen/typescript.zig` · test-mode codegen ×4 · `modules/compiler-cli/src/cli/test_cmd.zig` · `modules/lib-test-runner/src/{runner,report}.zig` · `libs/std/src/builtins.d.bp` (§4 mirror) |
| [frente-c-distribution](specs/frente-c-distribution.md) | `frente-c-distribution` | §H bpmp online · §I distribution submodule mergeback · §J module-auto-tag · §K v17 environment deferreds | `modules/bpmp/src/**` · each sibling repo's `feat` branch + the submodule pointer bumps · `.github/workflows/tag.yml` × 2 + 3 new `botopink.json` · `scripts/install-tooling.sh` + `build.zig` env gates |
| [prim-op-annotation](specs/prim-op-annotation.md) | `prim-op-annotation` | satellite to Frente A §A — extends `#[@external]` with `$self` / `$0..N` / `$argc` / `$stringify(...)` markers + `when($argc == N)` arity branching + `"""…"""` multi-line inline-fun templates, then migrates **3 families** of hardcoded switch arms (Family 1: `emitPrimMethod` 19 methods · Family 2: `emitResultOptionOp` 9 synthetic callees · Family 3: `@todo`/`@panic`/`@block`) — ~105 switch arms across 4 backends → zero | `parser/decls.zig` (`parseExternalCallTemplate` extension) · `ast.zig` (richer `ExternalCallTemplate`) · `codegen/{erlang,beam_asm,commonJS,wat}.zig` (consumer + switch deletions) · `libs/std/src/{builtins,primitives}.d.bp` · `comptime/primOpTemplate.zig` (new shared renderer) |
| [std-expansion](specs/std-expansion.md) | `std-expansion` | satellite consuming `prim-op-annotation` — fills cross-backend stdlib gaps from Node + Erlang reference APIs in five waves: §W1 essentials (`math`/`json`/`base64`/`time`/`random`) · §W2 system (`env`/`path`/`fs`/`process`/`os`) · §W3 text (`regex`/`unicode` + `array_ext`/`string_ext` extension methods) · §W4 network+crypto (`url`/`querystring`/`http` client/`crypto`) · §W5 assertions (`assert`). Every new `.bp` file ships with header comments citing the canonical Node + Erlang URLs and inline `test { … }` blocks covering the surface. | 13 new `libs/std/src/*.bp` files + `interface Array<T>` + `interface String` extensions on `primitives.d.bp` + sidecar adapters (`.mjs` for node, `.erl` for erlang) for `json` + `libs/std/tests/` per-module test fixtures + coverage-matrix gate in `comptime/infer.zig` |
| [std-expansion-tail](specs/std-expansion-tail.md) | `std-expansion-tail` | closes the 12 deferred std modules from `std-expansion` (json/base64/env/fs/process/os/regex/unicode/array_ext/string_ext/http/crypto) + the in-module tails (`path.relative`/`resolve` · `random.intInRange`/`bool`/`shuffle`/`seed` · `time.monotonic`/`sleep`/`formatIso8601`/`measure` · `asserts.throws`/`matches`/`AssertError`) + the F6 `STD-001` `std-unsupported-on-target` diagnostic at the `from "std"` import site + F7 examples.md "Real-world examples" CLI + the codegen per-target coverage doc. Adds two `prim-op-annotation` grammar pieces: §A2 chained-host-call templates (regression-tested only — passthrough already works) and §A3 `#[@result] declare fn` template-owned wrapper. | 10 new `libs/std/src/*.bp` files + 5 tail edits on landed modules + `primitives.d.bp` extension methods + `libs/std/src/sidecars/*.{mjs,erl}` adapters + `compiler-core/src/comptime/infer.zig` `STD-001` + `compiler-cli/src/cli/lib_test.zig` sidecar shipping + `docs.md` / `CHANGELOG.md` / `examples.md` rolls |
| [recursive-test-gate](specs/recursive-test-gate.md) | `recursive-test-gate` | local pre-commit gate, version-controlled + recursive — every project (meta + 6 submodules) has a tracked `scripts/git-hooks/pre-commit` that runs its own `zig build test` / `botopink test` / `npm test`; the meta hook additionally validates **staged submodule pointer bumps** by running the submodule's gate against the staged SHA in a throwaway worktree; one bootstrap script (`scripts/install-hooks.sh`) wires all 7 symlinks; a `hook-integrity.yml` CI smoke catches `--no-verify` bypasses | `scripts/git-hooks/**` (new tracked tree) · `scripts/install-hooks.sh` (new) · `repository/<sub>/scripts/git-hooks/pre-commit` + `lib/runner-standalone.sh` × 6 submodules · `.github/workflows/hook-integrity.yml` (new) · `scripts/AGENTS.md` + `repository/AGENTS.md` + each lib's `AGENTS.md` |

## Order

```text
Frente A — §A keystone ─▶ §B/§C/§D/§G   (codegen tail, byte-identical refactor first)
           §S, §U                       (cleanup tracks — parallel with everything)

Frente B — Rules §0 → §1 → §1F → §1I → §1C → §1G → §2 → §3 → §4 → F0–F7
           §E, §F, §T                   (parallel tracks, file-disjoint)

Frente C — §H ─▶ §I ─▶ §J               (distribution track)
           §K                           (env plumbing, fire-and-forget)

prim-op-annotation ─▶ runs alongside Frente A §A6/§D5 — landings in any order
                      (the grammar extension lands first as F0–F1; then F2/F2-R/F2-B
                      migrate the 105 switch arms across 4 backends)

std-expansion      ─▶ consumes prim-op-annotation; runs in its own per-wave worktrees
                      (.tasks/std-wave1/ ... wave5/). §W1 first (essentials), then
                      §W2 (system), §W3 (text + Array/String extension), §W4
                      (network+crypto), §W5 (assertions). Each wave is one
                      file-disjoint commit.

std-expansion-tail ─▶ closes std-expansion's 12 deferreds + the in-module tails +
                      F6 (`STD-001` `std-unsupported-on-target`) + F7 examples-CLI;
                      authors two prim-op-annotation grammar additions (§A2 chained
                      host calls + §A3 `#[@result] declare fn` template). One
                      worktree (.tasks/std-expansion-tail/). Phases F0/F1 (docs +
                      diagnostic) first, then F2/F3 (sidecar infra + grammar), then
                      F4 (in-module tails), then F5–F8 wave by wave, F9 closes.

recursive-test-gate ─▶ independent of every other spec (it only consumes the gates
                      each project already ships: zig build test / botopink test /
                      npm test). Lands on its own worktree .tasks/recursive-test-gate/.
                      File-disjoint with Frentes A/B/C: touches only scripts/git-hooks/**,
                      install-hooks.sh, per-submodule scripts/git-hooks/, and
                      .github/workflows/hook-integrity.yml.
```

- **The three frentes are file-disjoint** at the directory level — they can
  proceed in parallel on three worktrees with no cross-merge contention.
- **One coordination point:** Frente A's §D-D4 (`#[@future]` erlang/beam
  lowering) consumes the surface contract authored by Frente B's Rules
  track §1F. Schedule: Frente B's §1F lands first; Frente A's §D-D4 reads
  it.
- **Inside Frente A:** §A first (byte-identical refactor that §B/§D
  consume); §B/§C/§D parallelise after; §G is isolated; §S and §U are
  parallel with everything (§S touches lexer/parser/ast, §U touches
  `builtins.d.bp` + comptime handlers).
- **Inside Frente B:** the Rules track has internal DAG (§0 → §1 → …);
  §E/§F/§T are independent and can land in any order.
- **Inside Frente C:** §H → §I → §J along the distribution track (each
  consumes the prior); §K is fire-and-forget.

## Non-goals (explicit)

- **No new language surface besides the rules captured by Frente B's §1
  through §1G.** Every checkbox elsewhere closes an *already-recorded* gap
  or finishes an *already-merged* parser layer — no spec invents semantics
  beyond §1's auto-wrap (already an addendum from the user) and §1G's
  default generic positioning rule.
- **No backward-compatibility shim for `*fn`.** Frente A §S is a hard
  delete: `*fn` parses as a syntax error after this set lands.
- **No "soft" deprecation for the dropped builtins.** Frente A §U is a
  hard delete with live grep evidence captured in the commit body.
- **No external dependency for the run log.** Frente B §T is a string
  capture inside the test-mode codegen — no log library, no `tee`, no
  temp files.
- **No registry/index work** for `bpmp` — Frente C §H is purely "wire
  `std.http` / `std.tar` into the offline stubs"; the v0.beta.18 spec
  `bpmp.md` already nails the contract.
- **No `module-auto-tag` redesign.** Frente C §J implements the
  v0.beta.18 spec 6 *as written*; that spec is immutable.

## Goal

`zig build test` + `zig build test-libs` + `botopink-lib-test` green across
every backend (incl. wasm under wasmtime); zero `*fn` literals anywhere in
`repository/`; every builtin in `libs/std/src/builtins.d.bp` has at least
one authored caller; every `botopink test` invocation prints a
`----- RUN LOG -----` block per test; the six `#[@<effect>]` markers are
fully specified with bilingual addenda for the four user-supplied
rulesets (§1, §1F, §1I, §1C); `bpmp install <pkg>` works end-to-end
**online**; every lib submodule pointer in `repository/botopink-lang`
tracks its sibling repo's `feat` head; `compiler-core` / `compiler-cli` /
`vscode-extension` cut their own version tags via `module-auto-tag`.
After this set lands, every spec authored before it is fully closed.
