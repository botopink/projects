# Front 141 — inventory: where each retired spelling is written

Measured 2026-10-10 on the meta `feat`, by [`README.md`](./README.md) § Measure, over every tracked
`.md` and `.bp` of `specs/1.0.12-beta/` (plus the root `AGENTS.md` and `architecture.md`, which hold
none), without `decisions-taken.md` (step 1) and without `10-specs/**`. Step 0 re-measures it.
A line can match two families: the families add up to 285 lines, and 282 distinct lines in 71 files.

## Patterns

One extended regular expression per family, given to `grep -nE --`. A hit is a candidate, not a
finding: its class (S, R, H, P — README § What counts) is decided by reading the line. In the
table, `\|` is the alternation `|` (escaped for the table).

| Family | Pattern |
|---|---|
| F1 | `@Component<(ElementBase\|RequestBase\|StyledBase\|C), \|@Context<\|\bElementBase\b\|\bRequestBase\b\|\bStyledBase\b\|Context<[A-Z][A-Za-z]*>\(\)\|@getContext\|context-unbound\|provide\([A-Z][A-Za-z]*Context, \|use context\([A-Z][A-Za-z]*Context\)` |
| F2 | `\bChildren\b\|JhonstartNode` |
| F3 | `LocalKey\|\bLocal<\|setLocal` |
| F4 | `comptime tag: Tag` |
| F5 | `StyledPropertyView\|styledWith\|\bclsWith\b\|#\[(htmlPrelude\|stylePrelude)\]\|encodeSheet\|#\[styled\(\.` |
| F6 | `#\[schema\]\|schemaOf[A-Z]\|@emit\b` |
| F7 | `json\.(stringify\|parse)\(\|\bresult\.(map\|flatMap\|unwrapOr)\(` |
| F8 | `\[[a-z-]+\]=\{` |
| F9 | `#\[(restController\|configuration\|bean\|httpExchange\|getExchange\|streamListener\|listener)\]\|#\[value\(\|rkProp\|__rkMake_` |

## Lines per file

Path relative to `specs/1.0.12-beta/`, most hits first.

### F1 — wrapper and contexts (354, 357, 378, 379)

74 lines in 36 files.

| File | Lines |
|---|---|
| `01-compiler/134-builtins-declared/README.md` | 15 |
| `08-bpp/119-bpp-styling/README.md` | 8 |
| `09-cardume/136-cardume/README.md` | 6 |
| `08-bpp/123-bpp-middleware/README.md` | 4 |
| `07-onze/53-onze-example-app/acceptance.md` | 3 |
| `08-bpp/119-bpp-styling/examples/styled-example.bp` | 3 |
| `status.md` | 3 |
| `04-rakun/04-rakun-erlang-runtime/README.md` | 2 |
| `08-bpp/116-bpp-file-format/README.md` | 2 |
| `language-gaps.md` | 2 |
| `04-rakun/128-rakun-consolidation/README.md` | 1 |
| `05-jhonstart/26-jhonstart-router/examples/request-scope-example.bp` | 1 |
| `05-jhonstart/27-jhonstart-link/README.md` | 1 |
| `05-jhonstart/27-jhonstart-link/examples/post-list-links-example.bp` | 1 |
| `05-jhonstart/27-jhonstart-link/examples/src/components/nav_progress.bp` | 1 |
| `05-jhonstart/67-jhonstart-forms/examples/optimistic-like-example.bp` | 1 |
| `05-jhonstart/README.md` | 1 |
| `06-emilia/34-emilia-modifiers/README.md` | 1 |
| `08-bpp/117-bpp-routing/examples/pagination-example.bp` | 1 |
| `08-bpp/117-bpp-routing/examples/partial-and-endpoint-example.bp` | 1 |
| `08-bpp/117-bpp-routing/examples/static-paths-example.bp` | 1 |
| `08-bpp/118-bpp-components/README.md` | 1 |
| `08-bpp/118-bpp-components/examples/components-and-slots-example.bp` | 1 |
| `08-bpp/118-bpp-components/examples/template-expressions-example.bp` | 1 |
| `08-bpp/120-bpp-islands/examples/hydration-directives-example.bp` | 1 |
| `08-bpp/120-bpp-islands/examples/server-island-example.bp` | 1 |
| `08-bpp/121-bpp-content/examples/content-collection-example.bp` | 1 |
| `08-bpp/122-bpp-data/examples/response-control-example.bp` | 1 |
| `08-bpp/123-bpp-middleware/examples/locals-and-sequence-example.bp` | 1 |
| `08-bpp/126-bpp-view-transitions/examples/view-transitions-example.bp` | 1 |
| `08-bpp/127-bpp-actions/README.md` | 1 |
| `08-bpp/127-bpp-actions/examples/typed-action-example.bp` | 1 |
| `08-bpp/README.md` | 1 |
| `08-bpp/surface.md` | 1 |
| `decisions-pending.md` | 1 |
| `decisoes-pendentes.md` | 1 |

