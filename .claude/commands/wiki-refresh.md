---
description: Audit the wiki for cross-link health, red-links, orphan pages, and index drift. Read-only by default; suggest edits, don't apply them.
---

You are auditing the wiki. By default, you **suggest** fixes — do not apply them automatically. Write findings to a report; the user decides what to act on.

## Scope

Walk every file under `wiki/` and check four kinds of health issue:

### 1. Red-link promotion candidates

Find `[[Wikilinks]]` whose target file does **not** exist. Group by target:

- **High frequency** (3+ mentions across distinct files) — strong candidate for a new page. Suggest where it belongs (`wiki/people/`, `wiki/projects/`, `wiki/concepts/`, `wiki/decisions/`).
- **Medium frequency** (2 mentions) — probable candidate; flag for review.
- **Single mention** — could be a typo. Suggest the closest existing page name.

### 2. Orphan pages

Find pages in `wiki/` with **zero inbound `[[wikilinks]]`** from other wiki pages or Daily files. Group by folder:

- `wiki/concepts/`, `wiki/projects/`, `wiki/people/` — orphans here usually indicate either a stub that was never connected, or a page that became stale.
- `wiki/decisions/`, `wiki/reports/` — orphans here are usually OK (these are append-only logs that don't need to be linked from elsewhere).

### 3. Index drift

Compare `wiki/index.md` against the actual file system:

- Files that exist but are missing from `index.md` — suggest adding them.
- Entries in `index.md` that no longer have a corresponding file — suggest removing them.
- Entries whose one-line summary contradicts the file's current opening paragraph — flag for re-summarization.

### 4. Stale claims

Skim each wiki page for:

- **Universal claims** ("every", "all", "always", "never") — these are usually too sweeping. Quote them.
- **Dated claims** ("as of {date}", "currently", "this week") older than 30 days — flag for re-verification.
- **Status fields** that may not match the latest source-of-truth (e.g. project status in `wiki/projects/` vs. the actual task tracker).

## Output

Write a single report to `wiki/reports/wiki-audit-{YYYY-MM-DD}.md` with sections matching the four checks above. Group findings by file path. For each finding: quote the problematic text + your reasoning + suggested action.

**Do not edit any wiki page directly.** Suggest only.

## Output to stdout

After writing the report, print only:

```
Wiki audit → {full_path_to_report}
{N} red-link candidates · {M} orphans · {X} index drifts · {Y} stale claims
```

The user reads the report and decides what to fix by hand or by asking you to apply specific suggestions in a follow-up session.
