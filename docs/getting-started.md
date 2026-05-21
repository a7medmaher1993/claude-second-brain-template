---
type: setup-guide
audience: anyone setting up a second brain
updated: 2026-05-21
---

# Getting started — second brain

A personal, LLM-maintained knowledge base. A folder of plain markdown files that Claude keeps up to date for you, populated with your meetings, your tickets, your decisions. About 30 minutes end to end if your accounts are ready.

> Based on Andrej Karpathy's "LLM Wiki" pattern. Original idea file: <https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f>.

> Each person builds a second brain from scratch. Nothing is shared. The schema and slash commands are patterns Claude sets up for you in your own folder. The content (your wiki, your memory, your sources) is always yours.

---

## What you will have at the end

A folder on your Mac that:

1. Holds every Granola meeting you ever recorded as plain markdown (with full verbatim transcripts).
2. Holds every Linear ticket assigned to or touching you, refreshed on demand.
3. Has a Claude-maintained wiki of people, projects, decisions, and concepts, all cross-linked.
4. Produces a **daily inbox** every morning at 10:00 AM — last 24h of meetings, Linear, and Slack mentions — without you doing anything.
5. Opens in Obsidian as a navigable graph.
6. Opens in Claude Code so you can ask questions about your own work and get answers grounded in your real history.

You drive it with four slash commands, one shell alias, and one `launchd` job that fires the sync every morning.

---

## How it all connects

Before you start setting up, here's the shape of what you're building. Five moving parts:

1. **External sources** — Granola, Linear, Slack. They live outside the vault. Claude reaches them through MCPs (Step 6).
2. **`raw-sources/`** — the immutable archive. One markdown file per Granola meeting (with frontmatter + full verbatim transcript), one per Linear ticket export, one per Slack channel dump. Claude reads from here; nothing else writes to it except the sync commands.
3. **`wiki/`** — the curated synthesis. People, projects, concepts, decisions, reports. Cross-linked. This is what you actually read day-to-day. Claude maintains it.
4. **`Daily/`** — your morning inbox. One file per day, written by `/sync-all`. Last 24 hours of meetings (with `[[wikilinks]]` into `raw-sources/` and `wiki/people/`), Linear issues assigned to you, Slack mentions + DMs awaiting reply.
5. **`CLAUDE.md` + `Memory.md`** — read every session before Claude responds. CLAUDE.md says how the system works; Memory.md says who you are.

The daily loop, in one line:

> at 10:00 AM `launchd` runs `/sync-all` silently → it writes today's `Daily/{date}.md` + adds any new meetings to `raw-sources/granola-meetings/` → you open `Daily/{today}.md` in Obsidian over coffee → wikilinks pull you into the rest of the wiki when something interests you.

The bulk loop, for backfills:

> `/sync-granola` and `/sync-linear` pull full history into `raw-sources/`. `/wiki-refresh` curates the wiki — promoting red-links to pages, fixing drift. You run these manually, occasionally.

Everything is plain markdown. Obsidian renders the `[[wikilinks]]` as a clickable graph. Git versions every change if you opted into git in Step 2.

---

## The nine steps

1. Install the tools
2. Create the vault folder
3. Make a `brain` alias
4. Have Claude set up the schema
5. Create `Memory.md`
6. Connect data sources
7. Run the first sync
8. Daily usage
9. Automate the daily sync

---

## 1. Install the tools

Two pieces. Mac instructions below. (Windows works for the vault itself.)

<details>
<summary><strong>Claude Code CLI</strong> — the AI that maintains the wiki</summary>

Install instructions: <https://docs.claude.com/claude-code>

Sign in with an Anthropic account or work Claude account. Then in Terminal:

```bash
claude
```

If you see a Claude Code prompt, you are done. If you see `command not found`, close and reopen the terminal.

Once you have confirmed it works, type `/exit` to leave Claude Code and return to your shell. **Everything from Step 2 onwards runs in your shell unless a step says otherwise.**
</details>

<details>
<summary><strong>Obsidian</strong> — how you read the wiki</summary>

Install: <https://obsidian.md>

Free for personal use. Treats any folder of markdown files as a vault. The killer features for this workflow are:

- **Backlinks** — every `[[wikilink]]` becomes a clickable graph edge.
- **Graph view** — visual map of everything connected to everything. (Try it after the first sync; the shape is what sells the system to your future self.)
- **Search** — Cmd-Shift-F across the whole vault.
</details>


---

## 2. Create the vault folder

Pick a path you will remember.

```bash
mkdir -p ~/Documents/second-brain
cd ~/Documents/second-brain
```

<details>
<summary><strong>(explanation)</strong> — what those two lines do, in plain English</summary>

- `mkdir -p ~/Documents/second-brain` — make a folder called `second-brain` inside your `Documents` folder. The `~` is a shortcut for your home folder, so on every Mac this resolves correctly to *that user's* `Documents`. (On your Mac it resolves to `/Users/yourname/Documents/second-brain`.) The `-p` flag means "create any parent folders if they're missing" — so it won't fail if for some reason `Documents` doesn't exist yet.
- `cd ~/Documents/second-brain` — move into that folder so the next commands run inside it.

