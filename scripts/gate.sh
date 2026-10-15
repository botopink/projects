#!/usr/bin/env bash
# gate.sh — the meta repository's gate and the machine's gate scheduler
# (front 163 meta-ci, step s7; decisions 468, 469, 473).
#
#   scripts/gate.sh [check]            the meta repository's own checks — the
#                                      five of `.github/workflows/hook-integrity.yml`,
#                                      which calls this script — all run, every
#                                      red listed, exit 1 if any
#   scripts/gate.sh run <target>…      those repositories' / tasks' gates together
#                                      under the machine's job pool, each handed
#                                      its share of jobs
#   scripts/gate.sh tasks              every open task's gate (its own repositories)
#   scripts/gate.sh libs               every library's own gate, on the main
#                                      checkout's compiler
#   scripts/gate.sh status             what runs and what waits, each one's stage
#                                      and time
#   scripts/gate.sh exec [--jobs <N>] <name> -- <command>…
#                                      one command (a `zig build`, a test run, a
#                                      `cell check`, a library commit and its hook)
#                                      under the pool: it waits for a free job,
#                                      holds <N> (default a quarter of the capacity) while
#                                      it runs, and gives them back when it ends
#
# <target> is a repository of this checkout (`repository/<name>/`, which has a
# `scripts/gate.sh`), or a task: `task:<name>`, or a bare name that is no
# repository. A task is a worktree under `.tasks/<name>`, found by `git worktree
# list` of the meta repository and of every submodule; its OWN repositories are
# the ones checked out on its branch `front/<name>`, the others are linked
# siblings (symlinks to the main checkout's, or checkouts left on the pointer)
# and are not gated by it.
#
# Options of `run`, `tasks`, `libs`: `--no-conformance` is handed to every gate
# (a run by hand, not a gate verdict — the hook's flag, decision 470). A gate is
# run WITH conformance unless it is given.
#
# ── the pool ─────────────────────────────────────────────────────────────────
# One pool per machine (decision 468): a directory at a fixed path —
# `$XDG_RUNTIME_DIR/botopink-gate-pool`, else `/tmp/botopink-gate-pool-<uid>` —
# holding one `lease.<id>` file per running gate (its owner pid, its child pid,
# the jobs it holds, its name, start time and log) and one `wait.<id>` per gate
# that waits. The capacity is the machine's jobs: one per CPU bounded by
# `MemAvailable / 768 MiB`, then counted as ~2 runnable threads a job (the
# `botopink` child and its `erl` / `node`, measured in 144 B-29 step G), so
# `capacity = max(1, jobs / 2)`. A gate is admitted when at least one job is
# free: it takes `min(share, free)` jobs, `share = max(1, capacity / gates of
# this run)`, and gives them back when it ends; a lease whose owner and child
# are both dead is reaped. The path is fixed, not a flag or a variable a commit
# sets (decision 67). botopink-lang's gate takes no total of jobs yet (it sizes
# itself to the machine), so a run of it holds the whole pool. The commit hook's
# gate (decision 470) runs outside the pool; a thread that commits runs it
# through `exec`. Admissions are staggered: one gate starts at most every 60 s
# while another runs, first come first served. Every run waits for a free job, `--no-conformance` included
# (the maintainer, 2026-10-12: the lock is held while a gate executes, never
# skipped — unlocked runs piling up took the machine down).
#
# A repository's own `scripts/gate.sh` knows none of this (decision 469): this
# script calls it with `--jobs <share>` (a library's) and nothing else.
#
# ── logs ─────────────────────────────────────────────────────────────────────
# Each run's log is scratch: `<main checkout>/.tasks/.gate-logs/` for a
# repository of the checkout, `<task root>/.gate-logs/` for a task (git-ignored);
# a spec never names one (decision 473 (6)).
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

# The main checkout of this meta repository, from any of its worktrees.
mainRoot() {
    local common
    common="$(git rev-parse --path-format=absolute --git-common-dir)"
    dirname "$common"
}

