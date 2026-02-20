# Services & Command Handlers

## Purpose

This skill teaches how to implement write services, read services, and command handlers in Fineract, including transaction scopes, validation layering, and idempotency handling.

## Command Handler

Fineract routes commands to handlers via action+entity type. Handlers implement
`NewCommandSourceHandler`:

```java
@Service
@CommandType(entity = "SAVINGS_PRODUCT", action = "CREATE")
public class CreateSavingsProductCommandHandler implements NewCommandSourceHandler {

    private final SavingsProductWritePlatformService service;

    @Autowired
    public CreateSavingsProductCommandHandler(
            SavingsProductWritePlatformService service) {
        this.service = service;
    }

    @Override
    @Transactional
    public CommandProcessingResult processCommand(JsonCommand command) {
        return service.create(command);
    }
}
```

Handler annotations: `@CommandType(entity = "XXX", action = "CREATE|UPDATE|DELETE")`.
Actions: `CREATE`, `UPDATE`, `DELETE`, `APPROVE`, `REJECT`, `ACTIVATE`, `CLOSE`, etc.

## Write Service Pattern

### Interface

```java
public interface SavingsProductWritePlatformService {
    CommandProcessingResult create(JsonCommand command);
    CommandProcessingResult update(Long productId, JsonCommand command);
    CommandProcessingResult delete(Long productId);
}
```

### Implementation

```java
@Service
@Slf4j
@RequiredArgsConstructor
public class SavingsProductWritePlatformServiceImpl
        implements SavingsProductWritePlatformService {

    private final PlatformSecurityContext context;
    private final SavingsProductRepositoryWrapper repository;
    private final SavingsProductDataValidator validator;
    private final FromJsonHelper fromJsonHelper;
    private final BusinessEventNotifierService businessEventNotifierService;

    @Override
    @Transactional
    public CommandProcessingResult create(JsonCommand command) {
        // 1. Security check
        context.authenticatedUser();

        // 2. Validate input
        validator.validateForCreate(command.json());

        // 3. Create entity
        final SavingsProduct product = SavingsProduct.fromJson(command);

        // 4. Persist (use wrapper, not raw repo)
        try {
            repository.saveAndFlush(product);
        } catch (DataIntegrityViolationException e) {
            handleDataIntegrityIssues(command, e);
        }

        // 5. Publish event (within transaction)
        businessEventNotifierService.notifyPostBusinessEvent(
            new SavingsProductCreatedBusinessEvent(product));

        // 6. Return result
        return new CommandProcessingResultBuilder()
            .withCommandId(command.commandId())
            .withEntityId(product.getId())
            .build();
    }

    @Override
    @Transactional
    public CommandProcessingResult update(Long productId, JsonCommand command) {
        context.authenticatedUser();
        validator.validateForUpdate(command.json());

        final SavingsProduct product = repository.findOneWithNotFoundDetection(productId);
        final Map<String, Object> changes = product.update(command);

        if (!changes.isEmpty()) {
            try {
                repository.saveAndFlush(product);
            } catch (DataIntegrityViolationException e) {
                handleDataIntegrityIssues(command, e);
            }
        }

        return new CommandProcessingResultBuilder()
            .withCommandId(command.commandId())
            .withEntityId(productId)
            .with(changes)
            .build();
    }

    @Override
    @Transactional
    public CommandProcessingResult delete(Long productId) {
        context.authenticatedUser();
        final SavingsProduct product = repository.findOneWithNotFoundDetection(productId);

        // Business rule check
        if (product.isActive()) {
            throw new SavingsProductCannotBeDeletedException(
                productId, "Product is currently active");
        }

        repository.delete(product);

        return new CommandProcessingResultBuilder()
            .withEntityId(productId)
            .build();
    }

    private void handleDataIntegrityIssues(JsonCommand command,
            DataIntegrityViolationException e) {
        Throwable cause = e.getMostSpecificCause();
        if (cause.getMessage().contains("m_savings_product_name_unique")) {
            String name = command.stringValueOfParameterNamed("name");
            throw new PlatformDataIntegrityException(
                "error.msg.savings.product.duplicate.name",
                "Product name '" + name + "' already exists", "name", name);
        }
        throw new PlatformDataIntegrityException(
            "error.msg.savings.product.unknown.data.integrity.issue",
            "Unknown data integrity issue");
    }
}
```

