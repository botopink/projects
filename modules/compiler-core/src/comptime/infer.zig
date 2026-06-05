/// Type inference for the botopink type checker.
///
/// Entry points:
///   `inferProgram(env, program)` ---- infers all top-level declarations and
///   returns a map of name → *Type for every declared binding.
///
/// The inference is two-pass:
///   1. Register all type definitions (records, structs, enums) and build
///      constructor types for them.
///   2. Infer the type of every expression/declaration and bind the result.
const std = @import("std");
const ast = @import("../ast.zig");
const T = @import("./types.zig");
const Env = @import("env.zig").Env;
const envMod = @import("env.zig");
const TypeError = @import("error.zig").TypeError;
const template = @import("template.zig");
const templateEval = @import("template_eval.zig");
const specializeMod = @import("specialize.zig");
const unify = @import("unify.zig").unify;
const Lexer = @import("../lexer.zig").Lexer;
const Parser = @import("../parser.zig").Parser;
const Module = @import("../module.zig").Module;
const comptimeMod = @import("../comptime.zig");

pub const InferError = error{ TypeError, OutOfMemory };

/// A single resolved top-level binding: the declaration name and its inferred type.
pub const Binding = struct {
    name: []const u8,
    type_: *T.Type,
};

/// Like `Binding` but also carries the typed expression tree for `val` declarations.
/// `typedExpr` is null for type declarations (record/struct/enum/interface/fn).
/// `decl` is the original AST declaration node.
/// `typeId` is set for record/struct/enum declarations (monotonic counter).
pub const TypedBinding = struct {
    name: []const u8,
    type_: *T.Type,
    typedExpr: ?ast.TypedExpr,
    decl: ast.DeclKind,
    typeId: ?usize = null,
};

// ── public entry point ────────────────────────────────────────────────────────

/// Infer types for an entire program.
///
/// Pass 1 registers all type definitions (record, struct, enum) and builds
/// constructor bindings in the environment.
/// Pass 2 infers every `val` and `fn` declaration in source order.
///
/// Returns a slice of `Binding` values in declaration order.
/// All memory is allocated in `env.arena`.
/// `import {bool} from "std"` — marks each imported std module in
/// `env.stdImports` so qualified calls (`bool.negate(x)`) resolve against
/// `env.stdModules`. Returns true when the decl was a `from "std"` import
/// (fully handled here); unknown std module → clear type error.
fn markStdImports(env: *Env, u: ast.ImportDecl) InferError!bool {
    const from_std = switch (u.source) {
        .module => |m| std.mem.eql(u8, m, "std"),
        .root => false,
    };
    if (!from_std) return false;
    for (u.imports) |imp| {
        const mod_name = imp.segments[imp.segments.len - 1];
        if (!env.stdModules.contains(mod_name)) {
            env.lastError = TypeError.custom(
                "unknown \"std\" module in import",
                "Available std modules: bool. (`result` is builtin — call `result.map(r, f)` without importing.)",
            );
            return error.TypeError;
        }
        try env.stdImports.put(mod_name, {});
        // Type export: register the module's `pub` record/struct/enum decls
        // into this env so case patterns and annotations can name them
        // (e.g. `Order` from `import {order} from "std"`). Variant/constructor
        // value bindings come along — construct via the module's fns
        // (`order.lt()`), not the bare constructors (codegen has no local decl).
        if (env.stdModuleTypes.get(mod_name)) |decls| {
            for (decls) |d| try registerTypeDecl(env, d);
        }
    }
    return true;
}

pub fn inferProgram(env: *Env, program: ast.Program) InferError![]Binding {
    var list: std.ArrayListUnmanaged(Binding) = .empty;

    // Pass 1: register type definitions and their constructors.
    for (program.decls) |decl| {
        try registerTypeDecl(env, decl);
    }
    try registerExtensions(env, program);
    try buildScopeSnapshot(env, program);

    // Pass 2: infer value-producing declarations in order.
    for (program.decls) |decl| {
        if (try inferDecl(env, decl)) |b| {
            try list.append(env.arena, b);
        }
    }

    // Pass 3: semantic validation of `implement` blocks and struct accessors.
    try validateProgram(env, program);

    return list.toOwnedSlice(env.arena);
}

/// Like `inferProgram` but returns `TypedBinding` slices that include the
/// typed expression tree for each `val` declaration.
pub fn inferProgramTyped(env: *Env, program: ast.Program) InferError![]TypedBinding {
    var list: std.ArrayListUnmanaged(TypedBinding) = .empty;

    for (program.decls) |decl| {
        try registerTypeDecl(env, decl);
    }
    try registerExtensions(env, program);
    try buildScopeSnapshot(env, program);
    for (program.decls) |decl| {
        switch (decl) {
            // `resolveImports` (called before inference in comptime.zig) already
            // called `env.bind(name, ty)` for each symbol in the `use` statement.
            // Emit one TypedBinding per import so the LSP completion engine can
            // see them — the dummy `name = ""` binding is gone.
            .use => |u| {
                // `import {bool} from "std"` — mark each imported std module
                // so qualified calls (`bool.negate(x)`) resolve against
                // `env.stdModules`. Unknown std module → clear type error.
                if (try markStdImports(env, u)) continue;
                for (u.imports) |imp| {
                    const name = imp.name();
                    if (env.lookup(name)) |ty| {
                        try list.append(env.arena, .{
                            .name = name,
                            .type_ = ty,
                            .typedExpr = null,
                            .decl = decl,
                        });
                    }
                }
            },
            else => {
                if (try inferDeclTyped(env, decl)) |b| {
                    try list.append(env.arena, b);
                }
            },
        }
    }

    // Semantic validation of `implement` blocks and struct accessors.
    try validateProgram(env, program);

    return list.toOwnedSlice(env.arena);
}

// ── pass 3: semantic validation ───────────────────────────────────────────────

/// Validate `implement` blocks against the interfaces they claim to satisfy and
/// check that struct getters/setters agree with their backing field's type.
///
/// Runs after type registration so user-defined interface and field types are
/// already known. Only the standalone `implement … for …` form is checked for
/// method coverage; inline `struct/enum/record implement` clauses carry no method
/// bodies of their own here. Interfaces that are not declared in this program
/// (e.g. stdlib interfaces) are skipped — their method sets are not visible.
fn validateProgram(env: *Env, program: ast.Program) InferError!void {
    var interfaces = std.StringHashMap(ast.InterfaceDecl).init(env.arena);
    defer interfaces.deinit();
    for (program.decls) |decl| switch (decl) {
        .interface => |d| try interfaces.put(d.name, d),
        else => {},
    };

    for (program.decls) |decl| switch (decl) {
        .implement => |impl| try validateImplement(env, impl, interfaces),
        .@"struct" => |s| try validateStructAccessors(env, s),
        else => {},
    };
}

/// True when interface `d` declares a method named `name` (abstract or default).
fn interfaceHasMethod(d: ast.InterfaceDecl, name: []const u8) bool {
    for (d.methods) |m| {
        if (std.mem.eql(u8, m.name, name)) return true;
    }
    return false;
}

/// True when `name` is one of the interfaces this implement block declares.
fn implementsInterface(impl: ast.ImplementDecl, name: []const u8) bool {
    for (impl.interfaces) |iname| {
        if (std.mem.eql(u8, iname, name)) return true;
    }
    return false;
}

fn validateImplement(
    env: *Env,
    impl: ast.ImplementDecl,
    interfaces: std.StringHashMap(ast.InterfaceDecl),
) InferError!void {
    // Per-method checks: qualifier validity, method existence, ambiguity.
    for (impl.methods) |m| {
        if (m.qualifier) |q| {
            // The qualifier must name an interface this block implements.
            if (!implementsInterface(impl, q)) {
                env.lastError = TypeError.unknownInterface(q, m.name);
                return error.TypeError;
            }
            // If the interface is visible, it must declare the method.
            if (interfaces.get(q)) |d| {
                if (!interfaceHasMethod(d, m.name)) {
                    env.lastError = TypeError.unknownMethod(impl.target, m.name);
                    return error.TypeError;
                }
            }
        } else {
            // Unqualified: find which implemented interfaces declare this method.
            var first: ?[]const u8 = null;
            var second: ?[]const u8 = null;
            for (impl.interfaces) |iname| {
                const d = interfaces.get(iname) orelse continue;
                if (!interfaceHasMethod(d, m.name)) continue;
                if (first == null) {
                    first = iname;
                } else if (second == null) {
                    second = iname;
                }
            }
            if (first == null) {
                env.lastError = TypeError.unknownMethod(impl.target, m.name);
                return error.TypeError;
            }
            if (second) |snd| {
                env.lastError = TypeError.ambiguousMethod(m.name, first.?, snd);
                return error.TypeError;
            }
        }
    }

    // Coverage: every abstract method of every implemented interface must be met.
    for (impl.interfaces) |iname| {
        const d = interfaces.get(iname) orelse continue;
        for (d.methods) |am| {
            if (am.body != null) continue; // default method — implementing it is optional
            var covered = false;
            for (impl.methods) |m| {
                if (!std.mem.eql(u8, m.name, am.name)) continue;
                if (m.qualifier) |q| {
                    if (std.mem.eql(u8, q, iname)) {
                        covered = true;
                        break;
                    }
                } else {
                    covered = true;
                    break;
                }
            }
            if (!covered) {
                env.lastError = TypeError.missingMethod(impl.target, iname, am.name);
                return error.TypeError;
            }
        }
    }
}

/// Resolve the declared type of struct field `name`, or null when there is no
/// field with that name (e.g. a computed getter that backs no field).
fn structFieldType(
    env: *Env,
    s: ast.StructDecl,
    genericMap: std.StringHashMap(*T.Type),
    name: []const u8,
) InferError!?*T.Type {
    for (s.members) |m| switch (m) {
        .field => |f| if (std.mem.eql(u8, f.name, name)) {
            return try env.resolveTypeName(f.typeName, genericMap);
        },
        else => {},
    };
    return null;
}

/// Check that each getter/setter named after a field agrees with that field's
/// type: a getter must return the field type, a setter must accept it.
fn validateStructAccessors(env: *Env, s: ast.StructDecl) InferError!void {
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    for (s.genericParams) |gp| {
        try genericMap.put(gp.name, try env.freshVar());
    }

    for (s.members) |m| switch (m) {
        .getter => |g| {
            const fieldTy = (try structFieldType(env, s, genericMap, g.name)) orelse continue;
            const retTy = try env.resolveTypeName(g.returnType, genericMap);
            try unify(env, fieldTy, retTy);
        },
        .setter => |st| {
            const fieldTy = (try structFieldType(env, s, genericMap, st.name)) orelse continue;
            // The value parameter follows `self`; skip malformed setters.
            if (st.params.len < 2) continue;
            const valueParam = st.params[st.params.len - 1];
            const valueTy = try resolveTypeRefInContext(env, valueParam.typeRef, genericMap);
            try unify(env, fieldTy, valueTy);
        },
        else => {},
    };
}

// ── stdlib preload ────────────────────────────────────────────────────────────

/// Parse and register all stdlib interface declarations into `env`.
///
/// The three stdlib source files are embedded at compile time via `@embedFile`.
/// Each file is lexed and parsed in a temporary arena that is freed immediately
/// after inference; the resulting type bindings live in `env.arena`.
fn inferDeclTyped(env: *Env, decl: ast.DeclKind) InferError!?TypedBinding {
    switch (decl) {
        .val => |v| {
            const annType: ?*T.Type = if (v.typeAnnotation) |ann| try resolveTypeRef(env, ann) else null;
            // When binding a lambda to a `fn(...) -> ...` annotation, feed the
            // annotation into the lambda so its params are typed from context.
            const typedExpr = if (annType != null and v.value.* == .function)
                try inferFunctionExprExpected(env, v.value.function, v.value.function.loc, annType)
            else
                try inferExprTyped(env, v.value.*);
            const ty = typedExpr.getType();
            if (annType) |at| try unifyAt(env, at, ty, v.value.getLoc());
            // The annotation is the DECLARED type — bind it, not the RHS type
            // (`val head: ?i32 = 5;` must bind `?i32`, or a later
            // `option.map(head, f)` sees a bare `i32`).
            const bindTy = annType orelse ty;
            try env.bind(v.name, bindTy);
            return .{ .name = v.name, .type_ = bindTy, .typedExpr = typedExpr, .decl = decl };
        },
        .@"fn" => |f| {
            const ty = try inferFnDecl(env, f);
            try env.bind(f.name, ty);
            return .{ .name = f.name, .type_ = ty, .typedExpr = null, .decl = decl };
        },
        .record => |r| {
            const typeName = try buildRecordDeclName(env, r);
            const typeId = if (env.lookupTypeDef(r.name)) |td| switch (td) {
                .record => |rec| rec.id,
                else => null,
            } else null;
            return .{ .name = r.name, .type_ = try env.namedType(typeName), .typedExpr = null, .decl = decl, .typeId = typeId };
        },
        .@"struct" => |s| {
            const typeName = try buildStructDeclName(env, s);
            const typeId = if (env.lookupTypeDef(s.name)) |td| switch (td) {
                .struct_ => |st| st.id,
                else => null,
            } else null;
            return .{ .name = s.name, .type_ = try env.namedType(typeName), .typedExpr = null, .decl = decl, .typeId = typeId };
        },
        .@"enum" => |e| {
            const typeName = try buildEnumDeclName(env, e);
            const typeId = if (env.lookupTypeDef(e.name)) |td| switch (td) {
                .enum_ => |en| en.id,
                else => null,
            } else null;
            return .{ .name = e.name, .type_ = try env.namedType(typeName), .typedExpr = null, .decl = decl, .typeId = typeId };
        },
        .interface => |d| {
            const typeName = try buildInterfaceDeclName(env, d);
            return .{ .name = d.name, .type_ = try env.namedType(typeName), .typedExpr = null, .decl = decl };
        },
        // Handled in `inferProgramTyped` — each import name is looked up in env.
        // `from "std"` imports must be marked here too — the untyped path
        // (tests, LSP) otherwise leaves qualified-call receivers unbound.
        .use => |u| {
            _ = try markStdImports(env, u);
            return null;
        },
        // A test block produces no binding, but its body must type-check.
        .@"test" => |t| {
            try inferTestDecl(env, t);
            return null;
        },
        else => return null,
    }
}

// ── pass 1: type definition registration ─────────────────────────────────────

fn registerTypeDecl(env: *Env, decl: ast.DeclKind) InferError!void {
    switch (decl) {
        .record => |r| try registerRecord(env, r),
        .@"struct" => |s| try registerStruct(env, s),
        .@"enum" => |e| try registerEnum(env, e),
        else => {},
    }
}

/// Pre-pass for static extension dispatch: record inherent methods, register
/// named `implement`/`extend` blocks, collect activations, and validate
/// `implement` blocks against their interfaces.
///
/// Runs after type-definition registration (pass 1) and before expression
/// inference (pass 2) so `obj.method()` resolution sees the full picture.
fn registerExtensions(env: *Env, program: ast.Program) InferError!void {
    // Note: `implement`-vs-interface coverage (extra/missing methods) is validated
    // by `validateProgram`; this pre-pass only builds the dispatch tables.

    // Inherent methods + extension entries.
    for (program.decls) |decl| {
        switch (decl) {
            .@"struct" => |s| for (s.members) |m| switch (m) {
                .method => |im| try env.addInherentMethod(s.name, im.name),
                else => {},
            },
            .record => |r| for (r.methods) |im| try env.addInherentMethod(r.name, im.name),
            .@"enum" => |e| for (e.methods) |im| try env.addInherentMethod(e.name, im.name),
            .implement => |im| {
                try env.extensions.put(im.name, .{
                    .name = im.name,
                    .target = im.target,
                    .isExtend = false,
                    .interfaces = im.interfaces,
                    .methods = try collectImplMethodNames(env, im.methods),
                });
                // Bind the symbol as a value so a qualified call `Sym.m(obj)` can
                // infer `Sym` as its receiver expression (it names a namespace of
                // methods, not a typed value — a fresh var types it permissively).
                try env.bind(im.name, try env.freshVar());
            },
            .extend => |ex| {
                try env.extensions.put(ex.name, .{
                    .name = ex.name,
                    .target = ex.target,
                    .isExtend = true,
                    .methods = try collectImplMethodNames(env, ex.methods),
                });
                try env.bind(ex.name, try env.freshVar());
            },
            else => {},
        }
    }

    // Activations: `name*` imports and bare `name*;` statements. Both are carried
    // by `use` declarations (`activationOnly` marks the bare `name*;` form).
    for (program.decls) |decl| {
        switch (decl) {
            .use => |u| for (u.imports) |imp| {
                if (!imp.activate) continue;
                const nm = imp.name();
                // A bare `name*;` must name a locally-known impl/extend symbol.
                if (u.activationOnly and !env.extensions.contains(nm)) {
                    env.lastError = TypeError.notAnExtension(nm);
                    return error.TypeError;
                }
                try env.activations.put(nm, {});
            },
            else => {},
        }
    }
}

/// Build the V1 origin-scope snapshot for the module being inferred: every
/// top-level declaration plus imported names, mapped to a `BindingKind`
/// (expr-templates F4). The snapshot is attached to every `expr` capture so
/// template functions can `lookup` names in the *caller's* scope — function
/// locals are not visible (V1 limit recorded in the spec).
///
/// Runs after `resolveImports` (comptime.zig) bound the imports, so an
/// imported name's kind is derived from its bound type (`fn` vs value).
fn buildScopeSnapshot(env: *Env, program: ast.Program) InferError!void {
    const snap = template.ScopeSnapshot.init(env.arena, env.modulePath) catch return error.OutOfMemory;
    for (program.decls) |decl| switch (decl) {
        .@"fn" => |f| try snap.put(f.name, .fn_, false),
        .val => |v| try snap.put(v.name, .val, false),
        .@"struct" => |s| try snap.put(s.name, .struct_, false),
        .record => |r| try snap.put(r.name, .struct_, false),
        .@"enum" => |e| try snap.put(e.name, .enum_, false),
        .interface => |i| try snap.put(i.name, .interface, false),
        .use => |u| for (u.imports) |imp| {
            const name = imp.name();
            const kind: template.BindingKind = blk: {
                const ty = env.lookup(name) orelse break :blk .val;
                break :blk if (ty.deref().* == .func) .fn_ else .val;
            };
            try snap.put(name, kind, true);
        },
        else => {},
    };
    env.scopeSnapshot = snap;
}

fn collectImplMethodNames(env: *Env, methods: []const ast.ImplementMethod) ![]const []const u8 {
    var names = try env.arena.alloc([]const u8, methods.len);
    for (methods, 0..) |m, i| names[i] = m.name;
    return names;
}

fn extractImplementNames(arena: std.mem.Allocator, impls: []const ast.TypeRef) ![]const []const u8 {
    if (impls.len == 0) return &.{};
    var names = try arena.alloc([]const u8, impls.len);
    for (impls, 0..) |im, i| {
        names[i] = switch (im) {
            .named => |n| n,
            .generic => |g| g.name,
            else => "unknown",
        };
    }
    return names;
}

/// Render a `TypeRef` to its source-level string form (heap-allocated in `arena`).
fn typeRefToString(arena: std.mem.Allocator, ref: ast.TypeRef) ![]const u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    try appendTypeRefStr(&buf, arena, ref);
    return buf.toOwnedSlice(arena);
}

/// If any of `impls` is `@Context<B, R>`, return the rendered `ContextBase` (`B`).
/// Returns null when the type does not implement `@Context`.
fn contextBaseFromImplements(arena: std.mem.Allocator, impls: []const ast.TypeRef) !?[]const u8 {
    for (impls) |im| {
        switch (im) {
            .generic => |g| if (std.mem.eql(u8, g.name, "Context")) {
                if (g.args.len >= 1) return try typeRefToString(arena, g.args[0]);
                return null;
            },
            else => {},
        }
    }
    return null;
}

/// Derive the `@Context` capability of a function from its declared return type.
/// A return type implements `@Context` either directly (`@Context<B, R>`) or via a
/// named type whose inline `implement` clause lists `@Context<B, R>`.
fn contextInfoFromReturn(env: *Env, retType: ?ast.TypeRef) InferError!envMod.FnContext {
    const display = if (retType) |rt| try typeRefToString(env.arena, rt) else "void";
    if (retType) |rt| switch (rt) {
        .generic => |g| if (std.mem.eql(u8, g.name, "Context")) {
            const base = if (g.args.len >= 1) try typeRefToString(env.arena, g.args[0]) else null;
            return .{ .implementsContext = true, .base = base, .returnDisplay = display };
        },
        .named => |n| if (env.lookupTypeDef(n)) |td| {
            if (td.contextBase()) |b| return .{ .implementsContext = true, .base = b, .returnDisplay = display };
        },
        else => {},
    };
    return .{ .implementsContext = false, .base = null, .returnDisplay = display };
}

