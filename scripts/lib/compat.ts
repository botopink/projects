// The text, pattern, path and JSON semantics the meta scripts are written against, in one place.
//
// The scripts were Python until 2026-10-26; their output is kept byte-for-byte. JavaScript differs from that
// in a few quiet ways — `\w`, `\d`, `\s` and `\b` are Unicode in the old patterns, lines split on more than
// `\n`, strings sort by code point, files read with universal newlines, `json.dumps` escapes non-ASCII and
// keeps key order. Everything here exists to keep one of those differences out of the output.
import { lstatSync, readdirSync, readFileSync, readlinkSync, statSync, writeSync } from "node:fs";
import { resolve as resolveAbs } from "node:path";

/** The script's arguments as they were given: Bun drops a `--` that comes first, so they are read from
 *  /proc/self/cmdline when it is there (the arguments after the script's own path). */
export function argv(): string[] {
  const seen = process.argv.slice(2);
  try {
    const cmd = readFileSync("/proc/self/cmdline", "utf8").split("\0");
    cmd.pop();
    const script = process.argv[1];
    for (let i = 1; i < cmd.length; i++)
      if (cmd[i] !== "" && resolveAbs(cmd[i]) === script) {
        const given = cmd.slice(i + 1);
        // the same arguments, give or take that one `--`
        if (given.length === seen.length || (given[0] === "--" && given.length === seen.length + 1)) return given;
        break;
      }
  } catch {}
  return seen;
}

// ── errors ─────────────────────────────────────────────────────────────────────

/** A value error (bad text, bad JSON, a path outside another): the scripts catch it where the original did. */
export class ValueError extends Error {}

// ── output ─────────────────────────────────────────────────────────────────────

// stdout is buffered until exit when it is not a terminal (stderr never is), so the two interleave as before.
const stdoutTTY = (() => {
  try {
    return require("node:tty").isatty(1);
  } catch {
    return false;
  }
})();
let pending: string[] = [];

function writeAll(fd: number, text: string) {
  const buf = Buffer.from(text, "utf8");
  let off = 0;
  while (off < buf.length) {
    try {
      off += writeSync(fd, buf, off, buf.length - off);
    } catch (e: any) {
      if (e?.code === "EAGAIN") continue;
      if (e?.code === "EPIPE") return;
      throw e;
    }
  }
}

/** One line to stdout. */
export function out(line: string = "") {
  if (stdoutTTY) writeAll(1, line + "\n");
  else pending.push(line + "\n");
}

/** One line to stderr. */
export function err(line: string = "") {
  writeAll(2, line + "\n");
}

export function flush() {
  if (pending.length) {
    const text = pending.join("");
    pending = [];
    writeAll(1, text);
  }
}

/** Ends the process. */
export function exit(code: number): never {
  flush();
  process.exit(code);
}

/** A message to stderr and exit 1. */
export function die(message: string): never {
  err(message);
  exit(1);
}

/** Runs a script's main: its return value is the exit code; an unexpected error is reported and exits 1. */
export function run(main: () => number | void) {
  let code: number;
  try {
    code = main() ?? 0;
  } catch (e: any) {
    err(String(e?.stack ?? e));
    exit(1);
  }
  exit(code);
}

// ── text ───────────────────────────────────────────────────────────────────────

const decoder = new TextDecoder("utf-8", { fatal: true, ignoreBOM: true });

/** Strict UTF-8; a bad byte is a ValueError. */
export function decode(bytes: Uint8Array): string {
  try {
    return decoder.decode(bytes);
  } catch {
    throw new ValueError("invalid UTF-8");
  }
}

/** Universal newlines: `\r\n` and `\r` read as `\n`. */
export function universal(text: string): string {
  return text.replace(/\r\n?/g, "\n");
}

/** A text file, UTF-8, with universal newlines. */
export function readText(path: string): string {
  return universal(decode(readFileSync(path)));
}

const LINE_BREAK = /\r\n|[\n\r\x0b\x0c\x1c\x1d\x1e\x85\u2028\u2029]/;