## Write Service Method Structure

Every write method follows this pattern:

```
1. context.authenticatedUser()         — Security check
2. validator.validateFor<Action>()     — Input validation
3. Load entity (for update/delete)     — Via RepositoryWrapper
4. Execute domain logic                — Entity methods
5. repository.saveAndFlush()           — Persist changes
6. notifyPostBusinessEvent()           — Publish event
7. Return CommandProcessingResult      — With entityId + changes
```

## CommandProcessingResult

Always return `CommandProcessingResult` from write services. Build with:

- `.withEntityId(id)` — the created/updated entity ID
- `.withCommandId(commandId)` — the command that triggered this
- `.with(changes)` — map of changed fields (for update auditing)
- `.withSubEntityId(id)` — if operating on a child entity

## Read Service Pattern

### Interface

```java
public interface SavingsProductReadPlatformService {
    SavingsProductData retrieveOne(Long productId);
    Collection<SavingsProductData> retrieveAll();
    Page<SavingsProductData> retrieveAll(SearchParameters searchParameters);
}
```

### Implementation

```java
@Service
@RequiredArgsConstructor
public class SavingsProductReadPlatformServiceImpl
        implements SavingsProductReadPlatformService {

    private final JdbcTemplate jdbcTemplate;
    private final PlatformSecurityContext context;
    private final SavingsProductMapper mapper = new SavingsProductMapper();

    @Override
    public SavingsProductData retrieveOne(Long productId) {
        context.authenticatedUser();
        final String sql = "SELECT " + mapper.schema() + " WHERE sp.id = ?";
        try {
            return jdbcTemplate.queryForObject(sql, mapper, productId);
        } catch (EmptyResultDataAccessException e) {
            throw new SavingsProductNotFoundException(productId);
        }
    }

    @Override
    public Collection<SavingsProductData> retrieveAll() {
        context.authenticatedUser();
        final String sql = "SELECT " + mapper.schema() + " ORDER BY sp.name";
        return jdbcTemplate.query(sql, mapper);
    }

    // Inner class: RowMapper
    private static final class SavingsProductMapper
            implements RowMapper<SavingsProductData> {

        public String schema() {
            return " sp.id AS id, sp.name AS name, "
                + "sp.description AS description, "
                + "sp.nominal_annual_interest_rate AS nominalAnnualInterestRate, "
                + "sp.active AS active "
                + "FROM m_savings_product sp ";
        }

        @Override
        public SavingsProductData mapRow(ResultSet rs, int rowNum)
                throws SQLException {
            final Long id = rs.getLong("id");
            final String name = rs.getString("name");
            final String description = rs.getString("description");
            final BigDecimal rate = rs.getBigDecimal("nominalAnnualInterestRate");
            final boolean active = rs.getBoolean("active");
            return new SavingsProductData(id, name, description, rate, active);
        }
    }
}
```

## Key Patterns

- **RowMapper as inner class**: Keeps mapping logic co-located with the query.
- **`schema()` method**: Returns the SELECT + FROM clause; callers add WHERE/ORDER BY.
- **Security check**: Always call `context.authenticatedUser()` at the start.
- **Exception mapping**: Catch `EmptyResultDataAccessException` → throw domain `NotFoundException`.
- **SearchParameters**: For paginated/filtered queries, accept `SearchParameters` and build dynamic SQL.

## Transaction Scope Rules