/// The display name of a `ContextBase` type (a phantom, typically a plain named type).
fn baseNameOfType(ty: *T.Type) ?[]const u8 {
    return switch (ty.deref().*) {
        .named => |n| n.name,
        else => null,
    };
}

/// The `ContextBase` of an inferred type, if it implements `@Context`.
/// Handles both `@Context<B, R>` directly and named types implementing it inline.
fn contextBaseOfType(env: *Env, ty: *T.Type) ?[]const u8 {
    const t = ty.deref();
    return switch (t.*) {
        .named => |n| blk: {
            if (std.mem.eql(u8, n.name, "Context")) {
                break :blk if (n.args.len >= 1) baseNameOfType(n.args[0]) else null;
            }
            if (env.lookupTypeDef(n.name)) |td| break :blk td.contextBase();
            break :blk null;
        },
        else => null,
    };
}

/// The type a `use` binding destructures from: the `Return` (`R`) of `@Context<B, R>`
/// when the hook's type is `@Context`, or the type itself for a named context type.
fn bindingSourceType(ty: *T.Type) *T.Type {
    const t = ty.deref();
    return switch (t.*) {
        .named => |n| if (std.mem.eql(u8, n.name, "Context") and n.args.len >= 2) n.args[1] else ty,
        else => ty,
    };
}

fn registerRecord(env: *Env, r: ast.RecordDecl) InferError!void {
    // Build generic param map: each param name → fresh generic type var.
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    var genericIds = try env.arena.alloc([]const u8, r.genericParams.len);
    for (r.genericParams, 0..) |gp, i| {
        const tv = try env.freshVar();
        try genericMap.put(gp.name, tv);
        genericIds[i] = gp.name;
    }

    // Resolve each field's type.
    var fields = try env.arena.alloc(envMod.FieldDef, r.fields.len);
    for (r.fields, 0..) |f, i| {
        fields[i] = .{
            .name = f.name,
            .type_ = try resolveTypeRefInContext(env, f.typeRef, genericMap),
        };
    }

    // Register the type definition.
    const typeId = env.allocTypeId();
    const implNames = try extractImplementNames(env.arena, r.implement);
    const ctxBase = try contextBaseFromImplements(env.arena, r.implement);
    try env.registerTypeDef(r.name, .{ .record = .{
        .name = r.name,
        .id = typeId,
        .genericParams = genericIds,
        .fields = fields,
        .implements = implNames,
        .contextBase = ctxBase,
    } });

    // Build constructor function type: `fn(T1, T2, ...) -> RecordName<A,B,...>`.
    // The return type carries the generic type vars so that after call-site
    // unification `typeNameOf` can display the instantiated form, e.g. `Pair<Int,String>`.
    var paramTypes = try env.arena.alloc(*T.Type, r.fields.len);
    for (fields, 0..) |f, i| paramTypes[i] = f.type_;
    var retArgs = try env.arena.alloc(*T.Type, r.genericParams.len);
    for (r.genericParams, 0..) |gp, i| retArgs[i] = genericMap.get(gp.name).?;
    const retType = try env.namedTypeArgs(r.name, retArgs);
    const ctorType = try env.funcType(paramTypes, retType);
    try env.bind(r.name, ctorType);
}

fn registerStruct(env: *Env, s: ast.StructDecl) InferError!void {
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    var genericIds = try env.arena.alloc([]const u8, s.genericParams.len);
    for (s.genericParams, 0..) |gp, i| {
        const tv = try env.freshVar();
        try genericMap.put(gp.name, tv);
        genericIds[i] = gp.name;
    }

    // Collect non-private fields.
    var fieldCount: usize = 0;
    for (s.members) |m| switch (m) {
        .field => fieldCount += 1,
        else => {},
    };

    var fields = try env.arena.alloc(envMod.FieldDef, fieldCount);
    var fi: usize = 0;
    for (s.members) |m| switch (m) {
        .field => |f| {
            fields[fi] = .{
                .name = f.name,
                .type_ = try env.resolveTypeName(f.typeName, genericMap),
            };
            fi += 1;
        },
        else => {},
    };

    const structTypeId = env.allocTypeId();
    const implNames = try extractImplementNames(env.arena, s.implement);
    const ctxBase = try contextBaseFromImplements(env.arena, s.implement);
    try env.registerTypeDef(s.name, .{ .struct_ = .{
        .name = s.name,
        .id = structTypeId,
        .genericParams = genericIds,
        .fields = fields,
        .implements = implNames,
        .contextBase = ctxBase,
    } });

    var paramTypes = try env.arena.alloc(*T.Type, fields.len);
    for (fields, 0..) |f, i| paramTypes[i] = f.type_;
    const retType = try env.namedType(s.name);
    const ctorType = try env.funcType(paramTypes, retType);
    try env.bind(s.name, ctorType);
}

fn registerEnum(env: *Env, e: ast.EnumDecl) InferError!void {
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    var genericIds = try env.arena.alloc([]const u8, e.genericParams.len);
    for (e.genericParams, 0..) |gp, i| {
        const tv = try env.freshVar();
        try genericMap.put(gp.name, tv);
        genericIds[i] = gp.name;
    }

    var variants = try env.arena.alloc(envMod.VariantDef, e.variants.len);
    for (e.variants, 0..) |v, vi| {
        var fields = try env.arena.alloc(envMod.FieldDef, v.fields.len);
        for (v.fields, 0..) |f, fi| {
            fields[fi] = .{
                .name = f.name,
                .type_ = try resolveTypeRefInContext(env, f.typeRef, genericMap),
            };
        }
        variants[vi] = .{ .name = v.name, .fields = fields };

        // Each variant is also a constructor: unit → `EnumName`, payload → `fn(T...) → EnumName`.
        const retType = try env.namedType(e.name);
        const ctorType = if (v.fields.len == 0)
            retType
        else blk: {
            var ps = try env.arena.alloc(*T.Type, v.fields.len);
            for (fields, 0..) |f, i| ps[i] = f.type_;
            break :blk try env.funcType(ps, retType);
        };
        try env.bind(v.name, ctorType);
    }

    const enumTypeId = env.allocTypeId();
    const implNames = try extractImplementNames(env.arena, e.implement);
    const ctxBase = try contextBaseFromImplements(env.arena, e.implement);
    try env.registerTypeDef(e.name, .{ .enum_ = .{
        .name = e.name,
        .id = enumTypeId,
        .genericParams = genericIds,
        .variants = variants,
        .implements = implNames,
        .contextBase = ctxBase,
    } });
    // Bind the enum name itself so `inferDecl` can look it up.
    try env.bind(e.name, try env.namedType(e.name));
}

// ── pass 2: declaration inference ────────────────────────────────────────────

/// Build a signature name for a record declaration binding.
/// Format: `"record { f1: T1, f2: T2 }"` ---- fields inline, body omitted.
fn buildRecordDeclName(env: *Env, r: ast.RecordDecl) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    try buf.appendSlice(env.arena, "record");
    if (r.genericParams.len > 0) {
        try buf.appendSlice(env.arena, " <");
        for (r.genericParams, 0..) |gp, i| {
            if (i > 0) try buf.appendSlice(env.arena, ", ");
            try buf.appendSlice(env.arena, gp.name);
        }
        try buf.append(env.arena, '>');
    }
    try buf.appendSlice(env.arena, " { ");
    for (r.fields, 0..) |f, i| {
        if (i > 0) try buf.appendSlice(env.arena, ", ");
        try buf.appendSlice(env.arena, f.name);
        try buf.appendSlice(env.arena, ": ");
        try appendTypeRefStr(&buf, env.arena, f.typeRef);
    }
    try buf.append(env.arena, ' ');
    try buf.appendSlice(env.arena, "}");
    return try buf.toOwnedSlice(env.arena);
}

/// Build a signature name for a struct declaration binding.
/// Format: `"struct {\n    name: Type\n}"` ---- fields only.
fn buildStructDeclName(env: *Env, s: ast.StructDecl) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    try buf.appendSlice(env.arena, "struct");
    if (s.genericParams.len > 0) {
        try buf.appendSlice(env.arena, " <");
        for (s.genericParams, 0..) |gp, i| {
            if (i > 0) try buf.appendSlice(env.arena, ", ");
            try buf.appendSlice(env.arena, gp.name);
        }
        try buf.append(env.arena, '>');
    }
    try buf.appendSlice(env.arena, " {\n");
    for (s.members) |m| {
        switch (m) {
            .field => |f| {
                try buf.appendSlice(env.arena, "    ");
                try buf.appendSlice(env.arena, f.name);
                try buf.appendSlice(env.arena, ": ");
                try buf.appendSlice(env.arena, f.typeName);
                if (f.init) |_| {
                    try buf.append(env.arena, '\n');
                } else {
                    try buf.append(env.arena, '\n');
                }
            },
            else => {},
        }
    }
    try buf.append(env.arena, '}');
    return try buf.toOwnedSlice(env.arena);
}

/// Build a signature name for an interface declaration binding.
/// Format: `"interface {\n    fn method(params)\n}"` ---- methods and fields.
fn buildInterfaceDeclName(env: *Env, d: ast.InterfaceDecl) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    try buf.appendSlice(env.arena, "interface");
    if (d.genericParams.len > 0) {
        try buf.appendSlice(env.arena, " <");
        for (d.genericParams, 0..) |gp, i| {
            if (i > 0) try buf.appendSlice(env.arena, ", ");
            try buf.appendSlice(env.arena, gp.name);
        }
        try buf.append(env.arena, '>');
    }
    try buf.appendSlice(env.arena, " {\n");
    for (d.fields) |f| {
        try buf.appendSlice(env.arena, "    val ");
        try buf.appendSlice(env.arena, f.name);
        try buf.appendSlice(env.arena, ": ");
        try buf.appendSlice(env.arena, f.typeName);
        try buf.appendSlice(env.arena, ";\n");
    }
    for (d.methods) |m| {
        try buf.appendSlice(env.arena, "    fn ");
        try buf.appendSlice(env.arena, m.name);
        try buf.append(env.arena, '(');
        for (m.params, 0..) |p, i| {
            if (i > 0) try buf.appendSlice(env.arena, ", ");
            try buf.appendSlice(env.arena, p.name);
            if (p.modifier == .@"comptime" or p.modifier == .syntax) {
                try buf.appendSlice(env.arena, " comptime");
            }
            try buf.appendSlice(env.arena, ": ");
            if (p.modifier == .syntax) try buf.appendSlice(env.arena, "syntax ");
            try appendTypeRefStr(&buf, env.arena, p.typeRef);
        }
        try buf.append(env.arena, ')');
        if (!m.is_default) try buf.appendSlice(env.arena, ";");
        try buf.append(env.arena, '\n');
    }
    try buf.append(env.arena, '}');
    return try buf.toOwnedSlice(env.arena);
}

/// Build a signature name for an enum declaration binding.
/// Format: `"enum {\n    Variant,\n    Variant(field: Type),\n}\n"`
fn buildEnumDeclName(env: *Env, e: ast.EnumDecl) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    try buf.appendSlice(env.arena, "enum");
    if (e.genericParams.len > 0) {
        try buf.appendSlice(env.arena, " <");
        for (e.genericParams, 0..) |gp, i| {
            if (i > 0) try buf.appendSlice(env.arena, ", ");
            try buf.appendSlice(env.arena, gp.name);
        }
        try buf.append(env.arena, '>');
    }
    try buf.appendSlice(env.arena, " {\n");
    for (e.variants) |v| {
        try buf.appendSlice(env.arena, "    ");
        try buf.appendSlice(env.arena, v.name);
        if (v.fields.len > 0) {
            try buf.append(env.arena, '(');
            for (v.fields, 0..) |f, i| {
                if (i > 0) try buf.appendSlice(env.arena, ", ");
                try buf.appendSlice(env.arena, f.name);
                try buf.appendSlice(env.arena, ": ");
                try appendTypeRefStr(&buf, env.arena, f.typeRef);
            }
            try buf.append(env.arena, ')');
        }
        try buf.appendSlice(env.arena, ",\n");
    }
    try buf.append(env.arena, '}');
    return try buf.toOwnedSlice(env.arena);
}

/// Build a signature name for a fn declaration binding.
/// Format: `fn(name [comptime]: [syntax ]Type, ...) -> ReturnType`
/// The function name and generic params are omitted; modifiers are included.
fn buildFnSigName(env: *Env, f: ast.FnDecl) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    try buf.appendSlice(env.arena, "fn(");
    for (f.params, 0..) |p, i| {
        if (i > 0) try buf.appendSlice(env.arena, ", ");
        try buf.appendSlice(env.arena, p.name);
        if (p.modifier == .@"comptime" or p.modifier == .syntax) {
            try buf.appendSlice(env.arena, " comptime");
        }
        try buf.appendSlice(env.arena, ": ");
        if (p.modifier == .syntax) {
            try buf.appendSlice(env.arena, "syntax ");
        }
        try appendTypeRefStr(&buf, env.arena, p.typeRef);
    }
    try buf.append(env.arena, ')');
    if (f.returnType) |rt| {
        try buf.appendSlice(env.arena, " -> ");
        try appendTypeRefStr(&buf, env.arena, rt);
    }
    return try buf.toOwnedSlice(env.arena);
}

/// Append the string form of a TypeRef to `buf`.
fn appendTypeRefStr(buf: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator, ref: ast.TypeRef) std.mem.Allocator.Error!void {
    switch (ref) {
        .named => |n| try buf.appendSlice(allocator, n),
        .array => |elem| {
            try appendTypeRefStr(buf, allocator, elem.*);
            try buf.appendSlice(allocator, "[]");
        },
        .tuple_ => |elems| {
            try buf.appendSlice(allocator, "#(");
            for (elems, 0..) |e, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try appendTypeRefStr(buf, allocator, e);
            }
            try buf.append(allocator, ')');
        },
        .optional => |inner| {
            try buf.append(allocator, '?');
            try appendTypeRefStr(buf, allocator, inner.*);
        },
        .function => |f| {
            try buf.appendSlice(allocator, "fn(");
            for (f.params, 0..) |p, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try appendTypeRefStr(buf, allocator, p);
            }
            try buf.appendSlice(allocator, ") -> ");
            try appendTypeRefStr(buf, allocator, f.returnType.*);
        },
        .generic => |b| {
            if (b.is_builtin) try buf.append(allocator, '@');
            try buf.appendSlice(allocator, b.name);
            try buf.append(allocator, '<');
            for (b.args, 0..) |a, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try appendTypeRefStr(buf, allocator, a);
            }
            try buf.append(allocator, '>');
        },
        .typeparam => |constraints| {
            try buf.appendSlice(allocator, "typeparam");
            for (constraints, 0..) |c, i| {
                try buf.appendSlice(allocator, if (i == 0) " " else " | ");
                try appendTypeRefStr(buf, allocator, c);
            }
        },
    }
}

fn inferDecl(env: *Env, decl: ast.DeclKind) InferError!?Binding {
    switch (decl) {
        .val => |v| {
            const ty = try inferExpr(env, v.value.*);
            // Bind the DECLARED (annotated) type when present — see
            // `inferDeclTyped`'s `.val` case.
            var bindTy = ty;
            if (v.typeAnnotation) |ann| {
                const annType = try resolveTypeRef(env, ann);
                try unifyAt(env, annType, ty, v.value.getLoc());
                bindTy = annType;
            }
            try env.bind(v.name, bindTy);
            return .{ .name = v.name, .type_ = bindTy };
        },
        .@"fn" => |f| {
            const ty = try inferFnDecl(env, f);
            try env.bind(f.name, ty);
            const sigName = try buildFnSigName(env, f);
            return .{ .name = f.name, .type_ = try env.namedType(sigName) };
        },
        // Type declarations produce a binding whose type name encodes the body.
        .record => |r| {
            const typeName = try buildRecordDeclName(env, r);
            return .{ .name = r.name, .type_ = try env.namedType(typeName) };
        },
        .@"struct" => |s| {
            const typeName = try buildStructDeclName(env, s);
            return .{ .name = s.name, .type_ = try env.namedType(typeName) };
        },
        .@"enum" => |e| {
            const typeName = try buildEnumDeclName(env, e);
            return .{ .name = e.name, .type_ = try env.namedType(typeName) };
        },
        .interface => |d| {
            const typeName = try buildInterfaceDeclName(env, d);
            return .{ .name = d.name, .type_ = try env.namedType(typeName) };
        },
        // A test block produces no binding, but its body must type-check.
        .@"test" => |t| {
            try inferTestDecl(env, t);
            return null;
        },
        // `from "std"` imports mark module namespaces (no value binding) —
        // the untyped path (tests, LSP) needs this too, not just
        // `inferProgramTyped`'s `.use` interception.
        .use => |u| {
            _ = try markStdImports(env, u);
            return null;
        },
        // implement doesn't produce a value binding.
        else => return null,
    }
}

/// Type-check a `test { … }` body like a `fn` body returning void: no async
/// context, no outer loop labels, lenient `throw` checking.
fn inferTestDecl(env: *Env, t: ast.TestDecl) InferError!void {
    const savedThrowCtx = env.throwContext;
    env.throwContext = .unchecked;
    defer env.throwContext = savedThrowCtx;

    const prevStarFn = env.starFn;
    const prevLabelsLen = env.labelStack.items.len;
    defer {
        env.starFn = prevStarFn;
        env.labelStack.shrinkRetainingCapacity(prevLabelsLen);
    }
    env.starFn = null;
    env.labelStack.shrinkRetainingCapacity(0);

    for (t.body) |stmt| {
        _ = try inferExpr(env, stmt.expr);
    }
}

/// Targets accepted by the `external` annotation builtin — must match
/// `enum Target { node, typescript, erlang, beam, wasm }` in builtins.d.bp.
const external_targets = [_][]const u8{ "node", "typescript", "erlang", "beam", "wasm" };

/// Type-checks one `external(target, module, symbol)` annotation against its
/// builtin signature (builtins.d.bp): `fn external(target: Target, module: string, symbol: string)`.
fn validateExternalAnnotation(env: *Env, f: ast.FnDecl, a: ast.Annotation) InferError!void {
    const fnLoc: ?ast.Loc = if (f.body.len > 0) f.body[0].expr.getLoc() else null;
    const fail = struct {
        fn fail(e_: *Env, loc: ?ast.Loc, msg: []const u8, hint: []const u8) InferError {
            var e = TypeError.custom(msg, hint);
            if (loc) |l| e = e.withLoc(l);
            e_.lastError = e;
            return error.TypeError;
        }
    }.fail;
    // RULE: `external` annotations are only valid on `declare fn` declarations
    // — the host symbol replaces the body, so an annotated plain `fn` (with or
    // without a body) is malformed.
    if (!f.isDeclare) {
        return fail(env, fnLoc, "`@[external(…)]` requires a `declare fn` declaration", "Write `@[external(erlang, \"string\", \"length\")] pub declare fn length(s: string) -> i32;`");
    }
    if (a.args.len != 3) {
        return fail(env, fnLoc, "`external` expects exactly 3 arguments: external(target: Target, module: string, symbol: string)", "Example: @[external(erlang, \"string\", \"length\")]");
    }
    // arg0: a `Target` enum member (a bare identifier, optionally `.target`).
    const target = std.mem.trimStart(u8, a.args[0], ".");
    const known = for (external_targets) |t| {
        if (std.mem.eql(u8, t, target)) break true;
    } else false;
    if (!known) {
        return fail(env, fnLoc, "`external` target must be a Target member: node, typescript, erlang, beam or wasm", "Example: @[external(erlang, \"string\", \"length\")]");
    }
    // arg1/arg2: string literals naming the host module and symbol.
    for (a.args[1..]) |arg| {
        if (arg.len < 2 or arg[0] != '"') {
            return fail(env, fnLoc, "`external` module and symbol must be string literals", "Example: @[external(node, \"./gleam_stdlib.mjs\", \"string_length\")]");
        }
    }
}

/// True when `name` names a registered type definition with generic params.
fn typeDefHasGenerics(env: *Env, name: []const u8) bool {
    const td = env.lookupTypeDef(name) orelse return false;
    return switch (td) {
        .record => |r| r.genericParams.len > 0,
        .struct_ => |s| s.genericParams.len > 0,
        .enum_ => |e| e.genericParams.len > 0,
    };
}

/// Per-call-site instantiation of a generic type-def constructor. Without it
/// the registration-time generic cells unify destructively at the first call
/// (`Pair(first: p.second, …)` in one fn would bind `A := B` for every later
/// `Pair(1, "one")` — "expected i32, found string").
fn instantiateCtorType(env: *Env, callee: []const u8, ctorType: *T.Type) InferError!*T.Type {
    if (!typeDefHasGenerics(env, callee)) return ctorType;
    var seen = std.AutoHashMap(*T.TypeCell, *T.Type).init(env.arena);
    defer seen.deinit();
    return instantiateType(env, ctorType, &seen);
}

