# Skill 07 — API & Swagger Layer

## Purpose

This skill teaches how to build JAX-RS API resources in Fineract with proper permission codes, command wrappers, OpenAPI annotations, and multi-tenant headers.

## API Resource Structure

```java
@Path("/v1/savingsproducts")
@Component
@Tag(name = "Savings Product", description = "Savings Product API")
@RequiredArgsConstructor
public class SavingsProductApiResource {

    private final PlatformSecurityContext context;
    private final PortfolioCommandSourceWritePlatformService commandsSourceWritePlatformService;
    private final DefaultToApiJsonSerializer<SavingsProductData> toApiJsonSerializer;
    private final SavingsProductReadPlatformService readPlatformService;
    private final ApiRequestParameterHelper apiRequestParameterHelper;

    // ─── CREATE ─────────────────────────────────────────
    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Create a Savings Product",
               description = "Creates a new savings product")
    @ApiResponses({
        @ApiResponse(responseCode = "200",
                     description = "OK",
                     content = @Content(schema = @Schema(
                         implementation = CommandProcessingResult.class)))
    })
    public String create(
            @Parameter(hidden = true) final String apiRequestBodyAsJson) {

        final CommandWrapper commandRequest = new CommandWrapperBuilder()
            .createSavingsProduct()
            .withJson(apiRequestBodyAsJson)
            .build();

        final CommandProcessingResult result =
            commandsSourceWritePlatformService.logCommandSource(commandRequest);

        return toApiJsonSerializer.serialize(result);
    }

    // ─── RETRIEVE ONE ───────────────────────────────────
    @GET
    @Path("{productId}")
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Retrieve a Savings Product",
               description = "Returns the details of a savings product")
    @ApiResponses({
        @ApiResponse(responseCode = "200",
                     description = "OK",
                     content = @Content(schema = @Schema(
                         implementation = SavingsProductData.class)))
    })
    public String retrieveOne(
            @PathParam("productId") @Parameter(description = "productId") final Long productId,
            @Context final UriInfo uriInfo) {

        context.authenticatedUser()
            .validateHasReadPermission("SAVINGSPRODUCT");

        final SavingsProductData productData = readPlatformService.retrieveOne(productId);

        final ApiRequestJsonSerializationSettings settings =
            apiRequestParameterHelper.process(uriInfo.getQueryParameters());

        return toApiJsonSerializer.serialize(settings, productData);
    }

    // ─── RETRIEVE ALL ───────────────────────────────────
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "List Savings Products")
    public String retrieveAll(@Context final UriInfo uriInfo) {

        context.authenticatedUser()
            .validateHasReadPermission("SAVINGSPRODUCT");

        final Collection<SavingsProductData> products =
            readPlatformService.retrieveAll();

        final ApiRequestJsonSerializationSettings settings =
            apiRequestParameterHelper.process(uriInfo.getQueryParameters());

        return toApiJsonSerializer.serialize(settings, products);
    }

    // ─── UPDATE ─────────────────────────────────────────
    @PUT
    @Path("{productId}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Update a Savings Product")
    public String update(
            @PathParam("productId") final Long productId,
            @Parameter(hidden = true) final String apiRequestBodyAsJson) {

        final CommandWrapper commandRequest = new CommandWrapperBuilder()
            .updateSavingsProduct(productId)
            .withJson(apiRequestBodyAsJson)
            .build();

        final CommandProcessingResult result =
            commandsSourceWritePlatformService.logCommandSource(commandRequest);

        return toApiJsonSerializer.serialize(result);
    }

    // ─── DELETE ──────────────────────────────────────────
    @DELETE
    @Path("{productId}")
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Delete a Savings Product")
    public String delete(
            @PathParam("productId") final Long productId) {

        final CommandWrapper commandRequest = new CommandWrapperBuilder()
            .deleteSavingsProduct(productId)
            .build();

        final CommandProcessingResult result =
            commandsSourceWritePlatformService.logCommandSource(commandRequest);

        return toApiJsonSerializer.serialize(result);
    }
}
```

## Permission Codes

Every API action needs a corresponding permission in `m_permission`:

| Action | Permission Code         | Format            |
| ------ | ----------------------- | ----------------- |
| Create | `CREATE_SAVINGSPRODUCT` | `CREATE_<ENTITY>` |
| Read   | `READ_SAVINGSPRODUCT`   | `READ_<ENTITY>`   |
| Update | `UPDATE_SAVINGSPRODUCT` | `UPDATE_<ENTITY>` |
| Delete | `DELETE_SAVINGSPRODUCT` | `DELETE_<ENTITY>` |

Entity name in permission is UPPERCASE with no separators: `SAVINGSPRODUCT`, `LOANPRODUCT`.

For read endpoints, check permission explicitly:

```java
context.authenticatedUser().validateHasReadPermission("SAVINGSPRODUCT");
```