You can put the folder anywhere. `~/Documents/second-brain` is just a sensible default. If you want it on your Desktop instead, use `~/Desktop/second-brain`. If you want a different name, swap `second-brain` for whatever you prefer.

</details>

That is it for the folder.

<details>
<summary><strong>Optional — version control with git</strong> (skip if you do not need backup or cross-machine sync)</summary>

The brain works fine without git. Skip this entirely unless you want either (a) a history of changes to your wiki, or (b) backup and cross-machine sync via GitHub.

**1. Make sure git is installed.**

In Terminal, type `git --version`. If you see a number, skip ahead. If you see an error, run:

```bash
xcode-select --install
```

This installs Apple's developer tools (which include git). Takes a few minutes.

**2. Initialize the repo.**

From inside your vault folder:

```bash
git init
git add -A
git commit -m "Initial vault"
```

`.gitignore` (created in Step 4) keeps `Memory.md` and credentials local, so they never get committed.

**3. Push to a private GitHub repo.**

Easiest with the `gh` CLI:

```bash
brew install gh
gh auth login
gh repo create second-brain --private --source=. --remote=origin
git push -u origin main
```

You now have a private GitHub mirror of your vault. To pull updates on another Mac, `git clone` it there and follow Step 1 (install Claude Code + Obsidian) and Step 6 (connect MCPs) to make it functional.

</details>

<details>
<summary><strong>What the folder will eventually contain</strong></summary>

```
second-brain/
├── CLAUDE.md                  the schema — Claude reads this every session
├── Memory.md                  your personality — Claude reads this every session
│
├── Daily/                     daily snapshots (one .md per day, written by /sync-all)
│   └── 2026-05-21.md          today's meetings, Linear issues, Slack mentions
│
├── wiki/                      Claude-maintained synthesis — this is what you read
│   ├── index.md               catalog of every wiki page
│   ├── log.md                 append-only ingest history
│   ├── people/                one page per colleague (← Daily/ attendees link here)
│   ├── projects/              one page per project
│   ├── meetings/              curated meeting summaries
│   ├── concepts/              domain terms (vendors, jargon, frameworks)
│   ├── decisions/             decisions you've made and why
│   └── reports/               audit reports, retros, deep-dives
│
├── raw-sources/               immutable inputs — Claude reads, never modifies
│   ├── granola-meetings/      one .md per meeting (frontmatter + full transcript)
│   ├── linear/                Linear ticket exports
│   └── slack/                 Slack channel archives (opt-in)
│
├── .claude/commands/          your slash commands (created in Step 4b)
│   ├── sync-granola.md
│   ├── sync-linear.md
│   ├── sync-all.md
│   └── wiki-refresh.md
├── .logs/                     launchd job logs (Step 9 creates this)
└── .gitignore                 keeps Memory.md and other personal files local
```

You start with empty folders. Each sync command populates them. The `Daily/` folder gets created on the first `/sync-all` run if it doesn't exist.
</details>

---

## 3. Make a `brain` alias

Set this up now so every following step is one word. From any terminal:

```bash
echo 'alias brain="cd ~/Documents/second-brain && claude"' >> ~/.zshrc
source ~/.zshrc
```

Now `brain` from any terminal `cd`s into your vault and starts a Claude Code session in one step. Every step from here on uses this.

<details>
<summary><strong>(explanation)</strong> — what those two lines do</summary>

- `echo 'alias brain="cd ~/Documents/second-brain && claude"' >> ~/.zshrc` — appends one line to your shell config file (`~/.zshrc`). That one line defines `brain` as a shortcut that does two things in order: change directory into your vault, then launch Claude Code.
- `source ~/.zshrc` — reloads the shell config so the alias is available right now, in this terminal, without you having to close and reopen.

If you put your vault somewhere other than `~/Documents/second-brain` in Step 2, swap the path in the first line to match.

</details>

> **Rule of thumb for the rest of the guide:** you are in your shell by default. `brain` opens a Claude Code session inside the vault. If a command starts with `/`, it is a Claude Code command (run after `brain`). Everything else is a shell command.

---

## 4. Have Claude set up the schema

This step produces `CLAUDE.md` (the rules), the slash commands, and the folder structure. You do not write these by hand. 4a saves Karpathy's gist as the body of your `CLAUDE.md`; 4b has Claude add bootstrap rules on top and create the supporting files. 4b reads the file 4a creates, so the order matters.

**4a — Save Karpathy's gist as your `CLAUDE.md`.**

From inside your vault folder, download the gist directly into a file named `CLAUDE.md`:

```bash
curl -L -o CLAUDE.md https://gist.githubusercontent.com/karpathy/442a6bf555914893e9891c11519de94f/raw
```

(Or open the gist in your browser, select-all + copy, then paste into a new file at `CLAUDE.md` in your vault.)

<https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f>

Open the file and read it. It is short (about 15 minutes). This text is the pattern your second brain is based on. Reading it means you understand what Claude is building, not just blindly running a setup.

**4b — Have Claude add bootstrap rules and the supporting files.**

Start a Claude Code session in the vault:

```bash
brain
```

Once Claude Code opens, paste this prompt:

