# The command contract, and where HEAD departs from it

> Carried from `1.0.2-beta/02-cli-gate/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F12` and bare front numbers are the old numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).
>
> Rows C1–C14 are **closed** at the CLI (1.0.2-beta cli-gate: each has a test). What this front still
> needs from this file: the two contract facts (step 1) and the diagnostic that is discarded in
> `codegenEmit` and `ComptimeOutput.outcome` (steps 2–3).

Several of these defects exist because the contract was never stated. This is the contract first,
then one row per place the code departs from it.

Paths are relative to `repository/botopink-lang/`; `main.zig` and `cli/*.zig` live under
`modules/compiler-cli/src/`, everything else under `modules/compiler-core/src/`.

## The contract

What each command promises. This is the target, not a description of HEAD.

| Command | Reads | Writes | Spawns | Exit 0 | Non-zero |
|---|---|---|---|---|---|
| `build [--target T] [--out D] [--typescript]` | `botopink.json`, the `src/` module tree, each declared dependency | `D/<module>.<ext>` for **every** module in the tree (+ `.d.ts`, + `.mjs` sidecars on commonJS) | nothing | every module compiled and its artifact is on disk | 1 — no project, unresolvable tree, or **any** module failed; nothing stale is left claiming to be current |
| `run [--target T] [--module M] [-- args…]` | what `build` reads | what `build` writes | the target runner on `out/M.<ext>` | the program's own 0 | `build`'s code, or the program's |
| `check [<path>]` | `botopink.json`, `src/` **and** `test/`, dependencies | nothing | `erl` (comptime) | every module type-checks | 1 — at least one diagnostic, each with file, line and excerpt |
| `test [--target T] [--filter S] [--json]` | `botopink.json`, `src/`, `test/`, dependencies | `.botopinkbuild/test-out/**` | the target runner per module with tests | every module compiled **and** every test passed | 1 — a module failed to compile, or a test failed; the surviving modules' tests still ran and are reported |
| `format [files…]` | the files, else `src/` | the files, in place | nothing | every file parsed and is now canonical | 1 — a file could not be read, lexed or parsed |
| `format --check` | as above | nothing | nothing | every file parsed **and** already canonical | 1 — a file would change, or could not be parsed |
| `new <name> [--target T]` | nothing | `<name>/{botopink.json,src/main.bp,.gitignore}` | nothing | scaffolded with a target the compiler supports | 1 — bad name, or a target outside `commonJS\|erlang\|beam\|wasm` |
| `clean` | nothing | deletes `out/` and `.botopinkbuild/` | nothing | both are gone | 1 — a delete failed |
| `migrate [--dry-run]` | the `src/` tree | index files (`root.bp`/`main.bp`/`mod.bp`) — **none** under `--dry-run` | nothing | the tree is covered | 1 — `src/` unreadable |

## Two contract facts that hold at HEAD and are documented nowhere

- **`build` and `test` execute the program they are compiling.** `codegen.generate`
  (`modules/compiler-core/src/codegen.zig:55`-`76`) runs every emitted module through
  `runtime.executeJavaScript` / `executeErlang` / `executeBeamAsm` and stores the stdout on
  `run_output`, which no CLI command reads. Verified: a `botopink build` of a program whose body
  is `print("side effect at build time")` leaves `.botopinkbuild/runtime-cache/<sha>` containing
  `OK:side effect at build time\n`. So a plain `build` spawns `node -e <your program>`
  (measured ~16 ms), or `erlc` + `erl` (~131 ms + ~79 ms), per module, and any side effect your
  program has happens at build time. The execution loop belongs to the snapshot harness, not to the
  driver; `generate` needs an "execute" flag that the CLI leaves off.
- `run` ignores `--out` (`cli/run.zig:42` calls `build_cmd.run` with the default `out`), and
  `clean` deletes the hardcoded `out`/`.botopinkbuild` (`cli/clean.zig:5`), so `build --out dist`
  produces a tree neither command can see.

## Per row: the mechanism

Reproduced against `zig-out/bin/botopink` built from HEAD.

