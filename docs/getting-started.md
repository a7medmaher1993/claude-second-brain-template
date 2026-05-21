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

1. Holds every meeting you've recorded as plain markdown (with full verbatim transcripts) — via whatever transcription service you use.
2. Holds every task or ticket from your project tracker, refreshed on demand.
3. Has a Claude-maintained wiki of people, projects, decisions, and concepts, all cross-linked.
4. Produces a **daily inbox** every morning at 10:00 AM — last 24h of meetings, tasks, and chat activity — without you doing anything.
5. Opens in Obsidian as a navigable graph.
6. Opens in Claude Code so you can ask questions about your own work and get answers grounded in your real history.

You drive it with four slash commands, one shell alias, and one `launchd` job that fires the sync every morning. **You pick which external services it pulls from** — the pattern is generic; Step 6 lists 85+ MCPs across categories so you can wire up whichever stack you actually use.

---

## How it all connects

Before you start setting up, here's the shape of what you're building. Five moving parts:

1. **External sources** — whichever services you want pulled in. Meetings (e.g. Granola, Otter, Fathom), tasks (Linear, Jira, Asana, Notion), chat (Slack, Discord, Teams), plus optionally email, calendar, docs, code, CRM. They live outside the vault. Claude reaches them through MCPs (Step 6 lists 85+ options).
2. **`raw-sources/`** — the immutable archive. One markdown file per meeting (with frontmatter + full verbatim transcript), one per task / ticket export, one per chat channel dump, one per anything else you ingest. Claude reads from here; nothing else writes to it except the sync commands.
3. **`wiki/`** — the curated synthesis. People, projects, concepts, decisions, reports. Cross-linked. This is what you actually read day-to-day. Claude maintains it.
4. **`Daily/`** — your morning inbox. One file per day, written by `/sync-all`. Last 24 hours of meetings (with `[[wikilinks]]` into `raw-sources/` and `wiki/people/`), tasks assigned to you, chat mentions + DMs awaiting reply.
5. **`CLAUDE.md` + `Memory.md`** — read every session before Claude responds. CLAUDE.md says how the system works; Memory.md says who you are.

The daily loop, in one line:

> at 10:00 AM `launchd` runs `/sync-all` silently → it writes today's `Daily/{date}.md` + adds any new meetings to `raw-sources/meetings/` → you open `Daily/{today}.md` in Obsidian over coffee → wikilinks pull you into the rest of the wiki when something interests you.

The bulk loop, for backfills:

> `/sync-{meetings}` and `/sync-{tasks}` pull full history into `raw-sources/`. `/wiki-refresh` curates the wiki — promoting red-links to pages, fixing drift. You run these manually, occasionally.

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
│   └── 2026-05-21.md          today's meetings, tasks, chat mentions
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
│   ├── {meetings}/            one .md per meeting (frontmatter + full transcript) — folder named after your meeting service
│   ├── {tasks}/               task / ticket exports — folder named after your tracker
│   └── {chat}/                chat channel archives (opt-in) — folder named after your chat service
│
├── .claude/commands/          your slash commands
│   ├── sync-{meetings}.md     e.g. sync-granola.md, sync-otter.md, sync-fathom.md (created in Step 4b)
│   ├── sync-{tasks}.md        e.g. sync-linear.md, sync-jira.md, sync-asana.md (created in Step 4b)
│   ├── sync-all.md            ships as a template — customize for your sources
│   └── wiki-refresh.md        ships as a template — read-only wiki audit
│
├── scripts/                   ready-to-run setup scripts (edit knobs at top)
│   ├── install-brain-sync.sh        daily /sync-all via launchd (Step 9)
│   └── install-cross-device-pull.sh hourly git pull on secondary devices
│
├── .github/workflows/         CI — weekly link-check on the docs
├── .logs/                     launchd job logs (Step 9 creates this)
├── LICENSE                    MIT
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

**Folders:**
- `raw-sources/` and category subfolders for whichever services you'll connect in Step 6. Examples: `raw-sources/granola-meetings/` (or `otter-meetings/`, `fathom-meetings/` — whatever you use), `raw-sources/linear/` (or `jira/`, `asana/`, `notion/`), `raw-sources/slack/` (or `discord/`, `teams/`). The folder name should match the source — one folder per service.
- `wiki/people/`, `wiki/projects/`, `wiki/meetings/`, `wiki/decisions/`, `wiki/concepts/`, `wiki/reports/`.
- `Daily/` with a `.keep` file inside so the folder commits cleanly when empty.

**Placeholder files:**
- `wiki/index.md` (empty catalog placeholder).
- `wiki/log.md` (empty log placeholder).

**Slash commands** — one per source you plan to connect, plus the daily aggregator:

