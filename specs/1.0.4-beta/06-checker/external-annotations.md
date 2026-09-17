# `#[@External.<Target>(…)]` — forms, traps and a rule per situation

> Carried from `1.0.2-beta/03-std-surface/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F12` and bare front numbers are the old numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).
>
> **Reference.** The `libs/std` rewrite it recommends, the commonJS helper registry (C5, commonJS half)
> and the template-import fix (C3) landed with 1.0.2-beta std-surface; C2 with cli-gate; C9 with
> comptime-dispatch. Its compiler-work rows C1 and C8 name the checker — see
> [`README.md`](./README.md) Notes. The other rows belong to the fronts named in the Owner column
> (old numbering). The deep dives it cites (`node-externals.md`, `blockers.md`, `surface.md`) were
> deleted with their front.

A design review of how `libs/std` binds host functionality. It does not repeat
`node-externals.md` (1.0.2-beta std-surface, landed) (the 22 `./gleam_stdlib.mjs` rows and the shipping
decision), `blockers.md` (1.0.2-beta std-surface, landed) §6d (the import emitter) or
`surface.md` (1.0.2-beta std-surface, landed) §E3 (`string:suffix/2`); it generalises them into one rule per case so
`libs/std` can be rewritten without deciding each declaration on its own.

Paths are relative to `repository/botopink-lang/` unless stated otherwise. `file:line` is at HEAD.

**Measured** = compiled with `zig-out/bin/botopink` (built from the working tree two minutes before
HEAD's last commit, `fix(wasm): trap on a call the backend cannot lower`; the binary already carries
that change) against scratch projects, then **run**: `node` for commonJS, `erlc` + `erl` for
erlang, `erlc +from_asm` + `erl` for beam, `wasmtime run` for wasm. The primitive table (§4) is 85
single-call programs × 4 targets. **Inferred** = read from source, not executed; marked as such.

---

## 1. The forms that exist

### Inventory

377 annotations on 215 declarations, counted by parsing every `#[…]` block in `libs/std/src` and
`repository/{emilia,erika,jhonstart,onze,rakun}` (comments excluded).

| | `libs/std` | emilia | erika | jhonstart | onze | rakun | total |
|---|---|---|---|---|---|---|---|
| declarations | 186 | 3 | 0 | 3 | 8 | 15 | **215** |
| annotations | 348 | 3 | 0 | 3 | 8 | 15 | **377** |

**Targets per declaration:** 1 target 84 (std 55: `erlang.bp` 48, 4 erlang-only and 3 node-only
`default fn`s in `primitives.bp`; siblings 29, all node) · 2 targets (node + erlang) 100 · 3 targets
(node + erlang + beam) 31. **No `@External.Wasm` or `@External.Typescript` anywhere.**

**Where it sits:**

| Position | Count | Validated? (measured) |
|---|---|---|
| top-level `declare fn` | 161 (std 135, emilia 3, onze 8, rakun 15) | yes — `comptime/infer.zig:2072` |
| interface method without body (`fn m(self: Self) -> T`, `primitives.bp`) | 43 | **no** — an unknown target, 4 args and non-string args all check clean |
| interface `default fn` with body | 8 (`negate`, `toString`, `isEmpty`, `contains`, `find`, `append`, `prepend`, `flatMap`) | **no** |
| bodyless `pub fn` in a `.d.bp` (`jhonstart/src/router.d.bp:26,29`, `server.d.bp:27`) | 3 | not compiled — no `mod` reaches them; module `"jhonstart/runtime"` exists nowhere |
| record method | 0 | parses and is **silently ignored** (measured) |
| `extend`/`implement` method, record `declare fn` | 0 | parse error (measured) |

**Shapes, per target:**

| Shape | node | erlang | beam | Where |
|---|---|---|---|---|
| 2-arg module + symbol, host global / OTP module (`("Math", "floor")`, `("lists", "reverse")`) | 33 | 100 | 26 | `math.bp` 22×3, `erlang.bp` 48, `primitives.bp` 23 erlang + 8 node |
| 2-arg module + symbol, **relative file** (`("./gleam_stdlib.mjs", "split")`) | 45 | — | — | std 22, rakun 15, onze 8 |
| 2-arg module + symbol, package path (`("jhonstart/runtime", "link")`) | 3 | — | — | jhonstart |
| 2-arg module + `symbol(args)` reorder (`("lists", "map(transform, self)")`) | — | 3 | — | `Array.forEach/map/filter` |
| 1-arg, no `$`, on an interface method = native method name (`"toUpperCase"`) | 16 | — | — | `primitives.bp` |
| 1-arg, no `$`, on a `declare fn` = bare host expression (`"process.cwd()"`) | 13 | 12 | — | `env` 2, `os` 6, `process` 4, `random` 1 |
| 1-arg template with `$` markers | 50 | 68 | — | 45 node + 46 erlang on `declare fn`, the rest on interface methods |
| 1-arg BEAM `.S` template (`"""    {call_ext, 1, …}."""`) | — | — | 5 | `toUpper`, `toLower`, `endsWith`, `trim`, `reverse` |
| `when(argc == N): "…"` arity branch | 3 | — | — | emilia, one branch each |

