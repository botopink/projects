# frente-b-rules-tooling — effect-annotation rules + LSP + TS .d.ts + test runner output

**Slug**: frente-b-rules-tooling
**Depends on**: nothing (file-disjoint from Frentes A and C; the Rules track
  is logically sequenced after Frente A's §S `*fn` removal since the rules
  assume `*fn` is gone, but the spec itself doesn't edit the `*fn` path)
**Files**:
  - **Rules track (§0–§4):** `modules/compiler-core/src/{ast,parser/decls}.zig`
    · `modules/compiler-core/src/comptime/{infer,transform,contextStack}.zig`
    (new last) · `modules/compiler-core/src/codegen/{commonJS,erlang,beam_asm,wat}.zig`
    · `libs/std/src/builtins.d.bp` (the `§ effect annotations` comment block
    becomes the verbatim mirror of §4 below) · `libs/std/AGENTS.md` ·
    `modules/compiler-core/src/codegen/tests/effect_*.zig` (new per-effect
    snapshot suites) · `modules/compiler-core/src/comptime/tests/generic_defaults.zig`
    (new)
  - **LSP track (§E):** `language-server/src/engine.zig` ·
    `language-server/src/tests/{definition_tuples,definition_iface_assoc}.zig`
    (new) · `modules/language-server/AGENTS.md` ·
    `modules/language-server/docs.md`
  - **TS .d.ts track (§F):** `modules/compiler-core/src/codegen/typescript.zig`
    · `codegen/tests/dts_skips_templates.zig` (new) ·
    `modules/compiler-core/src/codegen/AGENTS.md`
  - **Test runner output track (§T):** `modules/compiler-core/src/codegen/{commonJS,erlang,beam_asm,wat}.zig`
    (test-mode entry — each backend's `emitTestRunner` / `__bp_run_tests`
    path) · `modules/compiler-core/src/runtime.zig` ·
    `modules/compiler-cli/src/cli/test_cmd.zig` ·
    `modules/lib-test-runner/src/{runner,report}.zig` ·
    `tests/cli/test_run_log_format.zig` (new) · `snapshots/cli/test/` (new)
**Touches docs**: `libs/std/AGENTS.md` · `modules/compiler-core/AGENTS.md` ·
  `modules/compiler-core/src/codegen/AGENTS.md` ·
  `modules/compiler-core/src/comptime/AGENTS.md` ·
  `modules/language-server/AGENTS.md` · `modules/compiler-cli/AGENTS.md` ·
  `modules/lib-test-runner/AGENTS.md`
**Status**: pending

## Tracks

| Track | Closes | Description |
|---|---|---|
| **Rules** (§0–§4) | v0.beta.12 effect-annotations final spec | Authoritative ruleset for the six `#[@<effect>]` markers + default generic parameters (§1G); §1/§1F/§1I/§1C carry the user's hand-supplied addenda verbatim |
| **§E** | v0.beta.16 §E | LSP definition tail — tuple `recv._N` + interface assoc dispatch |
| **§F** | v0.beta.16 §F | drop `@Expr<…>`/`@ExprCustom<…>` return-fn signatures from emitted `.d.ts` |
| **§T** | net-new tooling | Each `test { … }` captures stdout into a structured `----- RUN LOG -----` fence so the output is mockable / snapshot-matchable |

## Internal ordering

```text
Rules: §0 → §1 → §1F → §1I → §1C → §1G → §2 → §3 → §4 → Steps F0–F7
§E    — parallel; touches language-server only
§F    — parallel; touches codegen/typescript.zig only
§T    — parallel; touches test-mode codegen + CLI driver + lib-test-runner
```

The four tracks are file-disjoint. The Rules track is the only one with
internal dependencies; §E/§F/§T can land in any order at any time during the
frente.

## Premise (Rules track)

v0.beta.12 (`effect-annotations.md`, commit `d09e4ea`) replaced the `*fn`
prefix with six builtin annotations: `#[@result]` / `#[@future]` /
`#[@generator]` / `#[@iterator]` / `#[@asyncGenerator]` / `#[@context]`. The
migration was byte-identical, but the spec didn't write down the *complete*
ruleset — what each marker requires, permits, forbids, and lowers to. This
spec is that contract, end to end. Once `remove-star-fn` ships, this becomes
**the** reference doc.

The compiler already implements **most** of these rules (see
`EffectKind` in `ast.zig:1584` + `effectAnnotation` at `:1682` + the
per-backend lowerings). What's missing is (a) the authoritative write-up,
(b) the `#[@result]` auto-wrap behaviour spelled out in §1 below (the user-
specified ruleset), (c) symmetric per-effect snapshot tests, and (d) the
diagnostic surface for the rejection cases listed in §2.

## §0 — The six effects, at a glance

| Annotation | Return wrapper required | Body permits | Body forbids | Lowering (commonJS) |
|---|---|---|---|---|
| `#[@result]` | `@Result<R, E>` | `throw <E>` (auto-wrapped) · `try` · plain `return <R>` (auto-wrapped) | `await` · `yield` | plain `function`; `return` and `throw` lower to `{ok}`/`{error}` records |
| `#[@future]` | `@Future<T, E = any>` | `await <future>` · plain `return <T>` (auto-wrapped to resolved) · `throw <E>` (auto-wrapped to rejected) | `yield` | `async function`; `await` is the JS `await`; `throw` becomes a Promise rejection |
| `#[@generator]` | `@Generator<T, R = void>` | `yield <T>` · `yield :label <T>` · plain `return <R>` | `await` · `throw` (outside `result` composition) | `function*`; `yield` is the JS `yield` |
| `#[@iterator]` | `@Iterator<T, E = any, C = void>` | `yield <T>` · `yield :label <T>` · `throw <E>` (auto-wrapped to iterator-error) · `break` (clean end) · `break <C>` (completion value) | `await` · plain `return <something>` (use `break <C>`) | `function*` adapter; `break <C>` populates the consumer's `completion_value()`; `throw <E>` lands in the iterator-error channel |
| `#[@asyncGenerator]` | `@AsyncIterator<T, E = any, C = void>` | `yield <T>` · `yield :label <T>` · `await <future>` · `throw <E>` · `break` · `break <C>` | plain `return <something>` | `async function*` (same shape as `#[@iterator]`, suspended on `await`) |
| `#[@context]` | `@Context<Base, T>` (Anchor = `Base`) | plain `return <T>` · `use <hook>()` (must yield a context anchored to `Base`) · `use @getContex(<Base or subtype>)` | `await` · `yield` · `throw` · `use` of a context anchored outside `Base`'s tree | plain `function` whose first param is the active `Base` provider, resolved inside-out on the activation stack |

Per-backend cells of the table live in `codegen/AGENTS.md`. The erlang / beam
columns mirror the commonJS column except for `#[@future]` (process spawn —
see `final-sweep §D-D4`) and `#[@asyncGenerator]` (currently scoped to a
follow-up per the same section).

**Default generic parameters** on every wrapper above (`E = any`, `R = void`,
`C = void`) follow the general language rule defined in §1G: defaults must be
the **trailing** parameters of the generic list. The grammar permits `@Future<User>`
(omitted `E` defaults to `any`), `@Iterator<i32>` (`E` and `C` default), and so
on. See §1G for the full rule and the compilation error it dictates.

## §1 — `#[@result]` auto-wrap behaviour (THE escape contract)

> ## ADENDO À ESPECIFICAÇÃO: COMPORTAMENTO DE ESCAPE EM `#[@result]`
>
> Quando uma função é anotada com `#[@result]`, o compilador assume a
> responsabilidade de fazer o **auto-wrapping** (empacotamento automático) dos
> pontos de saída do bloco. Isso limpa o boilerplate visual do código,
> permitindo que o desenvolvedor foque apenas nos tipos puros.
>
> ### 1. REGRA DO `return` (Sucesso)
>
> - A expressão que acompanha a instrução `return` **DEVE** ser estritamente do
>   tipo `R`.
> - **É proibido** tentar retornar manualmente variantes de `@Result::Ok(R)`.
> - O compilador intercepta o `return <expr_R>;` e faz o lowering para
>   `return @Result::Ok(<expr_R>);` de forma transparente.
>
> ### 2. REGRA DO `throw` (Falha/Erro)
>
> - A expressão que acompanha a instrução `throw` **DEVE** ser estritamente do
>   tipo `E`.
> - **É proibido** tentar lançar ou retornar manualmente variantes de
>   `@Result::Err(E)`.
> - O compilador intercepta o `throw <expr_E>;` e faz o lowering para um
>   desvio de fluxo (early return) que resulta em
>   `return @Result::Err(<expr_E>);`.
>
> ### 3. MATRIZ DE TRADUÇÃO SINTÁTICA (AST LOWERING)
>
> Código escrito pelo usuário:
>
> ```bp
> #[@result]
> fn parse(n: i32) -> @Result<i32, string> {
>     if n < 0 {
>         throw "Número inválido"; // Tipo "string" (E)
>     }
>     return n * 2; // Tipo "i32" (R)
> }
> ```
>
> Código expandido pelo compilador (pós-lowering):
>
> ```bp
> fn parse(n: i32) -> @Result<i32, string> {
>     if n < 0 {
>         return @Result::Err("Número inválido");
>     }
>     return @Result::Ok(n * 2);
> }
> ```
>
> ### 4. DIAGRAMA DE ASSINATURA VS. TIPAGEM INTERNA
>
> ```text
>       Assinatura: fn parse(n: i32) -> @Result< i32 , string >
>                                                |       |
>                                   +------------+       +------------+
>                                   |                                 |
>                                   v                                 v
>       Corpo Interno:        return X; (onde X: i32)            throw Y; (onde Y: string)
>                             [Auto-Wrap para Ok(X)]             [Auto-Wrap para Err(Y)]
> ```

### Diagnostics this implies

| Author wrote | Compiler emits | Why |
|---|---|---|
| `return Result::Ok(x);` inside `#[@result]` | `return-must-be-bare-R: a #[@result] fn must `return` a value of type R; the @Result::Ok wrapping is implicit. Drop the `Result::Ok(…)`.` | Forbids the manual form per §1.1 |
| `throw Result::Err(e);` inside `#[@result]` | `throw-must-be-bare-E: a #[@result] fn must `throw` a value of type E; the @Result::Err wrapping is implicit. Drop the `Result::Err(…)`.` | Forbids the manual form per §1.2 |
| `return e;` where `e: E` (not `R`) | `result-return-type-mismatch: a #[@result] fn returns R via `return`; use `throw` for the error variant.` | Auto-wrap targets `R`, so an `E`-typed `return` is the wrong sigil |
| `throw r;` where `r: R` (not `E`) | `result-throw-type-mismatch: a #[@result] fn raises E via `throw`; use `return` for the success variant.` | Mirror of the above |
| `try { … }` block calls a `#[@result]` fn whose `E` differs from the enclosing one | `result-error-type-incompatible: <callee.E> is not assignable to <enclosing.E>` | The error type is part of the surface |
| Manual `Result::Ok(...)`/`Result::Err(...)` constructor in *any* position inside a `#[@result]` body | `result-manual-construction-forbidden: the @Result type variants are only constructed by `return` / `throw` inside #[@result]; outside that the type is treated as opaque.` | Locks the contract — no `let r = Result::Ok(x);` |

### Lowering — per backend

- **commonJS** — `return r;` → `return { ok: <r-expr> };`; `throw e;` →
  `return { error: <e-expr> };`. The runtime shape mirrors the existing
  inline-method machinery (`map`/`flatMap`/`unwrapOr`/`isOk`/`isError`).
- **erlang** — `return r;` → `{ok, <r>}`; `throw e;` → `{error, <e>}`.
  Already what `lowerResultOptionOp` emits today — this spec just names the
  contract.
- **beam_asm** — same atoms; `put_tuple2 {atom, ok}, <r-reg>, {x,0}` for
  success; `put_tuple2 {atom, error}, <e-reg>, {x,0}` for error; both followed
  by `return.`.
- **typescript** — `.d.ts` declares `parse(n: i32): { ok: i32 } | { error: string }`
  (the inline-method API stays the same).
- **wat** — pending §C of `final-sweep`. Record this gap in
  `codegen/AGENTS.md` if §C hasn't landed yet at execution time.

## §1F — `#[@future]` auto-wrap behaviour (mirror of §1)

> ## ATUALIZAÇÃO DA ESPECIFICAÇÃO: PARÂMETROS GENÉRICOS DEFAULT E CONTRATO `#[@future]`
>
> ### 1. SINTAXE DE GENÉRICOS DEFAULT NA LINGUAGEM BP
>
> A linguagem Blueprints (bp) suporta a declaração de tipos genéricos com
> valores padrão (default parameters). O compilador aplica as seguintes
> restrições:
>
> - **Posicionamento Estrito:** Parâmetros genéricos com tipo default DEVEM
>   ser posicionados obrigatoriamente por último na lista de genéricos.
> - **Erro de Compilação:** Qualquer tentativa de declarar um parâmetro
>   genérico sem default *após* um parâmetro com default gerará uma falha
>   estática.
>
> ```bp
> // Válido
> struct Container<T, U = string> { ... }
> // Inválido — erro de compilação:
> struct Container<T = i32, U> { ... }
> ```
>
> > Esta é a regra geral da linguagem (não específica do `#[@future]`);
> > o contrato completo está em §1G.
>
> ### 2. O CONTRATO EXPANDIDO DO `#[@future]`
>
> O marker `#[@future]` passa a adotar a mesma assinatura dual de
> sucesso/erro do `@Result`, utilizando o mecanismo de genéricos default para
> manter retrocompatibilidade caso o tipo de erro seja omitido.
>
> **Assinatura Base do Wrapper:** `@Future<T, E = any>`
>
> A semântica de controle de fluxo e auto-wrapping no corpo da função
> funciona em perfeita simetria com o `#[@result]`, adicionando a capacidade
> de suspensão:
>
> - `return <expr>` — espera uma expressão estritamente do tipo `T`. O
>   compilador faz o auto-wrap para resolver a promessa com sucesso
>   (`Ok`/`Resolve`).
> - `throw <expr>` — espera uma expressão estritamente do tipo `E`. O
>   compilador faz o auto-wrap para rejeitar a promessa com o erro fornecido
>   (`Err`/`Reject`).
> - `await <expr>` — suspende a execução. A expressão avaliada deve ser um
>   `@Future`.
>
> ### 3. MATRIZ DE COMPARAÇÃO DE COMPORTAMENTO INTERNO
>
> | MECÂNICA `#[@result]` | MECÂNICA `#[@future]` |
> |---|---|
> | Retorno: `@Result<R, E>` | Retorno: `@Future<T, E = any>` |
> | `return x;` → exige tipo `R` (auto-wrap para `@Result::Ok(x)`) | `return x;` → exige tipo `T` (auto-wrap para resolve/Ok de T) |
> | `throw e;` → exige tipo `E` (auto-wrap para `@Result::Err(e)`) | `throw e;` → exige tipo `E` (auto-wrap para reject/Err de E) |
> | `expr?` → unpacks Result | `await expr` → suspende e desempacota o `@Future` interno |
>
> ### 4. EXEMPLO CANÔNICO EM CÓDIGO BP
>
> Código escrito pelo usuário:
>
> ```bp
> #[@future]
> fn fetchUser(id: u64) -> @Future<User, NetworkError> {
>     // await suspende a execução e extrai o valor de sucesso do Future interno
>     let connection = await connectToServer()?;
>
>     if connection.is_invalid() {
>         throw NetworkError::Timeout; // Tipo NetworkError (E)
>     }
>
>     let user = connection.get_user_bytes(id);
>     return User::parse(user); // Tipo User (T)
> }
> ```
>
> Lowering expandido pelo compilador:
>
> ```bp
> fn fetchUser(id: u64) -> @Future<User, NetworkError> {
>     // O compilador injeta a máquina de estados para gerenciar o 'await'.
>     // Se ocorrer um throw interno ou erro no await, o Future é rejeitado.
>     // ... [código de estado gerado pelo compilador] ...
>
>     if connection.is_invalid() {
>         return @Future::rejected(NetworkError::Timeout);
>     }
>
>     return @Future::resolved(User::parse(user));
> }
> ```

### Diagnostics this implies (in addition to the shared R1–R5 rejections)

| # | Author wrote | Diagnostic |
|---|---|---|
| RF1 | `return Future::resolved(x);` inside `#[@future]` | `return-must-be-bare-T: a #[@future] fn must `return` a value of type T; the @Future::resolved wrapping is implicit. Drop the wrapper.` |
| RF2 | `throw Future::rejected(e);` inside `#[@future]` | `throw-must-be-bare-E: a #[@future] fn must `throw` a value of type E; the @Future::rejected wrapping is implicit. Drop the wrapper.` |
| RF3 | `return e;` where `e: E` (not `T`) | `future-return-type-mismatch: a #[@future] fn resolves T via `return`; use `throw` for the rejection variant.` |
| RF4 | `throw r;` where `r: T` (not `E`) | `future-throw-type-mismatch: a #[@future] fn rejects E via `throw`; use `return` for the resolved variant.` |
| RF5 | Manual `Future::resolved(...)` / `Future::rejected(...)` constructor anywhere inside a `#[@future]` body | `future-manual-construction-forbidden: the @Future type variants are only constructed by `return` / `throw` inside #[@future]; outside that the type is treated as opaque.` |

### Lowering — per backend

- **commonJS** — `return r;` inside an `async function` already wraps in
  `Promise.resolve`. `throw e;` inside an `async function` already rejects
  the Promise — both are JS-native. The auto-wrap rewrite at AST level emits
  `return @Future.resolved(<expr>)` / `return @Future.rejected(<expr>)` so
  every backend reads a canonical form; the JS emitter then maps
  `@Future.resolved` → bare `return <expr>` (inside the `async function`)
  and `@Future.rejected` → `throw <expr>` (JS-level).
- **erlang / beam** — implemented by `final-sweep §D-D4`. A `#[@future]` fn
  spawns its body as a process; the returned `Future` handle's `await` joins.
  Resolved → `{ok, T}`; rejected → `{error, E}` — same tag shape as
  `@Result`, distinguished by the wrapper's `await` consumer.
- **typescript** — `.d.ts` declares
  `fetchUser(id: u64): Promise<User>` (when `E = any`, the rejection type
  isn't in the type surface; if `E` is a concrete type, the `.d.ts` still
  emits `Promise<User>` and `E` is noted in a JSDoc `@throws` tag).
- **wat** — out of scope (no JS-like Promise; deferred indefinitely).

## §1I — `#[@iterator]` syntax (yield :label + break)

> ## ESPECIFICAÇÃO DE SINTAXE UNIFICADA: YIELD ROTULADO (`yield :label <expr>`)
>
> A sintaxe para rotulagem de pontos de suspensão foi unificada para seguir o
> padrão posicional do `break`, utilizando a estrutura `yield :label <expr>`.
> Isso mantém a homogeneidade visual da linguagem e deixa claro a qual escopo
> de FSM o valor está sendo enviado.
>
> ### 1. REGRAS SINTÁTICAS DO `yield :label`
>
> - **`yield <expr>` (implícito):** emite o valor para o iterador do escopo
>   imediatamente superior. Caso a função tenha apenas um bloco iterador
>   (sem funções aninhadas ou closures iteradoras), o label é totalmente
>   opcional.
> - **`yield :label <expr>` (explícito):** direciona a emissão do valor
>   especificamente para o escopo da corrotina identificada por `:label`.
>   Essencial para evitar ambiguidades em funções complexas com macros
>   geradoras ou closures internas.
>
> ### 2. ESPECIFICAÇÃO DO CÓDIGO CANÔNICO CORRIGIDO
>
> ```bp
> #[@iterator]
> // ':a' define o rótulo de escopo para esta função iteradora
> fn lazyMap<T, U>(it: @Iterator<T>, f: fn(T) -> U) -> @Iterator<U, string, i32> :a {
>     loop(it) {
>         if item.is_invalid() {
>             // Interrompe o fluxo e propaga o erro do tipo E (string)
>             throw "Invalid item detected";
>         }
>
>         if item.is_skipped() {
>             // Ignora o resto do corpo do loop e avança no 'it'
>             continue;
>         }
>
>         // Envia o valor f(item) explicitamente para o escopo ':a'
>         yield :a f(item);
>     }
>
>     // Como estamos no escopo limpo pós-loop, o label aqui é opcional.
>     // Encerra a execução entregando o valor de conclusão 'C' (i32).
>     break 445;
> }
> ```
>
> ## ATUALIZAÇÃO: SINTAXE DE ENCERRAMENTO EM ITERADORES (`break` / `break <expr>`)
>
> Substituindo a diretiva anterior `yield break`, o compilador adota
> formalmente a palavra-chave `break` para o encerramento de escopo em
> funções iteradoras, estendendo a semântica de controle de fluxo de loops
> para a máquina de estados do gerador.
>
> ### REGRAS DE SINTAXE DO `break` EM ITERADORES
>
> - **`break` (sem expressão):** termina imediatamente a execução do
>   iterador de forma bem-sucedida. O estado da máquina é movido para
>   `Completed`. Se o fim do bloco de código for alcançado sem um `break`
>   implícito, o compilador injeta um `break;` automaticamente.
> - **`break <expr>` (com expressão de retorno de saída):** permite que o
>   iterador emita um valor de terminação final (*value on completion*).
>   Para suportar essa mecânica, a assinatura do `@Iterator` é estendida
>   para comportar três tipos genéricos: `@Iterator<T, E = any, C = void>`.
>
>   - `T`: tipo dos elementos gerados via `yield`.
>   - `E`: tipo do erro propagado via `throw` (padrão: `any`).
>   - `C`: tipo do valor de conclusão retornado via `break <expr>` (padrão:
>     `void`).
>
> ### ASSINATURA EXPANDIDA E SEUS COMPONENTES
>
> Sintaxe completa: `@Iterator<T, E = any, C = void>`.
>
> Com base no exemplo: se utilizar `break 445;`, o tipo do número `445`
> (ex.: `i32`) deve ser mapeado no terceiro parâmetro genérico da assinatura
> (`@Iterator<U, string, i32>`).
>
> ### COMPORTAMENTO DA MÁQUINA DE ESTADOS (FSM) NO ENCERRAMENTO
>
> Quando `break <expr>` é invocado dentro do escopo de um iterador, a FSM
> executa a seguinte sequência:
>
> 1. **Resolução do tipo `C`** — o sistema de tipos avalia `<expr>`; deve
>    ser idêntico ou implicitamente conversível para `C` declarado na
>    assinatura. Divergência ⇒ erro de type-mismatch em tempo de compilação.
> 2. **Mutação de estado** — o estado interno da corrotina muda de
>    `Suspended` para `Completed`; o valor avaliado é movido/copiado para o
>    campo de valor de conclusão do payload de retorno da FSM.
> 3. **Cleanup** — quaisquer blocos `defer` ou estruturas de limpeza do
>    escopo são executados antes da devolução definitiva do controle.
>
> ### INTERFACE DE CONSUMO (EXEMPLO)
>
> ```bp
> fn main() {
>     let meu_map = lazyMap(lista, duplicar);
>
>     // O loop padrão consome apenas os valores do tipo T
>     for item in meu_map {
>         println("Elemento: {}", item);
>     }
>
>     // Após a exaustão (Completed), o valor de conclusão C torna-se acessível
>     let resultado_final: i32 = meu_map.completion_value();
>     println("Iterador finalizado com código: {}", resultado_final);
>     // Saída: Iterador finalizado com código: 445
> }
> ```
>
> ### REGRAS DE ESCOPO — `break :label <expr>`
>
> Para manter coerência com `yield :label`, a semântica de desvio posicional
> do `break` herda propriedades idênticas em aninhamento complexo:
>
> Se houver ambiguidade (um `loop`/`while` tradicional dentro do próprio
> iterador), o `break` sem rótulo age no laço local de controle de fluxo.
> Para encerrar prematuramente a FSM de dentro de um laço interno
> propagando um valor, usa-se a sintaxe rotulada apontando para o escopo da
> função:
>
> ```bp
> #[@iterator]
> fn iteradorComplexo() -> @Iterator<string, string, i32> :meu_escopo {
>     loop {
>         while condicao_interna {
>             if forcar_saida_da_fsm {
>                 // Encerra o iterador inteiro de dentro do laço duplo
>                 break :meu_escopo 200;
>             }
>             // Break normal sairia apenas do 'while'
>             break;
>         }
>     }
>     break 0;
> }
> ```

### Diagnostics this implies (in addition to the shared R1–R5 rejections)

| # | Author wrote | Diagnostic |
|---|---|---|
| RI1 | `return <expr>;` inside `#[@iterator]` | `iterator-return-forbidden: use `break <C>` to deliver an iterator's completion value, or bare `break` for a clean end. Plain `return <expr>` is only valid in #[@generator].` |
| RI2 | `break <expr>;` where `<expr>` is not assignable to `C` | `iterator-break-type-mismatch: completion value of type <expr-type> is not assignable to the declared C parameter (<C-type>) of @Iterator<T, E, C>.` |
| RI3 | `break <expr>;` in a `#[@iterator]` whose wrapper declares `C = void` (or omits the third arg) | `iterator-break-without-completion-type: this iterator declares C = void; bare `break` is the only valid form. Extend the @Iterator wrapper to opt into completion values: @Iterator<T, E, <C-type>>.` |
| RI4 | `yield :label <expr>` where `:label` doesn't match an enclosing iterator's declared label | `yield-label-unbound: label ':<label>' does not match an enclosing #[@iterator] / #[@generator] / #[@asyncGenerator] fn. Declare the label on the fn signature: fn <name>(...) -> @Iterator<...> :<label> { ... }.` |
| RI5 | `break :label <expr>` where `:label` doesn't match an enclosing labelled scope (loop or iterator) | `break-label-unbound: label ':<label>' does not match an enclosing labelled loop or labelled iterator fn.` |
| RI6 | `yield break <expr>` (the deprecated form) | `yield-break-removed: use `break <C>` to end an iterator with a completion value. The `yield break` form was removed in v0.beta.19.` |

### Lowering — per backend

- **commonJS** — `function*` adapter that distinguishes the three exit
  channels: a `yield x` lowers to a JS `yield x` whose adapter returns
  `{value: x, done: false}`; a `throw e` inside the iterator body lowers to
  the JS `throw` operator (caught by the adapter and re-emitted via a
  `{error: e}` discriminator); a `break <C>` lowers to a `return <C>` from
  the `function*` body, which JS exposes as `{value: <C>, done: true}` —
  the adapter materialises this as `completion_value()` on the consumer
  side. A bare `break` is `return undefined;` (so `done: true` with no
  value, mapping to `C = void`).
- **erlang / beam** — the existing primitive-iterator machinery already
  models a yield channel. Extending to error + completion uses two extra
  reply atoms: `{yield, T}`, `{iter_error, E}`, `{iter_done, C}`. The
  consumer's `completion_value/1` reads the second element of `{iter_done,
  _}`. `final-sweep §B-B4` already covers emitting primitive default fns on
  erlang/beam — this spec extends the message shape.
- **typescript** — `.d.ts` declares
  `lazyMap<T, U>(it: Iterator<T>, f: (x: T) => U): Iterator<U, "string", number>`
  (the type arguments `E` and `C` map to the second and third type params of
  the generated `Iterator<T, TReturn, TNext>` JS type — the `E` thread is a
  JSDoc `@throws` tag).
- **wat** — pending `final-sweep §C2`; record this gap in
  `codegen/AGENTS.md` if §C2 hasn't landed.

## §1C — `#[@context]` Anchor + `@getContex` intrinsic

