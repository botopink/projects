# Decisões pendentes

As perguntas abertas do milestone corrente, 1.0.12-beta; um arquivo acima de todo milestone desde 2026-10-18.

**Nenhuma pergunta, contradição ou escolha de implementação está aberta** (2026-10-21: as 33 perguntas, 8 contradições e 100 escolhas foram respondidas por 899–955; uma nova entra abaixo, na sua seção).

- Uma resposta vai para [`decisions-taken-steps.md`](decisions-taken-steps.md) sob o próximo número livre (mantido
  só lá); um id com letra nunca é renumerado nem reutilizado.
- Toda recomendação é a leitura mais restritiva, sem configuração que a contorne (decisão 67).
- Uma frente que encontra uma pergunta que não consegue responder pelo código a acrescenta aqui: id · título · Medido
  (observado, re-executável) · Opções · Recomendação · Bloqueia. *Proposta* = levantada sem id.

- **Para revisar** — as decisões que um `fable` tomou por delegação do mantenedor e as respostas dele às perguntas de um fable (2026-10-20, 2026-10-21), para ele revisar depois.
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
número livre, que é **957**.

## Para revisar — as decisões do fable e as respostas às suas perguntas (2026-10-20, 2026-10-21)

O mantenedor pediu (2026-10-21) que toda decisão que um `fable` tomou por ele, e toda resposta que ele deu a uma pergunta de um fable ou a uma revisão ao lado, fosse marcada para revisar depois. Cada uma continua em vigor como escrita; uma revisão que mude uma é uma linha nova que a emenda. Marque `[x]` depois de revisar.