/// Field type of a generic record instance: substitute the registration-time
/// generic cells with the instance's type args (`p: Pair<i32, string>` →
/// `p.second: string`). The cells are recovered positionally from the
/// constructor binding's return type (`fn(…) -> Pair<A_cell, B_cell>`).
/// Falls back to the registered (shared) field type when the shape doesn't
/// line up — never worse than the previous behavior.
fn instantiateFieldType(env: *Env, typeName: []const u8, instArgs: []*T.Type, fieldType: *T.Type) InferError!*T.Type {
    if (instArgs.len == 0) return fieldType;
    const ctor = env.lookup(typeName) orelse return fieldType;
    const ctorResolved = ctor.deref();
    if (ctorResolved.* != .func) return fieldType;
    const ret = ctorResolved.func.ret.deref();
    if (ret.* != .named or ret.named.args.len != instArgs.len) return fieldType;

    var seen = std.AutoHashMap(*T.TypeCell, *T.Type).init(env.arena);
    defer seen.deinit();
    for (ret.named.args, instArgs) |cellTy, inst| {
        const cellResolved = cellTy.deref();
        if (cellResolved.* != .typeVar) continue;
        try seen.put(cellResolved.typeVar, inst);
    }
    if (seen.count() == 0) return fieldType;
    return instantiateType(env, fieldType, &seen);
}

/// Deep-copies `ty`, substituting every unbound type variable with a fresh
/// one. Per-call-site instantiation for "std" package generic fns — without
/// it the shared fn type would unify destructively at the first call site.
fn instantiateType(env: *Env, ty: *T.Type, seen: *std.AutoHashMap(*T.TypeCell, *T.Type)) InferError!*T.Type {
    const resolved = ty.deref();
    switch (resolved.*) {
        .typeVar => |cell| switch (cell.state) {
            .unbound, .generic => {
                if (seen.get(cell)) |fresh| return fresh;
                const fresh = try env.freshVar();
                try seen.put(cell, fresh);
                return fresh;
            },
            .link => unreachable, // deref follows links
        },
        .named => |n| {
            if (n.args.len == 0) return resolved;
            const args = try env.arena.alloc(*T.Type, n.args.len);
            for (n.args, 0..) |a, i| args[i] = try instantiateType(env, a, seen);
            const node = try env.arena.create(T.Type);
            node.* = .{ .named = .{ .name = n.name, .args = args } };
            return node;
        },
        .func => |f| {
            const params = try env.arena.alloc(*T.Type, f.params.len);
            for (f.params, 0..) |p, i| params[i] = try instantiateType(env, p, seen);
            const node = try env.arena.create(T.Type);
            node.* = .{ .func = .{ .params = params, .ret = try instantiateType(env, f.ret, seen) } };
            return node;
        },
        .union_ => |members| {
            const copies = try env.arena.alloc(*T.Type, members.len);
            for (members, 0..) |m, i| copies[i] = try instantiateType(env, m, seen);
            const node = try env.arena.create(T.Type);
            node.* = .{ .union_ = copies };
            return node;
        },
    }
}

fn inferFnDecl(env: *Env, f: ast.FnDecl) InferError!*T.Type {
    // ── `@[external(…)]` annotation validation (F1) ─────────────────────────
    for (f.annotations) |a| {
        if (std.mem.eql(u8, a.name, "external")) {
            try validateExternalAnnotation(env, f, a);
        }
    }

    // Build generic map.
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    for (f.genericParams) |gp| {
        try genericMap.put(gp.name, try env.freshVar());
    }

    // Collect typeparam constraints so call sites can validate comptime args.
    var typeparams: std.ArrayListUnmanaged(envMod.TypeparamConstraint) = .empty;
    // Collect `expr` meta-kind params so call sites capture their arguments
    // unevaluated (expr-templates F4).
    var exprParams: std.ArrayListUnmanaged(envMod.ExprParamInfo) = .empty;

    // Infer parameter types.
    var paramTypes = try env.arena.alloc(*T.Type, f.params.len);
    for (f.params, 0..) |p, i| {
        if (p.typeRef.isExprType()) {
            // An `@Expr<…>` parameter only exists at compile time — require the
            // `comptime` modifier so the binding-time is visible in the signature.
            if (p.modifier != .@"comptime") {
                env.lastError = TypeError.custom(
                    "an `@Expr` parameter requires the `comptime` modifier",
                    "Write it as `comptime name: @Expr<T>` — template arguments are captured at compile time.",
                ).withLoc(if (f.body.len > 0) f.body[0].expr.getLoc() else ast.Loc{ .line = 1, .col = 1 });
                return error.TypeError;
            }
            try exprParams.append(env.arena, .{ .paramIndex = i, .paramName = p.name });
        }
        if (p.typeRef == .typeparam) {
            const constraints = p.typeRef.typeparam;
            const names = try env.arena.alloc([]const u8, constraints.len);
            for (constraints, 0..) |c, ci| {
                names[ci] = switch (c) {
                    .named => |n| n,
                    else => "",
                };
            }
            try typeparams.append(env.arena, .{ .paramIndex = i, .paramName = p.name, .names = names });
        }
        // `fn(value: T) -> U` param: build a real func type (the typeRef is
        // just `.named "fn"`); names resolve via the generic map first.
        const ty = if (p.fnType) |ft| blk: {
            const fparams = try env.arena.alloc(*T.Type, ft.params.len);
            for (ft.params, 0..) |fp, j| {
                fparams[j] = genericMap.get(fp.typeName) orelse try env.namedType(fp.typeName);
            }
            const fret = if (ft.returnType) |rn|
                genericMap.get(rn) orelse try env.namedType(rn)
            else
                try env.namedType("void");
            break :blk try env.funcType(fparams, fret);
        } else try resolveTypeRefInContext(env, p.typeRef, genericMap);
        paramTypes[i] = ty;
        if (p.destruct) |d| {
            // Destructuring param: bind each field name to its type.
            const tyName: []const u8 = switch (p.typeRef) {
                .named => |n| n,
                else => "",
            };
            const maybeTypeDef = env.typeDefs.get(tyName);
            switch (d) {
                .names => |*n| {
                    for (n.fields) |fld| {
                        const fieldTy = if (maybeTypeDef) |td|
                            if (td.findField(fld.field_name)) |f_| f_.type_ else try env.freshVar()
                        else
                            try env.freshVar();
                        try env.bind(fld.bind_name, fieldTy);
                    }
                },
                .tuple_ => |t| {
                    // For tuple destructuring, we'd need the tuple element types.
                    // For now, bind each name to a fresh type variable.
                    for (t) |fname| {
                        try env.bind(fname, try env.freshVar());
                    }
                },
                .list => {}, // List destructuring — no bindings to infer
                .ctor => {}, // Constructor destructuring — handled by pattern matching
            }
        } else {
            try env.bind(p.name, ty);
        }
    }

    // Infer return type.
    const retType = if (f.returnType) |rt|
        try resolveTypeRefInContext(env, rt, genericMap)
    else
        try env.namedType("void");

    // The return type decides whether `use` is allowed in the body and which
    // ContextBase every `use` must agree on (@Context F7). Scope it to the body.
    const savedFnCtx = env.fnContext;
    env.fnContext = try contextInfoFromReturn(env, f.returnType);
    defer env.fnContext = savedFnCtx;

    // A `-> @Expr<…>` return marks a template function: its body runs at
    // comptime, enabling the `@expr`/`@code` construction builtins.
    const savedInTemplate = env.inTemplateFn;
    env.inTemplateFn = if (f.returnType) |rt| rt.isExprType() else false;
    defer env.inTemplateFn = savedInTemplate;

    // Determine how `throw` is checked inside this body:
    //   - no declared return type      → unchecked (lenient: e.g. `catch throw …`)
    //   - `*fn -> @Result<D, E>`       → checked-Result effect: thrown value must
    //     match `E`; `return`/`throw` construct `{ok, V}`/`{error, E}` values
    //   - plain `fn -> @Result<D, E>`  → NO special treatment: `throw` stays a
    //     raw host exception (unchecked), values are not wrapped
    //   - any other return type        → `throw` is illegal
    const isResultFn = f.returnsResult();
    var throwCtx: envMod.ThrowContext = .unchecked;
    if (f.returnType) |_| {
        throwCtx = .plain;
        if (isResultFn) {
            throwCtx = .unchecked;
            if (f.isStarFn) {
                const rtDeref = retType.deref();
                if (rtDeref.* == .named and rtDeref.named.args.len >= 2) {
                    throwCtx = .{ .result = rtDeref.named.args[1] };
                }
            }
        }
    }
    const savedThrowCtx = env.throwContext;
    env.throwContext = throwCtx;
    defer env.throwContext = savedThrowCtx;

    // ── `*fn` validation + async/generator context ──────────────────────────
    // A `*fn` must return `@Future<_>` / `@Iterator<_>` / `@AsyncIterator<_, _>`
    // — or `@Result<_, _>` (the checked-Result effect form); a normal `fn` must
    // NOT return the async kinds (it would have to be a `*fn`).
    const asyncKind = classifyAsyncReturn(retType);
    const fnLoc: ?ast.Loc = if (f.body.len > 0) f.body[0].expr.getLoc() else null;
    if (f.isStarFn and asyncKind == .none and !isResultFn) {
        var e = TypeError.custom(
            "a `*fn` must return `@Future<_>`, `@Iterator<_>`, `@AsyncIterator<_, _>` or `@Result<_, _>`",
            "Drop the `*` if this is a plain function, or change the return type.",
        );
        if (fnLoc) |l| e = e.withLoc(l);
        env.lastError = e;
        return error.TypeError;
    }
    if (!f.isStarFn and asyncKind != .none) {
        var e = TypeError.custom(
            "a function returning `@Future`/`@Iterator`/`@AsyncIterator` must be declared `*fn`",
            "Prefix the function with `*` to make it async/generator.",
        );
        if (fnLoc) |l| e = e.withLoc(l);
        env.lastError = e;
        return error.TypeError;
    }

    // Establish the `*fn` context (saved/restored around the body) so nested
    // `await`/`yield` validate against this function, not an enclosing one.
    const prevStarFn = env.starFn;
    const prevLabelsLen = env.labelStack.items.len;
    defer {
        env.starFn = prevStarFn;
        env.labelStack.shrinkRetainingCapacity(prevLabelsLen);
    }
    if (f.isStarFn and !isResultFn) {
        env.starFn = starCtxFromReturn(retType, asyncKind);
        if (f.label) |lbl| try env.labelStack.append(env.arena, lbl);
    } else {
        // A normal function body (and a `*fn -> @Result` checked-Result body)
        // sees no async context and no outer labels — `await`/`yield` stay
        // exclusive to `@Future`/`@Iterator` star fns.
        env.starFn = null;
        env.labelStack.shrinkRetainingCapacity(0);
    }

    // Self-recursion: bind the fn's own signature before walking the body so
    // `pushRange(out, start + 1, stop)` inside `pushRange` resolves. (Mutual
    // recursion across decls still needs a program-level pre-pass.)
    try env.bind(f.name, try env.funcType(paramTypes, retType));

    // Infer body (for type checking; we ignore the result for now).
    for (f.body) |stmt| {
        _ = try inferExpr(env, stmt.expr);
    }

    if (typeparams.items.len > 0) {
        try env.registerTypeparams(f.name, try typeparams.toOwnedSlice(env.arena));
    }
    if (exprParams.items.len > 0) {
        try env.registerExprParams(f.name, try exprParams.toOwnedSlice(env.arena));
    }
    // A function returning `expr [T]` is a template function: its calls are
    // expanded at comptime (F6) and the declaration never reaches codegen.
    if (f.returnType) |rt| {
        if (rt.isExprType()) try env.templateFns.put(f.name, f);
    }

    return env.funcType(paramTypes, retType);
}

const AsyncReturnKind = enum { none, future, iterator, asyncIterator };

/// Classify a resolved return type as `@Future` / `@Iterator` / `@AsyncIterator`.
fn classifyAsyncReturn(ty: *T.Type) AsyncReturnKind {
    const t = ty.deref();
    return switch (t.*) {
        .named => |n| if (std.mem.eql(u8, n.name, "Future"))
            .future
        else if (std.mem.eql(u8, n.name, "Iterator"))
            .iterator
        else if (std.mem.eql(u8, n.name, "AsyncIterator"))
            .asyncIterator
        else
            .none,
        else => .none,
    };
}

/// Build the `*fn` body context from its (already classified) return type.
fn starCtxFromReturn(ty: *T.Type, kind: AsyncReturnKind) envMod.StarFnCtx {
    const t = ty.deref();
    const item: ?*T.Type = switch (t.*) {
        .named => |n| if (n.args.len >= 1) n.args[0] else null,
        else => null,
    };
    return switch (kind) {
        .future => .{ .allowsAwait = true, .iterItem = null },
        .iterator => .{ .allowsAwait = false, .iterItem = item },
        .asyncIterator => .{ .allowsAwait = true, .iterItem = item },
        .none => .{ .allowsAwait = false, .iterItem = null },
    };
}

// ── expression inference ──────────────────────────────────────────────────────

fn isIntType(t: *T.Type) bool {
    return t.isNamed("i8") or t.isNamed("u8") or
        t.isNamed("i16") or t.isNamed("u16") or
        t.isNamed("i32") or t.isNamed("u32") or
        t.isNamed("i64") or t.isNamed("u64") or
        t.isNamed("isize") or t.isNamed("usize");
}

fn isFloatType(t: *T.Type) bool {
    return t.isNamed("f32") or t.isNamed("f64");
}

/// True when `t` satisfies a single typeparam constraint named `name`.
/// Besides exact name matches, the category names `int` and `float` match any
/// integer / floating-point primitive respectively.
fn typeSatisfiesConstraint(t: *T.Type, name: []const u8) bool {
    if (t.isNamed(name)) return true;
    if (std.mem.eql(u8, name, "int")) return isIntType(t);
    if (std.mem.eql(u8, name, "float")) return isFloatType(t);
    return false;
}

/// True when index `i` names a typeparam parameter in `constraints`.
fn isTypeparamIndex(constraints: []const envMod.TypeparamConstraint, i: usize) bool {
    for (constraints) |c| {
        if (c.paramIndex == i) return true;
    }
    return false;
}

/// The `expr` param info for parameter index `i`, or null when `i` is an
/// ordinary parameter.
fn exprParamAt(params: []const envMod.ExprParamInfo, i: usize) ?envMod.ExprParamInfo {
    for (params) |p| {
        if (p.paramIndex == i) return p;
    }
    return null;
}

/// Type-check and capture an argument bound to a `comptime p: expr T`
/// parameter (expr-templates F4). The argument unifies against the **inner**
/// `T` — it is an expression *of* `T`, not a value of `expr T` — and is
/// captured unevaluated with provenance (module path, location, origin-scope
/// snapshot) for the call-site expansion pass (F6).
///
/// V1 rule (spec): a source-capable template requires a **literal** string at
/// the call site (single or multiline, interpolation allowed) — a variable
/// carries no span or scope to attach.
fn captureExprArg(
    env: *Env,
    callee: []const u8,
    param: envMod.ExprParamInfo,
    rawArg: *const ast.Expr,
    typedArg: ast.CallArgOf(.typed),
    paramType: *T.Type,
) InferError!template.CapturedExpr {
    // Inner `T` of `expr T` (`expr` is encoded as a named type with one arg);
    // a bare `expr` param already carries a fresh var as its arg.
    const pDeref = paramType.deref();
    const inner: *T.Type = if (pDeref.* == .named and pDeref.named.args.len == 1)
        pDeref.named.args[0]
    else
        try env.freshVar();
    try unifyAt(env, inner, typedArg.value.getType(), typedArg.value.getLoc());

    // V1 literal rule. `text` stays null for `${…}` templates — the parts
    // live on the captured node. A hole-less multiline literal arrives as a
    // plain `stringLit` whose content keeps the `\n` after the opening `"""`,
    // so newline presence doubles as the multiline flag.
    var text: ?[]const u8 = null;
    var multiline = false;
    var isLiteral = false;
    // The lexer stamps a multiline literal with the line of its *closing*
    // `"""`; subtract the content's newlines to recover the opening line so
    // span mapping starts from where the template begins.
    var newlines: usize = 0;
    if (rawArg.* == .literal) {
        switch (rawArg.literal.kind) {
            .stringLit => |s| {
                text = s;
                newlines = std.mem.count(u8, s, "\n");
                multiline = newlines > 0;
                isLiteral = true;
            },
            .stringTemplate => |t| {
                multiline = t.multiline;
                // `${…}` holes are assumed single-line in V1.
                for (t.parts) |p| switch (p) {
                    .text => |s| newlines += std.mem.count(u8, s, "\n"),
                    .expr => {},
                };
                isLiteral = true;
            },
            else => {},
        }
    }
    if (!isLiteral) {
        env.lastError = TypeError.custom(
            "an `expr` argument must be a literal string at the call site",
            "Write the template inline — `f \"\"\"…\"\"\"` or `f(\"…\")`; a variable carries no span or scope to capture (V1).",
        ).withLoc(typedArg.value.getLoc());
        return error.TypeError;
    }

    const litLoc = rawArg.getLoc();
    return template.CapturedExpr{
        .callee = callee,
        .paramIndex = param.paramIndex,
        .paramName = param.paramName,
        .node = rawArg,
        .text = text,
        .multiline = multiline,
        .loc = .{ .line = litLoc.line -| newlines, .col = litLoc.col },
        .modulePath = env.modulePath,
        .scope = env.scopeSnapshot,
    };
}

// ── template call-site expansion (expr-templates F6, V1 driver) ───────────────

/// Expand a call to a template function (`-> @Expr<…>`) at the call site.
///
/// The V1 driver expands bodies of the form `return E` where `E` is an
/// identifier naming an `@Expr` parameter (pass-through: the captured
/// template splices in), `@expr(E)` (explicit value/expression lift), or
/// `@code("…")` (parse generated source text into code). Construction is
/// always explicit — there is no implicit value lifting. Richer bodies
/// (template methods, control flow) need the comptime evaluation runtime —
/// F6-full, not this driver.
///
/// Splice + re-check: the expansion is re-inferred in the *caller's*
/// environment, then checked against a bounded return (`-> @Expr<T>`); a
/// bare `-> @Expr` reveals the expansion's own structural type per call
/// site. The expansion is recorded in `env.templateExpansions` (keyed by
/// call loc) and substituted into the untyped AST by the transform pass —
/// codegen never sees the call or the template function.
fn expandTemplateCall(
    env: *Env,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    retType: *T.Type,
    loc: ast.Loc,
) InferError!TypedExpr {
    const body = classifyTemplateBody(tfn, captures) orelse {
        // Not reducible by inspection — run the body in the eval runtime
        // (F6-full). Tooling paths carry no eval context and keep the error.
        if (env.templateEval != null) {
            return expandTemplateCallViaRuntime(env, tfn, captures, retType, loc);
        }
        env.lastError = TypeError.custom(
            "cannot expand this template function at compile time",
            "The V1 expansion driver supports bodies of the form `return <@Expr param>`, `return @expr(value)`, or `return @code(\"…\")` with a literal string; richer bodies need the eval runtime (full `compile` pipeline).",
        ).withLoc(loc);
        return error.TypeError;
    };

    const expansion: *const ast.Expr = switch (body) {
        .capture, .lifted => |node| node,
        .code => |src| parseCodeText(env, src) orelse {
            env.lastError = TypeError.custom(
                "the `@code(…)` text does not parse as an expression",
                "The string handed to `@code` must be a single well-formed botopink expression.",
            ).withLoc(loc);
            return error.TypeError;
        },
    };

    return finishExpansion(env, expansion, retType, loc);
}

/// Splice + re-check the chosen expansion in the caller's environment, verify
/// a concrete `-> @Expr<T>` bound (an unconstrained generic reveals the type
/// per call site instead), and record the substitution for the transform pass.
fn finishExpansion(env: *Env, expansion: *const ast.Expr, retType: *T.Type, loc: ast.Loc) InferError!TypedExpr {
    const typed = try inferExprTyped(env, expansion.*);

    const rDeref = retType.deref();
    if (rDeref.* == .named and std.mem.eql(u8, rDeref.named.name, "Expr") and rDeref.named.args.len == 1) {
        const bound = rDeref.named.args[0];
        if (bound.deref().* != .typeVar) {
            try unifyAt(env, bound, typed.getType(), loc);
        }
    }

    try env.templateExpansions.put(loc, expansion);
    return typed;
}

