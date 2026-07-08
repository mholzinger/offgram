# offgram configuration — copy this file to `config.py` and edit.
# `config.py` is gitignored so your personal paths/usernames never get committed.
# Environment variables OFFGRAM_COLLECTION / OFFGRAM_LOGIN / OFFGRAM_PORT override these.
#
# This file is PLAIN PYTHON. Keep only `NAME = "value"` lines and `#` comments —
# don't paste HTML/CSS or rich text here, or offgram will refuse to start.

# The archive root: a folder containing one subfolder per Instagram profile
# (as laid out by 4K Stogram and/or instaloader).
COLLECTION = "/path/to/your/instagram/archive"

# instaloader session username used by the in-app "update" buttons, or "" for none.
# (Instagram now 403s anonymous requests, so a login is effectively required.)
#
# Easiest way to log in — no password, no 2FA: start offgram, open ⚙ accounts,
# and import the session straight from a browser where you're already logged in.
#
# Or create a session with the instaloader CLI:  instaloader --login YOUR_USERNAME
# NOTE: with a pipx install that CLI lives inside offgram's venv, not on your
# PATH — call it as:  ~/.local/pipx/venvs/offgram/bin/instaloader --login YOUR_USERNAME
INSTALOADER_LOGIN = ""
