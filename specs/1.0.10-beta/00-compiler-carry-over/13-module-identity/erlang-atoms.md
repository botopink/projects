# Erlang and BEAM — how a module is named today, and what the proposal changes

Paths are relative to `repository/botopink-lang/`. Line numbers were read at `botopink-lang`
; re-locate by symbol.

---

## 1. Current state

### 1.1 The identity a module has in the compiler

A module's identity is its **path string**, produced once and carried unchanged to codegen.

| Producer | Path shape | Where |
|---|---|---|
| blind scan (legacy) | `utils/math.bp` → `utils/math` | `modules/compiler-cli/src/cli/scanner.zig:62` |
| `mod`-tree resolver | root = basename; nested = `join(parent_logical, m.name)` | `modules/compiler-cli/src/cli/resolver.zig:99`, `:210` |
| dependency loader | `<dep>/<stem>` — `std/math`, `rakun/http` | `modules/compiler-cli/src/cli/libs.zig:323` |

It reaches codegen as `ComptimeOutput.name` (`src/comptime.zig:1198`, `:1375` — literally
`mod.path`, or `"main"` when empty) and then `ModuleOutput.name`
(`src/codegen/moduleOutput.zig:87`).

### 1.2 The atom: the path's **basename**, everything else discarded

Three sites implement the same truncation.

`src/codegen/crossModule.zig:80-84` — the shared helper:

```zig
/// Last path segment of a module path — the Erlang/BEAM module atom.
pub fn moduleBasename(path: []const u8) []const u8 {
    if (std.mem.lastIndexOfScalar(u8, path, '/')) |i| return path[i + 1 ..];
    return path;
}
```

`src/codegen/erlang.zig:962-968` writes the `-module` form:

```zig
// Module header. "std" package modules are named `std/<mod>` for output
// layout; the Erlang module atom is the basename (`-module(option).`).
const erl_module_name = if (std.mem.lastIndexOfScalar(u8, module_name, '/')) |i|
    module_name[i + 1 ..]
else
    module_name;
try forms.append(b.arena, .{ .module = erl_module_name });
```

The form is rendered at `src/codegen/beam/erl_emitter.zig:652` — `-module({s}).` — from the
`.module` variant declared at `src/codegen/beam/erl_ast.zig:244` ("the name as spelled"). **The
emitter never quotes it**: whatever the backend puts in that slot lands between the parentheses
verbatim.

`src/codegen/beam_asm.zig:907-913` does the same for the `.S` backend, and says why:

```zig
// The BEAM module atom is the path basename (`std/order` → `order`,
// `web/http` → `http`) — a slash is invalid in an unquoted module atom,
// and cross-module `call_ext` targets resolve by basename (see
// `crossModule.ownerModuleAtom`). Mirrors the Erlang backend's
// `erl_module_name`.
const module_atom = crossModule.moduleBasename(module_name);
```

### 1.3 How a cross-module call resolves the callee's module

`crossModule.build(alloc, outputs)` (`crossModule.zig:86`) walks every module's transformed program
and fills **one flat map keyed by the exported symbol's own name**:

```zig
try exports.put(r.name, .{ .module = ct.name, .kind = .record, … });   // :112
try exports.put(f.name, .{ .module = ct.name, .kind = .@"fn",  … });   // :123
try exports.put(v.name, .{ .module = ct.name, .kind = .val,    … });   // :135
```

A call site then asks for the owner (`crossModule.zig:74-77`):

```zig
pub fn ownerModuleAtom(self: *const CrossModule, name: []const u8) ?[]const u8 {
    const info = self.exports.get(name) orelse return null;
    return moduleBasename(info.module);
}
```

Consumers: `erlang.zig:2666`, `:2685`, `:2697`; `beam_asm.zig:1627`, `:1646`, `:1694`, `:3551`;
`wat.zig:211` (only to flag unlinkable imports). The result is spliced into `call_ext` /
`Mod:Fun(...)` unquoted.