| Revisada | Linha | Respondeu | O que foi decidido |
|---|---|---|---|
| [ ] | 814 | a revisão do fable de 809–813, Q8 | Respondida pelo mantenedor: o construtor e os campos de um tipo opaco privados ao tipo, os seus métodos sem `pub` privados ao módulo |
| [ ] | 815 | a revisão do fable de 809–813, Q1–Q3 | Respondida pelo mantenedor: `Composition<T>` de novo uma função, uma lambda desse tipo um componente sem hooks, chamável à mão |
| [ ] | 816 | a revisão do fable de 809–813, Q2 | Respondida pelo mantenedor: o estado dos hooks na célula de escopo do nó, mantido de render a render no mesmo lugar, como o React mantém uma fiber |
| [ ] | 817 | a auditoria do fable, Q1–Q4 | Respondida pelo mantenedor: o `Scope` da std guarda a árvore de células por lugar e identidade; contextos tomados de novo no reuso; `#[key]` |
| [ ] | 818 | a avaliação do fable de 809–817, Q1, Q2, Q4, Q7 | Respondida pelo mantenedor: todo `use` que responde um valor uma célula filha; a identidade de um componente a chamada que o fez; `#[key(expr)]` na chamada |
| [ ] | 819 | a avaliação do fable de 809–817, Q3 | Respondida pelo mantenedor: `Composition<T> = fn(scope: Scope, key: Place)`, abrindo a sua própria célula; uma chamada à mão segura; `key-duplicate` |
| [ ] | 820 | 819-a | Respondida pelo mantenedor: a chamada que faz um componente carimba o seu lugar no valor; quem roda passa `Place.none()` |
| [ ] | 821 | 819-b | Respondida pelo mantenedor: o número de uma chamada contado dentro do corpo `component` mais próximo; uma função auxiliar transparente; uma função de componente como valor numerada onde está escrita |
| [ ] | 822 | 809-e | Respondida pelo mantenedor: uma raiz roda um componente com o `run` da std (emendada pela 825) |
| [ ] | 823 | 810-b (parte) | O mantenedor escolheu (d); o fable decidiu onde a regra ansiosa fica escrita (§ body-markers (3), o escalonamento da 392 (1) declarado só para commonJS e wasm) e que o `ref.test` do wasm sobre `$task` é da 164 s2 |
| [ ] | 824 | 809-i | No erlang e no beam a árvore de células de uma raiz é uma entrada do dicionário do processo que a criou, encerrada com esse processo ou `root.close()`; um scope cruza um processo só como `scope.detach()` (emendada pela 825) |
| [ ] | 825 | a revisão do coordenador da 824 | Respondida pelo mantenedor: o `run` faz e fecha a sua própria raiz (`defer root.close()`); `close` marca uma raiz fechada nos quatro alvos |
| [ ] | 826 | 809-f | `Composition`, `Composable` e `Component` são nomes do prelude em `primitives.bp`, escritos sem import, lidos nominalmente |
| [ ] | 827 | 809-g, 804-d | O `use all(cs)` da std resolve uma lista de componentes em run time sob um `use`; o `Sheet.render` e o `spliced` do rakun-style o usam |
| [ ] | 828 | 809-h, 804-e | Os cinco códigos da forma de tipo; `component-compose-missing` e `component-use-outside-compose` viram as recusas gerais |
| [ ] | 829 | 811-a | `opaque` fecha só um record, uma palavra contextual, como construído |
| [ ] | 830 | 811-c | As chamadas do próprio lowering conhecidas por uma marca no nó da chamada, não pela faixa de linhas 3.000.000; uma chamada à mão de um nome `__bp_` é `reserved-name` |
| [ ] | 831 | 810-c | A identidade de um behavior em run time é o átomo da sua declaração `<package>@<path>@@<B>`, sem contador (o mantenedor aceitou a tabela por alvo) |
| [ ] | 832 | 806-b | A opinião do fable — um tipo inline num campo de registro, nomeado pelo dono `Bp__<Owner>__<field>`, nunca um contador — tomada com o "os dois devem ser aceitos" do mantenedor |
| [ ] | 833 | 798-b | Um arquivo do `compiler.load` checado para todo alvo do manifesto de quem chama, nunca o `--target` do build |
| [ ] | 834 | 798-c | O `--emit-resolved` escreve um arquivo por módulo, `<dir>/<pkg>/<module path>.bp`, os nomes como escritos |
| [ ] | 835 | 798-d | Um valor dobrado sem literal impresso como a chamada que o constrói (`createContext(v)`, `@embed("path")`) |
| [ ] | 836 | 798-e | `<f>__type`, `__<Enum>__<Section>`, `__embed_<p>` vão para o espaço reservado; `<Type>__<Assoc>` fica |
| [ ] | 837 | 805-a, 805-c | Um `.bpr` por pacote e por módulo da std, como construído; a ordem do programa só no arquivo da raiz |
| [ ] | 838 | 805-b | Um `.bpr` compilado e rodado só do diretório do seu projeto, `runtime-other-project` fora dele |
| [ ] | 839 | 723-b | `use context(ctx)` nomeia só um valor de contexto do módulo, nunca um parâmetro, um local ou uma expressão (como construído) |
| [ ] | 840 | 668-a | `compiler.meta(d, M)` / `compiler.metaAll(d, M)` a única grafia; `compiler.meta<M>(d)` sai |
| [ ] | 841 | 719-a | Uma função com parâmetro de expressão `syntax` retorna qualquer tipo escrito, `void` incluído |
| [ ] | 842 | 797-a | Um membro que um decorator acrescenta e usa é guardado como valor; um `decl` tipado por behavior atendido por `implement` (716 (1) sobre a 626 (2)) |
| [ ] | 843 | 564-d | Respondida pelas 606 (1), 639, 826 (3): um módulo pode sombrear um nome do prelude |
| [ ] | 844 | 723-c | Respondida pela 723: um default por tipo de contexto |
| [ ] | 845 | B-21-d | Respondida pelas 583, 408: `fn() { … }` é a forma não tipada |
| [ ] | 846 | B-21-e | Respondida pela 622: a forma curta `fn f(x: T) R` recusada, um desvio a remover |
| [ ] | 847 | B-02-c | `std:` num template recusado em toda variante e todo alvo |
| [ ] | 848 | B-10-b | `compiler.variants(d)` responde `compiler.Variant[]` tipado |
| [ ] | 849 | B-10-c | `clock.formatIso8601` sempre escreve milissegundos |
| [ ] | 850 | B-10-e | Respondida pelas 826 (4), 629 (2), 828 (1): um alias não implementa nada |
| [ ] | 851 | B-10-f | Superada pela 804 (2): não há `Renderable` a perguntar |
| [ ] | 852 | B-10-g | Um alias de `Component` num retorno é apagado; `-> View` responde `Component<Element>` |
| [ ] | 853 | B-27-e | Dois módulos que viram o mesmo átomo erlang recusados (só erlang e beam — o fable pergunta se em todo alvo) |
| [ ] | 854 | B-27-f | Respondida pelas 255 (1), 561: uma aplicação de tipo com crase antes de `.` são duas comparações, como construído |
| [ ] | 855 | B-27-g2 | Superada pelo B-128: `keys()` preguiçoso no erlang e no beam |
| [ ] | 856 | B-27-g4 | Modo raw e tamanho só no Linux no erlang e no beam, `Unsupported` fora |
| [ ] | 857 | 804-c | `children_for_walk` reescrita sobre `children: El[]`, mantida como o percurso de campo recursivo do wasm |
| [ ] | 858 | 810-a | Toda recusa de exaustividade leva o código `non-exhaustive` |
| [ ] | 859 | 811-b | Um método sem `pub` é privado ao módulo para todo tipo (`method-not-pub`); os métodos de `primitives.bp` viram `pub` |
| [ ] | 860 | B-86-a | O gate lib-agnóstico como construído; o alcance do catálogo vazio (`@TypeInfo.all` saiu) |
| [ ] | 861 | 548-a | Respondida pela 650: uma forma de link, o codemod da 166 s4 |
| [ ] | 862 | 548-b | Os nomes das bibliotecas antigas fora do código do rakun (`stylesheet()`, `SsrConfig`, `/_rakun-ssr/` — nomes do fable, a confirmar) |
| [ ] | 863 | 165-a | O conjunto de versões uma linha por pacote em `version_set.bp`, como construído |
| [ ] | 864 | 529-a, 529-b | `..` qualquer expressão, sem migração; um parâmetro de registro em todo chamável, sem variádico nem default ao lado |
| [ ] | 865 | 537-b | `catch` o infixo mais baixo, `??` o nível binário mais justo, como construído |
| [ ] | 866 | 539-a | Um corpo `defer` não lança nem propaga (`defer-throw`, `defer-try`) |
| [ ] | 867 | 540-b | Respondida pela 607: `Asset` importa `io.fs` ele mesmo |
| [ ] | 868 | 532-a | Uma célula de recusa declara os seus frames `from`, o cabeçalho igual |
| [ ] | 869 | 533-a | `comptime-badarith` nomeia a operação que divide no seu caret |
| [ ] | 870 | 535-b | O handler de abort do commonJS emitido na entrada do programa |
| [ ] | 871 | 800-a | "Idêntico" sobre tipos; o marcador `comptime` faz parte da assinatura |
| [ ] | 872 | 799-a | Um membro obrigatório que o tipo já tem atende o contrato, comparado pela 800 |
| [ ] | 873 | 641-a…d | `val length` só em `primitives.bp`; um local sombreia estáticos; `array` um nome reservado (`json.arrayOf`); `bytes.toUtf8` |
| [ ] | 874 | B-116-k | Respondida pelas 553/147, 819/821, 584/409 |
| [ ] | 875 | 518-a | Respondida pelas 575 (6), 621: as recusas de `needs:` são do construtor |
| [ ] | 876 | 335-a | Respondida pela 823: `race` sobre valores prontos; o rascunho sobre `raceOf` |
| [ ] | 877 | 547-a | Respondida pela 547: um `var` de módulo sem anotação é ETS no BEAM; o build um defeito |
| [ ] | 878 | 543-a | Cranelift com o cache; SIGINT / cancel do LSP interrompem um build |
| [ ] | 879 | 164-s3-g | `String.slice` como corpos botopink no P1 |
| [ ] | 880 | 164-s3-m | Uma folha de `Bytes` dá trap fora do seu domínio |
| [ ] | 881 | docs-b | Um decorator da std importado como folha é anotado pelo seu nome |
| [ ] | 882 | docs-c | Os helpers de teste de uma biblioteca são o seu módulo `testing/`; nenhum membro `-test` |
| [ ] | 883 | as correções de texto da auditoria | Oito frases velhas das 814–882 corrigidas (o armazenamento da 824, o teste wasm da 823 já construído, o exemplo da 866, os marcadores da 871, a dica da 847, `RAKUN_SSR_KEY`, a citação da 852, a 869) |
| [ ] | 884 | ctr-all-place | `use all` roda a entrada `i` em `Place.index(i)`, sem nunca substituir uma chave |
| [ ] | 885 | ctr-embed-resolved | Um `Asset` dobrado imprime `Asset(Link(path: …))`, bytes dobrados `bytes.fromHex(…)`; `bytes` ganha `fromHex` / `toHex` |
| [ ] | 886 | ctr-private-through-contract | O método de um tipo atende um bloco de extensão de outro módulo só se for `pub` |
| [ ] | 887 | ctr-no-pub-spelling | Um membro que `addMember` acrescenta é `pub`; `pub val length: i32;` |
| [ ] | 888 | ctr-lambda-arity | Uma lambda não tipada pode omitir parâmetros finais do tipo esperado |
| [ ] | 889 | 548-b, os nomes da 862 | Os nomes da 862 confirmados (`stylesheet()`, `SsrConfig`, `/_rakun-ssr/`…); exemplos do `rakun-bpp` sem prefixo; `emilia.bp`, os tipos do bundler e o `onze` do `rakun-cli` acrescentados |
| [ ] | 890 | B-27-e, o alcance da 853 | Dois módulos que viram o mesmo átomo recusados em todo alvo |
| [ ] | 891 | a pergunta aberta da 884 | O renderer do rakun-bpp passa `Place.index(i)` a uma lista de filhos; um índice nunca toca a contagem de um corpo nem uma chave |
| [ ] | 892 | a varredura de formas retiradas | Linhas 751–879 lidas nas suas substituições; o texto vigente, as caixas abertas e o retired.md reescritos |
| [ ] | 894 | 859-a | O `.d.ts` declara, além dos métodos `pub`, o método sem `pub` que implementa um membro de um behavior do `implement` do próprio tipo |
| [ ] | 895 | b162-lambda-underscore | `_` é um parâmetro de lambda que não liga nada, quantas vezes for escrito, baixado como um parâmetro sem nome |
| [ ] | 896 | b162-close-child | `close()` fora de uma raiz falha `scope-not-root`; um segundo `close()` numa raiz fechada não faz nada |
| [ ] | 897 | b162-detached-reuse | Uma raiz destacada é uma semente: sua árvore nasce por processo leitor, suas células falham `scope-closed` depois do `close()` desse processo, a semente recomeça, nenhuma entrada fica |
| [ ] | 899 | B-115-a | No commonJS uma chamada a uma fn genérica com corpo, não host, de outro módulo passa-lhe as formas de impressão, só pela assinatura do chamado |
| [ ] | 900 | B-115-b | Um valor de tipo genérico carrega as formas dos seus argumentos de tipo (`__bp_s`), postas pelo construtor genérico e lidas pelos seus métodos; `print(d)` imprime igual |
| [ ] | 901 | 878-a | Como construído: o primeiro SIGINT interrompe o corpo comptime, um segundo encerra o processo |
| [ ] | 902 | 798-f | Como construído: `// from <template>`, `// from comptime`, `// from comptime { … }` com file:line |
| [ ] | 903 | 547-b | Recomendação (b) revertida: o `x = f(x)` de um var `PersistentTerm` é atômico sob um lock por `var` do runtime; nenhuma escrita perdida em nenhuma guarda |
| [ ] | 904 | 789-b | As linhas `build` de um pacote recusado vêm primeiro, depois os registros da recusa; `build` depois de `refused` é malformado; emenda a lista de 789 (1) |
| [ ] | 905 | 547-c | O código é `module-var-holds-async` (`task` foi aposentado por 732), o alcance como construído |
| [ ] | 906 | 790-b | `env` como construído (`NAME=value`, entrada malformada `Error(Other)`); fora do commonJS `start` é recusado na chamada, `std-unsupported-on-target`, no erlang e beam como no wasm (518 (4), 67) |
| [ ] | 907 | 841-a | O uso decide: `#[f]` aplica uma função com `syntax` primeiro como decorator, `f(e)` a expande; `isSyntaxExprFn` sai; uma função `syntax` vive em `src/comptime/` quando B-69 pousar |
| [ ] | 908 | b162-render-library | As sete células com `render(c, scope)` reescritas para que os filhos resolvam dentro do corpo que provê; respostas mantidas; linha process |
| [ ] | 909 | 848-a | Como construído: o campo do wrapper `value`, seu `section` a seção envolvente, entradas de topo primeiro, depois o wrapper de cada seção, folhas e subseções em ordem de fonte |
| [ ] | 910 | s23-c | superada por 576 e 840: uma declaração alcançada é um handle opaco, sem `value`, meta lida tipada |
| [ ] | 911 | 14s8-c | um buraco de template conhecido no build cuja dobra lança é recusado no buraco, nunca adiado para o render (o (a) do mantenedor, numerado) |
| [ ] | 912 | 14s8-e | `use` só sob o marcador `component`, um hook é uma `component fn`, um `comptime` que alcança um `use` é recusado no `comptime` (a resposta do mantenedor, reescrita sob 722/809/825) |
| [ ] | 913 | 97-s16-a | `unicode_tables.bp` o irmão plano até B-75, depois `src/internal/`; um import do `internal/` do std recusado |
| [ ] | 914 | nat-d9 | a única grafia pública do `query` sobre um array é a gramática; os métodos LINQ de `Query<T>` e `of` viram alvos privados do lowering |
| [ ] | 915 | ctr-p | `std-a` confirmada, `03r-e` cai: um componente malformado ou com caractere de controle é recusado, nunca mantido como escrito; os leitores do rakun vão com 196 |
| [ ] | 916 | 396-a (onze-content) | `toElementWith(doc, render: fn(node: MdNode, kids: NodeChildren) -> ?NodeChild)`, `null` mantém o elemento padrão |
| [ ] | 917 | 07-g | (b): um pacote `rakun-release` do workspace rakun, sem repositório `botopink/release` (o exemplo de 326 emendado) — uma escolha de produto a confirmar |
| [ ] | 918 | 01-compiler (28), 24-c, 23-b | tabela confirmada; ck2-e, 139-b, 388-b/c/d/e, s29-c superadas; lem-b `inline: true` em método de tipo recusado; lem-d o `regex.matches` livre sai; cep-c testes ambíguos de record comptime recusados |
| [ ] | 919 | 02-std-and-packaging (10), 24-g, std-c | tabela confirmada; 95-a/95-c superadas por 724/882; 95-b revertida (um membro só estreita); std-c: import de pasta recusado nomeando a folha com B-69 |
| [ ] | 920 | Escolhas feitas pelas threads do 00-gate (5) | 111-b, 113-a confirmadas (nomes emendados); 113-b revertida: a auditoria casa o id `host-binding-missing`; 110-b, 112-a sem objeto |
| [ ] | 921 | 03-bundled-libs (4) | as quatro do `log` confirmadas; `fileSink` responde `Error`, nunca lança; `@print` lê-se `terminal.print` |
| [ ] | 922 | Escolhas feitas pela thread bugs-sweep (4) | bs-a, bs-b confirmadas; bs-c: 510 alcança os testes de snapshot do compiler-core, o cache de saída de runtime sai; bs-d sem objeto |
| [ ] | 923 | 03r-q | o roteamento de locale fica em `rakun-app/src/i18n.bp`; sem membro `rakun-i18n`; o subconjunto BCP 47 é do `i18n` |
| [ ] | 924 | nat-d6 | Os sinais de navegação são dados: `notFound()` / `redirect(url)` respondem um `Component<Element>` cujo nó é `NavSignal(outcome: NavOutcome)`, lido pelo renderer; sem raise, sem string `nav:`, sem `noreturn` (527 (5), 554) |
| [ ] | 925 | nat-d7 | O ciclo de vida de um componente por dois behaviors, o `Startable` do rakun e o `Closeable` do std, o container testando `is` em tempo de execução; `#[postConstruct]` / `#[preDestroy]` removidos |
| [ ] | 926 | nat-d8 | `use actionState(createPost, initial)`; uma declaração que responde `Component` chamada `use<Maiúscula>…` recusada, `hook-name-use-prefix` |
| [ ] | 927 | nat-f2 | As seis chaves de `rakun-ssr.json` lidas no build num único record tipado `SsrConfig`, toda chave ou valor errado recusado nomeando o caminho da chave |
| [ ] | 928 | nat-f4 | `#[publicEnv]` no `val` que lê a variável; o prefixo `RAKUN_SSR_PUBLIC_` removido; um `env.read` sem marca num componente `#[client]` recusado |
| [ ] | 929 | lg2-l | `noreturn` é o tipo bottom como construído; um corpo `-> noreturn` que pode terminar é recusado, `noreturn-falls-through` (sobrepõe a (1) da entrada) |
| [ ] | 930 | lg2-n | Superada por 804 (4) / 809 (7): sem coerção de thunk, um filho adiado é um valor de componente |
| [ ] | 931 | lg2-s | Sem reflexão do grafo de módulos; `importsOf` continua um scan textual que falha alto; o grafo, quando preciso, uma saída da CLI `botopink` |
| [ ] | 932 | 07-b | O "duas ou mais bibliotecas" da 115 continua o único teste para um pacote |
| [ ] | 933 | erk-b | O `#[documentRepository]` do `rakun-data` num behavior com anotações template `` #[documentQuery @`…`] ``, os holes `${name}` ligados aos parâmetros |
| [ ] | 934 | 03r-ab, ctr-w | Os quatro braços da 150 s17 confirmados, os protocolos binários recusados nomeando o driver; o braço Elasticsearch pelo `rkRegisterHttpClient` do core que o `rakun-restclient` preenche — sem aresta entre membros |
| [ ] | 935 | 03r-af | Os sete exemplos não construídos aposentados; cada diretório de `examples/` ganha um `README.md` |
| [ ] | 936 | 03r-ak | O SBOM validado pelo Ajv vendorizado da 399 no teste, não por um walker de schema escrito à mão |
| [ ] | 937 | 03r-al | O relay do outbox por `withProducerTransaction` no broker em processo; o broker real uma linha de `deferred.md` |
| [ ] | 938 | 03r-am | Os doubles no módulo `testing/` do `rakun` pelos hooks do core; nada a medir |
| [ ] | 939 | 03r-an | Um registro de transporte no core chaveado por `enum Transport`; o `rakun-websocket` registra `.WebSocket`; sem aresta `rakun-messaging → rakun-websocket` |
| [ ] | 940 | 67-a | `fake_dom.mjs` ganha formulários; as cinco caixas afirmadas no `rakun-bpp-dom-test` agora e de novo na execução em navegador do ssr |
| [ ] | 941 | 49-g | `Json.isString()` ao lado de `isObject`, no `json.bp` do std até a 151 s1; o próprio do rakun-ssr apagado |
| [ ] | 942 | 51-a | Um inteiro malformado no módulo og é recusado — `parseMetrics` responde um `Result`, `gradientOf` o seu valor de não-gradiente |
| [ ] | 943 | atm-c | Qualquer `T` num átomo; o conjunto de leituras de uma ilha checado no build; um átomo não codificável que uma ilha lê tem de ser `#[clientOnly]` |
| [ ] | 944 | atm-d | Nenhum efeito de átomo no primeiro corte; efeitos um passo posterior depois de uma necessidade medida |
| [ ] | 945 | 141-a | O commit da decisão que aposenta reescreve a forma antiga nos specs atuais e adiciona a sua linha em `retired.md`; sem check com allow-list no `land-check.py` |
| [ ] | 946 | 07-i | A proibição de um pacote embutido exportar um nome que o std ou um framework exporta é regra permanente |
| [ ] | 947 | ctr-l | A terceira recusa da 186 removida — nenhuma página se declara pré-renderizada sob a 202 |
| [ ] | 948 | ctr-v | Um carve-out só de comentários é do passo dono; a org-3 não sequencia mais nada agora que 118, 33, 34 são passos de uma frente |
| [ ] | 949 | ctr-x | 337 (2), (3) superadas pela 592 (1); a 337 mantém (1) e (4) |
| [x] | 950 | ctr-af | Revertida pelo mantenedor (956): o laço é o da 105, `for xs { x -> … }` / `for (a, b) { x, y -> … }`; `for x in xs` recusado |
| [ ] | 951 | ctr-ag | Um `?T` é casado por `null` e `_`, o valor lido `x!`; o braço ligador da 54 recusado (602 inteira) |
| [ ] | 952 | 03r-a, 03r-c, 03r-e, 03r-f, 03r-g, 03r-h, 03r-i, 03r-j, 03r-k, 03r-l, 03r-m, 03r-n, 03r-p, 03r-r, 03r-s, 03r-t, 03r-u, 03r-v, 03r-w, 03r-x (04-rakun) | As 21 escolhas da trilha 04 valem como construídas sob os nomes dos pacotes; 03r-a (todo manifesto erlang), 03r-e (um componente mantido como escrito) e 03r-r (starters) superadas por 724 / 762, 196 e 724; 03r-c, 03r-h, 03r-i, 03r-l, 03r-s, 03r-t, 03r-v emendadas para 299, 281 / 714, as camadas de 724, 318 (5), § library-split e 312 / 397 / 398. |
| [ ] | 953 | 26-a (jhonstart), 29-a, 30-b, 30-c, 30-d, 30-e, 30-f, 30-g, 31-a (05-jhonstart) | As nove escolhas da trilha 05 valem sob `rakun-bpp`; 29-a reduzida a `registerRouteStarters`; o `payload` de 30-b responde `?#(string, Json)`; `compose` recebe a página como valor de componente e `Suspense` é um nó da árvore (504, 414); a assinatura de 31-a é a de `nat-d6` / `lg2-l`. |
| [ ] | 954 | 05emilia-a, 05emilia-b, 05emilia-c, 05emilia-d, 05emilia-f, 05emilia-g, 05emilia-i, 05emilia-j, 05emilia-k (06-emilia) | As nove escolhas da trilha 06 valem sob `rakun-stylesheet`: cada uma é a saída do Tailwind 4.3.2 (350) e se mantém como o texto do literal através de 150 s52; os nomes `--tw-*` são CSS, fora de 862. |
| [ ] | 955 | 49-a, 49-c, 49-e, 50-a, 52-a, 53-a, 68-a, 68-d, 69-a (07-onze) | As nove escolhas da trilha 07 valem sob os nomes de `rakun-ssr`; 49-a escreve pelo `snap`; o `start` de 50-a lança o nó com `forwardSignals()` e executa o `bin/rakun-ssr` da release quando existe; a sonda de 68-d (`stylesheet-hash-split` / `-unevaluated`) vale até os tokens da anotação de tag serem comptime. |

