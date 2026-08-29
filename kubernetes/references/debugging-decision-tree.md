# Manifest-Level Debugging Decision Tree

**Effective date:** 2026-08-29 — **Parent skill:** `kubernetes`. Manifest-side hints. For live-cluster diagnosis defer to kubernetes-mcp-server or kubectl-ai.

## Symptom → likely manifest cause

### Pod stays Pending

Check order:
1. `kubectl describe pod` → events.
2. Insufficient CPU/memory → reduce `resources.requests` or scale node pool.
3. PVC not bound → check StorageClass + capacity.
4. Node selector / affinity mismatch → check node labels.
5. Taints on all nodes → tolerations missing.
6. Quota exceeded on namespace → `kubectl describe resourcequota`.

**Manifest fix hint:** too-large requests is the most common LLM-emitted bug. Default to small requests + HPA.

### Pod CrashLoopBackOff

1. `kubectl logs <pod> --previous` — last crash output.
2. Readiness probe path wrong / app listen on different port.
3. Missing ConfigMap / Secret env var (check `envFrom:` references).
4. Container runs as root but image doesn't allow it (`runAsNonRoot: true` mismatch).
5. Exit code 137 = OOM — raise `limits.memory` or fix leak.

**Manifest fix hint:** 90% of CrashLoops are env-var / probe / OOM. Verify probes with actual app path, use `readinessProbe` to gate traffic while app warms.

### Pod ImagePullBackOff

1. Image tag doesn't exist in registry.
2. Missing `imagePullSecrets` on private registry.
3. Digest pinned but registry rotated it.

**Manifest fix hint:** always verify digest exists — `crane digest <image>` or `docker manifest inspect <image>` before commit.

### OOMKilled (exit 137)

1. `limits.memory` too low.
2. Actual leak (look at `container_memory_working_set_bytes` history).

**Manifest fix hint:** raise limits, add VPA recommendation, consider in-place resize (1.35+) once stable.

### RBAC `forbidden` errors on apply

1. SA missing Role/ClusterRole binding.
2. Cluster-scoped resource applied to namespace-scoped SA.

**Manifest fix hint:** ship ServiceAccount + minimal Role + RoleBinding alongside the workload. NEVER ClusterRoleBinding to cluster-admin.

### Service unreachable

1. Selector mismatch — `kubectl get endpoints <svc>` shows no addresses.
2. containerPort wrong.
3. NetworkPolicy blocking.

**Manifest fix hint:** verify Service selector matches pod labels in Deployment template.

### Crash on admission: "violated PodSecurity"

1. Namespace has `pod-security.kubernetes.io/enforce: restricted`.
2. Manifest missing seccomp / runAsNonRoot / drop caps.

**Manifest fix hint:** emit the full restricted-profile securityContext (see SKILL.md section B example).

## Modification

Modifications require flag in `kubernetes` SKILL.md Revision History.
