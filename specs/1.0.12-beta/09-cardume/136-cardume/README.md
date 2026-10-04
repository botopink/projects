# Front 136 — cardume: shared, derived and transactional state (Recoil's model, botopink's spelling)

**Priority:** medium — no page needs it to render; every app with two islands that must agree
(a cart badge and a cart drawer) needs it to be correct, and rakun's request locals are its atoms (295) ·
**State:** not started · `repository/cardume` scaffolded (0.0.1: the model's types, no store)
**Depends on:** `26-jhonstart-router` (the core and its client runtime — `state` / `effect` rebinding
in `client_runtime.mjs`) · `08-bpp/120` (the island payload: one page store shared by every island) ·
`03-bundled-libs/125` (`encode<T>` for the values the server seeds) · decisions 128 (hooks), 297 (value-or-type parameters; `01-checker` step 26), 278
(`#[client]`), 281 (no string keys), 295 (request state as atoms), 296 (cardume) · open: `atm-a`, `atm-c`, `atm-d`
**Owns:** `repository/cardume/**` (the core: `modules/cardume/src/cardume.bp`, its tests) · new
member `repository/rakun/modules/rakun-cardume/**` (the request store, its hooks at `RequestBase`) ·
new member `repository/jhonstart/modules/jhonstart-cardume/**` (the page store, `sidecars/store_runtime.mjs`,
its hooks at `ElementBase`) · after 120: the store hand-off lines of `jhonstart/src/island_runtime.mjs`
(one subscription per island; 26's file, 189) · one `jhonstart-dom-test` test file
**Does not touch:** `hooks.bp`'s five nouns (`state`, `effect`, `memo`, `ref`, `reducer`) · rakun's and
jhonstart's other members · `http`'s `Cookie<T>` (294 — an HTTP concept, it stays there).

Reference: <https://recoiljs.org/docs/introduction/core-concepts>,
<https://recoiljs.org/docs/api-reference/core/useRecoilTransaction>.

## Goal

One atom type, two places to live (296): in **rakun**, a store per request — middleware writes,
pages and handlers read (295's locals); in **jhonstart**, a store per page in the browser, shared by
its islands. State that lives **outside** any one component: declared once as an atom, read and written by any
component or island of the page through `use`, derived by selectors (sync or async), parameterised by
families, and updated atomically across several atoms by a transaction — typed end to end, no string
key anywhere.

## Mechanism

### Recoil → botopink

| Recoil | botopink |
|---|---|
| `atom({ key: "count", default: 0 })` | `pub val count = atom(0);` — `from "cardume"`; the identity is the declaration (281), no key |
| `selector({ key, get: ({get}) => get(count) * 2 })` | `pub val doubled = selector({ get -> get.atom(count) * 2 });` (`get.selector(s)` for a selector — no overloading) |
| async selector (`get` returns a Promise) | `pub val user = selector({ get -> await fetchUser(get.atom(userId)) });` — a `Selector<@Task<User>>` |
| `atomFamily({ key, default: id => … })` | `pub val todo = atomFamily({ id: i32 -> Todo(id: id, text: "", done: false) });` — `todo(5)` is an `Atom<Todo>` |
| `selectorFamily` | `selectorFamily({ id: i32, get -> … })` |
| `useRecoilState(a)` | `val c = use atomState(a);` → jhonstart's `State<T>` (`c.value`, `c.set(…)`) |
| `useRecoilValue(a)` | `val v = use atomValue(a);` → `T` |
| `useSetRecoilState(a)` | `val set = use atomSetter(a);` → `fn(next: T)` (no subscription: the caller does not re-render) |
| `useResetRecoilState(a)` | `val reset = use atomReset(a);` → `fn()` |
| `useRecoilValueLoadable(s)` | `val l = use loadable(s);` → `Loadable<T> { Loading, Value(T), Failed(message: string) }` |
| `useRecoilCallback` | `val cb = use atomCallback({ snap, set, arg: A -> … });` → `fn(arg: A)` |
| `useRecoilTransaction_UNSTABLE` | `val move = use transaction({ tx, arg: A -> … });` → `fn(arg: A)` |
| `useRecoilSnapshot` | `val snap = use snapshot();` |
| `useGotoRecoilSnapshot` | `val restore = use snapshotRestorer();` → `fn(s: Snapshot)` |
| `useRecoilTransactionObserver_UNSTABLE` | `use transactionObserver({ now, previous -> … });` |
| `useRecoilRefresher_UNSTABLE` | `val refresh = use selectorRefresher(s);` → `fn()` |
| `useRecoilStateLoadable` | `use loadable(a)` + `use atomSetter(a)` |
| `waitForAny` / `waitForNone` / `waitForAllSettled` | the same names, variadic |
| `constSelector(v)` / `errorSelector(m)` | the same names |
| `noWait(s)`, `isRecoilValue`, `DefaultValue`, `useRecoilBridgeAcrossReactRoots`, `useGetRecoilValueInfo_UNSTABLE` | not added — `loadable`; the type says it; `atomReset`; islands share one store; the runtime's inspector |
| `waitForAll([a, b])` | `waitForAll(a, b)` — variadic (267) |
| `<RecoilRoot initializeState>` | optional `<AtomRoot initialize={seed}>`; without it the page's islands share one store |
| atom effects | `atom(default, effects: [...])` — which ship: `atm-d` |

**An atom by its declaration or by its type** (297). Every hook takes `comptime source: Atom<T> | type T`:

```bp
pub val currentUser = atom<?User>(null);
use atomState(currentUser)          // the declared atom — T inferred
use atomState<?User>(currentUser)   // the same, T written and checked
use atomState(User)                 // the type's implicit atom: one per type per store, ?User (null until set)

#[atom(default: Theme.Light)]
pub type Theme { Light, Dark }
use atomState(Theme)                // State<Theme> — the type's default, no `?`
```

The type form suits a value the store holds once (the signed-in user, the theme) — middleware
`use atomSetter(User)`, a page `use atomValue(User)`, nothing declared; a declared atom holds
several values of one type (`cartItems`, `wishlist`).

Hook names are **nouns** (`atomState`, `atomValue`, `atomSetter` — jhonstart's rule, `hooks.bp`'s
header): `use` is the activation, the name never repeats it (no `useAtomValue`) — whether 295's
`use setLocal` / `use setCookie` follow is `atm-a`. Both bridges spell the same hooks, each anchored at
its base (128): `jhonstart-cardume`'s at `ElementBase`, `rakun-cardume`'s at `RequestBase`.

### The stores

- **In rakun, one store per request** (`rakun-cardume`): it lives in the request's process frame and
  dies with it; middleware, route handlers and actions (`-> @Component<RequestBase, Response>`, 295)
  write with `use atomSetter(a)`; a page reads the request's value with jhonstart's `use atomValue(a)` —
  `#[serverOnly]` (186) when the atom was written by rakun this request (how the marker crosses: `08-j`).
- **In the browser, one store per page** (`jhonstart-cardume`). Every island of the page subscribes to it, so two islands
  reading `cartItems` agree; a component re-renders when an atom or selector it **read** changes
  (`atomValue`, `atomState`, `loadable` subscribe; `atomSetter`, `atomReset`, `transaction`,
  `atomCallback` do not). Client navigation (`jhonstart-link`) keeps the store; a document load
  starts a new one.
- **On the server**, during the render pass, `atomValue` reads the atom's default — or the value an
  `AtomRoot initialize` gave it for this request —, setters are no-ops, and the atoms an island read
  travel in the island payload as its starting values (encoded with `encode<T>`, 125; `T` must be
  encodable — `atm-c`).
- **Selectors** track their dependencies at run time (each `get(x)` call), are memoised on the
  dependencies' values, and recompute only when one changes; a cycle is an error naming the chain.
  An async selector suspends a component reading it with `atomValue` (the nearest `Suspense`, 26), or
  answers `Loading` / `Value` / `Failed` through `loadable`.

### Transactions

```bp
val move = use transaction({ tx, m: Move ->
    val from = tx.get(column(m.from));
    tx.set(column(m.from), from.filter({ id -> id != m.card }));
    tx.set(column(m.to), tx.get(column(m.to)).append(m.card));
});
move(Move(card: 7, from: .Todo, to: .Done));
```

- **Synchronous and atomic**: the body's `fn(tx: Tx, arg: A)` returns nothing — no `@Task`, so no
  `await` inside —; every `tx.set` / `tx.reset` is applied **together** when the body returns, and
  each subscriber is notified once.
- **Reads see the transaction's own writes** (`tx.get` after `tx.set` answers the new value).
- **Atoms only**: `tx.get` / `tx.set` take an `Atom<T>` (a family member included), never a selector —
  a selector is derived, not stored (Recoil's rule); a selector read inside is a type error.
- **All or nothing**: a body that fails (a refused `@Result`, a panic) applies nothing.

**The examples**, one per section of Recoil's API reference: `state-example.bp` (atom, selector,
the four hooks, the refresher), `async-example.bp` (async selectors, `loadable`, `waitFor*`,
`constSelector`, `errorSelector`), `families-example.bp`, `snapshot-example.bp` (`atomCallback`,
`snapshot`, undo with `snapshotRestorer` + `transactionObserver`), `transaction-example.bp`,
`root-and-effects-example.bp` (`AtomRoot initialize`, `persistLocal` — illustrative until `atm-d`),
`atoms-example.bp` (a cart across two islands).

## Open

### Step 0 — Measure

- [ ] how `client_runtime.mjs` re-renders after a `state` cell's `set` today (the subscription a store
      can hook into); whether two islands of one page share a JS realm and a microtask queue
- [ ] the island payload's encoding of a `#[clientProps]` record (120 step 0) — the shape the atoms'
      starting values reuse

### Step 1 — Atoms and their four hooks

- [ ] `repository/cardume` on GitHub, `feat` pushed, the submodule `repository/cardume` added here;
      the scaffold's model (`Atom`, `Selector`, `Getter`, `AtomFamily`, `Loadable`, `Tx`) compiled and its
      three tests green on both targets
- [ ] every hook takes `comptime source: Atom<T> | type T` (297, `01-checker` step 26): the type form is
      the type's implicit atom per store, `?T` unless `#[atom(default: …)]` on the type; `atomState<T>(a)`
      checked against `a`
- [ ] `atom<T>(default: T) -> Atom<T>`; `atomValue`, `atomState`, `atomSetter`, `atomReset`, each
      `-> @Component<ElementBase, …>` (128), the server pass reading the default
- [ ] `atoms_runtime.mjs`: the page store; a component re-renders on a change of what it read, and only then
- [ ] `examples/atoms-example.bp` passes (server pass on both targets; the browser half in
      `jhonstart-dom-test`: two islands sharing `cartItems`, one `atomSetter` updating both)

### Step 2 — Selectors

- [ ] `selector<T>(get: fn(get: Getter) -> T) -> Selector<T>`; dependency tracking, memoisation; a
      cycle refused at run time naming the chain
- [ ] a component reading a selector re-renders when, and only when, one of its dependencies changes
- [ ] `examples/state-example.bp` passes

### Step 3 — Families

- [ ] `atomFamily<P, T>(default: fn(p: P) -> T)` and `selectorFamily`; `todo(5)` the same atom on every
      call with `5`; `P` comparable by value; `examples/families-example.bp` passes

### Step 4 — Async selectors and `loadable`

- [ ] `selector({ get -> await … })`: `atomValue` suspends to the nearest `Suspense`; `loadable` answers
      `Loading` → `Value` / `Failed` without suspending; a dependency change re-runs it, a stale answer dropped
- [ ] `waitForAll`, `waitForAny`, `waitForNone`, `waitForAllSettled` (variadic), `constSelector`,
      `errorSelector`, `selectorRefresher`; `examples/async-example.bp` passes

### Step 5 — Transactions, callbacks, snapshots

- [ ] `examples/transaction-example.bp` passes: a card moved between two columns in one transaction —
      both columns change in one notification; a read after a write sees it; a failing body applies nothing
- [ ] `tx.get(aSelector)` a compile error at the argument (atoms only)
- [ ] `atomCallback({ snap, set, arg -> … })`: reads a snapshot without subscribing; `snapshot()`,
      `snapshotRestorer()`, `transactionObserver(…)`; `examples/snapshot-example.bp`'s undo passes in
      `jhonstart-dom-test`

### Step 6 — The server seed and the island hand-off

- [ ] `<AtomRoot initialize={seed}>` (`fn(set: Setter)`) seeds the request's values; the atoms each
      island read travel in its payload and start the browser store; an atom no island read sends
      nothing; a non-encodable `T` in an island's read set refused at build (`atm-c`)

### Step 7 — `rakun-cardume`: the request store

- [ ] the member: a store per request in the process frame; `use atomSetter` / `atomValue` / `atomState`
      / `atomReset` anchored at `RequestBase`; 295's `Local<T>` is cardume's `Atom<T>`; `examples` in
      123 (`locals-and-sequence-example.bp`) read and write through it
- [ ] a value set in middleware read by the page of the same request; gone at the next

### Step 8 — Effects (after `atm-d`)

- [ ] the effects `atm-d` keeps, each with a `jhonstart-dom-test` case

## Decisions

- `atm-a` — hook names: nouns here (`atomSetter`) against 295's verbs (`use setLocal`, `use setCookie`)
- `atm-c` — what an atom's `T` may be when the server seeds it (encodable only, or any `T` with a
  client-only default)
- `atm-d` — which atom effects ship (none; `persistLocal`; URL search-param sync)

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `cardume`'s `modules/cardume`, `jhonstart-cardume`, `rakun-cardume` (erlang); on commonJS in `jhonstart-dom-test`
- [ ] `zig build test-libs`: cardume, jhonstart, rakun green; the blog untouched (it uses no atom)
- [ ] `repository/cardume`'s own CI (`.github/workflows/test.yml`) green on its `feat`

## Notes

- **Not added.** Recoil's string `key` (281); `RecoilRoot` nesting with `override`; `useRecoilStateLoadable`
  (= `loadable` + `atomSetter`); `noWait` (= `loadable`); atom `dangerouslyAllowMutability` (values are
  immutable). Recoil's `_UNSTABLE` mark on transactions: here they are part of the surface.
- **Not React state.** `state` stays the component's own cell; an atom is for state two components share.
- **The name.** *Cardume*: a school of fish — many swimmers, one movement (and the boto's company).
