#!/usr/bin/env bash
# cliproxy.sh — CLIProxyAPI management CLI wrapper
# Usage: bash cliproxy.sh <command> [args...]
set -euo pipefail

BASE_URL="${CLIPROXY_BASE_URL:-http://127.0.0.1:8317}"
MGMT_BASE="${BASE_URL}/v0/management"

# Verify CLIPROXY_MGMT_PASSWORD is set
check_password() {
  if [[ -z "${CLIPROXY_MGMT_PASSWORD:-}" ]]; then
    echo "ERROR: CLIPROXY_MGMT_PASSWORD env var not set." >&2
    exit 1
  fi
}

# Core curl wrapper
api() {
  local method="$1" path="$2"
  shift 2
  check_password
  curl -sS -X "$method" \
    -H "Authorization: Bearer ${CLIPROXY_MGMT_PASSWORD}" \
    -H "Content-Type: application/json" \
    "$@" \
    "${MGMT_BASE}${path}"
}

# YAML-aware curl (no Content-Type override for GET, application/yaml for PUT)
api_yaml_get() {
  check_password
  curl -sS \
    -H "Authorization: Bearer ${CLIPROXY_MGMT_PASSWORD}" \
    "${MGMT_BASE}/config.yaml"
}

api_yaml_put() {
  check_password
  curl -sS -X PUT \
    -H "Authorization: Bearer ${CLIPROXY_MGMT_PASSWORD}" \
    -H "Content-Type: application/yaml" \
    --data-binary @- \
    "${MGMT_BASE}/config.yaml"
}

# Boolean arg helper: "on" -> true, "off" -> false
bool_val() {
  case "${1,,}" in
    on|true|1) echo "true" ;;
    off|false|0) echo "false" ;;
    *) echo "ERROR: expected on/off, got '$1'" >&2; exit 1 ;;
  esac
}

# Pretty-print JSON if jq available, else raw
pp() {
  if command -v jq &>/dev/null; then
    jq .
  else
    cat
  fi
}

cmd="${1:-help}"
shift || true

