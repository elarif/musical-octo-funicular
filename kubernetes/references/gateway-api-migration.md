# Ingress → Gateway API Migration

**Effective date:** 2026-08-29 — **Parent skill:** `kubernetes`. Ingress-nginx project retired Nov 2025; Ingress API frozen; Gateway API v1.6 spec is the current standard.

## Why migrate

- Ingress: single resource mixing infra (LB) and app (routing) concerns. Controller-specific annotations sprawl (`nginx.ingress.kubernetes.io/*`).
- Gateway API: explicit role split — Gateway (infra) + HTTPRoute (app) + ReferenceGrant (cross-namespace).

## Pattern

**Ingress (frozen, legacy):**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: app.example.com
      http:
        paths:
          - { path: /, pathType: Prefix, backend: { service: { name: myapp, port: { number: 80 } } } }
```

**Gateway API equivalent:**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: public
  namespace: infra
spec:
  gatewayClassName: cilium            # or istio, envoy-gateway, kong
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      tls:
        certificateRefs: [ { name: public-tls } ]
      allowedRoutes:
        namespaces:
          from: Selector
          selector:
            matchLabels: { gateway-access: "true" }
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: myapp
  namespace: myapp
spec:
  parentRefs: [ { name: public, namespace: infra } ]
  hostnames: [ "app.example.com" ]
  rules:
    - matches: [ { path: { type: PathPrefix, value: / } } ]
      backendRefs: [ { name: myapp, port: 80 } ]
```

## Migration tooling

`ingress2gateway` (GA v1.0) — reads Ingress YAML, emits Gateway API equivalents:

```bash
ingress2gateway print --input-file ingress.yaml > gateway-api.yaml
```

Then hand-tune: annotations have no direct equivalent, map to HTTPRoute filters or Gateway listeners.

## Anti-patterns

| ❌ | ✅ |
|---|---|
| New Ingress resources in 2026 | HTTPRoute from day one |
| Annotation `nginx.ingress.kubernetes.io/*` on GW API resources | Read GW API spec for equivalents (most exist as fields) |
| Wildcard `*` hostname on Gateway without TLS | Specific hostnames + cert |
| Cross-namespace backendRef without ReferenceGrant | ReferenceGrant explicitly allowing it |

## Implementations 2026

- **Cilium** Gateway API — eBPF-native.
- **Istio** — Gateway API preferred over Istio Gateway CRD for new installs.
- **Envoy Gateway** — standalone GW-API impl, GA.
- **Kong**, **Traefik**, **NGINX Gateway Fabric** (successor of retired ingress-nginx).

## Modification

Modifications require flag in `kubernetes` SKILL.md Revision History.
