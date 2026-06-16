# TODO — frente-b (rules + tooling close)

> Worktree task: closes v0.beta.19 `frente-b-rules-tooling` partial — F4F/F4G/F4C/F4I-tail/F5/F6 + `break :label` 4 backends + §T `----- RUN LOG -----` per test.
>
> Spec: [`tasks/v0.beta.20/specs/frente-b.md`](tasks/v0.beta.20/specs/frente-b.md) — full content of all 3 sub-specs lives there.

## Baseline (from origin/feat after prim-op-template-fix merge)

- meta: `932256a` · bot-lang: `f57a8cd`
- **rules-tooling-close partials landed**: §1G generic-param defaults wired into TypeDef + infer (`3ed957c`) · F4I `Jump.@"break"` widened (`a9f1a6d`) + 4 call sites updated.

## Stage 01 — keystones (2, parallel)

- [ ] **rules-tooling-close** — F4F (`#[@future]` RF3/RF4) · F4G (default generics gates beyond §1G) · F4C (context body validation) · F4I tail (T2/T3 `@IteratorStep` transform rewrite) · F5 builtins.d.bp Iterator enum · F6 effect suites cross-pollination · **`fn-param-default-expansion` for `declare fn`** (parser must accept `param: type = expr` in `declare fn` signatures — currently blocked path; prim-op + ci-tail catalogs depend on it).
- [ ] **test-run-log** — §T `----- RUN LOG -----` per test on 4 backends (net-new tooling in `runtime/runlog.zig` + test-mode codegen wrappers).

## Stage 02 — consumers (1)

- [ ] **codegen-break-label** ← rules-tooling-close (F4I-T2/T3). `break :label` honors label on 4 backends; consumes the `@IteratorStep` transform.

## Coordination

- **prim-op overlap on `fn-param-default-expansion`**: prim-op spec lists this as one of its keystones (AST plumbing already landed). frente-b needs the **parser** half (accepting defaults in `declare fn` signatures). Pick the half that fits: prim-op owns the codegen consumption; frente-b owns the parser accept.
- **test-run-log + ci-tail**: ci-tail's snap normalisation (CRLF / path-sep) might need to consider RUN LOG output formatting. Coordinate via `snap.zig` PR review.

## Exit gate

Per spec — F4F/F4G/F4C/F4I/F5/F6 done; `break :label` honors label on commonJS + erlang + beam + wasm; `botopink test` emits `----- RUN LOG -----` per test on all 4 backends.