- `.claude/commands/sync-{meetings}.md` (e.g. `sync-granola.md`) — pulls new meetings into `raw-sources/{source}-meetings/` with full verbatim transcripts, not just summaries. If your meeting service offers a transcript tool, use it.
- `.claude/commands/sync-{tasks}.md` (e.g. `sync-linear.md`) — refreshes the ticket / task archive into `raw-sources/{source}/`.
- (optional, one per other source you want bulk pulls for — e.g. sync-notion, sync-gmail.)
- `.claude/commands/sync-all.md` — **daily snapshot** (last 24h window, not full history). Writes `Daily/{YYYY-MM-DD}.md` with one section per connected source: a Meetings section (from whatever meeting MCP), a Tasks section (issues/tickets assigned to me), a Chat section (mentions + DMs awaiting reply), plus any other sources I've added. For each meeting in the window: also write a full per-meeting file to `raw-sources/{source}-meetings/{date}-{slug}.md` with frontmatter (including `{source}_id` field), summary, action items, and full verbatim transcript — idempotent by `{source}_id` so re-runs don't double-write. In the Daily file's Meetings section, link to those per-meeting files with `[[../raw-sources/{source}-meetings/{date}-{slug}|{title}]]` and link attendees as `[[Name]]` when `wiki/people/{Name}.md` exists. For each source: if the MCP isn't connected or returns an auth error, write `_Not connected — skipped._` under that section and continue. This is the skill the launchd job in Step 9 invokes daily; it's also safe to run manually.
- `.claude/commands/wiki-refresh.md` — cross-link audit, red-link promotion candidates, index drift, orphan check.
- `.gitignore` — excludes `Memory.md`, `.claude/.credentials*`, `*.log`, `.obsidian/workspace*`.

Each slash command should be idempotent (re-running with no new sources is a no-op), quiet by default (only print at meaningful checkpoints), and fail-soft (one step failing logs to `wiki/log.md` and the chain continues).

> **Note:** the prompt above uses Granola, Linear, and Slack as examples because they're popular. Substitute the services you actually use — see Step 6 for 85+ MCP options across categories. Claude will adapt the slash commands to whatever you tell it to use.

> **Shortcut if you cloned the template:** `.claude/commands/sync-all.md` and `.claude/commands/wiki-refresh.md` already ship as starter templates with the right structure. You can either (a) use the prompt above to have Claude regenerate them customized to your stack, or (b) skip the prompt and just edit those two files directly. The templates have placeholder source names (`{source}`) and generic categories; replace with the services you connected in Step 6.
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
| `/sync-{meetings}` | Pulls new meetings — **full verbatim transcripts**, notes, and action items — into `raw-sources/{source}-meetings/`, plus wiki summaries. Example: `/sync-granola`, `/sync-otter`. |
| `/sync-{tasks}` | Refreshes the task / ticket archive from your project tracker. Example: `/sync-linear`, `/sync-jira`, `/sync-asana`. |
| `/sync-all` | **Daily snapshot** — last 24h of meetings, tasks, and chat mentions/DMs into `Daily/{date}.md`. Also writes each new meeting to `raw-sources/{source}-meetings/` and cross-links via `[[wikilinks]]`. This is the skill the Step 9 launchd job runs daily. |
| `/wiki-refresh` | Audits cross-links, red-links, orphans after an ingest |

You only need the ones you use. Most people start with one meeting sync + one task sync, then add more sources later.
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

MCP stands for **Model Context Protocol**. It's the bridge that lets Claude read external services (meetings, tasks, chat, email, anything) as if they were native tools. You pick which ones to connect — the pattern works with any combination.

<details>
<summary><strong>Quick framing — API vs MCP vs Connector (worth reading once)</strong></summary>

Three layers of the same stack, not three alternatives.

| Layer | Where it runs | What it is | Best for |
|---|---|---|---|
| **API** (raw GraphQL / REST) | Your scripts | The service's actual door. Universal, lowest level. You handle auth, pagination, rate limits. | Bulk one-time exports. Recurring automation. Sync commands that talk to a service's GraphQL directly. No tokens burned. |
| **MCP** (Model Context Protocol) | Claude Code (terminal) | A wrapper around the API that exposes tools the model can call. | Claude in the terminal working alongside your filesystem, git, IDE. |
| **Connector** | Claude.ai web / mobile | Productized MCP with one-click OAuth, deferred loading, and a UI toggle. Under the hood it's still MCP. | Casual ticket / doc lookups in the browser when you are not in the terminal. |

**Watch out for two MCP gotchas:**

1. **Schema bloat.** Older Claude Code versions eagerly load every MCP tool's full schema into the context window at session start, before you have sent a message. Stack three or four servers and 50k+ tokens vanish before you type. Newer Claude Code defers loading (Tool Search). Run `/context` in a fresh session to check.
2. **Result pollution.** Asking an MCP for "all tickets" or any unfiltered list dumps every record's full JSON into context and re-sends it on every subsequent turn. Always filter — by assignee, state, cycle, label, or last-N-days.

**Rule of thumb:** go up the stack until you have enough power, then stop.

- Vault sync → API path (fastest, cheapest).
- Interactive use while you are in Claude Code → MCP path.
- Browser-based lookups when you are not in the terminal → Connector path.

</details>

### How to register an MCP

From your shell (inside the vault folder, or anywhere if you use `--scope user`):

```bash
claude mcp add --transport http <name> <url>
```

