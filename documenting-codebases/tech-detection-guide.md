# Tech Stack Detection Guide

Detect the language, build tool, framework, and module structure of a codebase
by scanning root-level files and directory structure.

## Detection Table

### Java

| Root file | Build tool | Module structure | Entry points | Framework hints |
|---|---|---|---|---|
| `pom.xml` | Maven | `<modules>` in parent pom → multi-module; else single | `public static void main`, `Verticle` class, `@SpringBootApplication` | Spring Boot (spring-boot-starter), Vert.x (vertx-core), Quarkus (quarkus-universe-bom) |
| `build.gradle` or `build.gradle.kts` | Gradle | `subprojects {}` or `include ':'` in settings.gradle | Same as Maven | Same as Maven |
| `settings.xml` | Maven (with nexus) | As above | As above | As above |

**Scanning order:**
1. Root `pom.xml` → check `<modules>` for multi-module
2. Each module's `pom.xml` → extract `<artifactId>`, `<dependencies>` (framework detection)
3. `src/main/java/**/*.java` → package structure = module decomposition
4. `src/main/resources/` → config files (application.yml, logback.xml, etc.)
5. `src/test/java/` → test names reveal behavior and business flows

### JavaScript / TypeScript

| Root file | Build tool | Module structure | Entry points | Framework hints |
|---|---|---|---|---|
| `package.json` | npm / yarn / pnpm | `workspaces` field → monorepo; else single | `main` / `module` / `bin` fields, `src/index.ts`, `src/server.ts` | Express (express), NestJS (@nestjs), Fastify (fastify), Next.js (next), React (react) |
| `tsconfig.json` | TypeScript compiler | `references` → project references (multi-project) | Same as JS | Same as JS |
| `turbo.json` | Turborepo | `packages/*` in turbo.json | Per-package package.json | Same as JS |

**Scanning order:**
1. `package.json` → `dependencies` + `devDependencies` (framework detection), `scripts` (entry points)
2. `tsconfig.json` → `paths` (module aliases), `references` (multi-project)
3. `src/` directory → file structure = module decomposition
4. Route definitions: `app.get/post`, `@Controller`, `router.get` → business flows
5. `*.test.ts` / `*.spec.ts` → test names reveal behavior

### Python

| Root file | Build tool | Module structure | Entry points | Framework hints |
|---|---|---|---|---|
| `pyproject.toml` | Poetry / pip / hatch | `[tool.poetry.packages]` or src layout | `__main__.py`, `app.py`, `manage.py`, `[tool.poetry.scripts]` | FastAPI (fastapi), Django (django), Flask (flask), Celery (celery) |
| `setup.py` / `setup.cfg` | setuptools | `packages` field | Same as above | Same as above |
| `requirements.txt` | pip | Flat or src layout | Same as above | Same as above |

**Scanning order:**
1. `pyproject.toml` → `[tool.poetry.dependencies]` or `[project.dependencies]`
2. `src/` or flat layout → package structure
3. Route definitions: `@app.route`, `@router.get`, `APIRouter` → business flows
4. `tests/` → test names reveal behavior

### Go

| Root file | Build tool | Module structure | Entry points | Framework hints |
|---|---|---|---|---|
| `go.mod` | go modules | `cmd/` directory (multi-binary), `internal/` (private packages), `pkg/` (public packages) | `main()` in `cmd/*/main.go` | Gin (github.com/gin-gonic/gin), Echo (labstack/echo), Chi (chi-router), stdlib net/http |

**Scanning order:**
1. `go.mod` → `require` block (dependencies = framework detection)
2. `cmd/` → one binary per subdirectory
3. `internal/` → private packages, business logic
4. Route registration: `router.GET`, `e.GET`, `r.Get` → business flows
5. `*_test.go` → test names reveal behavior

### Rust

