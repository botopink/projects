# Front 19 — evidence

Greps and excerpts behind [`README.md`](./README.md) and [`surface.md`](./surface.md). Read at `botopink-lang` `d55a3b87` (`repository/botopink-lang/modules/compiler-core/src/` unless stated), `jhonstart` `13d1672`, meta `b5ceb203`, 2026-09-20. Nothing was built or run.

## 1 · The keyword and its two AST homes

```
$ grep -n '"use"' lexer.zig
752:        if (std.mem.eql(u8, text, "use")) return .use;

$ grep -n 'use: ImportDecl\|activationOnly\|useHook: ' ast.zig
57:    activationOnly: bool = false,
198:        useHook: UseHookExprOf(phase),
1934:    use: ImportDecl,
```

`ast.zig:602-621`:

```zig
/// Use-hook expressions: the `use` prefix operator inside function bodies
/// (distinct from top-level `ImportDecl` imports).
///
/// `use` is a prefix operator on a hook call. Binding is handled by the
/// enclosing `val`/`var`, never by `use` itself:
///   `use effect { -> cleanup() }`       — void hook (statement position)
///   `val d = use memo { -> v*2 }`        — value bound by `val`
///   `val {v, s} = use state(0)`          — destructured by `val`
pub fn UseHookExprOf(comptime phase: Phase) type {
    const Kind = struct {
        /// The hook call the `use` prefix wraps, e.g. `state(0)` or `memo { … }`.
        inner: *ExprOf(phase),
```

## 2 · Parser

Declaration role — `parser.zig:385-397`:

```zig
            const decl: DeclKind = if (this.check(.import)) blk: {
                const d = try this.parseImportDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .use = d };
            } else if (…mod…) …
            } else if (this.isActivationStmt()) blk: {
                const d = try this.parseActivationStmt(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .use = d };
```

`parser/decls.zig:217-225`, `:263-272`:

```zig
/// Fallback activation statement `dottedPath "*" ";"` — activates an
/// already-visible symbol without re-importing it.
pub fn parseActivationStmt(this: *This, alloc: std.mem.Allocator) ParseError!ImportDecl {
    const path = try this.parseImportItem(alloc);
    …
    return ImportDecl{ .imports = imports, .source = .root, .activationOnly = true };
}
…
/// Lookahead for a top-level activation statement: `ident ("." ident)* "*"`.
pub fn isActivationStmt(this: *This) bool {
```

Expression role — `parser/exprs.zig:116-124`:

```zig
    // `use` prefix operator: `use <hookcall>`. Binding (if any) is handled
    // by the enclosing `val`/`var`, e.g. `val {v, s} = use state(0)`.
    if (this.check(.use)) {
        const useTok = this.advance();
        const loc = locFromToken(useTok);
        const inner = try this.parseExpr(alloc);
        const innerPtr = try this.boxExpr(alloc, inner);
        return Expr{ .useHook = .{ .loc = loc, .kind = .{ .inner = innerPtr } } };
    }
```

Tuple destructuring in a binding exists — `parser/exprs.zig:661-676` (`// Tuple destructuring: val #(a, b) = expr` … `.pattern = .{ .tuple_ = … }`).

The guard — `parser.zig:695-698`, `:735-745`, `:767-773`:

```zig
        /// Reject a `use` hook that appears after a branch/return (static-prefix rule).
        useAfterBranchGuard: bool = false,
…
        var seenBranch = false;
        _ = &seenBranch; // used only when useAfterBranchGuard is set
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            …
            if (opts.useAfterBranchGuard) {
                if (seenBranch and this.check(.use)) {
                    const tok = this.peek();
                    this.parseError = ParseErrorInfo.fromToken(.useAfterBranch, tok);
                    return ParseError.UnexpectedToken;
                }
                if (this.check(.@"if") or this.check(.@"return") or this.check(.loop) or this.check(.case))
                    seenBranch = true;
            }
…
    pub fn parseStmtListInBraces(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
        return this.parseBlock(alloc, .{
            .trackEmptyLines = true,
            .handleComments = true,
            .semicolonPolicy = .requiredExceptLast,
            .useAfterBranchGuard = true,
        });
    }
```

```
$ grep -n 'useAfterBranchGuard = true' parser.zig
772:            .useAfterBranchGuard = true,
```

