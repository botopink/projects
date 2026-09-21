# Decisions the maintainer owes — 1.0.10-beta

**One open, 90** — raised by front 19's step 1 landing on 2026-09-20: decision 88 (`#[@context]` on every
activating body) collides with rule R5 (one effect annotation per fn) exactly on the server component
(`#[@future] fn … -> @Future<Element>`), so decision 89 cannot be implemented until 90 is answered. The
nineteen questions raised while the milestone was cut (71–89) are all in
[`decisions-taken.md`](./decisions-taken.md). The next free number is **91**.

This file stays because the fronts will fill it again. A front that meets a question it cannot answer
from the code writes it here rather than guessing, in the shape the others used:

> **Raised by:** `<NN>-<front>` step <k>, <date>
> **Measured.** What was observed, with the command or program that produced it and the file or commit
> that can be re-read.
> **Options.** Each one stated so that choosing between them is possible without reading the code.
> **Recommendation.** One, argued — the default is the most restrictive behaviour, and no configuration
> that bypasses it (decision 67).
> **Blocks.** The step, front or landed work that waits on the answer.

---

## 90. A server component needs both `#[@future]` and `#[@context]` — and R5 allows one effect annotation per fn

**Raised by:** `00 · 19-use-activation` step 2 (decision 89), 2026-09-20, after step 1 landed on `fix/use-activation`.
**Measured.** Step 1 implemented decision 88 as the existing lowercase effect `#[@context]`: `FnContext.annotated`
is set only by that annotation (`infer.zig:987`), and a body that activates a hook without it gets the new
`use-without-context-effect`. A server component is `#[@future] fn Page() -> @Future<Element>`; the parser refuses a
second effect annotation on one fn (R5 `effect-duplicate-annotation`, `parser/decls.zig:407-409`,
`firstDuplicateEffect` `:525`). So `#[@future]` alone leaves `annotated == false` and every `use` in a server
component is refused; `#[@future] #[@context]` does not parse. Looking through `@Future<T>` in
`contextInfoFromReturn` (decision 89) is a five-line change that is unreachable until one of the three below holds.
Also measured: the codebase spells effects lowercase (`#[@future]`, `#[@context]`); `#[@Context]` with a capital is
today an unknown annotation silently ignored, and no alias was added (decision 67).
**Options.** (a) a `#[@future]` body whose return type unwraps to a context owner may activate hooks **without**
`#[@context]` — weakens 88 ("every activating body carries the annotation"); (b) `#[@future]` and `#[@context]` may
**coexist** on one fn — R5 keeps refusing two *return-wrapper* effects (`#[@future] #[@iterator]`) and admits the
capability effect beside one wrapper, because they answer different questions (what the return is wrapped in / what
the body may activate); (c) a combined spelling (`#[@context.future]` or `#[@future(context)]`) — a new production
for one pair.
**Recommendation.** (b), narrowly: the parser's duplicate rule becomes "at most one wrapper effect, at most one
capability effect", so `#[@future] #[@context] fn Page() -> @Future<Element>` parses and 89's unwrap applies; (a)
makes the annotation optional exactly where the reader most needs it, (c) invents syntax for one case. Under
decision 67 the refusals stay: `#[@context]` without a context-owning return type is still `effect-wrapper-mismatch`.
**Blocks.** Front 19 step 2 (decision 89); front 28's `request()`; every server component in `04-jhonstart` that reads
the request scope.
