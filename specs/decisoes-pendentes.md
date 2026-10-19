# Decisões pendentes

As perguntas abertas do milestone corrente, 1.0.12-beta; um arquivo acima de todo milestone desde 2026-10-18.

**36 perguntas e 8 contradições estão abertas, e 100 escolhas de implementação aguardam confirmação** (contadas das
entradas abaixo: uma pergunta com letra, sendo `nat-d` e `nat-f` títulos de seus casos; `ctr-*` e `119-a` as
contradições; uma linha de uma tabela de escolhas, ou uma entrada `#####` ao lado dela).

- Uma resposta vai para [`decisions-taken-steps.md`](decisions-taken-steps.md) sob o próximo número livre (mantido
  só lá); um id com letra nunca é renumerado nem reutilizado.
- Toda recomendação é a leitura mais restritiva, sem configuração que a contorne (decisão 67).
- Uma frente que encontra uma pergunta que não consegue responder pelo código a acrescenta aqui: id · título · Medido
  (observado, re-executável) · Opções · Recomendação · Bloqueia. *Proposta* = levantada sem id.

- **Bloqueando agora** — prioridade máxima: as perguntas que seguram hoje o trabalho da máquina 2, as que mais bloqueiam primeiro; um índice de entradas mantidas nas suas seções.
- **Bloqueando agora — máquina 1 e frente 165** — o mesmo para os passos da máquina 1 e a frente 165.
- **Máquina 1** — prioridade máxima: as perguntas que a máquina 1 da frente 144 espera, por passo.
- **Máquina 2** — prioridade máxima: as perguntas que a máquina 2 da frente 144 espera, as mais urgentes primeiro. O desenvolvimento novo está centrado na frente 164 wasm-gc (s1 → s4, wasmtime-a, wasmgc-a).
- **Frente 165** — rakun-workspace: um repositório `rakun`, 17 pacotes plug-and-play (mono-a).
- **Parte 1** — o que bloqueia a frente 144 (`repository/botopink-lang`, decisão 433: os passos abertos das antigas trilhas
  `00-gate`, `01-compiler`, `02-std-and-packaging`, `03-bundled-libs`), por antiga trilha, depois as
  escolhas de implementação dessas trilhas que aguardam confirmação.
- **Parte 2** — o resto (trilhas 04–10, 20, propriedade, contradições que não bloqueiam nenhum passo 00–03).
- **Parte 3** — as escolhas de implementação das trilhas 04–09.

A página em português (`decisoes-pendentes.md`) é a tradução direta desta página: o texto em inglês guarda o sentido
(`AGENTS.md` da meta § Conventions). Ids respondidos saem deste arquivo; `decisions-taken-steps.md` guarda as respostas e o próximo
número livre, que é **755**.

## Bloqueando agora — prioridade máxima (máquina 2, 2026-10-15)

As perguntas que seguram hoje o trabalho da máquina 2, as que mais bloqueiam primeiro. Cada uma é explicada aqui em
poucas linhas — o problema, um exemplo, as opções, a recomendação e por quê — e a sua entrada completa (Medido, todas as
opções) fica na § Máquina 2. Marque uma opção por pergunta (`[x]`); o coordenador transforma a resposta marcada numa decisão, e a pergunta sai desta lista.

Nenhuma pergunta segura o trabalho da máquina 2 hoje; as abertas seguram uma linha cada, ou nada construído (§ Máquina 2).

## Bloqueando agora — máquina 1 e frente 165 (2026-10-15)

As perguntas que seguram hoje os passos da máquina 1 e a frente 165, as que mais bloqueiam primeiro. Cada entrada fica na sua seção; esta tabela as indexa e sai quando são respondidas. Com a § Bloqueando agora — máquina 2 acima, estas são as perguntas a responder primeiro.

| # | Pergunta | O que decide | Trava | Recomendação |
|---|---|---|---|---|
| 1 | **50-b** — o que o servidor de dev (`onze dev`, agora rakun-ssr) faz numa mudança (§ Parte 2, 07-onze) | se o servidor de dev reinicia a partir de um build novo a cada mudança ou carrega a quente os módulos mudados | 50 passo 2; 53 passo 6 | (a) `build` e depois `start` a cada mudança |

Abertas e sem travar nada (frente 165): **165-b** (três nomes de pacote), **548-a** (toda biblioteca linka seu código),
**548-b** (os nomes de código que guardam o nome de uma biblioteca antiga).

---

## Máquina 1 — prioridade máxima (frente 144, `machine-1/144-checker/`)

As perguntas que os passos da máquina 1 esperam (lane A, B-19, B-22, B-23, B-24, B-25, B-27, B-55, B-60, o grupo do
modelo de módulos), respondidas antes de toda outra parte desta página; na ordem dos passos que travam.

#### B-02-c · `"std:…"` escrito como `template` de `.JavaScript` / `.Erlang`: código de host, ou recusado como os outros prefixos? (decisões 305, 481; 144 B-02)
- **Proposto (opus, 2026-10-13; aguardando o mantenedor):** **(a): recusado em todo target, nomeando a forma rotulada** — o `conformance/docs.md` § Host bindings já diz que as quatro strings com prefixo são recusadas no argumento em todo target; uma string que se lê como cell e roda como código de host é a ambiguidade que a 305 removeu. Desde a 575 (6), a 610 e a 621 a cell é um valor de `Implementation` e `std` é um campo rotulado só de `.Wasm` (`.Wasm(std: "hash.contentHash")`); `.JavaScript` e `.Erlang` têm só `template` e `body`, então a pergunta se estreita a um texto de `template` que começa com `std:`. Muda: a checagem do `template` recusa `"std:"` em `.JavaScript` e `.Erlang` também; uma cell.
- **Medido.** As checagens da tabela (516, mantidas sobre o valor pela 575 (6)) recusam `"std:…"` só num template de `.Wasm` (antes da 606: `@External.Wasm`); num template de `.JavaScript` / `.Erlang` é código de host ("`std:` was only ever a wasm cell").
- **Opções.**
  (a) Recusado em todo lugar.
  ```bp
  #[compiler.external(.JavaScript("std:hash.contentHash"))]   // refused: a `std:` cell is `.Wasm(std: …)`'s
  ```
  (b) Código de host fora do wasm, o texto corrigido.
  ```bp
  #[compiler.external(.JavaScript("std:hash.contentHash"))]   // JavaScript source `std:hash.contentHash`
  ```
- **Recomendação.** (a).
- **Trava.** A linha do `std:` do 144 B-02.

#### B-10-b · `compiler.variants(d)`: o que uma entrada carrega, incluindo uma seção? (decisões 268, 298; 144 B-10 G1)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): `Variant(name: string, fields: compiler.Field<unknown>[], annotations: DeclAnnotation[], section: ?string)`**, um record do `compiler.bp` ao lado dos records de handle (608) — uma variante com payload lista seus campos como `compiler.fields(T)` (576 (8), 630); uma seção não é entrada, suas variantes carregam o nome da seção. Uma entrada por variante construível.
- **Medido.** `compiler.variants(d)` (antes da 576: `Decl.variants`) carrega só nomes, com as seções listadas entre eles.
- **Opções.**
  (a) Entradas tipadas, seções como campo.
  ```bp
  compiler.variants(decl)[0].fields[0].name   // "amount"
  ```
  (b) Como hoje: nomes.
  ```bp
  compiler.variants(decl)[0]   // "Paid" — a name, sections among them
  ```
- **Recomendação.** (a).
- **Trava.** A linha do 144 B-10.

#### B-10-c · `clock.formatIso8601`: qual texto é a resposta única? (decisão 497; 144 B-10 G1)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): sempre milissegundos, `.sssZ`** — `2026-10-12T20:31:02.000Z` em todo target; uma largura fixa ordena como texto e é lida de volta por uma regra só.
- **Medido.** o commonJS responde sempre `.sssZ` (o `toISOString` do node); o erlang nunca escreve milissegundos.
- **Opções.**
  (a) Sempre `.sssZ`.
  ```bp
  clock.formatIso8601(t)   // 2026-10-12T20:31:02.000Z
  ```
  (b) Milissegundos só quando não são zero.
  ```bp
  clock.formatIso8601(t)   // 2026-10-12T20:31:02Z, .123Z only when nonzero
  ```
- **Recomendação.** (a).
- **Trava.** A linha do 144 B-10.

#### B-10-e · Como um alias de tipo de `Component<Styled>` implementa um behavior? (144 B-10 G2)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(b): não implementa — um alias é o seu alvo**: `Styleable` é implementado por `Styled`, e `Component<Styled>` (sem `@` desde a 606 (1)) chega a ele por `R`; um alias não declara nada (um segundo nome, não um tipo). O marcador do styled é reescrito sobre a implementação de `Styled`. Relido sob a 629: um `val` nomeia um tipo onde quer que um tipo seja nomeado (629 (2)), mas só um tipo nominal — declarado, ou construído por `compiler.buildType(name, fields, implements)` — carrega uma cláusula `implement`; `buildTypeInline(fields)` não recebe nenhuma (629 (1)). A 629 não diz se um `val` que nomeia o nominal `Component<Styled>` poderia carregar uma, então (a) continua uma pergunta e não uma grafia.
- **Medido.** `pub val StyledView = Component<Styled>` não aceita `implement`; não existe grafia.
- **Opções.**
  (a) Um alias com `implement`.
  ```bp
  pub val StyledView = Component<Styled> implement Styleable;
  ```
  (b) Só o tipo alvo implementa.
  ```bp
  pub type Styled(…) implement Styleable { … }   // StyledView reaches it
  ```
- **Recomendação.** (b).
- **Trava.** A linha do 144 B-10.

#### B-10-f · Como um decorator lê se o `R` de um retorno `Component<R>` implementa `Renderable`? (decisões 268, 280; 144 B-10 G3)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): pelo `compiler.typeInfo` do retorno declarado** — `compiler.typeInfo(compiler.returnType(decl)).typeArg(0).implements(Renderable)`; o handle continua sendo o handle de uma declaração lido por `compiler.*` (576 (3)) e perguntas de tipo passam por `compiler.typeInfo`, a única reflexão de um tipo (606 (3)). Viável: `compiler.returnType(d)` como valor de tipo (hoje um nome) e `compiler.Info<T>.implements(B)`. Muda: dois membros; o marcador do jhonstart em `client.bp` sai.
- **Medido.** Nenhuma reflexão responde: `compiler.returnType(d)` (antes da 576: `decl.returnType`) é o nome do tipo como texto, e nenhum membro pergunta se um tipo implementa um behavior. Desde a 626 (2) o handle de um decorator pode ser tipado pelo que o decorator exige (`syntax decl: fn() -> string`), checado na anotação — um terceiro caminho, (c).
- **Opções.**
  (a) `compiler.typeInfo` do tipo de retorno.
  ```bp
  if (!compiler.typeInfo(compiler.returnType(decl)).typeArg(0).implements(Renderable)) compiler.fail("…", at: decl);
  ```
  (b) Uma leitura de `Compiler` sobre o handle.
  ```bp
  if (!compiler.returnImplements(decl, Renderable)) compiler.fail("…", at: decl);
  ```
  (c) O tipo do handle o diz (626 (2)); se `Component<Element>` cabe em `Component<Renderable>` por `Element implement Renderable` é uma regra de genéricos que a 626 não enuncia.
  ```bp
  pub fn page(syntax decl: fn() -> Component<Renderable>) -> void { … }   // a return whose R is no Renderable refused at the annotation
  ```
- **Recomendação.** (a).
- **Trava.** A linha do `Renderable` do 144 B-10 G3.

#### B-10-g · Um template declarado `-> View` cujo código construído é um `Element`: a expansão é um `View`? (decisões 275, 276; 144 B-10 G3)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): sim — a expansão é o que o template declara** — o `html` declarado `-> View` (576 (4), 578 (2): um template devolve um tipo comum, a sua árvore de referência anexada por `compiler.custom(ast)`) responde um `View` (`Component<Element>`), e um `Element` construído é checado contra ele como corpo de um componente; o `renderNode(html …)` do jhonstart e os seus componentes `-> Element` passam para `View`. Viável: a checagem do código construído contra `View` aceita um `Element` como resposta de um componente. Muda: os componentes do jhonstart (um commit de consumidor), uma cell.
- **Medido.** Com `-> View` (antes da 576: `-> @ExprCustom<View>`) toda expansão do `html` falha `expected Component, got Element`. A 578 (2) faz do `T` declarado o tipo da chamada, então a opção anterior — a chamada manter `Element` enquanto a declaração diz `View` — não pode ser escrita e saiu; o que resta é se o código `Element` construído é aceito contra `View` como resposta de um componente, ou recusado, o template tendo de construir o componente ele mesmo.
- **Opções.**
  (a) Um `View`: o `Element` construído aceito como resposta de um componente.
  ```bp
  fn Card() -> View { html @`<div/>` }   // the expansion is a View
  ```
  (b) Recusado como hoje; o `html` constrói ele mesmo o componente em volta do seu `Element`.
  ```bp
  fn Card() -> View { html @`<div/>` }   // expected Component, got Element — unless html answers the component
  ```
- **Recomendação.** (a).
- **Trava.** A linha do `View` do 144 B-10 G3.

#### B-17-h · As funções host só-`op:` do math no build: ganham cells `std:`? (decisões 452, 481; 144 B-17)
- **Proposto (opus, 2026-10-13; aguardando o mantenedor):** **(a): sim — uma cell de binding `std:` por função no std-wasm** (`floor`, `abs`, `trunc`, `sqrt`, `minF`, `maxF`), para o runtime de comptime as responder e elas dobrarem (380); um opcode não tem forma de host no build de outro jeito. Desde a 610 existe um terceiro caminho ao lado de `std:` e de só-runtime: um corpo botopink, `.Wasm(body: f)`, que a 594 (1) e a 633 nomeiam forma de build como `std:` é; uma cell `Wasm` guarda um só de `op` / `std` / `body`, então (a) e (b) igualmente tiram o opcode do target wasm.
- **Medido.** São recusadas no build (452) e não são mais tratadas como dobráveis; a 633 confirma a regra — uma forma wasm (`std:` ou `body:`) é chamável no build, um `op:` sozinho não.
- **Opções.**
  (a) Uma cell `std:` cada.
  ```bp
  #[compiler.external(.Erlang("…"), .JavaScript("…"), .Wasm(std: "math.sqrt"))] pub declare fn sqrt(x: f64) -> f64;
  val r = "${math.sqrt(16.0)}";   // computed at build by std-wasm's export
  ```
  (b) Um corpo botopink cada (610).
  ```bp
  fn sqrtBody(x: f64) -> f64 { … }
  #[compiler.external(.Erlang("…"), .JavaScript("…"), .Wasm(body: sqrtBody))] pub declare fn sqrt(x: f64) -> f64;
  val r = "${math.sqrt(16.0)}";   // computed at build by the body
  ```
  (c) Só em runtime.
  ```bp
  val r = "${math.sqrt(16.0)}";   // computed at run time
  ```
- **Recomendação.** (a).
- **Trava.** A linha do 144 B-17.

#### B-27-e · No erlang, `not-found.bpp` e `not_found.bp` viram o mesmo nome de módulo (decisões 561, 109; 144 B-27)
- **Proposta (opus, 2026-10-15; aguardando o mantenedor):** (a): o átomo do módulo erlang é escrito entre aspas a partir do nome do arquivo como escrito, então os dois nunca se encontram.
- **Contexto.** A decisão 561 deixa importar um arquivo cujo nome não é identificador (`not-found.bpp`) e pede que cada backend mapeie um nome sem colisão. No erlang o nome de um módulo passa pela limpeza da decisão 109, que troca os caracteres que um átomo sem aspas não aceita.
- **Medido.** A limpeza da decisão 109 transforma `not-found.bpp` em `…@not_found`, o mesmo módulo que um `not_found.bp` irmão; os dois sobrescreveriam o `.beam` um do outro. Nenhuma célula tem o par hoje.
- **Opções.**
  (a) ★ O átomo do módulo vai entre aspas e mantém o nome do arquivo (`'pages@not-found'`).
  ```erlang
  'app@pages@not-found':render(...)   % not_found.bp stays app@pages@not_found
  ```
  (b) A limpeza da decisão 109 fica, e o par é recusado no segundo arquivo ("`not-found.bpp` and `not_found.bp` are one module on erlang").
  ```text
  error: src/pages/not_found.bp and src/pages/not-found.bpp are one module on erlang (app@pages@not_found) — rename one
  ```
  (c) A limpeza da decisão 109 fica e nada é checado.
- **Recomendação.** (a): a 561 pede nenhuma colisão, e um átomo entre aspas é a forma do próprio erlang para tal nome; (b) se um átomo de módulo entre aspas quebrar alguma ferramenta.
- **Bloqueia.** Nada hoje; um pacote com os dois arquivos.

#### B-27-f · `Name<T>.f()` com um nome de tipo entre crases (decisão 561; 144 B-27)
- **Proposta (opus, 2026-10-15; aguardando o mantenedor):** (a): o parser distingue um tipo pelo que o nome é, não por uma primeira letra maiúscula.
- **Contexto.** Argumentos de tipo explícitos antes de um `.` (`Name<T>.f()`) só são lidos como tipo quando o nome começa com letra maiúscula. Um nome de tipo entre crases (`` `my point` ``) não tem essa letra, então não pode ser escrito ali; uma chamada `Name<T>(…)` já funciona.
- **Medido.** `` `my box`<i32>.make() `` não é lido como um tipo com argumentos de tipo; `` `my box`<i32>(…) `` é.
- **Opções.**
  (a) ★ Estendido: um nome entre crases seguido de `<…>.` é lido como tipo, como um maiúsculo.
  ```bp
  val b = `my box`<i32>.make();
  ```
  (b) Deixado como está: um tipo entre crases recebe seus argumentos de tipo só numa chamada ou numa posição de tipo.
  ```bp
  val b: `my box`<i32> = `my box`.make();
  ```
- **Recomendação.** (a): a 561 diz toda posição que recebe um nome.
- **Bloqueia.** Nada.

#### B-27-g2 · `io.terminal.keys()` no erlang e no beam (decisões 506 (c), 553; 144 B-27 passo 6)
- **Proposta (sonnet, 2026-10-15; aguardando o mantenedor):** (b): acrescentar `readKey() -> Task<?Key>` (sem `@` desde a 606 (1)) em todo target.
- **Contexto.** `keys()` responde um stream de teclas para prompts interativos. No erlang e no beam um `Stream` é gerado de forma ansiosa.
- **Medido.** No erlang / beam `keys()` junta toda a entrada antes de entregar a primeira tecla, então nunca responde num terminal vivo (trava sob um pty); o commonJS entrega preguiçosamente. `stdin.readChunk()` + `terminal.parseKey` funciona nos três targets.
- **Opções.**
  (a) `keys()` como está; um laço interativo no erlang lê `readChunk()` e `parseKey`.
  ```bp
  val chunk = await stdin.readChunk(); val key = terminal.parseKey(chunk);
  ```
  (b) ★ `readKey() -> Task<?Key>` em todo target, `keys()` mantido.
  ```bp
  val key = await terminal.readKey();   // one key, null at end of input
  ```
  (c) Esperar uma geração preguiçosa de `{ async iter -> … }` no erlang (553; a grafia de marcador da 584), `keys()` a única API.
  ```bp
  for (await terminal.keys()) { k -> … }   // lazy once 553 lands on erlang
  ```
- **Recomendação.** (b), ou (c) quando a 553 gerar preguiçosamente no erlang.
- **Bloqueia.** Prompts guiados por tecla (`cli.prompt`) no erlang.

#### B-27-g4 · Modo raw e tamanho do terminal no erlang fora do Linux (decisão 506 (c); 144 B-27 passo 6)
- **Proposta (sonnet, 2026-10-15; aguardando o mantenedor):** (a): só Linux, a chamada respondendo `Unsupported` nos outros.
- **Contexto.** `terminal.setRaw(on)` e `terminal.size()` precisam do dispositivo do terminal. O Node os tem embutidos; a VM Erlang não.
- **Medido.** No erlang / beam a implementação lê o `/proc/<pid>/fd/{0,1}` do Linux e roda `stty` (para limpar `isig` e ler o tamanho). macOS e Windows não têm `/proc`.
- **Opções.**
  (a) ★ Só Linux: nos outros `setRaw` responde `Error(Unsupported)` e `size()` `null`.
  ```bp
  case terminal.setRaw(true) { Ok(_) -> …; Error(e) -> … }   // macOS on erlang: Error(Unsupported)
  ```
  (b) Um caminho por SO (`/dev/tty` e `stty -f` no macOS; Windows recusado).
  ```bp
  terminal.setRaw(true);   // Linux and macOS on erlang
  ```
- **Recomendação.** (a): nenhum caminho sem teste é entregue.
- **Bloqueia.** Nada no Linux.

#### 564-d · Um módulo pode declarar um nome ao qual o compilador dá regras? (decisão 564; linha da máquina 1 do 144)
- **Proposta (opus, 2026-10-16; construída como (a), aguardando o mantenedor):** (b) para os nomes aos quais o compilador dá regras, (a) para o resto.
- **Contexto.** O `behavior` próprio ou importado de um módulo agora é dono do seu nome em toda posição de tipo, como um `type` de mesmo nome já era (`conformance/docs.md` § behavior). Alguns nomes do prelúdio carregam regras da linguagem: `Result` (`try`, `throw`), `Task`, `Component`, `Iterator`.
- **Medido.** Como construído, `pub behavior Result { fn score(self: Self) -> i32; }` compila e despacha; o `Result` do módulo é o que o nome lê ali, e `try` / `throw` ficam com o da std.
- **Opções.**
  (a) Sim, para todo nome: a declaração do módulo é o que o nome lê (construído).
  ```bp
  pub behavior Result { fn score(self: Self) -> i32; }   // accepted
  ```
  (b) ★ Recusado na declaração para um nome ao qual o compilador dá regras, localizado, nomeando a declaração da std, como `primitive-type-name-taken` faz para os primitivos; (a) para o resto.
  ```bp
  pub behavior Result { … }      // refused: `Result` is std's (builtins.d.bp), the language's rules use it
  pub behavior Component { … }   // accepted
  ```
- **Recomendação.** (b) para os nomes aos quais o compilador dá regras, (a) para o resto: nunca uma sombra silenciosa de um tipo da linguagem.
- **Bloqueia.** Nada.

#### 667-a · Como `v is t` chega ao tipo concreto: uma cópia especializada, ou o teste passado em tempo de execução (decisão 667; 144 B-146)
- **Proposto (sonnet, 2026-10-18; construído como (b), retido do pouso):** (a) como a 667 a enuncia.
- **Contexto.** 667: o parâmetro `comptime t: type<T>` é a especialização da função (417), então `e is t` é `e is Users` na cópia em que `get(Users)` compila.
- **Medido.** A thread não construiu cópia. A chamada passa a função de teste `{ v -> v is Users }` em tempo de execução e o corpo a chama. `is_type_parameter_refused` e `is_comptime_type_parameter` respondem igual nos quatro alvos. Uma diferença visível: repassar `t` a outra chamada (`r.count(t)`) é recusado `expr-value-of-type`, onde uma cópia especializada conheceria `t` no build e aceitaria (417).
- **Opções.**
  (a) ★ Uma cópia por argumento de tipo, como a 667 enuncia: `t` é conhecido no build dentro da cópia, e repassá-lo é um argumento `comptime` conhecido no build.
  ```bp
  pub fn count<T>(self: Registry, comptime t: type<T>) -> i32 { … }
  pub fn get<T>(self: Registry, comptime t: type<T>) -> ?T { if (self.count(t) == 0) { return null; } … }   // accepted
  ```
  (b) O teste passado em tempo de execução (construído): sem cópias, as mesmas respostas, e `t` não pode ser repassado.
  ```bp
  pub fn get<T>(self: Registry, comptime t: type<T>) -> ?T { if (self.count(t) == 0) { return null; } … }   // refused: expr-value-of-type
  ```
- **Recomendação.** (a): a leitura da própria decisão, e a única em que `t` se comporta como todo outro argumento `comptime`.
- **Bloqueia.** O pouso da 667 (terceira caixa do B-146) e o B-152 (668): o `async.failed(comptime t: type<T>, …)` da std e a célula `type_parameter_bound_by_token` precisam que o token chegue ao tempo de execução, e hoje ele não chega a nenhum (erlang deixa `I32` não ligado, wasm recusa, commonJS e beam abortam); as outras duas caixas do B-146 pousam sem ela.

#### 723-a · O que é `use memo`: o jeito em tempo de execução de um componente fazer o próprio contexto (decisão 723; 144 B-17)
- **Proposto (opus, 2026-10-19; não construído):** (a).
- **Contexto.** A 723 nomeia `val c = use memo({ -> createContext(Theme(…)) });` como o jeito em tempo de execução de um componente fazer um contexto para prover. A std não tem `memo`, e nenhuma decisão diz o que ele guarda ou quando recalcula.
- **Medido.** `use memo` não está ligado em nenhum alvo; a forma de build `comptime createContext(…)` funciona (célula `context_provide_made_in_body`).
- **Opções.**
  (a) ★ `memo<T>(make: fn() -> T) -> Component<T>` nos hooks da std: calculado na primeira renderização do componente, guardado para aquela instância do componente, nunca recalculado (sem lista de dependências).
  ```bp
  component fn Page(dark: bool) -> Component<Element> { val c = use memo({ -> createContext(Theme(dark: dark)) }); use provide(c); … }
  ```
  (b) `memo` com uma lista de dependências, recalculado quando uma muda.
  ```bp
  val c = use memo([dark], { -> createContext(Theme(dark: dark)) });
  ```
