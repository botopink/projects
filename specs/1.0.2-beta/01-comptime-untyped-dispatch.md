# Spec 01 — Comptime untyped dispatch and the library gate

**Version:** 1.0.2-beta
**Priority:** critical — every library that uses a template or a decorator is uncompilable, and no gate catches it
**Depends on:** none

---

## Objective

A template or a decorator body may call a primitive's method (`split`, `join`, `slice`,
`indexOf`, `append`, `trim`, `map`, `push`, …) and the Erlang module it is lowered into must
define — or inline — every one of them. The library suites (`zig build test-libs`, the sibling
repos' `botopink test`) run in the same gate as the compiler suite, so this class of break cannot
land unnoticed again.

Paths are relative to `repository/botopink-lang/` unless stated otherwise.

## Current state

`botopink test` in `repository/jhonstart` fails before any test runs — `test/html_test.bp` does not
compile, and the project-scope fail-fast (step 4 of spec 08) returns before the healthy modules are
executed, so **0 tests run**. `botopink check` is green, because it loads `src/` only.

```
{undefined_function,{split,2}} {undefined_function,{slice,3}}
{undefined_function,{join,2}}  {undefined_function,{indexOf,2}}
{undefined_function,{append,2}} {undefined_function,{trim,1}}
   … at html_test:4:16
```

`html_test.bp:4` is `val page = html """<div><p>hi</p></div>""";`. This is not a regression: the
same failure reproduces on compilers built from before the 1.0.1-beta waves.

### The path, at HEAD

Template host — a `.bp` call site to the lint error:

| # | Site | What happens |
|---|---|---|
| 1 | `comptime/infer.zig:3204` `expandTemplateCall` | the body is not reducible by inspection (`classifyTemplateBody` returns null), so `:3211` hands it to the runtime |
| 2 | `comptime/infer.zig:3268` `expandTemplateCallViaRuntime` | `:3331` calls `templateEval.evaluate` |
| 3 | `comptime/template_eval.zig:80` `evaluate` → `:91` `buildModule` (`:282`) | wraps the template `FnDecl` as a **one-decl `ast.Program`** (`:290-291`) |
| 4 | `comptime/template_eval.zig:298` | `erlang.emitComptimeModule(arena, "template_module", program, config)` |
| 5 | `codegen/erlang.zig:484` `emitComptimeModule` | **`:494` creates an empty `instance_lowerings` map** (and `:490`/`:492` empty `comptime_vals`/`rewrites`), then calls `:496` |
| 6 | `codegen/erlang.zig:514` `emitErlangModule` | `:527` `em.untyped = comptime_module != null` |
| 7 | a method call reaches `plainCallNode` (`:3430`); the value-receiver arm starts at `:3489` | `:3545` `this.instance_lowerings.get(loc)` — **always a miss**, the map is empty by construction |
| 8 | `:3565` `selfPrimKind` | null (`self_prim_kind` is only set inside `instanceDefaultForms`) |
| 9 | `:3569` `arrayPrimFallbackNode` (`:3904`) | answers for `forEach`/`fold`/`drop`/`take`/`toList` only |
| 10 | `:3570` | `toString` with no args only |
| 11 | **`:3571`** | `b.call(cc.callee, …)` → the bare local call `split(T, <<"\n">>)` |
| 12 | `comptime/template_eval.zig:96-98` | writes the `.erl`, `persistent_erl.evalDetailed` compiles it → `{undefined_function,{split,2}}` |
| 13 | `comptime/template_eval.zig:111` | `.err = "the template module did not compile: …"` |

Decorator host — identical from step 5 on:

| # | Site | What happens |
|---|---|---|
| 1 | `comptime/infer.zig:2266` | `decoratorEval.evaluate(env.arena, ctx.io, ctx.build_root, dfn, handle, plain, …)` |
| 2 | `comptime/decorator_eval.zig:58` `evaluate` → `:69` `buildModule` (`:194`) | one-decl `ast.Program` (`:203-204`) |
| 3 | `comptime/decorator_eval.zig:212` | the same `erlang.emitComptimeModule`, so steps 5–11 above are shared verbatim |
| 4 | `comptime/decorator_eval.zig:89` | `.err = "the decorator module did not compile: …"` |

`step 11` is the whole defect. Everything else is correct.

### Why the typed path gets it right, and what the untyped path actually lacks

On the typed path `plainCallNode:3545` reads `instance_lowerings[loc]`, written by
`comptime/infer.zig:6612` `recordInstanceCall` (call sites `:6435`, `:6527`, `:7054`, `:7067`).
The value is a `envMod.InstanceLowering` (`comptime/env.zig:294`) whose `.prim` payload is a
`PrimKind` — **one of five enum values**, `array | string | bool | int | float`
(`comptime/env.zig:283`). With it, `:3547` calls `primMethodNode` (`:3829`), whose first move
(`:3831`) is `primAnnotationNode` (`:1724`):

1. `primIfaceForKind` (`:1092`) maps the kind to its controller interface (`.string` → `"String"`),
2. `PrimIfaceWalker` (`:1108`) climbs the `extends` chain (`I32 → Signed → Integer → Number`),
3. each step looks up `"<Iface>.<method>"` in `prim_erlang_dispatch`,
4. a hit whose symbol is a `$`-template renders through `templateNode` (`:1553`) →
   `comptime/primOpTemplate.zig`.

For `s.split("")` the entry is `String.split` from `libs/std/src/primitives.bp:121`
(`@External.Erlang("string:split($self, $0, all)")`) and the rendered result is
`string:split(S, <<"">>, all)`.

**The missing information is that single `PrimKind` — not "types" in general.** Both tables the
typed lowering consults are already fully built inside a comptime module:

| Table | Built by | Called from | Present in a comptime module? |
|---|---|---|---|
| `prim_erlang_dispatch` (`<Iface>.<method>` → `@External.Erlang` ref/template) | `collectPrimErlangDispatch` (`codegen/erlang.zig:1601`), which **re-parses the embedded `primitives.bp`** (`:1617-1626`, `comptime/stdlib/prelude.zig:12`) | `codegen/erlang.zig:573`, unconditional | **yes, complete** |
| `prim_iface_chain` (`extends` parents) | `collectIfaceExtendsChain` (`:1635`), same collector | same | **yes, complete** |
| `iface_instance_defaults` (bodied `default fn`s) | `collectInterfaces` (`:1777`) — walks `program.decls` **only**, never the re-parsed prelude | `:556` | **no — empty**, the program is one fn decl |

So there are two gaps, of very different sizes:

- **G1 (the reported failure).** Every host-backed method — the whole `@External.Erlang` surface —
  is one enum value away from lowering correctly. Nothing else is missing.
- **G2 (the tail).** A `default fn` with no `@External.Erlang` annotation (`String.slice`
  `libs/std/src/primitives.bp:165`, `Array.slice` `:572`, `Array.first` `:652`, `Array.all` `:683`,
  `Array.find` `:675`, `Array.count` `:679`, `Array.unique` `:804`, …) additionally has no body in
  the module, because `collectInterfaces` never sees the prelude.

**Threading the caller's map in is not a fix.** `emitComptimeModule` could be given the compiling
module's `ok.instance_lowerings` (the map `codegen/erlang.zig:332` already passes on the ordinary
path), and for an in-module template that would work — the template fn's own body *is* inferred
(`comptime/infer.zig:2746` sets `inTemplateFn` and walks the body like any other fn; nothing gates
`recordInstanceCall` on it). But every reported failure is **cross-module**: `html` lives in
`repository/jhonstart/src/html.bp` and is called from `test/html_test.bp`, and rakun's/onze's
decorators are imported the same way. `registerImportedTemplateFn` (`comptime/infer.zig:3160`) and
`registerImportedDecorator` (`comptime/infer.zig:565`) carry the `FnDecl` across the boundary and
nothing else — the locs in that body belong to a module whose `instanceLowerings` this `Env` never
had. The approach also degrades silently wherever inference bailed on a chain. Rejected.

