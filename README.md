# Claude second brain — template

A pattern for an **LLM-maintained personal knowledge base**. Built with Claude Code + Obsidian. macOS-first.

Every morning at 10:00 AM the system pulls your last 24 hours of activity — meetings, tasks, chat messages, anything you connect — into a `Daily/{date}.md` snapshot. Each meeting (with full verbatim transcript) gets filed into `raw-sources/`. The Daily file cross-links into a Claude-maintained wiki of people, projects, decisions, concepts — navigable as a clickable graph in Obsidian.

You decide which services it pulls from. The pattern works with any MCP server — Granola or Otter or Fathom for meetings, Linear or Jira or Asana for tasks, Slack or Discord or Teams for chat, plus anything else (email, calendar, docs, code, CRM). See [`docs/getting-started.md`](./docs/getting-started.md) Step 6 for the full menu.

Pick a path.

---

## Path 1 — Build your own from scratch

Start from an empty folder; in 30 minutes you'll have a working vault with the daily sync automated.

**The sync flavor here:** external sources (any MCP-connected service — meetings, tasks, chat, email, docs, etc.) → your vault. Runs daily via `launchd` on macOS.

→ **[`docs/getting-started.md`](./docs/getting-started.md)** — the full 9-step guide.

> **Want a head start?** Click **"Use this template"** at the top of this GitHub page to create your own empty repo with the same structure, then follow `docs/getting-started.md` from Step 3 onwards (skip Step 2 — you already have a folder).

---

## Path 2 — Sync your brain across devices

You already have a second brain on one Mac. You want it on your laptop, your second machine, or any other device.

**The sync flavor here:** vault ↔ vault via a private GitHub repo. Main Mac pushes; every other device auto-pulls hourly. ~5 minutes per extra device.

→ **[`docs/sync-across-devices.md`](./docs/sync-across-devices.md)** — clone + install the auto-pull LaunchAgent.

---

## Architecture

```
External sources              Your vault                  Obsidian
─────────────────             ────────────                ────────
Meetings ──┐                  raw-sources/  ─┐
Tasks    ──┼─> /sync-all ──>  Daily/         ├──> graph view
Chat     ──┤   (10am daily)   wiki/          │     (wikilinks
…anything──┘                                  │      become
                                              │      clickable
Manual / occasional:                          │      edges)
  /sync-{source}              ──> raw-sources/
  /wiki-refresh               ──> wiki/

CLAUDE.md + Memory.md  ──> read by Claude every session
                              (context for every answer)
```

- **`raw-sources/`** — immutable inputs. One file per meeting (frontmatter + full transcript), one per task / ticket export, one per chat channel dump.
- **`Daily/`** — your morning inbox. One file per day, written by `/sync-all`.
- **`wiki/`** — Claude-maintained synthesis. People, projects, concepts, decisions, reports. Cross-linked.
- **`CLAUDE.md`** — the schema. Tells Claude how the system works. (You generate this in Step 4 by downloading Karpathy's gist + having Claude prepend bootstrap rules.)
- **`Memory.md`** — your personality. Gitignored, local-only. Each device has its own.

The whole thing is plain markdown. Obsidian renders the `[[wikilinks]]` as a clickable graph. Git versions every change.

---

## Credit

Pattern based on [Andrej Karpathy's "LLM Wiki" idea file](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). This repo is a working template for following that pattern with Claude Code + Obsidian on macOS.

## License

MIT — use freely.