- **Recomendação.** (a): a única forma que a 723 escreve; uma lista de dependências é uma decisão posterior se um programa precisar.
- **Bloqueia.** A metade em tempo de execução do provide da 723 (célula `context_provide_made_at_run_time`); nada mais.

#### 723-b · Uma leitura de contexto pode nomear um parâmetro ou um local de tipo `Context<T>`? (decisões 722, 723; 144 B-17)
- **Proposto (opus, 2026-10-19; construído como (a)):** (a).
- **Contexto.** 722 / 723: um contexto é lido por um valor de contexto que o leitor importa; o handle fornece o tipo e o default.
- **Medido.** Como construído, `use context(ctx)` com `ctx` um parâmetro, um local ou uma expressão é recusado no argumento, `context-not-declared` (exemplo `context_read_of_parameter` em `conformance/docs.md`).
- **Opções.**
  (a) ★ Recusado: o argumento nomeia uma declaração de contexto de nível de módulo, local ou importada (construído).
  ```bp
  component fn Card(c: Context<Theme>) -> Component<Element> { val t = use context(c); … }   // refused: context-not-declared
  ```
  (b) Aceito: qualquer valor de tipo `Context<T>`; seu tipo e seu default vêm do valor.
  ```bp
  component fn Card(c: Context<Theme>) -> Component<Element> { val t = use context(c); … }   // accepted
  ```
- **Recomendação.** (a): a leitura mais restritiva, e a leitura continua resolvível no build a partir do texto.
- **Bloqueia.** Nada.

#### 723-c · Os defaults do `inject` e a checagem de um default por tipo, agora que um contexto é lido pelo seu handle (decisões 416, 722, 723, 379 (1))
- **Proposto (opus, 2026-10-19; construído como (a)):** (a).
- **Contexto.** A 722 retira o catálogo da 379 (1): uma leitura acha seu default pelo handle que nomeia. O `use inject(Deps)` da 416 ainda toma o default de cada campo como "o default declarado daquele tipo", o que exige achar as declarações por tipo; o `context-declared-twice` da 379 (1) (um default por tipo) é o que torna essa busca única.
- **Medido.** Como construído, `inject` e `context-declared-twice` não mudaram e ainda leem as declarações de contexto do programa por tipo.
- **Opções.**
  (a) ★ Manter os dois: `inject` resolve o default de um campo entre as declarações que o programa tem, e duas declarações sobre um tipo são recusadas (construído).
  ```bp
  pub val a = comptime createContext(Theme(…)); pub val b = comptime createContext(Theme(…));   // refused: context-declared-twice
  ```
  (b) `inject` perde o passo do default declarado (o mais próximo provido, senão o default do próprio campo, senão um erro); duas declarações sobre um tipo permitidas.
  ```bp
  type Deps(theme: Theme = Theme.default())   // the field's default when none is provided
  ```
- **Recomendação.** (a): a 416 vale como escrita e a 731 a mantém; (b) só se o maintainer não quiser busca de programa inteiro em lugar nenhum.
- **Bloqueia.** Nada.

#### 668-a · `compiler.meta<M>(d)` nomeia `M` só pelo retorno — a chamada reescrita `compiler.meta(d, M)`? (decisões 668, 298, 576 (3); 144 B-152)
- **Proposto (opus, 2026-10-19; construído como (b)):** (a).
- **Contexto.** 298 / 576 (3) escrevem a leitura `compiler.meta<M>(d) -> ?M` e `compiler.metaAll<M>(d) -> M[]`: `M` aparece só no tipo de retorno, o que a 668 recusa.
- **Medido.** Como construído, as declarações tomam `comptime m: type<M>` (a forma da 668) e o parser continua aceitando `compiler.meta<M>(d)`, reescrevendo para o token internamente.
- **Opções.**
  (a) ★ A chamada é escrita como a declaração lê: `compiler.meta(d, M)`; `compiler.meta<M>(d)` recusado como todo argumento de tipo explícito que não liga nada.
  ```bp
  val e = compiler.meta(decl, Entity);   // ?Entity
  ```
  (b) A grafia com argumento de tipo explícito continua, rebaixada para o token (construído).
  ```bp
  val e = compiler.meta<Entity>(decl);   // ?Entity
  ```
- **Recomendação.** (a): uma regra para toda função, `compiler` incluído; (b) mantém uma grafia que nenhuma função de usuário pode ter.
- **Bloqueia.** Nada (o B-152 está retido na 667-a).

#### 719-a · Uma função com parâmetro de expressão `syntax` pode responder `-> T`, código de tipo `T`? (decisões 719, 578 (2); 144 B-156)
- **Proposto (opus, 2026-10-19; construído como (b)):** (a).
- **Contexto.** A 719 manda a forma nova para os retornos da 578 (2): "um tipo, `anyvalue` ou `anytype`" — um template que responde `-> Component<Styled>` retorna código daquele tipo (célula `template_answer_component` do B-153). A caixa do B-156 diz que um retorno de tempo de execução (`-> void`, `-> i32`) é recusado na declaração.
- **Medido.** Como construído, só `-> anyvalue` e `-> anytype` são aceitos; `-> i32` e nenhum retorno são recusados `template-signature`, nomeando esses dois (célula `syntax_fn_run_time_return`).
- **Opções.**
  (a) ★ Como a 578 (2): todo tipo `T` é aceito e significa código de tipo `T`, checado onde é inserido; só `-> void` e nenhum retorno são recusados.
  ```bp
  pub fn twice(syntax e: i32) -> i32 { return code @`${e} + ${e}`; }   // accepted: code of type i32
  ```
  (b) Só `anyvalue` / `anytype` (construído): `-> i32` recusado como retorno de tempo de execução.
  ```bp
  pub fn twice(syntax e: i32) -> i32 { … }   // refused: template-signature
  ```
- **Recomendação.** (a): uma regra para o template e esta forma, como a 719 diz; o exemplo `-> i32` da caixa é anterior à leitura.
- **Bloqueia.** Nada; (a) afrouxa uma recusa.

#### 719-b · `compiler.source(value).file`: o caminho do módulo ou o arquivo? (decisões 719, 718; 144 B-156)
- **Proposto (opus, 2026-10-19; construído como (b)):** (a).
- **Contexto.** 719: `compiler.source(value)` é o `Source(file, line, col)` da chamada; o snap escreve o arquivo e a linha do teste em toda chamada. `builtins.d.bp` diz "module path (\"\" for main)".
- **Medido.** Como construído, `file` é o caminho do módulo: a célula `syntax_fn_expanded_at_call` imprime `main:32`, não `src/main.bp:32`.
- **Opções.**
  (a) ★ O arquivo, relativo à raiz do pacote, como os diagnósticos o imprimem.
  ```bp
  val at = compiler.source(value);   // at.file == "src/main.bp"
  ```
  (b) O caminho do módulo (construído).
  ```bp
  val at = compiler.source(value);   // at.file == "main"
  ```
- **Recomendação.** (a): o que a 719 nomeia e o que a localização de um snapshot precisa; o caminho do módulo é assunto de `compiler.name`.
- **Bloqueia.** O `matches` da frente 160 (a localização do snapshot); nada mais.

## Máquina 2 — prioridade máxima (frente 144, `machine-2/144-backends-tooling/`)

As perguntas que seguram um passo da máquina 2 (backends, runtimes, std, tooling, o gate), respondidas com as da
máquina 1 antes de toda outra parte desta página; cada uma segura uma linha, ou nada construído.

#### 164-s3-m · `bytes.at` fora do intervalo e `bytes.ofWords` sobre uma palavra fora de `0..255` (decisão 585 (k); 164 s3 P2-d)
- **Proposta (sonnet, 2026-10-17; regrafada em 2026-10-18; aguardando o mantenedor; construída como (a)):** **(a): `bytes.at` responde `-1` para um índice fora de `0..length-1`, como `text.byteAt` e `string.charCodeAt`; `bytes.ofWords` guarda os oito bits baixos de cada palavra.** A revisão (fable, 2026-10-17) recomenda (b).
- **Medido.** `modules/std-wasm/wat/bytes.wat`: `bytes.at` compara o índice sem sinal com `array.len` e responde `-1` além dele (um índice negativo incluído), o corpo de `text.byteAt` (P1-a) sobre o mesmo layout `$str` (`bytes` é um array de `i8`, 164 s2, 346); `string.charCodeAt` (641; então `String.charCodeAt`) responde `-1` fora do intervalo nos quatro alvos (`primitives.bp`: Erlang `_ -> -1`, Node `?? -1`, `text.zig`). `bytes.ofWords` escreve cada palavra com `array.set $str`: uma célula `i8` guarda os oito bits baixos, logo `256 + 33` é o byte `33`. Nenhuma operação de botopink constrói um `bytes` a partir de palavras (os membros do tipo, 641 — então `behavior Bytes`: `fromUtf8`, `toUtf8`, `length`, `concat`, `slice`), logo nenhum alvo tem uma resposta para comparar, e a 585 (k) nomeia as três folhas sem as suas respostas. Os codecs para que foram escritas (`base64DecodeBytes`, `hexDecodeBytes`) produzem palavras em `0..255` e leem índices em `0..length-1`: por eles nenhuma das respostas é observável; qualquer célula `std:` de `libs/std` (445) alcança as folhas. O teste unitário `wat: front 164 s3 ---- the Bytes leaves answer in a GC module` (`codegen/tests/wat.zig`) fixa `bytesOfWords([104, 105, 256 + 33])` como três bytes, `bytesAt(b, 2)` como `33`, `bytesAt(b, 3)` e `bytesAt(b, -1)` como `-1`. Sem a verificação, `array.get_u` dá trap fora de `0..length-1` (um abort `crash:`).
- **Opções.** (a) Como construído. (b) Ambas dão trap: `bytes.at` é o `array.get_u` nu (um trap fora de `0..length-1`, um índice negativo lido sem sinal incluído) e `bytes.ofWords` é `unreachable` na primeira palavra fora de `0..255`; os codecs `.bp` guardam os seus próprios limites; as três linhas do teste unitário substituídas. (c) `bytes.at` como `text.byteAt` (`-1`: uma resposta para uma leitura sobre um layout), `bytes.ofWords` dando trap.
- **Recomendação.** (b) — uma folha não responde nada fora do seu domínio e nenhuma palavra é truncada em silêncio; o `-1` de `text.byteAt` fica o do P1-a até o mantenedor estender a resposta a ele.
- **Bloqueia.** Nada construído espera; a metade `.bp` do P2-d (depois do B-139 e do s2 P5) lê a resposta antes de ser escrita.

#### 529-a · O que `..` como único spread deixa em aberto (decisões 529 (3), 359, 37; 144)
- **Proposto (sonnet, 2026-10-14; aguardando o mantenedor):** **(a) para cada um:** (1) nenhuma ferramenta de migração — nenhuma biblioteca escreve hoje um spread `...` em chamada (o único `{...pairs}` do jhonstart é um spread de tag que o compilador ainda não implementa); (2) a recusa da 37 de uma base que não é nome acabou: 359 (6) permite qualquer expressão de origem, avaliada uma vez (`record_update_base_not_a_name` responde `out 1`); (3) a atualização `..` de uma variante de enum continua recusada como `call-spread` (a linha de variante de enum da 359); (4) o caminho morto de atualização da decisão 37 em `infer.zig` é apagado.
- **Medido.** A 529 (3) pousou: `..src` é o spread de record, `...src` como spread é `spread-dot-dot-dot` nomeando `..`, o formatador imprime `..`, o botopink-lang migrado. Juntar as duas formas de spread moveu três respostas: `record_update_base_not_a_name` (uma recusa sob a 37) agora responde `out 1` sob a 359 (6); `Subject.Animal(..alice)` é `call-spread` (era um type mismatch); dois carets de recusa andaram uma coluna (o `..` mais curto). O parser recusa `...`, então o formatador não consegue ler um spread `...` antigo para migrá-lo.
- **Opções.** Cada ponto (a) como proposto ou (b): (1) o parser continua lendo `...` por uma versão, o formatador o reescrevendo; (2) a restrição da 37 mantida sob a 359; (3) a atualização de uma variante de enum permitida; (4) o caminho antigo mantido.
- **Recomendação.** (a) — a 359 é a regra posterior, nenhuma biblioteca precisa da grafia antiga.
- **Bloqueia.** Nada construído; a resposta de `record_update_base_not_a_name`.

#### 529-b · O que um parâmetro de record `..props: R` deixa em aberto (decisão 529 (2); 144)
- **Proposto (sonnet, 2026-10-14; aguardando o mantenedor):** **(a) para cada um:** (1) um parâmetro de record ao lado de um variádico recusado (`record-param-variadic`) — argumentos variádicos posicionais e campos rotulados colidem; (2) um default no parâmetro de record recusado (`record-param-default`) — os defaults dos próprios campos de `R` são os defaults; (3) as posições contam os outros parâmetros: em `fn f(a, ..p: R, b)`, `f(1, 2, x: 3)` passa `2` para `b`; (4) métodos e funções associadas recebem um parâmetro de record como as funções (um passo posterior o constrói); (5) um `R` genérico (`..p: Props<T>`) é legal, seus campos tipados pela chamada.
- **Medido.** A 529 (2) pousou para chamadas de função comuns: `..props: R` é um parâmetro comum de tipo `R`; o checker reescreve os rótulos de uma chamada que nomeiam campos de `R`, e um spread `..src`, numa única construção `R(…)`; quatro recusas que a 529 nomeia têm células. Construído além da 529 e a confirmar: (1) e (2) acima; (3) é como as posições são lidas hoje; métodos e funções associadas ainda não são reescritos; um `R` genérico é analisado e não foi testado.
- **Opções.** Cada ponto (a) como proposto ou (b) o seu oposto.
- **Recomendação.** (a) — as leituras mais estritas onde a 529 se cala, e a mesma regra para todo chamável.
- **Bloqueia.** Um parâmetro de record num método; nada construído fora isso.

#### 543-a · O que o s1 da front 164 (wasmtime) deixa em aberto (decisão 543)
- **Proposto (opus, 2026-10-14; aguardando o mantenedor):** **(1) Winch com o cache** — uma compilação a frio de 315 ms contra ~1000 ms do Cranelift, uma execução de 37 contra 33 ms; (2) o CLI e o LSP chamam `interrupt()` no SIGINT, para um corpo descontrolado terminar como um erro localizado; (3) o `attempt` no build captura o que captura num programa wasm — uma divisão inteira por zero faz trap lá, então é excluída no build também (uma resposta, 434 (5)); (4) o cache de módulos compilados é limpo pelo `botopink cache` do B-77.
- **Medido.** O s1 pousou no wasmtime v49 com Cranelift e o cache de módulos compilados (quente 48 ms, frio 1,0–1,3 s para 12 builds); o Winch não era uma das duas opções da 543; nenhum handler de SIGINT está instalado (Ctrl-C encerra o processo; `interrupt()` existe, nada o chama); o `attempt` no build também captura uma divisão inteira por zero, que faz trap num programa wasm; o cache não tem limpeza até o B-77.
- **Opções.** Cada ponto (a) como proposto ou (b): (1) manter o Cranelift; (2) nenhum handler; (3) continuar capturando no build; (4) um limite de tamanho já.
- **Recomendação.** (a) para cada um.
- **Bloqueia.** Nada construído.

#### 539-a · `throw` e um `try` que propaga dentro do corpo de um `defer`: recusados ou permitidos? (decisão 539 (5); 144)
- **Proposto (fable, 2026-10-14; aguardando o mantenedor):** **(c): recusar um `throw` e um `try` que propaga, localizados (`defer-throw`, `defer-try`); um `try … catch` tratado dentro do corpo continua** — a razão da 539 (5) é "não pode sair do caminho", e um throw sai dele: em `finally` / `after` o erro adiado substitui o erro sendo propagado, mascarando-o silenciosamente. O Zig recusa `try` num `defer`, o Swift recusa lançar.
- **Medido.** A 539 pousou em todos os targets com `return`, `break` / `continue` para fora do corpo, `yield` e `await` recusados; um `throw` ou um `try` que propaga no corpo compila, e seu erro substitui o do próprio bloco no commonJS, no erlang e no beam.
- **Opções.** (a) Recusar as duas formas, `catch` incluído. (b) Permitir: o erro adiado substitui o do bloco (hoje, não documentado). (c) Como proposto.
- **Recomendação.** (c).
- **Bloqueia.** Nada construído; duas células de recusa quando respondida.

#### 537-b · A precedência do `??` contra o parêntese da 537 (decisões 537 (2), 28, 330)
- **Proposto (fable, 2026-10-14; aguardando o mantenedor):** **(b): manter o `??` apertado; 537 (2) emendada para "`catch` é o infixo de menor precedência, abaixo do `??`"** — nenhum programa muda de significado, e a regra de parênteses da 330 já cobre o único vizinho ambíguo.
- **Medido.** A 537 dá ao `catch` "a precedência do `??`, abaixo de todo operador aritmético", mas o `??` é o nível binário mais apertado (decisão 28), recusado ao lado de `&&` / `||` (330). A std depende disso: `libs/std/src/hash.bp` (`h.at(2 * i) ?? 0 * 65536.0 + …`), `io/random.bp` (`64 + b.at(6) ?? 0 % 16`). O build fez o `catch` o mais baixo e deixou o `??` como estava.
- **Opções.** (a) O `??` vai para o nível do `catch`, com uma reescrita do formatador colocando parênteses em todo `??` ao lado de um operador aritmético. (b) Como proposto. (c) O `??` no nível do `||` (JS), o `catch` abaixo dele — a mesma migração de (a).
- **Recomendação.** (b).
- **Bloqueia.** Nada construído; só o texto da 537.

#### 535-b · Onde vive o texto de abort do commonJS: no guard do runner ou no programa emitido (decisão 535)
- **Proposto (fable, 2026-10-14; aguardando o mantenedor):** **(b): o módulo de entrada (o que tem `main`, nunca um módulo de biblioteca — um `process.on` global numa biblioteca é um efeito colateral) emite o handler; o guard do runner mantido para o `.mjs` do browser** — a 535 é sobre o que o programa escreve; uma regeneração mecânica dos snapshots de codegen do commonJS.
- **Medido.** A 535 pousou no commonJS como um guard `node --import` que o `botopink run` e os testes passam ao node; o `main.js` emitido não muda, e um `node main.js` rodado à mão imprime o relatório do próprio node. O guard do erlang também é do runner, mas um build erlang não tem entrada autocontida; um programa commonJS tem uma e é rodado pelo node fora do botopink.
- **Opções.** (a) Só o guard do runner, como pousou. (b) Como proposto. (c) Os dois.
- **Recomendação.** (b).
- **Bloqueia.** Nada; as células `abort_text_*` respondem o mesmo.

#### 532-a · O registro `from <file>:<line>:<col>` estende a 475 (2) (decisões 532, 475)
- **Proposto (fable, 2026-10-14; aguardando o mantenedor):** **(a): a 475 (2) emendada com `from`, o cabeçalho inalterado** — células mais antigas não são afetadas: o registro aparece só onde existem frames.
- **Medido.** A 475 (2) lista os registros do `.snap` exaustivamente; o build da 532 adicionou `from` (depois de `at` / `label`, o mais interno primeiro, comparado exatamente) no formato da célula e no `conformance/docs.md`. 13 células têm linhas `from`; o cabeçalho ainda é `botopink-cell 1`.
- **Opções.** (a) Como proposto. (b) `botopink-cell 2`. (c) Os frames dobrados na mensagem.
- **Recomendação.** (a).
- **Bloqueia.** Nada pousado; o texto da 475.

#### 533-a · `comptime-badarith` nomeia a expressão inteira enquanto o caret está no operador (decisões 533, 472)
- **Proposto (fable, 2026-10-14; aguardando o mantenedor):** **(b): a mensagem nomeia o fonte da operação que divide (`6 / (3 - 3)`, `a / b`), texto e caret concordando; as linhas `from` dão o `comptime`** — pouco em jogo.
- **Medido.** A 472 diz "a operação e o lugar"; depois da 533 o lugar é o operador mas o texto entre crases é a expressão inteira do `comptime` (`1 + 6 / (3 - 3) * 2`, `ratio(6, 0)`): `comptime_nested_division_by_zero`, `comptime_division_by_zero_in_helper`, `hole_any_call_raises`.
- **Opções.** (a) O texto do `comptime`, como pousou. (b) Como proposto. (c) Sem texto entre crases.
- **Recomendação.** (b).
- **Bloqueia.** Nada.

#### 540-b · `a.open()` exige `import {io.fs}` (decisão 538; 144)
- **Proposto (fable, 2026-10-14; aguardando o mantenedor):** **(a): manter a recusa `embed-open-needs-fs`** — `File` é um tipo da std; um valor cujo tipo o módulo não consegue nomear é a razão do Go para `import "embed"`.
- **Medido.** A 538 escreve `pub fn open(self: Asset) -> File` sem condição de import. O checker reescreve `a.open()` para `<fs>.openAsset(a)` (o alias mais curto de `io/fs`); sem o import é recusado na chamada (`embed_open_without_fs_import`).
- **Opções.** (a) Como construído. (b) Um import implícito de `io/fs` onde `a.open()` é escrito. (c) `File` ambiente em `builtins.d.bp`, `open` um método real de `Asset`.
- **Recomendação.** (a).
- **Bloqueia.** Nada.

#### 164-s3-g · `String.slice` (`text.slice`, `sliceFrom`, `sliceBetween`): com o P1 ou o P2? (164 s3)
- **Proposta (fable, 2026-10-15; aguardando o mantenedor):** **(a): P2, como um corpo em botopink que o `s[a..b]` / `s[i]` do codegen chama pelo prelúdio.**
- **Medido.** Os três são do próprio codegen (ele rebaixa `s[a..b]` e `s[i]` para eles), não métodos de `String` ligados por uma célula.
- **Opções.** (a) P2. (b) P1, como mais uma folha.
- **Recomendação.** (a).
- **Bloqueia.** Nada no P1.

#### B-116-k · O que o corpo de uma lambda `component` permite (decisão 574; 144 B-116 (i))
- **Proposta (opus, 2026-10-16; aguardando o mantenedor; construída como listado, a mais restritiva):** (1) um `throw` ou um `try` que propaga numa lambda `component` é recusado — `Component<Result<R, E>>` é do B-116 (iii); (2) os seus `use`s e `await`s não entram em nenhum nó de hook: o builder da função que a envolve é limpo para o corpo dela, então as suas chamadas recebem a leitura assíncrona conservadora da 375; (3) um corpo cuja última expressão termina com `;` é recusado como incompatível quando `R` não é `void`, onde uma `component fn` responderia `rendered(null)`.
- **Medido.** A 574 rebaixa `component { -> … }` como uma `component fn` (o caminho de component-fn, as capturas carregadas); `component_lambda_typed_val` e `component_lambda_typed_param` respondem nos quatro alvos. Os três pontos são casos que a 574 não nomeia.
- **Opções.** Cada ponto como construído, ou (b): (1) um `throw` permitido como numa `component fn` (um `ErrorBoundary` o pega, 414, 504); (2) os hooks da lambda juntados ao builder que a envolve; (3) um corpo terminado em `;` respondendo `rendered(null)` como uma `component fn` faz.
- **Recomendação.** (b) para (1) e (3), uma regra para uma `component fn` e uma lambda `component` como a 574 diz; (2) como construído até uma lambda `component` ter um builder próprio.
- **Bloqueia.** Nada construído espera.

#### 518-a · Duas recusas de `needs:` que nenhuma decisão afirma (decisão 518 (1); 144 B-07)
- **Proposto (o coordenador, 2026-10-15; aguardando o mantenedor):** **(a): as duas continuam recusas, cada uma com uma célula** — `needs:` em `@External.Node` / `@External.Erlang`, e `needs:` dado como qualquer coisa que não uma lista de valores `WasmNeed`; a leitura mais restritiva (67).
- **Medido.** A 518 (1) afirma uma recusa: um valor de `needs:` fora de `WasmNeed`. O build da 518 (7990b7de) também recusa `needs:` numa forma Node ou Erlang e um `needs:` que não é lista; nenhuma decisão afirma nenhuma das duas, e nenhuma célula as fixa (a análise da Conformance do B-07).
- **Opções.** (a) Como proposto. (b) `needs:` noutra forma aceito e ignorado. (c) Um valor só aceito como lista de um elemento.
- **Recomendação.** (a).
- **Bloqueia.** Nada construído; duas células de recusa uma vez respondida.

## Frente 165 — rakun-workspace (o mantenedor, 2026-10-14)

