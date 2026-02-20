# Architecture & Module Topology

## Purpose

This skill teaches an AI agent how Apache Fineract is architecturally structured, how modules are organized, what dependency rules govern inter-module communication, and how to reason about where new code belongs.

## Platform Overview

Apache Fineract is an open-source core banking platform providing:

- Multi-tenant, stateless RESTful JSON APIs
- Modular architecture with vertical slices per domain
- CQRS-inspired command/query separation with full audit trails
- Maker-checker (two-step approval) workflows
- Transactional business event framework
- Accounting ledger integration

**Tech Stack:** Java 21+, Spring Boot, Spring Data JPA (Hibernate), Spring Batch, JAX-RS (Jersey), MySQL/PostgreSQL, Liquibase, Gradle.

## Multi-Tenancy

Each financial institution (tenant) is isolated in a separate database schema.
The tenant identifier is passed via HTTP header (`Fineract-Platform-TenantId`)
or URL path parameter. A `TenantServerConnection` entity maps tenant IDs to
database connection details.

Key classes:

- `FineractPlatformTenant` — tenant metadata
- `TenantAwareRoutingDataSource` — routes DB calls to tenant schema
- `ThreadLocalContextUtil` — stores current tenant context per request

## Command-Query Separation

### Write Path (Commands)

```
HTTP POST/PUT/DELETE
  → ApiResource builds CommandWrapper via CommandWrapperBuilder
  → commandsSourceWritePlatformService.logCommandSource(commandRequest)
  → CommandSourceHandler.processCommand(JsonCommand)
  → XxxWritePlatformService method
  → Domain entity mutation + repository.save()
  → Business event raised
  → Audit log persisted (m_portfolio_command_source table)
```

CommandWrapper encapsulates: action, entity, entityId, JSON body.
The platform logs every command for audit before execution.

### Read Path (Queries)

```
HTTP GET
  → ApiResource calls XxxReadPlatformService
  → JDBC query / JPA query
  → Maps to XxxData DTO
  → Returns JSON response
```

Read services typically use `JdbcTemplate` with `RowMapper` for performance,
rather than loading full JPA entities. This avoids N+1 queries and unnecessary
entity hydration.

### Maker-Checker

Commands can be flagged for maker-checker approval. When enabled:

1. Maker submits command → stored as pending in `m_portfolio_command_source`
2. Checker approves → command executes
3. If rejected → command discarded

Configured per action via `m_permission` table.

## Business Event Framework

Fineract's transactional event system:

```java
// Raising an event during a domain operation
businessEventNotifierService.notifyPostBusinessEvent(
    new LoanApprovedBusinessEvent(loan));
```

Key contracts:

- `BusinessEvent<T>` — event interface carrying payload
- `BusinessEventNotifierService` — publish events within transaction
- Events stored in DB with Avro serialization for durability
- Transaction rollback on handler failure ensures consistency
- External systems can consume events via external event table

Event categories: Loan lifecycle (approved, disbursed, repayment, etc.),
Savings (deposit, withdrawal, interest posting), Client, Share, etc.

## Request Lifecycle

```
┌─────────┐    ┌──────────┐    ┌─────────────┐    ┌────────────┐
│  Client │───▶│ API      │───▶│ Command     │───▶│ Write      │
│  (HTTP) │    │ Resource │    │ Handler     │    │ Service    │
└─────────┘    └──────────┘    └─────────────┘    └──────┬─────┘
                                                         │
                                                  ┌──────▼─────┐
                                                  │  Domain    │
                                                  │  Entity +  │
                                                  │  Repository│
                                                  └──────┬─────┘
                                                         │
                                                  ┌──────▼─────┐
                                                  │  Business  │
                                                  │  Event     │
                                                  └────────────┘
```

## Vertical Slicing Model

Fineract uses **vertical module slices**, not layered architecture. Each business domain owns all its layers from API to persistence.

