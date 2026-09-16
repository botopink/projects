# Spec 08 — Module health

**Version:** 1.0.2-beta
**Priority:** critical — four of six libraries cannot compile, and three CLI commands report success on failure
**Depends on:** spec 01 (the comptime dispatch fix is the shared cause of the library breakage)

---

## Objective

Every library in the workspace compiles and its tests run; a CLI command's exit code matches what
it actually did; and the gate exercises the libraries, so this class of breakage cannot hide again.

Paths are relative to `repository/botopink-lang/` unless they start with a sibling repo name.

## Current state

Measured against a compiler built from HEAD (the checked-in `zig-out/bin/botopink` was stale — it
predated half the 1.0.1-beta waves, which is itself worth knowing when diagnosing).

| Module | `check` | `test` | Note |
|---|---|---|---|
| emilia | pass | **17/17** | was dead (source carried markdown escapes, `#\[@External\.node(`); fixed |
| erika | fail | fail | 13 template tests dead (L1); 16/18 of the fluent layer passes with them removed |
| jhonstart | pass | fail | 8/8 pass once the module compiles (verified by running the emitted JS) |
| onze | pass | fail | 8/8 pass once the module compiles |
| rakun | **fail** | fail | fails before compiling: declares a dependency that exists nowhere (L2) |
| vscode-extension | — | **15/15** | in sync with the server; its drift is cosmetic and predates the waves |
| `libs/std` | fail | fail | does not compile; 1147 lines in 3 modules have never compiled |

**No failure is a regression of the 1.0.1-beta waves** — each reproduces byte-identically on the
compiler built from the commit the milestone started at. (One real wave regression was found and
already fixed: the wasm backend folded an unlowerable call into a constant, so a program compiled,
loaded and did nothing with exit 0.)

---

## Steps

### Step 1 — Primitive methods in a comptime body (L1)

A comptime module carries `__bp_add/2`, `__bp_len/2`, `__bp_text/1`, `__bp_json/1`
(`codegen/erlang.zig:389-475`) and the host glue, and nothing else. A primitive method call in an
untyped body falls through `codegen/erlang.zig:3545` (`instance_lowerings` — empty by construction
at `:494`), `:3565`, `:3569`, `:3570` to **`:3571`, a bare local call `m(Recv, args)`**.
Mechanism, fix options and the recommendation are in **spec 01**; this step is the library-side
measurement and the corrections it forces.

Three claims in the earlier text are wrong:

- **"only `.length` resolves"** — `.length` resolves only as a *field* access, through
  `codegen/erlang.zig:3052-3056` → `'__bp_len'/2`. As a *call*, `s.length()` emits the
  auto-imported BIF `length/1`, which lints clean and raises `badarg` on a binary. Meanwhile
  `forEach`, `fold`, `take`, `drop` and `toList` already resolve correctly through
  `arrayPrimFallbackNode` (`codegen/erlang.zig:3904`), which is reached in untyped mode — that is
  why `decl.methods.forEach({ … })` works in every decorator today.
- **A subset of the failures never reach `erl_lint`.** Any method whose name/arity collides with an
  auto-imported BIF (`length/1`, `abs/1`, `round/1`, `floor/1`, `ceil/1`, `float/1`, `size/1`)
  compiles and then misbehaves at evaluation time. These appear in no `{undefined_function,…}`
  list.
- **"erika, 26 of its 35 lint errors"** — the real figures are 36 total / **27** `undefined_function`.
  `botopink check` truncates `erl_lint` detail at 4096 bytes (`comptime/template_eval.zig:76`,
  applied at `:117-118`; `comptime/decorator_eval.zig:56`, `:95-96`), clipping the last error.

Measured by re-linting each repo's generated modules under
`.botopinkbuild/tmp/{template,decorator}/`:

| Library | Host | Body | Methods used | Lint errors | Residual after the fix |
|---|---|---|---|---|---|
| erika | template | `src/erika.bp:356-591` | `append`×12, `join`×5, `split`×4, `map`×4, `slice`×2 | 36 / **27** undefined | **9** `unbound_var`/`unsafe_var` (`OpTok@2`, `LTok@2`, `RTok@2`, `Toks@3` at `:131`, `:134`, `:359`) |
| jhonstart | template | `src/html.bp:86-259` | `slice`×29, `append`×21, `join`×14, `split`×10, `trim`×6, `indexOf`×2 | 87 / **82** undefined | **5** `unbound_var` |
| onze | decorator | `src/onze.bp:153-186` | `push`×2, `join`×2, `startsWith`×1 | 5 / **5** undefined | **0** |
| rakun | decorator | `src/decorators.bp:46-227` (6 bodies) | `join`×16, `push`×6 | **22** predicted | `push` is a mutation — step 2 |
| emilia | — | none | — | 0 | unaffected |

136 bare-call errors in total, plus 14 residual scoping errors from a separate case-arm
variable-rebinding defect. **Only onze is fully unblocked by step 1** — erika and jhonstart still
will not compile afterwards. `repository/erika/examples/erika-linq` reproduces erika's 36/27 from 6
`erika "…"` sites in `src/main.bp`.

Two structural facts:

- **`check` is green while `test` is red** for jhonstart and onze: a template/decorator lowers only
  at a *call site*, and `cli/check.zig:23` loads `src/` only. A CI gate on `check` alone misses the
  entire class.
- `contains`, `at`, `reverse` and `toUpper` appear in no library comptime body — latent, not
  observed.

**Spec 01 must widen with this**: its acceptance named templates and `template_eval.zig` only,
while onze and rakun fail through `decorator_eval.zig`, and `push` is a *mutation*, not a read-only
call.

**Acceptance:**
- [ ] A template body and a decorator body may call any primitive method the typed path supports
- [ ] A method whose name collides with an auto-imported BIF dispatches on the receiver instead of
      calling the BIF
- [ ] onze compiles and runs its test suite; erika and jhonstart are down to their residual
      `unbound_var` errors only
- [ ] A compiler-core regression test covers both hosts, so it does not depend on a sibling checkout

### Step 2 — Mutation through a method inside a closure (L3)

`args.push(x)` inside a closure is emitted as a *discarded* expression, while an outer-`var`
assignment in the same position threads out through `lists:foldl`. Even with `push/2` defined,
rakun's constructor injection builds an empty argument list — step 1 alone does not unblock it.

**The two fold paths, and why `push` misses both.**

| Path | Entry | What it matches | `push`? |
|---|---|---|---|
| Fold fusion (peephole) | `detectFoldFusion` `codegen/erlang.zig:2424`, from `bodyNode:2403` | `var acc = init;` immediately followed by `recv.forEach({ p -> … })` | `classifyFoldStmt` (`:75`) **does** recognise `push` at `:91-101` and lowers it via `foldBodyExpr:2500` to `Acc ++ [X]` — but `:2464` requires the closure body to be **exactly one statement**, `:2445` requires the callee to be `forEach` (never `loop`), and `identName` (`:128`) requires a bare identifier receiver |
| Mutation threading (general) | `mutatingExpr` `codegen/erlang.zig:2531`, from `bodyNode:2412` | any closure/branch/loop that assigns to an outer local | `collectMutations` (`:2592`) counts **only** `.binding.assign` with a `.name` target (`:2595-2605`). `args.push(x)` is a `.call`, so `:2613` merely recurses into nested `forEach` bodies and the receiver is never marked. With no names, `:2556` returns null and the whole `forEach` degrades to a discarded `lists:foreach` |

The accumulator is a tuple of the mutated names (`varGroupExpr:2632`, version-bumped by
`bindVarGroupExpr:2643`), threaded by `mutatingFoldExpr:2734` and closed by `armWithGroup:2690`.

**What the fold needs to thread a receiver mutation out — two changes, not one.**

1. **Analysis.** `collectMutations` (`:2592`) needs a `.call` arm that, for a statement-position
   call whose callee is a known mutating method, takes `identName(cc.receiver.*)` (`:128`) and
   appends it under the same three guards as the assign arm (`this.locals.contains(n)`,
   not shadowed, not already collected). The `.branch` recursion and `mutatingIfExpr`'s name
   collection (`:2538-2539`) need the same.
2. **Rewrite — required; marking the name is not enough.** `armWithGroup` (`:2690`) appends
   `varGroupExpr(names)` (`:2695`) at whatever `var_current` versions the body left behind. Since
   `args.push(x)` lowers through `stmtExpr` (`:2872`) → `callNode` (`:3323`) to a bare
   `(Args ++ [X])` that binds nothing, `var_current["args"]` is never bumped, the group-out
   expression is the same `Args` the fun received, and `lists:foldl` faithfully returns the initial
   value. The statement must be lowered as a rebinding — `Args@1 = (Args ++ [X])` — the way
   `bindExpr` (`:2060`, version allocation at `:2083-2085`) does for `.assign`. After that the
   existing tuple/versioning machinery works unchanged.

**Scope and soundness.**

- Sound only when the receiver is a local `var` (`this.locals.contains(n)` plus the `.localBind`
  `mutable` bit read at `:2435`). A `push` onto a parameter or a field-access receiver
  (`identName` returns null) must keep today's behaviour or be diagnosed.