submodulePaths() {
    git config --file .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{ print $2 }'
}

# ═════════════════════════════════════════════════════════════════════════════
# The meta repository's own checks (what hook-integrity.yml runs).
# ═════════════════════════════════════════════════════════════════════════════

# The library repositories that share the pre-commit guards (CI check 4).
libraryRepos="rakun query actions http log routing validation css snap json yaml markdown"

# 1. every submodule pointer is an ancestor of (or equal to) its remote feat.
check1() {
    local bad=0 sub head
    for sub in $(submodulePaths); do
        if [ ! -d "$sub/.git" ] && [ ! -f "$sub/.git" ]; then echo "  ✗ $sub: not checked out"; bad=1; continue; fi
        head="$(git -C "$sub" rev-parse HEAD)"
        git -C "$sub" fetch --quiet origin feat
        if git -C "$sub" merge-base --is-ancestor "$head" FETCH_HEAD; then
            echo "  ✓ $sub $head is on origin/feat"
        else
            echo "  ✗ $sub $head is not on origin/feat — the bump points at a commit feat does not have"
            bad=1
        fi
    done
    [ "$bad" -eq 0 ] || { echo "gate: a submodule pointer is off its remote feat"; return 1; }
}

# 2. every path in the AGENTS.md layout table exists.
expandBraces() { # one {a,b,c} group
    local p="$1" pre rest body post b
    case "$p" in
        *\{*\}*)
            pre="${p%%\{*}"; rest="${p#*\{}"; body="${rest%%\}*}"; post="${rest#*\}}"
            local IFS=','
            for b in $body; do printf '%s\n' "$pre$b$post"; done ;;
        *) printf '%s\n' "$p" ;;
    esac
}
check2() {
    local bad=0 n=0 row p q
    while IFS= read -r row; do
        case "$row" in *git-ignored*) continue ;; esac
        p="$(printf '%s\n' "$row" | sed -n 's/^| `\([^`]*\)`.*/\1/p')"
        [ -n "$p" ] || continue
        for q in $(expandBraces "$p"); do
            n=$((n + 1))
            if [ -e "$q" ]; then echo "  ✓ $q"; else echo "  ✗ $q — named by AGENTS.md § Layout, absent on disk"; bad=1; fi
        done
    done < <(awk '/^## Layout/ { on = 1; next } /^## / { on = 0 } on && /^\| `/' AGENTS.md)
    [ "$n" -gt 0 ] || { echo "gate: AGENTS.md § Layout names no path"; return 1; }
    [ "$bad" -eq 0 ] || { echo "gate: the layout AGENTS.md describes is not the one on disk"; return 1; }
}

# 3. no snapshot candidate or todo.md is tracked anywhere.
check3() {
    local pattern='(\.snap\.new|\.snap\.md\.new|(^|/)todo\.md)$' bad=0 sub
    track() { # <label> <dir>
        local hits
        hits="$(git -C "$2" ls-files | grep -E "$pattern" || true)"
        if [ -n "$hits" ]; then
            echo "  ✗ $1 tracks:"; printf '%s\n' "$hits" | sed 's/^/      /'; bad=1
        else
            echo "  ✓ $1"
        fi
    }
    track meta .
    for sub in $(submodulePaths); do track "$sub" "$sub"; done
    [ "$bad" -eq 0 ] || { echo "gate: a snapshot candidate or a todo.md is tracked"; return 1; }
}