> ## SÍNTESE DE ESPECIFICAÇÃO: SISTEMA DE CONTEXTO E ISOLAMENTO
>
> ### 1. CONCEITO DE ANCHOR (A "ÂNCORA" DO CONTEXTO)
>
> O `Anchor` define a raiz hierárquica permitida para o escopo. O tipo base
> declarado na assinatura da função atua como o **filtro de validação
> obrigatório** para todos os contextos injetados ou recuperados dentro
> desse bloco.
>
> Exemplo de regra:
>
> ```bp
> #[@context]
> fn processarPagamento() -> @Context<BasePagamento, bool> { ... }
> ```
>
> - `BasePagamento` é o Anchor.
> - **Permitido:** qualquer contexto que herde de `BasePagamento`.
> - **Proibido:** qualquer contexto de outro ecossistema (ex.:
>   `DatabaseContext`).
>
> ### 2. EXEMPLOS DE IMPLEMENTAÇÃO E ERROS (CENÁRIOS PRÁTICOS)
>
> #### A. Cenário de sucesso (alinhamento de tipos com o Anchor)
>
> ```bp
> #[@context]
> fn processarPagamento() -> @Context<BasePagamento, bool> {
>     // Sucesso: 'pagamentoCartao' retorna um @Context cujo tipo base herda
>     // de 'BasePagamento'. O compilador valida e permite a execução.
>     val p = use pagamentoCartao();
>     return true;
> }
> ```
>
> #### B. Cenário de erro [E2 — type mismatch com contexto estranho]
>
> ```bp
> #[@context]
> fn processarPagamento() -> @Context<BasePagamento, bool> {
>     // ERRO SEMÂNTICO [E2]: o compilador detecta que 'DatabaseContext'
>     // diverge completamente do Anchor 'BasePagamento' definido na
>     // assinatura. A compilação é interrompida imediatamente para evitar
>     // contaminação.
>     val db = use database();
>     return false;
> }
> ```
>
> ### 3. MECANISMO DE RESOLUÇÃO E VALIDAÇÃO ESTRITA DO PARÂMETRO
>
> A função intrínseca `@getContex(T)` é o mecanismo oficial de recuperação,
> exigindo explicitamente que o parâmetro fornecido respeite a árvore do
> Anchor.
>
> - **Obrigatoriedade do Base Context no parâmetro:** ao invocar
>   `@getContex(T)`, o tipo passado como argumento `T` deve ser
>   rigorosamente o próprio Base Context do Anchor ou um subtipo validado
>   dele. Não é permitido passar um tipo de contexto isolado ou
>   incompatível.
>
>   ```bp
>   // Uso correto (buscando a raiz do ecossistema permitido):
>   val ctx = use @getContex(BasePagamento); // OK
>
>   // Erro (tentando buscar um ecossistema isolado):
>   val ctx = use @getContex(DatabaseContext); // Erro [E2]
>   ```
>
> - **Inferência automática:** o compilador resolve a variável local
>   automaticamente para `@Context<T, ...>`.
> - **Busca em profundidade:** a busca é realizada de dentro para fora
>   (*inside-out*) pela pilha de ativação do escopo atual.
> - **Segurança [E1]:** falha se nenhum provedor do tipo `T` estiver ativo
>   na pilha.
>
> ### 4. RESUMO DAS GARANTIAS DO COMPILADOR
>
> | Código | Garantia |
> |---|---|
> | **[E1] Unbound Context** | O tipo `T` passado em `@getContex(T)` não foi encontrado na pilha de escopo atual. |
> | **[E2] Type Mismatch** | O contexto do hook (`pagamentoCartao`) ou o tipo `T` informado em `@getContex(T)` (ex.: `DatabaseContext`) não pertence à árvore de herança do Anchor (`BasePagamento`). |

