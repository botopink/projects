# Front 85 — rakun Mail

**Track:** B rakun
**Priority:** medium — password reset, address verification and notification are table stakes for the kind of application this milestone is aimed at, and nothing in it can send an e-mail
**Target:** erlang (server)
**Wave:** 6
**Depends on:** 01 (`net` for the SMTP socket, `escape.html` for templated bodies, `encoding` for base64 and quoted-printable, `clock` for the `Date` header), 05 (configuration), 74 (STARTTLS and implicit TLS through the bundle registry), 11 (registers the `mail` health indicator), 83 (a send that must be tied to a database write goes through the outbox, not through a second one here)
**Owns:** `modules/rakun-mail/botopink.json`, `modules/rakun-mail/src/**` · `modules/rakun-mail/test/**`
**Does not touch:** `modules/rakun-tx/**` (front 83's outbox — this front enqueues into it, it does not reimplement it), every jhonstart, emilia and onze file — an HTML body arrives as a string (decision 113), and the four frozen files in `repository/rakun/src/`
**Reference:** `07-io.md § Email`, `§ Configuracao`, `§ JNDI Session` · `09-actuator.md § HealthIndicators Auto-configurados (mail)` · <https://docs.spring.io/spring-boot/reference/io/email.html>

---

## Problem

There is no way to send an e-mail from a rakun application, and the applications this milestone is
aimed at cannot exist without one. A sign-up flow needs to verify an address. A login flow needs a
password reset. Any application with an account needs to tell somebody that something happened to it.
None of those is a feature anyone writes a spec about, and all of them block a release.

The absence is total. There is no SMTP client anywhere in the workspace — not in rakun, not in std,
not behind a host cell. `io.http` can fetch a URL (`libs/std/src/http.bp:55`) and that is the whole
of the outbound networking botopink has today. Front 01 adds `io.net`, which gives a socket; from a
socket to a delivered message is a protocol, a MIME encoder, a TLS negotiation and a retry policy.

There is a second problem behind the first, and it is the one that produces incidents. Sending mail
is slow, fails routinely, and is almost always triggered by something that also writes to a database.
A naive implementation sends inline: the request blocks on a remote SMTP server, and when the
transaction that triggered it rolls back, the mail has already gone. "Your password was reset" for a
reset that did not happen is worse than no mail at all.

## Current state

| Piece | Where it is today |
|---|---|
| `modules/rakun-mail/` | does not exist — this front creates it |
| An SMTP client | nothing, in rakun or in std |
| MIME encoding | nothing. `libs/std/src/base64.bp` has `encode`/`decode`; quoted-printable and RFC 2047 header encoding do not exist |
| A socket | front 01 delivers `io.net`; nothing today |
| HTML escaping | front 01 delivers `escape.html`; nothing today |
| TLS | front 74 delivers the bundle registry over OTP's `ssl` |
| An HTML body | a string the caller hands in; rakun builds no HTML (decision 113) — in an onze application it is jhonstart's render |
| A durable queue | front 83 delivers the outbox; this front does not grow a second one |
| `gen_smtp` | not present, and not installable by the path the test row loads code — see *Mechanism* |

## Mechanism

### The transport question, and the same answer front 04 gave

The audit names `gen_smtp` as the BEAM analogue, and it is the right one: it is the established SMTP
client and server library on this runtime and its protocol surface is what this front's API is shaped
after. There is one obstacle, and it is the obstacle front 04 already met with cowboy.

A sidecar `.erl` is compiled and loaded at run time by `__bp_load_siblings/0`
(`modules/compiler-core/src/codegen/erlang.zig:1655-1668`) with no rebar, no `.app` file and no code
path beyond the output directory. A sidecar that calls `gen_smtp_client:send/2` compiles and then
dies with `undefined function` on every machine that has not separately installed it — including the
gate. Front 04 resolved this by writing its transport over `gen_tcp`, which is in `kernel`, and
leaving cowboy as a configured adapter. This front does the same thing for the same reason:

- **Default transport:** an SMTP client written here over `io.net` and OTP's `ssl`. EHLO, AUTH
  (PLAIN and LOGIN), STARTTLS, MAIL FROM, RCPT TO, DATA, QUIT. It is perhaps 300 lines, it has no
  dependency, and it is what the test row exercises.
- **Configured transport:** `rakun.mail.transport=gen_smtp` delegates to a `rakun_mail_gen_smtp`
  adapter module when it is loadable, and **fails at startup naming the missing module** when it is
  not. It does not silently fall back, for the same reason front 04's cowboy seam does not.

The API is identical across both, which is what makes the choice an operator's rather than a
developer's.

### Never send inline

`send` enqueues; it does not open a socket. The queue is drained by a supervised sender process with
a bounded concurrency, so a slow or unreachable SMTP server slows mail delivery and nothing else. A
request handler that sends four notifications returns in the time it takes to write four rows.

Durability is a choice per message, and the choice is not this front's to invent:

| Need | Path |
|---|---|
| Fire and forget; losing it on a crash is acceptable | the in-VM queue (ETS), the default |
| The mail must not be sent unless the transaction commits | `publishAfterCommit` — front 83's outbox, with this front as the consumer |
| The mail must not be *lost* if the node dies | the same outbox |

That is deliberate. A second durable queue here would be a second outbox with its own relay, its own
dedupe rules and its own failure modes, and the two would disagree on the day it mattered. This front
is a consumer of front 83's, and the README says so rather than leaving a reader to discover two
queues.

### Composition

A message is a record, and the MIME structure is derived from what it carries rather than configured:

| Carries | Structure |
|---|---|
| text only | `text/plain` |
| text + html | `multipart/alternative` |
| text + html + inline images | `multipart/related` inside `multipart/alternative` |
| any of the above + attachments | `multipart/mixed` wrapping it |

The alternative order is plain first, HTML second, because that is the order RFC 2046 gives and
clients take the last part they understand.

Header encoding is RFC 2047 (`=?UTF-8?B?…?=`) for any header value with a non-ASCII byte or a line
longer than 78 characters, applied to display names and to the subject. Bodies are quoted-printable
for text and base64 for everything else. Every one of those is a place where a naive implementation
produces mail that renders as mojibake in one client and fine in another, which is why each has its
own acceptance line below.

### HTML bodies are strings the caller renders

rakun builds no HTML (decision 113), so `Mail.html` is a string the caller hands in. In an onze
application the caller renders it with jhonstart — the same escaping walker a page goes through — and
rakun never names jhonstart. What this front owns is everything after the string: the MIME part, its
transfer encoding, and the plain-text part generated from it when the caller gave none. A mail body
interpolating a user-supplied display name is the classic injection vector, so the caller escapes at
its seam (`escape.html` from front 01 in a rakun-only application, jhonstart's walker in an onze one);
this front never re-escapes or re-parses the markup it carries.

### The health indicator

`09 § HealthIndicators Auto-configurados` lists `mail`. This front ships it, registered with front 11,
as every resource-owning front does. It opens a connection, completes EHLO and STARTTLS, and quits
**without sending** — a health check that sends mail is a health check that fills somebody's inbox
every thirty seconds. Its detail carries the host, the port and whether TLS was negotiated, and never
the credentials.

## Steps

### Step 1 — The module, configuration and the SMTP client

```bp
pub type MailServer(
    host: string,
    port: i32,
    username: string,
    password: string,
    tlsMode: TlsMode,
    bundle: string,
    connectTimeoutMs: i32,
    readTimeoutMs: i32,
    writeTimeoutMs: i32,
)

pub type TlsMode {
    None,
    StartTls,
    Implicit,
}
```

The three timeouts are the three `07 § Configuracao` names
(`mail.smtp.connectiontimeout`, `mail.smtp.timeout`, `mail.smtp.writetimeout`).

**Acceptance:**
- [ ] EHLO, AUTH PLAIN, MAIL FROM, RCPT TO, DATA and QUIT complete against the fixture server
- [ ] AUTH LOGIN is used when the server advertises it and not PLAIN
- [ ] `StartTls` upgrades the connection and refuses to continue in the clear when the server does not advertise `STARTTLS` — there is no property that permits the downgrade
- [ ] `Implicit` connects over TLS from the first byte, on the configured bundle
- [ ] Each of the three timeouts fires independently and is reported as a distinct reason
- [ ] A server that answers 5xx at any stage fails the attempt permanently; a 4xx fails it retryably, and the two are not confused
- [ ] Credentials never appear in a log line, an error message or a health detail — asserted by a test that greps the captured output

### Step 2 — Composition and encoding

```bp
pub type Attachment(filename: string, contentType: string, path: string, inline: bool, cid: string)

pub type Mail(
    from: string,
    to: string[],
    cc: string[],
    bcc: string[],
    replyTo: string,
    subject: string,
    text: string,
    html: string,
    attachments: Attachment[],
    headers: Array<#(string, string)>,
)
```

An attachment is a **path**, not bytes: botopink has no byte type
([`../language-gaps.md`](../../language-gaps.md)), so the file is read and base64-encoded by a host cell
and never passes through a botopink value.

**Acceptance:**
- [ ] Text only produces a single-part `text/plain; charset=utf-8` message
- [ ] Text plus HTML produces `multipart/alternative` with plain first and HTML second
- [ ] An inline image produces `multipart/related` with a `Content-ID` matching the `cid` the HTML references
- [ ] An attachment wraps the whole thing in `multipart/mixed`
- [ ] A subject containing a non-ASCII character is RFC 2047 encoded; an ASCII one is not encoded at all
- [ ] A display name containing a comma or a quote is quoted correctly and does not split the header
- [ ] Every line of the emitted message is at most 998 bytes, including a quoted-printable body with a long unbroken word
- [ ] A body line beginning with `.` is dot-stuffed
- [ ] `bcc` recipients appear in `RCPT TO` and in **no** header
- [ ] The boundary string appears nowhere in any part's content — it is derived and checked, not assumed

### Step 3 — HTML bodies as strings

**Acceptance:**
- [ ] `Mail.html` is written to the HTML part byte for byte, in its transfer encoding; the part is
      never re-escaped or re-parsed
- [ ] A value the caller escaped with `escape.html` containing `<script>` arrives escaped in the HTML
      part and literal in the plain part the caller supplied
- [ ] A message with an HTML body and no text body has a plain part generated from it, rather than being sent HTML-only
- [ ] `grep -rn jhonstart modules/rakun-mail` is empty

### Step 4 — The queue, retries and the dead-letter path

**Acceptance:**
- [ ] `send` returns before any socket is opened
- [ ] An unreachable server does not slow a request handler — asserted by timing a handler that sends against a server that never answers
- [ ] A retryable failure is retried with the configured backoff to the configured ceiling
- [ ] Past the ceiling the message moves to the dead-letter store with its last error, and is readable there
- [ ] A permanent failure (5xx, bad recipient) goes straight to dead-letter without consuming retries
- [ ] Concurrency is bounded: N queued messages open at most the configured number of connections
- [ ] A message enqueued through front 83's outbox is sent once per relay pass and is not duplicated by this front's own queue

### Step 5 — The `mail` health indicator

**Acceptance:**
- [ ] `UP` when EHLO and, where configured, STARTTLS complete
- [ ] `DOWN` with a reason when the connection, the greeting or the TLS negotiation fails
- [ ] No message is ever sent by the check
- [ ] The detail map carries host, port and TLS mode, and carries no username and no password
- [ ] The check has its own timeout, shorter than the send timeouts, so a hanging SMTP server cannot hang `/actuator/health`
- [ ] It is registered with front 11 and absent when this module is not present

## Examples

- [`examples/transactional-mail-example.bp`](./examples/transactional-mail-example.bp) — a password-reset
  mail: the HTML body as a component, the plain-text alternative, the send tied to the transaction
  that created the token through front 83's outbox, and the health indicator.

## Language gaps

No new rows. This front meets three that [`../language-gaps.md`](../../language-gaps.md) already
records — **no byte or binary type** (an attachment is a path, and the file is encoded by a host cell),
and **declared parameter defaults are never applied** (`Mail` is a record with every field written, which
is why the example spells `cc`, `bcc` and `replyTo` even when they are empty).

## Test plan

`modules/rakun-mail/test/`, run with `botopink test --target erlang` from `modules/rakun-mail/`, and
in the gate as `zig build test-libs -- --target erlang --lib rakun`.

The suite runs against a **fixture SMTP server** this front ships in `test/fixture_smtp.bp`: a
listener on an ephemeral port that speaks enough of the protocol to accept a message, records the
exact bytes it received, and can be told to answer 4xx, 5xx, to omit `STARTTLS` from its EHLO
response, or to stop answering entirely. That is what makes step 1 and step 2 testable as byte
assertions — the encoding tests assert on the captured message, line by line, which is the only way
to catch a header that is one fold short of correct.

Two acceptance lines deserve their test design named. "Credentials never appear in output" is tested
by capturing the sender's log output across a failing authentication and asserting the password
string is absent from it — a test that fails the day somebody adds a helpful debug line. "An
unreachable server does not slow a handler" is tested against a fixture that accepts the connection
and never answers, with the handler's elapsed time asserted against a ceiling far below the connect
timeout; the question is "did it block at all", and a generous ceiling answers it without flaking.

The `gen_smtp` transport is not exercised by the gate, because the gate does not install it. Its
adapter is tested for one thing only: that selecting it without the module present fails at startup
with a message naming it, rather than falling back.

This front is erlang-only. Sending mail from a browser is not a thing, and a commonJS row here would
be a module that compiles and cannot work.

## Definition of done

- [ ] `modules/rakun-mail/` exists with its manifest and module tree
- [ ] A message is delivered to the fixture server over plain, STARTTLS and implicit TLS
- [ ] STARTTLS cannot be downgraded, and no configuration key permits it
- [ ] All four MIME shapes are produced correctly, with RFC 2047 headers, dot-stuffing and the 998-byte
      line limit asserted on captured bytes
- [ ] An HTML body is a string the caller rendered; this front encodes it and names no HTML library
- [ ] `send` never blocks a request, retries retryable failures, and dead-letters the rest with a reason
- [ ] A send that must not outlive a rolled-back transaction goes through front 83's outbox, and this
      front grows no second durable queue
- [ ] The `mail` health indicator is registered with front 11, sends nothing, and leaks no credential
- [ ] `repository/rakun/AGENTS.md` records the transport decision and its parallel with front 04's
      cowboy seam
- [ ] The front's tests are green on its assigned target

