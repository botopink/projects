const std = @import("std");
const token = @import("./lexer/token.zig");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");

// Sub-grammar implementations split out of this file. Each module holds free
// functions on `*Parser`; the `Parser` struct below re-exports them as thin
// aliases so `this.parseX()` keeps resolving at every call site.
const types = @import("parser/types.zig");
const patterns = @import("parser/patterns.zig");
const decl_grammar = @import("parser/decls.zig");

pub const Token = token.Token;
pub const TokenKind = token.TokenKind;

pub const ImportDecl = ast.ImportDecl;
pub const ImportSource = ast.ImportSource;
pub const ImportPath = ast.ImportPath;
pub const InterfaceDecl = ast.InterfaceDecl;
pub const InterfaceField = ast.InterfaceField;
pub const InterfaceMethod = ast.InterfaceMethod;
pub const StructDecl = ast.StructDecl;
pub const StructMember = ast.StructMember;
pub const StructField = ast.StructField;
pub const StructGetter = ast.StructGetter;
pub const StructSetter = ast.StructSetter;
pub const Param = ast.Param;
pub const Stmt = ast.Stmt;
pub const Expr = ast.Expr;
pub const CollectionExpr = ast.CollectionExpr;
pub const JumpExpr = ast.JumpExpr;
pub const BranchExpr = ast.BranchExpr;
pub const LoopExpr = ast.LoopExprOf(.untyped);
pub const FunctionExpr = ast.FunctionExpr;
pub const Loc = ast.Loc;
pub const RecordDecl = ast.RecordDecl;
pub const RecordField = ast.RecordField;
pub const ImplementDecl = ast.ImplementDecl;
pub const ExtendDecl = ast.ExtendDecl;
pub const ImplementMethod = ast.ImplementMethod;
pub const DeclKind = ast.DeclKind;
pub const Program = ast.Program;
pub const GenericParam = ast.GenericParam;
pub const ParamModifier = ast.ParamModifier;
pub const CallArg = ast.CallArg;
pub const TrailingLambda = ast.TrailingLambda;
pub const EnumDecl = ast.EnumDecl;
pub const EnumVariant = ast.EnumVariant;
pub const EnumVariantField = ast.EnumVariantField;
pub const FnDecl = ast.FnDecl;
pub const ValDecl = ast.ValDecl;
pub const DelegateDecl = ast.DelegateDecl;
pub const Annotation = ast.Annotation;
pub const FnType = ast.FnType;
pub const FnTypeParam = ast.FnTypeParam;
pub const ParamDestruct = ast.ParamDestruct;
pub const Pattern = ast.Pattern;
pub const ListPatternElem = ast.ListPatternElem;
pub const CaseArm = ast.CaseArm;
pub const TypeRef = ast.TypeRef;

// ── Parser error types ────────────────────────────────────────────────────────

pub const ParseErrorType = enum {
    /// Generic unexpected token
    unexpectedToken,
    /// Reserved word used as an identifier (e.g. auto = 1)
    reservedWord,
    /// Assignment without 'val'/'var' (e.g. x = 4 instead of val x = 4)
    novalBinding,
    /// Binary operator with no value on its right-hand side (e.g. 1 + val a = 5)
    opNakedRight,
    /// List spread without a tail (e.g. [1, 2, ..])
    listSpreadWithoutTail,
    /// Elements after a spread in a list (e.g. [..xs, 1, 2])
    listSpreadNotLast,
    /// Useless spread with no elements to its left (e.g. [..wibble])
    uselessSpread,
    /// Removed error union syntax `T!E` (use `@Result<D, E>` instead)
    removedErrorUnion,
    /// Removed builtin type syntax `@Result(D, E)` (use `@Result<D, E>` instead)
    removedBuiltinType,
    /// `use` hook after branch/return (must be in static prefix)
    useAfterBranch,
    /// Anonymous `implement`/`extend` block (the name is required)
    anonymousImplExtend,
};

pub const ParseErrorInfo = struct {
    kind: ParseErrorType,
    /// Byte offset of the start of the problematic token in the original source
    start: usize,
    /// Byte offset of the end (exclusive)
    end: usize,
    /// Lexeme of the problematic token
    lexeme: []const u8,
    /// Line number (1-based) ---- used when source is not available
    line: usize = 1,
    /// Column (1-based) ---- used when source is not available
    col: usize = 1,
    /// Extra context (e.g. the reserved word name)
    detail: ?[]const u8 = null,
};

pub const ParseError = error{ UnexpectedToken, OutOfMemory };

// ── Parser ────────────────────────────────────────────────────────────────────