**Markers** (annotations containing one): `$N` 138 · `$self` 31 · `$args` 6 (only `builtins.d.bp`
`print`/`println`/`debug`) · `$stringify` 1 (`Array.join`, erlang). Triple-quoted `"""…"""` 91.
Same marker twice in one template 6 (`stringSlice1`, `arraySlice1`, `zip` ×2, `regex.match`,
`regex.matchAll`). `inline:` flag 0.

**Spellings:** `@External.<Target>` 368 · `External.<Target>` without `@` 6 (`builtins.d.bp:5-14`,
a file no collector parses successfully — its three entries are re-typed by hand at
`codegen/commonJS.zig:902` and `codegen/erlang.zig:1440`) · `@External.node` lowercase target 3
(emilia; works, the match is case-insensitive). Lowercase `@external(node, …)`: **0 in `.bp`, 73
times in compiler comments/doc strings** plus `codegen/AGENTS.md`.

---

## 2. What each form compiles to

### The reader

Every backend reads the annotation through `ast.zig` — `FnDecl.externalFor` (`:1794`) and
`InterfaceMethod.externalFor` (`:1097`): match `a.name` starting with `External.` and the target
case-insensitively, drop a trailing `true`/`false`, then **1 arg → `{module: "", symbol}`, 2 args →
`{module, symbol}`, anything else → null**. `when(argc == N)` args are read separately
(`externalHasArityBranches` `:1321`, `externalArityBranchFor` `:1336`). Whether a symbol is a
template is decided by one byte: `primOpTemplate.looksLikeTemplate` (`comptime/primOpTemplate.zig:41`)
= "contains `$`". The target key is `node` for commonJS, **`erlang` for both erlang and beam**, `wasm`
for wasm (`codegen.zig:29-33`) — used only by STD-001 (`comptime/infer.zig:87-103`).

### Top-level `declare fn` (user code or a std module)

Measured with one scratch program per shape; "result" is the printed value.

| Shape | commonJS | erlang | beam | wasm |
|---|---|---|---|---|
| `("Math", "floor")` / `("math", "floor")` | `const flo = Math.floor;` · `1` | no decl, `math:floor(1.5)` · `1.0` | local stub `flo/1` returning `ok` · **`ok`** | `;; declare fn flo — no wasm implementation` + `unreachable` · trap |
| `("./helper.mjs", "member")` | `const { member } = require("./helper.mjs");` at module top — **emitted and loaded even when never called** (an unused one aborts with `Cannot find module`) | — | stub · `ok` | trap |
| `("lists", "member(x, xs)")` reorder | — | **`lists:member(x, xs)([1, 2], 2)`** — erlc syntax error; the reorder form is only understood on interface methods | stub · `ok` | trap |
| 1-arg, no `$` (`"Date.now()"`) | **`const { Date.now(): now } = require("");`** — SyntaxError (6d) | **`:erlang:system_time()()`** — erlc syntax error | stub · `ok` | trap |
| template `"($0.length + $1)"` | inline at the call site, `(("ab" + "cd").length + 1)` · `5` | inline, `(byte_size(<<"abcd">>) + 1)` · `5` | stub · `ok` | trap |
| template `"Math.max($args)"` | `Math.max(1, 9, 3)` · `9` | `lists:max([1, 9, 3])` · `9` | stub · `ok` | trap |
| template using `$self` | build fails: bare `PrimOpRecvInUserTemplate`, no location; `check` is clean | same | stub | trap |
| template `$2` on a 1-param fn | build fails: bare `PrimOpArgIndexOutOfRange`; `check` is clean | same | stub | trap |
| template with `$0` twice, arg `next()` | `next()` runs **twice** | runs **twice** | — | — |
| two `when(argc == N)` branches | the branch for the call's argc · ok | same · ok | stub | trap |
| three `when(argc == N)` branches | `check`: "`@external` expects 1 or 2 arguments" — branches are counted as args (`infer.zig:2098`) | same | — | — |

Code: commonJS `collectExternals` `codegen/commonJS.zig:980` → `buildFnItem` `:1125` (alias/require)
or `renderDispatch` `:2620` (template); erlang `collectExternals` `codegen/erlang.zig:2181` →
`plainCallNode` `:3430` / `userTemplateNode` `:1765`; beam has **no declare-fn reader at all** (the
empty body lowers to `ok`; this is [`../01-beam/`](../01-beam/README.md) B2); wat skips the
declaration at `codegen/wat.zig:1059-1064` and traps at the call (`:3038`).