/// Run the template body in the node eval runtime and turn the protocol
/// result into an expansion (F6-full, slice 1). Limits (recorded follow-ups):
/// every parameter must be an `@Expr` capture (runtime params have no
/// comptime value) and captured templates must be hole-free (`${…}` parts
/// cannot cross into the evaluator yet).
fn expandTemplateCallViaRuntime(
    env: *Env,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    retType: *T.Type,
    loc: ast.Loc,
) InferError!TypedExpr {
    const ctx = env.templateEval.?;

    if (captures.len != tfn.params.len) {
        env.lastError = TypeError.custom(
            "a template function can only take `@Expr` parameters (V1)",
            "Runtime parameters have no value at compile time — capture everything the template needs as `comptime p: @Expr<…>`.",
        ).withLoc(loc);
        return error.TypeError;
    }
    // Memoize by callee + capture texts — hole-free captures only: a holed
    // template's expansion embeds the call site's own hole expressions, so
    // equal text parts at two sites would alias the wrong holes.
    var holed = false;
    for (captures) |cap| {
        if (cap.text == null) holed = true;
    }
    const memoKey: ?[]const u8 = if (holed) null else blk: {
        var buf: std.ArrayListUnmanaged(u8) = .empty;
        buf.appendSlice(env.arena, tfn.name) catch return error.OutOfMemory;
        for (captures) |cap| {
            buf.append(env.arena, 0) catch return error.OutOfMemory;
            buf.appendSlice(env.arena, cap.text.?) catch return error.OutOfMemory;
        }
        break :blk buf.toOwnedSlice(env.arena) catch return error.OutOfMemory;
    };
    if (memoKey) |key| {
        if (env.templateEvalCache.get(key)) |cached| {
            return finishExpansion(env, cached, retType, loc);
        }
    }

    const outcome = templateEval.evaluate(env.arena, ctx.io, ctx.build_root, tfn, captures) catch {
        env.lastError = TypeError.custom(
            "the template evaluator failed to run",
            "Template bodies are evaluated by the node runtime at compile time — check that `node` is available.",
        ).withLoc(loc);
        return error.TypeError;
    };

    const expansion: *const ast.Expr = switch (outcome) {
        .code => |src| blk: {
            const parsed = parseCodeText(env, src) orelse {
                env.lastError = TypeError.custom(
                    "the code built by the template does not parse as an expression",
                    "`build(…)`/`@code(…)` output must be a single well-formed botopink expression.",
                ).withLoc(loc);
                return error.TypeError;
            };
            // Splice the caller's `${…}` hole expressions back in place of
            // the `__bp_hole_<param>_<i>` placeholders the template embedded.
            substituteHoles(@constCast(parsed), captures);
            break :blk parsed;
        },
        .capture => |param| captureNodeFor(captures, param) orelse {
            env.lastError = TypeError.custom(
                "the template returned an unknown capture",
                "This is a template-evaluator protocol bug — please report it.",
            ).withLoc(loc);
            return error.TypeError;
        },
        .value => |v| literalFromJson(env, v, loc) orelse {
            env.lastError = TypeError.custom(
                "the template's `@expr(…)` value cannot be lifted as a literal",
                "V1 lifts numbers, strings, booleans, null, and arrays of those.",
            ).withLoc(loc);
            return error.TypeError;
        },
        .fail => |f| {
            const cap: ?*const template.CapturedExpr = blk: {
                if (f.param) |pn| for (captures) |*c| {
                    if (std.mem.eql(u8, c.paramName, pn)) break :blk c;
                };
                break :blk if (captures.len > 0) &captures[0] else null;
            };
            if (cap) |c| {
                env.lastError = template.failDiagnostic(c, f.span, f.message);
            } else {
                env.lastError = TypeError.custom(f.message, "raised by the template function via `fail`/`failAt`").withLoc(loc);
            }
            return error.TypeError;
        },
        .err => |msg| {
            env.lastError = TypeError.custom(
                msg,
                "Thrown while evaluating the template function's body at compile time.",
            ).withLoc(loc);
            return error.TypeError;
        },
    };

    if (memoKey) |key| {
        env.templateEvalCache.put(key, expansion) catch return error.OutOfMemory;
    }
    return finishExpansion(env, expansion, retType, loc);
}

/// Replace `__bp_hole_<param>_<i>` placeholder identifiers in freshly parsed
/// template output with the caller's hole expressions (the i-th `${…}` part
/// of the named capture). The parsed tree is private to this expansion, so
/// in-place mutation is safe.
fn substituteHoles(e: *ast.Expr, captures: []const template.CapturedExpr) void {
    switch (e.*) {
        .identifier => |id| switch (id.kind) {
            .ident => |name| {
                const hole = holeForPlaceholder(name, captures) orelse return;
                e.* = hole.*;
            },
            .identAccess => |ia| substituteHoles(ia.receiver, captures),
            else => {},
        },
        .binaryOp => |b| {
            substituteHoles(b.lhs, captures);
            substituteHoles(b.rhs, captures);
        },
        .unaryOp => |u| substituteHoles(u.expr, captures),
        .call => |c| switch (c.kind) {
            .call => |cc| {
                if (cc.receiver) |r| substituteHoles(r, captures);
                for (cc.args) |arg| substituteHoles(arg.value, captures);
            },
            .pipeline => |pl| {
                substituteHoles(pl.lhs, captures);
                substituteHoles(pl.rhs, captures);
            },
        },
        .collection => |col| switch (col.kind) {
            .grouped => |g| substituteHoles(g, captures),
            .arrayLit => |al| for (al.elems) |*elem| substituteHoles(elem, captures),
            .tupleLit => |tl| for (tl.elems) |*elem| substituteHoles(elem, captures),
            else => {},
        },
        .literal => |lit| switch (lit.kind) {
            .stringTemplate => |t| for (t.parts) |part| switch (part) {
                .text => {},
                .expr => |hole| substituteHoles(hole, captures),
            },
            else => {},
        },
        else => {},
    }
}

/// Resolve a `__bp_hole_<param>_<i>` placeholder to the i-th `${…}` hole
/// expression of the named capture, or null for ordinary identifiers.
fn holeForPlaceholder(name: []const u8, captures: []const template.CapturedExpr) ?*const ast.Expr {
    const prefix = "__bp_hole_";
    if (!std.mem.startsWith(u8, name, prefix)) return null;
    const rest = name[prefix.len..];
    const sep = std.mem.lastIndexOfScalar(u8, rest, '_') orelse return null;
    const param = rest[0..sep];
    const idx = std.fmt.parseInt(usize, rest[sep + 1 ..], 10) catch return null;

    for (captures) |cap| {
        if (!std.mem.eql(u8, cap.paramName, param)) continue;
        if (cap.node.* != .literal or cap.node.literal.kind != .stringTemplate) return null;
        var holeIdx: usize = 0;
        for (cap.node.literal.kind.stringTemplate.parts) |part| switch (part) {
            .text => {},
            .expr => |hole| {
                if (holeIdx == idx) return hole;
                holeIdx += 1;
            },
        };
        return null;
    }
    return null;
}

/// Build a literal expression from a JSON value produced by `@expr(…)` in
/// the eval runtime (V1: numbers, strings, booleans, null, arrays of those).
fn literalFromJson(env: *Env, v: std.json.Value, loc: ast.Loc) ?*const ast.Expr {
    const node = env.arena.create(ast.Expr) catch return null;
    switch (v) {
        .integer => |n| {
            const text = std.fmt.allocPrint(env.arena, "{d}", .{n}) catch return null;
            node.* = .{ .literal = .{ .loc = loc, .kind = .{ .numberLit = text } } };
        },
        .float => |f| {
            const text = std.fmt.allocPrint(env.arena, "{d}", .{f}) catch return null;
            node.* = .{ .literal = .{ .loc = loc, .kind = .{ .numberLit = text } } };
        },
        .string => |str| {
            const text = env.arena.dupe(u8, str) catch return null;
            node.* = .{ .literal = .{ .loc = loc, .kind = .{ .stringLit = text } } };
        },
        .bool => |b| {
            node.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = if (b) "true" else "false" } } };
        },
        .null => {
            node.* = .{ .literal = .{ .loc = loc, .kind = .null_ } };
        },
        .array => |items| {
            const elems = env.arena.alloc(ast.Expr, items.items.len) catch return null;
            for (items.items, 0..) |item, i| {
                const elem = literalFromJson(env, item, loc) orelse return null;
                elems[i] = elem.*;
            }
            node.* = .{ .collection = .{ .loc = loc, .kind = .{ .arrayLit = .{ .elems = elems } } } };
        },
        else => return null,
    }
    return node;
}

/// What a V1-expandable template body (`return E`) reduces to. Construction
/// is explicit: no implicit value lifting — a constant only becomes code via
/// `@expr(…)`, and generated source only via `@code(…)`.
const TemplateBody = union(enum) {
    /// `return <expr param>` — the captured argument splices in unchanged.
    capture: *const ast.Expr,
    /// `return @expr(E)` — lift the explicit expression as code.
    lifted: *const ast.Expr,
    /// `return @code("…")` — parse the source text into code.
    code: []const u8,
};

/// Classify a template body for the V1 expansion driver, or null when the
/// body needs the runtime-backed evaluator (F6-full).
fn classifyTemplateBody(tfn: ast.FnDecl, captures: []const template.CapturedExpr) ?TemplateBody {
    if (tfn.body.len != 1) return null;
    const stmt = tfn.body[0];
    if (stmt.expr != .jump) return null;
    if (stmt.expr.jump.kind != .@"return") return null;
    const ret = stmt.expr.jump.kind.@"return" orelse return null;

    switch (ret.*) {
        // `return template` — pass-through: an @Expr param IS an expr value.
        .identifier => |id| {
            if (id.kind != .ident) return null;
            const node = captureNodeFor(captures, id.kind.ident) orelse return null;
            return .{ .capture = node };
        },
        // `return @expr(E)` / `return @code("…")` — explicit construction.
        .call => |c| {
            if (c.kind != .call) return null;
            const cc = c.kind.call;
            if (!cc.is_builtin or cc.args.len != 1) return null;
            const arg = cc.args[0].value;
            if (std.mem.eql(u8, cc.callee, "expr")) {
                // A lifted expression must not reference the template's own
                // parameters — splicing `t` into the caller would leave an
                // unbound name. Such bodies go to the eval runtime instead.
                for (tfn.params) |p| {
                    if (specializeMod.identInExpr(arg.*, p.name)) return null;
                }
                return if (isV1Liftable(arg)) .{ .lifted = arg } else null;
            }
            if (std.mem.eql(u8, cc.callee, "code")) {
                if (arg.* == .literal and arg.literal.kind == .stringLit) {
                    return .{ .code = arg.literal.kind.stringLit };
                }
                return null;
            }
            return null;
        },
        else => return null,
    }
}

/// Parse `@code` source text into an expression (allocated in the env arena).
/// Null when the text fails to lex/parse as a single expression.
fn parseCodeText(env: *Env, src: []const u8) ?*const ast.Expr {
    var lx = Lexer.init(src);
    const tokens = lx.scanAll(env.arena) catch return null;
    var p = Parser.init(tokens);
    const node = env.arena.create(ast.Expr) catch return null;
    node.* = p.parseExpr(env.arena) catch return null;
    if (!p.check(.endOfFile)) return null;
    return node;
}

/// The captured argument bound to the `@Expr` parameter named `name`.
fn captureNodeFor(captures: []const template.CapturedExpr, name: []const u8) ?*const ast.Expr {
    for (captures) |cap| {
        if (std.mem.eql(u8, cap.paramName, name)) return cap.node;
    }
    return null;
}

/// True when `e` is a V1-liftable expression for `@expr(…)` — literals,
/// identifiers, operators, calls, collections. Control flow is conservatively
/// left to the runtime-backed evaluator (F6-full).
fn isV1Liftable(e: *const ast.Expr) bool {
    return switch (e.*) {
        .comptime_ => |ct| switch (ct.kind) {
            .comptimeExpr => |inner| isV1Liftable(inner),
            else => false,
        },
        .literal => |lit| switch (lit.kind) {
            .stringTemplate => |t| blk: {
                for (t.parts) |p| switch (p) {
                    .text => {},
                    .expr => |hole| if (!isV1Liftable(hole)) break :blk false,
                };
                break :blk true;
            },
            else => true,
        },
        .identifier => |id| switch (id.kind) {
            .identAccess => |ia| isV1Liftable(ia.receiver),
            else => true,
        },
        .binaryOp => |b| isV1Liftable(b.lhs) and isV1Liftable(b.rhs),
        .unaryOp => |u| isV1Liftable(u.expr),
        .call => |c| switch (c.kind) {
            .call => |cc| blk: {
                if (cc.receiver) |r| if (!isV1Liftable(r)) break :blk false;
                for (cc.args) |a| if (!isV1Liftable(a.value)) break :blk false;
                break :blk true;
            },
            .pipeline => |p| isV1Liftable(p.lhs) and isV1Liftable(p.rhs),
        },
        .collection => |col| switch (col.kind) {
            .grouped => |g| isV1Liftable(g),
            .arrayLit => |al| blk: {
                for (al.elems) |*elem| if (!isV1Liftable(elem)) break :blk false;
                break :blk true;
            },
            .tupleLit => |tl| blk: {
                for (tl.elems) |*elem| if (!isV1Liftable(elem)) break :blk false;
                break :blk true;
            },
            else => false,
        },
        else => false,
    };
}

/// Validate every constrained typeparam argument of a call against its declared
/// constraints. Unconstrained typeparams (empty `names`) accept any type.
/// On violation: sets `env.lastError` and returns `error.TypeError`.
fn validateTypeparams(
    env: *Env,
    constraints: []const envMod.TypeparamConstraint,
    typedArgs: []ast.CallArgOf(.typed),
) InferError!void {
    for (constraints) |c| {
        if (c.names.len == 0) continue; // unconstrained — accepts any type
        if (c.paramIndex >= typedArgs.len) continue;
        const argType = typedArgs[c.paramIndex].value.getType();
        var ok = false;
        for (c.names) |name| {
            if (typeSatisfiesConstraint(argType, name)) {
                ok = true;
                break;
            }
        }
        if (!ok) {
            env.lastError = TypeError
                .typeparamConstraint(c.paramName, argType, c.names)
                .withLoc(typedArgs[c.paramIndex].value.getLoc());
            return error.TypeError;
        }
    }
}

/// Calls `unify` and, if it fails, stamps the expression's location onto the error.
fn unifyAt(env: *Env, a: *T.Type, b: *T.Type, loc: ast.Loc) InferError!void {
    unify(env, a, b) catch |err| {
        if (env.lastError) |*e| e.loc = loc;
        return err;
    };
}
fn inferBuiltinCallReturnType(
    env: *Env,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
) InferError!*T.Type {
    // ── `@Expr` construction builtins (expr-templates) ───────────────────────
    // Construction is explicit: `@expr(value)` lifts a comptime value as code
    // and `@code(text)` parses generated source text. Both only make sense
    // inside a template function (`-> @Expr<…>`), whose body runs at comptime.
    if (std.mem.eql(u8, callee, "expr") or std.mem.eql(u8, callee, "code")) {
        if (!env.inTemplateFn) {
            var e = TypeError.custom(
                "`@expr`/`@code` build comptime code — only valid inside a template function",
                "Declare the enclosing fn with a `-> @Expr<…>` return type.",
            );
            if (typedArgs.len >= 1) e = e.withLoc(typedArgs[0].value.getLoc());
            env.lastError = e;
            return error.TypeError;
        }
        if (std.mem.eql(u8, callee, "expr")) {
            // `@expr(v)`: the result is an expression OF the value's type.
            const inner: *T.Type = if (typedArgs.len >= 1) typedArgs[0].value.getType() else try env.freshVar();
            return env.namedTypeArgs("Expr", &.{inner});
        }
        // `@code(text)`: the produced expression's type is revealed at expansion.
        if (typedArgs.len >= 1) {
            try unifyAt(env, try env.namedType("string"), typedArgs[0].value.getType(), typedArgs[0].value.getLoc());
        }
        return env.namedTypeArgs("Expr", &.{try env.freshVar()});
    }

    if (std.mem.eql(u8, callee, "block")) {
        if (typedTrailing.len > 0) {
            const body = typedTrailing[0].body;
            if (body.len > 0) return body[body.len - 1].expr.getType();
        }
        return env.namedType("void");
    }
    if (std.mem.eql(u8, callee, "src") or
        std.mem.eql(u8, callee, "embedFile") or
        std.mem.eql(u8, callee, "typeName") or
        std.mem.eql(u8, callee, "tagName"))
    {
        return env.namedType("string");
    }
    if (std.mem.eql(u8, callee, "sizeOf") or std.mem.eql(u8, callee, "alignOf")) {
        return env.namedType("i32");
    }
    if (std.mem.eql(u8, callee, "min") or
        std.mem.eql(u8, callee, "max") or
        std.mem.eql(u8, callee, "abs") or
        std.mem.eql(u8, callee, "as") or
        std.mem.eql(u8, callee, "field") or
        std.mem.eql(u8, callee, "typeOf"))
    {
        if (typedArgs.len > 0) return typedArgs[0].value.getType();
        return env.freshVar();
    }
    return env.namedType("void");
}

fn unwrapResultType(ty: *T.Type) ?*T.Type {
    const t = ty.deref();
    return switch (t.*) {
        .named => |n| if (std.mem.eql(u8, n.name, "Result") and n.args.len >= 1)
            n.args[0]
        else
            null,
        else => null,
    };
}

/// Unwrap the Ok type of a `@Result<D, E>` operand for `try`/`catch`.
/// A still-unresolved type variable is allowed (its `Result`-ness is unknown);
/// any other concrete non-Result type is a compile-time error.
fn tryUnwrapOrError(env: *Env, rawTy: *T.Type, loc: ast.Loc) InferError!*T.Type {
    if (unwrapResultType(rawTy)) |ty| return ty;
    const d = rawTy.deref();
    if (d.* == .typeVar) return rawTy;
    env.lastError = TypeError.tryOnNonResult(d).withLoc(loc);
    return InferError.TypeError;
}

/// `@Future<T>` -> `T`. Returns null when `ty` is not a `Future`.
fn unwrapFutureType(ty: *T.Type) ?*T.Type {
    const t = ty.deref();
    return switch (t.*) {
        .named => |n| if (std.mem.eql(u8, n.name, "Future") and n.args.len >= 1)
            n.args[0]
        else
            null,
        else => null,
    };
}

/// `@Iterator<T>` / `@AsyncIterator<T, E>` -> `T`. Returns null when `ty` is not an iterator.
fn unwrapIteratorType(ty: *T.Type) ?*T.Type {
    const t = ty.deref();
    return switch (t.*) {
        .named => |n| if ((std.mem.eql(u8, n.name, "Iterator") or
            std.mem.eql(u8, n.name, "AsyncIterator")) and n.args.len >= 1)
            n.args[0]
        else
            null,
        else => null,
    };
}

/// Shallow structural equality check ---- used by case-arm deduplication.
/// Does NOT unify type variables; treats any typeVar as distinct from a named type.
fn typesSameShape(a: *T.Type, b: *T.Type) bool {
    const ta = a.deref();
    const tb = b.deref();
    if (ta == tb) return true;
    return switch (ta.*) {
        .named => |na| switch (tb.*) {
            .named => |nb| std.mem.eql(u8, na.name, nb.name),
            else => false,
        },
        .union_ => |ua| switch (tb.*) {
            .union_ => |ub| ua.len == ub.len,
            else => false,
        },
        .typeVar => switch (tb.*) {
            .typeVar => |cellB| ta.typeVar == cellB,
            else => false,
        },
        else => false,
    };
}

