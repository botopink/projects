// onze — host runtime (the one mutable seam).
//
// A test lib needs shared, identity-based mutable state: a mocked method records
// every call as it runs, and `verify(...)` reads that log back later. botopink is
// immutable-first, so onze isolates the whole recorder + stub table behind these
// host cells, reached from `onze.bp` through `#[@external(node, …)]` declarations.
// The mocked code itself stays ordinary immutable botopink — only this file holds
// mutation. The Erlang/BEAM equivalent is a recorded follow-up.
//
// State is module-global (one node process per `botopink test` module run). Mock
// ids are unique per `newMock()` call, so two mocks never collide even though they
// share these tables.

let __counter = 0;
const calls = []; // { id, method, keys:[string], matchers:[{kind,key}] }
const stubs = []; // { id, method, matchers, action:{kind:"return"|"throw", value} }
let pending = []; // matcher stack built by eq()/anyXxx() before a mock call
let pendingStub = null; // the call captured by when(), awaiting thenReturn/thenThrow
let verifyMode = null; // { spec } set by verify(); consumed by the next mock call

// Pull the matcher stack for a call. If the caller pushed exactly one matcher per
// argument (eq/any), use them; otherwise treat every argument as literal equality
// on its key — so `find(7)` matches a stub registered with `eq(7)`.
function takeMatchers(keys) {
  let m;
  if (pending.length === keys.length) m = pending.slice();
  else m = keys.map((k) => ({ kind: "eq", key: k }));
  pending = [];
  return m;
}

function argsMatch(matchers, keys) {
  if (matchers.length !== keys.length) return false;
  for (let i = 0; i < keys.length; i++) {
    if (matchers[i].kind === "any") continue;
    if (matchers[i].key !== keys[i]) return false;
  }
  return true;
}

export function newMock() {
  __counter += 1;
  return "onze#" + __counter;
}

// Canonical, comparable key for any argument value (string/int/array/record).
export function key(v) {
  return JSON.stringify(v);
}

export function pushMatcher(kind, k) {
  pending.push({ kind, key: k });
  return 0;
}

export function beginVerify(spec) {
  verifyMode = { spec };
  return 0;
}

// The single entry every synthesized mock method calls: record the invocation
// (or, in verify mode, assert its count), then return the matching stub value —
// or `def`, the caller-supplied type-default for the method's return type.
export function invoke(id, method, keys, def) {
  const matchers = takeMatchers(keys);

  if (verifyMode !== null) {
    const spec = verifyMode.spec;
    verifyMode = null;
    let count = 0;
    for (const c of calls) {
      if (c.id === id && c.method === method && argsMatch(matchers, c.keys)) count += 1;
    }
    // spec: -1 = at least once, n >= 0 = exactly n (0 = never).
    const ok = spec === -1 ? count >= 1 : count === spec;
    if (!ok) {
      const want = spec === -1 ? "at least 1" : "exactly " + spec;
      const made = calls
        .filter((c) => c.id === id && c.method === method)
        .map((c) => method + "(" + c.keys.join(", ") + ")");
      throw new Error(
        "onze.verify: " + method + " — expected " + want + " matching call(s), got " + count +
          (made.length ? " [recorded: " + made.join("; ") + "]" : " [no calls recorded]"),
      );
    }
    return def;
  }

  calls.push({ id, method, keys, matchers });
  for (let i = stubs.length - 1; i >= 0; i--) {
    const s = stubs[i];
    if (s.id === id && s.method === method && argsMatch(s.matchers, keys)) {
      if (s.action.kind === "throw") throw new Error(s.action.value);
      return s.action.value;
    }
  }
  return def;
}

// when(mock.m(args)) recorded a call inside the argument; pop it back off the log
// and hold it as the stub target the builder will write to.
export function when() {
  const c = calls.pop();
  pendingStub = c ? { id: c.id, method: c.method, matchers: c.matchers } : null;
  return 0;
}

export function thenReturn(v) {
  if (pendingStub) stubs.push({ ...pendingStub, action: { kind: "return", value: v } });
  pendingStub = null;
  return 0;
}

export function thenThrow(msg) {
  if (pendingStub) stubs.push({ ...pendingStub, action: { kind: "throw", value: msg } });
  pendingStub = null;
  return 0;
}
