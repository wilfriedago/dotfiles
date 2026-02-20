# Business Event Framework

## Purpose

This skill teaches the transactional business event system in Fineract: how to define events, publish them, listen for them, handle failures, and serialize for external consumption.

## Event Architecture

```
Write Service (within @Transactional)
    │
    ├── notifyPreBusinessEvent(event)    ← Before the operation
    │       │
    │       └── Pre-event listeners execute (validation/enrichment)
    │
    ├── Entity mutation + save
    │
    └── notifyPostBusinessEvent(event)   ← After the operation
            │
            ├── Post-event listeners execute (side effects)
            ├── External event serialized to m_external_event (Avro)
            │
            └── If ANY listener fails → ENTIRE transaction rolls back
```

## Defining a Business Event

Every event implements `BusinessEvent<T>`:

```java
public class LoanApprovedBusinessEvent implements BusinessEvent<Loan> {

    private final Loan loan;

    public LoanApprovedBusinessEvent(Loan loan) {
        this.loan = loan;
    }

    @Override
    public Loan get() {
        return loan;
    }

    @Override
    public String getType() {
        return "LoanApprovedBusinessEvent";
    }

    @Override
    public String getCategory() {
        return "Loan";
    }

    @Override
    public Long getAggregateRootId() {
        return loan.getId();
    }
}
```

### Event Interface Contract

| Method                 | Purpose                                   | Example                           |
| ---------------------- | ----------------------------------------- | --------------------------------- |
| `get()`                | Returns the event payload (domain entity) | The Loan object                   |
| `getType()`            | Unique event type identifier              | `"LoanApprovedBusinessEvent"`     |
| `getCategory()`        | Groups related events                     | `"Loan"`, `"Savings"`, `"Client"` |
| `getAggregateRootId()` | ID of the aggregate root affected         | `loan.getId()`                    |

## Publishing Events

### Post-Business Events (Most Common)

Published after the domain operation succeeds but within the same transaction:

```java
@Transactional
public CommandProcessingResult approveLoan(Long loanId, JsonCommand command) {
    // ... validation, entity mutation, save ...

    businessEventNotifierService.notifyPostBusinessEvent(
        new LoanApprovedBusinessEvent(loan));

    return result;
}
```

### Pre-Business Events (Rare)

Published before the operation, for validation or enrichment by listeners:

```java
businessEventNotifierService.notifyPreBusinessEvent(
    new LoanApprovalRequestedBusinessEvent(loan));
```

Use pre-events when:

- Other modules need to validate before the operation proceeds
- Enrichment data needs to be added to the entity before save

## Listening for Events

```java
@Component
@RequiredArgsConstructor
public class LoanApprovalNotificationListener {

    private final BusinessEventNotifierService eventNotifierService;
    private final NotificationService notificationService;

    @PostConstruct
    public void registerListeners() {
        eventNotifierService.addPostBusinessEventListener(
            LoanApprovedBusinessEvent.class,
            event -> {
                Loan loan = event.get();
                notificationService.sendApprovalNotification(loan);
            });
    }
}
```

### Listener Rules

1. Listeners execute **within the same transaction** as the publisher
2. If a listener throws an exception, the **entire operation rolls back**
3. Keep listener logic fast — no long-running operations
4. For async processing, write to an outbox table and process separately

## External Events (Avro Serialization)

For consumption by external systems, events are serialized using Apache Avro.

### Avro Schema Definition

Place in `fineract-avro-schemas/src/main/avro/`:

```json
{
  "type": "record",
  "name": "LoanApprovedEvent",
  "namespace": "org.apache.fineract.avro.loan",
  "fields": [
    { "name": "loanId", "type": "long" },
    { "name": "clientId", "type": "long" },
    { "name": "approvedAmount", "type": "string" },
    { "name": "approvedOnDate", "type": ["null", "string"], "default": null },
    { "name": "currencyCode", "type": "string" }
  ]
}
```

### External Event Storage

External events are stored in `m_external_event` table:

