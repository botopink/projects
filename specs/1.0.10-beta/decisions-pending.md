# Decisions the maintainer owes — 1.0.10-beta

**Seven open, 91 to 94, 97, 99 and 100** — 91 and 92 raised on 2026-09-21 by the `#[@context]` sweep of
`04-jhonstart`, 93 by front 19 step 2's landing the same day, 94 by the wave sweep that followed.
**91 and 93 are now questions about decision 95's chain** (`@Context` ⊃ `@Future` ⊃ `@Result`) and
should be answered with it: 91 asks whether the context-owner unwrap follows the chain to any
payload, 93 whether `inContextFn` follows the same rule `annotated` does;
91, 92 and 94 are **non-blocking**: the specs and the library compile either way, and each answer is a rewrite of
prose, not of a landed refusal. The twenty questions raised while the milestone was cut and while
front 19 landed (71–90) are answered in [`decisions-taken.md`](./decisions-taken.md). The next free
number is **100**.

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

## 93. A server component may activate a hook but may not read a provider

**Raised by:** `00 · 19-use-activation` step 2, 2026-09-21, by the landing of decision 90.
**Measured.** Decision 90 widened `FnContext.annotated` to "`#[@context]` **or** a wrapper effect
whose unwrapped return owns a context", so `#[@future] fn Page() -> @Future<Element>` now activates
hooks. `@getContex(T)` is gated by a **different** flag: `env.inContextFn`, set as `eff == .context`
only (`comptime/infer.zig:3259`, the RC5 check at `:4498`). So the same server component that may
call `use request()` is refused when it reads a provider —
`context-getcontex-outside-context-fn` — and the diagnostic's hint tells it to mark itself
`#[@context]`, which R5 refuses to parse beside `#[@future]`
(`effect-duplicate-annotation`). The hint therefore instructs a fix the language forbids.
**Options.** (a) `inContextFn` follows the same rule as `annotated` — a wrapper effect whose
unwrapped return owns a context is inside a context fn, and `@getContex` works in a server
component; (b) reading a provider stays restricted to a `#[@context]` body on purpose (a server
component may activate hooks but not read the provider tree), and only the hint is corrected so it
stops naming an impossible annotation; (c) the provider read is refused in a `#[@future]` body with
a message of its own, naming the boundary rather than the annotation.
**Recommendation.** (a), by the reasoning of decision 90: the owner type already answers the
question the annotation would have, and one capability flag should not split in two. If the answer
is (b), the hint must change in the same commit — a diagnostic that asks for a refused annotation is
worse than the gap it reports.
**Blocks.** Front 28's `request()` reading a provider; every `04-jhonstart` server component that
reads context rather than activating a hook. Nothing landed depends on it today.

## 94. `data-onze-s` has two owners — front 29's server slot and front 69's style chunk

**Raised by:** the `fronts.md` § Waves reconciliation sweep, 2026-09-21.
**Measured.** `grep -rn 'data-onze-s' specs/1.0.10-beta` returns the same attribute spelled by two
fronts. [`contracts.md`](./contracts.md) registers it once, in the marker registry that exists "so no
front invents a prefix" — the row reads `data-onze-s` · owner **29** · "a server-rendered slot
inside an island — the Context-Provider hole" (`contracts.md:61`) — and front 29 emits it on a `div`:
`attrs: [#("data-onze-s", "1")]` (`04-jhonstart/29-jhonstart-client-directive/README.md:166`),
asserted at `:253` and described at `:170` as "this front's one addition to the `data-onze-` marker
family". The **same** attribute is also the style-chunk attribute of front 69's `collectChunk`:
`<style data-onze-s="<holeId>">…</style>` in `contracts.md:387` § the `RenderHooks` table and in
`06-onze/69-onze-styling-pipeline/README.md:121`, with the checkbox `chunkAttr("h1")` is
`#("data-onze-s", "h1")` at `:278` and two snapshot lines asserting it —
`<style data-onze-s="h0">` and `<style data-onze-s="h2">` (`06-onze/test-snap.md:1052`, `:1056`).
Front 69's use is **not** in the registry at `contracts.md:58-67`. Both spellings are inherited
verbatim from [`absorbed/1.0.9-beta/contracts.md`](./absorbed/1.0.9-beta/contracts.md) — `:59` for
the marker row, `:352` for the hook row — so this is drift carried in, not a decision either front
made. Nothing is landed yet; the collision is between two specs.
**Options.** (a) front 69's style chunk is renamed to a free marker — `data-onze-c="<holeId>"`, say,
for *chunk* — and registered in `contracts.md`'s marker table with owner 69; front 29 keeps
`data-onze-s` exactly as registered; (b) front 29's slot marker is renamed instead — it is the
`<div>` half, and `data-onze-s` reads naturally as *style* on a `<style>` element; (c) both keep the
spelling and `contracts.md` records that the attribute is disambiguated by element name (`div` =
slot, `style` = chunk), adding a second owner to the registry row.
**Recommendation.** (a). Front 29's use is the one the registry actually carries (`contracts.md:61`)
and the one a client reconciler adopts a subtree by (`29/README.md:175`); front 69's is unregistered,
so renaming it costs one contract row, one README row, one checkbox and two snapshot lines, against
front 29's row plus a reconciler rule. (c) is the least restrictive of the three and is rejected on
decision 67's ground: it is only safe under an element-name side condition that no document states
and that any `[data-onze-s]` selector — a reconciler query, a test, a devtool — is free to ignore.
**Blocks.** Nothing landed. It decides `contracts.md:61` and `:387`, front 69's `chunkAttr`
checkbox (`:278`) and its hook row (`:121`), front 29's `serverSlot` checkbox (`:253`), and the two
`06-onze/test-snap.md` lines — so it should be answered before front 69 writes `style_sink.bp` and
before that snapshot is generated.

