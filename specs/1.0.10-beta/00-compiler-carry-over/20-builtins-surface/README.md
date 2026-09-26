# Front 20 — the builtins surface

**Track:** compiler (carry-over item **C-28**)
**State:** closed. Every step and gate box is done; the effect vocabulary of `builtins.d.bp` is
now decisions 118–128's, landed by [`24-effects-by-return`](../24-effects-by-return/README.md). What
this front built holds under those names: the chain as `comptime/effect_chain.zig` asked by every
capability check, the two-way drift test against `builtins.d.bp`, one anchor per body, `External`'s
`inline` table, and a `builtins.d.bp` that formats.
**Owns (still):** the non-effect declarations of `repository/botopink-lang/libs/std/src/builtins.d.bp`
(`External`, `Target`, the intrinsics, the option and result sections) and `infer.zig`'s
`external_variants` table. The effect behaviors, `EffectKind`, `effect_chain.zig` and the effect
diagnostics are front 24's.

---

## What holds

**The chain is the type, not a table in the checker.** The legality of `use` / `await` / `yield` in
a body is "does the body's wrapper extend the wrapper that capability belongs to", asked of
`effect_chain.zig`, whose clauses follow `builtins.d.bp`: `@Component<C, T> ⊃ @Task<T>`,
`@Stream<T> ⊃ @Task<T>`, `@Iterator<T>` isolated, `@Context<Base>` a marker outside the chain.
`throw` / `try` read the fallible channel — a `@Result` in some layer of the return — not the level
(decision 121). A capability used above the body's level is refused, located, naming the level it
would need (decision 67). The drift tests ("every clause here is declared in builtins.d.bp",
"builtins.d.bp declares no clause this module does not carry", "every effect wrapper is declared,
and no removed one is") read the file in both directions — a `behavior` carries `extends`, and
`builtins.d.bp` is parsed by nothing but those tests, so the chain cannot be `implement` clauses in
the file.

**One anchor per body** (96). A `@Component<C, T>` body's base is `C`; a `use` anchored elsewhere
is refused at its own site naming both bases.

**`External`** (F9). `inline` is declared on `Erlang` and `Beam` only; `infer.zig`'s
`external_variants` restates the five variants with their `declares_inline` bit (a drift test reads
`builtins.d.bp` both ways), and `refuseUnreadInline` refuses the flag on `Node` / `Wasm` /
`Typescript`, anywhere but last, or with a non-bool value — on a `declare fn` and on a behavior's or
type's methods alike (`reject/external_inline_unread`). `builtins.d.bp` says in one sentence why
`External` is not `Target`.

**The file formats.** `botopink format --check libs/std/src/builtins.d.bp` passes and
`scripts/format-check.sh` holds it with `builtins_fns.d.bp`: an unannotated `[pub] declare fn` reads
its signature with `parseSignature`, a behavior `val` member carries a `TypeRef`, and `_` is a
bodyless declaration's placeholder (a function with a body refuses it, `discard-param-with-body`).
`scanDeclareFnExternal` (commonJS / erlang) stops on a prelude parse failure.

## The findings

| # | Finding | Now |
|---|---|---|
| F1 | `Context` declared twice (the hook wrapper and the Expr-template record) | one `Context`: the behavior `@Context<Base>`, a marker |
| F2 | the async-generator annotation and its wrapper disagreed | no annotations; `@Stream<T>` (122) |
| F3 | a generator without an error channel beside an iterator with one | `@Iterator<T>`; a fallible item is `@Iterator<@Result<T, E>>` (122) |
| F4 | `Result`'s variants were written `Result::Ok` / `Result::Err` in prose | the type wins: `Ok` / `Error` |
| F5 | the chain proved with a method, not a clause | `effect_chain.zig` |
| F6 | § 1C said `yield`, `await`, `throw` are forbidden in a context body | `@Component ⊃ @Task`: `await` is legal there; `throw` / `try` where `T` is a `@Result` (121) |
| F7 | `getContex` missing a `t` | `getContext` (108) |
| F8 | `Context<ContextBase, Return>` empty and `Element` its own base | `@Context<Base>`; jhonstart's `Element implement @Context<ElementBase>` (96, 102) |
| F9 | `External` asymmetric and duplicating `Target` | § *What holds* |
| F10 | the intrinsics at the foot written in another dialect | rewritten |
| F11 | `?T.expect(default)` documented as identical to `unwrapOr` | `expect` deleted and refused |
| F12 | `Iterable.iter(self)` answered a behavior as a value | `Iterable` gone; a type that wants to be iterated exposes `fn iter(self: Self) -> @Iterator<T>` |