### Diagnostics this implies (in addition to the shared R1–R5 rejections)

| # | Author wrote | Diagnostic |
|---|---|---|
| RC1 (E1) | `use @getContex(BasePagamento)` where no provider of `BasePagamento` (or a subtype) is active on the scope stack | `context-unbound: no active provider of type <T> found on the scope stack. A #[@context] fn must be called inside a scope that establishes a <T> provider (a parent `use` or a framework-installed root provider).` |
| RC2 (E2) | `use database()` inside a fn anchored to `BasePagamento` where `database()` returns `@Context<DatabaseContext, …>` and `DatabaseContext` is not assignable to `BasePagamento` | `context-anchor-violation: hook 'database' returns a context anchored to 'DatabaseContext', which is not in the inheritance tree of the enclosing fn's Anchor 'BasePagamento'. Anchors isolate context ecosystems — re-anchor the fn or route through a `BasePagamento`-anchored adapter.` |
| RC3 | `use @getContex(SomeStruct)` where `SomeStruct` is not assignable to the enclosing fn's Anchor | `context-getcontex-anchor-violation: @getContex<<T>> requires T to be the enclosing fn's Anchor (or a subtype thereof). The Anchor here is '<Anchor>'; '<T>' is not in its inheritance tree.` |
| RC4 | `@getContex(x)` where `x` is a value, not a type | `context-getcontex-expects-type: @getContex's argument must be a type (a Base Context or a subtype), not a value.` |
| RC5 | `@getContex<...>` outside a `#[@context]` fn | `context-getcontex-outside-context-fn: @getContex(...) is only valid inside a #[@context] fn body. Plain functions read contexts via explicit parameters.` |
| RC6 | `use <hook>()` where `<hook>` is **not** a `#[@context]`-marked fn | `use-of-non-context-fn: the `use` operator only consumes the return of a #[@context] fn. Call '<hook>' directly without `use`.` |