```
Source root: fineract-provider/src/main/java/org/apache/fineract/

portfolio/                    # Financial products & accounts
├── loanaccount/              # Loan module
│   ├── api/                  # REST endpoints (JAX-RS)
│   ├── handler/              # Command handlers
│   ├── service/              # Read + write services
│   ├── domain/               # JPA entities, repositories
│   ├── data/                 # DTOs (Data Transfer Objects)
│   ├── serialization/        # JSON serializers/deserializers
│   └── exception/            # Domain-specific exceptions
├── savingsaccount/           # Savings module (same layout)
├── client/                   # Client/customer module
├── group/                    # Group lending module
├── charge/                   # Fees and charges
├── fund/                     # Fund management
├── paymenttype/              # Payment methods
└── shareaccount/             # Share accounts

accounting/                   # Chart of accounts, GL, journal entries
├── journalentry/
├── glaccount/
├── closure/
└── producttoaccountmapping/

infrastructure/               # Platform infrastructure
├── core/                     # Core utilities, commands, security
├── codes/                    # System codes/code values
├── hooks/                    # Webhooks
├── jobs/                     # Scheduled job infrastructure
├── dataqueries/              # Ad-hoc reports
└── documentmanagement/       # File attachments

useradministration/           # Users, roles, permissions
organisation/                 # Offices, staff, currency, holidays
notification/                 # Alerts and notifications
```

Each module is self-contained: all layers from API to persistence live within
the module's package. Cross-module dependencies go through service interfaces.

## Module Boundaries

### Rule 1: Self-Containment

Every module owns its full vertical slice. All layers (API → Handler → Service → Domain → Data → Exception) live within the module's package.

### Rule 2: Interface-Based Cross-Module Communication

Modules communicate through **service interfaces**, never through direct entity or repository access.

```java
// CORRECT: Loan module depends on Client read service interface
public class LoanApplicationWriteServiceImpl {
    private final ClientReadPlatformService clientReadService; // interface
}

// WRONG: Direct entity access across modules
public class LoanApplicationWriteServiceImpl {
    private final ClientRepository clientRepository; // VIOLATION
}
```

### Rule 3: Dependency Direction

```
infrastructure ← organisation ← portfolio ← accounting
                                    ↑
                              useradministration
```

- `infrastructure` depends on nothing (core platform utilities)
- `organisation` depends on `infrastructure`
- `portfolio` depends on `organisation` and `infrastructure`
- `accounting` depends on `portfolio` (for product-to-account mappings)
- `useradministration` depends on `infrastructure`

### Rule 4: No Circular Dependencies

If Module A depends on Module B, Module B must not depend on Module A. Use events or service interfaces to break cycles.

## Package Structure Maps

### Standard Module Package Layout

```
org.apache.fineract.portfolio.<module>/
├── api/
│   └── <Entity>ApiResource.java              # JAX-RS REST controller
├── handler/
│   ├── Create<Entity>CommandHandler.java      # Create command handler
│   ├── Update<Entity>CommandHandler.java      # Update command handler
│   └── Delete<Entity>CommandHandler.java      # Delete command handler
├── service/
│   ├── <Entity>WritePlatformService.java      # Write service interface
│   ├── <Entity>WritePlatformServiceImpl.java  # Write service implementation
│   ├── <Entity>ReadPlatformService.java       # Read service interface
│   └── <Entity>ReadPlatformServiceImpl.java   # Read service implementation
├── domain/
│   ├── <Entity>.java                          # JPA entity
│   ├── <Entity>Repository.java                # Spring Data repository
│   └── <Entity>RepositoryWrapper.java         # Null-safe wrapper
├── data/
│   └── <Entity>Data.java                      # DTO for API responses
├── serialization/
│   └── <Entity>DataValidator.java             # Input validation
└── exception/
    ├── <Entity>NotFoundException.java          # 404 exception
    └── <Entity>CannotBeDeletedException.java   # Domain rule exception
```

### Gradle Module Structure

```
fineract-project/
├── fineract-provider/        # Main application module
├── fineract-core/            # Shared core classes
├── fineract-investor/        # Investor module (optional)
├── fineract-avro-schemas/    # Avro event schemas
├── fineract-doc/             # Documentation
└── integration-tests/        # Integration test suite
```

