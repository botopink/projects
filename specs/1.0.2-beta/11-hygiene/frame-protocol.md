# Group E — the comptime frame protocol (5.10)

`comptime/runtime/persistent_erl.zig`. Three gaps that compound into one failure mode: anything that
writes to stdout inside the comptime server desynchronises the length-prefixed frame protocol, and
the reader then trusts the corrupted prefix.

This is the one item in the hygiene front that is a correctness bug. It runs first.

| # | Deciding site | What a reader sees | Smallest fix |
|---|---|---|---|
| E1 | `:71-89` `safe_call/1` — `spawn_monitor(fun() -> … Mod:main() … end)` at `:72-73` | No `group_leader/2` call anywhere in the file (`grep logger\|group_leader\|error_logger` → 0 matches) | Spawn `Mod:main()` with its own group leader that captures or discards its output. Today it inherits the server's, which **is** `standard_io` — the frame channel — so one `io:format/1` in a comptime body desynchronises the protocol |
| E2 | `:224-225` `const len = std.mem.readInt(u32, &len_buf, .big); const payload = try allocator.alloc(u8, len);` | A `u32` read straight into an `alloc` with no bound | Cap the length (compare `libs.zig:289`, which uses `.limited(64 * 1024)`) and treat an oversize value as a transport failure, not an allocation |
| E3 | `:185-193` — erl's stderr goes to `erl.stderr.log` | Nothing in the tree ever reads that path (one grep hit: the site that writes it) | Either surface the tail of the log on a comptime failure, or say in `comptime/runtime/AGENTS.md` that it is write-only debris. The rationale for not inheriting stderr (`:182-184`, the orphan-holds-stdio deadlock) is sound and must be kept |

## The logger is a fourth mouth on the same channel

The server sets `latin1` correctly at `:46` but never moves the default handler off `standard_io`.
Reproduced on OTP 29:

```
erl -noshell -eval 'os:cmd("kill -TERM "++os:getpid()), timer:sleep(2000), halt().'
```

prints `=INFO REPORT==== … SIGTERM received` on **stdout**, stderr empty. The four bytes `=INF` are
`0x3D494E46` ≈ 1.02 GiB at `:224`.

`AGENTS.md:223-224` recommends `pkill -f botopink_comptime_server` (a SIGTERM) as the routine
cleanup — i.e. the docs recommend the trigger. `meta:erl_crash.dump` (2 MB, untracked, already
git-ignored via `meta:.gitignore:24`) is the artefact of exactly this.

## Steps

1. At server start, move the default logger handler to `standard_error` or remove it.
2. Run `Mod:main()` under its own group leader (E1).
3. Cap the frame length (E2).
4. Decide E3 and write the answer down.
5. Delete `meta:erl_crash.dump`.
6. Restore the `AGENTS.md:223-224` hint once a SIGTERM no longer corrupts anything.

## Acceptance

- [ ] A comptime body that calls `io:format/1` compiles; its output does not reach the frame stream
- [ ] A frame length above the cap fails as a transport error with a message, not an OOM
- [ ] A test covers both — `persistent_erl.zig` has **0** tests today. The `persistent_erl`
      regression set is a codegen-hardening row that [`../fronts.md`](../fronts.md) assigns to no
      front; this front writes the two tests its own fix needs and says so, rather than leaving the
      acceptance unowned
- [ ] `meta:erl_crash.dump` is gone
