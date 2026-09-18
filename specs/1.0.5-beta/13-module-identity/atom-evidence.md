# Evidence — what the BEAM actually does with these names

Every mechanical claim in this front was produced by running `erlc` / `erl` on hand-written files,
not read from documentation. Reproduce by re-running the command shown; nothing depends on the
botopink toolchain.

**Environment** (`erl -noshell -eval 'io:format("~p ~p~n",[erlang:system_info(otp_release), erlang:system_info(version)])'`):

```
otp_release = "29"
version     = "17.0.6"
```

`erlc`, `erl` and `escript` are on `PATH` (`/usr/bin/erlc`, `/usr/bin/erl`, `/usr/bin/escript`).
`rebar3` and `elixir` are **not installed** — every claim about them below is marked unverified.

Scratch directory used: a session scratchpad outside every repository. Files: `mismatch.erl`,
`user@app.models#Pessoa.erl`, `caller.erl`, `std@web@http.erl`, `coll/`, `shadow/`, `asm/`.

---

## E1 — the `-module` atom must equal the source file's basename

```erlang
%% mismatch.erl
-module(other_name).
-export([f/0]).
f() -> ok.
```

```
$ erlc mismatch.erl
…/mismatch.beam: Module name 'other_name' does not match file name 'mismatch'
exit=1
```

`+no_error_module_mismatch` downgrades the check and **does** produce `mismatch.beam`, but the
result is unloadable — the code server looks a module up by `<atom>.beam` and then rejects the
object code:

```
$ erlc +no_error_module_mismatch mismatch.erl   # exit=0
$ erl -pa . -eval 'io:format("~p~n",[code:ensure_loaded(mismatch)]), io:format("~p~n",[code:ensure_loaded(other_name)])'
ensure_loaded(mismatch)   -> {error,badfile}
=ERROR REPORT====
beam/beam_load.c(186): Error loading module mismatch:
  module name in object code is other_name
ensure_loaded(other_name) -> {error,nofile}
```

**Consequence:** the module atom is not a free-standing label. Whatever atom the erlang backend
writes, the CLI must name the file `<that exact atom>.erl` and the `.beam` next to it
`<that exact atom>.beam`. A scheme that encodes the source path in the atom therefore also decides
the on-disk layout — it cannot coexist with the mirrored `out/<path>.erl` tree the CLI writes today.

The same rule holds for the BEAM backend's `.S` files — see [E17](#e17).

---

## E2 — a bare dot ends the attribute; dotted module names are not a thing

```erlang
-module(user@app.models).
```

```
user@app.models.erl:1:17: syntax error before: '.'
%    1| -module(user@app.models).
%     |                 ^
user@app.models.erl:2:2: no module definition
exit=1
```

`@` is fine unquoted; `.` is not. (Erlang had dotted "packages" before R16; the grammar no longer
accepts them. E2 is the evidence, not the history.)

---

## E3 / E4 — the maintainer's atom, fully quoted, works end to end

```erlang
%% user@app.models#Pessoa.erl
-module('user@app.models#Pessoa').
-export([f/0, who/0]).
f() -> io:format("called f/0~n"), ok.
who() -> ?MODULE.
```

```
$ erlc 'user@app.models#Pessoa.erl'     # exit=0
$ ls
user@app.models#Pessoa.beam
user@app.models#Pessoa.erl
```

```
$ erl -pa . -eval "M = 'user@app.models#Pessoa', …"
ensure_loaded          -> {module,'user@app.models#Pessoa'}
M:f()                  -> ok
M:who()                -> 'user@app.models#Pessoa'
function_exported      -> true
module_info(module)    -> 'user@app.models#Pessoa'
code:which(M)          -> ".../user@app.models#Pessoa.beam"
```

`erl -s` takes it as a command-line atom without special handling:

```
$ erl -pa . -noshell -s 'user@app.models#Pessoa' f -s init stop
called f/0
```

`escript` reaches it the same way (`%%! -pa .` header, `'user@app.models#Pessoa':f()` in `main/1`)
and prints `ok`.

**Verdict:** mechanically the proposal is legal. `?MODULE`, `module_info/1`,
`erlang:function_exported/3`, `code:which/1`, `code:ensure_loaded/1`, `erl -s` and `escript` all
accept it. The objections are not "the BEAM refuses it".

---

## E5 — the caller's side, and the stack trace

```erlang
%% caller.erl
-module(caller).
-export([go/0, boom/0]).
-record(pessoa, {nome, idade}).

go() ->
    R = #pessoa{nome = "Ana", idade = 30},
    X = 'user@app.models#Pessoa':f(),
    {R#pessoa.nome, X}.

boom() -> 'user@app.models#Pessoa':missing().
```