# 4. the library repositories' guards, runner and gate are one text.
check4() {
    local ref=rakun bad=0 f lib pat
    for f in scripts/git-hooks/pre-commit scripts/git-hooks/lib/runner-standalone.sh scripts/gate.sh; do
        for lib in $libraryRepos; do
            [ "$lib" = "$ref" ] && continue
            if [ ! -f "repository/$lib/$f" ]; then
                echo "  ✗ $lib: no $f"; bad=1
            elif cmp -s "repository/$ref/$f" "repository/$lib/$f"; then
                echo "  ✓ $lib: $f identical to $ref's"
            else
                echo "  ✗ $lib: $f differs from $ref's — the guard clauses are not one text"; bad=1
            fi
        done
    done
    for lib in $libraryRepos; do
        for pat in '*.snap.new' '*.snap.md.new'; do
            if grep -qxF -- "$pat" "repository/$lib/.gitignore" 2>/dev/null; then
                echo "  ✓ $lib: .gitignore names $pat"
            else
                echo "  ✗ $lib: .gitignore does not name $pat"; bad=1
            fi
        done
        if [ -e "repository/$lib/scripts/known-broken-examples.txt" ]; then
            echo "  ✗ $lib: scripts/known-broken-examples.txt exists — a list of examples allowed to fail (gate-i)"; bad=1
        else
            echo "  ✓ $lib: no known-broken-examples.txt"
        fi
        for pat in 'git config core.hooksPath scripts/git-hooks' 'scripts/gate.sh' 'conformance/'; do
            if grep -qF -- "$pat" "repository/$lib/AGENTS.md" 2>/dev/null; then
                echo "  ✓ $lib: AGENTS.md names $pat"
            else
                echo "  ✗ $lib: AGENTS.md does not name $pat"; bad=1
            fi
        done
    done
    [ "$bad" -eq 0 ] || { echo "gate: the library guards differ (each repository's gate front owns its copy)"; return 1; }
}

# 5. every LANGUAGE GAP marker has a row.
check5() {
    [ -f scripts/language-gap-markers.sh ] || { echo "  ✗ scripts/language-gap-markers.sh is missing (113 step 4c)"; return 1; }
    bash scripts/language-gap-markers.sh
}

# 6. each repository's decisions-taken.md is what scripts/decisions-split.py writes (decision 482).
check6() {
    [ -f scripts/decisions-split.py ] || { echo "  ✗ scripts/decisions-split.py is missing (163 s10)"; return 1; }
    python3 scripts/decisions-split.py --check
}

runChecks() {
    local titles=(
        "1. every submodule pointer is on its remote feat"
        "2. every path in the meta AGENTS.md layout table exists"
        "3. no snapshot candidate or todo.md is tracked anywhere"
        "4. the library repositories' guards, runner and gate are one text"
        "5. every LANGUAGE GAP marker has a row"
        "6. every repository's decisions-taken.md is what decisions-split.py writes"
    )
    local i red=""
    for i in 1 2 3 4 5 6; do
        echo "── ${titles[$((i - 1))]}"
        if "check$i"; then :; else red="$red $i"; fi
    done
    if [ -n "$red" ]; then
        echo -e "${RED}✗ meta gate: check(s)$red red${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ meta gate: all six checks green${NC}"
}

# ═════════════════════════════════════════════════════════════════════════════
# The scheduler.
# ═════════════════════════════════════════════════════════════════════════════

poolDir() {
    if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -d "$XDG_RUNTIME_DIR" ]; then
        echo "$XDG_RUNTIME_DIR/botopink-gate-pool"
    else
        echo "/tmp/botopink-gate-pool-$(id -u)"
    fi
}
pool="$(poolDir)"

# poolCapacity — the machine's jobs, a job counted as ~2 runnable threads.
poolCapacity() {
    local cpus avail_kb by_mem jobs
    cpus="$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || echo 4)"
    jobs="$cpus"
    avail_kb="$(awk '/^MemAvailable:/ { print $2 }' /proc/meminfo 2>/dev/null || true)"
    if [ -n "$avail_kb" ]; then
        by_mem=$(( avail_kb / (768 * 1024) ))
        [ "$by_mem" -ge 1 ] || by_mem=1
        [ "$by_mem" -lt "$jobs" ] && jobs="$by_mem"
    fi
    jobs=$(( jobs / 2 ))
    [ "$jobs" -ge 1 ] || jobs=1
    echo "$jobs"
}

alive() { [ -n "${1:-}" ] && kill -0 "$1" 2>/dev/null; }