pub const Parser = struct {
    tokens: []const Token,
    current: usize,
    /// Populated when parse() returns ParseError.unexpectedToken
    parseError: ?ParseErrorInfo,
    /// Original source text (for span calculation, when available)
    source: ?[]const u8,
    /// When true, `parsePrimary` will not consume trailing `{ }` lambda blocks.
    noTrailingLambda: bool = false,
    /// When true, `parsePipelineExpr` will not consume a trailing `catch` operator.
    noTailCatch: bool = false,
    /// Auto-incrementing counters for unique IDs per declaration type.
    id_counters: struct {
        interface: u32 = 0,
        @"struct": u32 = 0,
        record: u32 = 0,
        @"enum": u32 = 0,
    } = .{},
    const This = @This();

    pub fn init(tokens: []const Token) Parser {
        return .{
            .tokens = tokens,
            .current = 0,
            .parseError = null,
            .source = null,
        };
    }

    /// Returns the next ID counter for a declaration type.
    /// The caller stores this as a u32; formatting happens in the formatter.
    pub fn nextId(this: *This, comptime kind: []const u8) u32 {
        const counter = &@field(this.id_counters, kind);
        counter.* += 1;
        return counter.*;
    }

    /// Consumes an optional `@type_NNNN` ID token after the declaration name.
    /// Always returns 0 when absent (IDs are parser-generated on first parse).
    pub fn tryParseId(this: *This) u32 {
        if (this.check(.at)) {
            _ = this.advance(); // skip @
            if (this.check(.identifier)) {
                _ = this.advance(); // skip type_NNNN token
            }
        }
        return 0;
    }

    /// Creates a Loc from a Token's line and column.
    pub fn locFromToken(tok: Token) Loc {
        return .{
            .line = tok.line,
            .col = tok.col,
        };
    }

    /// Initializes with the original source for richer error messages.
    pub fn initWithSource(tokens: []const Token, source: []const u8) Parser {
        return .{
            .tokens = tokens,
            .current = 0,
            .parseError = null,
            .source = source,
        };
    }

    pub fn deinit(this: *This) void {
        _ = this;
    }

    pub fn parse(this: *This, alloc: std.mem.Allocator) ParseError!Program {
        var decls: std.ArrayList(DeclKind) = .empty;
        errdefer {
            for (decls.items) |*d| d.deinit(alloc);
            decls.deinit(alloc);
        }
        while (!this.check(.endOfFile)) {
            const decl: DeclKind = if (this.check(.import)) blk: {
                const d = try this.parseImportDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .use = d };
            } else if (this.isActivationStmt()) blk: {
                const d = try this.parseActivationStmt(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .use = d };
            } else if (this.checkShorthand(.@"fn") or this.checkStarFn()) blk: {
                const d = try this.parseFnDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .@"fn" = d };
            } else if (this.checkShorthand(.@"enum")) blk: {
                const d = try this.parseShorthandEnumDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .@"enum" = d };
            } else if (this.checkShorthand(.@"struct")) blk: {
                const d = try this.parseShorthandStructDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .@"struct" = d };
            } else if (this.checkShorthand(.record)) blk: {
                const d = try this.parseShorthandRecordDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .record = d };
            } else if (this.checkShorthandDelegate()) blk: {
                const d = try this.parseShorthandDelegateDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .delegate = d };
            } else if (this.checkShorthand(.interface)) blk: {
                const d = try this.parseShorthandInterfaceDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .interface = d };
            } else if (this.checkNamedDecl(.implement)) blk: {
                const d = try this.parseShorthandImplementDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .implement = d };
            } else if (this.checkNamedDecl(.extend)) blk: {
                const d = try this.parseShorthandExtendDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .extend = d };
            } else if (this.check(.loop)) blk: {
                // top-level loop statement: parsed as a val named "_loop"
                const e = try this.parseLoopExpr(alloc);
                const ePtr = try this.boxExpr(alloc, .{ .loop = e });
                _ = this.match(.semicolon);
                break :blk DeclKind{ .val = ast.ValDecl{ .name = "_loop", .value = ePtr } };
            } else if (this.checkShorthand(.val)) blk: {
                const decl = try this.parseValForm(alloc);
                // Optional semicolon after top-level val declaration
                _ = this.match(.semicolon);
                break :blk decl;
            } else if (this.check(.hash)) blk: {
                // Annotations precede the declaration — peek past them to find the keyword.
                const annEnd = this.skipAnnotationsLookaheadFrom(0);
                const tok = this.peekAt(annEnd).kind;
                const isPub = tok == .@"pub";
                const eff = if (isPub) this.peekAt(annEnd + 1).kind else tok;
                const decl: DeclKind = switch (eff) {
                    .@"fn", .star => DeclKind{ .@"fn" = try this.parseFnDecl(alloc) },
                    .@"struct" => DeclKind{ .@"struct" = try this.parseShorthandStructDecl(alloc) },
                    .@"enum" => DeclKind{ .@"enum" = try this.parseShorthandEnumDecl(alloc) },
                    .record => DeclKind{ .record = try this.parseShorthandRecordDecl(alloc) },
                    .interface => DeclKind{ .interface = try this.parseShorthandInterfaceDecl(alloc) },
                    .declare => DeclKind{ .delegate = try this.parseShorthandDelegateDecl(alloc) },
                    else => return ParseError.UnexpectedToken,
                };
                // Optional semicolon after top-level declaration
                _ = this.match(.semicolon);
                break :blk decl;
            } else if (this.check(.commentNormal) or this.check(.commentDoc) or this.check(.commentModule)) blk: {
                const tok = this.advance();
                break :blk DeclKind{ .comment = .{
                    .text = commentText(tok.lexeme),
                    .is_module = tok.kind == .commentModule,
                    .is_doc = tok.kind == .commentDoc,
                } };
            } else {
                // A bare `implement …` / `extend …` (optionally `pub`) with no name:
                // these declarations are always named, so reject with a clear error.
                if (this.check(.implement) or this.check(.extend) or
                    (this.check(.@"pub") and (this.peekAt(1).kind == .implement or this.peekAt(1).kind == .extend)))
                {
                    this.reportAnonImplExtendError();
                    return ParseError.UnexpectedToken;
                }
                if (isReservedWord(this.peek().kind)) {
                    this.reportReservedWordError();
                }
                return ParseError.UnexpectedToken;
            };
            try decls.append(alloc, decl);
        }
        return Program{ .decls = try decls.toOwnedSlice(alloc) };
    }

    /// Dispatches `val [pub] Name = <kind> ...` to the appropriate sub-parser.
    /// Uses pure lookahead ---- no state mutation.
    pub fn parseValForm(this: *This, alloc: std.mem.Allocator) ParseError!DeclKind {
        // Check if we have `val Name : Type = Value` (type annotation) or `val Name = Value`
        var offset: usize = 0;
        if (this.peekAt(offset).kind == .@"pub") offset += 1; // optional pub
        offset += 1; // val
        offset += 1; // Name

        // Check for type annotation (`:`) vs direct assignment (`=`)
        const nextToken = this.peekAt(offset).kind;

        // If we have `:` followed by `fn`, this is a typed variable with function type
        // Use parseValDecl which handles type annotations properly
        if (nextToken == .colon and this.peekAt(offset + 1).kind == .@"fn") {
            return .{ .val = try this.parseValDecl(alloc) };
        }

        // Otherwise use the original logic for shorthand forms
        const baseOffset = this.valBodyOffset();
        const adjustedOffset = this.skipAnnotationsLookaheadFrom(baseOffset);
        const body = this.peekAt(adjustedOffset).kind;
        const bodyNext = this.peekAt(adjustedOffset + 1).kind;
        return switch (body) {
            .@"struct" => .{ .@"struct" = try this.parseStructDecl(alloc) },
            .record => .{ .record = try this.parseRecordDecl(alloc) },
            .implement => .{ .implement = try this.parseImplementDecl(alloc) },
            .extend => .{ .extend = try this.parseExtendDecl(alloc) },
            .@"enum" => .{ .@"enum" = try this.parseEnumDecl(alloc) },
            .declare => .{ .delegate = try this.parseDelegateDecl(alloc) },
            .interface => if (bodyNext == .@"fn")
                .{ .delegate = try this.parseDelegateDecl(alloc) }
            else
                .{ .interface = try this.parseInterfaceDecl(alloc) },
            .@"fn" => .{ .@"fn" = try this.parseFnDeclFromVal(alloc) },
            else => .{ .val = try this.parseValDecl(alloc) },
        };
    }

    /// true if the current token is `kind`, or `pub` followed by `kind`.
    pub inline fn checkShorthand(this: *This, kind: TokenKind) bool {
        return this.check(kind) or (this.check(.@"pub") and this.peekAt(1).kind == kind);
    }

    /// true for a named shorthand decl `Name <kind> …` or `pub Name <kind> …`,
    /// used to detect `Name implement …` / `Name extend …`.
    pub inline fn checkNamedDecl(this: *This, kind: TokenKind) bool {
        if (this.check(.identifier)) return this.peekAt(1).kind == kind;
        if (this.check(.@"pub")) return this.peekAt(1).kind == .identifier and this.peekAt(2).kind == kind;
        return false;
    }

    /// true if a `*fn` (async/generator) declaration is next: `*fn` or `pub *fn`.
    pub inline fn checkStarFn(this: *This) bool {
        if (this.check(.star)) return this.peekAt(1).kind == .@"fn";
        if (this.check(.@"pub")) return this.peekAt(1).kind == .star and this.peekAt(2).kind == .@"fn";
        return false;
    }

    /// true if a shorthand delegate (`declare fn` or `pub declare fn`) is next.
    pub inline fn checkShorthandDelegate(this: *This) bool {
        if (this.check(.declare)) return this.peekAt(1).kind == .@"fn";
        if (this.check(.@"pub")) return this.peekAt(1).kind == .declare and this.peekAt(2).kind == .@"fn";
        return false;
    }

    /// Returns the lookahead offset of the token that follows `[pub] val Name =`.
    /// Does not consume any tokens.
    pub inline fn valBodyOffset(this: *This) usize {
        var offset: usize = 0;
        if (this.peekAt(offset).kind == .@"pub") offset += 1; // optional pub
        offset += 1; // val
        offset += 1; // Name
        offset += 1; // =
        return offset;
    }

    // ── block parsing ──────────────────────────────────────────────────────

    /// How a `{ ... }` block enforces statement-terminating semicolons.
    const SemicolonPolicy = enum {
        /// Every statement must end with `;`.
        required,
        /// `;` is consumed if present but never required.
        optional,
        /// `;` required except for the last statement before `}`.
        requiredExceptLast,
    };

    /// Knobs controlling the single `parseBlock` implementation. All fields are
    /// comptime-known per call so unused branches are pruned.
    const BlockParseOptions = struct {
        /// Record `emptyLinesBefore` on each statement (formatter fidelity).
        trackEmptyLines: bool = false,
        /// Preserve `//`/`///`/`////` comment tokens as comment-literal statements.
        handleComments: bool = false,
        semicolonPolicy: SemicolonPolicy = .required,
        /// Reject a `use` hook that appears after a branch/return (static-prefix rule).
        useAfterBranchGuard: bool = false,
    };

    /// Parse `{ stmt; stmt; ... }`. The opening `{` must be the current token.
    /// Unifies every brace-delimited block in the parser via `BlockParseOptions`.
    pub fn parseBlock(this: *This, alloc: std.mem.Allocator, comptime opts: BlockParseOptions) ParseError![]Stmt {
        _ = try this.consume(.leftBrace);
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(alloc);
            stmts.deinit(alloc);
        }
        var seenBranch = false;
        _ = &seenBranch; // used only when useAfterBranchGuard is set
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const emptyLinesBefore: u32 = if (opts.trackEmptyLines) blk: {
                const prevLine = if (this.current > 0) this.tokens[this.current - 1].line else 1;
                const currLine = this.peek().line;
                break :blk if (currLine > prevLine + 1) @intCast(currLine - prevLine - 1) else 0;
            } else 0;

            if (opts.handleComments and try this.tryParseCommentStmt(alloc, &stmts, emptyLinesBefore)) continue;

            if (opts.useAfterBranchGuard) {
                if (seenBranch and this.check(.use)) {
                    const tok = this.peek();
                    this.parseError = .{
                        .kind = .useAfterBranch,
                        .start = tok.col - 1,
                        .end = tok.col - 1 + tok.lexeme.len,
                        .lexeme = tok.lexeme,
                        .line = tok.line,
                        .col = tok.col,
                    };
                    return ParseError.UnexpectedToken;
                }
                if (this.check(.@"if") or this.check(.@"return") or this.check(.loop) or this.check(.case))
                    seenBranch = true;
            }

            const expr = try this.parseExpr(alloc);
            switch (opts.semicolonPolicy) {
                .required => _ = try this.consume(.semicolon),
                .optional => _ = this.match(.semicolon),
                .requiredExceptLast => if (!this.match(.semicolon) and !this.check(.rightBrace))
                    return ParseError.UnexpectedToken,
            }
            try stmts.append(alloc, .{ .expr = expr, .emptyLinesBefore = emptyLinesBefore });
        }
        _ = try this.consume(.rightBrace);
        return stmts.toOwnedSlice(alloc);
    }

    /// Parse `{ expr; expr; ... }` — a brace-delimited block of semicolon-separated expressions.
    /// The opening `{` must already be the current token.
    pub fn parseStmtListInBraces(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
        return this.parseBlock(alloc, .{
            .trackEmptyLines = true,
            .handleComments = true,
            .semicolonPolicy = .requiredExceptLast,
            .useAfterBranchGuard = true,
        });
    }

    /// Parse either `{ expr; ... }` or a single `expr`.
    /// Used by `if`, `catch`, and any place that accepts a block or bare expression.
    /// Does NOT require semicolon after the bare expression.
    pub fn parseBlockOrExpr(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
        if (this.check(.leftBrace)) {
            return this.parseStmtListInBraces(alloc);
        }
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(alloc);
            stmts.deinit(alloc);
        }
        const expr = try this.parseExpr(alloc);
        try stmts.append(alloc, .{ .expr = expr });
        return stmts.toOwnedSlice(alloc);
    }

    /// Parse a block where the last expression doesn't require a semicolon.
    /// Used for catch handlers where `{ throw Error(...) }` is valid.
    pub fn parseBlockWithOptionalTrailingSemicolon(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
        return this.parseBlock(alloc, .{ .semicolonPolicy = .optional });
    }

    // ── shared body / param helpers ───────────────────────────────────────────

    /// Parses `{ stmt; ... }` preserving comment nodes as literal expressions.
    /// Used in fn/method bodies where source comments must be kept.
    pub fn parseMethodBodyStmts(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
        return this.parseBlock(alloc, .{ .handleComments = true });
    }

    /// Parses `{ stmt; ... }` without special comment handling.
    /// Used in implement methods, getters, setters, and interface default bodies.
    pub fn parseSimpleBodyStmts(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
        return this.parseBlock(alloc, .{});
    }

    pub const parseParamList = decl_grammar.parseParamList;

    /// Skips zero or more `#[name(args...)]` sequences from `offset` and returns
    /// the position of the first non-annotation token.  Pure lookahead.
    pub fn skipAnnotationsLookaheadFrom(this: *This, offset: usize) usize {
        var o = offset;
        while (this.peekAt(o).kind == .hash and this.peekAt(o + 1).kind == .leftSquareBracket) {
            o += 2; // skip `#` and `[`
            o += 1; // skip annotation name
            if (this.peekAt(o).kind == .leftParenthesis) {
                o += 1; // skip `(`
                var depth: usize = 1;
                while (depth > 0 and this.peekAt(o).kind != .endOfFile) {
                    switch (this.peekAt(o).kind) {
                        .leftParenthesis => depth += 1,
                        .rightParenthesis => depth -= 1,
                        else => {},
                    }
                    o += 1;
                }
            }
            o += 1; // skip `]`
        }
        return o;
    }

    /// Parses zero or more `#[name(arg, arg)]` annotations at the current position.
    /// Returns an owned slice (empty when no annotations are present).
    pub fn parseAnnotations(this: *This, alloc: std.mem.Allocator) ParseError![]Annotation {
        var list: std.ArrayList(Annotation) = .empty;
        errdefer {
            for (list.items) |*ann| ann.deinit(alloc);
            list.deinit(alloc);
        }
        while (this.check(.hash) and this.peekAt(1).kind == .leftSquareBracket) {
            _ = try this.consume(.hash);
            _ = try this.consume(.leftSquareBracket);
            // Accept any word (identifier or reserved word) as the annotation name.
            const nameTok = this.peek();
            if (nameTok.kind != .identifier and !isReservedWord(nameTok.kind)) return ParseError.UnexpectedToken;
            const name = this.advance().lexeme;
            var args: std.ArrayList([]const u8) = .empty;
            errdefer args.deinit(alloc);
            if (this.match(.leftParenthesis)) {
                while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                    if (this.check(.dot) and this.peekAt(1).kind == .identifier) {
                        // `.erlang` — adjacent source bytes form a single lexeme
                        const dot = try this.consume(.dot);
                        const ident = try this.consume(.identifier);
                        try args.append(alloc, dot.lexeme.ptr[0 .. dot.lexeme.len + ident.lexeme.len]);
                    } else {
                        const tok = this.advance();
                        try args.append(alloc, tok.lexeme);
                    }
                    if (!this.match(.comma)) break;
                }
                _ = try this.consume(.rightParenthesis);
            }
            _ = try this.consume(.rightSquareBracket);
            try list.append(alloc, Annotation{
                .name = name,
                .args = try args.toOwnedSlice(alloc),
            });
        }
        return list.toOwnedSlice(alloc);
    }

    /// The shared opening of a type/interface declaration: visibility, name and
    /// annotations. The keyword that introduces the construct (and the trailing
    /// generic params / body) are parsed by the caller.
    const DeclPreamble = struct {
        isPub: bool,
        name: []const u8,
        annotations: []Annotation,
    };

    /// Frees an owned annotation slice (used on declaration parse-error paths).
    pub fn freeAnnotations(alloc: std.mem.Allocator, annotations: []Annotation) void {
        for (annotations) |*a| a.deinit(alloc);
        alloc.free(annotations);
    }

    /// Parses the shared preamble of a declaration up to and including `keyword`.
    /// Two surface forms are supported:
    ///   - val-form (`shorthand == false`):  `[pub] val Name = #[...] <keyword>`
    ///   - shorthand (`shorthand == true`):   `#[...] [pub] <keyword> Name`
    /// On error the parsed annotations are freed.
    pub fn parseDeclPreamble(this: *This, alloc: std.mem.Allocator, keyword: TokenKind, shorthand: bool) ParseError!DeclPreamble {
        if (shorthand) {
            const annotations = try this.parseAnnotations(alloc);
            errdefer freeAnnotations(alloc, annotations);
            const isPub = this.match(.@"pub");
            _ = try this.consume(keyword);
            const name = (try this.consume(.identifier)).lexeme;
            _ = this.tryParseId();
            return .{ .isPub = isPub, .name = name, .annotations = annotations };
        }
        const isPub = this.match(.@"pub");
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        _ = try this.consume(.equal);
        const annotations = try this.parseAnnotations(alloc);
        errdefer freeAnnotations(alloc, annotations);
        _ = try this.consume(keyword);
        return .{ .isPub = isPub, .name = name, .annotations = annotations };
    }

    // ── expression helper ─────────────────────────────────────────────────────

    /// Creates a heap-allocated copy of an expression.
    pub fn boxExpr(this: *This, alloc: std.mem.Allocator, expr: Expr) ParseError!*Expr {
        _ = this;
        const ptr = try alloc.create(Expr);
        ptr.* = expr;
        return ptr;
    }

    /// The binary-operator enum carried by `binaryOp` expressions.
    const BinOp = @FieldType(ast.BinOpExpr, "op");

    /// Builds a `binaryOp` expression, boxing both operands.
    pub fn makeBinOp(this: *This, alloc: std.mem.Allocator, op: BinOp, opTok: Token, lhs: Expr, rhs: Expr) ParseError!Expr {
        const lhsPtr = try this.boxExpr(alloc, lhs);
        const rhsPtr = try this.boxExpr(alloc, rhs);
        return Expr{ .binaryOp = .{ .loc = locFromToken(opTok), .op = op, .lhs = lhsPtr, .rhs = rhsPtr } };
    }

    /// Builds a `call` expression node (no boxing needed — `args`/`trailing` are already slices).
    pub fn makeCall(
        tok: Token,
        receiver: ?*Expr,
        callee: []const u8,
        is_builtin: bool,
        args: []CallArg,
        trailing: []TrailingLambda,
    ) Expr {
        return Expr{ .call = .{ .loc = locFromToken(tok), .kind = .{ .call = .{
            .receiver = receiver,
            .callee = callee,
            .is_builtin = is_builtin,
            .args = args,
            .trailing = trailing,
        } } } };
    }

    /// Builds a `jump` expression (`return`/`throw`/`try`/`break`/`yield`), boxing `inner` when present.
    pub fn makeJump(this: *This, alloc: std.mem.Allocator, tok: Token, comptime variant: std.meta.Tag(JumpExpr), inner: ?Expr) ParseError!Expr {
        const innerPtr: ?*Expr = if (inner) |e| try this.boxExpr(alloc, e) else null;
        return Expr{ .jump = .{ .loc = locFromToken(tok), .kind = @unionInit(JumpExpr, @tagName(variant), innerPtr) } };
    }

    /// If the current token is a comment, consumes it and appends it as a comment
    /// literal statement to `stmts`, returning true. Otherwise returns false.
    /// `emptyLinesBefore` is recorded on the appended statement.
    pub fn tryParseCommentStmt(this: *This, alloc: std.mem.Allocator, stmts: *std.ArrayList(Stmt), emptyLinesBefore: u32) ParseError!bool {
        if (!this.check(.commentNormal) and !this.check(.commentDoc) and !this.check(.commentModule)) return false;
        const tok = this.advance();
        const kind: ast.CommentKind = if (tok.kind == .commentDoc)
            .{ .doc = "" }
        else if (tok.kind == .commentModule)
            .{ .module = "" }
        else
            .{ .normal = "" };
        const text = try alloc.dupe(u8, commentText(tok.lexeme));
        try stmts.append(alloc, .{
            .expr = Expr{ .literal = .{ .loc = locFromToken(tok), .kind = .{ .comment = .{ .kind = kind, .text = text } } } },
            .emptyLinesBefore = emptyLinesBefore,
        });
        return true;
    }

    /// If `noTailCatch` is false and the next token is `catch`, wraps `expr` in a tryCatch node.
    /// Otherwise returns `expr` unchanged. Used to apply `catch` as a tail operator.
    pub fn wrapCatch(this: *This, alloc: std.mem.Allocator, expr: Expr) ParseError!Expr {
        if (!this.noTailCatch and this.match(.@"catch")) {
            const catchTok = this.tokens[this.current - 1];
            const handler = try this.parseExpr(alloc);
            const exprPtr = try this.boxExpr(alloc, expr);
            const handlerPtr = try this.boxExpr(alloc, handler);
            return Expr{ .branch = .{ .loc = locFromToken(catchTok), .kind = .{ .tryCatch = .{ .expr = exprPtr, .handler = handlerPtr } } } };
        }
        return expr;
    }

    /// Parses comma-separated identifiers (e.g., `extends T1, T2, T3` or `use { a, b, c }`).
    pub fn parseCommaSeparatedIdentifiers(this: *This, alloc: std.mem.Allocator, stopAt: ?TokenKind) ParseError![]const []const u8 {
        var list: std.ArrayList([]const u8) = .empty;
        errdefer list.deinit(alloc);
        if (!this.check(.identifier)) return list.toOwnedSlice(alloc);
        try list.append(alloc, (try this.consume(.identifier)).lexeme);
        while (this.match(.comma)) {
            if (this.check(.rightBrace) or this.check(.rightParenthesis)) break;
            if (stopAt != null and this.check(stopAt.?)) break;
            try list.append(alloc, (try this.consume(.identifier)).lexeme);
        }
        return list.toOwnedSlice(alloc);
    }

    /// Reports a reserved word error for the current token.
    pub fn reportReservedWordError(this: *This) void {
        const tok = this.peek();
        this.parseError = .{
            .kind = .reservedWord,
            .start = tok.col - 1,
            .end = tok.col - 1 + tok.lexeme.len,
            .lexeme = tok.lexeme,
            .line = tok.line,
            .col = tok.col,
            .detail = tok.lexeme,
        };
    }

    // ── val decl ─────────────────────────────────────────────────────────────

    pub const parseValDecl = decl_grammar.parseValDecl;

    pub const parseTypeRef = types.parseTypeRef;

    pub const parseBaseTypeRef = types.parseBaseTypeRef;

    // ── import decl ──────────────────────────────────────────────────────────

    pub const parseImportDecl = decl_grammar.parseImportDecl;

    pub const parseActivationStmt = decl_grammar.parseActivationStmt;

    pub const parseImportList = decl_grammar.parseImportList;

    pub const parseImportItem = decl_grammar.parseImportItem;

    pub const isActivationStmt = decl_grammar.isActivationStmt;

    // ── fn decl ───────────────────────────────────────────────────────────────────

    pub const parseFnDecl = decl_grammar.parseFnDecl;

    pub const parseFnDeclFromVal = decl_grammar.parseFnDeclFromVal;

    pub const parseFnBody = decl_grammar.parseFnBody;

    // ── delegate decl ────────────────────────────────────────────────────────────

    pub const parseDelegateDecl = decl_grammar.parseDelegateDecl;

    pub const parseShorthandDelegateDecl = decl_grammar.parseShorthandDelegateDecl;

    pub const parseDelegateParams = decl_grammar.parseDelegateParams;

    // ── interface decl ───────────────────────────────────────────────────────────

    pub const parseInterfaceDecl = decl_grammar.parseInterfaceDecl;

    pub const parseShorthandInterfaceDecl = decl_grammar.parseShorthandInterfaceDecl;

    pub const parseExtendsClause = decl_grammar.parseExtendsClause;

    pub const parseInterfaceBody = decl_grammar.parseInterfaceBody;

    pub const parseInterfaceMethod = decl_grammar.parseInterfaceMethod;

    pub const parseMethodDecl = decl_grammar.parseMethodDecl;

    // ── struct decl ───────────────────────────────────────────────────────────

    pub const parseStructDecl = decl_grammar.parseStructDecl;

    pub const parseShorthandStructDecl = decl_grammar.parseShorthandStructDecl;

    pub const parseStructBody = decl_grammar.parseStructBody;

    pub const parseStructGetter = decl_grammar.parseStructGetter;

    pub const parseStructSetter = decl_grammar.parseStructSetter;

    // ── record decl ──────────────────────────────────────────────────────────

    pub const parseRecordDecl = decl_grammar.parseRecordDecl;

    pub const parseShorthandRecordDecl = decl_grammar.parseShorthandRecordDecl;

    pub const parseRecordBody = decl_grammar.parseRecordBody;

    // ── implement decl ────────────────────────────────────────────────────────────

    pub const parseImplementDecl = decl_grammar.parseImplementDecl;

    pub const parseShorthandImplementDecl = decl_grammar.parseShorthandImplementDecl;

    pub const parseImplementBody = decl_grammar.parseImplementBody;

    pub const parseExtendDecl = decl_grammar.parseExtendDecl;

    pub const parseShorthandExtendDecl = decl_grammar.parseShorthandExtendDecl;

    pub const parseExtendBody = decl_grammar.parseExtendBody;

    pub const parseImplementMethods = decl_grammar.parseImplementMethods;

    /// Reports an anonymous-implement/extend error for the current token.
    pub fn reportAnonImplExtendError(this: *This) void {
        const tok = this.peek();
        this.parseError = .{
            .kind = .anonymousImplExtend,
            .start = tok.col - 1,
            .end = tok.col - 1 + tok.lexeme.len,
            .lexeme = tok.lexeme,
            .line = tok.line,
            .col = tok.col,
            .detail = tok.lexeme,
        };
    }

    pub const parseImplementMethod = decl_grammar.parseImplementMethod;

    // ── enum decl ─────────────────────────────────────────────────────────────

    pub const parseEnumDecl = decl_grammar.parseEnumDecl;

    pub const parseShorthandEnumDecl = decl_grammar.parseShorthandEnumDecl;

    pub const parseEnumBody = decl_grammar.parseEnumBody;

    // ── case / pattern matching ────────────────────────────────────────────────

    pub const parseCaseExpr = patterns.parseCaseExpr;

    pub const parsePattern = patterns.parsePattern;

    pub const parseSimplePattern = patterns.parseSimplePattern;

    pub const parseListPattern = patterns.parseListPattern;

    // ── comment helpers ───────────────────────────────────────────────────────

    /// Strip the leading `//`, `///`, or `////` prefix (and optional space) from a comment lexeme.
    pub fn commentText(lexeme: []const u8) []const u8 {
        var start: usize = 0;
        while (start < lexeme.len and start < 4 and lexeme[start] == '/') start += 1;
        if (start < lexeme.len and lexeme[start] == ' ') start += 1;
        return lexeme[start..];
    }

    // ── param / type name helpers ─────────────────────────────────────────────

    pub fn consumeParamName(this: *This) ParseError!Token {
        if (this.check(.identifier)) return this.advance();
        return ParseError.UnexpectedToken;
    }

    /// Parses a plain type name token: `Self`, `type`, `null`, or any `identifier`.
    pub fn consumeTypeName(this: *This) ParseError!Token {
        if (this.check(.selfType)) return this.advance();
        if (this.check(.type)) return this.advance();
        if (this.check(.identifier)) return this.advance();
        // Allow `null` and other keywords that can be used as type names
        if (this.check(.null)) return this.advance();
        return ParseError.UnexpectedToken;
    }

    pub const parseGenericParams = types.parseGenericParams;

    pub const parseImplementClause = types.parseImplementClause;

    pub const parseParam = decl_grammar.parseParam;

    // ── expression parser ──────────────────────────────────────────────────────

    pub fn parseExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
        // ── Detect: identifier = expr or identifier : Type = expr ────────────
        if (this.check(.identifier)) {
            const saved = this.current;
            const identTok = this.advance();
            if (this.check(.colon)) {
                // "x: Int = 4" without val/var ---- NovalBinding error
                this.parseError = .{
                    .kind = .novalBinding,
                    .start = identTok.col - 1,
                    .end = identTok.col - 1 + identTok.lexeme.len,
                    .lexeme = identTok.lexeme,
                    .line = identTok.line,
                    .col = identTok.col,
                    .detail = identTok.lexeme,
                };
                return ParseError.UnexpectedToken;
            }
            if (this.match(.equal)) {
                // "x = expr" ---- assignment to a previously declared `var`
                var valExpr = try this.parseExpr(alloc);
                errdefer valExpr.deinit(alloc);
                const valPtr = try this.boxExpr(alloc, valExpr);
                return Expr{ .binding = .{ .loc = locFromToken(identTok), .kind = .{ .assign = .{
                    .target = .{ .name = identTok.lexeme },
                    .op = .assign,
                    .value = valPtr,
                } } } };
            }
            this.current = saved;
        }

        // throw [new] expr
        if (this.check(.throw)) {
            const throwTok = this.advance();
            _ = this.match(.new); // skip optional `new` keyword
            const inner = try this.parseExpr(alloc);
            return this.makeJump(alloc, throwTok, .throw_, inner);
        }

        // `use` prefix operator: `use <hookcall>`. Binding (if any) is handled
        // by the enclosing `val`/`var`, e.g. `val {v, s} = use state(0)`.
        if (this.check(.use)) {
            const useTok = this.advance();
            const loc = locFromToken(useTok);
            const inner = try this.parseExpr(alloc);
            const innerPtr = try this.boxExpr(alloc, inner);
            return Expr{ .useHook = .{ .loc = loc, .kind = .{ .inner = innerPtr } } };
        }

        // try expr [catch handler]
        if (this.check(.@"try")) {
            const tryTok = this.advance();
            const savedNoTailCatch = this.noTailCatch;
            this.noTailCatch = true;
            const inner = try this.parseExpr(alloc);
            this.noTailCatch = savedNoTailCatch;
            const innerPtr = try this.boxExpr(alloc, inner);
            if (this.match(.@"catch")) {
                const handler = try this.parseExpr(alloc);
                const handlerPtr = try this.boxExpr(alloc, handler);
                return Expr{ .branch = .{ .loc = locFromToken(tryTok), .kind = .{ .tryCatch = .{ .expr = innerPtr, .handler = handlerPtr } } } };
            }
            return Expr{ .jump = .{ .loc = locFromToken(tryTok), .kind = .{ .try_ = innerPtr } } };
        }

        // await expr — suspend on a `@Future`; result is the resolved value (like `try`).
        if (this.check(.await)) {
            const awaitTok = this.advance();
            const inner = try this.parseExpr(alloc);
            const innerPtr = try this.boxExpr(alloc, inner);
            return Expr{ .jump = .{ .loc = locFromToken(awaitTok), .kind = .{ .await_ = innerPtr } } };
        }

        // if (cond) { [binding ->] stmt; } [else { stmt; }]
        // OR: if (cond) expr [else expr]
        if (this.check(.@"if")) {
            const ifTok = this.advance();

            _ = try this.consume(.leftParenthesis);
            const cond = try this.parseBinaryExpr(alloc, prec.equality);
            errdefer @constCast(&cond).deinit(alloc);
            _ = try this.consume(.rightParenthesis);
            const condPtr = try this.boxExpr(alloc, cond);

            var binding: ?[]const u8 = null;

            const then_ = if (this.check(.leftBrace)) blk: {
                _ = this.advance(); // consume `{`
                if (this.check(.identifier) and this.peekAt(1).kind == .rightArrow) {
                    binding = this.advance().lexeme;
                    _ = this.advance(); // consume `->`
                }
                var stmts: std.ArrayList(Stmt) = .empty;
                errdefer {
                    for (stmts.items) |*s| s.deinit(alloc);
                    stmts.deinit(alloc);
                }
                while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
                    const expr = try this.parseExpr(alloc);
                    _ = try this.consume(.semicolon);
                    try stmts.append(alloc, .{ .expr = expr });
                }
                _ = try this.consume(.rightBrace);
                break :blk try stmts.toOwnedSlice(alloc);
            } else blk: {
                const expr = try this.parseExpr(alloc);
                var stmts: std.ArrayList(Stmt) = .empty;
                errdefer stmts.deinit(alloc);
                try stmts.append(alloc, .{ .expr = expr });
                break :blk try stmts.toOwnedSlice(alloc);
            };

            const else_ = if (this.match(.@"else")) blk: {
                break :blk if (this.check(.leftBrace))
                    try this.parseStmtListInBraces(alloc)
                else blk2: {
                    const expr = try this.parseExpr(alloc);
                    var stmts: std.ArrayList(Stmt) = .empty;
                    errdefer stmts.deinit(alloc);
                    try stmts.append(alloc, .{ .expr = expr });
                    break :blk2 try stmts.toOwnedSlice(alloc);
                };
            } else null;

            return Expr{ .branch = .{ .loc = locFromToken(ifTok), .kind = .{ .if_ = .{
                .cond = condPtr,
                .binding = binding,
                .then_ = then_,
                .else_ = else_,
            } } } };
        }

        // return expr
        if (this.check(.@"return")) {
            const retTok = this.advance();
            const inner = try this.parseExpr(alloc);
            return this.makeJump(alloc, retTok, .@"return", inner);
        }

        // case expr { arm* }
        if (this.check(.case)) {
            return .{ .collection = try this.parseCaseExpr(alloc) };
        }

        // comptime expr  /  comptime { expr; ... }
        if (this.check(.@"comptime")) {
            const comptimeTok = this.advance();
            if (this.check(.leftBrace)) {
                const body = try this.parseStmtListInBraces(alloc);
                return Expr{ .comptime_ = .{ .loc = locFromToken(comptimeTok), .kind = .{ .comptimeBlock = .{ .body = body } } } };
            } else {
                const inner = try this.parseBinaryExpr(alloc, prec.equality);
                const innerPtr = try this.boxExpr(alloc, inner);
                return Expr{ .comptime_ = .{ .loc = locFromToken(comptimeTok), .kind = .{ .comptimeExpr = innerPtr } } };
            }
        }

        // break [expr]
        if (this.check(.@"break")) {
            const breakTok = this.advance();
            // break with no expression (e.g. bare `break` inside a loop)
            const isEnd = this.check(.rightBrace) or this.check(.endOfFile) or this.check(.newLine) or this.check(.semicolon);
            if (isEnd) {
                return this.makeJump(alloc, breakTok, .@"break", null);
            }
            const inner = try this.parseExpr(alloc);
            return this.makeJump(alloc, breakTok, .@"break", inner);
        }

        // yield [:label] expr
        if (this.check(.yield)) {
            const yieldTok = this.advance();
            // Optional `:label` disambiguating the target generator/loop scope.
            var label: ?[]const u8 = null;
            if (this.check(.colon)) {
                _ = this.advance();
                const labelTok = try this.consume(.identifier);
                label = labelTok.lexeme;
            }
            const inner = try this.parseBinaryExpr(alloc, prec.equality);
            const innerPtr = try this.boxExpr(alloc, inner);
            return Expr{ .jump = .{ .loc = locFromToken(yieldTok), .kind = .{ .yield = .{ .label = label, .value = innerPtr } } } };
        }

        // continue
        if (this.check(.@"continue")) {
            const contTok = this.advance();
            return Expr{ .jump = .{ .loc = locFromToken(contTok), .kind = .@"continue" } };
        }

        // assert condition [,"message"]
        if (this.check(.assert)) {
            const assertTok = this.advance();
            const condition = try this.parseExpr(alloc);
            const conditionPtr = try this.boxExpr(alloc, condition);
            var message: ?*Expr = null;
            if (this.match(.comma)) {
                const msgExpr = try this.parseExpr(alloc);
                message = try this.boxExpr(alloc, msgExpr);
            }
            return Expr{ .comptime_ = .{ .loc = locFromToken(assertTok), .kind = .{ .assert = .{ .condition = conditionPtr, .message = message } } } };
        }

        // loop (iter) { params -> body }  /  loop (iter, 0..) { item, i -> body }
        if (this.check(.loop)) {
            return .{ .loop = try this.parseLoopExpr(alloc) };
        }

        // #(e1, e2, ...) ---- tuple literal
        if (this.check(.hash) and this.peekAt(1).kind == .leftParenthesis) {
            return .{ .collection = try this.parseTupleLitExpr(alloc) };
        }

        // val/var binding (local or destructuring)
        if (this.check(.val) or this.check(.@"var")) {
            return try this.parseLocalBindExpr(alloc);
        }

        // ident += expr  ou  ident.field += expr
        if (this.check(.identifier)) {
            const saved = this.current;
            const first = this.advance();

            // Simple assignment: ident += expr (no field access)
            if (this.match(.plusEqual)) {
                const valExpr = try this.parseExpr(alloc);
                const valPtr = try this.boxExpr(alloc, valExpr);
                return Expr{ .binding = .{ .loc = locFromToken(first), .kind = .{ .assign = .{
                    .target = .{ .name = first.lexeme },
                    .op = .plusAssign,
                    .value = valPtr,
                } } } };
            }

            if (this.check(.dot)) {
                _ = this.advance();
                // Accept both identifier and numberLiteral for tuple access (.0, .1)
                const fieldTok: Token = if (this.check(.numberLiteral))
                    this.advance()
                else
                    try this.consume(.identifier);

                if (this.match(.equal)) {
                    const valExpr = try this.parseBinaryExpr(alloc, prec.equality);
                    const valPtr = try this.boxExpr(alloc, valExpr);
                    const recvPtr = try this.boxExpr(alloc, Expr{ .identifier = .{ .loc = locFromToken(first), .kind = .{ .ident = first.lexeme } } });
                    return Expr{ .binding = .{ .loc = locFromToken(first), .kind = .{ .assign = .{
                        .target = .{ .fieldAccess = .{ .receiver = recvPtr, .field = fieldTok.lexeme } },
                        .op = .assign,
                        .value = valPtr,
                    } } } };
                }

                if (this.match(.plusEqual)) {
                    const valExpr = try this.parseBinaryExpr(alloc, prec.equality);
                    const valPtr = try this.boxExpr(alloc, valExpr);
                    const recvPtr = try this.boxExpr(alloc, Expr{ .identifier = .{ .loc = locFromToken(first), .kind = .{ .ident = first.lexeme } } });
                    return Expr{ .binding = .{ .loc = locFromToken(first), .kind = .{ .assign = .{
                        .target = .{ .fieldAccess = .{ .receiver = recvPtr, .field = fieldTok.lexeme } },
                        .op = .plusAssign,
                        .value = valPtr,
                    } } } };
                }

                this.current = saved;
            } else {
                this.current = saved;
            }
        }

        // ── call expressions & method chains ──
        //   ident(...) {...}, ident {...}, recv.method(...) {...},
        //   zero-arg method calls `r.isOk()`, and chains `a(x).map(f).filter(g)`.
        if (this.check(.identifier)) {
            const saved = this.current;
            const firstTok = this.advance();

            // Establish the chain base: a plain call `ident(args)`, a trailing
            // lambda call `ident { ... }`, or (provisionally) the bare identifier
            // — the latter only becomes a real node once a `.method(...)` follows.
            var base: Expr = Expr{ .identifier = .{ .loc = locFromToken(firstTok), .kind = .{ .ident = firstTok.lexeme } } };
            var baseIsCall = false;

            if (this.check(.leftParenthesis)) {
                const args = try this.parseCallArgs(alloc);
                errdefer {
                    for (args) |*a| a.deinit(alloc);
                    alloc.free(args);
                }
                const trailing = if (this.noTrailingLambda) try alloc.alloc(TrailingLambda, 0) else try this.parseTrailingLambdas(alloc);
                errdefer {
                    for (trailing) |*t| t.deinit(alloc);
                    alloc.free(trailing);
                }
                base = Expr{ .call = .{ .loc = locFromToken(firstTok), .kind = .{ .call = .{
                    .receiver = null,
                    .callee = firstTok.lexeme,
                    .is_builtin = false,
                    .args = args,
                    .trailing = trailing,
                } } } };
                baseIsCall = true;
            } else if (!this.noTrailingLambda and (this.check(.leftBrace) or this.checkLabeledTrailingLambda())) {
                const trailing = try this.parseTrailingLambdas(alloc);
                if (trailing.len > 0) {
                    base = Expr{ .call = .{ .loc = locFromToken(firstTok), .kind = .{ .call = .{
                        .receiver = null,
                        .callee = firstTok.lexeme,
                        .is_builtin = false,
                        .args = &.{},
                        .trailing = trailing,
                    } } } };
                    baseIsCall = true;
                } else {
                    alloc.free(trailing);
                    this.current = saved;
                    return this.wrapCatch(alloc, try this.parsePipelineExpr(alloc));
                }
            }

            // Postfix chain: consume `.method(args)` / `.method { ... }` links.
            // A `.member` with no `(`/trailing is a pure field-access link — roll
            // it back and let `parsePrimary` own `a.b.c` so those snapshots stay
            // identical.
            var sawMethodCall = false;
            while (this.check(.dot)) {
                const dotSaved = this.current;
                _ = this.advance(); // '.'
                const methodTok: Token = if (this.check(.numberLiteral))
                    this.advance()
                else
                    this.consume(.identifier) catch {
                        this.current = dotSaved;
                        break;
                    };

                const hasParen = this.check(.leftParenthesis);
                const hasTrailing = !this.noTrailingLambda and (this.check(.leftBrace) or this.checkLabeledTrailingLambda());
                if (!hasParen and !hasTrailing) {
                    // Field-access link without a call — not our job.
                    this.current = dotSaved;
                    break;
                }

                var args: []CallArg = &.{};
                if (hasParen) args = try this.parseCallArgs(alloc);
                errdefer {
                    for (args) |*a| a.deinit(alloc);
                    alloc.free(args);
                }
                const trailing = if (this.noTrailingLambda) try alloc.alloc(TrailingLambda, 0) else try this.parseTrailingLambdas(alloc);
                errdefer {
                    for (trailing) |*t| t.deinit(alloc);
                    alloc.free(trailing);
                }
                const recvPtr = try this.boxExpr(alloc, base);
                // Use the method token's loc so each chain link has a distinct
                // location (the type-directed method lowering is keyed by loc).
                base = Expr{ .call = .{ .loc = locFromToken(methodTok), .kind = .{ .call = .{
                    .receiver = recvPtr,
                    .callee = methodTok.lexeme,
                    .is_builtin = false,
                    .args = args,
                    .trailing = trailing,
                } } } };
                sawMethodCall = true;
            }

            if (baseIsCall or sawMethodCall) {
                return this.wrapCatch(alloc, base);
            }

            // Bare identifier with no call/chain — let parsePrimary handle it.
            this.current = saved;
        }

        return this.wrapCatch(alloc, try this.parsePipelineExpr(alloc));
    }

    /// `val/var name = expr` or any destructuring variant.
    /// Call when current token is `val` or `var`.
    pub fn parseLocalBindExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
        const mutable = this.peek().kind == .@"var";
        const bindTok = this.advance(); // consume 'val' or 'var'

        // Pattern assertion: val assert Pattern = expr catch handler
        if (this.check(.assert)) {
            const savedPos = this.current;
            const assertTok = this.advance(); // consume 'assert'

            if (this.parsePattern(alloc)) |pattern| {
                if (this.match(.equal)) {
                    // noTailCatch prevents `catch` from being consumed as tail operator
                    const savedNTC2 = this.noTailCatch;
                    this.noTailCatch = true;
                    var expr = try this.parseExpr(alloc);
                    this.noTailCatch = savedNTC2;
                    errdefer expr.deinit(alloc);
                    const exprPtr = try this.boxExpr(alloc, expr);
                    errdefer {
                        exprPtr.deinit(alloc);
                        alloc.destroy(exprPtr);
                    }
                    errdefer {
                        var mutPattern = pattern;
                        mutPattern.deinit(alloc);
                    }

                    if (this.match(.@"catch")) {
                        var catchExpr = if (this.check(.leftBrace)) blk: {
                            const stmts = try this.parseBlockWithOptionalTrailingSemicolon(alloc);
                            errdefer {
                                for (stmts) |*s| s.deinit(alloc);
                                alloc.free(stmts);
                            }
                            const resultOwned = stmts[stmts.len - 1].expr;
                            alloc.free(stmts);
                            break :blk resultOwned;
                        } else try this.parseExpr(alloc);
                        errdefer catchExpr.deinit(alloc);
                        const catchExprPtr = try this.boxExpr(alloc, catchExpr);
                        return Expr{ .comptime_ = .{ .loc = locFromToken(assertTok), .kind = .{ .assertPattern = .{
                            .pattern = pattern,
                            .expr = exprPtr,
                            .handler = catchExprPtr,
                        } } } };
                    } else {
                        return ParseError.UnexpectedToken;
                    }
                } else {
                    var mutPattern = pattern;
                    mutPattern.deinit(alloc);
                }
            } else |_| {}

            this.current = savedPos;
        }

        // Record destructuring: val { x, y } = expr
        if (this.check(.leftBrace)) {
            _ = this.advance();
            var fields: std.ArrayList(ast.FieldDestruct) = .empty;
            errdefer {
                for (fields.items) |f| {
                    alloc.free(f.field_name);
                    alloc.free(f.bind_name);
                }
                fields.deinit(alloc);
            }
            var hasSpread = false;
            while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
                if (this.check(.dotDot)) {
                    _ = this.advance();
                    hasSpread = true;
                    break;
                }
                const field_name = try alloc.dupe(u8, (try this.consume(.identifier)).lexeme);
                const bind_name: []const u8 = if (this.match(.colon))
                    try alloc.dupe(u8, (try this.consume(.identifier)).lexeme)
                else
                    field_name;
                try fields.append(alloc, .{ .field_name = field_name, .bind_name = bind_name });
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightBrace);
            _ = try this.consume(.equal);
            const valPtr = try this.boxExpr(alloc, try this.parseExpr(alloc));
            return Expr{ .binding = .{ .loc = locFromToken(bindTok), .kind = .{ .localBindDestruct = .{
                .pattern = .{ .names = .{ .fields = try fields.toOwnedSlice(alloc), .hasSpread = hasSpread } },
                .value = valPtr,
                .mutable = mutable,
            } } } };
        }

        // Tuple destructuring: val #(a, b) = expr
        if (this.check(.hash) and this.peekAt(1).kind == .leftParenthesis) {
            _ = this.advance();
            _ = this.advance(); // '#' '('
            var names: std.ArrayList([]const u8) = .empty;
            errdefer names.deinit(alloc);
            while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                try names.append(alloc, (try this.consume(.identifier)).lexeme);
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightParenthesis);
            _ = try this.consume(.equal);
            const valPtr = try this.boxExpr(alloc, try this.parseExpr(alloc));
            return Expr{ .binding = .{ .loc = locFromToken(bindTok), .kind = .{ .localBindDestruct = .{
                .pattern = .{ .tuple_ = try names.toOwnedSlice(alloc) },
                .value = valPtr,
                .mutable = mutable,
            } } } };
        }

        // List destructuring: val [...] = expr
        if (this.check(.leftSquareBracket)) {
            const listPattern = try this.parseListPattern(alloc);
            _ = try this.consume(.equal);
            const valPtr = try this.boxExpr(alloc, try this.parseExpr(alloc));
            return Expr{ .binding = .{ .loc = locFromToken(bindTok), .kind = .{ .localBindDestruct = .{
                .pattern = .{ .list = listPattern },
                .value = valPtr,
                .mutable = mutable,
            } } } };
        }

        // Constructor destructuring: val Ctor(fields) = expr
        if (this.check(.identifier)) {
            const saved = this.current;
            const ctorName = this.advance().lexeme;
            if (this.check(.leftParenthesis)) {
                _ = this.advance();
                var args: std.ArrayList(Pattern) = .empty;
                errdefer {
                    for (args.items) |*a| a.deinit(alloc);
                    args.deinit(alloc);
                }
                while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                    try args.append(alloc, try this.parseSimplePattern(alloc));
                    if (!this.match(.comma)) break;
                }
                _ = try this.consume(.rightParenthesis);
                _ = try this.consume(.equal);
                const valPtr = try this.boxExpr(alloc, try this.parseExpr(alloc));
                return Expr{ .binding = .{ .loc = locFromToken(bindTok), .kind = .{ .localBindDestruct = .{
                    .pattern = .{ .ctor = .{ .variant = .{ .name = ctorName, .payload = .{ .literals = try args.toOwnedSlice(alloc) } } } },
                    .value = valPtr,
                    .mutable = mutable,
                } } } };
            }
            this.current = saved;
        }

        // Plain binding: val name [: TypeRef] = expr
        const nameTok = this.tokens[this.current];
        if (nameTok.kind != .identifier and nameTok.kind != .underscore) {
            return ParseError.UnexpectedToken;
        }
        _ = this.advance();
        const name = if (nameTok.kind == .underscore) "_" else nameTok.lexeme;
        if (this.match(.colon)) {
            var typeRef = try this.parseTypeRef(alloc);
            typeRef.deinit(alloc); // discarded — type inference handles it
        }
        _ = try this.consume(.equal);
        const valPtr = try this.boxExpr(alloc, try this.parseExpr(alloc));
        return Expr{ .binding = .{ .loc = locFromToken(bindTok), .kind = .{ .localBind = .{
            .name = name,
            .value = valPtr,
            .mutable = mutable,
        } } } };
    }

    pub fn parsePipelineExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
        var lhs = try this.parseBinaryExpr(alloc, prec.lowest);

        while (true) {
            // Collect any comment that appears before the `|>` operator
            const savedPipe = this.current;
            var pipeComment: ?[]const u8 = null;
            while (this.isComment() or this.check(.newLine)) {
                const tok = this.advance();
                if (tok.kind == .commentNormal) {
                    // Free previous comment if multiple (keep last one)
                    if (pipeComment) |prev| alloc.free(prev);
                    pipeComment = try alloc.dupe(u8, commentText(tok.lexeme));
                }
            }
            if (!this.match(.pipe)) {
                if (pipeComment) |c| alloc.free(c);
                this.current = savedPipe;
                break;
            }
            const opTok = this.tokens[this.current - 1];
            // Skip comment tokens after `|>` (before RHS)
            while (this.isComment() or this.check(.newLine)) {
                _ = this.advance();
            }
            // Pipeline RHS can be a call expression: `add(2)`, `Recv.method(args)`, or a plain expr
            const rhs = rhs_blk: {
                if (this.check(.identifier)) {
                    const saved = this.current;
                    const nameTok = this.advance();
                    if (this.check(.leftParenthesis)) {
                        // ident(args) call
                        const args = try this.parseCallArgs(alloc);
                        errdefer {
                            for (args) |*a| a.deinit(alloc);
                            alloc.free(args);
                        }
                        const trailing = if (this.noTrailingLambda) try alloc.alloc(TrailingLambda, 0) else try this.parseTrailingLambdas(alloc);
                        errdefer {
                            for (trailing) |*t| t.deinit(alloc);
                            alloc.free(trailing);
                        }
                        break :rhs_blk makeCall(nameTok, null, nameTok.lexeme, false, args, trailing);
                    } else if (this.match(.dot)) {
                        const methodTok = try this.consume(.identifier);
                        var args: []CallArg = &.{};
                        if (this.check(.leftParenthesis)) {
                            args = try this.parseCallArgs(alloc);
                        }
                        errdefer {
                            for (args) |*a| a.deinit(alloc);
                            alloc.free(args);
                        }
                        const trailing = if (this.noTrailingLambda) try alloc.alloc(TrailingLambda, 0) else try this.parseTrailingLambdas(alloc);
                        errdefer {
                            for (trailing) |*t| t.deinit(alloc);
                            alloc.free(trailing);
                        }
                        const recvPtr = try this.boxExpr(alloc, Expr{ .identifier = .{ .loc = locFromToken(nameTok), .kind = .{ .ident = nameTok.lexeme } } });
                        break :rhs_blk makeCall(nameTok, recvPtr, methodTok.lexeme, false, args, trailing);
                    } else {
                        this.current = saved;
                    }
                }
                break :rhs_blk try this.parseBinaryExpr(alloc, prec.lowest);
            };
            const lhsPtr = try this.boxExpr(alloc, lhs);
            const rhsPtr = try this.boxExpr(alloc, rhs);
            lhs = Expr{ .call = .{ .loc = locFromToken(opTok), .kind = .{ .pipeline = .{ .lhs = lhsPtr, .rhs = rhsPtr, .comment = pipeComment } } } };
        }

        return lhs;
    }

    /// One operator token and the AST op it maps to, at a given precedence level.
    const PrecedenceOp = struct { tok: TokenKind, op: BinOp };

    /// One precedence level: the operators it recognises (left-associative) plus
    /// whether it enforces the `opNakedRight` rule (a compare op with no RHS value).
    const PrecedenceLevel = struct { ops: []const PrecedenceOp, nakedRightCheck: bool = false };

    /// Binary-operator precedence, lowest level first. `parseBinaryExpr` walks this
    /// table recursively; level == len delegates to `parsePrimary`.
    const precedence_table = [_]PrecedenceLevel{
        .{ .ops = &.{.{ .tok = .verticalBarVerticalBar, .op = .@"or" }} },
        .{ .ops = &.{.{ .tok = .amperAmper, .op = .@"and" }} },
        .{ .ops = &.{ .{ .tok = .equalEqual, .op = .eq }, .{ .tok = .notEqual, .op = .ne } } },
        .{ .ops = &.{
            .{ .tok = .lessThan, .op = .lt },
            .{ .tok = .greaterThan, .op = .gt },
            .{ .tok = .lessThanEqual, .op = .lte },
            .{ .tok = .greaterThanEqual, .op = .gte },
        }, .nakedRightCheck = true },
        .{ .ops = &.{ .{ .tok = .plus, .op = .add }, .{ .tok = .minus, .op = .sub } } },
        .{ .ops = &.{
            .{ .tok = .star, .op = .mul },
            .{ .tok = .slash, .op = .div },
            .{ .tok = .percent, .op = .mod },
        } },
    };

    /// Precedence-level entry points used by callers outside `parseBinaryExpr`.
    pub const prec = struct {
        /// `||` — the loosest binary level (full binary expression).
        pub const lowest: usize = 0;
        /// `==`/`!=` and tighter — the entry point for operand positions where
        /// `||`/`&&` are not accepted (if-conditions, yields, ranges, assignments…).
        pub const equality: usize = 2;
    };

    /// Left-associative precedence-climbing parser driven by `precedence_table`.
    pub fn parseBinaryExpr(this: *This, alloc: std.mem.Allocator, comptime level: usize) ParseError!Expr {
        if (level == precedence_table.len) return this.parsePrimary(alloc);
        const entry = precedence_table[level];

        var lhs = try this.parseBinaryExpr(alloc, level + 1);
        while (true) {
            const op: BinOp = inline for (entry.ops) |o| {
                if (this.match(o.tok)) break o.op;
            } else break;
            const opTok = this.tokens[this.current - 1];
            if (entry.nakedRightCheck and (this.check(.val) or this.check(.endOfFile))) {
                this.parseError = .{
                    .kind = .opNakedRight,
                    .start = opTok.col - 1,
                    .end = opTok.col - 1 + opTok.lexeme.len,
                    .lexeme = opTok.lexeme,
                    .line = opTok.line,
                    .col = opTok.col,
                };
                return ParseError.UnexpectedToken;
            }
            const rhs = try this.parseBinaryExpr(alloc, level + 1);
            lhs = try this.makeBinOp(alloc, op, opTok, lhs, rhs);
        }
        return lhs;
    }

    pub fn parsePrimary(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
        // Unary `-` — negation of any expression (-x, -123, -(a+b), etc.)
        if (this.check(.minus)) {
            const opTok = this.advance();
            const operand = try this.parsePrimary(alloc);
            const operandPtr = try this.boxExpr(alloc, operand);
            return Expr{ .unaryOp = .{ .loc = locFromToken(opTok), .op = .neg, .expr = operandPtr } };
        }

        // { params? -> body } ---- lambda expression (standalone or trailing)
        // Note: regular block expressions are only via @block builtin
        if (this.check(.leftBrace)) {
            const braceTok = this.advance();

            // Check if this is a lambda by looking ahead for `->` or params followed by `->`
            const isLambda = blk: {
                var i = this.current;
                const toks = this.tokens;
                const nextKind = if (i < toks.len) toks[i].kind else .endOfFile;
                // Empty lambda: `{ -> }`
                if (nextKind == .rightArrow) break :blk true;
                // Lambda with params: `{ ident, ident -> }`
                if (nextKind == .identifier) {
                    i += 1;
                    while (i < toks.len and toks[i].kind == .comma) {
                        i += 1;
                        if (i >= toks.len or toks[i].kind != .identifier) break :blk false;
                        i += 1;
                    }
                    const arrowKind = if (i < toks.len) toks[i].kind else .endOfFile;
                    break :blk arrowKind == .rightArrow;
                }
                break :blk false;
            };

            if (isLambda) {
                // Parse lambda: `{ params? -> body }`
                var paramList: std.ArrayList([]const u8) = .empty;
                errdefer paramList.deinit(alloc);

                // Parse parameters if present
                if (this.check(.identifier)) {
                    try paramList.append(alloc, (try this.consume(.identifier)).lexeme);
                    while (this.match(.comma)) {
                        try paramList.append(alloc, (try this.consume(.identifier)).lexeme);
                    }
                }
                _ = try this.consume(.rightArrow);

                // Parse body statements (with semicolons)
                var stmts: std.ArrayList(Stmt) = .empty;
                errdefer {
                    for (stmts.items) |*s| s.deinit(alloc);
                    stmts.deinit(alloc);
                }
                while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
                    const expr = try this.parseExpr(alloc);
                    try stmts.append(alloc, .{ .expr = expr });
                    // Consume semicolon if present
                    if (this.check(.semicolon)) {
                        _ = try this.consume(.semicolon);
                    }
                }
                _ = try this.consume(.rightBrace);

                return Expr{ .function = .{ .loc = locFromToken(braceTok), .kind = .{
                    .syntax = .lambda,
                    .params = try paramList.toOwnedSlice(alloc),
                    .body = try stmts.toOwnedSlice(alloc),
                } } };
            } else {
                // { } without -> is not allowed (use @block builtin instead)
                return ParseError.UnexpectedToken;
            }
        }

        // Unary `!` — logical not
        if (this.check(.bang)) {
            const opTok = this.advance();
            const operand = try this.parsePrimary(alloc);
            const operandPtr = try this.boxExpr(alloc, operand);
            return Expr{ .unaryOp = .{ .loc = locFromToken(opTok), .op = .not, .expr = operandPtr } };
        }

        // @name(args...) ---- built-in function call (same as regular calls, just with @ prefix)
        if (this.check(.builtinIdent)) {
            const nameTok = this.advance();
            const callee = nameTok.lexeme[1..]; // Remove @ prefix

            // Check for @name{ ... } syntax (trailing lambda with no args)
            if (this.check(.leftBrace)) {
                const trailing = try this.parseTrailingLambdas(alloc);
                errdefer {
                    for (trailing) |*t| t.deinit(alloc);
                    alloc.free(trailing);
                }
                return makeCall(nameTok, null, callee, true, &.{}, trailing);
            }

            // Regular @name(args...) syntax
            const args = try this.parseCallArgs(alloc);
            errdefer {
                for (args) |*a| a.deinit(alloc);
                alloc.free(args);
            }

            // Check for trailing lambdas after args
            const trailing = try this.parseTrailingLambdas(alloc);
            errdefer {
                for (trailing) |*t| t.deinit(alloc);
                alloc.free(trailing);
            }

            return makeCall(nameTok, null, nameTok.lexeme[1..], true, args, trailing);
        }

        if (this.check(.stringLiteral)) {
            const tok = this.advance();
            return Expr{ .literal = .{ .loc = locFromToken(tok), .kind = .{ .stringLit = tok.lexeme[1 .. tok.lexeme.len - 1] } } };
        }
        if (this.check(.multilineStringLiteral)) {
            const tok = this.advance();
            // Remove the triple quotes from both ends
            return Expr{ .literal = .{ .loc = locFromToken(tok), .kind = .{ .stringLit = tok.lexeme[3 .. tok.lexeme.len - 3] } } };
        }

        if (this.check(.numberLiteral)) {
            const tok = this.advance();
            return Expr{ .literal = .{ .loc = locFromToken(tok), .kind = .{ .numberLit = tok.lexeme } } };
        }

        if (this.check(.selfType)) {
            const tok = this.advance();
            return Expr{ .identifier = .{ .loc = locFromToken(tok), .kind = .{ .ident = "Self" } } };
        }

        // fn(params) { body } / *fn(params) { body } ---- anonymous function expression
        if (this.check(.@"fn") or (this.check(.star) and this.peekAt(1).kind == .@"fn")) {
            const isStarFn = this.match(.star);
            const fnTok = this.advance();
            _ = try this.consume(.leftParenthesis);
            var params: std.ArrayList([]const u8) = .empty;
            errdefer params.deinit(alloc);
            while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                try params.append(alloc, (try this.consume(.identifier)).lexeme);
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightParenthesis);
            const body = try this.parseStmtListInBraces(alloc);
            return Expr{ .function = .{ .loc = locFromToken(fnTok), .kind = .{
                .syntax = .fnExpr,
                .params = try params.toOwnedSlice(alloc),
                .body = body,
                .isStarFn = isStarFn,
            } } };
        }

        if (this.check(.null)) {
            const tok = this.advance();
            return Expr{ .literal = .{ .loc = locFromToken(tok), .kind = .null_ } };
        }

        // Detect reserved word used as expression
        if (isReservedWord(this.peek().kind)) {
            const tok = this.peek();
            this.parseError = .{
                .kind = .reservedWord,
                .start = tok.col - 1,
                .end = tok.col - 1 + tok.lexeme.len,
                .lexeme = tok.lexeme,
                .line = tok.line,
                .col = tok.col,
                .detail = tok.lexeme,
            };
            return ParseError.UnexpectedToken;
        }

        if (this.check(.identifier)) {
            const tok = this.advance();
            var base: Expr = Expr{ .identifier = .{ .loc = locFromToken(tok), .kind = .{ .ident = tok.lexeme } } };

            // Loop for chained field access: a.b.c.d
            while (this.check(.dot)) {
                _ = this.advance();
                // Accept both identifier and numberLiteral for tuple access
                const fieldTok: Token = if (this.check(.numberLiteral))
                    this.advance()
                else
                    try this.consume(.identifier);
                const recvPtr = try this.boxExpr(alloc, base);
                base = Expr{ .identifier = .{ .loc = locFromToken(tok), .kind = .{ .identAccess = .{
                    .receiver = recvPtr,
                    .member = fieldTok.lexeme,
                } } } };
            }
            return base;
        }

        // Dot-shorthand variant: `.Red` ---- type resolved from context.
        if (this.check(.dot)) {
            const dotTok = this.advance();
            const memberTok = try this.consume(.identifier);
            return Expr{ .identifier = .{ .loc = locFromToken(dotTok), .kind = .{ .dotIdent = memberTok.lexeme } } };
        }

        // [e1, e2, ...] or [e1, ..rest] ---- array literal with optional spread
        if (this.check(.leftSquareBracket)) {
            return .{ .collection = try this.parseArrayLitExpr(alloc) };
        }

        // `(expr)` ---- grouped expression (parentheses for precedence)
        if (this.check(.leftParenthesis)) {
            const parenTok = this.advance();
            const inner = try this.parseExpr(alloc);
            _ = try this.consume(.rightParenthesis);
            const innerPtr = try this.boxExpr(alloc, inner);
            return Expr{ .collection = .{ .loc = locFromToken(parenTok), .kind = .{ .grouped = innerPtr } } };
        }

        return ParseError.UnexpectedToken;
    }

    // ── collection literal helpers ────────────────────────────────────────────

    /// `#(e1, e2, ...)` ---- tuple literal.  Call when current token is `#`.
    pub fn parseTupleLitExpr(this: *This, alloc: std.mem.Allocator) ParseError!CollectionExpr {
        const tupleTok = this.advance(); // '#'
        _ = this.advance(); // '('
        var elems: std.ArrayList(Expr) = .empty;
        errdefer {
            for (elems.items) |*e| e.deinit(alloc);
            elems.deinit(alloc);
        }
        var allComments: std.ArrayList([]const u8) = .empty;
        errdefer {
            for (allComments.items) |c| alloc.free(c);
            allComments.deinit(alloc);
        }
        var commentsPerElem: std.ArrayList(u32) = .empty;
        errdefer commentsPerElem.deinit(alloc);

        while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
            var commentsBefore: u32 = 0;
            while (this.isComment()) {
                const cTok = this.advance();
                try allComments.append(alloc, try alloc.dupe(u8, commentText(cTok.lexeme)));
                commentsBefore += 1;
            }
            if (this.check(.rightParenthesis)) {
                try commentsPerElem.append(alloc, commentsBefore);
                break;
            }
            try commentsPerElem.append(alloc, commentsBefore);
            try elems.append(alloc, try this.parseExpr(alloc));
            if (!this.match(.comma)) break;
        }
        var trailingCount: u32 = 0;
        while (this.isComment()) {
            const cTok = this.advance();
            try allComments.append(alloc, try alloc.dupe(u8, commentText(cTok.lexeme)));
            trailingCount += 1;
        }
        if (allComments.items.len > 0) {
            if (commentsPerElem.items.len == elems.items.len) {
                try commentsPerElem.append(alloc, trailingCount);
            }
        } else {
            commentsPerElem.clearAndFree(alloc);
        }
        _ = try this.consume(.rightParenthesis);
        return .{
            .loc = locFromToken(tupleTok),
            .kind = .{
                .tupleLit = .{
                    .elems = try elems.toOwnedSlice(alloc),
                    .comments = try allComments.toOwnedSlice(alloc),
                    .commentsPerElem = try commentsPerElem.toOwnedSlice(alloc),
                },
            },
        };
    }

    /// `[e1, e2, ...]` or `[e1, ..rest]` ---- array literal.  Call when current token is `[`.
    pub fn parseArrayLitExpr(this: *This, alloc: std.mem.Allocator) ParseError!CollectionExpr {
        const bracketTok = this.advance(); // '['
        var elems: std.ArrayList(Expr) = .empty;
        errdefer {
            for (elems.items) |*e| e.deinit(alloc);
            elems.deinit(alloc);
        }
        var spread: ?[]const u8 = null;
        var spreadExpr: ?*Expr = null;
        errdefer if (spreadExpr) |se| {
            se.deinit(alloc);
            alloc.destroy(se);
        };
        var trailingComma = false;
        var allComments: std.ArrayList([]const u8) = .empty;
        errdefer {
            for (allComments.items) |c| alloc.free(c);
            allComments.deinit(alloc);
        }
        var commentsPerElem: std.ArrayList(u32) = .empty;
        errdefer commentsPerElem.deinit(alloc);

        while (!this.check(.rightSquareBracket) and !this.check(.endOfFile)) {
            var commentsBefore: u32 = 0;
            while (this.isComment()) {
                const cTok = this.advance();
                try allComments.append(alloc, try alloc.dupe(u8, commentText(cTok.lexeme)));
                commentsBefore += 1;
            }

            if (this.check(.dotDot)) {
                try commentsPerElem.append(alloc, commentsBefore);
                _ = this.advance();
                if (this.check(.identifier)) {
                    spread = this.advance().lexeme;
                } else if (!this.check(.rightSquareBracket) and !this.check(.endOfFile) and !this.check(.comma)) {
                    const se = try this.parseExpr(alloc);
                    spreadExpr = try this.boxExpr(alloc, se);
                } else {
                    spread = "";
                }
                if (this.match(.comma)) {
                    if (this.check(.rightSquareBracket)) trailingComma = true;
                }
                break;
            }

            if (this.check(.rightSquareBracket)) {
                try commentsPerElem.append(alloc, 0); // spread slot (no spread)
                try commentsPerElem.append(alloc, commentsBefore); // trailing
                break;
            }

            try commentsPerElem.append(alloc, commentsBefore);
            try elems.append(alloc, try this.parseExpr(alloc));
            if (!this.match(.comma)) break;
            if (this.check(.rightSquareBracket)) {
                trailingComma = true;
                break;
            }
        }

        var trailingCommentCount: u32 = 0;
        while (this.isComment()) {
            const cTok = this.advance();
            try allComments.append(alloc, try alloc.dupe(u8, commentText(cTok.lexeme)));
            trailingCommentCount += 1;
        }

        const hasSpreadSlot = (spread != null or spreadExpr != null);
        if (allComments.items.len > 0 or trailingCommentCount > 0) {
            if (!hasSpreadSlot and commentsPerElem.items.len == elems.items.len) {
                try commentsPerElem.append(alloc, 0);
            }
            if (commentsPerElem.items.len == elems.items.len + 1) {
                try commentsPerElem.append(alloc, trailingCommentCount);
            }
        } else {
            commentsPerElem.clearAndFree(alloc);
        }

        _ = try this.consume(.rightSquareBracket);
        const commentsSlice = try allComments.toOwnedSlice(alloc);
        errdefer {
            for (commentsSlice) |c| alloc.free(c);
            alloc.free(commentsSlice);
        }
        return .{
            .loc = locFromToken(bracketTok),
            .kind = .{
                .arrayLit = .{
                    .elems = try elems.toOwnedSlice(alloc),
                    .spread = spread,
                    .spreadExpr = spreadExpr,
                    .comments = commentsSlice,
                    .commentsPerElem = try commentsPerElem.toOwnedSlice(alloc),
                    .trailingComma = trailingComma,
                },
            },
        };
    }

    // ── lambda / call helpers ─────────────────────────────────────────────────

    /// Parses a block expression: `{ stmt; stmt; ... }`
    pub fn parseBlockExpr(this: *This, alloc: std.mem.Allocator) ParseError!CollectionExpr {
        const braceTok = try this.consume(.leftBrace);

        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(alloc);
            stmts.deinit(alloc);
        }

        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            if (try this.tryParseCommentStmt(alloc, &stmts, 0)) continue;
            const expr = try this.parseExpr(alloc);
            _ = try this.consume(.semicolon);
            try stmts.append(alloc, .{ .expr = expr });
        }
        _ = try this.consume(.rightBrace);

        return .{
            .loc = locFromToken(braceTok),
            .kind = .{
                .block = .{
                    .body = try stmts.toOwnedSlice(alloc),
                },
            },
        };
    }

    /// Returns true if the current token is any kind of comment.
    pub fn isComment(this: *const This) bool {
        const toks = this.tokens;
        if (this.current >= toks.len) return false;
        const k = toks[this.current].kind;
        return k == .commentNormal or k == .commentDoc or k == .commentModule;
    }

    /// Returns true if the upcoming tokens look like a lambda parameter list:
    /// `ident (,ident)* ->`.
    /// Does not consume any tokens.
    pub fn hasLambdaParams(this: *const This) bool {
        var i = this.current;
        const toks = this.tokens;
        if (i >= toks.len or toks[i].kind != .identifier) return false;
        i += 1;
        while (i < toks.len and toks[i].kind == .comma) {
            i += 1;
            if (i >= toks.len or toks[i].kind != .identifier) return false;
            i += 1;
        }
        return i < toks.len and toks[i].kind == .rightArrow;
    }

    /// Returns true if the upcoming tokens (after current) look like a lambda body:
    /// `{ ident (,ident)* -> ... }` or `{ -> ... }`.
    /// Used when current token is `{` to check if this is a lambda vs block.
    pub fn hasLambdaBodyAhead(this: *const This) bool {
        var i = this.current + 1; // Skip the current `{`
        const toks = this.tokens;
        if (i >= toks.len) return false;

        // Check for `->` immediately (lambda with no params)
        if (toks[i].kind == .rightArrow) return true;

        // Check for `ident (,ident)* ->`
        if (toks[i].kind != .identifier) return false;
        i += 1;
        while (i < toks.len and toks[i].kind == .comma) {
            i += 1;
            if (i >= toks.len or toks[i].kind != .identifier) return false;
            i += 1;
        }
        return i < toks.len and toks[i].kind == .rightArrow;
    }

    /// Returns true if the upcoming tokens are `ident : {` ---- a labeled trailing lambda.
    pub fn checkLabeledTrailingLambda(this: *const This) bool {
        const i = this.current;
        const toks = this.tokens;
        return i + 2 < toks.len and
            toks[i].kind == .identifier and
            toks[i + 1].kind == .colon and
            toks[i + 2].kind == .leftBrace;
    }

    /// Parses the body of a lambda after `{` has been consumed.
    /// Grammar: `(ident (, ident)* ->)? stmt* }`
    pub fn parseLambdaBody(this: *This, alloc: std.mem.Allocator) ParseError!FunctionExpr {
        const startTok = this.peek();
        // Detect and parse optional parameter list
        var paramList: std.ArrayList([]const u8) = .empty;
        errdefer paramList.deinit(alloc);

        if (this.hasLambdaParams()) {
            // Consume: ident (, ident)* ->
            try paramList.append(alloc, (try this.consume(.identifier)).lexeme);
            while (this.match(.comma)) {
                try paramList.append(alloc, (try this.consume(.identifier)).lexeme);
            }
            _ = try this.consume(.rightArrow);
        }

        // Parse body statements
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(alloc);
            stmts.deinit(alloc);
        }
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const expr = try this.parseExpr(alloc);
            try stmts.append(alloc, .{ .expr = expr });
        }
        _ = try this.consume(.rightBrace);

        return .{
            .loc = locFromToken(startTok),
            .kind = .{
                .syntax = .lambda,
                .params = try paramList.toOwnedSlice(alloc),
                .body = try stmts.toOwnedSlice(alloc),
            },
        };
    }

    pub fn parseCallArgs(this: *This, alloc: std.mem.Allocator) ParseError![]CallArg {
        _ = try this.consume(.leftParenthesis);
        var args: std.ArrayList(CallArg) = .empty;
        errdefer {
            for (args.items) |*a| a.deinit(alloc);
            args.deinit(alloc);
        }

        while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
            // Collect comments before this argument
            var argComments: std.ArrayList([]const u8) = .empty;
            errdefer argComments.deinit(alloc);
            while (this.isComment()) {
                const cTok = this.advance();
                try argComments.append(alloc, try alloc.dupe(u8, commentText(cTok.lexeme)));
            }

            // Spread argument used by record/variant update calls, e.g. `Ctor(..base, x: 1)`.
            if (this.match(.dotDot)) {
                const valExpr = try this.parseExpr(alloc);
                const valPtr = try this.boxExpr(alloc, valExpr);
                const commentsSlice = try argComments.toOwnedSlice(alloc);
                try args.append(alloc, .{ .label = "..", .value = valPtr, .comments = commentsSlice });
                if (!this.match(.comma)) break;
                continue;
            }

            // Detect named arg: ident : expr
            const label: ?[]const u8 = blk: {
                if (this.check(.identifier)) {
                    const i = this.current;
                    const toks = this.tokens;
                    if (i + 1 < toks.len and toks[i + 1].kind == .colon) {
                        const lbl = this.advance().lexeme; // consume ident
                        _ = this.advance(); // consume ':'
                        break :blk lbl;
                    }
                }
                break :blk null;
            };

            const valExpr = try this.parseExpr(alloc);
            const valPtr = try this.boxExpr(alloc, valExpr);
            const commentsSlice = try argComments.toOwnedSlice(alloc);
            try args.append(alloc, .{ .label = label, .value = valPtr, .comments = commentsSlice });

            if (!this.match(.comma)) break;
        }

        _ = try this.consume(.rightParenthesis);
        return args.toOwnedSlice(alloc);
    }

    /// Parses zero or more trailing lambda blocks:
    ///   `{ params? -> body }`  or  `label: { params? -> body }`
    pub fn parseTrailingLambdas(this: *This, alloc: std.mem.Allocator) ParseError![]TrailingLambda {
        var lambdas: std.ArrayList(TrailingLambda) = .empty;
        errdefer {
            for (lambdas.items) |*t| t.deinit(alloc);
            lambdas.deinit(alloc);
        }

        while (this.check(.leftBrace) or this.checkLabeledTrailingLambda()) {
            // Optional label: `erro: {`
            const label: ?[]const u8 = if (this.checkLabeledTrailingLambda()) lbl: {
                const lbl = this.advance().lexeme; // consume label ident
                _ = this.advance(); // consume ':'
                break :lbl lbl;
            } else null;

            _ = try this.consume(.leftBrace);

            // Detect params
            var paramList: std.ArrayList([]const u8) = .empty;
            errdefer paramList.deinit(alloc);

            if (this.hasLambdaParams()) {
                try paramList.append(alloc, (try this.consume(.identifier)).lexeme);
                while (this.match(.comma)) {
                    try paramList.append(alloc, (try this.consume(.identifier)).lexeme);
                }
                _ = try this.consume(.rightArrow);
            } else if (this.check(.rightArrow)) {
                // `{ -> body }` — explicit no-param lambda; consume the arrow.
                _ = this.advance();
            }

            // Parse body statements
            var stmts: std.ArrayList(Stmt) = .empty;
            errdefer {
                for (stmts.items) |*s| s.deinit(alloc);
                stmts.deinit(alloc);
            }
            while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
                const expr = try this.parseExpr(alloc);
                _ = try this.consume(.semicolon);
                try stmts.append(alloc, .{ .expr = expr });
            }
            _ = try this.consume(.rightBrace);

            try lambdas.append(alloc, .{
                .label = label,
                .params = try paramList.toOwnedSlice(alloc),
                .body = try stmts.toOwnedSlice(alloc),
            });
        }

        return lambdas.toOwnedSlice(alloc);
    }

    // ── primitives ────────────────────────────────────────────────────────────

    pub fn consume(this: *This, kind: TokenKind) ParseError!Token {
        if (this.check(kind)) return this.advance();
        // parseError may not be set here; the top-level caller must populate
        // it before propagating if rich error context is needed.
        return ParseError.UnexpectedToken;
    }

    pub fn match(this: *This, kind: TokenKind) bool {
        if (!this.check(kind)) return false;
        _ = this.advance();
        return true;
    }

    pub fn check(this: *This, kind: TokenKind) bool {
        return this.peek().kind == kind;
    }

    pub fn advance(this: *This) Token {
        const t = this.tokens[this.current];
        if (t.kind != .endOfFile) this.current += 1;
        return t;
    }

    pub fn peek(this: *This) Token {
        return this.tokens[this.current];
    }

    pub fn peekAt(this: *This, offset: usize) Token {
        const i = this.current + offset;
        return if (i < this.tokens.len) this.tokens[i] else this.tokens[this.tokens.len - 1];
    }

    // ── reserved word detection helpers ──────────────────────────────────────

    pub fn isReservedWord(kind: TokenKind) bool {
        return lexer.isReservedWord(kind);
    }

    /// Parses a `loop` expression:
    ///   `loop (iter) { param -> body }`
    ///   `loop (iter, 0..) { item, i -> body }`
    ///   `loop (start..end) { i -> body }`
    ///   `loop (start..) { i -> body }`
    pub fn parseLoopExpr(this: *This, alloc: std.mem.Allocator) ParseError!LoopExpr {
        const loopTok = this.advance(); // consume 'loop'

        // `loop await (iter)` — iterate an `@AsyncIterator`, awaiting each item.
        const awaitLoop = this.match(.await);

        // Optional loop label: `loop :acc (iter) { ... }`.
        var label: ?[]const u8 = null;
        if (this.check(.colon)) {
            _ = this.advance();
            label = (try this.consume(.identifier)).lexeme;
        }

        _ = try this.consume(.leftParenthesis);

        // Parse primary iterator expression (may be a range or identifier)
        const iterExpr = try this.parseRangeExpr(alloc);
        const iterPtr = try this.boxExpr(alloc, iterExpr);

        // Optional index range: `loop (iter, 0..)`
        var indexPtr: ?*Expr = null;
        if (this.match(.comma)) {
            const idxExpr = try this.parseRangeExpr(alloc);
            indexPtr = try this.boxExpr(alloc, idxExpr);
        }

        _ = try this.consume(.rightParenthesis);
        _ = try this.consume(.leftBrace);

        // Parse parameter list: `param1, param2, ...  ->`
        var params: std.ArrayList([]const u8) = .empty;
        errdefer params.deinit(alloc);
        while (this.check(.identifier)) {
            try params.append(alloc, this.advance().lexeme);
            if (!this.match(.comma)) break;
        }
        _ = try this.consume(.rightArrow);

        // Body is already-consumed `{ stmt; ... }`
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(alloc);
            stmts.deinit(alloc);
        }
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const e = try this.parseExpr(alloc);
            _ = try this.consume(.semicolon);
            try stmts.append(alloc, .{ .expr = e });
        }
        _ = try this.consume(.rightBrace);
        const body = try stmts.toOwnedSlice(alloc);

        return .{
            .loc = locFromToken(loopTok),
            .iter = iterPtr,
            .indexRange = indexPtr,
            .params = try params.toOwnedSlice(alloc),
            .body = body,
            .awaitLoop = awaitLoop,
            .label = label,
        };
    }

    /// Parses a range expression `expr..` or `expr..expr`, or falls back to
    /// a plain `parseEqExpr` if `..` is not present.
    pub fn parseRangeExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
        var start = try this.parseBinaryExpr(alloc, prec.equality);
        errdefer start.deinit(alloc);
        if (!this.check(.dotDot)) return start;
        const dotTok = this.advance(); // consume '..'
        const startPtr = try this.boxExpr(alloc, start);
        // Optional end: `0..10` vs `0..`
        const hasEnd = !this.check(.rightParenthesis) and !this.check(.comma) and
            !this.check(.endOfFile);
        if (hasEnd) {
            const end = try this.parseBinaryExpr(alloc, prec.equality);
            const endPtr = try this.boxExpr(alloc, end);
            return Expr{ .collection = .{ .loc = locFromToken(dotTok), .kind = .{ .range = .{ .start = startPtr, .end = endPtr } } } };
        }
        return Expr{ .collection = .{ .loc = locFromToken(dotTok), .kind = .{ .range = .{ .start = startPtr, .end = null } } } };
    }
};

