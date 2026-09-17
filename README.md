# Hermes + Obsidian: self-hosted knowledge extraction

Workshop material for building a **fully local AI agent over an Obsidian vault**: it searches thousands of notes,
compiles them into a cited wiki, and remembers you across sessions, with no cloud model and no API keys.

Everything here was built and verified on a real 2,330-note vault on 16–17 September 2026. The failures are kept
in on purpose; they're the most useful part of the workshop.

**Tested with:** Hermes Agent 0.21.3 · QMD 2.8.3 · Ollama 0.34.1 · Hindsight (client 0.10.0) ·
Ubuntu, RTX 3080 10 GB, i9-11900K, 62 GB RAM, Docker Desktop.

## What's here

| Folder | Contents |
|---|---|
| [`docs/`](docs/README.md) | The workshop itself: concepts, install guide, labs, troubleshooting, references, demo log, runbook |
| [`site/`](site/) | Four web pages: `index.html` (attendee handout), plus three keyboard-navigable decks — `managed.html` (cloud/managed alternatives and costs), `compiled-wiki.html` (the LLM wiki pattern) and `agent-memory.html` (memory for agents). Sources, shared CSS/JS and the build script included |
| [`scripts/`](scripts/) | `hermes-infra.sh` (start the whole stack), `workshop-demo.sh` (live demo presenter), `workshop-site.sh` (serve/check/screenshot the pages) |
| [`stack/`](stack/) | `docker-compose.yml` for Hindsight, systemd user units for Ollama and the search-index refresh, example QMD config |
| [`vault-template/`](vault-template/) | What goes in the vault: `AGENTS.md` rules, the LLM Wiki scaffold (`SCHEMA.md`, `index.md`, `log.md`), the deterministic `wiki_check.py`, and three example compiled pages |

## Start here

1. Read [`docs/README.md`](docs/README.md) for the agenda and what the workshop covers.
2. Follow [`docs/02-install-guide.md`](docs/02-install-guide.md) from a clean machine (~45–60 min, mostly downloads).
3. Work through [`docs/03-hands-on-labs.md`](docs/03-hands-on-labs.md) on your own vault.
4. When something breaks, [`docs/04-troubleshooting.md`](docs/04-troubleshooting.md) lists every problem hit while building this.

## The five-minute version

```
Your vault (Markdown, read-only to the agent)
   ↓  QMD: keyword + vector search + reranking, exposed to Hermes as MCP tools
Hermes Agent  ──►  Ollama + qwen3:30b-a3b-instruct-2507 on the GPU
   ↓  writes only to _hermes/wiki/ (the LLM Wiki), with citations back to your notes
Hindsight in Docker: long-term memory from conversations
```

Four things that decide whether it works:

1. **Memory providers remember conversations; search indexes notes.** You need both, and they're different systems.
2. **Hermes needs a model with ≥ 64K context.** Original Qwen3 models cap at 40,960 and are refused for tool use.
3. **Lock the defaults down.** Web search and browser tools are on by default; a local model that can't find its
   vault tools will search the web instead and cite notes that don't exist.
4. **Local models overclaim.** "Done", "verified" and "all links resolve" are not evidence. Run `wiki_check.py`
   and check one cited note by hand.

## Running it

```bash
scripts/hermes-infra.sh          # start Docker, Ollama (+model), Hindsight; check search, tools, sandbox
scripts/hermes-infra.sh chat     # …then open Hermes in your vault
scripts/workshop-demo.sh         # present the 8-step live demo
scripts/workshop-site.sh         # serve the handout at localhost:8080 (check / shots also available)
```

The scripts carry the reference machine's paths (`$HOME/Obsidian/obsidian-vault`, `$HOME/hermes-stack`).
Edit the variables at the top of each before running them elsewhere.

## Notes on the material

- `docs/06-demo-log.md` holds the real transcripts, timings and verification of six demos, including the two
  that failed. `docs/07-reference-machine-runbook.md` describes the presenter's machine specifically.
- The web pages are standalone HTML: open `site/index.html`, or host the folder anywhere static.
  Edit the `.src.html` files and rebuild with `cd site && python3 build.py …` (see `docs/README.md`).
- Prices in the managed deck were checked on 16 Sep 2026 and move fast; sources are listed on its last slide.