| Method Type | Annotation                              | Reason                                    |
| ----------- | --------------------------------------- | ----------------------------------------- |
| Create      | `@Transactional`                        | Ensures entity + event are atomic         |
| Update      | `@Transactional`                        | Ensures entity changes + event are atomic |
| Delete      | `@Transactional`                        | Ensures delete + event are atomic         |
| Read single | None or `@Transactional(readOnly=true)` | No mutation                               |
| Read list   | None                                    | No mutation                               |

## Validation Layering

```
Layer 1: Bean Validation        — @NotNull, @Size, @Min on DTO (if used)
Layer 2: DataValidator           — Fineract's custom JSON validation in serialization/ package
Layer 3: Entity Domain Logic     — Business rules in entity methods
Layer 4: Database Constraints    — Unique constraints, foreign keys, NOT NULL
```

Validation in DataValidator (Layer 2) is the primary validation approach in Fineract:

```java
@Component
public class SavingsProductDataValidator {
    private final FromJsonHelper fromJsonHelper;

    public void validateForCreate(String json) {
        final List<ApiParameterError> errors = new ArrayList<>();
        final JsonElement element = fromJsonHelper.parse(json);

        final String name = fromJsonHelper.extractStringNamed("name", element);
        if (StringUtils.isBlank(name)) {
            errors.add(ApiParameterError.parameterError(
                "validation.msg.savings.product.name.cannot.be.blank",
                "Name is mandatory", "name"));
        }

        throwExceptionIfValidationErrors(errors);
    }
}
```

## Idempotency Handling

For update operations, the `entity.update(command)` method returns a changes map. If the map is empty, skip the save:

```java
final Map<String, Object> changes = product.update(command);
if (!changes.isEmpty()) {
    repository.saveAndFlush(product);  // Only save if something changed
}
```

This provides idempotency — submitting the same update twice has no effect on the second call.

## Decision Framework

### When to Use Write Service vs Direct Repository

| Scenario                   | Approach                           |
| -------------------------- | ---------------------------------- |
| API-triggered CRUD         | Write service via command handler  |
| Batch job processing       | Write service (for audit + events) |
| Internal cross-module call | Write service interface            |
| Test data setup            | Raw repository is acceptable       |

### When to Use JdbcTemplate vs JPA for Reads

| Scenario            | Approach                               |
| ------------------- | -------------------------------------- |
| List/search queries | JdbcTemplate + RowMapper (performance) |
| Single entity by ID | RepositoryWrapper (simpler code)       |
| Complex joins       | JdbcTemplate (more control)            |
| Aggregation queries | JdbcTemplate (SQL aggregates)          |

## Generator

```bash
python3 scripts/generate_read_service.py \
  --entity-name SavingsProduct \
  --package org.apache.fineract.portfolio.savingsproduct \
  --table-name m_savings_product \
  --table-alias sp \
  --fields "name:String,description:String,nominalAnnualInterestRate:BigDecimal,active:boolean" \
  --output-dir ./output
```

Generates: `service/SavingsProductReadPlatformService.java`,
`service/SavingsProductReadPlatformServiceImpl.java`.

```bash
python3 scripts/generate_write_service.py \
  --entity-name SavingsProduct \
  --package org.apache.fineract.portfolio.savingsproduct \
  --actions "create,update,delete" \
  --output-dir ./output
```

Generates: `service/SavingsProductWritePlatformService.java`,
`service/SavingsProductWritePlatformServiceImpl.java`,
`handler/CreateSavingsProductCommandHandler.java`, etc.

## Checklist

### Write Service

- [ ] Interface + Impl pattern (separate files)
- [ ] Impl annotated with `@Service`
- [ ] Constructor injection (no field `@Autowired`)
- [ ] All write methods annotated `@Transactional`
- [ ] `context.authenticatedUser()` called first
- [ ] Input validated via DataValidator before entity mutation
- [ ] Entity loaded via RepositoryWrapper (not raw repo)
- [ ] DataIntegrityViolationException caught and mapped
- [ ] Business event published after save
- [ ] `CommandProcessingResult` returned with entityId + commandId