```
$ erlc caller.erl        # exit=0
go -> {"Ana",ok}
class=error err=undef
stack=[{'user@app.models#Pessoa',missing,[],[]},
       {erl_eval,do_apply,7,[{file,"erl_eval.erl"},{line,1044}]},
       …]
```

Note what `caller.erl` shows side by side: `#pessoa{…}` and `R#pessoa.nome` are erlang's **record**
syntax, and `'…#Pessoa':f()` is a module call. Both use `#`, and they mean unrelated things. The
record is a tuple shape declared with `-record`; the `#Pessoa` inside the atom is eight characters
of text.

---

## E6 — the atom table: size and per-atom length

```
atom_limit  = 1048576
atom_count  = 10865        (a bare node, at boot)
```

```erlang
list_to_atom(lists:duplicate(255,$a))   %% ok
list_to_atom(lists:duplicate(256,$a))   %% {'EXIT',{system_limit,[{erlang,list_to_atom,…}]}}
```

Atoms are never garbage collected; the default table holds 1 048 576 of them and an atom is at most
255 characters.

---

## E7 — the real length cap is the filename, not the atom

`NAME_MAX` on the filesystem here is 255 **bytes**, and E1 forces `<atom>.erl` and `<atom>.beam` to
exist as files:

```
$ python3 -c "open('m'*255 + '.erl','w')"
OSError: [Errno 36] File name too long

$ erlc mmm…(251 m's).erl
…mmm….bea#: error writing file: file name too long
exit=1

$ erlc mmm…(250 m's).erl     # exit=0, produces the .beam
```