- The same dead store exists at **function-body** level, not only inside closures:
  `var out = []; out.push(1); return out;` has the identical shape.
- **Backends:** erlang and beam_asm are broken; commonJS is correct by accident (JS arrays mutate
  in place — `commonJS.zig` has no `push` handling at all); wat does not implement array iteration.
  `beam_asm.zig` has no `collectMutations`, no `mutatingExpr` and no fusion — `emitLoop:4169`
  always picks `map`/`foreach`, and `primAppendElem:2754` computes `lists:append/2` into `x0` and
  drops it. Either fix it in parallel or scope beam out explicitly.
- **There is no notion of a mutating method anywhere in the compiler.** No marker in `ast.zig`,
  `infer.zig` or any backend; the only mutability bit is `mutable: bool` on bindings
  (`ast.zig:540`, `:555`). The concept exists solely as the hardcoded string `"push"` at
  `codegen/erlang.zig:93` and `codegen/beam_asm.zig:2573`. And `push` is declared
  **without a return type** — `libs/std/src/primitives.bp:564-566`,
  `fn push(self: Self, item: T)` — so there is semantically nothing to bind either. The principled
  version of this fix gives `push` `-> Self` and/or introduces a real receiver-mutation marker, so
  the analysis becomes declaration-driven instead of name-driven.
- `libs/std` already documents this as a trap and routes around it by hand:
  `libs/std/src/path.bp:19-21`, `:91`, `:148`; `libs/std/src/base64.bp:44`. `primitives.bp` itself
  still contains the broken shape — `Array.append:695` and `Array.prepend:702` both write
  `other.forEach({ y -> out.push(y); })` and are saved only by their `@External.Erlang` overrides
  (`:691`, `:699`) bypassing the body.

**The fixture.** The bug is already golden-committed:
`codegen/tests/features.zig:694` `test "js: iterator fromList yields array items"` (source at
`:711`, `out.push(item)` inside `loop (iter) { item -> … }`) and
`snapshots/codegen/erlang/iterator_fromlist_yields_array_items.snap.md:34-39`, whose run log at
`:51-54` is `<<>>` where commonJS gives `1,2,3`. The fix flips that run log; the beam copy likewise.
No fixture covers the multi-statement-closure shape rakun actually uses (the one `:2464` rejects) —
add one in `codegen/tests/features.zig` (4 snapshot files, one per backend directory) plus a
substring test next to `codegen/tests/comptime_module.zig:72`, since rakun goes through
`emitComptimeModule`, not the ordinary codegen path.

**rakun's site.** `repository/rakun/src/decorators.bp:46-58` (`component`; repeated verbatim in
`service:63`, `repository:80`, `cargs:114`, `rargs:139`, `gargs:172` — decorator bodies cannot call
sibling fns, `:42-45`): `args.push(f.name + ": " + expr)` inside a 4-statement `decl.fields.forEach`
closure, consumed at `:59` by `args.join(", ")`. It fails twice over — `:2464` rejects the
multi-statement closure, and `collectMutations` never marks `args`. Note the *inner*
`f.annotations.forEach({ a -> … valKey = … })` at `:51` **is** a `.binding.assign` and threads
correctly, so the inner mutation survives while the outer `push` silently vanishes.

**Acceptance:**
- [ ] A method that mutates its receiver inside a closure threads the value out, like assignment
      does, on erlang — and on beam, or beam is explicitly scoped out here
- [ ] The same holds in straight-line function-body position, not only inside a closure
- [ ] `snapshots/codegen/erlang/iterator_fromlist_yields_array_items.snap.md` run log matches
      commonJS's
- [ ] A new fixture covers a multi-statement closure that pushes, on all four backends
- [ ] rakun's decorators produce the arguments they collect

### Step 3 — Trailing default parameters at the call site (L4)

`pub fn h1(children: Children, attrs: Array<#(string,string)> = [])` cannot be called `h1(x)`:
`'h1' expects 2 argument(s), got 1`.

**The earlier diagnosis was wrong in one place: record methods do not expand their defaults
either.** Nothing in the compiler expands a default for a method. The asymmetry is that inference
*does not arity-check instance method calls* — `methodCallReturnType` (`comptime/infer.zig:6118`)
unifies arguments only when the arity already matches (`:6144-6149`) and the unknown-method
fallback (`:7105-7114`) types the call as a fresh var. So a short method call type-checks, no
default is filled, and codegen emits the short call: `undefined` on commonJS (`commonJS.zig:1675-1686`
`buildParam` drops `p.default`, so the emitted signature has no fallback either), a missing map key
or arity error on erlang. Where a method *is* checked, it reds exactly like a free fn —
`s.slice(2)` against `libs/std/src/primitives.bp:165` fails at `comptime/infer.zig:6509-6514`,
pinned by `codegen/tests/wat.zig:86-94` and
`snapshots/codegen/commonJS/string_slice_without_end_arg_slices_to_source_length.snap.md`.

**What is complete.** The parser. One `Param.default: ?Expr` slot (`ast.zig:1018-1042`), filled by
one function for every param list — free fns, record/struct methods, interface methods, `implement`
methods, delegates all funnel through `parseParam` (`parser/decls.zig:1348-1352`); the trailing-only
rule is enforced at parse time (`parser/decls.zig:71-85`). Record constructor fields
(`parser/decls.zig:810-815`) and enum-variant fields (`:1172-1178`) use the same slot
(`ast.zig:1821-1832`, `:1387-1392`). `parser/tests/declarations.zig:726-733` documents the slot and
names the gap as call-site auto-injection; its tests (`:735`–`:774`, `:882-902`) are parse-only.

**What is complete but unreachable.** The splice.
`expandTrailingDefaultsWithParams` (`comptime/transform.zig:834-866`) returns early if
`args.len >= params.len` (`:842`), bails if any missing trailing param lacks a default (`:846-849`),
and otherwise appends
`.{ .label = null, .value = &params[i].default.?, .is_default_inj = true }` (`:852-865`) — the
`ast.CallArgOf.is_default_inj` flag (`ast.zig:255-276`) exists solely for this. It is wired into
`rewriteCall` (`:872-903`) for free/stdlib fns via `fn_decls` (`:873`, `:903`) and for
record/struct/enum-variant constructors via `agg.ctor_params` (`:879-890`, fed from `env.ctorParams`,
`comptime/env.zig:545-551`, populated at `comptime/infer.zig:975`, `:1196`, `:1274-1276`).

It is unreachable because it runs **after** inference and inference fails first:
`comptime.zig:355-362` returns `.typeError` on `inferProgramTyped`, and only on success does
`comptime.zig:1450-1453` call `transform.transform`. Two shapes do reach it, because they skip the
arity check: builtin `@fn()` calls (`comptime/infer.zig:6881-6897`) and qualified
`Enum.Variant(args)` (`:7013-7020`).

**The arity checks that reject.**

| # | Site | Callee kind | Accounts for defaults |
|---|---|---|---|
| 1 | `comptime/infer.zig:7151-7155` | free fn **and record/struct constructor** (both are `.func` bindings), no spread — `f.params.len != call.args.len` | no — **this is what rejects `h1(x)`** |
| 2–4 | `:7204-7208`, `:7216-7219`, `:7226-7229` | same, spread paths | no |
| 5 | `:6509-6514` | interface `default fn` on a primitive receiver (`resolveStdArrayMethod`) — rejects `s.slice(2)` | no |
| 6 | `:1113-1118` | interface associated fn (`Pair.of`) | no |
| 7 | `:6952-6956` | `"std"`-package qualified call | no |
| 8 | `comptime/unify.zig:74-77` | fn-type ↔ fn-type unification (passing `h1` as a value) | no |
| 9 | `:2205-2213` | annotation / decorator application | **yes — the only correct one**: `required = count(params where default == null)`, accepts `required ≤ args ≤ params.len` |

Message: `TypeError.arityMismatch` (`comptime/error.zig:193-194`), rendered at `:295`. The
diagnostic codes already exist and describe the intended order —
`comptime/diagnostics.zig:187-219`, where D3 `fn-param-default-arity-mismatch` is documented to fire
"after `expandTrailingDefaults` could not fill every missing arg". That ordering is precisely what
is missing.

**Record constructors are the same defect, not a separate one.** A record ctor is an ordinary
`.func` binding (`comptime/infer.zig:960-969`), so `Config(host: "x")` takes the free-fn path and
dies at check #1; args are zipped positionally at `:7161-7167` with the label ignored. The
transform's ctor branch (`transform.zig:888-890`) is therefore dead for records for the same reason.

**This is a checker fix**, not a parser or transform fix.

1. Relax check #1 (and #2–#4, #5, and for parity #6/#7) to the rule already implemented at
   `comptime/infer.zig:2205-2213`: `required ≤ args ≤ params.len`.
2. `required` is not derivable from `T.func` — the type carries no defaults. Inference needs a
   `name → []ast.Param` side table for fns, mirroring `env.stdlibFnDecls` (`comptime/env.zig:539-544`).
   **Constructors need no new table**: `env.ctorParams` (`:545-551`) is already keyed by the name
   `:7117` looks up.