For write endpoints, `logCommandSource()` checks permissions automatically.

## Multi-Tenant Headers

The tenant is identified by the `Fineract-Platform-TenantId` HTTP header:

```
Fineract-Platform-TenantId: default
```

The platform handles this automatically via `TenantAwareRoutingDataSource`. API resources do NOT need to handle tenant routing manually.

## Response Field Filtering

Fineract supports response field filtering via query parameters:

```
GET /v1/savingsproducts/1?fields=id,name,active
```

Handle this with `ApiRequestJsonSerializationSettings`:

```java
final ApiRequestJsonSerializationSettings settings =
    apiRequestParameterHelper.process(uriInfo.getQueryParameters());
return toApiJsonSerializer.serialize(settings, productData);
```

## Custom Actions (Non-CRUD)

For actions beyond CRUD (approve, activate, disburse):

```java
@POST
@Path("{productId}")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
@Operation(summary = "Activate or Close a Savings Product")
public String handleCommands(
        @PathParam("productId") final Long productId,
        @QueryParam("command") @Parameter(description = "command") final String commandParam,
        @Parameter(hidden = true) final String apiRequestBodyAsJson) {

    CommandWrapper commandRequest;
    if ("activate".equals(commandParam)) {
        commandRequest = new CommandWrapperBuilder()
            .withEntityName("SAVINGS_PRODUCT")
            .withAction("ACTIVATE")
            .withEntityId(productId)
            .withJson(apiRequestBodyAsJson)
            .build();
    } else {
        throw new UnrecognizedQueryParamException("command", commandParam);
    }

    final CommandProcessingResult result =
        commandsSourceWritePlatformService.logCommandSource(commandRequest);
    return toApiJsonSerializer.serialize(result);
}
```

## Decision Framework

### When to Return `CommandProcessingResult` vs Data DTO

| HTTP Method   | Response Type                                     |
| ------------- | ------------------------------------------------- |
| POST (create) | `CommandProcessingResult` (contains new entityId) |
| PUT (update)  | `CommandProcessingResult` (contains changes map)  |
| DELETE        | `CommandProcessingResult` (contains entityId)     |
| POST (action) | `CommandProcessingResult`                         |
| GET (single)  | `<Entity>Data` DTO                                |
| GET (list)    | `Collection<EntityData>` or `Page<EntityData>`    |

## Generator

```bash
python3 scripts/generate_api_resource.py \
  --entity-name SavingsProduct \
  --package org.apache.fineract.portfolio.savingsproduct \
  --api-path "savingsproducts" \
  --actions "create,retrieveAll,retrieveOne,update,delete" \
  --output-dir ./output
```

## Checklist

- [ ] Resource class annotated with `@Path("/v1/<resource>")` and `@Component`
- [ ] `@Tag` annotation for OpenAPI grouping
- [ ] Write endpoints use `CommandWrapperBuilder` + `logCommandSource()`
- [ ] Read endpoints call read service directly
- [ ] Read endpoints check `validateHasReadPermission("<ENTITY>")`
- [ ] All endpoints have `@Operation` and `@ApiResponse` annotations
- [ ] Permissions registered in Liquibase migration (`m_permission` table)
- [ ] `@Consumes(MediaType.APPLICATION_JSON)` on POST/PUT
- [ ] `@Produces(MediaType.APPLICATION_JSON)` on all endpoints
- [ ] Field filtering handled via `ApiRequestJsonSerializationSettings`
- [ ] Custom actions use `@QueryParam("command")` pattern
- [ ] No business logic in API resource (delegate to services)

## Batch API

Fineract supports **batch requests** — grouping multiple API calls into a single HTTP request. This reduces network round-trips for bulk operations.

### Endpoint

```
POST /v1/batches
Content-Type: application/json

[
  {
    "requestId": 1,
    "relativeUrl": "clients",
    "method": "POST",
    "body": "{ \"firstname\": \"John\", ... }"
  },
  {
    "requestId": 2,
    "relativeUrl": "clients",
    "method": "POST",
    "body": "{ \"firstname\": \"Jane\", ... }"
  }
]
```

### Key Classes

- `BatchApiResource` — JAX-RS endpoint at `/v1/batches`
- `BatchRequest` — individual request within the batch (requestId, relativeUrl, method, headers, body)
- `BatchResponse` — individual response (requestId, statusCode, headers, body)
- `BatchRequestJsonHelper` — parses batch request JSON

### Response

```json
[
  { "requestId": 1, "statusCode": 200, "body": "{\"resourceId\": 101}" },
  { "requestId": 2, "statusCode": 200, "body": "{\"resourceId\": 102}" }
]
```

### When to Use

- Bulk entity creation (e.g., importing many clients)
- Operations that need to minimize HTTP overhead
- Client-side orchestration of multiple dependent API calls
