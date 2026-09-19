# Front 19 — Onze13 CLI

**Referência Next.js:** [create-next-app](https://nextjs.org/docs/app/api-reference/cli/create-next-app) · [Next.js CLI](https://nextjs.org/docs/app/api-reference/cli/next)

**Priority:** medium — CLI provides create-app, dev server, build, start commands
**Depends on:** F01 (onze13-stand-up)
**Owns:** `repository/onze13/modules/onze13-cli/src/**`
**Does not touch:** `onze13/src/**`, any other repos

---

## Problem

Developers need a CLI to create new onze13 apps, run the dev server, build for production, and start the production server. Analogous to `create-next-app` and `next dev/build/start`.

## Current state

- No onze13 CLI exists
- botopink has `bpmp` for package management
- No project scaffolding tool

## Mechanism

Create `onze13-cli` as a submodule of onze13:
- `onze13 create my-app` — scaffold a new app
- `onze13 dev` — start dev server with hot reload
- `onze13 build` — build for production
- `onze13 start` — start production server

## Exemplos em bp

### Criando um projeto

```bash
onze13 create my-app
cd my-app
onze13 dev
```

### page.bp gerado

```bp
// app/page.bp
pub fn HomePage() -> Element {
    return div([
        h1([text("Bem-vindo ao onze13!")], attrs: [
            #("class", emilia([.Text.Size.X4xl, .Text.Bold])),
        ]),
    ], attrs: [#("class", emilia([.Pad.All.8]))]);
}
```

## Steps

### Step 1 — CLI structure

```
modules/onze13-cli/
├── botopink.json
├── src/
│   ├── root.bp
│   ├── main.bp          # CLI entry point
│   ├── create.bp        # create command
│   ├── dev.bp           # dev command
│   ├── build.bp         # build command
│   └── start.bp         # start command
└── test/
    └── cli_test.bp
```

**Acceptance:**
- [ ] CLI module structure created
- [ ] `botopink.json` declares the module

### Step 2 — create command

```bp
// src/create.bp
pub fn create(appName: string) {
    // Create directory structure
    // Scaffold app/ directory with layout.bp, page.bp
    // Create botopink.json with dependencies
    // Create onze13.json config
}
```

**Acceptance:**
- [ ] `onze13 create my-app` creates directory
- [ ] Scaffolds basic app structure
- [ ] Installs dependencies (jhonstart, rakun, emilia, onze13)

### Step 3 — dev command

```bp
// src/dev.bp
pub fn dev() {
    // Start botopink dev server
    // Watch for file changes
    // Hot reload on changes
}
```

**Acceptance:**
- [ ] `onze13 dev` starts dev server
- [ ] Watches for file changes
- [ ] Hot reloads on changes

### Step 4 — build command

```bp
// src/build.bp
pub fn build() {
    // Run botopink build
    // Optimize for production
    // Generate .onze13/ output directory
}
```

**Acceptance:**
- [ ] `onze13 build` builds for production
- [ ] Output in `.onze13/` directory
- [ ] Optimized bundle

### Step 5 — start command

```bp
// src/start.bp
pub fn start() {
    // Start production server
    // Load .onze13/ build
}
```

**Acceptance:**
- [ ] `onze13 start` starts production server
- [ ] Serves the built app

### Step 6 — Tests

```bp
test "create command scaffolds app" {
    // Mock file system
    // Verify directory structure created
}
```

**Acceptance:**
- [ ] Tests pass

## Gate

- [ ] `botopink test` green
- [ ] CLI commands work end-to-end
- [ ] AGENTS.md updated
- [ ] Commit on `fix/onze13-cli`

## Blast radius

- New module `onze13-cli`
- No changes to existing onze13 core
- Developers can use CLI to create and run apps

## Notes

- The CLI wraps botopink commands — it doesn't replace them.
- `onze13 dev` is `botopink dev` + file watching + hot reload.
- `onze13 build` is `botopink build` + optimization.
- Future: integrate with `bpmp` for dependency management.
