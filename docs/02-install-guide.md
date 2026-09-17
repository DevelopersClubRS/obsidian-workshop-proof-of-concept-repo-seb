---
tags: [workshop, hermes, obsidian, install]
---
# Hermes Workshop - 02 Install Guide

Back to [Hermes-Obsidian-Workshop](README.md) · Prev: [01 Architecture and Concepts](01-architecture-and-concepts.md) · Next: [03 Hands-on Labs](03-hands-on-labs.md)

Fully self-hosted: **no cloud LLM, no API keys**. ~45–60 min, mostly downloads (~25 GB).

> **Tested on:** Ubuntu (kernel 7.0), RTX 3080 10 GB, i9-11900K, 62 GB RAM, Docker Desktop for Linux, Node 22.
> Steps marked *(untested here)* are from official docs but were not run on the reference machine.

## 0. Prerequisites

| Need | Why | Check |
|---|---|---|
| GPU ≥ 10 GB VRAM **and** ≥ 32 GB RAM, or Apple Silicon ≥ 32 GB unified | Local model with ≥ 64K context | `nvidia-smi` |
| ~40 GB free disk | model 18.6 GB + Hindsight image 3.7 GB + QMD models 2 GB | `df -h ~` |
| Docker (Desktop or Engine) | Hindsight memory server | `docker compose version` |
| Node.js ≥ 22 | QMD | `node --version` |
| git, curl | installers | |
| Obsidian vault **under git** | undo anything the agent does | `git -C <vault> log -1` |

Placeholders used below. Replace them with your own:
```bash
export VAULT="$HOME/Obsidian/MyVault"     # absolute path, no ~ inside config files
```

### 0.1 Scan your vault for secrets first
Your notes will be indexed and read by an agent. Count notes with credential-looking strings:
```bash
grep -rlIE --include='*.md' \
  '(sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY|eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}|AIza[0-9A-Za-z_-]{35}|mongodb(\+srv)?://[^ ]*:[^ ]*@)' \
  "$VAULT" | wc -l
```
Rotate and remove what you find, or at least know it's there. (The reference vault had 14.)

---

## 1. Local LLM: Ollama + a long-context model

### 1.1 Install Ollama
**Linux, no sudo (user-level service).** Used on the reference machine:
```bash
mkdir -p ~/.local/share/ollama-bin && cd ~/.local/share/ollama-bin
curl -fsSL https://github.com/ollama/ollama/releases/download/v0.34.1/ollama-linux-amd64.tar.zst -o ollama.tar.zst
tar --zstd -xf ollama.tar.zst && rm ollama.tar.zst
ln -sf ~/.local/share/ollama-bin/bin/ollama ~/.local/bin/ollama    # put the CLI on PATH
```
`~/.config/systemd/user/ollama.service`:
```ini
[Unit]
Description=Ollama (user-level) - local LLM for Hermes + Hindsight
After=network-online.target

[Service]
ExecStart=%h/.local/share/ollama-bin/bin/ollama serve
Environment=OLLAMA_HOST=127.0.0.1:11434
Environment=OLLAMA_CONTEXT_LENGTH=65536
Environment=OLLAMA_FLASH_ATTENTION=1
Environment=OLLAMA_KV_CACHE_TYPE=q8_0
Environment=OLLAMA_MAX_LOADED_MODELS=1
Environment=OLLAMA_NUM_PARALLEL=1
Environment=OLLAMA_KEEP_ALIVE=30m
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```
```bash
systemctl --user daemon-reload && systemctl --user enable --now ollama
curl -s http://127.0.0.1:11434/api/version
journalctl --user -u ollama | grep "inference compute"   # should name your GPU
```
**macOS / Windows** *(untested here)*: install from ollama.com. Hermes sends the context size per request (step 3),
so the only server-side settings that matter are flash attention and the q8_0 KV cache.

**With sudo on Linux**: the official `curl -fsSL https://ollama.com/install.sh | sh` works too. Add the same
`Environment=` lines with `systemctl edit ollama`.