/** Lines without their breaks, every Unicode line boundary a break; no empty last line. */
export function splitlines(text: string): string[] {
  const parts = text.split(LINE_BREAK);
  if (parts[parts.length - 1] === "") parts.pop();
  return parts;
}

/** Whitespace: what the old `\s` and `strip()` meant. */
export const WS = "\\t\\n\\x0b\\x0c\\r\\x1c-\\x1f \\x85\\xa0\\u1680\\u2000-\\u200a\\u2028\\u2029\\u202f\\u205f\\u3000";
const WS_SET = new RegExp(`^[${WS}]$`, "u");

function stripSet(chars?: string): (c: string) => boolean {
  return chars === undefined ? (c) => WS_SET.test(c) : (c) => chars.includes(c);
}

export function strip(s: string, chars?: string): string {
  return rstrip(lstrip(s, chars), chars);
}

export function lstrip(s: string, chars?: string): string {
  const is = stripSet(chars);
  const cps = Array.from(s);
  let i = 0;
  while (i < cps.length && is(cps[i])) i++;
  return cps.slice(i).join("");
}

export function rstrip(s: string, chars?: string): string {
  const is = stripSet(chars);
  const cps = Array.from(s);
  let j = cps.length;
  while (j > 0 && is(cps[j - 1])) j--;
  return cps.slice(0, j).join("");
}

/** Split on runs of whitespace, no empty pieces. */
export function splitWs(s: string): string[] {
  return s.split(new RegExp(`[${WS}]+`, "u")).filter((p) => p !== "");
}

/** At most `max` splits on `sep`, from the right. */
export function rsplit(s: string, sep: string, max: number): string[] {
  const out: string[] = [];
  let rest = s;
  while (out.length < max) {
    const i = rest.lastIndexOf(sep);
    if (i < 0) break;
    out.unshift(rest.slice(i + sep.length));
    rest = rest.slice(0, i);
  }
  out.unshift(rest);
  return out;
}

/** A slice by code point. */
export function cpSlice(s: string, start: number, end?: number): string {
  return Array.from(s).slice(start, end).join("");
}

/** The code point index of a UTF-16 index. */
export function cpIndex(s: string, utf16: number): number {
  return Array.from(s.slice(0, utf16)).length;
}

/** Strings by code point. */
export function cmpStr(a: string, b: string): number {
  const n = Math.min(a.length, b.length);
  for (let i = 0; i < n; ) {
    const x = a.codePointAt(i)!, y = b.codePointAt(i)!;
    if (x !== y) return x < y ? -1 : 1;
    i += x > 0xffff ? 2 : 1;
  }
  return a.length === b.length ? 0 : a.length < b.length ? -1 : 1;
}

export function sortStr(xs: Iterable<string>): string[] {
  return [...xs].sort(cmpStr);
}

/** Lists of ints and strings, element by element; an int against a string has no order (a TypeError before). */
export function cmpKey(a: (number | string)[], b: (number | string)[]): number {
  for (let i = 0; i < Math.min(a.length, b.length); i++) {
    const x = a[i], y = b[i];
    if (typeof x !== typeof y) throw new TypeError(`'<' not supported between instances of ${typeof x} and ${typeof y}`);
    const c = typeof x === "number" ? (x < (y as number) ? -1 : x > (y as number) ? 1 : 0) : cmpStr(x, y as string);
    if (c) return c;
  }
  return a.length - b.length;
}

// Decimal digits by Unicode, as the old `\d`, `isdigit()` and `int()` read them.
const ND = /^\p{Nd}$/u;

/** The value of one decimal digit of any script (a run of decimal digits always starts at its zero). */
function digitValue(c: string): number {
  let cp = c.codePointAt(0)!, k = 0;
  while (ND.test(String.fromCodePoint(cp - 1))) {
    cp--;
    k++;
  }
  return k % 10;
}

export function isDigitStart(s: string): boolean {
  const c = Array.from(s)[0];
  return c !== undefined && ND.test(c);
}

