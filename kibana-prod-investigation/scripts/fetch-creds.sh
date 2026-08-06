#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${HOME}/.config/kibana-skill"
ENV_FILE="${CONFIG_DIR}/env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "[fetch-creds] env file missing: ${ENV_FILE}" >&2
  exit 1
fi

set -a; . "${ENV_FILE}"; set +a

if [[ -z "${VAULT_PATH:-}" ]]; then
  echo "[fetch-creds] VAULT_PATH not set in env" >&2
  exit 1
fi

if ! command -v vault >/dev/null 2>&1; then
  echo "[fetch-creds] vault CLI not found" >&2
  exit 1
fi

VAULT_OUT="$(vault kv get -format=json "${VAULT_PATH}" 2>/dev/null || true)"
if [[ -z "${VAULT_OUT}" ]]; then
  echo "[fetch-creds] vault kv get failed for ${VAULT_PATH}" >&2
  exit 1
fi

ES_HOST_NEW="$(printf '%s' "${VAULT_OUT}" | jq -r '.data.data.ES_HOST // empty')"
ES_USER_NEW="$(printf '%s' "${VAULT_OUT}" | jq -r '.data.data.ES_USER // empty')"
ES_PASS_NEW="$(printf '%s' "${VAULT_OUT}" | jq -r '.data.data.ES_PASS // empty')"

if [[ -z "${ES_HOST_NEW}" || -z "${ES_USER_NEW}" || -z "${ES_PASS_NEW}" ]]; then
  echo "[fetch-creds] missing ES_HOST/ES_USER/ES_PASS in vault payload" >&2
  exit 1
fi

TMP="$(mktemp)"
grep -vE '^(ES_HOST|ES_USER|ES_PASS)=' "${ENV_FILE}" > "${TMP}" || true
{
  cat "${TMP}"
  printf 'ES_HOST=%s\n' "${ES_HOST_NEW}"
  printf 'ES_USER=%s\n' "${ES_USER_NEW}"
  printf 'ES_PASS=%s\n' "${ES_PASS_NEW}"
} > "${ENV_FILE}"
rm -f "${TMP}"
chmod 600 "${ENV_FILE}"

echo "[fetch-creds] credentials refreshed"