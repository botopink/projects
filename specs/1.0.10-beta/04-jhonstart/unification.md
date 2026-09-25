# Track C — jhonstart · unification

How the coordinates the nine READMEs cite resolve in this milestone, the one discrepancy between two
fronts that is still open, and the Next.js rows no front owns.

## 1 · Coordinates

Every cross-front and top-level reference in the READMEs is a backticked coordinate in prose
(`contracts.md § 2`, `23-rakun-ssr-pipeline/README.md:278`, `language-gaps.md`, `fronts.md`), not a
Markdown link. They resolve as follows:

| Coordinate as written | Resolves to |
|---|---|
| `contracts.md § N` | `../../contracts.md § N` |
| `language-gaps.md`, `fronts.md`, `overview.md`, `deferred.md` | `../../language-gaps.md`, `../../fronts.md`, `../../overview.md`, `../../deferred.md` |
| `NN-rakun-*/README.md:L` (22 · 23 · 24 · 53 · 62 · 63 · 66) | `../../03-rakun/NN-rakun-*/README.md:L` (53 → `../../06-onze/53-onze-example-app/`) |
| `01-std-lib-enablement/README.md:L`, front 02, front 03 | `../../01-std/NN-std-*/README.md:L` |
| `48-emilia-attributes` | `../../05-emilia/48-emilia-attributes/` |
| front 68 (client bundle) | `../../06-onze/68-onze-client-bundle/` |
| `specs/1.0.10-beta/` (the "gaps appear in a 1.0.10 spec" acceptance items) | `../../language-gaps.md` — this milestone |
| `19-use-activation` | `../00-compiler-carry-over/19-use-activation/README.md` — the `use` rule, as decisions 102 and 104 fix it (`README.md § 6` of this directory) |

## 2 · Open discrepancy

| Where | What | Disposition |
|---|---|---|
| 94 *What the consuming fronts do* row for 32 vs 32 *Mechanism* | 94 says `renderHead` "emits `meta`/`link`/`title` **elements** from this surface rather than a string"; 32 specifies `renderHead(m) -> string` and tests byte-identical output | 32's own README is authoritative for 32: `renderHead -> string`, built from 94's `title`/`meta`/`link` constructors and rendered through the same walker front 23 uses. `test-snap.md § 32` asserts the string. |

## 3 · Next.js reference rows no front owns

The client/React half of `NEXTJS-DOCS.md` walked against the nine fronts. A row is *missed* when no
jhonstart front owns it and no other track's front is named for it.

| `NEXTJS-DOCS.md` | Item | Owner | Status |
|---|---|---|---|
| § 7 · § 13 *Streaming de dados com `use`* | React `use(promise)` in a client component — a promise created on the server, awaited in the browser | none | **missed** — botopink's `use` is the `#[@use]` hook activation (decision 104), not a promise unwrap; `Boundary.child` is a server thunk. Candidate for `../../deferred.md`: needs a serializable pending value crossing the `i` payload. |
| § 10 *Invocando via event handlers* | calling a server action from `onClick`/`startTransition`, reading its result without a form | 24 (scripted POST, contract 3) · 68 (runtime) | **partly missed** — jhonstart has the `data-jh-on-click` handler id (29) and no hook that awaits an action result outside a form. `actionState()` (67) is form-bound. |
| § 14 *Erros em event handlers* · *`startTransition`* | `useTransition`/`startTransition` | 31 (states the semantics), 68 (routes the failure) | **missed as API** — no `transition` hook in `hooks.bp` (frozen) and no front adds one. |
| § 18 *Memoização de dados* | React `cache()` per-request memoization | 62 | covered by rakun (per-request memoization is 62's) — not a jhonstart surface |
| § 18 *OG Images dinâmicas (ImageResponse)* · *Metadata Files* | `opengraph-image`, `sitemap`, `robots`, `manifest` | 66 · 70 | covered by rakun/onze; 32 owes `openGraph.images` paths |
| § 25 `<Image>` · § 16 | `next/image` | 51 (onze) | covered elsewhere |
| § 25 `<Script>` | `next/script` strategies `beforeInteractive` / `afterInteractive` / `lazyOnload`, `onLoad` | 68 (emission order, `beforeInteractive` chunks only) | **missed as API** — 94 has a raw-text `script` constructor; no strategy attribute, no `lazyOnload`. |
| § 7 hooks beyond `useState` | `useContext`, `useCallback`, `useTransition`, `useDeferredValue`, `useId` | `hooks.bp` (frozen: `state`/`effect`/`memo`/`ref`/`reducer`) | **missed** — outside every front's scope by the freeze; `useId` matters for hydration-stable ids and has no owner. |
| § 5 `template.tsx` | a layout that remounts per navigation | 22 (file routing) | not a jhonstart surface; 27's `layoutKey` would need a "never shared" flag — unowned |
| § 8 *Client-side Transitions* · *History API nativa* · § 26 navigation table · `useLinkStatus` | — | 26 · 27 | covered |
| § 7 · § 27 `'use client'`, *Context Provider*, *Intercalação com children*, `server-only` | — | 29 | covered |
| § 13 `loading.tsx`, `<Suspense>` | — | 30 | covered |
| § 14 `error.tsx`, `not-found.tsx`, `global-error.tsx`, `catchError`, *Erros esperados* | — | 31 (+ 63, 67) | covered |
| § 18 static / `generateMetadata`; `generateViewport`, title template (upstream only) | — | 32 (reference gaps recorded there) | covered |
| § 10 *Formulários*, `useActionState`, § 25 `<Form>`; `useFormStatus`, `useOptimistic` (upstream React only) | — | 67 (reference gaps recorded there) | covered |

The Next.js names above name Next's API as the reference; the jhonstart spelling is the noun without
the `use` prefix (`README.md § 6`).
