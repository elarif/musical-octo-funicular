# Security Baseline — PSA, NetworkPolicy, RBAC

**Effective date:** 2026-08-29 — **Parent skill:** `kubernetes`. Security baseline every production workload should hit.

## Pod Security Admission (PSA)

Namespace labels enforce / audit / warn:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: myapp
  labels:
    pod-security.kubernetes.io/enforce: restricted   # strictest
    pod-security.kubernetes.io/audit:   restricted
    pod-security.kubernetes.io/warn:    restricted
```

Three profiles:
- `privileged` — anything goes. Only for infra namespaces (kube-system).
- `baseline` — prevents known privesc (hostNetwork, hostPID, privileged, hostPath).
- `restricted` — baseline + runAsNonRoot + seccomp + drop ALL caps + no priv escalation. **Target for applications.**

## Compliant workload securityContext

```yaml
securityContext:               # pod-level
  seccompProfile: { type: RuntimeDefault }
  runAsNonRoot: true
containers:
  - name: app
    securityContext:           # container-level
      runAsUser: 10001
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      capabilities: { drop: [ALL] }
```

Add userns for extra isolation (`spec.hostUsers: false`, k8s 1.36+).

## NetworkPolicy — default-deny + allowlist

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-myapp-ingress
spec:
  podSelector: { matchLabels: { app.kubernetes.io/name: myapp } }
  policyTypes: [Ingress]
  ingress:
    - from: [ { podSelector: { matchLabels: { app.kubernetes.io/name: frontend } } } ]
      ports: [ { port: 8080 } ]
```

Egress: allow DNS only (and whatever the app actually needs):

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-myapp-egress
spec:
  podSelector: { matchLabels: { app.kubernetes.io/name: myapp } }
  policyTypes: [Egress]
  egress:
    - to: [ { namespaceSelector: { matchLabels: { kubernetes.io/metadata.name: kube-system } } } ]
      ports: [ { port: 53, protocol: UDP }, { port: 53, protocol: TCP } ]
```

## RBAC scoping

- One ServiceAccount per workload (never share across deployments).
- Role in app namespace, not ClusterRole — unless truly cluster-scoped operations.
- Never ClusterRoleBinding to cluster-admin for a workload SA.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata: { name: myapp }
automountServiceAccountToken: false    # if SA doesn't need k8s API
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: { name: myapp-reader }
rules:
  - { apiGroups: [""], resources: [configmaps], verbs: [get, list] }
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: { name: myapp-reader }
subjects: [ { kind: ServiceAccount, name: myapp } ]
roleRef:  { apiGroup: rbac.authorization.k8s.io, kind: Role, name: myapp-reader }
```

## VAP (ValidatingAdmissionPolicy) — example

CEL-based, no webhook needed:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata: { name: disallow-latest-tag }
spec:
  matchConstraints:
    resourceRules:
      - { apiGroups: ["apps"], apiVersions: ["v1"], resources: ["deployments"], operations: [CREATE, UPDATE] }
  validations:
    - expression: "object.spec.template.spec.containers.all(c, !c.image.endsWith(':latest'))"
      message: "image must be pinned by digest, not :latest"
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata: { name: disallow-latest-tag-binding }
spec:
  policyName: disallow-latest-tag
  validationActions: [Deny, Audit]
```

## Modification

Modifications require flag in `kubernetes` SKILL.md Revision History.
