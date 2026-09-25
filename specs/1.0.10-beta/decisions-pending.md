# Decisions the maintainer owes — 1.0.10-beta

**One open: 129** (type-alias details, below). Every other question this milestone raised is answered in
[`decisions-taken.md`](./decisions-taken.md) — 91, 92, 93 and 97 by decisions 103 and 104, 99 by 108,
94, 100 and 101 by 113; every number up to 117 is answered — 114 answers the eight seams decision 113 left open, 115 the five points 114 left open, 116 nine more pieces two libraries both run, 117 the nine points 113–116 left, and 118–127 register the maintainer's effect revision (the return type is the annotation, `@Task<T>`, only `@Result` fails, `@Iterator<T>` / `@Stream<T>`, `async { }`, `iter` / `stream` loops, no compatibility mode — front `00 · 24-effects-by-return`), and 128 merges `@Use<C, T>` and `@Component<T>` into `@Component<C, T>`. The next free number is **130**.

This file stays because the fronts will fill it again. A front that meets a question it cannot answer
from the code writes it here rather than guessing, in the shape the others used:

> **Raised by:** `<NN>-<front>` step <k>, <date>
> **Measured.** What was observed, with the command or program that produced it and the file or commit
> that can be re-read.
> **Options.** Each one stated so that choosing between them is possible without reading the code.
> **Recommendation.** One, argued — the default is the most restrictive behaviour, and no configuration
> that bypasses it (decision 67).
> **Blocks.** The step, front or landed work that waits on the answer.

## 129. The type-alias details decision 118 leaves open

> **Raised by:** `24-type-alias` (the alias declaration decision 118 rule 1 presupposes), 2026-09-25
> **Measured.** Decision 118 rule 1 writes `pub type Parser<T> = @Result<T, ParseError>;` and rules
> that an alias types a function without activating its effect; nothing decides the declaration's
> edges. The compiler at the `front/24-type-alias` commit implements the restrictive reading of each
> (parser: `parser/decls.zig` `parseTypeAliasDecl`; checker: `comptime/infer.zig` `expandTypeAlias`
> / `checkTypeAliasDecl`; tests: `parser/tests/type_alias.zig`, `comptime/tests/type_alias.zig`).
> **Options.**
> 1. *A bare generic alias* (`x: Parser` for `type Parser<T> = …`): (a) refused, `type-alias-arity`
>    — implemented; (b) read as `Parser<fresh>` the way a bare generic `type` is.
> 2. *A parameter default* (`type P<T = i32> = …`): (a) refused at the parse,
>    `type-alias-generic-default` — implemented; (b) allowed, with decision 8's trailing-default rule.
> 3. *An annotation on the alias* (`#[deprecated] type Id = i32;`): (a) refused,
>    `type-alias-annotated` — implemented; (b) carried like a `type`'s annotations.
> 4. *`as` on an imported alias* (`import {Parser as P}`): (a) refused like any type,
>    `import-alias-on-type` — implemented, since decision 110's checker-local type alias has not
>    landed; (b) allowed once 110 lands for types, because an alias has no emitted identity at all.
> 5. *An alias taking the name of a type in scope*: (a) refused, `type-alias-name-taken` —
>    implemented; (b) the alias shadows.
> 6. *A return alias of a wrapper in the backends*: the backends see `-> Parser<i32>` unexpanded
>    (so none lowers it as an effect) and every other alias expanded (`comptime/alias_erase.zig`).
>    No alternative is proposed; recorded so the effect front reads the same position.
> **Recommendation.** (a) for 1–5: each is the most restrictive reading (decision 67), and each can be
> relaxed later without breaking a program that compiles today. For 4, revisit together with 110.
> **Blocks.** Nothing — the alias ships with the (a) readings; front `24-effects-by-return` reads
> `Env.aliasedWrapper` for `effect-wrapper-behind-alias`.