| # | Row | Call path → deciding line at HEAD | Observed | Correct |
|---|---|---|---|---|
| C1 | `build` exits 0 after dropping a module | `main.zig:113` → `cli/build.zig:96` → `codegen.zig:35` → the backend's `codegenEmit`: **`codegen/commonJS.zig:54`-`55`** `.parseError => continue, .typeError => continue`. A dropped module produces no `ModuleOutput`, and `cli/build.zig:110`-`118` inspects only `o.result.comptime_err`, which exists only for a `.validationError` | `src/broken.bp` fails to type-check → `Compiled in 130.93ms`, **exit 0**, `out/` holds `main.js` and no `broken.js`; `botopink check` on the same tree exits 1 with `unbound variable 'noSuchFunction' at broken:2:5` | the driver must fail naming every module that produced no artifact |
| C2 | `build` leaves a stale `out/` that `run` then executes | same; `cli/build.zig:121` `writeOutputs` is simply not reached for the missing module, and nothing removes the previous file | build v1 (`print("stale build v1")`), break the source, rebuild → exit 0, `out/main.js` still v1; `botopink run` → prints `stale build v1`, **exit 0** | with C1 fixed this cannot arise; additionally `build` should not leave an artifact it did not write this run |
| C3 | `test` fail-fast zeroes healthy tests | `cli/test_cmd.zig:149`-`157` returns before the artifact loop at `:161` | 2 passing `src/` tests + 1 broken `test/` module → `1 module(s) failed to compile — run 'botopink check' for diagnostics`, **exit 1**, no `TEST` line printed, and `.botopinkbuild/test-out/` still holds the *previous* run's artifacts | compile what compiles, run those tests, report the failures, exit 1 |
| C4 | **the `test` guard is unsound and can be disarmed** | `cli/test_cmd.zig:149` compares `outputs.items.len` — one entry per module **after** `expandStdImports` (`comptime.zig:1161`) — against `modules.len`, the count **before** expansion. Each `from "std"` module masks one failed module | `src/main.bp` (one `from "std"` import, one passing test) + `src/broken.bp` (does not compile): `botopink test` → `1 passed, 0 failed`, **exit 0**. `botopink check` on the same project → exit 1. With no test blocks at all it prints `no test blocks found` and exits 0 on a project that does not compile | the guard must compare *named* module sets, not counts — and C1's fix makes the count comparison unnecessary |
| C5 | `check` scans `src/` only | `main.zig:117` → `cli/check.zig:23` `sources.load(gpa, io, proj, "src")`; `cli/test_cmd.zig:70`+`:73` loads `src/` **and** `test/` | the project from C3: `botopink test` says "run `botopink check`"; `botopink check` prints `Checked in 88.29ms`, **exit 0** | `check` loads the same set `test` does — one row's fix makes C3's message truthful |
| C6 | lexer errors as a bare `@errorName` | `comptime.zig:449` `const tokens = try lexer.scanAll(arena);` — the error propagates out of `analyzeModule`/`compile`/`generate` and the located `Lexer.lexError` (`lexer.zig:71`) dies with the local. Surfaces at `cli/build.zig:98`, `cli/check.zig:79`, `cli/test_cmd.zig:127` | unterminated string → `error: type-check failed` / `  UnterminatedString`. No file, no line, no excerpt — and on `check` the label is wrong: it is not a type-check failure | a located outcome, rendered like a type error. The renderers already exist: `lexer.zig:782` `lexicalErrorMessage`, `lexer.zig:798` `printLexicalError` |
| C7 | **parse errors lose their location the same way** | `comptime.zig:1168`-`1174` returns the bare tag `.parseError`, discarding `Parser.parseError: ?ParseErrorInfo` (`parser.zig:185`); `cli/check.zig:90`-`93` can therefore print only `error: parse error in {s}` | `error: parse error in main` — no line. `cli/format_cmd.zig:91` renders the same failure properly through `print.zig:153` | give `ComptimeOutput.outcome` a payload-carrying `parseError` and a new `lexError`; **one change closes C6 and C7 across `build`, `check` and `test`** |
| C8 | `migrate <path> --dry-run` writes | `main.zig:141` `const dry = args.len > 2 and std.mem.eql(u8, args[2], "--dry-run");` — the flag is recognised only at `args[2]`. The positional is then discarded entirely: `cli/migrate.zig:29` hardcodes `"src"` | `botopink migrate src --dry-run` → `Created src/main.bp`, `Created src/shapes/mod.bp`; `src/main.bp` really gained two `pub mod` lines. Exit 0 | parse the flag wherever it appears; either accept a root path or reject the positional. `HELP` (`main.zig:48`) documents no positional, so rejecting is defensible |
| C9 | `format --check` passes on unparseable source | `cli/format_cmd.zig:81`-`84` (lex) and `:87`-`97` (parse) both `return false` = "unchanged"; `errors` (`:51`) is incremented only by the `catch` around `formatFile`, which fires on I/O failures alone | unbalanced paren: `botopink format --check` prints **nothing**, exit 0. `botopink format` likewise silently skips the file. On a lex error: `lex error in src/main.bp: UnterminatedString`, still exit 0 | a file that does not lex or parse counts as an error in both modes |
| C10 | `check <path>` ignores its argument | `main.zig:117` `check_cmd.run(gpa, io, env_map)` — the argument list is never forwarded, and `cli/check.zig:9` takes no path | `botopink check /nonexistent/path` type-checks the cwd project and reports *its* error | forward the path, or reject any positional with a usage error |
| C11 | `--target=erlang` silently dropped | `main.zig:158`-`171` `parseBuildOpts` has no `else` arm; identical in `parseRunOpts` (`:175`-`200`), `parseTestOpts` (`:202`-`220`), `parseNewOpts` (`:236`-`254`) | `build --target=erlang --out out-eq` → `out-eq/main.js` (commonJS), exit 0; `build --target erlang --out out-sp` → `out-sp/main.erl`. `build --frobnicate` → exit 0 | every parser gets an `else` that rejects an unrecognised token; support `--flag=value` or reject it explicitly |
| C12 | `new --target frobnicate` accepted | `main.zig:246` `opts.target = args[i]` stores the raw string (the other parsers call `cfg.Target.fromString`, `cli/config.zig:12`); `cli/new.zig:77` writes it verbatim; `cli/config.zig:79` `parsedTarget` does `fromString(...) orelse .commonJS` | scaffolds with `"target": "frobnicate"`, exit 0; a `build` in it emits `out/main.js` | validate in `parseNewOpts`; and `parsedTarget` must reject an unknown manifest target instead of degrading |
| C13 | `clean` reports success on failure | `cli/clean.zig:10`-`13` warns on a failed delete and then prints `Removed <dir>/` anyway; `run` always returns 0 | not reproduced — needs an undeletable `out/`; read from the source | print `Removed` only on success, and exit 1 when a delete fails |
| C14 | `format`/`run` leak their argument list | `main.zig:232` `opts.files = try files.toOwnedSlice(gpa)` and `main.zig:198` `opts.extra_args = try extra.toOwnedSlice(gpa)`; neither `cli/format_cmd.zig:18` nor `cli/run.zig:19` frees it | **not observable at runtime** — the process exits immediately and no allocator reports, so "visible on every successful run" does not hold. The real cost is testability: neither parser can be exercised with `std.testing.allocator`, and `main.zig` has **zero** tests (all 53 CLI unit tests are in `cli/`) | free in the command, or arena-allocate the options |