/** `int()` of a string: surrounding whitespace, decimal digits of any script, `_` between digits, a sign. */
export function toInt(s: string): number {
  const t = strip(s);
  const m = /^([+-]?)((?:\p{Nd}_?)*\p{Nd})$/u.exec(t);
  if (!m || /_$|__/.test(m[2])) throw new ValueError(`invalid literal for int() with base 10: ${repr(s)}`);
  let n = 0;
  for (const c of m[2]) if (c !== "_") n = n * 10 + digitValue(c);
  return m[1] === "-" ? -n : n;
}

/** A natural version key: the name split on `.` and `-`, digit runs as numbers. */
export function versionKey(name: string): (number | string)[] {
  return name.split(/[.-]/).map((x) => (x !== "" && /^\p{Nd}+$/u.test(x) ? toInt(x) : x));
}

// ── patterns ───────────────────────────────────────────────────────────────────

const WORD = "\\p{L}\\p{N}_";
const WORD_BOUNDARY = `(?:(?<=[${WORD}])(?![${WORD}])|(?<![${WORD}])(?=[${WORD}]))`;
const NOT_BOUNDARY = `(?:(?<=[${WORD}])(?=[${WORD}])|(?<![${WORD}])(?![${WORD}]))`;
const SYNTAX = "^$\\.*+?()[]{}|/";

/** The JavaScript source of a pattern written with Unicode `\w \d \s \b`, `$` before a final newline,
 *  `.` stopping only at `\n`, and `(?P<name>…)` groups. */
function translate(src: string, multiline: boolean, dotall: boolean): string {
  let o = "", inClass = false;
  for (let i = 0; i < src.length; i++) {
    const c = src[i];
    if (c === "\\") {
      const d = src[++i];
      if (inClass) {
        if (d === "w") o += WORD;
        else if (d === "d") o += "\\p{Nd}";
        else if (d === "s") o += WS;
        else if (d === "D") o += "\\P{Nd}";
        else if ("WSb".includes(d)) throw new Error(`untranslated class escape \\${d}`);
        else if (/[A-Za-z0-9]/.test(d)) o += "\\" + d;
        else o += SYNTAX.includes(d) || d === "-" ? "\\" + d : d;
        continue;
      }
      if (d === "b") o += WORD_BOUNDARY;
      else if (d === "B") o += NOT_BOUNDARY;
      else if (d === "w") o += `[${WORD}]`;
      else if (d === "W") o += `[^${WORD}]`;
      else if (d === "d") o += "\\p{Nd}";
      else if (d === "D") o += "\\P{Nd}";
      else if (d === "s") o += `[${WS}]`;
      else if (d === "S") o += `[^${WS}]`;
      else if (d === "A") o += "(?<![\\s\\S])";
      else if (d === "Z") o += "(?![\\s\\S])";
      else if (/[A-Za-z0-9]/.test(d)) o += "\\" + d;
      else o += SYNTAX.includes(d) ? "\\" + d : d;
      continue;
    }
    if (inClass) {
      if (c === "]") inClass = false;
      o += c === "[" ? "\\[" : c;
      continue;
    }
    if (c === "[") {
      inClass = true;
      o += c;
      if (src[i + 1] === "^") o += src[++i];
      if (src[i + 1] === "]") o += "\\" + src[++i];
    } else if (c === "(" && src.startsWith("(?P<", i)) {
      o += "(?<";
      i += 3;
    } else if (c === ".") o += dotall ? "[\\s\\S]" : "[^\\n]";
    else if (c === "^") o += multiline ? "(?:(?<![\\s\\S])|(?<=\\n))" : "(?<![\\s\\S])";
    else if (c === "$") o += multiline ? "(?=\\n|(?![\\s\\S]))" : "(?=\\n?(?![\\s\\S]))";
    else o += c;
  }
  return o;
}

