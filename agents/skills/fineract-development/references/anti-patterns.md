# Anti-Patterns & Failure Modes

## Purpose

**THIS IS YOUR GUARDRAIL SYSTEM.** Consult this skill BEFORE generating any Fineract code. It encodes the most common mistakes that AI agents make when generating code for a core banking platform.

Violation of these rules can cause: data corruption, financial loss, audit trail gaps, security breaches, and regulatory non-compliance.

## Anti-Pattern Detection Rules

### AP-01: Business Logic in Controllers

**Detection:** Code in `ApiResource` class that does more than build `CommandWrapper` or call a service.

```java
// ❌ WRONG: Business logic in API resource
@POST
public String create(String json) {
    JsonElement element = fromJsonHelper.parse(json);
    String name = fromJsonHelper.extractStringNamed("name", element);
    if (name.length() > 100) {  // BUSINESS LOGIC IN CONTROLLER
        throw new ValidationException("Name too long");
    }
    SavingsProduct product = new SavingsProduct(name);
    repository.save(product);  // DIRECT REPO ACCESS IN CONTROLLER
    return toJson(product);
}

// ✅ CORRECT: Controller only routes to command framework
@POST
public String create(String apiRequestBodyAsJson) {
    final CommandWrapper commandRequest = new CommandWrapperBuilder()
        .createSavingsProduct()
        .withJson(apiRequestBodyAsJson)
        .build();
    final CommandProcessingResult result =
        commandsSourceWritePlatformService.logCommandSource(commandRequest);
    return toApiJsonSerializer.serialize(result);
}
```

**Impact:** Breaks audit trail, bypasses maker-checker, bypasses permission checks.

---

### AP-02: Direct Repository Access in Command Handlers

**Detection:** Handler calls repository directly instead of delegating to write service.

```java
// ❌ WRONG: Handler with business logic and repo access
@Override
public CommandProcessingResult processCommand(JsonCommand command) {
    SavingsProduct product = SavingsProduct.fromJson(command);
    repository.save(product);  // DIRECT REPO — NO VALIDATION, NO EVENTS
    return new CommandProcessingResultBuilder()
        .withEntityId(product.getId()).build();
}

// ✅ CORRECT: Handler delegates to service
@Override
public CommandProcessingResult processCommand(JsonCommand command) {
    return writePlatformService.create(command);
}
```

**Impact:** Skips validation, skips business events, skips data integrity handling.

---

### AP-03: Missing Command Logging

**Detection:** Write operation that doesn't go through `logCommandSource()`.

```java
// ❌ WRONG: Direct service call from API (bypasses command framework)
@POST
public String create(String json) {
    JsonCommand command = new JsonCommand(...);
    CommandProcessingResult result = writePlatformService.create(command);
    return toJson(result);
}

// ✅ CORRECT: Through command framework
@POST
public String create(String json) {
    final CommandWrapper commandRequest = new CommandWrapperBuilder()
        .createSavingsProduct().withJson(json).build();
    return toJson(commandsSourceWritePlatformService.logCommandSource(commandRequest));
}
```

**Impact:** No audit trail, no maker-checker, no permission check.

---

### AP-04: Balance Mutations Outside Transaction Processors

**Detection:** Code that directly creates journal entries or modifies account balances outside the designated transaction processor.

```java
// ❌ WRONG: Direct journal entry creation in service
public void disburseLoan(Long loanId) {
    Loan loan = loanRepository.findById(loanId);
    loan.disburse();
    // Creating journal entries directly — DANGEROUS
    JournalEntry debit = new JournalEntry(loanPortfolioAccount, amount, JournalEntryType.DEBIT);
    JournalEntry credit = new JournalEntry(fundSourceAccount, amount, JournalEntryType.CREDIT);
    journalEntryRepository.save(debit);
    journalEntryRepository.save(credit);
}

// ✅ CORRECT: Through accounting processor
public void disburseLoan(Long loanId) {
    Loan loan = loanRepository.findById(loanId);
    loan.disburse();
    loanRepository.save(loan);
    // Accounting processor handles journal entries
    accountingProcessorHelper.createAccountingEntriesForLoan(loanDTO, transactions);
}
```

**Impact:** Unbalanced ledger, missing entries, incorrect GL mappings.

---

### AP-05: EAGER Fetching in JPA Relations

**Detection:** `@ManyToOne`, `@OneToMany`, `@ManyToMany` without explicit `FetchType.LAZY`.

```java
// ❌ WRONG: Defaults to EAGER or explicitly set
@ManyToOne  // Defaults to EAGER for @ManyToOne!
@JoinColumn(name = "office_id")
private Office office;

@OneToMany(fetch = FetchType.EAGER)  // Explicit EAGER
private Set<SavingsProductCharge> charges;

// ✅ CORRECT: Always LAZY
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "office_id")
private Office office;

@OneToMany(mappedBy = "product", fetch = FetchType.LAZY)
private Set<SavingsProductCharge> charges;
```

**Impact:** N+1 queries, massive performance degradation, out-of-memory on large datasets.

---

### AP-06: Returning JPA Entities from APIs

**Detection:** API resource returns entity class instead of Data DTO.

```java
// ❌ WRONG: Returning entity
@GET
public SavingsProduct getProduct(@PathParam("id") Long id) {
    return repository.findById(id).orElseThrow();
}

// ✅ CORRECT: Return DTO
@GET
public String retrieveOne(@PathParam("id") Long id, @Context UriInfo uriInfo) {
    SavingsProductData data = readPlatformService.retrieveOne(id);
    return toApiJsonSerializer.serialize(settings, data);
}
```

**Impact:** Exposes internal structure, triggers lazy loading in serialization, security risk.

---

