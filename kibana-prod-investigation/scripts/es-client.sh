#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${HOME}/.config/kibana-skill"
ENV_FILE="${CONFIG_DIR}/env"
LOG_FILE="${CONFIG_DIR}/es-calls.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "[es-client] env file missing — run setup.sh first" >&2
  exit 1
fi

load_env() {
  set -a; . "${ENV_FILE}"; set +a
}

refresh_creds() {
  echo "[es-client] 401/403 — refreshing credentials via vault" >&2
  if ! bash "${SCRIPT_DIR}/fetch-creds.sh" >/dev/null 2>&1; then
    echo "[es-client] vault refresh failed" >&2
    return 1
  fi
  load_env
}

load_env

ES_TIMEOUT="${ES_TIMEOUT:-30}"
AUTH=(-u "${ES_USER}:${ES_PASS}")

whitelist_check() {
  local method="$1" path="$2"
  local ok=0
  case "${path}" in
    /_search|/_async_search|/_count) [[ "${method}" == GET || "${method}" == POST ]] && ok=1 ;;
    /_field_caps) [[ "${method}" == GET ]] && ok=1 ;;
    /_cat/indices|/_cat/indices/*|/_cat/aliases|/_cat/aliases/*) [[ "${method}" == GET ]] && ok=1 ;;
    /_cluster/health|/_cluster/health/*) [[ "${method}" == GET ]] && ok=1 ;;
  esac
  if [[ "${path}" =~ ^/[^/]+/(_search|_count|_field_caps|_mapping)$ ]]; then
    if [[ "${method}" == GET || "${method}" == POST ]]; then ok=1; fi
    if [[ "${path}" =~ /_mapping$ && "${method}" == GET ]]; then ok=1; fi
  fi
  if [[ "${ok}" != 1 ]]; then
    echo "[es-client] REFUSED: ${method} ${path} not in read-only whitelist" >&2
    return 1
  fi
  if [[ "${method}" == PUT || "${method}" == DELETE || "${method}" == PATCH ]]; then
    echo "[es-client] REFUSED: ${method} not allowed" >&2
    return 1
  fi
  return 0
}

dsl_safety_check() {
  local dsl_file="$1"
  if [[ ! -f "${dsl_file}" ]]; then return 0; fi
  if ! command -v jq >/dev/null 2>&1; then return 0; fi
  local body; body="$(cat "${dsl_file}")"
  if printf '%s' "${body}" | jq -e '.. | .script? // empty' >/dev/null 2>&1; then
    if printf '%s' "${body}" | jq -r '.. | .script? // empty | .source? // empty' 2>/dev/null | grep -qE 'ctx\._(source|index|type)|params\._type'; then
      echo "[es-client] REFUSED: DSL contains write-capable script" >&2
      return 1
    fi
    if printf '%s' "${body}" | jq -e '.. | .aggs? // empty | .. | .script? // empty' >/dev/null 2>&1; then
      echo "[es-client] REFUSED: aggs with script not allowed" >&2
      return 1
    fi
  fi
  return 0
}

block_system_index() {
  local idx="$1"
  if [[ "${idx}" == .* ]]; then
    echo "[es-client] REFUSED: system index '${idx}' blocked" >&2
    return 1
  fi
  return 0
}

es_call() {
  local method="$1" path="$2"
  shift 2
  whitelist_check "${method}" "${path}" || return 1
  local start_ts; start_ts="$(date +%s)"
  local http_code body_file="/dev/null"
  local curl_out
  set +e
  curl_out="$(curl -sS -w '\n__HTTP_CODE__%{http_code}' -X "${method}" "${AUTH[@]}" --max-time "${ES_TIMEOUT}" "${@}" "${ES_HOST}${path}")"
  http_code="$(printf '%s' "${curl_out}" | tail -1 | sed 's/^__HTTP_CODE__//')"
  local body; body="$(printf '%s' "${curl_out}" | sed '$d')"
  set -e
  local dur=$(( $(date +%s) - start_ts ))
  local hits=0
  if [[ "${http_code}" == 200 && -n "${body}" ]]; then
    hits="$(printf '%s' "${body}" | jq -r '.hits.total.value // .count // (.hits | length) // 0' 2>/dev/null || echo 0)"
  fi
  printf '%s\t%s\t%s\thits=%s\tdur=%ss\n' "$(date -Iseconds)" "${method}" "${path}" "${hits}" "${dur}" >> "${LOG_FILE}"
  if [[ "${http_code}" == "401" || "${http_code}" == "403" ]]; then
    refresh_creds || return 1
    set +e
    curl_out="$(curl -sS -w '\n__HTTP_CODE__%{http_code}' -X "${method}" "${AUTH[@]}" --max-time "${ES_TIMEOUT}" "${@}" "${ES_HOST}${path}")"
    http_code="$(printf '%s' "${curl_out}" | tail -1 | sed 's/^__HTTP_CODE__//')"
    body="$(printf '%s' "${curl_out}" | sed '$d')"
    set -e
    if [[ "${http_code}" == "401" || "${http_code}" == "403" ]]; then
      echo "[es-client] auth failed after vault refresh" >&2
      return 1
    fi
  fi
  if [[ "${http_code}" != "2"* ]]; then
    echo "[es-client] HTTP ${http_code} for ${method} ${path}" >&2
    printf '%s\n' "${body}" >&2
    return 1
  fi
  printf '%s' "${body}"
}

run_search() {
  local idx="$1" dsl_file="$2"
  block_system_index "${idx}" || return 1
  dsl_safety_check "${dsl_file}" || return 1
  if [[ -f "${dsl_file}" ]]; then
    es_call POST "/${idx}/_search" -H 'Content-Type: application/json' --data-binary "@${dsl_file}"
  else
    es_call POST "/${idx}/_search" -H 'Content-Type: application/json' --data-binary '{}'
  fi
}

run_count() {
  local idx="$1" dsl_file="$2"
  block_system_index "${idx}" || return 1
  dsl_safety_check "${dsl_file}" || return 1
  if [[ -f "${dsl_file}" ]]; then
    es_call POST "/${idx}/_count" -H 'Content-Type: application/json' --data-binary "@${dsl_file}"
  else
    es_call POST "/${idx}/_count" -H 'Content-Type: application/json' --data-binary '{}'
  fi
}

run_field_caps() {
  local idx="$1"
  block_system_index "${idx}" || return 1
  es_call GET "/${idx}/_field_caps?fields=*"
}

run_mapping() {
  local idx="$1"
  block_system_index "${idx}" || return 1
  es_call GET "/${idx}/_mapping"
}

run_cat_indices() {
  local pattern="${1:-}"
  if [[ -n "${pattern}" ]]; then
    es_call GET "/_cat/indices/${pattern}?v&s=index"
  else
    es_call GET "/_cat/indices?v&s=index"
  fi
}

run_cluster_health() {
  es_call GET "/_cluster/health"
}

run_discover_indices() {
  es_call GET "/_cat/indices?v&s=index" | awk '{print $3}' | grep -iE 'apm|log|metric|audit|security' || true
}

run_trace_root() {
  local trace_id="$1"
  local dsl; dsl="$(mktemp)"
  cat > "${dsl}" <<EOF
{"size":500,"query":{"bool":{"filter":[{"term":{"trace.id":"${trace_id}"}}]}},"sort":[{"timestamp":"asc"}]}
EOF
  local out; out="$(es_call POST "/traces-apm-*,apm-*-transaction/_search" -H 'Content-Type: application/json' --data-binary "@${dsl}")"
  rm -f "${dsl}"
  printf '%s' "${out}" | jq '[.hits.hits[]._source] | map(select(.parent.id == null or .parent.id == "null" or (.parent.id | not))) | .[0] // empty'
}

run_trace_tree() {
  local trace_id="$1"
  local dsl; dsl="$(mktemp)"
  cat > "${dsl}" <<EOF
{"size":1000,"query":{"term":{"trace.id":"${trace_id}"}},"sort":[{"timestamp":"asc"}]}
EOF
  es_call POST "/traces-apm-*,apm-*-transaction,apm-*-span/_search" -H 'Content-Type: application/json' --data-binary "@${dsl}"
  rm -f "${dsl}"
}

run_trace_logs() {
  local trace_id="$1"
  local dsl; dsl="$(mktemp)"
  cat > "${dsl}" <<EOF
{"size":500,"query":{"term":{"trace.id":"${trace_id}"}},"sort":[{"@timestamp":"asc"}]}
EOF
  es_call POST "/logs-*,filebeat-*,*-logs-*/_search" -H 'Content-Type: application/json' --data-binary "@${dsl}"
  rm -f "${dsl}"
}

main() {
  local sub="${1:-}"
  [[ -z "${sub}" ]] && { echo "usage: es-client.sh <subcommand> [args]" >&2; exit 1; }
  shift
  case "${sub}" in
    search) run_search "$@" ;;
    count) run_count "$@" ;;
    field-caps) run_field_caps "$@" ;;
    mapping) run_mapping "$@" ;;
    cat-indices) run_cat_indices "$@" ;;
    cluster-health) run_cluster_health "$@" ;;
    discover-indices) run_discover_indices "$@" ;;
    trace-root) run_trace_root "$@" ;;
    trace-tree) run_trace_tree "$@" ;;
    trace-logs) run_trace_logs "$@" ;;
    *) echo "[es-client] unknown subcommand: ${sub}" >&2; exit 1 ;;
  esac
}

main "$@"