// ── List spread validation ---- public helpers ───────────────────────────────────

pub const ListSpreadError = enum {
    /// Spread without explicit tail: [1, 2, ..]
    noTail,
    /// Elements after spread: [..xs, 1, 2]
    elementsAfterSpread,
    /// Useless spread (sole element, no prepend): [..wibble]
    uselessSpread,
};

/// validates a list element sequence for spread errors.
/// Returns null if valid, or the error kind found.
pub fn validateListSpread(hasSpread: bool, spreadIsLast: bool, elementsBeforeSpread: usize) ?ListSpreadError {
    if (hasSpread) {
        if (!spreadIsLast) return .elementsAfterSpread;
        if (elementsBeforeSpread == 0) return .uselessSpread;
    }
    return null;
}

/// Error messages for invalid list spreads.
pub fn listSpreadErrorMessage(err: ListSpreadError) struct { message: []const u8, hint: []const u8 } {
    return switch (err) {
        .noTail => .{
            .message = "I was expecting a value after this spread",
            .hint = "If a list expression has a spread then a tail must also be given. Example: [1, 2, ..rest]",
        },
        .elementsAfterSpread => .{
            .message = "I wasn't expecting elements after this",
            .hint = "Lists are immutable and singly-linked. Prepend items to the list and then reverse it once you are done.",
        },
        .uselessSpread => .{
            .message = "This spread does nothing",
            .hint = "Try prepending some elements [1, 2, ..list].",
        },
    };
}

