---
tags: [workshop, hermes, troubleshooting]
---
# Hermes Workshop - 04 Troubleshooting and Gotchas

Back to [Hermes-Obsidian-Workshop](README.md)

Every item here was hit while building the reference setup on 2026-09-16. Symptom → cause → fix.

## Model / Ollama

### "Ollama runtime context is too small for Hermes tool use"
- **Cause:** Hermes v0.21 requires **≥ 64,000** tokens of runtime context. Original Qwen3 models (`qwen3:8b`,
  `qwen3:30b-a3b`) are capped at **40,960** in Ollama, whatever you set.
- **Fix:** use a model with native long context, e.g. `qwen3:30b-a3b-instruct-2507-q4_K_M` (256K), and set
  `model.ollama_num_ctx: 65536` + `model.context_length: 65536`.
- **Check:** `curl -s http://127.0.0.1:11434/api/ps` shows `context_length` of the loaded model.

### The agent "answers" without reading the note
- **Symptom:** it calls `query`, gets the right file, then writes plausible bullets that aren't in the note.
  Its reasoning says things like *"Since I can't access the file directly, I'll rely on the context provided"*.
- **Cause:** small models (tested: `qwen3:8b`) skip the `get` step and fill in from training data.
- **Fix:** a stronger model; `AGENTS.md` rule "search, then `get` to READ"; say "read the note" in the prompt.
  **Always open one cited note and check** during the workshop. It's the best lesson of the day.

### The agent never calls QMD, searches the web, and cites notes that don't exist
- **Symptom:** tool trace shows `tool_search` ×3 → `web_search` → `web_extract learn.microsoft.com`, and the answer
  cites `[[RAG Precision Enhancement]]`, `[[Reranking Models]]`, and other notes that aren't in the vault.
- **Cause 1:** **Tool Search** (default `auto` = on) replaces MCP tools with `tool_search`/`tool_describe`/`tool_call`
  bridges. The local model searched badly, concluded the vault tool didn't exist, and fell back to visible core tools.
- **Cause 2:** the `web` toolset is **enabled by default**, so the fallback sent the query to the internet.
- **Fix:** `hermes config set tools.tool_search.enabled off` and
  `hermes tools disable web browser image_gen tts vision computer_use connections`.
  After the fix, the same question ran `mcp__qmd__query → multi_get → get` and answered correctly in 98 s.

### Memory poisoning from a bad run
- The failed run above wrote `"No direct vault note found"` into `MEMORY.md`, and Hindsight retained the hallucinated
  answer **including fake entities** (`RAG Precision Enhancement`, …). Future sessions would "remember" wrong facts.
- **Fix:** after a bad session, clean up: `: > ~/.hermes/memories/MEMORY.md` (or `hermes memory reset`) and delete
  the Hindsight bank or documents (`curl -X DELETE http://127.0.0.1:8888/v1/default/banks/<bank_id>`), or
  browse and prune in the UI at http://localhost:9999.
- **Prevention:** set `memory.write_approval: true` while you're still tuning the setup.

### `ollama pull gpt-oss:20b` → `Error: EOF`
- Registry manifest answered HTTP 200 via curl, but Ollama 0.34.1 kept failing at "pulling manifest".
  Other models pulled fine. Not investigated further; switched models. If it happens to you, try another tag or retry later.

### Model reloads constantly / every turn is slow
- **Cause:** Hermes and Hindsight request different `num_ctx` → Ollama unloads and reloads the model.
- **Fix:** same value in `model.ollama_num_ctx` (Hermes) and `HINDSIGHT_API_LLM_OLLAMA_NUM_CTX` (Hindsight).
  Keep `OLLAMA_MAX_LOADED_MODELS=1` on a single GPU.

### VRAM is tight
- QMD's models (~2 GB) and the LLM share the GPU. Symptoms: slow first query, Ollama offloading more layers to CPU.
- Options: `OLLAMA_KV_CACHE_TYPE=q8_0` + `OLLAMA_FLASH_ATTENTION=1` (halves KV cache), or run QMD on CPU with
  `QMD_LLAMA_GPU=false` in the MCP server `env:`.

### `qmd query` says "InsufficientMemoryError: A context size of 2048 is too large for the available VRAM"
- **Cause:** the LLM is loaded in Ollama (~8 GB VRAM), so QMD's 1.7B **query-expansion** model doesn't fit. QMD falls
  back silently: results still come back (13 s), but ranking is worse (the right note dropped out of the top 3).
  Forcing CPU (`QMD_LLAMA_GPU=false`) ranks well but takes 48 s.
- **Fix:** use a **structured query**, which skips the expansion model:
  `qmd query $'lex: ColBERT reranker\nvec: how to re-rank retrieved snippets in RAG'` → right note #1 in 7 s.
  Hermes' MCP `query` tool already works this way (the agent writes the `lex:`/`vec:` lines), so the agent path isn't affected.

### Ollama killed an in-flight `pull` after a restart
- Pulls are resumable: run `ollama pull` again.

