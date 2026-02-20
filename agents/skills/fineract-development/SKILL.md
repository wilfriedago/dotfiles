---
name: fineract-development
description: Apache Fineract core-banking platform development skill. Provides code generation scripts and architectural guidance for scaffolding Fineract modules following CQRS, business events, and vertical-slice conventions. Use when building new Fineract modules, entities, services, API resources, command handlers, scheduled jobs, business events, Liquibase migrations, or any Java/Spring code within the Fineract codebase. Triggers on Fineract module development, core banking entity creation, CQRS handler scaffolding, Fineract API resource creation, Liquibase migration generation, Spring Batch job creation, business event implementation, Fineract service layer scaffolding, repository wrapper generation, Fineract data/DTO classes.
---

# Fineract Development Skill

Scaffold Apache Fineract modules with correct CQRS patterns, vertical-slice packaging,
and Spring/JPA conventions. All generators produce Java files following Fineract's
standard sub-package layout: `api/`, `handler/`, `service/`, `domain/`, `data/`, `serialization/`, `exception/`.

## Architecture Quick Reference

Fineract uses **vertical module slices** with **command-query separation**:

- **Commands** (writes): API → CommandWrapper → CommandHandler → WritePlatformService → Entity → Repository
- **Queries** (reads): API → ReadPlatformService → JDBC/JPA → Data DTO
- **Events**: Domain operations raise `BusinessEvent` via `BusinessEventNotifierService`; events are transactional and Avro-serialized.
- **Multi-tenancy**: Each tenant has isolated DB schema; tenant ID in request header/path.

For detailed architecture, read `references/architecture.md`.
For coding conventions and pitfalls, read `references/best-practices.md`.

## Code Generators

All scripts live in `scripts/` and accept `--help`. Output goes to stdout or a specified `--output-dir`.

### Full Module Scaffold

Generate an entire module (entity + repo + services + handler + API + data + exceptions + Liquibase + event):

```bash
python3 scripts/generate_module.py \
  --module-name "savings-product" \
  --entity-name "SavingsProduct" \
  --package "org.apache.fineract.portfolio.savingsproduct" \
  --fields "name:String,description:String,nominalAnnualInterestRate:BigDecimal,minRequiredBalance:BigDecimal,active:boolean" \
  --output-dir ./output
```

### Individual Generators

| Generator                     | Script                               | Reference Doc                                 |
| ----------------------------- | ------------------------------------ | --------------------------------------------- |
| Entity + Repository           | `scripts/generate_entity.py`         | `references/entity-repository.md`             |
| Write Service + Handler       | `scripts/generate_write_service.py`  | `references/services.md`                      |
| Read Service                  | `scripts/generate_read_service.py`   | `references/services.md`                      |
| API Resource                  | `scripts/generate_api_resource.py`   | `references/api-resource.md`                  |
| Data / Serializer / Validator | `scripts/generate_data.py`           | `references/data-serialization-validation.md` |
| Exception Classes             | `scripts/generate_exceptions.py`     | `references/exceptions.md`                    |
| Liquibase Migration           | `scripts/generate_liquibase.py`      | `references/liquibase.md`                     |
| Scheduled Job                 | `scripts/generate_scheduled_job.py`  | `references/scheduled-jobs.md`                |
| Business Event                | `scripts/generate_business_event.py` | `references/business-events.md`               |

### Common Parameters

All generators accept:

- `--entity-name` / `--name`: PascalCase entity or component name (e.g. `SavingsProduct`)
- `--package`: Java package (e.g. `org.apache.fineract.portfolio.savingsproduct`)
- `--fields`: Comma-separated `name:Type` pairs for entity fields
- `--output-dir`: Directory for generated files (default: stdout)

### Workflow

1. Decide which module to build. Read `references/architecture.md` if unfamiliar with Fineract structure.
2. Run `generate_module.py` for a full scaffold, or run individual generators.
3. Review generated code, customize business logic, add validation rules.
4. Read the relevant reference doc for the component you're working on.
5. Wire into Fineract's build (add to `settings.gradle` if new Gradle module).

## Reference Documentation

Read these as needed — do NOT load all at once:

### Core Architecture & Patterns

- `references/architecture.md` — Fineract architecture overview, CQRS, events, multi-tenancy
- `references/cqrs-commands.md` — Command lifecycle, CommandWrapper, CommandWrapperBuilder, handler routing
- `references/end-to-end-flows.md` — Complete write/read path walkthroughs, transaction boundaries
- `references/best-practices.md` — Coding conventions, common pitfalls, review checklist

### Safety & Guardrails

- `references/accounting.md` — CRITICAL: Journal entries, chart of accounts, transaction processors
- `references/anti-patterns.md` — 13 critical anti-patterns with severity levels, pre-generation checklist
- `references/maker-checker.md` — Two-step approval workflow, permission config, idempotency

### Component Reference

- `references/entity-repository.md` — Entity/repo patterns, base classes, JPA mappings
- `references/services.md` — Write services, read services, command handlers, transactions
- `references/api-resource.md` — JAX-RS resources, OpenAPI annotations, command routing
- `references/data-serialization-validation.md` — DTOs, JSON binding, FromJsonHelper, validation
- `references/exceptions.md` — Exception hierarchy, error responses
- `references/liquibase.md` — Database migrations, changelog conventions
- `references/scheduled-jobs.md` — Cron jobs, Spring Batch, @CronTarget
- `references/business-events.md` — Business event framework, Avro serialization

### Platform Concerns

- `references/multi-tenancy.md` — Tenant isolation, security context, office hierarchy
- `references/testing.md` — Integration tests, API helpers, test patterns, coverage

### Project-Specific

- `references/custom-modules.md` — Custom module/extension pattern, @AutoConfiguration, service overriding
- `references/keycloak-sync.md` — Keycloak user/role/permission sync module architecture
- `references/security-filters.md` — Security filter chain, OAuth2/Keycloak auth, instance modes