/// Resolve an `ast.TypeRef` to a `*T.Type` using a generic-parameter map.
/// Used when the type ref appears inside a generic context (record/enum registration).
fn resolveTypeRefInContext(env: *Env, ref: ast.TypeRef, genericMap: std.StringHashMap(*T.Type)) InferError!*T.Type {
    switch (ref) {
        .named => |n| return env.resolveTypeName(n, genericMap),
        .array => |elem| {
            const elemTy = try resolveTypeRefInContext(env, elem.*, genericMap);
            const args = try env.arena.alloc(*T.Type, 1);
            args[0] = elemTy;
            return env.namedTypeArgs("array", args);
        },
        .tuple_ => |elems| {
            const args = try env.arena.alloc(*T.Type, elems.len);
            for (elems, 0..) |e, i| args[i] = try resolveTypeRefInContext(env, e, genericMap);
            return env.namedTypeArgs("tuple", args);
        },
        .optional => |inner| {
            const innerTy = try resolveTypeRefInContext(env, inner.*, genericMap);
            const args = try env.arena.alloc(*T.Type, 1);
            args[0] = innerTy;
            return env.namedTypeArgs("optional", args);
        },
        .function => |f| {
            // Build a `.func` type so a `fn(A, B) -> R` annotation unifies with
            // lambda/anonymous-function values, propagating the annotated param
            // and return types into the value's fresh type variables.
            const paramTypes = try env.arena.alloc(*T.Type, f.params.len);
            for (f.params, 0..) |p, i| {
                paramTypes[i] = try resolveTypeRefInContext(env, p, genericMap);
            }
            const returnType = try resolveTypeRefInContext(env, f.returnType.*, genericMap);
            return env.funcType(paramTypes, returnType);
        },
        .generic => |b| {
            const args = try env.arena.alloc(*T.Type, b.args.len);
            for (b.args, 0..) |a, i| {
                args[i] = try resolveTypeRefInContext(env, a, genericMap);
            }
            // The builtin `@Option<T>` is the canonical form of the optional type
            // `?T` — normalise it so both share one representation (and one set of
            // `.map` / `.flatMap` / `.unwrapOr` lowerings).
            // `@Expr<T>` is encoded like `optional`/`array` — a named type with
            // one arg, so structural unification gives `@Expr<T> ~ @Expr<U>
            // iff T ~ U` for free. The generic parameter is mandatory; a type
            // only the expansion knows is an ordinary fn generic
            // (`fn yaml<T>(…) -> @Expr<T>`), resolved via `genericMap` above.
            // `Array<T>` is the canonical spelling of the array type `T[]` —
            // normalise it so annotations unify with array-literal inference
            // (`[1, 2]` infers as named "array").
            const name = if (b.is_builtin and std.mem.eql(u8, b.name, "Option"))
                "optional"
            else if (std.mem.eql(u8, b.name, "Array"))
                "array"
            else
                b.name;
            return env.namedTypeArgs(name, args);
        },
        // A comptime typeparam accepts a value of any type at the call site;
        // its constraints are validated separately (see `validateTypeparams`).
        // Resolve to a fresh variable so unification against it never fails.
        .typeparam => return env.freshVar(),
    }
}

/// Resolve an `ast.TypeRef` annotation to a `*T.Type` (no generic context).
fn resolveTypeRef(env: *Env, ref: ast.TypeRef) InferError!*T.Type {
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    return resolveTypeRefInContext(env, ref, genericMap);
}

/// Infer the type of an expression, returning a *Type.
/// On type error: sets `env.lastError` and returns `error.TypeError`.
/// This is a thin wrapper around `inferExprTyped` ---- it discards the typed node.
pub fn inferExpr(env: *Env, expr: ast.Expr) InferError!*T.Type {
    return (try inferExprTyped(env, expr)).getType();
}

// ── typed expression construction ─────────────────────────────────────────────

const TypedExpr = ast.TypedExpr;
const TypedStmt = ast.StmtOf(.typed);
const PatternBindingSnapshot = struct {
    name: []const u8,
    previous: ?*T.Type,
};

/// Allocate a heap-owned TypedExpr in env.arena.
fn makeTypedPtr(env: *Env, node: TypedExpr) !*TypedExpr {
    const ptr = try env.arena.create(TypedExpr);
    ptr.* = node;
    return ptr;
}

/// Convert a slice of untyped statements to typed ones (arena-allocated).
fn inferStmtsTyped(env: *Env, stmts: []const ast.Stmt) InferError![]TypedStmt {
    const out = try env.arena.alloc(TypedStmt, stmts.len);
    for (stmts, 0..) |s, i| out[i] = .{ .expr = try inferExprTyped(env, s.expr) };
    return out;
}

/// Convert a slice of untyped trailing lambdas to typed ones (arena-allocated).
fn inferTrailingLambdasTyped(env: *Env, trailing: []const ast.TrailingLambda) InferError![]ast.TrailingLambdaOf(.typed) {
    const out = try env.arena.alloc(ast.TrailingLambdaOf(.typed), trailing.len);
    for (trailing, 0..) |tl, i| {
        out[i] = .{
            .label = tl.label,
            .params = tl.params,
            .body = try inferStmtsTyped(env, tl.body),
        };
    }
    return out;
}

fn isEnumVariantNameForSubject(env: *Env, subjectType: *T.Type, candidate: []const u8) bool {
    const ty = subjectType.deref();
    if (ty.* != .named) return false;
    if (env.lookupTypeDef(ty.named.name)) |td| {
        switch (td) {
            .enum_ => |en| {
                for (en.variants) |v| {
                    if (std.mem.eql(u8, v.name, candidate)) return true;
                }
            },
            else => {},
        }
    }
    return false;
}

fn saveAndBindPatternName(
    env: *Env,
    snapshots: *std.ArrayListUnmanaged(PatternBindingSnapshot),
    name: []const u8,
    ty: *T.Type,
) InferError!void {
    var seen = false;
    for (snapshots.items) |s| {
        if (std.mem.eql(u8, s.name, name)) {
            seen = true;
            break;
        }
    }
    if (!seen) {
        try snapshots.append(env.arena, .{
            .name = name,
            .previous = env.lookup(name),
        });
    }
    try env.bind(name, ty);
}

fn restorePatternBindings(env: *Env, snapshots: []const PatternBindingSnapshot) InferError!void {
    var i = snapshots.len;
    while (i > 0) {
        i -= 1;
        const snapshot = snapshots[i];
        if (snapshot.previous) |old| {
            try env.bind(snapshot.name, old);
        } else {
            _ = env.bindings.remove(snapshot.name);
        }
    }
}

fn bindPatternNamesForSubject(
    env: *Env,
    pattern: ast.Pattern,
    subjectType: *T.Type,
    snapshots: *std.ArrayListUnmanaged(PatternBindingSnapshot),
) InferError!void {
    switch (pattern) {
        .wildcard, .numberLit, .stringLit => {},
        .ident => |name| {
            if (isEnumVariantNameForSubject(env, subjectType, name)) return;
            try saveAndBindPatternName(env, snapshots, name, try env.freshVar());
        },
        .variant => |v| switch (v.payload) {
            .binding => |binding| {
                try saveAndBindPatternName(env, snapshots, binding, try env.freshVar());
            },
            .fields => |fields| {
                for (fields) |binding| {
                    try saveAndBindPatternName(env, snapshots, binding, try env.freshVar());
                }
            },
            .literals => |args| {
                for (args) |arg| {
                    try bindPatternNamesForSubject(env, arg, try env.freshVar(), snapshots);
                }
            },
        },
        .list => |lst| {
            for (lst.elems) |elem| {
                switch (elem) {
                    .bind => |name| try saveAndBindPatternName(env, snapshots, name, try env.freshVar()),
                    else => {},
                }
            }
            if (lst.spread) |name| {
                if (name.len > 0) try saveAndBindPatternName(env, snapshots, name, try env.freshVar());
            }
        },
        .@"or" => |patterns| {
            if (patterns.len > 0) try bindPatternNamesForSubject(env, patterns[0], subjectType, snapshots);
        },
        .multi => {},
    }
}

fn bindCaseArmPatternNames(
    env: *Env,
    pattern: ast.Pattern,
    typedSubjects: []const ast.TypedExpr,
    snapshots: *std.ArrayListUnmanaged(PatternBindingSnapshot),
) InferError!void {
    if (pattern == .multi) {
        const patterns = pattern.multi;
        for (patterns, 0..) |p, i| {
            const subjectTy = if (i < typedSubjects.len) typedSubjects[i].getType() else try env.freshVar();
            try bindPatternNamesForSubject(env, p, subjectTy, snapshots);
        }
        return;
    }
    const subjectTy = if (typedSubjects.len > 0) typedSubjects[0].getType() else try env.freshVar();
    try bindPatternNamesForSubject(env, pattern, subjectTy, snapshots);
}

fn namesContain(list: []const []const u8, name: []const u8) bool {
    for (list) |n| {
        if (std.mem.eql(u8, n, name)) return true;
    }
    return false;
}

/// True when `pattern`, as a top-level case arm, binds the whole subject and so
/// matches any value of an enum/string domain — i.e. it is a catch-all. A `_`
/// wildcard, or an identifier that is NOT one of the subject enum's variant
/// names, both bind unconditionally. An OR pattern is a catch-all if any
/// alternative is.
fn patternIsCatchAll(env: *Env, pattern: ast.Pattern, subjectType: *T.Type) bool {
    return switch (pattern) {
        .wildcard => true,
        .ident => |name| !isEnumVariantNameForSubject(env, subjectType, name),
        .@"or" => |pats| blk: {
            for (pats) |p| {
                if (patternIsCatchAll(env, p, subjectType)) break :blk true;
            }
            break :blk false;
        },
        else => false,
    };
}

/// True when a variant pattern's payload matches *every* value of that variant,
/// so the variant is fully covered. Refined payloads like `Ok(1)` do not; a
/// payload of only bindings / wildcards (e.g. `Err(_)`, `Rgb(r, g, b)`) does.
fn variantPayloadIrrefutable(payload: anytype) bool {
    return switch (payload) {
        .binding, .fields => true,
        .literals => |args| blk: {
            for (args) |a| {
                const ok = switch (a) {
                    .wildcard, .ident => true,
                    else => false,
                };
                if (!ok) break :blk false;
            }
            break :blk true;
        },
    };
}

/// Append to `covered` every enum variant that `pattern` *fully* covers (an
/// irrefutable variant match). Refined matches (`Ok(1)`) are skipped so the
/// variant stays "open".
fn collectFullyCoveredVariants(
    env: *Env,
    pattern: ast.Pattern,
    subjectType: *T.Type,
    covered: *std.ArrayListUnmanaged([]const u8),
) InferError!void {
    switch (pattern) {
        .ident => |name| {
            if (isEnumVariantNameForSubject(env, subjectType, name) and !namesContain(covered.items, name)) {
                try covered.append(env.arena, name);
            }
        },
        .variant => |v| {
            if (variantPayloadIrrefutable(v.payload) and !namesContain(covered.items, v.name)) {
                try covered.append(env.arena, v.name);
            }
        },
        .@"or" => |pats| {
            for (pats) |p| try collectFullyCoveredVariants(env, p, subjectType, covered);
        },
        else => {},
    }
}

/// When `pattern` is a *single* irrefutable variant match whose variant is
/// already covered, return that variant's name (the arm is unreachable). OR
/// patterns are skipped — one covered alternative does not make the arm dead.
fn alreadyCoveredVariant(
    env: *Env,
    pattern: ast.Pattern,
    subjectType: *T.Type,
    covered: []const []const u8,
) ?[]const u8 {
    switch (pattern) {
        .ident => |name| {
            if (isEnumVariantNameForSubject(env, subjectType, name) and namesContain(covered, name)) return name;
        },
        .variant => |v| {
            if (variantPayloadIrrefutable(v.payload) and namesContain(covered, v.name)) return v.name;
        },
        else => {},
    }
    return null;
}

/// Full exhaustiveness + reachability analysis for a `case` on an enum or
/// string subject. Sets `env.lastError` and returns `error.TypeError` on the
/// first problem: an unreachable arm, a missing wildcard for an open domain, or
/// an enum with uncovered variants. Subjects of any other type are not checked.
fn checkCaseExhaustiveness(
    env: *Env,
    subjectType: *T.Type,
    arms: []const ast.CaseArm,
    loc: ast.Loc,
) InferError!void {
    const resolved = subjectType.deref();

    // Resolve the subject's domain. `string` is open (only a wildcard makes it
    // exhaustive); an enum has a known finite variant set; anything else is not
    // exhaustiveness-checked.
    const isString = resolved.isNamed("string");
    var typeName: []const u8 = "string";
    var variantNames: []const []const u8 = &.{};
    if (!isString) {
        if (resolved.* != .named) return;
        typeName = resolved.named.name;
        const td = env.lookupTypeDef(typeName) orelse return;
        switch (td) {
            .enum_ => |en| {
                const names = try env.arena.alloc([]const u8, en.variants.len);
                for (en.variants, 0..) |v, i| names[i] = v.name;
                variantNames = names;
            },
            else => return,
        }
    }

    var covered: std.ArrayListUnmanaged([]const u8) = .empty;
    defer covered.deinit(env.arena);
    var hasCatchAll = false;

    for (arms) |arm| {
        const guarded = arm.guard != null;

        // Any unguarded arm following an unguarded catch-all can never run.
        if (hasCatchAll and !guarded) {
            env.lastError = TypeError.redundantPattern(typeName, "this arm").withLoc(arm.body.getLoc());
            return error.TypeError;
        }

        // A guarded arm may fail its guard, so it neither covers a variant for
        // exhaustiveness nor shadows later arms.
        if (guarded) continue;

        if (patternIsCatchAll(env, arm.pattern, resolved)) {
            hasCatchAll = true;
            continue;
        }

        if (alreadyCoveredVariant(env, arm.pattern, resolved, covered.items)) |dup| {
            const desc = try std.fmt.allocPrint(env.arena, "variant '{s}'", .{dup});
            env.lastError = TypeError.redundantPattern(typeName, desc).withLoc(arm.body.getLoc());
            return error.TypeError;
        }

        try collectFullyCoveredVariants(env, arm.pattern, resolved, &covered);
    }

    if (hasCatchAll) return;

    if (isString) {
        env.lastError = TypeError.nonExhaustive(typeName, &.{}).withLoc(loc);
        return error.TypeError;
    }

    var missing: std.ArrayListUnmanaged([]const u8) = .empty;
    for (variantNames) |name| {
        if (!namesContain(covered.items, name)) try missing.append(env.arena, name);
    }
    if (missing.items.len > 0) {
        env.lastError = TypeError.nonExhaustive(typeName, try missing.toOwnedSlice(env.arena)).withLoc(loc);
        return error.TypeError;
    }
}

/// Infer the type of `expr` AND build the fully-annotated `TypedExpr` in one
/// pass.  Every child node is recursively typed before its parent is built, so
/// no expression is visited more than once.  All allocations go into env.arena.
pub fn inferExprTyped(env: *Env, expr: ast.Expr) InferError!TypedExpr {
    return switch (expr) {
        // ── literals ──────────────────────────────────────────────────────────
        .literal => |l| inferLiteralExpr(env, l, l.loc),

        // ── identifiers ───────────────────────────────────────────────────────
        .identifier => |i| inferIdentifierExpr(env, i, i.loc),

        // ── binary operations ───────────────────────────────────────────────────
        .binaryOp => |b| inferBinaryOpExpr(env, b, b.loc),

        // ── unary operations ──────────────────────────────────────────────────
        .unaryOp => |u| inferUnaryOpExpr(env, u, u.loc),

        // ── control flow ──────────────────────────────────────────────────────
        .jump => |j| inferJumpExpr(env, j, j.loc),
        .branch => |b| inferBranchExpr(env, b, b.loc),
        .loop => |lp| inferLoopExpr(env, lp, lp.loc),

        // ── binding expressions ────────────────────────────────────────────────
        .binding => |b| inferBindingExpr(env, b, b.loc),

        // ── use-hook expressions (@Context F7) ────────────────────────────────
        .useHook => |uh| inferUseHookExpr(env, uh, uh.loc),

        // ── call expressions ───────────────────────────────────────────────────
        .call => |c| inferCallExpr(env, c, c.loc),

        // ── function definition expressions ────────────────────────────────────
        .function => |f| inferFunctionExpr(env, f, f.loc),

        // ── collection expressions ─────────────────────────────────────────────
        .collection => |co| inferCollectionExpr(env, co, co.loc),

        // ── comptime expressions ───────────────────────────────────────────────
        .comptime_ => |a| inferComptimeExpr(env, a, a.loc),
    };
}

// ── Helper functions for each expression category ───────────────────────────

/// Infer type for literal expressions (strings, numbers, null, comments)
fn inferLiteralExpr(env: *Env, lit: ast.LiteralExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (lit.kind) {
        .stringLit => |s| TypedExpr{ .literal = .{ .loc = loc, .type_ = try env.namedType("string"), .kind = .{ .stringLit = s } } },
        .stringTemplate => |t| {
            // Desugar `"a ${x} b"` into the concatenation chain `"a " + x + " b"`
            // (same semantics as written-out string `+`, incl. coercion). The
            // typed AST therefore never contains a stringTemplate node, so
            // transform/eval/codegen stay untouched.
            var acc: ?*ast.Expr = null;
            if (t.parts.len > 0 and t.parts[0] == .expr) {
                // Force a string-typed result when the template starts with a hole.
                const empty = try env.arena.create(ast.Expr);
                empty.* = .{ .literal = .{ .loc = loc, .kind = .{ .stringLit = "" } } };
                acc = empty;
            }
            for (t.parts) |p| {
                const operand: *ast.Expr = switch (p) {
                    .text => |txt| blk: {
                        const e = try env.arena.create(ast.Expr);
                        e.* = .{ .literal = .{ .loc = loc, .kind = .{ .stringLit = txt } } };
                        break :blk e;
                    },
                    .expr => |e| e,
                };
                if (acc) |lhs| {
                    const bin = try env.arena.create(ast.Expr);
                    bin.* = .{ .binaryOp = .{ .loc = loc, .op = .add, .lhs = lhs, .rhs = operand } };
                    acc = bin;
                } else {
                    acc = operand;
                }
            }
            return inferExprTyped(env, acc.?.*);
        },
        .numberLit => |n| blk: {
            const isFloat = std.mem.indexOfScalar(u8, n, '.') != null;
            break :blk TypedExpr{ .literal = .{ .loc = loc, .type_ = try env.namedType(if (isFloat) "f64" else "i32"), .kind = .{ .numberLit = n } } };
        },
        .null_ => blk: {
            const innerVar = try env.freshVar();
            const optArgs = try env.arena.alloc(*T.Type, 1);
            optArgs[0] = innerVar;
            break :blk TypedExpr{ .literal = .{ .loc = loc, .type_ = try env.namedTypeArgs("optional", optArgs), .kind = .null_ } };
        },
        .comment => |c| TypedExpr{ .literal = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .comment = c } } },
    };
}

/// Infer type for identifier expressions (ident, dotIdent, identAccess)
fn inferIdentifierExpr(env: *Env, ident: ast.IdentifierExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (ident.kind) {
        .ident => |name| {
            if (env.lookup(name)) |ty| return TypedExpr{ .identifier = .{ .loc = loc, .type_ = ty, .kind = .{ .ident = name } } };
            env.lastError = TypeError.unboundVariable(name).withLoc(loc);
            return error.TypeError;
        },
        .dotIdent => |name| {
            if (env.lookup(name)) |ty| return TypedExpr{ .identifier = .{ .loc = loc, .type_ = ty, .kind = .{ .dotIdent = name } } };
            env.lastError = TypeError.unboundVariable(name).withLoc(loc);
            return error.TypeError;
        },
        .identAccess => |ia| {
            // When receiver is an identifier, check if it's a type name rather than a variable.
            // This handles enum/record/struct constructor access like Color.Red, Option.None
            if (ia.receiver.* == .identifier) {
                if (ia.receiver.*.identifier.kind == .ident) {
                    const receiverName = ia.receiver.*.identifier.kind.ident;
                    // Check if this identifier is a registered type definition
                    if (env.lookupTypeDef(receiverName)) |td| {
                        switch (td) {
                            .enum_ => |en| {
                                var found = false;
                                for (en.variants) |v| {
                                    if (std.mem.eql(u8, v.name, ia.member)) {
                                        found = true;
                                        break;
                                    }
                                }
                                if (!found) {
                                    env.lastError = TypeError.unknownField(receiverName, ia.member).withLoc(loc);
                                    return error.TypeError;
                                }
                                const ty = try env.namedType(receiverName);
                                const recvTyped = try makeTypedPtr(env, TypedExpr{ .identifier = .{
                                    .loc = ia.receiver.*.getLoc(),
                                    .type_ = ty,
                                    .kind = .{ .ident = receiverName },
                                } });
                                return TypedExpr{ .identifier = .{ .loc = loc, .type_ = ty, .kind = .{ .identAccess = .{
                                    .receiver = recvTyped,
                                    .member = ia.member,
                                } } } };
                            },
                            else => {},
                        }
                    }
                }
            }
            // Regular instance field access on a variable/instance.
            // Optional chaining (`a?.b`): the receiver may be `?T` — resolve the
            // member on the inner `T` and wrap the result back into an optional
            // (already-optional member types are not double-wrapped).
            const recvTyped = try inferExprTyped(env, ia.receiver.*);
            const recvPtr = try makeTypedPtr(env, recvTyped);
            var recvType = recvTyped.getType().deref();
            if (ia.optional) {
                if (recvType.* == .named and std.mem.eql(u8, recvType.named.name, "optional") and
                    recvType.named.args.len >= 1)
                {
                    recvType = recvType.named.args[0].deref();
                }
            }
            var outType: *T.Type = try env.freshVar();
            if (recvType.* == .named) {
                const recvNamed = recvType.named;
                if (env.lookupTypeDef(recvNamed.name)) |td| {
                    switch (td) {
                        .record, .struct_ => {
                            if (td.findField(ia.member)) |f| {
                                // Generic instance: substitute the registered
                                // cells with the instance's type args.
                                outType = try instantiateFieldType(env, recvNamed.name, recvNamed.args, f.type_);
                            } else {
                                env.lastError = TypeError.unknownField(recvNamed.name, ia.member).withLoc(loc);
                                return error.TypeError;
                            }
                        },
                        .enum_ => {
                            env.lastError = TypeError.unknownField(recvNamed.name, ia.member).withLoc(loc);
                            return error.TypeError;
                        },
                    }
                }
            }
            if (ia.optional) {
                const outDeref = outType.deref();
                const alreadyOptional = outDeref.* == .named and
                    std.mem.eql(u8, outDeref.named.name, "optional");
                if (!alreadyOptional) {
                    outType = try env.namedTypeArgs("optional", &.{outType});
                }
            }
            return TypedExpr{ .identifier = .{ .loc = loc, .type_ = outType, .kind = .{ .identAccess = .{
                .receiver = recvPtr,
                .member = ia.member,
                .optional = ia.optional,
            } } } };
        },
    };
}