## Bloqueando agora — prioridade máxima (máquina 2, 2026-10-15)

Nenhuma aberta: cada entrada foi respondida por 899–955 (2026-10-21), decidida pelo fable por delegação do mantenedor e listada em § Para revisar.

## Máquina 2 — prioridade máxima (frente 144, `machine-2/144-backends-tooling/`)

#### 810-d · `!(v is A)` e `v is A && …` estreitam `v`? (decisão 810 (2); 144 B-162, B-155)

- **Medido.** 810 (2): dentro de `if (v is A)` `v` é `A`; no seu `else`, e depois dele quando o ramo sai, `v` é sua união sem `A`.
  Não nomeia nem um teste negado nem `&&`. No `feat` (5a9e86add), todo alvo recusa tanto `if (!(k is A)) { return; } k.tag` quanto
  `if (k is A && k.tag == 7)` — "cannot read a field of a `A | B` — not every member of the union answers it".
- **Opções.** (a) os dois estreitam: `!(v is A)` troca os tipos dos dois ramos (depois de `if (!(v is A)) return`, `v` é `A`), e a direita de
  `v is A && …` vê `v` como `A` (como o corpo do `if`); `||` o dual; (b) só as formas que a 810 (2) nomeia, as outras recusadas como hoje.
- **Recomendação.** (a): é o mesmo fluxo que a 810 (2) afirma, lido pelos dois operadores pelos quais todo leitor espera lê-lo.
- **Bloqueia.** uma linha do checker (máquina 1, B-162) e a linha de estreitamento do wasm da B-155.

