---
type: setup-guide
audience: anyone with a brain on one Mac who wants it on more devices
updated: 2026-05-21
---

# Sync your second brain across devices

You built a second brain on your main Mac (per [docs/getting-started.md](./getting-started.md)). Now you want it on your laptop, your second machine, or any other device. This guide gets you there in about 5 minutes per extra device.

> **The sync flavor here:** vault ↔ vault via a private GitHub repo. Your main Mac pushes; every other device auto-pulls hourly. No external sources are touched on the extra devices — they just mirror what's already in the repo.

---

## How this works

```
Main Mac                  GitHub (private)            Second Mac / Laptop
────────                  ────────────────            ──────────────────
/sync-all  ─push─>     your-brain.git    <─pull─    git pull (hourly)
(daily 10am)                                         via LaunchAgent

Memory.md                                            (not synced — local only)
.obsidian/workspace                                  (not synced — local only)
```

- **One writer, many readers.** Your main Mac runs the daily sync and pushes commits. Every other device only pulls.
- **`Memory.md` stays local** on each device. Each one of your devices can have a different Memory.md if you want (e.g. a "weekend reading" personality on the laptop).
- **No conflicts** as long as you don't edit tracked files on the secondary devices. If you do, see [Troubleshooting](#two-way-edits-and-conflicts) below.

---

## Prerequisites

Before starting on the new device:

- **macOS** (the auto-sync uses `launchd`; Linux / Windows alternatives at the bottom).
- **Git** — preinstalled on macOS, or `xcode-select --install`.
- **A private GitHub repo holding your brain** — your main Mac has already pushed to it (per the optional git step in `docs/getting-started.md` Step 2).
- **GitHub access from the new device** — either signed into GitHub Desktop, or `gh auth login` from the `gh` CLI. Without cached credentials, `git pull` will prompt for a password every hour. See [Troubleshooting](#git-pull-asks-for-password-every-time).

---

## Step 1 — Clone on the new device

```bash
cd ~/Documents      # or wherever you keep your brain
git clone https://github.com/YOUR_USERNAME/YOUR_BRAIN_REPO.git
cd YOUR_BRAIN_REPO
```

Verify it landed:

```bash
ls
# CLAUDE.md  Daily/  raw-sources/  wiki/  docs/  ...
```

---

## Step 2 — Install hourly auto-sync

A LaunchAgent runs `git pull --rebase --autostash` every hour + once at login. Zero effort thereafter.

Save this as `~/install-brain-pull.sh` on the new device and run it once:

```bash
cat > ~/install-brain-pull.sh <<'SH'
#!/bin/bash
set -euo pipefail

LABEL="com.user.brain-pull"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
REPO_DIR="$HOME/Documents/YOUR_BRAIN_REPO"  # ← edit to your clone path
LOG="$HOME/Library/Logs/brain-pull.log"

cat > "$PLIST" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>-lc</string>
    <string>cd "$REPO_DIR" && /usr/bin/git pull --rebase --autostash >> "$LOG" 2>&1 && echo "[\$(date +%F\\ %T)] sync OK" >> "$LOG"</string>
  </array>
  <key>StartInterval</key><integer>3600</integer>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>$LOG</string>
  <key>StandardErrorPath</key><string>$LOG</string>
</dict>
</plist>
PLIST_EOF

launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID" "$PLIST"
launchctl enable "gui/$UID/$LABEL"
echo "Auto-pull installed. Pulls every hour + once at login."
echo "Log: $LOG"
SH
bash ~/install-brain-pull.sh
```

Confirm:

```bash
tail -n 5 ~/Library/Logs/brain-pull.log
# expect: [YYYY-MM-DD HH:MM:SS] sync OK
```

To disable later:

```bash
launchctl bootout gui/$UID/com.user.brain-pull
rm ~/Library/LaunchAgents/com.user.brain-pull.plist
```

To pull manually any time: `git pull` from inside the repo.

---

## Step 3 — Open in Obsidian + Claude Code

**Obsidian:** File → Open vault → "Open folder as vault" → pick your repo folder. Plugins and `.obsidian/` settings come with the clone (except `.obsidian/workspace*` which is gitignored — that's correct, each device has its own pane layout).

**Claude Code:** add the `brain` alias on this device too (mirroring Step 3 of getting-started.md):

```bash
echo 'alias brain="cd ~/Documents/YOUR_BRAIN_REPO && claude"' >> ~/.zshrc
source ~/.zshrc
```

Now `brain` works the same on every device.

---

## Step 4 — Decide what runs where

| Action | Main Mac | Other devices |
|---|---|---|
| `/sync-all` (the daily pull from your connected MCPs — meetings, tasks, chat, etc.) | ✅ via launchd at 10:00 AM | ❌ skip — only one writer |
| `git pull` (hourly auto-pull) | optional | ✅ via launchd |
| Read in Obsidian | ✅ | ✅ |
| Ask Claude questions | ✅ | ✅ |
| Edit `Memory.md` | ✅ (it's gitignored, local-only) | ✅ (different file, also local-only) |
| Edit `wiki/` by hand | rarely; Claude is the maintainer | ❌ |

The asymmetry is intentional. **One writer, many readers.** The daily `/sync-all` job lives on your main Mac so the wiki has a single source of truth.

---

## Troubleshooting

### `git pull` asks for password every time

You haven't cached GitHub credentials on the new device.

**Option A (easiest):** Download [GitHub Desktop](https://desktop.github.com), sign in once. It installs the macOS Keychain helper for git automatically.

**Option B (`gh` CLI):**

```bash
brew install gh
gh auth login
```

After either, `git pull` runs silently forever.

### Auto-pull isn't running

```bash
tail ~/Library/Logs/brain-pull.log
launchctl list | grep brain-pull
```

If you see auth errors in the log, fix credentials (above), then reinstall:

```bash
launchctl bootout gui/$UID/com.user.brain-pull
bash ~/install-brain-pull.sh
```

### Two-way edits and conflicts

If you only ever **read** on the second device, conflicts don't happen. But if you sometimes edit a tracked file there too:

```bash
# you have unpushed local edits + remote has new commits
git stash         # set aside local
git pull          # pick up remote
git stash pop     # reapply local (may conflict — resolve normally)
```

Better: keep the second device read-only. Use `Memory.md` (which is gitignored) for any personal scratch notes that don't need to sync.

### Linux / Windows

The repo works fine — only the auto-pull helper is Mac-specific.

- **Linux:** add a cron entry. cron has a minimal `PATH`, use the absolute git path and redirect to a log:
  ```
  0 * * * * cd ~/Documents/YOUR_BRAIN_REPO && /usr/bin/git pull --rebase --autostash >> ~/brain-pull.log 2>&1
  ```
- **Windows:** Task Scheduler → Create Basic Task → hourly trigger → run `git pull --rebase --autostash` in the repo directory. Cache credentials with Git Credential Manager first.

### Memory.md isn't syncing

By design. `Memory.md` is in `.gitignore` so each device has its own personality file. If you really want a shared Memory.md, remove it from `.gitignore` — but you'll likely regret it the first time the laptop's stale Memory.md overwrites the main Mac's fresh edits.
