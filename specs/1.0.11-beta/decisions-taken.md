# Decisions taken — 1.0.11-beta

Answered by the maintainer, kept here as the record the fronts implement against. The numbering
continues from [1.0.10-beta's record](../1.0.10-beta/decisions-taken.md), which stopped at **143**
(68–90, 95, 96, 98, 102–143 are decisions; 91–94, 97 and 99–101 were questions resolved inside
other decisions and are used, not free) — a number is never reused or renumbered across
milestones. Questions are raised in [`decisions-pending.md`](./decisions-pending.md) with a lettered
id (`07-a`, `03r-y`, `lg2-a` …) and move here with the next free number when answered. **The next
free number is 144.**

**Inherited by reference, not copied.** The earlier records stay where they are; these standing
principles govern this milestone and are cited by number throughout:

- [67](../1.0.5-beta/decisions-taken.md#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it)
  — the most restrictive behaviour, and no configuration that bypasses it. Every option list in
  `decisions-pending.md` is written against it, and it is why this milestone's first track admits
  no *tolerated* red: a red cell is fixed, or its test is deleted by a decision — never allow-listed.
- [113](../1.0.10-beta/decisions-taken.md) — the libraries split by concern: emilia is CSS, jhonstart
  is HTML, rakun is the service on erlang, onze wires them.
- [114](../1.0.10-beta/decisions-taken.md) — an emilia example is emilia-only.
- [115](../1.0.10-beta/decisions-taken.md), [116](../1.0.10-beta/decisions-taken.md),
  [117](../1.0.10-beta/decisions-taken.md) — when a bundled library is justified, what is generic
  goes to std, `.bp` only with inline `#[@External]` templates. `07-bundled-libs` is cut against
  these three.
- [118–128](../1.0.10-beta/decisions-taken.md) — the return type is the annotation; only `@Result`
  fails.
- [79](../1.0.10-beta/decisions-taken.md) — the `onze` name passes from the mocking library to the
  orchestrator (the takeover as it actually happened is question `95-d` in `decisions-pending.md`).

| # | Question | Answer |
|---|---|---|
| — | *none yet* | |
