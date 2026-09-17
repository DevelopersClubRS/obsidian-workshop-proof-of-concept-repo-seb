---
title: Ontology
created: 2026-09-16
updated: 2026-09-16
type: concept
tags: [llm, agents, system-design]
sources: ["[[GRAPH in memory + LLM wiki + Mongo]]"]
confidence: high
---

An ontology in unified memory defines the data model, including:

- **Entities**: The core objects (e.g., services, tools, people).
- **Relationships**: How entities are connected (e.g., "uses", "depends on", "created by").
- **Merging rules**: When two entities should be combined.
- **Fact evolution**: How information updates over time.

The ontology is the contract between the LLM, the database, and the retrieval layer. It determines whether the entire memory system succeeds or fails.

It is not a one-time design but a living document that evolves as new patterns emerge from data and usage.

^[[[GRAPH in memory + LLM wiki + Mongo]]]

[[unified-memory]] | [[self-learning-knowledge-base]]