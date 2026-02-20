# CQRS & Command Processing

## Purpose

This skill teaches the command-query responsibility segregation (CQRS) pattern as implemented in Fineract: command lifecycle, command logging, handler routing, and maker-checker injection points.

## Command Lifecycle

### 1. Command Construction (API Layer)

Every write operation starts by building a `CommandWrapper`:

```java
final CommandWrapper commandRequest = new CommandWrapperBuilder()
    .createSavingsProduct()                // Fluent method sets entity + action
    .withJson(apiRequestBodyAsJson)        // Attaches the JSON body
    .build();
```

The `CommandWrapperBuilder` has fluent methods for common operations. For custom entities:

```java
final CommandWrapper commandRequest = new CommandWrapperBuilder()
    .withJson(apiRequestBodyAsJson)
    .withEntityName("CUSTOM_ENTITY")       // Custom entity name
    .withAction("CREATE")                   // Action verb
    .withHref("/custom-entities")           // API path for audit
    .build();
```

### 2. Command Logging

When submitted via `logCommandSource()`, the platform:

```java
CommandProcessingResult result =
    commandsSourceWritePlatformService.logCommandSource(commandRequest);
```

1. Persists command to `m_portfolio_command_source` table (raw JSON, user, timestamp)
2. Checks user permission: `<ACTION>_<ENTITY>` (e.g., `CREATE_SAVINGSPRODUCT`)
3. Checks maker-checker: if this action requires approval, stores as pending
4. If immediate: routes command to matching handler

### 3. Handler Routing

Handlers are discovered by `@CommandType` annotation:

```java
@Service
@CommandType(entity = "SAVINGS_PRODUCT", action = "CREATE")
public class CreateSavingsProductCommandHandler
        implements NewCommandSourceHandler {

    @Override
    @Transactional
    public CommandProcessingResult processCommand(JsonCommand command) {
        return writePlatformService.create(command);
    }
}
```

**Routing rule:** The platform finds the Spring bean with `@CommandType` matching `entity` + `action` from the `CommandWrapper`.

### 4. Command Execution

The `JsonCommand` object provides:

```java
command.commandId()                          // Unique command ID
command.json()                               // Raw JSON string
command.stringValueOfParameterNamed("name")  // Extract string field
command.bigDecimalValueOfParameterNamed("rate") // Extract BigDecimal
command.longValueOfParameterNamed("officeId")   // Extract Long
command.booleanPrimitiveValueOfParameterNamed("active") // Extract boolean
command.isChangeInStringParameterNamed("name", current)  // Detect changes
```

### 5. Command Result

All write operations return `CommandProcessingResult`:

```java
return new CommandProcessingResultBuilder()
    .withCommandId(command.commandId())      // Link back to command
    .withEntityId(entity.getId())            // Created/modified entity ID
    .withOfficeId(entity.getOfficeId())      // Optional: office context
    .withSubEntityId(subEntity.getId())      // Optional: child entity
    .with(changes)                           // Map of changed fields (for updates)
    .build();
```

## Command Entity/Action Naming

### Standard Actions

| Action       | HTTP Method | When to Use                   |
| ------------ | ----------- | ----------------------------- |
| `CREATE`     | POST        | New entity creation           |
| `UPDATE`     | PUT         | Modify existing entity        |
| `DELETE`     | DELETE      | Remove entity                 |
| `ACTIVATE`   | POST        | Enable/start entity lifecycle |
| `CLOSE`      | POST        | End entity lifecycle          |
| `APPROVE`    | POST        | Approve pending operation     |
| `REJECT`     | POST        | Reject pending operation      |
| `DISBURSE`   | POST        | Loan disbursement             |
| `DEPOSIT`    | POST        | Savings deposit               |
| `WITHDRAWAL` | POST        | Savings withdrawal            |
| `WAIVE`      | POST        | Waive charge/penalty          |

### Entity Name Convention

Entity names in `@CommandType` are UPPER_CASE without separators:

