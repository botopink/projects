# Front 110 — gate-wasm: the link loop mangles every colliding declaration, and no lowering degrades silently

**Priority:** critical — stage 9's one red cell, and the only class of defect in the compiler that
prints a wrong value at exit 0.
**Depends on:** none. `111` step 4 (the deletion of `expected-failures.txt`) landed with this
front's step 3.
**Owns:** `modules/compiler-core/src/codegen/wat.zig` (the link loop, the refusal path
`Emitter.refuse`, the host-binding refusal) · the wasm snapshots
`modules/compiler-core/snapshots/codegen/<runtime>/wasm/**` (`<runtime>` is `beam` and `wat`; the
runtime-parity audit keeps the pair equal) · `src/codegen/tests/wat.zig` (the backend's fixtures) ·
the `<cell>.wasm.expect` files decision 146 flips · new `tests/language/run/*.bp` and `modules/*`
cells for wasm only. `libs/std/src/testing/asserts.bp` is NOT restructured here (its header comment
alone was corrected): which of its functions wasm may import is the std track's question, § Left.
**Does not touch:** `wat_prelude.zig`, `wat_runtime.zig`, `codegen/wat/**` beyond what a hard error
needs (`../../01-compiler/05-wasm` owns wasm's lowering rows — `Array.unique`, the primitive-method
traps, C-07 twins); `tests/language/run.sh` (111's); `beam_asm.zig`, `erlang.zig`, `commonJS.zig`.

---

## Problem

Two habits, one consequence: a name collision the link loop did not resolve (every colliding
declaration but a `fn` or a `val` was dropped, `wat.zig`'s `else => {}`), and a lowering that could
not resolve a name emitting `i32.const 0` with a `;; note` and going on (18 sites, plus the
catch-all arms of the same shape). Together, a wrong program was indistinguishable from a right one
at the exit code — the failure mode the gate exists to catch, and the one a snapshot cannot (the
wasm snapshot of a stub is the stub). Measured at the open (`par/6.out`): `1244 passed, 1 expected
failures, 1 failed` on `--target all`; `run.sh --target wasm`: `374 passed, 1 expected failures,
1 failed` (`modules/import_same_name_from_two_packages` printed `200\n0\n` for `200\n<p>\n`).

## Current state

- **The link loop** (`wat.zig` `emitWat`): a linked `type` (record or enum), `behavior`, `implement`
  or `extend` block whose name an earlier declaration took is registered as `<module>/<Name>`
  (`link_mangled_types`), the way a `fn` and a `val` already were, and every reference its module
  and its importers write is renamed in a copy of their declarations (`linkTypeRenames`,
  `renameLinkedTypes`: a type in a signature, an annotation or a type argument, a constructor call,
  an `Enum.Variant` read or call, a `case` arm's path, an `extend`/`implement` target). The
  registries stay keyed by that name; the text a value prints under is the bare name again
  (`displayTypeName`); a method call whose receiver inference named by the bare name goes to the
  receiver's own module's method (`ownerAmongTwins`). The `else => {}` arm is gone. Cells:
  `modules/import_same_name_from_two_packages` (`200\n<p>\n`), `modules/import_same_enum_name_from_two_packages`
  (two `Signal` enums with different variants, matched by `case` in each — four targets),
  `modules/type_name_collision` (the method axis).
- **No silent degradation** (`Emitter.refuse(loc, …)` → `error.WasmLoweringRefused` → a located
  `Diagnostic` the driver reports beside `MissingExternal`'s): the 18 sites of the open, the
  `emitC(zero, …)` arms of the same class (a pattern naming no variant, a record with no descriptor,
  a label the record does not declare, a range bound that is not a number literal, a pipeline into
  anything but a named function, a range expression), the `lowerExpr` / comptime catch-alls, the
  `Result`/`Option` op with no lowering and the binary operator with no opcode (it dropped the right
  operand) are refusals. `grep -c "emitCf(zero" wat.zig` = 0; the three `emitC(zero, …)` left are
  the `0` a `null` IS (`?.` on an absent receiver, an absent optional compared or propagated);
  `self.note("` = 0 (`noteF("extra argument {d} ignored")` survives: a checker arity gap, not a
  value — see § Left). An array literal's trailing spread is lowered (`$__arr_concat`); it was the
  one stub a wasm snapshot recorded (`array_prepend_with_identifier`), and
  `run/array_spread_literal` pins the values on commonJS, erlang and wasm.
- **No lowering gap is a run-time trap.** The `unreachable` sites that stood for a shape wasm
  could not lower (26 `emitC`/`emitCf` at the audit, six added by `05-wasm` — `flatMap`,
  `flatten`, `unique`, the untyped lambda parameter — plus `lowerPlainCall`'s "unresolved call"
  and the bodyless-`declare fn` trap) are located refusals: `is` with no descriptor, the
  `unknown` box nothing types, an all-unit enum with no printed form, a comptime-only builtin in
  a program, index/slice on an untyped receiver, an unresolved call, a bodyless `declare fn`
  with no external, a primitive method with no lowering, a higher-order method given a function
  value, `flatMap`/`flatten`/`unique` over unknown shapes, `.next()` without `YieldStep`,
  `pop`/`push` on a receiver that cannot be rebound, a loop over a non-array iterable, an untyped
  lambda parameter (at the lambda), and dispatch by value over an all-unit enum implementer.
  `pop` on a record field is lowered (as `push`'s is). What keeps an `unreachable` is the
  program's own semantics — `assert`, `@panic`/`@todo`, an uncaught `throw`, a rejected
  `#[@future]` — and the dispatcher's end, which the dispatch refusal makes unreachable
  (`grep -c '\.@"unreachable"' wat.zig` = 6, the sixth `refuseUnlessTemplate`'s).
- **A generic body traps only where no execution meets it.** In the one generic body of a
  generic `fn` / method / lambda, a construct a bound type parameter would lower is an
  `unreachable` that marks the body; every unspecialised call into a generic body is recorded
  (plain, associated, record method, fn value, behavior dispatch, `@print` of a generic `type`
  declaring `display`), and the first concrete call that reaches a marked body is refused there —
  `@print(Box(value: 1))` over `Box<T>.display`, `d.display()` on a `Dict<string, i32>`.
  `x is T` over a parameter asks for a specialised copy, so `shown(1)` / `shown("s")` answer.
  A refusal inside another module's code is located at the consumer's import or call.
  Fixtures: `tests/wat.zig` `wat: refusal ---- …` (six) and the three former trap fixtures, by
  `assertWasmRefusedAt` (message + `line:col`); no `tests/language` cell relied on a trap — `run.sh
  --target wasm`: `494 passed, 0 failed` (272/272 wasm cells).
- **The print path** treats a plain call of a function declared to answer an enum as that enum's
  value (`enumReturnedBy`): `@print(stop())` over a linked `fn stop() -> Signal` printed the value's
  address at exit 0 (single-module `@print(Signal.Red)` was already right). A `?Enum` return keeps
  the optional path.
- **ck-host (a), decision 146 — strict on every target.** `collectHostBound`, `host_bound` and
  `MissingExternal.via` are gone from `wat.zig` / `moduleOutput.zig`. Every bodied function is
  emitted (`emitDecl`), so a body that calls a host function with no wasm binding is refused at
  that call by `lowerPlainCall` — the rule lives where it lives on the other three backends, in
  the call's lowering, and prints their diagnostic. The wrapper program
  (`run/external_wrapper_keeps_refusal.bp`), measured on four targets: commonJS
  `` `otpRelease` has no `#[@External.<Target>(…)]` for the node backend `` at `src/main.bp:14:12`;
  wasm the same line "for the wasm backend" at `14:12`; erlang and beam print `up` (they bind it).
  The mirror (`#[@External.Node]` only, wrapped, never called): commonJS runs, erlang, wasm and
  beam refuse it at the call inside the wrapper, each naming its backend.
- **A behavior's associated `default fn` with no type parameter** is queued at registration
  (`registerSymbols`) instead of when a call reaches it, for the same reason
  (`run/external_wrapper_associated_default.bp`: commonJS and wasm refuse, erlang and beam run).
- **A refused module is reported in its own file, and each consumer at its import**
  (`codegenEmit`'s `relocateLinkedRefusals`, `Linked.via`). wasm emits a linked module's
  declarations into the consumer, so the consumer met the same refusal and the driver printed the
  dependency's location against the consumer's file (`--> src/main.bp:101:9`, a line `main.bp`
  does not have). Now: `std/testing/asserts.bp:101:9` for the module, and for the consumer
  `` `canonical` has no `#[@External.<Target>(…)]` for the wasm backend — in `std/testing/asserts`,
  which this import links `` at the import item (`src/main.bp:10:9`).
- **What (a) costs, measured against the lazy rule** (one program per std module,
  `import {<m>} from "std"` and a `main` that prints):
  - three std modules were importable on wasm and are refused now — `testing.asserts`
    (`canonical` ← `deepEquals`; `regexMatches` ← `matches`; `tryCatch` ← `throws` /
    `throwsWith`), `testing.snapshots` (`writeFile`) and `escape` (`lineSeparator`). The other
    twenty-three answer as before: `collections`, `path`, `url`, `string_builder` build; the
    rest were already refused at the import by STD-001 or by a call in a method body;
  - `tests/language`: two cells ran on wasm and are refused there, by `.wasm.expect` at the import —
    `run/std_asserts_on_every_target` and `modules/labelled_call_by_label` (the cell's `"std"`
    call path is `asserts.greaterThan`; its associated, imported and namespace paths lose their
    wasm verdict with it); `run/std_asserts_host_cell_on_wasm` was refused at the call of
    `deepEquals` and is refused at the import; `run/std_decorator_through_namespace` pins the
    import's STD-001 line (`testing.mocks` now names `pushMatcher` first, not `thenReturnCell`);
  - codegen snapshots: none recorded the lazy drop — `zig build test` is green with no fixture
    re-recorded, `scripts/snap_audit.sh --mode=runtime-parity`: 1431 pairs, 0 differing;
  - `botopink build --target wasm` in `libs/std`: exit 1, fifteen modules refused where it was two
    (`querystring`, `testing/mocks`) — `async` (`gateHandle`), `encoding` (`base64Encode`),
    `escape` (`lineSeparator`), `hash` (`pbkdf2Derive`), `io/clock` (`systemTimeWithUnit`), `io/fs`
    (`mkdir`), `io/http` (`fetch`), `io/random` (`float`), `json` (`quote`), `math` (`floor`),
    `querystring` (STD-001 on `std/encoding.percentEncode`), `testing/asserts` (`canonical`),
    `testing/mocks` (`pushMatcher`), `testing/snapshots` (STD-001 on `std/io/fs.exists`),
    `unicode` (`firstCodepointOrZero`). Each is a bodied function calling a host cell with no
    wasm binding; the refusals rule added none (`collections` still builds).
- **Measured after** (this worktree): `zig build test` green from a cold runtime cache;
  `run.sh --target all`: `language tests: 1483 passed, 0 failed` (four targets);
  `--target wasm`: `380 passed, 0 failed`; `--target beam`: `395 passed, 0 failed`.
- **The neighbouring rows did not move.** commonJS still accepts a host function IMPORTED from
  another module with no node binding and dies at run time (`04-js`'s row), and erlang still
  answers "the OTP compiler refused emitted erlang" for the mirror (`02-erlang`'s row): this
  front changed `wat.zig` and `moduleOutput.zig` only.

## Steps

### Step 1 — the link loop mangles every colliding declaration — done

- [x] `bash tests/language/run.sh --target wasm --only modules/import_same_name_from_two_packages` → `passed`, stdout `200\n<p>\n`
- [x] `modules/import_same_enum_name_from_two_packages` — two linked packages declaring the same `enum` name with different variants, matched by `case` in each — passes on commonJS, erlang, wasm and beam
- [x] `else => {}` is gone from the link loop (`sed -n 630,760p wat.zig | grep -c "else => {}"` = 0)

### Step 2 — every silent-degradation site is a hard error — done

- [x] `grep -c "emitCf(zero" wat.zig` = 0; the `;; note` survivors and the three `emitC(zero, …)` are listed above with their reason
- [x] step 2a measured at the open: 1 wasm snapshot hit a stub (`array_prepend_with_identifier`, `;; note: array spread not lowered`); the three `std_package_*` matches were source comments. Re-recorded: the four `array_prepend_*` fixtures (both runtimes), whose text now calls `$__arr_concat` — the value is `run/array_spread_literal`'s (`4 1 4 3 40 0`, run on wasm); their `RUN LOG` is empty (no `main`)
- [x] `wat: unknown ---- a field read on a type parameter's slot is refused` (`tests/wat.zig`, `.refused_on_wasm`): the wasm snapshot records the diagnostic where `v.length` used to be `i32.const 0`; commonJS, erlang and beam record `3`. The sibling trap test keeps its literal arm
- [x] `scripts/snap_audit.sh --mode=runtime-parity` green; `zig build test` green
- [x] `tests/language/run.sh --target wasm` → `0 failed`
- [x] every lowering that cannot proceed is a located refusal: `grep -c '\.@"unreachable"' wat.zig`
  = 6 (assert, `@panic`/`@todo`, uncaught `throw`, rejected `#[@future]`, the dispatcher's end,
  `refuseUnlessTemplate`); each refusal has a `tests/wat.zig` fixture; `run.sh --target wasm` →
  `494 passed, 0 failed`

### Step 3 — ck-host (a), decision 146: wasm refuses a function that reaches a host cell, called or not — done

- [x] `bash tests/language/run.sh --target wasm --only run/external_wrapper_keeps_refusal.bp` → `passed` (the cell's `.wasm.expect` is the refusal, `14:12`)
- [x] `expected-failures.txt` had no live line left and is deleted (111 step 4); `run.sh --target all` prints `language tests: 1483 passed, 0 failed`
- [ ] `botopink build --target wasm` in `libs/std` → exit 0 — **not reachable under (a) as std stands**: exit 1, fifteen modules refused (§ Current state). It closes when every std module either has a wasm lowering for its host cells or is out of a wasm build; neither is this front's (§ Left)

## Left

- **`@print` of a value whose static type nothing names** reaches `$__display_of` unrecorded:
  when that dispatch lands in a marked generic `display`, it still traps inside it. The proper
  lowering — a print of a generic `type` calling the specialised `display` — is
  `../../01-compiler/05-wasm`'s (monomorphisation), as is `d.display()` / `@print(d)` on a
  `Dict<string, i32>`, refused now.
- **What closing `libs/std` on wasm takes, per module** (measured; not contained in `wat.zig`
  and std without a new mechanism): the wasm backend reads `@External.Wasm` nowhere, so no host
  cell can be bound. With a template reader (`05-wasm`): `math` (`floor` & co. are `f64`
  opcodes), `unicode`, `json`, `escape`, `encoding` (→ `querystring`), `hash` as prelude helpers
  or pure-bp bodies; `io/clock`, `io/random`, `io/fs` (→ `testing/snapshots`) need WASI imports
  (`clock_time_get`, `random_get`, `path_open`); `io/http`, `async` (gates are processes),
  `testing/mocks` (process state) and `testing/asserts` (decision 146's choice) are the std
  track's to place out of a wasm build or restructure.
- **std on wasm under decision 146** — for the maintainer, `02-std-and-packaging`:
  `testing.asserts`, `testing.snapshots` and `escape` are no longer importable on wasm, and
  `libs/std` does not build there. For `asserts` the choice is (1) it stays unimportable on wasm;
  (2) `matches`, `throws`, `throwsWith` (and `deepEquals` while `canonical` has no wasm lowering)
  move to a module of their own, so the pure assertions import on wasm — an API change of
  `asserts-api.md` (decision 74); (3) the three cells gain wasm lowerings — `canonical` can (a
  structural stringify over the value's descriptor, the print path's), `regexMatches` cannot
  without a regex engine in the wasm prelude, `tryCatch` cannot while `@panic` is `unreachable`
  on wasm, and the wasm backend reads `@External.Wasm` nowhere yet (`../../01-compiler/05-wasm`).
- **A generic behavior's associated `default fn` is still lowered only when a call reaches it**
  (`behavior Probe<A> { default fn f(x: A) -> string { return otpRelease(); } }`, never called:
  commonJS refuses, wasm prints `up`). Queueing those too emits the primitive behaviors'
  (`Array.range`, `Array.repeat`, `Pair.of`, …) into every module that carries the behavior —
  measured: 14 wasm fixtures change (both runtimes) and a two-line `flatMap` program's `.wat`
  goes from 12 to 17 functions. `../../01-compiler/05-wasm`'s to weigh.
- `modules/labelled_call_by_label` has no wasm verdict for its labelled-call paths while its
  `"std"` path is `testing.asserts`; a std function that builds on wasm in that position gives it
  back (`111` / `01-checker`'s cell).
- `noteF("extra argument {d} ignored")` / `"missing argument"` in `lowerPlainCall`: an arity the
  checker did not refuse reaches codegen; the honest shape is a checker refusal
  (`../../01-compiler/01-checker`), and until then wasm pads or drops arguments where the other
  backends do the same.
- beam drops an array literal's trailing spread (`run/array_spread_literal` prints `2 1 null 1
  null 0` on beam) — `beam_asm.zig`, `../../01-compiler/03-beam` / 111 (beam joins `--target
  all` there).
- `..<call>()` in an array literal is a parse error (`list-spread-not-last`): the parser reads
  `..` + identifier as the spread name and refuses the `(` after it — `../../01-compiler/01-checker`'s
  parser rows.
- `modules/import_same_name_from_two_packages/botopink.json` declares `"targets": ["commonJS",
  "erlang"]` and `modules/type_name_collision` likewise; both pass on wasm now — 111 step 5 (gate-d)
  deletes the narrowing.

## Blast radius

- wasm snapshots: 4 fixtures re-recorded (both runtimes), 1 added (both runtimes, four backends)
  by steps 1–2; step 3 moved none.
- `../../01-compiler/05-wasm` starts from this landing: a missing lowering is a refusal rather than
  a `0`; 05's fixtures may move from "prints wrong" to "refused" — the intended direction. A
  `@External.Wasm` template reader is the prerequisite of any std wasm binding.
- `../../02-std-and-packaging`: three std modules stopped importing on wasm (§ Current state);
  `asserts.bp` changed in its header comment only, so `97-std-dedupe` has nothing to rebase over.
- A library that builds for wasm and imports `escape`, `testing.asserts` or `testing.snapshots`
  is refused at that import; no gate stage builds a sibling library for wasm.

## Notes

- A `;; note` in the emitted `.wat` is a comment; the rule is about what the emitter *does* after
  writing it. A note that documents a correct lowering may stay; none documents a `0` any more.
- The compiler knows no library: the strict rule names no module, and which std functions sit on
  a host cell is std's to arrange.
