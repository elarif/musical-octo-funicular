# Helm Chart Conventions

**Effective date:** 2026-08-29 — **Parent skill:** `kubernetes` (body holds summary; this file holds the full Helm v4 chart rules).

## Chart layout (Helm v4, current)

```
mychart/
├── Chart.yaml
├── values.yaml            # defaults, NO secrets
├── values-prod.yaml       # env overrides, NO secrets either
├── templates/
│   ├── _helpers.tpl       # named templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml       # only if you must; prefer HTTPRoute
│   ├── httproute.yaml     # Gateway API pattern
│   ├── serviceaccount.yaml
│   ├── hpa.yaml           # autoscaling/v2 ONLY
│   ├── pdb.yaml           # policy/v1 ONLY
│   └── NOTES.txt
├── charts/                # vendored dependencies
└── crds/                  # if chart ships CRDs (Helm installs before templates)
```

## Chart.yaml minimum

```yaml
apiVersion: v2            # v1 is Helm 2 legacy — never
name: mychart
description: One-line description.
type: application         # or 'library' for shared templates
version: 0.1.0            # chart version (semver)
appVersion: "1.4.2"       # app version (string, quoted)
```

## values.yaml discipline

- All defaults inline. No empty stubs.
- Use nested maps, not flat: `image: { repository, tag, digest, pullPolicy }`.
- `digest` beats `tag` when both present. Document.
- Document each value with `# --` comments above.

## Templates

- Always `{{- include "mychart.fullname" . }}` for resource names.
- Quote string values: `{{ .Values.image.repository | quote }}`.
- Use `required` for user-must-set fields: `{{ required "db.password required" .Values.db.password }}`.
- Use `default` for optional fallbacks: `{{ .Values.replicas | default 3 }}`.
- `tpl` for user-supplied template snippets: `{{ tpl .Values.extraEnv $ | nindent 12 }}`.
- Prefer `nindent` over `indent` — handles leading newline cleanly.

## Subchart / library charts

- Type `library` chart defines shared named templates only. No rendered output.
- Use for cross-chart idioms: common labels, common security context, common service account shape.

## Anti-patterns

| ❌ | ✅ |
|---|---|
| `apiVersion: v1` in Chart.yaml | `apiVersion: v2` |
| Committing `values-prod.yaml` with `password: abc` | Use SOPS/ESO |
| `{{ .Values.foo }}` unquoted in YAML string field | `{{ .Values.foo \| quote }}` |
| Hardcoded namespace in every template | `{{ .Release.Namespace }}` |
| helm install from chart repo without values diff first | `helm template ... \| kubectl diff --server-side -f -` |

## Testing charts

- `helm lint ./mychart` — fast static check.
- `helm template ./mychart > rendered.yaml` then `kubeconform rendered.yaml`.
- `helm unittest` plugin (helm-unittest/helm-unittest) — YAML unit tests for templates.

## Release flow

1. `helm lint` + `helm template` + `kubeconform` locally.
2. Open PR with rendered diff in commit message (or CI artifact).
3. Merge → GitOps operator (Flux / ArgoCD) reconciles via HelmRelease / Application CRD.
4. Rollback via `helm rollback` OR GitOps revert PR.

## Modification

Modifications to this file require flag in `kubernetes` SKILL.md Revision History.
