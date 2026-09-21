> Carried from `specs/1.0.5-beta/13-module-identity/declaration-qualifier.md`, status at carry (2026-09-20): half 1 landed (`154f3bc9`); halves 2–3 (steps 8–19) are C-01, decision 64 is C-03 (uncommitted in `.tasks/identity`), step 6's residuals are C-25. The README still reads T1 and an unticked step 0 — decisions 6, 21, 22, 23 and 62 override it

# A2 — telling apart several modules born of the same source file

The maintainer accepted [option A](./atom-options.md#option-a--the-path-joined-with-) and asked for the
half the `#Pessoa` suffix was reaching for: **when one `.bp` file produces more than one BEAM
module, the atoms must say which declaration each one came from.** This file is that rule.

It is an extension of option A, not a replacement: `erlAtom(path)` still names the module the file
itself emits, unchanged. A2 only adds a suffix for the *extra* modules.

---

## 1. Where the need is real today

One `.bp` file already produces more than one BEAM module — the comptime evaluators do it on every
build, and their names carry **no origin at all**:

| Producer | Atom today | Where |
|---|---|---|
| a template body | `template_3f1a9c02b7e4d5f8` | `src/comptime/template_eval.zig:340` |
| a decorator body | `decorator_9c02b7e4d5f83f1a` | `src/comptime/decorator_eval.zig:238` |

The hash is a Wyhash of the generated erlang source, so it is stable and unique — and it says
neither which file the template was written in nor which template it was. A stack trace, a
`.botopinkbuild/tmp/template/*.erl` listing, and an `erl.stderr.log` line all name a module nobody
can trace back to source without re-hashing. That is the concrete, live case A2 fixes.

The second case is not live yet but the naming must not block it: if a `type` or a `behavior` ever
gets a module of its own (a per-type dispatch module, a behaviour's `-callback` module), the scheme
has to have room for it without another migration.

## 2. The rule

```
atom = erlAtom(path) [ "__" kind "__" decl [ "__" hash ] ]
```

- `erlAtom(path)` — option A's rule, unchanged.
- `"__"` — the **in-file separator**, reserved (§ 4).
- `kind` — a fixed two-or-three letter tag, never a free string:

  | `kind` | Means | Live today |
  |---|---|---|
  | `t` | a `type` declared in that file | no — reserved |
  | `b` | a `behavior` declared in that file | no — reserved |
  | `im` | an `implement` block | no — reserved |
  | `tpl` | a template body evaluated at compile time | **yes** |
  | `dec` | a decorator body evaluated at compile time | **yes** |

- `decl` — the declaration's own name, lowercased, `[^a-z0-9_]` → `_`.
- `hash` — 16 hex, **only for a comptime producer**, because one template declaration evaluates to
  many distinct generated bodies. It is the same Wyhash the evaluators already compute, so
  content-addressing (and therefore the "identical body ⇒ identical module, re-load is a no-op"
  property of `persistent_erl.zig:63-73`) is preserved exactly.

Every form is a legal **unquoted** erlang atom
([E18](./atom-evidence.md#e18--the-in-file-separator-candidates)).

## 3. Worked examples

| Source | What it is | Atom |
|---|---|---|
| `src/models/user.bp` | the file's own module | `models@user` |
| `src/models/user.bp` | `type Pessoa` | `models@user__t__pessoa` |
| `src/models/user.bp` | `type Empresa` | `models@user__t__empresa` |
| `src/models/user.bp` | `behavior Greeter` | `models@user__b__greeter` |
| `src/services/user.bp` | `type Pessoa` (same decl name, other file) | `services@user__t__pessoa` |
| `libs/std/src/math.bp` | `behavior Signed` | `std@math__b__signed` |
| `jhonstart/src/html.bp` | the `html` template, one evaluation | `jhonstart@html__tpl__html__3f1a9c02b7e4d5f8` |
| `onze/src/mock.bp` | the `mock` decorator, one evaluation | `onze@mock__dec__mock__9c02b7e4d5f83f1a` |
| `src/web/api/http.bp` | the file's own module | `web@api@http` |

The four modules of one file compile, load and answer independently
([E19](./atom-evidence.md#e19--four-sibling-modules-from-one-source-file)):

```
$ erlc models@user.erl models@user__t__pessoa.erl models@user__t__empresa.erl models@user__b__greeter.erl
$ erl -pa . -eval 'lists:foreach(fun(M) -> io:format("~p -> ~p~n",[M, M:who()]) end, […])'
models@user             -> models@user
models@user__t__pessoa  -> models@user__t__pessoa
models@user__t__empresa -> models@user__t__empresa
models@user__b__greeter -> models@user__b__greeter
```

## 4. `__` is reserved, and what that costs

For the suffix to be decodable, `__` must never occur inside `erlAtom(path)`. Add one clause to
option A's rule:

```
3b. collapse every run of two or more '_' in a segment to a single '_'
```

`my__mod/user` and `my_mod/user` then both render `my_mod@user`
([E21](./atom-evidence.md#e21--__-has-to-be-reserved)) — a genuine, if pathological, collision. **The
compiler must diagnose it**, not silently pick a winner: two source paths that render to the same
atom is exactly the failure this whole front exists to remove, and the check is a hash-set over the
rendered atoms at the point `crossModule.build` runs (`crossModule.zig:86`). One new diagnostic,
and it also catches the `RESERVED` and length cases for free.

Nothing in the seven repositories uses `__` in a file or directory name today, so the clause costs
nothing now; it only has to exist before it can bite.

**Why `__` and not `@@`.** Both scan as one unquoted atom
([E18](./atom-evidence.md#e18--the-in-file-separator-candidates)), so the choice is readability and prior
art. `@@` would overload the separator option A already spends on path segments — `web@api@@http`
reads as a typo. `__` reads as a different kind of boundary, and it is what **OTP itself uses** for
exactly this purpose: `escript` names the module it generates from a script with `__` separators
([E20](./atom-evidence.md#e20--otps-own-escript-uses-__-the-same-way)):

```
$ escript whoami.escript      # main(_) -> io:format("~p~n",[?MODULE]).
whoami_escript__escript__1789__696388__940472__2306
```

## 5. It decodes back

The atom is not just distinct, it is **reversible** — an operator, a log parser or a future
`botopink explain <atom>` recovers the origin with a `string:split/3`
([E19b](./atom-evidence.md#e19b--the-atom-decodes-back-with-no-ambiguity)):

```erlang
decode(A) ->
  P = fun(X) -> lists:flatten(string:replace(X,"@","/",all)) end,
  case string:split(atom_to_list(A), "__", all) of
    [Path]             -> {module, P(Path)};
    [Path,Kind,Decl]   -> {decl,   P(Path), Kind, Decl};
    [Path,Kind,Decl,H] -> {gen,    P(Path), Kind, Decl, H}
  end.
```

```
models@user                                  {module,"models/user"}
models@user__t__pessoa                       {decl,"models/user","t","pessoa"}
std@math__b__signed                          {decl,"std/math","b","signed"}
jhonstart@html__tpl__html__3f1a9c02b7e4d5f8  {gen,"jhonstart/html","tpl","html","3f1a9c02b7e4d5f8"}
web@api@http                                 {module,"web/api/http"}
```

This is what the maintainer's `#Pessoa` was aiming at, and it is strictly more than `#` could have
delivered: `#` produced text the BEAM never reads
([E8](./atom-evidence.md#e8---cannot-address-anything-inside-a-module)), while `__` produces a **real
module** that can be loaded, called and hot-swapped on its own.

## 6. Length

The worst case is a comptime module: `erlAtom(path)` + `__tpl__` + decl + `__` + 16 hex. The longest
real example is 43 characters
([E18](./atom-evidence.md#e18--the-in-file-separator-candidates)) against the 250-byte filename cap
([E7](./atom-evidence.md#e7--the-real-length-cap-is-the-filename-not-the-atom)). The budget is comfortable,
and § 4's collision check is the natural place to also reject an atom over 250 bytes with a located
diagnostic instead of an `erlc: file name too long` from a build step.

## 7. What it adds to the front

| Step | Addition |
|---|---|
| 1 | `erlAtom` gains clause 3b; a new `erlDeclAtom(alloc, id, kind, decl, ?hash)`; a `Kind` enum so `kind` can never be a free string |
| 1 | **New:** a collision check over the rendered atoms in `crossModule.build` (`crossModule.zig:86`) — duplicate atom, reserved name, or over 250 bytes, each a located diagnostic |
| 5 | the comptime rename becomes `erlDeclAtom(file_id, .tpl, template_name, hash)` instead of a flat prefix — the evaluators must therefore pass the **owning module's path and the declaration's name**, which they do not carry today (`template_eval.zig:329-343`, `decorator_eval.zig:227-243` see only the generated code). This is the one piece of real plumbing A2 adds: ~30 LOC threading two strings through `buildModule` |
| — | Acceptance: `erlDeclAtom` unit tests for each `kind`; a fixture where one file's template and its own module are both called; the decoder in § 5 as a test, so the reversibility is pinned |

Cost over plain option A: **+0.5 day**, almost all of it the plumbing in step 5. No extra snapshot
churn — no snapshot records a comptime atom (`grep -rl 'template_[0-9a-f]\{16\}' snapshots` → 0).

---

## 8. Worked example, end to end

A project that is impossible to build correctly on erlang today: two `user.bp` in different
directories, a `http.bp` that collides with `libs/std`'s, and a `math.bp` name that shadows OTP.

### The source tree

```
myapp/
├── botopink.json            { "dependencies": ["std", "jhonstart"] }
└── src/
    ├── main.bp
    ├── math.bp                        fn variance(xs) -> f64
    ├── models/
    │   └── user.bp                    type Pessoa(nome: string, idade: i32)
    │                                  behavior Greeter { fn greet(self) -> string; }
    └── services/
        └── user.bp                    fn load(id: i32) -> Pessoa
```

plus the dependencies the resolver pulls in: `libs/std/src/{math,http,root}.bp`,
`jhonstart/src/{html,hooks,root}.bp`.

### The atoms

| Module path | Kind | Atom | Why |
|---|---|---|---|
| `main` | file | `main` | single segment, not reserved — **unchanged from today** |
| `math` | file | `bp@math` | single segment **and** an OTP module name → `bp@` prefix (rule 5) |
| `models/user` | file | `models@user` | |
| `models/user` | `type Pessoa` | `models@user__t__pessoa` | A2 |
| `models/user` | `behavior Greeter` | `models@user__b__greeter` | A2 |
| `services/user` | file | `services@user` | **no longer collides with `models/user`** |
| `std/math` | file | `std@math` | has a segment → no OTP collision, no prefix |
| `std/http` | file | `std@http` | |
| `std/root` | file | `std@root` | **no longer collides with `jhonstart/root`** |
| `jhonstart/html` | file | `jhonstart@html` | |
| `jhonstart/html` | `html` template, eval #1 | `jhonstart@html__tpl__html__3f1a9c02b7e4d5f8` | A2 + content hash |
| `jhonstart/html` | `html` template, eval #2 | `jhonstart@html__tpl__html__b7e4d5f83f1a9c02` | different body → different hash |
| `jhonstart/root` | file | `jhonstart@root` | |

Today the same project produces `main`, `math` (shadowing OTP), `user` **twice**, `math` again,
`http`, `root` **twice**, `html`, `root` again, and two `template_<hash>` with no traceable origin.

### What lands on disk

```
out/
├── erl/                                     ← flat, because erlc demands atom == basename (E1)
│   ├── main.erl
│   ├── bp@math.erl
│   ├── models@user.erl
│   ├── models@user__t__pessoa.erl
│   ├── models@user__b__greeter.erl
│   ├── services@user.erl
│   ├── std@math.erl   std@http.erl   std@root.erl
│   └── jhonstart@html.erl   jhonstart@hooks.erl   jhonstart@root.erl
├── main.js                                  ← commonJS keeps the mirrored tree, unchanged
├── math.js
├── models/user.js
├── services/user.js
├── std/{math,http,root}.js
└── jhonstart/{html,hooks,root}.js
```

`erlc -o ebin out/erl/*.erl` compiles all eleven with no overwrite; `erl -pa ebin` loads all
eleven with no shadowing. The comptime modules never reach `out/` — they stay in
`.botopinkbuild/tmp/template/jhonstart@html__tpl__html__3f1a9c02b7e4d5f8.erl`.

### What the emitted erlang reads like

`out/erl/services@user.erl`, calling into the sibling `user.bp` and into `libs/std`:

```erlang
-module(services@user).
-export([load/1]).

load(Id) ->
    Row  = std@http:get(<<"/users/">>, Id),
    Name = std@math:clamp(maps:get(nome, Row), 1, 64),
    models@user:pessoa(Name, maps:get(idade, Row)).
```

Every module name is a **bare word**: no quotes, greppable, and the directory it came from is
legible in the name. Compare the same three call sites under the original proposal:

```erlang
-module('user@services#Pessoa').
load(Id) ->
    Row  = 'http@std#Row':get(<<"/users/">>, Id),
    Name = 'math@std#Clamp':clamp(maps:get(nome, Row), 1, 64),
    'user@models#Pessoa':pessoa(Name, maps:get(idade, Row)).
```

### What a failure looks like

A crash inside the template, today and after:

```
today:  {template_3f1a9c02b7e4d5f8, render, 2, []}       ← which file? which template?
after:  {jhonstart@html__tpl__html__3f1a9c02b7e4d5f8, render, 2, []}
```

and the operator recovers the origin with the decoder of § 5:

```
{gen, "jhonstart/html", "tpl", "html", "3f1a9c02b7e4d5f8"}
```

### What the compiler now refuses

The check added in § 4 and step 1 turns three silent failures into located diagnostics:

```
error: two modules render to the same erlang atom 'my_mod@user'
  src/my__mod/user.bp
  src/my_mod/user.bp
  note: '__' is reserved as the in-file qualifier separator

error: module 'math' would shadow the OTP module 'math'
  src/math.bp
  note: emitted as 'bp@math'                      ← rule 5, applied automatically

error: module atom exceeds 250 bytes (filename limit)
  src/a/very/deeply/nested/…/module.bp
```

The first and third are new; the second is the eleven-module `libs/std` problem
([E14](./atom-evidence.md#e14--eleven-libsstd-module-names-are-already-otp-module-names)) closed by
construction.
