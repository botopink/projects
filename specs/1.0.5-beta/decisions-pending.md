# Decisions the maintainer owes — 1.0.5-beta

**None open.** The last one, 65, was answered on 2026-09-19; it was opened 2026-09-18 by
[`16-formatter`](./16-formatter/README.md) while landing
[decision 61](./decisions-taken.md#61-the-formatters-canonical-layout--four-rules)'s four rules. **63 and 66
were answered 2026-09-19** and have moved to [`decisions-taken.md`](./decisions-taken.md) with their
evidence: 63 as
[an index answers `T`, and an absent key fails](./decisions-taken.md#63-an-index-answers-t-and-an-absent-key-fails-rather-than-answering),
66 as
[`format --check` looks at the whole project](./decisions-taken.md#66-format---check-looks-at-the-whole-project--and-something-has-to-call-it);
the same message raised
[decision 67](./decisions-taken.md#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it),
the standing principle every option list from here is written against — the most restrictive behaviour, and
no configuration that bypasses it. Every question before the two — 38 to 63, and 66 — is answered and
recorded there, which is the record the fronts implement against: 38 to 47 were answered on 2026-09-18
together with four the same pass raised and answered (48, 49, 50, 51), and 52 to 62 followed within the day,
several of them within hours of being written — among them the three that were open when this header last
counted them, 53 opened by `08-hygiene`, 55 by `03-beam` and 56 by `10-cli-residuals`. What is left after
the two is the list of defects with an owner and no row, kept so they are not re-discovered; decision 62
says which three of them are this wave's. Neither of the two is a defect with an owner: 64 is a mechanism
[decision 43](./decisions-taken.md#43-beammemory-lives-in-two-layers--and-off-the-beam-the-annotation-is-a-no-op-while-the-module-is-an-error)
took without naming its dependency, and 65 is how every library *looks* — a call of the class decision 61
was.

**53 and 55 both changed after they were opened**, and the new evidence is in their sections: Zig was
measured (it has *both* spellings, in different positions, so the compiler is the Zig-consistent side and
decisions 20/36 are not), and `yield` beside `break` in a collection loop was measured on all four
backends (four different answers, three of them order-dependent).

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

Numbers are never reused: the next question added here is **68** — 67 is the standing principle the
maintainer raised with 63's answer, and it is in
[`decisions-taken.md`](./decisions-taken.md#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it).
