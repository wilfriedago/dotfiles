# Entity & Repository Engineering

## Purpose

This skill teaches how to create JPA entities, repositories, and repository wrappers following Fineract conventions, including base class inheritance, auditing fields, tenant awareness, and proper relationship mappings.

## Entity Base Classes

### AbstractPersistableCustom<Long>

All Fineract entities extend this class:

```java
@MappedSuperclass
public abstract class AbstractPersistableCustom<PK extends Serializable>
        implements Persistable<PK> {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private PK id;

    // getId(), isNew(), equals(), hashCode()
}
```

This provides:

- Auto-generated `id` field (BIGINT in DB)
- JPA lifecycle management
- Equals/hashCode based on ID

### AbstractAuditableWithUTCDateTimeCustom

For entities needing audit fields:

```java
@MappedSuperclass
public abstract class AbstractAuditableWithUTCDateTimeCustom
        extends AbstractPersistableCustom<Long> {

    @Column(name = "created_by")
    private Long createdBy;

    @Column(name = "created_on_utc")
    private OffsetDateTime createdDate;

    @Column(name = "last_modified_by")
    private Long lastModifiedBy;

    @Column(name = "last_modified_on_utc")
    private OffsetDateTime lastModifiedDate;
}
```

Use this base class when you need audit trail fields (who created/modified and when).

## Entity Conventions

### Complete Entity Example

```java
package org.apache.fineract.portfolio.savingsproduct.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;
import org.apache.fineract.infrastructure.core.api.JsonCommand;
import org.apache.fineract.infrastructure.core.domain.AbstractPersistableCustom;
import org.apache.fineract.organisation.monetary.domain.MonetaryCurrency;

@Entity
@Table(name = "m_savings_product")
public class SavingsProduct extends AbstractPersistableCustom<Long> {

    @Column(name = "name", length = 100, nullable = false, unique = true)
    private String name;

    @Column(name = "description", length = 500)
    private String description;

    @Column(name = "nominal_annual_interest_rate", precision = 19, scale = 6, nullable = false)
    private BigDecimal nominalAnnualInterestRate;

    @Column(name = "active", nullable = false)
    private boolean active;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "currency_id")
    private MonetaryCurrency currency;

    // Protected no-arg constructor for JPA
    protected SavingsProduct() {}

    // All-args constructor for programmatic creation
    public SavingsProduct(String name, String description,
            BigDecimal nominalAnnualInterestRate, boolean active) {
        this.name = name;
        this.description = description;
        this.nominalAnnualInterestRate = nominalAnnualInterestRate;
        this.active = active;
    }

    // Factory method from JSON command
    public static SavingsProduct fromJson(JsonCommand command) {
        final String name = command.stringValueOfParameterNamed("name");
        final String description = command.stringValueOfParameterNamed("description");
        final BigDecimal rate = command.bigDecimalValueOfParameterNamed("nominalAnnualInterestRate");
        final boolean active = command.booleanPrimitiveValueOfParameterNamed("active");
        return new SavingsProduct(name, description, rate, active);
    }

    // Update method returning changes map for audit
    public Map<String, Object> update(JsonCommand command) {
        final Map<String, Object> actualChanges = new LinkedHashMap<>();

        if (command.isChangeInStringParameterNamed("name", this.name)) {
            final String newValue = command.stringValueOfParameterNamed("name");
            actualChanges.put("name", newValue);
            this.name = newValue;
        }

        if (command.isChangeInBigDecimalParameterNamed(
                "nominalAnnualInterestRate", this.nominalAnnualInterestRate)) {
            final BigDecimal newValue = command.bigDecimalValueOfParameterNamed(
                "nominalAnnualInterestRate");
            actualChanges.put("nominalAnnualInterestRate", newValue);
            this.nominalAnnualInterestRate = newValue;
        }

        if (command.isChangeInBooleanParameterNamed("active", this.active)) {
            final boolean newValue = command.booleanPrimitiveValueOfParameterNamed("active");
            actualChanges.put("active", newValue);
            this.active = newValue;
        }

        return actualChanges;
    }

    // Domain logic belongs in the entity
    public void activate() {
        if (this.active) {
            throw new PlatformApiDataValidationException(/* already active */);
        }
        this.active = true;
    }

    // Getters (no setters — mutations via methods only)
    public String getName() { return name; }
    public String getDescription() { return description; }
    public BigDecimal getNominalAnnualInterestRate() { return nominalAnnualInterestRate; }
    public boolean isActive() { return active; }
}
```

### Key Rules

1. **Table naming:** `m_<snake_case>` prefix for all main tables
2. **Column naming:** Explicit `@Column(name = "snake_case")` on every field
3. **No-arg constructor:** `protected` for JPA
4. **Relations:** Always `FetchType.LAZY` — NEVER EAGER
5. **Domain logic in entity:** Validation, state transitions, business rules
6. **No setters:** Use `update(JsonCommand)` or domain methods
7. **Money fields:** `precision = 19, scale = 6` for `BigDecimal`
8. **fromJson factory:** Static method to construct from `JsonCommand`
9. **update method:** Returns `Map<String, Object>` of actual changes for audit

## Repository Pattern

### Spring Data Repository

```java
@Repository
public interface SavingsProductRepository
        extends JpaRepository<SavingsProduct, Long>,
                JpaSpecificationExecutor<SavingsProduct> {

    Optional<SavingsProduct> findByName(String name);

    @Query("SELECT sp FROM SavingsProduct sp WHERE sp.active = true")
    List<SavingsProduct> findAllActive();
}
```

### Repository Wrapper (Required)

Fineract wraps repositories for null-check + exception throwing:

