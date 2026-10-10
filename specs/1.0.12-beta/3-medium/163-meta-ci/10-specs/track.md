# Track 10 — specs: the milestone's text follows its decisions

The specs are what a front opens from. When a decision retires a spelling (`@Component<C, R>`,
`LocalKey<T>`, `#[schema]`, `StyledPropertyView` …), the code moves with the front that implements
it, and the spec text has to move with the decision. Nothing ties the two, so the text drifts. This
track holds the sweep that brings it back in line. It edits no repository under `repository/`.

| Front | Priority | State | What | Depends on (open) |
|---|---|---|---|---|
| [`141-specs-sweep/`](../141-specs-sweep/context.md) | high | partial — steps 0–5 done | the retired spellings out of `specs/1.0.12-beta/**`; `decisions-taken.md`'s amended rows stated as in force; the overtaken pending questions listed for the maintainer | nothing · step 6: `141-a` |

**Decisions:** none of its own; it applies the ones in force (§ Inventory of the front names them).
Open: `141-a` (how a decision that retires a spelling keeps the specs from drifting again).