### 1.2 Pull the model
```bash
export OLLAMA_HOST=127.0.0.1:11434
ollama pull qwen3:30b-a3b-instruct-2507-q4_K_M     # 18.6 GB, MoE 30B total / 3B active, 256K native context
```
Why this model (details in [04 Troubleshooting and Gotchas](04-troubleshooting.md)):
- Hermes needs **≥ 64K context** for tool use. `qwen3:8b` and `qwen3:30b-a3b` (original) are capped at 40,960, so Hermes refuses them.
- 8B models hallucinated answers in testing instead of reading the notes.
- MoE with 3B active parameters stays usable when part of the model runs from system RAM.

---

## 2. Install Hermes Agent
```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh -o hermes-install.sh
less hermes-install.sh                      # read before running; sudo is only used for optional packages
bash hermes-install.sh --non-interactive --skip-setup
source ~/.bashrc
hermes --version                            # tested: v0.21.3
```
It installs into `~/.hermes/` (code in `~/.hermes/hermes-agent`, config `~/.hermes/config.yaml`, secrets `~/.hermes/.env`).

## 3. Point Hermes at the local model
```bash
hermes config set model.provider custom
hermes config set model.base_url http://127.0.0.1:11434/v1
hermes config set model.default qwen3:30b-a3b-instruct-2507-q4_K_M
hermes config set model.ollama_num_ctx 65536
hermes config set model.context_length 65536
```
Smoke test:
```bash
hermes chat --oneshot -q "Say hello in five words."
```