export class Match {
  constructor(private m: RegExpExecArray) {}
  /** The group's text, or null when it took no part. */
  group(g: number | string = 0): string | null {
    const v = typeof g === "number" ? this.m[g] : this.m.groups?.[g];
    return v === undefined ? null : v;
  }
  get groups(): Record<string, string | null> {
    const out: Record<string, string | null> = {};
    for (const [k, v] of Object.entries(this.m.groups ?? {})) out[k] = v === undefined ? null : v;
    return out;
  }
  /** UTF-16 offsets into the searched string. */
  get index(): number {
    return this.m.index;
  }
  get end(): number {
    return this.m.index + this.m[0].length;
  }
  get groupCount(): number {
    return this.m.length - 1;
  }
}

export class Re {
  readonly js: string;
  private flags: string;
  constructor(readonly source: string, flags: string = "") {
    this.js = translate(source, flags.includes("M"), flags.includes("S"));
    this.flags = "u" + (flags.includes("I") ? "i" : "");
    new RegExp(this.js, this.flags); // a bad pattern fails here, once
  }
  private rx(extra: string, wrap?: (s: string) => string) {
    return new RegExp(wrap ? wrap(this.js) : this.js, this.flags + extra);
  }
  search(s: string): Match | null {
    const m = this.rx("").exec(s);
    return m ? new Match(m) : null;
  }
  /** Anchored at the start. */
  match(s: string): Match | null {
    const r = this.rx("y");
    r.lastIndex = 0;
    const m = r.exec(s);
    return m ? new Match(m) : null;
  }
  /** The whole string. */
  fullmatch(s: string): Match | null {
    const m = this.rx("", (j) => `^(?:${j})$`).exec(s);
    return m ? new Match(m) : null;
  }
  finditer(s: string): Match[] {
    return [...s.matchAll(this.rx("g"))].map((m) => new Match(m as RegExpExecArray));
  }
  /** The whole matches, or the one group's texts ("" when it took no part). */
  findall(s: string): string[] {
    return this.finditer(s).map((m) => (m.groupCount === 0 ? m.group(0)! : (m.group(1) ?? "")));
  }
  test(s: string): boolean {
    return this.search(s) !== null;
  }
  /** Every match replaced: by a function of it, or by a template where `\1` is a group. */
  sub(repl: string | ((m: Match) => string), s: string): string {
    let o = "", last = 0;
    for (const m of this.finditer(s)) {
      o += s.slice(last, m.index);
      o += typeof repl === "function" ? repl(m) : repl.replace(/\\(\d+)|\\g<(\d+)>/g, (_, a, b) => m.group(Number(a ?? b)) ?? "");
      last = m.end;
    }
    return o + s.slice(last);
  }
  /** At most `max` splits (0: all), no groups. */
  split(s: string, max = 0): string[] {
    const out: string[] = [];
    let last = 0, n = 0;
    for (const m of this.finditer(s)) {
      if (max && n >= max) break;
      out.push(s.slice(last, m.index));
      last = m.end;
      n++;
    }
    out.push(s.slice(last));
    return out;
  }
}

export const re = (source: string, flags = "") => new Re(source, flags);

// ── paths ──────────────────────────────────────────────────────────────────────

/** A path as written lexically: no empty or `.` parts, no trailing slash, `..` kept. */
export function pnorm(p: string): string {
  if (p === "") return ".";
  const root = p.startsWith("//") && !p.startsWith("///") ? "//" : p.startsWith("/") ? "/" : "";
  const parts = p.split("/").filter((x) => x !== "" && x !== ".");
  const s = root + parts.join("/");
  return s === "" ? "." : s;
}

export function pjoin(...ps: string[]): string {
  let acc = "";
  for (const p of ps) acc = p.startsWith("/") || acc === "" ? p : acc + "/" + p;
  return pnorm(acc);
}

export function pname(p: string): string {
  const n = pnorm(p);
  if (n === "." || n === "/" || n === "//") return "";
  return n.slice(n.lastIndexOf("/") + 1);
}

export function pparent(p: string): string {
  const n = pnorm(p);
  if (n === "." || n === "/" || n === "//") return n;
  const i = n.lastIndexOf("/");
  if (i < 0) return ".";
  const head = n.slice(0, i);
  return head === "" ? "/" : head === "/" ? "//" : head;
}