/// Infer type for binary operation expressions
fn inferBinaryOpExpr(env: *Env, binop: ast.BinOpExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    const lhsTyped = try inferExprTyped(env, binop.lhs.*);
    const rhsTyped = try inferExprTyped(env, binop.rhs.*);
    const lhsPtr = try makeTypedPtr(env, lhsTyped);
    const rhsPtr = try makeTypedPtr(env, rhsTyped);

    // Determine result type based on operator
    const resultType: *T.Type = switch (binop.op) {
        .lt, .gt, .lte, .gte, .eq, .ne => try env.namedType("bool"),
        .@"and", .@"or" => blk: {
            try unifyAt(env, lhsTyped.getType(), try env.namedType("bool"), loc);
            try unifyAt(env, rhsTyped.getType(), try env.namedType("bool"), loc);
            break :blk try env.namedType("bool");
        },
        .add => blk: {
            // String + anything → string (coercion)
            const lhsTy = lhsTyped.getType();
            const rhsTy = rhsTyped.getType();
            if (lhsTy.isNamed("string") or rhsTy.isNamed("string")) break :blk try env.namedType("string");
            // Numeric promotion: float wins over int
            if (isFloatType(lhsTy) and isIntType(rhsTy)) break :blk lhsTy;
            if (isIntType(lhsTy) and isFloatType(rhsTy)) break :blk rhsTy;
            try unify(env, lhsTy, rhsTy);
            break :blk lhsTy;
        },
        .sub, .mul, .div, .mod => blk: {
            const lhsTy = lhsTyped.getType();
            const rhsTy = rhsTyped.getType();
            if (isFloatType(lhsTy) and isIntType(rhsTy)) break :blk lhsTy;
            if (isIntType(lhsTy) and isFloatType(rhsTy)) break :blk rhsTy;
            try unify(env, lhsTy, rhsTy);
            break :blk lhsTy;
        },
    };
    return TypedExpr{ .binaryOp = .{
        .loc = loc,
        .type_ = resultType,
        .op = binop.op,
        .lhs = lhsPtr,
        .rhs = rhsPtr,
    } };
}

/// Infer type for unary operation expressions
fn inferUnaryOpExpr(env: *Env, unaryop: ast.UnaryOpExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    const operandTyped = try inferExprTyped(env, unaryop.expr.*);
    const operandPtr = try makeTypedPtr(env, operandTyped);
    return switch (unaryop.op) {
        .not => blk: {
            try unifyAt(env, operandTyped.getType(), try env.namedType("bool"), loc);
            break :blk TypedExpr{ .unaryOp = .{ .loc = loc, .type_ = try env.namedType("bool"), .op = .not, .expr = operandPtr } };
        },
        .neg => TypedExpr{ .unaryOp = .{ .loc = loc, .type_ = operandTyped.getType(), .op = .neg, .expr = operandPtr } },
    };
}

/// Infer type for jump expressions (return, throw, try, break, continue, yield)
fn inferJumpExpr(env: *Env, j: ast.MakeExpr(.untyped, ast.JumpExprOf(.untyped)), loc: ast.Loc) InferError!TypedExpr {
    return switch (j.kind) {
        .@"return" => |r| {
            const valPtr: ?*TypedExpr = if (r) |rv| try makeTypedPtr(env, try inferExprTyped(env, rv.*)) else null;
            // Inside a `-> @Result<…>` fn, a returned plain value must be wrapped
            // into `{ok, V}` by the transform pass (`__bp_ok`). Skip values that
            // are already a `@Result` (passthrough) and `try`/`catch` forms —
            // those have dedicated statement-level lowerings in each backend.
            if (env.throwContext == .result) {
                if (r) |rv| {
                    const isCatchForm = rv.* == .branch and rv.branch.kind == .tryCatch;
                    const isTryJump = rv.* == .jump and rv.jump.kind == .try_;
                    const valIsResult = blk: {
                        const vt = valPtr.?.getType().deref();
                        break :blk vt.* == .named and std.mem.eql(u8, vt.named.name, "Result");
                    };
                    if (isTryJump) {
                        // `return try f()` — unwrap-then-rewrap is the identity;
                        // the transform returns `f()`'s Result directly.
                        try env.result_jump_lowerings.put(loc, .unwrap_passthrough);
                    } else if (!isCatchForm and !valIsResult) {
                        try env.result_jump_lowerings.put(loc, .wrap_ok);
                    }
                }
            }
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .@"return" = valPtr } } };
        },
        .throw_ => |e| {
            const valPtr: ?*TypedExpr = if (e) |ev| try makeTypedPtr(env, try inferExprTyped(env, ev.*)) else null;
            // Validate the thrown value against the enclosing fn's error type.
            switch (env.throwContext) {
                .result => |errType| {
                    if (valPtr) |vp| {
                        // Order matters: `errType` is the expected `E`, the thrown
                        // value is what we got — so unify(expected, got).
                        try unifyAt(env, errType, vp.getType(), loc);
                        // `throw e` in a `-> @Result<…>` fn produces the value
                        // `{error, E}` — the transform rewrites it to
                        // `return __bp_error(e)`.
                        try env.result_jump_lowerings.put(loc, .wrap_error);
                    }
                },
                .plain => {
                    env.lastError = TypeError.throwWithoutResult().withLoc(loc);
                    return error.TypeError;
                },
                .unchecked => {},
            }
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .throw_ = valPtr } } };
        },
        .try_ => |e| {
            const valPtr: ?*TypedExpr = if (e) |ev| try makeTypedPtr(env, try inferExprTyped(env, ev.*)) else null;
            const rawTy = if (valPtr) |vp| vp.getType() else try env.freshVar();
            const ty = try tryUnwrapOrError(env, rawTy, loc);
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = ty, .kind = .{ .try_ = valPtr } } };
        },
        .@"break" => |e| {
            const typedPtr: ?*TypedExpr = if (e) |expr| try makeTypedPtr(env, try inferExprTyped(env, expr.*)) else null;
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .@"break" = typedPtr } } };
        },
        .await_ => |e| {
            // `await` is only valid inside an async `*fn` (returns `@Future`/`@AsyncIterator`).
            if (env.starFn == null or !env.starFn.?.allowsAwait) {
                env.lastError = TypeError.custom(
                    "`await` can only be used inside an async `*fn`",
                    "Mark the enclosing function `*fn` with a `@Future`/`@AsyncIterator` return type.",
                ).withLoc(loc);
                return error.TypeError;
            }
            const valPtr = try makeTypedPtr(env, try inferExprTyped(env, e.*));
            const rawTy = valPtr.getType();
            // `await @Future<T>` yields `T`. A resolved non-`@Future` named type is
            // an error; an unresolved type variable stays lenient.
            const deref = rawTy.deref();
            if (deref.* == .named and !std.mem.eql(u8, deref.named.name, "Future")) {
                env.lastError = TypeError.custom(
                    "`await` expects a `@Future<_>` value",
                    null,
                ).withLoc(loc);
                return error.TypeError;
            }
            const ty = unwrapFutureType(rawTy) orelse rawTy;
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = ty, .kind = .{ .await_ = valPtr } } };
        },
        .@"continue" => TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .@"continue" } },
        .yield => |y| {
            // A `:label` must name an enclosing labelled `*fn`/loop.
            if (y.label) |lbl| {
                if (!env.hasLabel(lbl)) {
                    env.lastError = TypeError.custom(
                        "`yield` targets an unknown label",
                        "Label a `*fn` (`-> @Iterator<T> :name`) or a `loop :name (...)`.",
                    ).withLoc(loc);
                    return error.TypeError;
                }
            }
            const typedPtr: ?*TypedExpr = if (y.value) |expr| try makeTypedPtr(env, try inferExprTyped(env, expr.*)) else null;
            // Inside a `*fn` generator, each yielded value unifies with the
            // iterator item type `T` of `@Iterator<T>` / `@AsyncIterator<T, _>`.
            if (env.starFn) |ctx| {
                if (ctx.iterItem) |item| {
                    if (typedPtr) |vp| try unifyAt(env, vp.getType(), item, loc);
                }
            }
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .yield = .{ .label = y.label, .value = typedPtr } } } };
        },
    };
}

/// Infer type for branch expressions (if and try-catch)
fn inferBranchExpr(env: *Env, b: ast.MakeExpr(.untyped, ast.BranchExprOf(.untyped)), loc: ast.Loc) InferError!TypedExpr {
    return switch (b.kind) {
        .if_ => |i| {
            const condTyped = try inferExprTyped(env, i.cond.*);
            const condPtr = try makeTypedPtr(env, condTyped);

            if (i.binding) |binding_name| {
                // Null-check form: `if (x) { e -> ... }` — condition is optional, not bool.
                // Bind the unwrapped inner type to `binding_name`.
                const condTy = condTyped.getType().deref();
                const innerTy: *T.Type = switch (condTy.*) {
                    .named => |n| if (std.mem.eql(u8, n.name, "optional") and n.args.len == 1)
                        n.args[0]
                    else
                        try env.freshVar(),
                    else => try env.freshVar(),
                };
                try env.bind(binding_name, innerTy);
            } else {
                try unifyAt(env, try env.namedType("bool"), condTyped.getType(), loc);
            }

            const thenTyped = try inferStmtsTyped(env, i.then_);
            const elseTyped = if (i.else_) |els| try inferStmtsTyped(env, els) else null;

            const bodyType = if (thenTyped.len > 0) thenTyped[thenTyped.len - 1].expr.getType() else try env.namedType("void");
            const elseType = if (elseTyped) |els| blk: {
                if (els.len > 0) break :blk els[els.len - 1].expr.getType();
                break :blk try env.namedType("void");
            } else try env.namedType("void");

            if (elseTyped != null) {
                try unify(env, bodyType, elseType);
            }
            return TypedExpr{ .branch = .{ .loc = loc, .type_ = bodyType, .kind = .{ .if_ = .{
                .cond = condPtr,
                .binding = i.binding,
                .then_ = thenTyped,
                .else_ = elseTyped,
            } } } };
        },

        .tryCatch => |tc| {
            const exprTyped = try inferExprTyped(env, tc.expr.*);
            const exprPtr = try makeTypedPtr(env, exprTyped);
            const handlerTyped = try inferExprTyped(env, tc.handler.*);
            const handlerPtr = try makeTypedPtr(env, handlerTyped);
            const rawTy = exprTyped.getType();
            const resultTy = try tryUnwrapOrError(env, rawTy, loc);
            const handlerTy = handlerTyped.getType().deref();
            const effectiveTy = switch (handlerTy.*) {
                .func => |f| f.ret,
                else => handlerTyped.getType(),
            };
            if (!effectiveTy.isNamed("void")) {
                try unify(env, resultTy, effectiveTy);
            }
            return TypedExpr{ .branch = .{ .loc = loc, .type_ = resultTy, .kind = .{ .tryCatch = .{
                .expr = exprPtr,
                .handler = handlerPtr,
            } } } };
        },
    };
}

/// Infer type for loop expressions
fn inferLoopExpr(env: *Env, lp: ast.LoopExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    const iterTyped = try inferExprTyped(env, lp.iter.*);
    const iterPtr = try makeTypedPtr(env, iterTyped);
    const indexRangePtr = if (lp.indexRange) |ir| try makeTypedPtr(env, try inferExprTyped(env, ir.*)) else null;

    // `loop await (iter)` requires an async context and an `@AsyncIterator<T, E>`
    // iterable; the loop param binds to the item type `T`.
    var awaitItem: ?*T.Type = null;
    if (lp.awaitLoop) {
        if (env.starFn == null or !env.starFn.?.allowsAwait) {
            env.lastError = TypeError.custom(
                "`loop await` can only be used inside an async `*fn`",
                "Mark the enclosing function `*fn` with a `@Future`/`@AsyncIterator` return type.",
            ).withLoc(loc);
            return error.TypeError;
        }
        const iterTy = iterTyped.getType().deref();
        if (iterTy.* == .named and std.mem.eql(u8, iterTy.named.name, "AsyncIterator") and iterTy.named.args.len >= 1) {
            awaitItem = iterTy.named.args[0];
        } else if (iterTy.* != .typeVar) {
            env.lastError = TypeError.custom(
                "`loop await` expects an `@AsyncIterator<T, E>` value",
                null,
            ).withLoc(loc);
            return error.TypeError;
        }
    }

    for (lp.params) |p| {
        try env.bind(p, awaitItem orelse try env.freshVar());
    }

    // A `loop :label (...)` adds its label to scope for `yield :label` inside it.
    const prevLabelsLen = env.labelStack.items.len;
    defer env.labelStack.shrinkRetainingCapacity(prevLabelsLen);
    if (lp.label) |lbl| try env.labelStack.append(env.arena, lbl);

    const typedBody = try inferStmtsTyped(env, lp.body);
    const loopArrayArgs = try env.arena.alloc(*T.Type, 1);
    loopArrayArgs[0] = try env.freshVar();
    return TypedExpr{ .loop = .{
        .loc = loc,
        .type_ = try env.namedTypeArgs("array", loopArrayArgs),
        .iter = iterPtr,
        .indexRange = indexRangePtr,
        .params = lp.params,
        .body = typedBody,
        .awaitLoop = lp.awaitLoop,
        .label = lp.label,
    } };
}

/// Infer type for binding expressions (variable declarations and assignments)
fn inferBindingExpr(env: *Env, b: ast.BindingExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (b.kind) {
        .localBind => |lb| {
            const annType: ?*T.Type = if (lb.typeAnnotation) |ann| try resolveTypeRef(env, ann) else null;
            // Feed a `fn(...) -> ...` annotation into a lambda RHS so its
            // params are typed from context (mirrors `inferDeclTyped`).
            const valTyped = if (annType != null and lb.value.* == .function)
                try inferFunctionExprExpected(env, lb.value.function, lb.value.function.loc, annType)
            else
                try inferExprTyped(env, lb.value.*);
            const valPtr = try makeTypedPtr(env, valTyped);
            if (annType) |at| try unifyAt(env, at, valTyped.getType(), lb.value.getLoc());
            // The annotation is the DECLARED type — bind it, not the RHS type
            // (`val head: ?i32 = 5;` must bind `?i32`).
            const bindTy = annType orelse valTyped.getType();
            try env.bind(lb.name, bindTy);
            return TypedExpr{ .binding = .{ .loc = loc, .type_ = bindTy, .kind = .{ .localBind = .{
                .name = lb.name,
                .value = valPtr,
                .mutable = lb.mutable,
                .typeAnnotation = lb.typeAnnotation,
            } } } };
        },

        .assign => |a| {
            const valTyped = try inferExprTyped(env, a.value.*);
            const valPtr = try makeTypedPtr(env, valTyped);

            return TypedExpr{ .binding = .{ .loc = loc, .type_ = valTyped.getType(), .kind = .{ .assign = .{
                .target = switch (a.target) {
                    .name => |name| blk: {
                        if (env.lookup(name)) |ty| {
                            try unifyAt(env, ty, valTyped.getType(), loc);
                        } else {
                            env.lastError = TypeError.unboundVariable(name).withLoc(loc);
                            return error.TypeError;
                        }
                        break :blk .{ .name = name };
                    },
                    .fieldAccess => |fa| blk: {
                        const recvTyped = try inferExprTyped(env, fa.receiver.*);
                        const recvPtr = try makeTypedPtr(env, recvTyped);
                        break :blk .{ .fieldAccess = .{ .receiver = recvPtr, .field = fa.field } };
                    },
                },
                .op = a.op,
                .value = valPtr,
            } } } };
        },

        .localBindDestruct => |lb| {
            const valTyped = try inferExprTyped(env, lb.value.*);
            const valPtr = try makeTypedPtr(env, valTyped);
            // Destructuring a hook (`val {v, s} = use state(0)`) is lenient: the
            // hook's Return type `R` need not be a record, so unknown fields bind
            // to fresh type vars rather than triggering a `notARecord` error.
            if (isUseHookValue(lb.value)) {
                try bindUseDestructure(env, lb.pattern, valTyped.getType());
                return TypedExpr{ .binding = .{ .loc = loc, .type_ = valTyped.getType(), .kind = .{ .localBindDestruct = .{
                    .pattern = lb.pattern,
                    .value = valPtr,
                    .mutable = lb.mutable,
                } } } };
            }
            // Bind destructured names into the environment.
            const derefedTy = valTyped.getType().deref();
            switch (lb.pattern) {
                .names => |n| {
                    const typeName: []const u8 = switch (derefedTy.*) {
                        .named => |nm| nm.name,
                        else => "",
                    };
                    const maybeDef = env.typeDefs.get(typeName);
                    // For concrete named types that are not records/structs, reject destructuring.
                    if (maybeDef == null and typeName.len > 0 and derefedTy.* == .named) {
                        env.lastError = TypeError.notARecord(typeName).withLoc(loc);
                        return error.TypeError;
                    }
                    for (n.fields) |fld| {
                        const fieldTy = if (maybeDef) |td|
                            if (td.findField(fld.field_name)) |f| f.type_ else try env.freshVar()
                        else
                            try env.freshVar();
                        try env.bind(fld.bind_name, fieldTy);
                    }
                },
                .tuple_ => |t| {
                    const tupleArgs: []*T.Type = switch (derefedTy.*) {
                        .named => |n| if (std.mem.eql(u8, n.name, "tuple")) n.args else &.{},
                        else => &.{},
                    };
                    for (t, 0..) |nm, i| {
                        const elemTy = if (i < tupleArgs.len) tupleArgs[i] else try env.freshVar();
                        try env.bind(nm, elemTy);
                    }
                },
                .list => |pat| {
                    // Bind pattern variable names to fresh type vars.
                    switch (pat) {
                        .ident => |name| try env.bind(name, try env.freshVar()),
                        .variant => |v| if (v.payload == .fields) for (v.payload.fields) |binding| try env.bind(binding, try env.freshVar()),
                        else => {},
                    }
                },
                .ctor => |pat| {
                    switch (pat) {
                        .ident => |name| try env.bind(name, try env.freshVar()),
                        .variant => |v| if (v.payload == .fields) for (v.payload.fields) |binding| try env.bind(binding, try env.freshVar()),
                        else => {},
                    }
                },
            }
            return TypedExpr{ .binding = .{ .loc = loc, .type_ = valTyped.getType(), .kind = .{ .localBindDestruct = .{
                .pattern = lb.pattern,
                .value = valPtr,
                .mutable = lb.mutable,
            } } } };
        },
    };
}

fn containsStr(haystack: []const []const u8, needle: []const u8) bool {
    for (haystack) |s| if (std.mem.eql(u8, s, needle)) return true;
    return false;
}

/// The nominal type name of `ty`, or null if `ty` is not a named type.
fn nominalName(ty: *T.Type) ?[]const u8 {
    const d = ty.deref();
    return switch (d.*) {
        .named => |n| n.name,
        else => null,
    };
}

/// Build a typed method-call node, preserving the surface `recv.callee(args)`
/// shape (`recvPtr` is the typed receiver expression). External dispatch
/// (rewriting to `Sym.callee(recv, args)`) is recorded separately in
/// `env.dispatchRewrites` and applied by the transform pass.
fn makeMethodCall(
    env: *Env,
    recvPtr: ?*ast.TypedExpr,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
    loc: ast.Loc,
) InferError!TypedExpr {
    const retType = try env.freshVar();
    return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
        .receiver = recvPtr,
        .callee = callee,
        .is_builtin = false,
        .args = typedArgs,
        .trailing = typedTrailing,
    } } } };
}

