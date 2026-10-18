#!/usr/bin/env python3
"""Tests of decision-cells.py: one green case and one red case per reason of check 7, in throwaway trees,
plus the classification and the scaffold / promote round trip.

Usage: scripts/decision-cells-test.py
"""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
SCRIPT = Path(__file__).resolve().parent / "decision-cells.py"
LEDGER = """Generated from x.

## Language

| # | Id | Rule in force | Binds | Cell |
|---|---|---|---|---|
| 10 | a-1 | **Code rule ten.** Body text. | 144 | code_rule_ten |
| 11 | a-2 | **Replaced by 10.** | 144 | |
| 12 | a-3 (process) | **A process rule.** Body. | 163 | |
| 13 | a-4 | **Another code rule.** `x \\| y` | 144 | another_code_rule |
| 14 | a-5 | **Overtaken by 10 and 13** (a note). | 144 | |
| 15 | a-6 | **A rule with no slug yet.** | 144 | |
"""
D = "—"
T10 = f"Decision 10 {D} Code rule ten."
T13 = f"Decision 13 {D} Another code rule."
S = {10: "code_rule_ten", 13: "another_code_rule"}


class Cells(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.repo = self.root / "repository" / "snap"
        (self.repo / "conformance" / "modules").mkdir(parents=True)
        (self.repo / "decisions-taken.md").write_text(LEDGER)
        (self.repo / "conformance/modules/botopink.json").write_text(
            '{ "name": "conformance", "targets": ["commonJS", "erlang"], "workspaces": ["*"] }\n')
        self.d = self.repo / "conformance/modules/decisions-taken"

    def tearDown(self):
        self.tmp.cleanup()

    def run_cmd(self, *a):
        r = subprocess.run([sys.executable, str(SCRIPT), "--root", str(self.root), *a], capture_output=True, text=True)
        return r.returncode, r.stdout + r.stderr

    def cell(self, n, title, promoted=False):
        c = self.d / (f"{S[n]}-{n}" if n in S else f"slug_{n}-{n}")
        (c / "src" if promoted else c).mkdir(parents=True)
        inc = "src/main.bp" if promoted else "main.bp"
        (c / "docs.md").write_text(f"# {title}\n\nprose\n\n{{{inc}}}\n")
        (c / inc).write_text(f"//// {title}\npub fn main() -> void {{}}\n")
        if promoted:
            (c / "botopink.json").write_text(json.dumps({"name": c.name}))
        return c

    def slug_on(self, n, slug):
        lines = (self.repo / "decisions-taken.md").read_text().split("\n")
        lines = [ln[:-1] + slug + " |" if ln.startswith(f"| {n} |") else ln for ln in lines]
        (self.repo / "decisions-taken.md").write_text("\n".join(lines))

    def assertRed(self, text):
        code, out = self.run_cmd("check")
        self.assertEqual(code, 1, out)
        self.assertIn(text, out)
        self.assertIn("front 166", out)

    def test_green_empty(self):
        self.assertEqual(self.run_cmd("check"), (0, "decision-cells: green\n"))

    def test_green_phase1_and_promoted(self):
        self.cell(10, T10)
        self.cell(13, T13, promoted=True)
        self.assertEqual(self.run_cmd("check"), (0, "decision-cells: green\n"))

    def test_unknown_row(self):
        self.cell(99, f"Decision 99 {D} x")
        self.assertRed("snap: directory slug_99-99: directory name is <slug>-<N> with N naming no row")

    def test_one_liner_row(self):
        self.slug_on(11, "slug_11")
        self.cell(11, f"Decision 11 {D} Replaced by 10.")
        self.assertRed("snap: decision 11: row is a one-liner")

    def test_overtaken_one_liner_with_note(self):
        self.slug_on(14, "slug_14")
        self.cell(14, f"Decision 14 {D} Overtaken by 10 and 13")
        self.assertRed("decision 14: row is a one-liner")

    def test_process_row(self):
        self.slug_on(12, "slug_12")
        self.cell(12, f"Decision 12 {D} A process rule.")
        self.assertRed("decision 12: row is tagged process")

    def test_wrong_slug(self):
        self.cell(10, T10)
        (self.d / "code_rule_ten-10").rename(self.d / "other_name-10")
        self.assertRed("directory other_name-10: directory slug differs from the row's (code_rule_ten)")

    def test_docs_first_line(self):
        c = self.cell(10, T10)
        (c / "docs.md").write_text("# wrong\n\n{main.bp}\n")
        self.assertRed("decision 10: docs.md first line is not the row's")

    def test_no_include(self):
        c = self.cell(10, T10)
        (c / "docs.md").write_text(f"# {T10}\n\nprose\n")
        self.assertRed("docs.md has no {path} include line")

    def test_include_missing_file(self):
        c = self.cell(10, T10)
        (c / "docs.md").write_text(f"# {T10}\n\n{{other.bp}}\n")
        self.assertRed("docs.md includes {other.bp}, which does not exist")

    def test_fenced_code(self):
        c = self.cell(10, T10)
        (c / "docs.md").write_text(f"# {T10}\n\n```bp\nx\n```\n\n{{main.bp}}\n")
        self.assertRed("docs.md contains a fenced code block")

    def test_no_docs(self):
        c = self.cell(10, T10)
        (c / "docs.md").unlink()
        self.assertRed("decision 10: no docs.md")

    def test_no_program(self):
        c = self.cell(10, T10)
        (c / "main.bp").unlink()
        (c / "docs.md").write_text(f"# {T10}\n\n{{docs.md}}\n")
        self.assertRed("decision 10: no main.bp")

    def test_header(self):
        c = self.cell(10, T10)
        (c / "main.bp").write_text("//// stale\n")
        self.assertRed("main.bp header is not the row's")

    def test_promoted_without_manifest(self):
        c = self.cell(13, T13, promoted=True)
        (c / "botopink.json").unlink()
        (c / "src").rename(c / "src2")
        (c / "src2").rename(c / "src")
        self.assertRed("decision 13: promoted cell has no botopink.json")

    def test_targets_not_subset(self):
        c = self.cell(13, T13, promoted=True)
        (c / "botopink.json").write_text('{"name": "another_code_rule-13", "targets": ["wasm"]}')
        self.assertRed("targets ['wasm'] are not the workspace's")

    def test_phase1_with_src(self):
        c = self.cell(10, T10)
        (c / "src").mkdir()
        self.assertRed("phase 1 cell has a manifest or src/")

    def test_completeness(self):
        code, out = self.run_cmd("check")
        self.assertEqual(code, 0)
        sys.path.insert(0, str(SCRIPT.parent))
        import importlib.util
        spec = importlib.util.spec_from_file_location("dc", SCRIPT)
        dc = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(dc)
        dc.COMPLETE_REPOS.append("snap")
        reasons = dc.check_repo(self.root, "snap")
        self.assertEqual(sorted(r.split(": decision ")[1].split(":")[0] for r in reasons), ["10", "13", "15"])
        self.assertIn("code-bearing row has no conformance/modules/decisions-taken/code_rule_ten-10 directory", reasons[0])
        self.assertIn("decision 15: code-bearing row has no slug", reasons[2])
        self.assertIn("front 166", reasons[0])

    def test_scaffold_list_and_write(self):
        code, out = self.run_cmd("scaffold", "--list", "snap")
        self.assertEqual(code, 0)
        self.assertIn("snap: 6 rows, 2 one-liners, 1 tagged process, 3 to scaffold", out)
        self.assertFalse(self.d.exists())
        self.assertEqual(self.run_cmd("scaffold", "snap")[0], 0)
        self.assertEqual(sorted(p.name for p in self.d.iterdir()), ["another_code_rule-13", "code_rule_ten-10"])
        self.assertEqual((self.d / "code_rule_ten-10/docs.md").read_text(), f"# {T10}\n\n{{main.bp}}\n")
        self.assertEqual(self.run_cmd("check"), (0, "decision-cells: green\n"))

    def test_scaffold_rewrites_changed_lead(self):
        self.run_cmd("scaffold", "snap")
        (self.repo / "decisions-taken.md").write_text(LEDGER.replace("Code rule ten.", "Renamed rule."))
        self.run_cmd("scaffold", "snap")
        self.assertEqual((self.d / "code_rule_ten-10/docs.md").read_text().split("\n")[0], f"# Decision 10 {D} Renamed rule.")
        self.assertEqual((self.d / "code_rule_ten-10/main.bp").read_text().split("\n")[0], f"//// Decision 10 {D} Renamed rule.")

    def test_promote(self):
        self.run_cmd("scaffold", "snap")
        self.assertEqual(self.run_cmd("promote", "snap")[0], 0)
        self.assertTrue((self.d / "code_rule_ten-10/src/main.bp").is_file())
        self.assertEqual(json.loads((self.d / "code_rule_ten-10/botopink.json").read_text()), {"name": "code_rule_ten-10"})
        self.assertIn("{src/main.bp}", (self.d / "code_rule_ten-10/docs.md").read_text())
        self.assertIn('"decisions-taken/*"', (self.repo / "conformance/modules/botopink.json").read_text())
        self.assertEqual(self.run_cmd("check"), (0, "decision-cells: green\n"))


if __name__ == "__main__":
    unittest.main()