### Inheritance / assignability rule

`X` is "in the inheritance tree of" `Anchor` when one of:

- `X` *is* `Anchor` (identity);
- `X` `implements` (or `extends`) `Anchor` directly;
- the transitive closure of `X`'s `implements` / `extends` chain contains
  `Anchor`.

Inheritance is the existing record / interface mechanism; this spec does not
add a new "context-only" inheritance form. The Anchor check is just a
standard subtype check against the declared `Base`.

### Resolution algorithm — `use @getContex(T)`

1. Validate `T` is assignable to the enclosing fn's Anchor (RC3 otherwise).
2. Walk the activation stack from innermost to outermost (*inside-out*).
   At each frame, check whether a provider of type `T` (or a subtype) was
   installed. The first matching provider wins.
3. If no frame holds a matching provider, emit RC1 at the call site.
4. The returned value binds to a local whose static type is `@Context<T, V>`
   where `V` is the provider's own `T` slot (the value the provider's
   `#[@context]` fn was authored to return). The local then participates in
   subsequent `use` / member-access exactly like any `@Context<…>`.

### Resolution algorithm — `use <hook>()`

1. Type-check the call: `<hook>` must be a `#[@context]` fn (RC6 otherwise).
2. Read the hook's wrapper: `@Context<HookBase, HookT>`.
3. Check `HookBase` is assignable to the enclosing fn's Anchor (RC2
   otherwise).
4. Lower as: invoke the hook with the active `HookBase` provider (resolved
   per the same inside-out walk as `@getContex`), bind its returned value
   to the local.

### Lowering — per backend

- **commonJS** — the active `Base` provider lives in a host-side "scope
  stack" (a module-level array of frames, push on `use`-block entry, pop on
  exit). `@getContex(T)` lowers to a `findFrame(T)` call that walks the
  stack top-down. A hook call lowers to a regular fn call with the
  resolved provider passed as the synthetic first arg.
- **erlang / beam** — the scope stack lives in the process dictionary (a
  per-process map of `Type → Provider`). Push / pop wrap the `use`-block.
  `@getContex(T)` reads from the dict; missing key ⇒ runtime exception
  carrying the RC1 code, surfaced by the test runner via §1I's error
  channel for any `#[@iterator]` consumer or by the conventional
  exception path for direct callers.
- **typescript** — `.d.ts` declares `processarPagamento(base: BasePagamento):
  boolean` (the Anchor is the explicit first param at the type-system
  surface; the inside-out walk is hidden by the runtime).
- **wat** — out of scope; `#[@context]` is a tree-walking dynamic feature
  that doesn't map cleanly to wasm's linear stack. Record this gap in
  `codegen/AGENTS.md`.

## §1G — Default generic parameters (general language rule)

This is the **general language rule** for default generic parameters; the
effect wrappers above (`@Future<T, E = any>`, `@Iterator<T, E = any, C =
void>`, `@Generator<T, R = void>`, `@AsyncIterator<T, E = any, C = void>`,
`@Result<R, E>` (no defaults), `@Context<Base, T>` (no defaults)) all
conform to it.

### Grammar extension

```text
GenericParam      := IDENT ( "=" TypeRef )? ;
GenericParamList  := "<" GenericParam ("," GenericParam)* ">" ;
```

### The strict-trailing-position rule

A `GenericParam` with an `= TypeRef` default is permitted **only** when
every subsequent `GenericParam` in the same list also has a default. Stated
operationally: once a parameter declares a default, every parameter after it
must too.

```bp
// Valid — default trailing
struct Container<T, U = string> { ... }
fn lazyMap<T, U>(...) -> @Iterator<U, string, i32>
@Future<User, NetworkError>           // E provided; T is required as always
@Future<User>                          // E omitted, defaults to any
@Iterator<i32>                         // E and C both defaulted
@Iterator<i32, MyError>                // E provided, C defaults to void
@Iterator<i32, MyError, i64>           // all three provided
```

```bp
// Invalid — default-before-required ⇒ compilation error
struct Container<T = i32, U> { ... }   // U is required and follows a default
@Future<T = string, E>                  // same shape
@Iterator<T = i32, E, C>                // same
```

The compiler emits:

```
error[generic-default-before-required]: generic parameter '<name>' has a
default but is followed by '<next-name>' which has none. Default-typed
generic parameters must be the trailing parameters of the list.
  --> file.bp:<L>:<C>
   |
 L | struct Container<T = i32, U> { ... }
   |                  ^^^^^^^^^ ^
   |                  |         |
   |                  |         this parameter has no default
   |                  this default forces every following parameter to have one
   |
   = help: either give 'U' a default, or remove the default from 'T'.
```

### Resolution rules

- **Call site / type position omission** — when fewer type arguments are
  provided than parameters declared, the omitted suffix takes its declared
  defaults. The omission must be a **contiguous trailing range**: you can
  drop `<U, V>` from a `<T, U=…, V=…>` to get `<T>` or `<T, U>`, but you
  can't drop an interior `U` while keeping `V`.
- **Inference** — when a default is satisfied by inference (a call where the
  use-site fixes the type), the inferred type wins over the default. The
  default is the *fallback* when inference is undetermined.
- **`any` as a default** — `E = any` means "the rejection / error channel
  exists but is unconstrained". A `throw e;` in a `#[@future]` whose `E` is
  defaulted to `any` accepts any expression; the consumer must treat the
  rejection payload opaquely (a future spec may add `any`-typed runtime
  reflection — out of scope here).

### Diagnostics this implies

