---
title: Unified Memory Architecture
created: 2026-09-16
updated: 2026-09-16
type: concept
tags: [llm, agents, tool, system-design]
sources: ["[[GRAPH in memory + LLM wiki + Mongo]]"]
confidence: high
---

A unified memory system integrates multiple functions—document storage, vector embeddings, and knowledge graph—into a single database layer. Based on the **MongoDB** deployment, the architecture uses four core layers:

1. **Ontology**: Defines the data model, including entities, relationships, and rules for merging or evolving facts. It acts as the contract between the LLM, database, and retrieval layer.
2. **Durable Write Path**: Two independent, orchestrated pipelines:
   - Data ingestion into a document warehouse.
   - Transformation of documents into a structured memory state.
3. **One Database**: All functions (document store, vector store, knowledge graph) run in a single MongoDB instance, preserving lineage and avoiding data duplication.
4. **Serving Layer**: Agents do not query the database directly. Instead, they interact with a business logic server (e.g., **FastMCP**) that manages search, update, synchronization, and continuous learning.

The central insight is that **the ontology determines the success of the entire system**. The architecture enables scalable, cohesive agent memory that learns continuously from interactions.

^[[[GRAPH in memory + LLM wiki + Mongo]]]

[[ontology]] | FastMCP | MongoDB | [[self-learning-knowledge-base]]