- `SAVINGS_PRODUCT` (underscores allowed for multi-word)
- `LOANPRODUCT`
- `CLIENT`
- `SAVINGSACCOUNT`

The corresponding permission code is `<ACTION>_<ENTITY>`: `CREATE_SAVINGSPRODUCT`, `UPDATE_LOANPRODUCT`.

## Maker-Checker Injection

Maker-checker is controlled per action via the `m_permission` table:

```sql
-- Enable maker-checker for loan approval
UPDATE m_permission
SET can_maker_checker = true
WHERE code = 'APPROVE_LOAN';
```

When enabled:

1. **Maker** submits command → stored as pending (`status = 0` in `m_portfolio_command_source`)
2. **Checker** (different user) approves → command re-executed
3. **Rejection** → command marked as rejected, never executed

The agent does NOT need to implement maker-checker logic — it's built into the platform. The agent only needs to:

1. Use `CommandWrapperBuilder` correctly
2. Set `can_maker_checker` in Liquibase migration for the permission
3. Ensure the handler is idempotent (can be re-run on approval)

## Decision Framework

### When to Create a New Command Handler

Create a handler when:

- A new write operation is introduced (create, update, delete, state transition)
- The operation needs audit logging
- The operation might need maker-checker in the future
- The operation modifies persistent state

Do NOT create a handler for:

- Read-only operations (use read services directly)
- Internal service-to-service calls within the same transaction
- Utility/helper operations

### When to Use Custom Entity/Action Names

Use standard `CommandWrapperBuilder` methods when available:

```java
.createSavingsProduct()    // Preferred: uses standard naming
```

Use custom names only for new entities not covered by builder methods:

```java
.withEntityName("MY_ENTITY").withAction("APPROVE")
```

## Templates

### Command Handler Template

```java
@Service
@CommandType(entity = "${ENTITY_UPPER}", action = "${ACTION}")
@RequiredArgsConstructor
public class ${Action}${Entity}CommandHandler implements NewCommandSourceHandler {

    private final ${Entity}WritePlatformService service;

    @Override
    @Transactional
    public CommandProcessingResult processCommand(JsonCommand command) {
        return service.${action}(command);
    }
}
```

### CommandWrapper Builder Pattern

```java
// For standard CRUD
new CommandWrapperBuilder().create${Entity}().withJson(json).build();
new CommandWrapperBuilder().update${Entity}(entityId).withJson(json).build();
new CommandWrapperBuilder().delete${Entity}(entityId).build();

// For custom actions
new CommandWrapperBuilder()
    .withEntityName("${ENTITY}")
    .withAction("${ACTION}")
    .withEntityId(entityId)
    .withJson(json)
    .build();
```

## Checklist

### Command Construction

- [ ] CommandWrapper built via CommandWrapperBuilder
- [ ] Entity name matches `@CommandType(entity=...)` on handler
- [ ] Action name matches `@CommandType(action=...)` on handler
- [ ] JSON body attached via `.withJson()`
- [ ] EntityId attached for update/delete operations

### Command Handler

- [ ] Annotated with `@Service`
- [ ] Annotated with `@CommandType(entity=..., action=...)`
- [ ] Implements `NewCommandSourceHandler`
- [ ] Method `processCommand` is `@Transactional`
- [ ] Handler delegates to write service (no business logic)
- [ ] Handler is stateless (no instance fields beyond injected services)

### Command Logging

- [ ] Command submitted via `commandsSourceWritePlatformService.logCommandSource()`
- [ ] Corresponding permission exists: `<ACTION>_<ENTITY>` in `m_permission`
- [ ] `can_maker_checker` set appropriately in permission migration
- [ ] Handler is idempotent (safe to re-execute on maker-checker approval)

### CommandProcessingResult

- [ ] `.withCommandId(command.commandId())` included
- [ ] `.withEntityId(entity.getId())` included
- [ ] `.with(changes)` included for update operations
- [ ] No null entity IDs returned
