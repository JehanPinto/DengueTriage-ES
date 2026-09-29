#!/bin/sh
# =====================================================================
#  DengueTriage-ES  --  launcher for macOS and Linux
#  Usage:  sh run.sh          start the expert system
#          sh run.sh test     run the automated test suite
# =====================================================================
cd "$(dirname "$0")" || exit 1

if ! command -v swipl >/dev/null 2>&1; then
  echo
  echo "  SWI-Prolog was not found."
  echo "  Install it with one of:"
  echo "      sudo apt install swi-prolog      (Debian / Ubuntu)"
  echo "      brew install swi-prolog          (macOS)"
  echo "  or from https://www.swi-prolog.org/Download.html"
  echo
  exit 1
fi

if [ "$1" = "test" ]; then
  exec swipl -g run_tests -t halt main.pl
else
  exec swipl -g start -t halt main.pl
fi