## The diagnostic exists and is discarded three times

C1, C6 and C7 are one defect seen at three depths, and it is also what makes the comptime-dispatch
front's failure unreadable (`comptime-dispatch` (1.0.2-beta, landed)).

`comptime.zig:76` `ComptimeOutput.outcome` carries the full `TypeError`, but every backend drops it:
`codegen/erlang.zig:317-318`, `codegen/commonJS.zig:54-55`, `codegen/beam_asm.zig:414-415`,
`codegen/wat.zig:160-161` all `continue` on `.parseError` and `.typeError`, so the module produces
no `ModuleOutput` at all. `cli/test_cmd.zig:136-145` can only render a `comptime_err`, which only
the `.validationError` arm ever sets (`codegen/erlang.zig:319-329`); a template failure lands in the
`outputs.items.len < modules.len` arm (`cli/test_cmd.zig:148-156`), whose message points at
`botopink check` — which loads `src` only (`cli/check.zig:23`).

The four `codegenEmit` sites are the backends' files, owned by the backend fronts. The change is
mechanical and identical in all four — emit a `ModuleOutput` that carries the diagnostic instead of
`continue` — so it lands here as one commit, and the backend fronts are told it moved no output.

## One fix, several rows

- **C1 + C2 + C4** are the same defect — a module that fails to compile leaves no trace in
  `codegen.generate`'s result — and are best closed in `codegenEmit` (all four backends:
  `commonJS.zig:54`, `erlang.zig:315`, `beam_asm.zig:414`, `wat.zig:160`) by emitting a
  `ModuleOutput` that carries the diagnostic, so `build`, `test` and any future driver share one
  check.
- **C6 + C7** are one change to `ComptimeOutput.outcome`: a payload-carrying `parseError` plus a
  new `lexError`.
- **C11 + C12** are one flag-parsing pass over `main.zig`.
- **C3 + C5** together make the `test` failure message truthful: compile what compiles and run
  those tests, and have `check` load the same set `test` does.