```
There is a CLAUDE.md in this folder containing Karpathy's LLM Wiki pattern. Read it.

Extend it: prepend a bootstrap section at the top of CLAUDE.md that:
- Names this project (ask me what to call it).
- Instructs you to read Memory.md and wiki/index.md silently at the start of every session before responding to anything.
- Asserts that the wiki is the source of truth — never respond with "I don't have information about X" without first checking wiki/index.md.

Then create the supporting files:
- Empty folders: raw-sources/, raw-sources/granola-meetings/, raw-sources/linear/, raw-sources/slack/, wiki/people/, wiki/projects/, wiki/meetings/, wiki/decisions/, wiki/concepts/, wiki/reports/, Daily/.
- A .keep file inside Daily/ so the folder commits cleanly when empty (the daily sync writes the actual content).
- wiki/index.md (empty catalog placeholder) and wiki/log.md (empty log placeholder).
- .claude/commands/sync-granola.md — pulls new Granola meetings into raw-sources/granola-meetings/ (full verbatim transcripts via `get_meeting_transcript`, plus notes and action items — not just summaries), writes wiki summaries to wiki/meetings/, updates indexes.
- .claude/commands/sync-linear.md — refreshes Linear ticket archive into raw-sources/linear/ and wiki/linear/.
- .claude/commands/sync-all.md — **daily snapshot** (last 24h window, not full history). Writes Daily/{YYYY-MM-DD}.md with three sections: Meetings (from Granola), Linear (issues assigned to you), Slack (mentions + DMs awaiting reply). For each meeting in the window: also write a full per-meeting file to raw-sources/granola-meetings/{date}-{slug}.md matching the format of existing files in that folder (frontmatter with `granola_id`, summary, full verbatim transcript) — idempotent by `granola_id` so re-runs don't double-write. In the Daily file's Meetings section, link to those per-meeting files with `[[../raw-sources/granola-meetings/{date}-{slug}|{title}]]` and link attendees as `[[Name]]` when `wiki/people/{Name}.md` exists. This is the skill the launchd job in Step 9 invokes daily; it's also safe to run manually.
- .claude/commands/wiki-refresh.md — cross-link audit, red-link promotion candidates, index drift, orphan check.
- .gitignore — excludes Memory.md, .claude/.credentials*, *.log, .obsidian/workspace*.

Each slash command should be idempotent (re-running with no new sources is a no-op), quiet by default (only print at meaningful checkpoints), and fail-soft (one step failing logs to wiki/log.md and the chain continues).
```

Claude reads the gist you saved, prepends bootstrap rules to your `CLAUDE.md`, and writes the supporting files to disk. Review the result. Adjust anything that does not match how you want to work.

<details>
<summary><strong>What your CLAUDE.md ends up looking like</strong></summary>

After 4b, `CLAUDE.md` has two sections:

1. **Bootstrap rules at the top** (added by Claude, customized for you): project name, session-start instructions, the "wiki is the source of truth" rule.
2. **Karpathy's gist below** (the body): the canonical pattern description. Stays as a reference.

Claude re-reads the whole file every session, so both pieces stay in play.
</details>

<details>
<summary><strong>Why we save the gist as a file instead of just pasting it into the prompt</strong></summary>

Pasting a long document into a chat session works once, then it is gone. Saving it as `CLAUDE.md` means Claude re-loads it on every future session as part of the bootstrap. The pattern stays canonical instead of paraphrased.

It also lets you edit it later. If something in Karpathy's text does not match how you actually use the brain, you can change it.
</details>

<details>
<summary><strong>What the slash commands do</strong></summary>

Once generated, these become available when you run `claude` from the vault folder:

| Command | What it does |
|---|---|
| `/sync-granola` | Pulls new Granola meetings — **full verbatim transcripts**, notes, and action items — into `raw-sources/granola-meetings/`, plus wiki summaries |
| `/sync-linear` | Refreshes the Linear archive from the GraphQL API |
| `/sync-all` | **Daily snapshot** — last 24h of meetings, Linear issues, and Slack mentions/DMs into `Daily/{date}.md`. Also writes each new meeting to `raw-sources/granola-meetings/` and cross-links via `[[wikilinks]]`. This is the skill the Step 9 launchd job runs daily. |
| `/wiki-refresh` | Audits cross-links, red-links, orphans after an ingest |

You only need the ones you use. Most people start with just `/sync-granola` and `/sync-linear`.
</details>

<details>
<summary><strong>What is in CLAUDE.md and why it matters</strong></summary>

`CLAUDE.md` is the schema. The pattern comes from Andrej Karpathy's "LLM Wiki" idea file (<https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f>) — a sketch of how an LLM can build and maintain a personal knowledge base instead of you doing it by hand. CLAUDE.md is where that pattern gets pinned down into rules your specific agent follows every session.

It tells Claude:

- How the three-layer architecture works (raw-sources, wiki, schema).
- What to read at the start of every session (bootstrap).
- How to ingest a new source (where transcripts go, where wiki summaries go).
- How to handle red-links, indexes, and the log.
- That the wiki is the source of truth, not Claude's training data.

