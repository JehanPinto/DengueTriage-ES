#!/usr/bin/env python3
"""
Rebuild docs/DengueTriage-ES-Report.pdf from docs/report.html.

Run this after editing the report, for example to fill in the student name
and index number on the cover page.

    python tools/build-report.py

It does three things:
  1. asks the expert system itself to print its rules, facts and questions
     as HTML table rows, so the annex tables can never drift from the code;
  2. splices those rows, the inference-engine source and the saved session
     transcripts into docs/report.html;
  3. renders the result to PDF with headless Chrome or Edge.

Requires: SWI-Prolog, Python 3.8+, and Chrome or Edge. No Python packages.
"""

import html
import pathlib
import re
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
GEN = ROOT / "tools" / "_gen"
PDF = DOCS / "DengueTriage-ES-Report.pdf"


def find(name, candidates):
    found = shutil.which(name)
    if found:
        return found
    for c in candidates:
        if pathlib.Path(c).exists():
            return c
    return None


SWIPL = find("swipl", [
    r"C:\Program Files\swipl\bin\swipl.exe",
    r"C:\Program Files (x86)\swipl\bin\swipl.exe",
])

BROWSER = find("chrome", [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
])


def read(p):
    return pathlib.Path(p).read_text(encoding="utf-8", errors="replace")


def span(text, start_marker, end_marker):
    """The lines from the one containing start_marker up to (not including)
    the next line containing end_marker."""
    lines = text.splitlines()
    si = next(i for i, l in enumerate(lines) if start_marker in l)
    ei = next(i for i in range(si + 1, len(lines)) if end_marker in lines[i])
    return "\n".join(lines[si:ei]).rstrip()


def gen_tables():
    """Have the knowledge base print its own annex tables."""
    if not SWIPL:
        sys.exit("SWI-Prolog not found. Install it, or add swipl to PATH.")
    GEN.mkdir(parents=True, exist_ok=True)
    genpl = (ROOT / "tools" / "gen-tables.pl").as_posix()
    for goal, out in [("genannex", "rules.html"),
                      ("genfactshtml", "facts.html")]:
        with open(GEN / out, "w", encoding="utf-8") as fh:
            r = subprocess.run(
                [SWIPL, "-g", f"consult('{genpl}'),{goal}", "-t", "halt", "main.pl"],
                cwd=ROOT, stdout=fh, stderr=subprocess.PIPE, text=True)
        if r.returncode != 0:
            sys.exit(f"generating {out} failed:\n{r.stderr}")
        print(f"  generated {out}")


def strip_rule_lines(text):
    """Drop a trailing '%  -----' separator line left at the end of a span."""
    lines = text.rstrip().splitlines()
    while lines and set(lines[-1].strip()) <= set("%- "):
        lines.pop()
    return "\n".join(lines)


def build_html():
    engine = read(ROOT / "src" / "engine.pl")
    kb = read(ROOT / "src" / "kb.pl")
    esc = lambda s: html.escape(s, quote=False)

    repl = {
        "<!--RULES_ROWS-->":    read(GEN / "rules.html"),
        "<!--FACTS_ROWS-->":    read(GEN / "facts.html"),
        "<!--CODE_RULES-->":    esc(strip_rule_lines(
            span(kb, "%  SECTION 4 -- PRODUCTION RULES", "%  SECTION 5 -- ADVICE"))),
        "<!--CODE_FORWARD-->":  esc(strip_rule_lines(
            span(engine, "forward_chain :- forward_chain(silent).", "%  --- premise evaluation"))),
        "<!--CODE_PREMISE-->":  esc(strip_rule_lines(
            span(engine, "%  --- premise evaluation", "%  3. BACKWARD CHAINING"))),
        "<!--CODE_BACKWARD-->": esc(strip_rule_lines(
            span(engine, "prove(Goal, Proof) :-", "%  --- asking the user"))),
    }

    doc = read(DOCS / "report.html")
    missing = [k for k in repl if k not in doc]
    if missing:
        sys.exit(f"report.html is missing placeholders: {missing}")
    for k, v in repl.items():
        doc = doc.replace(k, v)

    out = DOCS / "report.built.html"
    out.write_text(doc, encoding="utf-8")
    print(f"  built {out.name} ({len(doc):,} chars)")
    return out


def to_pdf(src):
    if not BROWSER:
        print("\n  Chrome or Edge not found, so the PDF was not rendered.")
        print(f"  Open {src} in a browser and print to PDF (A4, no margins,")
        print("  background graphics on).")
        return
    r = subprocess.run([
        BROWSER, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
        f"--print-to-pdf={PDF}", src.as_uri(),
    ], capture_output=True, text=True)
    if PDF.exists():
        print(f"  rendered {PDF.name} ({PDF.stat().st_size:,} bytes)")
    else:
        sys.exit(f"PDF rendering failed:\n{r.stderr}")


if __name__ == "__main__":
    print("Rebuilding the report")
    gen_tables()
    to_pdf(build_html())
    print("Done.")
