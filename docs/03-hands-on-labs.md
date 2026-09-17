---
tags: [workshop, hermes, labs]
---
# Hermes Workshop - 03 Hands-on Labs

Back to [Hermes-Obsidian-Workshop](README.md) · Prev: [02 Install Guide](02-install-guide.md) · Real transcripts: [06 Demo Log](06-demo-log.md)

Run everything **from your vault root** (`cd $VAULT`) so `AGENTS.md` loads.
Local models need ~1–3 minutes per question. That's normal, so use the wait to read the tool trace.

---

## Lab 0 — Health check (5 min)
```bash
systemctl --user is-active ollama        # or check the Ollama app on macOS/Windows
curl -s http://127.0.0.1:8888/health
qmd status | sed -n 1,10p
hermes mcp test qmd
hermes tools list | grep -E "web|browser"   # both should be ✗ disabled
```
✅ Everything green, QMD shows your note count, 0 pending embeddings.

---

## Lab 1 — Search three ways, by hand (10 min)
Before the agent does it, see what the retrieval layer returns:
```bash
qmd search "<an exact term, error code or ticket id from your notes>"   # BM25, instant
qmd vsearch "<a question phrased in words your note doesn't use>"       # vectors
qmd query  "<the same question>"                                        # hybrid + rerank, best quality
```
**Discuss:** find one query where BM25 wins (identifiers) and one where vectors win (paraphrases).
Look at the scores: does `query` separate good from bad results better?

---

## Lab 2 — Ask your vault, then verify (15 min)
```bash
hermes chat --oneshot -q "Using the qmd search tools, find what my vault says about <topic you know well>. \
Read the most relevant note, then answer in 3-5 bullets and cite the source notes as wikilinks."
```
Watch the tool trace. A good run looks like:
```
mcp__qmd__query → mcp__qmd__multi_get / get → answer with [[Note Name]]
```
**Then verify:** open the cited note in Obsidian and check **every** bullet.
- Does each claim appear in the note?
- Are numbers exact, or "roughly right"? (Reference run: the note said *70% vs 50%*; the agent said *~20% better*.)
- Did it cite a note that doesn't exist? (→ [04 Troubleshooting and Gotchas](04-troubleshooting.md))

🎯 Takeaway: citations make verification cheap, but you still have to do it.

---