- `type` — Event type string
- `category` — Event category
- `schema` — Avro schema name
- `data` — Avro-serialized binary payload
- `aggregate_root_id` — Entity ID
- `created_at` — Timestamp
- `status` — PENDING / SENT

External consumers poll or are notified about new events.

## Failure and Rollback Behavior

### Scenario: Listener Failure

```
1. Write service creates entity → saved
2. Event published → listener throws exception
3. ENTIRE transaction rolls back
4. Entity creation is undone
5. Caller receives error response
```

This is by design — Fineract prioritizes **data consistency** over availability.

### Handling Long-Running Side Effects

If a listener needs to trigger a long operation (email, external API call):

```java
// WRONG: Direct call in listener (blocks transaction, risks timeout)
eventNotifierService.addPostBusinessEventListener(
    LoanApprovedBusinessEvent.class,
    event -> externalApiService.callSlowApi(event.get()) // DANGEROUS
);

// CORRECT: Write to outbox, process async
eventNotifierService.addPostBusinessEventListener(
    LoanApprovedBusinessEvent.class,
    event -> outboxService.enqueue("LOAN_APPROVED", event.getAggregateRootId())
);
```

## Decision Framework

### When to Publish Business Events

**Always publish** when:

- Entity lifecycle changes (created, activated, closed, deleted)
- Financial transactions occur (disbursement, repayment, deposit, withdrawal)
- State transitions happen (approved, rejected, written-off)
- Cross-module side effects needed (accounting entries, notifications)

**Never publish** when:

- Read-only operations
- Internal helper/utility methods
- Temporary/intermediate calculations
- Configuration lookups

### Event Naming Convention

```
<Entity><Action>BusinessEvent

Examples:
- LoanCreatedBusinessEvent
- LoanApprovedBusinessEvent
- LoanDisbursedBusinessEvent
- SavingsDepositBusinessEvent
- ClientActivatedBusinessEvent
```

### Pre vs Post Events

| Criteria       | Pre-Event                | Post-Event                    |
| -------------- | ------------------------ | ----------------------------- |
| Timing         | Before operation         | After operation               |
| Entity state   | Pre-mutation             | Post-mutation                 |
| Use case       | Validation, enrichment   | Side effects, notifications   |
| Frequency      | Rare                     | Common (most events are post) |
| Failure impact | Operation never executes | Operation rolls back          |

Use **pre-events** sparingly for cross-module validation. Use **post-events** for most scenarios.

## Key Points

- Events are transactional: failure in any handler rolls back the entire operation.
- Use `notifyPostBusinessEvent` for most cases (entity already persisted).
- Events provide decoupling between modules without circular dependencies.
- External events enable CDC-like patterns for downstream systems.
- Category groups related events; type uniquely identifies the event.

## Generator

```bash
python3 scripts/generate_business_event.py \
  --entity-name SavingsProduct \
  --package org.apache.fineract.portfolio.savingsproduct \
  --events "Created,Updated,Deleted" \
  --output-dir ./output
```

## Checklist

### Event Definition

- [ ] Event implements `BusinessEvent<T>` where T is the domain entity
- [ ] `getType()` returns unique event type string matching class name
- [ ] `getCategory()` returns entity category name
- [ ] `getAggregateRootId()` returns the entity's ID (never null after save)
- [ ] Event class is in the module's `event/` or `domain/` sub-package

### Event Publishing

- [ ] Event published within `@Transactional` boundary
- [ ] `notifyPostBusinessEvent()` used for most events
- [ ] `notifyPreBusinessEvent()` used only when pre-validation needed
- [ ] Event published AFTER entity save (for post-events)
- [ ] No long-running operations in event listeners

### External Events (Avro)

- [ ] Avro schema defined in `fineract-avro-schemas`
- [ ] Schema fields match event data contract
- [ ] Nullable fields use Avro union types `["null", "type"]`
- [ ] Money amounts serialized as string (not float/double)

### Failure Handling

- [ ] Listener failures understood to roll back entire transaction
- [ ] Long-running side effects use outbox pattern, not direct calls
- [ ] No external API calls inside event listeners