### The full surface, swept from the lowering

Read off the fallback chain at `codegen/erlang.zig:3565-3571`, not from the failure reports. In a
comptime body `recv.m(args)` lowers to exactly one of:

- the correct host op, if `m` is one of the five names `arrayPrimFallbackNode` (`:3904`) answers;
- `iolist_to_binary(io_lib:format("~p", […]))`, if `m` is `toString` with no arguments (`:3570`);
- otherwise the bare local call `m(Recv, args)` (`:3571`) — which is an `erl_lint`
  `{undefined_function,{m,N}}` **unless the name/arity happens to be an auto-imported Erlang BIF**,
  in which case it lints clean and then misbehaves at runtime.

| Method (receiver) | Declared at `libs/std/src/primitives.bp` | Typed lowering | Untyped result today |
|---|---|---|---|
| `split` (string) | `:121` | `string:split(S, Sep, all)` | `split/2` **undefined** |
| `trim`, `trimStart`, `trimEnd` (string) | `:148`, `:153`, `:157` | `string:trim(S)` | `trim/1` … **undefined** |
| `toUpper` / `toLower` (string) | `:125` / `:130` | `string:uppercase/lowercase(S)` | **undefined** |
| `contains` (string) | `:135` | `(string:find(S, Sub) =/= nomatch)` | `contains/2` **undefined** |
| `startsWith` / `endsWith` (string) | `:139` / `:143` | `(string:prefix(…) =/= nomatch)` / `string:suffix(…)` | **undefined** |
| `replace` (string) | `:161` | `string:replace(S, P, W)` | **undefined** |
| `charAt` / `indexOf` (string) | `:173` / `:177` | `string:slice(S, I)` / `string:str(S, Sub)` | **undefined** |
| `padStart`, `padEnd`, `repeat`, `replaceAll`, `chars`, `lines`, `words`, `charCodeAt`, `lastIndexOf` (string) | `:191`–`:225` | inline `fun`/`binary:` templates | **undefined** (9 methods) |
| `at`, `push`, `pop` (array) | `:560`, `:564`, `:568` | inline `fun` / `($self ++ [$0])` / `lists:last` | `at/2`, `push/2`, `pop/1` **undefined** |
| `join` (array) | `:580` | `iolist_to_binary(lists:join(…))` | `join/2` **undefined** |
| `reverse` (array) | `:584` | `lists:reverse(Xs)` | `reverse/1` **undefined** |
| `indexOf` (array) | `:589` | inline recursive `fun` | **undefined** |
| `map` / `filter` / `zip` (array) | `:597` / `:601` / `:610` | `lists:map` / `lists:filter` / `lists:zipwith` | `map/2`, `filter/2`, `zip/2` **undefined** |
| `isEmpty` / `contains` / `append` / `prepend` (array) | `:642` / `:647` / `:691` / `:699` | `($self =:= [])` / `lists:member` / `($self ++ $0)` / `[$0 \| $self]` | **undefined** |
| `slice` (string **and** array) | `:165`, `:572` | `default fn` body + the `stringSlice0/1` / `arraySlice0/1` prelude helpers (`:230`, `:234`; `preludeHelperNode`, `codegen/erlang.zig:3444`) | `slice/2`, `slice/3` **undefined** — and **G2**: not fixed by a dispatch-table route alone |
| `first`, `rest`, `count`, `all`, `any`, `find`, `flatten`, `flatMap`, `unique`, `chunked`, `sliding`, `findIndex`, `fill`, `some`, `every`, `flat` (array) | `:652`–`:804` | `<Iface>_<method>` local from `instanceDefaultForms` (`codegen/erlang.zig:3884`) | **undefined** — **G2** |
| `forEach`, `fold`, `take`, `drop`, `toList` (array) | `:595`, `:668`, `:660`, `:664`, `:719` | `lists:foreach` / `lists:foldl` / `lists:sublist` / `lists:nthtail` / identity | **resolve**, via `arrayPrimFallbackNode` (`codegen/erlang.zig:3908`, `:3914`, `:3929`, `:3924`, `:3934`) |
| `toString` (any) | `:34`, `:54`, `:182` | `integer_to_binary` / `float_to_binary` / identity | **resolves** to the `~p` format fallback (`codegen/erlang.zig:3570`) — lints, but formats instead of returning the string |
| `length` (string / array), `abs`, `round`, `floor`, `ceil` | `:119`, `:48`, `:70`, `:62`, `:66` | `string:length` / `length` / `abs` / … | **lints clean, silently wrong**: the emitted `length(S)` / `abs(N)` / … are auto-imported BIFs. `s.length()` on a binary raises `badarg` at evaluation time instead of failing the compile |
| `squareRoot` | `:74` | `math:sqrt` | **undefined** |

