# Front 97 — std dedupe: one place for every shared primitive

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s11 → B-00e · s18 box 1 → B-04 · s18 boxes 2, 3 → B-07 · compiler residuals → B-22 · s13 → B-24 · s14 → B-24 · s15 → B-24 · s17 → B-25 · s4 residue → B-27 · s6 → B-27 · gate → B-27; [146-validation](../../../2-libraries/146-validation/README.md): s2 residue box 1 → 146 s2; [150-rakun](../../../2-libraries/150-rakun/README.md): s2 residue box 2 → 150 s2. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — every library's "consume std X" step is written against this surface ·
**State:** partial: steps 0–5, 8–10, 12 and step 1's residue on feat; residue of steps 2 (the library
repositories' copies), 4, step 6 (conditional), 11
open (its questions: `97-a`, `97-b` → 334, 335; `97-c` → 335; `110-a` open), 13 (box 1's three `io/clock` templates —
`97-s13-b` —, box 2), 14, 15, 17 open; step 7 → 20-snap
**Depends on:** `std-d` (step 6) · `24-g` confirmed (step 5) · decision 230 (step 11) · decision
262 (step 12)
**Owns:** `repository/botopink-lang/libs/std/src/**`, `libs/std/AGENTS.md`, `libs/std/test/**` ·
consumer edits `libs/actions/src/{envelope,rpc}.bp`, `repository/validation/src/binding.bp` (moved by 138) ·
`libs/AGENTS.md` · `docs.md` § std where it lists the surface
**Does not touch:** `repository/botopink-lang/modules/**` (a new primitive method is declared in
`libs/std/src/primitives.bp`; a needed backend lowering → stop and report) · `libs/routing/**`,
`libs/validation/src/schemas.bp` (`03-bundled-libs`) · `repository/{rakun,jhonstart,emilia,onze,erika}`
(copies deleted by the file's owner, § Consumers) · `.gitignore`, the hooks · `01-compiler/05-wasm`
step 5 (wasm half of step 12, also touches std's wasm bodies `fn:…Body`) — sequenced, never together

## Goal

Every primitive two libraries need lives once in std — `.bp` only, both targets,
`#[@External.<Target>]` template where a host is needed, no sidecar (decisions 115/116). Method on a
primitive receiver (`"42".parseInt()`), method on the type where one exists (`Json`), else a free
function in the concept's module. Each library copy deleted by its file's front.

## Consumers — "consume std X" rows handed to the library fronts

Each row is a step of the named front; deletion measured by the grep.

| Copy | Owner front | Step | Measured by |
|---|---|---|---|
| `emilia.bp` `hashHex` | `06-emilia/34-emilia-modifiers` step 1 | `import {hash} from "std"`, `hash.contentHash`, fixture `e_39b87d03` unchanged | `grep -n hashHex repository/emilia/modules/emilia/src` empty |
| `onze/src/config.bp` (`pub` accessors) | `07-onze/49-onze-stand-up` step 1 | receiver swap; `pub` copies deleted (no consumer outside `onze`) | `grep -rn "fn membersOf\|fn strOf\|fn isObject\|fn kindName" repository/onze/modules/onze/src` empty |
| `onze-cli/src/{build,info}.bp`, `onze-bundler/src/entry.bp` (accessors, its `parseInt`) | `07-onze/50-onze-cli` step 1 | receiver swap | same grep over `onze-cli/src`, `onze-bundler/src` empty |
| `onze-og/src/svg.bp`, `metrics.bp` number parsers | `07-onze/51-onze-image` step 1 | `parseInt` / `parseFloat` | `grep -n "fn parse" repository/onze/modules/onze-og/src` empty |
| `libs/validation/src/schemas.bp` `itemsOf`, `membersOf`, `pub fn fieldOf` | `03-bundled-libs/125-validation-zod` (step 2 residue) | receiver swap (`input.items()`, `input.members()`); emitted `schemas.fieldOf(input, "…")` → `input.field("…") ?? Json.Null` or a function the grep does not match | `grep -n "fn itemsOf\|fn membersOf\|fn fieldOf" libs/validation/src` empty |
| rakun's copies (below) | `04-rakun` fronts, by file | one row each | `04-rakun`'s greps |

rakun's copies, by primitive:
- number parsers answering a `@Result` (e.g. `rakun-metrics/src/registry.bp`,
  `rakun-scheduling/src/cron.bp`, `rakun/src/config.bp`) → `parseInt` / `parseFloat`
- `Json` accessors in `rakun-security/src/jwt.bp`, `rakun/src/autoconfig_registry.bp` → `Json` methods
- the four retry loops → `async.retry`
- `config.parseDuration`, `jwt.skewOf` → `clock.parseDuration`
- `rakun_security.erl`'s `pbkdf2` → `hash.pbkdf2Sha256` (salt changes from base64url-decoded to text,
  decision 175)
- constant-time equality (`request_context.bp`), `sha256` (`rakun-ws/src/ws.bp`), `xmlEscape`
  (`config.bp`), `cron.rkFormatUtc`, `rakun-logging`'s `rkLogIso` → `hash.equalsConstantTime`,
  `hash.sha256`, `escape.attribute`, `clock.formatIso8601`
- `rakun-messaging/reliability/policy.bp` keeps its own `RetryPolicy` / `nextDelay` until its step
  (decision 170)

## Notes

- No jitter, no `retry` over a plain `@Task` (never fails, decision 120), no "unbounded"
  `RetryPolicy` field — most restrictive (decision 67).
- No std argv flag parser (rakun `rakun-cli/src/args.bp`, `config.cliEntries`,
  `onze-cli/src/create.bp`): three consumers, three grammars; a std `cli` module waits until they agree.

