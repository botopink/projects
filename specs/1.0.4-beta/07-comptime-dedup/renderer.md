# The comptime AST renderer — what `TYPED AST JSON` can and cannot assert

> Carried from `1.0.2-beta/10-comptime-dedup/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F12` and bare front numbers are the old numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).

`src/comptime/snapshot.zig` serialises each module's bindings into the `TYPED AST JSON` section of a
comptime snapshot. It renders partly from **syntax** and partly from **inference**, drops several
declaration kinds, and fills two fields with placeholders. That makes a large share of the `weak`
rows in reports 3.7–3.10 unverifiable rather than wrong, and it makes a `grep '"?"'` count useless
for sizing a checker fix.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`. Counts measured
2026-09-16 over `snapshots/comptime/node/` (the other three copies are byte-identical — see
[`README.md`](./README.md)); every figure holds per directory.

## Two functions print `?`, and they mean opposite things

| | `typeNameFromTypeRef` | `typeNameOf` |
|---|---|---|
| Site | `src/comptime/snapshot.zig:239-244` | `src/comptime/snapshot.zig:478-541`, the `?` at `:512` (`.typeVar => return allocator.dupe(u8, "?")`) |
| Renders | an **annotation** — a syntactic `TypeRef` | an **inferred** `*T.Type` |
| Prints `?` when | the `TypeRef` is anything but `.named`: `?i32`, `T[]`, `#(A,B)`, `fn(A) -> B`, `Option<T>`, `@Future<T>`, a type parameter, an anonymous record | the type, after `deref`, is still a type variable |
| Used for | `fn_def` params (`:421`) and return type (`:432`); `record_def` field values (`:440`) | `val` / `use` return types (`:376`), `case` subject and type (`:268`, `:270`), case arms and block statements (`:349`, `:357`), `call` args and type (`:281`, `:287`), and the diagnostic renderers |
| `?`s in `snapshots/comptime/node` | **52** in 34 files — 28 fn return types, 22 fn params, 2 record fields | **26** in **17** files — 10 `case` types, 2 inside a block arm, 7 under a `val`, 7 under a `call` |
| Moves when the checker becomes strict | **no** — it never consults inference | **yes** |

**`typeNameOf`'s `.typeVar` arm is the real tripwire.** It is the checker admitting it does not know
a type. The 17 files carrying one are the visible blast radius of the checker's "fresh variable,
never unified" rows ([`../06-checker/rows.md`](../06-checker/rows.md) M1 / C2 / C8 / C9);
`typeNameFromTypeRef`'s `?` is renderer noise that no checker change can remove.

A plain `grep -o '"?"'` reports 79 per directory, not 78: the extra one is inside a raw fn body
source line (`pub_fn_using_enum_case_in_body.snap.md`), not a rendered type — see "fn bodies" below.
51 files carry a rendered `?`; `grep -l` reports 52 for the same reason. **Do not `grep '"?"'` to
size a row.**

Even `typeNameOf`'s arm is coarser than it should be: `T.TypeVar` (`src/comptime/types.zig:20-28`)
has three states, and `deref` removes only `.link`. Both remaining states print `?`:

- `.unbound` — a free variable inference never resolved. This is the tripwire.
- `.generic` — a generalised variable inside a polymorphic scheme. This is a correct answer (the
  type of a generic parameter), printed as if it were a failure.

### The tripwire set — the 17 slugs

Measured by parsing each snapshot's JSON and attributing every `?` to the field that produced it.
Identical names in all four comptime directories (68 files).

| Group | Slugs |
|---|---|
| `case` (10) | `case_arms_three_distinct_types_union_of_three`, `case_arms_with_different_types_string_i32_union`, `case_arms_with_same_type_no_union`, `case_nested_case_in_block_arm`, `case_on_enum_variants_all_arms_return_string`, `case_on_integer_with_wildcard`, `case_or_patterns_with_block_arm_body`, `case_union_return_type_from_mismatched_arms`, `case_with_or_patterns`, `case_with_variant_field_bindings_body_does_not_use_bound_vars` |
| method / extension dispatch (5) | `inherent_record_method_is_always_available`, `local_extension_method_resolves_without_activation`, `multi_module_extension_activated_via_star_import`, `multi_module_local_extension_resolves_on_an_imported_record`, `qualified_extension_call_needs_no_activation` |
| `@makeRecord` (2) | `single_field_returns_record_type`, `multiple_fields_returns_record_type` |

[`../06-checker/rows.md`](../06-checker/rows.md) groups the same 17 as 10 `case` + 4 extension +
3 `@makeRecord`; by field attribution `multi_module_local_extension_resolves_on_an_imported_record`
is an extension slug and only two are `@makeRecord`.

## `"id"` is always `0`

`record_def` and `enum_def` carry `"id"`. It is `0` in all **69** occurrences (63 files); no snapshot
has a non-zero id, including modules with two records
(`disjoint_records_merge_correctly`: `User` and `Timestamps`, both `0`).

