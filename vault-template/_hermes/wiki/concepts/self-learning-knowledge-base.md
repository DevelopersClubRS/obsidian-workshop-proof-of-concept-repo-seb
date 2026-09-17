---
title: Self-Learning Knowledge Base
created: 2026-09-16
updated: 2026-09-16
type: concept
tags: [llm, agents, tool, system-design]
sources: ["[[Self-learning Knowledge base]]"]
confidence: high
---

A self-learning knowledge base is a dynamically evolving personal knowledge system built from raw research data (articles, papers, repos, datasets, images). It follows a three-stage process:

1. **Data Ingest**: Source documents are indexed into a `raw/` directory. The Obsidian Web Clipper and image downloader are used to capture web content and associated media.
2. **Compilation**: An LLM incrementally compiles the raw data into a structured markdown wiki (`.md` files), generating summaries, backlinks, and organizing content into concepts and articles.
3. **Operation**: The knowledge base is maintained and enhanced by agents. Users query the wiki with complex questions, and the system autonomously researches answers, generates outputs (e.g., markdown, slides, plots), and files the results back into the wiki, making it increasingly valuable over time.

Key features:

- **No manual editing**: The LLM maintains the wiki; humans intervene only occasionally.
- **Semantic search**: Powered by tools like `qmd`, enabling deep insight discovery.
- **Iterative enhancement**: LLMs perform health checks (inconsistencies, missing data, new connections) and suggest improvements.

This model enables agents to leverage rich, contextual knowledge for advanced reasoning and automation.

^[[[Self-learning Knowledge base]]]

[[unified-memory]] | [[ontology]] | Obsidian | LLM agent | qmd | research indexing