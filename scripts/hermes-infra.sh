#!/usr/bin/env bash
# Start, stop and check the self-hosted Hermes stack for the Obsidian vault.
#
#   ./hermes-infra.sh              start everything, wait until healthy, print status
#   ./hermes-infra.sh chat         start everything, then open Hermes in the vault
#   ./hermes-infra.sh ask "..."    start everything, then ask one question
#   ./hermes-infra.sh status       health of every component, starts nothing
#   ./hermes-infra.sh stop         stop Hindsight + Ollama (frees GPU and RAM; memories are kept)
#   ./hermes-infra.sh refresh      re-index the vault now (QMD update + embed)
#
# Order matters: Docker Desktop -> Ollama (+ model warm-up) -> Hindsight -> QMD index -> Hermes.
set -uo pipefail

VAULT="$HOME/Obsidian/obsidian-vault"
STACK_DIR="$HOME/hermes-stack"
MODEL="qwen3:30b-a3b-instruct-2507-q4_K_M"
NUM_CTX=65536                        # must match model.ollama_num_ctx in ~/.hermes/config.yaml
OLLAMA_URL="http://127.0.0.1:11434"
HINDSIGHT_URL="http://127.0.0.1:8888"
export PATH="$HOME/.local/bin:$PATH"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %-12s %s\n' "$1" "${2:-}"; }
warn() { printf '  \033[33m!\033[0m %-12s %s\n' "$1" "${2:-}"; }
bad()  { printf '  \033[31m✗\033[0m %-12s %s\n' "$1" "${2:-}"; PROBLEMS=$((PROBLEMS + 1)); }
PROBLEMS=0

wait_for() {  # seconds, description, command...
  local secs="$1" what="$2"; shift 2
  local i
  for ((i = 0; i < secs * 2; i++)); do
    "$@" >/dev/null 2>&1 && return 0
    [ $((i % 10)) -eq 9 ] && printf '    waiting for %s (%ss)…\n' "$what" $(((i + 1) / 2))
    sleep 0.5
  done
  return 1
}

docker_up()    { docker info >/dev/null 2>&1; }
ollama_up()    { curl -sf -m 2 "$OLLAMA_URL/api/version" >/dev/null; }
hindsight_up() { curl -sf -m 3 "$HINDSIGHT_URL/health" | grep -q '"healthy"'; }
model_loaded() { curl -sf -m 3 "$OLLAMA_URL/api/ps" | grep -q "\"$MODEL\""; }

start_docker() {
  if docker_up; then ok "Docker" "running"; return 0; fi
  echo "  → starting Docker Desktop"
  systemctl --user start docker-desktop 2>/dev/null || { command -v docker-desktop >/dev/null && (docker-desktop >/dev/null 2>&1 &); }
  if wait_for 120 "Docker Desktop" docker_up; then ok "Docker" "started"; else bad "Docker" "didn't start; open Docker Desktop manually"; return 1; fi
}

