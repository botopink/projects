# Track 09 — cardume: shared state as atoms (decision 296)

A library of its own, `repository/cardume` (`botopink/cardume`), for one concern — **shared state**
(113): atoms, selectors, families, loadables and transactions, Recoil's model in botopink's
spelling (281: no string keys). The core imports neither jhonstart nor rakun; each framework hosts
its store and its `use` hooks in a bridge member of its own repository.

| Front | Priority | State | What | Depends on (open) |
|---|---|---|---|---|
| [`136-cardume/`](../README.md) | medium | not started · repository scaffolded (0.0.1, the model's surface) | the core; `rakun-cardume` (request store, 295's locals); `jhonstart-cardume` (page store in the browser, shared by islands) | `05-jhonstart/26` · `08-bpp/120` · `03-bundled-libs/125` · `atm-c`, `atm-d` |

**The repository.** `botopink/cardume` is to be created on GitHub (empty) by the maintainer; the
scaffold (workspace, `modules/cardume`, CI copied from erika) waits to be pushed to its `feat`, then
it becomes the submodule `repository/cardume` of this repository.

**Decisions:** 295 (request state as atoms), 296 (cardume; the request locals' hooks are its
`atomSetter` etc.), 297 (an atom by declaration or by type). 400 answers `atm-a` (the cookie hooks in the same family: `cookieValue`, `cookieState`, `cookieSetter`,
`cookieReset`). Open: `atm-c` (an atom's `T` across the server/browser seam), `atm-d` (atom effects).