Three corrections to what the earlier reports said:

1. **"only `.length` resolves" is wrong in both directions.** `.length` resolves only as a *field*
   access — `codegen/erlang.zig:3052-3056` routes an untyped `.len`/`.length` member access to
   `'__bp_len'/2`. As a *call*, `s.length()` falls to `:3571` and emits the BIF `length/1`, which
   lints and then throws `badarg` on a binary. Meanwhile five array methods already resolve
   correctly through `arrayPrimFallbackNode`; that is why `decl.methods.forEach({ … })` works in
   every decorator today and why `codegen/tests/comptime_module.zig:72` passes.
2. **A subset of the failures are runtime-silent, not lint errors.** Any method whose name/arity
   collides with an auto-imported BIF (`length/1`, `abs/1`, `round/1`, `floor/1`, `ceil/1`,
   `float/1`, `size/1`) compiles and misbehaves. These will not appear in any
   `{undefined_function,…}` list and must be fixed by the same change.
3. **`.size` is missing from the untyped member-access branch.** `codegen/erlang.zig:3053` tests
   `len`/`length` while its typed sibling at `:3042` also accepts `size`. One-word fix, same file.

### Blast radius, measured

Counts come from re-linting the generated modules under each repo's
`.botopinkbuild/tmp/{template,decorator}/` directly (`compile:file(…, strong_validation)`).
`botopink check` truncates `erl_lint` detail at 4096 bytes
(`comptime/template_eval.zig:76` `max_error_detail`, applied at `:117-118`; same at
`comptime/decorator_eval.zig:56`, `:95-96`), which is why the earlier report said "26 of 35" —
the last error was clipped.