## Bloqueando agora — máquina 1 e frente 165 (2026-10-15)

Nenhuma aberta: cada entrada foi respondida por 899–955 (2026-10-21), decidida pelo fable por delegação do mantenedor e listada em § Para revisar.

## Máquina 1 — prioridade máxima (frente 144, `machine-1/144-checker/`)

Nenhuma aberta: cada entrada foi respondida por 899–955 (2026-10-21), decidida pelo fable por delegação do mantenedor e listada em § Para revisar.

#### b162-place-repeat · Um valor carimbado rodado duas vezes entre irmãos
- **Medido.** O `context.bp` do B-162 falha `key-duplicate` só quando a metade de item de um lugar é uma chave. Um lugar numerado pelo corpo ou simples
  encontrado duas vezes numa renderização de um pai (`val h = Header(); div([h, h])`, ou `use h` duas vezes) reusa uma célula. O título de 819 (5) diz
  "um lugar repetido entre irmãos falha", mas sua cláusula nomeia só "dois valores de uma chamada com uma chave"; 820 (1) faz de um valor
  um lugar.
- **Opções.** (a) As duas execuções compartilham uma célula (construído). (b) Qualquer lugar encontrado duas vezes numa renderização de um pai falha em run time
  (`place-duplicate`, ou `key-duplicate` lido pelo título de 819 (5)). (c) A segunda execução pega uma célula nova, descartada na próxima renderização.
