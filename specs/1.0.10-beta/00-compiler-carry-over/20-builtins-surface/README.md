# Front 20 — the builtins surface

**Priority:** critical — `libs/std/src/builtins.d.bp` is the one file that says what the language's
own types are, and it currently declares one name twice, names an effect's wrapper two ways, and
describes a `#[@context]` body by a rule decision 95 reverses. Every front that writes an effect,
a hook or an indexable type reads it.
**Target:** all — the declarations are backend-independent; what changes per backend is only which
cells prove the rules.
**Depends on:** decisions [95](../../decisions-taken.md#95-the-effects-are-a-chain-context--future--result-and-every-effect-can-fail)
and [96](../../decisions-taken.md#96-one-contextbase-per-function-and-element-carries-its-base); 88, 89, 90 stand
**Owns:** `repository/botopink-lang/libs/std/src/builtins.d.bp` · the effect-legality and anchor
checks in `modules/compiler-core/src/comptime/infer.zig` (`try` / `await` / `use` / `yield`, RC1–RC5)
and their diagnostics · `EffectKind` in `modules/compiler-core/src/ast.zig` · `docs.md` § effects,
§ builtins, § use · the `tests/language` and `comptime/tests` cells for each rule
**Does not touch:** any `codegen/**` lowering (each backend's front owns its own — this front
changes what is *legal*, never what is *emitted*) · `libs/std/src/*.bp` other than `builtins.d.bp`
· the five library repositories, except that `Element`'s declaration is named here and changed by
jhonstart's own front
**Reference:** the file itself, read at `506ab409`; `specs/1.0.10-beta/00-compiler-carry-over/19-use-activation/README.md`

---

## Problem

The builtins file is the language's own vocabulary, and it has drifted from itself. Twelve findings,
each read in the tree rather than inferred, with the line it sits on:

| # | Finding | Where |
|---|---|---|
| F1 | **`Context` is declared twice in one module** — the hook wrapper `pub behavior Context<ContextBase, Return> { }` and the Expr-template record `pub type Context(source, text, multiline)`. One name, two unrelated meanings, same file | `:177` and `:404` |
| F2 | **An effect's annotation and its wrapper disagree** — `#[@asyncGenerator]` requires the wrapper `AsyncIterator` (`EffectKind.returnWrapper`), and no `AsyncGenerator` type exists. **Decision 98 settles it**: the effect is renamed `#[@futureGenerator]` → `@FutureGenerator`, so suspension has one word — 127 sites spell `asyncGenerator`, 64 spell `AsyncIterator` | `builtins.d.bp:123`, `ast.zig:2072` |
| F3 | **`Generator<T, R>` has no error channel** while `Iterator<T, E = any, C = void>` has one — the one wrapper decision 95's chain cannot reach without changing an arity; it is question 97, and the status quo (no `throw`/`try` in a `#[@generator]` body) stands | `:109` vs `:88` |
| F4 | **`Result`'s variants are `Ok` / `Error`, the prose says `Result::Ok` / `Result::Err`** — the auto-wrap paragraph and the R11/R12 rejection both name a variant the type does not declare | type at `:24`, prose at `:284-286` |
| F5 | **`Future` proves the chain with a method, not a clause** — `fn await(self) -> Result<T, E>` already says a future answers a result; decision 95 makes that an `implement` clause, after which the method is the *unwrap*, not the proof | `:116` |
| F6 | **§ 1C is now false** — "`yield`, `await`, `throw` are all forbidden inside a `#[context]` body"; decision 95 makes `await` and `try` legal there, and `use` remains what only `@Context` grants | `:354` |
| F7 | **`getContex` is missing a `t`** — the intrinsic, its prelude registration, its two error rules and the docs all spell it that way | `builtins.d.bp`, `comptime/stdlib/prelude.zig:16`, `docs.md:620`, RC4/RC5 tests |
| F8 | **`Context<ContextBase, Return>` is an empty behavior and `Element` is its own base** (`implement @Context<Element, Element>`), which makes "the same base" vacuous — decision 96 | `:177`; `jhonstart/modules/jhonstart/src/element.bp:8` |
| F9 | **`External` is asymmetric and duplicates `Target`** — `inline` exists on `Erlang`/`Node`/`Beam` and not on `Wasm`/`Typescript`, and its five variants are the five `Target` values under another name | the `External` and `Target` declarations |
| F10 | **The intrinsics at the foot are written in another dialect** — `fn field<T, F>(obj: T, comptime name: string) F`, `fn trap() noreturn`, `fn emit(source: string)`, `fn module() module`, `fn getContex<T>(comptime _: type) Context<T, any>`: no `pub`, no `->`, while every declaration above them has both | the runtime/reflection section |
| F11 | **`?T`'s `expect(self, default: T) -> T` is documented as identical to `unwrapOr`** — the name says the absent branch is unreachable, the signature says it is a fallback; one of the two is wrong for a reader | the option section |
| F12 | **`Iterable.iter(self) -> Iterator<T, E, C>` answers a behavior as a value** — legal or not, it is the only place in the file that does it, and nothing says which it is | `:100` |

F1, F2, F4, F6 and F7 are the file contradicting itself or the compiler. F8, F9 and F11 are decisions this front takes; F3 is question 97,
which it implements around. F5 and F10 are mechanical. F12 is a question.

## Current state

`EffectKind` has six values (`result`, `future`, `generator`, `iterator`, `asyncGenerator`,
`context`), each with an annotation spelling and a required return wrapper (`ast.zig:2051-2090`).
R5 allows one effect annotation per fn (`parser/decls.zig:407`). `FnContext.annotated` is set by
`#[@context]` **or** by a wrapper effect whose unwrapped return owns a context (decision 90,
`comptime/infer.zig`), and `env.inContextFn` — which gates `@getContex` — is still set by
`eff == .context` alone, which is open question 93.

## Mechanism

**The chain is the type, not a table in the checker.** Decision 95 is spelled as `implement`
clauses in `builtins.d.bp`; the legality of `try` / `await` / `use` / `yield` in a body is then
"does the body's wrapper implement the wrapper that capability belongs to", asked of the same
conformance machinery every other behavior uses. A capability written above the body's level is
refused, located, naming the level it would need — never accepted and ignored (decision 67).

**One anchor per body.** Decision 96 makes the `ContextBase` a property of the function: the first
`use` fixes it, a later `use` anchored at a different base is refused at that second site with both
bases named. RC2's subtype rule stays for the relation between a hook's anchor and the body's base;
what goes is the freedom for two different subtypes to meet in one body.

## Steps

### Step 0 — measure

Probe what `try`, `await`, `use` and `yield` do today in each of the six bodies — six by four, one
cell each — and write the table down. It is the before-column of everything below, and three of the
twelve findings above are claims about behaviour that the table either confirms or corrects.

### Step 1 — the file says one thing once

F1 (rename one `Context`; the Expr-template record is the one with the narrower audience), F2 (decision 98: `#[@asyncGenerator]`/`@AsyncIterator` →
`#[@futureGenerator]`/`@FutureGenerator`, including the `EffectKind` enum value; shape unchanged —
`codegen/typescript.zig`'s mapping to TS's `AsyncGenerator` and `codegen/wat.zig`'s wrapper test are
the one carve-out from this front's no-`codegen/**` rule, because both are name mappings rather than
lowerings), F4 (`Ok`/`Error` everywhere, or
`Ok`/`Err` everywhere — the type wins over the prose), F5, F10. No behaviour changes in this step:
it is the file agreeing with itself and with `ast.zig`.

**Acceptance:** `grep -c "^pub \(type\|behavior\) Context" builtins.d.bp` is 1 · every
`EffectKind.returnWrapper` value names a type declared in the file, and each equals its annotation's
name · `grep -rn "AsyncIterator\|asyncGenerator"` over the repository finds nothing but a CHANGELOG line, and `Async` is not a word the language spells anywhere · the `Result::` spellings match
the declared variants · the five intrinsics read like the rest of the file · `zig build test` green
with no snapshot moved.

### Step 2 — the chain, as `implement` clauses (decision 95)

`@Future<T, E>` implements `@Result<T, E>`; `@AsyncIterator<T, E, C>` implements `@Future`;
`@Generator` and `@Iterator` implement `@Result`; `@Context<B, R>` implements `@Future<R, E>` and
through it `@Result`. F3 is **not** decided here: `@Generator<T, R>` is question 97 and is left exactly as it is — a
`#[@generator]` body still may not `throw` or `try`, and the file says why where a reader meets it.
Implement every other row; a generator cell asserts the refusal, not a capability.

**Acceptance:** each row of decision 95's table is a cell that compiles · each capability one level
above a body is a cell that is refused, with the diagnostic naming the level · `#[@future] #[@context]`
is still `effect-duplicate-annotation` · no `codegen/**` file changed.

### Step 3 — one anchor per body (decision 96)

The body's `ContextBase` is fixed by its first `use`; a second `use` anchored elsewhere is refused
at its own site, naming both bases. `Element` gains its base type, and jhonstart's declaration
names it — the library half is jhonstart's front, this step ships the rule and the diagnostic.

**Acceptance:** a two-base body is refused and the message names both · a body whose hooks share a
base still compiles · RC1–RC5 keep firing where they did · the jhonstart handoff is written down.

### Step 4 — the residues

F9 (`External` gains `inline` everywhere or loses it, and says why it is not `Target`), F11 (`expect`
gets the signature its name implies, or the name its signature implies), F12 (answered either way,
in the file). Each is one paragraph and one cell.

### Step 5 — `docs.md` and the cells

§ effects carries decision 95's table; § use carries decision 96; every rule above has a
`tests/language` cell that **runs**, and every refusal a `reject/` cell carrying the real diagnostic.

## Open

- **Question 97** — whether a `#[@generator]` body answers `try`. Step 2 implements the chain
  around it and leaves the generator infallible; the recommendation there is to keep it so until a
  body needs otherwise, since the defaulted parameter can be added later and never removed.
- **Question 91** — whether the context-owner unwrap follows the chain to any payload, or stays
  `@Future` only. Step 2 makes the chain real; 91 decides how far the *owner* rule reads it.
- **Question 93** — whether `env.inContextFn` follows the same rule `FnContext.annotated` does. It
  is the same shape as 91 and should be answered with it.
- **F12** — `Iterable.iter` answering a behavior as a value: legal, or a `Self`-bounded generic.