### F2 — node type (223)

14 lines in 7 files.

| File | Lines |
|---|---|
| `08-bpp/118-bpp-components/README.md` | 6 |
| `05-jhonstart/README.md` | 2 |
| `08-bpp/116-bpp-file-format/README.md` | 2 |
| `05-jhonstart/modules.md` | 1 |
| `08-bpp/README.md` | 1 |
| `decisions-pending.md` | 1 |
| `language-gaps.md` | 1 |

### F3 — request locals (295, 296, 354)

20 lines in 8 files.

| File | Lines |
|---|---|
| `08-bpp/123-bpp-middleware/examples/locals-and-sequence-example.bp` | 7 |
| `08-bpp/123-bpp-middleware/README.md` | 6 |
| `09-cardume/136-cardume/README.md` | 2 |
| `03-bundled-libs/105-i18n/README.md` | 1 |
| `05-jhonstart/26-jhonstart-router/README.md` | 1 |
| `decisions-pending.md` | 1 |
| `decisoes-pendentes.md` | 1 |
| `status.md` | 1 |

### F4 — tag annotation (302, 364)

2 lines in 1 files.

| File | Lines |
|---|---|
| `08-bpp/118-bpp-components/README.md` | 2 |

### F5 — styles (338, 361, 367, 369, 381)

28 lines in 13 files.

| File | Lines |
|---|---|
| `08-bpp/119-bpp-styling/examples/styled-example.bp` | 5 |
| `08-bpp/119-bpp-styling/README.md` | 4 |
| `07-onze/53-onze-example-app/examples/app-layout-example.bp` | 3 |
| `07-onze/53-onze-example-app/examples/post-card-example.bp` | 3 |
| `06-emilia/34-emilia-modifiers/README.md` | 2 |
| `08-bpp/README.md` | 2 |
| `language-gaps.md` | 2 |
| `status.md` | 2 |
| `02-std-and-packaging/98-packaging-tail/test-helpers.md` | 1 |
| `05-jhonstart/modules.md` | 1 |
| `07-onze/53-onze-example-app/acceptance.md` | 1 |
| `08-bpp/116-bpp-file-format/README.md` | 1 |
| `08-bpp/surface.md` | 1 |

### F6 — validation and emit (306, 327, 373)

64 lines in 18 files.

| File | Lines |
|---|---|
| `01-compiler/130-decorator-outputs/README.md` | 9 |
| `language-gaps.md` | 9 |
| `08-bpp/127-bpp-actions/README.md` | 7 |
| `03-bundled-libs/125-validation-zod/README.md` | 6 |
| `08-bpp/117-bpp-routing/examples/pagination-example.bp` | 5 |
| `08-bpp/121-bpp-content/examples/content-collection-example.bp` | 5 |
| `status.md` | 5 |
| `08-bpp/121-bpp-content/README.md` | 3 |
| `08-bpp/127-bpp-actions/examples/typed-action-example.bp` | 3 |
| `01-compiler/README.md` | 2 |
| `08-bpp/117-bpp-routing/README.md` | 2 |
| `08-bpp/117-bpp-routing/examples/static-paths-example.bp` | 2 |
| `01-compiler/02-erlang/README.md` | 1 |
| `01-compiler/14-comptime-on-beam/README.md` | 1 |
| `03-bundled-libs/README.md` | 1 |
| `04-rakun/19-rakun-test-utilities/examples/controller-test-example.bp` | 1 |
| `08-bpp/121-bpp-content/examples/markdown-example.bp` | 1 |
| `08-bpp/README.md` | 1 |

