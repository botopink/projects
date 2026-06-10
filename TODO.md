# TODO — erika  (sub-language DSL · Wave 2)

> Task branch `task/erika-dsl` · spec
> [`tasks/v0.beta.8/specs/erika.md`](../../tasks/v0.beta.8/specs/erika.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> Sibling of `jhonstart-html` (same template-fn mechanism). F0 shipped on `feat`;
> the `generic-loader-binding` keystone landed in `feat` (binds bare `erika`) and
> was merged in (`04ef4ee`), unblocking F1.
>
> Lib-side / example-side only — **zero** core code. `erika "…"` is an embedded SQL
> sub-language: references (the queried collection) resolve in the CALLER's scope,
> just like `html` resolves builders.

## F0 — runnable example  ✅ (done — in `feat`, examples/erika-linq, 4/4 green)
- [x] `examples/erika-linq/` (bare `import {of}`): lists → `Query` → join, the result
      folded as an Iterator, standalone iterator map/join. `botopink test` 4/4.

## F1 — the cross-module `erika "…"` sub-language  ✅
- [x] Added `erika "select …"` **and** multi-line `erika """ … """` `test {}`s to
      `examples/erika-linq/` (a consumer module, `import {of, erika} from "erika"`).
- [x] The query resolves its collection (`cities`) in the **caller's comptime scope**
      (same caller-scope resolution `html` uses). Gap surfaced + fixed in `.bp`: the
      multi-line form glued `\n` to the source token (`cities\n`) — the tokenizer now
      normalizes newlines/tabs to spaces (`split("\n").join(" ")`, native-JS ops).

## F2 — docs  ✅
- [x] `libs/erika/examples.md` points at the runnable `examples/erika-linq/`; the
      "unbound after import" limit dropped from `AGENTS.md`/`docs.md` (now works) and
      the multi-line form documented; `examples/AGENTS.md` updated. Test count 21→25.

## Done gate
- [x] `erika "…"` + `erika """…"""` run cross-module from a consumer (`erika-linq`, 6/6).
- [x] `botopink test` green from `examples/erika-linq/` (6/6) and `libs/erika/` (25/25).
- [x] `grep -riE "erika" modules/compiler-core/src` returns nothing (std exempt).

## Notes
- No new LINQ operators — the lib (`Query<T>` + the SQL template) is done. The only
  code change was the multi-line tokenizer fix in `libs/erika/src/erika.bp` (real `.bp`).
