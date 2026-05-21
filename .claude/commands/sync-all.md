---
description: Daily second-brain sync — pull meetings, tasks, and chat from connected MCPs into a dated markdown file.
---

You are running an automated daily sync. The user may not be present. Do not ask clarifying questions. Make reasonable defaults and note them in the output.

## Config

```
OUTPUT_DIR     = ~/Documents/second-brain/Daily      # ← edit if your vault is elsewhere
LOOKBACK_HOURS = 24
TIMEZONE       = America/Los_Angeles                  # ← edit to your timezone
```

## Behavior

Run each connected source **in order**. After each step, append a section to an in-memory summary string — do not write to disk until all sources have been attempted. At the end, write the full file in one call.

For every source: if the relevant MCP tool isn't loaded or returns an auth error, write `_Not connected — skipped._` under that section and continue. Never abort the whole sync because one source is missing.

### 1. Meetings — last 24h

If a meeting MCP is loaded (e.g. Granola, Otter, Fathom, Fireflies, tl;dv — whichever you connected), list meetings from the last `LOOKBACK_HOURS`. For each meeting:

**1a. Fetch the data:** summary + action items + **full verbatim transcript** (call the MCP's transcript tool — most have one).

**1b. Write a per-meeting file to `raw-sources/{source}-meetings/`.** This is the historical archive. The Daily file is just a daily index pointing into it.

- **Filename:** `{YYYY-MM-DD}-{slug}.md`, where `slug` = title lowercased, non-alphanumerics → hyphens.
- **Idempotency:** if a file with that exact path already exists, OR if any existing file in that folder has the same `{source}_id` in its frontmatter, **skip the write**.
- **File contents:**

  ```
  ---
  type: meeting
  source: {source-name}
  {source}_id: {id}
  date: {YYYY-MM-DD}
  time: "{HH:mm}"
  title: {title}
  attendees:
    - {name}
  tags: []
  ---

  ## Summary

  {summary text verbatim}

  ## Notes

  _No private notes._

  ## Transcript

  {transcript_verbatim}
  ```

  Leave `tags: []` empty — a separate `/wiki-refresh` pass curates tags later.

**1c. Render the Meetings section of the Daily file with `[[wikilinks]]`:**

```
## Meetings

### [[../raw-sources/{source}-meetings/{YYYY-MM-DD}-{slug}|{title}]] — {start_time_local}
**Attendees:** {linked_attendee_list}
**Summary:** … (2–3 lines max)
**Action items:**
- …
```

For `{linked_attendee_list}`: for each attendee, check whether `wiki/people/{Name}.md` exists. If yes, render as `[[{Name}]]`. If no, render as plain text. Comma-separated.

Do **not** inline the transcript in the Daily file — the wikilink to the per-meeting file is sufficient.

If no meetings in the window, write `_No meetings in the last {LOOKBACK_HOURS}h._`

### 2. Tasks — your open work

If a task-tracker MCP is loaded (e.g. Linear, Jira, Asana, Notion, ClickUp), list open issues assigned to the current user, sorted by priority desc then updatedAt desc. Render:

```
## Tasks
- **{identifier}** [{state}] {title} — P{priority} — due {dueDate or "—"} → [link]({url})
```

Cap at 25 issues. If more, append `_…and N more_`.

If the tracker has a stable API (Linear's GraphQL, Jira's REST), prefer calling it directly with an API key for speed — see the "Special case" in Step 6 of getting-started.md.

### 3. Chat — unread mentions & DMs

If a chat MCP is loaded (e.g. Slack, Discord, Teams), first get the current user's ID, then two searches over the last `LOOKBACK_HOURS`:

1. **Mentions:** messages that @-mention you but aren't from you
2. **DMs awaiting reply:** DM channels where the latest message is from someone other than you

Render:

```
## Chat
### Mentions
- **{user}** in #{channel} ({time_ago}): {text_first_120_chars} → [link]({permalink})

### DMs awaiting reply
- **{user}** ({time_ago}): {text_first_120_chars} → [link]({permalink})
```

If both lists are empty, write `_Inbox zero._`

### 4. Write the file

Filename: `{OUTPUT_DIR}/{YYYY-MM-DD}.md` using `TIMEZONE` for the date. Expand `~` to the actual home directory.

If the file already exists from an earlier run today, **overwrite** it — a later run has fresher data.

Top of file:

```
# Second brain — {YYYY-MM-DD} ({weekday})

_Generated {HH:mm} {TIMEZONE}_
```

Then the connected sections in order: Meetings, Tasks, Chat.

At the very bottom, add a one-line tally:

```
---
_Sources: meetings={ok|skipped}, tasks={ok|skipped}, chat={ok|skipped}_
```

## Output to stdout

After the file is written, print **only** this — no preamble:

```
Synced → {full_path_to_file}
{N} meetings · {M} tasks · {X} mentions · {Y} DMs
```

If any source was skipped, add a second line: `Skipped: meetings, tasks` (or whichever).