| Library | Host | Comptime body | Methods used inside | `erl_lint` errors | Residual after this fix |
|---|---|---|---|---|---|
| erika | template | `src/erika.bp:356-591` | `append`×12, `join`×5, `split`×4, `map`×4, `slice`×2 | 36 total, **27** `undefined_function` | **9** `unbound_var`/`unsafe_var` (`OpTok@2`, `LTok@2`, `RTok@2`, `Toks@3` at `:131`, `:134`, `:359`) — a separate case-arm rebinding bug; erika still will not compile |
| jhonstart | template | `src/html.bp:86-259` | `slice`×29, `append`×21, `join`×14, `split`×10, `trim`×6, `indexOf`×2 | 87 total, **82** `undefined_function` | **5** `unbound_var` (`Tokens@2`×2, `Tokens@15`, `CodeStack@1`, `RootMarks@2`) |
| onze | decorator | `src/onze.bp:153-186` | `push`×2, `join`×2, `startsWith`×1 | 5 total, **5** `undefined_function` | **0** — fully unblocked by this fix |
| rakun | decorator | `src/decorators.bp:46-227`, 6 bodied decorators | `join`×16, `push`×6 (`forEach`×20 already works) | **22** predicted, per-module 3/3/3/5/5/3 | `push` is a *mutation* — spec 08 step 2 |
| emilia | none | — | — | 0 | unaffected; 17/17 pass |

Also affected: `repository/erika/examples/erika-linq` reproduces erika's 36/27 exactly, from 6
`erika "…"` sites in `src/main.bp`.