# poolLock / poolUnlock — a mkdir lock; a lock whose owner is dead is broken.
poolLock() {
    mkdir -p "$pool"
    until mkdir "$pool/lock" 2>/dev/null; do
        local owner
        owner="$(cat "$pool/lock/pid" 2>/dev/null || true)"
        if [ -n "$owner" ] && ! alive "$owner"; then rm -rf "$pool/lock"; continue; fi
        sleep 0.1
    done
    echo "$BASHPID" >"$pool/lock/pid"
}
poolUnlock() { rm -rf "$pool/lock"; }

# leaseField <file> <key>
leaseField() { sed -n "s/^$2=//p" "$1" | head -1; }

# poolReap — drop the leases and waits whose owner and child are dead (under the lock).
poolReap() {
    local f
    for f in "$pool"/lease.* "$pool"/wait.*; do
        [ -e "$f" ] || continue
        if ! alive "$(leaseField "$f" owner)" && ! alive "$(leaseField "$f" child)"; then rm -f "$f"; fi
    done
}

# poolUsed — the jobs the live leases hold (under the lock, after poolReap).
poolUsed() {
    local f n=0
    for f in "$pool"/lease.*; do
        [ -e "$f" ] || continue
        n=$(( n + $(leaseField "$f" jobs) ))
    done
    echo "$n"
}

POOL_STAGGER=60

# poolOlderWaiter <id> — true when another live gate waits since before <id> (or <id> has not waited yet and
# another waits at all).
poolOlderWaiter() {
    local me="$pool/wait.$1" mine f t
    mine="$(leaseField "$me" start 2>/dev/null)"
    [ -n "$mine" ] || mine="$(date +%s)"
    for f in "$pool"/wait.*; do
        [ -e "$f" ] && [ "$f" != "$me" ] || continue
        alive "$(leaseField "$f" owner)" || continue
        t="$(leaseField "$f" start)"
        if [ "$t" -lt "$mine" ] || { [ "$t" -eq "$mine" ] && [ ! -e "$me" ]; } || { [ "$t" -eq "$mine" ] && [[ "$f" < "$me" ]]; }; then
            return 0
        fi
    done
    return 1
}

# poolAcquire <id> <name> <want> <log> — blocks until a job is free; prints the
# jobs granted (min(want, free)) and leaves lease.<id>.
poolAcquire() {
    local id="$1" name="$2" want="$3" log="$4" cap used free grant waited=0 last
    while :; do
        poolLock
        poolReap
        # The capacity is read on every pass: it follows MemAvailable, and one read when the wait began would
        # hold a gate that started under memory pressure to that low capacity for good.
        cap="$(poolCapacity)"
        used="$(poolUsed)"
        free=$(( cap - used ))
        # Admissions are staggered (the maintainer, 2026-10-13: "libera o gate paralelo aos poucos"): a gate
        # starts only when the last one started at least POOL_STAGGER seconds ago, or nothing runs, so the
        # builds' memory peaks never coincide.
        last="$(cat "$pool/last_admit" 2>/dev/null || echo 0)"
        if [ "$used" -gt 0 ] && [ $(( $(date +%s) - last )) -lt "$POOL_STAGGER" ]; then free=0; fi
        # A gate that asks for the whole pool (botopink-lang's, which sizes itself to the machine, run by a commit
        # hook under `exec --jobs <capacity>`) starts only on an empty pool and then holds all of it.
        if [ "$want" -ge "$cap" ] && [ "$used" -gt 0 ]; then free=0; fi
        # First come, first served: a gate is admitted only when no live gate has waited longer, so a thread
        # running commands back to back never starves one that waits.
        if [ "$free" -ge 1 ] && poolOlderWaiter "$id"; then free=0; fi
        if [ "$free" -ge 1 ]; then
            date +%s >"$pool/last_admit"
            grant="$want"; [ "$grant" -le "$free" ] || grant="$free"
            [ "$grant" -le "$cap" ] || grant="$cap"
            rm -f "$pool/wait.$id"
            printf 'owner=%s\nchild=\njobs=%s\nname=%s\nstart=%s\nlog=%s\n' "$$" "$grant" "$name" "$(date +%s)" "$log" >"$pool/lease.$id"
            poolUnlock
            echo "$grant"
            return 0
        fi
        if [ "$waited" -eq 0 ]; then
            printf 'owner=%s\nchild=\njobs=0\nname=%s\nstart=%s\nlog=%s\n' "$$" "$name" "$(date +%s)" "$log" >"$pool/wait.$id"
            waited=1
        fi
        poolUnlock
        sleep 2
    done
}

