# Maker-Checker Workflows

## Purpose

This skill explains the maker-checker (four-eyes principle) workflow in Fineract: how commands flow through approval, how to configure it, and when it should be required.

## Concept

Maker-checker is a two-step approval process:

1. **Maker** initiates the operation (submits command)
2. **Checker** (different user) approves or rejects the command
3. Only upon approval does the command actually execute

This provides an audit control mechanism critical in financial systems.

## How It Works

### Normal Flow (Maker-Checker Disabled)

```
Maker submits command → Command executes immediately → Result returned
```

### Maker-Checker Flow (Enabled)

```
Maker submits command
    │
    ▼
Command stored as PENDING in m_portfolio_command_source
    │
    ▼
Checker reviews pending commands
    │
    ├── APPROVE → Command re-submitted and executed
    │                 │
    │                 └── Result stored in command source record
    │
    └── REJECT → Command marked as rejected, never executed
```

## Configuration

Maker-checker is configured per action in `m_permission`:

```sql
-- Enable maker-checker for loan approval
UPDATE m_permission
SET can_maker_checker = true
WHERE code = 'APPROVE_LOAN';

-- Disable maker-checker for savings product creation
UPDATE m_permission
SET can_maker_checker = false
WHERE code = 'CREATE_SAVINGSPRODUCT';
```

In Liquibase:

```xml
<insert tableName="m_permission">
    <column name="grouping" value="portfolio"/>
    <column name="code" value="APPROVE_LOAN"/>
    <column name="entity_name" value="LOAN"/>
    <column name="action_name" value="APPROVE"/>
    <column name="can_maker_checker" valueBoolean="true"/>
</insert>
```

## Pending Command Table

`m_portfolio_command_source` stores all commands:

| Column            | Description                         |
| ----------------- | ----------------------------------- |
| `id`              | Command ID                          |
| `action_name`     | CREATE, UPDATE, APPROVE, etc.       |
| `entity_name`     | LOAN, SAVINGSPRODUCT, etc.          |
| `office_id`       | Maker's office                      |
| `maker_id`        | User who submitted                  |
| `made_on_date`    | Submission timestamp                |
| `checker_id`      | User who approved (null if pending) |
| `checked_on_date` | Approval timestamp                  |
| `status`          | 0=pending, 1=processed, 2=rejected  |
| `command_as_json` | Original JSON payload               |
| `result`          | Processing result after execution   |

## Checker API

Pending commands are managed via the maker-checker API:

```
GET  /v1/makercheckers?officeId=1&status=pending    # List pending commands
POST /v1/makercheckers/{commandId}?command=approve   # Approve
POST /v1/makercheckers/{commandId}?command=reject    # Reject
```

## Developer Requirements

The developer does NOT implement maker-checker logic. The platform handles it automatically. Developers must:

1. **Use CommandWrapperBuilder** — all writes must go through the command framework
2. **Set permissions correctly** — include `can_maker_checker` in Liquibase
3. **Make handlers idempotent** — the command may be executed later when approved
4. **Never bypass logCommandSource()** — this breaks maker-checker

## Risk Classification

### When Maker-Checker SHOULD Be Enabled

| Operation             | Risk Level | Maker-Checker |
| --------------------- | ---------- | ------------- |
| Loan approval         | HIGH       | Required      |
| Loan disbursement     | HIGH       | Required      |
| Large fund transfer   | HIGH       | Required      |
| User role changes     | HIGH       | Recommended   |
| GL account creation   | MEDIUM     | Recommended   |
| Product configuration | MEDIUM     | Recommended   |
| Client creation       | LOW        | Optional      |
| Read operations       | NONE       | Never         |

### Decision Rule

Enable maker-checker when:

- Operation involves money movement
- Operation changes security/permissions
- Operation modifies financial product configuration
- Regulatory requirement mandates dual approval
- Risk of error has significant financial impact

## Idempotency Implications

Since a command may be stored and executed later, handlers must be idempotent:

```java
// GOOD: Idempotent — safe to run again
@Override
public CommandProcessingResult processCommand(JsonCommand command) {
    return writePlatformService.create(command);
}

// BAD: Not idempotent — counter increments each time
@Override
public CommandProcessingResult processCommand(JsonCommand command) {
    counter.increment(); // Side effect outside transaction
    return writePlatformService.create(command);
}
```

# Checklist

- [ ] All write operations use CommandWrapperBuilder + logCommandSource()
- [ ] Permission created with appropriate `can_maker_checker` value
- [ ] High-risk operations (money, permissions, products) have maker-checker enabled
- [ ] Command handlers are idempotent (safe to execute on approval)
- [ ] No side effects outside the transaction boundary in handlers
- [ ] logCommandSource() is never bypassed for write operations
- [ ] Risk classification documented for new operations