**Cross-module (a std module's external, called as `math.abs(x)`):** measured with
`import {os, process, math} from "std"`.

| | commonJS | erlang | beam | wasm |
|---|---|---|---|---|
| owner module | `std/math.js` aliases and exports `floor` | `std/math.erl` emits **no function** for an external (`-module(math)`, the OTP name) | `std/math.S` stub `ok` | `main.wat` **not written**, `build` exits 0 (inferred: STD-001) |
| `math.floor(2.5)` | ok | `math:floor` → **OTP's** `math:floor` · `2.0` — right by name coincidence | `call_ext math:floor` · OTP · right by coincidence | — |
| `math.abs(-2.5)`, `os.cpuCount()`, `process.pid()` | `math.abs` ok (`std/math.js` aliases `Math.abs`); `os.js` SyntaxError (6d) | **undef** — OTP `math`/`os` have no such function, the std owner defines none | undef | — |

### Interface methods on primitives (`primitives.bp`)

Receiver calls are dispatched by type through `instance_lowerings`; the annotation is looked up by
`<Interface>.<method>`, walking `extends`.

| Shape | commonJS (`buildInterface` `:1296`, `buildCall` `:2654`) | erlang (`collectIfaceErlangDispatch` `:1649`, `primAnnotationNode` `:1724`) | beam (`collectIfaceErlangDispatch` `:856`, `tryEmitPrimAnnotation` `:2594`) | wasm |
|---|---|---|---|---|
| 2-arg host global `("Math", "abs")` | `Number.prototype.abs = function(){ return Math.abs(this.valueOf()); }` (`:1431`) | `erlang:abs(N)` | `call_ext` when the args are simple and the receiver is **Array/String/Bool** — numeric kinds map to nothing (`primIfaceForKind` `beam_asm.zig:61`) | ignored |
| 2-arg relative file | **skipped** (`:1431` and `infer.zig:6678` `findInterfaceDefaultFn`); the call emits verbatim and the native JS method of the same name runs | — | — | ignored |
| 1-arg native name `"toUpperCase"` | call-site rename (`prim_node_renames` `:954`, `infer.zig:6647`); no patch | — | — | ignored |
| 1-arg template | **prototype patch** rendering the template (`:1385`) | inline template (`templateNode` `:1553`) — but the text is stored raw (`:1699`), not through `dupeTemplate` (`:2169`) as declare fns are | **ignored** — templates fall through to the inline switch (`:2616`) | ignored |
| `symbol(args)` reorder | — | args reordered | reorder → `call_ext` (`:2617-2640`) | ignored |
| `.S` template | — | — | rendered verbatim after pre-loading x-registers (`renderBeamTemplate` `:2666`); wins over everything | — |
| `default fn` body, no annotation for the target | **prototype patch** with the body (`:1402`) | local `<iface>_<method>` form **emitted only if a call reached it** (`instanceDefaultForms` `:3884`) | not lowered — `%% unresolved method call` (`:2436`), the receiver is the value | ignored |
| `default fn` + annotation for the target | node 1-arg name → no patch, native; erlang template/mod:sym → annotation wins over the body | | | |

**commonJS emits the whole interface's patch block when any one member needs it** (measured):
`xs.first()` alone writes 25 `Array.prototype.*`/`Array.*` assignments, `s.slice(1, 3)` 5 on
`String.prototype`, `n.min(3)` 3 on `Number.prototype`.

**The comptime path.** A template or decorator body is lowered by `emitComptimeModule`
(`codegen/erlang.zig:484`) with an empty `instance_lowerings` (`:494`), so **no primitive annotation
is consulted**: `t.toUpper()`, `t.padStart(…)`, `t.split(…)`, `t.chars()`, `t.slice(…)` in a template
body all fail `erl_lint` with `undefined_function` (measured). A user `declare fn` with only a Node
binding called from a template body fails the same way (`{undefined_function,{upNode,1}}`,
measured). The primitive half is `comptime-dispatch` (1.0.2-beta, landed)
step 1; the rule that follows from it — only an Erlang binding can ever run at compile time — is in
§6.

---

## 3. The traps

Each row: what the author expected, what happens (measured), how the compiler could refuse it.
Refusals only become visible once `botopink build` stops exiting 0 with no output on a type error —
measured: a `check`-time rejection makes `build` print `Compiled` and write nothing
([`../05-cli-residuals/`](../05-cli-residuals/README.md)).

| # | Trap | Expected | What happens | Refuse by |
|---|---|---|---|---|
| T1 | Lowercase `#[@external(node, "Math", "floor")] declare fn flo(…)` | a host binding (the form 73 compiler comments still teach) | **`check` clean; `flo` compiles to an empty function** — `function flo(n) {}` / `flo(N) -> undefined.` — and prints `undefined`. `externalFor` requires the name `External.` (`ast.zig:1796`), and a `declare fn` with no recognised annotation is an ordinary empty fn | Reject any annotation whose name is `external` (any case) or starts with `External.` but is not `External.<Target>`; reject a top-level `declare fn` that has neither a body nor a recognised host binding |
| T2 | Relative-file module on an interface method (`("./gleam_stdlib.mjs", "starts_with")`) | the Gleam function runs | skipped by the emitter (`commonJS.zig:1431`) and inference (`infer.zig:6678`); the native JS method of the same name runs. Harmless only by accident: `charAt` returns `""` where the signature says `?string`, and no other target sees the intent | Refuse a relative module on an interface method (there is no receiver slot to bind it) |
| T3 | `default fn slice` whose body calls host-bound `stringSlice0/1` (`primitives.bp:165-171`, `:572-578`) | botopink `slice` for every target | commonJS replaces **`String.prototype.slice` and `Array.prototype.slice`** with a body that requires the missing file. Measured side effects: `rest`/`take`/`drop`/`zip` crash (their bodies call `.slice`), and so does **any** `[1,2,3].slice(1)` in the same process, including code the program did not write | Stop patching prototypes (rule R1): a default fn lowers to a module-local function called by static dispatch, as `implement`/`extend` already do (`buildExtensionNamespace` `:1496`) |
| T4 | Template on an interface method that calls the native method of **the same name** (`charCodeAt`: `"(($self.charCodeAt($0) ?? -1) \| 0)"`, `primitives.bp:219`) | wrap the native call | the patch calls itself: `"abc".charCodeAt(0)` → `RangeError: Maximum call stack size exceeded`. Because the block is all-or-nothing (§2), a program that only calls `s.chars()` crashes the same way | Same fix as T3; until then refuse a Node template on method `m` that contains `.m(` |
| T5 | Default bodies that shadow a native with different semantics (`fill`, `every`, `some`, `flat`, `findIndex`) | botopink versions of the methods | measured: after the block, native `a.fill(0)` no longer mutates `a`; 17 patched names become **enumerable** — `for (k in [7])` yields 18 keys | Same fix as T3 |
| T6 | Non-raw template with a `\` escape (`lines`: `"$self.split(/\\r?\\n/)"`, `words`) | the regex `/\r?\n/` | commonJS writes the raw lexeme → `/\\r?\\n/` → `["a\nb"]` unsplit; erlang interface path stores it raw (`erlang.zig:1699`) → `<<\"\\n\">>` → **erlc: unterminated string**. `declare fn` templates resolve `\"` only (`dupeTemplate` `:2169`) | Require `"""…"""` for any template, or reject `\` in a non-raw template string |
| T7 | 1-arg annotation with no `$` on a `declare fn` (`"process.cwd()"`, `"require('os').hostname()"`, `"list_to_integer(os:getpid())"`) — 13 node, 12 erlang | a host expression | `$`-presence decides "template" (`primOpTemplate.zig:41`), so these become an alias: commonJS `const { process.cwd(): cwd } = require("")` (6d), erlang `:erlang:system_time()()`. `env`, `os`, `process`, `random` do not load/compile | On a `declare fn`, a 1-arg annotation is always rendered at the call site — decide by declaration kind and arg count, not by `$` |
| T8 | `$self` in a top-level `declare fn` template | the first argument | erlang renders it as the first argument **only** for a `primitives.bp` helper called from a default body (`preludeHelperNode` `:1528`); a user `declare fn` fails the build with bare `PrimOpRecvInUserTemplate`; commonJS always fails | Reject `$self` outside interface methods at check time, with a location |
| T9 | Same marker twice (`$0` in `stringSlice1`, `arraySlice1`, `regex.match`; `$self`/`$0` twice in `zip`) | one evaluation | the argument expression is substituted twice: `dbl(next())` prints the side effect **twice** on commonJS and erlang | Reject (or warn on) a repeated marker; the author binds once (`(fun(X) -> … end)($0)`, `(x => …)($0)`) |
| T10 | Erlang `symbol(args)` reorder on a `declare fn` | argument reordering | `lists:member(x, xs)([1, 2], 2)` — erlc syntax error | Refuse the form outside interface methods (then delete it, §6) |
| T11 | Annotations on interface methods / record methods with a wrong target or arity (`@External.Nodee("a","b","c")`, `@External.Erlang(1,2,3,4)`) | a check error, as on `declare fn` | `check` clean; ignored | Run `validateExternalAnnotation` (`infer.zig:2072`) on every annotated declaration kind |
| T12 | `@External.Wasm("…")` / `@External.Typescript("…")` | a wasm binding | accepted by `check` (they are enum members, `builtins.d.bp:164-170`), read by nothing; wasm traps at the call | Reject a target no backend reads, until one does |
| T13 | An Erlang binding naming a function OTP does not have | a host call | runs until called: `string:suffix/2`, **`math:round/1`**, `string:str/2` on a binary (`function_clause`) — measured | A table of OTP `{module, fun, arity}` checked at build, or a test per binding (rule R5) |
| T14 | A declaration with an Erlang binding only, on beam | the Erlang call | beam reads no `declare fn` external: local fn returning `ok` (B2). STD-001 gates beam on the `erlang` key (`codegen.zig:31`), so it passes | beam derives `call_ext` from the Erlang 2-arg form, and STD-001 gates on what beam can actually lower |
| T15 | Array/String/numeric method with no beam lowering | the call | `%% unresolved method call` — the receiver becomes the value; 55 of 85 calls in §4 | Fail the lowering (B4's "or each remaining one…") |

---

## 4. Coverage per target

One program per call, receiver bound with `val` (`s = "Hello World"`, `sp = "  hi  "`,
`xs = [3, 1, 2]`, `n = -7`, `f = 2.5`, …), built and **run** on each target.

**Legend.** Form: `mod:sym` 2-arg host module · `rel` 2-arg `./gleam_stdlib.mjs` (inert on
interfaces, T2) · `name` 1-arg native name · `tmpl` template · `iife` template that wraps a whole
algorithm in an applied fun · `reorder` `symbol(args)` · `.S` beam template · `body` `default fn`
body · `patch` commonJS prototype patch · `switch` beam inline switch · `helper` synthesized
helper. Outcome: `ok` · **WRONG** · **CRASH** (runtime) · **ERLC** (does not compile) · **SILENT**
(beam `%%` marker, receiver returned) · **TRAP** (wasm `unreachable`).

### Totals

| | ok | WRONG | divergent¹ | CRASH / ERLC | SILENT | TRAP |
|---|---|---|---|---|---|---|
| commonJS | 68 | 3 | 1 | 13 | — | — |
| erlang | 64 | 6 | 1 | 14 | — | — |
| beam | 22 | 4 | 1 | 3 | 55 | — |
| wasm | 3 | 3 | — | — | — | 79 |

¹ `xs.push(9)`: node mutates and returns `4`; erlang/beam return the new list and mutate nothing.

### `String` (`primitives.bp:116-226`)

| Method | node | erlang | beam | wasm |
|---|---|---|---|---|
| `length` | `rel` → `.length` prop · ok | `mod:sym` · ok | `call_ext` · ok | native · ok |
| `split` | `rel` → native · ok | `tmpl` · ok | `switch` "complex arg" · SILENT | TRAP |
| `toUpper` / `toLower` | `name` rename · ok | `mod:sym` · ok | `.S` · ok | TRAP |
| `contains` | `name` `includes` · ok | `tmpl` · ok | `switch` · ok | TRAP |
| `startsWith` | `rel` → native · ok | `tmpl` · ok | `switch` · ok | TRAP |
| `endsWith` | `rel` → native · ok | `mod:sym string:suffix` · **CRASH undef** | `.S` same · **CRASH undef** | TRAP |
| `trim` | `rel` → native · ok | `mod:sym` · ok | `.S` · ok | TRAP |
| `trimStart` / `trimEnd` | `rel` → native · ok | `mod:sym string:trim` · **WRONG** both ends | `call_ext` · **WRONG** | TRAP |
| `replace` | `rel` → native (first) · ok | `mod:sym string:replace` · **WRONG** iolist `[<<"He">>,<<"L">>,…]` | SILENT | TRAP |
| `slice` | `body` → `patch` · **CRASH** gleam | `body` + prelude template · ok | SILENT | wat helper `$__str_slice` · ok |
| `charAt(1)` / `charAt(99)` | `rel` → native · ok / **WRONG** `""` for `?string` | `mod:sym string:slice/2` · **WRONG** rest of string / `<<>>` | same · **WRONG** | TRAP |
| `indexOf` (hit / miss) | `rel` → native · ok | `mod:sym string:str` · **CRASH** function_clause | SILENT | TRAP |
| `toString` (default) | `name` → native · ok | `body` · ok | SILENT (coincides) | TRAP |
| `padStart` / `padEnd` | `name` · ok | `iife` · ok | SILENT (`<<>>`) | TRAP |
| `repeat` | `name` · ok | `tmpl` · ok | SILENT | TRAP |
| `replaceAll` | `name` · ok | `iife` · ok | SILENT | TRAP |
| `chars` | `tmpl` → `patch` · **CRASH** RangeError (T4) | `tmpl` · ok | SILENT | TRAP |
| `lines` / `words` | `tmpl` → `patch` · **WRONG** unsplit (T6) | `tmpl` · **ERLC** (T6) | SILENT | TRAP |
| `charCodeAt` | `tmpl` → `patch` · **CRASH** RangeError (T4) | `iife` · ok | SILENT | TRAP |
| `lastIndexOf` | `name` · ok | `iife` · ok | SILENT | TRAP |

### `Array` (`primitives.bp:555-823`)

| Method | node | erlang | beam | wasm |
|---|---|---|---|---|
| `length` | property · ok | `length/1` · ok | `gc_bif` · ok | **WRONG** `0` |
| `at(0)` / `at(9)` | `rel` → native · ok | `iife` · ok | `helper` (`ensureAtHelper` `:2978`) · ok | `$__arr_at` · ok / **WRONG** `0` |
| `push` | `rel` → native · divergent¹ | `tmpl` · divergent¹ | `switch` · divergent¹ | TRAP |
| `pop` | `rel` → native (mutates) · ok | `mod:sym lists:last` · ok | `call_ext` · ok | TRAP |
| `slice(1, 2)` | `body` → `patch` · **CRASH** gleam | `body` + prelude template · ok | `switch` · ok | `$__str_slice` by callee name · **WRONG** |
| `join` | `rel` → native · ok | `tmpl` + `$stringify` · ok | `helper` · ok | TRAP |
| `reverse` | `name` · ok | `mod:sym` · ok | `.S` · ok | TRAP |
| `indexOf` | `rel` → native · ok | `iife` · ok | `helper` · ok | TRAP |
| `forEach` / `map` / `filter` | `rel` → native · ok | `reorder` · ok | `reorder` → `call_ext` · ok | TRAP |
| `zip` | `tmpl` → `patch` · **CRASH** (calls the patched `slice`) | `tmpl` · ok | SILENT | TRAP |
| `Array.range` / `Array.repeat` | `body` · **CRASH** not a function | `body` · **CRASH** `array:range` undef (OTP `array`) | **CRASH** undef | TRAP |
| `isEmpty` / `contains` / `prepend` | `body` → `patch` · ok | `tmpl` · ok | `switch` · ok | TRAP |
| `append` | `name` `concat` · ok | `tmpl` · ok | `switch` · ok | TRAP |
| `first` | `body` → `patch` · ok | `body` · ok | SILENT (whole list) | TRAP |
| `rest` / `take` / `drop` | `body` → `patch` · **CRASH** gleam (via `slice`) | `body` / fallback · ok | SILENT | TRAP |
| `fold` `count` `all` `any` `some` `every` `findIndex` | `body` → `patch` · ok | `body` · ok | SILENT | TRAP |
| `find` / `flatMap` | `name` · ok | `body` · ok / **ERLC** `flatten/1` undefined | SILENT | TRAP |
| `flatten` / `flat` | `body` → `patch` · ok | `body` · **ERLC** `append/2` undefined | SILENT | TRAP |
| `toList` | `body` → `patch` · ok | inline · ok | SILENT (coincides) | TRAP |
| `fill` | `body` → `patch` · ok, native `fill` replaced (T5) | `body` · ok | SILENT | TRAP |
| `chunked` / `sliding` | `body` → `patch` · **CRASH** at `while_(…)` | `body` · **ERLC** `while/2` undefined | SILENT | TRAP |
| `unique` | `body` → `patch` · **CRASH** `prev.unwrapOr` | `body` · **ERLC** `unwrapOr/2` undefined | SILENT | TRAP |

### `Bool` (`:87-112`) and the numeric tower (`:17-83`)

| Method | node | erlang | beam | wasm |
|---|---|---|---|---|
| `Bool.toString` | `name` · ok | `mod:sym` · ok | `call_ext` · ok | TRAP |
| `negate` | `body` → `patch` · ok | `tmpl (not $self)` · ok | SILENT (inverted) | TRAP |
| `nor` `nand` `exclusiveOr` `exclusiveNor` | `body` → `patch` · ok | `body` · ok | SILENT (3 of 4 wrong) | TRAP |
| `min` / `max` (int, float) | `mod:sym Math` → `patch` · ok | `mod:sym erlang` · ok | SILENT | TRAP |
| `clamp` `isEven` `isOdd` | `body` → `patch` · ok | `body` · ok | SILENT | TRAP |
| `Integer.toString` | `name` · ok | `mod:sym` · ok | SILENT (integer, not binary) | TRAP |
| `abs` (Signed, Float) | `mod:sym Math` → `patch` · ok | `mod:sym` · ok | SILENT | TRAP |
| `Float.toString` | `name` · ok `2.5` | `mod:sym float_to_binary` · **WRONG** `2.50000000000000000000e+00` | SILENT | TRAP |
| `floor` `ceil` `squareRoot` | `mod:sym Math` → `patch` · ok | `mod:sym math` · ok | SILENT | TRAP |
| `round` | `mod:sym Math` → `patch` · ok | `mod:sym math:round` · **CRASH undef** | SILENT | TRAP |

Reading across: **every `CRASH`/`WRONG`/`ERLC` on commonJS and erlang is an annotation defect or a
`default fn` body the backend cannot lower** — none is a missing host capability. beam and wasm are
not "missing a few bindings": beam lowers 22 of 85, wasm 3.

---

## 5. The four approaches compared

| | (a) inline template naming the host expression | (b) module + symbol of a shipped file | (c) compiler-owned helper, emitted on demand | (d) botopink body (`default fn` / `fn`, no annotation) |
|---|---|---|---|---|
| **Examples today** | `"binary:copy($self, $0)"`, `"Buffer.from($0,'utf8').toString('base64')"`; `("Math","floor")` is the degenerate case | `./gleam_stdlib.mjs` (22, missing), `./sidecars/random.mjs`, rakun `./runtime.mjs`, onze `onze.mjs` | wat `Builder.helper` (`codegen/wat/wat_ast.zig:557`), beam `ensureAtHelper`/`ensureIndexOfHelper`/`ensureStringifyHelper` (`beam_asm.zig:2978-3072`), erlang `comptime_helper_forms` (`erlang.zig:389`); commonJS none | `clamp`, `isEven`, `nor`, `fold`, `all`, every pure std module (`dict`, `path`, `url`, …) |
| **Runtime shipping / loading** | nothing shipped; the text is duplicated at every call site (the erlang `padStart` fun is emitted in full per call — measured) | the file must exist next to the **emitted** module; `shipMjsSidecars` (`compiler-cli/src/cli/libs.zig:351`) finds it by grepping the output for `require("…")`; the whole file loads at module load, **even if unused** (measured) | nothing shipped; one copy per module, only if called (wat, beam: measured; erlang instance defaults: `instanceDefaultForms` `:3884`) | nothing shipped; erlang emits only reached defaults; **commonJS emits the whole interface as global prototype patches** (§2, T3-T5) |
| **Works on all four targets** | only on targets with a template renderer: commonJS + erlang; beam reads no Erlang source template (`beam_asm.zig:2616`) and needs its own `.S`; wasm none. A binding is written per target | commonJS only (erlang: no file form; beam/wasm: none) | yes by construction — but written once **per backend**, in that backend's IR | yes in principle — one source; today erlang ok for simple bodies, commonJS via harmful patches, beam SILENT, wasm TRAP |
| **Arity and types checked** | botopink signature at the call; template text unchecked until the host compiler runs (T6, T9, `$N` range is a bare codegen error) | signature at the call; host symbol/arity never (T13) | helper is compiler code, covered by its unit tests; the annotation names it — an unknown name can be a check error | fully checked by the botopink checker |
| **Testable** | only by running on each host; no test in `libs/std` exercises beam | by running on node | in `compiler-core` tests, per backend, once | `botopink test` inline tests, every target the runner supports (commonJS, erlang today) |
| **Host lacks the operation** | runtime `undef` / `ReferenceError`, or erlc/`SyntaxError`; a missing target is `MissingExternalTarget` with no location (measured) | `Cannot find module` at load | the backend has no helper of that name → compile error at the request (the request-and-mark call can fail) | nothing to lack — only lowering gaps |
| **Comptime path (Erlang VM)** | the Erlang template can run once front 01 dispatches it; a Node template means nothing there | never (a JS file) | the Erlang helper set can be emitted into the comptime module the way `comptime_helper_forms` are | runs if the untyped path lowers the body (front 01 step 1 covers reached defaults) |
| **Semantics owned by** | the host (edge cases differ: §4 `charAt`, `trimStart`, `replace`, `Float.toString`) | the file's author | botopink, per backend | botopink, once — except operations bound to the host representation (UTF-16 JS strings vs UTF-8 binaries), which a body cannot express portably |

---

## 6. Recommendation

### Rules

Apply the first rule that matches.

| Rule | Situation | Approach | Form in `libs/std` |
|---|---|---|---|
| **R1** | Expressible over other primitives with acceptable cost (no host representation, no host capability) | **(d)** botopink body, no annotation | `default fn clamp(self: Self, lo: Self, hi: Self) -> Self { … }` |
| **R2** | A host operation whose semantics **match the signature exactly** on that host, expressible as one host call or expression | **(a)** per-target annotation: 2-arg `("module", "symbol")` for a host-global / OTP module in declaration order, else a `"""…"""` template, each marker at most once | `#[@External.Erlang("string", "uppercase"), @External.Node("toUpperCase")] fn toUpper(self: Self) -> string` |
| **R3** | A host operation that exists but differs at the edges (indices, `-1` vs null, what is trimmed, iolist vs binary, float format), or an algorithm longer than one host expression | **(c)** compiler-owned helper, one per backend, emitted when called; the declaration names it **once** | `#[@Helper("stringCharAt")] fn charAt(self: Self, index: i32) -> ?string` (name of the annotation is the maintainer's choice) |
| **R4** | Needs a host capability (clock, env, fs, process, crypto, regex, sockets) | **(a)** per target on a `declare fn`; wasm refuses at compile time (STD-001 with a location) until a WASI decision exists ([`../03-wasm/`](../03-wasm/README.md) W1) | `#[@External.Node("""process.cwd()"""), @External.Erlang("""(fun() -> {ok, P} = file:get_cwd(), list_to_binary(P) end)()""")] pub declare fn cwd() -> string;` |
| **R5** | Any binding kept under R2/R4 | a `test` in the module that asserts the **value**, run on commonJS and erlang (and beam once `botopink test` supports it) | — |
| **R6** | Something a template or decorator body may call | must be R1, R3 (Erlang helper) or have an **Erlang** R2/R4 binding; a Node-only binding is refused inside a comptime body | — |
| **—** | (b) relative/shipped file | **not used in `libs/std`**. For sibling libraries that own host state (rakun, onze), allowed only if the build verifies the file exists and the `require` is emitted lazily | — |

Corollaries that remove whole classes of the traps:

- **Pick the host call by semantics, not by name.** `string:suffix`, `math:round`, `string:str` on a
  binary, `string:trim` for `trimStart` are all name matches (T13, §4).
- **One spelling.** `#[@External.<Target>(…)]` with a `Target` member; `Wasm`/`Typescript` refused
  until a backend reads them (T12); `when(argc == N)` removed — arity is fixed by the signature and
  trailing defaults are expanded before codegen once front 01 step 3 lands; the `inline:` flag
  removed (0 uses); the `symbol(args)` reorder removed (T10) once beam reads call-shaped templates.
- **`$self` only on interface methods; `$N` on `declare fn`.** (T8)
- **A `default fn` never replaces a native method** — it is not a prototype patch at all (T3–T5).

### `libs/std` after the rules

| Area | Today | After |
|---|---|---|
| `String` / `Array` / numeric host-backed methods | 22 `rel`, 16 `name`, 23+26 erlang forms, 5 `.S`, 5 node templates | **R2** for exact matches (`toUpper`, `toLower`, `contains`, `startsWith`, `endsWith` with a real suffix call, `trim`, `split`, `repeat`, `replaceAll`, `reverse`, `pop`, `map`/`filter`/`forEach`, `abs`/`floor`/`ceil`/`squareRoot`, `min`/`max`); **R3** for `charAt`, `indexOf`, `lastIndexOf`, `charCodeAt`, `slice`, `at`, `join`, `trimStart`/`trimEnd`, `replace`, `padStart`/`padEnd`, `chars`/`lines`/`words`, `round`, `Float.toString`; no `rel`, no `iife` |
| `stringSlice0/1`, `arraySlice0/1` (`primitives.bp:228-236`, `:825-833`) | host `declare fn`s behind `default fn slice` | deleted — `slice` is R3 |
| `default fn`s (`clamp` … `unique`, `Pair`, `Function`) | bodies, patched on commonJS, SILENT on beam | **R1**, unchanged source; bodies that use what no backend lowers (`while`, `unwrapOr` on a local, `append` inside a default) rewritten or reported to the backend front |
| `default fn` + annotation (`negate`, `isEmpty`, `contains`, `append`, `prepend`, `find`, `flatMap`, `toString`) | per-target override of a body | kept: R2 annotation where it is an exact host op, body as the fallback for targets without one |
| `math.bp` | 22 × node/erlang/beam `mod:sym` | node/erlang `mod:sym`; the 22 `@External.Beam` deleted (beam derives `call_ext` from the Erlang pair) |
| `os`, `process`, `env`, `fs`, `crypto`, `regex`, `time`, `http`, `json`, `base64`, `unicode` | 13 bare expressions (T7), templates with `\` escapes, `$1` twice in `regex` | **R4**, all templates triple-quoted, markers bound once; STD-001 refuses them on wasm with a location |
| `random.bp` | `require('./sidecars/random.mjs')` (Mulberry32) | R1 if 32-bit wrapping integer arithmetic lowers identically on every backend, else R3; `sidecars/` deleted |
| `erlang.bp` | 48 `mod:sym`, erlang-only | unchanged (the BIF surface of the erlang target); STD-001 refuses it on node and wasm |
| `builtins.d.bp:5-14` | 6 `External.<Target>` without `@`, unparsed, re-typed in two emitters | one parseable source (or deleted), and the two hand-written registries removed |

### Compiler work

S = one site, ≤1 day · M = one backend, 2–4 days · L = new mechanism or cross-backend, ≥1 week.
"Owner" is the front in [`../fronts.md`](../fronts.md) that holds the file.

| # | Work | Enables | Size | Owner |
|---|---|---|---|---|
| C1 | One validator for every annotated declaration kind (declare fn, interface method, `default fn`, record method): refuse `external`/unknown `External.*`, wrong arg count, non-string args, unread targets, `$self` outside interfaces, repeated markers, `\` in non-raw templates, `when(…)` — each with a location | T1, T6, T8, T9, T11, T12 | M | F7 checker (`comptime/infer.zig`) |
| C2 | `build` exits non-zero and prints the error when `check` would fail | every refusal above is visible | S | F2 cli-gate |
| C3 | commonJS: on a `declare fn`, a 1-arg annotation always renders at the call site; a 2-arg host-global form stays an alias; a relative-file form is required lazily at the call | T7, the unused-file load | S | F8 js-bridges (= std-surface step 3) |
| C4 | commonJS: **replace prototype patching** — instance `default fn`s and interface templates lower to module-local functions called through static dispatch, emitted only when reached (the erlang `instanceDefaultForms` shape) | T3, T4, T5, `rest`/`take`/`drop`/`zip`/`chars` crashes | L (re-records `snapshots/codegen/commonJS/`) | F8 js-bridges |
| C5 | Helper registry per backend with request-and-mark as one call (`wat_ast.zig:557` shape): commonJS new, erlang forms appended on demand, beam `ensure*` generalised, wat existing; an annotation naming an unknown helper is a check error | R3 | M for the mechanism (commonJS), then S per helper per backend (~16 helpers × 4) | F8 + F4 + F5 + F6 |
| C6 | beam: `declare fn` externals via the Erlang 2-arg pair (B2); numeric kinds + `extends` walk in `primIfaceForKind`; instance `default fn`s on demand; a call-shaped Erlang template (`mod:sym($0, $self)`) becomes `call_ext`; fail instead of `%% unresolved` (B4) | T14, T15, deleting `.S`/`Beam` annotations and the reorder form | L | F4 beam |
| C7 | erlang: interface templates through `dupeTemplate` (or C1's raw-only rule); a `pub` external emits a wrapper function in its owner module so `math.abs(x)` resolves; std module atoms that collide with OTP (`math`, `os`) renamed | T6, cross-module std calls | M | F5 erlang (+ F11 for the naming) |
| C8 | STD-001 keyed on what each backend can lower (beam ≠ erlang), raised through `build` with a location | T14, wasm R4 | S | F7 checker |
| C9 | Comptime: front 01 step 1 shim; plus refuse a call to a declaration with no Erlang binding inside a template/decorator body | R6 | (front 01) + S | F1 comptime-dispatch |
| C10 | wasm: instance lowering for R1 bodies and helper-backed R3 methods | wasm column of §4 | L | F6 wasm (W1) |
| C11 | Delete dead vocabulary: `inline:` flag readers (`erlang.zig`/`beam_asm.zig` `hasExternalInline`), `when(argc == N)` (`parser.zig:742`, `ast.zig:1275-1346` and four collectors), `parseExternalCallTemplate` reorder (`ast.zig:1196`) after C6, the 73 lowercase `@external(…)` comments | one grammar | S | the owner of each file |

**Order.** C1 + C2 first — they turn T1/T6/T8–T12 from silent into errors and cost the least. Then
C3 (unblocks `env`/`os`/`process`/`random`) and C5's commonJS mechanism with the four `slice`
helpers (unblocks the 18 std tests, std-surface step 2). C4 is the change that removes the
prototype-patch class for good and should land before any new `default fn` is added to
`primitives.bp`. C6 and C10 are the backend fronts' own rows (B2/B4, W1); the `libs/std` rewrite
does not wait for them, but it must not add `@External.Beam` annotations that C6 makes redundant.

## Acceptance

- [ ] Every row of §3 is either impossible to write (a located check error) or fixed
- [ ] §4 re-measured after the rewrite: commonJS and erlang have 0 `WRONG`/`CRASH`/`ERLC`; every
      beam `SILENT` and wasm `TRAP` is either gone or a compile-time error
- [ ] No `rel` form, no `iife` template, no `when(argc == N)`, no `symbol(args)` and no `\` escape
      in a non-raw template remains in `libs/std`
- [ ] Each R2/R4 binding has a value-asserting test (R5)
- [ ] `libs/std/AGENTS.md` §`#[@External.<Target>(...)]` states the rules R1–R6 instead of the
      form catalogue