#### B-86-a · O `query` do gate lib-agnóstico, e o alcance do catálogo entre pacotes (144 B-86, frente 165 s4)
- **Proposta (opus, 2026-10-14; aguardando o mantenedor):** (1) o gate recusa `rakun` em qualquer caixa em qualquer lugar de `compiler-core/src`, e `query` só como pacote — a origem de import `"query"` ou o handle `import query`; (2) `jhonstart` sai da lista do gate, como a caixa diz; (3) a entrada do catálogo de uma dependência tem `module` = `<package>/<module>` (`plugin/root`), e as declarações de uma dependência transitiva também são listadas — construído assim, fixado por `modules/typeinfo_all_dependency_declarations`.
- **Medido.** `grep -riIE 'rakun|query' modules/compiler-core/src` casa cerca de 111 linhas: `query` é a palavra do próprio catálogo (`Query`, "a template body's query"). `@TypeInfo.all` já listava todo módulo do build, as dependências inclusas, e o journal do nível B já guarda `declared` e `meta`: a nova cell é verde no pai, em todo alvo, a frio e a partir do nível B. A referência diz "every module of the build", enquanto a decisão 242 deixa um programa importar só suas dependências diretas. Ordem e colisões seguem a regra existente (caminho do módulo, depois ordem de declaração; a chave é módulo e nome).
- **Opções.** (1)(a) ★ `query` só como pacote: `! grep -rIE '"query"|import query\b'`; (b) a palavra `query` em qualquer lugar, o vocabulário do catálogo renomeado. (2)(a) ★ `jhonstart` fora da lista (a caixa); (b) mantido até o 165 s2 renomeá-lo. (3)(a) ★ `<package>/<module>`, as dependências transitivas listadas; (b) só as dependências diretas listadas (a regra de import da 242).
  ```bp
  #[m] pub fn hello() -> string { "plugin" }   // in package plugin, module root
  // the program: @TypeInfo.all(with: m) lists { module: "plugin/root", name: "hello" }
  ```
- **Recomendação.** (a) para cada: (1) recusa toda grafia de pacote sem renomear a palavra própria da linguagem; (2) é o texto da caixa; (3) é o que `rakun.boot()` precisa — um módulo contribuído por um pacote duas camadas abaixo é descoberto.
- **Trava.** Nada — construído como (a); o 165 s5 lê (3).

#### 548-a · A referência de toda biblioteca linka seu código e checa os links? (decisão 548; 461, 463)
- **Contexto.** A referência de uma biblioteca — o `docs.md` ao lado das suas cells de conformance — mostra código. As decisões 461 e 463 apontam para o código de uma cell com `<!-- example: <cell> -->`; a decisão 548 (2026-10-15) faz a referência do rakun linkar o seu código em vez disso, como `[src/main.bp](src/main.bp)`, e checa que todo link nomeia um arquivo que existe. Hoje só o rakun faz isso; as outras bibliotecas e o botopink-lang mantêm a forma antiga, e o runner que elas compartilham não conhece nenhuma das duas. A pergunta é se todo repositório segue o rakun.
- **Medido.** A decisão 548 faz a referência do rakun linkar seu código (`[src/main.bp](src/main.bp)`, a base o diretório do `docs.md`) e o rakun checa todo link com seu próprio `scripts/check-doc-links.sh`, rodado pelo seu `repository-stages.sh`. As outras bibliotecas e o botopink-lang mantêm o `<!-- example: <cell> -->` da 461 / 463. O runner compartilhado (`runner-standalone.sh`, um texto entre as bibliotecas, check 4 da CI) não conhece nenhuma das formas.
- **Opções.**
  (a) ★ Toda biblioteca e o botopink-lang passam à forma da 548, a checagem de links no runner compartilhado (e `zig build test-docs` lendo `{path}`), uma frente por repositório.
  ```text
  conformance/<feature>/docs.md, in every repository:  [src/main.bp](src/main.bp)   ← a link to a file that does not exist fails the gate
  ```
  (b) Só o rakun; os outros mantêm `<!-- example -->`.
  ```text
  rakun:                          [src/main.bp](src/main.bp)
  other libraries, botopink-lang: <!-- example: <cell> -->
  ```
- **Recomendação.** (a): um só jeito de ler uma referência entre os repositórios.
- **Bloqueia.** Nada — o rakun é construído como a 548 diz.

#### 548-b · Os nomes de código que guardam o nome de uma biblioteca antiga (frente 165)
- **Contexto.** Depois da frente 165 os pacotes têm nomes novos — `rakun-stylesheet` para o emilia, `rakun-bpp` para o jhonstart, `rakun-ssr` para o onze (mono-a) — mas as funções, tipos, arquivos, URLs e prefixos de ambiente dentro deles guardam os nomes antigos das bibliotecas, então um usuário de `rakun-stylesheet` ainda chama `emilia()`. A pergunta é se um passo da frente 150 os renomeia para o vocabulário do pacote ou se eles ficam como a API.
- **Medido.** Depois do 165 os nomes de pacote são novos, mas o código guarda os antigos: `emilia()`, `emiliaWith`, `emiliaPlugin`, `emilia.bp`, a recusa `emilia-hash-split`, os sidecars `jhonstart_*.erl`, `OnzeConfig`, `Onze.run`, `ONZE_PUBLIC_`, `/_onze/`, `.onze`, `onze_main.bp`, os diretórios de exemplo `examples/rakun-stylesheet/emilia-*` e `examples/rakun-bpp/jhonstart-*`.
- **Opções.**
  (a) ★ Um passo do 150 os renomeia para o vocabulário do pacote (um codemod, todo consumidor e toda cell no mesmo commit).
  ```bp
  // a 150 step: `emilia()`, `OnzeConfig`, `/_onze/` … get rakun-stylesheet's and rakun-ssr's names; every consumer and cell in one commit
  ```
  (b) Ficam: os nomes são a API, só o nome do pacote mudou.
  ```bp
  // a program depending on `rakun-stylesheet` still calls `emilia()`; one on `rakun-ssr` still writes `OnzeConfig`
  ```
- **Recomendação.** (a): quem lê encontra um nome para uma coisa.
- **Bloqueia.** Nada.

#### 165-a · Onde ficam as linhas do conjunto de versões dos pacotes juntados (decisão 113; frente 165 s2)
- **Medido.** O `version_set.bp` do rakun guarda uma linha por pacote da família rakun; seu teste compara cada manifesto com a tabela. Após o 165 s1 o workspace tem 21 pacotes juntados (erika, emilia, styled, jhonstart, onze e seus `*-test` / subpacotes) sem linha: uma linha que nomeia `onze` no `src` do núcleo do rakun quebra o grep da decisão 113 (o núcleo do rakun não nomeia nenhum consumidor), então o teste lê só os manifestos `rakun*`.
- **Opções.** (a) ★ Nenhuma até o s2: após a renomeação todo pacote é `rakun-*`, as linhas são escritas então, e o filtro sai. (b) Um conjunto de versões fora do núcleo (um arquivo no nível do workspace que o gate lê), todo membro uma linha agora.
- **Recomendação.** (a): o s2 renomeia todo pacote para um nome `rakun-*`, então as linhas não precisam de exceção; uma versão para o workspace (o README) faz da tabela uma linha por pacote no s2.
- **Trava.** Nada antes do s2; o s2 escreve as linhas.

#### 165-b · Três pacotes fora da tabela do 165: `onze-server`, `jhonstart-dom-test`, `rakun-cli` (frente 165 s2)
- **Contexto.** A frente 165 junta sete repositórios num workspace `rakun` e dá a todo pacote um nome `rakun-*` e uma linha na sua tabela (mono-a). Três pacotes não couberam: `onze-server` e `jhonstart-dom-test` se juntariam a um pacote compilado para outro conjunto de alvos, e `rakun-cli` não tem linha. A linguagem define alvos por pacote, não por módulo nem por dependência, então o 165 s2 os deixou como pacotes próprios; a pergunta é como eles se chamam e se a tabela ganha as suas linhas.
- **Medido.** O 165 s2 dobrou todo pacote da tabela menos três. `onze-server` precisa do `rakun` (só erlang) enquanto `rakun-ssr` compila também para commonJS (seu CLI roda no node): dobrado, 21 vermelhos em commonJS (`rkReqLive` has no External for the node backend) — a linguagem não tem alvo por módulo nem dependência por alvo. Os externals de `jhonstart-dom-test` são só node enquanto `rakun-bpp` compila para erlang. `rakun-cli` não está em nenhuma linha da tabela. Construído: os três ficam pacotes próprios (`onze-server` dependendo de `rakun-ssr`, `rakun-app`, `rakun-service`; `jhonstart-dom-test` de `rakun-bpp`).
- **Opções.**
  (a) ★ Três pacotes nomeados na tabela: `rakun-ssr-server` (era `onze-server`), `rakun-bpp-dom-test` (era `jhonstart-dom-test`), `rakun-cli` como está, cada um sua linha com seus alvos.
  ```text
  modules/rakun-ssr-server/     was onze-server, needs rakun (erlang)
  modules/rakun-bpp-dom-test/   was jhonstart-dom-test, node-only externals
  modules/rakun-cli/            as it is
  ```
  (b) Uma feature da linguagem primeiro — o conjunto de alvos de um módulo ou de uma dependência — e os três dobrados em `rakun-ssr`, `rakun-bpp` (um passo do 144).
  ```text
  onze-server folded into rakun-ssr today: 21 commonJS reds — `rkReqLive` has no External for the node backend
  ```
- **Recomendação.** (a): um pacote é hoje a unidade de um conjunto de alvos; três linhas nomeadas mantêm a regra do 165 (todo pacote um nome `rakun-*`, uma linha cada) sem feature nova da linguagem.
- **Trava.** Nada; os nomes mudam na segunda caixa do s5 ou no s7.

## Parte 1 — O que bloqueia as trilhas 00–03

### 01-compiler

`00-gate` não tem pergunta aberta: os passos da 114 não esperam nenhuma decisão.

#### s23-c · O que o `Declared` de uma declaração alcançada guarda num corpo de decorator
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(b), e a leitura de meta tipada** — num corpo de decorator o `value` de uma declaração alcançada (`h.hook.value`, `c.callee.value`, `n.function.value`) é recusado na leitura, localizado (`decl-hooks-value: a reached function is no value at build`), como o `value` de catálogo de um corpo de template é (`typeinfo-all-template-value`); seu meta é lido tipado — `h.hook.meta(Route)` → `Route[]` (298, 130-s8-a), respondido no build quando `Route` é dado e recusado nomeando o campo de run-time caso contrário (415 (3), 380) — nunca a lista de strings `<decorator>.<key>`. Recusar antes de aceitar (67): um `null` tipado como a função esconde que não há nada ali, e a 364 (3) já diz que uma função não tem valor no build; strings carregando os fatos de um decorator são o legado da 216 (2), que o próprio `builtins.d.bp` marca como de saída. Viável: a recusa de corpo de template em `infer.zig` (guardada por `env.inTemplateFn`) ampliada para um corpo de decorator, um id em `diagnostics.zig`; `hooks.zig` `declaredTerm` constrói o termo (escreve `value` como `undefined` e o `meta` de string, e não escreve a chave `typedMeta` hoje, então uma leitura direta de `typedMeta` provavelmente falha em run time — uma linha 144); a leitura tipada segue a regra de `meta_read_at_build` para dados. Mudanças: `Declared.meta: DeclaredMeta[]` sai com o meta de string; o comentário sobre `Declared` em `builtins.d.bp`; uma célula de recusa.
- **Medido.** `HookUse.hook`, `HookCall.callee` e `HookNode.function` são `Declared<unknown>`. Construído: `value` é
  `null` (nenhuma função do programa roda enquanto ele compila, 364 (3)), e `meta` é toda entrada que os decorators da
  declaração definiram até então, com chave `<decorator>.<key>` (`DeclaredMeta(key: "route.path", value: "/about")`). A leitura de `value`
  de uma entrada de catálogo no corpo de um template é recusada (`typeinfo-all-template-value`).
- **Opções.** (a) Como construído: `h.value == null` é `true`; `h.meta` lista `route.path`. (b) `h.value` recusado na leitura
  num corpo de decorator, como num corpo de template (`decl-hooks-value: a reached function is no value at build`); `meta` como
  (a). (c) (b), e `meta` guarda só as entradas do decorator que lê a lista (`path`), como uma entrada de catálogo
  guarda as de `d`.
- **Recomendação.** (b): recusar > aceitar; um `null` que passa na checagem de tipos como a função esconde que não há nada ali.
- **Bloqueia.** Nada — construído como (a).

#### 14s8-c · Um buraco conhecido no build cujo valor lança lá
- **Respondida (o mantenedor, 2026-10-11; aguardando seu número em `decisions-taken.md`):** **(a), pela 14s8-a (e).** A expressão de um buraco é emendada no código gerado; quando o compilador a dobra no build (355 / 376) e ela lança, o build é recusado no buraco do usuário, localizado — nunca adiado para o render.
- **Medido.** Um buraco conhecido no build é avaliado no runtime de comptime como um `comptime` é (331). Construído: um lançamento é recusado no buraco — `pub val boom = raising "x"; pub val read = quote "${boom}";` (`raising` construindo `crash("x")`, que dá `@panic`) é ``this hole is known at build (decision 355) and its value raised there: the comptime block raised: {error,{panic,<<"crash: x">>}}`` em `${boom}` (`reject/hole_known_at_build_raises`).
- **Opções.** (a) Recusado no buraco (como construído). (b) O buraco é calculado na renderização (`known` falso): `read` constrói, e o programa lança quando lê `boom`.
- **Recomendação.** (a) — falhar > avisar, no build e não em tempo de execução.
- **Bloqueia.** Nada — construído como (a).

