#!/usr/bin/env bash
# state-tool.sh — manage projet-state.json for Bpifrance finance skills.
# The agent NEVER hand-writes projet-state.json; it calls this script.
set -euo pipefail

SHARED_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA="$SHARED_DIR/projet-state.schema.json"
STATE="./projet-state.json"

die() { echo "state-tool error: $*" >&2; exit 1; }

need_jq() { command -v jq >/dev/null 2>&1 || die "jq not installed. Install jq before continuing. No manual JSON fallback."; }

validate() {
  need_jq
  [ -f "$SCHEMA" ] || die "schema not found at $SCHEMA"
  [ -f "$STATE" ] || die "state file $STATE not found. Run 'state-tool.sh init' first."
  # Lightweight structural validation: valid JSON + required top-level keys.
  jq empty "$STATE" 2>/dev/null || die "invalid JSON in $STATE"
  for k in projet variables scenarios alertes bp_sections; do
    jq -e --arg k "$k" 'has($k)' "$STATE" >/dev/null 2>&1 || die "missing top-level key: $k"
  done
}

cmd_init() {
  need_jq
  [ -f "$STATE" ] && die "state file already exists: $STATE (remove it to reinit)"
  jq -n '{
    projet: { nom: "", activite: "", modele: "commerce", marche_etude: false, tva_regime: "reel" },
    variables: {
      apports: 0, emprunts: 0, investissements_ht: 0,
      ca_mensuel: [0,0,0,0,0,0,0,0,0,0,0,0],
      tva_collectee_mensuelle: [0,0,0,0,0,0,0,0,0,0,0,0],
      tva_deductible_mensuelle: [0,0,0,0,0,0,0,0,0,0,0,0],
      tva_a_decaisser_mensuelle: [0,0,0,0,0,0,0,0,0,0,0,0],
      tresorerie_solde: [0,0,0,0,0,0,0,0,0,0,0,0],
      tresorerie_cumul: [0,0,0,0,0,0,0,0,0,0,0,0],
      ca_annuel_ht: [0,0,0], charges_fixes: [0,0,0], charges_variables: [0,0,0],
      bfr: [0,0,0], caf: [0,0,0], seuil_rentabilite: [0,0,0], point_mort_jours: [0,0,0],
      investissements_annuels: [0,0,0], remboursements_emprunts_capital: [0,0,0], nouveaux_emprunts: [0,0,0]
    },
    scenarios: { optimiste: {}, nominal: {}, pessimiste: {} },
    alertes: [],
    bp_sections: { executive_summary: "empty", economique: "empty", financiere: "empty", juridique: "empty" },
    saas_metrics: {}
  }' > "$STATE"
  echo "initialized $STATE"
}

# get <dotted.key>  e.g. variables.apports, scenarios.nominal.ca_annuel_ht.2
cmd_get() {
  validate
  local key="$1"; shift
  jq -r --arg k "$key" 'getpath($k | split(".") | map(if . | test("^[0-9]+$") then tonumber else . end))' "$STATE"
}

# set <dotted.key> <json-value>  e.g. set variables.apports 30000 ; set variables.ca_annuel_ht '[1,2,3]'
# Bare words (saas, reel, commerce) are coerced to JSON strings; valid JSON (numbers, arrays, objects, quoted strings) is passed through.
cmd_set() {
  validate
  local key="$1"; local val="$2"
  if jq -e . <<<"$val" >/dev/null 2>&1; then
    jq --argjson v "$val" --arg k "$key" 'setpath(($k | split(".") | map(if . | test("^[0-9]+$") then tonumber else . end)); $v)' "$STATE" > "$STATE.tmp"
  else
    jq --arg v "$val" --arg k "$key" 'setpath(($k | split(".") | map(if . | test("^[0-9]+$") then tonumber else . end)); $v)' "$STATE" > "$STATE.tmp"
  fi
  mv "$STATE.tmp" "$STATE"
  validate
  echo "set $key"
}

# patch '<json-patch-array>'  e.g. patch '[{"op":"add","path":"/alertes/-","value":{...}}]'
# Supports "add" with "/-" path (array append) and "replace" (setpath).
cmd_patch() {
  validate
  local patch="$1"
  jq --argjson p "$patch" '
    reduce $p[] as $op (.;
      if $op.op == "add" and ($op.path | endswith("/-")) then
        ($op.path | ltrimstr("/") | rtrimstr("/-") | split("/") | map(if . | test("^[0-9]+$") then tonumber else . end)) as $arrpath |
        setpath($arrpath; getpath($arrpath) + [$op.value])
      else
        setpath(($op.path | ltrimstr("/") | split("/") | map(if . | test("^[0-9]+$") then tonumber else . end)); $op.value)
      end
    )
  ' "$STATE" > "$STATE.tmp" \
    && mv "$STATE.tmp" "$STATE"
  validate
  echo "patched"
}

cmd_snapshot() {
  validate
  jq '.' "$STATE"
}

usage() { cat <<EOF
state-tool.sh — manage projet-state.json
Usage:
  state-tool.sh init
  state-tool.sh get <dotted.key>
  state-tool.sh set <dotted.key> <json-value>
  state-tool.sh patch '<json-patch-array>'
  state-tool.sh snapshot
EOF
}

main() {
  need_jq
  case "${1:-}" in
    init) shift; cmd_init "$@";;
    get) shift; [ $# -ge 1 ] || die "get requires a key"; cmd_get "$@";;
    set) shift; [ $# -ge 2 ] || die "set requires a key and a value"; cmd_set "$@";;
    patch) shift; [ $# -ge 1 ] || die "patch requires a json-patch array"; cmd_patch "$@";;
    snapshot) shift; cmd_snapshot "$@";;
    *) usage; exit 1;;
  esac
}

main "$@"