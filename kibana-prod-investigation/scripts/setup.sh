#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${HOME}/.config/kibana-skill"

echo "[setup] creating ${CONFIG_DIR}"
mkdir -p "${CONFIG_DIR}/browser-state" "${CONFIG_DIR}/screenshots"
chmod 700 "${CONFIG_DIR}"
touch "${CONFIG_DIR}/es-calls.log"
chmod 600 "${CONFIG_DIR}/es-calls.log"

echo "[setup] installing rison"
(cd "${SKILL_DIR}/scripts/kibana-url-deps" && npm install --silent --no-audit --no-fund 2>&1 | tail -2)

echo "[setup] installing playwright + chromium"
(cd "${SKILL_DIR}/scripts/capture-deps" && npm install --silent --no-audit --no-fund 2>&1 | tail -2)
(cd "${SKILL_DIR}/scripts/capture-deps" && npx playwright install chromium 2>&1 | tail -2)

read -rp "Vault path (e.g. secret/elastic/prod): " VAULT_PATH
read -rp "Kibana base URL (e.g. https://kibana.example.com): " KIBANA_BASE_URL
read -rp "Kibana space [default]: " KIBANA_SPACE
KIBANA_SPACE="${KIBANA_SPACE:-default}"
read -rp "Kibana version [8.x]: " KIBANA_VERSION
KIBANA_VERSION="${KIBANA_VERSION:-8.x}"

ENV_FILE="${CONFIG_DIR}/env"
cat > "${ENV_FILE}" <<EOF
ES_HOST=
ES_USER=
ES_PASS=
KIBANA_BASE_URL=${KIBANA_BASE_URL}
KIBANA_SPACE=${KIBANA_SPACE}
KIBANA_VERSION=${KIBANA_VERSION}
VAULT_PATH=${VAULT_PATH}
ES_TIMEOUT=30
EOF
chmod 600 "${ENV_FILE}"

echo "[setup] fetching credentials from vault"
bash "${SKILL_DIR}/scripts/fetch-creds.sh" || echo "[setup] WARNING: fetch-creds failed — run manually after configuring vault"

echo "[setup] done"