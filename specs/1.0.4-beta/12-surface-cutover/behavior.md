# Deep dive — `interface` becomes `behavior`

> Carried from `1.0.3-beta/02-surface-cutover/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F4` and bare front numbers are 1.0.3-beta's numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).

Part of [front 03](./README.md).

## Why

`behavior` names what the declaration is — a set of capabilities (methods, `val` fields, default
methods, associated functions) a type exhibits through `implement` — rather than the structural
contract `interface` suggests. It is a rename; the semantics do not move. It lands together with
`type` so the surface changes once.

Naming note: OTP uses *behaviour* for module callbacks (`-behaviour(gen_server)`). Nothing in the
codegen emits that attribute today and no library uses OTP behaviours (`interfaceForms` in
`erlang.zig:4004` only writes a `%% interface Name` comment, which becomes `%% behavior Name`). If a
future milestone maps botopink behaviors to OTP behaviours, the name will read naturally; if it
does not, the comment is the only place they meet.

## Scope

| Area | Change |
|---|---|
| Lexer | `interface` removed, `behavior` added. |
| Parser | `parseInterfaceDecl` → `parseBehaviorDecl`, `parseShorthandInterfaceDecl` → `parseShorthandBehaviorDecl`, `parseInterfaceBody` → `parseBehaviorBody`, `parseInterfaceMethod` → `parseBehaviorMethod` (`parser/decls.zig:551–1007`). Separators follow [`separators.md`](./separators.md). |
| Val-form | `val X = behavior { … }`. The route `val X = interface fn(…)` → delegate (`parser.zig:450`) is **dropped**: zero uses in any `.bp` or Zig source; delegates are `declare fn`. |
| AST | `InterfaceDecl` → `BehaviorDecl`, `InterfaceField` → `BehaviorField`, `InterfaceMethod` → `BehaviorMethod` (also used by `TypeDecl.methods`), `DeclKind.interface` → `DeclKind.behavior`, `CollectionExpr.kind.interfaceLit` (`@Name(f: v)`) → `behaviorLit`. Parser ids `behavior_NNNN`. |
| Comptime | Behaviors live in `StringHashMap(ast.InterfaceDecl)` (`comptime/infer.zig:280–283`), not in `TypeDef` — the map is retyped. `registerInterfaceAssociatedFns` (`infer.zig:1043`) → `registerBehaviorAssociatedFns`; `assocInterfaceDecls` (`env.zig`) → `assocBehaviorDecls`. |
| Diagnostics | Texts saying *interface* say *behavior*. Code `effect-on-interface-method-forbidden` → `effect-on-behavior-method-forbidden`. The comptime prelude's `DeclKind { Record, Struct, Enum, Interface … }` (`comptime.zig:541–594`) exposes `Type` and `Behavior` shapes instead. |
| Codegen | `buildInterface` (`commonJS.zig:1296`), `typescript.zig:78–127`, `interfaceForms` (`erlang.zig:4004`), `reserveInterfaceMethods` / `emitInterfaceAssoc` (`beam_asm.zig`), wat decl readers — renamed consumers; output identical except comments naming the declaration. |

## Existing limitations kept as they are

- A behavior `val` field's type must be a bare identifier (`parser/decls.zig:605`) — `val xs: Array<i32>;` stays a parse error.
- Generics must follow `extends` (`behavior I<T> extends B` fails) — unchanged.

Both are recorded here so the rename does not hide them; neither is in scope.

## Acceptance

- [ ] `behavior Printable { fn print(self: Self) -> string; }` parses to `BehaviorDecl`
- [ ] `behavior Integer extends Number { default fn isEven(self: Self) -> bool { return self % 2 == 0; } }` parses and checks
- [ ] `#[mock] behavior UserRepo { fn find(self: Self, id: i32) -> string; }` keeps onze's synthesis working
- [ ] `val Drawable = behavior { fn draw(self: Self); }` parses
- [ ] `interface X {}` → `removed-keyword-interface`
- [ ] Generated JS, Erlang, BEAM and wasm for behavior fixtures are byte-identical except `%%`/`//` comments naming the declaration