| # | Author wrote | Diagnostic |
|---|---|---|
| RG1 | `struct Container<T = i32, U> { ... }` (default before required) | `generic-default-before-required: ...` (per the error template above) |
| RG2 | `Container<>` (all params defaulted, called with no args — legal, no diagnostic) | — |
| RG3 | `@Future<>` (T is required, no default) | `generic-required-arg-missing: @Future requires a value type T; only the trailing parameters (E) have defaults.` |
| RG4 | `@Iterator<i32, , i64>` (skipped middle arg) | `generic-arg-skip-forbidden: cannot skip a defaulted argument while providing a later one. Either pass the middle argument explicitly, or rely on defaults for the contiguous trailing range.` |

## §2 — Rejection cases (where the annotation is invalid)

Each rule below is a parser- or comptime-time diagnostic with a stable
diagnostic code so the snapshot suite can assert the exact text.

| # | Author wrote | Diagnostic | Where it fires |
|---|---|---|---|
| R1 | `#[@result] declare fn parse(n: i32) -> @Result<i32, string>;` | `effect-on-declare-forbidden: a #[@<effect>] annotation marks an IMPLEMENTATION (a fn with a body); declare fn declarations express the effect through the return wrapper alone.` | parser, after the decl body's presence check |
| R2 | `interface Parser { #[@result] fn parse(self: Self) -> @Result<i32, string> }` | `effect-on-interface-method-forbidden: interface methods are declarative — they express the effect through the return wrapper alone, never via #[@<effect>].` | parser, when visiting an interface decl's methods |
| R3 | `#[@future] fn load() -> @Result<i32, E>` (annotation/wrapper mismatch) | `effect-wrapper-mismatch: #[@future] requires a return wrapper of @Future<…>, found @Result<…>.` | comptime, `effectAnnotation` cross-check vs `returnType` |
| R4 | `#[@result] fn parse(n: i32) -> i32` (no wrapper) | `effect-missing-wrapper: #[@result] requires a @Result<R, E> return type.` | comptime, same cross-check |
| R5 | `#[@result] #[@future] fn x() -> @Result<i32, E>` | `effect-duplicate-annotation: at most one #[@<effect>] annotation per fn; found `result` and `future`.` | parser, annotation pass |
| R6 | `#[@generator] fn s() -> @Generator<T> { yield 1; throw "boom"; }` | `effect-throw-without-fallible-channel: `throw` is only valid inside a fn whose effect declares an error channel: #[@result], #[@future], #[@iterator], or #[@asyncGenerator].` | comptime, body walk |
| R7 | `#[@iterator] fn it() -> @Iterator<T> { await someFuture(); }` | `effect-await-without-future: `await` is only valid inside #[@future] or #[@asyncGenerator].` | comptime, body walk |
| R8 | plain `fn` with `yield 1;` in body | `yield-without-generator: `yield` requires the enclosing fn to be marked #[@generator] / #[@iterator] / #[@asyncGenerator].` | comptime, body walk |
| R9 | `#[@result] fn x(): @Result<i32, string> { … `await` … }` | combines R7 (await without future) — same diagnostic as R7 |
| R10 | `#[@context] fn useThing() -> @Context<Base, T> { throw "x"; }` | applies R6 (throw without fallible channel) — diagnostic R6 reused |
| R11 | `#[@result] fn x() -> @Result<i32, string> { return Result::Ok(5); }` | per §1 table — `return-must-be-bare-R` |
| R12 | `#[@result] fn x() -> @Result<i32, string> { let r = Result::Ok(5); return r; }` | per §1 table — `result-manual-construction-forbidden` |
| R13 | `break <expr>` inside a `#[@iterator]`/`#[@asyncGenerator]` whose wrapper's `C` is `void` | per §1I table — `iterator-break-without-completion-type` |
| R14 | `return <expr>` inside a `#[@iterator]`/`#[@asyncGenerator]` | per §1I table — `iterator-return-forbidden` |
| R15 | `yield :label <expr>` where `:label` doesn't match an enclosing labelled iterator fn | per §1I table — `yield-label-unbound` |
| R16 | `struct Container<T = i32, U>` (default-before-required) | per §1G table — `generic-default-before-required` |
| R17 | Manual `Future::resolved(...)` / `Future::rejected(...)` inside `#[@future]` | per §1F table — `future-manual-construction-forbidden` |
| R18 (E2) | `use database()` inside `#[@context] fn ... -> @Context<BasePagamento, _>` where `database()` returns `@Context<DatabaseContext, _>` | per §1C table — `context-anchor-violation` |
| R19 (E1) | `use @getContex(BasePagamento)` with no `BasePagamento` provider active on the scope stack | per §1C table — `context-unbound` |
| R20 | `use @getContex(DatabaseContext)` inside a `BasePagamento`-anchored fn | per §1C table — `context-getcontex-anchor-violation` |
| R21 | `use <hook>()` where `<hook>` is not a `#[@context]` fn | per §1C table — `use-of-non-context-fn` |

## §3 — Per-effect detail

### `#[@result]` — fallible computation

Already specified in §1 + §2. Open data points the implementation must pin:

- Inference must accept a *non-literal* `R` (e.g. a generic `T`, an inferred
  numeric, a record type). `return n * 2;` types as `i32` and auto-wraps; the
  signature drives `R`.
- The fn may itself call other `#[@result]` fns. `try { x = parse(s)?; … }`
  unwraps `Ok` to `x` and re-throws on `Err` (the existing `?` machinery).
- Composing `#[@result]` with another effect is **out of scope here**. The
  matrix above explicitly forbids `yield`/`await` inside `#[@result]`; future
  composition (e.g. `#[@result] #[@asyncGenerator]`) is a follow-up spec.

### `#[@future]` — async computation (dual contract)

Specified in §1F. Open data points the implementation must pin:

- The `E` parameter defaults to `any` (per §1G). `@Future<User>` and
  `@Future<User, NetworkError>` are both legal; the former opts out of an
  authored rejection type.
- `await <future>;` types as the awaited future's `T` (independent of its
  `E`). When `await` appears inside a fn whose own `E` is not assignable
  from the awaited future's `E`, comptime emits an error (the existing
  `try`/`?` machinery in `comptime/transform.zig` already handles the
  parallel for `@Result` — extend it).
- The `?` suffix on a `@Future<T, E>` expression (`let x = future?`)
  unwraps the resolved value and re-rejects the surrounding fn's future on
  the awaited rejection. Identical to `try { x = await future }` for the
  fail-fast case — `?` is the ergonomic shorthand.

### `#[@generator]` — synchronous yielding