That's the shape for **hosted (HTTP) MCPs** — the vendor runs the server, you just point Claude at it. First time Claude uses each one, a browser tab opens for OAuth. That's the only browser step.

For **stdio MCPs** (community servers that run locally as a subprocess), the shape differs — usually `claude mcp add <name> -- npx -y <package>` with env vars for credentials. Each table row below gives the exact command.

Verify your registrations any time with:

```bash
claude mcp list
```

### Pick your stack — ~85 MCPs across 13 categories

You don't need them all. Most readers wire up 3–6: a meeting tool, a task tracker, a chat tool, maybe email/calendar. **The first three categories below are the core of the daily sync** — everything else is optional power-ups.

**Type column key:**
- **Official** = vendor builds and hosts the MCP. Most reliable.
- **Community** = third-party. Read the linked repo before installing — names, flags, and packages drift.
- **(none)** = no MCP exists yet — use the vendor's API directly, skip, or wait.

#### Core trio (the daily sync uses these)

<details>
<summary><strong>Meetings & transcription</strong> — 13 options</summary>

| Service | Type | `claude mcp add` command | What it exposes |
|---|---|---|---|
| Granola | Official | `claude mcp add --transport http granola https://mcp.granola.ai/mcp` | Lists meetings, fetches full verbatim transcripts, browses folders; OAuth |
| Otter.ai | Official | `claude mcp add --transport http otter https://mcp.otter.ai/mcp` | Full-text search and retrieval of meeting transcripts |
| Fathom | Community | `claude mcp add fathom -e FATHOM_API_KEY=<key> -- node /path/to/fathom-mcp/dist/index.js` | List/search meetings, fetch transcripts and action items, export, webhooks |
| Fireflies.ai | Official | `claude mcp add --transport http fireflies https://api.fireflies.ai/mcp` | Meeting transcripts, summaries, action items, speaker metadata |
| tl;dv | Official | `claude mcp add tldv -e TLDV_API_KEY=<key> -- npx -y @tldv/tldv-mcp-server` | List meetings, fetch transcripts and AI highlights across Google Meet, Zoom, MS Teams (Business/Enterprise plan) |
| Read.ai | Official (open beta) | Add as custom connector via Claude UI — URL distributed in Read.ai's MCP help article | Read.ai meeting summaries, transcripts, action items |
| Krisp | Official | `claude mcp add --transport http krisp https://mcp.krisp.ai/mcp` | 14 tools: transcript ops, knowledge graph queries, productivity actions |
| Grain | Official | `claude mcp add --transport http grain https://api.grain.com/_/mcp` | Meetings, recordings, transcripts, deals, coaching scorecards (paid plans) |
| Avoma | Official | `claude mcp add avoma -- npx mcp-remote https://mcp.avoma.com/mcp --header "Authorization: Bearer <key>"` | Transcripts, notes, deal insights |
| Sembly | Official | `claude mcp add --transport http sembly https://mcp.sembly.ai/mcp` (EU: `mcp-eu.sembly.ai`) | Search and read meetings, summaries, key points, action items |
| Tactiq | (none) | — | No first-party MCP; only third-party bridges (Zapier, viaSocket) |
| Modjo | (none public) | — | Marketing mentions MCP, no public endpoint published |
| Loom | (none official) | — | No vendor MCP; community variants exist for video download |

</details>

<details>
<summary><strong>Tasks & project tracking</strong> — 14 options</summary>

| Service | Type | `claude mcp add` command | What it exposes |
|---|---|---|---|
| Linear | Official | `claude mcp add --transport http linear https://mcp.linear.app/mcp` | Issues, projects, teams, cycles, labels, comments, initiatives, milestones (read + write) |
| Jira / Confluence (Atlassian) | Official | `claude mcp add --transport http atlassian https://mcp.atlassian.com/v1/mcp` | Jira issues, Confluence pages, Compass components; OAuth |
| Asana | Official | `claude mcp add --transport http asana https://mcp.asana.com/v2/mcp` | Tasks, projects, portfolios, teams, comments, attachments; requires OAuth client ID + secret |
| Notion | Official | `claude mcp add --transport http notion https://mcp.notion.com/mcp` | Pages, databases, comments, workspace search (read + write) |
| ClickUp | Official | `claude mcp add --transport http clickup https://mcp.clickup.com/mcp` | Tasks, lists, folders, docs, time entries, comments, chat (public beta) |
| Monday.com | Official (stdio) | `claude mcp add monday-api-mcp -- npx @mondaydotcomorg/monday-api-mcp@latest -e MONDAY_TOKEN=<token>` | Boards, items, columns, updates, users |
| Shortcut | Official | `claude mcp add --transport http shortcut https://mcp.shortcut.com/mcp` | Stories, epics, iterations, labels, custom fields, objectives, teams, projects |
| Todoist | Official (Doist) | `claude mcp add --transport http todoist https://ai.todoist.net/mcp` | Tasks, projects, labels, filters, comments |
| Airtable | Official | `claude mcp add --transport http airtable https://mcp.airtable.com/mcp` | Bases, tables, fields, records, interfaces |
| Smartsheet | Official | `claude mcp add --transport http smartsheet https://mcp.smartsheet.com -H "Authorization: Bearer $SMARTSHEET_API_TOKEN"` | Sheets, rows, columns, workspaces, attachments (Business/Enterprise) |
| Trello | Community | `claude mcp add trello -- npx -y @delorenj/mcp-server-trello` (Trello API key + token env vars) | Boards, lists, cards, checklists, labels, comments |
| Basecamp | Community | `claude mcp add basecamp -- npx -y basecamp-mcp` (37signals OAuth app) | Projects, todos, messages, comments, schedules |
| Pivotal Tracker | (none / router only) | Use a Composio/Pipedream router URL | Limited — typically just create project / create story |
| Height | (shut down) | — | Height ceased operations Sept 2025 |

