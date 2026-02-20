# End-to-End Execution Flows

## Purpose

This skill teaches an AI agent the complete request lifecycle in Fineract, from HTTP request to database persistence and event publishing. Understanding these flows is essential for placing code in the correct layer.

## Write Path (Command Flow)

The write path handles all state-changing operations (POST, PUT, DELETE).

### Sequence Diagram

```
Client (HTTP POST/PUT/DELETE)
    │
    ▼
┌──────────────────────┐
│ ApiResource           │  1. Authenticate user
│ (JAX-RS Controller)   │  2. Build CommandWrapper via CommandWrapperBuilder
│                       │  3. Call commandsSourceWritePlatformService.logCommandSource()
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ PortfolioCommandSource│  4. Log command to m_portfolio_command_source (audit)
│ WritePlatformService  │  5. Check maker-checker: if enabled, store as pending
│                       │  6. If immediate execution: route to handler
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ CommandHandler        │  7. Receive JsonCommand
│ (@CommandType)        │  8. Delegate to write service method
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ WritePlatformService  │  9. Validate input (DataValidator)
│ (@Transactional)      │ 10. Load/create entity
│                       │ 11. Apply business rules (entity methods)
│                       │ 12. Save via RepositoryWrapper
│                       │ 13. Publish BusinessEvent
│                       │ 14. Return CommandProcessingResult
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Domain Entity +       │ 15. JPA persist/merge
│ Repository            │ 16. Hibernate flush
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ BusinessEvent         │ 17. Pre/post event listeners execute
│ Framework             │ 18. External event serialized (Avro) if configured
│                       │ 19. All within same transaction boundary
└──────────────────────┘
```

### Detailed Step-by-Step

#### Step 1–3: API Resource Layer

```java
@POST
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
@Operation(summary = "Create Savings Product")
public String create(final String apiRequestBodyAsJson) {
    // Step 1: Build command wrapper
    final CommandWrapper commandRequest = new CommandWrapperBuilder()
        .createSavingsProduct()               // Sets entity="SAVINGS_PRODUCT", action="CREATE"
        .withJson(apiRequestBodyAsJson)        // Attaches JSON body
        .build();

    // Step 2: Submit command for logging + execution
    final CommandProcessingResult result =
        commandsSourceWritePlatformService.logCommandSource(commandRequest);

    // Step 3: Return result as JSON
    return toApiJsonSerializer.serialize(result);
}
```

#### Step 4–6: Command Source Processing

The platform:

1. **Logs** the raw command to `m_portfolio_command_source` table (audit trail)
2. **Checks permissions** — does the user have `CREATE_SAVINGSPRODUCT` permission?
3. **Checks maker-checker** — if enabled for this action, stores as pending and returns
4. **Routes** to the correct handler based on `entity` + `action` from CommandWrapper

#### Step 7–8: Command Handler

```java
@Service
@CommandType(entity = "SAVINGS_PRODUCT", action = "CREATE")
public class CreateSavingsProductCommandHandler implements NewCommandSourceHandler {

    private final SavingsProductWritePlatformService service;

    @Override
    @Transactional
    public CommandProcessingResult processCommand(JsonCommand command) {
        return service.create(command);
    }
}
```

The handler is minimal — it delegates to the write service. **Never put business logic in the handler.**

#### Step 9–14: Write Service

```java
@Override
@Transactional
public CommandProcessingResult create(JsonCommand command) {
    // 9. Validate
    context.authenticatedUser();
    validator.validateForCreate(command.json());

    // 10-11. Create entity with business rules
    final SavingsProduct product = SavingsProduct.fromJson(command);

    // 12. Persist
    repository.saveAndFlush(product);

    // 13. Publish event
    businessEventNotifierService.notifyPostBusinessEvent(
        new SavingsProductCreatedBusinessEvent(product));

    // 14. Return result
    return new CommandProcessingResultBuilder()
        .withCommandId(command.commandId())
        .withEntityId(product.getId())
        .build();
}
```

