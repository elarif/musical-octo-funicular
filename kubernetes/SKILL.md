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

## C. Resources and Limits

**Always set `resources.requests`** — kube scheduler uses them for bin-packing, VPA uses them for recommendations, HPA scaling math depends on them.

**Always set `resources.limits`** — protects neighbors from runaway pods; enables Guaranteed QoS when requests == limits.

**QoS tiers:**
- `Guaranteed` — requests == limits on all containers. Survives node-pressure eviction last. Use for: critical infra, low-latency.
- `Burstable` — requests < limits. Default for typical apps.
- `BestEffort` — no requests/limits. Evicted first. Avoid in production.

**CPU limits nuance (cgroup v2, default since k8s 1.25):** CPU limits can **throttle latency-sensitive services** even when CPU is idle. Modern consensus (Tim Hockin, k8s maintainers, 2024+):
- **Set `requests.cpu`** (drives scheduling).
- **Skip `limits.cpu`** for latency-sensitive services; set it for batch jobs. If you must set, monitor `container_cpu_cfs_throttled_seconds_total`.
- Memory limits are different: exceeding memory = OOM-kill, so always set `limits.memory`.

**HPA (autoscaling/v2 stable):**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: { name: myapp }
spec:
  scaleTargetRef: { apiVersion: apps/v1, kind: Deployment, name: myapp }
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource: { name: cpu, target: { type: Utilization, averageUtilization: 70 } }
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300       # don't flap
```

Use `behavior` to control scale-down rate. Default is often too aggressive.

**VPA** (Vertical Pod Autoscaler): installs alongside, recommends right-size. In-place pod resize (1.35+) removes the historic "VPA must restart pod" pain. Use VPA in `updateMode: "Auto"` for long-running steady-state workloads.

## D. Anti-Patterns Table

Never emit, recommend, or leave unflagged any pattern on the left column. When encountered in existing YAML, refactor to right column or flag `🚫` + the fix reference.

| ❌ Forbidden | ✅ Fix | Why |
|---|---|---|
| `kind: PodSecurityPolicy` | Namespace PSA labels: `pod-security.kubernetes.io/enforce: restricted` | PSP removed v1.25. |
| `apiVersion: extensions/v1beta1` (anything) | `apps/v1`, `networking.k8s.io/v1`, etc. | Removed in v1.16-1.22. |
| `image: app:latest` | `image: app@sha256:<digest>` | Untraceable, breaks rollback, blocks admission policy. |
| `image: app:v1.0` (mutable tag) | `image: app@sha256:<digest>` | Tags mutable; digest immutable. |
| `emptyDir` for database / uploads / stateful data | `volumeClaimTemplates` on StatefulSet, or `persistentVolumeClaim` on pod | emptyDir dies with pod. |
| `hostPath` volume | PVC-backed local PV or CSI driver | Escapes container, host-coupled. |
| `hostNetwork: true` | ClusterIP Service + explicit NetworkPolicy | Bypasses CNI policy layer. |
| `hostPID: true` / `hostIPC: true` | Remove; or scoped exception only with documented justification | Bypass isolation. |
| `securityContext.privileged: true` | Add specific `capabilities.add: [NET_ADMIN]` etc. if truly needed, else omit | privileged = full host root. |
| `capabilities.add: [NET_ADMIN]` on routine pods | `capabilities.drop: [ALL]` (default restricted) | NET_ADMIN allows iptables mutations. |
| No `securityContext` on pod or container | seccompProfile RuntimeDefault + runAsNonRoot + RO root FS + drop ALL caps | PSA `restricted` baseline. |
| `kind: Endpoints` | `kind: EndpointSlice` (discovery.k8s.io/v1) | Endpoints deprecated v1.33; slices scale better. |
| `Service.spec.externalIPs` | LoadBalancer Service or Gateway API `Gateway`+`HTTPRoute` | Removed v1.36 — security risk (IP spoofing). |
| `kind: Ingress` with `kubernetes.io/ingress.class` annotation | `spec.ingressClassName` field; or migrate to Gateway API | Annotation deprecated; Ingress frozen post-Ingress-nginx retirement. |
| No NetworkPolicy at all in a namespace | Default-deny ingress + egress NetPol, then allowlist | Zero-trust baseline; without it any pod can reach any pod. |
| ClusterRoleBinding to `cluster-admin` for a service account | Scoped `Role` in app namespace | Massive privilege escalation on SA compromise. |
| `imagePullPolicy: Always` on `:latest`-tagged images (default) | Pinned digest + `IfNotPresent` | Always-pull wastes bandwidth, can surprise. |
| No `livenessProbe` | Define it, distinct from readiness | Silent hung processes never restart. |
| liveness == readiness endpoint | Distinct endpoints (liveness = process alive; readiness = can serve traffic) | Same endpoint = cascading failures during GC pause etc. |
| No `readinessProbe` | Define it | Pods take traffic before ready. |
| `runAsUser: 0` without userns | `runAsUser: 10001` + `runAsNonRoot: true`; OR `hostUsers: false` + userns (1.36+) | Root-in-container = root-adjacent-on-host. |
| `kubectl apply -f .` (whole directory untargeted) | Targeted `kubectl apply -f specific.yaml` + `kubectl diff` first | Broad applies destroy unknown state. |
| Hardcoded secrets in YAML (`password: abc123`) | External Secrets Operator, SOPS-encrypted file, sealed-secrets | Repo leaks = prod leaks. |
| `terminationGracePeriodSeconds: 0` | Omit (default 30s) or tune purposefully | Instant SIGKILL = request drops, no cleanup. |
| No `terminationMessagePolicy` customization when logging matters | `terminationMessagePolicy: FallbackToLogsOnError` | Easier debugging on CrashLoop. |
| No `podDisruptionBudget` on critical deployments | `policy/v1 PodDisruptionBudget` `minAvailable: 1` | Voluntary disruptions (drain, upgrades) can take all replicas. |
| `securityContext: {}` empty block (looks intentional, does nothing) | Full restricted profile | Empty block = silent no-op; PSA audit flags it. |
| Deprecated annotation `kubectl.kubernetes.io/last-applied-configuration` sprawl | `kubectl apply --server-side` (field managers, not annotation) | Server-side apply GA since 1.22, removes annotation bloat. |

## Scope Out — Live Cluster Ops

This skill authors and reviews manifests. It does NOT execute `kubectl apply`, `kubectl delete`, `kubectl scale`, `helm install`, or any live mutation. For live ops, the user or orchestrator connects to `kubernetes-mcp-server` (containers/kubernetes-mcp-server) or invokes `kubectl-ai` directly. If the user asks this skill to "apply this to prod" or "delete that pod", the skill declines the operation and offers the manifest + the exact kubectl command for the user to run.

---
