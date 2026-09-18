# Decisions the maintainer owes — 1.0.5-beta

**Eight open**, all raised on 2026-09-18 by the fronts [`15-language-surface`](./15-language-surface/README.md)
and [`16-formatter`](./16-formatter/README.md) while auditing the written surface against what the
parser accepts. The twenty-seven already answered are in [`decisions-taken.md`](./decisions-taken.md).

| # | Question | Blocks | Recommended |
|---|---|---|---|
| [28](#28-what-decision-14-left-unassigned) | Which forms were "the two decision 8 implies", and what is the third absent one? | 15's step 1 | the pair is one production; the third slot is empty |
| [29](#29-does-a-block-shaped-statement-end-itself) | Does `if` / `loop` / `case` need a `;`? | 15's step 2 | none — ask once, decide once |
| [30](#30-is-there-an-index-expression) | Is there an index expression at all? | decision 8 §§ that presuppose one | yes |
| [31](#31-does-any-exist) | Does `any` exist? `libs/std` depends on it | `libs/std`'s `Iterator` default | delete it, give `Iterator` a real default |
| [32](#32-are-optionnone-and-some1-value-names) | Are `Option.None` / `Some(1)` value names? | the documents that write them | the documents are wrong |
| [33](#33-a-bodyless-fn-with-no-return-type) | `fn f(x: string)` with no body and no return type | three `libs/std` declarations | make it parse |
| [34](#34-the-format---check-exemption-does-not-exist) | Decision 18 assumed a skip list that is not there | 16's exemption, 09's format step | a key in `botopink.json` |
| [36](#36-does--exclude-its-end-in-a-pattern) | Does `..` exclude its end **in a pattern**? | 12's range cells, still working around it | exclusive, stated |

---

## 28. What decision 14 left unassigned

**Measured.** Decision 14 said "four parse, three are deliberately absent" — but front 15 found the
seven are **six**: `(sql "").length` and `(a == b).toString()` are the *same* production (any
`(expr).method` fails, `("ab").length` included). And the seventh is not a missing form at all: `if`,
`loop` and `case` do parse, with a `;`. Front 17's text, and decision 14's third "absent" slot, rest
on a description that does not reproduce.

**Recommendation.** The parenthesised pair is one production and counts once; the third absent slot is
**empty**, and decision 14 is amended to "four parse, two absent" rather than inventing a third.

**Blocks:** `15-language-surface` step 1.

---

## 29. Does a block-shaped statement end itself?

**Measured.** `if`, `loop` and `case` parse **with** a `;` after the closing brace. Whether that `;`
should be required, optional or rejected is a question nobody has been asked; the grammar simply grew
one answer.

**Options.** (a) Required, as today. (b) Optional. (c) Rejected — a block-shaped statement ends itself.

**No recommendation** — this is taste, and the point is to ask it **once** rather than let each front
meet it separately. What is not taste: whichever answer, it should be the same for the three.

**Blocks:** `15-language-surface` step 2.

---

## 30. Is there an index expression?

**Measured.** `xs[0]` is a **parse error in any position** — there is no index expression in the
language. Decision 8 presupposes one twice (`:112`, `:447`), and so does ordinary reading of every
array example.

**Options.** (a) Add it. (b) Keep arrays accessed only through methods (`at`, `first`, …) and correct
decision 8.

**Recommendation: (a).** An array with no index syntax is a surprise in every direction — the
documents assume it, the libraries work around it, and `at` returning an optional is a different
feature, not a replacement.

**Blocks:** the decision 8 sections that presuppose it; `15-language-surface` step 4.

---

## 31. Does `any` exist?

**Measured.** `any` parses **and checks**, and `libs/std/src/builtins.d.bp:88` uses it as a default
type argument — while decision 8 (`:129-133`) says in as many words that no type turns the checker
off.

**Options.** (a) Delete `any` and give `Iterator` a real default. (b) Keep it and correct decision 8.

**Recommendation: (a).** A type that means "stop checking" is the one thing decision 8 refuses by
name; the single use is a default that can be written properly.

**Blocks:** `libs/std`'s `Iterator` declaration; `01-checker`'s source step.

---

## 32. Are `Option.None` and `Some(1)` value names?

**Measured.** The documents write them in value position. Decision 2 already settled that `?T` is the
only optional and `.Some` / `.None` are patterns — so the documents contradict a decision already
taken.

**Recommendation.** The documents are wrong; correct them rather than re-open decision 2.

**Blocks:** the `docs.md` and decision-8 lines that write them.

---

## 33. A bodyless `fn` with no return type

**Measured.** `fn f(x: string)` — no body, no return type — does not parse, and `libs/std` **declares
three of them**.

**Options.** (a) Make it parse. (b) Require `-> void` or a body.

**Recommendation: (a).** The standard library already writes the form; either it parses or those three
declarations are wrong, and they read as deliberate.

**Blocks:** `15-language-surface` step 4.

---

## 34. The `format --check` exemption does not exist

**Measured.** [Decision 18](./decisions-taken.md) exempted emilia's `tokens.bp` from `format --check`
— but there is **no exemption mechanism**: `format_cmd.zig` has no skip list of any kind. The decision
assumed a feature.

**Options.** (a) A key in `botopink.json` (a list of paths the check skips, with a reason string).
(b) A marker comment in the file itself. (c) No exemption — the file is formatted and the hoist
accepted.

**Recommendation: (a)**, built by `10-cli-residuals`, which owns `format_cmd.zig`. It keeps the reason
next to the project rather than hidden in a file, and `--check` can print it, so a reader meets the
defect instead of wondering why one file is exempt.

**Blocks:** `16-formatter`'s exemption; `09-ecosystem-residuals`' format step.

---


This file stays because the fronts will fill it again. A front that meets a question it cannot answer
from the code writes it here rather than guessing, in the shape the others used:

> **Measured.** What was observed, with the command or program that produced it and the file or commit
> that can be re-read.
>
> **Options.** Each one stated so that choosing between them is possible without reading the code.
>
> **Recommendation.** One, argued — a question with no recommendation is a question the front did not
> finish thinking about.
>
> **Blocks.** The step, front or landed work that waits on the answer.

Numbers are never reused: the next question added here is **28**, whatever has left the file since.


## 36. Does `..` exclude its end **in a pattern**?

**Measured.** [Decision 20](./decisions-taken.md) removed `...` and made `..` the only range, "in
patterns and in iteration alike". `loop (0..4)` is exclusive, so a pattern `1..9` is *implicitly*
exclusive — but nothing says so, and front 12's cells still work around the boundary instead of
asserting it.

**Options.** (a) Exclusive, matching `loop`. (b) Inclusive in a pattern, exclusive in a loop — the same
spelling meaning two things by position.

**Recommendation: (a).** (b) is what decision 20 refused when it removed the second spelling. What is
missing is not the answer but the sentence: decision 8 §5 has to say it, and front 12 turns the
work-arounds into assertions.

**Blocks:** `12-language-tests`' range cells.

---