3. When `args.len < params.len`, the unification loop at `:7161-7182` must stop at `args.len`; the
   omitted slots are typed by the default expression, checked at decl registration.
4. Leave `transform.zig` untouched.

**What the call site looks like afterwards:** exactly what the transform already produces — the
`call` node's `args` slice grows to `params.len`, with each injected entry
`.{ .label = null, .value = &decl.params[i].default.?, .is_default_inj = true }`
(`transform.zig:858-863`). **No codegen change is needed**, confirmed in all four backends:
commonJS maps `cc.args` blindly (`commonJS.zig:2636-2637`, `:2773-2774`, `:1920`), erlang the same
for plain calls (`erlang.zig:1756`) and by label/position for record ctors (`erlang.zig:3455-3461`),
wat walks them positionally (`wat.zig:2400-2411`), typescript emits declarations only. No backend
emits a parameter default in the *declaration*, so call-site injection is the only lowering that
can work at all — an "emit `= default` in the JS signature" fix is impossible for erlang.

One caveat: injected args are positional and appended at the tail, while user args may be named
(`h1(x, attrs: [])`). Since inference zips positionally (`:7161`) and the parser forbids
positional-after-named (`parser/exprs.zig:1488-1491`), tail-appending is sound for "omit the
trailing defaults". Allowing a *middle* named param to be skipped would additionally need
name-matched injection in `expandTrailingDefaultsWithParams` and label-aware unification.

**Impact.** `repository/jhonstart/src/element.bp` carries **24** occurrences of `attrs: []`, of
which 22 are pure arity padding at call sites (2 are genuine forwarding, `:15`, `:19`); 29 repo-wide
across `element.bp`, `hooks.bp`, `html.bp`. The declarations that should make them unnecessary are
`element.bp:14`, `:18`, `:22-27`. `element.bp:59` pads four times in one expression. The same file
shows the constructor half: `Element` (`:3-8`) declares no field defaults because adding one would
hit check #1.

**Acceptance:**
- [ ] A free fn accepts a call that omits trailing defaults, and the injected arg reaches codegen
      through `transform.zig` unchanged
- [ ] A record constructor accepts a call that omits a defaulted field
- [ ] An instance method with a trailing default expands it too — today it neither errors nor
      expands, which is worse than either
- [ ] A genuinely missing *required* argument still reds, as D3 (`comptime/diagnostics.zig:202-219`)
- [ ] `jhonstart`'s examples and its documented API compile; `element.bp`'s 22 padding `attrs: []`
      can be deleted

### Step 4 — A CLI command must not report success on failure (L5)

Several of these exist because the contract was never stated. Write it down first: the rest of
the step is making the code match it.

#### The contract

What each command promises. This is the target, not a description of HEAD — every row below it
is a place the code departs from it.

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

Two contract facts that hold at HEAD and are documented nowhere:

- **`build` and `test` execute the program they are compiling.** `codegen.generate`
  (`modules/compiler-core/src/codegen.zig:55`-`76`) runs every emitted module through
  `runtime.executeJavaScript` / `executeErlang` / `executeBeamAsm` and stores the stdout on
  `run_output`, which no CLI command reads. Verified: a `botopink build` of a program whose body
  is `print("side effect at build time")` leaves
  `.botopinkbuild/runtime-cache/<sha>` containing `OK:side effect at build time\n`. So a plain
  `build` spawns `node -e <your program>` (measured ~16 ms), or `erlc` + `erl` (~131 ms + ~79 ms),
  per module, and any side effect your program has happens at build time. The execution loop
  belongs to the snapshot harness, not to the driver; `generate` needs an "execute" flag that the
  CLI leaves off.
- `run` ignores `--out` (`cli/run.zig:42` calls `build_cmd.run` with the default `out`), and
  `clean` deletes the hardcoded `out`/`.botopinkbuild` (`cli/clean.zig:5`), so
  `build --out dist` produces a tree neither command can see.

#### Per row: the mechanism

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

**One fix, several rows.** C1+C2+C4 are the same defect — a module that fails to compile leaves
no trace in `codegen.generate`'s result — and are best closed in `codegenEmit` (all four
backends: `commonJS.zig:54`, `erlang.zig:315`, `beam_asm.zig:414`, `wat.zig:160`) by emitting a
`ModuleOutput` that carries the diagnostic, so `build`, `test` and any future driver share one
check. C6+C7 are one change to `ComptimeOutput.outcome`. C11+C12 are one flag-parsing pass over
`main.zig`.

**Acceptance:**
- [ ] The contract table above is in `modules/compiler-cli/AGENTS.md`, per command
- [ ] Every row C1–C14 has a test that reds before the fix: a `main.zig` unit test for
      C10–C12/C14, and a script under `modules/compiler-cli/tests/` wired to a build step
      (step 5) for the rows that need a real project
- [ ] `botopink build`, `check` and `test` agree: on the same tree, either all three exit 0 or
      all three exit 1
- [ ] No command executes the program it is compiling unless asked to

### Step 5 — The gate must cover what ships (L6)

#### What each build step actually runs

`build.zig` declares seven named steps plus the default `install`. `test` is the only one
anything depends on.

| Step | What it runs | In `zig build test` | In CI | State |
|---|---|---|---|---|
| `test` | `core_tests` (`:111`, cwd `modules/compiler-core`), the lib-agnostic grep gate (`:152`), `lsp_tests` (`:169`), `cli_tests` (`:188`) — and `clean-tmp` (`:127`) as a prerequisite | — | yes, `test.yml` job `test` (ubuntu-22.04 + macos-14 hard, windows-2022 allow-fail) | green |
| `clean-tmp` | reaps `modules/compiler-core/.botopinkbuild/tmp` dirs older than a day | yes | via `test` | fine |
| `test-libs` | `bash scripts/test-libs.sh` → `zig-out/bin/botopink-lib-test` (`:285`) | **no** | yes, `test.yml` job `test-libs`, `-- --target commonJS`, `needs: test`, allow-fail only on windows | **red on every push** — see below |
| `test-vscode` | `bash ../../scripts/test-vscode.sh` (`:301`) | no | no | **the script does not exist** anywhere in the workspace; the meta repo has no `scripts/` directory at all |
| `test-backends` | `bash modules/compiler-cli/tests/backend_exec.sh` (`:315`) | no | no | runs; 1 of its 2 pinned reds is stale |
| `test-bpmp` | `bpmp` unit tests (`:264`) | no | no | deliberate (`:255` comment) |
| `run`, `install` | the CLI | — | `release.yml`/`tag.yml` build only, never test | — |

**Corrected:** `hook-integrity` is not a gate that is missing — it is a name with no referent.
No build step, no workflow and no script in any of the seven repositories mentions it; the only
occurrence in the workspace is this spec. The meta repository has no `.github/` directory at all,
so nothing gates a submodule bump.

#### Where the libraries are compiled

| Repo | Workflow | Trigger | Compiler it builds against | Effect |
|---|---|---|---|---|
| botopink-lang | `test.yml` job `test-libs` | push/PR to `main`/`feat` | itself | `actions/checkout` pulls botopink-lang alone, so the runner's root walk finds only `<checkout>/libs` → **`libs/std` and nothing else** |
| erika | `test.yml` | push/PR to erika's own branches | `vars.BOTOPINK_LANG_REF \|\| 'feat'` (`:63`) — but the identity banner at `:125` prints `\|\| 'main'` | never triggered by a compiler change |
| jhonstart, onze, rakun | `test.yml` | push/PR to their own branches | `vars.BOTOPINK_LANG_REF \|\| 'main'` | same, and `main` lags `feat` |
| vscode-extension | `test.yml` | push/PR to `main`/`feat` | — | pure-TS suite |
| emilia | — | — | — | **no workflows at all** |

None of the sibling workflows can be triggered from botopink-lang (no `repository_dispatch`, no
`workflow_call`). **A change to the compiler is therefore never tested against any library.**

#### The local gate

| Repo | `.git/hooks/pre-commit` |
|---|---|
| meta | symlink to `../../scripts/git-hooks/pre-commit` — **dangling**, the meta repo has no `scripts/` |
| **botopink-lang** | **absent** — the repo that ships everything has no local gate |
| erika, jhonstart, onze, rakun, vscode-extension | installed, resolve |
| emilia | absent |

The installed sibling hooks delegate to `$META_ROOT/scripts/git-hooks/lib/test-runner.sh`
(`scripts/git-hooks/pre-commit:13`), which does not exist, so every one of them falls through to
the standalone path. botopink-lang's own `runner-standalone.sh` is the strongest gate in the
workspace — conflict markers, `zig fmt --check`, `zig build`, `zig build test`, then
`botopink test` in each `libs/*` — and it is the one that is not installed. Installing it today
would red immediately: `botopink test` in `libs/std` exits 1.

#### What is therefore unchecked