**136 bare-call errors across the ecosystem**, plus 14 residual scoping errors that are a
different defect.

Two facts the earlier text did not have:

- **`check` is green while `test` is red** for jhonstart and onze: the template/decorator only
  lowers at a *call site*, and `cli/check.zig:23` loads `src/` only. A CI gate on `check` alone
  misses the whole class.
- `contains`, `at`, `reverse` and `toUpper` appear in no library comptime body today — they are
  latent, not observed. Every observed failure is one of
  `append`, `join`, `split`, `slice`, `map`, `trim`, `indexOf`, `push`, `startsWith`.
- rakun never reaches evaluation: `botopink.json` declares `"dependencies": ["server"]` and no
  such library exists under the libs root (`cli/check.zig:40`). Its 22 errors are latent behind
  that — see spec 08 step 7.

### Why the failure is unreadable

`comptime.zig:76` `ComptimeOutput.outcome` carries the full `TypeError`, but every backend drops
it: `codegen/erlang.zig:317-318`, `codegen/commonJS.zig:54-55`, `codegen/beam_asm.zig:414-415`,
`codegen/wat.zig:160-161` all `continue` on `.parseError` and `.typeError`, so the module produces
no `ModuleOutput` at all. `cli/test_cmd.zig:136-145` can only render a `comptime_err`, which only
the `.validationError` arm ever sets (`codegen/erlang.zig:319-329`); the template failure lands in
the `outputs.items.len < modules.len` arm (`cli/test_cmd.zig:148-156`), whose message points at
`botopink check` — which loads `src` only (`cli/check.zig:23`). The diagnostic exists and is thrown
away three times.

---

## Steps

### Step 1 — Primitive methods reachable from a comptime body

Make the untyped path resolve a primitive method through the same table the typed path uses.

**Fix options.**

**(a) A per-method runtime-dispatch shim, generated from the typed table.** At
`codegen/erlang.zig:3571`, when `this.untyped`, record `(callee, argc)` in a
`needed_untyped_prim_shims` set and emit `'__bp_prim_<callee>'(Recv, A0…An)` instead of the bare
call. Then emit one form per reached `(callee, argc)`: one clause per `PrimKind` that has a
`prim_erlang_dispatch` entry for the method, guarded by `is_binary/1` (string), `is_list/1`
(array), `is_boolean/1` (bool), `is_integer/1` (int), `is_float/1` (float), plus a final clause
that raises a readable error. Erlang's runtime types separate the five kinds cleanly, which is
exactly the trick `'__bp_len'/2` (`codegen/erlang.zig:406-424`) already plays.

Each clause body is produced by calling `primMethodNode` (`:3829`) itself with a synthetic
receiver identifier and synthetic argument identifiers — so the shim body *is* the typed path's
output and no lowering logic is duplicated.

- **Cost:** one collector plus one form emitter of roughly the size of `instanceDefaultForms`
  (`:3884`), one branch at `:3571`, and synthetic `ast.Expr`/`ast.Loc` construction (safe here:
  `rewrites` and `instance_lowerings` are both empty, so a synthetic loc cannot collide).
- **Covers:** every method carrying an `@External.Erlang` annotation — i.e. all of **G1** — and,
  because `primMethodNode` also runs `arrayPrimFallbackNode` (`:3845`) and `ifaceDefaultNode`
  (`:3849`), the **G2** tail too, for free and only for the methods actually reached.
- **Breaks:** nothing structurally. The failure mode moves from "`erl_lint` rejects the module" to
  "the shim's last clause raises at evaluation time on a receiver of an unexpected type", which is
  what `'__bp_add'`/`'__bp_len'` already do.
- **Interaction with `instanceDefaultForms`:** a shim clause reaching `ifaceDefaultNode` writes to
  `needed_instance_defaults` (`:3871`). Shim generation must therefore run **before** the drain at
  `:803`, or that drain must be re-entered. The shim generator must also save/set/restore
  `self_prim_kind` per clause the way `instanceDefaultForms` does at `:3897`, so a default body's
  `self.x()` resolves through `selfPrimKind` (`:3565`).
