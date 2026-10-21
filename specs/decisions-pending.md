# Decisions the maintainer owes

The open questions of the current milestone, 1.0.12-beta; one file above every milestone since 2026-10-18.

**No question, contradiction or implementation choice is open** (2026-10-21: the 33 questions, 8 contradictions and 100 choices were answered by 899–955; a new one is added below in its section).

- An answer goes into [`decisions-taken-steps.md`](decisions-taken-steps.md) under the next free number (kept
  there only); a lettered id is never renumbered or reused.
- Every recommendation is the most restrictive reading, no configuration bypassing it (decision 67).
- A front meeting a question it cannot answer from the code adds it here: id · title · Measured
  (observed, re-runnable) · Options · Recommendation · Blocks. *Proposed* = raised without an id.

- **To review** — the decisions a `fable` took at the maintainer's delegation and his answers to a fable's questions (2026-10-20, 2026-10-21), for his later review.
- **Blocking now** — maximum priority: the questions that hold machine 2's work back today, most blocking first; an index of entries kept in their sections.
- **Blocking now — machine 1 and front 165** — the same for machine 1's steps and front 165.
- **Machine 1** — maximum priority: the questions front 144's machine 1 waits on, by step.
- **Machine 2** — maximum priority: the questions front 144's machine 2 waits on, most urgent first. New development is centred on front 164 wasm-gc (s1 → s4, wasmtime-a, wasmgc-a).
- **Front 165** — rakun-workspace: one `rakun` repository, 17 plug-and-play packages (mono-a).
- **Part 1** — what blocks front 144 (`repository/botopink-lang`, decision 433: the open steps of the old tracks
  `00-gate`, `01-compiler`, `02-std-and-packaging`, `03-bundled-libs`), by old track, then those
  tracks' implementation choices awaiting confirmation.
- **Part 2** — the rest (tracks 04–10, 20, ownership, contradictions that block no 00–03 step).
- **Part 3** — the implementation choices of tracks 04–09.

The Portuguese page (`decisoes-pendentes.md`) is this page's direct translation: this English text holds the meaning
(meta `AGENTS.md` § Conventions). Answered ids leave this file; `decisions-taken-steps.md` holds the answers and the next free
number, which is **956**.

## To review — the fable's decisions and the answers to its questions (2026-10-20, 2026-10-21)

The maintainer asked (2026-10-21) that every decision a `fable` took for him, and every answer he gave to a fable's question or to a review beside it, be marked for his later review. Each stays in force as written; a review that changes one is a new row amending it. Tick `[x]` once reviewed.