/// Resolve a builtin `result` namespace qualified call (Gleam-style surface):
/// `result.map(r, f)` / `result.then(r, f)` / `result.unwrap(r, fallback)` /
/// `result.isOk(r)` / `result.isError(r)`. The subject `@Result<R, E>` value
/// arrives as the first positional argument. Records a `qualified`
/// MethodLowering at `loc` so the transform rewrites to the same
/// `__bp_result_<op>(args…)` builtin the method form uses — every backend
/// lowers it inline (no module emitted, no import required).
fn inferResultNamespaceCall(
    env: *Env,
    recvPtr: ?*ast.TypedExpr,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
    loc: ast.Loc,
) InferError!TypedExpr {
    const op: envMod.MethodLowering.Op = blk: {
        if (std.mem.eql(u8, callee, "map")) break :blk .map;
        if (std.mem.eql(u8, callee, "then")) break :blk .flatMap;
        if (std.mem.eql(u8, callee, "unwrap")) break :blk .unwrapOr;
        if (std.mem.eql(u8, callee, "isOk")) break :blk .isOk;
        if (std.mem.eql(u8, callee, "isError")) break :blk .isError;
        env.lastError = TypeError.custom(
            "unknown `result` namespace function",
            "Available: map, then, unwrap, isOk, isError.",
        ).withLoc(loc);
        return error.TypeError;
    };

    const wantArity: usize = switch (op) {
        .map, .flatMap, .unwrapOr => 2,
        .isOk, .isError => 1,
    };
    const total = typedArgs.len + typedTrailing.len;
    if (total != wantArity) {
        env.lastError = TypeError.arityMismatch(callee, wantArity, total).withLoc(loc);
        return error.TypeError;
    }

    // The subject `@Result<R, E>` is the first positional argument.
    const okTy = try env.freshVar();
    const errTy = try env.freshVar();
    const subjectShape = try env.namedTypeArgs("Result", &.{ okTy, errTy });
    try unifyAt(env, subjectShape, typedArgs[0].value.getType(), typedArgs[0].value.getLoc());

    const arg1: ?*T.Type = if (typedArgs.len >= 2) typedArgs[1].value.getType() else null;

    const retType: *T.Type = switch (op) {
        .map => blk: {
            const r2 = try env.freshVar();
            if (arg1) |a| try unifyAt(env, a, try env.funcType(&.{okTy}, r2), loc);
            break :blk try env.namedTypeArgs("Result", &.{ r2, errTy });
        },
        .flatMap => blk: {
            const r2 = try env.freshVar();
            const resTy = try env.namedTypeArgs("Result", &.{ r2, errTy });
            if (arg1) |a| try unifyAt(env, a, try env.funcType(&.{okTy}, resTy), loc);
            break :blk resTy;
        },
        .unwrapOr => blk: {
            if (arg1) |a| try unifyAt(env, a, okTy, loc);
            break :blk okTy;
        },
        .isOk, .isError => try env.namedType("bool"),
    };

    try env.method_lowerings.put(loc, .{ .domain = .result, .op = op, .qualified = true });

    return ast.TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
        .receiver = recvPtr,
        .callee = callee,
        .is_builtin = false,
        .args = typedArgs,
        .trailing = typedTrailing,
    } } } };
}

/// Resolve a builtin method call on a `@Result<R, E>` or `@Option<T>` receiver
/// (`.map` / `.flatMap` / `.unwrapOr` / `.isOk` / `.isError`).
///
/// Returns the typed call node (with the correct result type) and records a
/// lowering decision in `env.method_lowerings` keyed by `loc`, so the AST
/// transform can rewrite it into a `__bp_<domain>_<op>(receiver, arg)` builtin
/// call. Returns `null` when the receiver is not a Result/Option or the method
/// is unknown — the caller then falls back to permissive method typing.
fn inferResultOptionMethod(
    env: *Env,
    recvPtr: *ast.TypedExpr,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
    loc: ast.Loc,
) InferError!?ast.TypedExpr {
    const recvTy = recvPtr.getType().deref();
    if (recvTy.* != .named) return null;
    const named = recvTy.named;
    const isResult = std.mem.eql(u8, named.name, "Result");
    const isOption = std.mem.eql(u8, named.name, "optional");
    if (!isResult and !isOption) return null;

    const op: envMod.MethodLowering.Op =
        if (std.mem.eql(u8, callee, "map")) .map else if (std.mem.eql(u8, callee, "flatMap")) .flatMap else if (std.mem.eql(u8, callee, "unwrapOr")) .unwrapOr else if (isResult and std.mem.eql(u8, callee, "isOk")) .isOk else if (isResult and std.mem.eql(u8, callee, "isError")) .isError else return null;

    // The success-payload type: `R` for `Result<R, E>`, `T` for `Option<T>`.
    const okTy: *T.Type = if (named.args.len >= 1) named.args[0] else try env.freshVar();
    const errTy: *T.Type = if (isResult and named.args.len >= 2) named.args[1] else try env.freshVar();

    // The functional / default argument arrives as the first positional arg.
    const arg0: ?*T.Type = if (typedArgs.len >= 1) typedArgs[0].value.getType() else null;

    const retType: *T.Type = switch (op) {
        .map => blk: {
            const r2 = try env.freshVar();
            if (arg0) |a| try unifyAt(env, a, try env.funcType(&.{okTy}, r2), loc);
            break :blk if (isResult)
                try env.namedTypeArgs("Result", &.{ r2, errTy })
            else
                try env.namedTypeArgs("optional", &.{r2});
        },
        .flatMap => blk: {
            const r2 = try env.freshVar();
            const resTy = if (isResult)
                try env.namedTypeArgs("Result", &.{ r2, errTy })
            else
                try env.namedTypeArgs("optional", &.{r2});
            if (arg0) |a| try unifyAt(env, a, try env.funcType(&.{okTy}, resTy), loc);
            break :blk resTy;
        },
        .unwrapOr => blk: {
            if (arg0) |a| try unifyAt(env, a, okTy, loc);
            break :blk okTy;
        },
        .isOk, .isError => try env.namedType("bool"),
    };

    try env.method_lowerings.put(loc, .{ .domain = if (isResult) .result else .option, .op = op });

    return ast.TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
        .receiver = recvPtr,
        .callee = callee,
        .is_builtin = false,
        .args = typedArgs,
        .trailing = typedTrailing,
    } } } };
}

/// Resolve a compiler-provided template method (expr-templates F4):
/// `text`/`parts`/`lookup`/`fail`/`failAt` on an `expr` receiver, plus
/// `ref()` on a `Binding`.
///
/// The data model (`Span`, `Part`, `Binding`) lives in `std.syntax`
/// (libs/std/src/syntax.bp); these methods are inference-resolved like the
/// `@Result`/`@Option` builtins — no runtime dispatch table — and recorded in
/// `env.templateLowerings` (keyed by call loc) for the expansion pass (F6).
/// Instances only exist at comptime; no codegen backend ever sees these calls.
/// Returns null when the receiver is not an `expr`/`Binding` or the method is
/// unknown — the caller falls back to permissive method typing.
fn inferTemplateMethod(
    env: *Env,
    recvPtr: *ast.TypedExpr,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
    loc: ast.Loc,
) InferError!?ast.TypedExpr {
    const recvTy = recvPtr.getType().deref();
    if (recvTy.* != .named) return null;
    const named = recvTy.named;

    const unifyArg = struct {
        fn unifyArg(e: *Env, args: []ast.CallArgOf(.typed), i: usize, expected: *T.Type) InferError!void {
            if (i >= args.len) return;
            try unifyAt(e, expected, args[i].value.getType(), args[i].value.getLoc());
        }
    }.unifyArg;

    var op: envMod.TemplateOp = undefined;
    var retType: *T.Type = undefined;

    if (std.mem.eql(u8, named.name, "Expr")) {
        if (std.mem.eql(u8, callee, "value")) {
            // The expression's value type slot — what the code evaluates to.
            op = .value;
            retType = if (named.args.len >= 1) named.args[0] else try env.freshVar();
        } else if (std.mem.eql(u8, callee, "text")) {
            op = .text;
            retType = try env.namedType("string");
        } else if (std.mem.eql(u8, callee, "parts")) {
            op = .parts;
            retType = try env.namedTypeArgs("array", &.{try env.namedType("Part")});
        } else if (std.mem.eql(u8, callee, "source")) {
            // Declaration position — where the expression was written.
            op = .source;
            retType = try env.namedType("Source");
        } else if (std.mem.eql(u8, callee, "context")) {
            // The full second-layer input: source + text + shape.
            op = .context;
            retType = try env.namedType("Context");
        } else if (std.mem.eql(u8, callee, "bindings")) {
            // Enumerate the origin scope (top-level decls + imports, V1).
            op = .bindings;
            retType = try env.namedTypeArgs("array", &.{try env.namedType("Binding")});
        } else if (std.mem.eql(u8, callee, "build")) {
            // Parse source text into an expression carrying the receiver's
            // origin scope + provenance — how a second-layer language emits
            // code without quoting (`expr { … }` covers the pattern case).
            op = .build;
            try unifyArg(env, typedArgs, 0, try env.namedType("string"));
            retType = try env.namedTypeArgs("Expr", &.{try env.freshVar()});
        } else if (std.mem.eql(u8, callee, "lookup")) {
            op = .lookup;
            try unifyArg(env, typedArgs, 0, try env.namedType("string"));
            retType = try env.namedTypeArgs("optional", &.{try env.namedType("Binding")});
        } else if (std.mem.eql(u8, callee, "fail")) {
            op = .fail;
            try unifyArg(env, typedArgs, 0, try env.namedType("string"));
            // `fail` never returns — a fresh var unifies with any context.
            retType = try env.freshVar();
        } else if (std.mem.eql(u8, callee, "failAt")) {
            op = .failAt;
            try unifyArg(env, typedArgs, 0, try env.namedType("Span"));
            try unifyArg(env, typedArgs, 1, try env.namedType("string"));
            retType = try env.freshVar();
        } else return null;
    } else if (std.mem.eql(u8, named.name, "Binding")) {
        if (!std.mem.eql(u8, callee, "ref")) return null;
        op = .ref;
        // A spliceable reference: `expr` of a type revealed at expansion.
        retType = try env.namedTypeArgs("Expr", &.{try env.freshVar()});
    } else return null;

    try env.templateLowerings.put(loc, op);

    return ast.TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
        .receiver = recvPtr,
        .callee = callee,
        .is_builtin = false,
        .args = typedArgs,
        .trailing = typedTrailing,
    } } } };
}

/// Resolve `recv.callee(args)` against inherent methods and activated extensions.
///
/// Returns the typed call on success, or null when there is no method/extension
/// match (the caller then falls back to a plain callee lookup). Raises
/// `error.TypeError` for the diagnostic cases: not-active, and ambiguity.
fn resolveReceiverCall(
    env: *Env,
    recv: []const u8,
    recvPtr: ?*ast.TypedExpr,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
    loc: ast.Loc,
) InferError!?TypedExpr {
    // (a) Qualified call: receiver is an extension symbol, e.g. `PatoNada.swim(donald)`.
    //     Qualified calls resolve without activation.
    if (env.extensions.get(recv)) |ext| {
        if (!containsStr(ext.methods, callee)) return null;
        return try makeMethodCall(env, recvPtr, callee, typedArgs, typedTrailing, loc);
    }

    // A type-qualified call (`EnumType.Variant(args)`, struct static call) is not an
    // instance dispatch — leave it to the constructor-resolution path.
    if (env.lookupTypeDef(recv) != null) return null;

    // (b) Instance call: `recv` is a value; dispatch on its nominal type.
    const recvType = env.lookup(recv) orelse return null;
    const typeName = nominalName(recvType) orelse return null;

    // Rule 1 — inherent method (declared on the type or inline `implement`).
    if (env.hasInherentMethod(typeName, callee)) {
        return try makeMethodCall(env, recvPtr, callee, typedArgs, typedTrailing, loc);
    }

    // Rule 2 — activated `implement`/`extend` providing `callee` for this type.
    var activatedSym: ?[]const u8 = null;
    var ambiguousWith: ?[]const u8 = null;
    var inactiveSym: ?[]const u8 = null;
    var it = env.extensions.valueIterator();
    while (it.next()) |ext| {
        if (!std.mem.eql(u8, ext.target, typeName)) continue;
        if (!containsStr(ext.methods, callee)) continue;
        if (env.isActivated(ext.name)) {
            if (activatedSym == null) {
                activatedSym = ext.name;
            } else if (ambiguousWith == null) {
                ambiguousWith = ext.name;
            }
        } else if (inactiveSym == null) {
            inactiveSym = ext.name;
        }
    }

    if (activatedSym) |sym| {
        if (ambiguousWith) |other| {
            env.lastError = TypeError.ambiguousExtension(typeName, callee, sym, other).withLoc(loc);
            return error.TypeError;
        }
        // External dispatch: lower `recv.callee(args)` → `sym.callee(recv, args)`.
        try env.dispatchRewrites.put(loc, sym);
        return try makeMethodCall(env, recvPtr, callee, typedArgs, typedTrailing, loc);
    }

    // Rule 3 — method exists but no activation: error with an activation hint.
    if (inactiveSym) |sym| {
        env.lastError = TypeError.methodNotActive(typeName, callee, sym).withLoc(loc);
        return error.TypeError;
    }

    return null;
}

/// Infer type for `use`-hook expressions (@Context F7).
///
/// The enclosing function's return type decides whether `use` is allowed and which
/// ContextBase the hook expression must agree on. The capability was recorded in
/// `env.fnContext` by `inferFnDecl` before the body was visited.
fn inferUseHookExpr(env: *Env, uh: ast.UseHookExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    const fc = env.fnContext orelse {
        env.lastError = TypeError.useNotAllowed("void").withLoc(loc);
        return error.TypeError;
    };
    if (!fc.implementsContext) {
        env.lastError = TypeError.useNotAllowed(fc.returnDisplay).withLoc(loc);
        return error.TypeError;
    }

    // `use <hookcall>` — infer the wrapped call, check it yields the right
    // ContextBase, and expose its Return type `R` as the prefix's type. Any
    // binding/destructuring is performed by the enclosing `val`/`var`.
    const valTyped = try inferExprTyped(env, uh.kind.inner.*);
    const valPtr = try makeTypedPtr(env, valTyped);
    try validateUseBase(env, valTyped.getType(), fc, loc);
    const srcTy = bindingSourceType(valTyped.getType());
    return TypedExpr{ .useHook = .{ .loc = loc, .type_ = srcTy, .kind = .{ .inner = valPtr } } };
}

/// True when a binding's value is a `use`-hook prefix expression.
fn isUseHookValue(value: *const ast.ExprOf(.untyped)) bool {
    return value.* == .useHook;
}

/// Verify a `use` expression returns `@Context<B, _>` whose `B` matches the
/// enclosing function's ContextBase.
fn validateUseBase(env: *Env, valTy: *T.Type, fc: envMod.FnContext, loc: ast.Loc) InferError!void {
    const useBase = contextBaseOfType(env, valTy) orelse {
        const disp = baseNameOfType(valTy) orelse "value";
        env.lastError = TypeError.useNotContext(disp).withLoc(loc);
        return error.TypeError;
    };
    const fnBase = fc.base orelse return; // implements @Context but base unconstrained
    if (!std.mem.eql(u8, fnBase, useBase)) {
        env.lastError = TypeError.contextMismatch(fnBase, useBase).withLoc(loc);
        return error.TypeError;
    }
}

/// Bind the names introduced by a destructuring `use { ... } = expr` against the
/// hook's Return type. Falls back to fresh type vars when fields are unknown.
fn bindUseDestructure(env: *Env, pattern: ast.ParamDestruct, srcTy: *T.Type) InferError!void {
    const derefed = srcTy.deref();
    switch (pattern) {
        .names => |n| {
            const typeName: []const u8 = switch (derefed.*) {
                .named => |nm| nm.name,
                else => "",
            };
            const maybeDef = env.typeDefs.get(typeName);
            for (n.fields) |fld| {
                const fieldTy = if (maybeDef) |td|
                    if (td.findField(fld.field_name)) |f| f.type_ else try env.freshVar()
                else
                    try env.freshVar();
                try env.bind(fld.bind_name, fieldTy);
            }
        },
        .tuple_ => |t| {
            for (t) |nm| try env.bind(nm, try env.freshVar());
        },
        .list, .ctor => {},
    }
}

