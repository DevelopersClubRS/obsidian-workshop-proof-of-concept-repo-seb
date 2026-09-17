#!/usr/bin/env bash
# Test the "Hermes in the Vault" workshop page locally.
#
#   ./workshop-site.sh            serve on http://localhost:8080 and open the browser (Ctrl+C to stop)
#   ./workshop-site.sh serve 9000 same, on another port
#   ./workshop-site.sh check      automated checks on index.html + managed.html: loads, HTML, no personal info, links
#   ./workshop-site.sh shots      screenshots (desktop light, desktop dark, phone) into ~/workshop-site-shots
#
# Every mode rebuilds index.html first if the source file is newer.
set -euo pipefail

SITE="$HOME/Obsidian/obsidian-vault/2 Areas/PUBLIC-SPEAKING-talks/2026/Hermes-Obsidian-Workshop/site"
SRC="$SITE/hermes-in-the-vault.src.html"
PAGE="$SITE/index.html"
SHOTS="$HOME/workshop-site-shots"   # must be a non-hidden folder in $HOME: snap Chromium can't write to /tmp

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$*"; FAILED=1; }
FAILED=0

[ -f "$PAGE" ] || { echo "Can't find $PAGE"; exit 1; }

rebuild_if_needed() {
  if [ -f "$SRC" ] && [ "$SRC" -nt "$PAGE" ]; then
    bold "Source changed, rebuilding index.html"
    local tmp; tmp="$(mktemp --suffix=.html)"
    (cd "$SITE" && python3 build.py "$tmp" index.html)
    rm -f "$tmp"
  fi
}

free_port() {
  local p="$1"
  while ss -ltnH "sport = :$p" 2>/dev/null | grep -q .; do p=$((p + 1)); done
  echo "$p"
}

SERVER_PID=""
start_server() {
  PORT="$(free_port "${1:-8080}")"
  python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$SITE" >/dev/null 2>&1 &
  SERVER_PID=$!
  trap 'kill "$SERVER_PID" 2>/dev/null || true' EXIT
  for _ in $(seq 1 50); do
    curl -sf -o /dev/null "http://127.0.0.1:$PORT/" && return 0
    sleep 0.1
  done
  echo "Server didn't start on port $PORT"; exit 1
}

find_chromium() {
  for b in chromium chromium-browser google-chrome google-chrome-stable /snap/bin/chromium; do
    command -v "$b" >/dev/null 2>&1 && { command -v "$b"; return 0; }
  done
  return 1
}

mode_serve() {
  rebuild_if_needed
  local want="${1:-8080}"
  PORT="$(free_port "$want")"
  [ "$PORT" != "$want" ] && warn "Port $want is busy, using $PORT"
  local url="http://localhost:$PORT/"
  bold "Serving the workshop pages: handout $url · managed deck ${url}managed.html"
  echo "  Things to try: dark mode, phone width (DevTools Ctrl+Shift+M), Copy buttons,"
  echo "  tick the prep checklist and reload, type 'docker' in the troubleshooting filter."
  echo "  Press Ctrl+C to stop."
  if [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] && command -v xdg-open >/dev/null; then
    (sleep 0.6; xdg-open "$url" >/dev/null 2>&1) &
  fi
  exec python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$SITE"
}