</details>

<details>
<summary><strong>Chat & messaging</strong> — 12 options</summary>

| Service | Type | `claude mcp add` command | What it exposes |
|---|---|---|---|
| Slack | Official | `claude mcp add --transport http slack https://mcp.slack.com/mcp` | Search, read/send messages, channels, DMs, mentions, canvases |
| Discord | Community | `claude mcp add discord -e DISCORD_BOT_TOKEN=<token> -- npx -y discord-mcp@latest` | Send/read channel messages, manage channels, roles, reactions, webhooks (self-hosted bot) |
| Microsoft Teams | Official (Work IQ, preview) | `claude mcp add --transport http teams https://agent365.svc.cloud.microsoft/agents/tenants/<TENANT>/mcp_TeamsServer` | Chats, channels, messages, members (M365 Copilot license; tenant-scoped) |
| Mattermost | Community | `claude mcp add mattermost -e MATTERMOST_URL=<url> -e MATTERMOST_TOKEN=<token> -- npx -y @cloud-ru-tech/mcp-server-mattermost` | Read/send messages, manage channels, search, file uploads |
| Telegram | Community | `claude mcp add telegram -- npx -y @chaindead/telegram-mcp` (MTProto; API ID/hash + login) | Personal-account access: read/send messages, manage dialogs, drafts, search |
| WhatsApp | Community | `claude mcp add whatsapp -- uv --directory /path/to/whatsapp-mcp/whatsapp-mcp-server run main.py` (Go bridge required) | Search and read personal messages, contacts, send to people/groups |
| Signal | Community | `claude mcp add signal -- uvx signal-mcp` (reads from local Signal Desktop) | Read Signal Desktop chats and attachments |
| Rocket.Chat | Community | Docker-based; see `enyonee/rocketchat-mcp` README | Channels, messages, threads, DMs, reactions, search (~28 tools) |
| Zulip | Community | `claude mcp add zulip -- npx -y @modelcontextprotocol/server-zulip` (Zulip site + API key) | Send/read messages, search history, resolve users, monitor streams |
| Element / Matrix | Community | `claude mcp add --transport http matrix http://localhost:3000/mcp` (self-hosted) | List rooms, read message history, search across rooms (15 tools) |
| Twist | Official (Doist) | `claude mcp add twist -- npx -y @doist/twist-ai` (Twist API token env var) | User info, inbox threads, load thread/conversation, read comments |
| Google Chat | Community | `claude mcp add gchat -- npx -y google-chat-mcp-server` (Google OAuth credentials) | List spaces, read/send messages, list members |

</details>

#### Communication & calendar

<details>
<summary><strong>Email</strong> — 6 options</summary>

| Service | Type | `claude mcp add` command | What it exposes |
|---|---|---|---|
| Gmail | Official (Google) | `claude mcp add --transport http gmail https://gmailmcp.googleapis.com/mcp/v1` | Search emails, threads, labels, drafts (BYO OAuth client) |
| Outlook / Microsoft 365 Mail | Official (Claude built-in Connector) | Enable via Claude Settings → Connectors → Microsoft 365 | Outlook mail via delegated Graph |
| Fastmail | Official | `claude mcp add --transport http fastmail https://api.fastmail.com/mcp` | Email, contacts, calendar via JMAP; OAuth with read/write/send |
| ProtonMail | Community | See `amotivv/protonmail-mcp` (SMTP send) or `jongaydos/protonmail-mcp-server-for-claude-code` (Proton Bridge) | Send via SMTP or full mailbox access via local Proton Bridge |
| Apple Mail (macOS) | Community | See `s-morgan-jeffries/apple-mail-mcp`, `jxnl/apple-mcp` (AppleScript) | Read, send, search local Apple Mail |
| iCloud Mail | Community | See `adamzaidi/icloud-mcp`, `iteratio/icloud-mcp` (IMAP + app-specific password) | iCloud mail |

</details>

<details>
<summary><strong>Calendar</strong> — 7 options</summary>

