# Template de Spec — Botopink Lang

**Versão:** 2.0  
**Última atualização:** 2026-09-14

---

## Estrutura de um Spec

Cada spec deve seguir esta estrutura para garantir aprofundamento antes da implementação:

```
specs/1.0.0-beta/
├── 01-test-green/
│   ├── README.md                    ← Visão geral + métricas
│   ├── step-1-decorator-eval.md     ← Step detalhado
│   ├── step-2-allocation-leaks.md   ← Step detalhado
│   └── step-3-regression-tests.md   ← Step detalhado
```

---

## Template: README.md

```markdown
# Spec XX — [Nome do Spec]

**Status:** 🔴 in progress | 🟡 blocked | 🟢 completed  
**Priority:** 🔴 CRÍTICO | 🟡 ALTA | 🟢 MÉDIA  
**Objetivo:** [1-2 sentences]

---

## Estado atual

```
[Métricas atuais]
```

### Problemas identificados

| Categoria | Quantidade | Arquivo |
|-----------|------------|---------|
| [categoria] | [n] | [arquivo] |

---

## Steps

| # | Step | Status | Bloqueia |
|---|------|--------|----------|
| 1 | [Link para step](./step-X.md) | ⏳ pending | [o que bloqueia] |

---

## Ordem de execução

```
Step 1 ← CRÍTICO
  └─► Step 2
       └─► Step 3
```

---

## Métricas de sucesso

| Métrica | Antes | Depois |
|---------|-------|--------|
| [métrica] | [valor] | [valor] |

---

## Arquivos relevantes

| Arquivo | Papel |
|---------|-------|
| [arquivo] | [papel] |
```

---

## Template: Step detalhado

```markdown
# Step X — [Nome do Step]

**Status:** ⏳ pending | 🔍 investigating | 🛠 implementing | ✅ completed  
**Priority:** 🔴 CRÍTICO | 🟡 ALTA | 🟢 MÉDIA  
**Estimativa:** [X-Y horas]  
**Depende de:** [Step anterior se houver]

---

## 🎯 Objetivo

[1-2 sentences sobre o que este step resolve]

---

## 🔍 Fase 1: Aprofundamento (Discovery)

### Problema

[Descrição detalhada do problema]

### Sintomas

```
[Output de erro, logs, ou comportamento observado]
```

### Testes afetados

| # | Teste | Linha | Complexidade |
|---|-------|-------|--------------|
| 1 | [nome] | [linha] | [Baixa/Média/Alta] |

### Causa raiz (hipótese inicial)

[Análise do código relevante]

**Arquivo: [arquivo:linha]**
```zig
[Código relevante]
```

**Problema identificado:**
[Explicação do que está errado]

### Investigação necessária

Antes de implementar, precisamos:

1. [ ] [Ler arquivo X para entender Y]
2. [ ] [Verificar se Z é público/privado]
3. [ ] [Testar hipótese com exemplo mínimo]
4. [ ] [Consultar documentação de W]

### Exemplos concretos

**Exemplo 1: [caso simples]**
```botopink
[Código que deve funcionar]
```
**Esperado:** [comportamento]

**Exemplo 2: [caso complexo]**
```botopink
[Código que deve funcionar]
```
**Esperado:** [comportamento]

---

## 🛠 Fase 2: Implementação

### Solução proposta

**Opção A (recomendada):** [descrição]
**Opção B:** [descrição alternativa]

#### Por que Opção A?

- [Vantagem 1]
- [Vantagem 2]
- [Trade-off aceito]

### Arquivos a modificar

| Arquivo | Ação | Linhas estimadas |
|---------|------|------------------|
| [arquivo] | [criar/modificar] | [~N] |

### Código esperado

```zig
[Snippet do que será implementado]
```

### Passo a passo

1. [Primeiro passo concreto]
2. [Segundo passo]
3. [Terceiro passo]

---

## ✅ Fase 3: Validação

### Testes de aceitação

#### Teste 1: [nome]

```botopink
[Código de teste]
```

**Esperado:** [resultado]

#### Teste 2: [nome]

```botopink
[Código de teste]
```

**Esperado:** [resultado]

### Comandos de verificação

```bash
# Rodar testes específicos
zig build test --test-filter "[filtro]"

# Rodar suite completa
zig build test

# Verificar métricas
[comando específico]
```

### Checklist de conclusão

- [ ] [Item 1]
- [ ] [Item 2]
- [ ] [Item 3]
- [ ] `zig build test` passa
- [ ] Sem regressões

---

## ⚠️ Riscos e mitigação

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| [risco] | [Baixa/Média/Alta] | [Baixo/Médio/Alto] | [mitigação] |

---

## 📚 Referências

- [Link para código relevante]
- [Link para documentação]
- [Link para issue/discussão]
```

---

## Fluxo de trabalho recomendado

### 1. Criar spec com fase de aprofundamento

```bash
# Criar diretório
mkdir -p specs/1.0.0-beta/XX-nome-spec

# Criar README
touch specs/1.0.0-beta/XX-nome-spec/README.md

# Criar steps
touch specs/1.0.0-beta/XX-nome-spec/step-1-nome.md
touch specs/1.0.0-beta/XX-nome-spec/step-2-nome.md
```