**A module atom on this platform is capped at 250 bytes**, not 255 — `.beam` is five bytes and
`erlc` additionally stages through `<name>.bea#` (visible in the 251 error above, and itself a
reminder that `#` is already in use in the toolchain's own filenames).

Measured against the codebase this is not a live risk: module paths are project-relative
(`std/math`, `rakun/http`, `jhonstart/hooks`), the longest today is under 20 characters. It becomes
a risk only if a scheme concatenates a deep `mod` tree, a `@comp__` prefix and a 16-hex hash.

---

## E8 — `#` cannot address anything inside a module

```erlang
f() -> mod#Pessoa:g().
```

```
hashbare.erl:3:18: syntax error before: ':'
exit=1
```

And inside the quoted form the text has no structure at all:

```
'user@app.models#Pessoa' -> is_atom=true len=22 text=user@app.models#Pessoa
```

One atom, 22 characters. Nothing in the BEAM splits it, indexes it, or resolves `#Pessoa` against
the module's contents. Erlang has no sub-module namespace; what it offers instead is listed in
[`erlang-atoms.md` § What `#` was reaching for](./erlang-atoms.md#23-what--was-reaching-for).

---

## E9 — a leading `@` forces quoting

```erlang
f() -> @comp__foo:g().
```

```
atsign.erl:3:8: syntax error before: '@'
```

Quoted, the comptime form compiles and calls fine:

```
$ erlc '@comp__user@app.models#Pessoa.erl'   # exit=0
$ erl -pa . -eval "io:format(\"~p~n\",['@comp__user@app.models#Pessoa':f()])"
comptime_ok
```

So the prefix works, but it removes the last case where the atom could have been written bare.

---

## E10 — what is and is not a legal *unquoted* atom

`erl_scan:string(S ++ " .")`, asking whether the whole text scans as a single atom token:

| Text | Scans as |
|---|---|
| `http` | `{unquoted_atom_ok,http}` |
| `std@web@http` | `{unquoted_atom_ok,std@web@http}` |
| `bp@std@web@http` | `{unquoted_atom_ok,bp@std@web@http}` |
| `web_http` | `{unquoted_atom_ok,web_http}` |
| `x__y` | `{unquoted_atom_ok,x__y}` |
| `user@app.models#Pessoa` | `{not_a_single_atom,[atom,'.',atom,'#',var,dot]}` |
| `@comp__x` | `{not_a_single_atom,['@',atom,dot]}` |
| `Web` | `{not_a_single_atom,[var,dot]}` |
| `1x` | scanner error `{illegal,integer}` |

**`@` and `_` are legal in an unquoted atom after a lowercase first character.** This is the whole
basis of [option A](./atom-options.md#option-a--the-path-joined-with-) — a path-encoding scheme that
needs no quotes at all.

---

## E11 — `make` truncates a name at `#`

`bash` is safe (`#` only starts a comment at the start of a word), but `make` is not:

```make
SRC := user@app.models#Pessoa.erl
all:
	@echo "[$(SRC)]"
```

```
[user@app.models]
```

A rule whose target carries the `#` fails outright:

```
Makefile:4: *** missing separator.  Stop.
```

`rebar3` was not installed here, so its `src/*.erl` handling is **unverified**; E1 already implies
its constraint (module = filename, flat `src/`).

---

## E12 — `@`-joined atoms need no quoting anywhere

```erlang
%% std@web@http.erl
-module(std@web@http).
-export([get/0]).
get() -> ok.

%% caller2.erl
go() -> std@web@http:get().
```

```
$ erlc 'std@web@http.erl'   # exit=0
$ erlc caller2.erl          # exit=0
$ erl -pa . -eval 'io:format("~p ~p~n",[caller2:go(), code:which(std@web@http)])'
ok ".../std@web@http.beam"
```

An uppercase or digit first character still needs quotes:

```
-module(Web@http).
Web@http.erl:1:9: bad module declaration
```

---

## E13 — what collides today: two modules, one atom

```erlang
%% coll/models/user.erl          %% coll/services/user.erl
-module(user).                   -module(user).
who() -> "models/user".          who() -> "services/user".
```

Same output directory — silent overwrite, no warning from `erlc`:

```
$ erlc -o coll/ebin coll/models/user.erl     # ok
$ erlc -o coll/ebin coll/services/user.erl   # ok, coll/ebin/user.beam replaced
$ erl -pa coll/ebin -eval 'io:format("~s~n",[user:who()])'
services/user
```

Separate `ebin` directories, both on the code path — silent shadowing, the winner decided by `-pa`
order, not by the program:

```
$ erl -pa coll/ebin1 -pa coll/ebin2 -eval 'io:format("~s from ~s~n",[user:who(), code:which(user)])'
services/user from .../coll/ebin2/user.beam
```

---

## E14 — eleven `libs/std` module names are already OTP module names

For each `libs/std/src/<n>.bp`, `code:which(list_to_atom("<n>"))` on a bare OTP 29 node:

```
SHADOWS OTP: math       -> /usr/lib/erlang/lib/stdlib-8.0.4/ebin/math.beam
SHADOWS OTP: os         -> /usr/lib/erlang/lib/kernel-11.0.3/ebin/os.beam
SHADOWS OTP: crypto     -> /usr/lib/erlang/lib/crypto-5.9.3/ebin/crypto.beam
SHADOWS OTP: base64     -> /usr/lib/erlang/lib/stdlib-8.0.4/ebin/base64.beam
SHADOWS OTP: queue      -> /usr/lib/erlang/lib/stdlib-8.0.4/ebin/queue.beam
SHADOWS OTP: sets       -> /usr/lib/erlang/lib/stdlib-8.0.4/ebin/sets.beam
SHADOWS OTP: dict       -> /usr/lib/erlang/lib/stdlib-8.0.4/ebin/dict.beam
SHADOWS OTP: json       -> /usr/lib/erlang/lib/stdlib-8.0.4/ebin/json.beam
SHADOWS OTP: unicode    -> /usr/lib/erlang/lib/stdlib-8.0.4/ebin/unicode.beam
SHADOWS OTP: random     -> /usr/lib/erlang/lib/stdlib-8.0.4/ebin/random.beam
SHADOWS OTP: erlang     -> preloaded
```

(`string` is in the list too, as an OTP module — botopink has no `string.bp`, but any user module
named `string.bp` would hit it.)

---

## E15 — what shadowing an OTP module actually does

```erlang
%% shadow/math.erl
-module(math).
-export([floor/1]).
floor(X) -> {botopink_math, X}.
```

```
$ erl -pa shadow -eval 'io:format("~s~n",[code:which(math)]), io:format("~p~n",[math:pi()])'
which(math) = .../shadow/math.beam
math:pi()   = {'EXIT',{undef,[{math,pi,[],[]},…]}}
```

The user directory wins over `stdlib`, and **every OTP function of that module disappears**.
`math:floor/1` still answered `1.0` because it is dispatched as a BIF, which makes the failure mode
worse, not better: part of the module keeps working and part vanishes.

`erlang` is preloaded and cannot be replaced at all — `erlc erlang.erl` succeeds, the module never
takes effect, and `erlang:hello()` is `undef`. `libs/std/src/erlang.bp` is declaration-only
(`@External.Erlang` catalogue), so nothing breaks today; a `pub fn` added to it would be silently
unreachable on erlang.

---

<a id="e17"></a>

## E17 — the BEAM `.S` path behaves identically

A hand-written `.S` whose `{module, …}` form carries the quoted atom assembles and runs:

```
$ erlc +from_asm 'mod@a.b#C.S'    # exit=0 → mod@a.b#C.beam
$ erl -pa . -eval "io:format(\"~p~n\",['mod@a.b#C':f()])"
ok
```

Renaming the file breaks it the same way E1 does:

```
$ cp 'mod@a.b#C.S' renamed.S && erlc +from_asm renamed.S
…/renamed.beam: Module name 'mod@a.b#C' does not match file name 'renamed'
```

Quirk worth knowing for the gate: `erlc +from_asm` printed that error but **exited 0**, where the
`.erl` path (E1) exits 1. A check that only reads the exit code would miss a `.S` name mismatch.

---

The four experiments below were added when the maintainer accepted option A and asked for a way to
tell apart several modules born of the same source file — see
[`declaration-qualifier.md`](./declaration-qualifier.md).

<a id="e18--the-in-file-separator-candidates"></a>

## E18 — the in-file separator candidates

`erl_scan:string(S ++ " .")`, asking whether each spelling is a single unquoted atom:

| Text | Result |
|---|---|
| `models@user__t__pessoa` | OK (22 chars) |
| `models@user@@pessoa` | OK (19 chars) |
| `jhonstart@html__tpl__html__3f1a9c02b7e4d5f8` | OK (43 chars) |
| `std@math__b__signed` | OK (19 chars) |
| `onze@mock__dec__mock__9c02b7e4` | OK (30 chars) |
| `a__b__c` | OK (7 chars) |
| `x@@y@@z` | OK (7 chars) |

Both `__` and `@@` are legal unquoted, so the choice between them is readability and prior art
([E20](#e20--otps-own-escript-uses-__-the-same-way)), not legality. The longest realistic comptime
form is 43 characters against the 250-byte cap of [E7](#e7--the-real-length-cap-is-the-filename-not-the-atom).

<a id="e19--four-sibling-modules-from-one-source-file"></a>

## E19 — four sibling modules from one source file

Four `.erl` files standing for one logical `src/models/user.bp` — the file's own module plus two
`type`s and a `behavior`:

```
$ erlc models@user.erl models@user__t__pessoa.erl models@user__t__empresa.erl models@user__b__greeter.erl
erlc exit=0 — all four assembled

$ erl -pa . -eval 'lists:foreach(fun(M) -> io:format("~p -> ~p~n",[M, M:who()]) end, […])'
models@user             -> models@user
models@user__t__pessoa  -> models@user__t__pessoa
models@user__t__empresa -> models@user__t__empresa
models@user__b__greeter -> models@user__b__greeter
```

Each is a real, separately loadable module — which is more than the proposal's `#Pessoa` could
be ([E8](#e8---cannot-address-anything-inside-a-module)): that suffix named nothing the BEAM reads.

<a id="e19b--the-atom-decodes-back-with-no-ambiguity"></a>

## E19b — the atom decodes back, with no ambiguity

An `escript` with the 8-line decoder of
[`declaration-qualifier.md` § 5](./declaration-qualifier.md#5-it-decodes-back):

```
models@user                                  {module,"models/user"}
models@user__t__pessoa                       {decl,"models/user","t","pessoa"}
std@math__b__signed                          {decl,"std/math","b","signed"}
jhonstart@html__tpl__html__3f1a9c02b7e4d5f8  {gen,"jhonstart/html","tpl","html","3f1a9c02b7e4d5f8"}
web@api@http                                 {module,"web/api/http"}
```

Path, kind, declaration and content hash all come back out. `web@api@http` correctly decodes as a
three-segment module path and not as a qualified declaration, because `@` and `__` are different
separators.

<a id="e20--otps-own-escript-uses-__-the-same-way"></a>

## E20 — OTP's own `escript` uses `__` the same way

```erlang
#!/usr/bin/env escript
main(_) -> io:format("~p~n", [?MODULE]).
```

```
$ escript whoami.escript
whoami_escript__escript__1789__696388__940472__2306
```

OTP names the module it synthesises from a script `<script>__escript__<numbers>` — `__` as the
boundary between a source-derived name and generator-supplied discriminators. That is exactly the
shape A2 proposes, from the toolchain itself.

<a id="e21--__-has-to-be-reserved"></a>

## E21 — `__` has to be reserved

```
my__mod@user   legal atom, but split on "__" gives ["my","mod@user"]
my_mod@user    legal atom, but split on "__" gives ["my_mod@user"]
```

A source segment containing `__` would be read back as a declaration qualifier. Hence clause 3b of
[`declaration-qualifier.md` § 4](./declaration-qualifier.md#4-__-is-reserved-and-what-that-costs):
collapse runs of `_`, and diagnose the resulting `my__mod` / `my_mod` collision instead of picking a
winner. No file or directory in the seven repositories uses `__` today.

---

The five experiments below were added for
[policy 3](./policy-3-module-per-type.md) — one BEAM module per `type` and per `behavior`, decided
by the maintainer on 2026-09-17.

<a id="e22--four-sibling-s-modules-from-one-source-file"></a>

## E22 — four sibling `.S` modules from one source file

Hand-written `.S` files standing for one `src/models/user.bp` (the file's own module, two `type`s
and a `behavior`), plus an `.erl` caller that `call_ext`s into three of them:

```
$ erlc +from_asm 'models@user.S' 'models@user__t__pessoa.S' \
                 'models@user__t__empresa.S' 'models@user__b__greeter.S'
erlc +from_asm exit=0

$ erl -pa . -eval 'io:format("cross-call -> ~p~n",[caller3:go()])'
cross-call -> {file_module,pessoa_v1,greeter_v1}
```

The BEAM backend carries policy 3 exactly as the erlang backend does.

<a id="e23--hot-swapping-one-type-module"></a>

## E23 — hot-swapping one type module, siblings untouched

Re-assembling only `models@user__t__pessoa.S` and reloading it:

```
before      -> {file_module,pessoa_v1,greeter_v1}
after  swap -> {file_module,pessoa_v2_HOTSWAPPED,greeter_v1}
reloaded    -> {module,models@user__t__pessoa}
```

`code:load_file/1` on one type swaps that type alone. Under today's flat layout the whole file's
module reloads, taking every type in it.

<a id="e24--a-stack-trace-names-the-owning-type"></a>

## E24 — a stack trace names the owning type

The same failure, emitted the two ways. Today's shape — the type name fused into the function name,
the module being the file:

```erlang
-module(main).
pessoa_greet(P) when is_map(P) -> maps:get(nome, P).
```

Policy 3's shape:

```erlang
-module('models@user__t__pessoa3').
greet(P) when is_map(P) -> maps:get(nome, P).
```

```
today:   error:function_clause  {main,pessoa_greet,[notamap],
                                      [{file,"today/main.erl"},{line,3}]}
after:   error:function_clause  {models@user__t__pessoa3,greet,[notamap],
                                      [{file,"models@user__t__pessoa3.erl"},{line,3}]}
```

The module names the owner and the function keeps the name the programmer wrote.

<a id="e25--botopink-run-breaks-under-policy-3"></a>

## E25 — `botopink run --target erlang` breaks under policy 3

`cli/run.zig:66-71` runs the erlang target as `escript out/<mod>.erl`, with no `-pa`. escript
compiles only the file it is handed:

```
$ escript main.erl          # main/1 calls 'models@user__t__pessoa':greet("ana")
escript: exception error: undefined function models@user__t__pessoa:greet/1
  in function  main_erl__escript__1789__697293__450783__2309:main/1 (main.erl:2)
```

Under policy 3 *every* program whose type has a method is a multi-module program, so this stops
being the residual recorded in [`README.md`](./README.md) step 6 and becomes a **blocker**. The fix
is the shape `runtime.zig:581` already uses: `erl -noinput -pa <dir> -s <entry> _botopink_main -s
init stop`.

(The escript trace also shows E20's convention once more: OTP named its own synthesised module
`main_erl__escript__1789__697293__450783__2309`.)

<a id="e26--local-call-vs-remote-call"></a>

## E26 — local call vs remote call

Identical one-line body, 10 000 000 calls, best of 5 `timer:tc` runs after a 100 000-call warm-up.
`local_call` calls a function in its own module; `remote_call` calls `callee:greet/1`.

```
N            = 10000000 calls
local  call  = 22234 us  (2.223 ns/call)
remote call  = 25953 us  (2.595 ns/call)
overhead     = 3719 us total, 0.372 ns/call, 16.7%
```

Linux 7.2.4-arch1-2, Erlang/OTP 29 (`erts-17.0.6`).

The 16.7% is the **upper bound** of the relative overhead — the body is a single `+`, so the call is
nearly the whole cost. In absolute terms it is **0.372 ns per call**: ten million method calls cost
3.7 ms more. The erlang fixtures make tens to hundreds of calls. The cost is irrelevant at the scale
of the programs this compiler generates.
