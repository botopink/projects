# Front 71 — the 1.0.10 snapshot map, `06-onze/test-snap.md` § 71 (realised under 53-b (c): the five texts are on disk as `onze-release/test/__snapshots__/release/*.snap`, recorded through `snapshots.assertAs` rather than these helpers)

## 71 — release packaging · `modules/onze-release/test/`

```bp
import {assertBuildId, assertReleaseText, assertDockerfile, assertReleaseTree, assertShutdown, assertStaticExport} from "onze-test";
import {ReleaseSpec, releaseSpec, withErts} from "onze-release";
import {fixtureApp} from "onze-test";

test "release: build id ---- derived once, sort-independent, sensitive" {
    try assertBuildId(@src(), ["4f21ab", "7e0055", "9c1d40"], "41ab08");
}
```

`modules/onze-release/test/__snapshots__/release/build-id-derived-once-sort-independent-sensitive.snap`

```
generateBuildId(["4f21ab","7e0055","9c1d40"], "41ab08") = b7f2a1
generateBuildId(["9c1d40","4f21ab","7e0055"], "41ab08") = b7f2a1
generateBuildId(["4f21ab","7e0055","9c1d41"], "41ab08") = 3e8d27
validateBuildId("")          error: build id is empty
validateBuildId("has/slash") error: build id "has/slash" is not [A-Za-z0-9_-]{1,64}
validateBuildId(65 chars)    error: build id is 65 characters; the limit is 64
verifyBuildId(b7f2a1, b7f2a1, b7f2a1) ok
verifyBuildId(b7f2a1, b7f2a1, stale)  error: release and payload build ids disagree (b7f2a1 vs stale)
```

```bp
test "release: text ---- rel, sys.config, vm.args and the boot script" {
    try assertReleaseText(@src(), releaseSpec("blog", "0.1.0", "b7f2a1"));
}
```

`modules/onze-release/test/__snapshots__/release/text-rel-sys-config-vm-args-and-the-boot-script.snap`

```
== releases/b7f2a1/onze.rel
{release, {"blog", "0.1.0"}, {erts, "16.0"},
 [{kernel, "10.3"}, {stdlib, "7.0"}, {sasl, "4.3"}, {rakun, "0.0.1"}, {jhonstart, "0.0.1"}, {emilia, "0.0.1"}, {onze, "0.0.1"}, {blog, "0.1.0"}]}.
== releases/b7f2a1/sys.config
[{blog, [{port, 3000}, {base_path, ""}]}].
== releases/b7f2a1/vm.args
-name blog@127.0.0.1
-setcookie ${RELEASE_COOKIE}
+K true
== bin/onze
#!/bin/sh
set -e
BUILD_ID="$(cat "$(dirname "$0")/../BUILD_ID")"
[ "$BUILD_ID" = "b7f2a1" ] || { echo "build id mismatch: $BUILD_ID != b7f2a1" >&2; exit 1; }
[ -n "$RELEASE_COOKIE" ] || { echo "RELEASE_COOKIE is not set" >&2; exit 1; }
export PORT="${PORT:-3000}"
exec "$(dirname "$0")/../erts-16.0/bin/erl" -boot "$(dirname "$0")/../releases/b7f2a1/start" -config "$(dirname "$0")/../releases/b7f2a1/sys" -args_file "$(dirname "$0")/../releases/b7f2a1/vm.args" -noshell
== sys.config contains a value from env.read
false
```

```bp
test "release: dockerfile ---- two stages, non-root, erts bundled and not" {
    try assertDockerfile(@src(), releaseSpec("blog", "0.1.0", "b7f2a1"));
}
```

`modules/onze-release/test/__snapshots__/release/dockerfile-two-stages-non-root-erts-bundled-and-not.snap`

```
== includeErts: true
FROM erlang:28-alpine AS build
WORKDIR /src
COPY . .
RUN onze build

FROM alpine:3.20 AS runner
RUN addgroup -S onze && adduser -S -G onze onze
WORKDIR /app
COPY --from=build --chown=onze:onze /src/.onze/release ./
USER onze
ENV PORT=3000
EXPOSE 3000
CMD ["bin/onze", "start"]
== includeErts: false — runner line
FROM erlang:28-alpine AS runner
== .dockerignore
.git
.onze
.botopinkbuild
test/
== runner stage contains COPY . . / onze build / USER root
false / false / false
```

```bp
test "release: tree ---- the standalone layout" {
    try assertReleaseTree(@src(), fixtureApp());
}
```

`modules/onze-release/test/__snapshots__/release/tree-the-standalone-layout.snap`

```
.onze/release/
  BUILD_ID
  bin/
    onze
  erts-16.0/
  lib/
    blog-0.1.0/ebin/
    emilia-0.0.1/ebin/
    jhonstart-0.0.1/ebin/
    onze-0.0.1/ebin/
    rakun-0.0.1/ebin/
  prerender/
    index.html
    manifest.txt
  public/
    favicon.ico
  releases/
    b7f2a1/
      onze.rel
      start.boot
      sys.config
      vm.args
  static/
    b7f2a1/
      app.2b91cc.css
      entry.9c1d40.js
      r2.7e0055.js
      shared.41ab08.js
== BUILD_ID
b7f2a1
== manifest chunks present
4 of 4
== scanForSecrets (DATABASE_URL=postgres://secret@db)
none
== scanForSecrets with the value planted in shared.41ab08.js
error: release refused — value of DATABASE_URL found in static/b7f2a1/shared.41ab08.js
```

```bp
test "release: shutdown ---- the five steps and a clean drain" {
    try assertShutdown(@src(), 5000);
}
```

`modules/onze-release/test/__snapshots__/release/shutdown-the-five-steps-and-a-clean-drain.snap`

```
readinessChecks: route-table, client-manifest, datasource:default
shutdownOrder:
  1 readiness=false
  2 stop-accepting
  3 drain-renders
  4 drain-after-tasks
  5 stop-supervision-tree
drain(5000): renders=0 afterTasks=0 timedOut=false exit=0
drain(1) with 2 renders in flight: renders=2 afterTasks=0 timedOut=true exit=1
```

```bp
test "release: static export ---- three routes out, a dynamic route refused" {
    try assertStaticExport(@src(),
        \\ == app/page.bp
        \\ #[page("")]
        \\ == app/about/page.bp
        \\ #[page("about")]
        \\ == app/docs/page.bp
        \\ #[page("docs")]
        \\ == app/blog/[slug]/page.bp
        \\ #[page("blog/[slug]")]
        \\ (no registerStaticParams)
    );
}
```

`modules/onze-release/test/__snapshots__/release/static-export-three-routes-out-a-dynamic-route-refused.snap`

```
== without app/blog/[slug]
out/
  index.html
  about/index.html
  docs/index.html
  favicon.ico
  _onze/static/b7f2a1/app.2b91cc.css
  _onze/static/b7f2a1/entry.9c1d40.js
  _onze/static/b7f2a1/shared.41ab08.js
no bin/, no releases/
== with app/blog/[slug]
error: static export refused — route /blog/:slug (app/blog/[slug]/page.bp) cannot be prerendered: no static params registered
```

---