| Service | Type | `claude mcp add` command | What it exposes |
|---|---|---|---|
| Google Calendar | Official (Google) | `claude mcp add --transport http gcal https://calendarmcp.googleapis.com/mcp/v1` | Events: list/create/update/delete; availability checks; OAuth |
| Outlook / Microsoft 365 Calendar | Official (Claude built-in Connector) | Enable via Claude Settings → Connectors → Microsoft 365 | Calendar via delegated Graph |
| Apple Calendar (iCloud) | Community | See `iteratio/icloud-mcp` (CalDAV + app-specific password) | Read/create/update iCloud Calendar events |
| Cal.com | Official | `claude mcp add --transport http calcom https://mcp.cal.com/mcp` | Bookings, event types, schedules, availability |
| Calendly | Official | `claude mcp add --transport http calendly https://mcp.calendly.com` | Find slots, create/cancel meetings, manage event types |
| Fantastical | Official (Claude built-in Connector) | Enable via Claude Settings → Connectors → Browse → Fantastical (Mac, Claude 4.1.10+) | Local Fantastical app events |
| Fastmail Calendar | Covered by Fastmail MCP above | — | — |

</details>

<details>
<summary><strong>Docs & notes</strong> — 11 options</summary>

| Service | Type | `claude mcp add` command | What it exposes |
|---|---|---|---|
| Notion | Official | `claude mcp add --transport http notion https://mcp.notion.com/mcp` | Pages, databases, comments; OAuth |
| Atlassian (Confluence + Jira) | Official | `claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse` | Confluence pages, Jira issues, Compass; OAuth 2.1 |
| Google Drive | Official (Google) | `claude mcp add --transport http gdrive https://drivemcp.googleapis.com/mcp/v1` | List, read, manage Drive files (BYO OAuth client) |
| Google Docs | Use Google Drive MCP above, or community `a-bonus/google-docs-mcp` (stdio) | — | Drive MCP covers read; community adds editing |
| Dropbox | Official | `claude mcp add --transport http dropbox https://mcp.dropbox.com/mcp` | Files: search, upload, read, organize, delete |
| Microsoft 365 (SharePoint + OneDrive) | Official (Claude built-in Connector) | Enable via Claude Settings → Connectors → Microsoft 365 | SharePoint, OneDrive, Teams chats/meetings, Outlook |
| Coda | Community | `claude mcp add coda -- npx -y coda-mcp@latest` (API_KEY env var) | Coda docs, tables, pages, permissions |
| Obsidian | Community | `claude mcp add obsidian -- npx -y obsidian-mcp` (varies by maintainer) | Vault read/write, full-text search, backlinks, tags |
| Roam Research | Official | `claude mcp add roam -- npx -y @roam-research/roam-tools` (local Roam HTTP API) | Read/write/organize Roam graph |
| OneNote | Community | See `purpleslurple/onenote-mcp-server` README | OneNote notebooks via Microsoft Graph |
| Evernote | Community | See `brentmid/evernote-mcp-server` README | Note search, read, sync |

</details>

#### Work tools

<details>
<summary><strong>Code hosting</strong> — 4 options</summary>

| Service | Type | `claude mcp add` command | What it exposes |
|---|---|---|---|
| GitHub | Official | `claude mcp add --transport http github https://api.githubcopilot.com/mcp` | Repos, issues, PRs, code search, Actions |
| GitLab | Official | `claude mcp add --transport http gitlab https://gitlab.com/api/v4/mcp` (self-hosted: swap base URL) | Projects, repos, issues, MRs, CI/CD |
| Sourcegraph | Official (Enterprise) | `claude mcp add --transport http sourcegraph https://<your-instance>.sourcegraph.com/.api/mcp/v1` | Cross-repo code search, go-to-def, references, Deep Search |
| Bitbucket | Official (via Atlassian Rovo) | `claude mcp add --transport http atlassian https://mcp.atlassian.com/v1/sse` (one Rovo MCP covers Bitbucket + Jira + Confluence) | Workspaces, repos, branches, PRs, pipelines |

</details>

<details>
<summary><strong>Design</strong> — 6 options</summary>

| Service | Type | `claude mcp add` command | What it exposes |
|---|---|---|---|
| Figma | Official | `claude mcp add --transport http figma https://mcp.figma.com/mcp` | Read design context, screenshots, components; write designs; Code Connect |
| Sketch | Official (Sketch 2025.2.4+) | `claude mcp add --transport stdio sketch -- npx -y @sketch-hq/mcp-server` | Read/write Sketch documents via SketchAPI scripting |
| Penpot | Official | `claude mcp add --transport http penpot http://localhost:4401/mcp` (pairs with Penpot MCP plugin) | Read/modify/create design data in a Penpot file |
| Pencil (OpenPencil) | Official | `claude mcp add --transport stdio pencil -- npx -y @open-pencil/mcp-server` (HTTP also on port 7601) | Read & write `.pen` files: components, tokens, layout |
| Mobbin | Official | `claude mcp add --scope user --transport http mobbin https://api.mobbin.com/mcp` | 621k+ real app screens, 142k+ flows for design reference |
| Adobe XD | (none) | — | Adobe XD is in extended maintenance; no MCP |

</details>

<details>
<summary><strong>CRM</strong> — 6 options</summary>

