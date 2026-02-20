# Liquibase & Schema Evolution

## Purpose

This skill teaches database schema management in Fineract using Liquibase, including changelog naming, rollback strategies, index optimization, and permission seeding.

## Changelog Location

```
fineract-provider/src/main/resources/db/changelog/tenant/parts/
```

All schema changes for tenant databases go here. There is a separate `initial/` folder for first-time setup.

## Naming Convention

```
XXXX__<description>.xml
```

Where `XXXX` is a sequential four-digit number. Examples:

- `0001__create_m_savings_product.xml`
- `0002__add_currency_to_savings_product.xml`
- `0003__create_m_savings_product_charge.xml`

## ChangeSet ID Convention

```xml
<changeSet author="developer" id="XXXX-1">
    <!-- First change in this file -->
</changeSet>
<changeSet author="developer" id="XXXX-2">
    <!-- Second change in this file -->
</changeSet>
```

## Complete Migration Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.3.xsd">

    <!-- 1. Create Table -->
    <changeSet author="developer" id="1">
        <createTable tableName="m_savings_product">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true" nullable="false"/>
            </column>
            <column name="name" type="VARCHAR(100)">
                <constraints nullable="false" unique="true"
                    uniqueConstraintName="m_savings_product_name_unique"/>
            </column>
            <column name="description" type="VARCHAR(500)">
                <constraints nullable="true"/>
            </column>
            <column name="nominal_annual_interest_rate" type="DECIMAL(19,6)">
                <constraints nullable="false"/>
            </column>
            <column name="min_required_balance" type="DECIMAL(19,6)">
                <constraints nullable="true"/>
            </column>
            <column name="currency_id" type="BIGINT">
                <constraints nullable="false"/>
            </column>
            <column name="active" type="TINYINT(1)" defaultValueNumeric="0">
                <constraints nullable="false"/>
            </column>
            <!-- Audit fields -->
            <column name="created_by" type="BIGINT"/>
            <column name="created_on_utc" type="DATETIME"/>
            <column name="last_modified_by" type="BIGINT"/>
            <column name="last_modified_on_utc" type="DATETIME"/>
        </createTable>

        <!-- Rollback -->
        <rollback>
            <dropTable tableName="m_savings_product"/>
        </rollback>
    </changeSet>

    <!-- 2. Foreign Keys -->
    <changeSet author="developer" id="2">
        <addForeignKeyConstraint
            baseTableName="m_savings_product"
            baseColumnNames="currency_id"
            referencedTableName="m_currency"
            referencedColumnNames="id"
            constraintName="fk_savings_product_currency"/>

        <rollback>
            <dropForeignKeyConstraint
                baseTableName="m_savings_product"
                constraintName="fk_savings_product_currency"/>
        </rollback>
    </changeSet>

    <!-- 3. Indexes -->
    <changeSet author="developer" id="3">
        <createIndex tableName="m_savings_product"
                     indexName="idx_savings_product_active">
            <column name="active"/>
        </createIndex>

        <rollback>
            <dropIndex tableName="m_savings_product"
                       indexName="idx_savings_product_active"/>
        </rollback>
    </changeSet>

    <!-- 4. Permissions -->
    <changeSet author="developer" id="4">
        <insert tableName="m_permission">
            <column name="grouping" value="portfolio"/>
            <column name="code" value="CREATE_SAVINGSPRODUCT"/>
            <column name="entity_name" value="SAVINGSPRODUCT"/>
            <column name="action_name" value="CREATE"/>
            <column name="can_maker_checker" valueBoolean="false"/>
        </insert>
        <insert tableName="m_permission">
            <column name="grouping" value="portfolio"/>
            <column name="code" value="READ_SAVINGSPRODUCT"/>
            <column name="entity_name" value="SAVINGSPRODUCT"/>
            <column name="action_name" value="READ"/>
            <column name="can_maker_checker" valueBoolean="false"/>
        </insert>
        <insert tableName="m_permission">
            <column name="grouping" value="portfolio"/>
            <column name="code" value="UPDATE_SAVINGSPRODUCT"/>
            <column name="entity_name" value="SAVINGSPRODUCT"/>
            <column name="action_name" value="UPDATE"/>
            <column name="can_maker_checker" valueBoolean="false"/>
        </insert>
        <insert tableName="m_permission">
            <column name="grouping" value="portfolio"/>
            <column name="code" value="DELETE_SAVINGSPRODUCT"/>
            <column name="entity_name" value="SAVINGSPRODUCT"/>
            <column name="action_name" value="DELETE"/>
            <column name="can_maker_checker" valueBoolean="false"/>
        </insert>

        <rollback>
            <delete tableName="m_permission">
                <where>entity_name = 'SAVINGSPRODUCT'</where>
            </delete>
        </rollback>
    </changeSet>