#### 14s8-e · Um `comptime` que alcança um componente que lê um contexto (`comptime padAll(2)`)
- **Respondida (o mantenedor, 2026-10-11; aguardando seu número em `decisions-taken.md`):** **`use` existe só no corpo de um `@Component`, e um hook é um `@Component<R>` — então um `comptime` ou um buraco nunca alcança um.** (1) Um hook é um componente que responde um valor: `pub fn usePad(n: i32) -> @Component<StyledProperty> { val cfg = use context(StyleConfig); return padAll(n, cfg); }`, lido num componente com `val p = use usePad(2);` (`use` o executa com o scope do corpo e responde `R`). (2) `use` escrito numa função que não responde `@Component<R>` é recusado no `use`, localizado (`use` is allowed only in a component's body — `padAll` answers `StyledProperty`). (3) Chamar um componente ou um hook sem `use` só cria sua lambda (504), então uma expressão solta nunca executa um `use`; só o renderer executa — no build também, com `RenderScope.root()`, onde `use context` lê o padrão declarado (388 (4)). (4) Um contexto é declarado e lido como a 354 (2) o escreve — `pub val styleContext = comptime createContext(StyleConfig(unit: 4));`, lido pelo tipo do seu valor `use context(StyleConfig)`, fornecido por `use provide(createContext(StyleConfig(unit: 5)))` — e seu valor é imutável (nenhum campo `var`; um que tenha é recusado, localizado), então ler seu padrão no build é seguro. (5) O styled mantém suas funções puras, a config um parâmetro (`padAll(n, cfg: StyleConfig = StyleConfig(unit: 4))`), calculadas no build num buraco ou num `comptime`; um componente lê `StyleConfig` com `use context(StyleConfig)` ou usa o hook `use usePad(2)`. O `use context(StyleConfig); sheet.add(…)` de hoje sai: as regras viajam como dado (`StyledProperty(className, rule)`), coletadas onde são usadas (355 / 377).
- **Medido.** A caixa do passo 8 lia `comptime padAll(2).rules` como recusado em `.contentHash(…)`; com
  `contentHash` carregado (passo 6, 341) a execução agora alcança o `styledPropertyComputed` do styled, cujo corpo
  é `val sheet = use context(StyledContext); … sheet.add(sheet.layer, …)` — um `comptime` não tem árvore
  de renderização (354 (3)), então nada provê `StyledContext`, e a execução parou em ``the comptime block calls
  `.add(…)` with 2 argument(s) at 144:11, which no primitive type … provides`` (botopink-lang, styled `feat`). A 376 (3) faz `context` ser `Any`, e a 355 / 376 (5) calculam
  `styled "${padAll(2)}"` no build — mas no build não há provedor para ler.
- **Opções.** (a) ★ Um `comptime` (ou um buraco calculado no build) que alcança um `use` numa função que
  carrega é recusado no `comptime`, nomeando o `use` e sua função: ``the comptime reaches `use
  context.context(…)` at 139:17 in `__bp_tpl_styled_styled__propertyComputed`, and a `comptime` runs with
  no render tree: nothing provides what the `use` reads (decision 354 (3))`` (`reject/comptime_reaches_use`); `padAll(2)` fica na renderização até o styled não ler
  contexto nesse caminho. (b) O build provê o default declarado de cada contexto (o do `StyledContext`), então
  `comptime padAll(2)` calcula com a folha default e seu registro é descartado:
  `val p = comptime padAll(2);` responde `StyledProperty(className: "s_…", …)` e nenhuma folha guarda a
  regra. (c) Um buraco que nomeia uma chamada que alcança um `use` nunca é conhecido no build (o `Any` da 376 exclui uma
  função que alcança um `use context`): `styled "${padAll(2)}"` é calculado na renderização, como hoje.
- **Recomendação.** (a) — recusar em vez de responder com um provedor que ninguém escreveu (67); (c) é o que o estágio do
  passo 36 do 01-checker dá quando pousar, e concorda com (a).
- **Bloqueia.** Nada — construído como (a) (`block_eval.useReached`); a caixa da chamada `Any` do passo 8 o lê.

### 02-std-and-packaging

#### 97-s16-a · Onde ficam as tabelas geradas do `unicode`
- **Proposta (fable, 2026-10-12; estreitada em 2026-10-18; aguardando o mantenedor):** **Resolvido: o 97 s16 pousou como (a), o irmão plano privado `libs/std/src/unicode_tables.bp` (`status.md` `[x] 97 s16`). Falta confirmar: o irmão fica como pousado até o 144 B-75; depois, sob a 592 (1), (8), o arquivo é `libs/std/src/internal/unicode_tables.bp`** — quando o modelo de módulos pousar (B-69: um arquivo é um módulo nomeado por seu caminho, `mod` vai embora; `src/internal/` é privado a seu pacote, 592 (8)) as tabelas geradas vão para `src/internal/`, `unicode.bp` escreve `import {internal.unicode_tables as tables};`, e o residual 11 fecha estruturalmente — um import do `internal/` do std a partir de outro pacote é recusado, localizado (67: estrutural, sem lista). Viável: a resolução de `mod` do `resolver.zig` e `collectStdModules` do `build.zig` hoje; a caixa de `internal/` do B-69 e a mudança do std no B-75 (`collectStdModules` percorre a árvore em vez de ler linhas `mod`; o gerador `libs/std/tools/unicode-gen` escreve o novo caminho). Mudanças: nenhuma agora; um defeito a registrar até o B-69: `import {unicode_tables} from "std"` compila (`resolver.zig` checa visibilidade só dentro do pacote que importa).
- **Não viável:** a antiga (b) — um módulo de arquivo declarando filhos na pasta do seu próprio nome (`mod tables;` em `unicode.bp`, ou um `unicode/mod.bp`) — se foi com a 592 (1): sem `mod`, sem filho de pasta a declarar; um arquivo sob `src/` é um módulo nomeado por seu caminho.
- **Medido.** O `02/97` passo 16 nomeava `libs/std/src/unicode/tables.bp`. Pousado (antes da 592, com `mod` então em vigor): um irmão plano `libs/std/src/unicode_tables.bp`, uma linha privada `mod unicode_tables;` em `root.bp`, `import {unicode_tables as tables};` em `unicode.bp`. O registro não respeita a privacidade do `mod`: o `import {unicode_tables} from "std"` de um consumidor resolve (resíduo 11 da 97 do compilador). Sob a 592 a linha `mod` vai embora com o `root.bp` (B-75) e a privacidade é a da pasta.
- **Opções.** (a) ★ Como pousado, depois `src/internal/` com o B-75:
  ```bp
  // today — libs/std/src/unicode.bp
  import {unicode_tables as tables};
  // after B-75 — libs/std/src/unicode.bp
  import {internal.unicode_tables as tables};   // libs/std/src/internal/unicode_tables.bp, private to std (592 (8))
  ```
- **Recomendação.** (a): nenhuma mudança no compilador; a mudança é um arquivo gerado e o caminho de saída do gerador no B-75, e o resíduo 11 fecha com `internal/`.
- **Bloqueia.** Nada (a mudança do std no B-75 lê a resposta).

#### nat-d9 · Os nomes do LINQ no erika ao lado dos do std (98)
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **(a), lida com a 312: a gramática é a única grafia pública do `query` sobre um array, os métodos do std a outra; o `Query<T>` fluente com nomes do LINQ vira o alvo privado de lowering do `query`** — `` query @`select name from xs where active order by name` `` (312: uma gramática, dois alvos; 577: um template é chamado com seu texto cru) e `xs.filter(…)`, `map`, `flatMap`, `unique` do std são os dois jeitos de computar sobre um array; os 35 métodos públicos de `Query<T>` (`where`, `select`, `selectMany`, `orderByDescending`, `toList`, …) saem da API pública, mantidos privados como aquilo em que o template constrói; o `query` não acrescenta operador fluente ao lado dos do std (o contexto da 137 já diz isso). Um só jeito de escrever cada coisa: hoje `xs.filter(p)`, `query.of(xs).where(p)` (então `erika.of`) e `` query @`select * from xs where …` `` são três grafias de uma leitura, duas delas nomes do LINQ para métodos do std (170: o std toma o nome natural, a cópia de uma biblioteca vai embora). Viável hoje, só `query`: o módulo `Query<T>` de `repository/query` (então `erika.bp`; seus métodos viram `fn`s privadas, o lowering do pipeline do template continua a chamá-las), `modules/query-test` e `examples/query-linq` reescritos para a gramática. Mudanças: um passo da 145 (uma renomeação e um passe de visibilidade, sem mudança no compilador); (b) e (c) mantêm dois modelos públicos de uma coisa contra a leitura caso a caso da 283.
- **Medido.** `98-packaging-tail/README.md:47-51`; o módulo `Query<T>` (então `erika.bp`): `where`, `select`, `selectMany`, `orderByDescending`, `toList`; o `query` é ansioso — todo operador materializa um novo array; o std tem `filter`, `map`, `flatMap`, `unique` (217). O erika é o repositório `query` (frente 145; 165, decisão 548), seu template escrito `` query @`…` `` (577); a pergunta se mantém para os nomes públicos do LINQ em `Query<T>`.
- **Opções.** (a) Nomes do std (`filter`, `map`), o `query` acrescentando só o que o std não tem (`groupBy`, os agregados). (b) Nomes do LINQ — a identidade do `query` é o LINQ. (c) Como está.
- **Recomendação.** nenhuma desta revisão: o propósito do `query` decide; (b) é uma leitura justa.
- **Bloqueia.** 145 (query).

### 03-bundled-libs

#### ctr-p · Confirmação `std-a` contra a confirmação `03r-e`
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **Confirmar `std-a`; `03r-e` caduca, e os leitores próprios do rakun vão embora com ela** — um componente de query ou um pedaço de cookie cujo escape é malformado ou decodifica para um caractere de controle é recusado: `querystring.parse` / `parseForm` respondem `Error` (std, já é assim), `http.cookie.parse` / `get` respondem o pedaço como ausente enquanto o pedaço recusado ainda reivindica seu nome (196, 181); nada é mantido "como escrito". Recusar antes de aceitar (67), um leitor por header (196): o `queryDict` do rakun-app já lê queries por `querystring.parse` com `try`, então a metade de query da `03r-e` está morta; sua metade de cookie vive só nos cinco leitores do rakun (`request_context.bp` `decodeComponent`, `csrf.bp` `cookieValue`, `session_cookie.bp` `cookieFromHeader`, `i18n.bp` `cookieFrom`, `exchanges.bp` `sessionIdOf`), que a 196 apaga. Viável: `libs/std/src/querystring.bp` e `repository/http/src/cookie.bp` existem e recusam como dito; o rakun ainda não declara dependência de `http` — a adoção é o passo "consumir http" da 150 (rakun 04 passo 5). Mudanças: a linha `03r-e` da Parte 3 é revertida por esta confirmação; duas linhas 150 a registrar: `cookieFromHeader` pega a última duplicata contra 181 / 348 (a primeira vence), e os cinco leitores discordam sobre um mesmo header.
- **Regras.** `std-a`: `querystring.parse` / `parseForm` "recusam … um escape que decodifica para um caractere de controle", e o `splitQuery` do rakun passa a usá-los. `03r-e`: um componente de cookie ou de query que decodificaria para um caractere de controle "fica exatamente como escrito". A 196 move os leitores de cookie do rakun para o `http`.
- **Recomendação.** Confirmar `std-a`; `03r-e` caduca quando o rakun lê queries via `querystring` e cookies via `http`.
- **Bloqueia.** Os leitores da rakun 04; a varredura de consumidores da 104.

#### 396-a · onze-content: "um nó renderizado por um componente da própria página onde a página pede"
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **(a), no módulo `content/` do rakun-ssr (então onze-content), tipada pela árvore da 504** — `toElementWith(doc: MdDoc, render: fn(node: MdNode, kids: Node) -> ?Node) -> Element` ao lado de `toElement`: a função da página vê cada nó com seus filhos já renderizados e responde o nó a colocar — uma tag, um valor de componente (`<MeuTitulo nivel={depth} id={id}>{kids}</MeuTitulo>` é o lambda não executado que o renderizador executa, 504) ou `null` para o elemento default; `Item`, `Row` e `Cell` também são nós, oferecidos por seus pais, e os parágrafos de uma lista compacta mantêm sua renderização `tight` quando o hook responde `null`. Uma função, um `case` tipado sobre os tipos de `MdNode` (281: o tipo é a variante, nunca uma string), nada por tipo a manter em dia com a árvore (o record de 21 campos de (b)); (c) continua disponível mas reproduz a contabilidade do mapeamento default em toda página. Viável hoje: `rakun-ssr/src/content/element.bp` (então `onze/modules/onze-content/src/element.bp`; `toElement`, `blockElement`, `inlineElement`, `itemElement`, `tableElement`, `rowElement` passam o hook adiante; o `MdNode` de `markdown/src/markdown.bp` é público); o `Node` do rakun-bpp (então do jhonstart) é a união que um buraco aceita (223, 191) e um valor de componente nela é o da 504. Mudanças: a caixa aberta do 158 s1 (era a segunda caixa do passo 3 da 142); o "`toElement` do markdown" da entrada é do rakun-ssr (396 (3): o markdown não nomeia framework).
- **Medido.** O passo 3 da 142 construiu `element.toElement(doc: MdDoc) -> Element` (todo `MdNode` para um elemento fixo, como o antigo `toElement`); a 396 (3) e a caixa aberta do 158 s1 dizem que uma página pode renderizar um nó com um componente seu, e não fixam forma. Componentes são funções de um record de props (192/193, 593), `Element`s são valores. O onze-content é um módulo do pacote `rakun-ssr` e o `Node` do jhonstart é do rakun-bpp (165 s2); `Array<Element>` se escreve `Element[]` (641).
- **Opções.** (a) `toElementWith(doc, render: fn(node: MdNode, kids: Element[]) -> ?Element)` — uma função, `null` mantém o elemento default, a página casa os kinds de nó que quer (`Heading`, `Link`, `CodeBlock`, …). (b) Um record de funções opcionais por kind, `Components(heading: ?fn(depth, id, kids) -> Element, link: ?fn(href, title, kids) -> Element, …)`, um campo por kind de nó. (c) Percorrer o `MdDoc` na página e chamar `toElement` para os nós que ela não renderiza (sem hook; a árvore é pública).
  Exemplo de (a):
  ```bp
  val page = toElementWith(doc, { node, kids -> case node { Heading(depth, id, _) -> <MeuTitulo nivel={depth} id={id}>{kids}</MeuTitulo>, _ -> null } });
  ```
  Exemplo de (b):
  ```bp
  val page = toElementWith(doc, Components(heading: { depth, id, kids -> <MeuTitulo nivel={depth} id={id}>{kids}</MeuTitulo> }));
  ```
- **Recomendação.** (a): uma leitura, nenhum campo por kind para manter em compasso com a árvore; (c) não precisa de código e está disponível hoje.
- **Bloqueia.** A caixa aberta do 158 s1 (só o hook; o mapeamento default está construído).

#### 07-g · Renderização de release OTP
- **Proposta (fable, 2026-10-12; estreitada em 2026-10-18; aguardando o mantenedor):** **Uma biblioteca de renderizadores puros (`.rel`, `vm.args`, `sys.config`, o boot script, o Dockerfile e a unit do systemd), escrita em botopink para todo alvo, importada por `rakun-cli` e pelo módulo de release do rakun-ssr (então `onze-release`); cada um mantém só o que é seu (os caminhos de actuator e o env de cookie do rakun, a execução de processo `assembleRelease` do ssr). Falta: onde ela vive — um repositório `botopink/release` (a), ou um pacote do único workspace `rakun` (b)** — desde a 165 (mono-a, 548) os dois consumidores são pacotes do `rakun`, então o teste "duas ou mais bibliotecas" da 115 e o argumento da 326 por um repositório novo não se seguem mais por si: os dois consumidores são um só repositório, e um pacote `release` ao lado deles (dependendo de nada do rakun) é o jeito próprio do workspace de compartilhar código; (c) mantém dois renderizadores cujos bytes já diferem (as versões de `kernel` / `stdlib` do `.rel`, as flags do `vm.args`), duas respostas para um release. Viável: `rakun/modules/rakun-cli/src/release/release.bp` (`renderRel`, `renderVmArgs`, `bootScript`, `renderDockerfile`, `renderSystemdUnit` são texto puro; `renderSysConfig` chama o host Erlang `rkRelTerm` e precisa do escritor de termos `.bp` que a primeira caixa do s1 da 107 pede) e o `otp.bp` do rakun-ssr (então `onze/modules/onze-release/src/otp.bp`); sob (a) o `.gitmodules` da meta, o § Layout e a checagem 4 do CI carregam o repositório como carregam `json` / `yaml`; sob (b) nada da meta muda. Mudanças: a 107 abre como escrita (seu s1 reproduz as duas linhas byte a byte a partir de um renderizador), sua casa lendo a resposta.
- **Não viável (fable, 2026-10-12):** a antiga (b), um recurso do CLI `botopink` (02) — não serve ao release do ssr, que não tem alvo erlang.
- **Medido.** `rakun-cli/src/release/release.bp` (então `rakun-release`, 187) e `onze-release/src/otp.bp` renderizam o mesmo `.rel` / `vm.args` / `sys.config` / script de boot / Dockerfile; o ssr não pode reutilizar o do rakun-cli (rakun-cli só erlang, o ssr também commonJS). Os dois estão no workspace `rakun` (tabela da 165: `rakun-cli` um pacote, `onze-release` dobrado em `rakun-ssr`).
- **Opções.** (a) Um repositório `botopink/release` de renderizadores puros (326), dependência dos dois. (b) Um pacote `release` do workspace `rakun`, dependendo de nada do rakun, importado pelos dois. (c) Deixar os dois.
- **Recomendação.** (a) ou (b) — um renderizador; entre elas nenhuma desta revisão: se uma biblioteca compartilhada dentro de um workspace é um repositório é leitura da 326, do mantenedor.
- **Bloqueia.** `107-release` (uma frente condicional: respondê-la ou adiar a 107).

### Escolhas de implementação das trilhas 00–03

Cada uma implementada com sua opção recomendada; o mantenedor confirma ou reverte (uma reversão é uma
mudança local no lugar nomeado). O texto completo da 1.0.10 de cada uma estava sob o mesmo id na página de pendências da 1.0.10-beta, dobrado nestes arquivos em
2026-10-18 (decisão 748); esta tabela é o registro.

#### 01-compiler (28)

| Id | Escolha implementada | Onde |
|---|---|---|
| 01c-a | O átomo de um módulo comptime é `bp@comptime@<owner path>__tpl__<decl>__<hash>` | comptime |
| 01c-b | Uma folha de seção aceita a forma abreviada de ponto inicial onde o tipo da posição é essa seção; sem expectativa, é recusada nomeando sua seção | checker |
| ck2-b | Um membro de seção pode dividir nome com uma variante de nível superior do mesmo enum (o caminho e o tipo da posição os distinguem); uma variante declarada duas vezes num nível é `enum-variant-duplicate` | `modules/enum_section_leaf_beside_variant` |
| ck2-d | Um rótulo numa chamada de um valor de função é `label-on-function-value` | `reject/label_on_function_value` |
| ck2-e | Um decorator do std é alcançado pelo seu handle de módulo (`#[<handle>.<fn>]`); um import folha de um é `std-decorator-leaf-import`; `#[<handle>.<not a decorator>]` é `unknown-annotation`; o handle ainda é necessário depois da 216 (o texto `addType` / `addMember` de `mocks.mock` nomeia `mocks.invoke`, `testing/mocks.bp:212-220`), enquanto 282/289 já importam como folha decorators de outras bibliotecas | checker |
| rc3-b | `unknown` é a grafia do vocabulário do host onde havia `any` (testado com `is` antes do uso) | `run/host_unknown_parameter` |
| rc3-c | Atribuir a um `var` estreitado checa contra seu tipo declarado e encerra o estreitamento | `reject/narrow_ends_at_assignment` |
| 0405-b | O `__bp_show` do commonJS imprime `undefined` como `null` | prelúdio do commonJS |
| onze F7 | Inteiro `/` inteiro trunca em direção a zero e é um inteiro em todo alvo (`7.0 / 2.0` continua `3.5`); `docs.md:961-963` já o declara | `run/integer_division_truncates` |
| lem-a | Um método de host é um método real de seu tipo cujo corpo é o binding, nunca inlinado no ponto de chamada | `codegen/hostMethods.zig` |
| lem-b | `inline: true` (grafia da 305; o código ainda escreve `inline = true` até o 01-checker passo 27) no `External.Erlang` / `Beam` de um método de tipo é aceito, não muda nada (recusá-lo cabe ao 01-checker acrescentar; recomendado: recusar) | `run/external_method_local` |
| lem-c | Um método de host sem binding para o alvo é recusado onde é chamado (`MissingExternal` nomeando `Type.method`); o wasm recusa todo método de host; um receptor sem tipo falha em tempo de execução (`ctr-o`) | `hostMethods.missingAt` |
| lem-d | Um nome por operação em todo tipo (`Listener.port/accept/close`, `Socket.recv/send/close/peer`, `TlsListener.port/accept`, `TlsSocket.recv/send/close`, `Regex.matches`); construtores continuam funções de módulo | `io.net` · `regex` |
| lem-e | Helpers privados que recebem um tipo continuam livres (`tlsEchoOnce`, `rkvPush`, `putMessageSource`, `messageSourceOr`) | std · `validation` |
| lem-f | O commonJS adota um record construído pelo host em sua classe (`__bp_adopt`) diretamente e por `?T`, arrays e o lado ok de um `@Result`, não por `@Task` | `run/external_method_on_host_record` |
| cep-a | Um caminho de seção (`.Pad.All.8`) numa função deste módulo declarada depois do `comptime` que a alcança ainda não tem reescrita (o corpo é inferido depois), então (a) o `comptime` é recusado nomeando o caminho, seu `line:col` e a função — "declare `later` before the `comptime` in this module" — como o passo 8 da 14 recusa uma chamada de template ali; (b) inferiria tal função antes do `comptime`, dentro do corpo sendo inferido. Recomendado: (a) | `block_eval.unresolvedSectionPath` · `reject/comptime_section_path_declared_after` |
| cep-b | A função de um decorator local que escreve um caminho de seção (`fn fallback() -> Tok { return .Pad.All.8; }`) é inferida antes da execução, uma vez, como a 371 infere uma que escreve `same` (`infer.sameLoweredFn`), e carregada reescrita; (b) recusaria o decorator na anotação nomeando o caminho. Recomendado: (a) — não existe remédio para (b) além de mover a função para outro módulo | `infer.sameLoweredFn` · `run/comptime_decorator_section_value` |
| cep-c | O record de um módulo comptime é seu mapa sem tag, então (a) `v is Rule` e um braço que nomeia um record testam suas chaves declaradas — `is_map(V) andalso is_map_key(selector, V) andalso is_map_key(decl, V)` — e um record de outro tipo com essas chaves responde `true`; (b) carregar o tipo no mapa (`#{'__bp_type' => 'Rule', selector => …}`), uma mudança de todo termo comptime que os avaliadores leem e respondem; (c) recusar `is` / um braço de record no runtime de comptime onde dois records carregados dividem suas chaves. Recomendado: (c), o mais estrito; (a) implementado, nenhuma célula tem dois desses records | `codegen/erlang.zig` `untypedRecordTest` · `run/comptime_record_pattern` |
| 388-b | `c.run(scope)` responde `@Task<Rendered<R>>` para todo componente (a marca da 375 não está no tipo), declarado no `Component<R>` de `builtins.d.bp`; o `context` do std declara `pub type Rendered<R>(value: R, scope: RenderScope)` e `pub type RenderScope(frames: unknown)`, sua construção recusada fora do std (`render-scope-construction`) já que o botopink não tem construtor privado | `infer.inferComponentRun` · `context` do std · `run/component_run_root`, `reject/render_scope_construction` |
| 388-c | O "fora de todo corpo um valor roda com `c.run(RenderScope.root())`" da 388 (4) lido como o que `await c` significa ali: um `await` de um valor de componente numa função simples, `main`, um teste ou um lambda o roda com `RenderScope.root()`; (b) o recusaria, nomeando `c.run(RenderScope.root())` — todo teste e `main` que aguarda um componente seria reescrito | `context_lower.zig` · `run/component_run_root` |
| 139-b | A superfície do `bigint` é o `behavior BigInt` de `primitives.bp`, ao lado dos métodos de todo outro primitivo, e não um `type bigint` em `builtins.d.bp` como o README da frente disse primeiro: o parser recusa um método `self` num `type` sem campos (`namespace-type-self`), e um `declare fn` estático ali é uma linha de builtin `@` de `builtins.zig`. `bigint.of(n)` / `bigint.parse(text)` são primitivos de host associados da forma da decisão 262 (a de `String.fromCodepoint`), escritos pelo nome do próprio tipo (o checker renomeia o receptor `BigInt`); `BigInt.of(n)` também tipa, como `String.fromCodepoint` faz. (b) ensinaria ao parser e ao teste de deriva um `type` primitivo com métodos | `primitives.bp` · `infer.inferPrimitiveStaticCall` |
| 388-d | O backend wasm recusa um módulo que o lowering de escopo alcançou, em seu primeiro componente (`the wasm backend does not lower a component yet`), até o lowering da 05: toda célula de componente é um `.wasm.expect` (32 células; `run/decl_hooks_*` entre elas, que rodavam no wasm sob o mapa da 354) | `wat.zig` `refuseScopeLowering` · `language-gaps.md` 354-wasm |
| 388-e | Um corpo que mantém um `try` solto roda os statements depois de seu último `use provide` como um closure interno, cuja resposta (o valor, ou o erro que o `try` devolve cedo) é o resultado; todo outro corpo responde `rendered(v, kids)` em cada `return` | `context_lower.zig` `lowerComponentBody` · `run/component_try_in_body` |
| 389-a | Uma função declarada cujo próprio retorno não é um `@Component` que responde um por seus argumentos de tipo (`first<T>(cards)`) é o "o que o código genérico responde" da 389: uma aresta com `callee: null`, o nó assíncrono, nenhuma marca síncrona na chamada | `infer.noteHookCall` · `run/decl_hooks_dynamic_call` |
| s29-c | As saídas de uma anotação de template nomeiam um buraco por sua expressão como escrita (o placeholder `__bp_hole_q_0` do `code` da parte vira `id` num meta registrado ou fonte de membro); `q.fail` / `q.failAt` / `decl.fail` e um `lookup` de um nome que não está no texto são reportados na anotação (o literal não tem mapa de spans ali); seu `DeclAnnotation.args` é o literal como escrito; `decl.params` lista `self` | `infer.unplaceholderContributions` · `decorator_eval.annotationPlans` · `run/template_annotation` |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 01c-a:** confirmar só como nome e chave de cache: o esquema (`__tpl__`, e `__dec__` para um decorator) vive em `template_eval.zig` `ownerId` e `decorator_eval.zig`, lido por `crossModule.erlDeclAtom` / `decodeAtom`; o módulo comptime ainda é escrito como texto Erlang que `runtime/wat/erl_parse.zig` e `lower.zig` abaixam para wasm (434) — o "comptime" do Onde é esse caminho, nenhum runtime BEAM.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 01c-b:** confirmar (a leitura da 369 e da 382 de um caminho de ponto inicial sob um tipo de seção esperado; não remedido).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — ck2-b:** confirmar (célula `enum_section_leaf_beside_variant`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — ck2-d:** confirmar (célula `label_on_function_value`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — ck2-e:** reverter para uma só regra para todo pacote (386): um decorator do std é importado como o de uma biblioteca é — por folha (`import {testing.mocks.mock} from "std"`, escrito `#[mock]`) ou pelo seu namespace (`#[mocks.mock]`) — e `std-decorator-leaf-import` vai embora; `#[<handle>.<não decorator>]` continua `unknown-annotation`. Duas regras de import para um mesmo tipo de coisa é o que a 386 removeu para as bibliotecas; o texto de `#[mocks.mock]` nomeando `mocks.invoke` é uma mensagem a corrigir, não uma razão. Viável: `infer.zig` `registerStdDecorators`; células `std_decorator_leaf_import` (vira célula de execução), `std_decorator_unknown_through_handle`, `std_decorator_through_namespace`.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — rc3-b:** confirmar (célula `host_unknown_parameter`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — rc3-c:** confirmar a regra; a célula `narrow_ends_at_assignment` agora fixa uma recusa de leitura de opcional (`v is read off an optional ?Node — write ?.v`), não uma atribuição encerrando um estreitamento — uma linha 144: a célula é remedida e reescrita para sua afirmação (458 (2)).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 0405-b:** confirmar (`codegen/js/js_prelude.zig` `__bp_show`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — onze F7:** confirmar (célula `integer_division_truncates`; o texto está em `conformance/docs.md` § operadores agora).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — lem-a:** confirmar (`codegen/hostMethods.zig`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — lem-b:** reverter para a recomendação: `inline: true` no `@External.Erlang` de um método de tipo é recusado na anotação, localizado — uma flag aceita que não muda nada é uma mentira (67); o checker já recusa um `inline` não lido em `Node` / `Wasm` / `Typescript` (`infer.zig` `refuseUnreadInline`) e `hasExternalInline` é lido só pelo dispatch de primitivas, então a recusa é mais um braço ali; o passo 27 do 144 B-02 a toma, a célula `external_method_local` reescrita de `inline = true` para uma célula de recusa.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — lem-c:** confirmar, como a regra única da `ctr-o` (`hostMethods.missingAt`); o braço wasm `binds(.wasm)` fixo em `false` é a linha 144 da `ctr-o`.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — lem-d:** confirmar (`libs/std/src/io/net.bp`; `regex.bp` `Regex.matches`); uma linha 144 de std a pesar: o `regex.matches(pattern, input)` livre ao lado de `Regex.matches` é uma segunda grafia de um mesmo teste.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — lem-e:** confirmar; emendar o Onde: `tlsEchoOnce` é do std (`io/net.bp`), `rkvPush`, `putMessageSource` e `messageSourceOr` são do `validation` (`src/binding.bp`, `src/messages.bp`) desde a 326.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — lem-f:** confirmar (`js_prelude.zig` `__bp_adopt`; célula `external_method_on_host_record`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — cep-a:** confirmar até o 144 B-72, que a remove com a recusa da 14s8-d (uma caixa para as duas; `block_eval.unresolvedSectionPath`, célula `comptime_section_path_declared_after`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — cep-b:** confirmar (`infer.sameLoweredFn`; célula `comptime_decorator_section_value`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — cep-c:** (c), a recomendação, como uma linha 144: no runtime de comptime um record ainda é um mapa sem tag (o módulo comptime é texto Erlang abaixado para wasm; `erlang.zig` `untypedRecordTest`, `is_map_key` servido pela biblioteca de termos do std-wasm) e `v is Rule` testa chaves, então dois records de comptime que compartilham suas chaves respondem `true` um pelo outro — uma resposta silenciosamente errada (67). Proposta: `is` e um braço de record sobre um valor de comptime são recusados, localizados, onde dois records carregados para esse módulo comptime compartilham um mesmo conjunto de chaves, até o comptime carregar o tipo ((b), a resposta completa, sob necessidade medida); a checagem fica onde o módulo é emitido (`erlang.zig` `emitComptimeModule` conhece os records que carrega). Viável hoje; uma célula de recusa ao lado de `comptime_record_pattern`.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 388-b:** confirmar (`infer.inferComponentRun`; `context.bp` do std `RenderScope` / `Rendered`; células `render_scope_construction`, `component_run_root`); sob a resposta da s23-j um componente não marcado responde sua árvore diretamente em run time e `await` sobre ele é no-op (375 (3)) — o tipo `@Task<Rendered<R>>` continua são porque `await` é sempre legal.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 388-c:** confirmar (`context_lower.zig` `bpScopeRoot__`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 139-b:** confirmar (501; `primitives.bp` `behavior BigInt`, `infer.inferPrimitiveStaticCall`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 388-d:** confirmar até o 144 B-25 passo 4 (504: composição por dados em wasm); emendar a contagem: 38 células carregam uma partida `snapshot/targets/wasm/main.snap` "does not lower a component" (a forma `.wasm.expect` saiu com a 457), todas saindo com o B-25 (458: uma partida nunca registra um defeito — essas são a linha 354-wasm do `language-gaps.md`, que o B-25 fecha).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 388-e:** confirmar (`context_lower.zig` `lowerComponentBody`; célula `component_try_in_body`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 389-a:** confirmar (`infer.noteHookCall`; célula `decl_hooks_dynamic_call`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — s29-c:** confirmar (`infer.unplaceholderContributions`, `decorator_eval.annotationPlans`; célula `template_annotation`); o placeholder `__bp_hole_q_0` é reescrito pelo passo que pousa a 14s8-a (e) (s29-a).

##### 24-c · `iter for` / `iter while` são um `loop` com prefixo (*implementado como (a)*)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), como construído** — açúcar sobre o `loop` com prefixo, o rótulo nomeando o `for` escrito (`LoopExprOf.prefixedKeyword`, `yield-label-not-generator`; células `iter_loop_and_for`, `yield_label_loop`): a equivalência que a 125 escreve, nenhum nó novo de backend (quatro lowerings a manter de acordo seriam o custo de (b) por nada). Viável, construído; sem mudança.
- **Medido.** O README da frente pediu um novo nó `GenLoop { kind, loop }`; mas cada um dos quatro backends já baixa uma forma de laço anotado (o `loop` da 22-loops), e a própria decisão 125 diz que `iter for (xs) { … }` significa `iter loop { for (xs) { … }; break; }`. O parser o lê assim e guarda a palavra-chave escrita em `LoopExpr.prefixedKeyword`, para o formatador devolvê-la. O rótulo fica onde a decisão 105 o escreve, depois da palavra do laço.
  Hoje:
  ```bp
  iter for (xs) { x -> yield x * 2; }      // read as: iter loop { for (xs) { x -> yield x * 2; }; break; }
  iter loop :l { yield :l 1; }             // the label names the generator
  iter for :l (xs) { x -> break :l; }      // the label names the written `for`
  iter for :l (xs) { x -> yield :l x; }    // error[yield-label-not-generator]
  ```
- **Opções.** (a) ★ Açúcar sintático sobre o `loop` com prefixo; o rótulo de `iter for :l` nomeia o `for` (então `break :l` / `continue :l` mantêm seu significado de sempre).
  ```bp
  iter for :l (xs) { x -> if (x < 0) { continue :l; }; yield x; }   // continue of the `for`
  ```
  (b) Um novo nó `GenLoop`, com um lowering próprio em cada um dos quatro backends — o mesmo fonte, mais quatro caminhos para manter em acordo.
  ```bp
  iter for (xs) { x -> yield x * 2; }      // becomes GenLoop { kind: For, loop: … } down to the backend
  ```
  (c) Como (a), mas o rótulo de um `for` com prefixo nomeia também o gerador — o parser só move o rótulo para o nó de fora.
  ```bp
  iter for :l (xs) { x -> yield :l x; }    // compiles: `:l` is the generator's scope
  ```
- **Recomendação.** (a). É a equivalência que a decisão 125 já escreve, sem nenhum backend novo.
- **Bloqueia.** Nada (as confirmações do passo 2 da `01-compiler/24`).

##### 23-b · As quatro funções do `base64` aposentadas, não aliasadas (*implementado como (a)*)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), como construído** — as quatro aposentadas; `encoding.base64Decode` / `base64UrlDecode` respondem `@Result` (`libs/std/src/encoding.bp`, `base64.bp` removido): nenhum alias escondendo uma recusa (67). Viável, construído; sem mudança.
- **Medido.** `base64.decode` respondia uma `string`; seu substituto `encoding.base64Decode` responde `@Result<string, string>` porque a frente 01 valida a entrada antes de o `Buffer.from` truncá-la (idem `decodeUrlSafe` → `base64UrlDecode`). Nenhuma biblioteca importava `base64`. O `base64.bp` foi apagado e seus quatro testes reescritos com os nomes do `encoding` (o std mantém 417 testes). A decisão 106 e `01-std/modules.md` já nomeiam os substitutos.
  Hoje:
  ```bp
  val s = try encoding.base64Decode(text);     // @Result<string, string>: validates before decoding
  base64.decode(text)                          // no longer exists
  ```
- **Opções.** (a) ★ Aposentar as quatro (`encode` / `decode` / `encodeUrlSafe` / `decodeUrlSafe`).
  ```bp
  val raw = try encoding.base64UrlDecode(token);
  ```
  (b) Manter as quatro no `encoding` como aliases que respondem `string` (escondem a recusa).
  ```bp
  val s = encoding.decode("not base64!");   // answers a truncated string, no error
  ```
- **Recomendação.** (a). Duas grafias de um mesmo codec, uma delas escondendo a recusa, é o que a frente 01 removeu.
- **Bloqueia.** Nada (as confirmações do passo 2 da `01-compiler/23`).

#### 02-std-and-packaging (10)

| Id | Escolha implementada | Onde |
|---|---|---|
| 01std-a | Uma biblioteca embutida carregada pelo CLI e pelo LSP (`appendBundled`), não por `expandStdImports`; o compiler-core não nomeia nenhum pacote além de `std` | `build.zig` `bundled_packages` |
| 01std-c | O padrão vazio de `routing.pattern` casa só com `/`; o rakun-web mantém "vazio roda em todo lugar" em seu ponto de chamada (`matcherAdmits`) | `routing` |
| 01std-e | `actions.readEnvelope` recusa um `redirect` que discorda de `n` | `actions` |
| std-a | `querystring.parse` / `parseForm` respondem `@Result`, recusam um escape malformado, não-UTF-8 e um caractere de controle cru ou decodificado; `stringify` recusa um caractere de controle; `parse` é RFC 3986 (`+` permanece), `parseForm` o sabor de formulário (`ctr-p`) | `libs/std/src/querystring.bp` |
| std-b | `fs.exists` segue um link simbólico (link pendente é `false`) | `io/fs.bp` |
| 95-a | A frente 95 realocou `jhonstart-link` e `rakun-app` como movimentos sem comportamento | jhonstart · rakun |
| 95-b | `rakun-app` declara seu próprio `"targets": ["erlang"]`, como todos os 36 manifestos do rakun fazem (opção (b); o "herda o workspace" da 1.0.10 não é o que o código faz) | manifesto do `rakun-app` |
| 95-c | `erika-test` existe | erika |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 01std-a:** confirmar a regra (o compiler-core não nomeia pacote além de `std`: `comptime.zig` `bundledPackage`); emendar a linha: o conjunto embutido é só `std` desde a 326 (`build.zig` `bundled_packages`), e `appendBundled` não existe mais (sobrevive só em `compiler-cli/src/cli/AGENTS.md` e `language-server/AGENTS.md`, duas linhas defasadas para o 144).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 01std-c:** confirmar (`routing/src/pattern.bp`; `rakun-web/src/middleware.bp` `matcherAdmits`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 01std-e:** confirmar (`actions/src/envelope.bp` `readEnvelope`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — std-a:** confirmar (`libs/std/src/querystring.bp`); sua contraparte de cookie é a da `ctr-p`.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — std-b:** confirmar (`libs/std/src/io/fs.bp` `exists`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 95-a:** confirmar (os dois membros existem).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 95-b:** reverter sob a 512 (3): `targets` é herdado do workspace e um membro o escreve só para estreitar; as 31 listas `["erlang"]` idênticas do rakun (o "36" está defasado) vão embora na varredura de manifestos da 150, o manifesto do workspace mantendo a única declaração — um lugar para um fato.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 95-c:** confirmar (`erika/modules/erika-test`).

##### 24-g · A forma do `std/async` com uma Task que nunca falha (*implementado como (a)*)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), como construído** — `allOf` / `all` / `race` sobre tasks iniciadas, `runAll` / `raceOf` / `timeout` sobre thunks, `failed(message)`; cada forma tem um nome (67), e o guia e a suíte da 24 já o escrevem; a 432 depois fez um `@Task<@Result<T, E>>` rejeitar, o que não muda nome algum aqui. Viável, construído: `libs/std/src/async.bp` (o módulo desde então ganhou `Gate`, `delay`, `RetryPolicy`, `retry`). Mudanças: nenhuma; a nota dos `beam_memory_*` (uma task erlang roda eagerly) é o defeito da lg2-b, não desta escolha.
- **Medido.** Antes da frente 24, o `std/async` tinha uma superfície de thunks (`allOf`, `settleOf`, `raceOf`, `timeout`) e uma de Tasks já iniciadas (`all`, `allSettled`, `race`), as duas construídas sobre "Task rejeitada = falha". Agora uma Task nunca falha (decisões 120 e 121): o erro vai DENTRO, `@Task<@Result<T, E>>`. O guia escreve `try await async.allOf([fetchUser(1), fetchUser(2)])` — Tasks já iniciadas cujo valor é um `@Result` — e a suíte da frente 24 segue o guia; as células `beam_memory_*`, porém, precisam de thunks não iniciados, porque no erlang uma Task ansiosa já rodou quando o combinador a recebe. A implementação deu à forma do guia o nome `allOf` e aos thunks outros nomes.
  Hoje:
  ```bp
  val users = try await async.allOf([fetchUser(1), fetchUser(2)]);   // started Tasks of @Result: stops at the first Error
  val xs = await async.runAll([{ -> work(1) }, { -> work(2) }]);     // thunks: this is where the concurrency is
  val r = await async.timeout({ -> slow() }, 100);                   // timed out → Error("timeout"), a string
  ```
- **Opções.** (a) ★ Iniciadas: `allOf`, `all`, `race`; não iniciadas: `runAll`, `raceOf`, `timeout`; `failed(message)` responde `Error(message)`; `allSettled`, `settleOf`, `unwrapAll` e `attempt` foram removidos (não há rejeição para "settle"). Um crash dentro de uma task é relançado.
  ```bp
  val users = try await async.allOf([fetchUser(1), fetchUser(2)]);
  async.allSettled([…])          // no longer exists
  ```
  (b) `allOf` sobre thunks, como o README da `01-std/02` o escreveu — o exemplo do guia é reescrito com thunks.
  ```bp
  val users = try await async.allOf([{ -> fetchUser(1) }, { -> fetchUser(2) }]);
  ```
  (c) Um `allOf` sobrecarregado para as duas formas de elemento — exige sobrecarga por tipo, que a linguagem não tem.
  ```bp
  async.allOf([fetchUser(1)])            // started
  async.allOf([{ -> fetchUser(1) }])     // thunks — same name, another signature
  ```
- **Recomendação.** (a). Segue o guia e a suíte da frente 24, e cada forma tem um nome.
- **Bloqueia.** Nada — o README da `01-std/02-std-async-primitives` (1.0.10) já especifica `allOf` sobre Tasks iniciadas (`02/97` passo 5 — o `RetryPolicy` construído sobre o `std/async`, um resíduo — e `01-compiler/24` passo 2).

##### std-c · O namespace de pasta da decisão 110 é uma reescrita do programa lido (*implementado como (a)*)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a) até o B-69, que decide o destino da pasta** — a reescrita fica (`comptime/std_namespace.zig`); sob a B-55-a (e) (1) um módulo é nomeado por seu caminho e nada diz que uma pasta é um valor, então o B-69 declara uma regra para `import {io} from "std"`: proposta, a forma folha `import {io.fs} from "std"` é o único jeito e uma pasta não é importável (uma grafia, e nenhuma reescrita que possa perder um membro — `io.nope.f()` hoje é `unbound variable 'io'`, um diagnóstico que não nomeia nada); o tipo de namespace de (b) não é necessário então. Viável: o B-69 (a nomeação de módulos do resolver) e a remoção de `std_namespace.zig`. Mudanças: uma caixa no B-69; o namespace de pasta da decisão 110 emendado por ela.
- **Medido.** A decisão 110 permite `import {io} from "std"` e depois `io.fs.readText(…)`. A implementação (`comptime/std_namespace.zig`) reescreve o programa já lido para as formas folha que o checker e os quatro backends já baixam: `io.fs.f()` vira o namespace de `io/fs` (o item `io.fs as __bp_ns_io_fs` é acrescentado), e `collections.Dict` vira `Dict`. Só os módulos alcançados são importados. Limites: um membro ausente é `unbound variable 'io'`; um módulo que declara seu próprio `Dict` de nível superior mantém `collections.Dict` sem reescrever (recusado do mesmo jeito); um local com o nome da pasta (`fn f(io: …)`) não é distinguido dela. (A alternativa da 23-a entrou por aqui.)
  Hoje:
  ```bp
  import {io} from "std";
  io.fs.readText(path)       // rewritten to the leaf import `io.fs`; only the modules reached are imported
  io.nope.f()                // unbound variable 'io'
  ```
- **Opções.** (a) ★ A reescrita: um arquivo, nenhum backend tocado.
  ```bp
  import {collections} from "std";
  val d = collections.Dict.empty();   // runs on the four targets
  ```
  (b) Um tipo de namespace no checker e um lowering de `a.b.f()` nos quatro backends, para o diagnóstico nomear a pasta.
  ```bp
  io.nope.f()                // error: std folder `io` has no module `nope`
  ```
- **Recomendação.** (a). (b) só se o diagnóstico que nomeia a pasta for desejado.
- **Bloqueia.** Nada (as confirmações do passo 2 da `01-compiler/23`); uma reversão abre um passo no `01-checker`.

#### Escolhas feitas pelas threads do 00-gate e pela consolidação (5)

| Id | ★ implementado | Onde |
|---|---|---|
| 111-b | o carregador sidecar do beam é emitido só quando o build liga uma função de host (13 snapshots mudaram); o backend erlang segue a mesma regra (`buildBindsErlangHost`) | botopink-lang `codegen/beam_asm.zig` |
| 113-a | um alvo que o `botopink test` não consegue rodar (wasm hoje — ele roda commonJS, erlang e beam) é `NOT RUNNABLE` e falha o `test-libs`, como o item 3 de `fronts.md` § Gate exige | `scripts/test-libs.sh` |
| 113-b | a auditoria de restrições casa a recusa por seu texto (alternativa, recomendada: dar um id à recusa — 07-residuals) | `lib-test-runner` |
| 110-b | o histórico de contagens saiu de `tests/language/AGENTS.md` | `tests/language/AGENTS.md` |
| 112-a | o `TREES` do `format-check` guarda `examples` como uma entrada mais `modules/manifest/tests` | `scripts/format-check.sh` |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 111-b:** confirmar; emendar o nome: o lado erlang é `codegen/crossModule.zig` `bindsErlangHost` (o lado beam `beam_asm.zig` `bindsBeamHost` / `buildBindsBeamHost`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 113-a:** confirmar como construído (`scripts/test-libs.sh` conta `skipped_unsupported` como NOT RUNNABLE e falha; `test_cmd.zig` recusa só `.wasm`); duas linhas defasadas para o 144: a legenda do script ainda diz "(beam, wasm)", e a coluna wasm do `botopink test` é do B-25 / 97 s11.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 113-b:** reverter para a alternativa: a recusa ganha um id (`host-binding-missing`, ao lado do `std-unsupported-on-target` da 334 (3)) e a auditoria casa o id, nunca o texto (`lib-test-runner/src/runner.zig` `HOST_BINDING_MARK`) — uma mensagem reescrita passaria em silêncio pela auditoria (67). A 510 não a toca (a auditoria dispara um build, sem store).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 110-b:** obsoleta: `tests/language/` saiu com a 466 (conformance na árvore); o arquivo não existe.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 112-a:** confirmar como está agora: `TREES=(examples libs/std modules/compiler-cli/tests modules/manifest/tests conformance)` — `examples` uma entrada; emendar a linha.

#### 03-bundled-libs (4)

| Id | Escolha implementada | Onde |
|---|---|---|
| 106-b | `log.consoleSink` escreve uma linha por registro na saída padrão por `@print` em todo alvo (não o `console.error` / `console.warn` do node, não o `logger` do OTP) — o único stream que um programa wasm também escreve; `defaultSink` mantém o logger do host | `repository/log/src/sink.bp` |
| 106-c | `log.fileSink` rotaciona como o `logger_std_h` do OTP faz, escrito uma vez em botopink sobre quatro células: depois que uma escrita deixa o arquivo em `maxBytes` ou mais, o arquivo vira `<path>.0`, cada arquivo morto sobe um, `<path>.<maxFiles - 1>` é apagado, `maxFiles` 0 apaga o arquivo; uma chamada de host que falha lança; o teto de tamanho total do rakun continua do rakun (dobrado em `maxFiles`) | `repository/log/src/logfile.bp` |
| 106-d | Níveis por nome: `Threshold { From(level), Off }`, `Levels(root, names)`, vale o prefixo pontuado mais longo definido; um nome vazio, um segmento vazio e um nome definido duas vezes são recusados (um `Error` quando um sink é construído, um panic quando resolvido); grupos e overrides em tempo de execução são do framework (ele reconstrói os `Levels` e instala um sink de novo) | `repository/log/src/levels.bp` |
| 106-e | `log.captureRuntimeReports()` observa e nunca trata: BEAM um filtro `logger` primário no domínio `otp` que repassa o evento inalterado (o handler do próprio OTP ainda o imprime), node `uncaughtExceptionMonitor` (o node ainda sai; `unhandledRejection` chega como sua origem sob o modo default do node), registros do logger `runtime` com `report.kind` (e a pilha do node sob `error.stack_trace`), wasm um binding no-op | `repository/log/src/reports.bp` |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 106-b:** confirmar (`log/src/sink.bp` `consoleSink`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 106-c:** confirmar a rotação; emendar "uma chamada de host que falha lança": sob 431 / 486 / 495 as quatro células de arquivo (`appendLine`, `fileBytes`, `moveFile`, `removeFile`) carregam `result: true` e `fileSink` / `appendRotating` respondem `Error` do enum de erro próprio do `log`, nunca um raise — a auditoria do 144 B-08 nomeia as células, a 156 toma a mudança do consumidor.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 106-d:** confirmar (`log/src/levels.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 106-e:** confirmar (`log/src/reports.bp`; sua célula wasm já é `fn: captureNothing`, 481).

#### Escolhas feitas pela thread bugs-sweep (4)

| Id | ★ implementado | Onde |
|---|---|---|
| bs-a | Uma fn associada de um tipo é chamada como a fn de um módulo do std é (`planQualifiedCall`): uma chamada curta é preenchida dos defaults declarados, uma rotulada é reordenada, qualquer outra contagem é o erro de aridade. `fn of(x: string, y: string = "d")` — (a) ★ `Bag.of("p")` é `Bag.of("p", "d")`; (b) recusar a chamada curta, `'of' expects 2 argument(s), got 1` (antes, toda contagem exceto a exata caía num fallback que não checava nada e não preenchia nada) | `infer.zig` `associatedCallReturnType` · `run/associated_fn_of_type_default` |
| bs-b | Um tipo sem sinal não aceita literal negado: `val x: u32 = -1;` — (a) ★ recusado no literal, ``the literal `-1` does not fit `u32` (at least 0)``; (b) aceito, e a checagem em tempo de execução da 264 aborta na negação (`-0` é aceito nos dois casos) | `infer.zig` `refuseIntegerOutOfRange` |
| bs-c | Um `erl` que imprimiu o banner de seu break handler (`BREAK: (a)bort …`) é uma execução interrompida mesmo saindo com 0 (SIGINT, depois EOF no stdin para o emulador com status 0): nunca guardado no cache de runtime — o único lugar em que o harness lê a saída, e só para decidir não cachear. (a) ★ o banner a marca como `.interrupted`; (b) iniciar `erl +Bi` (SIGINT ignorado): a execução termina e é genuína, mas uma execução travada então sobrevive ao Ctrl-C até o timeout de 2 minutos | `codegen/runtime.zig` `classifyEnd` |
| bs-d | `scripts/check-docs.sh --lib-root <dir>` substitui as raízes de biblioteca default; o teste do harness nomeia as suas. O gate mantém o default, que faz o hash de todo pacote irmão inteiro — `repository/vscode-extension` carrega um `botopink.json`, então um link simbólico em seu `node_modules` faz toda checagem de docs ficar `never stored` no checkout meta (um custo, nunca um veredito). (a) ★ como está; (b) as raízes default tomam só um pacote com `src` (o manifesto do vscode-extension é `{ "name", "version" }`); (c) o hash da árvore pula `node_modules` | `scripts/check-docs.sh` · `modules/compiler-cli/tests/result_store.sh` |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — bs-a:** confirmar (`infer.zig` `planQualifiedCall` / `associatedCallReturnType`; a célula é `associated_fn_of_type_default`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — bs-b:** confirmar (`infer.zig` `refuseIntegerOutOfRange`; a mensagem agora cita a 319).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — bs-c:** confirmar a classificação (`codegen/runtime.zig` `classifyEnd`); o cache que ela guarda — o cache de saída de runtime chaveado por conteúdo do harness dos testes de snapshot do compiler-core, que pula uma execução de `erl` / `node` num acerto — é o que a 510 proíbe lida ao pé da letra ("todo teste roda em toda checagem"): proposta, esse cache vai embora (uma linha 144), sujeito ao mantenedor confirmar que a 510 alcança os testes do próprio compiler-core; a bs-c então não tem objeto.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — bs-d:** obsoleta: `check-docs.sh` não aceita `--lib-root` (suas opções são `--doc`, `--list`, `--self-test`; ele checa que as referências `<!-- example: … -->` nomeiam células existentes, 461), e o result store e `result_store.sh` saíram com a 510.

#### Escolhas de outras trilhas de que um passo 00–03 espera

| Id | Escolha implementada | Onde |
|---|---|---|
| 03r-q | O roteamento de locale vive em `rakun-app/src/i18n.bp`; nenhum membro `rakun-i18n` | 22 |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-q:** confirmar (`rakun-app/src/i18n.bp`; nenhum membro `rakun-i18n`).

---

## Parte 2 — O resto

### Prioridade — a forma botopink (`nat-*`)

#### nat-d · Um segundo modelo do que a linguagem tem — caso a caso (decisão 283)
Nenhuma regra geral (283): cada caso abaixo é sua própria pergunta, (a) o da própria linguagem, (b) ambos — o estrangeiro uma camada fina sobre o nativo — ou (c) como está.

#### nat-d6 · `throw "nav:not-found"` ao lado de `noreturn` (53)
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **(a), tipada: `notFound() -> noreturn`, `redirect(url) -> noreturn`, o sinal um valor `NavOutcome`, capturado por tipo, nunca por um prefixo `nav:`** — os dois sinais do rakun-bpp (então do jhonstart) lançam `NavOutcome` (`NotFound`, `Redirect(url)`) pela sua única célula de host (`__jhRaise` carregando o valor — `#[compiler.external(.Erlang("…"), .JavaScript("…"))]`, 606 (4): um `Error` que o guarda em commonJS, `error({jhonstart_nav, Outcome})` em erlang) e respondem `noreturn`, então `throw notFound();`, um `notFound();` solto e `val s: string = if (c) "a" else notFound();` todos checam (lg2-l: o código já tem `noreturn` como tipo bottom); um boundary lê o valor capturado com `case` sobre `NavOutcome` (`renderNotFound` captura só `NotFound`, `renderErrorBoundary` relança qualquer `NavOutcome`, 414 (2)); uma action redireciona pelo seu `Result` — `ActionError` ganha `Redirect(url: string)` (303 emendada; 303 See Other no wire), sem raise. 281 (um fato de código nunca viaja como string), 67 (o boundary casa um tipo, um prefixo mal escrito não escapa), e o teste de string de `isSignalReason` vai embora; (b) mantém a string sob um invólucro; (c) mantém `-> string` para um valor nunca produzido. Viável agora: o `error_boundary.bp` do rakun-bpp (então `jhonstart/modules/jhonstart/src/`; `__jhRaise`, `notFound`, `redirect`, `__jhCapture`), `signal_runtime.mjs` / `jhonstart_signal.erl`, o `navigation.bp` do rakun-app (`rkNavSignal`, `-> i32`), o `ActionError` do `actions`; medido na feat que uma célula de host `declare fn raise(reason) -> noreturn` checa e roda em commonJS e erlang. Mudanças: a linha "navigation signals do not return `noreturn`" do `language-gaps.md` fecha (seu texto está defasado: `throw notFound();` já checa); `31-a` (Parte 3) vira `-> noreturn`; wasm segue a forma wasm das células (B-25); com `attempt` pousado (B-07, 431; 595 (8)) o try de host dos boundaries é o da 431, o `NavOutcome` ainda lido por tipo.
- **Medido.** Um sinal é uma string com prefixo `nav:` lançada pelo host (`contracts.md` § 5b); `notFound()` / `redirect()` do rakun-bpp declaram `-> string`, os do rakun `-> i32` (então `jhonstart/src/error_boundary.bp:180-189`, `rakun-app/src/navigation.bp:47-55`); `isSignal` → `isSignalReason` por prefixo; `boundaries-example.bp:89-91` (um `throw` dentro de `-> Result`, um valor `Error` pela 118, não um raise); `server-action-example.bp:79` `val _gone = redirect(…)`.
- **Regras.** 303: uma action responde `Result<T, ActionError>` e `throw e` ali é `Error(e)`; `ActionError` tem `NotFound` mas nenhum caso de redirect — a resposta deve dizer também como uma action redireciona.
- **Opções.** (a) `fn notFound() -> noreturn`, boundaries casando o tipo `NavOutcome`. (b) O sinal de string mantido sob um wrapper tipado. (c) Como está.
- **Recomendação.** (a). Com lg2-l (lg2-h está fechada pela 656).
- **Bloqueia.** 150 s36 (então `05-jhonstart/26`), 150 s67 (então `07-onze/53`); lg2-l, 31-a.

#### nat-d7 · Anotações de ciclo de vida ao lado de interfaces (rakun 04)
- **Proposta (fable, 2026-10-12; reescrita em 2026-10-18; aguardando o mantenedor):** **(a): `type Cache(…) implement Lifecycle { fn start(self: Self) -> void { … } fn stop(self: Self) -> void { … } }`, `pub behavior Lifecycle { fn start(self: Self) -> void; fn stop(self: Self) -> void; }` declarado pelo core do rakun; `#[component]` registra as duas chamadas; `#[postConstruct]` / `#[preDestroy]` vão embora (318 (8): o rakun fala botopink, nenhum nome do Spring). Aberto dentro de (a): como `#[component]` fica sabendo que o tipo anotado implementa `Lifecycle`** — `Decl` se foi (576 (1)), então a rota que esta entrada propunha, um campo `Decl.implements` que o compilador devia, não tem objeto; o que a 576 (3), (8) dá a um decorator são as leituras `compiler.kind(d)`, `compiler.methods(d)`, `compiler.fields(d)`, `compiler.annotations(d)`, …, nenhuma delas as cláusulas `implement`. Restam dois caminhos: (a1) o handle tipado estruturalmente da 626 (2) — `pub fn component(syntax decl: Lifecycle) -> void` checa o tipo anotado contra os membros do behavior na anotação — que tipa todo componente por `Lifecycle` e recusa um componente sem `start` / `stop`, a menos que o rakun escreva um segundo marcador ou um parâmetro `lifecycle:` para o componente simples (duas grafias, 67); (a2) uma leitura `compiler.*` das cláusulas — `compiler.implements(d) -> unknown[]`, os handles dos behaviors que o tipo nomeia — uma linha 144 ao lado das leituras da 576 (8), `#[component]` mantendo `syntax decl: unknown` e registrando as chamadas quando `Lifecycle` está entre eles. Um behavior é a forma própria da linguagem para um contrato (311 (1), 617 (2)), tipado e checado na declaração (um `stop` ausente é erro do checker, não um marcador que ninguém leu). Até a resposta o rakun mantém os marcadores de (c) (`rakun/src/lifecycle.bp`, `rkRegisterLifecycle` de `context.bp` sobre `compiler.methods(decl)`) como sua forma mais próxima, marcada como lacuna de linguagem.
- **Não viável:** a antiga "(a) sobre um `Decl.implements` que o compilador deve" — `Decl` e `Decl<T>` são removidos inteiros (576 (1)); uma declaração é lida só por `compiler.*` (576 (3)).
- **Medido.** `context-lifecycle-example.bp:66,72`: `#[postConstruct]`, `#[preDestroy]`. A 576 (8) lista o que um handle responde — `hooks`, `fields`, `methods`, `params`, `returnType`, `owner`, `annotations`, `variants` — e nenhum `implements`; a 626 (2) checa um handle `syntax decl: B` contra os membros de `B` estruturalmente, nenhuma cláusula `implement` pedida ao tipo do usuário.
- **Opções.** (a) `implement Lifecycle { fn start(self: Self) -> void; fn stop(self: Self) -> void; }`, lido por `#[component]` como (a1) o handle tipado ou (a2) uma leitura `compiler.implements(d)`. (b) Ambos. (c) Como está.
- **Recomendação.** (a); entre (a1) e (a2) nenhuma desta revisão — (a1) não pede nada ao compilador mas tipa todo componente por um behavior, (a2) é uma leitura a mais em `compiler`.
- **Bloqueia.** rakun 04 (150 s1); sob (a2) uma linha 144.

#### nat-d8 · Um nome de hook `use…` sob `use` (53)
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **(a): `use actionState(createPost, initial)`; um hook cujo nome começa com `use` é recusado na sua declaração** — um hook é uma função que responde `Component<R>` e é lido com `use h(…)` (354 (1)), então `use useX(…)` escreve o verbo duas vezes; o checker recusa uma declaração que responde `Component` nomeada `use<Maiúscula…>`, localizada (`hook-name-use-prefix: a hook is read with use — name it actionState`). Uma grafia (67), e a 281 já fixa o argumento (a action por referência). Viável: o módulo `forms/` do rakun-bpp (então jhonstart-forms) tem `actionState(actionId: string, initial)` (`form.bp`; seu primeiro parâmetro vira a referência da action sob a 281 — um passo da seção do jhonstart da 150, 150 s36 … s47); a recusa vai junto com os diagnósticos de `use` em `comptime/diagnostics.zig` e os braços `.useHook` de `infer.zig` (hoje `use useThing(2)` passa no `check`), uma célula de recusa. Mudanças: o 150 s67 passo 7 reescreve `use useActionState(…)` para `use actionState(…)`; uma linha 144 para a recusa.
- **Medido.** `new-post-form-example.bp:118`: `use useActionState("createPost", actionState(""))` — o rakun-bpp não exporta nenhum `useActionState`; seu hook de forms é `actionState(actionId: string, initial)` (`form.bp:182`).
- **Regras.** A 281 já resolve o argumento: a action é passada como referência (`createPost`), nunca como string — no exemplo e na assinatura de `actionState` (o 150 s67 passo 7 a escreve assim). Só o nome do hook está aberto.
- **Opções.** (a) `use actionState(createPost, initial)`; um hook chamado `use…` recusado. (b) Os dois nomes. (c) Como está.
- **Recomendação.** (a).
- **Bloqueia.** Os exemplos do 150 s67 passo 7 (então `07-onze/53`).

#### nat-f · Configuração em JSON — caso a caso (decisão 284)
`botopink.json` o mais limpo possível, configuração permitida onde faz sentido (284); `"bpp"` fica, um objeto desde a 338 (`{"default": "<package>", "style": …}`). Cada caso abaixo é sua própria pergunta.

#### nat-f2 · `trailingSlash`, `redirects`, `markdown`, `allowedRedirects` do `onze.json` (124, 08-h)
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **(a), como um só record tipado** — o arquivo de configuração do ssr mantém suas chaves (284; a 271 fixa `trailingSlash`, `redirects`, `markdown`, `islands`, `site`), lidas no build para um record `OnzeConfig` cujos campos são as opções tipadas que o código do rakun-ssr já tem (`UrlRules`, `MarkdownOptions`, `IslandProps`, `allowedRedirects: string[]`): uma chave desconhecida, um tipo errado, uma variante desconhecida ou um valor ruim é um erro nomeando o arquivo, o caminho da chave e o tipo esperado (as recusas da 49-c, tipadas), o precedente da 299 no leitor próprio do ssr. Configuração é permitida ali (284) e o build a checa como checaria código; (b) moveria o que 271 / 272 / 224 puseram no arquivo e deixaria duas casas para um fato. Viável hoje: o `config.bp` do rakun-ssr (então `onze/modules/onze/src/config.bp`) `loadConfig` / `applyKey` / `configKeys` (escrito à mão, tipado; `allowedRedirects` existe, as outras quatro são acrescentadas ali); o binder `#[config]` da 299 não está construído no rakun, então nada é copiado; a linha no arquivo fica "sujeita a" o `decode` da biblioteca `json` expor a posição de um caminho — até lá o erro nomeia o caminho da chave. Mudanças: o 150 s66 passo 1 (as quatro chaves) e 150 s60 / s67 leem `OnzeConfig`; `islands` entra em `configKeys` (a 224 a nomeia, o código não a tem). Dúvida: o nome do arquivo — o 165 s2 marcou o codemod `onze.json` → `rakun-ssr.json`, enquanto as caixas do 150 s60 e do s67 ainda escrevem `onze.json`; qual nome o arquivo mantém não é resolvido pelas linhas 575–659 e segue os passos do ssr, não esta pergunta.
- **Não viável (fable, 2026-10-12):** (a) pelo binder `#[config]` da 299 — não está construído no rakun; a proposta usa o leitor tipado próprio do ssr no lugar.
- **Medido.** O arquivo de configuração é lido e validado por `loadConfig` sempre que o CLI resolve o projeto, `onze build` incluído (então `onze-cli/src/resolve.bp:48-50`); uma chave desconhecida é recusada (49-c) sem linha. Só `allowedRedirects` existe (então `onze/src/config.bp:192-193`); `trailingSlash`, `redirects`, `markdown` são as chaves planejadas do 150 s66 (então `124-bpp-cli/README.md:67-69`), que a 08-h já escreve; as quatro repetem opções que o código do ssr tipa (`url_rules`, `MarkdownOptions`, `app(allowedRedirects:)`). Precedente: 299 (record tipado ligado a partir de um arquivo, erros nomeando arquivo, linha e tipo esperado).
- **Opções.** (a) Mantidas no arquivo de configuração, lidas no record tipado no build como a 299 faz, uma chave ou valor errado um erro em sua linha no arquivo. (b) Um record tipado no código do app (`pub val config = OnzeConfig(trailingSlash: .Never, …)`), sem JSON. (c) Como está.
- **Recomendação.** (a) — configuração é permitida ali (284); o build a checa como o código checaria, como a 299 faz para o rakun.
- **Bloqueia.** 150 s66 passo 1 (então 124); 08-h; 150 s59 / s60 (então `07-onze/49`, `50`).

#### nat-f4 · O prefixo `ONZE_PUBLIC_` nas variáveis de ambiente (53, `contracts.md`)
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **(b): a declaração diz — `#[publicEnv] pub val apiUrl = env.read("API_URL");` — e o prefixo `ONZE_PUBLIC_` vai embora** — um valor que o navegador pode ver é declarado uma vez, tipado, marcado onde é lido; o bundler inlina o valor do build de um `val` marcado no bundle do cliente e recusa, localizado, qualquer `env.read` alcançado de um componente `#[client]` que não seja tal `val` (`env-non-public` mantido, sua mensagem nomeando o marcador). Um fato carregado por uma convenção de nomes do ambiente é uma regra de string que o código nunca declara (o espírito da 281; 67: um prefixo esquecido é um erro localizado de qualquer modo, mas o marcador é checado onde o autor o escreveu, não onde o operador nomeou uma variável); a lista de (c) no arquivo de configuração é uma segunda casa para um fato de código. Viável: o módulo de bundler do rakun-ssr (então `onze/modules/onze-bundler/src/refusal.bp` — `env-non-public`, `env-dynamic`, `env-vars`, `env-write` — e `scan.bp`) já acha o `env.read` de um módulo de cliente; `isPublicEnvName` / `publicEnvPrefix` de `config.bp` vão embora; `publicEnv` é um decorator num `val` (356: ele roda e o `val` é achado por `compiler.find`) registrando o meta tipado `PublicEnv(name)` (`compiler.setMeta`, 576 (11)), que o bundler lê do scan (ele escaneia fonte hoje) ou, só no build, por `compiler.find(with: publicEnv)` (581 (3): o catálogo responde handles de declaração e nunca chega ao run time — a antiga leitura `@TypeInfo.all` se foi, 576 (7); uma lista de que o bundler em execução precise é escrita pelo próprio marcador por `compiler.init`). Mudanças: 150 s60 / s67 e `contracts.md` § env; os nomes `ONZE_PUBLIC_*` dos exemplos viram nomes simples sob o marcador. O nome do próprio prefixo depois do 165 s2 (`ONZE_KEY` → `RAKUN_SSR_KEY`; os passos de ssr da 150 ainda escrevem `ONZE_PUBLIC_`) é pergunta só de (a).
- **Medido.** Uma variável chega ao código do cliente só quando seu nome começa com `ONZE_PUBLIC_` (o `NEXT_PUBLIC_` do Next). Um prefixo ausente não é silencioso: o bundler recusa no build o `env.read("X")` de um módulo cliente sem ele, nomeando a variável (`env-non-public`, então `onze-bundler/src/refusal.bp:13-14`; `contracts.md:440-442`). O que resta é um fato de estágio (186) carregado por uma convenção de nome que o ambiente deve seguir (`client-island-example.bp:41`).
- **Opções.** (a) Mantido. (b) A declaração o diz — `#[publicEnv] val apiUrl = env.read("API_URL")`, seu uso de um componente `#[client]` checado no build (186); um marcador próprio, já que `#[clientVisible]` é a anotação de hidratação da 278; o `#[env("…")]` da 299 o precedente num record. (c) Uma lista de variáveis públicas no arquivo de configuração.
- **Recomendação.** (b).
- **Bloqueia.** 150 s60, s67 (então `07-onze/50`, `53`); `contracts.md`.

### 01-compiler — a linguagem

#### lg2-l · Se `noreturn` é um tipo bottom
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **(2), como o código já tem: `noreturn` é o tipo bottom, e um corpo `noreturn` não pode cair pelo fim** — uma chamada `noreturn` cabe em qualquer posição (`val s: string = notFound();`, `throw notFound();`, um ramo de `if`), encerra seu caminho (`stmtsAlwaysExit` / `callNeverReturns` estreitam depois dela), e uma função declarada `-> noreturn` cujo corpo pode completar é recusada na declaração, localizada. Medido na feat: `unify.zig` ("`noreturn` é o tipo bottom de mão única"), as células `builtin_noreturn_any_position` e `try_catch_null_and_noreturn_narrowing` fixam (2) nos quatro alvos; (1) quebraria as duas células sem ganho — uma posição de valor que um `noreturn` preenche nunca é produzida, então nada fica silenciosamente errado, e é o que deixa os sinais serem `-> noreturn` (nat-d6). Viável: construído; a checagem de queda pelo fim é mais um uso de `stmtsAlwaysExit` num corpo `-> noreturn` (`infer.zig`). Mudanças: uma linha 144 para o defeito (`fn bad(c: bool) -> noreturn { if (c) { panic("x"); } }` compila e retorna — `panic` importado de `failure`, 606 (2)); o Medido da entrada e as duas linhas de `noreturn` do `language-gaps.md` estão defasados.
- **Medido.** `fn notFound() -> noreturn { raise("…"); }` encerra o caminho no commonJS e no erlang, mas `throw notFound();` num corpo `Result` e `val s: string = notFound();` dão incompatibilidade → `notFound()` / `redirect()` do rakun-bpp (então do jhonstart) declaram `-> string` (`error_boundary.bp:180-188`); o exemplo da frente 53 escreve `val _gone = redirect(…)` (`server-action-example.bp:79`); o app de blog do ssr chama `notFound();` como statement. `panic(message) -> noreturn` (606 (2); `todo` se foi, `panic("not implemented")` em seu lugar); um branch que termina numa chamada `noreturn` já estreita — pode ser confirmado de fato.
- **Opções.** (1) `noreturn` não unifica com nada: uma chamada a ele é um statement que encerra seu caminho; os sinais viram `-> noreturn` chamados como statements (numa página: `fn() -> View`, `use params<P>()`). (2) `noreturn` é o tipo bottom, cabe em qualquer posição.
- **Recomendação.** (1).
- **Bloqueia.** A linha; os sinais do rakun-bpp (então jhonstart 63, `31-a`); os testes de navegação do rakun.

#### lg2-n · Um thunk coagido para `Node`
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **(1): nenhuma coerção de thunk — um filho adiado é um valor de componente, nunca um `fn() -> Element`** — `Node` aceita um array, um `Element`, uma `string` e um valor de componente (191, 223, 504: a árvore guarda o lambda não executado que `view()` faz); o filho adiado de um boundary é tipado `child: Component<Element>` (os nós da 414), não `fn() -> Component<Element>` como o rakun-bpp (então jhonstart) escreve hoje. Três coerções que o compilador conhece e nada inferido da forma de um lambda (67); sob a 388 um componente já é a forma adiada, então um thunk é uma segunda grafia dela. Viável: `infer.zig` `childrenCoercion` (`Children`, array, `string`, `Renderable`) fica; medido na feat `show({ -> "x" })` é `expected Children, got function`. Mudanças: os campos `child` de `ErrorBoundaryNode` / `NotFoundBoundaryNode` / `suspense.Boundary` do rakun-bpp largam o thunk (a 414-a está fechada pela 653: chamar um componente só faz seu lambda; B-17, 150 s36).
- **Medido.** `show({ -> "x" })` contra `fn show(children: Children)` (`Node` sob a 223) dá incompatibilidade.
- **Opções.** (1) Nenhuma coerção de thunk: um filho adiado é um campo nomeado do boundary. (2) `fn() -> Element` coage para `Node`.
- **Recomendação.** (1): as coerções conhecidas pelo compilador continuam três (array, `Element`, `string`).
- **Bloqueia.** A linha; os boundaries do rakun-bpp (então jhonstart 30).

#### lg2-s · Reflexão do grafo de módulos
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **(1): sem reflexão do grafo de módulos; o bundler do rakun-ssr (então onze-bundler) mantém `importsOf`, um scan que falha alto** — nenhuma leitura `compiler.*` responde os imports de um módulo (576 (3), (8): um handle é de uma declaração, suas leituras `hooks`, `fields`, `methods`, `params`, …), e a antiga (2) se foi duas vezes: não há anotação de nível de módulo (315) e não há `@Decl` nenhum (576 (1)). O bundler lê o que o compilador já resolve quando uma frente precisar — uma saída do CLI `botopink` com o grafo de módulos (o resolver do B-69 nomeia todo módulo por caminho, 592 (1)), nunca uma reflexão de comptime sobre módulos (`compiler.find` responde declarações, não módulos, 581 (3)). Viável: `scan.bp` `importsOf` e `graph.bp` `loadModules` do rakun-ssr (então `onze/modules/onze-bundler/src/`); medido na feat antes da 576, `decl.imports` era `unknown field 'imports' on type 'Decl'`. Mudanças: uma das duas linhas do `status.md` — ver Medido.
- **Não viável (fable, 2026-10-12; 576):** (2) — um campo `imports` num `@Decl` de nível de módulo: nenhuma anotação de nível de módulo (315), e `@Decl` é removido inteiro (576 (1)).
- **Medido.** `decl.imports` era o campo desconhecido de `Decl` do checker, na leitura (antes da 576; hoje `Decl` é um tipo desconhecido); o bundler lê imports com `importsOf`, uma varredura textual. Dúvida: o `status.md:403` lista `ctr-m (= lg2-s)` entre as perguntas fechadas em 9 de outubro, enquanto o `status.md:401` mantém a `lg2-s` aberta na mesma seção — se esta entrada já está fechada pelo que fechou a ctr-m, ou só a contradição estava, não é resolvido pelas linhas 575–659; uma das duas linhas vai embora com a resposta.
- **Opções.** (1) Nenhuma: `importsOf` continua uma varredura textual que falha alto; o grafo de módulos, quando uma frente precisar, é uma saída do CLI `botopink`, não uma reflexão.
- **Recomendação.** (1); seu argumento antigo ("em compasso com `lg2-k`") caiu com a 216.
- **Bloqueia.** A linha; o bundle cliente do rakun-ssr (então onze 68).

### 02-std-and-packaging

### 03-bundled-libs

#### 07-b · "Uma biblioteca, várias cópias divergentes" também justifica um pacote?
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): o "duas ou mais bibliotecas" da 115 continua o único teste** — uma duplicata dentro de uma biblioteca vai para o std quando genérica, senão para o core dessa biblioteca; os cinco leitores de cookie do rakun já são o caso da 196 (`http.cookie`, consumido por rakun e onze-server). Um segundo teste admitiria um pacote para um consumidor contando suas cópias (a exceção da 115 é do mantenedor, declarada caso a caso: 396 (4), 398 (3)). Viável: `repository/http/src/cookie.bp` existe; a adoção pelo rakun é um passo da 150 (nenhum manifesto do rakun depende de `http` ainda). Mudanças: nenhuma.
- **Medido.** O rakun tem quatro leitores de `Cookie:` divergentes dentro de si (`request_context.bp`, `csrf.bp`, `rakun-app/i18n.bp`, `session_cookie.bp`; 196, frente 104). As cópias de cookie e q-value já qualificam pelo teste da 115 (o onze também as consome).
- **Opções.** (a) O "duas ou mais bibliotecas" da 115 continua o único teste. (b) Acrescentar o teste de divergência.
- **Recomendação.** (a): uma duplicata de uma biblioteca só vai para o std ou para o core da biblioteca dona.
- **Bloqueia.** Nada; a regra para o próximo candidato (o `http` da frente 104 existe; o rakun o adota em seu passo 5).

### 04-rakun

#### erk-b · `#[documentQuery]` sob a 313 (*proposta*)
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **(a), com gerador próprio: o `#[documentRepository]` do rakun-data sobre um `behavior` cujos métodos carregam `` #[documentQuery @`…`] ``** — a mesma forma da 313 (um `behavior`, uma anotação por método registrando meta tipado, um gerador produzindo a implementação e o registro por tipo), o filtro um texto de template entregue ao store textualmente como `#[nativeQuery]` entrega SQL (577: um template é chamado com seu texto cru; placeholders `:name` casados por nome com os parâmetros, um erro na anotação quando um fica sem par); não o `#[repository]` de SQL (então do dbcontext, dobrado no rakun-data pelo 165 s3), cujo gerador emite runners de SQL e recusa um método que não conhece (313: "um método sem nenhuma das anotações é um erro"). Uma forma de repositório para todo store, nenhum segundo modelo (283); (b) um alvo de documentos do `query` espera uma necessidade medida; (c) é a forma que a 313 apagou. Viável como decorator de biblioteca (216, 311 (1); 604: um marcador é uma função com um parâmetro `syntax decl`): um novo módulo `rakun-data/src/nosql/` (uma linha `pub mod nosql;` em `root.bp` até o B-75; sob a 592 (1) só o caminho o nomeia) — nada da 09 existe na feat (nenhum `DocumentStore`, nenhum `nosql.url`; `documentQuery` é um comentário em `sql/query.bp`), e a forma de repositório SQL é do rakun-data desde o 165 s3 (`entity/`, `context/`, `repository/`), então o 150 s17 passo 4 abre depois que 150 s48 … s51 (então 143) pousarem a forma a copiar. Mudanças: o README do 150 s17 nomeia `#[documentRepository]`; o "09 passo 4" da entrada é o 150 s17 passo 4.
- **Não viável (fable, 2026-10-12):** (a) pelo `#[repository]` de SQL — seu gerador emite runners de SQL e recusa um método que não conhece (313); (b) — nenhum alvo de documentos do `query` existe.
- **Medido.** 150 s17 passo 4: `` #[documentQuery @`…`] `` segue a forma de `#[query]` — um membro do tipo repositório que responde o template literalmente. A 313 apaga essa forma para SQL: um repositório é um `#[repository] behavior`, seus métodos carregando `` #[query @`…`] `` (então `#[erika "…"]`) ou `#[nativeQuery("…")]`. A gramática do `query` é a do SQL; o filtro de um document store é JSON (`$in`, `$gt`, …).
- **Opções.** (a) A mesma forma: um repositório de documentos é um `#[repository] behavior` cujos métodos carregam `` #[documentQuery @`…`] ``, o texto entregue ao store como `#[nativeQuery]` entrega SQL ao driver (placeholders `:name` casados com os parâmetros, escapados por `bind`). (b) O `query` ganha um alvo de documentos — o mesmo `select … where …` baixado para o filtro do store. (c) Como está: um membro do tipo.
- **Recomendação.** (a) agora — uma forma de repositório para todo store; (b) quando uma necessidade medida pedir.
- **Bloqueia.** 150 s17 passo 4.

#### 03r-ab · Os stores de protocolo binário da frente 09
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **(a), confirmar — só o registro** — o 150 s17 (então 09) entrega `ets:memory`, `mnesia:local` / `mnesia:cluster`, `redis://` e `https://` com a suíte do behavior contra os quatro no gate; `mongodb://`, `bolt://`, `cassandra://`, `couchbase://` são esquemas reconhecidos cuja recusa de boot nomeia o driver (150 s17 passo 5; 160: um double em processo ou uma linha de `deferred.md`, nunca um fallback para ETS). Recusar antes de um substituto silencioso (67); o braço Elasticsearch alcança HTTP por um ponto de extensão do core, nunca por uma aresta `rakun-data → rakun-restclient` (`ctr-w`, 185). Viável: nada da 09 está na feat (`rakun.nosql.url` não existe; o único store escolhido por URL é `rakun.datasource.url` em `rakun-data/src/datasource.bp`, cuja recusa de esquema desconhecido — "whose scheme no arm serves — accepted: …" — e `sql_datasource_test.bp` são o padrão que as células do passo 5 copiam). Mudanças: nenhuma; o 150 s17 segue (a) como escrito.
- **Medido.** O store é selecionado por `rakun.nosql.url`. MongoDB, Neo4j, Cassandra, Couchbase são protocolos de bytes (`bytes`, 346, 641 — então `Bytes`, ainda não construído) que precisam de drivers OTP que um sidecar não consegue carregar; ETS e Mnesia estão na VM; Redis é RESP sobre `gen_tcp`; Elasticsearch é HTTP + JSON. O 150 s17 já está escrito para (a): os antigos passos 4 e 7 são as células de recusa do passo 5 mais uma linha de `deferred.md` cada — só falta o registro.
- **Opções.** (a) O 150 s17 entrega `ets:memory`, `mnesia:local` / `mnesia:cluster`, `redis://`, `https://` com a suíte de behavior contra os quatro no gate; `mongodb://`, `bolt://`, `cassandra://`, `couchbase://` são esquemas reconhecidos cuja recusa no boot nomeia o driver (passo 5). (b) Quatro clientes de protocolo em sidecars Erlang, uma frente cada. (c) Adiar o 150 s17.
- **Recomendação.** (a): nunca um fallback para ETS sob uma URL Mongo; o braço Elasticsearch sem uma aresta `rakun-restclient` (`ctr-w`; o 150 s17 passo 3 ainda passa por ela). A frente já segue (a).
- **Bloqueia.** 150 s17 passo 5 (as células de recusa).

#### 03r-af · Os sete projetos de exemplo não construídos
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): aposentar os sete; os três em disco ganham um `README.md` cada** — `examples/` contém `rakun`, `rakun-container`, `rakun-ssr` (nenhum com README), e o contrato de todo membro é afirmado por seus próprios testes (390 (5): um valor que nada verifica vira um teste comum, não um exemplo). Um exemplo que nunca rodou é uma promessa que o gate não pode cumprir (67); (b) são sete frentes para nenhum leitor medido. Viável: três arquivos; o manifesto do workspace já lista `examples/*`. Mudanças: o passo 3 da 73; a lista da 1.0.10 é um registro fechado.
- **Medido.** `examples/` guarda `rakun`, `rakun-container`, `rakun-ssr` (células de gate); `rest-service`, `secured-api`, `blog-server`, `order-pipeline`, `observed-service`, `realtime-gateway`, `release-kit` nunca começaram; o contrato de cada membro é afirmado por seus próprios testes.
- **Opções.** (a) Aposentar os sete (a lista de exemplos da 1.0.10 um registro fechado; os três em disco ganham um `README.md` cada). (b) Construí-los, uma frente cada, depois de toda frente de membro. (c) Construir só o `rest-service`.
- **Recomendação.** (a).
- **Bloqueia.** 73 passo 3.

#### 03r-ak · Validação CycloneDX
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a′): validar o SBOM contra o schema CycloneDX 1.5 versionado com o validador vendorizado que a 399 já fixou, só no teste — não um caminhador escrito à mão** — `release_test.bp` roda `process.run("node", ["test/tools/check-schema.js", <documento>])` sobre `test/release/fixtures/bom-1.5.schema.json`, como `repository/validation/test/json_schema_test.bp` faz com o build standalone 2020 do Ajv (399: vendorizado sob `test/tools/`, versão e hash no `AGENTS.md`, nunca distribuído); `ok` ou a lista de erros do validador reprova o teste; sem rede. Um validador no ecossistema, não um segundo de ~120 linhas implementando um subconjunto do JSON Schema (67: um subconjunto que aprova um documento que o schema real recusaria é uma aprovação silenciosa); (b) enfraquece a caixa, (c) é uma funcionalidade de std de que ninguém mais precisa. Viável: `rakun-cli/test/release/release_test.bp` (o teste do SBOM afirma `bomFormat`, `specVersion`, `components` por nome hoje; nenhum `fixtures/` ainda), o `io.process.run` do std (o CLI do rakun já o chama); node nas linhas de CI do rakun como nas do validation. Mudanças: a caixa do passo 3 da 81 nomeia a ferramenta da 399; o `release_test.bp:168` da entrada está defasado.
- **Não viável (fable, 2026-10-12):** (c) — o std não tem validador de JSON Schema, e a 399 fixou o vendorizado para testes.
- **Medido.** A caixa pede validação contra um schema CycloneDX 1.5 versionado, sem rede; o std não tem validador de JSON schema; `release_test.bp:168` afirma campos por nome (`rakun-cli/test/release/` depois da 128).
- **Opções.** (a) `release_test.bp` percorre o SBOM contra os `required`, `type`, `enum` e `$ref`s locais de `test/release/fixtures/bom-1.5.schema.json` (~120 linhas), como o passo 3 da 81 já lê. (b) Emendar a caixa para a lista campo a campo. (c) Um `json.schema` no std.
- **Recomendação.** (a).
- **Bloqueia.** 81 passo 3.

#### 03r-al · Transações de produtor Kafka contra o broker em processo
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): confirmar — o registro, e a fiação** — o relay de outbox da 83 publica por `withProducerTransaction` no broker em processo (envios retidos, liberados no commit, descartados num raise; `read_committed` não vê nada depois de um abort); a execução com broker real é uma linha de `deferred.md` (160). Viável: `rakun-messaging/src/reliability/transaction.bp` `withProducerTransaction` (testado em `transaction_test.bp`); o outbox (`rakun-data/src/tx/outbox.bp` `publishAfterCommit`, `relayTick(ds, publisher)`) recebe uma função publicadora e ainda não passa por ele — a aresta `rakun-messaging → rakun-data` existe, então a cola é o publicador do rakun-messaging entregue a `relayTick`, a primeira caixa do passo 5 da 15. Mudanças: nenhuma no plano; o `transaction.bp:39` da entrada é `:54`.
- **Medido.** `rakun-messaging/src/reliability/transaction.bp:39` provê `withProducerTransaction(prefix, body)` (envios retidos, liberados no commit, descartados num raise; leitor `read_committed` testado em `transaction_test.bp`). O passo 5 da 15 já está escrito para (a): quatro caixas (caminho do outbox por `withProducerTransaction`, nenhuma linha de outbox; nada visível a `read_committed` depois de um aborto; o caminho no log; uma linha de `deferred.md` para um broker real). Só falta o registro.
- **Opções.** (a) O caminho do outbox da 83 publica por `withProducerTransaction` no broker em processo; execução com broker real uma linha de `deferred.md`. (b) Apagar as caixas de broker do passo 5. (c) Deixar o passo 5 aberto até um Kafka real estar no gate.
- **Recomendação.** (a).
- **Bloqueia.** 15 passo 5 (só o registro; a frente segue (a)).

#### 03r-am · Onde vivem os doubles de broker e scheduler
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **(c): os doubles vivem no módulo `testing/` do rakun (então o pacote `rakun-test` — 165: cada `*-test` é o módulo `testing/` do seu pacote), alcançando os registros só pelos hooks do core — nenhuma aresta para o rakun-messaging, nada a medir** — `rkOnReset("broker-double", …)` (`rakun/src/runtime.bp`) e um termo de nomes de listeners que o core possui são a costura; `testing/` é um módulo de `rakun`, então não importa nada de `rakun-messaging` (esse import seria `rakun → rakun-messaging`, o próprio ciclo), e os testes do `rakun-messaging` importam o `testing` de `rakun` pela aresta `rakun-messaging → rakun` que já têm. A regra da 185 (o core define o ponto de extensão); o 150 s21 passo 3 então roda `container_test.bp` pelo double. Viável: `rkOnReset` existe; nenhum `broker_double` / `task_double` existe no rakun (as notas do módulo `testing/` já descrevem "o double de broker" que não contém). Mudanças: os passos 3–4 do 150 s21 escritos para (c); o `runtime.bp:215` da entrada é `:232`.
- **Medido.** Os testes do `rakun-messaging` importam o módulo `testing/` de `rakun` (então `rakun-test`, que dependia só de `rakun`) por `rakun-messaging → rakun`; o 150 s21 passo 3 faz `container_test.bp` rodar pelo double — um double dentro de `rakun/src/testing/` que importasse `rakun-messaging` seria `rakun → rakun-messaging` ao lado de `rakun-messaging → rakun`, um ciclo de pacotes, a menos que o loader respeite um escopo de teste (nenhum existe em `modules/manifest`; não verificado). `rkOnReset(name, reset)` (`rakun/src/runtime.bp:232`).
- **Opções.** (a) Medir: acrescentar o import ao módulo `testing/` e o de `container_test.bp`; se `botopink test` recusar o ciclo, os doubles vivem ao lado do módulo que duplicam (`rakun-messaging/src/broker_double.bp` + `rakun_messaging_fixture.erl`, `rakun-scheduling/src/task_double.bp`) e o `testing/` do rakun os documenta. (b) Tomar a aresta, supondo que a regra pousou. (c) Os doubles no módulo `testing/` do rakun, alcançando os registros só por hooks do core (`rkOnReset("broker-double", …)`, o termo de nomes de listeners).
- **Recomendação.** (a), com a forma de (c) de qualquer jeito.
- **Bloqueia.** 150 s21 passos 3 e 4.

#### 03r-an · O transporte WebSocket do RSocket depois da decisão 187 (*proposta*, levantada como R92-1)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(b): um ponto de extensão do core chaveado por um enum de transporte — `rkRegisterTransport(.WebSocket, mount)`; o `rakun-websocket` se encaixa** — o core declara `enum Transport { Tcp, Tls, WebSocket }` e um registro em `rakun/src/runtime.bp`; o RSocket no `rakun-messaging` pede ao registro o transporte configurado e recusa o boot nomeando o membro a acrescentar quando nenhum o registrou; `rakun.rsocket.server.transport` é lido no enum pela config tipada da 299. 185 (nenhuma aresta membro-a-membro para o que é opcional; o `rakun-messaging` não depende do `rakun-websocket` hoje e (a) carregaria sua árvore para todo consumidor de messaging); 281 / 299: o transporte é uma variante, não a string que o código compara. Viável: `rakun-messaging/src/rsocket/rsocket.bp` recusa `transport == "websocket"` e fala só `tcp://`; nenhum registro ou enum existe — a primeira e a terceira caixas do passo 2 da 92 os constroem (o padrão de registro de `rkOnReset`). Mudanças: o `rakun-rsocket/src/rsocket.bp:69` da entrada é `rakun-messaging/src/rsocket/rsocket.bp` (187).
- **Não viável (fable, 2026-10-12):** (a) — uma aresta `rakun-messaging → rakun-websocket` carrega a árvore de websocket para todo consumidor de messaging, o que a 185 proíbe para o que é opcional.
- **Medido.** R92-1 monta o transporte pelo `#[wsEndpoint]` do `rakun-websocket`; depois da 187 o RSocket vive no `rakun-messaging` → a aresta carregaria a árvore do `rakun-websocket` (security, data) para todo consumidor de messaging; hoje o transporte WebSocket é recusado no boot (`rakun-rsocket/src/rsocket.bp:69`, só TCP).
- **Opções.** (a) Tomar a aresta `rakun-messaging → rakun-websocket`. (b) O core define um ponto de extensão de transporte em que o `rakun-websocket` se pluga (regra da 185), chaveado pela variante do enum de transporte (`rkRegisterTransport(.WebSocket, …)` — a 299 tipa a config, a 281 nenhuma string). (c) Aposentar o transporte WebSocket: as duas caixas da R92-1 e os braços `ws://` / `wss://` da R92-7 apagados, só TCP e TLS, uma linha de `deferred.md`.
- **Recomendação.** (b).
- **Bloqueia.** A primeira e a terceira caixas do passo 2 da 92.

### 05-jhonstart

#### 67-a · Onde as caixas de formulários do lado DOM são afirmadas
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **(a): `fake_dom.mjs` ganha `<form>`, `<input>`, `FormData` e `submit`; as cinco caixas são afirmadas em `forms_dom_test.bp` agora, e de novo na execução de navegador do ssr (150 s67, então onze 53)** — uma caixa afirmada só numa execução de navegador que nenhum gate segura é não afirmada (160, 67); (c) acrescenta uma dependência para o que algumas centenas de linhas de fake dão. Viável: `fake_dom.mjs` (sem form, sem `FormData`, sem `submit` hoje) em `jhonstart-dom-test`, ainda um pacote próprio enquanto a pergunta 165-b está aberta — ou o módulo `testing/` do rakun-bpp quando a 165-b o dobrar; a casa de `forms_dom_test.bp` (`jhonstart-dom-test/test/` ou o `testing/` do `rakun-bpp`) segue essa resposta, não esta; `test/dom_test.bp` o padrão; org-6: o passo é dono do arquivo que acrescenta, `fake_dom.mjs` editado por um passo de cada vez. Mudanças: os passos 1–3 do 150 s38 como escritos; uma linha de decisão o registra (o cabeçalho da frente reivindica uma resposta que nenhuma decisão tem).
- **Medido.** `fieldError` depois de `__jhFormState`, re-renderização no lugar em `ok: false`, `pending` de dois formulários, commit / rollback otimista leem `document` e `FormData`; `botopink test` não tem DOM; `jhonstart-dom-test` (`fake_dom.mjs`, só commonJS) já serve a metade de navegador da renderização. O cabeçalho da frente 67 (agora 150 s38) diz "`67-a` respondida", mas nenhuma decisão a registra — ainda aberta.
- **Opções.** (a) Estender `fake_dom.mjs` com `<form>`, `<input>`, `FormData`, `submit`; afirmar as cinco caixas (3a, 3b, 4, 5 da 1.0.10) em `forms_dom_test.bp` ao lado de `fake_dom.mjs` agora, e de novo na execução de navegador do ssr (150 s67). (b) Só na execução de navegador do ssr. (c) Uma biblioteca DOM real como dependência de dev.
- **Recomendação.** (a).
- **Bloqueia.** 150 s38 passos 1–3 (escritos para (a)); o caminho de escrita do 150 s67.

### 06-emilia

### 07-onze

#### 50-b · O que `onze dev` faz numa mudança
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): `onze dev` é `build` e depois `start`, em loop sobre um observador de arquivos — um caminho de código, os bytes que o `start` serve** — uma mudança reconstrói e reinicia o nó (1–3 s por edição); o estado das ilhas se perde de qualquer modo (Fast Refresh não é meta). O hot load de (b) e o fallback de (c) acrescentam um segundo caminho cuja equivalência com o `start` nada prova (67); (b) volta quando (a) medir lento demais no blog. Viável: `onze-cli/src/start.bp` (`erl -noshell -pa … -eval …`), `onze-bundler/src/rebuild.bp` (a invalidação, mantida para a metade do cliente); `onze dev` responde 2 hoje (`main.bp`) e nenhum observador existe — o observador é o `fs` do std em commonJS / erlang com o `io.process.spawn` / `forwardSignals` da 506 para o filho; o passo 2 da 50 o constrói. Mudanças: o "recarrega os módulos mudados" do passo 6 da 50 vira um reinício; o passo 6 da 53.
- **Não viável (fable, 2026-10-12):** (b) e (c) — o caminho de hot load não está escrito, e nada prova sua equivalência com os bytes que o `start` serve.
- **Contexto.** `onze dev` é o comando de desenvolvimento da renderização no servidor do onze (o onze agora é o pacote `rakun-ssr`, mono-a): enquanto o app roda, ele deveria pegar o que o usuário acabou de editar. Hoje ele responde 2 e não faz nada; `onze build` compila o servidor para BEAM e `onze start` o roda. A escolha é se uma mudança reinicia o servidor a partir de um build novo ou carrega os módulos mudados no que está rodando, e ela precisa ser feita antes que o passo 2 da 50 construa o observador (decisões 67, 140, 506).
- **Medido.** `onze build` compila o servidor para BEAM (`server/beam/`), `onze start` roda `erl -noshell -pa <outDir>/server/beam -eval …` (50-a); `onze-bundler/src/rebuild.bp` calcula os módulos invalidados; o BEAM pode fazer `code:load_file/1`; o registro de UI e a tabela de rotas se preenchem no carregamento do módulo (decisão 140): uma página recarregada se re-registra, um novo arquivo de rota precisa de `onze_routes.bp` regenerado e da tabela reconstruída.
- **Opções.**
  (a) Reiniciar o nó a cada mudança (`build` + `start` em loop sobre um observador de arquivos — os mesmos bytes de `start`, 1–3 s por edição).
  ```text
  $ onze dev
  # src/app/page.bp saved → build, then start again: the node restarts (1–3 s) and serves what `onze start` would
  ```
  (b) Carregar a quente os módulos alterados; regenerar e recarregar `onze_routes` quando a árvore do app mudar.
  ```text
  # src/app/page.bp saved → each invalidated module reloaded with code:load_file/1 in the running node
  # a new route file → onze_routes.bp regenerated, the route table rebuilt
  ```
  (c) (b), recaindo em (a) quando um arquivo de convenção mudou.
  ```text
  # page.bp saved → hot-loaded as (b); a convention file saved → restarted as (a)
  ```
  Estado de ilha do navegador perdido de qualquer jeito (Fast Refresh um não-objetivo, `07-onze/reference-holes.md` § 29).
- **Recomendação.** (a): um caminho de código, os mesmos bytes que `start` serve; (b) depois, se (a) medir lento demais no blog.
- **Bloqueia.** 50 passo 2; 53 passo 6.

#### 49-g · `isString` — do próprio onze, ou o `Json` do std
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **(b), no `json`: `Json.isString()` ao lado de `isObject`; o rakun-ssr apaga o seu** — um leitor por pergunta, na biblioteca dona do `Json` (396: a biblioteca `json` toma o `json.bp` do std inteiro, o std não sabe nada de JSON; até o 151 s1 pousar o tipo ainda é do std, então o método é escrito no `json.bp` do std sob a 97 e viaja com a mudança). (c) é um texto de diagnóstico como teste de tipo, nunca. Viável: `libs/std/src/json.bp` (o `case` de `isObject` é a forma), depois o `isString` do `config.bp` do rakun-ssr e o import de `types.bp` vão embora (então `onze/modules/onze/src/`). Mudanças: uma continuação de uma linha no rakun-ssr depois que a linha do `json` pousar.
- **Medido.** O passo 1 da 49 moveu o `config.bp` e o `types.bp` do ssr (então `onze/src/`) para os métodos do `Json` do std
  (`members`, `field`, `str`, `items`, `isObject`, `kindName`); o `Json` não tem teste de string, então
  `config.bp` mantém um `pub fn isString(v: Json) -> bool` (um `case` sobre `Str`), importado por
  `types.bp`. O grep do passo (`membersOf`, `strOf`, `isObject`, `kindName`) está vazio; sua
  linha de Mechanism também nomeia `isString`.
- **Opções.** (a) Manter o `isString` do ssr — `if (isString(v) == false) throw wrongKind(…)`.
  (b) O `json` (o `json.bp` do std até o 151 s1) acrescenta `pub fn isString(self: Self) -> bool` ao `Json` (superfície da 97), o ssr apaga o
  seu — `if (v.isString() == false) throw wrongKind(…)`. (c) Ler por `kindName` —
  `if (v.kindName() != "a string") throw …` (um texto de diagnóstico como teste de tipo).
- **Recomendação.** (b): um leitor por pergunta, no `json`, ao lado de `isObject`; (c) nunca.
- **Bloqueia.** nada; sob (b), um acompanhamento de uma linha em `config.bp` / `types.bp` depois da linha do `json` (151 s1).

#### 51-a · Um inteiro malformado num sidecar de métricas ou num ângulo de gradiente
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **(b): recusar — `parseMetrics(…) -> Result<FontMetrics, string>` responde `Error("<family> <weight>: line 3: \"9x0\" is not an integer")`, e `gradientOf` responde seu valor "not a two-stop linear gradient" para um ângulo não inteiro** — uma entrada malformada é recusada, nunca lida como zero (67; o precedente da 299: `rkPropInt("12abc") == 12` foi revertido). Viável: o módulo `og/` do rakun-ssr (então `onze-og/src/`): `metrics.bp` (`Error(_) -> 0` em três pontos de `parseInt`) e `svg.bp` `gradientOf`; os pontos de chamada e `og_test.bp`. Mudanças: as caixas de `og_test.bp` do passo de og (150, então 51).
- **Medido.** O passo 1 da 51 substituiu as duas células `intOf` do módulo de og pelo `string.parseInt()` do std;
  as células antigas respondiam `0` para texto que não é inteiro, e os pontos de chamada agora também
  (`case t.parseInt() { Ok(n) -> n.toI32(); Error(_) -> 0; }` — `metrics.bp` `parseMetrics`,
  `svg.bp` `gradientOf`). Uma linha de sidecar `ascent 9x0` lê-se como `ascent 0`;
  `linear-gradient(9.5deg,#a,#b)` desenha a 0°. Um inteiro além de `i32` agora aborta (`toI32`).
- **Opções.** (a) Manter `0`. (b) Recusar: `parseMetrics(…) -> Result<FontMetrics, string>`
  responde `Error("<family> <weight>: line 3: \"9x0\" is not an integer")`, e `gradientOf`
  responde seu valor "not a two-stop linear gradient" (`#(-1, "", "")`) para um ângulo que não é
  inteiro.
- **Recomendação.** (b) — decisão 67: uma entrada malformada é recusada, nunca lida como zero.
- **Bloqueia.** nada hoje; (b) é uma mudança em `og_test.bp` do passo de og da 150 (então 51).

### 08-bpp

### 09-cardume

#### atm-c · O `T` de um átomo através da costura servidor/navegador (*proposta*)
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **(b), com `#[clientOnly]` na declaração do átomo como a única grafia** — qualquer `T` pode ser um átomo; o conjunto de leituras de uma ilha é checado no build sobre seus hooks (277: arestas `use atomValue(x)`), e um átomo que uma ilha lê cujo `T` não é codificável (o `encode` do `#[validated]`, 327, ou um tipo que a 294 aceita) deve ser declarado `#[clientOnly] pub val draft = atom(…);` — a única função com um só significado da 278, numa declaração como a 186 a põe num hook — senão um erro no `use` da ilha nomeando o átomo e `T`; nenhum `clientAtom(…)`. Restritiva onde cruza, livre no resto (a 354 (6) declara a costura para contextos e deixa os átomos a esta pergunta); (a) proíbe um handle de DOM em qualquer átomo, (c) descobre em run time. Viável só com o cardume: `repository/cardume` não existe (296, passo 0 da 136) e rakun / rakun-bpp (então jhonstart) ainda não têm átomos de requisição; a checagem precisa que o modelo de hooks carregue o argumento de declaração do `use` (o `val` do átomo) — `HookUse.context` guarda um handle de declaração desde a 576 (7), mas se o argumento do `use` está entre os handles é o `HookUse` da 277 ganhá-lo (uma linha 144 se o B-17 não o fizer), senão o conjunto de leituras da ilha é incognoscível no build. Mudanças: o passo 6 da 136 escrito para (b); a 282 lê `#[clientOnly]` num `val`.
- **Não viável (fable, 2026-10-12):** toda opção hoje — `repository/cardume` não existe (passo 0 da 136); a proposta vincula o passo 6 da 136 quando abrir.
- **Medido.** O servidor semeia os valores que uma ilha leu em seu payload (136 passo 6); um valor que cruza deve ser codificável — depois da 306, o membro `encode` de um tipo `#[validated]` (`T.encode(v)`, 327; outra biblioteca aceita `T` só com `comptime compiler.typeInfo(T).meta(Validated)`, 606 (3) — antes da 606 `@typeInfo(T).meta(Validated)`), ou um dos `T`s que a 294 aceita para um cookie (string, número, `bool`, enum, record de um campo); algum estado é só do navegador por natureza (um handle de DOM, uma função).
- **Opções.** (a) O `T` de todo átomo codificável, checado onde o átomo é declarado. (b) Qualquer `T`; o conjunto de leitura de uma ilha checado no build — um átomo não codificável que uma ilha lê deve ser declarado só-cliente (`clientAtom(…)`, ou o `#[clientOnly]` da 278 estendido a declarações, 282). (c) Qualquer `T`, recusado só em tempo de execução.
- **Recomendação.** (b): restritivo onde importa (o que cruza), livre no resto.
- **Bloqueia.** 136 passo 6.

#### atm-d · Quais efeitos de átomo são entregues (*proposta*)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): nenhum efeito de átomo no primeiro corte** — o store pousa primeiro; `persistLocal` / `syncSearchParam` são um passo próprio depois de uma necessidade medida, uma função por preocupação (281: uma chave é a declaração, nunca uma string). Viável: nada a construir; o cardume ainda não tem código (136). Mudanças: o passo 8 da 136 adiado.
- **Não viável (fable, 2026-10-12):** (b) e (c) hoje — o cardume não tem código; a proposta é (a), nada a construir.
- **Medido.** Os efeitos de átomo do Recoil persistem ou sincronizam um átomo (localStorage, URL, um push do servidor); nenhum existe aqui.
- **Opções.** (a) Nenhum no primeiro corte. (b) Só `persistLocal("cart")`. (c) `persistLocal` e uma sincronização de search-param (`syncSearchParam("tab")`).
- **Recomendação.** (a): pousar o store primeiro; efeitos como um passo próprio depois de uma necessidade medida.
- **Bloqueia.** 136 passo 8.

### 10-specs

#### 141-a · Como uma decisão que aposenta uma grafia impede os specs de derivar (*proposta*)
- **Proposta (fable, 2026-10-12; estreitada em 2026-10-18; aguardando o mantenedor):** **(a): o commit da decisão reescreve a grafia aposentada em `specs/<current>/**` e acrescenta sua linha ao `inventory.md` da 141; o `scripts/land-check.py` (484 (4); 163 s12 pousado) ganha uma checagem — uma linha de decisão que emenda ou substitui N fica vermelha enquanto uma grafia que N aposenta ainda está escrita fora de um milestone fechado e das tabelas de alias** — a deriva nasce no commit da decisão, então é fechada ali; a lista de permissão de (b) escusa linhas (67) e não distingue uma frase que declara uma regra de uma que nomeia o que remove; (c) deixa uma frente ler a forma aposentada por um milestone. Viável: nenhuma ferramenta para a reescrita de (a); o `scripts/land-check.py` existe (`status.md` `[x] 163 s12`: não é fast-forward, um `*.snap.new` rastreado, uma referência de scratch, um hash de commit, um par EN/PT cujos ids ou blocos de código diferem — cada razão uma linha), então a checagem são algumas linhas a mais nele, lendo as palavras da própria linha pela grafia que aposenta (a linha nomeia as duas formas, o inventário da 141 os arquivos). Falta: se o `land-check.py` ganha essa checagem, ou se o dever fica só de quem escreve. Mudanças: o 163 s3 (141 s6) escreve a regra onde a resposta a puser.
- **Medido.** A 354 aposentou `@Component<C, R>`; o compilador a recusa e o codemod da 134 reescreveu as bibliotecas (`01-compiler/134` passo 6 caixas 1, 6), mas cerca de 280 linhas de spec em 71 arquivos ainda escrevem grafias aposentadas (`10-specs/141-specs-sweep/inventory.md`, nove famílias), e 25 linhas de `decisions-taken.md` ainda declaram o texto que uma emenda substituiu. Nada liga uma decisão às linhas de spec que ela aposenta; a 575, a 576, a 606 e a 641 aposentaram desde então `.d.bp`, `@Decl` / `@Expr`, todo builtin `@name` e as primitivas com maiúscula — cada uma uma família que a varredura mede do mesmo jeito.
- **Opções.** (a) O commit que escreve tal decisão também reescreve as linhas de classe S de `specs/<current>/**` que escrevem a forma antiga, e acrescenta sua linha ao `inventory.md` da 141 — um dever de quem escreve a decisão; a checagem do `land-check.py` é o oráculo no pouso. (b) Uma checagem de CI meta própria: uma lista de grafias aposentadas e dos arquivos autorizados a nomeá-las, vermelha em qualquer outro acerto — uma lista que desculpa linhas, o que o espírito da decisão 67 recusa, e uma checagem que não distingue uma linha S de uma linha R. (c) Nada: a varredura da 141 re-roda em cada fechamento de milestone.
- **Exemplos.** Uma decisão que aposenta `Context<T>()` por `createContext(value)` (379): (a) seu commit também reescreve o `pub val StyledContext = Context<StyledSheet>();` de `08-bpp/119/README.md` para `comptime createContext(StyledSheet.missing())` e acrescenta uma linha F1 ao `inventory.md` — `grep -rn 'Context<StyledSheet>()' specs/1.0.12-beta` fica vazio quando pousa, e o `land-check.py` fica vermelho até ficar; (b) `scripts/retired-spellings.txt` ganha `Context<[A-Z][A-Za-z]*>\(\)` com `01-compiler/134/README.md` autorizado, e a checagem de CI fica vermelha na linha da 119 até alguém reescrevê-la — e fica verde numa caixa que nomeia a forma como o que ela remove só porque esse arquivo está na lista; (c) a linha da 119 mantém `Context<StyledSheet>()` até o milestone fechar, e uma frente que abre a 119 nesse meio-tempo lê a forma aposentada.
- **Recomendação.** (a): a deriva nasce no commit da decisão, então é fechada ali; (b) só se (a) for medida falhando.
- **Bloqueia.** 163 s3 (141 passo 6).

#### Superadas por uma decisão posterior (frente 141 passo 5)

Listadas para o mantenedor, não fechadas aqui; cada uma mantém sua própria entrada e id.

| Id | Superada por | Fechamento recomendado |
|---|---|---|

### Do registro em português do mantenedor (`decisoes-pendentes.md`)

#### 07-i (revision) · Se a proibição da 163 de nomes repetidos em pacotes embutidos sobrevive ao alias da 170
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): continua proibido — um novo pacote embutido escolhe um nome que o std e os frameworks não exportam** — o alias da 170 serve às colisões próprias de um programa, não à nomeação do ecossistema; um nome para uma coisa entre pacotes se lê igual em todo módulo (67), e o `cookie` do `http`, o `id.deriveActionId` do `actions` já escolheram nomes livres. Viável: nada a construir. Mudanças: o "até a linha do toolchain fechar" da 163 vira regra permanente; nenhuma no código.
- **Medido.** A 163 proíbe um pacote embutido de exportar um nome que o std ou um framework exporta "até a linha do toolchain fechar"; a 170 (um import que nomeia seu módulo nunca é ambíguo; alias quando os dois são necessários) a fecha.
- **Opções.** (a) Ainda proibido: um novo pacote embutido escolhe um nome que não colide (o módulo `cookie` do `http`, o `id.deriveActionId` do `actions`). (b) Proibição suspensa: nomes naturais, os importadores usam alias.
- **Recomendação.** (a).
- **Bloqueia.** Nada; 102, 103 e 104 já escolheram nomes livres.

### 20-snap

### Propriedade

### Contradições que não bloqueiam nenhum passo 00–03

#### ctr-l · A terceira recusa da decisão 186 contra a decisão 202
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **Retirar a terceira recusa da 186** — sob a 202 nenhuma página se declara pré-renderizada, então "um hook `#[serverOnly]` numa página que se declara pré-renderizada" não tem caso: o `#[page]` recusa um hook `#[serverOnly]` dentro de um componente `#[client]` e um hook `#[clientOnly]` fora de um, e renderiza por requisição uma página cujos hooks alcançam `#[serverOnly]` (186, 202, 277). Viável: o contexto da 26 já lista só as duas recusas (`machine-1/150-rakun/26-jhonstart-router/context.md`). Mudanças: a linha da 186 perde sua terceira recusa; o `README.md:58-59,182-183` da entrada é esse arquivo de contexto.
- **Regras.** A 186 recusa "um hook `#[serverOnly]` numa página que se declara pré-renderizada (`08-g`)". A 202: "Nenhuma declaração … nenhum `pub val prerender` … nenhum jeito de forçar". Uma página é `pub fn blog() -> View` lendo `use cookie(sessionCookie)` (293, 294): renderizada por requisição, sem erro.
- **Recomendação.** Descartar a terceira recusa da 186: sob a 202 nenhuma página se declara pré-renderizada. O `05-jhonstart/26` passo 8 já lista só as duas recusas (`README.md:58-59,182-183`); só a linha da 186 está pendente.
- **Bloqueia.** Nada nas frentes; o registro.

#### ctr-v · A decisão 189 (org-3) contra as frentes do emilia abrindo antes da 118
- **Proposta (fable, 2026-10-12; relida em 2026-10-18; aguardando o mantenedor):** **Registrar: um carve-out só de comentários é tomado pelo passo dono; o resíduo da 118 mantém as linhas de código** — a org-3 sequencia carve-outs de código entre frentes, e as linhas de colchetes do rakun-stylesheet (então do emilia) são comentários (hoje só em seu `AGENTS.md`, `README.md`, `conformance/docs.md` e no comentário de uma célula: `attributes.bp` / `emilia.bp` não têm nenhuma, e `emilia-card` não existe mais). Viável: nada a construir. Mudanças: a linha org-3 da 189 ganha a frase, se algo restar — ver Medido; as linhas de arquivo da entrada estão defasadas.
- **Regras.** org-3: as exceções da 118 pousam antes de a frente dona abrir. Desde o 165 s8 (e a tabela da 165: o emilia é o pacote `rakun-stylesheet`) a 118 e a 33 / 34 são passos de uma só frente — o resíduo da 118 é o 150 s39, os passos da 34 são 150 s52 … s54 (`steps-emilia.md`; o 33 s2 está feito), todos na lane "style / bpp / stylesheet" de um só repositório, o `rakun`; as linhas `[class]={…}` (então `attributes.bp:30,32,36`, `emilia.bp:185,202`) e o `[emilia]={…}` de `emilia-card/src/main.bp:5` eram só comentários, reescritos por esses passos.
- **Medido (2026-10-18).** Dúvida: a org-3 ordena duas frentes, e 118, 33 e 34 não são mais frentes mas passos da 150 numa só lane, ordenados pelo próprio texto da 150 (`steps-jhonstart.md` § Order: "26 → 27 → 67 → 118's residue → 119's jhonstart half → …"; `steps-emilia.md` § Depends on); a contradição pode portanto estar fechada — nada da org-3 sequencia passos de uma só frente — e o que restaria é só o registro (a linha da 189). As linhas 575–659 não o dizem; o mantenedor a fecha ou mantém o registro.
- **Recomendação.** Registrar que uma exceção só de comentários é tomada pelo passo dono; o resíduo da 118 (150 s39) mantém as linhas de código (seus próprios testes, o teste de ponte do rakun-stylesheet (então do `jhonstart-emilia`), `document-shell`). Os passos já a seguem (118 § Does not touch, 150 s52, `fronts.md:49`); só a linha da org-3 está pendente — ou fechada, se a dúvida acima valer.
- **Bloqueia.** Nada nas frentes; o registro.

#### ctr-w · O braço Elasticsearch da frente 09 contra a decisão 185
- **Proposta (fable, 2026-10-12; regrafada em 2026-10-18; aguardando o mantenedor):** **O braço Elasticsearch alcança HTTP por um ponto de extensão do core (185), nunca por uma aresta `rakun-data → rakun-restclient`; respondida com a lista de braços da `03r-ab`** — o `rakun-data` depende só de `rakun` e `query` (tabela da 165) e nenhum braço existe, então nada é desfeito. Viável: o padrão de registro do core (`rkOnReset`; o registro de transporte da `03r-an`), ou o `io/http` do std diretamente (`fetch(req: Request)`, 623), como o relay da 65 faz. Mudanças: o 150 s17 passo 3 escrito contra ela.
- **Regras.** 185: uma capacidade opcional passa por um ponto de extensão do core, "nenhuma aresta de membro para membro". `04-rakun/09` § Open point (agora 150 s17): o braço Elasticsearch sobre `rakun-restclient` (então `rakun-client`) acrescenta uma aresta `rakun-data → rakun-restclient` que todo consumidor de data carrega.
- **Recomendação.** O braço alcança HTTP por um ponto de extensão do core (ou o `io/http` diretamente, como o relay da 65), não por uma aresta `rakun-restclient`; respondida com a lista de braços da `03r-ab`.
- **Bloqueia.** 150 s17 passo 3.


#### ctr-x · A decisão 337 (2), (3) contra a 592 (1): `mod m;` e `pub mod` depois de "sem `mod` / `pub mod`"
- **Proposto (opus, 2026-10-18; aguardando o mantenedor):** **A 337 (2) e (3) são superadas pela 592 (1); a 337 mantém (1) e (4).**
- **Regras.** 337 (2): `mod config;` e `pub mod config;` vinculam `config` como namespace no módulo que os declara; (3): o `mod.bp` de uma pasta expõe a função de um submódulo por `pub val`, o submódulo mantido privado. 592 (1): todo `.bp` sob `src/` é um módulo do pacote, seu caminho o seu nome; sem `lib.bp`, sem `mod` / `pub mod`. As duas linhas estão em vigor no ledger. A frente 166 s3 (yaml) escreveu a célula de decisão da 337 só como a recusa de (1).
- **Recomendação.** Emendar a 337 à sua recusa `shorthand-import` de (1) e à sua migração de (4); (2) e (3) "Overtaken by 592 (1)".
- **Bloqueia.** As células de decisão da 337 em todo repositório que ela vincula (166 s3).
---

#### ctr-af · A decisão 105 contra a 553 (3): a grafia de um laço sobre coleção
- **Regras.** A 105 (2026-09-24) escreveu o laço sobre coleção como lambda final, `for (xs) { x -> … }`. A 553 (3) (2026-10-15) consome um iterador com `for x in try xs` / `for await x in try xs`, e a frase de laços do arquivo de assuntos (105) omite a grafia.
- **Opções.** (a) `for x in xs` (`for await x in xs`; `try` onde a camada é um `Result`), a forma da 553 (3), a grafia de lambda final da 105 se vai; (b) o `for (xs) { x -> … }` da 105 fica como segunda grafia.
- **Recomendação.** (a) — uma grafia, a da decisão mais tardia.

#### ctr-ag · A decisão 54 contra a 602: um `?T` casado por um braço ligador
- **Regras.** 54 (2026-09-18): um `?T` é casado por `null` e por um ligador, `case x { null { … } v { … } }`. 602 (2026-10-17) com B-22: um nome sozinho nunca é padrão — `case-bare-name-arm`, em toda forma de braço.
- **Opções.** (a) a 602 inteira: o braço não-nulo é `_` (ou um padrão tipado), o valor lido estreitado como `x!`; o braço ligador da 54 se vai; (b) o braço ligador da 54 fica como a única exceção, só para `?T`.
- **Recomendação.** (a) — uma regra para todo braço.

## Parte 3 — Escolhas de implementação das trilhas 04–09

### 04-rakun (21)

| Id | Escolha implementada | Onde |
|---|---|---|
| 03r-a | Todo manifesto do rakun é `["erlang"]`; um programa erlang construído distribui e carrega seus sidecars `.erl` (a metade do ledger perde o sentido sob a 153) | todo membro |
| 03r-c | Os leitores da frente 05 continuam botopink (`config.bp`); nenhum `rakun_config.erl`; sob a 299 alimentam os records `#[config]` | 04 |
| 03r-e | Um componente de cookie ou query que o std recusa, ou que decodificaria para um caractere de controle, fica como escrito (`decodeComponent`) (`ctr-p`) | 04 |
| 03r-f | Uma chave de cache é `namespace + ":" + hash.strongCacheKey(parts)` | 12 |
| 03r-g | Uma leitura de escopo privado sem sessão roda o loader, não guarda nada | 12 |
| 03r-h | A chave de um gêmeo é `[method, args…]`; `#[cacheEvict(name, false)]` o expulsa sob todo leitor `#[cacheable(name)]` | 12 |
| 03r-i | O provedor de cache Redis reutiliza o wire RESP do rakun-session (`rkSessRedis`); `revalidateTag` apaga; um Redis inalcançável roda o loader sem cache (health DOWN) | 12 |
| 03r-j | Fora de uma requisição `revalidateTag` / `revalidatePath` são legais, `updateTag` lança; o global `rakun.cache.type=none` desativa todo cache seja qual for seu próprio tipo | 12 |
| 03r-k | Todo braço de messaging roda no broker em processo (`transport=memory`); um endereço real sem ele recusa o boot nomeando o driver | 15 |
| 03r-l | Um container de listener recebe o nome de seu destino (`#[amqpListener("orders")]` → `rakun.messaging.listener.orders.*`, `#[streamListener("audit-stream", "@next")]` → `listener.audit-stream.*`); o Redis tem por default o ack-mode `none` (`auto` / `manual` explícito no Redis recusa o boot). As grafias das chaves seguem a 299 (`ackMode` ou `#[key("ack-mode")]`) | 15 · `markers.bp:90,103` · `container.bp:125` |
| 03r-m | Dentro de uma server action `revalidatePath` / `revalidateTag` expiram de uma vez; fora, obsoleto-depois-fresco | 12 · 22 |
| 03r-n | Um argumento JSON-RPC é uma lista de campos codificados como formulário, lida em ordem num só formulário | 22 |
| 03r-p | Um slot pertence ao layout mais próximo na altura de sua entrada mais curta ou acima dela; um conflito são duas páginas de um slot numa URL | 22 |
| 03r-r | Os starters nomeiam membros irmãos como `{ "workspace": true }` | 73 |
| 03r-s | OTLP empurrado como HTTP/JSON (`json:encode` em `rakun_metrics.erl`) | 17 |
| 03r-t | As chaves da frente 76 sob `rakun.management.*`, num só `management.bp` mais o sidecar `rakun_probes` | 11 |
| 03r-u | O grupo de liveness admite só `livenessState`, `ping`, `diskSpace`; qualquer outro nome recusa o boot | 11 |
| 03r-v | O operador do construtor de queries tipado é o enum `Op` (`Eq`, `Ne`, `Lt`, `Gt`, `Le`, `Ge`, `Like`): `queryOf(City.entityMeta()).where(City.columns().state, Op.Eq, "CA")`; a coluna como `compiler.Field<City>` (308) é uma pergunta separada | 08 · `orm/query.bp:84-115` |
| 03r-w | Os endpoints explícitos do OAuth2 são campos de `OAuth2Provider` (`authorizationUri`, `tokenUri`, `userinfoUri`, `jwksUri`); as credenciais de cliente são `withClientToken(id, call)`, tentando uma vez de novo em 401 | 79 · 13 |
| 03r-x | O relay do outbox reivindica por `UPDATE` condicional (as reivindicações de um relay que caiu voltam por `reclaimStale`); os coordenadores de saga e 2PC persistem toda transição e retomam no boot (`resumeSagas`, `recover2pc`); o job store reivindica triggers e assume leases do mesmo modo | 15 |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-a:** confirmar a regra só-erlang; sob a 512 (3) os 27 manifestos de membros, 8 de starters e 3 de exemplos que repetem `"targets": ["erlang"]` o largam (o workspace o declara uma vez) — com a `95-b`, a varredura de manifestos da 150.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-c:** confirmar (`rakun/src/config.bp`, nenhum `rakun_config.erl`); os records `#[config]` da 299 ainda não estão construídos (`#[configurationProperties]` e `rkProp*` permanecem) — rakun 04 s7.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-e:** revertida pela `ctr-p`: nada fica "como escrito"; `decodeComponent` vai embora com os leitores que a 196 apaga.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-f:** confirmar (`rakun-cache/src/cache.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-g:** confirmar (`cache.bp`: uma linha privada sem sessão roda o loader, não guarda nada).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-h:** confirmar (`cache.bp` `cacheMethod`, `cacheEvictAll`, `cacheEvictKeys`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-i:** confirmar; o wire Redis ainda é o `rkSessRedis` do `rakun-session` importado pelo `rakun-cache` — uma aresta membro-a-membro que a 185 move para o core quando uma frente a tocar.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-j:** confirmar (`cache.bp`: `rakun.cache.type=none` vence todo cache; `updateTag` fora de uma action entra em pânico).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-k:** confirmar (`rakun-messaging/src/container.bp` aceita só `memory`, recusa nomeando o driver).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-l:** emendar sob a 318 (5): um listener, `#[listen(orders)]` num método de um `#[component]`, o destino declarado uma vez e tipado (`pub val orders = Destination<OrderPlaced>("order-events")`), o container nomeado por esse destino (`rakun.messaging.listener.<destination>.*`), o modo de ack `none` do Redis imposto, as chaves lidas pela config tipada da 299 (`ackMode` / `#[key("ack-mode")]`); na feat `markers.bp` ainda declara `#[amqpListener]`, `#[kafkaListener]`, `#[redisListener]`, `#[streamListener]`, `#[listener]` e lê `rkProp(listenerKey(…))` — o passo da 15 para a 318.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-m:** confirmar (o texto de fase de action do `cache.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-n:** confirmar (`rakun-app/src/actions.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-p:** confirmar (`rakun-app/src/file_router.bp`, `slotOf`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-r:** confirmar (`starters/rakun-starter/botopink.json` `"workspace": true`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-s:** confirmar (`rakun_metrics.erl` `otlp_*_json`, `json:encode`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-t:** confirmar (`rakun-actuator/src/management.bp`, `rakun_probes.erl`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-u:** confirmar (`management.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-v:** confirmar como o estado na feat (`rakun-data/src/orm/query.bp` `Op`, `queryOf`, `City.columns()`); superada em direção por 312 / 397 / 398: o builder tipado sai do rakun-data quando o `self.db.query "…"` do erika e o dbcontext pousarem (137, 143), uma linguagem de consulta — a pergunta da coluna como `compiler.Field<City>` (308) fica sem objeto então.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-w:** confirmar (`rakun-security/src/oauth2/provider.bp`; `client_credentials.bp` `withClientToken`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-x:** confirmar (`tx/outbox.bp` `reclaimStale`, `saga.bp` `resumeSagas`, `twopc.bp` `recover2pc`).

### 05-jhonstart (9)

| Id | Escolha implementada | Onde |
|---|---|---|
| 26-a (jhonstart) | Toda célula do router de alvo duplo (um gêmeo `router_runtime.mjs`). Id compartilhado com o `26-a` do 01-compiler, decisão 242 | core |
| 29-a | O que a 281 deixa: a tabela de starters de ilhas é o `globals.starters` do registro, preenchida por rota por `registerRouteStarters(pattern, load)` (um padrão de rota é uma URL, uma string sob a 281); um segundo loader para uma rota falha. O `registerStarter(name, start)` por nome sai — a 281 constrói a tabela de starters em comptime (`@TypeInfo.all(with: client)`, 120 passo 6, 53 passo 7) | core · 26 passo 5 (sua linha de `docs.md` ainda nomeia `registerStarter`) |
| 30-b | `RenderPlugin` é um record de funções async; `payload` responde `Array<#(key, json)>`; `chunk(id)` roda no próprio processo do boundary | `streaming.bp` |
| 30-c | `render` / `renderStream` / `App` em `streaming.bp`; `compose` recebe a página como um thunk, roda os layouts primeiro — `compose(chain, { -> Page() })`; o parâmetro `route: PageContext` de hoje sai com a 293, a página é `fn() -> View` (276) | `streaming.bp` · `render.bp:341` |
| 30-d | `Suspense(Boundary(id, fallback, child))` registra seu boundary na renderização por uma célula de host; a página devolve só a árvore (`-> View`) | `suspense.bp:19-34` |
| 30-e | O record de segmento é `UiSegment` | core |
| 30-f | `app(…, lang = "en")`: uma língua checada por app. A checagem vira o subconjunto BCP 47 da decisão 180 quando a 105 substituir `isLangTag` por `i18n.wellFormedTag`; um `PageInput.lang` por requisição do `htmlLang()` existente do rakun-app continua aditivo | core · `streaming.bp:197-204` · 105 |
| 30-g | Metade de navegador afirmada no membro só-commonJS `jhonstart-dom-test` sobre `fake_dom.mjs` | `jhonstart-dom-test` |
| 31-a | `notFound()` / `redirect(url)` lançam por uma célula de host (`__jhRaise`); um boundary captura por `__jhCapture`; `notFoundReason()` / `redirectReason(url)` respondem a razão sem lançar. Declaram `-> string` até `noreturn` caber numa posição de valor — espera nat-d6 e lg2-l (se nat-d6 for (a), viram `-> noreturn`) | core · `error_boundary.bp:118-187` |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 26-a (jhonstart):** confirmar (`router_runtime.mjs` ao lado de `router.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 29-a:** confirmar a escolha reduzida (`registerRouteStarters` + `globals.starters`); o `registerStarter` por nome ainda está declarado em `client.bp` — vai embora com a tabela de starters em comptime da 281 (26 passo 5, 120 passo 6), uma linha 149.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 30-b:** confirmar (`plugin.bp` `RenderPlugin`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 30-c:** confirmar o thunk (`render.bp` `compose(chain, route: PageContext, page: fn() -> @Component<Element>)`); o parâmetro `route: PageContext` ainda está lá — sai com a 293 (26 passo 11), quando a assinatura vira `compose(chain, { -> Page() })`.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 30-d:** confirmar (`suspense.bp` `Boundary`, `__jhPushBoundary`); seu `child: fn() -> @Component<Element>` vira `@Component<Element>` sob 504 / lg2-n.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 30-e:** confirmar (`routes.bp` `UiSegment`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 30-f:** confirmar (`streaming.bp` `app(…, lang = "en")`, `isLangTag`; o repositório `i18n` da 105 ainda não existe).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 30-g:** confirmar (`jhonstart-dom-test`, `fake_dom.mjs`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 31-a:** emendar sob a `nat-d6` (a) e a `lg2-l`: `notFound()` / `redirect(url)` viram `-> noreturn`, lançando um `NavOutcome` tipado; `notFoundReason()` / `redirectReason(url)` ficam; `isSignalReason` vai embora.

### 06-emilia (9)

| Id | Escolha implementada | Onde |
|---|---|---|
| 05emilia-a | O leitor de filter é a cadeia inline do upstream (`filterChain()`, `backdropFilterChain()`), não `var(--tw-filter)` | 42 |
| 05emilia-b | A seção de backdrop é `BackdropFilter` | 42 |
| 05emilia-c | `drop-shadow-none` segue o upstream (`--tw-drop-shadow: ` e o leitor) | 42 |
| 05emilia-d | A rigidez do snap é o fallback `var(--tw-scroll-snap-strictness, proximity)` | 46 |
| 05emilia-f | As entradas `--inset-shadow-*` descartam o `inset` inicial do upstream | 41 |
| 05emilia-g | `space-*` / `divide-*` seguem o seletor do upstream e margens cientes de reverso | 35 · 40 |
| 05emilia-i | As variáveis de transform `--tw-*` são blocos `@property` com a camada `properties` do upstream — `translate-*`, `skew-*` e `scale-*` (`--tw-scale-*`) igualmente | 45 · 54 · 56 |
| 05emilia-j | Um modificador de lista de seletores (`marker:`, `selection:`) é uma lista de variantes de um `&` | 34 · 56 |
| 05emilia-k | O meio passo negativo é `spacingNegHalf(n)`; `spacingHalf` recusa um `n` negativo | 54 |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-a:** confirmar (`emilia.bp` `filterChain`, `backdropFilterChain`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-b:** confirmar (`BackdropFilter` em `emilia.bp`, `tokens.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-c:** confirmar (`emilia.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-d:** confirmar (`tokens.bp` / `emilia.bp` `--tw-scroll-snap-strictness`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-f:** confirmar (`theme.bp` `--inset-shadow-*`; o detalhe do `inset` inicial não reverificado).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-g:** confirmar (`emilia.bp` `space-*` / `divide-*`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-i:** confirmar (blocos `@property` em `emilia.bp`, `tokens.bp`, `output.bp`; o nome da camada não relido).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-j:** confirmar (`emilia.bp` `selectionVariants`, `tokens.bp` `Selection`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-k:** confirmar (`spacing.bp` `spacingNegHalf`; `spacingHalf` recusa um `n` negativo).

### 07-onze (9)

| Id | Escolha implementada | Onde |
|---|---|---|
| 49-a | As suítes do core renderizam por seus próprios `describe*` sobre `snapshots.assertAs`; os helpers do `onze-test` são wrappers finos | core do onze |
| 49-c | `onze.json` recusa uma chave desconhecida, uma duplicada, um tipo errado, uma porta fora de `1..65535`, uma entrada não-string de `allowedRedirects` | `config.bp` |
| 49-e | A metade rakun do boot é o membro erlang `onze-server` | 49 passo 2 |
| 50-a | `onze build` prepara um main de servidor, compila para BEAM; `onze start` o roda com `erl` — como emendado: `start` chama o `bin/onze` da frente 71 assim que existir | 50 · 71 passo 2 |
| 52-a | A tabela de métricas de fonte tem cinco linhas transcritas; seu gerador é devido | 51 passo 4 |
| 53-a | Os fontes do blog sob `src/` (`appDir: "src/app"`) | 53 |
| 68-a | Um campo do manifesto de cliente escapa só `%`, `\|`, LF e CR | bundler |
| 68-d | O styleMap é avaliado por uma sonda compilada em ambos os pacotes (`emilia-hash-split`, `emilia-unevaluated`) — sem sentido quando o passo 1 da 34 e o passo 4 da 119 pousarem (301: os tokens `#[styled]` são comptime, a classe e a regra calculadas no build sobre o `contentHash` do std); vale até lá | bundler |
| 69-a | O onze-assets mantém `AssetRoot`; o onze-server o converte para o `StaticRoot` do rakun-web | assets · server |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 49-a:** confirmar os `describe*` próprios; emendar o motor: as suítes escrevem pelo `assertAs` do `snap` (391; `import {assertAs} from "snap"`, uma dependência git em `onze/botopink.json`), não pelo `snapshots` do std.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 49-c:** confirmar (`onze/src/config.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 49-e:** confirmar (`onze-server`, erlang).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 50-a:** confirmar (`onze-cli/src/start.bp` roda `erl -noshell …`; `bin/onze` espera a 71).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 52-a:** confirmar (`onze-assets/src/font_metrics.bp`, cinco linhas; o gerador devido).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 53-a:** confirmar (`examples/blog/onze.json` `appDir: "src/app"`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 68-a:** confirmar (`onze-bundler/src/manifest.bp` `escapeField`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 68-d:** confirmar até 34 s1 / 119 s4 pousarem (a sonda e seu snapshot ainda existem).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 69-a:** confirmar (`onze-assets/src/assets.bp` `AssetRoot`; `onze-server/src/server.bp` `staticRootOf`).