The ids exist — `env.allocTypeId` (`src/comptime/env.zig:844-848`, called at
`src/comptime/infer.zig:947`) hands out a monotonic counter and `infer.zig:469-474` / `:478-483` put
it on the binding as `TypedBinding.typeId` (`infer.zig:41-47`). The lookup loses it:

1. `src/comptime.zig:1276-1279` (and again at `:1455-1458`) builds `type_ids` keyed by the
   **declared name**, `b.name` (`User`).
2. `src/comptime/snapshot.zig:225-230` `resolveTypeId` looks up `ty.deref().named.name` — the name
   of the binding's **type**.
3. That type is `env.namedType(buildRecordDeclName(env, r))` (`infer.zig:474`; `buildEnumDeclName`
   at `:483`), and `buildRecordDeclName` (`infer.zig:1760`) / `buildEnumDeclName` (`:1862`) produce
   a structural string — `record { name: string, id: i32 }`, `enum …`.
4. The keys never match, so `.id = resolvedTypeId orelse 0` (`snapshot.zig:446`, `:457`) always
   takes the fallback.

Found by reading the four sites; the 69-of-69 zeros are consistent with it.

## Declaration kinds that never reach the JSON

`bindingToRepr` (`src/comptime/snapshot.zig:369-473`) handles `.use`, `.val`, `.fn`, `.record`,
`.enum` and `.interface`; everything else becomes `{"ast": "<tag>"}` (`:471`).

| Kind | What is rendered | What is missing |
|---|---|---|
| `interface` | `interface_def` with `name` and `generic` only (`:462-469`) | every member signature |
| `record` | `record_def` with `name`, `id`, `generic`, and `fields` from `typeNameFromTypeRef` (`:437-449`) | methods, `implement` list, inferred field types |
| `enum` | `enum_def` with `name`, `id`, `generic` (`:452-459`) | variants and their payloads, sections, methods |
| `implement` blocks | nothing — they produce no binding | everything |
| doc comments | nothing | everything |

Counts of rendered kinds in `snapshots/comptime/node`: `val` 139 · `fn_def` 136 · `call` 61 ·
`record_def` 43 · `enum_def` 26 · `value` (case arm) 24 · `interface_def` 11 · `case` 10 ·
`use-declaration` 9 · `use` 8 · `block` 2.

## Other lossy fields

- **fn bodies are raw source lines.** `extractFnBody` (`:246-257`) copies the source line of each
  top-level statement. No types; a multi-line statement shows its first line. A checker fix is
  therefore asserted with annotated top-level `val`s plus an error snapshot, never by reading a body
  out of a snapshot.
- **`.func` renders its return type only.** `typeNameOf` `:511` (`.func => |f| return
  typeNameOf(allocator, f.ret)`) — the params in `T.Type.func.params` are dropped, so a `val` bound
  to a function looks like a value of its return type.
- **`case` binding names are dropped.** `buildCaseArm` (`:348-368`) renders an arm's type (and, for
  a block arm, each statement's type) but not its pattern or the names it binds.
- **A block arm is recognised by shape.** `:350-352` treats a zero-parameter `.lambda` as a block —
  the typed AST carries a block arm as a lambda, which is the node beam and wasm lower to a fun and
  a `;; lambda` placeholder (see
  [`../08-review-backlog/semantics-decisions.md`](../08-review-backlog/semantics-decisions.md#decision-2)).
- **`"indent"` holds a binding name.** The key is written at `:60` and `:120` and filled with
  `b.name` at `:384`, `:407`, `:413`; `"ident"` is meant (`comptime-templates-types-exprs.md` C10).
  102 AST files carry the key; renaming it re-records all of them.

## Where the reports record this

| Report | Heading / id | Finding |
|---|---|---|
| `comptime-decls-variants.md` | `## Cross-cutting findings`, X2 (`:63`) | `fn_def` JSON is not inferred data |
| `comptime-decls-variants.md` | X8 (`:69`) | `"id"` is `0` everywhere |
| `comptime-decls-variants.md` | X9 (`:70`) | interfaces, implements, methods, variants, doc comments missing |
| `comptime-templates-types-exprs.md` | `## Cross-cutting findings`, C2 / C5 / C10 (`:77-93`) | `?` for non-`.named` TypeRefs; `"id"` always 0; `"indent"` |
| `comptime-generics-effects-decorators.md` | `## Cross-cutting compiler findings`, G4 (`:72-80`) | the renderer is lossy |

The line numbers inside those reports (`snapshot.zig:236-241`, `:443`, `:454`, `:459-466`) predate
the fix waves; the table above is at HEAD. Report citations are lines in
[`../../1.0.1-beta/06-snapshot-review/`](../../1.0.1-beta/06-snapshot-review/).