# poolSetChild <id> <pid>
poolSetChild() {
    poolLock
    if [ -f "$pool/lease.$1" ]; then
        sed "s/^child=.*/child=$2/" "$pool/lease.$1" >"$pool/lease.$1.tmp" && mv "$pool/lease.$1.tmp" "$pool/lease.$1"
    fi
    poolUnlock
}

poolRelease() {
    rm -f "$pool/lease.$1" "$pool/wait.$1"
}

# ── finding the repositories and the tasks ───────────────────────────────────

# findTasks — `<name>\t<task root>` for every task, once, from `git worktree
# list` of the meta repository and of each submodule of the main checkout.
findTasks() {
    local main sub path name
    main="$(mainRoot)"
    {
        git -C "$main" worktree list --porcelain | sed -n 's/^worktree //p'
        for sub in $(git -C "$main" config --file .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{ print $2 }'); do
            [ -e "$main/$sub/.git" ] || continue
            git -C "$main/$sub" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p'
        done
    } | while IFS= read -r path; do
        case "$path" in
            "$main"/.tasks/*)
                name="${path#"$main"/.tasks/}"; name="${name%%/*}"
                [ -n "$name" ] && printf '%s\t%s\n' "$name" "$main/.tasks/$name" ;;
        esac
    done | sort -u
}

# taskOwnRepos <name> <task root> — the repositories of the task on its branch
# `front/<name>`; a symlink or a checkout on any other branch is a linked sibling.
taskOwnRepos() {
    local name="$1" troot="$2" d
    for d in "$troot"/repository/*; do
        [ -d "$d" ] && [ ! -L "$d" ] || continue
        [ -e "$d/.git" ] || continue
        [ "$(git -C "$d" branch --show-current 2>/dev/null)" = "front/$name" ] && basename "$d"
    done
}

# ── running gates ────────────────────────────────────────────────────────────

logDir() { # <task root or "">
    local d
    if [ -n "$1" ]; then d="$1/.gate-logs"; else d="$(mainRoot)/.tasks/.gate-logs"; fi
    mkdir -p "$d"
    echo "$d"
}

# plan lines: `<display name>\t<repository dir>\t<kind: lang|lib>\t<log dir>\t<bin>`
plan=()
addRepo() { # <name> <repository dir> <log dir> <bin or "">
    local kind=lib
    [ "$(basename "$2")" != "botopink-lang" ] || kind=lang
    [ -x "$2/scripts/gate.sh" ] || { echo -e "${RED}✗ $1: $2 has no scripts/gate.sh${NC}" >&2; return 1; }
    plan+=("$1"$'\t'"$2"$'\t'"$kind"$'\t'"$3"$'\t'"$4")
}

# resolveTarget <target> — add the gates the target names to the plan.
resolveTarget() {
    local t="$1" name troot own r found=0
    if [ "${t#task:}" = "$t" ] && [ -x "$root/repository/$t/scripts/gate.sh" ]; then
        addRepo "$t" "$root/repository/$t" "$(logDir "")" "" || return 1
        return 0
    fi
    name="${t#task:}"
    while IFS=$'\t' read -r n tr <&3; do
        [ "$n" = "$name" ] || continue
        found=1; troot="$tr"
    done 3< <(findTasks)
    [ "$found" -eq 1 ] || { echo -e "${RED}✗ '$t' is no repository of this checkout and no open task${NC}" >&2; return 1; }
    own="$(taskOwnRepos "$name" "$troot")"
    [ -n "$own" ] || { echo -e "${RED}✗ task $name owns no repository (none is on front/$name)${NC}" >&2; return 1; }
    for r in $own; do
        addRepo "$name:$r" "$troot/repository/$r" "$(logDir "$troot")" "" || return 1
    done
}

# runPlan <extra gate args…> — start every gate of the plan, each when the pool
# admits it, wait for all, print the report, return 1 if any is red.
runPlan() {
    local extra=("$@") n="${#plan[@]}" cap share line i=0 pids=() names=() logs=() rcs_dir
    [ "$n" -gt 0 ] || { echo "gate: nothing to run"; return 1; }
    cap="$(poolCapacity)"
    share=$(( cap / n )); [ "$share" -ge 1 ] || share=1
    rcs_dir="$(mktemp -d)"
    echo "gate: pool $pool — capacity $cap job(s), $n gate(s), share $share"
    for line in "${plan[@]}"; do
        local name dir kind ldir bin log id
        IFS=$'\t' read -r name dir kind ldir bin <<<"$line"
        log="$ldir/$(echo "$name" | tr ':/' '__').$(date +%Y%m%d-%H%M%S).log"
        names+=("$name"); logs+=("$log")
        id="$$.$i"
        (
            want="$share"; [ "$kind" != "lang" ] || want="$cap"
            grant="$(poolAcquire "$id" "$name" "$want" "$log")"
            trap 'poolRelease "$id"' EXIT
            start=$SECONDS
            args=("${extra[@]}")
            [ "$kind" != "lib" ] || args=(--jobs "$grant" "${extra[@]}")
            (
                cd "$dir"
                if [ -n "$bin" ]; then export BOTOPINK_BIN="$bin"; fi
                exec scripts/gate.sh "${args[@]}"
            ) >"$log" 2>&1 </dev/null &
            child=$!
            poolSetChild "$id" "$child"
            rc=0; wait "$child" || rc=$?
            echo "$rc $((SECONDS - start))" >"$rcs_dir/$i"
        ) &
        pids+=("$!")
        i=$((i + 1))
    done
    for i in "${!pids[@]}"; do wait "${pids[$i]}" || true; done
    local red=0 rc secs
    for i in "${!names[@]}"; do
        read -r rc secs <"$rcs_dir/$i" 2>/dev/null || { rc=1; secs=0; }
        if [ "$rc" = 0 ]; then
            echo -e "${GREEN}✓ ${names[$i]}${NC} (${secs}s) — ${logs[$i]}"
        else
            echo -e "${RED}✗ ${names[$i]}${NC} (${secs}s, exit $rc) — ${logs[$i]}"
            sed -E "s/$(printf '\033')\[[0-9;]*m//g" "${logs[$i]}" | tail -n 15 | sed 's/^/      /'
            red=1
        fi
    done
    rm -rf "$rcs_dir"
    [ "$red" -eq 0 ]
}

cmdStatus() {
    local f any=0 now name jobs start log stage
    now="$(date +%s)"
    echo "pool $pool — capacity $(poolCapacity) job(s)"
    for f in "$pool"/lease.* "$pool"/wait.*; do
        [ -e "$f" ] || continue
        alive "$(leaseField "$f" owner)" || alive "$(leaseField "$f" child)" || continue
        any=1
        name="$(leaseField "$f" name)"; jobs="$(leaseField "$f" jobs)"; start="$(leaseField "$f" start)"; log="$(leaseField "$f" log)"
        stage=""
        if [ -f "$log" ]; then
            stage="$(sed -E "s/$(printf '\033')\[[0-9;]*m//g" "$log" | grep -E '^==> gate:|Testing |Building |Refusing |Checking ' | tail -1 | sed 's/^ *//' | cut -c1-80 || true)"
        fi
        case "$f" in
            */lease.*) printf 'running  %-28s %2s job(s)  %4ss  %s\n' "$name" "$jobs" "$((now - start))" "$stage" ;;
            *)         printf 'waiting  %-28s            %4ss\n' "$name" "$((now - start))" ;;
        esac
    done
    [ "$any" -eq 1 ] || echo "(no gate running or waiting)"
}

