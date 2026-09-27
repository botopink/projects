# Front 110 — gate-wasm: the link loop mangles every colliding declaration, and no lowering degrades silently

**Priority:** critical — stage 9's one red cell, and the only class of defect in the compiler that
prints a wrong value at exit 0.
**Depends on:** none to start; `112` reformats `libs/std/src/testing/asserts.bp` — this front
rebases its restructure over that commit. `111` starts from this front's landing.
**Owns:** `modules/compiler-core/src/codegen/wat.zig` (the link loop, the refusal path
`Emitter.refuse`, `collectHostBound`) · the wasm snapshots
`modules/compiler-core/snapshots/codegen/<runtime>/wasm/**` (`<runtime>` is `beam` and `wat`; the
runtime-parity audit keeps the pair equal) · `src/codegen/tests/wat.zig` (the backend's fixtures) ·
`libs/std/src/testing/asserts.bp` (the ck-host restructure, gate-b) · the single `wasm |` line of
`tests/language/expected-failures.txt` (`:243` — the file is 111's; this front's only edit to it is
deleting that line, and 111 starts from the result) · new `tests/language/run/*.bp` and
`modules/*` cells for wasm only.
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
- **The print path** treats a plain call of a function declared to answer an enum as that enum's
  value (`enumReturnedBy`): `@print(stop())` over a linked `fn stop() -> Signal` printed the value's
  address at exit 0 (single-module `@print(Signal.Red)` was already right). A `?Enum` return keeps
  the optional path.
- **Measured after** (this worktree, sibling libraries at their `feat` tips): `zig build test` green;
  `scripts/snap_audit.sh --mode=runtime-parity`: 1431 pairs, 0 differing; `run.sh --target wasm`:
  `377 passed, 1 expected failures, 0 failed` (the 2 new cells included).
- **ck-host** (gate-b) — measured, not closed: `libs/std/src/testing/asserts.bp` has THREE host
  cells with Node and Erlang templates only — `canonical` (`deepEquals`), `regexMatches`
  (`matches`), `tryCatch` (`throws`, `throwsWith`, `:286-288`). The strict rule (a) refuses a
  function whose body reaches a cell with no wasm binding where it is declared, so under (a) the
  module does not build on wasm until all three have a wasm lowering: `canonical` can have one (a
  structural stringify over the value's descriptor, the print path's); `regexMatches` (no regex
  engine on wasm) and `tryCatch` (`@panic` is `unreachable` on wasm — there is nothing to catch)
  cannot. Two language cells pin today's lazy rule on wasm: `run/std_asserts_on_every_target`
  (the import builds) and `run/std_asserts_host_cell_on_wasm` (the call is refused, `.wasm.expect`).
  `libs/std` `botopink build --target wasm` is red today for two reasons outside `asserts`:
  `querystring` (`std-unsupported-on-target: std/encoding.percentEncode`) and `testing/mocks`
  (`thenReturnCell` called in a method body, refused) — `02-std-and-packaging`'s. The wasm backend
  reads `@External.Wasm` nowhere (`docs.md` § host bindings: "nothing declares one today"), so a
  wasm binding for `canonical` is a compiler feature (`../../01-compiler/05-wasm`) before it is a
  std template.

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

### Step 3 — ck-host (a): `collectHostBound` strict, `asserts` restructured — blocked on ck-host

The measurement above is what ck-host must decide with. (a) as recommended is not "one std
restructuring": `matches`, `throws` and `throwsWith` have no possible wasm lowering, so (a) means
either the `asserts` module does not build on wasm at all (every wasm program importing it is
refused; `run/std_asserts_on_every_target` and `run/std_asserts_host_cell_on_wasm` flip to
refusals at the import) or the three functions leave `asserts` for a module of their own — an API
change of `asserts-api.md` (decision 74) the std track owns, not this front. (c) — strict for the
root package, lazy for a dependency's functions — closes `run/external_wrapper_keeps_refusal`
(the wrapper is the root's) and keeps `asserts` importable; (b) keeps today's behaviour and rewrites
`docs.md` § host bindings. Until the maintainer answers, `collectHostBound` is unchanged and
`expected-failures.txt:243` stays.

- [ ] `bash tests/language/run.sh --target wasm --only run/external_wrapper_keeps_refusal.bp` → `passed` (the cell's `.expect` is the refusal)
- [ ] `botopink build --target wasm` in `libs/std` → exit 0 (needs `querystring` and `testing/mocks` first — `02-std-and-packaging`)
- [ ] `expected-failures.txt` has no `wasm |` line; `run.sh --target all` prints `0 expected` for wasm

## Left

- ck-host, as above; then the `asserts` restructure the answer implies and the line's deletion.
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

- wasm snapshots: 4 fixtures re-recorded (both runtimes), 1 added (both runtimes, four backends).
- `../../01-compiler/05-wasm` starts from this landing: a missing lowering is a refusal rather than
  a `0`; 05's fixtures may move from "prints wrong" to "refused" — the intended direction. A
  `@External.Wasm` template reader is the prerequisite of any std wasm binding (ck-host (a)).
- `../../02-std-and-packaging/97-std-dedupe` rebases over `asserts.bp` only if ck-host lands a
  restructure.
- `111` deletes what is left of `expected-failures.txt` after ck-host removes this front's line.

## Notes

- A `;; note` in the emitted `.wat` is a comment; the rule is about what the emitter *does* after
  writing it. A note that documents a correct lowering may stay; none documents a `0` any more.
- The compiler knows no library: `asserts.bp` is std, and the restructure is a std change this
  front owns only because the ck-host line cannot close without it.
