# The unplaced Tailwind rows — `05-emilia/reference-coverage.md` § Missing and partial rows (1.0.10). Category (c) rows are this front's step 4, conditional on decision 05emilia-n (the four feature rows), except § 3.3 removing breakpoints, settled by decision 300 (step 3, unconditional); (b) rows stay out of scope.

## Missing and partial rows, consolidated

Category: (a) follow-up for an existing front · (b) out of scope by design · (c) unplaced — no front claims it.

| Row | Status | Owner | Category | Detail |
|---|---|---|---|---|
| § 3.2 `:has()`, `:not()`, ARIA, data-attribute and `in-[…]` named forms | partial | [34](../../../1.0.10-beta/05-emilia/34-emilia-modifiers/README.md) / [57](../../../1.0.10-beta/05-emilia/57-emilia-escape-hatches/README.md) | (c) | Only via `arbSel`; no named tokens or recipes. |
| § 3.2 `group-*` / `peer-*` beyond the declared states; named groups and peers | partial | [34](../../../1.0.10-beta/05-emilia/34-emilia-modifiers/README.md) | (c) | Six group, eight peer states named; `group/item`, `peer/name` undeclared. |
| § 3.2 full variant table — five bracket rows | partial | [34](../../../1.0.10-beta/05-emilia/34-emilia-modifiers/README.md) / [57](../../../1.0.10-beta/05-emilia/57-emilia-escape-hatches/README.md) | (c) | Aggregate of the rows above. |
| § 3.3 custom breakpoints — a new name | partial | [34](../../../1.0.10-beta/05-emilia/34-emilia-modifiers/README.md) · [54](../../../1.0.10-beta/05-emilia/54-emilia-theme/README.md) | (b) | Overrides move the query; a new `--breakpoint-*` name adds no variant (use `arbMin`/`arbMax`). |
| § 3.3 removing breakpoints | partial | [34](../../../1.0.10-beta/05-emilia/34-emilia-modifiers/README.md) | (c) → 300 | Cleared `--breakpoint-*` emits `@media (width >= )`; decision 300: a token naming a cleared breakpoint is a compile error where the list is comptime-known — this front's step 3. |
| § 3.5 `@theme inline` | missing | — | (c) | Always `var(--x)`; no value-resolving render mode. |
| § 3.7 named class in `@layer utilities` | partial | [59](../../../1.0.10-beta/05-emilia/59-emilia-custom-utilities-and-variants/README.md) | (b) | `named()` takes no `layer:` argument; `components` only. |
| § 10.4 stop positions, radial/conic, interpolation | partial | [39](../../../1.0.10-beta/05-emilia/39-emilia-backgrounds/README.md) | (b) | Not in the reference; not declared. |
| § 12.1 `shadow-<color>/<opacity>` | partial | [41](../../../1.0.10-beta/05-emilia/41-emilia-effects/README.md) | (b) | Reference gives the class, no property/value row. |
| § 16.10 negative translate (`-translate-y-2`) | partial | [45](../../../1.0.10-beta/05-emilia/45-emilia-transforms/README.md) | (c) | No `Neg` sub-section under `TranslateX`/`TranslateY` (as `Rotate.Neg`). |
| § 16.4 `rotate-x/y/z`, `translate-z`, `scale-z` | — | [45](../../../1.0.10-beta/05-emilia/45-emilia-transforms/README.md) | (b) | Not in the reference; not a reference row. |
| § 11.7 `outline-hidden`, § 15.6 `@starting-style` | — | [40](../../../1.0.10-beta/05-emilia/40-emilia-borders/README.md) / [44](../../../1.0.10-beta/05-emilia/44-emilia-transitions/README.md) | (b) | Not in the reference; not declared. |
