# Testing Strategy

## Purpose

This skill teaches how to write integration tests, API tests, event tests, and migration tests for Fineract modules.

## Test Architecture

```
integration-tests/
└── src/test/java/org/apache/fineract/integrationtests/
    ├── SavingsProductIntegrationTest.java    # Full API integration test
    ├── common/
    │   ├── Utils.java                        # Shared test utilities
    │   ├── SavingsProductHelper.java         # API helper for savings products
    │   └── ClientHelper.java                 # API helper for clients
    └── ...
```

## Integration Test Pattern

### API-Level Integration Test

```java
@ExtendWith(FineractExtension.class)
public class SavingsProductIntegrationTest {

    private ResponseSpecification responseSpec;
    private RequestSpecification requestSpec;
    private SavingsProductHelper savingsProductHelper;

    @BeforeEach
    public void setup() {
        requestSpec = new RequestSpecBuilder()
            .setContentType(ContentType.JSON)
            .build();
        requestSpec.header("Authorization", "Basic " + Utils.loginIntoServerAndGetBase64EncodedAuthenticationKey());
        requestSpec.header("Fineract-Platform-TenantId", "default");
        responseSpec = new ResponseSpecBuilder()
            .expectStatusCode(200)
            .build();
        savingsProductHelper = new SavingsProductHelper(requestSpec, responseSpec);
    }

    @Test
    public void testCreateSavingsProduct() {
        // Create
        final Integer productId = savingsProductHelper.createSavingsProduct(
            "Test Savings Product",
            "5.0"  // interest rate
        );
        assertNotNull(productId);

        // Retrieve and verify
        HashMap productData = savingsProductHelper.getSavingsProduct(productId);
        assertEquals("Test Savings Product", productData.get("name"));
        assertEquals(5.0, ((Number) productData.get("nominalAnnualInterestRate")).doubleValue());
    }

    @Test
    public void testUpdateSavingsProduct() {
        final Integer productId = savingsProductHelper.createSavingsProduct(
            "Original Name", "5.0");

        // Update
        savingsProductHelper.updateSavingsProduct(productId, Map.of(
            "name", "Updated Name",
            "nominalAnnualInterestRate", "7.5",
            "locale", "en"
        ));

        // Verify
        HashMap productData = savingsProductHelper.getSavingsProduct(productId);
        assertEquals("Updated Name", productData.get("name"));
    }

    @Test
    public void testDeleteSavingsProduct() {
        final Integer productId = savingsProductHelper.createSavingsProduct(
            "To Delete", "5.0");

        savingsProductHelper.deleteSavingsProduct(productId);

        // Verify 404
        ResponseSpecification notFoundSpec = new ResponseSpecBuilder()
            .expectStatusCode(404)
            .build();
        savingsProductHelper.getSavingsProduct(productId, notFoundSpec);
    }

    @Test
    public void testCreateSavingsProduct_ValidationError() {
        // Missing required field
        ResponseSpecification badRequestSpec = new ResponseSpecBuilder()
            .expectStatusCode(400)
            .build();

        HashMap response = savingsProductHelper.createSavingsProductExpectingError(
            Map.of("description", "No name provided"),
            badRequestSpec
        );

        assertNotNull(response.get("errors"));
    }
}
```

### API Helper Pattern

```java
public class SavingsProductHelper {

    private final RequestSpecification requestSpec;
    private final ResponseSpecification responseSpec;
    private static final String BASE_URL = "/fineract-provider/api/v1/savingsproducts";

    public SavingsProductHelper(RequestSpecification requestSpec,
            ResponseSpecification responseSpec) {
        this.requestSpec = requestSpec;
        this.responseSpec = responseSpec;
    }

    public Integer createSavingsProduct(String name, String interestRate) {
        String json = new Gson().toJson(Map.of(
            "name", name,
            "nominalAnnualInterestRate", interestRate,
            "locale", "en",
            "dateFormat", "dd MMMM yyyy"
        ));

        return Utils.performServerPost(requestSpec, responseSpec,
            BASE_URL, json, "resourceId");
    }

    public HashMap getSavingsProduct(Integer productId) {
        return Utils.performServerGet(requestSpec, responseSpec,
            BASE_URL + "/" + productId, "");
    }

    public void updateSavingsProduct(Integer productId, Map<String, Object> changes) {
        String json = new Gson().toJson(changes);
        Utils.performServerPut(requestSpec, responseSpec,
            BASE_URL + "/" + productId, json, "resourceId");
    }

    public void deleteSavingsProduct(Integer productId) {
        Utils.performServerDelete(requestSpec, responseSpec,
            BASE_URL + "/" + productId, "resourceId");
    }
}
```