# cmdExec [--jobs <N>] <name> -- <command>… — run one command under the pool:
# wait for a free job, hold the jobs granted while it runs, return its status.
cmdExec() {
    local want="" name="" id grant rc=0 child
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --jobs) want="$2"; shift 2 ;;
            --) shift; break ;;
            *) [ -z "$name" ] || { echo "usage: scripts/gate.sh exec [--jobs <N>] <name> -- <command>…" >&2; return 1; }
               name="$1"; shift ;;
        esac
    done
    [ -n "$name" ] && [ "$#" -gt 0 ] || { echo "usage: scripts/gate.sh exec [--jobs <N>] <name> -- <command>…" >&2; return 1; }
    [ -n "$want" ] || { want=$(( $(poolCapacity) / 4 )); [ "$want" -ge 1 ] || want=1; }
    id="$$.exec"
    grant="$(poolAcquire "$id" "$name" "$want" "")"
    trap 'poolRelease "$id"' EXIT
    "$@" &
    child=$!
    poolSetChild "$id" "$child"
    wait "$child" || rc=$?
    poolRelease "$id"
    trap - EXIT
    return "$rc"
}

# ── commands ─────────────────────────────────────────────────────────────────

extra=()
parseExtra() { # sets targets[] and extra[] from "$@"
    targets=()
    local a
    for a in "$@"; do
        case "$a" in
            --no-conformance) extra+=("$a") ;;
            -*) echo "gate: unknown option '$a'" >&2; return 1 ;;
            *) targets+=("$a") ;;
        esac
    done
}