- **A `.bp` library.** `test-libs` is in no gate. Measured at HEAD over the six checked-out
  libraries (`botopink-lib-test --lib-root <copies>`, default targets): **1 passed, 7 failed,
  4 skipped** — emilia green on commonJS; erika and std red on both; jhonstart, onze and rakun red
  on commonJS and skipped on erlang — 7 red cells of 12, not "8/8 red". Since `libs/std` is one of
  the red ones and CI's `test-libs` job sees only `libs/std`, that job is red on `feat` right now.
- **wasm execution, entirely.** `codegen/runtime.zig:553` `executeWat` discards its arguments and
  returns `""`. Every one of the 278 wasm snapshots therefore carries an empty RUN LOG; the
  backend is never run. CI installs wasmtime (`test.yml:82`-`100`) for a step that never uses it.
  The decision belongs to spec 03 step 2.
- **Program output — partially, not wholly.** "Assertions are return values, never stdout" holds
  for `backend_exec.sh` (`--invoke main`, `erl -eval`) but not for the snapshot suite, which
  compares a captured RUN LOG byte for byte. Measured: non-empty RUN LOGs in
  `snapshots/codegen/` — commonJS 106/279, erlang 117/279, beam 106/278, **wasm 0/278**. So three
  backends do assert stdout, on ~40 % of fixtures; the blind spot is wasm and the ~60 % of
  fixtures whose program prints nothing.
- **The CLI end to end.** All 53 compiler-cli unit tests are in `cli/*.zig`; `main.zig` has none,
  so no flag parser is tested, and no step runs the binary against a real project. This is the
  whole of step 4.
- **`modules/compiler-cli/tests/`** — only `backend_exec.sh` is wired (`build.zig:315`):
  - `test_tooling.sh` asserts `grep -q "running 4 tests"` (`:45`). The runner prints
    `TEST main.bp:9 …` per test and `4 passed, 0 failed` — never a `running N tests` banner. The
    script fails on its first assertion, and has since the banner changed. The *behaviours* it
    checks all hold.
  - `std_erlang.sh` documents itself as "currently EXPECTED TO FAIL" and cites
    `tasks/v0.beta.3/specs/`, a path that no longer exists.
  - `mutual_recursion.sh` and `std_erlang.sh` both run an unconditional `zig build`; neither
    honours `BOTOPINK_SKIP_BUILD`, so neither can be wired as-is.
- **`backend_exec.sh`'s pinned reds.** Two escape hatches, both non-fatal by construction.
  `pin_beam_red RECORDS 3 "case-dispatch/lambda codegen"` (`:120`) is **stale**: at HEAD the
  fixture builds, `erlc +from_asm` succeeds and `main:main()` returns `3`, so the cell prints
  `looks FIXED — promote to a hard assert` and passes either way. `pin_run_red MODULES erlang`
  (`:128`) is still genuinely red — `out/main.erl:26:24: function describe/0 undefined`.
- **An orphan module.** `cli/sources.zig:65`-`67` reports a module no `mod` path reaches as a
  `warnDetail`, so `libs/std`'s `primitives.bp` (1019), `reflect.bp` (49) and `types.bp` (79) —
  1147 lines — are skipped by `check`, `build` and `test` alike with three warning lines.

#### What the gate should be

**Local, in order** — each step is cheap enough that a failure is found before the next runs:

1. `zig fmt --check` on staged `.zig`, conflict-marker scan (already in `runner-standalone.sh`)
2. `zig build` — the CLI and the LSP link
3. `zig build test` — the compiler suite, **with `modules/compiler-core/.botopinkbuild/runtime-cache`
   deleted** for the run that decides a merge
4. `zig build test-cli` (new) — `modules/compiler-cli/tests/*.sh`, every script, each honouring
   `BOTOPINK_SKIP_BUILD`
5. `zig build test-libs` — every library the checkout can see, per target, with **no** skip that
   is not a missing runtime
6. `zig build test-backends` — pinned reds converted to hard asserts or deleted

Install it as botopink-lang's `pre-commit`, and in the meta repo replace the dangling symlink with
a hook that runs the same gate in `repository/botopink-lang` plus `botopink test` in each
checked-out sibling.

**In CI**, one workflow in botopink-lang with the sibling repos checked out:

| Job | Steps | Runners |
|---|---|---|
| `test` | zig, OTP 28, node, wasmtime → steps 2–4 above | ubuntu + macos hard, windows allow-fail |
| `libs` | `needs: test`; checkout botopink-lang, then `actions/checkout` each of `botopink/{emilia,erika,jhonstart,onze,rakun}` at `feat` into `repository/<name>/`; `zig build test-libs` over all targets | ubuntu hard |
| `backends` | `needs: test`; `zig build test-backends` | ubuntu hard |

A library failure must surface as the job's own failure with the library's name and the failing
module's diagnostic in the log — which is exactly what step 4's C1/C4 fixes make possible: today a
library can fail to compile and `botopink test` still exits 0.

**Cost.** Measured on the dev workstation, cold caches:

| Piece | Measured |
|---|---|
| `botopink check` / `test` per library | 105–460 ms each; rakun 17 ms (fails at dependency resolution) |
| `botopink-lib-test` over 6 libraries × 2 targets | **3.1 s** total (2.3 s for commonJS alone) |
| `zig build test`, warm runtime cache | ~17 s (`AGENTS.md`) |
| one child-process spawn | `node` 16 ms, `wasmtime` 2 ms, `erl` 79 ms, `erlc` 131 ms |
| entries in the runtime cache a cold run must re-execute | 532 |

So the libraries cost **seconds**, not minutes: the reason to add them to the gate is coverage, not
that they are expensive. The expensive piece is the cold cache — 532 re-executions at the unit costs
above put a cold `zig build test` in the region of a minute rather than 17 s, which is the price of
the rule that the merge-deciding run is cold.

**Acceptance:**
- [ ] `zig build test-cli` exists and runs all four `modules/compiler-cli/tests/*.sh`; each is green
      or deleted, and each honours `BOTOPINK_SKIP_BUILD`
- [ ] `test_tooling.sh` asserts the output the runner actually emits
- [ ] The two `pin_*_red` helpers are gone: each cell is a hard assert or the cell is deleted
- [ ] `zig build test-vscode` points at a script that exists, or the step is deleted
- [ ] CI checks out the sibling repos and `zig build test-libs` covers them; a library failure fails
      the job by name
- [ ] botopink-lang has an installed `pre-commit` that runs the local gate, and the meta repo's
      dangling hook symlink is replaced
- [ ] `libs/std` is green, so the gate above can be installed without being pinned red (step 6)
- [ ] A module not reached by a `mod` path fails, or is counted and reported

### Step 6 — `libs/std` (L7)

Paths in this step are relative to `repository/botopink-lang/`.

**Current state.** `botopink check` inside `libs/std` stops on the first error and never reaches
the tests:

```
warning: module not reached by any `mod` path — not compiled: src/types.bp
warning: module not reached by any `mod` path — not compiled: src/reflect.bp
warning: module not reached by any `mod` path — not compiled: src/primitives.bp
  Checking 24 module(s)...
error: pick expects a type and field names at random:141:13
```

`src/root.bp:13-35` declares 23 `pub mod`; `src/` holds 26 `.bp` plus `sidecars/random.mjs`. The
three warned modules are 1147 lines (`primitives.bp` 1019, `types.bp` 79, `reflect.bp` 49).

Six defects. **6a is the only one that blocks the rest** — with `random.bp`'s `pick` renamed in a
scratch copy, the 23-module tree checks clean in 113 ms and `botopink test` reaches 131 tests:
113 pass, 18 fail, and four modules never start. Fix in the order below.

| | before 6a | after 6a alone |
|---|---|---|
| `botopink check` | fails at `random:141:13` | clean, 24 modules |
| `botopink test` | not reached | 131 discovered · 113 pass · 18 fail · exit 1 |
| modules that crash before their first test | — | `env`, `os`, `process`, `random` (4) |
| failing assertions | — | 18, **all** `Cannot find module './gleam_stdlib.mjs'` |

#### 6a — the comptime type-manipulation intercept claims `pick` before any module can

`comptime/infer.zig:6901` runs `tryResolveTypeManipulationCall` on the **bare callee name**, with
no `env.lookup(call.callee)` guard and no receiver guard:

```zig
6901:  if (try tryResolveTypeManipulationCall(env, call.callee, typedArgs, typedTrailing, loc)) |result| {
```

`tryResolveTypeManipulationCall` (`:4041-4073`) matches five names and dispatches four of them —
`mergeRecords` (`:4059`), `partial` (`:4062`), `omit` (`:4065`), `pick` (`:4068`). `mapFields`
falls through to `return null` (`:4071-4072`, "takes a lambda transform — not yet implemented").
So **any** call named `pick`/`omit`/`partial`/`mergeRecords` anywhere in any module is intercepted,
including `libs/std/src/random.bp:141`, which calls its own `pub fn pick<T>(xs: Array<T>) -> ?T`
(`random.bp:73`). The error text — `pick expects a type and field names` — comes from
`resolvePick` (`:4242`, `:4245`).