### Read Service

- [ ] Interface + Impl pattern
- [ ] Uses JdbcTemplate + RowMapper for list queries
- [ ] RowMapper as private inner class with `schema()` method
- [ ] Returns Data DTOs, never JPA entities
- [ ] `context.authenticatedUser()` called
- [ ] EmptyResultDataAccessException caught → NotFoundException

### Command Handler

- [ ] `@Service` + `@CommandType(entity=..., action=...)`
- [ ] Implements `NewCommandSourceHandler`
- [ ] `processCommand` is `@Transactional`
- [ ] Delegates to write service (zero business logic)
- [ ] Handler is stateless

### Idempotency

- [ ] Update checks `changes.isEmpty()` before saving
- [ ] Create uses `saveAndFlush` for immediate ID generation
- [ ] Delete checks business rules before removal

## Assembler Pattern

For complex entities with nested associations, use an **Assembler** instead of `Entity.fromJson()`. Assemblers construct entities by resolving related entities from multiple repositories.

### When to Use

| Scenario                                            | Approach                       |
| --------------------------------------------------- | ------------------------------ |
| Simple entity, flat fields                          | `Entity.fromJson(JsonCommand)` |
| Entity with nested objects, foreign keys to resolve | Assembler                      |

### Naming Convention

`<Entity>Assembler` — lives in `service/` or `domain/` package.

### Example

```java
@Service
@RequiredArgsConstructor
public class DepositAccountAssembler {

    private final ClientRepositoryWrapper clientRepository;
    private final SavingsProductRepositoryWrapper productRepository;
    private final StaffRepositoryWrapper staffRepository;
    private final FromJsonHelper fromJsonHelper;

    public SavingsAccount assembleFrom(JsonCommand command) {
        final Long clientId = command.longValueOfParameterNamed("clientId");
        final Client client = clientRepository.findOneWithNotFoundDetection(clientId);

        final Long productId = command.longValueOfParameterNamed("productId");
        final SavingsProduct product = productRepository.findOneWithNotFoundDetection(productId);

        final Long staffId = command.longValueOfParameterNamed("fieldOfficerId");
        Staff staff = null;
        if (staffId != null) {
            staff = staffRepository.findOneWithNotFoundDetection(staffId);
        }

        return SavingsAccount.create(client, product, staff, command);
    }
}
```

The write service calls the assembler instead of `Entity.fromJson()`:

```java
@Override
@Transactional
public CommandProcessingResult create(JsonCommand command) {
    context.authenticatedUser();
    validator.validateForCreate(command.json());

    final SavingsAccount account = assembler.assembleFrom(command);
    repository.saveAndFlush(account);

    return new CommandProcessingResultBuilder()
        .withEntityId(account.getId())
        .build();
}
```

## Request-Level Idempotency

Beyond the update-level idempotency (`changes.isEmpty()` pattern above), Fineract supports **request-level idempotency** via the `Idempotency-Key` HTTP header. This prevents duplicate financial operations when clients retry requests.

### How It Works

1. Client sends request with `Idempotency-Key: <unique-key>` header
2. `IdempotencyStoreFilter` extracts the key and stores it in request context
3. `SynchronousCommandProcessingService` checks if a command with this key already executed
4. If yes → returns the stored result without re-executing
5. If no → executes command and stores result keyed by the idempotency key

### Configuration

```properties
fineract.idempotency-key-header-name=Idempotency-Key
```

### Usage in API Calls

```
POST /v1/savingsaccounts
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000
Content-Type: application/json

{ "clientId": 1, "productId": 2, ... }
```

Retrying the same request with the same key returns the original result.

See `references/security-filters.md` for the `IdempotencyStoreFilter` implementation details.
