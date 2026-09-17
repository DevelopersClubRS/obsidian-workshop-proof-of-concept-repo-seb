---
tags: [workshop, hermes, obsidian, agents, public-speaking]
created: 2026-09-16
---
# Hermes + Obsidian: Self-Hosted Knowledge Extraction from a Massive Vault

**Workshop hub.** Build a fully local AI agent that searches thousands of notes, compiles them into a curated wiki,
and remembers you across sessions, without sending a single note to the cloud.

## Modules
1. [01 Architecture and Concepts](01-architecture-and-concepts.md): the stack, memory vs search, two authors, LLM Wiki, safety model
2. [02 Install Guide](02-install-guide.md): step-by-step, copy-paste commands (Ollama, Hermes, QMD, Hindsight, vault wiring)
3. [03 Hands-on Labs](03-hands-on-labs.md): exercises with expected results
4. [04 Troubleshooting and Gotchas](04-troubleshooting.md): every problem hit while building this, with fixes
5. [05 References](05-references.md): all sources, marked read-in-full vs further reading
6. [06 Demo Log](06-demo-log.md): real transcripts from the reference setup (timings, what went wrong)
7. [07 My Setup Runbook](07-reference-machine-runbook.md): presenter's machine: services, health checks, rollback

## Web handout for attendees
`site/index.html` in this repo is a standalone page called **Hermes in the Vault**, with no personal paths or vault
details. Preview: https://claude.ai/artifact/422RF7JaABeRMCrWJrjkMS (private until shared).
- **Host:** upload `site/index.html` to any static host (GitHub Pages, Netlify, Cloudflare Pages, S3), or test locally
  with `cd site && python3 -m http.server 8080`. Fonts load from Google Fonts; without them it falls back to system fonts.
- **Edit:** change `site/hermes-in-the-vault.src.html` (code blocks are written raw), then run
  `cd site && python3 build.py /tmp/artifact.html index.html`.
- **Before going public:** add date, venue and speaker to the top line.

## Managed alternatives deck
`site/managed.html` is **Hermes, Managed**, a 14-slide presentation on renting the stack instead of self-hosting.
It covers which layer moves off the machine, the accounts matrix, the measured token profile, monthly cost by model
(16 models, Light/Typical/Heavy), a stack calculator, plans, memory/hosting/search add-ons, six example stacks and
sources. Prices checked 16 Sep 2026. Preview: https://claude.ai/artifact/CCqdQmbHDg3bLQcze6u7j2
- **Present:** `~/workshop-site.sh`, then open `/managed.html`. ↓/Space/PageDown to advance, F for full screen.
## Concept decks
Two more 12-slide presentations in `site/`, same look and keyboard navigation, for talks that aren't a hands-on lab:
- **`compiled-wiki.html`** — *The Compiled Wiki*: the LLM wiki pattern, Karpathy's gist quoted from the primary
  source, what the evidence actually shows (GraphRAG win rates, one industry preprint, nothing peer-reviewed),
  the 171-commit lint replay where 47 defects sat unnoticed, three myths to stop repeating, ten implementations,
  and when not to compile. Preview: https://claude.ai/artifact/L3sQyVZ7XFE8F9wsACCnGA
- **`agent-memory.html`** — *What the Agent Remembers*: the CoALA taxonomy, why context windows aren't memory,
  how six systems work, contested benchmarks, memory poisoning (34–67% attack success) alongside the three false
  memories our own agent stored, hygiene, and a cheap ablation test.
  Preview: https://claude.ai/artifact/55ZmrtS5NqNimyAHtNGQHi

All four pages share `site/_deck-base.css` and `site/_deck-nav.js`, injected at build time.

- **Refresh prices:** edit the `MODELS` table in `site/hermes-managed.src.html`, then
  `cd site && python3 build.py hermes-managed.src.html /tmp/artifact.html managed.html`. Watch the GPT-5.6 Sol promo
  (to 21 Nov 2026) and Gemini 3.8 Flash doubling on 1 Jan 2027.

## The stack in one line
**Obsidian vault** (source, read-only) → **QMD** (hybrid search, MCP) → **Hermes Agent** (local **Ollama** model)
→ **LLM Wiki** in `_hermes/wiki/` (agent-owned) + **Hindsight** in Docker (long-term memory).

## Audience & outcomes
For people with a large Obsidian (or any Markdown) knowledge base who are comfortable in a terminal.
By the end, attendees:
- understand why **memory ≠ search** and the two-author model
- have Hermes answering questions over *their own* vault with citations they verified
- have compiled their first wiki pages from existing notes
- have seen memory recall work across sessions

## Agenda (≈ 3 h)
| Time | Block | Material |
|---|---|---|
| 0:00 | Why vaults become write-only; demo of the end result | [06 Demo Log](06-demo-log.md) |
| 0:15 | Architecture & concepts | [01 Architecture and Concepts](01-architecture-and-concepts.md) |
| 0:40 | Install (models pre-downloaded!) | [02 Install Guide](02-install-guide.md) § 1–5 |
| 1:30 | Break |  |
| 1:40 | Wire the vault: AGENTS.md, wiki scaffold | Install Guide § 6–7 |
| 2:00 | Labs 1–4: search, verify, ingest, memory | [03 Hands-on Labs](03-hands-on-labs.md) |
| 2:45 | Safety, secrets, hardening, Q&A | Concepts § 5, Install Guide § 9 |

## Attendee prep (send a week before)
Downloads are the bottleneck; conference Wi-Fi won't handle 25 GB per person.
- [ ] Check hardware: GPU ≥ 10 GB VRAM + 32 GB RAM, or Apple Silicon ≥ 32 GB (otherwise pair up)
- [ ] Install Docker, Node 22, git
- [ ] Pre-pull: `ollama pull qwen3:30b-a3b-instruct-2507-q4_K_M` and `docker pull ghcr.io/vectorize-io/hindsight:latest`
- [ ] Put your vault under git and commit
- [ ] Run the secrets scan (Install Guide § 0.1)
- [ ] Bring a copy of your vault if you'd rather not experiment on the real one

## Key takeaways (closing slide)
1. Memory providers remember **conversations**; search indexes **notes**. You need both, and they're different.
2. Your notes stay human-owned; the agent maintains its own wiki with citations back to them.
3. Local models work, but **context ≥ 64K** is mandatory, **defaults leak** (web search is on), and **models overclaim**.
   Verify citations and don't trust "done".
4. **Judgement → LLM, mechanics → scripts, truth → you.** A deterministic checker caught what the agent's self-lint called "optimal".
5. Rules in `AGENTS.md` are soft; `HERMES_WRITE_SAFE_ROOT` blocks file tools; Docker `:ro` mounts are the hard guarantee; git is your undo.
6. Memory needs hygiene: auto-retain happily stores hallucinations and false success claims.
7. Scan for secrets before any agent touches your vault.

## What the reference run proved (see [06 Demo Log](06-demo-log.md))
| Demo | Result |
|---|---|
| 1 Vault Q&A | ❌ 8B model hallucinated → ❌ 30B went to the **web** (default tools) → ✅ after locking tools down: correct, cited, 98 s |
| 2 Wiki ingest (3 notes) | ✅ faithful content, 0 human notes touched · ❌ 13 dangling links, off-taxonomy tags |
| 3 Agent self-lint | ❌ 120 tool calls, then "all links resolve" (false) |
| 4 Memory across sessions | ✅ after `recall_sync: true` |
| 5 Write sandbox | ✅ write to a human note rejected, file unchanged |
| 6 Script → agent fix loop | ✅ 13 → 6 → 0 dangling, plus a human pass for a regression and an invented sentence |