| Reviewed | Row | Answered | What was decided |
|---|---|---|---|
| [ ] | 814 | the fable review of 809–813, Q8 | Answered by the maintainer: an opaque type's constructor and fields private to the type, its methods without `pub` private to the module |
| [ ] | 815 | the fable review of 809–813, Q1–Q3 | Answered by the maintainer: `Composition<T>` a function again, a lambda of that type a component without hooks, callable by hand |
| [ ] | 816 | the fable review of 809–813, Q2 | Answered by the maintainer: the hooks' state in the node's scope cell, kept from render to render at the same place, as React keeps a fiber |
| [ ] | 817 | the fable audit, Q1–Q4 | Answered by the maintainer: std's `Scope` keeps the tree of cells by place and identity; contexts taken anew on reuse; `#[key]` |
| [ ] | 818 | the fable evaluation of 809–817, Q1, Q2, Q4, Q7 | Answered by the maintainer: every value-answering `use` a child cell; a component's identity the call that made it; `#[key(expr)]` at the call |
| [ ] | 819 | the fable evaluation of 809–817, Q3 | Answered by the maintainer: `Composition<T> = fn(scope: Scope, key: Place)`, opening its own cell; a hand call safe; `key-duplicate` |
| [ ] | 820 | 819-a | Answered by the maintainer: the call that makes a component stamps its place on the value; runners pass `Place.none()` |
| [ ] | 821 | 819-b | Answered by the maintainer: a call's number counted within the nearest `component` body; a helper transparent; a component function as a value numbered where written |
| [ ] | 822 | 809-e | Answered by the maintainer: a root runs a component with std's `run` (amended by 825) |
| [ ] | 823 | 810-b (part) | The maintainer chose (d); the fable settled where the eager rule is written (§ body-markers (3), 392 (1)'s scheduling stated for commonJS and wasm only) and that the wasm `ref.test` over `$task` is 164 s2's |
| [ ] | 824 | 809-i | On erlang and beam a root's tree of cells is one process-dictionary entry of the process that made it, ended with that process or `root.close()`; a scope crosses a process only as `scope.detach()` (amended by 825) |
| [ ] | 825 | the coordinator's review of 824 | Answered by the maintainer: `run` makes and closes its own root (`defer root.close()`); `close` marks a root closed on the four targets |
| [ ] | 826 | 809-f | `Composition`, `Composable` and `Component` are prelude names in `primitives.bp`, written bare, read nominally |
| [ ] | 827 | 809-g, 804-d | std's `use all(cs)` resolves a run-time list of components under one `use`; rakun-style's `Sheet.render` and `spliced` use it |
| [ ] | 828 | 809-h, 804-e | The type form's five codes; `component-compose-missing` and `component-use-outside-compose` become the general refusals |
| [ ] | 829 | 811-a | `opaque` closes a record alone, a contextual word, as built |
| [ ] | 830 | 811-c | The lowering's own calls known by a mark on the call node, not the 3,000,000 line range; a hand call of a `__bp_` name `reserved-name` |
| [ ] | 831 | 810-c | A behavior's run-time identity is its declaration's atom `<package>@<path>@@<B>`, no counter (the maintainer accepted the per-target table) |
| [ ] | 832 | 806-b | The fable's opinion — an inline type in a record field, named by its owner `Bp__<Owner>__<field>`, never a counter — taken with the maintainer's "os dois devem ser aceitos" |
| [ ] | 833 | 798-b | A `compiler.load` file checked for every target of the caller's manifest, never the build's `--target` |
| [ ] | 834 | 798-c | `--emit-resolved` writes one file per module, `<dir>/<pkg>/<module path>.bp`, names as written |
| [ ] | 835 | 798-d | A folded value with no literal printed as the call that builds it (`createContext(v)`, `@embed("path")`) |
| [ ] | 836 | 798-e | `<f>__type`, `__<Enum>__<Section>`, `__embed_<p>` move into the reserved space; `<Type>__<Assoc>` stays |
| [ ] | 837 | 805-a, 805-c | A `.bpr` per package and per std module, as built; the program's order in the root's file alone |
| [ ] | 838 | 805-b | A `.bpr` built and run only from its project's directory, `runtime-other-project` otherwise |
| [ ] | 839 | 723-b | `use context(ctx)` names a module-level context value only, never a parameter, a local or an expression (as built) |
| [ ] | 840 | 668-a | `compiler.meta(d, M)` / `compiler.metaAll(d, M)` the one spelling; `compiler.meta<M>(d)` goes |
| [ ] | 841 | 719-a | A `syntax` expression function returns any written type, `void` included |
| [ ] | 842 | 797-a | A member a decorator adds and needs is held as a value; a behavior-typed `decl` met by `implement` (716 (1) over 626 (2)) |
| [ ] | 843 | 564-d | Answered by 606 (1), 639, 826 (3): a module may shadow a prelude name |
| [ ] | 844 | 723-c | Answered by 723: one default per context type |
| [ ] | 845 | B-21-d | Answered by 583, 408: `fn() { … }` is the untyped form |
| [ ] | 846 | B-21-e | Answered by 622: the shortform `fn f(x: T) R` refused, a departure to remove |
| [ ] | 847 | B-02-c | `std:` in a template refused on every variant and target |
| [ ] | 848 | B-10-b | `compiler.variants(d)` answers typed `compiler.Variant[]` |
| [ ] | 849 | B-10-c | `clock.formatIso8601` always writes milliseconds |
| [ ] | 850 | B-10-e | Answered by 826 (4), 629 (2), 828 (1): an alias implements nothing |
| [ ] | 851 | B-10-f | Overtaken by 804 (2): no `Renderable` to ask about |
| [ ] | 852 | B-10-g | An alias of `Component` in a return is erased; `-> View` answers `Component<Element>` |
| [ ] | 853 | B-27-e | Two modules folding to one erlang atom refused (erlang and beam only — the fable asks whether every target) |
| [ ] | 854 | B-27-f | Answered by 255 (1), 561: a backtick type application before `.` is two comparisons, as built |
| [ ] | 855 | B-27-g2 | Overtaken by B-128: `keys()` lazy on erlang and beam |
| [ ] | 856 | B-27-g4 | Raw mode and size Linux-only on erlang and beam, `Unsupported` elsewhere |
| [ ] | 857 | 804-c | `children_for_walk` rewritten over `children: El[]`, kept as wasm's recursive-field walk |
| [ ] | 858 | 810-a | Every exhaustiveness refusal carries the code `non-exhaustive` |
| [ ] | 859 | 811-b | A method without `pub` is private to its module for every type (`method-not-pub`); `primitives.bp`'s methods made `pub` |
| [ ] | 860 | B-86-a | The lib-agnostic gate as built; the catalogue reach void (`@TypeInfo.all` gone) |
| [ ] | 861 | 548-a | Answered by 650: one link form, 166 s4's codemod |
| [ ] | 862 | 548-b | Former library names out of rakun's code (`stylesheet()`, `SsrConfig`, `/_rakun-ssr/` — the fable's names, to confirm) |
| [ ] | 863 | 165-a | The version set one row per package in `version_set.bp`, as built |
| [ ] | 864 | 529-a, 529-b | `..` any expression, no migration; a record parameter on every callable, no variadic or default beside it |
| [ ] | 865 | 537-b | `catch` the lowest infix, `??` the tightest binary level, as built |
| [ ] | 866 | 539-a | A `defer` body neither throws nor propagates (`defer-throw`, `defer-try`) |
| [ ] | 867 | 540-b | Answered by 607: `Asset` imports `io.fs` itself |
| [ ] | 868 | 532-a | A refusal cell claims its `from` frames, header unchanged |
| [ ] | 869 | 533-a | `comptime-badarith` names the dividing operation at its caret |
| [ ] | 870 | 535-b | The commonJS abort handler emitted in the program's entry |
| [ ] | 871 | 800-a | "Identical" over types; the `comptime` marker part of the signature |
| [ ] | 872 | 799-a | A required member a type has meets the contract, compared by 800 |
| [ ] | 873 | 641-a…d | `val length` in `primitives.bp` only; a local shadows statics; `array` a taken name (`json.arrayOf`); `bytes.toUtf8` |
| [ ] | 874 | B-116-k | Answered by 553/147, 819/821, 584/409 |
| [ ] | 875 | 518-a | Answered by 575 (6), 621: the `needs:` refusals are the constructor's |
| [ ] | 876 | 335-a | Answered by 823: `race` over settled values; the draft over `raceOf` |
| [ ] | 877 | 547-a | Answered by 547: an unannotated module `var` is ETS on the BEAM; the build a defect |
| [ ] | 878 | 543-a | Cranelift with the cache; SIGINT / LSP cancel interrupt a build |
| [ ] | 879 | 164-s3-g | `String.slice` as botopink bodies in P1 |
| [ ] | 880 | 164-s3-m | A `Bytes` leaf traps outside its domain |
| [ ] | 881 | docs-b | A std decorator imported as a leaf is annotated by its name |
| [ ] | 882 | docs-c | A library's test helpers are its `testing/` module; no `-test` member |
| [ ] | 883 | the audit's wording fixes | Eight stale phrasings of 814–882 corrected (824's store, 823's wasm test landed, 866's example, 871's markers, 847's hint, `RAKUN_SSR_KEY`, 852's citation, 869) |
| [ ] | 884 | ctr-all-place | `use all` runs entry `i` at `Place.index(i)`, never replacing a key |
| [ ] | 885 | ctr-embed-resolved | A folded `Asset` prints `Asset(Link(path: …))`, folded bytes `bytes.fromHex(…)`; `bytes` gains `fromHex` / `toHex` |
| [ ] | 886 | ctr-private-through-contract | A type's method meets another module's extension block only if `pub` |
| [ ] | 887 | ctr-no-pub-spelling | A member `addMember` adds is `pub`; `pub val length: i32;` |
| [ ] | 888 | ctr-lambda-arity | An untyped lambda may omit trailing parameters of its expected type |
| [ ] | 889 | 548-b, 862's names | 862's names confirmed (`stylesheet()`, `SsrConfig`, `/_rakun-ssr/`…); `rakun-bpp` examples bare; `emilia.bp`, bundler kinds and `rakun-cli`'s `onze` added |
| [ ] | 890 | B-27-e, 853's scope | Two modules folding to one atom refused on every target |
| [ ] | 891 | 884's open question | rakun-bpp's renderer passes `Place.index(i)` to a child list; an index never touches a body's count or a key |
| [ ] | 892 | the retired-forms sweep | Rows 751–879 read in their replacements; the subject text, the open boxes and retired.md respelled |
| [ ] | 894 | 859-a | The `.d.ts` declares, beside `pub` methods, a non-`pub` method that implements a member of the type's own `implement` clause |
| [ ] | 895 | b162-lambda-underscore | `_` is a lambda parameter bound to nothing, any number of times, lowered as an unnamed one |
| [ ] | 896 | b162-close-child | `close()` off a root fails `scope-not-root`; a second `close()` on a closed root does nothing |
| [ ] | 897 | b162-detached-reuse | A detached root is a seed: its tree starts per reading process, its cells fail `scope-closed` after that process's `close()`, the seed starts anew, no entry stays |
| [ ] | 899 | B-115-a | On commonJS a call into another module's bodied, non-host generic fn hands it the print shapes, by the callee's signature alone |
| [ ] | 900 | B-115-b | A value of a generic type carries its type arguments' shapes (`__bp_s`), set by the generic constructor and read by its methods; `print(d)` prints alike |
| [ ] | 901 | 878-a | As built: the first SIGINT interrupts the comptime body, a second ends the process |
| [ ] | 902 | 798-f | As built: `// from <template>`, `// from comptime`, `// from comptime { … }` with file:line |
| [ ] | 903 | 547-b | Overruled (b): a `PersistentTerm` var's `x = f(x)` is atomic under a per-`var` runtime lock; no write lost on any holding |
| [ ] | 904 | 789-b | A refused package's `build` lines come first, then the refusal records; `build` after `refused` malformed; amends 789 (1)'s list |
| [ ] | 905 | 547-c | The code is `module-var-holds-async` (`task` is retired by 732), the reach as built |
| [ ] | 906 | 790-b | `env` as built (`NAME=value`, a malformed entry `Error(Other)`); off commonJS `start` is refused at the call, `std-unsupported-on-target`, on erlang and beam as on wasm (518 (4), 67) |
| [ ] | 907 | 841-a | The use decides: `#[f]` applies a `syntax`-first function as a decorator, `f(e)` expands it; `isSyntaxExprFn` goes; a `syntax` function lives in `src/comptime/` once B-69 lands |
| [ ] | 908 | b162-render-library | The seven `render(c, scope)` cells rewritten so children resolve inside the providing body; answers kept; process row |
| [ ] | 909 | 848-a | As built: the wrapper's field `value`, its `section` the enclosing one, entries top-level first then each section's wrapper, leaves and sub-sections in source order |
| [ ] | 910 | s23-c | overtaken by 576 and 840: a reached declaration is an opaque handle, no `value`, meta read typed |
| [ ] | 911 | 14s8-c | a template's hole known at build whose fold raises is refused at the hole, never deferred to render (the maintainer's (a), numbered) |
| [ ] | 912 | 14s8-e | `use` only under the `component` marker, a hook a `component fn`, a `comptime` reaching a `use` refused at the `comptime` (the maintainer's answer, respelled under 722/809/825) |
| [ ] | 913 | 97-s16-a | `unicode_tables.bp` the flat sibling until B-75, then `src/internal/`; an import of std's `internal/` refused |
| [ ] | 914 | nat-d9 | `query`'s one public array spelling is the grammar; `Query<T>`'s LINQ methods and `of` become private lowering targets |
| [ ] | 915 | ctr-p | `std-a` confirmed, `03r-e` lapses: a malformed or control-character component is refused, never kept as written; rakun's readers go with 196 |
| [ ] | 916 | 396-a (onze-content) | `toElementWith(doc, render: fn(node: MdNode, kids: NodeChildren) -> ?NodeChild)`, `null` keeps the default element |
| [ ] | 917 | 07-g | (b): a `rakun-release` package of the rakun workspace, no `botopink/release` repository (326's example amended) — a product choice to confirm |
| [ ] | 918 | 01-compiler (28), 24-c, 23-b | table confirmed; ck2-e, 139-b, 388-b/c/d/e, s29-c overtaken; lem-b `inline: true` on a type method refused; lem-d the free `regex.matches` goes; cep-c ambiguous comptime record tests refused |
| [ ] | 919 | 02-std-and-packaging (10), 24-g, std-c | table confirmed; 95-a/95-c overtaken by 724/882; 95-b reversed (a member narrows only); std-c: a folder import refused naming the leaf with B-69 |
| [ ] | 920 | Choices made by the 00-gate threads (5) | 111-b, 113-a confirmed (names amended); 113-b reversed: the audit matches the id `host-binding-missing`; 110-b, 112-a no object |
| [ ] | 921 | 03-bundled-libs (4) | `log`'s four confirmed; `fileSink` answers `Error`, never raises; `@print` reads `terminal.print` |
| [ ] | 922 | Choices made by the bugs-sweep thread (4) | bs-a, bs-b confirmed; bs-c: 510 reaches compiler-core's snapshot tests, the runtime-output cache goes; bs-d no object |
| [ ] | 923 | 03r-q | locale routing stays in `rakun-app/src/i18n.bp`; no `rakun-i18n` member; the BCP 47 subset is `i18n`'s |
| [ ] | 924 | nat-d6 | Navigation signals are data: `notFound()` / `redirect(url)` answer a `Component<Element>` whose node is `NavSignal(outcome: NavOutcome)`, read by the renderer; no raise, no `nav:` string, no `noreturn` (527 (5), 554) |
| [ ] | 925 | nat-d7 | A component's lifecycle by two behaviors, rakun's `Startable` and std's `Closeable`, the container testing `is` at run time; `#[postConstruct]` / `#[preDestroy]` gone |
| [ ] | 926 | nat-d8 | `use actionState(createPost, initial)`; a `Component`-answering declaration named `use<Upper>…` refused, `hook-name-use-prefix` |
| [ ] | 927 | nat-f2 | `rakun-ssr.json`'s six keys read at build into one typed `SsrConfig` record, every wrong key or value refused naming the key path |
| [ ] | 928 | nat-f4 | `#[publicEnv]` on the `val` that reads the variable; the `RAKUN_SSR_PUBLIC_` prefix gone; an unmarked `env.read` in a `#[client]` component refused |
| [ ] | 929 | lg2-l | `noreturn` is the bottom type as built; a `-> noreturn` body that can complete refused, `noreturn-falls-through` (overrules the entry's (1)) |
| [ ] | 930 | lg2-n | Overtaken by 804 (4) / 809 (7): no thunk coercion, a deferred child is a component value |
| [ ] | 931 | lg2-s | No module-graph reflection; `importsOf` stays a loud textual scan; the graph, when needed, a `botopink` CLI output |
| [ ] | 932 | 07-b | 115's "two or more libraries" stays the only test for a package |
| [ ] | 933 | erk-b | `rakun-data`'s `#[documentRepository]` on a behavior with `` #[documentQuery @`…`] `` template annotations, `${name}` holes bound to the parameters |
| [ ] | 934 | 03r-ab, ctr-w | 150 s17's four arms confirmed, binary protocols refused naming the driver; the Elasticsearch arm through the core's `rkRegisterHttpClient` that `rakun-restclient` fills — no member edge |
| [ ] | 935 | 03r-af | The seven unbuilt examples retired; every `examples/` directory gains a `README.md` |
| [ ] | 936 | 03r-ak | The SBOM validated by 399's vendored Ajv in the test, not a hand-written schema walker |
| [ ] | 937 | 03r-al | The outbox relay through `withProducerTransaction` on the in-process broker; the real broker a `deferred.md` row |
| [ ] | 938 | 03r-am | The doubles in `rakun`'s `testing/` module through the core's hooks; nothing to measure |
| [ ] | 939 | 03r-an | A core transport registry keyed by `enum Transport`; `rakun-websocket` registers `.WebSocket`; no `rakun-messaging → rakun-websocket` edge |
| [ ] | 940 | 67-a | `fake_dom.mjs` gains forms; the five boxes asserted in `rakun-bpp-dom-test` now and in the ssr's browser run again |
| [ ] | 941 | 49-g | `Json.isString()` beside `isObject`, in std's `json.bp` until 151 s1; rakun-ssr's own deleted |
| [ ] | 942 | 51-a | A malformed integer in the og module is refused — `parseMetrics` answers a `Result`, `gradientOf` its not-a-gradient value |
| [ ] | 943 | atm-c | Any `T` in an atom; an island's read set checked at build; a non-encodable atom an island reads must be `#[clientOnly]` |
| [ ] | 944 | atm-d | No atom effect in the first cut; effects a later step after a measured need |
| [ ] | 945 | 141-a | The retiring decision's commit rewrites the old form in the current specs and adds its `retired.md` row; no allow-listed `land-check.py` check |
| [ ] | 946 | 07-i | The ban on a bundled package exporting a name std or a framework exports is a standing rule |
| [ ] | 947 | ctr-l | 186's third refusal dropped — no page declares itself prerendered under 202 |
| [ ] | 948 | ctr-v | A comments-only carve-out is the owning step's; org-3 sequences nothing now that 118, 33, 34 are steps of one front |
| [ ] | 949 | ctr-x | 337 (2), (3) overtaken by 592 (1); 337 keeps (1) and (4) |
| [ ] | 950 | ctr-af | The loop is `for x in xs { … }` / `for await x in s { … }` (553 (3)); 105's `for (xs) { x -> … }` gone, rewritten by the formatter |
| [ ] | 951 | ctr-ag | A `?T` is matched by `null` and `_`, the value read `x!`; 54's binder arm refused (602 whole) |
| [ ] | 952 | 03r-a, 03r-c, 03r-e, 03r-f, 03r-g, 03r-h, 03r-i, 03r-j, 03r-k, 03r-l, 03r-m, 03r-n, 03r-p, 03r-r, 03r-s, 03r-t, 03r-u, 03r-v, 03r-w, 03r-x (04-rakun) | The 21 choices of track 04 stand as built under the package names; 03r-a (every manifest erlang), 03r-e (a component kept as written) and 03r-r (starters) overtaken by 724 / 762, 196 and 724; 03r-c, 03r-h, 03r-i, 03r-l, 03r-s, 03r-t, 03r-v amended to 299, 281 / 714, 724's layers, 318 (5), § library-split and 312 / 397 / 398. |
| [ ] | 953 | 26-a (jhonstart), 29-a, 30-b, 30-c, 30-d, 30-e, 30-f, 30-g, 31-a (05-jhonstart) | The nine choices of track 05 stand under `rakun-bpp`; 29-a reduced to `registerRouteStarters`; 30-b's `payload` answers `?#(string, Json)`; `compose` takes the page as a component value and `Suspense` is a tree node (504, 414); 31-a's signature is `nat-d6`'s / `lg2-l`'s. |
| [ ] | 954 | 05emilia-a, 05emilia-b, 05emilia-c, 05emilia-d, 05emilia-f, 05emilia-g, 05emilia-i, 05emilia-j, 05emilia-k (06-emilia) | The nine choices of track 06 stand under `rakun-stylesheet`: each is Tailwind 4.3.2's output (350) and holds as the literal's text across 150 s52; the `--tw-*` names are CSS, outside 862. |
| [ ] | 955 | 49-a, 49-c, 49-e, 50-a, 52-a, 53-a, 68-a, 68-d, 69-a (07-onze) | The nine choices of track 07 stand under `rakun-ssr`'s names; 49-a writes through `snap`; 50-a's `start` spawns the node with `forwardSignals()` and runs the release's `bin/rakun-ssr` when it exists; 68-d's probe (`stylesheet-hash-split` / `-unevaluated`) holds until the tag annotation's tokens are comptime. |

## Blocking now — maximum priority (machine 2, 2026-10-15)

None open: every entry was answered by 899–955 (2026-10-21), decided by the fable at the maintainer's delegation and listed in § To review.

## Machine 2 — maximum priority (front 144, `machine-2/144-backends-tooling/`)

None open: every entry was answered by 899–955 (2026-10-21), decided by the fable at the maintainer's delegation and listed in § To review.

## Blocking now — machine 1 and front 165 (2026-10-15)

None open: every entry was answered by 899–955 (2026-10-21), decided by the fable at the maintainer's delegation and listed in § To review.

## Machine 1 — maximum priority (front 144, `machine-1/144-checker/`)

None open: every entry was answered by 899–955 (2026-10-21), decided by the fable at the maintainer's delegation and listed in § To review.

#### b162-place-repeat · One stamped value run twice among siblings
- **Measured.** B-162's `context.bp` fails `key-duplicate` only when a place's item half is a key. A body-numbered or plain place
  met twice in one render of one parent (`val h = Header(); div([h, h])`, or `use h` twice) reuses one cell. 819 (5)'s heading says
  "a repeated place among siblings fails", but its clause names only "two values of one call with one key"; 820 (1) makes one value
  one place.
- **Options.** (a) The two runs share one cell (built). (b) Any place met twice in one render of one parent fails at run time
  (`place-duplicate`, or `key-duplicate` read by 819 (5)'s heading). (c) The second run takes a fresh cell, dropped at the next render.
- **Recommendation.** (b): 817 (1) keeps one cell per place, and two bodies writing one slot in one render is the aliasing 819 (5)
  guards against for keys. A program that wants two instances writes the call twice, or a key.
- **Blocks.** Nothing; built as (a).

#### b162-all-outside-use · `all(cs)` and `memo(f)` used other than as a `use` operand
- **Measured.** 354's `context-hook-without-use` is raised for `provide`, `context` and `inject` only. `all(cs)` or `memo(f)` outside a
  `use` type-checks as a `Component` value whose body panics when run. 827 (1)'s "as provide, context and inject are" describes the
  lowering, not the refusal.
- **Options.** (a) Refused at check as those three are: 354's code extends to every hook lowered where it is `use`d (`memo`, `all`).
  (b) A value whose body panics when run (built). (c) std implements the bodies, so the value runs.
- **Recommendation.** (a): the checker knows it statically, as it does for the three; refuse > accept.
- **Blocks.** Nothing; built as (b).

#### b162-key-outside-body · `#[key(k)] x` written outside every function
- **Measured.** Outside every body the lowering writes the key with call number 0. 820 (3) says a value made outside every body
  carries no stamp, and 818 (3) makes a key's identity "the call and the key's value". With call 0, two module-level calls with one key
  (`val xs = [#[key(1)] Item(1), #[key(1)] Card(1)]`) collide and fail `key-duplicate` under one runner; inside a body they are two places.
- **Options.** (a) Call 0 plus the key (built). (b) Refused at check, `key-outside-body`: a key is a stamp (818 (3)), and 820 (3)
  gives none there; the list is keyed where it is run (`use all(views.map({ v -> #[key(v.id)] v }))`). (c) The module's
  initialisation numbered as a plain function's body (821 (2)), amending 820 (3) and 891 (1).
- **Recommendation.** (b): the smallest change, and it keeps 820 (3) whole.
- **Blocks.** Nothing; built as (a).

#### b162-lowering-aliases · The lowering's `bp…__` aliases and std's `pub` context helpers can be spelled by a program
- **Measured.** `reserved_names.zig` reserves `__bp_` and `Bp__` only. The component lowering imports std's `context.stamp`,
  `stampPlain`, `stampKeyed`, `memoIn`, `allIn`, `countNew`, `countEnd` (and the older `enter`, `provideIn`, `find`) as `bpStamp__`, …
  after the check, and `context.bp` declares them `pub fn`. So `import {context.stamp} from "std"; stamp(Item(p), scope, 7)` type-checks
  and forges a call number, against 817 (1) ("nothing outside std decides identity") and 814 (2) ("under a name no source can spell").
- **Options.** (a) As built. (b) The aliases renamed `__bp_stamp` …, so 805 (6) / 830 (3) cover them with no new rule, and a program's
  reference to the helpers' std names refused as `context-hook-without-use` refuses the hooks. (c) The helpers made module-private,
  reached by the lowering through 830's call mark, as 814 (2) describes for methods.
- **Recommendation.** (c): a private helper that only the marked lowering reaches is 830's mechanism already, and the names stay std's.
- **Blocks.** Nothing.

## Front 165 — rakun-workspace (the maintainer, 2026-10-14)

None open: every entry was answered by 899–955 (2026-10-21), decided by the fable at the maintainer's delegation and listed in § To review.

## Part 1 — What blocks tracks 00–03

None open: every entry was answered by 899–955 (2026-10-21), decided by the fable at the maintainer's delegation and listed in § To review.

## Part 2 — The rest

None open: every entry was answered by 899–955 (2026-10-21), decided by the fable at the maintainer's delegation and listed in § To review.

## Part 3 — Implementation choices of tracks 04–09

None open: every entry was answered by 899–955 (2026-10-21), decided by the fable at the maintainer's delegation and listed in § To review.
