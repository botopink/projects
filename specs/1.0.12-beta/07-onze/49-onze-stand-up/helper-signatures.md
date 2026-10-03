# `onze-test` helper signatures — the 1.0.10 map, `06-onze/test-snap.md` § Helper signatures. Front 49 owns `onze-test/src/root.bp`; each front fills the group file it owns (README step 6 stubs them). `core` and `fixtures` exist; the other groups are the open half.

## Helper signatures (`modules/onze-test/src/`)

```bp
pub type SourceLocation(file: string, line: i32, column: i32, fnName: string)

// core — 49
pub fn assertConfig(loc: SourceLocation, botopinkJson: string, onzeJson: string) -> @Result<void, string>
pub fn assertAppFiles(loc: SourceLocation, paths: string[]) -> @Result<void, string>
pub fn assertAlias(loc: SourceLocation, aliasJson: string, specs: string[]) -> @Result<void, string>
pub fn assertPublicEnv(loc: SourceLocation, env: Array<#(string, string)>, names: string[]) -> @Result<void, string>

// cli — 50
pub fn assertScan(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertGeneratedTree(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertTreeCheck(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertScaffold(loc: SourceLocation, args: string) -> @Result<void, string>
pub fn assertBuildOutput(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertDevServer(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertInfo(loc: SourceLocation, cwd: string) -> @Result<void, string>

// bundler — 68
pub fn assertGraph(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertRefusal(loc: SourceLocation, tree: string, config: string) -> @Result<void, string>
pub fn assertChunks(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertManifest(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertScriptTags(loc: SourceLocation, tree: string, route: string) -> @Result<void, string>
pub fn assertEntry(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertScriptPlan(loc: SourceLocation, decls: ScriptDecl[]) -> @Result<void, string>

// assets — 69 · 51 · 52
pub fn assertHead(loc: SourceLocation, links: Array<#(string, string)>, render: fn() -> Element) -> @Result<void, string>
pub fn assertStyleModule(loc: SourceLocation, path: string, css: string) -> @Result<void, string>
pub fn assertStylesheet(loc: SourceLocation, globalCss: string, modules: Array<#(string, string)>) -> @Result<void, string>
pub fn assertStaticRoots(loc: SourceLocation, publicDir: string, outDir: string, buildId: string) -> @Result<void, string>
pub fn assertImage(loc: SourceLocation, props: ImageProps, cfg: ImageConfig) -> @Result<void, string>
pub fn assertImageSource(loc: SourceLocation, cfg: ImageConfig, srcs: string[]) -> @Result<void, string>
pub fn assertImageHandler(loc: SourceLocation, cfg: ImageConfig, queries: string[]) -> @Result<void, string>
pub fn assertFontCss(loc: SourceLocation, family: string, opts: GoogleFontOptions) -> @Result<void, string>
pub fn assertFontHead(loc: SourceLocation, fonts: Font[]) -> @Result<void, string>
pub fn assertFontRefusals(loc: SourceLocation, cases: Array<#(string, GoogleFontOptions)>) -> @Result<void, string>

// og — 70
pub fn assertStyleParse(loc: SourceLocation, style: string) -> @Result<void, string>
pub fn assertLayout(loc: SourceLocation, tree: Element, size: ImageSize) -> @Result<void, string>
pub fn assertSvg(loc: SourceLocation, tree: Element, size: ImageSize, fonts: FontRef[]) -> @Result<void, string>
pub fn assertRasterizer(loc: SourceLocation, contentType: string, r: Rasterizer) -> @Result<void, string>

// release — 71
pub fn assertBuildId(loc: SourceLocation, moduleHashes: string[], manifestHash: string) -> @Result<void, string>
pub fn assertReleaseText(loc: SourceLocation, spec: ReleaseSpec) -> @Result<void, string>
pub fn assertDockerfile(loc: SourceLocation, spec: ReleaseSpec) -> @Result<void, string>
pub fn assertReleaseTree(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertShutdown(loc: SourceLocation, drainTimeoutMs: i32) -> @Result<void, string>
pub fn assertStaticExport(loc: SourceLocation, tree: string) -> @Result<void, string>
```

Every helper renders its subject to one canonical text (the tables and trees below), compares it
with the `.snap`, and on mismatch writes `<path>.new` and returns `Err("<path> differs; wrote <path>.new")`.
Refusal helpers render the **error list**; an empty list renders `(no refusals)`.

---

