# Multi-Tenancy & Security Context

## Purpose

This skill teaches how Fineract handles multi-tenancy (database per tenant), security context propagation, and office-based access restrictions.

## Multi-Tenancy Model

Fineract uses **database-per-tenant** isolation:

```
┌──────────────────────────────────────┐
│           HTTP Request               │
│  Header: Fineract-Platform-TenantId  │
└──────────────┬───────────────────────┘
               │
               ▼
┌──────────────────────────────────────┐
│     TenantIdentifierFilter           │
│  Resolves tenant from header/path    │
│  Sets ThreadLocalContextUtil         │
└──────────────┬───────────────────────┘
               │
               ▼
┌──────────────────────────────────────┐
│   TenantAwareRoutingDataSource       │
│   Routes SQL to correct DB schema    │
└──────────────┬───────────────────────┘
               │
       ┌───────┴───────┐
       ▼               ▼
   ┌────────┐     ┌────────┐
   │Tenant A│     │Tenant B│
   │Database│     │Database│
   └────────┘     └────────┘
```

### Key Classes

| Class                          | Purpose                                  |
| ------------------------------ | ---------------------------------------- |
| `FineractPlatformTenant`       | Tenant metadata (name, DB connection)    |
| `TenantServerConnection`       | Maps tenant ID to DB connection details  |
| `TenantAwareRoutingDataSource` | Routes DB calls to correct tenant schema |
| `ThreadLocalContextUtil`       | Stores current tenant context per thread |
| `TenantIdentifierFilter`       | Extracts tenant from HTTP request        |

### How Tenant Context Flows

```java
// In servlet filter (automatically):
FineractPlatformTenant tenant = tenantService.findById(tenantId);
ThreadLocalContextUtil.setTenant(tenant);

// In your code, NEVER manually set tenant context.
// The filter handles it before your code runs.

// To access current tenant (rarely needed):
FineractPlatformTenant currentTenant = ThreadLocalContextUtil.getTenant();
```

## Security Context

### PlatformSecurityContext

Every service should validate the authenticated user:

```java
@Override
@Transactional
public CommandProcessingResult create(JsonCommand command) {
    // ALWAYS call this first in write services
    AppUser currentUser = context.authenticatedUser();

    // User's office
    Long officeId = currentUser.getOffice().getId();

    // ... proceed with operation
}
```

### Permission Checking

For read services, check permissions explicitly:

```java
context.authenticatedUser()
    .validateHasReadPermission("SAVINGSPRODUCT");
```

For write operations, `logCommandSource()` checks permissions automatically.

### Office Hierarchy Restrictions

Users can only access data within their office hierarchy:

```java
// User in head office can see all offices below
// User in branch can only see their branch and sub-branches

// In read services, filter by office hierarchy:
final String officeHierarchy = currentUser.getOffice().getHierarchy();
// Use in SQL: WHERE o.hierarchy LIKE 'officeHierarchy%'
```

## Multi-Tenancy Rules for Developers

### Rule 1: Never Hardcode Tenant

```java
// WRONG: Hardcoded tenant reference
String tenantId = "default";

// CORRECT: Let the filter handle it (you don't need tenant ID in your code)
```

### Rule 2: Never Access Cross-Tenant Data

Each tenant's data is completely isolated. Your code should never attempt to query another tenant's database.

### Rule 3: Tenant-Aware Scheduled Jobs

Jobs run per-tenant automatically. The scheduler iterates all tenants and sets context before executing your tasklet.

### Rule 4: Thread Safety

Tenant context is thread-local. If you spawn new threads (don't do this normally), the tenant context won't propagate automatically.

## Security Best Practices

1. **Always call `context.authenticatedUser()`** at the start of every service method
2. **Never trust client-provided user IDs** — always get the current user from security context
3. **Apply office hierarchy filtering** in read queries for sensitive data
4. **Use permission codes** consistently with the `m_permission` table
5. **Never expose internal IDs** that could allow cross-tenant enumeration

## Decision Framework

### When to Check Permissions Manually

| Scenario                 | Permission Check                                 |
| ------------------------ | ------------------------------------------------ |
| Write via CommandWrapper | Automatic (logCommandSource checks)              |
| Read endpoint            | Manual: `validateHasReadPermission()`            |
| Custom action            | Manual: `validateHasPermission("ACTION_ENTITY")` |
| Scheduled job            | Not needed (runs as system user)                 |
| Internal service call    | Not needed (caller already checked)              |

### Office Filtering

| Data Type             | Office Filter Needed?         |
| --------------------- | ----------------------------- |
| Client data           | YES (office hierarchy)        |
| Account data          | YES (via client's office)     |
| Product configuration | NO (shared across offices)    |
| System configuration  | NO (global)                   |
| Reports               | YES (filter by user's office) |

# Checklist

- [ ] `context.authenticatedUser()` called at start of every service method
- [ ] No hardcoded tenant identifiers
- [ ] No cross-tenant data access
- [ ] Read permissions checked with `validateHasReadPermission()`
- [ ] Write permissions handled by CommandWrapper/logCommandSource
- [ ] Office hierarchy filtering applied for client/account queries
- [ ] Current user obtained from security context, not from request parameters
- [ ] Scheduled jobs do not manually set tenant context
- [ ] No new thread spawning without proper tenant context propagation
- [ ] Permission codes registered in m_permission via Liquibase
