# Decisions the maintainer owes — 1.0.10-beta

**Two open, 91 and 92** — both raised on 2026-09-21 by the `#[@context]` sweep of `04-jhonstart`,
both **non-blocking**: the specs and the library compile either way, and each answer is a rewrite of
prose, not of a landed refusal. The twenty questions raised while the milestone was cut and while
front 19 landed (71–90) are answered in [`decisions-taken.md`](./decisions-taken.md). The next free
number is **93**.

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

## 91. `@Result<Element, string>` owns no context — is `@Future` the only wrapper 89 looks through?

**Raised by:** the `04-jhonstart` sweep for decision 88, 2026-09-21.
**Measured.** Decision 89 unwraps `@Future<T>` **and only `@Future`**, and decision 90 grants the
dispensation to "a wrapper effect whose unwrapped return type owns a context". Front 31's five panels
are `#[@result] fn … -> @Result<Element, string>`: the wrapper is `@Result`, so the return type owns
no context, so such a body may not activate a hook even though it answers an `Element`. Nothing
breaks today — those five panels activate nothing — and no document states the asymmetry.
**Options.** (a) `@Future` stays the only wrapper looked through; a `#[@result]` component that needs
a hook is refused, and the asymmetry is written into front 19's *rule for libraries* as intended;
(b) `contextInfoFromReturn` looks through every **single-payload** return wrapper the language has
(`@Future<T>`, `@Result<T, E>`, `@Option<T>`) and takes `T`'s owner, which makes 90's dispensation
follow the effect rather than the one type; (c) case by case, as each front needs it.
**Recommendation.** (a) — the narrowest rule that serves a measured need (decision 67); (b) widens a
capability for a case nobody has written yet, and (c) is (b) paid for one front at a time.
**Blocks.** Nothing. It decides one sentence of front 19 step 2 and one row of `04-jhonstart`.

## 92. Does a component that activates nothing still carry `#[@context]`?

**Raised by:** the `04-jhonstart` sweep for decision 88, 2026-09-21.
**Measured.** Decision 88 reads "a component therefore carries the `#[@Context]` effect annotation",
and the sweep annotated all **29** component declarations under `04-jhonstart/**`. The **compiler**
refuses only an *activating* body without the annotation (`use-without-context-effect`); `docs.md`
states that a bare `fn … -> Element` is an ordinary function. jhonstart's own source (`b89c787`)
annotates only the bodies that activate, so the specs and the library now disagree on ~20 purely
presentational components (`Loading`, `NotFound`, `GlobalError`, `RootLayout`, …).
**Options.** (a) every component carries it — the annotation reads as "this is a component", the
specs stay as swept and jhonstart gains ~20 annotations; (b) only an activating body carries it —
the specs are narrowed to the library's reading, and the annotation means exactly what the compiler
enforces; (c) leave both, documented as style.
**Recommendation.** (b), by the reasoning of decision 90: an annotation that says nothing the return
type does not already say is not written. It also removes a standing drift between `04-jhonstart/**`
and the library the front describes.
**Blocks.** Nothing. It decides whether ~20 spec sites and ~20 library sites keep an annotation.
