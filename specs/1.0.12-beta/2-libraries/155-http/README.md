# Front 155 — http: the cookie typed, the consumer sweep

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Owns:** `repository/http/**`; the consumer lines step 2 names (decision 188)
**Depends on:** 144 B-12 (`Bytes`) · s2: rakun 150 s1, s16, s6, s12, s21, s13, s22 and onze 162 s1, s3 landed; pending ctr-p
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `104-http` s6 | 155 s1 |
| `104-http` s5 | 155 s2 |

## Steps

### 155 s1 — a cookie declared once, typed (104 s6)

#### Step 6 — a cookie is declared once, typed (decision 294) (was `104-http` s6)

- [ ] `pub type Cookie<T>(name: string, httpOnly: bool = true, secure: bool = true, sameSite:
      SameSite = .Lax, maxAge: ?Duration = null, path: string = "/")` in `repository/http` (the package both
      jhonstart and rakun reach, 113); `T` one `http` can encode — `string`, numbers, `bool`, an enum,
      a one-field record — a value that does not decode reads as absent
- [ ] `cookie.read(decl, header) -> ?T` (first-wins, 181) and `cookie.write(decl, value) -> string`
      (a `Set-Cookie` line carrying the declaration's attributes), `cookie.clear(decl)`; tests per `T` kind

**Gate:** standard (fronts.md § Gate), for the sweep

### 155 s2 — the consumer sweep (104 s5)

#### Step 5 — the consumer sweep (was `104-http` s5)

One commit per member, after the member's owning front has landed.

- [ ] rakun-session's `cookieFromHeader` deleted; store tests green with first-wins asserted
- [ ] `negotiation.rangeQ`, `compression.qMillis`, `i18n.qPerMille` deleted; the three members'
      tests green (negotiation tests relying on leniency rewritten to refuse, decision 182)
- [ ] one MIME table: `image_handler.bp` and `static.bp` import it; `static.bp` drops
      `etagMatches` for std `hash.matches`
- [ ] `error.bp`'s `statusReason` table deleted; sidecars receive the phrase from the `.bp` side
- [ ] every consumer file above imports `http`; `grep -rn
      "cookieFromHeader\|rangeQ\|qMillis\|qPerMille" repository/{rakun,onze}/modules` is empty
- [ ] each touched member's `AGENTS.md` updated in its commit