- **Recomendação.** (b): 817 (1) mantém uma célula por lugar, e dois corpos escrevendo um slot numa renderização é o aliasing de que 819 (5)
  protege as chaves. Um programa que quer duas instâncias escreve a chamada duas vezes, ou uma chave.
- **Bloqueia.** Nada; construído como (a).

#### b162-all-outside-use · `all(cs)` e `memo(f)` usados fora de um operando de `use`
- **Medido.** O `context-hook-without-use` da 354 é emitido só para `provide`, `context` e `inject`. `all(cs)` ou `memo(f)` fora de um
  `use` passa no checker como um valor `Component` cujo corpo dá panic quando roda. O "como provide, context e inject são" de 827 (1) descreve o
  lowering, não a recusa.
- **Opções.** (a) Recusados no check como aqueles três: o código da 354 se estende a todo hook baixado onde é `use`ado (`memo`, `all`).
  (b) Um valor cujo corpo dá panic quando roda (construído). (c) O std implementa os corpos, então o valor roda.
- **Recomendação.** (a): o checker sabe disso estaticamente, como sabe dos três; recusar > aceitar.
- **Bloqueia.** Nada; construído como (b).

#### b162-key-outside-body · `#[key(k)] x` escrito fora de toda função
- **Medido.** Fora de todo corpo o lowering escreve a chave com o número de chamada 0. 820 (3) diz que um valor feito fora de todo corpo
  não carrega carimbo, e 818 (3) faz da identidade de uma chave "a chamada e o valor da chave". Com a chamada 0, duas chamadas no nível do módulo com uma chave
  (`val xs = [#[key(1)] Item(1), #[key(1)] Card(1)]`) colidem e falham `key-duplicate` sob um runner; dentro de um corpo são dois lugares.
