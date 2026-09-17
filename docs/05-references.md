---
tags: [workshop, hermes, references]
---
# Hermes Workshop - 05 References

Back to [Hermes-Obsidian-Workshop](README.md)

Researched 2026-09-15/16. Versions used: **Hermes Agent v0.21.3**, **QMD 2.8.3**, **Ollama 0.34.1**,
**Hindsight** `ghcr.io/vectorize-io/hindsight:latest` (client 0.10.0).
✅ = read in full while building this workshop · 🔎 = seen in search results only (further reading)

## Hermes Agent — official
- ✅ [NousResearch/hermes-agent (GitHub)](https://github.com/NousResearch/hermes-agent): install, quick-start CLI
- ✅ [Releases](https://github.com/NousResearch/hermes-agent/releases) · ✅ [Changelog summary, Sep 2026](https://www.gradually.ai/en/changelogs/hermes-agent/): v0.21 "Pantheon" (cron with persistent memory, MCP command center), v0.21.1 state.db fixes
- ✅ [Persistent Memory](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory): MEMORY.md/USER.md limits, frozen snapshot, `session_search`
- ✅ [Memory Providers](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory-providers): Honcho, OpenViking, Mem0, Hindsight, Holographic, RetainDB, ByteRover, Supermemory
- ✅ [Hindsight plugin README](https://github.com/NousResearch/hermes-agent/blob/main/plugins/memory/hindsight/README.md): `local_external` mode, `config.json` keys, recall/retain options
- ✅ [LLM Wiki skill docs](https://hermes-agent.nousresearch.com/docs/user-guide/skills/bundled/research/research-llm-wiki) · [SKILL.md source](https://github.com/NousResearch/hermes-agent/blob/main/skills/research/llm-wiki/SKILL.md)
- ✅ [QMD optional skill](https://hermes-agent.nousresearch.com/docs/user-guide/skills/optional/research/research-qmd)
- ✅ [Context files: AGENTS.md, .hermes.md, SOUL.md](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/user-guide/features/context-files.md)
- ✅ [Inference providers](https://hermes-agent.nousresearch.com/docs/integrations/providers): Ollama via `custom` provider, 64K context note
- ✅ [Configuration](https://hermes-agent.nousresearch.com/docs/user-guide/configuration)
- ✅ [Docker setup](https://hermes-agent.nousresearch.com/docs/user-guide/docker): `/opt/data` volume, never share `~/.hermes` between containers

## Vault search
- ✅ [tobi/qmd (GitHub)](https://github.com/tobi/qmd): collections, `ignore`, contexts, `update` vs `embed`, MCP
- ✅ [Obsidian Semantic Search: Grep, OmniSearch & QMD Benchmarked (Mandalivia)](https://www.mandalivia.com/obsidian/semantic-search-for-your-obsidian-vault-what-i-tried-and-what-worked/): 2,400-note vault benchmark
- ✅ [Obsidian MCP Guide: AI Search & Retrieval (Blake Crosley)](https://blakecrosley.com/guides/obsidian): chunking at H2, RRF, scaling table, credential scrubbing
- ✅ [flowing-abyss/obsidian-hybrid-search](https://github.com/flowing-abyss/obsidian-hybrid-search): alternative; Obsidian-aware (links, backlinks, frontmatter), 117 MB model; benchmark numbers are self-reported
- 🔎 [QMD Semantic Search Obsidian plugin](https://community.obsidian.md/plugins/qmd-search) · 🔎 [Hybrid Search plugin](https://community.obsidian.md/plugins/hybrid-search)

## Memory providers
- ✅ [The Fully Open Agent Memory Stack: Self-Hosting Hermes + Hindsight](https://hindsight.vectorize.io/blog/2026/07/17/hermes-hindsight-open-stack) (vendor blog)
- ✅ [Hindsight configuration reference](https://hindsight.vectorize.io/developer/configuration): `HINDSIGHT_API_LLM_*`, `..._OLLAMA_NUM_CTX`
- ✅ [Agent Memory Providers Compared: Honcho, Mem0, Hindsight… (Rost Glukhov)](https://www.glukhov.org/ai-systems/memory/agent-memory-providers/): infra needs per provider
- ✅ [Best Memory Providers for Hermes Agent (Hermes Atlas)](https://hermesatlas.com/lists/best-memory-providers): 38 providers ranked by stars
- 🔎 [Hermes Agent Memory System: How It Works (Glukhov)](https://www.glukhov.org/ai-systems/hermes/hermes-agent-memory-system/)

## Hermes + Obsidian practice
- ✅ [Hermes Agent Obsidian Integration in 2026 (Atomic Bot)](https://atomicbot.ai/blog/blog-hermes-agent-obsidian): 3 integration methods, hot/warm/deep memory, access zones
- ✅ [How my LLM Wiki became my second brain agent workspace (Danny Shmueli)](https://dannyshmueli.com/2026/05/18/Hermes-Console-turns-Obsidian-into-my-agent-workspace/): two-author model
- ✅ [dannyshmueli/obsidian-hermes-console](https://github.com/dannyshmueli/obsidian-hermes-console) · 🔎 [Hermes Console in Obsidian community plugins](https://community.obsidian.md/plugins/hermes-console)
- ✅ [Hermes + Obsidian: my second brain learns me back (Artem)](https://artemxtech.substack.com/p/i-stopped-teaching-my-agent-who-i): self-learning loop, per-channel personas
- ✅ [Hermes + Obsidian: The Agentic Second Brain Pattern (Catlabs)](https://arapaholabs.com/blog/2026-06-07-obsidian-hermes-second-brain)
- 🔎 [Hermes Agent Ships a Bundled LLM Wiki Skill (Catlabs)](https://arapaholabs.com/blog/2026-06-15-llm-wiki-karpathy-pattern)
- 🔎 [Obsidian x Hermes Agent Is So Good I'm Deleting Apps (Parazettel)](https://parazettel.com/articles/hermes-obsidian-deleting-apps/)
- 🔎 [hermes-obsidian-setup-guide.md (hermes-profiles)](https://github.com/theheavenlyd3mon/hermes-profiles/blob/main/hermes-obsidian-setup-guide.md)
- 🔎 [truongmanhsang/obsidian-wiki: LLM Wiki as a Hermes MemoryProvider](https://github.com/truongmanhsang/obsidian-wiki)
- 🔎 [Ar9av/obsidian-wiki](https://github.com/Ar9av/obsidian-wiki) · 🔎 [shannhk/llm-wikid](https://github.com/shannhk/llm-wikid)

## Local models
- ✅ [Ollama releases](https://github.com/ollama/ollama/releases): user-level install from `ollama-linux-amd64.tar.zst`, no sudo
- 🔎 [Ollama library: qwen3](https://ollama.com/library/qwen3)
- 🔎 [Run Hermes Agent with Ollama and Local LLMs (Fastio)](https://fast.io/resources/hermes-agent-ollama-local-llm/)
- 🔎 [Run Hermes Agent Locally with Ollama (LocalAIMaster)](https://localaimaster.com/blog/hermes-agent-ollama)
- 🔎 [Best Open-Source Models for Hermes Agent (Claude Market)](https://www.claudemarket.ai/blog/best-opensource-models-for-hermes)