### F7 — std (330, 336)

5 lines in 2 files.

| File | Lines |
|---|---|
| `04-rakun/22-rakun-file-routing/examples/verb-exports-carried-example.bp` | 4 |
| `01-compiler/01-checker/README.md` | 1 |

### F8 — bracket attribute (118 step 1)

17 lines in 8 files.

| File | Lines |
|---|---|
| `08-bpp/118-bpp-components/README.md` | 6 |
| `08-bpp/118-bpp-components/examples/template-expressions-example.bp` | 3 |
| `06-emilia/34-emilia-modifiers/README.md` | 2 |
| `06-emilia/README.md` | 2 |
| `05-jhonstart/26-jhonstart-router/README.md` | 1 |
| `08-bpp/README.md` | 1 |
| `08-bpp/surface.md` | 1 |
| `decisions-pending.md` | 1 |

### F9 — rakun's annotations (234, 242, 254, 299, 318, 324)

61 lines in 21 files.

| File | Lines |
|---|---|
| `03-bundled-libs/103-actions-id/README.md` | 6 |
| `04-rakun/13-rakun-http-clients/examples/http-exchange-example.bp` | 6 |
| `04-rakun/15-rakun-messaging/examples/order-listeners-example.bp` | 6 |
| `04-rakun/19-rakun-test-utilities/examples/controller-test-example.bp` | 6 |
| `04-rakun/04-rakun-erlang-runtime/examples/context-lifecycle-example.bp` | 5 |
| `04-rakun/09-rakun-data-nosql/examples/stores-example.bp` | 5 |
| `04-rakun/04-rakun-erlang-runtime/README.md` | 4 |
| `04-rakun/13-rakun-http-clients/README.md` | 3 |
| `04-rakun/19-rakun-test-utilities/README.md` | 3 |
| `01-compiler/130-decorator-outputs/README.md` | 2 |
| `04-rakun/08-rakun-data-sql/README.md` | 2 |
| `04-rakun/15-rakun-messaging/README.md` | 2 |
| `04-rakun/88-rakun-cli/README.md` | 2 |
| `status.md` | 2 |
| `03-bundled-libs/106-log/README.md` | 1 |
| `04-rakun/08-rakun-data-sql/examples/audit-and-revisions-example.bp` | 1 |
| `04-rakun/08-rakun-data-sql/examples/city-entity-example.bp` | 1 |
| `04-rakun/13-rakun-http-clients/examples/hal-resource-example.bp` | 1 |
| `04-rakun/79-rakun-oauth2-sso/README.md` | 1 |
| `04-rakun/README.md` | 1 |
| `language-gaps.md` | 1 |

## `decisions-taken.md` — rows to state as in force (step 1)

Rows that append `**Amended by N:**` to the text it replaced (25): 193, 200, 270, 276, 277, 280,
284, 285, 295, 296, 300, 301, 302, 338, 351, 352, 353, 354, 355, 356, 360, 364, 369, 376, 378.

Rows fully replaced, one line each (3): 269, 279, 366. 269's line names 354's `Context<T>` object,
retired by 379; step 1 checks the other two.

## In code — what the repositories write today

Read at the repositories' `feat` (jhonstart, rakun) on 2026-10-10:

- `jhonstart/modules/jhonstart/src/element.bp:22` — `pub type View = @Component<Element>;`; `:10`
  keeps `pub type ElementBase()` as a phantom, its comment naming `ElementContext` (354 (7)) and
  `05-jhonstart/26` as what retires it; `children: Children` still in `Element`.
- `rakun/modules/rakun/src/request_context.bp:94` — `pub type RequestBase()`, the same phantom, for
  `RequestContext` and `04-rakun/128`.
- 35 lines in jhonstart and rakun still import or name `ElementBase` / `RequestBase`; they move with
  26 and 128, not here.
