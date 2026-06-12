# botopink/projects · CHANGELOG

Workspace-level changes (submodule layout, root docs, scripts). Per-project
changelogs live inside each submodule.

## Unreleased

### Layout

- **Converted `repository/` libs to git submodules.** Each project under
  `repository/` (`vscode-extension`, `onze`, `jhonstart`, `erika`,
  `botopink-lang`, `rakun`) is now its own GitHub repo at
  `git@github.com:botopink/<name>.git`, mounted here via `.gitmodules` and
  tracking the `feat` branch.
- Renamed the meta-repository remote to
  `git@github.com:botopink/projects.git`.
- Added root docs: `AGENTS.md`, `README.md`, `docs.md`, `CHANGELOG.md`.
- Added `.gitignore` for `.zig-cache`, `zig-out`, `.botopinkbuild` inside the
  `botopink-lang` submodule.

### Migration notes

After pulling this commit, contributors must initialise the submodules:

```bash
git submodule update --init --recursive
```

To pull the latest tip of every submodule's `feat`:

```bash
git submodule update --remote --merge
```
