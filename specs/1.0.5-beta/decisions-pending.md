# Decisions the maintainer owes — 1.0.5-beta

**One open**, all raised on 2026-09-18 by the fronts [`15-language-surface`](./15-language-surface/README.md)
and [`16-formatter`](./16-formatter/README.md) while auditing the written surface against what the
parser accepts. The twenty-seven already answered are in [`decisions-taken.md`](./decisions-taken.md).

| # | Question | Blocks | Recommended |
|---|---|---|---|
| [28](#28-what-decision-14-left-unassigned) | Which forms were "the two decision 8 implies", and what is the third absent one? | 15's step 1 | the pair is one production; the third slot is empty |

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