/** The last part's last suffix, leading dots ignored. */
export function psuffix(p: string): string {
  const name = pname(p).replace(/^\.+/, "");
  const i = name.lastIndexOf(".");
  return i >= 0 ? name.slice(i) : "";
}

/** Parts for ordering: paths sort part by part. */
export function cmpPath(a: string, b: string): number {
  const x = pnorm(a).split("/"), y = pnorm(b).split("/");
  for (let i = 0; i < Math.min(x.length, y.length); i++) {
    const c = cmpStr(x[i], y[i]);
    if (c) return c;
  }
  return x.length - y.length;
}

export function sortPaths(xs: Iterable<string>): string[] {
  return [...xs].sort(cmpPath);
}

/** `p` relative to `base`, lexically; a ValueError when `base` does not hold it. */
export function relativeTo(p: string, base: string): string {
  const a = pnorm(p), b = pnorm(base);
  if (a === b) return ".";
  const bp = b === "." ? [] : b.split("/"), ap = a.split("/");
  if (b !== "." && !a.startsWith("/") === !b.startsWith("/") && bp.every((x, i) => ap[i] === x) && ap.length > bp.length)
    return ap.slice(bp.length).join("/");
  if (b === "." && !a.startsWith("/")) return a;
  throw new ValueError(`'${a}' is not in the subpath of '${b}'`);
}

/** The absolute path with every symbolic link of its existing part resolved; a missing tail is kept. */
export function resolve(p: string): string {
  const abs = p.startsWith("/") ? p : process.cwd() + "/" + p;
  let cur = "";
  let missing = false;
  const todo = abs.split("/").filter((x) => x !== "" && x !== ".");
  let hops = 0;
  while (todo.length) {
    const part = todo.shift()!;
    if (part === "..") {
      cur = cur.slice(0, Math.max(0, cur.lastIndexOf("/")));
      continue;
    }
    const next = cur + "/" + part;
    if (missing) {
      cur = next;
      continue;
    }
    let st;
    try {
      st = lstatSync(next);
    } catch {
      missing = true;
      cur = next;
      continue;
    }
    if (st.isSymbolicLink() && hops++ < 40) {
      const target = readlinkSync(next);
      if (target.startsWith("/")) cur = "";
      todo.unshift(...target.split("/").filter((x) => x !== "" && x !== "."));
      continue;
    }
    cur = next;
  }
  return cur === "" ? "/" : cur;
}

export function exists(p: string): boolean {
  try {
    statSync(p);
    return true;
  } catch {
    return false;
  }
}

export function lexists(p: string): boolean {
  try {
    lstatSync(p);
    return true;
  } catch {
    return false;
  }
}

export function isDir(p: string): boolean {
  try {
    return statSync(p).isDirectory();
  } catch {
    return false;
  }
}

export function isFile(p: string): boolean {
  try {
    return statSync(p).isFile();
  } catch {
    return false;
  }
}

/** The entries of a directory, as paths under it (unsorted). */
export function iterdir(p: string): string[] {
  return readdirSync(p).map((n) => pjoin(p, String(n)));
}