One caller; `parseBlockOrExpr` (`:779-781`) routes `if` blocks through it. The check reads the *first token* of the statement (`this.check(.use)`), so `val c = use …` is never flagged, and `seenBranch` is a local of one `parseBlockBody` call (`:735`), so a nested block starts clean.

Message — `print.zig:88-91`:

```zig
        .useAfterBranch => .{
            .message = "`use` must be in static prefix",
            .hint = "Move all `use` statements to the top of the function body, before any `if`, `case`, `loop`, or `return`",
        },
```

## 3 · Inference

Activation statement is always refused — `infer.zig:879-899`:

```zig
    // Activations carried by `use` declarations: an `import { name* } from "…"`
    // opts an *imported* extension into scope, while a bare `name*;`
    // (`activationOnly`) names a local symbol. Rule B: a locally-declared
    // extension is auto-applied in its module, so a bare `name*;` is never needed.
    …
                if (u.activationOnly) {
                    env.lastError = if (env.extensions.contains(nm))
                        TypeError.redundantActivation(nm)
                    else
                        TypeError.notAnExtension(nm);
                    return error.TypeError;
                }
                try env.activations.put(nm, {});
```

Capability from the return type — `infer.zig:973-990`:

```zig
/// Derive the `@Context` capability of a function from its declared return type.
/// A return type implements `@Context` either directly (`@Context<B, R>`) or via a
/// named type whose inline `implement` clause lists `@Context<B, R>`.
fn contextInfoFromReturn(env: *Env, retType: ?ast.TypeRef) InferError!envMod.FnContext {
    const display = if (retType) |rt| try typeRefToString(env.arena, rt) else "void";
    if (retType) |rt| switch (rt) {
        .generic => |g| if (std.mem.eql(u8, g.name, "Context")) { … return .{ .implementsContext = true, .base = base, … }; },
        .named => |n| if (env.lookupTypeDef(n)) |td| {
            if (td.contextBase()) |b| return .{ .implementsContext = true, .base = b, … };
        },
        else => {},
    };
    return .{ .implementsContext = false, .base = null, .returnDisplay = display };
}
```

`@Future<Element>` is a `.generic` named `Future` → falls through → `implementsContext = false`.

Body scope — `infer.zig:3009-3013` (and `:3277-3279` for `implement` methods):

```zig
    // The return type decides whether `use` is allowed in the body and which
    // ContextBase every `use` must agree on (@Context F7). Scope it to the body.
    const savedFnCtx = env.fnContext;
    env.fnContext = try contextInfoFromReturn(env, f.returnType);
    defer env.fnContext = savedFnCtx;
```

Lambdas do not reset it — `infer.zig:9100-9121` saves `throwContext`, `starFn`, `labelStack` only.

The expression rule — `infer.zig:8129-8172`:

```zig
fn inferUseHookExpr(env: *Env, uh: ast.UseHookExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    const fc = env.fnContext orelse {
        env.lastError = TypeError.useNotAllowed("void").withLoc(loc);
        return error.TypeError;
    };
    if (!fc.implementsContext) {
        env.lastError = TypeError.useNotAllowed(fc.returnDisplay).withLoc(loc);
        return error.TypeError;
    }
    const valTyped = try inferExprTyped(env, uh.kind.inner.*);
    const valPtr = try makeTypedPtr(env, valTyped);
    try validateUseBase(env, valTyped.getType(), fc, loc);
    const srcTy = bindingSourceType(valTyped.getType());
    return TypedExpr{ .useHook = .{ .loc = loc, .type_ = srcTy, .kind = .{ .inner = valPtr } } };
}
…
fn validateUseBase(env: *Env, valTy: *T.Type, fc: envMod.FnContext, loc: ast.Loc) InferError!void {
    const useBase = contextBaseOfType(env, valTy) orelse {
        … TypeError.useNotContext(disp) …
    };
    const fnBase = fc.base orelse return; // implements @Context but base unconstrained
    if (!std.mem.eql(u8, fnBase, useBase)) {
        env.lastError = TypeError.contextMismatch(fnBase, useBase).withLoc(loc);
        return error.TypeError;
    }
}
```

What `R` is — `infer.zig:1018-1027`:

