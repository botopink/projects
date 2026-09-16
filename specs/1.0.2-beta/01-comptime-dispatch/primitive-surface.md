# The primitive surface in an untyped body

What a `recv.m(args)` in a template or decorator body lowers to today, swept from the lowering
itself (`codegen/erlang.zig:3565-3571`), not from the failure reports. Paths are relative to
`repository/botopink-lang/`.

In a comptime body `recv.m(args)` lowers to exactly one of:

- the correct host op, if `m` is one of the five names `arrayPrimFallbackNode` (`:3904`) answers;
- `iolist_to_binary(io_lib:format("~p", […]))`, if `m` is `toString` with no arguments (`:3570`);
- otherwise the bare local call `m(Recv, args)` (`:3571`) — which is an `erl_lint`
  `{undefined_function,{m,N}}` **unless the name/arity happens to be an auto-imported Erlang BIF**,
  in which case it lints clean and then misbehaves at runtime.

## The full table

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

G1 and G2 are defined in [`lowering-path.md`](./lowering-path.md).

## Three corrections to what the earlier reports said

1. **"Only `.length` resolves" is wrong in both directions.** `.length` resolves only as a *field*
   access — `codegen/erlang.zig:3052-3056` routes an untyped `.len`/`.length` member access to
   `'__bp_len'/2`. As a *call*, `s.length()` falls to `:3571` and emits the BIF `length/1`, which
   lints and then throws `badarg` on a binary. Meanwhile five array methods already resolve
   correctly through `arrayPrimFallbackNode`; that is why `decl.methods.forEach({ … })` works in
   every decorator today and why `codegen/tests/comptime_module.zig:72` passes.
2. **A subset of the failures are runtime-silent, not lint errors.** Any method whose name/arity
   collides with an auto-imported BIF (`length/1`, `abs/1`, `round/1`, `floor/1`, `ceil/1`,
   `float/1`, `size/1`) compiles and misbehaves. These appear in no `{undefined_function,…}` list
   and must be fixed by the same change.
3. **`.size` is missing from the untyped member-access branch.** `codegen/erlang.zig:3053` tests
   `len`/`length` while its typed sibling at `:3042` also accepts `size`. One-word fix, same file.

## Blast radius, measured

Counts come from re-linting the generated modules under each repo's
`.botopinkbuild/tmp/{template,decorator}/` directly (`compile:file(…, strong_validation)`).
`botopink check` truncates `erl_lint` detail at 4096 bytes
(`comptime/template_eval.zig:76` `max_error_detail`, applied at `:117-118`; same at
`comptime/decorator_eval.zig:56`, `:95-96`), which is why the earlier report said "26 of 35" —
the last error was clipped. The real figures for erika are 36 total / **27** `undefined_function`.

| Library | Host | Comptime body | Methods used inside | `erl_lint` errors | Residual after this fix |
|---|---|---|---|---|---|
| erika | template | `src/erika.bp:356-591` | `append`×12, `join`×5, `split`×4, `map`×4, `slice`×2 | 36 total, **27** `undefined_function` | **9** `unbound_var`/`unsafe_var` (`OpTok@2`, `LTok@2`, `RTok@2`, `Toks@3` at `:131`, `:134`, `:359`) — a separate case-arm rebinding bug; erika still will not compile |
| jhonstart | template | `src/html.bp:86-259` | `slice`×29, `append`×21, `join`×14, `split`×10, `trim`×6, `indexOf`×2 | 87 total, **82** `undefined_function` | **5** `unbound_var` (`Tokens@2`×2, `Tokens@15`, `CodeStack@1`, `RootMarks@2`) |
| onze | decorator | `src/onze.bp:153-186` | `push`×2, `join`×2, `startsWith`×1 | 5 total, **5** `undefined_function` | **0** — fully unblocked by step 1 |
| rakun | decorator | `src/decorators.bp:46-227`, 6 bodied decorators | `join`×16, `push`×6 (`forEach`×20 already works) | **22** predicted, per-module 3/3/3/5/5/3 | `push` is a *mutation* — see [`closure-mutation.md`](./closure-mutation.md) |
| emilia | none | — | — | 0 | unaffected; 17/17 pass |

Also affected: `repository/erika/examples/erika-linq` reproduces erika's 36/27 exactly, from 6
`erika "…"` sites in `src/main.bp`.

**136 bare-call errors across the ecosystem**, plus 14 residual scoping errors that are a
different defect. **Only onze is fully unblocked by step 1** — erika and jhonstart still will not
compile afterwards.

Three facts the earlier text did not have:

- **`check` is green while `test` is red** for jhonstart and onze: the template/decorator only
  lowers at a *call site*, and `cli/check.zig:23` loads `src/` only. A CI gate on `check` alone
  misses the whole class. See [`../02-cli-gate/command-contract.md`](../02-cli-gate/command-contract.md) row C5.
- `contains`, `at`, `reverse` and `toUpper` appear in no library comptime body today — they are
  latent, not observed. Every observed failure is one of
  `append`, `join`, `split`, `slice`, `map`, `trim`, `indexOf`, `push`, `startsWith`.
- rakun never reaches evaluation: `botopink.json` declares `"dependencies": ["server"]` and no
  such library exists under the libs root (`cli/check.zig:40`). Its 22 errors are latent behind
  that — owned by the library-repos front, not this one.

## Snapshot coverage, measured

There are 36 `COMPTIME ERLANG` sections, one per file, across
`snapshots/comptime/{node,erlang,beam,wasm}/` (5 files each) and
`snapshots/codegen/{commonJS,erlang,beam,wasm}/` (4 files each); the four backend copies of a
fixture are byte-identical by design (`comptime/tests/helpers.zig:127-132`). Backing tests:
`comptime/tests/templates.zig:408, 420, 438, 480, 818` and `codegen/tests/comptime.zig:318, 357,
408, 426`.

- **Not one of the 36 sections contains a primitive method call.** Every fixture body uses only
  the `@Expr` host API (`q.text()`, `q.build()`, `q.parts()`, `q.lookup()`, `q.fail()`,
  `@expr(…)`) plus string `+`. So under any fix option the existing suite stays byte-identical, and
  the whole surface this front is about has **zero** snapshot coverage.
- **There is no decorator `COMPTIME ERLANG` section at all** (0 of 36) — the host onze and rakun
  depend on entirely has no Erlang-output snapshot. Adding one fixture means 4 new files (one per
  backend directory), never an edit to an existing one.
