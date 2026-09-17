# Wiki Log

> Chronological record of all wiki actions. Append-only.
> Format: `## [YYYY-MM-DD] action | subject`
> Actions: ingest, update, query, lint, create, archive, delete
> When this file exceeds 500 entries, rotate: rename to log-YYYY.md, start fresh.

## [2026-09-16] create | Wiki initialized
- Domain: compiled knowledge from Seb's Obsidian vault (vault notes are the read-only source layer, no raw/)
- Structure created with SCHEMA.md, index.md, log.md

## [2026-09-16] ingest | LLM Knowledge Base Sources
- Sources: [[3 Resources/AI/LLM/LLM-knowledge-wiki/GRAPH in memory + LLM wiki + Mongo.md]], [[3 Resources/AI/LLM/LLM-knowledge-wiki/Obsidian approach.md]], [[3 Resources/AI/LLM/LLM-knowledge-wiki/Self-learning Knowledge base.md]]
- Updated: [[ontology]], [[unified memory architecture]], [[self-learning knowledge base]]
- Created: [[ontology]], [[unified memory architecture]], [[self-learning knowledge base]]
- Updated index.md
- Updated log.md

## [2026-09-16] lint | fixed links, tags, frontmatter, index from deterministic check
- Fixed: concepts/ontology.md (links, tags)
- Fixed: concepts/unified-memory.md (links, tags)
- Fixed: concepts/self-learning-knowledge-base.md (links, tags)
- Fixed: index.md (links, tags, total count)
- Updated log.md

## [2026-09-16] lint | manual review after deterministic check
- Un-indented frontmatter keys; restored sources as [[Note Name]] wikilinks; provenance markers use note names
- ontology.md: removed self-link · self-learning-knowledge-base.md: added [[ontology]] link (>=2 outbound)
- unified-memory.md: removed unsupported sentence "builds on the Obsidian approach…" (not in source note)
- Reviewer: setup session (Claude Code), after agent fix rounds left these open
