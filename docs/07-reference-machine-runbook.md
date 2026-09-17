---
tags: [workshop, hermes, runbook]
---
# Hermes Workshop - 07 My Setup Runbook

Back to [Hermes-Obsidian-Workshop](README.md)

The reference install on this machine (set up 2026-09-16). Everything local, no cloud LLM, no GCP.

## What runs where

| Component | Version | How it runs | Location |
|---|---|---|---|
| Hermes Agent | v0.21.3 | CLI (`~/.local/bin/hermes`) | code `~/.hermes/hermes-agent`, config `~/.hermes/config.yaml`, env `~/.hermes/.env` |
| Ollama | 0.34.1 | systemd **user** service `ollama.service`, `127.0.0.1:11434` | `~/.local/share/ollama-bin`, models `~/.ollama/models` |
| Model | `qwen3:30b-a3b-instruct-2507-q4_K_M` | loaded by Ollama on demand, 30 min keep-alive | 18.6 GB |
| QMD | 2.8.3 | stdio MCP server spawned by Hermes; index refresh timer `qmd-refresh.timer` (30 min) | config `~/.config/qmd/index.yml`, index `~/.cache/qmd/index.sqlite` |
| Hindsight | `ghcr.io/vectorize-io/hindsight:latest` | Docker Desktop, compose project `hermes-stack` | `~/hermes-stack/docker-compose.yml`, volumes `hermes-stack_hindsight-data`, `hermes-stack_hindsight-cache` |
| Hindsight plugin config | client 0.10.0 | `local_external`, bank `seb-vault`, `recall_sync: true` | `~/.hermes/hindsight/config.json` |
| Vault rules | | loaded when Hermes starts in the vault root | `AGENTS.md` (vault root) |
| LLM Wiki | | agent-owned | `_hermes/wiki/` (`SCHEMA.md`, `index.md`, `log.md`, `concepts/`) |
| Wiki checker | | run after every ingest/fix; exit 0 = clean | `_hermes/scripts/wiki_check.py` |

**Hardening applied** (see [02 Install Guide](02-install-guide.md) § 3.1 and § 6.1):
- Toolsets disabled for CLI: `web browser image_gen tts vision computer_use connections`
- `tools.tool_search.enabled: off` (QMD tools load directly)
- `HERMES_WRITE_SAFE_ROOT=/home/seb/Obsidian/obsidian-vault/_hermes:/home/seb/.hermes` in `~/.hermes/.env`

Backups of the untouched originals: `~/.hermes/config.yaml.orig`, `~/.hermes/.env.orig`, `~/.config/qmd/index.yml.bak`.

## Scripts (in `~`)
| Script | What it does |
|---|---|
| `./hermes-infra.sh` | Starts Docker Desktop → Ollama (+ loads the model at ctx 65536) → Hindsight → checks QMD, Hermes, web tools, sandbox. Cold start ~26 s |
| `./hermes-infra.sh chat` | Same, then opens Hermes in the vault |
| `./hermes-infra.sh ask "…"` | Same, then one question |
| `./hermes-infra.sh status` / `stop` / `refresh` | Health only · stop Hindsight + Ollama (frees GPU, keeps memories) · re-index the vault |
| `./workshop-demo.sh` | Live demo presenter: 8 steps, each shows talking points + exact command, Enter to run. `--list`, `--from N`, `--only N`, `DEMO_AUTO=1` to rehearse |
| `./workshop-site.sh` | Serves the web handout on http://localhost:8080 · `check` (HTML, privacy leaks, 32 links) · `shots` (light/dark/phone screenshots) |

## Daily use
```bash
cd ~/Obsidian/obsidian-vault && hermes              # interactive TUI in the vault (AGENTS.md loads)
hermes chat --oneshot -q "..."                       # one-shot question
hermes -c                                            # continue last session
```
Web UIs: Hindsight memory browser → http://localhost:9999

## Health check (all green = working)
```bash
systemctl --user is-active ollama qmd-refresh.timer
curl -s http://127.0.0.1:11434/api/ps                # loaded model + context_length
curl -s http://127.0.0.1:8888/health                 # Hindsight
docker compose -f ~/hermes-stack/docker-compose.yml ps
qmd status | sed -n 1,12p                            # docs indexed / pending embeddings
hermes mcp test qmd && hermes memory status
hermes tools list | grep -E "web|browser"            # must be ✗ disabled
python3 ~/Obsidian/obsidian-vault/_hermes/scripts/wiki_check.py ~/Obsidian/obsidian-vault   # exit 0
```

## Extract knowledge (the actual workflow)
```bash
cd ~/Obsidian/obsidian-vault
# 1. ask
hermes chat --oneshot -q "Using the qmd search tools, find what my vault says about <X>. Read the notes, answer with [[wikilink]] citations."
# 2. compile a topic into the wiki (3-5 short notes at a time)
hermes chat --oneshot -s llm-wiki --max-turns 80 -q "…ingest prompt from Lab 3…"
# 3. check → fix loop until exit 0 (Lab 3b), then read the pages
python3 _hermes/scripts/wiki_check.py .
```

## Memory hygiene
- Browse/prune: http://localhost:9999 (bank `seb-vault`)
- Delete a bad session: `curl -X DELETE http://127.0.0.1:8888/v1/default/banks/seb-vault/documents/<session_id>`
- Built-in: `cat ~/.hermes/memories/{MEMORY,USER}.md`

## Start / stop
```bash
systemctl --user stop ollama            # frees the GPU (e.g. for gaming)
systemctl --user start ollama
docker compose -f ~/hermes-stack/docker-compose.yml stop    # memories are kept in the volume
docker compose -f ~/hermes-stack/docker-compose.yml up -d
```

## Update
```bash
hermes update
npm update -g @tobilu/qmd
docker compose -f ~/hermes-stack/docker-compose.yml pull && docker compose -f ~/hermes-stack/docker-compose.yml up -d
# Ollama: download the new tarball into ~/.local/share/ollama-bin, then systemctl --user restart ollama
```

## Roll back / uninstall
```bash
cp ~/.hermes/config.yaml.orig ~/.hermes/config.yaml && cp ~/.hermes/.env.orig ~/.hermes/.env
systemctl --user disable --now ollama qmd-refresh.timer
rm ~/.local/bin/ollama ~/.config/systemd/user/{ollama.service,qmd-refresh.service,qmd-refresh.timer}
docker compose -f ~/hermes-stack/docker-compose.yml down        # add -v to DELETE memories
ollama rm qwen3:30b-a3b-instruct-2507-q4_K_M                     # frees 18.6 GB
rm -rf ~/.hermes ~/.cache/qmd ~/.local/share/ollama-bin          # full removal
```
Vault changes made during setup: `AGENTS.md`, `_hermes/`, this workshop folder, `.gitignore` entry `.obsidian/hermes/`.

## Open items
- [ ] **Rotate the credential the secrets scan found in the vault**, then remove it from the note (git history keeps the old copy)
- [ ] Review the other notes with credential-looking strings: re-run the scan in [02 Install Guide](02-install-guide.md) § 0.1
- [ ] Decide on the Hermes Console bridge plugin (blocked by Hermes' scanner, see install guide § 8)
- [ ] Obsidian: install the **Hermes Console** community plugin + "Download binaries" (UI only)
