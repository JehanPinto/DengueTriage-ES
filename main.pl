%  =====================================================================
%  main.pl  --  LOADER AND ENTRY POINT
%  Dengue Triage Expert System (DengueTriage-ES)
%
%  Run it with:      swipl main.pl
%  or on Windows:    run.bat
%  or headless:      swipl -g "tests:run_all" -t halt main.pl
%  =====================================================================

:- use_module(library(readutil)).

:- ensure_loaded('src/kb').
:- ensure_loaded('src/engine').
:- ensure_loaded('src/scenarios').
:- ensure_loaded('src/tests').
:- ensure_loaded('src/ui').

%  Convenience predicates available at the Prolog prompt. start/0 comes
%  in from ui. Loading this file does not start anything by itself, so
%  the same file serves the interactive session, the test run and the
%  batch run.
run_tests :- tests:run_all.
