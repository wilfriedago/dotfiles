# Data, Serialization & Validation

## Purpose

This skill teaches how to create Data Transfer Objects (DTOs), JSON serializers/deserializers, and validators following Fineract's conventions.

## Data DTO Pattern

DTOs are immutable value objects that carry data between layers:

```java
public final class SavingsProductData {

    private final Long id;
    private final String name;
    private final String description;
    private final BigDecimal nominalAnnualInterestRate;
    private final boolean active;

    // Optional: template/dropdown data
    private final Collection<CurrencyData> currencyOptions;

    public SavingsProductData(Long id, String name, String description,
            BigDecimal nominalAnnualInterestRate, boolean active) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.nominalAnnualInterestRate = nominalAnnualInterestRate;
        this.active = active;
        this.currencyOptions = null;
    }

    // Template constructor (for "new" form with dropdown options)
    public static SavingsProductData template(
            Collection<CurrencyData> currencyOptions) {
        return new SavingsProductData(null, null, null, null, false,
            currencyOptions);
    }

    // Getters only — no setters
    public Long getId() { return id; }
    public String getName() { return name; }
    // ...
}
```

### Key Rules

1. DTOs are **immutable**: all fields `final`, no setters
2. Constructor takes all fields
3. `template()` static method for dropdown/form data
4. Never expose JPA entities through APIs — always map to DTOs
5. Field names match JSON property names (camelCase)

## JSON Parsing with FromJsonHelper

Fineract uses `FromJsonHelper` (wrapping Gson) for JSON parsing:

```java
@Component
@RequiredArgsConstructor
public class SavingsProductDataValidator {

    private final FromJsonHelper fromJsonHelper;

    private static final String NAME = "name";
    private static final String DESCRIPTION = "description";
    private static final String RATE = "nominalAnnualInterestRate";
    private static final String ACTIVE = "active";

    private static final Set<String> CREATE_PARAMS = Set.of(
        NAME, DESCRIPTION, RATE, ACTIVE, "locale", "dateFormat"
    );

    public void validateForCreate(final String json) {
        if (StringUtils.isBlank(json)) {
            throw new InvalidJsonException();
        }

        final JsonElement element = fromJsonHelper.parse(json);

        // Check for unsupported parameters
        fromJsonHelper.checkForUnsupportedParameters(
            element.getAsJsonObject(), CREATE_PARAMS);

        final List<ApiParameterError> errors = new ArrayList<>();

        // Required: name
        final String name = fromJsonHelper.extractStringNamed(NAME, element);
        baseDataValidator.reset().parameter(NAME).value(name)
            .notBlank().notExceedingLengthOf(100);

        // Required: rate
        final BigDecimal rate = fromJsonHelper.extractBigDecimalWithLocaleNamed(
            RATE, element);
        baseDataValidator.reset().parameter(RATE).value(rate)
            .notNull().positiveAmount();

        // Optional: description
        if (fromJsonHelper.parameterExists(DESCRIPTION, element)) {
            final String desc = fromJsonHelper.extractStringNamed(
                DESCRIPTION, element);
            baseDataValidator.reset().parameter(DESCRIPTION).value(desc)
                .notExceedingLengthOf(500);
        }

        throwExceptionIfValidationWarningsExist(errors);
    }

    public void validateForUpdate(final String json) {
        if (StringUtils.isBlank(json)) {
            throw new InvalidJsonException();
        }

        final JsonElement element = fromJsonHelper.parse(json);
        final List<ApiParameterError> errors = new ArrayList<>();

        // Only validate fields that are present in the update payload
        if (fromJsonHelper.parameterExists(NAME, element)) {
            final String name = fromJsonHelper.extractStringNamed(NAME, element);
            baseDataValidator.reset().parameter(NAME).value(name)
                .notBlank().notExceedingLengthOf(100);
        }

        throwExceptionIfValidationWarningsExist(errors);
    }

    private void throwExceptionIfValidationWarningsExist(
            List<ApiParameterError> errors) {
        if (!errors.isEmpty()) {
            throw new PlatformApiDataValidationException(errors);
        }
    }
}
```

## Validation Approach

### DataValidator (Fineract Standard)

Uses `DataValidatorBuilder` for fluent validation:

