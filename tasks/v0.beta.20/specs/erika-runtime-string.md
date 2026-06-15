# erika-runtime-string — `var s = "select …"; erika s` runtime-string template form

**Slug**: erika-runtime-string
**Depends on**: nothing in v0.beta.20 — file-disjoint with every
  other v0.beta.20 spec.
**Files**: `modules/compiler-core/src/comptime/{template_eval,template,infer}.zig`
  · `libs/erika/AGENTS.md` "Recorded gaps" drops the G2 row
**Touches docs**: `modules/compiler-core/src/comptime/AGENTS.md`
  (new runtime-template dispatch row) · `libs/erika/AGENTS.md`
**Status**: pending

## Background

The `erika "…"` template form requires a literal at the call site
today because the comptime template body runs over a
`@Expr<string>` captured at parse time. A `var s = "select …";
erika s` form needs the compiler to recognise the call site with a
runtime `string` arg (not an `@Expr<string>`) and synthesise a
runtime path: parse the SQL string at runtime, resolve the source
collection via the comptime scope snapshot, build the runtime
query.

The mechanism is **pure generic** — no erika-specific code in core.
Any template fn that wants runtime-string mode can opt in.

v0.beta.19's frente-a-compiler §G2 deferred this; the inline
template form (§G1 `${…}` interp) shipped on `origin/feat` as
erika `0262a54` + bot-lang `bc92e01`.

## Checklist

- [ ] **F1-infer** — In `comptime/infer.zig`, when a template fn call
      receives a runtime `string` arg (not an `@Expr<string>` capture),
      synthesise a `runtime_template` dispatch: the template body
      runs at runtime over the string payload. The comptime scope
      snapshot binds named collections; the runtime form looks them
      up by name at expansion time.
- [ ] **F2-template-eval** — `comptime/template_eval.zig` ships a
      runtime bootstrapper: the same JS prelude (`text` / `parts` /
      `lookup` / `bindings` / `build` / `custom` / `fail`) but
      parameterised over a runtime string + a runtime
      scope-snapshot dict. The runtime form's `text()` returns the
      runtime string; `parts()` returns a single `Text` part (no
      holes — runtime-string mode forbids `${…}` for now,
      diagnosable with a clear error).
- [ ] **F3-erika** — Erika picks up the runtime form for free —
      `erika.bp`'s template body already iterates `q.parts()` and
      uses `q.lookup(name)`. The only check needed: a runtime hole
      via `${}` interp on a runtime string is rejected with the
      diagnostic above.
- [ ] **F4-test** — Inline tests in `repository/erika/src/erika.bp`:
      `var s = "select name from erikaCities"; erika s` returns
      the same `Array<string>` the literal form does. Compile-time
      diagnostic on `var s = "where id = ${x}"` (interp in runtime
      string).
- [ ] **F5-docs** — `comptime/AGENTS.md` gains a "runtime-template
      dispatch" row; `libs/erika/AGENTS.md` "Recorded gaps" drops
      the G2 row.

## Test scenarios

```
F4 ---- `var s = "select name from erikaCities"; erika s` returns
        the same array `erika "select name from erikaCities"` does.
F4-fail -- `erika "where id = ${x}"` (interp form) keeps working;
            `var s = "where id = ${x}"; erika s` rejects with the
            new diagnostic.
F5      -- libs/erika/AGENTS.md "Recorded gaps" no longer mentions
            the runtime-string form.
```

## Notes

- **No erika-specific code in core** — the dispatch is generic;
  every template fn benefits.
- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit**.
- The scope snapshot is shared with the comptime form — same
  `q.lookup(name)` API.
