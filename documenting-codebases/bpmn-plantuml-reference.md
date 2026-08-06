# BPMN Process Diagrams with PlantUML Activity

PlantUML does not have native BPMN 2.0 support, but its **activity diagram (beta syntax)**
maps well to BPMN constructs and is text-based, diffable, and git-friendly.

## BPMN → PlantUML Activity Mapping

| BPMN Element | PlantUML Activity Syntax | Notes |
|---|---|---|
| Start event | `start` | Single entry point per process |
| End event | `stop` | Can have multiple end events |
| Task | `:Task name;` | Colon prefix, semicolon suffix |
| Sub-process | `:Label;` then `note right: see sub-process diagram` | Reference separate diagram |
| Exclusive gateway (XOR) | `if (condition) then (yes)\n :task;\n else (no)\n :task;\n endif` | Branch on condition |
| Parallel gateway (AND) | `fork\n :task A;\n fork again\n :task B;\n end fork` | Concurrent execution |
| Inclusive gateway (OR) | Multiple `if` blocks, each independent | No native OR; use multiple ifs |
| Swimlane (pool/lane) | `partition "Lane Name" {\n ...\n }` | Groups tasks by role/system |
| Error boundary event | `if (condition?) then (yes)\n :handle error;\n stop\n endif` | Error as conditional branch |
| Message flow | `note right: HTTP call to Kratos` | Annotate cross-system calls |
| Timer event | `:Wait for schedule;` | Cron or scheduled trigger |
| Loop activity | `while (condition?) is (yes)\n :task;\nendwhile (no)` | Loop with condition |

## Basic Syntax

### Start and Stop

```plantuml
@startuml
start
:Process request;
stop
@enduml
```

### Tasks

```plantuml
@startuml
start
:Receive HTTP request;
:Validate input;
:Process business logic;
:Send response;
stop
@enduml
```

### Conditional (Exclusive Gateway)

```plantuml
@startuml
start
:Receive request;
if (Valid token?) then (yes)
  :Process authenticated request;
else (no)
  :Return 401 Unauthorized;
  stop
endif
:Return 200 OK;
stop
@enduml
```

### Parallel (Parallel Gateway)

```plantuml
@startuml
start
:Receive registration webhook;
fork
  :Create tenant schema;
fork again
  :Provision default tenant;
end fork
:Return success;
stop
@enduml
```

### Swimlanes (partition)

```plantuml
@startuml
start
partition "API Server" {
  :Receive HTTP request;
  :Extract Bearer token;
}
partition "Hydra" {
  :Validate JWT via JWKS;
  if (Valid?) then (yes)
    :Return claims;
  else (no)
    :Try introspection;
  endif
}
partition "API Server" {
  :Inject TokenPrincipal;
  :Handle request;
  :Return response;
}
stop
@enduml
```

### Loop

```plantuml
@startuml
start
:Initialize retry counter;
while (Retries < 3?) is (yes)
  :Call external service;
  if (Success?) then (yes)
    stop
  else (no)
    :Increment retry counter;
    :Wait 1s;
  endif
endwhile (no)
:Return 503 Service Unavailable;
stop
@enduml
```

## Complete Example: User Registration Flow

```plantuml
@startuml bpmn-user-registration
title Business Process: User Registration

start
partition "User" {
  :Submit registration form (email + password);
}

partition "Kratos" {
  :Create identity;
  :Send verification email;
  :Trigger after-registration webhook;
}

partition "API Server (Webhook Handler)" {
  :Receive webhook payload (identity + traits);
  if (tenant_id trait present?) then (yes)
    if (Tenant already exists?) then (yes)
      :Return 204 (nothing to do);
      stop
    else (no)
      :Create tenant in registry;
      :Create tenant schema via Liquibase;
      :Return 200 (tenant provisioned);
      stop
    endif
  else (no)
    :Extract domain from email;
    :Derive default tenant slug;
    :Create tenant + schema;
    :Return 200 (default tenant provisioned);
    stop
  endif
}
@enduml
```

## Complete Example: Authenticated API Request Flow

```plantuml
@startuml bpmn-authenticated-request
title Business Process: Authenticated API Request

start
partition "Client" {
  :Send HTTP request with headers;
  note right
    X-Tenant: acme
    Cookie: ory_kratos_session=...
    Authorization: Bearer <jwt>
  end note
}

partition "TenantFilter (order -100)" {
  :Extract X-Tenant header;
  if (Tenant exists in registry?) then (yes)
    :Inject TenantContext;
  else (no)
    :Return 404 Tenant not found;
    stop
  endif
}

partition "KratosSessionFilter (order -90)" {
  if (Cookie present?) then (yes)
    :Call Kratos /sessions/whoami;
    if (Session valid?) then (yes)
      :Inject Identity;
    else (no)
      :Return 401 Unauthorized;
      stop
    endif
  else (no)
    :Return 401 Unauthorized;
    stop
  endif
}

partition "HydraTokenFilter (order -80)" {
  if (Authorization Bearer present?) then (yes)
    :Validate JWT via JWKS;
    if (JWT valid?) then (yes)
      :Inject TokenPrincipal;
    else (no)
      :Try introspection fallback;
      if (Token active?) then (yes)
        :Inject TokenPrincipal;
      else (no)
        :Return 401 Unauthorized;
        stop
      endif
    endif
  else (no)
    :Return 401 Unauthorized;
    stop
  endif
}

partition "KetoAuthzFilter (order -70)" {
  :Resolve subject from Identity or TokenPrincipal;
  :Check Tenant:<slug>#access@<subject> via Keto;
  if (Allowed?) then (yes)
    :Continue to handler;
  else (no)
    :Return 403 Forbidden;
    stop
  endif
}

partition "Business Handler" {
  :Process request;
  :Return 200 OK with data;
}
stop
@enduml
```

## Complete Example: Tenant Provisioning Flow

```plantuml
@startuml bpmn-tenant-provisioning
title Business Process: Tenant Provisioning

start
:Admin submits tenant creation request (slug, name);
partition "TenantAdminHandler" {
  :Validate slug format;
  if (Slug already exists?) then (yes)
    :Return 409 Conflict;
    stop
  else (no)
    :Insert tenant row in public.tenants;
    :Create schema tenant_<slug>;
    :Run Liquibase migrations on new schema;
    :Return 201 Created;
  endif
}
stop
@enduml
```

## Tips

- Use `partition` for swimlanes — maps to BPMN pools/lanes
- Use `note right` or `note left` to annotate HTTP calls, payloads, or error codes
- One `.puml` file per business process (e.g., `bpmn-registration.puml`, `bpmn-auth-flow.puml`)
- Keep diagrams readable: max 20-30 elements per diagram. Split into sub-processes if larger
- Use `if/else` for business decisions (XOR gateways) — the most common BPMN pattern
- Use `fork/end fork` sparingly — only when true parallelism exists in the process
- End every path with `stop` (BPMN end event) — avoid implicit termination
- Label tasks with action verbs: "Validate token", "Create schema", "Send response"