- **Opções.** (a) Chamada 0 mais a chave (construído). (b) Recusado no check, `key-outside-body`: uma chave é um carimbo (818 (3)), e 820 (3)
  não dá nenhum ali; a lista é chaveada onde é rodada (`use all(views.map({ v -> #[key(v.id)] v }))`). (c) A
  inicialização do módulo numerada como o corpo de uma função simples (821 (2)), emendando 820 (3) e 891 (1).
- **Recomendação.** (b): a menor mudança, e mantém 820 (3) inteira.
- **Bloqueia.** Nada; construído como (a).

#### b162-lowering-aliases · Os aliases `bp…__` do lowering e os helpers `pub` de contexto do std podem ser escritos por um programa
- **Medido.** `reserved_names.zig` reserva só `__bp_` e `Bp__`. O lowering de componentes importa `context.stamp`,
  `stampPlain`, `stampKeyed`, `memoIn`, `allIn`, `countNew`, `countEnd` do std (e os mais antigos `enter`, `provideIn`, `find`) como `bpStamp__`, …
  depois do check, e `context.bp` os declara `pub fn`. Então `import {context.stamp} from "std"; stamp(Item(p), scope, 7)` passa no checker
  e forja um número de chamada, contra 817 (1) ("nada fora do std decide a identidade") e 814 (2) ("sob um nome que nenhum fonte pode escrever").