| Root file | Build tool | Module structure | Entry points | Framework hints |
|---|---|---|---|---|
| `Cargo.toml` | cargo | `[[bin]]` sections (multi-binary), `src/lib.rs` (library), `src/main.rs` (binary) | `fn main()` in `src/main.rs` or `[[bin]]` targets | Actix (actix-web), Axum (axum), Rocket (rocket), Warp (warp) |

**Scanning order:**
1. `Cargo.toml` → `[dependencies]` (framework detection), `[[bin]]` (entry points)
2. `src/` → module structure (mod.rs or mod declarations)
3. Route definitions: `#[get("/")]`, `Router::new().route` → business flows
4. `tests/` → integration tests reveal behavior

### Multi-language / Polyglot

If multiple root files exist (e.g., `pom.xml` + `package.json` + `go.mod`):
1. Detect ALL tech stacks (the codebase has multiple sub-systems)
2. Document each sub-system as a separate Container in C4
3. Scan each sub-system independently for components and flows
4. Cross-references between sub-systems become `Rel` in C4

## Framework-Specific Scanning

### Spring Boot (Java)
- `@RestController`, `@RequestMapping` → API endpoints (business flows)
- `@Service`, `@Repository` → component decomposition
- `application.yml` / `application.properties` → external systems (DB, broker, APIs)
- `@Entity` → data model (ContainerDb in C4)
- `@Scheduled` → background jobs (BPMN start events)

### Vert.x (Java)
- `Verticle` classes → deployable units (Container in C4)
- `Router.router()` → route definitions (business flows)
- `WebClient` → external HTTP calls (System_Ext in C4)
- `route().handler()` → filter chain (Component in C4)
- `executeBlocking()` → async operations

### Express / Fastify (JS/TS)
- `app.get/post/put/delete` → API endpoints (business flows)
- `require()` / `import` from `models/`, `services/` → component decomposition
- `process.env` → external systems (DB, broker, APIs)
- `mongoose.model` / `prisma` → data model (ContainerDb in C4)

### NestJS (JS/TS)
- `@Controller` → API endpoints (business flows)
- `@Injectable` services → component decomposition
- `@Module` → module boundaries (Container or Component in C4)
- `@EventPattern` / `@Cron` → event/scheduled flows (BPMN start events)

### FastAPI (Python)
- `@app.get/post` → API endpoints (business flows)
- `@router.include` → module boundaries
- Pydantic models → data model
- Celery tasks → background flows (BPMN start events)

### Django (Python)
- `urls.py` → URL routing (business flows)
- `views.py` → request handlers
- `models.py` → data model (ContainerDb in C4)
- `tasks.py` (Celery) → background flows

## External Systems Detection

Scan for these patterns to identify external systems (System_Ext in C4):

| Pattern | External system |
|---|---|
| JDBC URLs (`jdbc:postgresql://`, `jdbc:mysql://`) | Database (ContainerDb) |
| Connection strings (`mongodb://`, `redis://`, `amqp://`) | Data store / message broker |
| `@Value` / `process.env` / `os.environ` with URL keys | External API |
| HTTP client calls (`WebClient`, `axios`, `requests`, `http.Get`) | External API (System_Ext) |
| Docker Compose services (`docker-compose.yml`) | Infrastructure dependencies |
| Helm chart dependencies (`Chart.yaml`) | Infrastructure (K8s deployments) |
| Cloud SDK imports (`aws-sdk`, `google-cloud`, `azure`) | Cloud services (System_Ext) |
| SMTP config (`spring.mail`, `nodemailer`) | Email service (System_Ext) |

## Output

After detection, summarize findings as:
```
Tech Stack:
  Language: Java 25
  Build: Maven (multi-module: core, tenant, identity, oauth, authz, api)
  Framework: Vert.x 5
  Modules: 6
  Entry point: com.mysaas.api.MainVerticle
  External systems: PostgreSQL, Ory Kratos, Ory Hydra, Ory Keto, Mailhog
  Key business flows: registration, auth (session+token), tenant provisioning
```