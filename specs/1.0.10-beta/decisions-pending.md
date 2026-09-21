# Decisions the maintainer owes — 1.0.10-beta

**One open, 75** — re-shaped on 2026-09-20 by the maintainer's counter-request (*"implementar algo
parecido com o npm workspaces para bp no `repository/rakun/botopink.json`; faça uma contraproposta"*).
The eighteen others raised the same day (71–74, 76–89) were answered within the day and moved to
[`decisions-taken.md`](./decisions-taken.md) with their evidence. The next free number is **90**.

The shape every question uses — **Measured · Options · Recommendation · Blocks** — is the one 1.0.5
used; the recommendation defaults to the most restrictive behaviour and no configuration that bypasses
it (decision 67).

---

## 75. How `test-libs` and the dependency loader see `modules/**` and `examples/**` — a `workspaces` manifest, npm-style

**Raised by:** `02-packaging` ([`README.md`](./02-packaging/README.md) § Mechanism); re-shaped by the
maintainer on 2026-09-20, who asked for a counter-proposal modelled on npm workspaces.
**Measured.** `modules/lib-test-runner/src/discovery.zig` treats every *immediate* child of a lib root
holding `botopink.json` as a lib; `compiler-cli/src/cli/libs.zig:loadOne` uses the same roots and the
same immediate-child rule and ships only a dependency's `files`. So `modules/**` and `examples/**` are
invisible to the gate and to `from "rakun-web"` today, and rakun's 13 scaffolded manifests (`entry`,
no `files`) would give a consumer zero modules. npm solves the same problem with a `workspaces` array
in the root `package.json`: globs naming the member packages; the root is not itself installable; a
member's name is what other members import; tooling runs per member or across all.
**Options.**
(A) *roots by environment* — export `repository/*/modules` and `repository/*/examples` as extra roots
in `scripts/test-libs.sh`; umbrella manifest without `files`; `files` mandatory on every module. No
compiler change; the layout is known only to a shell script.
(B) *nested discovery* — `discovery.zig` and `libs.zig` recurse into `modules/` and `examples/`; a
carve-out of `00 · 10-cli-residuals`. The layout is hard-coded in the compiler.
(C) **`workspaces` in the umbrella manifest** — the counter-proposal:

```json
// repository/rakun/botopink.json — the umbrella: not a package, a workspace
{
  "name": "rakun-workspace",
  "workspaces": ["modules/*", "examples/*"],
  "targets": ["erlang", "commonJS"]
}
```

```json
// repository/rakun/modules/rakun-web/botopink.json — a member
{
  "name": "rakun-web",
  "src": "src/",
  "files": ["root.bp", "middleware.bp", "cors.bp"],
  "dependencies": { "rakun": { "workspace": true } }
}
```

```json
// repository/rakun/examples/rest-service/botopink.json — an example is a member too
{
  "name": "rest-service",
  "src": "src/",
  "dependencies": { "rakun": { "workspace": true }, "rakun-web": { "workspace": true } }
}
```

Rules of (C): a manifest with `workspaces` is a **workspace**, never a package — it has no `src`, no
`files`, no `entry`, and importing it (`from "rakun-workspace"`) is a located error; the globs expand
to directories that each hold a `botopink.json`, and a member's `name` is its import name (`from
"rakun-web"`); `{ "workspace": true }` resolves a dependency to the sibling member by name (the
counterpart of npm's `workspace:` protocol) and is the **only** way a member may depend on a sibling —
a `path` to a sibling is a located error, so the graph is always the workspace's own; `test-libs`
and `botopink test` run every member, examples included, and report per member; a member without
`files` ships nothing and fails its own tests loud; a member with a `name` that another root already
holds is a located error (today: first-root-wins, silent). Discovery: the runner and the loader both
gain one function — *read the umbrella, expand `workspaces`, treat each expansion as a lib root
entry* — instead of recursion (B) or environment (A); the layout is declared by the repository, not
known by the tool.
**Recommendation.** (C). It is (A)'s "no hard-coded layout" and (B)'s "the compiler resolves it"
with the one thing neither has: the repository *declares* its members, so a wrong tree is a
diagnostic instead of a silent zero-module dependency; `{ "workspace": true }` keeps the object form
of decision 76 and adds no second dependency spelling; and every refusal in it is structural, not a
knob. Cost: `discovery.zig` + `libs.zig` + `project_graph.zig` + `bpmp/manifest.zig` each learn
`workspaces` (one function, shared), `docs/botopink-json.md` documents it, and the thirteen rakun
manifests gain `files`. It stays a `00 · 10-cli-residuals` carve-out as (B) would.
**Blocks.** `02-packaging` step 1; the first `<lib>-test` submodule that a gate must run; every
`modules/*/botopink.json` and `examples/*/botopink.json`.