| Service | Type | `claude mcp add` command | What it exposes |
|---|---|---|---|
| Salesforce | Official | `claude mcp add --transport http salesforce https://api.salesforce.com/platform/mcp/v1/platform/sobject-all` (External Client App + OAuth/PKCE) | sObjects, Flows, Invocable Actions, Data 360, Prompt Builder |
| HubSpot | Official (beta) | `claude mcp add --transport http --scope user hubspot https://mcp.hubspot.com/anthropic` | Contacts, companies, deals, tickets, products, invoices, quotes |
| Attio | Official | `claude mcp add --transport http attio https://mcp.attio.com/mcp` | People, companies, deals, tasks, notes, meetings, calls, emails |
| Close | Official | `claude mcp add --transport http close https://mcp.close.com/mcp` | Leads, opportunities, activities, templates, org data |
| Pipedrive | Community | `claude mcp add pipedrive -e PIPEDRIVE_API_TOKEN=<token> -- npx -y @iamsamuelfraga/mcp-pipedrive` | Deals, leads, activities, pipelines (API v2) |
| Copper | (none) | — | Only via third-party gateways (viaSocket, Pipedream, Composio) |

</details>

<details>
<summary><strong>Customer support / help desks</strong> — 5 options</summary>

| Service | Type | `claude mcp add` command | What it exposes |
|---|---|---|---|
| Intercom | Official (US workspaces) | `claude mcp add --transport http intercom https://mcp.intercom.com/mcp` | Conversations, contacts, tickets, Fin data |
| Zendesk | Community | `claude mcp add zendesk -e ZENDESK_SUBDOMAIN=<sub> -e ZENDESK_EMAIL=<email> -e ZENDESK_API_KEY=<key> -- uvx zendesk-mcp-server` | Tickets, comments, Help Center articles |
| Help Scout | Community | `claude mcp add helpscout -e HELPSCOUT_APP_ID=<id> -e HELPSCOUT_APP_SECRET=<secret> -- npx -y @drewburchfield/help-scout-mcp-server` | Conversations, customers, mailboxes, support analytics |
| Front | Community | `claude mcp add frontapp -e FRONT_API_KEY=<key> -- npx -y @zqushair/frontapp-mcp` | Conversations, contacts, accounts, tags, webhooks |
| Freshdesk | Community | `claude mcp add freshdesk -e FRESHDESK_API_KEY=<key> -e FRESHDESK_DOMAIN=<domain> -- uvx freshdesk-mcp` | Tickets, contacts, agents, companies, conversations |

</details>

<details>
<summary><strong>Analytics, observability & dev tools</strong> — 8 options</summary>

| Service | Type | `claude mcp add` command | What it exposes |
|---|---|---|---|
| Sentry | Official | `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` | Issues, events, projects, releases, performance data |
| Datadog | Official | `claude mcp add --transport http datadog https://mcp.datadoghq.com/api/unstable/mcp-server/mcp` (EU: `mcp.datadoghq.eu`; needs `DD-API-KEY` + `DD-APPLICATION-KEY`) | APM, logs, metrics, monitors, dashboards, security signals |
| PostHog | Official | `claude mcp add --transport http posthog https://mcp.posthog.com/mcp` | Events, insights, feature flags, session replays, experiments |
| Mixpanel | Official (beta) | `claude mcp add --transport http mixpanel https://mcp.mixpanel.com/mcp` (EU/IN regions available) | Events, funnels, flows, retention, session replays, Boards |
| Amplitude | Official (beta) | `claude mcp add --transport http amplitude https://mcp.amplitude.com/mcp` | Charts, dashboards, experiments, cohorts, session replay search |
| Statsig | Official | `claude mcp add --transport http statsig https://api.statsig.com/v1/mcp` | Feature gates, experiments, dynamic configs, layers |
| LaunchDarkly | Official | `claude mcp add launchdarkly -e LAUNCHDARKLY_API_KEY=<key> -- npx -y @launchdarkly/mcp-server` (or hosted URL from your account) | Feature flags, environments, AgentControl configs, observability |
| Stripe | Official | `claude mcp add --transport http stripe https://mcp.stripe.com` | Customers, charges, subscriptions, invoices + docs/KB search |

</details>

<details>
<summary><strong>Web search & research</strong> — 5 options</summary>

| Service | Type | `claude mcp add` command | What it exposes |
|---|---|---|---|
| Exa | Official | `claude mcp add --transport http exa https://mcp.exa.ai/mcp` | Web search, content extraction, research, Websets |
| Brave Search | Community (Anthropic reference) | `claude mcp add brave-search -e BRAVE_API_KEY=<key> -- npx -y @modelcontextprotocol/server-brave-search` | Web, image, video, news, local search |
| Tavily | Official | `claude mcp add --transport http tavily "https://mcp.tavily.com/mcp/?tavilyApiKey=<key>"` | Search, extract, map, crawl |
| Firecrawl | Official | `claude mcp add firecrawl -e FIRECRAWL_API_KEY=<key> -- npx -y firecrawl-mcp` (hosted: `https://mcp.firecrawl.dev/<key>/v2/mcp`) | Scrape, crawl, map, deep research, batch |
| Perplexity | Official | `claude mcp add perplexity -e PERPLEXITY_API_KEY=<key> -- npx -y @perplexity-ai/mcp-server` | Sonar real-time web search + deep research |

