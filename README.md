# offgram

**An offline web gallery for your instaloader archive.**

[instaloader](https://github.com/instaloader/instaloader) downloads Instagram posts, reels, stories, and highlights to disk. offgram is the other half: it turns that pile of dated files into a fast, browsable local gallery — per profile, with captions, in-browser video, and original-post links — and gives you buttons to pull updates, add new profiles, and check account health. It's for archivists who already have an instaloader collection and want to actually *look* at it (and keep it current).

It's a single dependency-free Python file (standard library only). The archive can live anywhere — local disk or a network share — and offgram scans it **once** into a local cache, so the UI stays instant.

## Features

**Browse**
- By profile, with **posts / reels / stories / highlights / tagged** section tabs
- Lightbox with keyboard navigation and **in-browser video scrubbing** (HTTP Range)
- **Captions + original-post links** from instaloader's `.txt` / `.json.xz` sidecars
- **Search box** filters your profiles live as you type
- Huge profiles stay snappy — grids render in batches as you scroll (windowed)

**Update**
- Per-profile **↻ update** and **↻ Update all** buttons run instaloader, with live progress in a collapsible **▤ log** panel; updates are **incremental** (`--latest-stamps`), never full re-downloads
- **Ephemeral capture** — updates also pull **stories, highlights, and reels** in separate instaloader passes, each routed into its own section subfolder so the tabs populate (reels also arrive in-feed with posts)
- **Add a new profile** — type an un-archived `@name` in the search box and hit **Archive @name**; instaloader downloads it and it joins the grid

**Accounts**
- An **"as @account"** switcher in the header lists your saved instaloader sessions; the active account is used for both updates and the heartbeat, and the choice persists across restarts

**Status (heartbeat)**
- **♥ Check all** pings Instagram via your session and marks every profile with a colored dot: 🟢 alive · 🟡 private · 🔴 dead · 🔵 renamed (hover for the new handle) · ⚪ not checked. A legend sits in the header. Throttled and on-demand only; rename detection uses the account's numeric user-id (parsed from filenames), so it survives username changes

**Fast on a slow archive**
- Scans the archive **once** (in parallel) into a local cache; pages render from it and never re-walk the archive
- **Cached thumbnails** (ffmpeg) keep grids light — small tiles instead of full images — and are **pre-warmed in the background** so first-browse is instant
- The archive is touched only on first scan and when loading media, never to render a page

## Requires the patched instaloader fork

Stock instaloader `4.15.1` is **broken against current Instagram** (retired `doc_id` / GraphQL changes), and Instagram now returns `403` to anonymous requests. offgram therefore depends on a fork carrying the unmerged fixes, and needs a logged-in session:

```
instaloader @ git+https://github.com/mholzinger/instaloader@fix-profile-metadata-web-profile-info
```

## Install

**As a command (recommended):**

```bash
pipx install git+https://github.com/mholzinger/offgram
brew install ffmpeg          # for thumbnails and video poster frames
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
INSTALOADER_LOGIN = "your_ig_username"           # session for updates/heartbeat, or ""
```

Create the instaloader session the update buttons and heartbeat use (one time per account):

```bash
instaloader --login YOUR_USERNAME
```

Add more accounts the same way — they appear in the in-app account switcher.

### Environment variables (override config)

| Variable | Default | Purpose |
|---|---|---|
| `OFFGRAM_COLLECTION` | — | archive root (folder of per-profile subfolders) |
| `OFFGRAM_LOGIN` | — | default instaloader session username |
| `OFFGRAM_CONFIG` | — | explicit path to a `config.py` |
| `OFFGRAM_PORT` | `8077` | web server port |
| `OFFGRAM_PREWARM` | `1` | background thumbnail pre-warm (`0` to disable) |
| `OFFGRAM_EPHEMERAL` | `1` | grab stories/highlights/reels on update (`0` = posts only) |
| `OFFGRAM_PASS_DELAY` | `6` | seconds between instaloader passes (throttle protection) |
| `OFFGRAM_HEARTBEAT_INTERVAL` | `4` | seconds between heartbeat checks |

## Run

```bash
offgram                    # if pipx-installed
# or:  python3 offgram.py  # from a checkout
# then open http://localhost:8077
```

First launch scans the collection in the background (slower the first time; cached
forever after). Hit **⟳ rescan** after large external changes; per-profile **↻ update**
re-scans that profile automatically when instaloader finishes.

## How it works

- **Local cache** (`~/.cache/offgram/`): the file listing is scanned once into
  `index.json`; every page renders from that in-memory index, so browsing never
  re-walks the archive — instant even when the files live on a network share.
- **Parallel scan**: profiles are scanned concurrently, since the cost is per-directory
  I/O latency rather than CPU.
- **Thumbnails**: generated with ffmpeg (~360 px) and cached under `~/.cache/offgram/thumbs/`;
  legacy 4K Stogram thumbnails are reused when present. A gentle background pass
  pre-warms thumbnails for instaloader profiles so first-browse is instant.
- **Updates**: each profile runs a posts pass plus separate stories/highlights/reels
  passes (highlights use the `{profile}` dirname token so they land flat in
  `highlights/` instead of per-collection folders). Passes are spaced out to avoid
  Instagram throttling.
- offgram never writes to the archive itself — only instaloader does, via the update
  buttons. If offgram breaks, your folders are untouched and browsable in Finder.
- Runs on `127.0.0.1` only (single-user, local). It is not hardened for network exposure.

## Roadmap

Planned, not yet built:

- **Identity management** — sign out / remove an account, add an account by importing
  a browser session (`instaloader --load-cookies`, sidestepping password + 2FA), and
  detect/refresh stale logins.
- **Stale-archive refresh engine** — a slow, resumable, throttle-aware background job
  that brings every legacy profile current via instaloader, with trackable progress
  (queue, per-profile status, pause/resume). The migration path for old 4K Stogram
  archives.
- **Archive-wide dedup / migration** — prune legacy 4K Stogram files where a complete
  instaloader copy exists, treating instaloader as the source of truth. Dry-run first,
  reversible, never deletes without confirmation.

---

### Footnote: legacy 4K Stogram archives

offgram grew out of a [4K Stogram](https://www.4kdownload.com/products/stogram) collection, and still reads one if it happens to find it — captions and original-post URLs from a `.stogram.sqlite` in the archive root, and thumbnails from `.thumb.stogram/` folders. This is **optional legacy support**: 4K Stogram is effectively abandoned (chronic account lockouts), and a pure instaloader archive never touches any of it. If you have an old 4K Stogram export, offgram will quietly surface its captions and thumbnails; if you don't, you'll never know the code is there. The roadmap's refresh + dedup work is about migrating these legacy archives onto instaloader for good.