## Lab 3 — Compile your first wiki pages (25 min)
Pick **3 notes on one topic** (short ones, ~1–2k words total). Then:
```bash
hermes chat --oneshot -s llm-wiki --max-turns 80 -q "Use the llm-wiki skill on the wiki at \$WIKI_PATH. \
Orient first (SCHEMA.md, index.md, log.md). Then INGEST these 3 vault notes as sources: \
'<path/one.md>', '<path/two.md>', '<path/three.md>' (paths relative to the vault root). \
Follow SCHEMA.md exactly: the vault notes ARE the sources, do not create raw/, never modify the source notes, \
cite them as wikilinks in sources frontmatter. Create or update at most 5 wiki pages, each with >=2 outbound wikilinks. \
Update index.md and append to log.md. Finish with a short list of the pages you created."
```
Then in Obsidian:
1. Open `_hermes/wiki/index.md`: are the new pages listed with summaries?
2. Open a page: frontmatter `sources:` links should jump to your original notes.
3. **Graph view**, filter `path:_hermes`: are the pages linked to each other and to sources?
4. `git status` / `git diff --stat`: **only `_hermes/` changed?**
5. **Deterministic check.** Don't trust the LLM's own bookkeeping:
   ```bash
   python3 _hermes/scripts/wiki_check.py "$VAULT"
   # reference run after ingest: 13 dangling links + off-taxonomy tags; after fixes: "0 problem(s)", exit 0
   ```
   <details><summary>wiki_check.py (copy into your vault)</summary>

   ```python
   #!/usr/bin/env python3
   """Deterministic LLM-Wiki check (don't let the model grade its own homework).

   Checks every wiki page (except SCHEMA.md / log.md) for:
     - dangling [[wikilinks]] (Obsidian resolves by vault path or by basename)
     - tags outside the SCHEMA.md "## Tag Taxonomy" section
     - frontmatter: present, keys unindented, required keys present
     - sources: every entry is a [[wikilink]] that resolves
     - self-links, and fewer than 2 outbound links to other notes/pages
   Exit code 1 if anything is found.

   Usage: python3 wiki_check.py <vault> [wiki_subdir=_hermes/wiki]
   """
   import re, sys, pathlib

   vault = pathlib.Path(sys.argv[1]).expanduser()
   wiki = vault / (sys.argv[2] if len(sys.argv) > 2 else "_hermes/wiki")
   notes = {p.relative_to(vault).with_suffix("").as_posix().lower() for p in vault.rglob("*.md")}
   notes |= {n.rsplit("/", 1)[-1] for n in notes}
   schema = (wiki / "SCHEMA.md").read_text()
   taxonomy = set(re.findall(r"`([a-z0-9-]+)`", schema.split("## Tag Taxonomy")[1].split("\n## ")[0]))
   REQUIRED = ("title", "created", "updated", "type", "tags", "sources")
   LINK = re.compile(r"\[\[([^\[\]|#^]+)")           # [^\[\]] skips the extra bracket of ^[[[...]]] markers

   problems = total = dangling = 0
   def report(kind, page, msg):
       global problems
       problems += 1
       print(f"{kind:<9} {page.relative_to(wiki)} -> {msg}")

   for page in sorted(wiki.rglob("*.md")):
       if page.name in ("SCHEMA.md", "log.md"):
           continue
       text = page.read_text()
       is_index = page.name == "index.md"
       fm = re.match(r"---\n(.*?)\n---\n", text, re.S)
       if not is_index:
           if not fm:
               report("FRONTMTR", page, "missing YAML frontmatter")
           else:
               lines = [l for l in fm.group(1).splitlines() if l.strip()]
               if any(l[0].isspace() for l in lines if re.match(r"\s*[a-z_]+:", l)):
                   report("FRONTMTR", page, "indented keys (Obsidian won't parse properties)")
               keys = {l.split(":", 1)[0].strip() for l in lines if ":" in l}
               missing = [k for k in REQUIRED if k not in keys]
               if missing:
                   report("FRONTMTR", page, f"missing keys {missing}")
               src = re.search(r"^\s*sources:\s*\[(.*)\]\s*$", fm.group(1), re.M)
               for entry in (re.findall(r'"([^"]*)"', src.group(1)) if src else []):
                   m = LINK.search(entry)
                   if not m:
                       report("SOURCES", page, f"not a wikilink: {entry}")
                   elif m.group(1).strip().removesuffix(".md").lower() not in notes:
                       report("SOURCES", page, f"source note not found: {entry}")
           tags = re.search(r"^\s*tags:\s*\[([^\]]*)\]", text, re.M)
           bad = [t.strip() for t in (tags.group(1).split(",") if tags else []) if t.strip() and t.strip() not in taxonomy]
           if bad:
               report("TAGS", page, f"not in taxonomy: {bad}")
       outbound = set()
       for target in LINK.findall(text):
           key = target.strip().removesuffix(".md").lower()
           total += 1
           if key not in notes:
               dangling += 1
               report("DANGLING", page, f"[[{target}]]")
           elif key.rsplit("/", 1)[-1] == page.stem.lower():
               report("SELFLINK", page, f"[[{target}]]")
           else:
               outbound.add(key)
       if not is_index and len(outbound) < 2:
           report("LINKS", page, f"only {len(outbound)} outbound link(s) to other notes (schema: >= 2)")

   print(f"\n{total} wikilinks, {total - dangling} resolve, {dangling} dangling; {problems} problem(s); taxonomy has {len(taxonomy)} tags")
   sys.exit(1 if problems else 0)
   ```
   </details>

🎯 Takeaway: this is the extraction step. Knowledge from scattered notes becomes a linked, cited page you can reuse.