</details>

<details>
<summary><strong>Storage / files</strong> — 2 options</summary>

| Service | Type | `claude mcp add` command | What it exposes |
|---|---|---|---|
| AWS S3 | Official | `claude mcp add aws-s3 -- uvx awslabs.s3-mcp-server@latest` (uses local AWS credentials) | List/get/put/delete buckets and objects |
| Cloudflare R2 | Official | `claude mcp add --transport sse cloudflare-bindings https://bindings.mcp.cloudflare.com/sse` (Bindings server covers R2 + KV + D1) | R2 buckets + objects |

</details>

### Special case — direct API access for bulk syncs

For high-volume pulls (refreshing thousands of records at once), the **vendor's direct API** is often better than MCP: faster, no token cost, no context pollution. Store an API key in an env var and have your sync skill talk to the API directly via the Bash tool.

Linear example — the same pattern applies to any service with a stable GraphQL/REST API:

```bash
echo 'export LINEAR_API_KEY=lin_api_YOUR_KEY' >> ~/.zshrc
source ~/.zshrc
```

Now `/sync-linear` can call Linear's GraphQL directly with `curl -H "Authorization: $LINEAR_API_KEY" …`, no MCP involved. Faster + cheaper + no context bloat from large result sets. The MCP path is still useful for interactive ticket lookups — just not for bulk archives.

> **Picking your first MCPs:** if you don't know where to start, the most common starter stack is one **meeting** MCP + one **task tracker** MCP + one **chat** MCP. Add email/calendar/docs once the daily sync is running and you want more in `Daily/{date}.md`.

---

## 7. Run the first sync

Start a Claude Code session in the vault:

```bash
brain
```

Then inside Claude Code, run your **meeting sync** to pull historical transcripts. The command name matches whatever you named it in Step 4b:

```
/sync-{meetings}
```

For example, `/sync-granola`, `/sync-otter`, `/sync-fathom` — whichever meeting service you connected in Step 6.

This pulls every meeting you have, writes raw transcripts to `raw-sources/{source}-meetings/`, writes wiki summaries to `wiki/meetings/`, and updates the index. This is the one-time bulk backfill — fills the archive with years of history.

The first run is the heaviest. Subsequent runs take seconds because the command is idempotent (only fetches what changed).

After this, the **daily incremental** (Step 9) takes over: `/sync-all` running at 10:00 AM every morning adds new meetings to the same `raw-sources/{source}-meetings/` folder and writes a `Daily/{date}.md` snapshot. You shouldn't need to run the bulk command again unless something gets out of sync.

**If you also want task / ticket history filed locally**, run `/sync-{tasks}` now too (e.g. `/sync-linear`). For services with a stable API (Linear, Jira), this often uses an API key for speed — see the "Special case" at the end of Step 6.

<details>
<summary><strong>What to expect on screen</strong></summary>

Terminal output looks like:

```
{Source} sync — 2026-05-21
47 new meetings ingested:
  - 2026-05-20 [meeting title] — [headline decision]
  - 2026-05-19 [meeting title] — [headline decision]
  - ...
```

After it finishes, open Obsidian → File → Open vault → pick the vault folder. You'll see `wiki/meetings/` filled with summaries and `wiki/people/`, `wiki/projects/`, etc. populated where Claude inferred entities from the transcripts.

Click the graph view icon in the left sidebar. This is the moment the system clicks into place visually.
</details>

<details>
<summary><strong>If something fails</strong></summary>

Sync commands are designed to be fail-soft. A single failure logs to `wiki/log.md` and the chain continues. Common failures:

- **Rate-limited by the vendor.** Wait a few minutes, re-run. Idempotent.
- **MCP not connected.** Run `claude mcp list` to check; re-auth if needed.
- **Permission errors.** Make sure you are running inside the vault folder, not the home directory.

Errors never destroy data. The script never deletes anything. Worst case, you re-run.
</details>

> **If you picked Memory.md Option B in Step 5**, this is the moment to go back. You now have meetings in `raw-sources/{source}-meetings/`. Paste the Option B prompt and Claude will draft `Memory.md` from your meeting history.

---

## 8. Daily usage

Assuming you've enabled Step 9's automation, your daily loop is:

1. **Morning — open `Daily/{today}.md` in Obsidian.** The sync wrote it silently at 10:00 AM. Skim the sections: meetings (with full-transcript wikilinks), tasks assigned to you, chat mentions + DMs. Two minutes to know what's pending.
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

**1. Edit the knobs at the top of `scripts/install-brain-sync.sh`** (ships with this template):

```bash
# Inside scripts/install-brain-sync.sh:
VAULT_DIR="$HOME/Documents/second-brain"   # ← your vault path
HOUR=10                                    # ← 24-hour clock; 10 = 10:00 AM
MINUTE=0
```

<details>
<summary><strong>If you didn't clone from the template — full script to paste</strong></summary>