So there are **two** name spaces, both flat and both global to a build: the module atom (basename)
and the export table (bare symbol name). The proposal addresses the first only.

### 1.4 Where the name touches disk

`modules/compiler-cli/src/cli/build.zig:148-155` picks the extension (`.erl`, `.S`, `.js`, `.wat`);
`:184-201` writes the file:

```zig
const sub_path = try std.fmt.allocPrint(gpa, "{s}/{s}{s}", .{ out_dir, o.name, ext });
…
// Create subdirectories if the module path contains slashes.
if (std.fs.path.dirname(sub_path)) |parent| { … createDirPath … }
```

`out_dir` defaults to `"out"` (`build.zig:16`, `run.zig:15`). **The output tree mirrors the source
tree** — `out/std/math.erl`, `out/rakun/http.erl` — and a dependency's modules stay under
`out/<dep>/`. `.botopinkbuild/` is scratch only (`build.zig:89` `build_root`; `clean.zig:8` deletes
both trees).

The `.erl` file therefore lives at a **path**, while its `-module` atom is only the **basename**.
They agree today because `erlc` matches the atom against the file's basename (E1), not its
directory. They stop agreeing the moment two directories hold the same basename.

### 1.5 Where the name is executed

`src/codegen/runtime.zig:451-455`:

```zig
/// An Erlang module name is the path basename (`std/bool` → `bool`) —
/// matches the `-module(...)` atom the erlang backend emits.
fn erlModuleName(name: []const u8) []const u8 { … }
```

`executeErlang` (`runtime.zig:490-590`) writes `<scratch>/<basename>.erl` for the entry and for each
aux module, runs `erlc -o . <basename>` with the scratch dir as cwd, then
`erl -noinput -pa . -s <entry> _botopink_main -s init stop`. `executeBeamAsm` (`:600-682`) is the
same with `erlc +from_asm`. The aux loop skips only an aux whose basename equals the **entry's**
(`:559`, `:654`) — two *aux* modules sharing a basename overwrite each other in the scratch dir with
no diagnostic. **The snapshot harness is flat by construction**, which is why the basename scheme
has held so far.

`botopink run` on erlang is `escript out/<module>.erl` with no `-pa`
(`modules/compiler-cli/src/cli/run.zig:66-71`); `beam` is `unreachable` there and only prints an
`erlc +from_asm` hint (`:53-63`).

`scripts/beam_export_audit.sh:63-80` splits every BEAM snapshot into `<n>/<module>.S` — **the atom
read out of the snapshot becomes a filename directly** (`out = dir "/" mod ".S"`).

### 1.6 Comptime-generated modules

`src/comptime/decorator_eval.zig:128` and `src/comptime/template_eval.zig:165` emit under a
placeholder (`decorator_module` / `template_module`), then rename the header to a content hash —
`decorator_eval.zig:238-241`:

```zig
const module = try std.fmt.allocPrint(arena, "decorator_{x:0>16}", .{std.hash.Wyhash.hash(0, code)});
const header = "-module(" ++ placeholder_module ++ ").";
const renamed = try std.fmt.allocPrint(arena, "-module({s}).{s}", .{ module, code[header.len..] });
```

`template_eval.zig:340-343` is identical with `template_{x:0>16}`. `writeModule`
(`template_eval.zig:120-135`) stages the file and renames it into
`.botopinkbuild/tmp/{template,decorator}/<module>.erl`. The comptime server compiles and loads it
with `compile:file/2` + `code:load_binary/3` (`src/comptime/runtime/persistent_erl.zig:63-73`) and
**never calls `code:purge/1` or `code:delete/1`**; the `.erl` files are never deleted either.

The naming is already content-addressed and already path-free — it is the one place in the compiler
that has no collision problem, because a Wyhash of the generated source is the identity.

### 1.7 What collides, measured

