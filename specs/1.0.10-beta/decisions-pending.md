# Decisions the maintainer owes — 1.0.10-beta

**Three open: 94, 100 and 101.** All three are **non-blocking**: nothing running waits on them, and
each answer is a rewrite of prose, not of a landed refusal. Every other number up to 112 is answered
in [`decisions-taken.md`](./decisions-taken.md) — 91, 92, 93 and 97 by decisions 103 and 104, 99 by
108. The next free number is **113**.

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
verbatim from the 1.0.9 draft's `contracts.md` — `:59` for
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

## 101. The hydration entry is spelled two ways, and the split is not a typo

**Raised by:** jhonstart front 29 on landing, 2026-09-21, which reported it as "one of the two is
wrong" and left it. Measuring it shows something more awkward than a typo.
**Measured.** `grep -rn '__jhLinkMount\|__onzeLinkMount' specs/1.0.10-beta`:

- **`__onzeLinkMount`** — front 27's README five times (including its `pub declare fn` at `:302` and
  two acceptance checkboxes), front 29's README at `:275`, `04-jhonstart/modules.md` at `:166` and
  `:227`, `04-jhonstart/test-snap.md` at `:476`, and front 27's own example file.
- **`__jhLinkMount`** — front 67's README at `:160`, front 68's README at `:290` and its acceptance
  checkbox at `:430`, `06-onze/test-snap.md` three times (including the generated entry's import
  line and its ordering assertion), and **`contracts.md:334`**, the registry.

So it is not one document against six; it is a consistent split with the **track boundary running
through the middle of track C**: jhonstart's front 67 sides with onze and with the registry, while
jhonstart's fronts 27 and 29 and that track's own `modules.md` and `test-snap.md` do not. Both
spellings are inherited verbatim from the 1.0.9 draft's `contracts.md:316`, so neither front
invented it.
**The sibling settles the logic, if logic is what decides it.** The form mount is `__jhFormMount`
**everywhere**, with no competing spelling — front 67's own, front 68's entry, front 29's prose and
`contracts.md`. Both mounts are *jhonstart's* functions, called once by onze's generated entry, so
`__jhLinkMount` is the one that pairs with its sibling and matches the registry, and
`__onzeLinkMount` is the outlier. The counter-argument is that `__onzeFill` and
`__onzeClientPropsRaw` are also called by that entry and carry onze's prefix — but those are onze's
own functions, which is the distinction the `__jh*` prefix is making.
**Options.** (a) `__jhLinkMount` everywhere — it matches `__jhFormMount`, matches `contracts.md`,
and the prefix then reliably names the package that *owns* the function; costs eight edits across
front 27's README, front 29's README and track C's two shared documents. (b) `__onzeLinkMount`
everywhere — costs six edits, including `contracts.md` and a generated-entry import line in
`06-onze/test-snap.md`, and leaves `__jhFormMount` beside `__onzeLinkMount` with no rule explaining
the difference. (c) leave both and let front 68 pick — rejected: front 68 imports it by name from a
package, so "both" is a compile error, not an ambiguity.
**Recommendation.** (a). The prefix is doing real work — `__jh*` for a function jhonstart declares,
`__onze*` for one onze declares — and (b) breaks that rule for one name out of four.
**Blocks.** Nothing, and that is why it is worth answering now rather than later: **front 27
deliberately did not ship the cell** (it waits on front 68's bundle), so today this is a rename in
prose only. The day front 68 writes its entry, it becomes a rename across two packages and a
generated file.