### The agent's own lint says "all links resolve" when 13 don't
- Seen with `qwen3:30b-a3b-instruct-2507`: `execute_code` is blocked in unattended sessions, the model fell into a
  `read_file SCHEMA.md` loop (Hermes' loop guard blocked repeats), hit the 60-iteration budget, then **wrote a
  confident all-green report anyway**.
- **Fix:** run deterministic checks with a script (`_hermes/scripts/wiki_check.py`) and give its output to the agent to *fix*.
  Treat any report that ends with `⚠ Iteration budget reached` as unreliable.

### "I will remember that" — but nothing was saved
- The model promised to remember a preference but made 0 tool calls; `USER.md`/`MEMORY.md` stayed empty.
  Hindsight's **auto-retain** caught it anyway. Without an external provider, that preference would have been lost.
- Check with `cat ~/.hermes/memories/*.md` or the Hindsight UI instead of trusting the sentence.

### Hindsight memories never show up in `--oneshot` runs
- **Cause:** `recall_sync: false` (default) runs recall in the background and injects results on the **next** turn.
  One-turn sessions never get them.
- **Fix:** `"recall_sync": true` in `~/.hermes/hindsight/config.json` (adds ~1 s). You should see
  `👁️ Hindsight — recalled N memories`. Also consider `"recall_types": "observation,world"`, since the default is observations only.

## Docker / Hindsight

### Hindsight can't reach Ollama: `[Errno 101] Network is unreachable`
- **Cause:** on **Docker Desktop** (even on Linux) containers run in a VM. `host.docker.internal` resolves to the VM
  gateway (`192.168.65.x`) and is proxied to the **host loopback**, so binding Ollama to `docker0`
  (`172.17.0.1`) breaks it.
- **Fix (Desktop):** Ollama on `127.0.0.1:11434`, Hindsight uses `http://host.docker.internal:11434/v1`.
- **Fix (Docker Engine):** the reverse: `host-gateway` = `172.17.0.1`, so Ollama must listen there.
- **Tell which you have:** `docker context ls` (`desktop-linux *` = Desktop).
- **Test from inside:** `docker exec hindsight python3 -c "import urllib.request;print(urllib.request.urlopen('http://host.docker.internal:11434/api/version').read())"`

### Don't expose Hindsight to your LAN
- The API and UI have no auth by default. Publish ports as `127.0.0.1:8888:8888` / `127.0.0.1:9999:9999`.

### Memories disappear after `docker compose down -v` / image update
- Memories live in the **named volume** `hindsight-data` (`/home/hindsight/.pg0`). `down` is safe; `down -v` deletes them.

## Hermes CLI

### `hermes mcp add qmd --command qmd --args mcp` hangs
- It's interactive (tool-selection picker) and waits on stdin. In scripts, edit `~/.hermes/config.yaml` directly
  (`mcp_servers:` block), then `hermes mcp test qmd`.

### `pkill -f "hermes mcp add"` killed my own shell
- The pattern matched the command line of the shell running `pkill`. Use `pgrep -af` first, then `kill <pid>`.

### `until ! pgrep -f "hermes chat …"; do sleep; done` never finishes
- Same trap: the wait loop's own command line contains the pattern, so it waits on itself forever. The ingest had finished
  after 3.5 min. Wait on something else, e.g. `hermes … > out.txt; echo finished` and poll for `finished` in the file.

### The fix round "passed" the checker but broke citations
- Round 2 of the fix loop turned `sources: ["[[Note]]"]` into `sources: ["Note"]`. The v1 checker only looked at
  links that existed, so it reported 0 dangling. **A checker only guards what it checks.** v2 validates sources,
  frontmatter indentation, self-links and ≥ 2 outbound links, and exits non-zero. Review diffs with `git log -p -- _hermes/wiki`.

### Community plugin install: `Decision: BLOCKED — community source + caution verdict`
- Hermes scans plugins on install. Read the findings (many are heuristic, e.g. README text matching
  "exfiltration"). Only `--force` after reviewing the code and binaries yourself.

### Installer warning: "No sudo available — skipping system-library install"
- Only affects Playwright browser tools (`sudo npx playwright install-deps chromium`). Not needed for the vault setup.

## QMD

### Search misses notes I wrote 5 minutes ago
- `qmd update` indexes text, `qmd embed` creates vectors. Both need to run. Use the systemd timer from the
  install guide, or run them manually before a demo.

### Results full of template placeholders / junk
- Add `ignore:` globs per collection (templates, attachments, canvas tests, debug dumps), then `qmd update`
  and `qmd cleanup`.

### Poor ranking between daily notes and reference notes
- Add `context:` descriptions per folder (`qmd context add qmd://vault/1\ Projects "..."` or in `index.yml`).

## Vault hygiene

### Credentials in notes
- Real vaults contain pasted tokens (the reference vault had **14 notes**, including a GitHub PAT in a top-level note).
  With a local LLM nothing leaves the machine, but the agent can still copy secrets into wiki pages.
  **Rotate the credential**, delete it from the note, and remember that **git history keeps it**.

### Obsidian auto-commit sweeps agent files into git
- Expected, and it's your undo button. Add churn files to `.gitignore`, e.g. `.obsidian/hermes/`.