```zig
/// The type a `use` binding destructures from: the `Return` (`R`) of `@Context<B, R>`
/// when the hook's type is `@Context`, or the type itself for a named context type.
fn bindingSourceType(ty: *T.Type) *T.Type {
    …
        .named => |n| if (std.mem.eql(u8, n.name, "Context") and n.args.len >= 2) n.args[1] else ty,
```

Destructuring — `infer.zig:7371-7372`, `:8176-8199`:

```zig
            if (isUseHookValue(lb.value)) {
                try bindUseDestructure(env, lb.pattern, valTyped.getType());
…
fn bindUseDestructure(env: *Env, pattern: ast.ParamDestruct, srcTy: *T.Type) InferError!void {
    switch (pattern) {
        .names => |n| { … findField(fld.field_name) … else fresh var … },
        .tuple_ => |t| {
            for (t) |nm| try env.bind(nm, try env.freshVar());
        },
        .list, .ctor => {},
```

A hook body's `return` targets `R` — `infer.zig:3358-3362`:

```zig
    // A hook returns `@Context<B, X>` with or without `#[@context]`: its body
    // returns the `X` the `use` prefix binds (a `state` or `memo` hook).
    if (t.* == .named and std.mem.eql(u8, t.named.name, "Context") and t.named.args.len >= 2) {
        return t.named.args[1];
```

Flat bindings — `comptime/env.zig:346-347`, `:841-847`:

```zig
    /// Value bindings: variable/function name → *Type.
    bindings: std.StringHashMap(*T.Type),
…
    pub fn lookup(self: *Env, name: []const u8) ?*T.Type { return self.bindings.get(name); }
    pub fn bind(self: *Env, name: []const u8, ty: *T.Type) !void { try self.bindings.put(name, ty); }
```

```
$ grep -n 'env\.bindings' comptime/infer.zig
5448:            _ = env.bindings.remove(snapshot.name);      # restorePatternBindings, case arms only
```

Diagnostics — `comptime/error.zig:335-337`, `:341`, `:343`:

```
use-of-non-context-fn: `use` not allowed: function returns '{s}' which does not implement @Context
use-of-non-context-fn: `use` requires @Context: '{s}' does not implement @Context
context-anchor-violation: function returns @Context<{s}, _> but `use` returns @Context<{s}, _>
'{s}' does not name an implement/extend symbol
`{s}*` is redundant: an extension declared in this module is auto-applied; `*` is only for imports
```

## 4 · Lowering

```
$ grep -rn 'useHook' codegen/*.zig | grep -v 'countLocals\|walk\|declareNested\|exprTail\|isBool\|collectIdents\|isString\|wasmTypeOf\|=> false\|=> true'
codegen/commonJS.zig:160:pub fn useHookInner(e: ast.Expr) ?*ast.Expr {
codegen/commonJS.zig:162:        .useHook => |uh| uh.kind.inner,
codegen/commonJS.zig:2372:                    const value = if (useHookInner(lb.value.*)) |inner| blk: {
codegen/commonJS.zig:2384:                    const value = if (useHookInner(lb.value.*)) |inner| blk: {
codegen/commonJS.zig:2398:            .useHook => |uh| return .{ .expr = try self.buildHookCall(uh.kind.inner.*) },
codegen/commonJS.zig:2966:            .useHook => |uh| return self.buildHookCall(uh.kind.inner.*),
codegen/beam_asm.zig:2912:            .useHook => |uh| return self.lowerExprIntoX0(uh.kind.inner.*),
codegen/wat.zig:2814:            .useHook => |uh| try self.lowerExpr(uh.kind.inner.*),
codegen/erlang.zig:5216:            .useHook => |uh| return this.exprNode(b, uh.kind.inner.*),
```

commonJS — `codegen/commonJS.zig:2466-2511`:

```zig
    // ── use-hooks (React-like target) ─────────────────────────────────────────

    /// Hooks whose lambda argument is wrapped with an inferred dependency array,
    /// matching React's `useMemo`/`useEffect`/`useCallback` calling convention.
    fn hookTakesDeps(callee: []const u8) bool {
        const with_deps = [_][]const u8{ "memo", "effect", "callback", "layoutEffect", "imperativeHandle" };
        …
    /// A hook's JS name. Bare capability names map by the React convention
    /// `state` → `useState`, `memo` → `useMemo`. Names already in `useXxx` form
    /// (custom hooks like `useAuth`) pass through unchanged.
    fn hookName(self: *Emitter, callee: []const u8) ![]const u8 {
        const is_custom = callee.len > 3 and
            std.mem.startsWith(u8, callee, "use") and
            std.ascii.isUpper(callee[3]);
        if (is_custom) return callee;
        if (callee.len == 0) return "use";
        return std.fmt.allocPrint(self.arena(), "use{c}{s}", .{ std.ascii.toUpper(callee[0]), callee[1..] });
    }
    …
    fn buildHookCall(self: *Emitter, value: ast.Expr) anyerror!js.Expr {
        …
        const callee: js.Expr = if (cc.receiver) |recv|
            try self.b.member(try self.buildExpr(recv.*), cc.callee)
        else
            .{ .name = try self.hookName(cc.callee) };
        …
        if (hookTakesDeps(cc.callee)) {
            try args.append(self.arena(), .{ .array = .{ .elems = try self.buildHookDeps(cc) } });
        }
```

erlang / wasm / beam — `codegen/erlang.zig:5214-5216`, `codegen/wat.zig:2812-2814`, `codegen/beam_asm.zig:2910-2912`, each with the same comment: "`use` is a transparent prefix: lower the wrapped call".

Recorded snapshot — `snapshots/codegen/commonJS/codegen_use_tuple_destructure_state_to_usestate.snap.md`:

```javascript
function state(initial) {
    initial;
}

function Counter() {
    const [ count, setCount ] = useState(0);
    new Element();
}
```

The definition is `state`; the call is `useState`; nothing declares `useState`. The same in a shipped example — `repository/jhonstart/examples/jhonstart-counter/out/main.js`:

```
20:const { state } = require("./jhonstart/hooks.js");
34:    const c = useState(0);
51:    const c = state(7);
```

## 5 · Cells that exist

```
parser/tests/errors.zig:52        "parser error: use after return (static prefix violation)"   — bare `use state(0);` after `return 1;`
parser/tests/expressions.zig:19   "parser: use multiple hooks in function"                      — val {…} = use / val = use / bare use
comptime/tests/effects.zig:243    "context: use with binding in @Context fn passes"
comptime/tests/effects.zig:256    "context: use void hook with discard binding passes"
comptime/tests/effects.zig:268    "context: record implement @Context resolved via inline impl passes"
comptime/tests/effects.zig:280    "context: custom hook propagates ContextBase transitively passes"
comptime/tests/effects.zig:293    "context error: use in fn returning string"
comptime/tests/effects.zig:304    "context error: ContextBase mismatch Element vs Http"
comptime/tests/effects.zig:368    "context: {value, set} hook shape type-checks"
comptime/tests/infer_errors.zig:661 "infer error: RC6 ---- use of non-context fn reds use-of-non-context-fn"
codegen/tests/features.zig:196    "codegen ---- use object destructure state to useState"
codegen/tests/features.zig:209    "codegen ---- use tuple destructure state to useState"
codegen/tests/features.zig:222    "codegen ---- use memo infers dependency array"
codegen/tests/features.zig:238    "codegen ---- use effect void hook empty deps"
```

```
$ grep -rl 'use state\|@Context' repository/botopink-lang/tests/language
(nothing)
$ sed -n '393,394p' repository/botopink-lang/tests/language/AGENTS.md
What cannot be tested from botopink at all, and why: `@Context` / `use` (lowers to React hooks on
commonJS, no erlang lowering — it needs a host framework); …
```

## 6 · The language reference

```
$ wc -l repository/botopink-lang/docs.md
670
$ grep -n 'Context\|\buse\b' repository/botopink-lang/docs.md
34:Projects use an explicit, Rust-style module tree. …
70:Leaf modules are single files; folder modules use a `mod.bp` entry point.
```

Neither role of `use` nor `@Context` is documented. Section headings: `## Expressions` `:296`, `## Functions` `:493`, `## Decided, not yet implemented` `:642`.

## 7 · The library convention

`repository/jhonstart/src/hooks.bp:1-11`, `:30`, `:37`, `:43`, `:49`, `:55-58`, `:100`, `:108-110`:

```
// Every hook is a function whose return implements `@Context<Element, _>`: that
// capability is what makes the `use` prefix legal on it, and only inside a
// component (a `-> Element` body) — enforced by the language's context-inference,
// not by jhonstart. … (the `use` prefix lowers to the target's
// hook convention — React `useState`/… on `commonJS`); …
pub fn state<T>(initial: T) -> @Context<Element, State<T>> {
pub fn effect(run: fn(), deps: any[]) -> @Context<Element, #()> {
pub fn memo<T>(compute: fn() -> T, deps: any[]) -> @Context<Element, T> {
pub fn ref<T>(initial: T) -> @Context<Element, #(current: T)> {
pub fn reducer<S, A>(…) -> @Context<Element, #(state: S, dispatch: fn(action: A))> {
fn useCounter(start: i32) -> @Context<Element, State<i32>> {
fn Counter() -> Element {
    val c = use state(0);
    val doubled = use memo({ -> …
```

```
$ grep -rn 'Context<' repository/jhonstart/src --include=*.bp
element.bp:8:) implement @Context<Element, Element>
router.d.bp:25:pub declare fn useRouter() -> @Context<Element, Router>;
server.d.bp:26:pub declare fn request() -> @Context<Http, Request>;
hooks.bp:30,37,43,49,58,100   (above)

$ grep -rn '\buse [a-zA-Z]' repository/jhonstart/examples --include=*.bp
jhonstart-app/app/posts/[id]/page.bp:26:    val req = use request();                         // @Context<Http, Request>
jhonstart-counter/src/main.bp:25:    val c = use state(0);
jhonstart-todo/src/main.bp:27:    val items = use state(["buy milk", "write docs"]);
jhonstart-todo/src/main.bp:28:    val open = use useToggle(true);
```

## 8 · The specs before the sweep

```
$ grep -rn "use use" specs/1.0.10-beta/04-jhonstart | wc -l
17
$ grep -rnoE "\buse[A-Z][A-Za-z]*" specs/1.0.10-beta/04-jhonstart | sed 's/.*://' | sort | uniq -c
     27 useActionState      1 useCallback        1 useContext        1 useDeferredValue
     20 useFormStatus       2 useId             20 useLinkStatus     19 useOptimistic
      6 useParams          17 usePathname       30 useRouter          9 useSearchParams
     11 useSelectedLayoutSegment   3 useSelectedLayoutSegments   2 useState   2 useTransition
```

Directive spellings across `specs/1.0.10-beta` (occurrences; files by directory):

| Spelling | Total | Where |
|---|---|---|
| `#[client]` | 92 | 04-jhonstart: 26 (2 files), 27 (1), 29 (5), 31 (2), modules/README/test-snap/test-snap-examples/unification (1 each); 06-onze: 53 (3), 68 (1), test-snap (1); absorbed/1.0.7-beta (6) |
| `'use client'` | 33 | prose naming Next: 02-packaging (2), 03-rakun 10/23 (1 each), 04-jhonstart 29/README/unification (1 each), 06-onze 53/68 (1 each), absorbed (3) |
| `'use server'` | 10 | 02-packaging/README.md (1), 03-rakun/24 (2), 06-onze/53 (1), absorbed (3) |
| `#[useCache]` | 3 | 03-rakun/12-rakun-cache (2 files) |
| `'use cache'` | 21 | 03-rakun/12 (2), 03-rakun/modules.md (1), language-gaps.md (1), 02-packaging/README.md (1), absorbed (4) |
| `#![…]` | 3 | 03-rakun/12 (1), language-gaps.md (1), absorbed/1.0.9-beta (1) |
| `#[server]` | 0 | — |

## 9 · Decisions

```
$ grep -n -i '\buse\b.*hook\|@Context\|activation\|\buse\*\|`use`' specs/1.0.5-beta/decisions-taken.md
926:the next line: to *use* `label` you must narrow it, …          # prose only
$ grep -n '^## 67\|^## 8\.' specs/1.0.5-beta/decisions-taken.md
229:## 8. `beam` as a target of the language suite
2214:## 67. The most restrictive behaviour, and no configuration that bypasses it
$ sed -n '3p' specs/1.0.10-beta/decisions-pending.md
**Twelve open, 71 to 82** … The next free number is **83**.
```

No decision binds `use`; the pending file's last entry is 82 (`:169`), so 84–86 are the numbers this front proposes (the coordinator assigns).