cmd="${1:-check}"
[ "$#" -eq 0 ] || shift
case "$cmd" in
    check) runChecks ;;
    run)
        parseExtra "$@"
        [ "${#targets[@]}" -gt 0 ] || { echo "usage: scripts/gate.sh run <repository|task> … [--no-conformance]" >&2; exit 1; }
        for t in "${targets[@]}"; do resolveTarget "$t"; done
        runPlan ${extra[@]+"${extra[@]}"} ;;
    tasks)
        parseExtra "$@"
        [ "${#targets[@]}" -eq 0 ] || { echo "usage: scripts/gate.sh tasks [--no-conformance]" >&2; exit 1; }
        any=0
        while IFS=$'\t' read -r name troot <&3; do
            own="$(taskOwnRepos "$name" "$troot")"
            [ -n "$own" ] || { echo "gate: task $name owns no repository — skipped"; continue; }
            for r in $own; do addRepo "$name:$r" "$troot/repository/$r" "$(logDir "$troot")" ""; any=1; done
        done 3< <(findTasks)
        [ "$any" -eq 1 ] || { echo "gate: no open task"; exit 0; }
        runPlan ${extra[@]+"${extra[@]}"} ;;
    libs)
        parseExtra "$@"
        [ "${#targets[@]}" -eq 0 ] || { echo "usage: scripts/gate.sh libs [--no-conformance]" >&2; exit 1; }
        bin="$(mainRoot)/repository/botopink-lang/zig-out/bin/botopink"
        [ -x "$bin" ] || { echo -e "${RED}✗ the main checkout's compiler is not built: $bin${NC}" >&2; exit 1; }
        ldir="$(logDir "")"
        for d in "$root"/repository/*/; do
            name="$(basename "$d")"
            case "$name" in botopink-lang|vscode-extension) continue ;; esac
            [ -x "$d/scripts/gate.sh" ] || continue
            addRepo "$name" "${d%/}" "$ldir" "$bin"
        done
        runPlan ${extra[@]+"${extra[@]}"} ;;
    status) cmdStatus ;;
    exec) cmdExec "$@" ;;
    -h|--help|help) sed -n '2,58p' "$0" ;;
    *) echo "gate: unknown command '$cmd' (check, run, tasks, libs, status, exec)" >&2; exit 1 ;;
esac