- **`COMPTIME ERLANG` snapshots:** a listing renders `forms.items[decls_start + 1 ..]`
  (`codegen/erlang.zig:851`) and skips the helper block behind `if (!cm.listing)` (`:806`), so
  shims emitted inside that gate never appear in a section. The *call sites* do move
  (`split(…)` → `'__bp_prim_split'(…)`) — but see the snapshot note below: **no existing section
  contains a primitive method call, so none changes.**

**(b) Emit the reached `default fn` bodies (the untyped analogue of `instanceDefaultForms`).**

- **Cost:** needs the same missing `PrimKind` to pick the interface, *and* `iface_instance_defaults`
  populated from the embedded prelude. `collectInterfaces` (`:1777`) reads `program.decls` only;
  extending it to the re-parse at `:1614-1621` means deep-copying whole `ast.InterfaceMethod`
  bodies out of that throwaway arena (today only three strings per entry are copied) or keeping the
  arena alive for the emit.
- **Does not cover G1 at all.** `String.split`, `Array.join`, `Array.map` are bodyless `fn`s — there
  is no body to emit. So (b) alone does not fix the reported failure.
- **Reintroduces the bug inside its own output.** `Array.append`'s body
  (`libs/std/src/primitives.bp:693-697`) is `var out = self.slice(…); other.forEach({ y -> out.push(y); })`
  — `out` is a local, not `self`, so `selfPrimKind` cannot help it, and `push` on a local is the
  discarded-mutation defect of spec 08 step 2.
- **`COMPTIME ERLANG` snapshots:** `instanceDefaultForms` is emitted at `:803`, *above* the
  `cm.listing` gate and after `decls_start` (`:851`), so every body it adds **does** land in the
  listing. Harmless today only because no existing fixture reaches a default; structurally it means
  every future default-fn body shows up in the snapshot of any body that touches it.
- **Verdict:** required as a complement for the G2 tail, wrong as the mechanism. Under (a) it is
  reached automatically and only for what is used.

**(c) Extend the comptime prelude by hand (`comptime_helper_forms`, `codegen/erlang.zig:389`).**

- **Cost:** hand-transcribe ~40 methods × up to 5 kinds of Erlang clauses, duplicating
  `libs/std/src/primitives.bp` in Zig. Two sources of truth that will drift: every new
  `@External.Erlang` annotation needs a matching Zig edit. The templates are not trivial —
  `padStart` (`:191`) is a one-line `fun` over `binary:first`, `lastIndexOf` (`:223`) a recursive
  `fun` — and transcription is where the bugs go.
- **Breaks:** nothing, and it needs no interaction with `instanceDefaultForms`. Snapshots are
  untouched (same `!cm.listing` gate at `:806`), though every comptime module grows by the full
  prelude unless it is gated on reached names — which is (a)'s collector anyway.
- **Verdict:** the escape hatch if the milestone needs the six jhonstart names today; not the fix.