```java
baseDataValidator.reset()
    .parameter("name")
    .value(name)
    .notBlank()                    // Cannot be null or empty
    .notExceedingLengthOf(100);    // Max length

baseDataValidator.reset()
    .parameter("amount")
    .value(amount)
    .notNull()                     // Cannot be null
    .positiveAmount()              // Must be > 0
    .notGreaterThanMax(maxAmount); // Upper bound

baseDataValidator.reset()
    .parameter("startDate")
    .value(date)
    .notNull()
    .validateDateAfter(minimumDate);
```

Common validations:

- `.notBlank()` — string not null/empty
- `.notNull()` — not null
- `.notExceedingLengthOf(n)` — max string length
- `.zeroOrPositiveAmount()` — BigDecimal >= 0
- `.positiveAmount()` — BigDecimal > 0
- `.inMinMaxRange(min, max)` — numeric range
- `.isOneOfTheseValues(values...)` — enum validation

### Supported Parameter Checking

For Create: All required fields must be present
For Update: Only validate fields included in the JSON payload

```java
// Check if parameter exists in JSON before validating
if (fromJsonHelper.parameterExists("name", element)) {
    // validate name
}
```

### Unsupported Parameter Detection

Prevent clients from sending unrecognized fields:

```java
fromJsonHelper.checkForUnsupportedParameters(
    element.getAsJsonObject(), SUPPORTED_PARAMS);
```

This throws an error if the JSON contains fields not in the whitelist.

## JSON Extraction Methods

| Java Type    | FromJsonHelper Method                                |
| ------------ | ---------------------------------------------------- |
| `String`     | `extractStringNamed("field", element)`               |
| `Long`       | `extractLongNamed("field", element)`                 |
| `Integer`    | `extractIntegerWithLocaleNamed("field", element)`    |
| `BigDecimal` | `extractBigDecimalWithLocaleNamed("field", element)` |
| `boolean`    | `extractBooleanNamed("field", element)`              |
| `LocalDate`  | `extractLocalDateNamed("field", element)`            |
| `JsonArray`  | `extractJsonArrayNamed("field", element)`            |

## Serialization (Response)

Fineract uses `DefaultToApiJsonSerializer` for responses:

```java
// In API Resource
private final DefaultToApiJsonSerializer<SavingsProductData> toApiJsonSerializer;

// Serialize with field filtering
return toApiJsonSerializer.serialize(settings, productData);

// Serialize without filtering
return toApiJsonSerializer.serialize(result);
```

## Decision Framework

### Supported Parameters Set

Always define `CREATE_PARAMS` and `UPDATE_PARAMS` as static sets. Include:

- All entity fields
- `locale` (for number/date parsing)
- `dateFormat` (for date parsing)
- Any nested object names

### When to Use Which Validation Layer

| Check                              | Where                 |
| ---------------------------------- | --------------------- |
| Required fields, format, length    | DataValidator         |
| Business rules (state transitions) | Entity domain methods |
| Referential integrity              | Database constraints  |
| Cross-entity rules                 | Write service         |

## Generator

```bash
python3 scripts/generate_data.py \
  --entity-name SavingsProduct \
  --package org.apache.fineract.portfolio.savingsproduct \
  --fields "name:String,description:String,nominalAnnualInterestRate:BigDecimal,active:boolean" \
  --output-dir ./output
```

## Checklist

### Data DTO

- [ ] All fields are `final` (immutable)
- [ ] No setters, only getters
- [ ] Field names match JSON property names (camelCase)
- [ ] Template factory method for form/dropdown data
- [ ] Never exposes JPA entities

### DataValidator

- [ ] Uses `FromJsonHelper` for JSON parsing
- [ ] `CREATE_PARAMS` and `UPDATE_PARAMS` sets defined
- [ ] `checkForUnsupportedParameters()` called
- [ ] Required fields validated with `notBlank()` / `notNull()`
- [ ] String fields have length limits
- [ ] BigDecimal fields use `positiveAmount()` where applicable
- [ ] Update validation only checks present fields
- [ ] Validation errors collected and thrown together (not one at a time)

### JSON Parsing

- [ ] `locale` included in supported parameters (for number/date parsing)
- [ ] `dateFormat` included if dates are used
- [ ] BigDecimal extracted with `extractBigDecimalWithLocaleNamed`
- [ ] Dates extracted with `extractLocalDateNamed`