- **Opções.** (a) Como construído. (b) Os aliases renomeados `__bp_stamp` …, então 805 (6) / 830 (3) os cobrem sem regra nova, e a
  referência de um programa aos nomes do std dos helpers recusada como `context-hook-without-use` recusa os hooks. (c) Os helpers privados ao módulo,
  alcançados pelo lowering pela marca de chamada da 830, como 814 (2) descreve para métodos.
- **Recomendação.** (c): um helper privado que só o lowering marcado alcança já é o mecanismo da 830, e os nomes continuam do std.
- **Bloqueia.** Nada.

#### 907-a · O código que um corpo devolve quando a função é aplicada como anotação
- **Medido.** 907 (2) diz "o retorno responde nada ou `T` igualmente" para uma função usada tanto como `#[f]` quanto como `f(e)`. Em `f(e)` um
  `code @`…`` devolvido é a expansão. Em `#[f]` nenhuma linha diz o que acontece com ele. Construído: na forma de decorator um
  `return <code>` no topo é descartado, e a função responde `void` ali.
- **Opções.** (a) Como construído: em `#[f]` o código devolvido é descartado. (b) Em `#[f]` o código devolvido é inserido depois da declaração
  anotada, como item do módulo. (c) Uma função cujo corpo devolve código é recusada em `#[f]`, localizada, nomeando a forma de chamada.
- **Recomendação.** (c): descartar em silêncio código escrito é a leitura de aceitar em vez de recusar, e (b) dá à anotação um segundo
  sentido que nenhuma decisão afirma.
- **Bloqueia.** Nada; construído como (a).

## Frente 165 — rakun-workspace (o mantenedor, 2026-10-14)

Nenhuma aberta: cada entrada foi respondida por 899–955 (2026-10-21), decidida pelo fable por delegação do mantenedor e listada em § Para revisar.

## Parte 1 — O que bloqueia as trilhas 00–03

Nenhuma aberta: cada entrada foi respondida por 899–955 (2026-10-21), decidida pelo fable por delegação do mantenedor e listada em § Para revisar.

## Parte 2 — O resto

Nenhuma aberta: cada entrada foi respondida por 899–955 (2026-10-21), decidida pelo fable por delegação do mantenedor e listada em § Para revisar.

## Parte 3 — Escolhas de implementação das trilhas 04–09

Nenhuma aberta: cada entrada foi respondida por 899–955 (2026-10-21), decidida pelo fable por delegação do mantenedor e listada em § Para revisar.