### Lab 3b — Fix loop: script finds, agent fixes, script re-checks (15 min)
**Don't** ask the agent to lint its own wiki: in the reference run it looped for 120 tool calls and then reported
"all links resolve" when 13 didn't ([06 Demo Log](06-demo-log.md), Demo 3). Instead:
```bash
python3 _hermes/scripts/wiki_check.py "$VAULT" > /tmp/check.txt; echo "exit=$?"
{ echo "Use the llm-wiki skill. A deterministic checker found these problems in \$WIKI_PATH:"; cat /tmp/check.txt
  echo "Fix them by editing only the files named above. Wikilinks between wiki pages use the file name ([[unified-memory]]);"
  echo "terms without a page become plain text. Tags only from SCHEMA.md. Frontmatter keys unindented."
  echo "sources entries must stay [[Note Name]] wikilinks. Don't change prose. Don't claim success; list your edits."
} > /tmp/fix.txt
hermes chat --oneshot -s llm-wiki --max-turns 60 --query-file /tmp/fix.txt
python3 _hermes/scripts/wiki_check.py "$VAULT"; echo "exit=$?"     # repeat until exit=0
git log -p --since=1.hour -- _hermes/wiki | less                   # review every change
```
Reference: 13 → 6 → 0 dangling in two rounds. Round 2 silently broke the `sources:` links, which is why the checker
also validates sources. Then **read the pages**: an invented sentence survived both agent rounds.

---

## Lab 4 — Memory across sessions (15 min)
**Session A:**
```bash
hermes chat --oneshot -q "Remember this preference for all future sessions: when you answer questions about my vault, \
end every answer with a line 'Sources:' listing the wikilinks you used."
```
Open http://localhost:9999 → bank → memories. Wait for the retain to finish (it uses the local LLM, ~30–60 s).
Also check `cat ~/.hermes/memories/USER.md`.

**Session B** (new process = new session):
```bash
hermes chat --oneshot -q "How do I want you to format answers about my vault?"
```
✅ The agent recalls the preference without being told again, and the trace shows `👁️ Hindsight — recalled N memories`.
❌ No recall line? Set `"recall_sync": true` in `~/.hermes/hindsight/config.json`. The default injects memories on
the *next* turn, which a one-shot session never has.

**Also look for:** in the reference run the agent replied "I will remember" but made **0 tool calls**, so `USER.md`
stayed empty. Hindsight's auto-retain saved it anyway. Don't trust the sentence; check the stores.

**Discuss:** which layer answered it, `USER.md` (hot, in the prompt) or Hindsight (recalled)? Look for
`👁️ Hindsight — recalled N memories` in the trace.

---

## Lab 5 — Try to break the rules (10 min)
1. **Soft rule:** ask Hermes to "fix a typo in `<some human note>`" without saying you explicitly allow it.
   It should refuse or ask, per `AGENTS.md`.
2. **Hard rule:** add the write sandbox and restart Hermes:
   ```bash
   echo "HERMES_WRITE_SAFE_ROOT=$VAULT/_hermes:$HOME/.hermes" >> ~/.hermes/.env
   ```
   Now explicitly ask it to append a line to a scratch note outside `_hermes/`. `write_file`/`patch` must fail with
   *"outside HERMES_WRITE_SAFE_ROOT"*.
3. `git status`: nothing outside `_hermes/` changed.

⚠️ `HERMES_WRITE_SAFE_ROOT` guards the **file tools**. A shell redirect through the `terminal` tool is not covered.
For a real guarantee use the Docker read-only mount variant (Install Guide § 9).

---

## Stretch labs
- **Lint:** `hermes chat --oneshot -s llm-wiki -q "Lint the wiki at \$WIKI_PATH and report findings by severity. Don't fix anything."`
- **Query + file:** ask a comparison question across wiki pages and have it saved under `queries/`.
- **Scheduled extraction** (see the Hermes cron docs): a weekly job that ingests the last 7 daily notes into the wiki. Review its `log.md` entries before trusting it.
- **Hermes Console** in Obsidian: highlight a paragraph and send it as context (Install Guide § 8).