</databaseChangeLog>
```

## Type Mappings

| Java Type        | Liquibase Type  | Notes                               |
| ---------------- | --------------- | ----------------------------------- |
| `Long` (PK)      | `BIGINT`        | autoIncrement, primaryKey           |
| `String`         | `VARCHAR(n)`    | Specify max length                  |
| `BigDecimal`     | `DECIMAL(19,6)` | Money: 19 digits, 6 decimal places  |
| `LocalDate`      | `DATE`          |                                     |
| `LocalDateTime`  | `DATETIME`      |                                     |
| `OffsetDateTime` | `DATETIME`      | For UTC timestamps                  |
| `boolean`        | `TINYINT(1)`    | defaultValueNumeric="0"             |
| `Integer`        | `INT`           |                                     |
| `int`            | `INT`           |                                     |
| FK reference     | `BIGINT`        | Add foreignKeyConstraint separately |
| Enum (ordinal)   | `SMALLINT`      | Store as integer                    |
| Text blob        | `TEXT`          | For long text content               |

## Rollback Strategies

**Every changeSet MUST have a `<rollback>` block.**

| Operation                 | Rollback                   |
| ------------------------- | -------------------------- |
| `createTable`             | `dropTable`                |
| `addColumn`               | `dropColumn`               |
| `addForeignKeyConstraint` | `dropForeignKeyConstraint` |
| `createIndex`             | `dropIndex`                |
| `insert` (permission)     | `delete` with WHERE clause |
| `addUniqueConstraint`     | `dropUniqueConstraint`     |

## Index Optimization Rules

1. Index columns used in WHERE clauses of read service queries
2. Index foreign key columns (MySQL does this automatically, PostgreSQL doesn't)
3. Use composite indexes for multi-column queries: `(status, created_date)`
4. Don't over-index — each index slows writes
5. Name indexes: `idx_<table>_<columns>` (e.g., `idx_savings_product_active`)

## Decision Framework

### When to Create a New Changelog File vs Add to Existing

**New file** when:

- New table creation
- New module being added
- Unrelated schema change

**Same file** when:

- FK constraints for the table just created
- Indexes for the table just created
- Permissions for the same entity

### Constraint Naming

| Constraint  | Format                    | Example                         |
| ----------- | ------------------------- | ------------------------------- |
| Primary key | `pk_<table>`              | `pk_m_savings_product`          |
| Unique      | `<table>_<column>_unique` | `m_savings_product_name_unique` |
| Foreign key | `fk_<table>_<referenced>` | `fk_savings_product_currency`   |
| Index       | `idx_<table>_<columns>`   | `idx_savings_product_active`    |

## Generator

```bash
python3 scripts/generate_liquibase.py \
  --entity-name SavingsProduct \
  --table-name m_savings_product \
  --fields "name:String:100,description:String:500,nominalAnnualInterestRate:BigDecimal,active:boolean" \
  --author developer \
  --output-dir ./output
```

# Checklist

- [ ] Changelog placed in `db/changelog/tenant/parts/`
- [ ] File named `XXXX__<description>.xml` with sequential number
- [ ] ChangeSet IDs are unique and sequential within file
- [ ] Table name uses `m_` prefix with snake_case
- [ ] Column names are snake_case
- [ ] Primary key: `BIGINT` with `autoIncrement="true"`
- [ ] Money fields: `DECIMAL(19,6)`
- [ ] Boolean fields: `TINYINT(1)` with `defaultValueNumeric="0"`
- [ ] String fields have explicit length: `VARCHAR(n)`
- [ ] Audit columns included: `created_by`, `created_on_utc`, `last_modified_by`, `last_modified_on_utc`
- [ ] Foreign keys added as separate changeSets with constraint names
- [ ] Every changeSet has a `<rollback>` block
- [ ] Indexes added for frequently queried columns
- [ ] Permissions inserted for CREATE, READ, UPDATE, DELETE
- [ ] Permission entity_name is UPPERCASE without separators
- [ ] `can_maker_checker` set appropriately
- [ ] Constraint names follow conventions (`fk_`, `idx_`, `_unique`)
- [ ] No `DROP TABLE` without data migration plan
