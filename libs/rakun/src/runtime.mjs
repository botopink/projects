// rakun — host runtime: the mutable seams behind `#[@external]`.
//
// botopink is immutable-first and has no top-level mutable globals, so the
// framework's runtime state — the component scan registry, the dependency-cycle
// guard, the config properties, and the router table — lives here, reached from
// `runtime.bp` through `#[@external(node, …)]` declarations. The decorators
// (`decorators.bp`) emit self-registering `val`s and factory fns that call into
// these; `Rakun.run` reads the router back. The compiler core learns nothing
// about rakun.
//
// State is module-global (one node process per run / per `botopink test`
// module). The Erlang/BEAM equivalent is a recorded follow-up.

// ── component scan ──────────────────────────────────────────────────────────
// Every component decorator emits `rkScan(name)` at module load, so the set of
// managed component types is known without cross-decorator compile-time state.

const scanned = []; // component type names, in declaration order

export function scan(name) {
  scanned.push(name);
  return 0;
}
export function scannedNames() {
  return scanned.join(",");
}
export function scannedCount() {
  return scanned.length;
}

// ── dependency-cycle guard ──────────────────────────────────────────────────
// A component factory (`__rkMake_X`) brackets its construction with
// `enter(X)`/`done(X)`. Constructor injection has no whole-graph compile-time
// view (each decorator sees only its own record), so a cycle A→B→A is caught
// here at first construction — `enter` throws when a type is already mid-build —
// instead of recursing until the stack overflows.

const building = new Set();

export function enter(name) {
  if (building.has(name)) {
    throw new Error(
      "rakun dependency cycle: component '" + name +
        "' depends (transitively) on itself — constructor injection requires an acyclic graph",
    );
  }
  building.add(name);
  return 0;
}
export function done(name) {
  building.delete(name);
  return 0;
}

// ── property injection (`#[value("key")]`) ──────────────────────────────────
const props = new Map(); // key -> string

export function setProp(key, value) {
  props.set(key, value);
  return 0;
}
export function prop(key) {
  return props.has(key) ? props.get(key) : "";
}

// ── router ──────────────────────────────────────────────────────────────────
// A controller decorator emits one `registerRoute` per mapped method, each with
// a handler closure that builds the controller via its factory and calls the
// method. `dispatch` matches an incoming (verb, path) — supporting `:name` path
// params — runs the handler with a request, and returns its Response; an
// unmatched path returns a 404 Response (a plain {status, body}, the shape
// botopink's `Response` record lowers to).

const routes = []; // { verb, path, segs, handler }

function split(path) {
  return path.split("/").filter((s) => s.length > 0);
}

export function registerRoute(verb, path, handler) {
  routes.push({ verb, path, segs: split(path), handler });
  return 0;
}
export function routeCount() {
  return routes.length;
}
export function routePaths() {
  return routes.map((r) => r.verb + " " + r.path).join(", ");
}

function match(verb, path) {
  const want = split(path);
  for (const r of routes) {
    if (r.verb !== verb) continue;
    if (r.segs.length !== want.length) continue;
    const params = {};
    let ok = true;
    for (let i = 0; i < r.segs.length; i++) {
      const seg = r.segs[i];
      if (seg.startsWith(":")) params[seg.slice(1)] = want[i];
      else if (seg !== want[i]) { ok = false; break; }
    }
    if (ok) return { route: r, params };
  }
  return null;
}

// A request handed to a handler. The server supplies the real one; this is the
// in-process value `dispatch` builds (path params bound, the rest empty).
function makeRequest(verb, path, params, body) {
  return {
    method: verb,
    path: path,
    param: (n) => (Object.prototype.hasOwnProperty.call(params, n) ? params[n] : undefined),
    query: (_n) => undefined,
    header: (_n) => undefined,
    body: () => body,
  };
}

export function dispatch(verb, path) {
  const m = match(verb, path);
  if (m === null) return { status: 404, body: "" };
  const req = makeRequest(verb, path, m.params, "");
  return m.route.handler(req);
}
