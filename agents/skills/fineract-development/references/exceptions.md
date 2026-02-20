# Exception & Error Taxonomy

## Purpose

This skill defines the exception hierarchy in Fineract, including domain vs platform exceptions, HTTP status code mappings, error code conventions, and localization support.

## Exception Hierarchy

```
RuntimeException
└── AbstractPlatformException (base for all Fineract exceptions)
    ├── AbstractPlatformResourceNotFoundException     → HTTP 404
    ├── AbstractPlatformDomainRuleException           → HTTP 403
    ├── PlatformApiDataValidationException            → HTTP 400
    ├── PlatformDataIntegrityException                → HTTP 409
    ├── AbstractPlatformServiceUnavailableException   → HTTP 503
    └── UnsupportedCommandException                   → HTTP 400
```

## Exception Types

### Not Found (404)

When a requested resource doesn't exist:

```java
public class SavingsProductNotFoundException
        extends AbstractPlatformResourceNotFoundException {

    public SavingsProductNotFoundException(Long id) {
        super("error.msg.savings.product.not.found",
              "Savings product with identifier " + id + " does not exist",
              id);
    }
}
```

**Use when:** Entity lookup by ID returns empty, invalid reference IDs.

### Domain Rule Violation (403)

When a business rule prevents the operation:

```java
public class SavingsProductCannotBeDeletedException
        extends AbstractPlatformDomainRuleException {

    public SavingsProductCannotBeDeletedException(Long id, String reason) {
        super("error.msg.savings.product.cannot.be.deleted",
              "Savings product " + id + " cannot be deleted: " + reason,
              id, reason);
    }
}
```

**Use when:** Entity in wrong state for operation, business constraint violated.

### Validation Error (400)

When input data fails validation:

```java
// Typically thrown by DataValidator, not manually constructed
throw new PlatformApiDataValidationException(errors);
// where errors is List<ApiParameterError>
```

**Use when:** Missing required fields, invalid formats, out-of-range values.

### Data Integrity (409)

When a database constraint is violated:

```java
throw new PlatformDataIntegrityException(
    "error.msg.savings.product.duplicate.name",
    "Product name '" + name + "' already exists",
    "name", name);
```

**Use when:** Unique constraint violation, FK constraint violation.

## Error Code Convention

```
error.msg.<module>.<entity>.<condition>
```

Examples:

- `error.msg.savings.product.not.found`
- `error.msg.savings.product.cannot.be.deleted`
- `error.msg.savings.product.duplicate.name`
- `error.msg.loan.account.not.in.approved.state`

## Error Response Format

The platform translates exceptions to JSON:

```json
{
  "developerMessage": "Savings product with identifier 42 does not exist",
  "httpStatusCode": "404",
  "defaultUserMessage": "Savings product with identifier 42 does not exist",
  "userMessageGlobalisationCode": "error.msg.savings.product.not.found",
  "errors": []
}
```

For validation errors:

```json
{
  "developerMessage": "Validation errors exist.",
  "httpStatusCode": "400",
  "defaultUserMessage": "Validation errors exist.",
  "userMessageGlobalisationCode": "validation.msg.validation.errors.exist",
  "errors": [
    {
      "developerMessage": "The parameter name is mandatory.",
      "defaultUserMessage": "The parameter name is mandatory.",
      "userMessageGlobalisationCode": "validation.msg.savings.product.name.cannot.be.blank",
      "parameterName": "name"
    }
  ]
}
```

## Data Integrity Handling Pattern

In write services, catch `DataIntegrityViolationException` and map to domain-specific errors:

```java
private void handleDataIntegrityIssues(JsonCommand command,
        DataIntegrityViolationException e) {
    Throwable cause = e.getMostSpecificCause();
    String message = cause.getMessage();

    if (message.contains("m_savings_product_name_unique")) {
        String name = command.stringValueOfParameterNamed("name");
        throw new PlatformDataIntegrityException(
            "error.msg.savings.product.duplicate.name",
            "Product name '" + name + "' already exists", "name", name);
    }

    // Fallback for unknown constraints
    log.error("Unknown data integrity issue: {}", message, e);
    throw new PlatformDataIntegrityException(
        "error.msg.savings.product.unknown.data.integrity.issue",
        "Unknown data integrity issue with savings product");
}
```

## Decision Framework

### Which Exception Type to Use

| Scenario                       | Exception                                     | HTTP |
| ------------------------------ | --------------------------------------------- | ---- |
| Entity not found by ID         | `AbstractPlatformResourceNotFoundException`   | 404  |
| Entity in wrong state          | `AbstractPlatformDomainRuleException`         | 403  |
| Invalid input data             | `PlatformApiDataValidationException`          | 400  |
| Duplicate/constraint violation | `PlatformDataIntegrityException`              | 409  |
| External service unavailable   | `AbstractPlatformServiceUnavailableException` | 503  |
| Unknown command                | `UnsupportedCommandException`                 | 400  |

## Generator

```bash
python3 scripts/generate_exceptions.py \
  --entity-name SavingsProduct \
  --package org.apache.fineract.portfolio.savingsproduct \
  --output-dir ./output
```

### Exception Anti-Patterns

- **NEVER** catch `Exception` broadly — let Fineract's handler translate
- **NEVER** return HTTP status codes manually — throw the correct exception
- **NEVER** use `RuntimeException` directly — extend Fineract's hierarchy
- **NEVER** swallow exceptions silently — always log or re-throw

## Checklist

- [ ] All exceptions extend Fineract's `AbstractPlatformException` hierarchy
- [ ] NotFoundException extends `AbstractPlatformResourceNotFoundException`
- [ ] Business rule violations extend `AbstractPlatformDomainRuleException`
- [ ] Error codes follow `error.msg.<module>.<entity>.<condition>` format
- [ ] Default messages are human-readable and include relevant IDs
- [ ] DataIntegrityViolationException caught in write services and mapped to domain errors
- [ ] Constraint names in DB match what's checked in handleDataIntegrityIssues
- [ ] No broad Exception catches that swallow errors
- [ ] No manual HTTP status code returns
- [ ] Unknown data integrity issues logged with error level