The bootstrap rule is the most important line in the file: *every session, read Memory.md and wiki/index.md silently before answering anything.* Without it, Claude treats each conversation as if it had never seen your wiki.
</details>

---

## 5. Create `Memory.md`

This is your personality file. Claude reads it on every session before doing anything else. Without it, Claude treats every question generically.

You do not have to write it by hand. Two automated paths below. Pick whichever feels more natural — both produce a first draft that you then review and edit.

**Option A (recommended) — Have Claude interview you.**

Best for day one, before you have any meetings in the vault. Takes about 15 minutes.

Start a Claude Code session in the vault:

```bash
brain
```

Then paste:

```
Create a Memory.md file at the vault root. Interview me one section at a time. Sections:
- Who I am (name, role, who I work with, where I sit)
- What I'm building (projects, with enough detail that you can recognize them in transcripts)
- How I work (cadence, collaborators, stack, meeting rhythm)
- What I care about (principles, standards, what I won't compromise on)
- What I'm figuring out (open questions, things in flux)
- Pet peeves and non-negotiables (em-dashes, weasel words, anything you should never do in my voice)
- Tools and stack (the actual products I use day to day)

Ask me one section at a time. After I answer, write that section to Memory.md, then move to the next. Do not write anything until I answer.
```

Claude walks you through each section, writes your answers into `Memory.md` as you go, and asks follow-ups when something is vague.

**Option B — Let Claude draft from your meetings.**

Best if you'd rather not do an interview. Skip Memory.md for now and come back to this *after* Step 7 (first sync) lands your meetings in the vault.

Then paste:

```
Read every file in raw-sources/granola-meetings/ and draft Memory.md at the vault root. Infer who I am, who I work with, what I'm building, how I work, and what I care about from how I show up in the transcripts. Mark anything you're uncertain about with [TODO: confirm] so I can correct it.
```

Claude reads your meetings and produces a first draft based on how you actually show up at work. Faster, less self-conscious, but biased by what's in your meetings (you'll find gaps about things you do off-camera).

**Either way: review and edit before you start using the brain.**

Open `Memory.md` and:

- Fix anything wrong.
- Add the things Claude could not infer (your private principles, your non-negotiables, context that does not show up in meetings).
- Delete anything you do not want Claude assuming about you.

<details>
<summary><strong>Why this is the highest-leverage file in the whole vault</strong></summary>

`Memory.md` is read every session. It is how Claude knows that a particular name is a colleague vs. a noun, that an internal acronym refers to a specific project, that you have non-negotiable rules about voice or formatting. Without it, Claude sees a meeting transcript and treats every name as generic. With it, Claude reads the same transcript and connects names to roles, projects to constraints, decisions to history.

Start with a paragraph per section. Grow it as you notice gaps. A mature `Memory.md` is ~500 lines and takes several weeks of editing to stabilize. Yours can start much smaller and still be useful from day one.
</details>

<details>
<summary><strong>Manual template if you'd rather write it yourself</strong></summary>

Create the file in the vault root and paste this skeleton in:

```markdown
# Memory

## Who I am
[Your name, role, who you work with, where you sit]

## What I'm building
[The projects you actually spend time on, with enough detail that Claude can recognize them in transcripts]

## How I work
[Your cadence, your collaborators, your stack, your meeting rhythm]

## What I care about
[Your principles, your standards, the things you do not compromise on]

## What I'm figuring out
[Open questions, things in flux, decisions you have not made yet]

## Pet peeves & non-negotiables
[Things you do not want Claude doing in your voice — em-dashes, weasel words, etc.]

## Tools & stack
[The actual products you use day to day]
```
</details>

<details>
<summary><strong>The monthly review habit</strong></summary>

Once a month, read `Memory.md` end to end with the past month's meeting summaries in mind. Anything that does not match your current reality, rewrite. Anything Claude has been quietly assuming about you that is no longer true, delete.

This file drifts faster than any other. If it drifts, every conversation drifts with it.
</details>

---

## 6. Connect data sources

MCP stands for Model Context Protocol. It is the bridge that lets Claude read external services like Granola or Linear as if they were native tools.

<details>
<summary><strong>Quick framing — API vs MCP vs Connector (worth reading once)</strong></summary>

Three layers of the same stack, not three alternatives.

| Layer | Where it runs | What it is | Best for |
|---|---|---|---|
| **API** (raw GraphQL / REST) | Your scripts | The service's actual door. Universal, lowest level. You handle auth, pagination, rate limits. | Bulk one-time exports. Recurring automation. The sync commands (`/sync-linear` talks to Linear's GraphQL directly). No tokens burned. |
| **MCP** (Model Context Protocol) | Claude Code (terminal) | A wrapper around the API that exposes tools the model can call. | Claude in the terminal working alongside your filesystem, git, IDE. |
| **Connector** | Claude.ai web / mobile | Productized MCP with one-click OAuth, deferred loading, and a UI toggle. Under the hood it's still MCP. | Casual ticket / doc lookups in the browser when you are not in the terminal. |

**Watch out for two MCP gotchas:**