case "$cmd" in
  status)
    echo "=== Version ==="
    api GET /latest-version | pp
    echo "=== Debug ==="
    api GET /debug | pp
    echo "=== Proxy ==="
    api GET /proxy-url | pp
    echo "=== Request Retry ==="
    api GET /request-retry | pp
    echo "=== Request Log ==="
    api GET /request-log | pp
    echo "=== File Log ==="
    api GET /logging-to-file | pp
    echo "=== Usage Stats ==="
    api GET /usage-statistics-enabled | pp
    ;;

  config)
    api GET /config | pp
    ;;

  config-yaml)
    api_yaml_get
    ;;

  debug)
    if [[ $# -eq 0 ]]; then
      api GET /debug | pp
    else
      api PUT /debug -d "{\"value\":$(bool_val "$1")}" | pp
    fi
    ;;

  proxy)
    if [[ $# -eq 0 ]]; then
      api GET /proxy-url | pp
    elif [[ -z "$1" ]]; then
      api DELETE /proxy-url | pp
    else
      api PUT /proxy-url -d "{\"value\":\"$1\"}" | pp
    fi
    ;;

  retry)
    if [[ $# -eq 0 ]]; then
      api GET /request-retry | pp
    else
      api PATCH /request-retry -d "{\"value\":$1}" | pp
    fi
    ;;

  max-retry-interval)
    if [[ $# -eq 0 ]]; then
      api GET /max-retry-interval | pp
    else
      api PATCH /max-retry-interval -d "{\"value\":$1}" | pp
    fi
    ;;

  request-log)
    if [[ $# -eq 0 ]]; then
      api GET /request-log | pp
    else
      api PUT /request-log -d "{\"value\":$(bool_val "$1")}" | pp
    fi
    ;;

  file-log)
    if [[ $# -eq 0 ]]; then
      api GET /logging-to-file | pp
    else
      api PUT /logging-to-file -d "{\"value\":$(bool_val "$1")}" | pp
    fi
    ;;

  logs)
    if [[ $# -gt 0 ]]; then
      api GET "/logs?after=$1" | pp
    else
      api GET /logs | pp
    fi
    ;;

  clear-logs)
    api DELETE /logs | pp
    ;;

  error-logs)
    api GET /request-error-logs | pp
    ;;

  error-log-get)
    [[ $# -ge 1 ]] || { echo "Usage: cliproxy.sh error-log-get <filename>" >&2; exit 1; }
    check_password
    curl -sS -H "Authorization: Bearer ${CLIPROXY_MGMT_PASSWORD}" \
      -OJ "${MGMT_BASE}/request-error-logs/$1"
    ;;

  usage-stats)
    if [[ $# -eq 0 ]]; then
      api GET /usage-statistics-enabled | pp
    else
      api PUT /usage-statistics-enabled -d "{\"value\":$(bool_val "$1")}" | pp
    fi
    ;;

  usage-queue)
    local count="${1:-10}"
    api GET "/usage-queue?count=$count" | pp
    ;;

  api-keys)
    api GET /api-keys | pp
    ;;

  api-key-usage)
    api GET /api-key-usage | pp
    ;;

  api-keys-set)
    [[ $# -ge 1 ]] || { echo "Usage: cliproxy.sh api-keys-set <json-array>" >&2; exit 1; }
    api PUT /api-keys -d "$1" | pp
    ;;

  api-keys-add)
    [[ $# -ge 1 ]] || { echo "Usage: cliproxy.sh api-keys-add <key>" >&2; exit 1; }
    # Get current keys, append, PUT back
    local current
    current=$(api GET /api-keys)
    local new_list
    if command -v jq &>/dev/null; then
      new_list=$(echo "$current" | jq --arg k "$1" '.["api-keys"] + [$k]')
    else
      # Fallback: simple string manipulation
      new_list=$(echo "$current" | sed "s/]/,\"$1\"]/" | sed 's/\["/["/' | sed 's/,"/, "/')
    fi
    api PUT /api-keys -d "$new_list" | pp
    ;;

  api-keys-del)
    [[ $# -ge 1 ]] || { echo "Usage: cliproxy.sh api-keys-del <key>" >&2; exit 1; }
    api DELETE "/api-keys?value=$1" | pp
    ;;

  gemini-keys)
    api GET /gemini-api-key | pp
    ;;

  gemini-keys-set)
    [[ $# -ge 1 ]] || { echo "Usage: cliproxy.sh gemini-keys-set <json-array>" >&2; exit 1; }
    api PUT /gemini-api-key -d "$1" | pp
    ;;

  gemini-keys-add)
    [[ $# -ge 1 ]] || { echo "Usage: cliproxy.sh gemini-keys-add <json-entry>" >&2; exit 1; }
    local current
    current=$(api GET /gemini-api-key)
    local new_list
    if command -v jq &>/dev/null; then
      new_list=$(echo "$current" | jq --argjson e "$1" '.["gemini-api-key"] + [$e]')
    else
      echo "ERROR: jq required for gemini-keys-add" >&2; exit 1
    fi
    api PUT /gemini-api-key -d "$new_list" | pp
    ;;

  gemini-keys-del)
    [[ $# -ge 1 ]] || { echo "Usage: cliproxy.sh gemini-keys-del <api-key-value>" >&2; exit 1; }
    api DELETE "/gemini-api-key?api-key=$1" | pp
    ;;

  claude-keys)
    api GET /claude-api-key | pp
    ;;

  claude-keys-set)
    [[ $# -ge 1 ]] || { echo "Usage: cliproxy.sh claude-keys-set <json-array>" >&2; exit 1; }
    api PUT /claude-api-key -d "$1" | pp
    ;;

  codex-keys)
    api GET /codex-api-key | pp
    ;;

  codex-keys-set)
    [[ $# -ge 1 ]] || { echo "Usage: cliproxy.sh codex-keys-set <json-array>" >&2; exit 1; }
    api PUT /codex-api-key -d "$1" | pp
    ;;

  openai-compat)
    api GET /openai-compatibility | pp
    ;;

  openai-compat-set)
    [[ $# -ge 1 ]] || { echo "Usage: cliproxy.sh openai-compat-set <json-array>" >&2; exit 1; }
    api PUT /openai-compatibility -d "$1" | pp
    ;;

  openai-compat-add)
    [[ $# -ge 1 ]] || { echo "Usage: cliproxy.sh openai-compat-add <json-entry>" >&2; exit 1; }
    local current
    current=$(api GET /openai-compatibility)
    local new_list
    if command -v jq &>/dev/null; then
      new_list=$(echo "$current" | jq --argjson e "$1" '.["openai-compatibility"] + [$e]')
    else
      echo "ERROR: jq required for openai-compat-add" >&2; exit 1
    fi
    api PUT /openai-compatibility -d "$new_list" | pp
    ;;

  openai-compat-del)
    [[ $# -ge 1 ]] || { echo "Usage: cliproxy.sh openai-compat-del <name>" >&2; exit 1; }
    local current
    current=$(api GET /openai-compatibility)
    local new_list
    if command -v jq &>/dev/null; then
      new_list=$(echo "$current" | jq --arg n "$1" '.["openai-compatibility"] |= map(select(.name != $n))')
    else
      echo "ERROR: jq required for openai-compat-del" >&2; exit 1
    fi
    api PUT /openai-compatibility -d "$new_list" | pp
    ;;

  quota-switch-project)
    if [[ $# -eq 0 ]]; then
      api GET /quota-exceeded/switch-project | pp
    else
      api PUT /quota-exceeded/switch-project -d "{\"value\":$(bool_val "$1")}" | pp
    fi
    ;;

  quota-switch-preview)
    if [[ $# -eq 0 ]]; then
      api GET /quota-exceeded/switch-preview-model | pp
    else
      api PUT /quota-exceeded/switch-preview-model -d "{\"value\":$(bool_val "$1")}" | pp
    fi
    ;;

  ws-auth)
    if [[ $# -eq 0 ]]; then
      api GET /ws-auth | pp
    else
      api PUT /ws-auth -d "{\"value\":$(bool_val "$1")}" | pp
    fi
    ;;

  raw)
    [[ $# -ge 2 ]] || { echo "Usage: cliproxy.sh raw <METHOD> <path> [body]" >&2; exit 1; }
    local rmethod="$1" rpath="$2"
    shift 2
    if [[ $# -gt 0 ]]; then
      api "$rmethod" "$rpath" -d "$1" | pp
    else
      api "$rmethod" "$rpath" | pp
    fi
    ;;

  help|--help|-h)
    head -60 "$0" | grep -E '^\s*(#|$)' | sed 's/^# \?//'
    ;;

  *)
    echo "Unknown command: $cmd" >&2
    echo "Run: cliproxy.sh help" >&2
    exit 1
    ;;
esac
