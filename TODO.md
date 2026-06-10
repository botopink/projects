# TODO — erika  (sub-language DSL · Wave 2)

> Task branch `task/erika-dsl` · spec
> [`tasks/v0.beta.8/specs/erika.md`](../../tasks/v0.beta.8/specs/erika.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> Sibling of `jhonstart-html` (same template-fn mechanism). F0 already shipped on
> `feat`; F1 is ⛔ **GATED on `generic-loader-binding`** (binds bare `erika`) —
> `git merge feat` once the keystone lands.
>
> Lib-side / example-side only — **zero** core code. `erika "…"` is an embedded SQL
> sub-language: references (the queried collection) resolve in the CALLER's scope,
> just like `html` resolves builders.

## F0 — runnable example  ✅ (done — in `feat`, examples/erika-linq, 4/4 green)
- [x] `examples/erika-linq/` (bare `import {of}`): lists → `Query` → join, the result
      folded as an Iterator, standalone iterator map/join. `botopink test` 4/4.

## F1 — the cross-module `erika "…"` sub-language
- [ ] After `generic-loader-binding` binds the bare template fn, add `erika "select …"`
      **and** multi-line `erika """ … """` `test {}`s to the example (consumer module).
- [ ] The query resolves its collection (`cities`) in the **caller's comptime scope**
      (same caller-scope resolution `html` uses); unknown name → diagnostic inside the query.

## F2 — docs
- [ ] Point `libs/erika/examples.md` at the runnable `examples/erika-linq/`; in
      `AGENTS.md` drop the recorded "unbound after import" limit (now works). Same commit.

## Done gate
- [ ] `erika "…"` + `erika """…"""` run cross-module from a consumer (after keystone).
- [ ] `botopink test` green from `examples/erika-linq/`.
- [ ] `grep -riE "erika" modules/compiler-core/src` returns nothing (std exempt).

## Notes
- No new LINQ operators — the lib (`Query<T>` + the SQL template) is done. If a gap
  surfaces, fix it in `libs/erika/*.bp` (real `.bp`).