start_ollama() {
  if ! ollama_up; then
    echo "  → starting Ollama"
    systemctl --user start ollama
    wait_for 30 "Ollama" ollama_up || { bad "Ollama" "didn't start: journalctl --user -u ollama -n 30"; return 1; }
  fi
  ok "Ollama" "$(curl -s "$OLLAMA_URL/api/version" | sed 's/.*"version":"\([^"]*\)".*/v\1/')"
  if model_loaded; then
    ok "Model" "$MODEL loaded"
  else
    echo "  → loading $MODEL into memory (first load takes ~30–60 s)"
    # Same num_ctx as Hermes, otherwise Ollama reloads the model on the first real question.
    if curl -sf -m 300 "$OLLAMA_URL/api/generate" \
         -d "{\"model\":\"$MODEL\",\"prompt\":\"\",\"keep_alive\":\"30m\",\"options\":{\"num_ctx\":$NUM_CTX}}" >/dev/null; then
      ok "Model" "$MODEL warmed up (ctx $NUM_CTX)"
    else
      warn "Model" "warm-up failed; Hermes will load it on first use (ollama list?)"
    fi
  fi
}

start_hindsight() {
  if ! hindsight_up; then
    echo "  → starting Hindsight"
    (cd "$STACK_DIR" && docker compose up -d >/dev/null 2>&1) || { bad "Hindsight" "docker compose up failed in $STACK_DIR"; return 1; }
    wait_for 120 "Hindsight" hindsight_up || { bad "Hindsight" "not healthy: docker logs hindsight --tail 30"; return 1; }
  fi
  ok "Hindsight" "healthy · UI http://localhost:9999"
}

check_qmd() {
  if ! command -v qmd >/dev/null; then
    # nvm-installed node isn't on PATH in non-interactive shells
    for d in "$HOME"/.nvm/versions/node/*/bin; do [ -x "$d/qmd" ] && export PATH="$d:$PATH"; done
  fi
  command -v qmd >/dev/null || { bad "QMD" "qmd not found (npm install -g @tobilu/qmd)"; return 1; }
  local st docs pending
  st="$(qmd status 2>/dev/null)"
  docs="$(echo "$st" | awk '/Total:/ {print $2; exit}')"
  pending="$(echo "$st" | awk '/Pending:/ {print $2; exit}')"
  if [ -n "$pending" ] && [ "$pending" != "0" ]; then
    warn "QMD" "${docs:-?} notes, $pending waiting for embeddings (run: ./hermes-infra.sh refresh)"
  else
    ok "QMD" "${docs:-?} notes indexed"
  fi
  systemctl --user is-active --quiet qmd-refresh.timer && ok "QMD timer" "refreshes every 30 min" \
    || warn "QMD timer" "inactive: systemctl --user enable --now qmd-refresh.timer"
}

check_hermes() {
  command -v hermes >/dev/null || { bad "Hermes" "not installed (see workshop install guide step 2)"; return 1; }
  ok "Hermes" "$(hermes --version 2>/dev/null | head -1 | sed 's/Hermes Agent //; s/ ·.*//')"
  if hermes tools list 2>/dev/null | grep -qE '✓ enabled +web'; then
    warn "Web tools" "ENABLED: vault questions can leak to the web (hermes tools disable web browser)"
  else
    ok "Web tools" "disabled"
  fi
  grep -q '^HERMES_WRITE_SAFE_ROOT=' "$HOME/.hermes/.env" 2>/dev/null && ok "Sandbox" "writes limited to _hermes/ + ~/.hermes" \
    || warn "Sandbox" "HERMES_WRITE_SAFE_ROOT not set in ~/.hermes/.env"
}

status_only() {
  bold "Hermes stack status"
  docker_up && ok "Docker" "running" || bad "Docker" "not running"
  if ollama_up; then
    ok "Ollama" "running"
    model_loaded && ok "Model" "$MODEL loaded" || warn "Model" "not loaded (loads on first use, ~30–60 s)"
  else
    bad "Ollama" "stopped"
  fi
  hindsight_up && ok "Hindsight" "healthy · UI http://localhost:9999" || bad "Hindsight" "not reachable"
  check_qmd
  check_hermes
  [ -x "$VAULT/_hermes/scripts/wiki_check.py" ] || [ -f "$VAULT/_hermes/scripts/wiki_check.py" ] && {
    python3 "$VAULT/_hermes/scripts/wiki_check.py" "$VAULT" >/dev/null 2>&1 && ok "Wiki" "checker passes" \
      || warn "Wiki" "checker reports problems: python3 _hermes/scripts/wiki_check.py ."
  }
}

start_all() {
  bold "Starting the Hermes stack"
  start_docker || true
  start_ollama || true
  docker_up && start_hindsight || true
  check_qmd || true
  check_hermes || true
  echo
  if [ "$PROBLEMS" -eq 0 ]; then
    bold "Ready. Try: ./hermes-infra.sh chat"
  else
    bold "$PROBLEMS component(s) need attention (see ✗ above)."
  fi
  return "$PROBLEMS"
}

case "${1:-start}" in
  start)
    start_all ;;
  chat)
    start_all || { read -r -p "Some components failed. Open Hermes anyway? [y/N] " a; [ "$a" = "y" ] || exit 1; }
    cd "$VAULT" && exec hermes ;;
  ask)
    shift
    [ $# -gt 0 ] || { echo 'Usage: ./hermes-infra.sh ask "your question"'; exit 1; }
    start_all >/dev/null || { echo "Stack isn't healthy; run ./hermes-infra.sh for details."; exit 1; }
    cd "$VAULT" && exec hermes chat --oneshot -q "$*" ;;
  status)
    status_only ;;
  refresh)
    check_qmd >/dev/null 2>&1
    bold "Re-indexing the vault"
    qmd update && qmd embed && ok "QMD" "index refreshed" ;;
  stop)
    bold "Stopping the Hermes stack"
    (cd "$STACK_DIR" && docker compose stop >/dev/null 2>&1) && ok "Hindsight" "stopped (memories kept)" || warn "Hindsight" "wasn't running"
    systemctl --user stop ollama && ok "Ollama" "stopped (GPU freed)"
    echo "  Docker Desktop and the QMD timer are left running." ;;
  -h|--help|help)
    sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//' ;;
  *)
    echo "Unknown command '$1'. Use: start | chat | ask \"...\" | status | stop | refresh"; exit 1 ;;
esac
