# Closure — 1.0.11-beta

**Closed 2026-10-03**, at meta `feat` = `84aa028`, `botopink-lang` `ec77f649`, rakun `fac248b`,
jhonstart `eddd681`, emilia `42d51ec`, onze `b1a3110`, erika `0a463f5`, vscode-extension `7993f96`.
The milestone was not finished: it was **consolidated** into 1.0.12-beta at the maintainer's request,
because its spec had grown to ~1.9 MB of history, measurements and status narratives that cost too
much to read. This tree is frozen; nothing here is edited again.

**Where the open work went:** [`specs/1.0.12-beta/`](../1.0.12-beta/README.md) — the same goals and
every open step, rewritten to current state only; the front numbers stay, decisions continue at 267.
What changed in the cut:

- the thirteen closed `00-gate` fronts (99, 100, 101, 108, 109, 110, 111, 112, 113, 115, 131, 132,
  133) are not carried — the rules they established are 1.0.12's `00-gate/README.md` baseline, and
  their residue went to `00-gate/114`;
- `01-compiler/25-gate-perf` is closed (its work landed through 115 and 133); `07-review-backlog`,
  `08-hygiene` and `09-ecosystem-residuals` were merged into `01-compiler/07-residuals`;
- the nine snapshot maps (`test-snap*.md`) left their fronts for one front, `20-snap` (135), which
  re-evaluated every case; the maps stay here;
- every `carried.md` stays here; the decisions were rewritten to the rules in force, superseded rows
  reduced to a pointer, and the pending file holds only open questions, the 1.0.10 confirmations as
  one-liners and the contradictions found (`ctr-a…`).

## State at the close

Measured by read-only audits of every track against the code at the commits above (no build was
run: the auditing machine had no `zig` or `erl`). The audits are kept in
[`closure-audit/`](./closure-audit/): `audit-00-02.md`, `audit-01.md`, `audit-03.md`,
`audit-04.md`, `audit-05-07.md`, `audit-08-decisions.md`, and `snapshot-maps.md` (the case-by-case
evaluation behind `20-snap`).

| Track | At the close |
|---|---|
| `00-gate` | 13 of 14 fronts done; 114 partial (botopink-lang CI green run, `budget_cold` 300 vs decision 265's 450, vscode-extension on OTP 24, no cold gate recorded on integrations 7–14) |
| `01-compiler` | 129 done; 01, 02, 03, 04, 05, 12, 14, 17, 26, 130, 134 partial and merged on `feat`; 07, 08, 09, 16, 18, 23, 24 not started |
| `02-std-and-packaging` | 97 merged with residue; 98 not started |
| `03-bundled-libs` | 104 and 106 package halves and 125 steps 0–2 on `feat`; 102 and 103 only on unpushed branches; 105, 107 not started |
| `04-rakun` | not started (13 step 4 and half of 92 step 1 true in code); 128 blocked on 102 step 3 / 103 step 2 |
| `05`–`07` | not started; prerequisites 100, 101, 109 landed |
| `08-bpp` | not started; decision 266 (the `.bpp` prelude) taken at the close |

The last recorded green `scripts/gate.sh --cold` is on botopink-lang `0041d38c`; none was recorded on
`ec77f649`.