### 2. Completar fase de aprofundamento (Discovery)

**Antes de escrever qualquer código:**

1. **Ler código relevante**
   ```bash
   # Ler arquivos mencionados
   view modules/compiler-core/src/[arquivo]
   ```

2. **Rodar testes para ver estado atual**
   ```bash
   cd modules/compiler-core
   zig build test 2>&1 | grep -E "(error|fail)" | head -20
   ```

3. **Identificar causa raiz exata**
   - Onde está o bug?
   - Por que acontece?
   - Quais constructs estão envolvidos?

4. **Criar exemplos mínimos**
   - Código que falha
   - Código que deve funcionar
   - Casos edge

5. **Explorar alternativas**
   - Opção A: [prós/contras]
   - Opção B: [prós/contras]
   - Qual escolher e por quê?

6. **Atualizar spec com findings**
   - Preencher "Causa raiz"
   - Preencher "Exemplos concretos"
   - Preencher "Solução proposta"

### 3. Revisar spec antes de implementar

**Checklist de revisão:**

- [ ] Causa raiz está clara e documentada?
- [ ] Exemplos concretos foram testados?
- [ ] Solução proposta é viável?
- [ ] Arquivos a modificar estão identificados?
- [ ] Testes de aceitação estão definidos?
- [ ] Riscos foram considerados?

### 4. Implementar

```bash
# Rodar testes antes
zig build test 2>&1 | tail -5

# Implementar mudanças
edit modules/compiler-core/src/[arquivo]

# Rodar testes depois
zig build test 2>&1 | tail -5
```

### 5. Validar

```bash
# Rodar suite completa
zig build test

# Verificar métricas
[comando específico]

# Verificar que não há regressões
zig build test 2>&1 | grep -E "(fail|error)"
```

---

## Exemplo de aprofundamento bem feito

### Problema

9 testes de decorator falham com "decorator evaluator failed to run"

### Investigação

1. **Ler `decorator_invocation.zig`**
   - Identificar quais testes falham
   - Ver padrões nos que falham vs passam

2. **Ler `decorator_eval.zig`**
   - Ver como `evaluateErl` está implementado
   - Identificar onde retorna `EvalFailed`

3. **Ler `template_eval.zig`**
   - Ver se `emitBpExpr` está público
   - Ver se suporta todos os constructs necessários

4. **Testar hipótese**
   ```zig
   // Criar exemplo mínimo que falha
   fn test(comptime decl: @Decl) {
       val msg = "Processing: " + decl.name;  // string concat
   }
   #[test]
   record Service { x: i32 }
   ```

5. **Identificar causa raiz**
   - `evaluateErl` não usa `emitBpExpr` de `template_eval.zig`
   - Ou `emitBpExpr` não suporta string concat

6. **Explorar soluções**
   - Opção A: Reutilizar `emitBpExpr` (recomendada)
   - Opção B: Implementar decompiler separado (não recomendada)

### Resultado

Spec atualizado com:
- Causa raiz clara
- Exemplos concretos
- Solução proposta
- Testes de aceitação
- Arquivos a modificar

---

## Anti-patterns a evitar

### ❌ Pular fase de aprofundamento

**Ruim:**
```markdown
## Problema
Testes falham.

## Solução
Consertar o código.
```

**Bom:**
```markdown
## Problema
9 testes falham com "decorator evaluator failed to run"

## Causa raiz
`evaluateErl` em `decorator_eval.zig:94` retorna `EvalFailed` porque:
1. Não usa `emitBpExpr` de `template_eval.zig`
2. `emitBpExpr` não suporta string concat

## Exemplos
[Código mínimo que falha]

## Solução
Reutilizar `emitBpExpr` em `evaluateErl`
```

### ❌ Não testar exemplos concretos

**Ruim:**
```markdown
## Solução
Adicionar suporte a string concat.
```

**Bom:**
```markdown
## Exemplo que deve funcionar
```botopink
fn test(comptime decl: @Decl) {
    val msg = "Processing: " + decl.name;
}
```
**Esperado:** Compila sem erros
```

### ❌ Não definir testes de aceitação

**Ruim:**
```markdown
## Checklist
- [ ] Testes passam
```

**Bom:**
```markdown
## Testes de aceitação

### Teste 1: String concat
```botopink
[Código]
```
**Esperado:** Compila sem erros

### Comandos de verificação
```bash
zig build test --test-filter "decorator"
# Esperado: 9/9 tests passed
```
```

---

## Resumo

**Antes de implementar:**
1. 🔍 **Aprofundar** — ler código, entender causa raiz, criar exemplos
2. 📝 **Documentar** — preencher spec com findings
3. ✅ **Revisar** — verificar que spec está completo
4. 🛠 **Implementar** — só agora escrever código
5. 🧪 **Validar** — rodar testes, verificar métricas

**Benefícios:**
- Menos retrabalho
- Soluções mais robustas
- Documentação útil para o futuro
- Onboarding mais fácil para novos contribuidores
