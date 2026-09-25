# Decisions the maintainer owes — 1.0.10-beta

**One open** (below, front 24's open point 8). Every other question this milestone raised is answered in
[`decisions-taken.md`](./decisions-taken.md) — 91, 92, 93 and 97 by decisions 103 and 104, 99 by 108,
94, 100 and 101 by 113; every number up to 117 is answered — 114 answers the eight seams decision 113 left open, 115 the five points 114 left open, 116 nine more pieces two libraries both run, 117 the nine points 113–116 left, and 118–127 register the maintainer's effect revision (the return type is the annotation, `@Task<T>`, only `@Result` fails, `@Iterator<T>` / `@Stream<T>`, `async { }`, `iter` / `stream` loops, no compatibility mode — front `00 · 24-effects-by-return`), and 128 merges `@Use<C, T>` and `@Component<T>` into `@Component<C, T>`. The next free number is **129**.

This file stays because the fronts will fill it again. A front that meets a question it cannot answer
from the code writes it here rather than guessing, in the shape the others used:

> **Raised by:** `<NN>-<front>` step <k>, <date>
> **Measured.** What was observed, with the command or program that produced it and the file or commit
> that can be re-read.
> **Options.** Each one stated so that choosing between them is possible without reading the code.
> **Recommendation.** One, argued — the default is the most restrictive behaviour, and no configuration
> that bypasses it (decision 67).
> **Blocks.** The step, front or landed work that waits on the answer.

---

## Front 24 open point 8 — the error a failing render carries, and whether the writers stay infallible

> **Raised by:** `00-compiler-carry-over/24-effects-by-return` step E7 (rakun's half), 2026-09-25
>
> **Measured.** Decision 117 item 1 says `renderStream` "resolves when the response is closed, and a
> failed render (rule 1's target check, a plugin's `close`) is the future's error". Under decision
> 120 a `@Task` has no error, and decision 121's note leaves the `E` and the writers' shape to this
> step. Decision 120 already respells the pieces around it: `RenderPlugin.close` →
> `@Task<@Result<void, string>>`, `ChunkWriter.write` / `close` and `PageRenderer` → `@Task<void>`,
> jhonstart's `Response.write` / `close` → `@Task<void>`. In `repository/rakun` at `feat` `f67c1e8`
> none of `ChunkWriter`, `PageRenderer`, `page(pattern, render)` or `servePage` exists yet (they are
> rakun front 23 step 1's, specified in `03-rakun/23-rakun-ssr-pipeline/README.md:78-86`); the
> render code that does exist — `ssr.bp`'s `render`, `document`, `renderAll`, `missingPage` and the
> host `rkSsrAll` — neither throws nor tries (`grep -nE 'throw|try ' modules/rakun/src/ssr.bp`
> over their bodies finds nothing; a miss is the status 404, not an error), so the E7 sweep moved
> each `@Future<T>` to `@Task<T>` with no `@Result`.
>
> **Options.**
> - **(a)** `E = string`, the writers infallible. `renderStream(…) -> @Task<@Result<void, string>>`;
>   `PageRenderer = fn(req: Request, out: ChunkWriter) -> @Task<@Result<void, string>>`, so onze's
>   boot closure stays `return ui.renderStream(…)`; `ChunkWriter.write` / `close` and
>   `Response.write` / `close` stay `@Task<void>` as decision 120 spells them. rakun's dispatch
>   answers an `Error(msg)` like an untagged raise of the renderer: 500 when nothing was written,
>   otherwise the response is closed; the message goes to the log under a correlation digest and
>   never on the wire (rakun-web's rule). A write after `close` and `setStatus` / `setHeader`
>   after the first `write` keep failing the request (a raise, decision 67) — they are misuse, not
>   an outcome. `servePage` stays `@Task<i32>` (the status written).
> - **(b)** A typed error, `RenderError { TargetRefused(target: string), PluginClose(plugin: string,
>   detail: string), … }`, instead of `string`. Stricter to match on, but `RenderPlugin.close` is
>   already `@Result<void, string>` by decision 120, so (b) re-opens that too, and jhonstart would
>   own a type rakun has to name in `PageRenderer` — the dependency decision 114 item 5 forbids.
> - **(c)** `renderStream` stays `@Task<void>` and a failed render raises (the request answers 500).
>   Keeps every signature as decision 120 wrote it, but drops the value decision 117 promised and
>   makes the failure uncatchable from `.bp` code (a raise is not catchable, `rakun-web/src/error.bp`).
> - **(d)** The writers become fallible too, `write: fn(string) -> @Task<@Result<void, string>>`,
>   so a peer that went away is a value. Every chunk then needs a `try await`, and a vanished peer
>   is not something the renderer can act on — rakun already owns the socket and closes it.
>
> **Recommendation.** (a). It is what decision 120's respelling implies (the one fallible piece of
> the pipeline, a plugin's `close`, is already `@Result<void, string>`, so the render that forwards
> it carries the same `E`), it keeps rakun ignorant of jhonstart's types (decision 114 item 5), and
> it is the strict reading of "a failed render is the future's error": the failure is a value the
> dispatch must handle, and its handling is fixed (500 / close, digest in the log) with no switch
> to put the message on the wire (decision 67). The writers stay infallible because their failures
> are misuse (a raise) or the transport's (rakun's), never the renderer's to handle.
>
> **Blocks.** rakun front 23 step 1 (`ChunkWriter`, `PageRenderer`, `servePage`); jhonstart front 30
> (`renderStream`'s signature); onze front 49 (the boot closure); the E8 respelling of
> `03-rakun/23-rakun-ssr-pipeline/README.md:78-99`. Nothing in `repository/rakun` at `f67c1e8`
> waits on it — no code there spells these types yet.
