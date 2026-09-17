# Group D — instructions and vocabulary that do not work (5.8, 5.13)

> Carried from `1.0.2-beta/11-hygiene/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F12` and bare front numbers are the old numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).

An example header and a sweep of comments teaching forms the compiler rejects. Paths are relative
to `repository/botopink-lang/`; bare `codegen/…`, `comptime/…`, `parser/…`, `ast.zig` and
`codegen.zig` are under `modules/compiler-core/src/`, and `main.zig`/`check.zig` under
`modules/compiler-cli/src/`.

Runs any time. Nothing here changes behaviour except one fixture, which re-records one comptime
snapshot (see [Blast radius](#blast-radius)).

---

## Items

| # | Deciding site | What a reader sees | Smallest fix |
|---|---|---|---|
| 5.8 | `examples/hello.bp:3-4` | `botopink run examples/hello.bp` and `botopink check examples/hello.bp`. The CLI is project-based: `main.zig:116-118` calls `check_cmd.run` without slicing `args[2..]` at all, so the path is ignored and `check.zig:14-16` reports "botopink.json not found — are you in a botopink project?"; `parseRunOpts` (`main.zig:175-200`) has **no final `else`**, so a bare positional falls through every branch silently. These are the first two lines a new user reads | Replace the header with the sequence `examples/AGENTS.md:56-58` already documents: `botopink new demo && cp examples/hello.bp demo/src/main.bp && cd demo && botopink run`. Rejecting unexpected positionals belongs to [`../05-cli-residuals/`](../05-cli-residuals/README.md) (the command contract) |
| 5.13 | `comptime/tests/infer_decls.zig:518` | `@external(node, "./gleam_stdlib.mjs", "string_length")`, sitting next to a correct `@External.Erlang(…)` on `:517`. `ast.zig:1796` (`FnDecl`) and `:1099` (`InterfaceMethod`) both gate on `startsWith(a.name, "External.")`, so the lowercase form **can never match** — it parses, type-checks, and is silently ignored by every backend. The test passes only because its sibling annotation carries the load | Rewrite the fixture to `#[@External.Node(…)]` and re-record its snapshot. Then decide whether a lowercase `@external` should be a parse error rather than silently inert — `codegen/tests/externals.zig:51` is named *"External.\<Target\> ---- template equivalent to @external(target, template)"*, which asserts an equivalence `ast.zig:1796` does not implement |
| 5.13 (cont.) | the comment sites [below](#513--the-comment-sweep) | `@external(<target>, …)` described as the live form, and an even older bracket form `@[external(…)]` beside it | Rewrite to `#[@External.<Target>(…)]`. **`libs/std/src/http.bp:62` is the one user-visible site** — do it first. Leave the sites that already label the form as legacy |

## 5.13 — the comment sweep

Sites describing `@external(<target>, …)` as the live form:

| File | Lines |
|---|---|
| `codegen/erlang.zig` | `:1069, 1156, 1163, 1268, 1275, 1388, 1394, 1438, 1484, 1596, 1643, 1653, 1718, 1742, 1761, 3402, 3446, 3825, 3842` |
| `codegen/commonJS.zig` | `:206, 716, 735, 744, 747, 826, 898, 946, 1367, 2600, 2608, 2678` |
| `codegen/beam_asm.zig` | `:46, 830, 917, 2565, 2586` |
| `comptime/infer.zig` | `:89, 6639, 6702, 7083` |
| `comptime/env.zig` | `:503` |
| `comptime/diagnostics.zig` | `:172` |
| `codegen/AGENTS.md` | `:175` |
| `comptime/AGENTS.md` | `:68` |
| `codegen/tests/externals.zig` | `:117, 135` |
| `comptime/tests/std_target_gating.zig` | `:6` |
| `codegen.zig` | `:26` |
| `parser/decls.zig` | `:400` |
| `libs/std/src/http.bp` | `:62` — the user-visible one |

The older bracket form `@[external(…)]` survives at `codegen/commonJS.zig:206, 716`,
`codegen/erlang.zig:1156` and `parser/tests/errors.zig:148, 156`.

The table lists 49 lines; [`README.md`](./README.md) summarises it as "~24". A grep for
`@external(` over `*.zig`, `*.bp` and `*.md` under `libs/` and `modules/` (snapshots excluded,
measured 2026-09-16) also returns 49.

The same grep for `@[external` returns **25**, not five. The other twenty, all comments unless
noted:

| File | Lines |
|---|---|
| `codegen/erlang.zig` | `:1159, 2160` |
| `codegen/commonJS.zig` | `:720, 974` |
| `codegen/tests/features.zig` | `:889` |
| `comptime/infer.zig` | `:2594, 6491, 6493, 6622, 6673, 6674` |
| `parser/decls.zig` | `:283, 418, 611` |
| `parser.zig` | `:358` |
| `ast.zig` | `:1061, 1726, 1762` (`:1762` names both `@[external(…)]` and `@[External.<Target>(…)]`) |
| `modules/language-server/src/tests/hover.zig` | `:180, 182` |

**Leave `parser/tests/errors.zig:148, 156`**, although the list above names them. They are the
input and the expected rendering of `test "parser error: retired @[ annotation block"`
(`errors.zig:142`), which asserts that `@[…]` is *rejected* with "write `#[…]` instead" — the
regression test for 5.12, not a site teaching the form.

**Leave** the sites that already label the form as legacy:

- `comptime/infer.zig:2099, 2107, 2113` — error messages suggesting the correct form
- `codegen/beam_asm.zig:740` — explicitly "(or legacy `external(beam,`)"
- `parser/tests/errors.zig:148, 156` — the retired-`@[` rejection test (above)

`codegen/erlang.zig:3825` and `codegen/beam_asm.zig:917` also carry the stale `primitives.d.bp`
name ([`std-declarations.md`](./std-declarations.md), 5.14) — rewrite each line once.

## Steps

1. **5.8** — replace `examples/hello.bp:3-4` with the `botopink new demo && …` sequence from
   `examples/AGENTS.md:56-58`.
2. **5.13 fixture** — rewrite `comptime/tests/infer_decls.zig:518` to `#[@External.Node(…)]` and
   re-record its snapshot.
3. **5.13 decision** — decide whether a lowercase `@external` is a parse error or accepted, and
   write it down; rename or fix `codegen/tests/externals.zig:51` so its name matches what
   `ast.zig:1796` implements.
4. **5.13 sweep** — `libs/std/src/http.bp:62` first, then the comment sites, one commit per owning
   file (see [Ownership](#ownership)).

## Acceptance

- [ ] No comment, fixture or `.bp` file presents `@external(<target>, …)` or `@[external(…)]` as
      current
- [ ] `examples/hello.bp`'s header works when pasted into a shell
- [ ] Whether a lowercase `@external` is rejected or accepted is decided and written down

## Blast radius

The fixture rewrite at `comptime/tests/infer_decls.zig:518` re-records one comptime snapshot, in a
directory `comptime-dispatch` (1.0.2-beta, landed),
[`../06-checker/`](../06-checker/README.md) and
[`../07-comptime-dedup/`](../07-comptime-dedup/README.md) all move. Land it when none of them is in
flight, or hand that single row to whichever is. If the decision in step 3 makes a lowercase
`@external` a parse error, that is a parser change and belongs to
[`../06-checker/`](../06-checker/README.md), which owns `parser/{decls,exprs,patterns}.zig`.

## Ownership

| Files | Owner |
|---|---|
| `codegen/erlang.zig` | `comptime-dispatch` (1.0.2-beta, landed) (untyped path), [`../02-erlang/`](../02-erlang/README.md) (typed path) |
| `codegen/commonJS.zig` | [`../04-js-bridges/`](../04-js-bridges/README.md) |
| `codegen/beam_asm.zig` | [`../01-beam/`](../01-beam/README.md) |
| `comptime/infer.zig`, `comptime/env.zig`, `parser/decls.zig` | [`../06-checker/`](../06-checker/README.md) |
| `codegen/tests/**`, `comptime/tests/**` | [`../08-review-backlog/`](../08-review-backlog/README.md) |
| `libs/std/src/http.bp` | `std-surface` (1.0.2-beta, landed) |
| `ast.zig`, `parser.zig`, `codegen.zig`, `comptime/diagnostics.zig`, `modules/language-server/**` | no front in [`../fronts.md`](../fronts.md) — this front's for comment edits |
| `examples/**`, every `AGENTS.md` | this front |

A comment-only edit in another front's file is safe to make and expensive to merge: do each sweep
last, after the owning front has landed, or hand it to that front.