| Collision | Instances |
|---|---|
| `root.bp` in every library → `-module(root)` | 6 (`libs/std`, emilia, erika, jhonstart, onze, rakun) |
| `http.bp` in two places → `-module(http)` | 2 (`libs/std/src/http.bp`, `rakun/src/http.bp`) |
| `libs/std` basenames that are OTP module names | **11** — `math`, `os`, `crypto`, `base64`, `queue`, `sets`, `dict`, `json`, `unicode`, `random`, `erlang` (E14) |
| snapshots already recording a shadowing atom | `-module(math).`, `-module(http).` in `snapshots/codegen/erlang/` |
| duplicate-basename guard in the compiler | **none** — `resolver.Error.DuplicateModule` (`resolver.zig:117`) fires on the same *file* reached twice, never on two files sharing a basename |

The OTP row is the sharpest: shadowing `math` does not produce a diagnostic, it produces an `undef`
at the first call to any OTP function of that module (E15). `libs/std/src/erlang.bp` is
declaration-only today, so its `-module(erlang)` is never emitted — a `pub fn` added to it would be
silently unreachable, because `erlang` is preloaded and cannot be replaced.

---

## 2. The proposal, point by point

```
'namemodule@caminho1.caminho2...#Pessoa.erl'
'@comp__namemodule@caminho1.caminho2...#Pessoa.erl'
```

### 2.1 What holds