## Read Path (Query Flow)

The read path handles all non-mutating operations (GET).

### Sequence Diagram

```
Client (HTTP GET)
    │
    ▼
┌──────────────────────┐
│ ApiResource           │  1. Authenticate user
│ (JAX-RS Controller)   │  2. Call ReadPlatformService directly
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ ReadPlatformService   │  3. Execute JDBC query with RowMapper
│                       │  4. Map ResultSet to Data DTO
│                       │  5. Return DTO (never entity)
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Database              │  6. SQL execution on tenant schema
│ (JdbcTemplate)        │
└──────────────────────┘
```

### Key Differences from Write Path

| Aspect                      | Write Path                | Read Path                        |
| --------------------------- | ------------------------- | -------------------------------- |
| HTTP Methods                | POST, PUT, DELETE         | GET                              |
| Goes through CommandWrapper | Yes                       | No                               |
| Audit logged                | Yes                       | No                               |
| Maker-checker               | Applicable                | Not applicable                   |
| Transaction scope           | `@Transactional`          | Read-only (no annotation needed) |
| Returns                     | `CommandProcessingResult` | Data DTO (`<Entity>Data`)        |
| Data access                 | JPA entities              | JdbcTemplate + RowMapper         |
| Business events             | Published                 | Never                            |

## Transaction Boundaries

### Rule: One Transaction Per Command

Each command handler method (or the write service method it calls) should execute within a single `@Transactional` boundary. This ensures:

1. Entity persistence and event publishing are atomic
2. If event handler fails, entity changes roll back
3. If entity save fails, no event is published

```
┌─────────── @Transactional ───────────────────────┐
│                                                    │
│  validate → create entity → save → publish event   │
│                                                    │
│  If ANY step fails, EVERYTHING rolls back          │
└────────────────────────────────────────────────────┘
```

### Anti-Pattern: Nested Transactions

Do NOT create nested `@Transactional` boundaries within a single command flow. If a service calls another transactional service, the inner one joins the outer transaction by default (Spring's `REQUIRED` propagation).

### Read Transactions

Read services generally don't need `@Transactional` annotation. If you need a consistent snapshot across multiple queries, use `@Transactional(readOnly = true)`.

## Decision Framework

### When to Use the Write Path

- Any operation that creates, updates, or deletes data
- Any operation that needs audit logging
- Any operation subject to maker-checker approval
- Any operation that should trigger business events

### When to Use the Read Path

- Listing/searching entities
- Retrieving single entity details
- Template/dropdown data retrieval
- Report generation

### When to Publish Business Events

- Entity created, updated, or deleted
- State transition (e.g., loan approved, savings activated)
- Financial operation (disbursement, repayment, withdrawal)
- Do NOT publish events for reads or template retrieval

## Checklist

### Write Path Validation

- [ ] API Resource builds CommandWrapper via CommandWrapperBuilder
- [ ] Command submitted through `commandsSourceWritePlatformService.logCommandSource()`
- [ ] Handler annotated with `@CommandType(entity=..., action=...)`
- [ ] Handler delegates to write service (no business logic in handler)
- [ ] Write service method annotated `@Transactional`
- [ ] Validation occurs before entity mutation
- [ ] Entity saved via RepositoryWrapper (not raw repository)
- [ ] Business event published after save, within same transaction
- [ ] `CommandProcessingResult` returned with entityId and commandId

### Read Path Validation

- [ ] API Resource calls read service directly (no CommandWrapper)
- [ ] Read service uses JdbcTemplate + RowMapper (not JPA entities for lists)
- [ ] Returns Data DTO, never JPA entity
- [ ] `context.authenticatedUser()` called at entry
- [ ] EmptyResultDataAccessException caught and converted to NotFoundException

### Transaction Boundaries

- [ ] Single @Transactional boundary per command
- [ ] No nested @Transactional with REQUIRES_NEW in command flow
- [ ] Event publishing inside transaction boundary
- [ ] Read services use readOnly=true if annotated at all