The correct pattern is eleven lines below, in the `result` namespace: `infer.zig:6911` gates on
`env.lookup(recvName) == null`, and `:6919` repeats it for associated fns, precisely so a value
binding of the same name keeps normal dispatch.

`pick` is documented public std surface (`libs/std/AGENTS.md:47`), so renaming it is an API break,
not a fix. **Fix in the compiler:** guard `:6901` with `env.lookup(call.callee) == null` (and
`call.receiver == null`), so a user declaration of any of the five names wins.

This is the same defect spec 06 report `codegen-comptime-misc` records as "the `pick`/`omit`/
`partial`/`mergeRecords` builtin intercept shadowing user fns" and report `codegen-wat-narrowing`
as "user `pick` vs the builtin". Fixing it here closes both rows.

**Acceptance:**
- [ ] A module that declares `pick`/`omit`/`partial`/`mergeRecords`/`mapFields` calls its own
- [ ] `mergeRecords(A, B)`, `partial(T)`, `omit(T, n)`, `pick(T, ns)` still resolve where no user
      declaration shadows them (they do today with no `.bp` declaration anywhere)
- [ ] `botopink check` in `libs/std` is clean

#### 6b — `botopink.json` `files` names three files that do not exist

`libs/std/botopink.json:8-11` lists `primitives.d.bp`, `array.d.bp`, `string.d.bp`,
`builtins.d.bp`. Only `builtins.d.bp` exists; the real core set is `primitives.bp`,
`builtins.d.bp`, `builtins_fns.d.bp` (`build.zig:35-39`). `array.d.bp` and `string.d.bp` were
folded into `primitives.bp` — `comptime.zig:615-618` binds `array_interface_src` and
`string_interface_src` to the same `primitives` blob and says so.

`files` is consumed by `compiler-cli/src/cli/libs.zig:300-312`; the read at `:302` is a bare `try`,
so the **first** missing entry aborts `loadLibModules` with an unhandled `error.FileNotFound` — no
diagnostic naming the file, unlike the manifest probe at `:289` which does `catch continue`. It is
latent only because `std` is served by the embedded prelude rather than by this loader.

**Fix in the std source:** set `files` to the three real core files, or drop the key once nothing
resolves `std` through `libs.zig` (CLI `loadDependencies`, LSP `project_graph.zig:163`). Either
way `libs.zig:302` should report the missing path instead of propagating `FileNotFound`.

**Acceptance:**
- [ ] Every entry of every `botopink.json` `files` in the workspace resolves
- [ ] A missing `files` entry produces a located diagnostic, not a bare error name

#### 6c — `./gleam_stdlib.mjs`: 22 declarations, 4 of them actually emitted, 0 shipped

**`gleam_stdlib.mjs` is the Gleam language's runtime, not ours.** The 22 annotations name a file
from another language's standard library — `string_length`, `starts_with`, `trim_start` are Gleam
symbols, and `libs/std/src/order.bp:1` says outright that the module is "inspired by
`gleam/order`". The reference is a leftover from that borrowing, so **shipping the file is not on
the table**: vendoring another language's runtime to satisfy our own primitives would make botopink
depend on Gleam's ABI for `slice`. The decision is to remove the dependency, not to satisfy it.

The file exists in no repository, in no commit, and no build step copies it. What that costs is
narrower — and sharper — than "22 broken primitives".

**Mechanism.** A 3-arg `@External.Node("<module>", "<symbol>")` on an *interface method* is
skipped by both the emitter and inference when `<module>` is a relative companion:
`commonJS.zig:1431` (`if (!isJsGlobalNamespace(ref.module)) continue;` — no prototype patch) and
`infer.zig:6675-6677` ("left to the permissive path (native JS handles them)"). The call-site
rename map is fed only by the **2-arg** form (`commonJS.zig:734-742, 786-788`), so no rename is
recorded either. The call therefore emits verbatim — `xs.at(0)`, `path.split(sep)` — and resolves
against the real JS prototype. A 3-arg annotation on a **`declare fn`** has no receiver to fall
back to, so it emits `require("./gleam_stdlib.mjs").<symbol>(…)` and throws at require time.

Measured over the whole of `libs/std` compiled to `commonJS`: the only gleam symbols that reach
emitted JavaScript are `slice` (12 call sites) and `string_slice` (4).

| # | Declaration | `primitives.bp` | gleam symbol | Emitted JS | Status |
|---|---|---|---|---|---|
| 1 | `String.length` | `:118` | `string_length` | none — `.length` is only ever read as a property | inert |
| 2 | `String.split` | `:122` | `split` | `s.split(sep)` | inert · native |
| 3 | `String.startsWith` | `:140` | `starts_with` | `s.startsWith(p)` | inert · native |
| 4 | `String.endsWith` | `:145` | `ends_with` | `s.endsWith(x)` | inert · native |
| 5 | `String.trim` | `:150` | `trim` | `s.trim()` | inert · native |
| 6 | `String.trimStart` | `:154` | `trim_start` | `s.trimStart()` | inert · native |
| 7 | `String.trimEnd` | `:158` | `trim_end` | `s.trimEnd()` | inert · native |
| 8 | `String.replace` | `:162` | `replace` | `s.replace(a, b)` | inert · native |
| 9 | `String.charAt` | `:174` | `string_char_at` | `s.charAt(i)` | inert · native, **semantics differ**: JS returns `""` where the signature says `?string` |
| 10 | `String.indexOf` | `:178` | `index_of` | `s.indexOf(sub)` | inert · native |
| 11 | `stringSlice0` | `:231` | `string_slice` | `require("./gleam_stdlib.mjs").string_slice(self, start)` | **broken** |
| 12 | `stringSlice1` | `:235` | `string_slice` | `require("./gleam_stdlib.mjs").string_slice(self, start, end)` | **broken** |
| 13 | `Array.at` | `:561` | `index` | `xs.at(i)` | inert · native (ES2022) |
| 14 | `Array.push` | `:565` | `push` | `xs.push(x)` | inert · native |
| 15 | `Array.pop` | `:569` | `pop` | `xs.pop()` | inert · native |
| 16 | `Array.join` | `:581` | `join` | `xs.join(sep)` | inert · native |
| 17 | `Array.indexOf` | `:590` | `index_of` | `xs.indexOf(x)` | inert · native |
| 18 | `Array.forEach` | `:594` | `for_each` | `xs.forEach(f)` | inert · native |
| 19 | `Array.map` | `:598` | `map` | `xs.map(f)` | inert · native |
| 20 | `Array.filter` | `:602` | `filter` | `xs.filter(p)` | inert · native |
| 21 | `arraySlice0` | `:828` | `slice` | `require("./gleam_stdlib.mjs").slice(this, start)` | **broken** |
| 22 | `arraySlice1` | `:832` | `slice` | `require("./gleam_stdlib.mjs").slice(this, start, end)` | **broken** |

**18 of 22 are inert** — the annotation documents an intent the backend never acts on, and the
native JS method of the same name carries the call. No other backend is affected: each of the 22
also carries `@External.Erlang` (and 5 carry `@External.Beam`), which is what erlang/beam use.

**4 of 22 break, and they break more than themselves.** `stringSlice0/1` and `arraySlice0/1` are
the arity-dispatch helpers behind `default fn slice` (`primitives.bp:165-171` for `String`,
`:572-578` for `Array`). Because `slice` is a `default fn`, the emitter *does* patch the prototype
— `String.prototype.slice` and `Array.prototype.slice` appear in the emitted std — so the patch
**replaces the working native `slice` with one that throws**:

```javascript
String.prototype.slice = function(start, end) {
    const self = this.valueOf();
     if (end) { return require("./gleam_stdlib.mjs").string_slice(self, start, end); } else { … };
};
```
(`snapshots/codegen/commonJS/string_methods_map_to_native_js_names.snap.md:39-42`; the array twin
is `array_slice_2_arg_lowers_byte_identically_across_backends.snap.md:57`.)

**Who else it breaks.** Every one of the 18 `botopink test` failures in `libs/std` is this, and
nothing else:

| Module | Failing tests | Reached through |
|---|---|---|
| `url` | 8 | `.slice` in `parse`/`serialize` |
| `path` | 5 (`dirname`, `relative` ×2, `resolve` ×2) | `.slice` |
| `queue` | 4 | `.slice` |
| `querystring` | 1 | `query.slice(1, query.length)` |

Plus, outside std: 2 of erika's 18 fluent tests, and the jhonstart/onze paths already recorded in
step 1. Five committed commonJS snapshots pin the broken `require` as the expected output
(`string_methods_map_to_native_js_names`, `string_slice_copies_bytes_into_a_new_buffer`,
`array_slice_2_arg_lowers_byte_identically_across_backends`, `array_instance_default_fn_methods`,
`option_method_on_tuple_element`, `array_zip_via_external_node_template`), four of them with an
empty RUN LOG.

**This is a shipping decision, and there are three options.** It should be settled before any code
moves:

