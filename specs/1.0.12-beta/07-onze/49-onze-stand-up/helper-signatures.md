# `onze-test` helper signatures

Front 49 owns `onze-test/src/root.bp`, `core.bp` and `fixtures.bp` (they exist) and stubs the group
files (README step 6). The other groups of the 1.0.10 map
([`06-onze/test-snap.md`](../../../1.0.10-beta/06-onze/test-snap.md) § Helper signatures) — `cli`,
`bundler`, `assets`, `og`, `release` — are the snapshot layer: → 20-snap (front 135) step 5. Under
`snap-a` (a) none of them is written, `e2e` holds the five harness functions, and `assertAlias`
goes with decision 218 (`50` step 9).

## Helper signatures (`modules/onze-test/src/`)

```bp
pub type SourceLocation(file: string, line: i32, column: i32, fnName: string)

// core — 49 (on feat)
pub fn assertConfig(loc: SourceLocation, botopinkJson: string, onzeJson: string) -> @Result<void, string>
pub fn assertAppFiles(loc: SourceLocation, paths: string[]) -> @Result<void, string>
pub fn assertAlias(loc: SourceLocation, aliasJson: string, specs: string[]) -> @Result<void, string>
pub fn assertPublicEnv(loc: SourceLocation, env: Array<#(string, string)>, names: string[]) -> @Result<void, string>
```

Every helper renders its subject to one canonical text, compares it with the `.snap`, and on
mismatch writes `<path>.new` and returns `Err("<path> differs; wrote <path>.new")`.
