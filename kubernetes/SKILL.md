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

## A. API Discipline

**Baseline version:** k8s v1.35 minimum (N-2 of v1.37 stable, Aug 2026). Always check target cluster's `kubectl version` or `kubectl api-versions` before emitting manifests.

**Removed since 2020 (DO NOT USE, even for "legacy"):**

| API / feature | Removed in | Replacement |
|---|---|---|
| `policy/v1beta1 PodSecurityPolicy` | v1.25 | Pod Security Admission (namespace labels) |
| `extensions/v1beta1` Ingress | v1.22 | `networking.k8s.io/v1` Ingress OR Gateway API |
| `apps/v1beta1` Deployment / StatefulSet | v1.16 | `apps/v1` |
| dockershim CRI runtime | v1.24 | containerd / CRI-O |
| In-tree AWS/GCE/Azure cloud providers | v1.29 | Cloud Controller Manager (out-of-tree) |
| In-tree EBS/GCE-PD/AzureDisk storage | v1.24-1.27 | CSI drivers |
| Legacy ServiceAccount token auto-secret | v1.24 | `TokenRequest` API |
| `Endpoints` (legacy) | deprecated v1.33 | `EndpointSlice` (discovery.k8s.io/v1) |
| `Service.spec.externalIPs` | v1.36 | LoadBalancer type + CNI-specific externalIP policy, or Gateway API |

**Stable `v1` core kinds (safe):** Pod, Service, ConfigMap, Secret, Namespace, ServiceAccount, PersistentVolume, PersistentVolumeClaim.

**Stables apps/v1:** Deployment, StatefulSet, DaemonSet, ReplicaSet.

**Stables batch/v1:** Job, CronJob (since 1.21).

**Stable networking.k8s.io/v1:** Ingress (still, but frozen — no new features since Ingress-nginx retirement), NetworkPolicy.

**Preferred newer (GA):** `gateway.networking.k8s.io/v1` Gateway + HTTPRoute (v1.6 spec — replaces Ingress), `policy/v1` PodDisruptionBudget, `autoscaling/v2` HorizontalPodAutoscaler, `admissionregistration.k8s.io/v1` ValidatingAdmissionPolicy (CEL-based, GA 1.30).

**Rule:** when in doubt, `kubectl api-resources --verbs=list | grep <kind>` to confirm the resource is served on the target cluster before writing the YAML.

## B. Workload Authoring

**Deployment (stateless)** — modern shape:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: myapp
  labels:
    app.kubernetes.io/name: myapp
    app.kubernetes.io/version: "1.4.2"
spec:
  replicas: 3
  revisionHistoryLimit: 3
  strategy:
    type: RollingUpdate
    rollingUpdate: { maxSurge: 1, maxUnavailable: 0 }
  selector:
    matchLabels: { app.kubernetes.io/name: myapp }
  template:
    metadata:
      labels:
        app.kubernetes.io/name: myapp
        app.kubernetes.io/version: "1.4.2"
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
    spec:
      securityContext:
        seccompProfile: { type: RuntimeDefault }
      containers:
        - name: app
          image: registry.example.com/myapp@sha256:PINNED_DIGEST_HERE
          imagePullPolicy: IfNotPresent
          ports:
            - { name: http, containerPort: 8080 }
          resources:
            requests: { cpu: 100m, memory: 128Mi }
            limits:   { cpu: 500m, memory: 256Mi }
          securityContext:
            runAsNonRoot: true
            runAsUser: 10001
            readOnlyRootFilesystem: true
            allowPrivilegeEscalation: false
            capabilities: { drop: [ALL] }
          livenessProbe:
            httpGet: { path: /healthz, port: http }
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe:
            httpGet: { path: /ready, port: http }
            periodSeconds: 5
          volumeMounts:
            - { name: tmp, mountPath: /tmp }
      volumes:
        - { name: tmp, emptyDir: {} }    # OK for tmp; NEVER for stateful data
```

**Why each field:**
- Pinned `@sha256:` digest — never `:latest`. Rollback-able, traceable, admission-policy-friendly.
- `revisionHistoryLimit: 3` — keeps rollout history bounded.
- `maxUnavailable: 0` — never drop available capacity mid-rollout.
- `seccompProfile: RuntimeDefault` — default seccomp filter, GA since v1.27.
- `securityContext` block — pod security admission `restricted` profile compliance.
- `readOnlyRootFilesystem: true` + `emptyDir` mounted at `/tmp` — app keeps a writable scratch space without weakening root FS.
- liveness ≠ readiness — different endpoints. Same endpoint for both = silent retry loops.

**Stateful (databases, queues):** use `StatefulSet` + `volumeClaimTemplates`. NEVER `emptyDir` for data dirs (anti-pattern row 5).

**Native sidecars (1.29+ GA):** no more sidecar-as-second-container hacks. Native pattern:

```yaml
spec:
  initContainers:
    - name: istio-proxy                # or logshipper, otel-collector, vault-agent
      image: istio/proxyv2:1.26.0
      restartPolicy: Always            # <-- this makes it a native sidecar
  containers:
    - name: app
      image: ...
```

Sidecar starts before app containers, terminates after. Kubelet tracks lifecycle independently.

**In-place pod resize (1.35+ GA):** when `PodResizePolicy` allows, mutating `resources.requests/limits` on a running pod does NOT restart it. Set:

```yaml
spec:
  containers:
    - name: app
      resizePolicy:
        - { resourceName: cpu,    restartPolicy: NotRequired }
        - { resourceName: memory, restartPolicy: RestartContainer }   # memory shrink restart is safer
```

**User namespaces (1.36+ GA):** `spec.hostUsers: false` runs the pod with a host-user-namespace mapping so UID 0 inside container ≠ UID 0 on host. Massive security win. Pair with `runAsUser: 0` inside the container for workloads that need "root" but shouldn't escape.

**Jobs / CronJobs:** `batch/v1` only. Set `ttlSecondsAfterFinished` on Jobs to avoid finished-pod accumulation.

## Scope Out — Live Cluster Ops

This skill authors and reviews manifests. It does NOT execute `kubectl apply`, `kubectl delete`, `kubectl scale`, `helm install`, or any live mutation. For live ops, the user or orchestrator connects to `kubernetes-mcp-server` (containers/kubernetes-mcp-server) or invokes `kubectl-ai` directly. If the user asks this skill to "apply this to prod" or "delete that pod", the skill declines the operation and offers the manifest + the exact kubectl command for the user to run.

---