## Test Categories

### 1. CRUD Tests

Test basic create, read, update, delete operations:

- Create with valid data → success
- Create with invalid data → validation error
- Retrieve existing → returns data
- Retrieve non-existent → 404
- Update with changes → changes applied
- Delete → entity removed

### 2. Business Rule Tests

Test domain-specific rules:

- Cannot delete active product
- Cannot approve already-approved loan
- Cannot withdraw more than balance
- Interest rate must be positive

### 3. Event Tests

Verify business events are published:

```java
@Test
public void testLoanApprovalPublishesEvent() {
    // Create and approve loan
    // Verify external event in m_external_event table
    HashMap events = EventHelper.getExternalEvents(requestSpec, responseSpec,
        "LoanApprovedBusinessEvent", loanId);
    assertFalse(events.isEmpty());
}
```

### 4. Migration Tests

Verify Liquibase changelogs apply correctly:

- Table exists after migration
- Columns have correct types
- Constraints are in place
- Permissions are seeded

### 5. Maker-Checker Tests

Test the approval workflow:

```java
@Test
public void testMakerCheckerForLoanApproval() {
    // Step 1: Maker submits approval (stored as pending)
    Integer commandId = loanHelper.approveLoanAsMaker(loanId);
    assertNotNull(commandId);

    // Step 2: Verify loan still in submitted state
    HashMap loanData = loanHelper.getLoan(loanId);
    assertEquals("Submitted and pending approval", loanData.get("status"));

    // Step 3: Checker approves
    loanHelper.approveCommand(commandId);

    // Step 4: Verify loan is now approved
    loanData = loanHelper.getLoan(loanId);
    assertEquals("Approved", loanData.get("status"));
}
```

## Test Data Management

### Setup

```java
@BeforeEach
public void setup() {
    // Create test infrastructure
    officeId = OfficeHelper.createOffice(requestSpec, responseSpec);
    clientId = ClientHelper.createClient(requestSpec, responseSpec, officeId);
}
```

### Cleanup

Tests should be independent — each test creates its own data. Don't rely on shared state between tests.

## Decision Framework

### What to Test

| Component          | Test Type          | Priority       |
| ------------------ | ------------------ | -------------- |
| CRUD operations    | Integration        | HIGH           |
| Business rules     | Integration        | HIGH           |
| Validation errors  | Integration        | HIGH           |
| Accounting entries | Integration        | CRITICAL       |
| Maker-checker      | Integration        | MEDIUM         |
| Event publishing   | Integration        | MEDIUM         |
| Permission checks  | Integration        | MEDIUM         |
| Edge cases         | Unit + Integration | HIGH           |
| Performance        | Load testing       | LOW (separate) |

## Checklist

### Integration Tests

- [ ] Test class uses `@ExtendWith(FineractExtension.class)`
- [ ] Auth header and tenant header set in `@BeforeEach`
- [ ] Helper classes used for API calls (not raw HTTP in tests)
- [ ] CRUD operations covered (create, read, update, delete)
- [ ] Validation error scenarios tested (missing fields, invalid values)
- [ ] Business rule violations tested
- [ ] 404 responses tested for non-existent entities

### Test Data

- [ ] Each test is independent (creates own data)
- [ ] No shared mutable state between tests
- [ ] Test data uses unique names to avoid conflicts

### Financial Tests

- [ ] Accounting entries verified after financial operations
- [ ] Balance checks before and after transactions
- [ ] Journal entries are balanced (debits = credits)

### Event Tests

- [ ] Business events verified in m_external_event after operations
- [ ] Event type and payload validated

### API Helper

- [ ] Helper methods match API contract (correct paths, methods)
- [ ] JSON serialization handles locale and dateFormat
- [ ] Error response helpers available for negative tests
