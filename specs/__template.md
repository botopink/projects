# [SPEC NAME]

**Version:** 1.0.0-beta  
**Status:** planning  
**Priority:** [CRÍTICO | ALTA | MÉDIA | BAIXA]  
**Created:** [DATE]  
**Author:** [AUTHOR]  
**Depends on:** [Other specs or none]  
**Blocks:** [What this spec blocks]

---

## Status

> **planning** → **in progress** → **completed** / **cancelled**

**Current:** planning

| Step | Title | Status | Branch | Commit |
|------|-------|--------|--------|--------|
| Step 1 | [Step title] | pending | [branch-name] | - |

---

## Objective

[2-4 lines: what is achieved, what problem is solved.]

**Motivation:**
[Why is this needed? What problem does it solve?]

**Success criteria:**
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
- [ ] All tests pass

---

## Prerequisites

- [Dependencies, related specs, blocking conditions]
- [E.g.: Spec `X.md` completed]
- [E.g.: `zig build test` passing]
- [E.g.: Feature Y implemented]

---

## Implementation Plan

### Architecture

[High-level description of the approach. Which compiler layers are affected?]

**Layers affected:**
- [ ] Lexer (`lexer.zig`)
- [ ] Parser (`parser/`)
- [ ] AST (`ast.zig`)
- [ ] Type Inference (`comptime/infer.zig`)
- [ ] Codegen (`codegen/`)
- [ ] Formatter (`format.zig`)
- [ ] Runtime (`comptime/runtime/`)

### Implementation Steps

Statuses: **pending** | **open** (in progress) | **completed** | **cancelled**

#### Step 1 — [Step title]

**Status:** pending  
**Branch:** `[branch-name]`  
**Assignee:** [NAME]  
**Estimated time:** [X hours]

**What to do:**
1. [Action 1]
2. [Action 2]
3. [Action 3]

**Acceptance criteria:**
- [ ] [Objective condition 1]
- [ ] [Objective condition 2]
- [ ] Tests added and passing
- [ ] `zig build test` passes

**Files to modify:**

| File | Purpose |
|------|---------|
| `path/to/file.zig` | What changes |

**Tests to add:**

| Test file | Test name | What it verifies |
|-----------|-----------|------------------|
| `tests/file.zig` | `test name` | [Description] |

---

## Worktree Setup

```bash
# Create worktree for this spec
git worktree add .tasks/[spec-name] -b [branch-name]

# Initialize submodules
cd .tasks/[spec-name]
git submodule update --init --recursive

# Work on compiler-core
cd repository/botopink-lang/modules/compiler-core
```

---

## Testing Strategy

### Unit Tests

[What unit tests need to be added?]

| Layer | Test file | What to test |
|-------|-----------|--------------|
| Parser | `parser/tests/[file].zig` | [Description] |
| Inference | `comptime/tests/[file].zig` | [Description] |
| Codegen | `codegen/tests/[file].zig` | [Description] |
| Formatter | `format/tests/[file].zig` | [Description] |

### Integration Tests

[What integration tests verify the feature works end-to-end?]

### Regression Tests

[What existing tests might break? What regression tests should be added?]

---

## Metrics

| Metric | Before | After |
|--------|--------|-------|
| Tests passing | [X]/[Y] | [X]/[Y] |
| Tests failing | [N] | 0 |
| Code coverage | [X]% | [Y]% |
| [Other metric] | [Value] | [Value] |

---

## Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| [Risk description] | [Low/Med/High] | [Low/Med/High] | [How to mitigate] |

---

## Dependencies

### Blocks

- [What specs/steps does this block?]
- [E.g.: Step 1 depends on this spec]

### Blocked by

- [What specs/steps block this?]
- [E.g.: Requires Spec X to be completed]

---

## Notes

- [Design decisions]
- [Alternatives considered]
- [Trade-offs made]
- [Lessons learned]

---

## Changelog

| Date | Change | Author |
|------|--------|--------|
| [DATE] | Spec created | [NAME] |
| [DATE] | [What changed] | [NAME] |

---

## Working Memory

Create a `_memory.md` sibling file to track live thinking during spec execution — current state, open questions, hunches, next actions. This file is **not** committed (`.gitignore`-ed via `_memory.md`).

Two usage modes:

1. **Clean slate** — empty file; write whatever comes up while working.
2. **Spec snapshot** — copy the Steps table and current status from this spec into `_memory.md` as a checklist; tick off items, add per-step notes, keep the live state in one place.

Either way: update it liberally, delete it when the spec closes. Never commit it — it's transient scratch, not a design artifact.
