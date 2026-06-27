# offgram configuration — copy this file to `config.py` and edit.
# `config.py` is gitignored so your personal paths/usernames never get committed.
# Environment variables OFFGRAM_COLLECTION / OFFGRAM_LOGIN / OFFGRAM_PORT override these.

# The archive root: a folder containing one subfolder per Instagram profile
# (as laid out by 4K Stogram and/or instaloader).
COLLECTION = "/path/to/your/instagram/archive"

# instaloader session username used by the in-app "update" buttons, or "" for none.
# Create the session once with:  instaloader --login YOUR_USERNAME
# (Instagram now 403s anonymous requests, so a login is effectively required.)
INSTALOADER_LOGIN = ""
