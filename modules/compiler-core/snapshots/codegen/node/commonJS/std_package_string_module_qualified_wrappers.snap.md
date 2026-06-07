----- SOURCE CODE -- std/string.bp
```botopink
//// String utilities module (`import {string} from "std";`).
//// Qualified wrappers over the built-in String interface methods.
//// Follows the Gleam-inspired naming convention: camelCase.

pub fn split(s: string, sep: string) -> Array<string> {
    return s.split(sep);
}

pub fn trim(s: string) -> string {
    return s.trim();
}

pub fn trimStart(s: string) -> string {
    return s.trim_start();
}

pub fn trimEnd(s: string) -> string {
    return s.trim_end();
}

pub fn contains(s: string, sub: string) -> bool {
    return s.contains(sub);
}

pub fn startsWith(s: string, prefix: string) -> bool {
    return s.starts_with(prefix);
}

pub fn endsWith(s: string, suffix: string) -> bool {
    return s.ends_with(suffix);
}

pub fn slice(s: string, start: i32, end: i32) -> string {
    return s.slice(start, end);
}

pub fn replace(s: string, pattern: string, with: string) -> string {
    return s.replace(pattern, with);
}

pub fn toUpper(s: string) -> string {
    return s.to_upper();
}

pub fn toLower(s: string) -> string {
    return s.to_lower();
}

// `join` takes an array of strings and a separator — Array<string>.join(sep).
pub fn join(parts: Array<string>, sep: string) -> string {
    return parts.join(sep);
}

test "inline: split and join round-trip" {
    val parts = split("a,b,c", ",");
    assert join(parts, "-") == "a-b-c";
}

test "inline: contains" {
    assert contains("hello world", "world");
    assert !contains("hello", "xyz");
}

test "inline: startsWith and endsWith" {
    assert startsWith("foobar", "foo");
    assert endsWith("foobar", "bar");
}

test "inline: slice" {
    assert slice("hello", 1, 3) == "el";
}

test "string split and length" {
    val s = "a,b";
    val parts = s.split(",");
    assert parts.length == 2;
}

test "string trim" {
    val padded = "  hi  ";
    assert padded.trim() == "hi";
}

test "string slice via method" {
    val h = "hello";
    assert h.slice(1, 3) == "el";
    assert h.slice(0, 2) == "he";
}

```

----- JAVASCRIPT -- std/string.js
```javascript
//// String utilities module (`import {string} from "std";`).

//// Qualified wrappers over the built-in String interface methods.

//// Follows the Gleam-inspired naming convention: camelCase.

function split(s, sep) {
    return s.split(sep);
}
exports.split = split;

function trim(s) {
    return s.trim();
}
exports.trim = trim;

function trimStart(s) {
    return s.trim_start();
}
exports.trimStart = trimStart;

function trimEnd(s) {
    return s.trim_end();
}
exports.trimEnd = trimEnd;

function contains(s, sub) {
    return s.contains(sub);
}
exports.contains = contains;

function startsWith(s, prefix) {
    return s.starts_with(prefix);
}
exports.startsWith = startsWith;

function endsWith(s, suffix) {
    return s.ends_with(suffix);
}
exports.endsWith = endsWith;

function slice(s, start, end) {
    return s.slice(start, end);
}
exports.slice = slice;

function replace(s, pattern, with_) {
    return s.replace(pattern, with_);
}
exports.replace = replace;

function toUpper(s) {
    return s.to_upper();
}
exports.toUpper = toUpper;

function toLower(s) {
    return s.to_lower();
}
exports.toLower = toLower;

// `join` takes an array of strings and a separator — Array<string>.join(sep).

function join(parts, sep) {
    return parts.join(sep);
}
exports.join = join;
```

----- TYPESCRIPT TYPEDEF -- std/string.d.ts
```typescript
export declare function split(s: , sep: ): Array<string>;


export declare function trim(s: ): string;


export declare function trimStart(s: ): string;


export declare function trimEnd(s: ): string;


export declare function contains(s: , sub: ): bool;


export declare function startsWith(s: , prefix: ): bool;


export declare function endsWith(s: , suffix: ): bool;


export declare function slice(s: , start: , end: ): string;


export declare function replace(s: , pattern: , with: ): string;


export declare function toUpper(s: ): string;


export declare function toLower(s: ): string;


export declare function join(parts: , sep: ): string;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {string} from "std";

fn main() {
    val parts = string.split("a,b,c", ",");
    @print(string.join(parts, "|"));
    @print(string.contains("hello world", "world"));
    @print(string.startsWith("foobar", "foo"));
    @print(string.slice("hello", 1, 3));
    @print(string.trim("  hi  "));
}
```

----- JAVASCRIPT -- main.js
```javascript
const string = require("./std/string.js");

function main() {
    const parts = string.split("a,b,c", ",");
    console.log(string.join(parts, "|"));
    console.log(string.contains("hello world", "world"));
    console.log(string.startsWith("foobar", "foo"));
    console.log(string.slice("hello", 1, 3));
    console.log(string.trim("  hi  "));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
