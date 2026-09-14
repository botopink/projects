# TODO — Step 3: Regression tests

**Branch:** `fix/step-3-regression-tests`  
**Commit base:** `8d88372` (feat atual com Step 4 concluído)  
**Objetivo:** Testes de regressão para garantir que fixes não regredam  
**Prioridade:** 🟢 MÉDIA  
**Depende de:** Step 1 e Step 2

---

## Estado atual (2026-09-14)

- ✅ **Step 4 (Interface Literal) CONCLUÍDO** e merged em `feat` (commit `8d88372`)
- ✅ Branches atualizadas (todos os worktrees no commit `8d88372`)
- ✅ **TESTES JÁ ESCRITOS** (commit `731963d` na feat)
- ❌ **TODOS OS 4 TESTES FALHANDO** (dependem do Step 1)
- ⏳ Validação final pendente (Step 1 + Step 2 completos)

---

## Testes criados

### Arquivo: `modules/compiler-core/src/comptime/tests/decorator_regression.zig`

| # | Teste | Status | Verifica |
|---|-------|--------|----------|
| 1 | `decorator regression: loop in body` | ❌ falha | Loops em decorator bodies |
| 2 | `decorator regression: conditional in body` | ❌ falha | Conditionals em decorator bodies |
| 3 | `decorator regression: string concat in body` | ❌ falha | String concatenation em decorator bodies |
| 4 | `decorator regression: @emit in body` | ❌ falha | @emit em decorator bodies |

**Erro atual (todos):**
```
error: the decorator evaluator failed to run
hint: Decorator bodies run in the node runtime at compile time
```

**Causa:** Step 1 não completo — decorator eval broken

---

## Checklist de implementação

### Pré-requisitos
- [ ] **Step 1 completo** — decorator eval funcionando
- [ ] **Step 2 completo** — 0 allocation leaks

### Validação
- [ ] `zig build test --test-filter "decorator regression"` → 4/4 pass
- [ ] `zig build test` → 168/168 pass (164 originais + 4 regression)
- [ ] `zig build test` → 0 leaks
- [ ] `zig fmt` nos arquivos (se necessário)

### Finalização
- [ ] Commit (se houver mudanças): `test: validate regression tests`
- [ ] Merge para `feat`
- [ ] Limpar worktrees (opcional)

---

## Estrutura dos testes

### Teste 1: Loop in body

```botopink
fn validate(comptime decl: @Decl) {
    decl.fields.forEach({ f ->
        if (f.name == "bad") { decl.fail("field 'bad' not allowed"); }
    });
}
#[validate]
record Good { name: string, age: i32 }
```

**Verifica:** Loops em decorator bodies funcionam

### Teste 2: Conditional in body

```botopink
fn conditional(comptime decl: @Decl) {
    if (decl.kind == DeclKind.Record) {
        if (decl.name == "Bad") { decl.fail("Bad not allowed"); }
    }
}
#[conditional]
record Good { x: i32 }
```

**Verifica:** Conditionals em decorator bodies funcionam

### Teste 3: String concat in body

```botopink
fn concat(comptime decl: @Decl) {
    val msg = "Processing: " + decl.name;
    @print(msg);
}
#[concat]
record Service { x: i32 }
```

**Verifica:** String concatenation em decorator bodies funciona

### Teste 4: @emit in body

```botopink
fn emit(comptime decl: @Decl) {
    @emit("pub val generated_" + decl.name + " = 42;");
}
#[emit]
record Service { x: i32 }
fn useit() -> i32 { return generated_Service; }
```

**Verifica:** @emit em decorator bodies funciona

---

## Arquivos criados

| Arquivo | Ação | Linhas |
|---------|------|--------|
| `decorator_regression.zig` | Criado (commit `731963d`) | ~102 |
| `tests.zig` | Modificado (adicionado import) | ~1 |

---

## Dependências

- **Depende de Step 1** — decorator eval funcionando
- **Depende de Step 2** — 0 allocation leaks
- **Bloqueia nada** — este é o último step da Spec 01

---

## Fluxo de merge

```bash
# Depois de Step 1 e Step 2 merged em feat
cd .tasks/step-3-regression-tests
git merge feat  # trazer Step 1 + Step 2
cd repository/botopink-lang
git merge feat  # atualizar submodule

# Validar
cd modules/compiler-core
zig build test --test-filter "decorator regression"  # 4/4 pass
zig build test  # 168/168 pass, 0 leaks

# Commit (se necessário)
cd ../../..
git add -A
git commit -m "test: validate regression tests"

# Merge para feat
cd /home/ericfillipe/develop/botopink-lang
git checkout feat
git merge fix/step-3-regression-tests
```

---

## Notas

- Testes já foram escritos e committed na feat (commit `731963d`)
- Worktree não tem trabalho adicional — só precisa validar
- Depois de validar, pode limpar worktrees (ver WORKTREES.md)
- Este step completa a Spec 01 — Test Green