mode_check() {
  rebuild_if_needed
  start_server 8080
  local url="http://127.0.0.1:$PORT/"

  local PAGE name
  for PAGE in "$SITE/index.html" "$SITE/managed.html"; do
  [ -f "$PAGE" ] || continue
  name="$(basename "$PAGE")"
  echo; bold "━━ $name"
  url="http://127.0.0.1:$PORT/$name"
  bold "1. Page loads"
  local code size
  code="$(curl -s -o /dev/null -w '%{http_code}' "$url")"
  size="$(curl -s "$url" | wc -c)"
  [ "$code" = "200" ] && ok "HTTP 200, $((size / 1024)) KB" || fail "HTTP $code"

  bold "2. HTML structure"
  python3 - "$PAGE" <<'PY' && ok "all tags closed and nested correctly" || FAILED=1
import html.parser, sys
VOID = {"meta", "link", "br", "img", "input", "hr", "source", "wbr"}
class P(html.parser.HTMLParser):
    def __init__(self):
        super().__init__(); self.stack = []; self.errors = []
    def handle_starttag(self, tag, attrs):
        if tag not in VOID: self.stack.append((tag, self.getpos()[0]))
    def handle_endtag(self, tag):
        if tag in VOID: return
        if self.stack and self.stack[-1][0] == tag: self.stack.pop()
        else: self.errors.append(f"unexpected </{tag}> on line {self.getpos()[0]}")
p = P(); p.feed(open(sys.argv[1], encoding="utf-8").read())
problems = p.errors + [f"<{t}> opened on line {l} never closed" for t, l in p.stack]
for e in problems[:5]: print("  \033[31m✗\033[0m " + e)
sys.exit(1 if problems else 0)
PY
  local ids dupes
  ids="$(grep -o ' id="[^"]*"' "$PAGE" | sort)"
  dupes="$(echo "$ids" | uniq -d)"
  [ -z "$dupes" ] && ok "$(echo "$ids" | wc -l) element ids, all unique" || fail "duplicate ids: $dupes"
  local missing=""
  for anchor in $(grep -o 'href="#[^"]*"' "$PAGE" | sed 's/href="#//; s/"$//' | sort -u); do
    grep -q " id=\"$anchor\"" "$PAGE" || missing="$missing #$anchor"
  done
  [ -z "$missing" ] && ok "all in-page links point to existing sections" || fail "broken in-page links:$missing"

  bold "3. Nothing personal leaked into the public page"
  local leaks
  leaks="$(grep -inE '/home/seb|sebastian|eqho|twilio|tow-?pilot|MAIN\.md|github_pat_[A-Za-z0-9]|Obsidian/obsidian-vault' "$PAGE" | cut -c1-120 || true)"
  [ -z "$leaks" ] && ok "no home paths, names, employer or vault details found" || { fail "possible personal details:"; echo "$leaks" | sed 's/^/      /'; }

  bold "4. External links (can take ~20 s)"
  local links total bad=0
  links="$(grep -o 'href="https://[^"]*"' "$PAGE" | sed 's/^href="//; s/"$//' | grep -vE 'fonts\.(googleapis|gstatic)\.com' | sort -u)"
  total="$(echo "$links" | wc -l)"
  while IFS=' ' read -r status link; do
    case "$status" in
      2*|3*) ;;
      403|429) warn "$status (site blocks scripts, check in a browser): $link" ;;
      *) fail "$status: $link"; bad=$((bad + 1)) ;;
    esac
  done < <(echo "$links" | xargs -P 8 -I{} sh -c \
    'printf "%s %s\n" "$(curl -sL -o /dev/null -m 15 -A "Mozilla/5.0 (X11; Linux x86_64) workshop-link-check" -w "%{http_code}" "{}")" "{}"')
  [ "$bad" -eq 0 ] && ok "$total links checked, none broken"
  done

  echo
  if [ "$FAILED" -eq 0 ]; then bold "All checks passed. Run './workshop-site.sh' to click through it yourself."
  else bold "Some checks failed (see ✗ above)."; exit 1; fi
}

mode_shots() {
  rebuild_if_needed
  local chrome; chrome="$(find_chromium)" || { echo "No Chromium/Chrome found; install one or use './workshop-site.sh' and look manually."; exit 1; }
  start_server 8080
  local url="http://127.0.0.1:$PORT/"
  mkdir -p "$SHOTS"
  bold "Taking screenshots with $chrome"
  shoot() {  # name width height extra-flags...
    local name="$1" w="$2" h="$3"; shift 3
    "$chrome" --headless=new --no-sandbox --disable-gpu --hide-scrollbars --virtual-time-budget=8000 \
      --window-size="$w,$h" "$@" --screenshot="$SHOTS/$name.png" "$url" >/dev/null 2>&1 \
      && ok "$SHOTS/$name.png" || fail "$name"
  }
  shoot desktop-light 1440 3000 --blink-settings=preferredColorScheme=1
  shoot desktop-dark  1440 3000 --blink-settings=preferredColorScheme=0 --force-dark-mode
  shoot phone-light    390 2600 --blink-settings=preferredColorScheme=1
  echo
  bold "Open them with: xdg-open $SHOTS"
}

case "${1:-serve}" in
  serve) mode_serve "${2:-8080}" ;;
  check) mode_check ;;
  shots) mode_shots ;;
  -h|--help|help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//' ;;
  *) echo "Unknown mode '$1'. Use: serve [port] | check | shots"; exit 1 ;;
esac