### AP-07: Missing @Transactional on Write Services

**Detection:** Write service method without `@Transactional`.

```java
// ❌ WRONG: No @Transactional
@Override
public CommandProcessingResult create(JsonCommand command) {
    // Save may not commit if no transaction context!
    repository.saveAndFlush(product);
    return result;
}

// ✅ CORRECT
@Override
@Transactional
public CommandProcessingResult create(JsonCommand command) {
    repository.saveAndFlush(product);
    return result;
}
```

**Impact:** Changes silently not committed, events not transactional.

---

### AP-08: Missing Liquibase Migration

**Detection:** New entity or field added without corresponding Liquibase changelog.

**Impact:** Schema mismatch on deployment, application fails to start.

---

### AP-09: Hardcoded Tenant Reference

**Detection:** String literal tenant IDs or manual tenant context setting.

```java
// ❌ WRONG
ThreadLocalContextUtil.setTenant(tenantService.findById("default"));

// ✅ CORRECT: Let the platform filter handle it
// (Don't set tenant context in application code)
```

---

### AP-10: Using equals() for BigDecimal Comparison

**Detection:** `BigDecimal.equals()` comparison.

```java
// ❌ WRONG: equals() checks scale (1.0 != 1.00)
if (amount.equals(BigDecimal.ZERO)) { }

// ✅ CORRECT: compareTo() ignores scale
if (amount.compareTo(BigDecimal.ZERO) == 0) { }
```

**Impact:** Financial calculations fail silently.

---

### AP-11: Catching Exceptions Too Broadly

**Detection:** `catch (Exception e)` that swallows domain exceptions.

```java
// ❌ WRONG: Swallows all exceptions
try {
    repository.saveAndFlush(product);
} catch (Exception e) {
    log.error("Error", e);
    // Swallowed — client gets no useful error
}

// ✅ CORRECT: Catch specific exceptions
try {
    repository.saveAndFlush(product);
} catch (DataIntegrityViolationException e) {
    handleDataIntegrityIssues(command, e);
}
```

---

### AP-12: Missing Security Check

**Detection:** Service method that doesn't call `context.authenticatedUser()`.

---

### AP-13: Field Injection Instead of Constructor Injection

**Detection:** `@Autowired` on fields instead of constructor parameters.

```java
// ❌ WRONG
@Autowired
private SavingsProductRepository repository;

// ✅ CORRECT
@RequiredArgsConstructor
public class ServiceImpl {
    private final SavingsProductRepository repository;
}
```

---

## Pre-Generation Checklist

**Before writing ANY Fineract code, verify:**

1. [ ] Write operations go through CommandWrapper + logCommandSource
2. [ ] Handlers delegate to services (no business logic)
3. [ ] Services use RepositoryWrapper (not raw repository)
4. [ ] All JPA relations are LAZY
5. [ ] Write methods have @Transactional
6. [ ] Business events published for significant operations
7. [ ] Liquibase migration created for schema changes
8. [ ] Permissions seeded for new entities
9. [ ] Exceptions extend Fineract hierarchy
10. [ ] Financial operations go through accounting processors
11. [ ] context.authenticatedUser() called in service methods
12. [ ] Read services return DTOs, not entities
13. [ ] BigDecimal uses compareTo(), not equals()
14. [ ] Constructor injection used (not field @Autowired)
15. [ ] Data integrity exceptions caught and mapped

## Severity Classification

| Anti-Pattern                                | Severity | Impact               |
| ------------------------------------------- | -------- | -------------------- |
| AP-04: Balance mutations outside processors | CRITICAL | Financial corruption |
| AP-03: Missing command logging              | CRITICAL | Audit trail gap      |
| AP-01: Business logic in controllers        | HIGH     | Security bypass      |
| AP-02: Direct repo in handlers              | HIGH     | Validation bypass    |
| AP-07: Missing @Transactional               | HIGH     | Data loss            |
| AP-05: EAGER fetching                       | MEDIUM   | Performance          |
| AP-06: Returning entities from API          | MEDIUM   | Security risk        |
| AP-10: BigDecimal equals()                  | MEDIUM   | Financial error      |
| AP-08: Missing migration                    | MEDIUM   | Deployment failure   |
| AP-09: Hardcoded tenant                     | MEDIUM   | Multi-tenancy breach |
| AP-11: Broad exception catch                | LOW      | Poor error handling  |
| AP-12: Missing security check               | LOW      | Access control gap   |
| AP-13: Field injection                      | LOW      | Testability          |

## Checklist

Run this checklist against ALL generated code before committing.

### CRITICAL (Financial Safety)

- [ ] No direct writes to m_journal_entry (use accounting processor)
- [ ] No balance mutations outside transaction processors
- [ ] All financial operations create balanced journal entries
- [ ] No journal entry deletions (use reversal only)

### HIGH (Audit & Security)

- [ ] All write operations go through CommandWrapper + logCommandSource()
- [ ] No business logic in ApiResource classes
- [ ] No direct repository access in command handlers
- [ ] Write services annotated with @Transactional
- [ ] context.authenticatedUser() called in service methods

### MEDIUM (Correctness)

- [ ] All JPA relations use FetchType.LAZY
- [ ] APIs return Data DTOs, never JPA entities
- [ ] BigDecimal compared with compareTo(), not equals()
- [ ] Liquibase migration created for every schema change
- [ ] No hardcoded tenant identifiers
- [ ] DataIntegrityViolationException caught and mapped

### LOW (Quality)

- [ ] Constructor injection used (no field @Autowired)
- [ ] No broad catch(Exception) swallowing errors
- [ ] Exceptions extend Fineract's hierarchy
- [ ] Permissions seeded in Liquibase for new entities