| Claim | Evidence | Status |
|---|---|---|
| The atom is legal and the module compiles | [E3](./atom-evidence.md#e3--e4--the-maintainers-atom-fully-quoted-works-end-to-end) | **holds** |
| It loads, remote-calls, answers `?MODULE`, `module_info/1`, `function_exported/3`, `code:which/1` | E4 | **holds** |
| Stack traces show it readably | E5 | **holds** |
| `erl -s` and `escript` accept it | E4 | **holds** |
| The `.S` backend behaves identically | [E17](./atom-evidence.md#e17) | **holds** |
| The `@comp__` prefix works | [E9](./atom-evidence.md#e9--a-leading--forces-quoting) | **holds (quoted)** |
| It removes every same-basename collision | § 1.7 | **holds** |
| It removes OTP shadowing as a side effect (`math` → `math@std…`) | E14/E15 | **holds — and this is the biggest win, larger than the collision it was aimed at** |
| It makes the atom table worse | E6 + § 1.6 | **does not hold** — one atom per module, ~120 ecosystem-wide, against a 1 048 576 limit. The unbounded growth that exists is the comptime server's `template_<hash>` / `decorator_<hash>` modules, which are never purged, and the proposal neither helps nor hurts there |

### 2.2 What breaks

**B1 — the atom decides the filename, so the proposal is a layout change, not a naming change.**
E1: `erlc` refuses a `.erl` whose basename differs from the atom, and the code server refuses the
`.beam` it produces under `+no_error_module_mismatch`. So `'user@app.models#Pessoa'` obliges the
CLI to write a file literally named `user@app.models#Pessoa.erl`. The mirrored `out/<path>.erl`
tree (`build.zig:190`) cannot survive: the path is in the name, so it must not also be in the
directory, or the same information is carried twice and `erlc -o` output lands in a directory whose
shape says nothing. **The front must decide the output layout in the same step as the atom.** The
proposal as written does not mention this and it is its largest hidden cost.

**B2 — quoting becomes mandatory, everywhere, forever.** E2 and E10: `.` closes the attribute, `#`
scans as its own token, a leading `@` is not an atom start. So every emitted call site becomes
`'a@b.c#D':f(X)`, `{extfunc,'a@b.c#D',f,1}` in `.S`, and every hand-written erlang in the repo has
to quote too. `beam/erl_emitter.zig:652` prints the name raw and would have to learn quoting,
as would every `call_ext` target site listed in § 1.3. That is not hard, but it is a rule that can
be violated silently in exactly one direction: forget the quotes once and the module fails to
*parse*, which at least is loud; forget them in `beam_export_audit.sh:80` (`out = dir "/" mod ".S"`)
and a **quote character lands in a filename** and E17's mismatch error appears — with `+from_asm`
exiting 0 (E17), so a check reading only the exit code misses it.

**B3 — `#` does not do what it is being asked to do.** E8: `mod#Pessoa:g()` is a syntax error, and
inside the quotes the atom is 22 opaque characters. Nothing in the BEAM resolves `#Pessoa` against
the module's contents. The intent — "one module per file, so `#` names a declaration inside that
file" — has no runtime meaning; the suffix would be a comment that the linker happens to hash.

Worse, `#` is the one character erlang already spends on something adjacent. E5 shows both in one
file: `#pessoa{nome = "Ana"}` builds a record and `R#pessoa.nome` reads a field, while
`'…#Pessoa':f()` calls a module. A reader — and any tool that splits a name on `#` — now has to
know which of the two it is looking at. `erlc` itself already writes `<name>.bea#` as its staging
file (visible in [E7](./atom-evidence.md#e7--the-real-length-cap-is-the-filename-not-the-atom)).

**B4 — `#` is hostile outside the shell.** `bash` is safe (E11: `#` starts a comment only at the
start of a word), but `make` truncates a variable at `#` (`[user@app.models]`) and a rule whose
target contains one fails with `missing separator`. Any `.gitignore`-style parser, any URL
(fragment), any CI step that builds a file list in `make` or in a config format with `#` comments
hits the same. `rebar3` is not installed here, so its behaviour is **unverified**; E1 already
implies its constraint.

**B5 — the length budget shrinks from 255 to 250 bytes.** E6 caps an atom at 255 characters; E7
shows the `.beam` file is the real constraint at 250. Not a live risk against today's short
project-relative paths, but the proposal's own worst case —
`'@comp__` + module + `@` + a nested `mod` path + `#Decl'` — is the one shape that could reach it,
and nothing in the compiler would diagnose it: the failure surfaces as `erlc: error writing file:
file name too long` (E7), from a build step, not from the checker.

**B6 — it fixes the module name space and leaves the symbol name space untouched.** § 1.3:
`CrossModule.exports` is keyed by the bare exported symbol. Two libraries each exporting `pub fn
get` still overwrite one another in that map, whatever the module atoms are. Any front that claims
to close "module naming" must say this explicitly or the next collision report reopens it.

**B7 — redundant information if the output tree stays.** If B1 is answered by keeping
`out/<path>.erl` *and* encoding the path in the atom, the path is stored twice and the two can
drift (a module moved on disk, a stale `out/`). If it is answered by flattening, `out/` loses the
grouping the JS backend depends on (`commonJS.zig:1858-1870` computes `../` from the *depth of the
requiring module's path*) — so the layout can only be flattened **per target**, not globally.

### 2.3 What `#` was reaching for

The premise "one module per file" is already true in botopink — a `.bp` file is a module. What the
declarations inside it need is a way to be *addressed*, and erlang already gives three, none of
which is a name suffix:

| Botopink declaration | Erlang's mechanism | Shape |
|---|---|---|
| a `type` used in a signature | `-type pessoa() :: …` + `-export_type([pessoa/0])` | `'std@models@user':pessoa()` in a spec |
| a `type` with fields, as a value | a map (what the backend emits today), or `-record(pessoa, …)` in an `.hrl` the consumer includes | `#pessoa{}` — a **tuple shape**, not a namespace; not reachable cross-module without the include |
| a `behavior` | `-behaviour(Mod)` + `-callback` | a module-level contract |
| a method / associated fn | an exported function, already how the backend emits it | `'std@models@user':pessoa_greet(P)` |

So the right reading of the maintainer's `#` is: *the declaration is already addressed — by
`Module:function` and by the record/type forms — and adding it to the module atom adds a third
spelling of the same thing*. The recommendation in [`options.md`](./atom-options.md) keeps the `@`-path
half of the proposal, which solves a real problem, and drops the `#` half, which solves none.
