# Wiki Schema

## Domain
Compiled knowledge from Seb's Obsidian vault: the engineering knowledge, decisions, runbooks, people,
tools and lessons that are spread across daily notes, work logs, project notes and resource notes.
The goal is to **extract** durable knowledge so it can be found and reused without re-reading hundreds of notes.

## Sources — adaptation for an existing vault
This wiki does **not** use a `raw/` folder. The vault itself is the immutable source layer:
- Sources are existing vault notes outside `_hermes/`, referenced by wikilink: `[[Note Name]]`.
- Never copy source notes into the wiki and never modify them (see `/AGENTS.md`).
- Find sources with the `qmd` MCP `query` tool (collection `vault`), read them with `get`.
- External URLs may be cited directly when a note links to them.

## Conventions
- File names: lowercase, hyphens, no spaces (e.g. `hindsight-memory-provider.md`)
- Every wiki page starts with YAML frontmatter (see below)
- Use `[[wikilinks]]` to link between pages (minimum 2 outbound links per page)
- When updating a page, always bump the `updated` date
- Every new page must be added to `index.md` under the correct section
- Every action must be appended to `log.md`
- **Provenance markers:** on pages that synthesize 3+ sources, end a paragraph with `^[[[Source Note]]]`
  when its claims come from a specific note.
- **Secrets:** never copy credentials into the wiki. Write `[REDACTED credential — see [[Source Note]]]`.
- Language: write pages in English; keep Serbian terms/quotes when they are the original wording.
- Wikilinks between wiki pages use the **file name**: `[[unified-memory]]`, not the title. Terms without a page stay plain text.
- Frontmatter keys start at column 0 (no indentation).
- **Verification:** after any change, run `python3 /home/seb/Obsidian/obsidian-vault/_hermes/scripts/wiki_check.py /home/seb/Obsidian/obsidian-vault`
  with the terminal tool and fix until it exits 0. Its output overrides your own assessment. Never report
  "all links resolve" without it.

## Frontmatter
```yaml
---
title: Page Title
created: YYYY-MM-DD
updated: YYYY-MM-DD
type: entity | concept | comparison | query | summary
tags: [from taxonomy below]
sources: ["[[Source Note One]]", "[[Source Note Two]]"]
# Optional quality signals:
confidence: high | medium | low
contested: true
contradictions: [other-page-slug]
---
```

## Tag Taxonomy
Every tag on a page must appear here. Add a new tag here BEFORE using it.
- Work: `eqho`, `incident`, `runbook`, `decision`, `project`
- Engineering: `backend`, `frontend`, `system-design`, `devops`, `cloud`, `database`, `testing`
- AI: `llm`, `agents`, `voice-ai`, `rag`
- Tools & platforms: `tool`, `obsidian`, `linux`
- People & career: `person`, `career`, `public-speaking`
- Meta: `comparison`, `timeline`, `lesson-learned`

## Page Thresholds
- **Create a page** when an entity/concept appears in 2+ source notes OR is central to one note
- **Add to an existing page** when a source mentions something already covered
- **Don't create** pages for passing mentions or one-off trivia
- **Split** a page when it exceeds ~200 lines
- **Archive** superseded pages to `_archive/`, remove from index, fix backlinks

## Entity Pages
One page per notable thing: a service, tool, library, person (work context only), customer-facing system,
recurring incident type. Include: what it is, how Seb uses/interacts with it, key facts, gotchas, related pages.

## Concept Pages
One page per idea or practice (e.g. `stacked-prs`, `hybrid-search`). Include: definition, how it applies
in Seb's work, examples from the notes, open questions.

## Comparison Pages
Side-by-side analyses (e.g. memory providers, deployment options). Include: what's compared, dimensions
(table preferred), verdict, sources.

## Update Policy
When new information conflicts with existing content:
1. Check dates — newer notes generally supersede older ones
2. If genuinely contradictory, note both positions with dates and sources
3. Mark in frontmatter: `contradictions: [page-name]`
4. Flag for Seb's review in the lint report