## Decision Framework

### Where Does My New Code Belong?

```
Is it a financial product or account? ──→ portfolio/<module>/
Is it a chart of accounts / GL entry?  ──→ accounting/<module>/
Is it platform infrastructure?         ──→ infrastructure/<module>/
Is it user/role/permission management? ──→ useradministration/<module>/
Is it org structure (offices, staff)?  ──→ organisation/<module>/
```

### Should I Create a New Module or Extend an Existing One?

Create a **new module** when:

- The entity has its own lifecycle (create, update, delete, activate)
- It introduces new API endpoints under a distinct resource path
- It has independent business rules and state transitions
- Other modules will reference it (it's a new aggregate root)

**Extend an existing module** when:

- The entity is a child/detail of an existing aggregate
- It shares transaction boundaries with the parent
- It doesn't introduce new top-level API resources

### Naming Conventions

| Component     | Convention                            | Example                                     |
| ------------- | ------------------------------------- | ------------------------------------------- |
| Package       | `org.apache.fineract.<area>.<module>` | `org.apache.fineract.portfolio.loanproduct` |
| Entity        | PascalCase, domain noun               | `LoanProduct`                               |
| Table         | `m_<snake_case>`                      | `m_loan_product`                            |
| API Resource  | `<Entity>ApiResource`                 | `LoanProductApiResource`                    |
| Write Service | `<Entity>WritePlatformService`        | `LoanProductWritePlatformService`           |
| Read Service  | `<Entity>ReadPlatformService`         | `LoanProductReadPlatformService`            |
| Handler       | `<Action><Entity>CommandHandler`      | `CreateLoanProductCommandHandler`           |
| DTO           | `<Entity>Data`                        | `LoanProductData`                           |
| Exception     | `<Entity><Condition>Exception`        | `LoanProductNotFoundException`              |
| Permission    | `<ACTION>_<ENTITY>`                   | `CREATE_LOANPRODUCT`                        |

## Key Classes Reference

| Class                             | Purpose                             |
| --------------------------------- | ----------------------------------- |
| `AbstractPersistableCustom<Long>` | Base entity with ID                 |
| `CommandWrapper`                  | Encapsulates write command metadata |
| `CommandWrapperBuilder`           | Builds CommandWrapper instances     |
| `JsonCommand`                     | Parsed JSON command body            |
| `CommandProcessingResult`         | Return type from write operations   |
| `NewCommandSourceHandler`         | Interface for command handlers      |
| `BusinessEvent<T>`                | Interface for domain events         |
| `BusinessEventNotifierService`    | Event publishing service            |
| `PlatformSecurityContext`         | Security/auth context               |
| `ThreadLocalContextUtil`          | Tenant context per request          |
| `FromJsonHelper`                  | JSON parsing utility                |

## Example: Complete Loan Product Module Layout

```
org/apache/fineract/portfolio/loanproduct/
├── api/
│   └── LoanProductApiResource.java
├── handler/
│   ├── CreateLoanProductCommandHandler.java
│   ├── UpdateLoanProductCommandHandler.java
│   └── DeleteLoanProductCommandHandler.java
├── service/
│   ├── LoanProductWritePlatformService.java
│   ├── LoanProductWritePlatformServiceImpl.java
│   ├── LoanProductReadPlatformService.java
│   └── LoanProductReadPlatformServiceImpl.java
├── domain/
│   ├── LoanProduct.java
│   ├── LoanProduct Repository.java
│   ├── LoanProductRepositoryWrapper.java
│   ├── LoanProductStatus.java              # Enum for lifecycle states
│   └── LoanTransactionProcessingStrategy.java
├── data/
│   ├── LoanProductData.java
│   └── LoanProductAccountingData.java      # Nested DTO for accounting config
├── serialization/
│   └── LoanProductDataValidator.java
├── exception/
│   ├── LoanProductNotFoundException.java
│   ├── LoanProductCannotBeDeletedException.java
│   └── InvalidLoanProductException.java
└── event/
    ├── LoanProductCreatedBusinessEvent.java
    └── LoanProductUpdatedBusinessEvent.java
```

### Dependency Map (What This Module Uses)

```
LoanProduct Module
├── depends on → infrastructure.core (CommandWrapper, JsonCommand, security)
├── depends on → organisation.monetary (Currency, MonetaryData)
├── depends on → accounting.producttoaccountmapping (GL mappings)
├── depends on → portfolio.charge (ChargeReadPlatformService)
├── depends on → portfolio.fund (FundReadPlatformService)
└── depends on → portfolio.paymenttype (PaymentTypeReadPlatformService)
```

### Dependency Map (Who Uses This Module)

```
Consumers of LoanProduct:
├── portfolio.loanaccount → LoanProductReadPlatformService (to validate product config)
├── accounting → LoanProductReadPlatformService (to map products to GL accounts)
└── integration-tests → LoanProductApiResource (API-level testing)
```

## Checklist

### New Module Validation

- [ ] Module placed under correct area (`portfolio/`, `accounting/`, `infrastructure/`, etc.)
- [ ] Package follows `org.apache.fineract.<area>.<module>` convention
- [ ] All seven sub-packages created: `api/`, `handler/`, `service/`, `domain/`, `data/`, `serialization/`, `exception/`
- [ ] No circular dependencies with existing modules
- [ ] Cross-module access uses service interfaces, not repositories
- [ ] Table name uses `m_` prefix with snake_case
- [ ] Entity name is PascalCase domain noun
- [ ] Permission codes follow `ACTION_ENTITYNAME` format (uppercase, no separators in entity)

### Dependency Rules

- [ ] Module does not import from a module at the same or higher architectural level
- [ ] `infrastructure` has no upward dependencies
- [ ] `portfolio` modules do not import from `accounting` (accounting depends on portfolio, not reverse)
- [ ] Events used for cross-module communication where dependency would be circular

### File Naming

- [ ] API Resource: `<Entity>ApiResource.java`
- [ ] Write Service: `<Entity>WritePlatformService.java` + `Impl`
- [ ] Read Service: `<Entity>ReadPlatformService.java` + `Impl`
- [ ] Handlers: `<Action><Entity>CommandHandler.java`
- [ ] Data DTO: `<Entity>Data.java`
- [ ] Validator: `<Entity>DataValidator.java`
- [ ] Exceptions: `<Entity>NotFoundException.java`, `<Entity>CannotBe<Action>Exception.java`

## Instance Modes

Fineract supports running in different **instance modes** to separate read, write, and batch workloads across deployments:

| Mode          | Property                                   | Allowed Operations                                |
| ------------- | ------------------------------------------ | ------------------------------------------------- |
| Read          | `fineract.mode.read-enabled=true`          | GET requests only                                 |
| Write         | `fineract.mode.write-enabled=true`         | All HTTP methods                                  |
| Batch Manager | `fineract.mode.batch-manager-enabled=true` | `/v1/jobs`, `/v1/scheduler`, `/v1/loans/catch-up` |
| Batch Worker  | `fineract.mode.batch-worker-enabled=true`  | Batch job execution                               |

### Configuration

```properties
# Read-only replica instance
fineract.mode.read-enabled=true
fineract.mode.write-enabled=false
fineract.mode.batch-manager-enabled=false
fineract.mode.batch-worker-enabled=false

# Primary write instance
fineract.mode.read-enabled=true
fineract.mode.write-enabled=true
fineract.mode.batch-manager-enabled=true
fineract.mode.batch-worker-enabled=false

# Batch worker instance
fineract.mode.read-enabled=false
fineract.mode.write-enabled=false
fineract.mode.batch-manager-enabled=false
fineract.mode.batch-worker-enabled=true
```

### Enforcement

The `FineractInstanceModeApiFilter` intercepts all API requests and rejects operations that don't match the instance's mode, returning **405 Method Not Allowed**.

Endpoints always allowed regardless of mode: `/v1/instance-mode`, `/v1/batches`, actuator endpoints.

See `references/security-filters.md` for the full filter chain.