1. **Schema bloat.** Older Claude Code versions eagerly load every MCP tool's full schema into the context window at session start, before you have sent a message. Stack three or four servers and 50k+ tokens vanish before you type. Newer Claude Code defers loading (Tool Search). Run `/context` in a fresh session to check.
2. **Result pollution.** Asking an MCP for "all tickets" or any unfiltered list dumps every record's full JSON into context and re-sends it on every subsequent turn. Always filter — by assignee, state, cycle, label, or last-N-days.

**Rule of thumb:** go up the stack until you have enough power, then stop.

- Vault sync → API path.
- Interactive use while you are in Claude Code → MCP path.
- Browser-based lookups when you are not in the terminal → Connector path.

</details>

Each MCP is registered with a single command, run from inside your vault folder. If you opened a new terminal since Step 2, `cd` back in first:

```bash
cd ~/Documents/second-brain
```

Then for each MCP you want, run a one-liner. The shape is always:

```
claude mcp add --transport http <name> <url>
```

The first time Claude actually uses each MCP, a browser tab opens for OAuth sign-in. That is the only browser step.

<details>
<summary><strong>Granola</strong> — meeting transcripts</summary>

```bash
claude mcp add --transport http granola https://mcp.granola.ai/mcp
```

The first time Claude reads Granola, a browser tab opens. Sign in with the same Granola account that records your meetings.

To verify, in a terminal:

```bash
claude mcp list
```

You should see `granola — ✓ Connected`.

**Tip:** open Granola → Preferences → Internal jargon, and add the names of your colleagues. This stops the transcription from mishearing names.
</details>

<details>
<summary><strong>Linear</strong> — tickets (three paths, pick what you need)</summary>

Linear is the clearest example of the API / MCP / Connector tradeoff. All three are valid; they serve different jobs.

**Path 1 — API key (required for `/sync-linear` to write tickets into your vault)**

Go to Linear → Settings → API → Personal API keys → create one → copy the value (looks like `lin_api_…`).

In Terminal:

```bash
echo 'export LINEAR_API_KEY=lin_api_YOUR_KEY_HERE' >> ~/.zshrc
source ~/.zshrc
```

`/sync-linear` uses this to talk to Linear's GraphQL API directly. Fast, no token cost, no context pollution. This is the path for any automated bulk pull into the vault.

**Path 2 — MCP in Claude Code (for interactive ticket lookups in the terminal)**

```bash
claude mcp add --transport http linear https://mcp.linear.app/mcp
```

The first time Claude reaches for Linear, a browser tab opens for the OAuth sign-in.

Caveats — important:

- The Linear MCP has a lot of tools (issues, projects, teams, cycles, labels, comments). On older Claude Code versions every tool schema loads into your context at session start. Check with `/context`.
- **Never ask the MCP for "all tickets" or any unfiltered list.** Every record's full JSON gets pulled into context and stays there for the rest of the session. Always filter: assignee, state, cycle, label, last-N-days.
- If you do not live in the terminal, skip this. Use the Connector path below instead.

**Path 3 — Linear Connector in Claude.ai web (recommended if you are not in the terminal)**

In Claude.ai (web or mobile): Settings → Connectors → Linear → Connect → OAuth.

Why this is often the right choice for casual ticket lookups:

- Deferred tool loading — only a thin index sits in context. Full schemas load on demand when Claude actually needs them.
- One-click OAuth, no keys to manage.
- Pagination and result summarization are built in — bulk queries do not blow up your context the same way MCP does.

Tradeoff: Claude.ai web cannot write to your vault folder. To save a ticket dump into your vault from the browser, ask Claude to generate a markdown artifact in chat, then save it into the vault manually. For automated vault sync, use Path 1.
</details>

<details>
<summary><strong>Slack</strong> — mentions and DMs (needed for the daily sync)</summary>

```bash
claude mcp add --transport http slack https://mcp.slack.com/mcp
```

First time Claude reaches Slack a browser OAuth tab opens. Sign in with your work Slack account.

The daily sync (`/sync-all`, automated in Step 9) uses this to pull your last-24h mentions and DMs awaiting reply into `Daily/{date}.md`. If you skip Slack, the Daily file will show `_Not connected — skipped._` under the Slack section but still pull Granola and Linear.

Full-history Slack channel archives (channel dumps into `raw-sources/slack/`) are a separate, heavier ingest — defer that until the rest of the loop is working.
</details>

<details>
<summary><strong>Optional MCPs</strong></summary>

Same pattern. Pick any that fit how you work:

```bash
claude mcp add --transport http figma  https://mcp.figma.com/mcp
claude mcp add --transport http mobbin https://api.mobbin.com/mcp
```

| MCP | Used for |
|---|---|
| Figma | Reading Figma frames, Code Connect |
| Mobbin | Competitor and industry screen references |

Skip anything you do not use. You can always add more later. Each MCP triggers its own browser OAuth flow the first time Claude needs it.
</details>

---

## 7. Run the first sync

Start a Claude Code session in the vault:

```bash
brain
```

Then inside Claude Code, run:

```
/sync-granola
```

This pulls every Granola meeting you have, writes raw transcripts to `raw-sources/granola-meetings/`, writes wiki summaries to `wiki/meetings/`, and updates the index. This is the one-time bulk backfill — fills the archive with years of history.