**Recommendation: (a), with (b) reached through it; keep (c) off the table.** (a) is the only
option in which `libs/std/src/primitives.bp` stays the single source of truth, it adds no new
lowering logic (the shim body is `primMethodNode`'s own output), it extends the
`'__bp_add'`/`'__bp_len'` precedent the module already carries, and its forms sit behind the
`cm.listing` gate so no green `COMPTIME ERLANG` section moves.

Fix `codegen/erlang.zig:3053` (`size`) in the same change.

**Snapshot coverage, measured.** There are 36 `COMPTIME ERLANG` sections, one per file, across
`snapshots/comptime/{node,erlang,beam,wasm}/` (5 files each) and
`snapshots/codegen/{commonJS,erlang,beam,wasm}/` (4 files each); the four backend copies of a
fixture are byte-identical by design (`comptime/tests/helpers.zig:127-132`). Backing tests:
`comptime/tests/templates.zig:408, 420, 438, 480, 818` and `codegen/tests/comptime.zig:318, 357,
408, 426`.

- **Not one of the 36 sections contains a primitive method call.** Every fixture body uses only
  the `@Expr` host API (`q.text()`, `q.build()`, `q.parts()`, `q.lookup()`, `q.fail()`,
  `@expr(…)`) plus string `+`. So under any option the existing suite stays byte-identical, and
  the whole surface this spec is about has **zero** snapshot coverage.
- **There is no decorator `COMPTIME ERLANG` section at all** (0 of 36) — the host onze and rakun
  depend on entirely has no Erlang-output snapshot. Adding one fixture means 4 new files (one per
  backend directory), never an edit to an existing one.

**Acceptance:**
- [ ] A template body and a decorator body may call any primitive method the typed path supports —
      the same `prim_erlang_dispatch` entry answers both
- [ ] `split`, `join`, `slice`, `indexOf`, `append`, `trim`, `map`, `at`, `contains`, `reverse`,
      `toUpper`, `startsWith` evaluate from a comptime body on a string or an array receiver
- [ ] A method whose name collides with an auto-imported BIF (`length`, `abs`, `round`, `floor`,
      `ceil`, `size`) dispatches on the receiver instead of calling the BIF
- [ ] An unsupported method raises a located comptime error instead of `{undefined_function,…}`
- [ ] `repository/onze` `botopink test` passes (0 residual errors); `repository/jhonstart` is down
      to its 5 `unbound_var` errors and `repository/erika` to its 9 — both then tracked as the
      case-arm rebinding defect, not here
- [ ] Regression tests in `codegen/tests/comptime_module.zig` (next to `:52`, which pins
      `'__bp_add'`/`'__bp_len'`), covering **both** hosts, so this does not depend on a sibling repo
      being checked out
- [ ] A new fixture adds the first decorator `COMPTIME ERLANG` section (4 files, one per backend
      directory)
- [ ] The 36 existing `COMPTIME ERLANG` sections are unchanged

### Step 2 — A failing test module must say why

The diagnostic exists and is discarded three times (see *Why the failure is unreadable*). Carry
`ComptimeOutput.outcome.typeError` (`comptime.zig:76`) through codegen the way `.validationError`
already is (`codegen/erlang.zig:319-329`), so `cli/test_cmd.zig:136-145` can render it, and either
make `cli/check.zig:23` load `test/` too or stop pointing at it.

**Acceptance:**
- [ ] `botopink test` prints the located diagnostic of the module that failed, not a count
- [ ] All four backends carry a `.typeError` through instead of `continue`
- [ ] `botopink check` covers `test/` too, or its message stops naming a command that does not look
      there

### Step 3 — The gate must include the libraries

`zig build test` never compiles a `.bp` library, so a compiler change can break every library and
stay green. `zig build test-libs` exists and is part of no wave's gate; the sibling repos'
pre-commit hooks are the only thing that noticed.

**Acceptance:**
- [ ] The gate documented in `AGENTS.md` (and used by every task) is
      `zig build test && zig build test-libs`
- [ ] `test-libs` covers `libs/std` and the sibling libraries that are checked out, and says which
      it skipped
- [ ] CI runs it on the same matrix as `test`, with the sibling repos checked out

## Notes

- The sibling pre-commit hook blocks any commit in `repository/jhonstart` while this is open —
  including unrelated maintenance (an ignore rule for `out/` is waiting on it).
- The whole untyped fix rests on the `primitives.bp` re-parse at `codegen/erlang.zig:1617-1620`
  succeeding; both `scanAll` and `parse` there are `catch return`, so a parse regression in
  `libs/std/src/primitives.bp` would silently empty the dispatch table for **every** module, typed
  and untyped. Worth a test that asserts the table is non-empty.
- Spec 08 step 1 is the same defect seen from the library side; step 2 there is the reason
  defining `push/2` does not by itself unblock rakun.
- Related: spec 05 of 1.0.1-beta lists the hook installation and `test-libs` wiring problems
  (5.2, 5.4, 5.5).