| Option | What it means | Cost |
|---|---|---|
| **A — delete the companion** (recommended) | Re-annotate the four helpers as Node templates: `@External.Node("$self.slice($0)")` / `("$self.slice($0, $1)")`. The template form renders into the prototype body (`commonJS.zig:1385-1397`), so `.slice` keeps working and no file needs shipping. Drop the `./gleam_stdlib.mjs` module argument from the other 18 and leave the 2-arg native-name form where the JS name differs | Re-record 6 snapshots; nothing else moves |
| B — write and ship the companion | Author `libs/std/src/sidecars/gleam_stdlib.mjs` with 12 exports and ship it through `shipMjsSidecars` (`cli/libs.zig`), which already probes `<lib>/src/sidecars/<base>` | New file to maintain; a `require` on every `.slice` call; the other 18 stay inert either way |
| C — keep the annotations as documentation | State in `libs/std/AGENTS.md` that a relative-companion 3-arg Node annotation is documentation only, and fix only the four `declare fn` | Leaves a live trap: any future `declare fn` with a relative companion breaks silently |

Option A is the smallest fix that makes the 18 red tests green, needs no new file, and removes a
name that grep says is load-bearing but is not.

**Acceptance:**
- [ ] No declaration in `libs/std` names a file that is not shipped
- [ ] `libs/std`'s 18 `./gleam_stdlib.mjs` test failures are green
- [ ] The six commonJS snapshots that pin the `require` are re-recorded with a non-empty RUN LOG
- [ ] `libs/std/AGENTS.md` states what a 3-arg `@External.Node` with a relative module actually
      does on an interface method versus on a `declare fn`

#### 6d — four std modules emit JavaScript that does not parse

Independent of 6c, and only visible once 6a lets the tests run. `env`, `os`, `process` and
`random` abort with a Node `SyntaxError` before their first test, because a template-form
`@External.Node` on an imported `declare fn` is lowered as a destructuring import whose *key* is
the template:

```javascript
env.js:71      const { (process.argv.slice(2)): args } = require("");
os.js:55       const { require('os').hostname(): hostname } = require("");
process.js:66  const { process.cwd(): cwd } = require("");
random.js:66   const { require('./sidecars/random.mjs').seededFloat(): seededFloat } = require("");
```

Note the empty module specifier — a 1-arg (`module == ""`) annotation reaches the import emitter,
which has nothing to put in `require(…)`. 31 tests are lost this way (`env` 5, `os` 7, `process` 4,
`random` 14, minus the ones already counted). This is spec 06 report `codegen-comptime-misc`'s
"dangling import for template-only symbols" with a reproduction: **fix in the compiler** —
`commonJS.zig` must not emit an import binding for a symbol whose `@External.Node` is a template
or a 1-arg native name; those render at the call site.

**Acceptance:**
- [ ] `env`, `os`, `process` and `random` run their tests
- [ ] A `declare fn` whose `@External.Node` is a template or 1-arg form emits no `require(…)`
- [ ] A codegen test covers each of the two shapes

#### 6e — `reflect.bp` and `types.bp` are unreachable re-implementations of working builtins

Neither is in `root.bp` nor in `build.zig:35-39` `std_core_files`, so neither is embedded by
anything; `stdPkgFilesFromRoot` (`build.zig:56`) derives the importable set from `root.bp` alone.
Declaring them does not help, because each fails on its own **and** because the four functions
they define already exist in Zig and would be intercepted by 6a's code path regardless:

| File | Defines | Zig implementation | Compiles today |
|---|---|---|---|
| `reflect.bp:19` | `mergeRecords` | `infer.zig:4076` `resolveMergeRecords` | no |
| `types.bp:17` | `mapFields` | **none** (`infer.zig:4071-4072`) | no |
| `types.bp:37` | `partial` | `infer.zig:4062` `resolvePartial` | no |
| `types.bp:52` | `omit` | `infer.zig:4065` `resolveOmit` | no |
| `types.bp:68` | `pick` | `infer.zig:4068` `resolvePick` | no |

Verified: with no `.bp` declaration anywhere, `mergeRecords(User, Stamps)`, `partial(User)`,
`omit(User, "id")` and `pick(User, ["name"])` all check clean; `mapFields(...)` reports
`unbound variable 'mapFields'`.

Why each fails, precisely — **the recorded cause for `reflect.bp` is incomplete**:

| Site | What a reader sees | Real cause |
|---|---|---|
| `types.bp:23` (also `:55`, `:71`) | `error: unknown field 'Record' on type 'TypeInfo' at types:23:16` | `TypeInfo` is an **enum** with a `Record(fields: RecordField[])` variant (`comptime.zig:594-605`). `info.Record.fields` is variant-payload access written as nested field access; the payload is reachable only through `case info { TypeInfo.Record(fields) -> … }` |
| `reflect.bp:26` | `error: parse error in reflect` — **no location** (see step 4: parse/lexer errors are unlocated) | Two independent blockers. (1) `and` is not a keyword: `lexer.zig:693-745` has no entry for it, so it lexes as an identifier. (2) **Rewriting it to `&&` does not fix it** — `exprs.zig:136` parses an `if` condition at `prec.equality`, which `parser.zig:1134-1140` defines as level 2, *below* `\|\|` (0) and `&&` (1), and documents as "operand positions where `\|\|`/`&&` are not accepted (if-conditions, yields, ranges, assignments…)". `if (a && b)` is a parse error for every operand shape. No `.bp` in the workspace uses it; `libs/std/src/path.bp:83` and `primitives.bp:102` show the two forms that do work (`val c = a == b && …;` and `return … && …;`) |
| `reflect.bp:24-25,37,40,42` | — | the same `info.Record.fields` as `types.bp`, behind the parse error |
| `primitives.bp:473` | `error: type mismatch: expected string, got i32 at primitives:473:21` | Exactly **one** error in 1019 lines. `val always42 = Function.constant(42)` is not generalised, so its parameter type is a single unification variable: `:472` binds it to `string`, `:473` then offers `i32`. A let-generalisation gap, not a `Function` bug |

**This is a shipping decision.** Recommended: delete `reflect.bp` and `types.bp`. They are
1129 lines of unreachable source that shadow working implementations and give a false impression
that the std has `.bp` type functions. If the type-system spec's std-type-functions step wants
`.bp` sources instead, it owns all five fixes above plus an implementation of `mapFields`, and it
must decide first whether the Zig intercept or the `.bp` module is the definition. Spec 05 item
5.1 tracks the same file pair from the hygiene side.

**Acceptance:**
- [ ] `reflect.bp` and `types.bp` are deleted, or declared in `root.bp` with tests that run
- [ ] `libs/std/AGENTS.md:27-29` matches the outcome
- [ ] `mapFields` either works or is documented as not existing

#### 6f — `primitives.bp`'s 67 tests are unreachable, and `pub mod primitives` is not the fix

`primitives.bp` is embedded as a core file only (`build.zig:36`,
`comptime/stdlib/prelude.zig:12`), i.e. as a source string flattened into the global type env. It
is never compiled in test mode, so its 67 `test` blocks (`:296` onward) never run.
`libs/std/test/` holds one unrelated file, `result_test.bp`.

`pub mod primitives;` would put it in **both** sets — `std_core_files` (`build.zig:35-39`, embedded
into the prelude) and `std_pkg_files` (`build.zig:56-83`, registered as the importable package
`std/primitives`) — so the primitive interfaces would be declared twice and `import {primitives}
from "std"` would become a surface nobody wants.

**Fix in the std source plus the harness:** move the tests to `libs/std/test/primitives_test.bp`
(`test/` is scanned directly and sees the global env), or add a compiler-core test that compiles
`primitives.bp` in test mode. Expect one failure to carry over — 6e's `primitives.bp:473` — plus
whatever the 66 remaining tests find; register those in the codegen-hardening spec. Spec 05 item
5.2 is the hygiene half of the same move.

**Acceptance:**
- [ ] The 67 tests run on commonJS and erlang, with their failures registered by name
- [ ] `primitives.bp` is in exactly one of `std_core_files` / `std_pkg_files`
- [ ] A module in `libs/std/src/` that no `mod` path reaches fails the gate (step 5)

### Step 7 — Library repos (L2, L8, L9, L10)

Paths in this step are relative to `repository/`, except where they name the compiler
(`botopink-lang/…`).

| Repo | Blocking defect | Fix lives in | 7.x |
|---|---|---|---|
| rakun | a dependency that exists in no commit | rakun, or a new repo | 7a |
| erika | two-parameter `loop` loses the accumulator | compiler | 7b |
| erika | `AGENTS.md` documents a removed evaluator | erika | 7c |
| emilia | no hook, no CI | emilia | 7d |
| vscode-extension | retired syntax in snippets + grammar | extension | 7e |
| vscode-extension | Test Explorer forwards targets `test` refuses | extension | 7f |
| vscode-extension | CI never builds against this compiler | extension | 7g |
| bpmp | three git-dependency bugs | bpmp | 7h |

#### 7a — rakun's `server` dependency exists nowhere

`rakun/botopink.json:7` — `"dependencies": ["server"]`. There is no directory named `server` under
`repository/`, no `botopink.json` with `"name": "server"` anywhere (the workspace has exactly
seven: the six libs plus `std`), and nothing in the git history of either rakun or the meta repo
(`git log --all -S'"name": "server"'` is empty in both).

