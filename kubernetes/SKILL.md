---
name: kubernetes
description: Use when writing, editing, reviewing, or debugging Kubernetes manifests (YAML) or Helm/Kustomize artifacts targeting k8s v1.35+ — emitting manifests with removed APIs (PodSecurityPolicy, dockershim-era, extensions/v1beta1 Ingress) crashes apply on modern clusters, and latest-tag/hostNetwork/emptyDir-for-stateful silently breaks security and reliability
type: sub-skill
contracts:
  - api-discipline
  - workload-authoring
  - resources-and-limits
  - anti-patterns-table
  - helm-kustomize-conventions
  - safe-change-discipline
  - observability-hints
---

# Kubernetes

## The Iron Law

> **NO KUBERNETES MANIFEST WITHOUT `apiVersion` STABLE AND `kind` FROM A NON-REMOVED API GROUP.**

This is not a guideline. LLM training data is full of 2020-era patterns that broke years ago on modern clusters: `PodSecurityPolicy` was removed in v1.25, `extensions/v1beta1` Ingress in v1.22, dockershim in v1.24, `Service.spec.externalIPs` in v1.36, in-tree cloud providers in v1.29. Every manifest this skill emits, edits, or approves targets k8s v1.35+ (N-2 support window as of v1.37 stable). If you are about to emit a manifest with a deprecated/removed API, stop and consult section D (anti-patterns table) and the cluster's `kubectl api-versions` output.

## Hard Gate

<HARD-GATE>
Do NOT emit, quote, review, or validate any Kubernetes manifest, Helm template, or Kustomize overlay without first (a) verifying `apiVersion` and `kind` are not in the removed-API list of section D, and (b) scanning the manifest against the anti-patterns table of section D. This applies even under deadline pressure, even for "dev clusters", even when the user says "just make it work".
</HARD-GATE>

This gate exists because three failure modes recur on every k8s help request: (1) the user's source is a 2020 blog post, and a compliant agent regurgitates YAML that crashes on a v1.35+ cluster; (2) `image: myapp:latest` looks harmless but breaks rollbacks, provenance, and admission policies — the fix is a pinned digest; (3) `emptyDir` for stateful data looks convenient but vanishes on pod reschedule — the fix is a PVC. The gate forces these to the surface before any manifest is emitted.

## Snapshot

This skill owns the rules an agent applies when writing, editing, or reviewing Kubernetes manifests, Helm charts, and Kustomize overlays. It mandates stable-API discipline (v1.35+ baseline), modern workload patterns 2026 (native sidecars 1.29+, in-place pod resize 1.35+, user namespaces 1.36+, ValidatingAdmissionPolicy CEL 1.30+), a 25-plus-row anti-patterns table, Helm chart v4 and Kustomize conventions, safe-change flow (kubectl diff + server-side dry-run), and observability hints (Prometheus annotations, OTLP sidecar, structured logs). Live-cluster operations are explicitly out of scope and deferred to kubernetes-mcp-server or kubectl-ai.

**Announce at start:** `I'm using the kubernetes skill to <verb: write|edit|review|debug> this <manifest|chart|overlay>.`

## Quick Reference (projection — see Content sections for full rules)

| Field | Value |
|---|---|
| Audience | Agent or engineer writing/editing/reviewing k8s manifests, Helm charts, Kustomize overlays |
| Trigger | "write Deployment", "edit YAML k8s", "review Helm chart", "fix this manifest", "Kustomize overlay" |
| Inputs | YAML manifest or Helm/Kustomize artifact (existing or to-create); target cluster version hint |
| Outputs | Manifest with stable APIs, security context, resource requests/limits, observability hints |
| Type | sub-skill (see `_shared/SKILL-ARCH.md`) |
| Baseline | k8s v1.35+ (N-2 of v1.37 stable). Explicitly refuse or downgrade-flag for older targets. |
| Iron Law | NO K8S MANIFEST WITHOUT stable apiVersion AND non-removed kind |
| Scope out | Live cluster ops, cluster provisioning, CRD/operator authoring |
| Identity | Descriptive name (`kubernetes`); stable — do not rename |

## Related Skills

| Sibling | Relationship | What crosses the boundary |
|---|---|---|
| `using-superpowers` | `upstream` | Routes manifest-authoring triggers here. Translation: using-superpowers's "trigger match" = this skill's "k8s task announced". |
| `writing-skills` | `shared-kernel` | Co-maintains TDD-for-skills vocabulary. This skill applied RED→GREEN→REFACTOR during its own authoring. |
| `technical-writing` | `shared-kernel` | Co-maintains 4-slot discipline (Audience, Purpose/Scope, Definitions, Revision History). |
| `verification-before-completion` | `downstream` | After emitting a manifest, suggest `kubectl diff -f file.yaml` or `kubectl apply --dry-run=server` before claiming done. |
| `requesting-code-review` | `downstream` | Manifests/charts are artifacts for code review. |
| `_shared/glossary-en.md` | `shared-kernel` | TDD/RED/GREEN/Iron Law/Hard Gate terms live there. |
| kubernetes-mcp-server / kubectl-ai / k8sgpt | `none` | These are runtime tools/MCP servers, not skills. This skill explicitly defers live-cluster ops to them. No invocation. |

## Scope Out — Live Cluster Ops

This skill authors and reviews manifests. It does NOT execute `kubectl apply`, `kubectl delete`, `kubectl scale`, `helm install`, or any live mutation. For live ops, the user or orchestrator connects to `kubernetes-mcp-server` (containers/kubernetes-mcp-server) or invokes `kubectl-ai` directly. If the user asks this skill to "apply this to prod" or "delete that pod", the skill declines the operation and offers the manifest + the exact kubectl command for the user to run.

---