If you're following the docs without cloning this repo, save this as `~/install-brain-sync.sh` (it's the same content the template ships):

```bash
cat > ~/install-brain-sync.sh <<'SH'
#!/bin/bash
set -euo pipefail

VAULT_DIR="$HOME/Documents/second-brain"   # ← edit if your vault is elsewhere
HOUR=10                                    # 24-hour clock
MINUTE=0

LABEL="com.user.sync-second-brain"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG_DIR="$VAULT_DIR/.logs"

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

</details>

**2. Run it once.**

```bash
bash scripts/install-brain-sync.sh   # (or ~/install-brain-sync.sh if you pasted manually)
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

A new file dated today should be there. Open it in Obsidian — it should contain your recent meetings (with full transcripts), open tasks assigned to you, and recent chat activity from the last 24 hours.

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

# Change the time: edit HOUR/MINUTE in scripts/install-brain-sync.sh, then re-run it
bash scripts/install-brain-sync.sh

# Uninstall completely
launchctl bootout gui/$UID/com.user.sync-second-brain
rm ~/Library/LaunchAgents/com.user.sync-second-brain.plist
```

</details>

<details>
<summary><strong>What lands in <code>Daily/</code> — and how it stays connected to the wiki</strong></summary>

Each run writes `Daily/YYYY-MM-DD.md` with three sections:

1. **Meetings** from the last 24 hours — for each one, the sync **also writes a full per-meeting file** to `raw-sources/granola-meetings/{date}-{slug}.md` (matching your existing archive: frontmatter, summary, full verbatim transcript). The Daily file shows the title, attendees, summary, and action items, with `[[wikilinks]]` to (a) the new per-meeting file and (b) any attendee who has a `wiki/people/` page. The Daily file does **not** inline the transcript — it lives in `raw-sources/`.
2. **Tasks / tickets** assigned to you (open, sorted by priority and recency), with direct links back to the source.
3. **Chat** mentions and DMs awaiting your reply from the last 24 hours, with direct permalinks back to the source.

A later run on the same day overwrites the Daily file (latest snapshot wins). Older days stay as a permanent log. The per-meeting files in `raw-sources/` are write-once — if a meeting already has a file (matched by its source-specific ID in frontmatter), the sync leaves it alone.

**Net effect on the graph:** Daily files are not orphans. Each one points into `raw-sources/granola-meetings/` and `wiki/people/`, so the new files appear naturally in Obsidian's graph view connected to your existing wiki.

</details>

<details>
<summary><strong>The job runs silently in the background — no UI, no notification</strong></summary>

`launchd` doesn't open a Terminal window, doesn't show a Dock icon, doesn't send a notification when it fires. At your scheduled time the sync just runs invisibly and exits. The only evidence is:

- A new file in `Daily/`
- New per-meeting files in `raw-sources/granola-meetings/` (if any meetings happened)
- An entry in `~/{vault}/.logs/sync.out.log`

**The morning habit that makes this work:** open `Daily/{today}.md` in Obsidian first thing — it's your inbox replacement. A few sections, two minutes to skim, every meeting / ticket / chat thread you need to know about is there.

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
4. Drifted statuses — project or ticket status in the wiki that may not match the latest state in your task tracker.

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
<summary><strong>Source service rate-limited (e.g. Granola, Otter, Fireflies)</strong></summary>

Wait a few minutes and re-run. Syncs are idempotent and pick up where they left off.
</details>

<details>
<summary><strong>API-key sync says "skipped — set {SERVICE}_API_KEY first"</strong></summary>

For syncs that use the vendor's direct API (Linear, Jira, etc.), the env var isn't set in the shell where you're running Claude. Linear example — same shape for any other:

```bash
export LINEAR_API_KEY=lin_api_…
```

…right before running the sync, OR add the line to `~/.zshrc` permanently and reload (`source ~/.zshrc`).
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

Fix: the launchd plist must invoke claude with `--dangerously-skip-permissions`. Check that line in `~/Library/LaunchAgents/com.user.sync-second-brain.plist` (Step 9). If you wrote the plist without it, edit `scripts/install-brain-sync.sh` and re-run.

The flag is only safe for slash commands you've reviewed (like `/sync-all`). Don't put it in plists that run untrusted prompts.
</details>

<details>
<summary><strong>Wikilinks in the Daily file don't resolve (Obsidian shows them dimmed)</strong></summary>

Three causes, in likelihood order:

1. **The target file doesn't exist yet.** Wikilinks like `[[Person Name]]` only resolve if `wiki/people/Person Name.md` exists. Dimmed links are a normal "red-link" state — they tell Claude to consider creating that page on the next `/wiki-refresh`.
2. **Obsidian's link format setting is wrong.** Open Obsidian → Settings → Files & Links → New link format → set to "Shortest path when possible". Then Settings → Files & Links → "Use [[Wikilinks]]" → ON.
3. **The sync ran before `wiki/people/` was populated.** Run your bulk meeting sync first (it creates people pages from meeting attendees), then re-run `/sync-all`.
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
