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
