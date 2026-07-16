# offgram

**An offline web gallery for your instaloader archive.**

[instaloader](https://github.com/instaloader/instaloader) downloads Instagram posts, reels, stories, and highlights to disk. offgram is the other half: it turns that pile of dated files into a fast, browsable local gallery — per profile, with captions, in-browser video, and original-post links — and gives you buttons to pull updates, add new profiles, check account health, rehydrate old metadata, and **merge an author's scattered accounts into one de-duplicated timeline**. It's for archivists who already have a collection and want to actually *look* at it (and keep it current).

It's a single dependency-free Python file (standard library only). The archive can live anywhere — local disk or a network share — and offgram scans it **once** into a local cache, so the UI stays instant.

> **Non-destructive by design.** offgram never writes to your archive. Everything it adds — health, identity/renames, lists, merges, rehydrated captions, dedup hashes — lives in its own cache as overlays. The only thing that ever writes media is instaloader, via the update buttons. If offgram vanished tomorrow, your folders would be untouched and browsable in Finder.

## Features

**Browse**
- By profile, with **posts / reels / stories / highlights / tagged** section tabs
- Lightbox with keyboard navigation and **in-browser video scrubbing** (HTTP Range)
- **Mute toggle** on videos — they start muted (so autoplay is reliable); 🔇/🔊 flips sound and remembers your choice
- **Captions + original-post links** from instaloader's `.txt` / `.json.xz` sidecars (or a 4K Stogram db — see *Rehydrate*)
- **Search box** filters your profiles live as you type (matches handles, folder names, and known aliases)
- Huge profiles stay snappy — grids render in batches as you scroll (windowed)

**Update**
- Per-profile **↻ update** and **↻ Update all** run instaloader, with live progress in a collapsible **▤ log**; updates are **incremental** (`--latest-stamps`), never full re-downloads
- **Ephemeral capture** — updates also pull **stories, highlights, and reels** in separate passes, each routed into its own section subfolder
- **Add a new profile** — type an un-archived `@name` in the search box and hit **Archive @name**
- **⟲ Refresh all** runs a slow, resumable, throttle-aware whole-archive refresh in the background; skips dead and archive-only accounts
- **⚡ scan updates** — a throttled live sweep that asks Instagram whether each tracked account has posts **newer than your archive**, *without downloading anything*. Profiles with news get a clickable **⚡ new posts** tag (click = update just that one) and a **⚡ new posts** filter chip; each probe doubles as a health check

**Accounts & sessions**
- An **"as @account"** switcher in the header picks the active instaloader session (used for updates and the authenticated heartbeat); the choice persists across restarts
- **⚙ accounts** opens a manager to **import a session straight from a logged-in browser** (`--load-cookies` — no password, no 2FA), **test** whether a saved session is still valid (a live login check, flags stale/expired ones), **switch** between accounts, and **sign out** (delete a saved session). Your archive is never touched

**Health & validation**
- **⚡ Quick check** — anonymous, login-free liveness triage across all profiles (cheap reachability, fired in parallel)
- **♥ Check all** — authenticated heartbeat via your session; marks every profile with a colored dot: 🟢 alive · 🟡 private · 🔴 dead · 🔵 renamed (hover for the new handle) · ⚪ not checked. Rename detection uses the account's numeric user-id (parsed from filenames), so it survives username changes
- **✓ validate** (per-tile) — a one-click liveness **+ name-history** check for a single folder. Ideal for confirming a folder name from an old backup is still a live handle: it resolves the stable user-id and reports a rename even when the handle no longer exists. Falls back to anonymous liveness when you're not logged in

**Merge accounts into one timeline**
- **▦ select** several profiles from the same creator (an abandoned one, a revived one, a banned one…) and **⤳ merge…** them
- Name a **new merged profile**, or designate a **parent** (its handle and cover lead) — the parent picker **pre-selects the live (public/private) account with the newest post**, with all candidates listed newest-first
- **👁 Preview** the combined timeline *before committing* — nothing is saved until you confirm
- The **omnibus view** stitches every member's posts into one contiguous, time-sorted timeline, each post badged with its source account (🏷 toggle)
- **Near-duplicate dedup** — the same photo re-uploaded across accounts (Instagram re-encodes it each time, so files differ) is detected by **perceptual hash** and collapsed to a single cell carrying *every* copy's caption/date/account. Always keeps at least the best-quality copy
  - **Deduped by default** — opening a merge collapses duplicates automatically; the hash index **builds itself in the background** on first open (inline progress, no button to find)
  - Tunable **match tolerance** (− tighter / looser +) per view
  - A **size guard** leaves runaway look-alike groups un-collapsed (errs toward never falsely merging)
- Fully **non-destructive and reversible** — a merge is a saved grouping plus a live view; **✕ unmerge** restores the source profiles instantly. No files move.

**Rehydrate from a 4K Stogram database**
- Migrating folders out of an old [4K Stogram](https://www.4kdownload.com/products/stogram) archive? Their captions, post URLs, real timestamps, and identity live in that archive's `.stogram.sqlite`, not in the folders themselves.
- **⇪ import…** (per-tile) pulls one folder's metadata from a source db you point at; **⇪ import all** sweeps every folder in one pass. **Idempotent** — safe to re-run as you add more folders or point at a newer db.
- Reads the source db **read-only**; writes only a per-folder `.offgram-stogram.json` sidecar in your collection. Never touches the source archive or any media file.

**Organize**
- **Tracking modes** per profile: *active* (default), **⊘ archive (view-only)** — browsable but skipped by Update all / Refresh all — and **✕ removed** (dropped from the grid, files kept, restorable from the **hidden** filter; or **🗑 deleted from disk** behind a type-the-name confirm)
- **Lists** — user-named groups (tags); an account can be on several. Create/rename/delete via **🗂 lists**, tag one from its per-card **🗂**, or **▦ select** several and bulk-assign. Each list becomes a filter chip
- **Discovery** — folders that appear on disk but aren't tracked get a **🆕 new folders** banner; adopt one to deep-scan it, seed incremental-update stamps, and register its identity — or ignore it (stale ignores self-prune when a folder is gone)
- **⟳ rescan** waits for the scan to finish and then reports exactly what changed (`+N new, −M removed`)
- Filter the grid by **status · tracking · list · ⚡ new posts · ⤳ merges** chips; search works within any active filter
- **Sort** the grid by **name** or **↓ recent** (newest archived post first — great for "what moved lately" across tracked profiles); the choice is remembered

**Back up**
- **💾 backup** snapshots every offgram setting — lists, identity/renames, tracking, hidden, dismissed, health, merges, dedup hashes, latest-stamps, the index, and your `config.py` — into a timestamped `.tar.gz` under `~/.cache/offgram/backups/` (login sessions excluded). Restore from the list (snapshots current state first, reloads in place)

**Fast on a slow archive**
- Scans the archive **once** (in parallel) into a local cache; pages render from it and never re-walk the archive
- **Cached thumbnails** (ffmpeg) keep grids light and are **pre-warmed in the background** so first-browse is instant
- The archive is touched only on first scan and when loading media, never to render a page

## Requires the patched instaloader fork

Stock instaloader `4.15.1` is **broken against current Instagram** (retired `doc_id` / GraphQL changes), and Instagram now returns `403` to anonymous requests. offgram therefore depends on a fork carrying the unmerged fixes, and needs a logged-in session for updates and the authenticated heartbeat:

```
instaloader @ git+https://github.com/mholzinger/instaloader@offgram-stable
```

## Install

**As a command (recommended):**

```bash
pipx install git+https://github.com/mholzinger/offgram
brew install ffmpeg          # thumbnails, video poster frames, perceptual hashing
```

This pulls in the patched instaloader fork automatically and gives you an `offgram` command.

**Or from a checkout (for development):**

```bash
git clone https://github.com/mholzinger/offgram && cd offgram
python3 -m venv .venv && source .venv/bin/activate
pip install -e .
```

## Configure

**Easiest: just run `offgram`.** With no config present it asks for your archive path and writes `~/.config/offgram/config.py` for you.

Or create `~/.config/offgram/config.py` by hand (copy from [`config.example.py`](config.example.py) — if you grab it from GitHub in a browser, use the **Raw** button; saving the page itself gives you HTML, which isn't a valid config):

```python
COLLECTION = "/path/to/your/instagram/archive"   # folder of per-profile subfolders
INSTALOADER_LOGIN = "your_ig_username"           # session for updates/heartbeat, or ""
```

The config is **plain Python** — just `NAME = "value"` lines. (Pasting HTML/CSS or rich text into it stops offgram at startup with a pointer to the bad line.)

Create the instaloader session the update buttons and heartbeat use (one time per account):

```bash
instaloader --login YOUR_USERNAME
# pipx install? the CLI lives inside offgram's venv, not on your PATH:
~/.local/pipx/venvs/offgram/bin/instaloader --login YOUR_USERNAME
```

If you already have a saved session, offgram uses it automatically — `INSTALOADER_LOGIN` only matters for choosing between several. Without any login, updates fail fast with a clear message instead of Instagram's misleading anonymous-request errors.

Add more accounts the same way — they appear in the in-app account switcher. Or skip the CLI entirely: in the running app, **⚙ accounts → import** pulls a session straight from a logged-in browser (`--load-cookies`), no password or 2FA required. Browser import needs the optional `browser_cookie3` package (`pip install browser_cookie3`); **Firefox or Chrome are the most reliable** — Safari cookie access is flaky on macOS.

### Environment variables (override config)

| Variable | Default | Purpose |
|---|---|---|
| `OFFGRAM_COLLECTION` | — | archive root (folder of per-profile subfolders) |
| `OFFGRAM_LOGIN` | — | default instaloader session username |
| `OFFGRAM_CONFIG` | — | explicit path to a `config.py` |
| `OFFGRAM_STOGRAM_DB` | — | default source `.stogram.sqlite` for **⇪ import** rehydration |
| `OFFGRAM_CACHE` | — | explicit cache directory (overrides the per-archive keying below) |
| `OFFGRAM_CACHE_HOME` | `~/.cache/offgram` | base under which per-archive cache dirs are created |
| `OFFGRAM_PORT` | `8077` | web server port |
| `OFFGRAM_PREWARM` | `1` | background thumbnail pre-warm (`0` to disable) |
| `OFFGRAM_EPHEMERAL` | `1` | grab stories/highlights/reels on update (`0` = posts only) |
| `OFFGRAM_PASS_DELAY` | `6` | seconds between instaloader passes (throttle protection) |
| `OFFGRAM_HEARTBEAT_INTERVAL` | `4` | seconds between heartbeat checks |
| `OFFGRAM_UPDSCAN_INTERVAL` | `5` | seconds between ⚡ update-scan probes |
| `OFFGRAM_NO_BROWSER` | — | set to `1` to skip auto-opening the browser on start |

## Run

```bash
offgram                    # if pipx-installed
# or:  python3 offgram.py  # from a checkout
```

Your browser opens to `http://localhost:8077` automatically (set `OFFGRAM_NO_BROWSER=1` to skip, e.g. on a headless box).

Closing the tab doesn't stop the server — it keeps running until **⏻ quit** or Ctrl-C. If you run `offgram` while one is already running (say, right after an upgrade), it notices, and offers to stop the old instance and take over the port.

**Button cheat-sheet** (also in-app via **❓**): *rescan* reads your disk; *checks/scans* ask Instagram without downloading; *update/refresh* download new content.

| Button | What it does | Needs login? |
|---|---|---|
| ⚡ Quick check | fast anonymous "is this account still visible?" triage | no |
| ♥ Check all | deep health check: alive · private · dead · renamed dots | yes |
| ⚡ scan updates | flags accounts with posts newer than your archive (no download) | yes |
| ⟳ rescan | re-read the archive folder after outside changes | no |
| ⇪ import all | pull captions/dates/identity from a 4K Stogram db | no |
| ↻ update / ⟲ Refresh all | download new content (one profile / all, slowly) | yes |

First launch scans the collection in the background (slower the first time; cached forever after). Hit **⟳ rescan** after large external changes; per-profile **↻ update** re-scans that profile automatically when instaloader finishes. Stop the server cleanly from the UI with **⏻ quit** (or Ctrl-C in the terminal) — the shutdown page shows the exact command to relaunch *that* instance.

### Multiple archives / fresh testing

Because the cache is keyed per archive (see [How it works](#how-it-works)), you can run several collections side by side — each gets its own isolated index, health, lists, merges, and dedup hashes, with **no clobbering**. Point `OFFGRAM_COLLECTION` at the archive and `OFFGRAM_PORT` at a free port:

```bash
# a second, independent gallery for another archive
OFFGRAM_COLLECTION=/Volumes/whatever/other-archive OFFGRAM_PORT=8078 offgram
# → http://localhost:8078, cache under ~/.cache/offgram/<name>-<hash>/

# a throwaway/empty archive for testing — just works, real library untouched
OFFGRAM_COLLECTION=/tmp/test-archive OFFGRAM_PORT=8079 offgram
```

Use `OFFGRAM_CACHE` to pin an explicit cache directory, or `OFFGRAM_CACHE_HOME` to relocate the base that holds the per-archive dirs.

### Start fresh / reset

All of offgram's state lives in its cache, never in your archive. To reset completely: quit the app (**⏻** or Ctrl-C), `rm -rf ~/.cache/offgram`, relaunch — it rescans from the files on disk, and your archive is untouched. A leftover background refresh queue from a previous run shows up as a banner with **▶ resume / ■ clear** buttons; **■ clear** drops it.

### Diagnostics

Update output streams live into the **▤ log** panel and is also appended to `update.log` in the cache directory (`~/.cache/offgram/<archive>/update.log`), so errors survive closed windows and reloads.

Append `?debug=1` to any page (or press **Shift+D**) for an opt-in overlay that samples DOM node count, JS heap (Chrome only), fetch rate, and live timer count over time — handy for spotting a slow client-side leak. History is exportable from the console via `copy(JSON.stringify(__leak.hist))`.

## How it works

- **Local cache, keyed per archive** (`~/.cache/offgram/<name>-<pathhash>/`): the file listing is scanned once into `index.json`; every page renders from that in-memory index, so browsing never re-walks the archive — instant even on a network share. Overlays (`identity.json`, `tracking.json`, `lists.json`, `merges.json`, `phash.json`, …) live alongside it. The cache dir is derived from a stable hash of the archive's canonical path, so pointing offgram at a different collection (e.g. a throwaway test archive) gets its own isolated cache instead of clobbering another's — no token is written into the archive. Set `OFFGRAM_CACHE` to force a specific dir. (An older single flat cache is migrated into its per-archive dir automatically on first run.) All cache/state files are written **atomically** (temp file + rename), so a crash or a concurrent reader never sees a half-written file.
- **Parallel scan**: profiles are scanned concurrently, since the cost is per-directory I/O latency rather than CPU.
- **Thumbnails**: generated with ffmpeg and cached under `~/.cache/offgram/thumbs/`; legacy 4K Stogram thumbnails are reused when present. A gentle background pass pre-warms them.
- **Dedup hashing**: a DCT-based perceptual hash (pHash) is computed from each cached thumbnail (videos use their poster frame) — robust to Instagram's per-upload re-encoding — and near-duplicates are grouped by Hamming distance using LSH banding so it scales to thousands of posts.
- **Updates**: each profile runs a posts pass plus separate stories/highlights/reels passes, spaced out to avoid throttling.
- Runs on `127.0.0.1` only (single-user, local). It is not hardened for network exposure.

## Releases

Tagged releases are cut automatically by GitHub Actions. Maintainers: bump the version in `pyproject.toml`, then push a `v*` tag:

```bash
git tag v0.2.0 && git push origin v0.2.0
```

The workflow smoke-tests the build, builds an sdist/wheel, and publishes a GitHub Release with auto-generated notes and `offgram.py` attached. Every push and PR runs a lightweight syntax + import check.

## Roadmap

Planned, not yet built:

- **Archive-wide file dedup / migration** — prune legacy 4K Stogram files where a complete instaloader copy exists, treating instaloader as the source of truth. Dry-run first, reversible, never deletes without confirmation. (The merge view already de-duplicates *visually*; this is about reclaiming disk.)

---

### Footnote: legacy 4K Stogram archives

offgram grew out of a [4K Stogram](https://www.4kdownload.com/products/stogram) collection, and reads one when it finds it — captions and original-post URLs from a `.stogram.sqlite` in the archive root, and thumbnails from `.thumb.stogram/` folders. The **⇪ import** feature extends this to *separate* source archives, so you can migrate folders in one at a time and rehydrate their metadata. This is optional legacy support: 4K Stogram is effectively abandoned (chronic account lockouts), and a pure instaloader archive never touches any of it.