## 97. Does a `#[@generator]` body answer `try`?

**Raised by:** decision 95, 2026-09-21, by the maintainer while taking it: *"eu ainda não estou
certo se o Generator eu quero que de suporte para 'try'"*.
**Measured.** `@Generator<T, R>` (`libs/std/src/builtins.d.bp:109`) is the only effect wrapper with
**no** error channel: `@Result<R, E>`, `@Future<T, E = any>`, `@Iterator<T, E = any, C = void>` and
`@AsyncIterator<T, E = any, C = void>` all carry one, and the file's own § 1 prose lists the
fallible-channel effects as *result, future, iterator, asyncGenerator* — generator excluded. So
today a `#[@generator]` body may not `throw` or `try`, and decision 95's chain cannot reach it
without changing the type's arity.
**Options.** (a) `@Generator<T, R>` gains `E = any`, implements `@Result<T, E>`, and a generator body
answers `try` and `throw` like every other effect — uniform, and the arity change is source-compatible
because the parameter is defaulted; (b) the generator stays infallible: it is the one effect that
cannot fail, `try` in its body is refused naming the reason, and the file says so where a reader
meets it; (c) `@Generator` is folded into `@Iterator` (which already has both extra channels) and
`#[@generator]` becomes a spelling of the same wrapper.
**Recommendation.** (b) as the default until there is a body that needs it: it is the status quo,
it is the most restrictive (decision 67), and (a) remains available at any time without breaking a
signature, whereas removing the channel later would break every generator that used it. (c) is a
larger question about whether two generator effects earn their keep, and belongs to front 15.
**Blocks.** Front 20 step 2's generator row, and nothing else — the rest of decision 95's chain is
implementable without it.

## 99. `getContex` is missing a `t`

**Raised by:** front 20 (C-28), 2026-09-21, as the one of its twelve findings no step owned.
**Measured.** The context-retrieval intrinsic is spelled `getContex` everywhere it exists:
`libs/std/src/builtins.d.bp`, `builtins_fns.d.bp`, `docs.md:631`, `comptime/stdlib/prelude.zig:16`,
`comptime.zig`, `env.zig`, `infer.zig`, the diagnostic codes `context-getcontex-outside-context-fn`
and `context-getcontex-expects-type` in `diagnostics.zig`, their rules RC4/RC5 in
`comptime/tests/infer_errors.zig`, and three snapshots whose slug carries the name. It is a typo,
not a convention — nothing else in the language drops a letter.
**Options.** (a) rename to `getContext`, moving the two diagnostic codes and the three snapshot
slugs with it; (b) keep the spelling, and write in `builtins.d.bp` that it is deliberate so no
future reader 'fixes' it; (c) accept both, with `getContex` deprecated — rejected on sight by
decision 67, which forbids two spellings of one thing.
**Recommendation.** (a). It is mechanical, it is nine files plus three snapshot renames, and every
consumer of the name is inside this repository — no library spells it today. The reason it is a
question and not a sweep is decision 98: the maintainer amended a rename mid-flight over exactly
this class of change, so the name of a public builtin is his to take.
**Blocks.** Nothing. Front 20 landed around it.

## 100. Who owns the `ElementView<Element>` adapter — and what it costs the erlang row

**Raised by:** jhonstart front 28, 2026-09-21, on landing without it and saying so.
**Measured.** Front 23's handoff gives the adapter to front 26. Front 26 landed and its `AGENTS.md`
hands it on to front 28 "together with the `dependencies` entry … and the targets decision that
entry forces". Front 28's own README does not ask for it at all — rakun 23 and 62 are cited
*read-only* there. So three specs name three owners and no front has it in its Definition of done.
The obstacle is not the code: `ElementView<El>` is **rakun's** type, the adapter needs
`import { ElementView } from "rakun"`, jhonstart declares no rakun dependency, and rakun's member is
`"targets": ["commonJS"]` — so adding the entry reds the erlang row that front 28 and front 26 are
both gated on. Front 28 declined to write it and declined to invent a substitute, which is the
behaviour I want; it is recorded in its `AGENTS.md` as a disagreement, not resolved there.
**Options.** (a) rakun widens its member to `["commonJS", "erlang"]` first (that is front 04's
`targets` array, and the compiler ledger already measures the erlang row at 2 failed, both front
04's own) and the adapter then goes to whichever of 26/28 the two specs are amended to agree on;
(b) the adapter moves to **rakun** — it is rakun's type, so rakun exports the jhonstart-shaped view
and jhonstart imports nothing; (c) it is deleted from all three specs and the seam is spelled
structurally, with neither package naming the other's type.
**Recommendation.** (b). The dependency direction in `02-packaging` runs from the app to the
framework, and (b) is the only option where no new edge is added at all: jhonstart keeps declaring
no rakun dependency, rakun keeps its own type, and the erlang-row cost disappears rather than being
paid by somebody. (a) pays a real cost — widening a `targets` array is a front 04 landing, not a
line — and (c) throws away a typed seam to avoid a naming problem.
**Blocks.** Nothing that is running. It blocks front 26's "the router calls front 22's `matchPath`"
Definition-of-done bullet, which is separately unsatisfiable for the same reason, and it should be
answered together with that.
