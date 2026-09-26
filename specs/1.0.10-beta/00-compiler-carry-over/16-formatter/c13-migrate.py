#!/usr/bin/env python3
"""c13-migrate.py [--md] <files...> — C-13 (decision 29 (c)): delete the `;` after a braced
block statement — a statement that STARTS with `if`, `for`, `while`, `loop`, `case`, a
`iter`/`stream` prefixed loop or a `#[…]`-annotated loop, whose last token before the `;` is
its closing `}`. Nothing else is touched: a binding or `return` whose value is braced keeps
its `;`, as `format.zig`'s `terminated` and the parser's `isBracedBlockStmt` do.
With --md, only the ```botopink fences of a Markdown file are rewritten.

Front 16's C-13 migration (compiler 7af79f44). Verify a run the way that commit did: every changed
line differs only by deleted `;`, and `botopink format` of each file before and after is byte-identical
(the same program). Trees `scripts/format-check.sh` holds canonical are migrated by `botopink format`
instead."""
import re, sys

KW = {'if', 'for', 'while', 'loop', 'case'}
TOK = re.compile(r'"""[\s\S]*?"""|\\\\[^\n]*|"(?:\\.|[^"\\\n])*"|//[^\n]*|[A-Za-z_@$][A-Za-z0-9_]*|\d[\w.]*|->|\S', re.M)

def migrate(src):
    toks = [(m.start(), m.group()) for m in TOK.finditer(src)]
    code = [(p, t) for p, t in toks if not t.startswith('//')]
    deletes = []
    # stack of frames: each frame is the statement list of one brace/paren/bracket level
    stack = [{'open': None, 'start': 0}]  # start: index in `code` of the current statement's first token
    i = 0
    def stmt_kind(j):
        t = code[j][1] if j < len(code) else ''
        if t in KW: return True
        if t in ('iter', 'stream') and j + 1 < len(code) and code[j + 1][1] in ('loop', 'while', 'for'): return True
        if t == '#' and j + 1 < len(code) and code[j + 1][1] == '[':
            depth = 0
            for k in range(j + 1, len(code)):
                if code[k][1] == '[': depth += 1
                elif code[k][1] == ']':
                    depth -= 1
                    if depth == 0:
                        nxt = code[k + 1][1] if k + 1 < len(code) else ''
                        return nxt in ('loop', 'while', 'for', 'iter', 'stream')
            return False
        return False
    def closes_body(start, i):
        # True when the `}` at `i` closes a brace that opened at the statement's
        # own nesting level — its body — and not a lambda inside its condition.
        depth = 0
        for k in range(start, i + 1):
            t = code[k][1]
            if t in '{([': depth += 1
            elif t in '})]': depth -= 1
        return depth == 0
    while i < len(code):
        p, t = code[i]
        if t in '{([':
            fr = stack[-1]
            isCase = t == '{' and any(code[k][1] == 'case' for k in range(fr['start'], i))
            stack.append({'open': t, 'start': i + 1, 'case': isCase}); i += 1; continue
        if t == '->':
            # A lambda's / binder's parameter prologue (`{ x ->`, `{ a, b ->`,
            # `{ ->`): the statement list starts after the arrow. Not in a `case`
            # body, where `->` separates an arm's pattern from its value.
            fr = stack[-1]
            if fr['open'] == '{' and not fr.get('case') and all(
                    re.match(r'^[A-Za-z_][A-Za-z0-9_]*$|^,$', code[k][1]) for k in range(fr['start'], i)):
                fr['start'] = i + 1
            i += 1; continue
        if t in '})]':
            if len(stack) > 1: stack.pop()
            # A block statement already written without its `;` ends at this `}`:
            # the next statement starts after it (unless an `else` continues it).
            fr = stack[-1]
            nxt = code[i + 1][1] if i + 1 < len(code) else ''
            if t == '}' and fr['open'] in (None, '{') and fr['start'] <= i and stmt_kind(fr['start']) \
                    and nxt not in (';', 'else') and closes_body(fr['start'], i):
                fr['start'] = i + 1
            i += 1; continue
        if t == ';':
            fr = stack[-1]
            if fr['open'] in (None, '{') and fr['start'] < i and code[i - 1][1] == '}' and stmt_kind(fr['start']):
                deletes.append(p)
            fr['start'] = i + 1
        i += 1
    out = src
    for p in sorted(deletes, reverse=True):
        out = out[:p] + out[p + 1:]
    return out, len(deletes)

total = 0
md = sys.argv[1] == '--md'
for f in sys.argv[2 if md else 1:]:
    s = open(f, encoding='utf-8').read()
    if md:
        n = 0
        def rep(m):
            global n
            body, k = migrate(m.group(2)); n += k
            return m.group(1) + body + m.group(3)
        new = re.sub(r'(```botopink\n)([\s\S]*?)(```)', rep, s)
    else:
        new, n = migrate(s)
    if n:
        open(f, 'w', encoding='utf-8').write(new); print(f'{n:4d}  {f}'); total += n
print(f'total {total}')
