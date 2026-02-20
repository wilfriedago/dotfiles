# Fineract Best Practices & Conventions

## Table of Contents

1. [Package Naming](#package-naming)
2. [Entity Conventions](#entity-conventions)
3. [Service Layer](#service-layer)
4. [API Layer](#api-layer)
5. [Database](#database)
6. [Common Pitfalls](#common-pitfalls)
7. [Code Review Checklist](#code-review-checklist)

## Package Naming

```
org.apache.fineract.<module>.<submodule>.<layer>
```

Examples:

- `org.apache.fineract.portfolio.loanaccount.domain`
- `org.apache.fineract.portfolio.savingsaccount.service`
- `org.apache.fineract.accounting.journalentry.api`

Layer sub-packages: `api`, `handler`, `service`, `domain`, `data`, `serialization`, `exception`.

## Entity Conventions

- Extend `AbstractPersistableCustom<Long>` (provides `id` field with `@Id @GeneratedValue`).
- Table name: `m_<module>_<entity>` (e.g., `m_savings_product`). Prefix `m_` for main tables.
- Use `@Table(name = "m_xxx")` explicitly.
- All `@ManyToOne` / `@OneToMany` relations: use `FetchType.LAZY`. Never EAGER.
- Use `@JoinColumn(name = "xxx_id")` explicitly.
- Provide a protected no-arg constructor for JPA.
- Put domain logic (validation, state transitions) in the entity, not services.
- Use `@Column(name = "xxx", nullable = false)` with explicit column names.

## Service Layer

- **Write services**: Interface `XxxWritePlatformService` + Impl annotated `@Service`.
  - Methods are `@Transactional`.
  - Validate input, load/mutate entities, save, raise events.
  - Return `CommandProcessingResult` (contains entityId, resourceId, changes map).
- **Read services**: Interface `XxxReadPlatformService` + Impl annotated `@Service`.
  - Use `JdbcTemplate` + `RowMapper` for list/search queries (performance).
  - Use JPA repository for single-entity lookups if simpler.
  - Return `XxxData` DTOs, never entities.
- Use **constructor injection** (not `@Autowired` on fields).
- Keep services focused: one write service per aggregate root.

## API Layer

- Use JAX-RS annotations (`@Path`, `@GET`, `@POST`, etc.) on resource classes.
- Resource class naming: `XxxApiResource`.
- For writes: build `CommandWrapper` via `CommandWrapperBuilder`, call
  `commandsSourceWritePlatformService.logCommandSource(commandRequest)`.
- For reads: call read service directly, return `XxxData`.
- Include `@Operation` and `@ApiResponse` (OpenAPI) annotations.
- Inject `@Context UriInfo`, `PlatformSecurityContext` for auth checks.
- Use `ApiRequestJsonSerializationSettings` for response field filtering.

## Database

- All schema changes via **Liquibase** XML changelogs.
- Changelog naming: `V<version>__<description>.xml` or numbered parts.
- Place changelogs in `src/main/resources/db/changelog/tenant/parts/`.
- Include `<rollback>` blocks for reversibility.
- Use `BIGINT` for IDs, `VARCHAR` for strings, `DECIMAL(19,6)` for money.
- Add foreign key constraints with `ON DELETE` / `ON UPDATE` policies.
- Index frequently queried columns.

## Common Pitfalls

1. **EAGER fetching**: Causes N+1 queries. Always use LAZY.
2. **Returning entities from APIs**: Return Data DTOs instead.
3. **Missing @Transactional**: Write operations silently not committed.
4. **Skipping CommandWrapper**: Breaks audit trail and maker-checker.
5. **Hardcoded tenant**: Use `ThreadLocalContextUtil` for tenant context.
6. **Missing Liquibase migration**: Schema changes without changelog break deployments.
7. **Catching exceptions too broadly**: Let Fineract's exception handler translate domain exceptions to HTTP responses.
8. **Not using repository wrapper**: Fineract wraps repos for null-check + exception throwing. Use `XxxRepositoryWrapper.findOneWithNotFoundDetection(id)`.
9. **BigDecimal comparison with equals()**: Use `compareTo()` for money values.
10. **Mutable shared state**: Services should be stateless; use method parameters.

## Checklist

- [ ] Entity extends `AbstractPersistableCustom<Long>`
- [ ] All JPA relations are LAZY
- [ ] Write service is `@Transactional`
- [ ] API uses `CommandWrapperBuilder` for writes
- [ ] Read service returns DTOs, not entities
- [ ] Liquibase changelog included for schema changes
- [ ] Custom exceptions extend Fineract base exceptions
- [ ] Business events raised for significant domain operations
- [ ] No EAGER fetching
- [ ] Constructor injection used throughout
- [ ] OpenAPI annotations on API resource
- [ ] Input validation via validators or Bean Validation
