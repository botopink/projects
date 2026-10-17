#!/usr/bin/env python3
"""Tests of land-check.py: one green case and one red case per reason, each in a throwaway git repo.

Usage: scripts/land-check-test.py
"""
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent / "land-check.py"
PT, EN = "specs/m/decisoes-pendentes.md", "specs/m/decisions-pending.md"
BLOCK = "#### A-1 · q\n```bp\nval x = 1;\n```\n"


def git(repo, *a):
    subprocess.run(["git", "-C", str(repo), "-c", "user.name=t", "-c", "user.email=t@t", *a],
                   check=True, capture_output=True)


class LandCheck(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name)
        git(self.repo, "init", "-q", "-b", "feat")
        self.write(EN, BLOCK)
        self.write(PT, BLOCK)
        self.commit("base")
        git(self.repo, "update-ref", "refs/remotes/origin/feat", "HEAD")
        git(self.repo, "checkout", "-q", "-b", "work")

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, rel, text):
        p = self.repo / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)

    def commit(self, msg="c"):
        git(self.repo, "add", "-A", "-f")
        git(self.repo, "commit", "-q", "-m", msg)

    def run_check(self):
        r = subprocess.run([sys.executable, str(SCRIPT), str(self.repo), "work"], capture_output=True, text=True)
        return r.returncode, r.stdout

    def assertRed(self, reason):
        code, out = self.run_check()
        self.assertEqual(code, 1, out)
        self.assertIn(reason + ":", out)

    def test_green(self):
        self.write("specs/m/ok.md", "plain text\n")
        self.commit()
        self.assertEqual(self.run_check(), (0, "land-check: green\n"))

    def test_not_fast_forward(self):
        git(self.repo, "checkout", "-q", "feat")
        self.write("other.txt", "x")
        self.commit("moved")
        git(self.repo, "update-ref", "refs/remotes/origin/feat", "HEAD")
        git(self.repo, "checkout", "-q", "work")
        self.write("a.txt", "a")
        self.commit()
        self.assertRed("not-fast-forward")

    def test_forbidden_file(self):
        for name in ("a.snap.new", "b.snap.md.new", "todo.md"):
            with self.subTest(name):
                self.write(name, "x")
                self.commit()
                self.assertRed("forbidden-file")
                git(self.repo, "reset", "-q", "--hard", "HEAD~1")

    def test_scratch_ref(self):
        self.write("specs/m/n.md", "see .tasks/foo-1/patch\n")
        self.commit()
        self.assertRed("scratch-ref")

    def test_commit_hash(self):
        self.write("specs/m/n.md", "landed in 1a2b3c4d5e6f\n")
        self.commit()
        self.assertRed("commit-hash")

    def test_pair_code_differs(self):
        self.write(PT, BLOCK.replace("x = 1", "x = 2"))
        self.commit()
        self.assertRed("pair-differs")

    def test_pair_ids_differ(self):
        self.write(PT, BLOCK.replace("A-1", "A-2"))
        self.commit()
        self.assertRed("pair-differs")

    def test_snapshot_targets(self):
        self.write("lib/snapshot/targets/erlang/a.out", "x")
        self.commit()
        self.assertRed("snapshot-targets")


if __name__ == "__main__":
    unittest.main()
