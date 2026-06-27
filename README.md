# offgram

**An offline web gallery for your instaloader archive.**

[instaloader](https://github.com/instaloader/instaloader) downloads Instagram posts, reels, stories, and highlights to disk. offgram is the other half: it turns that pile of dated files into a fast, browsable local gallery — per profile, with captions, in-browser video, and original-post links — and gives you buttons to pull updates with instaloader. It's for archivists who already have an instaloader collection and want to actually *look* at it.

It's a single dependency-free Python file (standard library only). The archive can live anywhere — local disk or a network share — and offgram scans it **once** into a local cache, so the UI stays instant.

## Features

- Browse by profile, with **posts / reels / stories / highlights / tagged** sections
- Lightbox with keyboard navigation and **in-browser video scrubbing** (HTTP Range)
- **Captions + original-post links** from instaloader's `.txt` / `.json.xz` sidecars
- Generates video poster frames with ffmpeg on demand (cached locally)
- Per-profile and **"Update all"** buttons that run instaloader, with live progress — updates are **incremental** (`--latest-stamps`), never full re-downloads
- **Heartbeat** ("♥ Check all"): pings Instagram via your session and marks each profile **alive / private / gone / renamed** with a colored dot. Throttled and on-demand only. Rename detection uses the account's numeric user-id (parsed from filenames), so it survives username changes
- Local cache (`~/.cache/offgram/`) — the archive is read only on first scan and when loading media, never to render a page

## Requires the patched instaloader fork

Stock instaloader `4.15.1` is **broken against current Instagram** (retired `doc_id` / GraphQL changes), and Instagram now returns `403` to anonymous requests. offgram therefore depends on a fork carrying the unmerged fixes, and needs a logged-in session:

```
instaloader @ git+https://github.com/mholzinger/instaloader@fix-profile-metadata-web-profile-info
```

## Install

**As a command (recommended):**

```bash
pipx install git+https://github.com/mholzinger/offgram
brew install ffmpeg          # optional, for video poster frames
```

This pulls in the patched instaloader fork automatically and gives you an
`offgram` command.

**Or from a checkout (for development):**

```bash
git clone https://github.com/mholzinger/offgram && cd offgram
python3 -m venv .venv && source .venv/bin/activate
pip install -e .
```

## Configure

Create `~/.config/offgram/config.py` (copy from [`config.example.py`](config.example.py)):

```python
COLLECTION = "/path/to/your/instagram/archive"   # folder of per-profile subfolders
INSTALOADER_LOGIN = "your_ig_username"           # session for the update buttons, or ""
```

Env vars `OFFGRAM_COLLECTION`, `OFFGRAM_LOGIN`, `OFFGRAM_PORT` take priority. A
repo checkout also works without extra setup — offgram looks for `config.py` next
to the script and in the current directory.

Create the instaloader session the update buttons use (one time):

```bash
instaloader --login YOUR_USERNAME
```

## Run

```bash
offgram                    # if pipx-installed
# or:  python3 offgram.py  # from a checkout
# then open http://localhost:8077
```

First launch scans the collection in the background (slow once over SMB; cached
forever after). Hit **⟳ rescan** after large changes; per-profile **↻ update**
auto-rescans that profile when instaloader finishes.

## The local cache

offgram scans the archive **once** in a background thread and writes the file
listing to `~/.cache/offgram/index.json` on local disk. Every page renders from
that in-memory index, so browsing never re-walks the archive — which keeps it
instant even when the files live on a network share. Media (full images, video
streams, thumbnails) is fetched lazily, only when actually viewed.

## Notes

- offgram never writes to the archive itself — only instaloader does, via the update buttons. If offgram breaks, your folders are untouched and browsable in Finder.
- Runs on `127.0.0.1` only (single-user, local). It is not hardened for exposure to a network.

---

### Footnote: legacy 4K Stogram archives

offgram grew out of a [4K Stogram](https://www.4kdownload.com/products/stogram) collection, and still reads one if it happens to find it — captions and original-post URLs from a `.stogram.sqlite` in the archive root, and thumbnails from `.thumb.stogram/` folders. This is **optional legacy support**: 4K Stogram is effectively abandoned (chronic account lockouts), and a pure instaloader archive never touches any of it. If you have an old 4K Stogram export, offgram will quietly surface its captions and thumbnails; if you don't, you'll never know the code is there.