```java
@Component
@RequiredArgsConstructor
public class SavingsProductRepositoryWrapper {

    private final SavingsProductRepository repository;

    public SavingsProduct findOneWithNotFoundDetection(final Long id) {
        return repository.findById(id)
            .orElseThrow(() -> new SavingsProductNotFoundException(id));
    }

    public void saveAndFlush(final SavingsProduct entity) {
        repository.saveAndFlush(entity);
    }

    public void save(final SavingsProduct entity) {
        repository.save(entity);
    }

    public void delete(final SavingsProduct entity) {
        repository.delete(entity);
    }

    public boolean existsById(final Long id) {
        return repository.existsById(id);
    }
}
```

**Always use the wrapper in services, not the raw repository.** This ensures consistent `NotFoundException` handling.

## Relationship Mappings

### ManyToOne (Most Common)

```java
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "office_id", nullable = false)
private Office office;
```

### OneToMany

```java
@OneToMany(mappedBy = "savingsProduct", fetch = FetchType.LAZY,
           cascade = CascadeType.ALL, orphanRemoval = true)
private Set<SavingsProductCharge> charges = new HashSet<>();
```

### ManyToMany (Rare)

```java
@ManyToMany(fetch = FetchType.LAZY)
@JoinTable(name = "m_savings_product_charge",
    joinColumns = @JoinColumn(name = "savings_product_id"),
    inverseJoinColumns = @JoinColumn(name = "charge_id"))
private Set<Charge> charges = new HashSet<>();
```

## Auditing Fields

For entities needing creation/modification tracking:

```sql
-- In Liquibase migration
<column name="created_by" type="BIGINT"/>
<column name="created_on_utc" type="DATETIME"/>
<column name="last_modified_by" type="BIGINT"/>
<column name="last_modified_on_utc" type="DATETIME"/>
```

Extend `AbstractAuditableWithUTCDateTimeCustom` instead of `AbstractPersistableCustom`.

## Decision Framework

### Which Base Class?

| Need                  | Base Class                               |
| --------------------- | ---------------------------------------- |
| Simple entity with ID | `AbstractPersistableCustom<Long>`        |
| Entity + audit trail  | `AbstractAuditableWithUTCDateTimeCustom` |
| Value object (no ID)  | `@Embeddable` class                      |

### When to Use Repository Wrapper vs Raw Repository

| Context                       | Use                          |
| ----------------------------- | ---------------------------- |
| Write services                | Always RepositoryWrapper     |
| Read services (single lookup) | RepositoryWrapper            |
| Read services (list/search)   | JdbcTemplate + RowMapper     |
| Scheduled jobs                | RepositoryWrapper            |
| Tests                         | Raw Repository is acceptable |

## Generator

```bash
python3 scripts/generate_entity.py \
  --entity-name SavingsProduct \
  --package org.apache.fineract.portfolio.savingsproduct \
  --fields "name:String,description:String,nominalAnnualInterestRate:BigDecimal,active:boolean" \
  --output-dir ./output
```

Generates: `domain/SavingsProduct.java`, `domain/SavingsProductRepository.java`,
`domain/SavingsProductRepositoryWrapper.java`.

Generates: Entity, Repository, RepositoryWrapper.

## Checklist

### Entity

- [ ] Extends `AbstractPersistableCustom<Long>` or `AbstractAuditableWithUTCDateTimeCustom`
- [ ] `@Table(name = "m_<snake_case>")` annotation present
- [ ] All fields have `@Column(name = "snake_case")` with explicit names
- [ ] Protected no-arg constructor for JPA
- [ ] All `@ManyToOne` / `@OneToMany` use `FetchType.LAZY`
- [ ] `@JoinColumn(name = "xxx_id")` explicit on relationships
- [ ] `BigDecimal` fields have `precision = 19, scale = 6`
- [ ] Static `fromJson(JsonCommand)` factory method
- [ ] `update(JsonCommand)` method returns `Map<String, Object>` of changes
- [ ] Domain logic in entity methods, not in services
- [ ] No public setters — mutation via domain methods only
- [ ] `BigDecimal` compared with `compareTo()`, never `equals()`

### Repository

- [ ] Annotated with `@Repository`
- [ ] Extends `JpaRepository<Entity, Long>` and `JpaSpecificationExecutor<Entity>`
- [ ] Custom query methods use `Optional<>` return type

### Repository Wrapper

- [ ] Annotated with `@Component`
- [ ] Constructor injection of repository
- [ ] `findOneWithNotFoundDetection(Long id)` throws domain NotFoundException
- [ ] `saveAndFlush()`, `save()`, `delete()` methods present
- [ ] Used in all write services instead of raw repository

## ExternalId Pattern

Fineract entities can have a business-facing **ExternalId** (UUID) alongside the database ID. This allows external systems to reference entities by a stable identifier that doesn't depend on database sequence numbers.

### ExternalId Value Object

```java
// Immutable wrapper around a String UUID
ExternalId externalId = ExternalIdFactory.generate();  // Generates new UUID
ExternalId externalId = new ExternalId("550e8400-e29b-41d4-a716-446655440000");
```

### Entity Field Mapping

```java
@Entity
@Table(name = "m_loan")
public class Loan extends AbstractPersistableCustom<Long> {

    @Column(name = "external_id", length = 100, unique = true)
    private ExternalId externalId;

    // ...
}
```

### API Lookup by ExternalId

API resources support lookup by both database ID and external ID:

```java
@GET
@Path("external-id/{externalId}")
public String retrieveByExternalId(
        @PathParam("externalId") final String externalId) {
    // Resolve entity by external ID
}
```

### When to Use

- Add `ExternalId` to any entity that external systems (other microservices, frontends, integrations) need to reference
- Use `ExternalIdFactory.generate()` in `fromJson()` or assembler when creating new entities
- Always store as `VARCHAR(100)` with a unique constraint in the migration