The array form is valid — `compiler-cli/src/cli/config.zig:182-195` `parseDependencies` accepts
both the legacy array and the object form. The failure is resolution:
`compiler-cli/src/cli/libs.zig:295` `return error.LibNotFound`, surfaced by
`cli/build.zig:65` and `cli/check.zig:40` as *"a declared dependency was not found under the libs
root"*. So `check`, `build` and `test` all fail before rakun's own source is read.

Two asymmetries worth fixing with it:

- **The LSP disagrees with the CLI.** `language-server/src/project_graph.zig:171` swallows the
  miss (`self.loadLib(…) catch continue`), so the editor shows a working project while the CLI
  refuses to build it.
- **A test hard-codes the phantom.** `libs.zig:669` —
  `test "loadOne: rakun resolves \"server\" across roots; absent dep is LibNotFound"` — synthesises
  `ws/repository/botopink-lang/libs/server/botopink.json` at `:677` because no real one exists.

rakun's source does use it: `rakun/src/bootstrap.bp:26` `import {serverServe} from "server";`, called
at `:35`. The prose at `bootstrap.bp:6-7`, `:21`, `runtime.bp:85-88` and `test/server_test.bp:4-10`
all describe a `libs/server` that owns the socket.

Also at `rakun/botopink.json:6`: `"targets": ["commonJS"]` (plural, array). The manifest parser
reads only a singular string `"target"` (`config.zig:158-161`, default at `:61`), so the key is
silently ignored — an instance of step 4's "unknown key accepted" class.

**Fix:** decide one of — create `libs/server` (the `bootstrap.bp` prose describes its contract:
one `serverServe(port, dispatcher)` entry point), vendor it into rakun's own `src/` as a
`declare fn` over `node:http`, or drop the dependency and the `bootstrap.bp:26` import together.
Whatever is chosen, the `libs.zig:669` test must stop inventing the lib, and `"targets"` becomes
`"target": "commonJS"`.

**Acceptance:**
- [ ] `botopink check`, `test` and `build` run in `rakun/` — no `LibNotFound`
- [ ] No compiler test synthesises a library that does not exist
- [ ] A missing dependency is reported the same way by the CLI and the language server

#### 7b — the two-parameter `loop` drops its accumulator and calls `lists:foreach/2` with arity 2

One compiler defect, two deciding lines, both in
`botopink-lang/modules/compiler-core/src/codegen/erlang.zig` — which is also the comptime path
(`comptime/template_eval.zig:24` imports it; there is no separate loop lowering under `comptime/`).

1. **The fold is refused.** `erlang.zig:2547` — `if (lp.params.len != 1 or lp.indexRange != null or lp.awaitLoop) return null;`. A two-parameter loop never reaches `mutatingFoldExpr` (`:2551`), so the rebinding contract documented at `:2517-2523` ("a statement-level `if`/`loop`/`forEach` that reassigns variables bound before it is lowered to an expression that *returns* the new values") silently does not apply to it.
2. **The `enumerate` repair misses.** `erlang.zig:3259` — `if (lp.indexRange != null and lp.params.len == 2)`. The comment at `:3253-3257` explains that `lists:map`/`foreach` pass one element, so two loop parameters cannot be two fun parameters — "that raised `function_clause` at every call". But the guard requires an explicit `, 0..` range. erika writes `loop (cmpToks) { ct, idx -> }` with no range, so `indexRange == null`, control falls to `:3275-3322`, and a **2-arity fun** is handed to `lists:foreach/2`.

Both defects are visible in one generated body —
`erika/.botopinkbuild/tmp/template/template_097e224d193d043e.erl`:

```erlang
105        lists:foreach(fun(Ct, Idx) ->
106            LTok@2 = case (Idx =:= 0) of
...
127        end, CmpToks),
131                failAt(Q, maps:get(span, OpTok@2), …
```

`:105` is the arity-2 fun into `lists:foreach/2`; there is no `{LTok@2, OpTok@2, RTok@2} =
lists:foldl(…)` binding, and `OpTok@2` is read at `:131` outside the closure that bound it. One-param
loops in the same module lower correctly (`:14`, `:367`, `:427`, `:516` are all `lists:foldl`).

Affected source: `erika/src/erika.bp:410` (`buildCmp`, whose only purpose is to mutate `lTok`/
`opTok`/`rTok`, read at `:416` and `:418-420`) and `erika/src/erika.bp:440` (the lexer, mutating
five outer `var`s declared at `:435-439`). `erika/AGENTS.md:123` documents the two-parameter form
as the idiom, so this is a documented API that does not work.

The typed backend is the *same code*, so it has the same bug wherever a two-parameter loop appears.

**Fix in the compiler:** relax `:2547` to accept `params.len == 2` and fold over
`lists:enumerate/1` with a `{Item, Idx}` tuple parameter; relax `:3259` to fire on
`params.len == 2` whether or not `indexRange` was written. Both must go in together — fixing only
`:3259` leaves the accumulator lost.

**Acceptance:**
- [ ] `loop (xs) { x, i -> acc = … }` threads `acc` out, like the one-parameter form
- [ ] No `lists:foreach/2` or `lists:map/2` ever receives a fun of arity ≠ 1
- [ ] A compiler-core regression test covers the two-parameter loop on the typed **and** the
      comptime path, so it does not depend on an erika checkout
- [ ] erika's `buildCmp` and its lexer produce their accumulated values

#### 7c — erika documents a comptime evaluator that no longer exists

`erika/AGENTS.md:108-148` ("Comptime-eval constraint") describes a **JavaScript** evaluator and
derives every rule in the file from it:

| Line | Claim | Reality |
|---|---|---|
| `:117-118` | anonymous `record {…}` "lower to plain JS object literals"; a named record "would emit `new Token(…)`, undefined in the eval" | bodies run as Erlang; records are maps |
| `:119-121` | "Native-JS ops only: `split`/`join`/`slice`/`map`/`filter`/`append`/`+`/`==`, plus array `.length` (a *property*)" | this list is **the cause of step 1** — the comptime module defines only `__bp_add/2`, `__bp_len/2`, `__bp_text/1`, `__bp_json/1` |
| `:125-126` | `string.length()` "needs a JS-property rename" — use `s.split("").length` | `.len`/`.length` lower to `'__bp_len'(X, length)` (`erlang.zig:406-424`) |
| `:60` | "No arity overloading (the JS backend mangles same-named methods)" | unrelated to the current evaluator |