/** Paths under `dir` matching `pattern` (`/`-separated parts, `*` any run of characters, dot files included). */
export function glob(dir: string, pattern: string): string[] {
  let found = [pnorm(dir)];
  for (const seg of pattern.split("/")) {
    if (!seg.includes("*")) {
      found = found.map((f) => pjoin(f, seg));
      continue;
    }
    const rx = new RegExp("^" + seg.split("*").map((x) => x.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join("[\\s\\S]*") + "$", "u");
    const next: string[] = [];
    for (const f of found) {
      let names: string[];
      try {
        names = readdirSync(f).map(String);
      } catch {
        continue;
      }
      for (const n of names) if (rx.test(n)) next.push(pjoin(f, n));
    }
    found = next;
  }
  return found.filter(lexists);
}

// ── processes ──────────────────────────────────────────────────────────────────

export interface Ran {
  code: number;
  stdout: string;
  stderr: string;
}

/** A command's exit code and its output as text (strict UTF-8, universal newlines); a missing program throws. */
export function spawn(cmd: string[], opts: { cwd?: string } = {}): Ran {
  const r = Bun.spawnSync(cmd, { cwd: opts.cwd, stdout: "pipe", stderr: "pipe", stdin: "ignore" });
  return {
    code: r.exitCode ?? 1,
    stdout: universal(decode(r.stdout ?? new Uint8Array())),
    stderr: universal(decode(r.stderr ?? new Uint8Array())),
  };
}

/** The same, an error when it exits non-zero. */
export function spawnChecked(cmd: string[], opts: { cwd?: string } = {}): Ran {
  const r = spawn(cmd, opts);
  if (r.code !== 0) throw new Error(`Command ${JSON.stringify(cmd)} returned non-zero exit status ${r.code}.`);
  return r;
}

// ── JSON values: objects keep their key order, integers stay integers ──────────

export type Json = null | boolean | bigint | number | string | Json[] | JsonObject;
export type JsonObject = Map<string, Json>;

export const isObject = (v: unknown): v is JsonObject => v instanceof Map;

/** Parses JSON as before: `NaN` and `Infinity` allowed, integers exact, a ValueError on anything else. */
export function loads(text: string): Json {
  let i = 0;
  const fail = (what: string): never => {
    throw new ValueError(`${what}: char ${i}`);
  };
  const ws = () => {
    while (i < text.length && " \t\n\r".includes(text[i])) i++;
  };
  const value = (): Json => {
    ws();
    const c = text[i];
    if (c === "{") {
      i++;
      const o: JsonObject = new Map();
      ws();
      if (text[i] === "}") {
        i++;
        return o;
      }
      for (;;) {
        ws();
        if (text[i] !== '"') fail("Expecting property name enclosed in double quotes");
        const k = str();
        ws();
        if (text[i] !== ":") fail("Expecting ':' delimiter");
        i++;
        o.set(k, value());
        ws();
        if (text[i] === ",") {
          i++;
          continue;
        }
        if (text[i] === "}") {
          i++;
          return o;
        }
        fail("Expecting ',' delimiter");
      }
    }
    if (c === "[") {
      i++;
      const a: Json[] = [];
      ws();
      if (text[i] === "]") {
        i++;
        return a;
      }
      for (;;) {
        a.push(value());
        ws();
        if (text[i] === ",") {
          i++;
          continue;
        }
        if (text[i] === "]") {
          i++;
          return a;
        }
        fail("Expecting ',' delimiter");
      }
    }
    if (c === '"') return str();
    for (const [word, v] of [["null", null], ["true", true], ["false", false], ["NaN", NaN], ["Infinity", Infinity], ["-Infinity", -Infinity]] as const)
      if (text.startsWith(word, i)) {
        i += word.length;
        return v;
      }
    const m = /-?(?:0|[1-9][0-9]*)(\.[0-9]+)?([eE][-+]?[0-9]+)?/y;
    m.lastIndex = i;
    const n = m.exec(text);
    if (!n) return fail("Expecting value");
    i += n[0].length;
    if (n[1] || n[2]) return Number(n[0]);
    if (n[0].replace("-", "").length > 4300) throw new ValueError("Exceeds the limit (4300 digits) for integer string conversion");
    return BigInt(n[0]);
  };
  const str = (): string => {
    i++;
    let s = "";
    for (;;) {
      if (i >= text.length) fail("Unterminated string starting at");
      const c = text[i++];
      if (c === '"') return s;
      if (c === "\\") {
        const e = text[i++];
        const simple: Record<string, string> = { '"': '"', "\\": "\\", "/": "/", b: "\b", f: "\f", n: "\n", r: "\r", t: "\t" };
        if (e in simple) s += simple[e];
        else if (e === "u") {
          const h = text.slice(i, i + 4);
          if (!/^[0-9a-fA-F]{4}$/.test(h)) fail("Invalid \\uXXXX escape");
          s += String.fromCharCode(parseInt(h, 16));
          i += 4;
        } else fail("Invalid \\escape");
      } else if (c.charCodeAt(0) < 0x20) fail("Invalid control character at");
      else s += c;
    }
  };
  const v = value();
  ws();
  if (i !== text.length) fail("Extra data");
  return v;
}

/** A float as the old `repr` wrote it: shortest digits, exponent form below 1e-4 and from 1e16. */
export function floatRepr(x: number): string {
  if (Number.isNaN(x)) return "nan";
  if (!Number.isFinite(x)) return x > 0 ? "inf" : "-inf";
  if (x === 0) return Object.is(x, -0) ? "-0.0" : "0.0";
  const [mant, ex] = Math.abs(x).toExponential().split("e");
  const digits = mant.replace(".", "");
  const decpt = Number(ex) + 1;
  const sign = x < 0 ? "-" : "";
  if (decpt > -4 && decpt <= 16) {
    if (decpt <= 0) return `${sign}0.${"0".repeat(-decpt)}${digits}`;
    if (decpt >= digits.length) return `${sign}${digits}${"0".repeat(decpt - digits.length)}.0`;
    return `${sign}${digits.slice(0, decpt)}.${digits.slice(decpt)}`;
  }
  const e = decpt - 1;
  return `${sign}${digits[0]}${digits.length > 1 ? "." + digits.slice(1) : ""}e${e < 0 ? "-" : "+"}${String(Math.abs(e)).padStart(2, "0")}`;
}

function jsonString(s: string): string {
  let o = '"';
  for (let i = 0; i < s.length; i++) {
    const c = s[i], n = s.charCodeAt(i);
    const esc: Record<string, string> = { '"': '\\"', "\\": "\\\\", "\n": "\\n", "\r": "\\r", "\t": "\\t", "\b": "\\b", "\f": "\\f" };
    if (c in esc) o += esc[c];
    else if (n < 0x20 || n > 0x7e) o += "\\u" + n.toString(16).padStart(4, "0");
    else o += c;
  }
  return o + '"';
}

/** JSON text as before: ASCII only, `", "` / `": "` without an indent, one item per line with one. */
export function dumps(v: Json, indent?: number, level = 0): string {
  if (v === null) return "null";
  if (v === true) return "true";
  if (v === false) return "false";
  if (typeof v === "bigint") return v.toString();
  if (typeof v === "number") return Number.isNaN(v) ? "NaN" : !Number.isFinite(v) ? (v > 0 ? "Infinity" : "-Infinity") : floatRepr(v);
  if (typeof v === "string") return jsonString(v);
  const items: string[] = Array.isArray(v)
    ? v.map((x) => dumps(x, indent, level + 1))
    : [...v].map(([k, x]) => jsonString(k) + ": " + dumps(x, indent, level + 1));
  const [open, close] = Array.isArray(v) ? ["[", "]"] : ["{", "}"];
  if (!items.length) return open + close;
  if (indent === undefined) return open + items.join(", ") + close;
  const pad = "\n" + " ".repeat(indent * (level + 1));
  return open + pad + items.join("," + pad) + "\n" + " ".repeat(indent * level) + close;
}

/** `repr()` of a JSON value. */
export function repr(v: Json): string {
  if (v === null) return "None";
  if (v === true) return "True";
  if (v === false) return "False";
  if (typeof v === "bigint") return v.toString();
  if (typeof v === "number") return floatRepr(v);
  if (typeof v === "string") {
    const q = v.includes("'") && !v.includes('"') ? '"' : "'";
    let o = q;
    for (const c of v) {
      const n = c.codePointAt(0)!;
      if (c === q || c === "\\") o += "\\" + c;
      else if (c === "\n") o += "\\n";
      else if (c === "\r") o += "\\r";
      else if (c === "\t") o += "\\t";
      else if (n < 0x20 || n === 0x7f) o += "\\x" + n.toString(16).padStart(2, "0");
      else if (n > 0x7f && /[\p{Cc}\p{Cf}\p{Cs}\p{Co}\p{Cn}\p{Zl}\p{Zp}\p{Zs}]/u.test(c))
        o += n <= 0xff ? "\\x" + n.toString(16).padStart(2, "0") : n <= 0xffff ? "\\u" + n.toString(16).padStart(4, "0") : "\\U" + n.toString(16).padStart(8, "0");
      else o += c;
    }
    return o + q;
  }
  if (Array.isArray(v)) return "[" + v.map(repr).join(", ") + "]";
  return "{" + [...v].map(([k, x]) => repr(k) + ": " + repr(x)).join(", ") + "}";
}

/** Truthiness. */
export function truthy(v: Json | undefined): boolean {
  if (v === null || v === undefined || v === false) return false;
  if (typeof v === "bigint") return v !== 0n;
  if (typeof v === "number") return v !== 0;
  if (typeof v === "string" || Array.isArray(v)) return v.length > 0;
  if (isObject(v)) return v.size > 0;
  return true;
}

function numeric(v: Json): number | bigint | null {
  if (v === true) return 1n;
  if (v === false) return 0n;
  return typeof v === "bigint" || typeof v === "number" ? v : null;
}

/** Equality: `1 == 1.0 == True`, containers element by element. */
export function eq(a: Json, b: Json): boolean {
  const x = numeric(a), y = numeric(b);
  if (x !== null || y !== null) {
    if (x === null || y === null) return false;
    if (typeof x === "bigint" && typeof y === "bigint") return x === y;
    if (typeof x === "number" && typeof y === "number") return x === y;
    const f = (typeof x === "number" ? x : y) as number, i = (typeof x === "bigint" ? x : y) as bigint;
    return Number.isInteger(f) && BigInt(f) === i;
  }
  if (typeof a === "string" || typeof b === "string" || a === null || b === null) return a === b;
  if (Array.isArray(a) || Array.isArray(b)) return Array.isArray(a) && Array.isArray(b) && a.length === b.length && a.every((x, i) => eq(x, b[i]));
  return a.size === b.size && [...a].every(([k, x]) => b.has(k) && eq(x, b.get(k)!));
}

/** What `for x in v` walks: a list's items, a string's characters, an object's keys; else a TypeError. */
export function iter(v: Json): Json[] {
  if (Array.isArray(v)) return v;
  if (typeof v === "string") return Array.from(v);
  if (isObject(v)) return [...v.keys()];
  throw new TypeError(`'${typeName(v)}' object is not iterable`);
}

/** `x in v`. */
export function contains(v: Json, x: Json): boolean {
  if (typeof v === "string") {
    if (typeof x !== "string") throw new TypeError("'in <string>' requires string as left operand");
    return v.includes(x);
  }
  if (Array.isArray(v)) return v.some((y) => eq(y, x));
  if (isObject(v)) {
    if (Array.isArray(x) || isObject(x)) throw new TypeError("unhashable type");
    return typeof x === "string" && v.has(x);
  }
  throw new TypeError(`argument of type '${typeName(v)}' is not iterable`);
}

/** `v.get(k)` on an object; any other value has no `get`. */
export function get(v: Json, k: string): Json | undefined {
  if (!isObject(v)) throw new TypeError(`'${typeName(v)}' object has no attribute 'get'`);
  return v.get(k);
}

/** `v[k]`. */
export function item(v: Json, k: string): Json {
  if (isObject(v)) {
    if (!v.has(k)) throw new Error(`KeyError: ${repr(k)}`);
    return v.get(k)!;
  }
  throw new TypeError(`'${typeName(v)}' object is not subscriptable by a string`);
}

export function typeName(v: Json): string {
  if (v === null) return "NoneType";
  if (typeof v === "boolean") return "bool";
  if (typeof v === "bigint") return "int";
  if (typeof v === "number") return "float";
  if (typeof v === "string") return "str";
  return Array.isArray(v) ? "list" : "dict";
}