The first run is the heaviest. Subsequent runs take seconds because the command is idempotent (it only fetches what changed).

After this, the **daily incremental** (Step 9) takes over: `/sync-all` running at 10:00 AM every morning adds new meetings to the same `raw-sources/granola-meetings/` folder and writes a `Daily/{date}.md` snapshot. You shouldn't need to run `/sync-granola` again unless something gets out of sync.

If you also want Linear history filed locally, run `/sync-linear` now too (requires the `LINEAR_API_KEY` from Step 6).

<details>
<summary><strong>What to expect on screen</strong></summary>

Terminal output looks like:

```
Granola sync — 2026-05-20
47 new meetings ingested:
  - 2026-05-19 [meeting title] — [headline decision]
  - 2026-05-18 [meeting title] — [headline decision]
  - ...
```

After it finishes, open Obsidian → File → Open vault → pick the vault folder. You will see `wiki/meetings/` filled with summaries and `wiki/people/`, `wiki/projects/`, etc. populated where Claude inferred entities from the transcripts.

Click the graph view icon in the left sidebar. This is the moment the system clicks into place visually.
</details>

<details>
<summary><strong>If something fails</strong></summary>

Sync commands are designed to be fail-soft. A single failure logs to `wiki/log.md` and the chain continues. Common failures:

- **Granola rate-limited.** Wait a few minutes, re-run. Idempotent.
- **MCP not connected.** Run `claude mcp list` to check; re-auth if needed.
- **Permission errors.** Make sure you are running inside the vault folder, not the home directory.

Errors never destroy data. The script never deletes anything. Worst case, you re-run.
</details>

> **If you picked Memory.md Option B in Step 5**, this is the moment to go back. You now have meetings in `raw-sources/granola-meetings/`. Paste the Option B prompt and Claude will draft `Memory.md` from your meeting history.

---

## 8. Daily usage

Assuming you've enabled Step 9's automation, your daily loop is:

1. **Morning — open `Daily/{today}.md` in Obsidian.** The sync wrote it silently at 10:00 AM. Skim the three sections: meetings (with full-transcript wikilinks), Linear issues, Slack mentions + DMs. Two minutes to know what's pending.
2. **Follow wikilinks** as things interest you — clicking a meeting title jumps you into the full transcript in `raw-sources/`; clicking a colleague's name jumps to their wiki page.
3. **Ask the brain** when context matters. Type `brain` in any terminal, then ask. It reads `Memory.md`, `CLAUDE.md`, and `wiki/index.md` silently first, so every answer is grounded in your actual history.
4. **File good answers back** — when Claude synthesizes something useful, tell it `file this as a decision page` or `add this as a concept page`. Explorations compound into the encyclopedia instead of disappearing into chat.
5. **Don't run `/sync-all` manually** unless launchd missed a fire. The job is automatic; the file is fresh when you wake up.

<details>
<summary><strong>What to ask</strong></summary>

Ask the brain when the answer depends on your context:

- "What did [person] say about [topic] at the last call?"
- "Where is the current state of [project]?"
- "What did we decide about [thing]?"
- "Show me every meeting where [concept] came up."
- "Who is working on [project] and what did they say recently?"

Ask Claude (without the vault) for general knowledge that does not need your history.
</details>

<details>
<summary><strong>Saving good answers back into the wiki</strong></summary>

When Claude gives a useful synthesized answer (a comparison, an analysis, a connection you had not seen), tell it:

> file this as a decision page

or

> add this as a concept page

The next session inherits it. Explorations compound into the encyclopedia instead of disappearing into chat history.
</details>

<details>
<summary><strong>When to push back on Claude</strong></summary>

The wiki is a draft, not a verdict. The LLM is wrong sometimes. Watch for:

- **Universal claims** ("every", "all", "always", "never"). Sanity-check before quoting.
- **Old "current state" claims.** A page that says "as of [date]" with a date more than two weeks ago is probably stale.
- **Confident statements on topics you have not filed sources about.** Hallucination territory.

When you spot something wrong, correct Claude in conversation and ask it to update the relevant wiki page. The fix cascades.
</details>

---

## 9. Automate the daily sync

Once you have run `/sync-all` manually a few times and trust what it does, schedule it to fire automatically with macOS `launchd` — the system's native scheduler. It survives reboots, catches up missed runs after sleep, and runs in your real shell with full access to your `claude` binary and your MCPs.

> **Why not Cowork?** Cowork's scheduled tasks run in a sandboxed Claude session that can't see your terminal-side slash commands, MCPs, or shell. `launchd` runs your actual `claude` CLI, so `/sync-all` works end-to-end.

**1. Save the setup script.** From your shell:

