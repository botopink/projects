<!--
Spec template. Copy to tasks/v0.beta.N/specs/<slug>.md and fill in.
A spec is INTENT, written before building, IMMUTABLE once written.
Remove these comments when done. See ../AGENTS.md for the rules.
-->

# <Feature> — <one-line summary>

**Slug**: <kebab-case>          <!-- derives branch task/<slug> + worktree .tasks/<slug>/ -->
**Depends on**: nothing          <!-- another <slug> already in feat, or "nothing" (default) -->
**Files**: <target source files> <!-- blast radius + parallel-collision detection -->
**Touches docs**: <AGENTS.md/docs.md to update on completion>
**Status**: pending              <!-- coarse only (pending|done); live state lives in status.md -->

## Target syntax

<!-- The final .bp form(s). Add a grammar block if introducing syntax. -->

```bp
<example of the feature in source>
```

## Examples

<!-- Concrete before/after that removes ambiguity about the intent. -->

### <case>
```bp
<input>
```
<what it lowers to / does>

## Steps

<!-- Build order, phased. Each checkbox becomes a line in .tasks/<slug>/TODO.md. -->

### F0 — <phase name>
- [ ] <step>
- [ ] <step>

### F1 — <phase name>
- [ ] <step>

## Test scenarios

<!-- The acceptance criteria: how you know it's done. One per snapshot/case. -->

```
<stage> ---- <scenario name>
<stage> ---- <scenario name>
```

## Notes

<!-- Scope boundaries, pitfalls, file collisions with other tasks, open points. -->

- <note>
