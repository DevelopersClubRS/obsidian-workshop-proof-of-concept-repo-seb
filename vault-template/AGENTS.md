# AGENTS.md — rules for AI agents working in this vault

Loaded automatically by Hermes Agent (and other AGENTS.md-aware agents) when started from the vault root.
Setup and workshop notes: [[Hermes-Obsidian-Workshop]].

## What this vault is
Seb's personal Obsidian vault, PARA layout, ~2,300 notes, English and Serbian mixed.

| Folder | Contents |
|---|---|
| `00-PeriodicNotes/` | Daily/weekly notes (`<year>/Daily/<MM>/<YYYY-MM-DD>.md`) |
| `1 Projects/` | Active projects; `1-Eqho.AI/` is work (work logs, runbooks, incidents) |
| `2 Areas/` | Ongoing areas: career, public speaking, people, finance, self-improvement |
| `3 Resources/` | Reference/learning notes by topic |
| `4 Archives/` | Inactive material |
| `_hermes/` | **Agent-owned.** The only place agents write by default |

## Ownership — two authors
1. **Everything outside `_hermes/` is human-written and READ-ONLY.** Do not edit, move, rename or delete
   those notes unless Seb explicitly asks for that specific change in the current conversation.
   Renames break wikilinks from daily notes and work-log H1 self-links.
2. **`_hermes/` is yours.** The LLM Wiki lives in `_hermes/wiki/` (`$WIKI_PATH`) — follow its `SCHEMA.md`.

## How to find things
1. **Search first with the `qmd` MCP tools** (hybrid BM25 + vector + rerank over the whole vault):
   - `query` — use `lex:` lines for exact names/IDs/error strings, `vec:` lines for natural-language questions.
     Collections: `vault` (human notes), `wiki` (compiled wiki pages).
   - `get` / `multi_get` — read the notes that the search returned.
2. Use `search_files` only for exact regex matches or when QMD's index may be stale (very recent edits).
3. For questions the wiki already covers, read `_hermes/wiki/index.md` first — it is cheaper than re-reading sources.

## Answering and writing
- **Cite sources** as wikilinks to the note name, without `.md`: `[[2026-08-03 IRE deploy - rollback]]`.
- Prefer quoting the note's own words for decisions and numbers; don't invent details that aren't in the notes.
- Say explicitly when the vault has no information on something.

## Secrets — hard rule
Some notes contain credentials (tokens, API keys, connection strings). **Never copy a credential into any
answer, wiki page, memory, or log.** Write `[REDACTED credential — see [[Source Note]]]` instead.

## Don'ts
- No `git` commands. The vault auto-commits every few minutes; Seb reverts through git history if needed.
- Do not touch `.obsidian/` (plugin config, may contain keys).
- Do not bulk-edit: ask before creating or changing more than 10 wiki pages in one go.
