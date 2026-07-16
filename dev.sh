#!/usr/bin/env bash
# dev.sh — one-command development runner for offgram.
#
#   ./dev.sh          start against a throwaway archive on port 8079 (safe default)
#   ./dev.sh real     run the checkout's code against your real config.py collection
#
# First run bootstraps .venv with offgram installed EDITABLE (your edits apply on
# the next restart, no reinstall) and the instaloader engine installed editable
# from a local fork checkout when one exists (~/src/instaloader by default, or
# $OFFGRAM_FORK) — so the engine follows whatever branch that repo has checked out.
set -euo pipefail
cd "$(dirname "$0")"

VENV=.venv
FORK="${OFFGRAM_FORK:-$HOME/src/instaloader}"

if [ ! -d "$VENV" ]; then
    echo "▸ creating dev venv…"
    python3 -m venv "$VENV"
    "$VENV/bin/pip" install --quiet --upgrade pip
fi

if ! "$VENV/bin/pip" show --quiet offgram 2>/dev/null; then
    echo "▸ installing offgram into the venv (editable)…"
    "$VENV/bin/pip" install --quiet --no-deps -e .
fi

if ! "$VENV/bin/python" -c "import instaloader" 2>/dev/null; then
    if [ -d "$FORK" ]; then
        echo "▸ installing instaloader engine from local fork checkout (editable): $FORK"
        "$VENV/bin/pip" install --quiet -e "$FORK"
    else
        echo "▸ installing instaloader engine from the offgram-stable branch…"
        "$VENV/bin/pip" install --quiet "git+https://github.com/mholzinger/instaloader@offgram-stable"
    fi
fi

if [ -d "$FORK/.git" ]; then
    echo "▸ engine: local fork on branch '$(git -C "$FORK" branch --show-current)'"
fi

MODE="${1:-dev}"
case "$MODE" in
    dev)
        export OFFGRAM_COLLECTION="${OFFGRAM_COLLECTION:-/tmp/offgram-dev-archive}"
        export OFFGRAM_PORT="${OFFGRAM_PORT:-8079}"
        mkdir -p "$OFFGRAM_COLLECTION"
        echo "▸ DEV mode: archive $OFFGRAM_COLLECTION · port $OFFGRAM_PORT (real library untouched)"
        ;;
    real)
        echo "▸ REAL mode: checkout code against your configured collection"
        ;;
    *)
        echo "usage: ./dev.sh [dev|real]" >&2
        exit 2
        ;;
esac

exec "$VENV/bin/python" offgram.py
