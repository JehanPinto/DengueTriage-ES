# DengueTriage-ES

An expert system for the clinical triage of suspected dengue, written in SWI-Prolog.

Given a patient's clinical findings it returns three things:

1. the **WHO case classification** — dengue without warning signs, dengue with warning signs, or severe dengue;
2. the **WHO management group** — A (home care), B (in-hospital), or C (emergency treatment and urgent referral);
3. the **reasoning**, rule by rule, with the guideline page each rule was taken from.

Every rule in the knowledge base is transcribed from a published clinical guideline and carries a citation in the code itself. No rule was invented by the developer. See [`docs/SOURCES.md`](docs/SOURCES.md).

> **For teaching and assessment only.** This program is not a medical device and must not be used to treat a real patient.

---

## 1. Requirements

| | |
|---|---|
| Software | **SWI-Prolog 8.0 or later** (developed and tested on 10.0.2, x64) |
| Dependencies | none beyond the standard SWI-Prolog library |
| Operating system | Windows, macOS or Linux |
| Disk | under 1 MB |

## 2. Installing SWI-Prolog

**Windows** — either run

```
winget install --id SWI-Prolog.SWI-Prolog
```

or download the installer from <https://www.swi-prolog.org/Download.html> and accept the defaults.

**macOS**

```
brew install swi-prolog
```

**Debian / Ubuntu**

```
sudo apt install swi-prolog
```

Check the installation with `swipl --version`. If Windows reports that `swipl` is not recognised, close and reopen the Command Prompt so the new PATH takes effect; `run.bat` also finds SWI-Prolog in its default install folder without any PATH change.

## 3. Running the system

**Windows** — double-click **`run.bat`**, or from a Command Prompt in this folder:

```
run.bat
```

**macOS / Linux**

```
sh run.sh
```

**Any platform, directly**

```
swipl -g start -t halt main.pl
```

**From an interactive Prolog prompt**

```
swipl main.pl
?- start.
```

## 4. Running the tests

```
test.bat            (Windows)
sh run.sh test      (macOS / Linux)
swipl -g run_tests -t halt main.pl
```

The suite runs 12 forward-chaining scenarios, 8 backward-chaining goals and 12 explanation checks — 32 tests. The expected result is `12 passed, 0 failed`, `8 passed, 0 failed`, `12 passed, 0 failed`, and `every rule in the knowledge base carries a source: YES`. A saved run is in [`docs/test-output.txt`](docs/test-output.txt).

Menu option 7 runs the same suite from inside the program.

## 5. Using the interface

The program opens on a menu:

```
   1  New consultation  (forward chaining, data driven)
   2  New consultation  (backward chaining, goal driven)
   3  Run a built-in scenario
   4  Show the reasoning trace of the last consultation
   5  Explain a conclusion  (HOW was it reached?)
   6  Browse the knowledge base
   7  Run the automated test suite
   8  Help
   0  Quit
```

**Option 1 — forward chaining.** The system asks every question, grouped into eight sections, then lets the data drive the rules forward to every conclusion they support. Answer `y` or `n`; pressing Enter alone means no; typing `s` skips the rest of a section and takes every remaining answer in it as no.

**Option 2 — backward chaining.** You pick a hypothesis, such as *does this patient have severe dengue?*, and the system asks only the questions it needs to settle it — typically five or six instead of forty-two. Typing `w` at any question makes it explain **why** it is asking, by printing the chain of goals it is currently pursuing.

**Option 3 — built-in scenarios.** Twelve prepared cases, `t01` to `t12`, run instantly without typing answers. This is the quickest way to see the system work.

**Option 5 — explanation.** Prints the proof tree for any conclusion, with the guideline citation at each step.

### Worked example

Choose `3`, then `t04`:

```
  Step 2   rule r03
    IF    a pulse pressure of 20 mmHg or less
    THEN  shock
    src   [WHO2009] s.2.1.4, p.28 -- "The patient is considered to have shock
          if the pulse pressure ... is <= 20 mm Hg"
```

and the system concludes:

```
  Case classification : SEVERE DENGUE
  Management group    : GROUP C -- requires emergency treatment and urgent referral
```

Full saved transcripts are in [`docs/`](docs/):

| File | What it shows |
|---|---|
| `transcript-forward.txt` | forward-chaining run of scenario t04 (severe dengue) plus a proof tree |
| `transcript-groupa.txt` | forward-chaining run of scenario t01 (Group A, home care) |
| `transcript-backward.txt` | backward-chaining run including the WHY explanation |
| `test-output.txt` | the full automated test run |
| `kb-listing.txt` | all 35 rules printed with their sources |
| `DengueTriage-ES-Report.pdf` | the assignment report |
| `report.html` / `report.built.html` | the report source, and the built version the PDF was rendered from |

### Rebuilding the report

The cover page has blanks for the student name, index number and module. After
filling them in (edit `docs/report.html`), regenerate the PDF with:

```
python tools/build-report.py
```

The script asks the expert system to print its own rule, fact and question tables,
splices them together with the inference-engine source and the saved transcripts into
`docs/report.html`, and renders the result to PDF with headless Chrome or Edge. The
annex tables therefore cannot drift out of step with the code. It needs SWI-Prolog,
Python 3.8 or later, and Chrome or Edge; if no browser is found it stops after
building the HTML and tells you to print it yourself.

## 6. Files

```
main.pl                 loader; defines start/0 and run_tests/0
run.bat  test.bat       Windows launchers
run.sh                  macOS / Linux launcher
src/kb.pl               KNOWLEDGE BASE  - 25 static facts, 42 askable facts,
                                          35 rules, each with its citation
src/engine.pl           INFERENCE ENGINE - working memory, stratified forward
                                          chainer, backward chainer, WHY and
                                          HOW explanation facility
src/ui.pl               USER INTERFACE  - the menu-driven console
src/scenarios.pl        12 test scenarios, shared by the UI and the tests
src/tests.pl            the automated test suite
docs/SOURCES.md         full bibliography and rule-to-source table
docs/*.txt              saved transcripts and test output
```

The knowledge base is completely separate from the inference engine: `engine.pl` contains no clinical knowledge, and `kb.pl` contains no control logic. The knowledge base can be replaced with a different domain without touching the engine.

## 7. How the inference works

**Forward chaining** is data driven. All observations are asserted into working memory, then the engine runs to a fixpoint. The knowledge base is *stratified*: each rule declares a layer, and every negated premise refers only to a strictly lower layer, so the engine saturates layer 1 completely, then layer 2, and so on. This makes the fixpoint unique and independent of the order the rules happen to be written in — without it, a rule such as "dengue **without** warning signs" could fire before the warning-sign rules had run.

**Backward chaining** is goal driven. `prove/2` works from a hypothesis back towards the observations, asking the user only for what it needs, and returns a proof tree. Counting premises stop as soon as enough members are found, so the system never asks for a sixth criterion once the second has been confirmed.

Both modes use the same `rule/4` clauses in `kb.pl`.

## 8. Licence and attribution

Clinical content is quoted from the World Health Organization guideline cited in `docs/SOURCES.md`, which is published for public health use. The code is submitted as university coursework.