```bash
cat > ~/setup-brain-sync.sh <<'SH'
#!/bin/bash
set -euo pipefail

LABEL="com.user.sync-second-brain"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
VAULT_DIR="$HOME/Documents/second-brain"   # ← edit if your vault is elsewhere
LOG_DIR="$VAULT_DIR/.logs"
HOUR=10                                    # 24-hour clock; 10 = 10:00 AM
MINUTE=0

CLAUDE_BIN="$(command -v claude || true)"
[ -z "$CLAUDE_BIN" ] && { echo "claude not in PATH"; exit 1; }

mkdir -p "$LOG_DIR" "$(dirname "$PLIST")"

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
      <string>cd "$VAULT_DIR" && $CLAUDE_BIN -p --dangerously-skip-permissions "/sync-all"</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
      <key>Hour</key><integer>$HOUR</integer>
      <key>Minute</key><integer>$MINUTE</integer>
    </dict>
    <key>RunAtLoad</key><false/>
    <key>StandardOutPath</key><string>$LOG_DIR/sync.out.log</string>
    <key>StandardErrorPath</key><string>$LOG_DIR/sync.err.log</string>
    <key>EnvironmentVariables</key>
    <dict>
      <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
      <key>HOME</key><string>$HOME</string>
    </dict>
</dict>
</plist>
PLIST_EOF

launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID" "$PLIST"
launchctl enable "gui/$UID/$LABEL"
echo "✓ Loaded. Next run: ${HOUR}:$(printf %02d $MINUTE) daily."
SH
```

Edit the `VAULT_DIR` and `HOUR`/`MINUTE` lines at the top of the script to match your vault and preferred time.

**2. Run it once.**

```bash
bash ~/setup-brain-sync.sh
```

You should see `✓ Loaded`.

**3. Test-fire it without waiting until tomorrow.**

```bash
launchctl kickstart -k gui/$UID/com.user.sync-second-brain
```

Wait about a minute, then check that today's file landed:

```bash
ls -la "$HOME/Documents/second-brain/Daily/"
```

A new file dated today should be there. Open it in Obsidian — it should contain your meetings (with full transcripts), open Linear issues, and recent Slack activity from the last 24 hours.

<details>
<summary><strong>Why <code>--dangerously-skip-permissions</code> is in the plist</strong></summary>

Unattended `claude` runs hit a wall: every tool call (MCP search, file write, etc.) normally triggers an interactive permission prompt. In `-p` (print) mode with no user present, those prompts auto-deny and the sync produces an empty file. The `--dangerously-skip-permissions` flag bypasses the gate for that single invocation.

Only use this flag for commands you've reviewed and trust — like `/sync-all`, which only reads from MCPs and writes one file to your vault. Do not paste it into one-off prompts.

</details>

<details>
<summary><strong>Operating the job — verify, logs, change time, uninstall</strong></summary>

```bash
# Confirm it's queued
launchctl print gui/$UID/com.user.sync-second-brain | grep -E 'state|next'

# Tail the logs
tail -f "$HOME/Documents/second-brain/.logs/sync.out.log"
tail -f "$HOME/Documents/second-brain/.logs/sync.err.log"

# Change the time: edit HOUR/MINUTE in setup-brain-sync.sh, then re-run it
bash ~/setup-brain-sync.sh

# Uninstall completely
launchctl bootout gui/$UID/com.user.sync-second-brain
rm ~/Library/LaunchAgents/com.user.sync-second-brain.plist
```

</details>

<details>
<summary><strong>What lands in <code>Daily/</code> — and how it stays connected to the wiki</strong></summary>

Each run writes `Daily/YYYY-MM-DD.md` with three sections:

1. **Meetings** from the last 24 hours — for each one, the sync **also writes a full per-meeting file** to `raw-sources/granola-meetings/{date}-{slug}.md` (matching your existing archive: frontmatter, summary, full verbatim transcript). The Daily file shows the title, attendees, summary, and action items, with `[[wikilinks]]` to (a) the new per-meeting file and (b) any attendee who has a `wiki/people/` page. The Daily file does **not** inline the transcript — it lives in `raw-sources/`.
2. **Linear issues** assigned to you (open, sorted by priority and recency), with direct `linear.app` URLs.
3. **Slack** mentions and DMs awaiting your reply from the last 24 hours, with direct Slack permalinks.

A later run on the same day overwrites the Daily file (latest snapshot wins). Older days stay as a permanent log. The per-meeting files in `raw-sources/` are write-once — if a meeting already has a file (matched by `granola_id`), the sync leaves it alone.

**Net effect on the graph:** Daily files are not orphans. Each one points into `raw-sources/granola-meetings/` and `wiki/people/`, so the new files appear naturally in Obsidian's graph view connected to your existing wiki.

</details>

<details>
<summary><strong>The job runs silently in the background — no UI, no notification</strong></summary>

`launchd` doesn't open a Terminal window, doesn't show a Dock icon, doesn't send a notification when it fires. At your scheduled time the sync just runs invisibly and exits. The only evidence is:

- A new file in `Daily/`
- New per-meeting files in `raw-sources/granola-meetings/` (if any meetings happened)
- An entry in `~/{vault}/.logs/sync.out.log`

**The morning habit that makes this work:** open `Daily/{today}.md` in Obsidian first thing — it's your inbox replacement. Five sections, two minutes to skim, every meeting / ticket / Slack thread you need to know about is there.

If you want explicit feedback that the job ran, add an `osascript` notification call to the plist or have it auto-open today's Daily file. Both are optional. Most people get used to silent operation quickly.

</details>

---

## Optional next steps

<details>
<summary><strong>Set up auto-pull on a second Mac</strong></summary>