/// Infer type for call expressions (function/method invocations and pipelines)
fn inferCallExpr(env: *Env, c: ast.CallExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (c.kind) {
        .call => |call| {
            // Method calls carry a receiver expression — infer it first.
            // Exception: a `"std"` module receiver (`bool.negate(x)`) or the
            // builtin `result` namespace (`result.map(r, f)`) is a namespace,
            // not a value binding — synthesize its typed node instead of
            // looking it up (it would be an unbound variable).
            const typedReceiver: ?*ast.TypedExpr = if (call.receiver) |recvExpr| blk: {
                if (recvExpr.* == .identifier and recvExpr.*.identifier.kind == .ident) {
                    const rn = recvExpr.*.identifier.kind.ident;
                    // An explicit `from "std"` import wins over same-named value
                    // bindings (e.g. the primitive type name `bool`); the builtin
                    // `result` namespace is shadowable by a local binding.
                    if (env.stdImports.contains(rn) or
                        (env.lookup(rn) == null and std.mem.eql(u8, rn, "result")))
                    {
                        break :blk try makeTypedPtr(env, TypedExpr{ .identifier = .{
                            .loc = recvExpr.*.identifier.loc,
                            .type_ = try env.namedType("#std_module"),
                            .kind = .{ .ident = rn },
                        } });
                    }
                }
                break :blk try makeTypedPtr(env, try inferExprTyped(env, recvExpr.*));
            } else null;

            const typedArgs = try env.arena.alloc(ast.CallArgOf(.typed), call.args.len);
            for (call.args, 0..) |arg, i| {
                const val = try inferExprTyped(env, arg.value.*);
                typedArgs[i] = .{ .label = arg.label, .value = try makeTypedPtr(env, val) };
            }
            const typedTrailing = try inferTrailingLambdasTyped(env, call.trailing);

            if (call.is_builtin) {
                const retType = try inferBuiltinCallReturnType(env, call.callee, typedArgs, typedTrailing);
                return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
                    .receiver = null,
                    .callee = call.callee,
                    .is_builtin = call.is_builtin,
                    .args = typedArgs,
                    .trailing = typedTrailing,
                } } } };
            }
            // Builtin `result` namespace: `result.map(r, f)`, `result.unwrap(r, 0)`,
            // `result.isOk(r)`… — Gleam-style qualified surface over the built-in
            // `@Result` method ops. No import needed (builtin, not a "std" module);
            // a local value binding named `result` shadows the namespace.
            if (call.receiver) |recvExpr| {
                if (recvExpr.* == .identifier and recvExpr.*.identifier.kind == .ident) {
                    const recvName = recvExpr.*.identifier.kind.ident;
                    if (env.lookup(recvName) == null and std.mem.eql(u8, recvName, "result")) {
                        return try inferResultNamespaceCall(env, typedReceiver, call.callee, typedArgs, typedTrailing, loc);
                    }
                }
            }

            // `"std"` package qualified call (F2a): `bool.negate(x)` where
            // `bool` was imported via `import {bool} from "std"`. The explicit
            // import wins over same-named value bindings (e.g. the primitive
            // type name `bool`). The callee resolves in the module's exports
            // table; the fn type is instantiated per call site.
            if (call.receiver) |recvExpr| {
                if (recvExpr.* == .identifier and recvExpr.*.identifier.kind == .ident) {
                    const recvName = recvExpr.*.identifier.kind.ident;
                    if (env.stdImports.contains(recvName)) {
                        if (env.stdModules.get(recvName)) |exports| {
                            const exported = exports.get(call.callee) orelse {
                                var e = TypeError.custom(
                                    "this \"std\" module has no such public function",
                                    "Check the function name against the module's exports.",
                                );
                                e = e.withLoc(loc);
                                env.lastError = e;
                                return error.TypeError;
                            };
                            var seen = std.AutoHashMap(*T.TypeCell, *T.Type).init(env.arena);
                            defer seen.deinit();
                            const instantiated = try instantiateType(env, exported, &seen);
                            const retType: *T.Type = switch (instantiated.deref().*) {
                                .func => |f| blk: {
                                    const total = typedArgs.len + typedTrailing.len;
                                    if (f.params.len != total) {
                                        env.lastError = TypeError.arityMismatch(call.callee, f.params.len, total).withLoc(loc);
                                        return error.TypeError;
                                    }
                                    for (typedArgs, f.params[0..typedArgs.len]) |ta, p| {
                                        try unifyAt(env, p, ta.value.getType(), ta.value.getLoc());
                                    }
                                    break :blk f.ret;
                                },
                                else => try env.freshVar(),
                            };
                            return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
                                .receiver = typedReceiver,
                                .callee = call.callee,
                                .is_builtin = false,
                                .args = typedArgs,
                                .trailing = typedTrailing,
                            } } } };
                        }
                    }
                }
            }

            // Static extension dispatch (F6): `obj.method(args)` resolved via
            // inherent methods, activated `implement`/`extend` blocks, or a
            // qualified call `Sym.method(obj)`. Only bare-identifier receivers
            // dispatch this way; a null result falls through to Result/Option
            // builtins and feat's permissive method typing below.
            if (call.receiver) |recvExpr| {
                if (recvExpr.* == .identifier and recvExpr.*.identifier.kind == .ident) {
                    const recvName = recvExpr.*.identifier.kind.ident;
                    if (try resolveReceiverCall(env, recvName, typedReceiver, call.callee, typedArgs, typedTrailing, loc)) |te| {
                        return te;
                    }
                }
            }

            if (typedReceiver) |recvPtr| {
                // Qualified constructor / static call: `EnumType.Variant(args)`.
                // The receiver names a type definition, so the callee is a global
                // constructor binding (not a method) — resolve it the same way as
                // a plain call and keep the receiver for codegen (`Color.Rgb(..)`).
                if (call.receiver) |re| {
                    if (re.* == .identifier and re.*.identifier.kind == .ident and
                        env.lookupTypeDef(re.*.identifier.kind.ident) != null)
                    {
                        if (env.lookup(call.callee)) |calleeTypeRaw| {
                            // Generic enum variant constructor — instantiate per
                            // call site (the receiver names the type def).
                            const calleeType = try instantiateCtorType(env, re.*.identifier.kind.ident, calleeTypeRaw);
                            const resolved = calleeType.deref();
                            const retType: *T.Type = switch (resolved.*) {
                                .func => |f| blk: {
                                    if (f.params.len == typedArgs.len) {
                                        for (typedArgs, f.params) |ta, p|
                                            try unifyAt(env, p, ta.value.getType(), ta.value.getLoc());
                                    }
                                    break :blk f.ret;
                                },
                                .named => resolved,
                                else => try env.freshVar(),
                            };
                            return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
                                .receiver = recvPtr,
                                .callee = call.callee,
                                .is_builtin = false,
                                .args = typedArgs,
                                .trailing = typedTrailing,
                            } } } };
                        }
                    }
                }

                // Builtin `@Result` / `@Option` methods — type-check and record
                // the lowering decision.
                if (try inferResultOptionMethod(env, recvPtr, call.callee, typedArgs, typedTrailing, loc)) |dispatched| {
                    return dispatched;
                }

                // Compiler-provided template methods on `expr` / `Binding`
                // receivers (expr-templates F4) — comptime-only.
                if (try inferTemplateMethod(env, recvPtr, call.callee, typedArgs, typedTrailing, loc)) |dispatched| {
                    return dispatched;
                }

                // Other method calls (struct getters, activated extensions) are
                // handled by sibling work — type them permissively as a fresh var
                // so they don't error here.
                return TypedExpr{ .call = .{ .loc = loc, .type_ = try env.freshVar(), .kind = .{ .call = .{
                    .receiver = recvPtr,
                    .callee = call.callee,
                    .is_builtin = false,
                    .args = typedArgs,
                    .trailing = typedTrailing,
                } } } };
            }

            const calleeTypeRaw = if (env.lookup(call.callee)) |ty| ty else {
                env.lastError = TypeError.unboundVariable(call.callee).withLoc(loc);
                return error.TypeError;
            };
            // Generic record/struct/enum constructor: instantiate per call site
            // so the registration-time cells never unify destructively.
            const calleeType = try instantiateCtorType(env, call.callee, calleeTypeRaw);
            const resolved = calleeType.deref();
            const retType: *T.Type = switch (resolved.*) {
                .func => |f| blk: {
                    // Constrained comptime typeparam args are validated against their
                    // declared constraints; their param slots skip ordinary unification.
                    const typeparams = env.lookupTypeparams(call.callee);
                    if (typeparams) |constraints| try validateTypeparams(env, constraints, typedArgs);
                    // `expr` meta-kind params capture their argument unevaluated
                    // instead of unifying it against `expr T` (expr-templates F4).
                    const exprParams = env.lookupExprParams(call.callee);

                    var spreadCount: usize = 0;
                    var nonSpreadCount: usize = 0;
                    for (typedArgs) |ta| {
                        if (ta.label) |lbl| {
                            if (std.mem.eql(u8, lbl, "..")) {
                                spreadCount += 1;
                                continue;
                            }
                        }
                        nonSpreadCount += 1;
                    }

                    if (spreadCount == 0) {
                        if (f.params.len != call.args.len) {
                            env.lastError = TypeError.arityMismatch(call.callee, f.params.len, call.args.len).withLoc(loc);
                            return error.TypeError;
                        }
                        var captures: std.ArrayListUnmanaged(template.CapturedExpr) = .empty;
                        for (typedArgs, f.params, 0..) |ta, paramType, i| {
                            if (typeparams) |constraints| if (isTypeparamIndex(constraints, i)) continue;
                            if (exprParams) |eps| if (exprParamAt(eps, i)) |ep| {
                                try captures.append(env.arena, try captureExprArg(env, call.callee, ep, call.args[i].value, ta, paramType));
                                continue;
                            };
                            try unifyAt(env, paramType, ta.value.getType(), ta.value.getLoc());
                        }
                        const capturedSlice: []const template.CapturedExpr = if (captures.items.len > 0)
                            try captures.toOwnedSlice(env.arena)
                        else
                            &.{};
                        if (capturedSlice.len > 0) {
                            try env.exprCaptures.put(loc, capturedSlice);
                        }
                        // Call-site expansion (F6): a call to a template fn
                        // (`-> expr [T]`) is replaced by its expansion,
                        // re-type-checked in the caller's environment.
                        if (env.templateFns.get(call.callee)) |tfn| {
                            return try expandTemplateCall(env, tfn, capturedSlice, f.ret, loc);
                        }
                        break :blk f.ret;
                    }

                    // Keep the historical spread behavior (and snapshots) for narrow update/error cases.
                    if (spreadCount != 1 or nonSpreadCount < 2) {
                        if (f.params.len != call.args.len) {
                            env.lastError = TypeError.arityMismatch(call.callee, f.params.len, call.args.len).withLoc(loc);
                            return error.TypeError;
                        }
                        for (typedArgs, f.params, 0..) |ta, paramType, i| {
                            if (typeparams) |constraints| if (isTypeparamIndex(constraints, i)) continue;
                            try unifyAt(env, paramType, ta.value.getType(), ta.value.getLoc());
                        }
                        break :blk f.ret;
                    }

                    if (nonSpreadCount > f.params.len) {
                        env.lastError = TypeError.arityMismatch(call.callee, f.params.len, nonSpreadCount).withLoc(loc);
                        return error.TypeError;
                    }

                    var paramIndex: usize = 0;
                    for (typedArgs) |ta| {
                        if (ta.label) |lbl| {
                            if (std.mem.eql(u8, lbl, "..")) continue;
                        }
                        if (paramIndex >= f.params.len) {
                            env.lastError = TypeError.arityMismatch(call.callee, f.params.len, nonSpreadCount).withLoc(loc);
                            return error.TypeError;
                        }
                        try unifyAt(env, f.params[paramIndex], ta.value.getType(), ta.value.getLoc());
                        paramIndex += 1;
                    }
                    break :blk f.ret;
                },
                .named => resolved,
                else => try env.freshVar(),
            };
            return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
                .receiver = null,
                .callee = call.callee,
                .is_builtin = call.is_builtin,
                .args = typedArgs,
                .trailing = typedTrailing,
            } } } };
        },
        .pipeline => |p| {
            const lhsTyped = try inferExprTyped(env, p.lhs.*);
            const lhsPtr = try makeTypedPtr(env, lhsTyped);
            // When the RHS is a plain call, the LHS value is the first argument.
            // Build the typed RHS manually to avoid the arity check in inferCallExpr.
            if (p.rhs.* == .call and p.rhs.*.call.kind == .call) {
                const call = p.rhs.*.call.kind.call;
                const calleeType = if (env.lookup(call.callee)) |ty| ty else try env.freshVar();
                const resolved = calleeType.deref();
                const retType: *T.Type = switch (resolved.*) {
                    .func => |f| blk: {
                        const totalArgs = call.args.len + 1;
                        if (f.params.len == totalArgs) {
                            try unifyAt(env, f.params[0], lhsTyped.getType(), loc);
                            for (call.args, 1..) |arg, i| {
                                const argTyped = try inferExprTyped(env, arg.value.*);
                                try unifyAt(env, f.params[i], argTyped.getType(), loc);
                            }
                        }
                        break :blk f.ret;
                    },
                    else => try env.freshVar(),
                };
                // Build a typed call node for the RHS (with pipeline arity).
                const typedCallArgs = try env.arena.alloc(ast.CallArgOf(.typed), call.args.len);
                for (call.args, 0..) |arg, i| {
                    const val = try inferExprTyped(env, arg.value.*);
                    typedCallArgs[i] = .{ .label = arg.label, .value = try makeTypedPtr(env, val) };
                }
                const typedTrailing = try inferTrailingLambdasTyped(env, call.trailing);
                const rhsNode = TypedExpr{ .call = .{ .loc = p.rhs.*.getLoc(), .type_ = retType, .kind = .{ .call = .{
                    .receiver = null,
                    .callee = call.callee,
                    .is_builtin = call.is_builtin,
                    .args = typedCallArgs,
                    .trailing = typedTrailing,
                } } } };
                const rhsPtr = try makeTypedPtr(env, rhsNode);
                return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .pipeline = .{
                    .lhs = lhsPtr,
                    .rhs = rhsPtr,
                    .comment = p.comment,
                } } } };
            }
            const rhsTyped = try inferExprTyped(env, p.rhs.*);
            const rhsPtr = try makeTypedPtr(env, rhsTyped);
            return TypedExpr{ .call = .{ .loc = loc, .type_ = rhsTyped.getType(), .kind = .{ .pipeline = .{
                .lhs = lhsPtr,
                .rhs = rhsPtr,
                .comment = p.comment,
            } } } };
        },
    };
}

/// Infer type for function definition expressions (lambdas and anonymous functions)
fn inferFunctionExpr(env: *Env, func: ast.FunctionExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return inferFunctionExprExpected(env, func, loc, null);
}

/// Infer a lambda / anonymous-function expression. When `expected` is a
/// function type (e.g. from a `val f: fn(A, B) -> R = ...` annotation, or a
/// `fn`-typed parameter), the lambda's parameters are bound to the expected
/// parameter types *before* the body is inferred — so the body can resolve
/// member calls and operators against the annotated types — and the body's
/// result is unified with the expected return type.
fn inferFunctionExprExpected(env: *Env, func: ast.FunctionExprOf(.untyped), loc: ast.Loc, expected: ?*T.Type) InferError!TypedExpr {
    // A nested function expression has no declared return type, so `throw`
    // inside it is not checked against the enclosing fn's `E`.
    const savedThrowCtx = env.throwContext;
    env.throwContext = .unchecked;
    defer env.throwContext = savedThrowCtx;

    // A nested function gets its own async/label scope: it does not inherit the
    // enclosing `*fn`'s `await`/`yield`/label context.
    const prevStarFn = env.starFn;
    const prevLabelsLen = env.labelStack.items.len;
    defer {
        env.starFn = prevStarFn;
        env.labelStack.shrinkRetainingCapacity(prevLabelsLen);
    }
    env.labelStack.shrinkRetainingCapacity(0);

    const fk = func.kind;
    // An anonymous `*fn(...)` has no declared return type, so we permit both
    // `await` and `yield` (item type unknown ⇒ no unification). Lambdas and plain
    // `fn` expressions clear the async context.
    env.starFn = if (fk.syntax == .fnExpr and fk.isStarFn)
        .{ .allowsAwait = true, .iterItem = null }
    else
        null;

    // Pull expected param/return types out of `expected`, but only when it is a
    // function type whose arity matches this lambda. This lets `val f: fn(A, B)
    // -> R = { a, b -> ... }` bind the params to A/B before the body is inferred.
    var expParams: ?[]*T.Type = null;
    var expRet: ?*T.Type = null;
    if (expected) |e| {
        const d = e.deref();
        if (d.* == .func and d.func.params.len == fk.params.len) {
            expParams = d.func.params;
            expRet = d.func.ret;
        }
    }

    const params = try env.arena.alloc(*T.Type, fk.params.len);
    for (fk.params, 0..) |p, i| {
        params[i] = if (expParams) |ep| ep[i] else try env.freshVar();
        try env.bind(p, params[i]);
    }
    const bodyTyped = try inferStmtsTyped(env, fk.body);
    // The lambda's return type is its tail expression's type; an explicit
    // `return expr` tail types as void, so use the returned value's type.
    const retType = if (bodyTyped.len > 0) blk: {
        const tail = bodyTyped[bodyTyped.len - 1].expr;
        if (tail == .jump and tail.jump.kind == .@"return") {
            break :blk if (tail.jump.kind.@"return") |rv| rv.getType() else try env.namedType("void");
        }
        break :blk tail.getType();
    } else try env.namedType("void");
    if (expRet) |er| try unifyAt(env, retType, er, loc);
    const funcType = try env.funcType(params, retType);
    return TypedExpr{ .function = .{ .loc = loc, .type_ = funcType, .kind = .{
        .syntax = fk.syntax,
        .params = fk.params,
        .body = bodyTyped,
        .isStarFn = fk.isStarFn,
    } } };
}

/// Infer type for collection expressions (arrays, tuples, ranges, case, block, grouped)
fn inferCollectionExpr(env: *Env, col: ast.CollectionExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (col.kind) {
        .arrayLit => |al| {
            const typedElems = try env.arena.alloc(ast.TypedExpr, al.elems.len);
            for (al.elems, 0..) |elem, i| {
                typedElems[i] = try inferExprTyped(env, elem);
            }
            const elemType = if (typedElems.len > 0) typedElems[0].getType() else try env.freshVar();
            for (typedElems) |elem| {
                try unify(env, elemType, elem.getType());
            }
            const arrayArgs = try env.arena.alloc(*T.Type, 1);
            arrayArgs[0] = elemType;
            const arrayType = try env.namedTypeArgs("array", arrayArgs);
            return TypedExpr{ .collection = .{ .loc = loc, .type_ = arrayType, .kind = .{ .arrayLit = .{
                .elems = typedElems,
                .spread = al.spread,
                .spreadExpr = if (al.spreadExpr) |se| try makeTypedPtr(env, try inferExprTyped(env, se.*)) else null,
                .comments = al.comments,
                .commentsPerElem = al.commentsPerElem,
                .trailingComma = al.trailingComma,
            } } } };
        },

        .tupleLit => |tl| {
            const typedElems = try env.arena.alloc(ast.TypedExpr, tl.elems.len);
            const elemTypes = try env.arena.alloc(*T.Type, tl.elems.len);
            for (tl.elems, 0..) |elem, i| {
                typedElems[i] = try inferExprTyped(env, elem);
                elemTypes[i] = typedElems[i].getType();
            }
            const tupleType = try env.namedTypeArgs("tuple", elemTypes);
            return TypedExpr{ .collection = .{ .loc = loc, .type_ = tupleType, .kind = .{ .tupleLit = .{
                .elems = typedElems,
                .comments = tl.comments,
                .commentsPerElem = tl.commentsPerElem,
            } } } };
        },

        .range => |r| {
            const startTyped = try inferExprTyped(env, r.start.*);
            const startPtr = try makeTypedPtr(env, startTyped);
            const endPtr = if (r.end) |e| try makeTypedPtr(env, try inferExprTyped(env, e.*)) else null;
            return TypedExpr{ .collection = .{ .loc = loc, .type_ = try env.namedType("Range"), .kind = .{ .range = .{
                .start = startPtr,
                .end = endPtr,
            } } } };
        },

        .case => |c| {
            const typedSubjects = try env.arena.alloc(ast.TypedExpr, c.subjects.len);
            for (c.subjects, 0..) |subj, i| {
                typedSubjects[i] = try inferExprTyped(env, subj);
            }

            const typedArms = try env.arena.alloc(ast.CaseArmOf(.typed), c.arms.len);
            for (c.arms, 0..) |arm, i| {
                var snapshots: std.ArrayListUnmanaged(PatternBindingSnapshot) = .empty;
                defer snapshots.deinit(env.arena);
                try bindCaseArmPatternNames(env, arm.pattern, typedSubjects, &snapshots);

                // A guard clause must type-check to a boolean, with the
                // pattern's bindings in scope.
                var guardTyped: ?ast.TypedExpr = null;
                if (arm.guard) |g| {
                    const gt = inferExprTyped(env, g) catch |err| {
                        try restorePatternBindings(env, snapshots.items);
                        return err;
                    };
                    unifyAt(env, gt.getType(), try env.namedType("bool"), g.getLoc()) catch |err| {
                        try restorePatternBindings(env, snapshots.items);
                        return err;
                    };
                    guardTyped = gt;
                }

                const bodyTyped = inferExprTyped(env, arm.body) catch |err| {
                    try restorePatternBindings(env, snapshots.items);
                    return err;
                };
                try restorePatternBindings(env, snapshots.items);
                typedArms[i] = .{
                    .pattern = arm.pattern,
                    .body = bodyTyped,
                    .guard = guardTyped,
                    .emptyLinesBefore = arm.emptyLinesBefore,
                };
            }

            // A single-subject `case` on an enum or string must cover every
            // possibility (or carry a wildcard), and no arm may be unreachable.
            if (typedSubjects.len == 1) {
                try checkCaseExhaustiveness(env, typedSubjects[0].getType(), c.arms, loc);
            }
            return TypedExpr{ .collection = .{ .loc = loc, .type_ = try env.freshVar(), .kind = .{ .case = .{
                .subjects = typedSubjects,
                .arms = typedArms,
                .trailingComments = c.trailingComments,
            } } } };
        },

        .grouped => |e| {
            return try inferExprTyped(env, e.*);
        },
    };
}

/// Infer type for comptime expressions (comptime, assert, assertPattern).
fn inferComptimeExpr(env: *Env, ct: ast.ComptimeExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (ct.kind) {
        .comptimeExpr => |e| {
            const typed = try inferExprTyped(env, e.*);
            const typedPtr = try makeTypedPtr(env, typed);
            return TypedExpr{ .comptime_ = .{ .loc = loc, .type_ = typed.getType(), .kind = .{ .comptimeExpr = typedPtr } } };
        },

        .comptimeBlock => |cb| {
            const typedBody = try inferStmtsTyped(env, cb.body);
            const bodyType = if (typedBody.len > 0) typedBody[typedBody.len - 1].expr.getType() else try env.namedType("void");
            return TypedExpr{ .comptime_ = .{ .loc = loc, .type_ = bodyType, .kind = .{ .comptimeBlock = .{
                .body = typedBody,
            } } } };
        },

        .assert => |a| {
            const condTyped = try inferExprTyped(env, a.condition.*);
            // The asserted condition must be a bool.
            try unifyAt(env, try env.namedType("bool"), condTyped.getType(), a.condition.getLoc());
            const condPtr = try makeTypedPtr(env, condTyped);
            const msgPtr = if (a.message) |msg| try makeTypedPtr(env, try inferExprTyped(env, msg.*)) else null;
            return TypedExpr{ .comptime_ = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .assert = .{
                .condition = condPtr,
                .message = msgPtr,
            } } } };
        },

        .assertPattern => |ap| {
            // Use a fresh type variable when the expression can't be inferred (e.g. unbound var).
            const exprTyped = inferExprTyped(env, ap.expr.*) catch |err| blk: {
                if (err != error.TypeError) return err;
                const freshTy = try env.freshVar();
                break :blk TypedExpr{ .literal = .{ .loc = ap.expr.getLoc(), .type_ = freshTy, .kind = .null_ } };
            };
            const exprPtr = try makeTypedPtr(env, exprTyped);
            const handlerExpr = ap.handler.*;
            const handlerTyped = inferExprTyped(env, handlerExpr) catch |err| blk: {
                if (err != error.TypeError) return err;
                const freshTy = try env.freshVar();
                break :blk TypedExpr{ .literal = .{ .loc = handlerExpr.getLoc(), .type_ = freshTy, .kind = .null_ } };
            };
            const handlerPtr = try makeTypedPtr(env, handlerTyped);
            return TypedExpr{ .comptime_ = .{ .loc = loc, .type_ = exprTyped.getType(), .kind = .{ .assertPattern = .{
                .pattern = ap.pattern,
                .expr = exprPtr,
                .handler = handlerPtr,
            } } } };
        },
    };
}

pub fn freshEnv(a: std.mem.Allocator, gpa: std.mem.Allocator) !Env {
    var e = Env.init(a);
    try e.registerBuiltins();
    try comptimeMod.registerStdlib(&e, gpa);
    try e.bind("true", try e.namedType("bool"));
    try e.bind("false", try e.namedType("bool"));
    return e;
}