- Body permits `yield <T>` and `yield :label <T>` (the labelled form
  unifies with `#[@iterator]`'s — see §1I).
- `return <R>` (where `R = void` by default per the `@Generator<T, R = void>`
  wrapper) produces the generator's final value, exposed as `Yield::Done(<R>)`
  in the iterator-protocol consumer.
- `throw` is **forbidden** in `#[@generator]` — generators don't carry an
  error channel. Errors travel by either returning an `R`-typed result that
  itself encodes the error (compose `@Generator<T, @Result<R, E>>`), or by
  switching to `#[@iterator]` which does have an error channel.
- The `:label` declaration follows the return type:
  `#[@generator] fn f() -> @Generator<i32> :outer { … yield :outer 1; … }`.

### `#[@iterator]` — lazy pull-based sequence (with error + completion channels)

Specified in §1I. The wrapper is `@Iterator<T, E = any, C = void>`; the
three exit channels are `yield <T>` (more elements), `throw <E>` (error),
`break <C>` (completion). Open data points the implementation must pin:

- Bare `break` is equivalent to `break ();` when `C = void`; the codegen
  hides the unit.
- `for x in iter { … }` consumes the `yield` channel until exhaustion;
  the consumer accesses `iter.completion_value()` afterwards. The
  `for`-loop body sees a thrown `E` as a propagated exception (same shape
  as `for x in result_iter { … }` re-throws on `Err`).
- The `:label` declaration follows the return type. `break :label <C>`
  encerra a FSM de dentro de um laço aninhado — see §1I's "REGRAS DE ESCOPO"
  for the canonical example.

### `#[@asyncGenerator]` — lazy async sequence

- Same wrapper shape as `#[@iterator]`, prefixed with the async capability:
  `@AsyncIterator<T, E = any, C = void>`. Same exit channels (`yield`,
  `throw`, `break`/`break <C>`) plus `await <future>`.
- Lowering on commonJS: `async function*`. erlang/beam: scoped to follow-up
  per `final-sweep §D-D4`.
- `throw` is permitted (it lands in the iterator-error channel `E`),
  *not* in the runtime-exception sense — same as `#[@iterator]`.

### `#[@context]` — scoped contextual read (with Anchor isolation)

Fully specified in §1C. Summary:

- The wrapper is `@Context<Base, T>`; `Base` is the **Anchor** — the root
  of the inheritance tree that gates every `use` operation inside the body.
- Body permits plain `return <T>`, `use <hook>()` (where the hook's
  context is anchored to `Base` or a subtype), and `use @getContex(<T>)`
  where `T` is the Anchor (or a subtype).
- `yield`, `await`, `throw` all forbidden (R6/R7/R8 apply).
- `use` of a context anchored outside `Base`'s tree triggers R18 (E2).
- `@getContex(T)` outside a `#[@context]` fn triggers RC5; with an
  Anchor-violating `T`, R20; with no active provider, R19 (E1).
- Lowering: a plain function whose first synthetic arg is the active `Base`
  provider, resolved inside-out on the activation stack at every entry.
  The framework (`jhonstart`, …) installs root providers; this spec defines
  the validation contract.

## §4 — `builtins.d.bp` mirror

The `§ effect annotations` comment block at `libs/std/src/builtins.d.bp:198–222`
is rewritten verbatim from §0 + §1 + §1F + §1I + §1C + §1G of this spec so a
reader of the stdlib has the same source of truth as a reader of this spec.
The block must:

1. Begin with the §0 table (markdown reflow allowed, columns identical).
2. Quote the canonical example signatures, in this order:
   ```bp
   #[@result]    fn parse(n: i32) -> @Result<i32, string>
   #[@future]    fn fetchUser(id: u64) -> @Future<User, NetworkError>
   #[@generator] fn range(a: i32, b: i32) -> @Generator<i32>
   #[@iterator]  fn lazyMap<T, U>(it: @Iterator<T>, f: fn(T) -> U) -> @Iterator<U, string, i32> :a
   #[@asyncGenerator] fn stream() -> @AsyncIterator<T, NetworkError, i32>
   #[@context]   fn processarPagamento() -> @Context<BasePagamento, bool>
   ```
3. State the §1 auto-wrap contract for `#[@result]` (one paragraph, both
   sides) AND the §1F dual contract for `#[@future]` (mirror paragraph, with
   the `await` / `?` operators) AND the §1I three-channel contract for
   `#[@iterator]` (`yield :label` + `throw` + `break <C>`) AND the §1C
   Anchor + `@getContex` contract for `#[@context]` (one paragraph naming
   E1/E2 and the inside-out resolution).
4. State the §1G strict-trailing-position rule for default generic
   parameters (one paragraph), with the inline valid/invalid `struct
   Container<T, U = string>` examples.
5. Reference this spec by path:
   `tasks/v0.beta.19/specs/effect-annotation-rules.md`.

Update both `@Future` and `@Iterator` declarations in the same file to
reflect the new wrapper signatures (see §"Future declaration" / §"Iterator
declaration" sub-blocks below).

Add the **`@getContex` intrinsic** declaration to the builtins surface:

```bp
// ── context retrieval (§1C) ──────────────────────────────────────────────
//
// `@getContex(T)` retrieves the active provider of context type `T` from the
// enclosing #[@context] fn's scope stack. `T` must be the enclosing fn's
// Anchor (or a subtype thereof); the call returns @Context<T, V> where V is
// the provider's authored value slot. Errors:
//   [E1] context-unbound: no T provider on the activation stack
//   [E2] context-anchor-violation: T is outside the enclosing Anchor's tree
// Only legal inside a #[@context] fn body, behind a `use`:
//   val ctx = use @getContex(BasePagamento);
fn getContex<T>(comptime _: type) @Context<T, any>
```

The fn is declared `comptime` in its single type argument because the
Anchor check is a compile-time validation, not a runtime read; the runtime
side is the inside-out walk inserted by the lowering.

Update both `@Future` and `@Iterator` declarations in the same file to
reflect the new wrapper signatures:

```bp
pub interface Future<T, E = any> {
    fn await(self: Self) -> Result<T, E>
    fn map<R>(self: Self, transform: fn(value: T) -> R) -> Future<R, E>
    fn flatMap<R>(self: Self, transform: fn(value: T) -> Future<R, E>) -> Future<R, E>
}

pub interface Iterator<T, E = any, C = void> {
    // The sole abstract method — produce the next element, the iterator's
    // completion value, or an error. Lazy pull-based protocol.
    fn next(self: Self) -> IteratorStep<T, E, C>
    fn completion_value(self: Self) -> C
}

pub enum IteratorStep<T, E, C> {
    Yielded(value: T),
    Error(error: E),
    Done(completion: C);
}
```

The existing `Yield<T, R>` enum stays for `#[@generator]` (no error channel).

## Steps

### F0 — write the spec + lock the contract
- [ ] This file (you are reading it). Immutable once committed.

### F1 — diagnostic-code table
- [ ] In `modules/compiler-core/src/comptime/diagnostics.zig` (or wherever
      effect diagnostics live today), reserve stable codes for R1–R17 in §2,
      RF1–RF5 in §1F, RI1–RI6 in §1I, and RG1–RG4 in §1G. Existing
      diagnostics keep their text; new ones (R11–R17 + the per-section
      family codes) are net-new.

### F2 — parser rejections (R1, R2, R5, RG1)
- [ ] R1: rejection at `declare fn` parse site when a `#[@<effect>]`
      annotation precedes the decl.
- [ ] R2: rejection when walking an interface decl's methods.
- [ ] R5: duplicate-effect-annotation rejection in the annotation pass.
- [ ] RG1 (§1G): parser rejects `<T = default, U>` (required after default)
      at every generic-list site: `GenericParamList` in struct, fn, enum,
      interface, and TypeRef parsing.

### F3 — comptime cross-checks (R3, R4, R6, R7, R8, R9, R10, RG3, RG4)
- [ ] Cross-check `effectAnnotation()` vs `returnType` for each
      `EffectKind.returnWrapper()` — fail with the correct R-code on mismatch.
- [ ] Body walk: `throw` outside `#[@result]`/`#[@future]`/`#[@iterator]`/
      `#[@asyncGenerator]` ⇒ R6; `await` outside `#[@future]`/`#[@asyncGenerator]`
      ⇒ R7; `yield` outside `#[@generator]`/`#[@iterator]`/`#[@asyncGenerator]`
      ⇒ R8.
- [ ] RG3: missing required generic arg ⇒ `generic-required-arg-missing`.
- [ ] RG4: skipped middle generic arg ⇒ `generic-arg-skip-forbidden`.

### F4 — `#[@result]` auto-wrap (§1) + R11/R12
- [ ] `comptime/transform.zig`: rewrite `return <r>;` inside `#[@result]` to
      `return Result::Ok(<r>);` AST-level (so codegen sees the canonical form).
- [ ] Same file: rewrite `throw <e>;` to `return Result::Err(<e>);`.
- [ ] R11/R12: visiting `return Result::Ok(...)` / `throw Result::Err(...)`
      / `Result::Ok(...)` / `Result::Err(...)` syntactically inside a
      `#[@result]` body emits the matching diagnostic.
- [ ] Cross-check: `final-sweep §D` codegens already emit `{ok, V}` /
      `{error, E}` from the canonical form — no codegen change needed for §1.

### F4F — `#[@future]` auto-wrap (§1F) + RF1–RF5
- [ ] `comptime/transform.zig`: rewrite `return <t>;` inside `#[@future]` to
      `return @Future.resolved(<t>);` AST-level.
- [ ] Same file: rewrite `throw <e>;` to `return @Future.rejected(<e>);`.
- [ ] RF1/RF2/RF5: visiting `Future::resolved(...)` / `Future::rejected(...)`
      / `@Future.resolved(...)` / `@Future.rejected(...)` syntactically inside
      a `#[@future]` body emits the matching diagnostic.
- [ ] commonJS emitter: `@Future.resolved(<t>)` (inside an `async function`
      body) lowers to bare `return <t>;`; `@Future.rejected(<e>)` lowers to
      `throw <e>;` — both leverage the host `async function`'s native
      Promise behaviour.
- [ ] erlang/beam: see `final-sweep §D-D4`; coordinate at merge time.

### F4I — `#[@iterator]` `break <C>` + `yield :label` (§1I) + RI1–RI6
- [ ] `parser/stmts.zig`: parse `break;`, `break <expr>;`, and `break :label
      [<expr>];` inside an `#[@iterator]`/`#[@asyncGenerator]` body. The
      bare `break` and `break <expr>` are also valid inside ordinary loops
      (existing semantics); the `:label` form already exists for labelled
      loops — extend matching to include the fn's own `:label` declaration.
- [ ] `parser/decls.zig`: parse the trailing `:label` after the return type
      (already in for `#[@generator]`; extend the same path for
      `#[@iterator]`/`#[@asyncGenerator]`).
- [ ] `comptime/transform.zig`: rewrite `break <c>;` inside `#[@iterator]`
      to `return @IteratorStep.Done(<c>);` AST-level (or the canonical
      "iter-done" form codegen reads from).
- [ ] Same file: rewrite `throw <e>;` inside `#[@iterator]` to
      `return @IteratorStep.Error(<e>);`.
- [ ] RI1/RI2/RI3/RI4/RI5/RI6: visiting the invalid forms emits the
      matching diagnostic. RI6 in particular replaces the legacy
      `yield break` token sequence with a hard rejection.

### F4C — `#[@context]` Anchor + `@getContex` (§1C) + RC1–RC6 (R18–R21)
- [ ] `parser/decls.zig`: parse the `@getContex(T)` intrinsic call; alias
      into the existing builtin-call path.
- [ ] `comptime/transform.zig`: when visiting a `#[@context]` body, record
      the Anchor (`Base`) extracted from the `@Context<Base, T>` wrapper.
      Every `use <hook>()` and `use @getContex(<T>)` is type-checked
      against this Anchor.
- [ ] Implement the inside-out resolution algorithm (`comptime/contextStack.zig`
      new): a per-compilation-unit map of `Type → Provider` populated by
      `use`-block entry / exit. The compiler tracks the static provider type
      at every program point; the *runtime* dispatch is per-backend (see
      §1C "Lowering — per backend").
- [ ] RC1 (E1): no active provider ⇒ comptime if the stack is statically
      knowable; runtime trap otherwise (snapshotted under
      `effect_context_unbound.bp`).
- [ ] RC2 (E2): hook's `HookBase` is not assignable to the enclosing
      Anchor.
- [ ] RC3: `@getContex(T)` with `T` outside the Anchor.
- [ ] RC4: `@getContex(<value>)` (non-type arg).
- [ ] RC5: `@getContex(...)` outside a `#[@context]` fn body.
- [ ] RC6: `use` of a non-`#[@context]` fn.
- [ ] commonJS lowering: scope-stack as a module-level array; push on
      `use`-block entry, pop on exit; `@getContex` is a `findFrame(T)` walk.
- [ ] erlang/beam lowering: process-dictionary scope; `put({context, T},
      provider)` / `get({context, T})` with a runtime exception for E1
      (the same exception used by `@Result`'s `try`/`?` path, so the test
      runner surfaces it identically).

### F4G — default generic parameters (§1G) + RG1–RG4
- [ ] `parser/types.zig`: `GenericParamList` accepts `IDENT ("=" TypeRef)?`
      per the §1G grammar. Enforce the strict-trailing-position rule at
      parse time (RG1).
- [ ] `comptime/types.zig`: omitted trailing args resolve to declared
      defaults; record the resolution path so RG3/RG4 fire correctly.
- [ ] Update every consumer that builds a `GenericParam` list (struct, fn,
      enum, interface) to thread the default-typed param through codegen
      (most backends already ignore the param; the wat backend needs to
      know the resolved type for layout — see `final-sweep §C3`).

### F5 — `builtins.d.bp` mirror (§4)
- [ ] Rewrite the `§ effect annotations` block per §4 above (the §1 + §1F +
      §1I + §1G summaries land here).
- [ ] Update the `pub interface Future<T, E = any>` declaration per §4's
      sample.
- [ ] Update the `pub interface Iterator<T, E = any, C = void>` declaration
      + the new `pub enum IteratorStep<T, E, C>` per §4's sample.
- [ ] Add `libs/std/AGENTS.md` link to this spec under "Effect annotations".

### F6 — snapshot suites
- [ ] `modules/compiler-core/src/codegen/tests/effect_result.zig`
- [ ] `modules/compiler-core/src/codegen/tests/effect_future.zig` (covers §1F
      auto-wrap + the canonical `fetchUser` example)
- [ ] `modules/compiler-core/src/codegen/tests/effect_generator.zig`
- [ ] `modules/compiler-core/src/codegen/tests/effect_iterator.zig` (covers
      §1I `yield :label` + `break <C>` + the canonical `lazyMap` example)
- [ ] `modules/compiler-core/src/codegen/tests/effect_asyncGenerator.zig`
      (gated on `final-sweep §D-D4` if not yet landed)
- [ ] `modules/compiler-core/src/codegen/tests/effect_context.zig`
- [ ] `modules/compiler-core/src/comptime/tests/generic_defaults.zig`
      (covers §1G: every RG-code + the resolution rules)
- [ ] Each suite covers: a valid example, an R-coded rejection, and a
      cross-backend snapshot diff (commonJS + erlang + beam where supported).

### F7 — AGENTS sweep
- [ ] `modules/compiler-core/AGENTS.md`: comptime section gains a one-paragraph
      pointer to this spec under "Effect annotations".
- [ ] `codegen/AGENTS.md`: the per-backend cell table from §0 lands in the
      "Effects" subsection (or a new one), with the current support matrix.

## Test scenarios

```
F1      ---- every R-code is defined; `grep -rn 'effect-on-\|future-\|iterator-\|generic-default-\|yield-label-\|break-label-' compiler-core/src/comptime/diagnostics.zig` finds R1–R17 + RF1–RF5 + RI1–RI6 + RG1–RG4
F2-R1   ---- `#[@result] declare fn parse(...) -> @Result<...>;` reds with effect-on-declare-forbidden
F2-R2   ---- `interface I { #[@result] fn parse(self) -> @Result<...> }` reds with effect-on-interface-method-forbidden
F2-R5   ---- `#[@result] #[@future] fn x() -> @Result<...>` reds with effect-duplicate-annotation
F2-RG1  ---- `struct Container<T = i32, U> { }` reds with generic-default-before-required
F3-R3   ---- `#[@future] fn f() -> @Result<...>` reds with effect-wrapper-mismatch
F3-R4   ---- `#[@result] fn f() -> i32` reds with effect-missing-wrapper
F3-R6   ---- `throw e;` in a plain fn reds with effect-throw-without-fallible-channel
F3-R7   ---- `await x;` in an `#[@iterator]` reds with effect-await-without-future
F3-R8   ---- `yield 1;` in a plain fn reds with yield-without-generator
F3-RG3  ---- `@Future<>` reds with generic-required-arg-missing
F3-RG4  ---- `@Iterator<i32, , i64>` reds with generic-arg-skip-forbidden
F4-§1   ---- the `parse(n: i32) -> @Result<i32, string>` example from §1 emits the post-lowering AST verbatim
F4-R11  ---- `return Result::Ok(5);` in #[@result] reds with return-must-be-bare-R
F4-R12  ---- `let r = Result::Ok(5); return r;` in #[@result] reds with result-manual-construction-forbidden
F4F-§1F ---- the `fetchUser` example from §1F emits `return @Future.resolved(...)` / `return @Future.rejected(...)` post-lowering
F4F-RF1 ---- `return Future::resolved(x);` in #[@future] reds with return-must-be-bare-T
F4F-RF4 ---- `throw r;` where r:T in #[@future] reds with future-throw-type-mismatch
F4F-await ---- `await otherFuture` types as the awaited future's T inside #[@future]; missing await ⇒ inference error
F4I-§1I ---- the `lazyMap` example from §1I emits `return @IteratorStep.Done(445)` for `break 445` post-lowering
F4I-RI1 ---- `return 5;` in #[@iterator] reds with iterator-return-forbidden
F4I-RI3 ---- `break 5;` in #[@iterator] whose wrapper has no C declared reds with iterator-break-without-completion-type
F4I-RI4 ---- `yield :ghost 1;` where ':ghost' isn't declared reds with yield-label-unbound
F4I-RI6 ---- `yield break 5;` reds with yield-break-removed
F4C-§1C ---- the `processarPagamento` example A in §1C lowers `val p = use pagamentoCartao();` to a fn call with the active BasePagamento provider injected; example B reds with R18 (context-anchor-violation)
F4C-R19 ---- `use @getContex(BasePagamento);` outside any active provider scope reds (E1)
F4C-R20 ---- `use @getContex(DatabaseContext);` inside a BasePagamento-anchored fn reds (anchor-violation)
F4C-R21 ---- `use plainFn();` where plainFn isn't #[@context] reds with use-of-non-context-fn
F4C-stack ---- nested `use` blocks: inside-out walk picks the innermost provider; pop on block exit restores the outer
F4G-§1G ---- `struct Pair<A, B = string>` parses + resolves; `Pair<i32>` resolves to `Pair<i32, string>`
F4G-RG2 ---- `@Future<>` legal when both T and E have defaults — for @Future, T is required so this still reds (RG3)
F5      ---- diff `libs/std/src/builtins.d.bp` against §4 — `Future`/`Iterator`/`IteratorStep` declarations all match
F6      ---- `zig build test` runs each effect_*.zig + generic_defaults.zig; all pass
F7      ---- `modules/compiler-core/AGENTS.md` + `codegen/AGENTS.md` updated in the same commit as F6
gate    ---- `zig build test` + `zig build test-libs` + `botopink-lib-test` all green
```

## Notes

- **Why this spec is separate from `final-sweep` §D-D4.** §D-D4 implements the
  erlang/beam side of `#[@future]`; this spec is the *contract* across all six
  effects. The two can land in either order: §D-D4 only changes a codegen
  emitter; this spec changes validation + the `#[@result]` / `#[@future]` /
  `#[@iterator]` AST rewrites + the generic-default rule + docs.
- **Why §1 / §1F / §1I / §1C are bilingual.** Per memory rule
  `feedback_everything_english`, project text is in English. These four
  blocks are the *exception* — they are the author's hand-supplied rulesets,
  copied verbatim so there's no semantic drift in translation. The
  surrounding spec is English; only the indented Portuguese blockquotes
  inside §1, §1F, §1I, §1C are bilingual. Every diagnostic table and
  lowering description that follows is English.
- **§1G is fully English** because default generic parameters are a general
  language rule that touches every type position, not a per-effect contract;
  there is no localised addendum from the user for §1G — the spec authored
  it from the user's `@Future<T, E = any>` + `@Iterator<T, E = any, C = void>`
  examples plus the "trailing only" rule the §1F addendum stated.
- **`@getContex` (with one `t`, not two) is the user's chosen spelling.**
  Preserved verbatim from the §1C addendum; the implementation honours the
  exact identifier the user wrote. A future spec may add `@getContext` as
  an alias if the typo proves annoying — but the v0.beta.19 contract is
  `@getContex`.
- **`Result::Ok` / `Result::Err` spelling.** The user-supplied addendum uses
  `Result::Ok` / `Result::Err`. The current AST uses `Result.Ok` /
  `Result.Error` (per `builtins.d.bp` lines 39–42). When the auto-wrap
  rewrite lands, it emits the AST's own form (`Result.Ok` / `Result.Error`);
  the `::` spelling in §1's pseudocode is illustrative. Diagnostics surface
  the actual identifier the user wrote, so both spellings show up correctly.
- **Composition (`#[@result] #[@asyncGenerator]`) is out of scope.** R6
  reserves a hook for it (`"… or a #[@result]+#[@asyncGenerator] composed
  body if the spec ever adds that"`) — actual composition is a follow-up
  spec, not v0.beta.19.
- **`return r;` vs `return @Result.Ok(r);`.** The compiler-canonical form
  post-lowering is `return @Result.Ok(r);`; users author the bare form. Once
  the rewrite lands, *no* tooling (LSP hover, `.d.ts`, `botopink test`
  output) leaks the wrapped form — it's a pure AST internal.
- **Memory rule reminder:** AGENTS.md updated in the same commit as the code
  it documents (`feedback_agents_md_maintenance`). The F5/F7 ticks make this
  explicit, but it bears repeating.

---

## §E — LSP definition tail (close v0.beta.16 §E)

**Files**: `language-server/src/engine.zig` ·
`language-server/src/tests/{definition_tuples,definition_iface_assoc}.zig`
(new) · `modules/language-server/AGENTS.md` ·
`modules/language-server/docs.md`

Extends the v0.beta.15 `definitionMember` machinery — the two recorded
non-goals there. File-disjoint from the Rules track and from §F/§T.

- [ ] **E1 (v16 §E1)** — Tuple-field `recv._N` resolves to the Nth element's
      declared type. Reuse `resolveChainType` + a new step that recognises
      the `_<digits>` synthetic field.
- [ ] **E2 (v16 §E2)** — Interface associated-function dispatch — a call to
      `Iface.method(...)` from another module jumps to the `default fn` in
      the interface source (not the empty `interface` declaration site).
- [ ] **E3 (v16 §E3)** — Note both paths in
      `modules/language-server/AGENTS.md` + `docs.md`. Regression tests
      under `language-server/src/tests/`.

### Test scenarios — §E

```
E1  ---- definition of recv._0 on a (i32, string) pair jumps to the i32 type token
E2  ---- definition of Iface.method() from another module jumps to interface default fn
E3  ---- AGENTS.md + docs.md updated in the same commit; new tests green
```

## §F — typescript `.d.ts` template skip (close v0.beta.16 §F)

**Files**: `modules/compiler-core/src/codegen/typescript.zig` ·
`codegen/tests/dts_skips_templates.zig` (new) ·
`modules/compiler-core/src/codegen/AGENTS.md`

`.d.ts` currently emits `@Expr<…>` / `@ExprCustom<…>` return-fn signatures
(template fns the host can never call directly). File-disjoint from
everything else in this frente.

- [ ] **F1 (v16 §F1)** — In `typescript.zig`'s decl emitter, skip any fn whose
      return type starts with `@Expr<` / `@ExprCustom<` / is `@expr` /
      `@code`. The body still emits via commonJS; only the `.d.ts` skips.
- [ ] **F2 (v16 §F2)** — Remove the "KNOWN GAP" note in `codegen/AGENTS.md`
      pointing at this; add a `.d.ts` snapshot asserting no `Expr<>` shows up.

### Test scenarios — §F

```
F1  ---- .d.ts for libs/erika has zero `Expr<` or `ExprCustom<` occurrences
F2  ---- codegen/AGENTS.md KNOWN GAP note removed; snapshot under codegen/tests/ asserts absence
```

## §T — test-run-log (net-new tooling)

**Files**: `modules/compiler-core/src/codegen/{commonJS,erlang,beam_asm,wat}.zig`
(test-mode entry: each backend's `emitTestRunner` / `__bp_run_tests` path) ·
`modules/compiler-core/src/runtime.zig` (host-side `execute*` paths that
invoke node / escript / wasmtime — capture stdout per test) ·
`modules/compiler-cli/src/cli/test_cmd.zig` (the `botopink test` driver) ·
`modules/lib-test-runner/src/{runner,report}.zig` ·
`modules/compiler-core/AGENTS.md` (`codegen/` test-mode subsection) ·
`libs/std/AGENTS.md` (note the new log capture in the `test` block doc) ·
`tests/cli/test_run_log_format.zig` (new) · `snapshots/cli/test/` (new
fixtures)

### Premise

Today `botopink test` prints a one-line pass / fail per `test { … }` block.
Any output the test wrote (`@print(...)`, `println(...)`, `debug(...)`,
host `console.log(...)` / `io:format(...)`) goes to stdout interleaved with
the runner's own progress lines — readable for a human, useless for
snapshot comparison or mock assertion.

This track captures everything a test wrote to the print sink and replays
it under a structured fence between the test header and the pass / fail
status, so a follow-up consumer (a snapshot test, a CI gate, an LSP
test-output panel, or a mock-asserting harness) can extract a test's
observable output as a single addressable string.

### Target format

For each `test "…" { … }` block, the runner emits:

````
TEST    libs/erika/src/erika.bp:42  query joins on user id
----- RUN LOG -----
```logs
hello from inside the test
got 3 rows
```
PASS    libs/erika/src/erika.bp:42  query joins on user id  (1.2ms)
````

Rules:

1. **The fence is mandatory, even when empty.** A test that wrote nothing
   still emits `----- RUN LOG -----\n```logs\n```\n` so a downstream parser
   can address every test's log slot uniformly.
2. **The log captures `@print`, `println`, `debug`, plus any host-target
   stdout** the user could otherwise inject. Captured output is the
   byte-stream the test produced — no normalisation, no trimming.
3. **The fence body uses the `logs` language tag.** Stable hook every
   consumer keys on.
4. **A test that prints the sentinel** does NOT escape it — documented as
   the user's responsibility.
5. **Order**: the run-log block appears **between** the `TEST` header and
   the `PASS` / `FAIL` line; independent of pass / fail status.
6. **Multi-process tests**: each spawned process's stdout is captured up to
   the test's join point; concurrent writes interleave (user's
   responsibility).
7. **`lib-test-runner`'s cross-lib aggregator** emits the same format,
   prefixed by the lib name (`[erika] TEST …`).

### Steps — §T

- [ ] **T0 — runtime capture primitive.** Add
      `runtime.zig.captureStdout(child: *std.process.Child) ![]u8`. Each
      existing `execute*` path becomes `(exit_code, stdout_bytes)`.
      Threading through `test_cmd.zig` + `lib-test-runner`.
- [ ] **T1 — per-backend test-mode codegen.**
      - **commonJS**: wrap each test body so the generated runner emits
        `TEST <file>:<line> <name>\n----- RUN LOG -----\n```logs\n` before
        the body and `\n```\n` after. Flush before the closing fence.
      - **erlang**: same wrapper via `io:put_chars/1`.
      - **beam_asm**: same via `call_ext` to `io:put_chars/1`.
      - **wat**: wired after Frente A's §C2; document the dependency, do
        not block §T on §C2.
- [ ] **T2 — CLI formatting (`test_cmd.zig`).** Parse the captured stdout:
      split on the `TEST` and run-log sentinels; group log bytes by test.
      Add a `--json` mode that emits per-test
      `{file, line, name, status, duration_ms, run_log}` records. Default
      human-readable output matches §"Target format" exactly.
- [ ] **T3 — `lib-test-runner` cross-lib aggregator.** `report.zig` formats
      `[<lib>] TEST <file>:<line> <name>` and `[<lib>] PASS …`. `--json`
      records carry an additional `lib` field.
- [ ] **T4 — tests + snapshots.**
      `tests/cli/test_run_log_format.zig` synthesises a fixture exercising
      pass-with-output / fail-with-output / pass-empty / multi-test
      ordering on each backend; assert byte-exact match against
      `snapshots/cli/test/`. `tests/cli/test_run_log_json.zig` covers
      `--json` schema.
- [ ] **T5 — docs.** `modules/compiler-cli/AGENTS.md` gains a "Test output
      format" subsection with the rules verbatim. Mirror in
      `modules/lib-test-runner/AGENTS.md` (lib-prefixed).
      `libs/std/AGENTS.md` gains one paragraph under "test blocks". Link
      from `modules/compiler-core/AGENTS.md` codegen section.

### Test scenarios — §T

```
T0       ---- runtime.captureStdout returns the child's full stdout
T1-CJS   ---- a 1-test fixture under --target commonJS emits exact bytes per "Target format"
T1-ERL   ---- same on --target erlang
T1-BEM   ---- same on --target beam
T1-WAT   ---- once Frente A §C2 lands: same on --target wasm
T2       ---- `botopink test --json` outputs valid JSON with run_log field per test
T2-empty ---- a passing test that prints nothing still emits the empty ````logs\n```` fence
T2-fail  ---- a failing test still emits the run-log block before the FAIL line + reason
T3       ---- `botopink-lib-test` against multi-lib fixture: each per-test record carries `lib` + `run_log`
T4       ---- snapshot suites match byte-for-byte; --json schema documented in AGENTS
T5       ---- AGENTS.md sweep across the 4 touched modules in the same commit as the code
mock     ---- a downstream snapshot test reads the run_log string from --json and asserts against a fixture file
```

### Notes — §T

- **Why the fence is mandatory even when empty.** Symmetric output keeps
  consumers simple — no "either there's a log or there isn't" branch.
- **No third-party logging lib.** Plain stdout capture into a fixed-format
  fence. The user-emitted bytes are the log; no levels, no JSON-structured
  log records *inside* the fence.
- **Why `logs` (not `text`) as the fence tag.** Stable hook for downstream
  renderers; unambiguous and renders without language-specific highlighting
  in standard markdown engines.
- **`--json` mode is not optional.** Snapshot / mock assertion needs a
  structured surface.
- **Cross-spec interaction with §1's auto-wrap.** A `#[@result]` test body
  that `throw`s emits the auto-wrap form to the backend, but the captured
  stdout is unchanged — only the return / error payload changes, not what
  the body wrote via `@print`. The auto-wrapping does not leak into this
  track's surface.

---

## Coordination notes (whole frente)

- **§D-D4 in Frente A consumes the Rules track's §1F.** Schedule the
  Rules track's `#[@future]` contract first; Frente A reads it. Schedule
  call-out also in `frente-a-compiler.md`.
- **§S in Frente A and the Rules track are parallel.** The Rules track
  assumes `*fn` is already a syntax error, but if §S hasn't landed yet,
  no rule fires — `*fn` users get the §S diagnostic instead. After §S
  ships, the Rules track is the only authoritative effect surface.
- **§T and Frente A §C2 (wasm test runner).** §T wires every backend's
  test-mode codegen; wat is gated on §C2 having landed. Land in either
  order — §T's commonJS/erlang/beam shipping doesn't block on wasm; the
  wat path turns green later.
- **No `--no-verify` ever.** Pre-commit gate stays green at every commit.
- **AGENTS.md in the same commit as the code it documents.** Memory rule.