### 3.1 Lock the toolset down (don't skip this)
Hermes ships with **web search, browser, TTS, image generation and vision enabled**. In testing, a local model
that couldn't find its vault tools silently **searched the web instead** (sending the query off the machine) and
then cited made-up notes. For a private vault agent, turn those off:
```bash
hermes tools disable web browser image_gen tts vision computer_use connections
hermes tools list      # keep: terminal, file, code_execution, skills, todo, memory, session_search, clarify, delegation, cronjob
```
Also turn off **Tool Search**. It defaults to on and hides MCP tools (like QMD's) behind a `tool_search` lookup
that local models tend to skip:
```bash
hermes config set tools.tool_search.enabled off
```
QMD only adds 4 tool schemas, so loading them directly costs almost nothing.

---

## 4. Vault search: QMD
```bash
npm install -g @tobilu/qmd
qmd --version                                # tested: 2.8.3
```
Edit `~/.config/qmd/index.yml`. Keep the `models:` block QMD generated, and add collections:
```yaml
collections:
  vault:
    path: /home/you/Obsidian/MyVault          # absolute
    pattern: "**/*.md"
    ignore:
      - ".obsidian/**"
      - ".trash/**"
      - "_hermes/**"                          # the wiki gets its own collection
      - "**/Templates/**"                     # template placeholders pollute results
    includeByDefault: true
    context:                                  # describe each top folder: improves reranking a lot
      "/": "Personal Obsidian vault (PARA). Human-written notes."
      "/1 Projects": "Active projects with a deadline or deliverable"
      "/2 Areas": "Ongoing areas of responsibility"
      "/3 Resources": "Reference material and learning notes by topic"
      "/4 Archives": "Inactive material"
  wiki:
    path: /home/you/Obsidian/MyVault/_hermes/wiki
    pattern: "**/*.md"
    includeByDefault: true
    context:
      "/": "Agent-compiled LLM Wiki pages with citations back to vault notes"
```
```bash
mkdir -p "$VAULT/_hermes/wiki"
qmd update          # scan files → BM25 index (seconds)
qmd embed           # vectors; first run downloads ~2 GB of GGUF models (reference: 2,330 notes → 12,558 chunks)
qmd query "how do I deploy"      # try it
```
Keep the index fresh (Linux): `~/.config/systemd/user/qmd-refresh.service` + `.timer`:
```ini
# qmd-refresh.service
[Unit]
Description=Refresh QMD index for the Obsidian vault
[Service]
Type=oneshot
Environment=PATH=/path/to/node/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/bin/sh -c 'qmd update && qmd embed'
Nice=10
```
```ini
# qmd-refresh.timer
[Unit]
Description=Refresh QMD vault index every 30 minutes
[Timer]
OnBootSec=5min
OnUnitActiveSec=30min
Persistent=true
[Install]
WantedBy=timers.target
```
```bash
systemctl --user daemon-reload && systemctl --user enable --now qmd-refresh.timer
```

### 4.1 Connect QMD to Hermes (MCP)
`hermes mcp add` opens an interactive picker, so in scripts append this to `~/.hermes/config.yaml` instead:
```yaml
mcp_servers:
  qmd:
    command: qmd
    args: ["mcp"]
    connect_timeout: 60
```
```bash
hermes mcp test qmd      # expect: ✓ Connected, 4 tools (query, get, multi_get, status)
```

---

## 5. Long-term memory: Hindsight in Docker
`~/hermes-stack/docker-compose.yml`:
```yaml
name: hermes-stack

services:
  hindsight:
    image: ghcr.io/vectorize-io/hindsight:latest
    container_name: hindsight
    restart: unless-stopped
    ports:
      - "127.0.0.1:8888:8888"   # Memory API (Hermes talks to this)
      - "127.0.0.1:9999:9999"   # Control-plane web UI
    extra_hosts:
      - "host.docker.internal:host-gateway"
    environment:
      HINDSIGHT_API_LLM_PROVIDER: ollama
      HINDSIGHT_API_LLM_BASE_URL: http://host.docker.internal:11434/v1
      HINDSIGHT_API_LLM_MODEL: ${HINDSIGHT_LLM_MODEL:-qwen3:30b-a3b-instruct-2507-q4_K_M}
      # MUST equal Hermes' model.ollama_num_ctx, or Ollama reloads the model on every switch
      HINDSIGHT_API_LLM_OLLAMA_NUM_CTX: ${OLLAMA_NUM_CTX:-65536}
      HINDSIGHT_API_LLM_MAX_CONCURRENT: 1
      HINDSIGHT_API_LLM_TIMEOUT: 600
    volumes:
      - hindsight-data:/home/hindsight/.pg0      # embedded PostgreSQL = your memories
      - hindsight-cache:/home/hindsight/.cache   # local embedding + reranker weights

volumes:
  hindsight-data:
  hindsight-cache:
```
```bash
cd ~/hermes-stack && docker compose up -d
curl -s http://127.0.0.1:8888/health          # {"status":"healthy","database":"connected",...}
docker exec hindsight python3 -c "import urllib.request;print(urllib.request.urlopen('http://host.docker.internal:11434/api/version').read())"
```
> **Docker Desktop vs Docker Engine on Linux.** Docker Desktop proxies `host.docker.internal` to the host's
> loopback, so Ollama on `127.0.0.1` works. **Docker Engine** maps it to the `docker0` bridge (`172.17.0.1`),
> so Ollama must listen there (`OLLAMA_HOST=172.17.0.1:11434`) or on `0.0.0.0` behind a firewall. Check with
> `docker context ls`.

### 5.1 Tell Hermes to use it
```bash
# Hermes ships its own uv; the plugin would also lazy-install this on first use
~/.hermes/bin/uv pip install --python ~/.hermes/hermes-agent/venv/bin/python "hindsight-client>=0.6.1"
hermes config set memory.provider hindsight
cat >> ~/.hermes/.env <<'EOF'
HINDSIGHT_MODE=local_external
HINDSIGHT_API_URL=http://127.0.0.1:8888
EOF
mkdir -p ~/.hermes/hindsight
cat > ~/.hermes/hindsight/config.json <<'EOF'
{
  "mode": "local_external",
  "api_url": "http://127.0.0.1:8888",
  "bank_id": "my-vault",
  "bank_retain_mission": "Extract durable facts about the user (preferences, projects, people, decisions) and about the vault/wiki. Never store credentials, tokens or connection strings.",
  "memory_mode": "hybrid",
  "recall_budget": "mid",
  "recall_sync": true,
  "recall_types": "observation,world",
  "auto_retain": true,
  "retain_async": true
}
EOF
hermes memory status
```
Why `recall_sync: true`: the default runs recall in the background and injects it on the **next** turn, so
single-turn `--oneshot` runs never see memories (verified in [06 Demo Log](06-demo-log.md), Demo 4).
(Interactive alternative: `hermes memory setup` → hindsight → Local External.)

---

## 6. Wire the vault in

### 6.1 Env vars for the bundled skills
```bash
cat >> ~/.hermes/.env <<EOF
OBSIDIAN_VAULT_PATH=$VAULT
WIKI_PATH=$VAULT/_hermes/wiki
# Hard sandbox for write_file/patch: only the agent-owned folder + Hermes' own state (skills, cron)
HERMES_WRITE_SAFE_ROOT=$VAULT/_hermes:$HOME/.hermes
EOF
hermes config set terminal.cwd "$VAULT"
```
`HERMES_WRITE_SAFE_ROOT` rejects `write_file`/`patch` outside those prefixes, with no approval prompt to override.
Verified: an explicitly requested write to a human note failed with *"outside the allowed write path"* and the file
stayed byte-identical. It does **not** cover shell redirects through the `terminal` tool (see § 9 for the hard version).

### 6.2 `AGENTS.md` at the vault root (rules)
Hermes loads `AGENTS.md` from the working directory into every session. Minimum content:
```markdown
# AGENTS.md — rules for AI agents working in this vault
## Ownership
1. Everything outside `_hermes/` is human-written and READ-ONLY. Don't edit, move, rename or delete it unless
   the user explicitly asks in this conversation.
2. `_hermes/` is agent-owned. The LLM Wiki lives in `_hermes/wiki/`; follow its SCHEMA.md.
## How to find things
1. Search first with the `qmd` MCP tools: `query` (lex: for exact terms, vec: for questions), then `get` to READ the notes.
2. `search_files` only for exact regex or very recent edits.
## Answering
- Cite sources as [[Note Name]] wikilinks (no path, no .md). Say when the vault has nothing.
## Secrets
- Never copy credentials into answers, wiki pages, memory or logs. Write [REDACTED credential — see [[Note]]].
## Don'ts
- No git commands. Don't touch .obsidian/. Ask before changing more than 10 wiki pages.
```
The reference vault's full version is `AGENTS.md` at the root of Seb's vault.

### 6.3 Wiki scaffold
Create `_hermes/wiki/SCHEMA.md`, `index.md`, `log.md`. Or ask Hermes: *"Initialize an LLM wiki at $WIKI_PATH for
&lt;your domain&gt;"*. Key adaptation in SCHEMA.md for an existing vault:
```markdown
## Sources — adaptation for an existing vault
This wiki does not use raw/. The vault itself is the immutable source layer.
Sources are vault notes referenced by wikilink: sources: ["[[Note Name]]"]. Never copy or modify them.
```
Add the deterministic checker `_hermes/scripts/wiki_check.py` (code in [03 Hands-on Labs](03-hands-on-labs.md), Lab 3).
Run it after every ingest or fix. It exits `1` on dangling links, off-taxonomy tags, broken frontmatter, unlinked
sources, self-links, or pages with fewer than 2 outbound links.

---

## 7. Verify everything
```bash
hermes doctor
hermes mcp test qmd
hermes memory status
curl -s http://127.0.0.1:8888/health
cd "$VAULT" && hermes chat --oneshot -q "Use the qmd tools to find my notes about <topic you know well>. Read the top note and summarize it in 3 bullets with [[wikilink]] citations."
```
✅ Pass criteria: the answer contains facts you can find in the cited note. **Open the note and check.**

---

## 8. Optional: Hermes Console inside Obsidian
Chat with Hermes in an Obsidian terminal tab and send highlighted text as context.
1. Obsidian → Settings → Community plugins → Browse → **Hermes Console** → Install → Enable
2. Settings → Hermes Console → **Download binaries** (node-pty)
3. Hermes-side context bridge: `hermes plugins install dannyshmueli/obsidian-hermes-console --enable`

> ⚠️ Hermes' plugin scanner **blocks** this bridge by default ("caution" verdict, 42 findings: 18 HIGH / 24 MEDIUM,
> 2026-09-16). Most HIGH hits are README phrases ("Send context to Hermes") and prebuilt Windows ARM64
> PTY binaries. Review the findings yourself before adding `--force`. Without the bridge, the Console tab still
> works as a plain terminal running `hermes`.

Add to the vault's `.gitignore` (rewritten on every prompt): `.obsidian/hermes/`

---

## 9. Hardened variant *(untested here)*
To make "the agent can't edit human notes" a hard guarantee instead of an `AGENTS.md` rule, run Hermes itself
in Docker (`nousresearch/hermes-agent`, state in `/opt/data`) and mount the vault read-only with only the wiki
writable:
```yaml
volumes:
  - ~/.hermes:/opt/data
  - /home/you/Obsidian/MyVault:/vault:ro
  - /home/you/Obsidian/MyVault/_hermes:/vault/_hermes:rw
```
See the official Hermes Docker docs. Never point two containers at the same `~/.hermes`.