The evaluator is the persistent `erl` server: `architecture.md:12-13, 15` ("**Não há runtime Node,
wasm3 ou WAT para comptime.**", `:19`), `comptime/AGENTS.md:27, 35`,
`comptime/template_eval.zig:1`. The server module is on disk at
`erika/.botopinkbuild/tmp/persistent_erl/botopink_comptime_server.erl`.

**Fix in erika:** rewrite `:108-148` against the Erlang evaluator — what a comptime body may call
(the four `__bp_*` helpers plus whatever step 1 adds), how records appear (maps, `maps:get/2`), and
which erlang-codegen gotchas apply (the two already listed in `libs/std/AGENTS.md:152-155`). Do it
after step 1 lands, so the constraint list is written against the fixed surface, not the broken one.

**Acceptance:**
- [ ] No `AGENTS.md` in the workspace describes a JavaScript, wasm3 or WAT comptime runtime
- [ ] Every workaround erika documents is justified by a constraint that still exists

#### 7d — emilia has no gate at all

Every other repo in the workspace ships a `scripts/git-hooks/pre-commit` plus
`scripts/git-hooks/lib/`, and a `.github/workflows/test.yml`. emilia ships neither: its top level
is `src/ examples/ AGENTS.md CHANGELOG.md README.md docs.md botopink.json .gitignore`. There is no
`scripts/`, no `.github/`, and no `test/`.

| Repo | tracked hook source | `.github/workflows/` | installed `.git/hooks/pre-commit` |
|---|---|---|---|
| botopink-lang, erika, jhonstart, onze, rakun, vscode-extension | yes | yes | **no** |
| **emilia** | **no** | **no** | no |

`emilia/AGENTS.md` has no "## Local gate" section — only "## Test surface" (`:137-153`), which
declares 17 in-file tests (`:139-140`) plus 4 in `examples/emilia-card/` (`:150-151`) and nothing
that enforces them. That is exactly how the escaped-markdown source (`#\[@External\.node(`) shipped.

Note the wider finding, which belongs to spec 05 item 5.5: **no repo in the workspace has a hook
installed.** `core.hooksPath` is unset everywhere, every `.git/hooks/` holds only samples, and the
meta repo's `.git/hooks/pre-commit` is a dangling symlink. Fixing emilia's missing *source* without
fixing the install path leaves the gate red-by-omission in all seven.

**Fix in emilia:** copy the sibling `scripts/git-hooks/` pair and a `.github/workflows/test.yml`,
add the "## Local gate" section to `AGENTS.md`, and make the gate run the 21 tests it already
claims.

**Acceptance:**
- [ ] emilia has a tracked hook source and a CI workflow matching its siblings
- [ ] Every sibling library's pre-commit hook is installable by a documented command and passes
- [ ] The gate would reject a source file carrying markdown escapes

#### 7e — the extension offers two snippets and one keyword for syntax the parser rejects

Snippets live in a single root file, `vscode-extension/snippets.json` (wired at
`package.json:56-58`), not `snippets/`.

| Site | Ships | Parser at HEAD |
|---|---|---|
| `snippets.json:52-56` | prefix `*fn`, body `*fn ${1:name}(…) -> @Iterator<…> { yield $0 }` | hard-removed. `parser.zig:88-90` `deprecatedStarFn` ("Deprecation window was v0.beta.12; the prefix is hard-removed in v0.beta.19"), raised at `parser/decls.zig:322-326` and `parser/exprs.zig:976`; message at `print.zig:89-95` — *"the `*fn` prefix was removed in v0.beta.19"*, hint *"rewrite as `#[@<effect>] fn <name>(...) -> @<Wrapper><...> { ... }`"* |
| `snippets.json:71-82` | prefix `struct`, body `struct ${1:Name} { … }` | `struct` is not a keyword. `lexer.zig:693-745` `keywordOrIdent` has `record` at `:730` and no `struct` entry; it falls through to `:745` `return .identifier` |
| `syntaxes/botopink.tmLanguage.json:47` | `struct` in the `keyword.declaration.botopink` alternation | same — and the same regex also lists `const`, which `lexer.zig:700` explicitly calls out: *"'const' is not a surface keyword in botopink; use 'val' instead."* |

The correct record snippet already sits directly above the broken one (`snippets.json:66-70`).

**Fix in the extension:** delete the `struct` snippet; rewrite the `*fn` snippet to the
`#[@iterator]` form named by `print.zig:94`; drop `struct` and `const` from the grammar
alternation at `:47`. Cross-check the whole alternation against `lexer.zig:693-745` while there.

**Acceptance:**
- [ ] Every snippet body and every grammar keyword parses against the compiler at HEAD
- [ ] A test asserts the grammar's declaration-keyword list against `keywordOrIdent`

#### 7f — the Test Explorer forwards targets `botopink test` refuses

`vscode-extension/src/testExplorer.ts:243` builds `["test", "--target", targets.target]` with no
filtering, and `src/targetConfig.ts:6` defines `TARGETS = ["commonJS", "erlang", "beam", "wasm"]`.
So selecting `beam` or `wasm` in the status-bar target picker and running a test yields
`compiler-cli/src/cli/test_cmd.zig:58-63`:

```
`botopink test` currently supports only the commonJS and erlang targets
hint: run with `--target commonJS` or set "target": "commonJS" in botopink.json
```

exit 1, surfaced as an opaque test-run failure. `libs/std/AGENTS.md:117` states the same
restriction, so it is intended, not a CLI gap.

**Fix in the extension:** add `TEST_TARGETS = ["commonJS", "erlang"]` to `targetConfig.ts`, gate
`testExplorer.ts:243` on it, and when the active target is outside that set either fall back to
`commonJS` with a visible notice or disable the run action with the reason.

**Acceptance:**
- [ ] No Test Explorer action can produce the `test_cmd.zig:60` error
- [ ] The two target sets (build vs test) are declared in one place and tested

#### 7g — the extension's CI never builds against this compiler

`BOTOPINK_LANG_REF` appears in every sibling's workflow — `onze/.github/workflows/test.yml:57`,
`jhonstart/…:48`, `rakun/…:8, 58, 120` (all `|| 'main'`) and `erika/…:8, 61-63, 125` (`|| 'feat'`)
— and in **none** of `vscode-extension/`. Its `test.yml` is 37 lines and never checks out
botopink-lang at all: checkout (`:21-22`), setup-node 22 (`:24-30`), `npm ci` (`:32-33`),
`npm test` (`:35-36`). The header says so (`:1-4`): the extension-host suite "is out of scope
here; this gate guards the TypeScript modules behind the extension."

That is precisely why 7e and 7f went unnoticed: nothing in the extension's CI has ever seen a
botopink parser. Note also that the siblings' default of `'main'` does not exercise `feat` either —
erika is the only repo pinned to the branch the work happens on.

**Fix in the extension:** add a job that checks out botopink-lang at
`${{ vars.BOTOPINK_LANG_REF || 'feat' }}`, builds `zig-out/bin/botopink`, and asserts that every
snippet body and the `examples/` sources parse. Settle the `'main'` vs `'feat'` default across all
five workflows in the same change.

**Acceptance:**
- [ ] The extension's CI compiles at least one `.bp` file with the compiler from this workspace
- [ ] All five `BOTOPINK_LANG_REF` defaults name the same branch

#### 7h — bpmp's three git-dependency bugs

`botopink-lang/modules/bpmp/` — the healthiest module in the workspace (builds, genuinely offline,
**90** `test "…"` declarations, run by `zig build test-bpmp`, `build.zig:267`). Note
`build.zig:256`: the step is **kept out of `zig build test`**, and
`src/commands/install.zig` and `src/commands/sync.zig` have **zero** tests between them — which is
why all three bugs are in exactly those two files.

**(a) `install --frozen` symlinks a store path it never checks exists.**
`src/dep/resolver.zig:93` comments "CAS hit *if the store dir exists*" but the only test performed
is `le.rev.len == 40` (`:96`); the file imports no `std.Io` and calls no `access`/`openDir`. `:116`
goes further — under `--frozen` a spec-pinned `rev:` dep is forced to `.reuse_cas` even on a cold
store, skipping the clone. `src/commands/install.zig:192-202` then symlinks it, and
`ensureSymlink` (`:280-290`) does not stat the target either. Result: with a lockfile and a pruned
`$BPMP_HOME/store`, `bpmp install --frozen` prints `✓ <name> (CAS) @ <rev>`, exits 0, and leaves a
**dangling symlink** at `.botopinkbuild/deps/<name>` — which the compiler later reports as
`libs.zig:295` `LibNotFound`, i.e. the misleading *"a declared dependency was not found under the
libs root"*. `src/dep/clone.zig:100` and `:180` do check; the `reuse_cas` path just never runs them.
**Fix:** thread `io` into `resolver.zig` so `:97` and `:113` can probe the path, and make a miss
under `--frozen` a named error rather than a silent success.

**(b) A first install of a `branch:`/`tag:` dependency clones default HEAD.**
`clone.zig:127-137` handles refs correctly (`--branch` for both `.branch` and `.tag`), but the ref
never reaches it: `resolver.zig:20-29` `Action` has no `branch`/`tag`/`ref` field, the fresh-clone
action at `:127-134` drops it, and `install.zig:205-206` re-derives a spec from `act.rev` alone —
so with no lockfile `s.ref` stays `.none`, `clone.zig:136` matches `.rev, .none => {}`, and the
command is `git clone --depth 1 -- <url> <tmp>`. `clone.zig:169` then records that wrong SHA into
the lockfile, so every later install faithfully reuses the wrong commit. The resolver's own test
(`resolver.zig:160-168`) asserts only `Kind.clone`, never that the branch survives.
**Fix:** add `ref: spec.DepRef` to `Action`, populate it at `:128-133`, use it at
`install.zig:205-206` — or carry the original `DepEntry` and delete the re-derivation.

**(c) `sync` resolves every dependency to `botopink/<name>`.**
`src/commands/sync.zig:60` — `allocPrint("botopink/{s}", .{d})` — for every dep, regardless of its
declared `git:` URL. A dep at `github.com/acme/widgets` is queried at `botopink/widgets`, which
either 404s (`:66-69` prints `fetch failed` and continues) or silently resolves against an
unrelated repo. The real source is already in the manifest: `dep/spec.zig` parses `git`/`path` per
entry and `config.zig:43-47` mirrors the shape — `sync.zig:36` just iterates the bare-name list
from `m.dependencies()` instead of `dep_spec.parseFromManifest`, which `install.zig:96` does use.
Compounding it, `sync.zig:99-100` makes `--update` a no-op while `install.zig:384` tells users to
run `bpmp sync --update` to regenerate the lockfile on a schema mismatch — dead-end advice.
**Fix:** iterate `parseFromManifest` entries and derive `RepoSpec` from `entry.spec.git`, falling
back to a configurable default org only where no `git:` is declared; then either implement
`--update` or stop advertising it.

**Acceptance:**
- [ ] `bpmp install --frozen` against an empty store fails with a named error, not a dangling symlink
- [ ] A first install of a `branch:`/`tag:` dep checks out the named ref, asserted by a test
- [ ] `sync` resolves each dep from its own declared source; no org name is hardcoded
- [ ] `install.zig` and `sync.zig` have tests; `zig build test-bpmp` is in the documented gate
      (step 5) or the reason it is not is written down

## Notes

- The sibling hooks are installed but the documented install path is dead: both `AGENTS.md`s point
  at `scripts/install-hooks.sh` in the meta repo, which has no `scripts/` directory. See spec 05.
- A library repo cannot be committed to while its hook is red — that currently blocks jhonstart,
  onze, rakun and erika, including unrelated maintenance.