/// Prints a list spread error to stderr ---- convenient for CLIs.
/// For tests or custom output destinations, use `print.zig` directly.
pub fn printListSpreadError(err: ListSpreadError, path: []const u8, line: usize, col: usize, span: []const u8) void {
    const msgs = listSpreadErrorMessage(err);
    const stderr = std.io.getStdErr().writer();
    const lineW = blk: {
        var w: usize = 1;
        var n = line;
        while (n >= 10) : (n /= 10) w += 1;
        break :blk w;
    };
    stderr.print("error comptime: syntax error\n", .{}) catch return;
    for (0..lineW + 1) |_| stderr.writeByte(' ') catch return;
    stderr.print("┌─ {s}:{d}:{d}\n", .{ path, line, col }) catch return;
    for (0..lineW + 1) |_| stderr.writeByte(' ') catch return;
    stderr.print("│\n", .{}) catch return;
    stderr.print("{d} │ {s}\n", .{ line, span }) catch return;
    for (0..lineW + 1) |_| stderr.writeByte(' ') catch return;
    stderr.print("│ ", .{}) catch return;
    for (0..col - 1) |_| stderr.writeByte(' ') catch return;
    for (0..span.len) |_| stderr.writeByte('^') catch return;
    stderr.print(" {s}\n\n", .{msgs.message}) catch return;
    for (0..lineW + 1) |_| stderr.writeByte(' ') catch return;
    stderr.print("hint: {s}\n\n", .{msgs.hint}) catch return;
}