If you want to read on one Mac and write on another, a macOS LaunchAgent can run `git pull` hourly in the vault. Ask Claude to set one up for you once the rest of the loop is stable.
</details>

<details>
<summary><strong>Monthly wiki audit (catch stale claims and contradictions)</strong></summary>

The wiki is maintained by an LLM, and LLMs occasionally over-generalize, misremember, or fail to notice when a fact has changed. Once a month, you do a deliberate pass to catch decay.

Open Claude in the vault folder and paste:

```
Scan every page in the wiki/ folder and look for four kinds of decay:

1. Stale claims — anything dated more than 30 days ago that may no longer be true ("as of [date]", "currently", "this week").
2. Contradictions — pages that disagree with each other on the same fact.
3. Over-generalized claims — universals like "every", "all", "always", "never" that may be too sweeping.
4. Drifted statuses — project or ticket status in the wiki that may not match the latest Linear state.

Write the report to wiki/reports/wiki-audit-YYYY-MM-DD.md. Group findings by file, with the questionable quote and your reasoning. Do not edit the wiki — just flag.
```

Read the report in Obsidian. Fix anything wrong by hand.

Manual on purpose for the first few months — Claude over-generalizes and the corpus is still young, so you stay in the loop. Once the recurring patterns settle, you can copy the Step 9 launchd plist, point it at `/wiki-refresh` instead of `/sync-all`, and schedule it for, say, the first day of each month.

</details>

---

## Troubleshooting

<details>
<summary><strong>"brain: command not found"</strong></summary>

The alias did not load. Run `source ~/.zshrc`, or close and reopen the terminal.
</details>

<details>
<summary><strong>MCP shows "Needs authentication"</strong></summary>

Inside Claude Code: `/mcp` → pick the broken MCP → follow the browser flow. Tokens expire periodically; this is normal.
</details>

<details>
<summary><strong>Claude does not seem to know about the vault</strong></summary>

Two common causes:

1. You ran `claude` from the wrong folder. Confirm with `pwd` inside the session — should be the vault path.
2. `CLAUDE.md` has a double extension (`CLAUDE.md.md`). Check with `ls CLAUDE.md*` in the vault folder, rename if needed.
</details>

<details>
<summary><strong>Granola rate-limited</strong></summary>

Wait a few minutes and re-run. The sync is idempotent and will pick up where it left off.
</details>

<details>
<summary><strong>Linear sync says "skipped — set LINEAR_API_KEY first"</strong></summary>

The env var is not set in the shell where you are running Claude. Either:

```bash
export LINEAR_API_KEY=lin_api_…
```

…right before running `/sync-linear`, OR add the line to `~/.zshrc` permanently and reload (`source ~/.zshrc`).
</details>

<details>
<summary><strong>Long sync gets killed when the laptop sleeps</strong></summary>

Run this in another terminal first:

```bash
caffeinate -d &
```

…then run the sync. Kill `caffeinate` after with `kill %1`.
</details>

<details>
<summary><strong>Daily file is empty / sync skipped every source</strong></summary>

When `claude` runs in `-p` (print) mode with no user present, every tool call (MCP search, file write) normally triggers an interactive permission prompt — and those auto-deny when nobody's around to answer. Result: empty file, all sources marked "skipped — permission denied" in the stderr log.

Fix: the launchd plist must invoke claude with `--dangerously-skip-permissions`. Check that line in `~/Library/LaunchAgents/com.user.sync-second-brain.plist` (Step 9). If you wrote the plist without it, edit `~/setup-brain-sync.sh` and re-run.

The flag is only safe for slash commands you've reviewed (like `/sync-all`). Don't put it in plists that run untrusted prompts.
</details>

<details>
<summary><strong>Wikilinks in the Daily file don't resolve (Obsidian shows them dimmed)</strong></summary>

Three causes, in likelihood order:

1. **The target file doesn't exist yet.** Wikilinks like `[[Person Name]]` only resolve if `wiki/people/Person Name.md` exists. Dimmed links are a normal "red-link" state — they tell Claude to consider creating that page on the next `/wiki-refresh`.
2. **Obsidian's link format setting is wrong.** Open Obsidian → Settings → Files & Links → New link format → set to "Shortest path when possible". Then Settings → Files & Links → "Use [[Wikilinks]]" → ON.
3. **The sync ran before `wiki/people/` was populated.** Run `/sync-granola` first (it creates people pages from meeting attendees), then re-run `/sync-all`.
</details>

<details>
<summary><strong>Launchd job loaded but never fires</strong></summary>

Check the queued state:

```bash
launchctl print gui/$UID/com.user.sync-second-brain | grep -E 'state|next'
```

- `state = waiting` and a future `next` timestamp → the job is queued correctly. It only fires at the scheduled time; it does **not** fire on load (we set `RunAtLoad = false` to avoid surprise runs on boot).
- No `next` line → the plist may have a syntax error. Validate with `plutil -lint ~/Library/LaunchAgents/com.user.sync-second-brain.plist`.
- Job ran but no file → see "Daily file is empty" above.

To force-fire it now without waiting: `launchctl kickstart -k gui/$UID/com.user.sync-second-brain`.
</details>
