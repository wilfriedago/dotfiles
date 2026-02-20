# Security Filter Chain

Fineract supports two mutually exclusive authentication modes, each with its own `SecurityFilterChain`:

- **Basic Auth** — `SecurityConfig.java` (when `fineract.security.basicauth.enabled=true`)
- **OAuth2/JWT** — `AuthorizationServerConfig.java` (when `fineract.security.oauth2.enabled=true`)

## Filter Chain Order

### Basic Auth Mode

```
Request → TenantAwareBasicAuthenticationFilter
        → BasicAuthenticationFilter (Spring Security)
        → RequestResponseFilter
        → CorrelationHeaderFilter
        → FineractInstanceModeApiFilter
        → [LoanCOBApiFilter]           (conditional)
        → IdempotencyStoreFilter
        → [CallerIpTrackingFilter]      (conditional)
        → [TwoFactorAuthenticationFilter] (conditional)
        → Authorization Manager
```

### OAuth2/JWT Mode (3 chains by `@Order`)

**Chain 1 (`@Order(1)`):** Public endpoints — Swagger UI, actuator, API docs. No authentication.

**Chain 2 (`@Order(2)`):** OAuth2 Authorization Server endpoints. Session-based auth.

**Chain 3 (`@Order(3)`):** Protected API endpoints:

```
Request → JwtAuthenticationFilter (Spring Security)
        → FineractJwtAuthenticationTokenConverter
        → TenantAwareAuthenticationFilter
        → BusinessDateFilter
        → RequestResponseFilter
        → CorrelationHeaderFilter
        → FineractInstanceModeApiFilter
        → [LoanCOBApiFilter]           (conditional)
        → IdempotencyStoreFilter
        → [CallerIpTrackingFilter]      (conditional)
        → [TwoFactorAuthenticationFilter] (conditional)
        → Authorization Manager
```

## Filter Details

### TenantAwareBasicAuthenticationFilter

**File:** `fineract-provider/.../security/filter/TenantAwareBasicAuthenticationFilter.java`
**Mode:** Basic Auth only

Extends Spring's `BasicAuthenticationFilter`. Handles tenant resolution and basic authentication together.

- Extracts tenant from `Fineract-Platform-TenantId` header or `tenantIdentifier` query param
- Loads tenant config via `AuthTenantDetailsService`
- Sets business dates via `BusinessDateReadPlatformService`
- Sets tenant context in `ThreadLocalContextUtil`
- Returns 400 if tenant identifier is missing

### TenantAwareAuthenticationFilter

**File:** `fineract-provider/.../security/filter/TenantAwareAuthenticationFilter.java`
**Mode:** OAuth2/JWT only

Extracts tenant from JWT claims before full authentication.

```java
public class TenantAwareAuthenticationFilter extends OncePerRequestFilter {
    private final BearerTokenResolver resolver;
    private final AuthTenantDetailsService tenantDetailsService;
    private final String tenantClaim;
    private final List<String> tenantClaimFallbacks;

    @Override
    protected void doFilterInternal(...) {
        String token = resolver.resolve(request);
        if (token != null) {
            var jwt = JWTParser.parse(token);  // parse without validation
            tenantId = resolveTenantId(jwt.getJWTClaimsSet());
        }
        if (tenantId == null) {
            tenantId = request.getParameter("tenantId"); // fallback
        }
        ThreadLocalContextUtil.setTenant(tenantDetailsService.loadTenantById(tenantId, false));
        filterChain.doFilter(request, response);
    }
}
```

Tenant claim resolution order:

1. Configured `tenantClaim` property
2. `tenantClaimFallbacks` list
3. Default `"tenant"` claim
4. `tenantId` query parameter

### FineractJwtAuthenticationTokenConverter

**File:** `fineract-provider/.../security/converter/FineractJwtAuthenticationTokenConverter.java`
**Mode:** OAuth2/JWT only

Converts Spring's `Jwt` to `FineractJwtAuthenticationToken` with full `UserDetails`.

```java
public class FineractJwtAuthenticationTokenConverter
    implements Converter<Jwt, FineractJwtAuthenticationToken> {

    @Override
    public FineractJwtAuthenticationToken convert(Jwt jwt) {
        UserDetails user = userDetailsService.loadUserByUsername(resolvePrincipal(jwt));
        Collection<GrantedAuthority> authorities = new JwtGrantedAuthoritiesConverter().convert(jwt);
        return new FineractJwtAuthenticationToken(jwt, authorities, user);
    }
}
```

Principal claim resolution order: `principalClaim` → `principalClaimFallbacks` → `"sub"`

### BusinessDateFilter

**File:** `fineract-provider/.../security/filter/BusinessDateFilter.java`
**Mode:** OAuth2/JWT only (basic auth handles this inside `TenantAwareBasicAuthenticationFilter`)

Sets business date context after tenant context is established:

```java
public class BusinessDateFilter extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(...) {
        if (ThreadLocalContextUtil.getTenant() != null) {
            HashMap<BusinessDateType, LocalDate> businessDates =
                businessDateReadPlatformService.getBusinessDates();
            ThreadLocalContextUtil.setBusinessDates(businessDates);
        }
        filterChain.doFilter(request, response);
    }
}
```

### TwoFactorAuthenticationFilter

**File:** `fineract-provider/.../security/filter/TwoFactorAuthenticationFilter.java`
**Mode:** Both (conditional on `fineract.security.twofactor.enabled`)

Validates the `Fineract-Platform-TFA-Token` header:

- Users with `BYPASS_TWOFACTOR` permission are auto-approved
- Valid token → adds `TWOFACTOR_AUTHENTICATED` authority
- Invalid/missing token → 401 Unauthorized
- Supports both `UsernamePasswordAuthenticationToken` and `FineractJwtAuthenticationToken`

### RequestResponseFilter

**File:** `fineract-core/.../core/filters/RequestResponseFilter.java`
**Mode:** Both

Logs request method/URI and response status at DEBUG level.

### CorrelationHeaderFilter

**File:** `fineract-core/.../core/filters/CorrelationHeaderFilter.java`
**Mode:** Both (conditional on `fineract.correlation.enabled`)

Extracts correlation ID from configurable header and stores in MDC:

```java
String correlationId = request.getHeader(correlationProperties.getHeaderName());
mdcWrapper.put("correlationId", correlationId);
```

MDC is cleaned up in `finally` block.

### FineractInstanceModeApiFilter

**File:** `fineract-provider/.../instancemode/filter/FineractInstanceModeApiFilter.java`
**Mode:** Both

Enforces API availability based on instance deployment mode:

| Mode                    | Allowed Operations                                |
| ----------------------- | ------------------------------------------------- |
| `read-enabled`          | GET requests only                                 |
| `write-enabled`         | All HTTP methods                                  |
| `batch-manager-enabled` | `/v1/jobs`, `/v1/scheduler`, `/v1/loans/catch-up` |

Always allowed: `/v1/instance-mode`, `/v1/batches`, actuator endpoints.
Returns **405 Method Not Allowed** when operation is rejected.

### LoanCOBApiFilter

**File:** `fineract-provider/.../jobs/filter/LoanCOBApiFilter.java`
**Mode:** Both (conditional on `LoanCOBEnabledCondition`)

Prevents API requests on loans locked for Close-of-Business processing:

- Calculates relevant loan IDs from request body
- If loans are behind schedule → executes inline COB first
- If loans are hard-locked → returns **409 Conflict**
- Bypass users can proceed without checks

### IdempotencyStoreFilter

**File:** `fineract-core/.../core/filters/IdempotencyStoreFilter.java`
**Mode:** Both

Implements request-level idempotency:

- Extracts key from configurable header (`fineract.idempotency-key-header-name`)
- Stores key in `FineractRequestContextHolder` for command processing
- After successful execution, stores response body for replay
- On duplicate request with same key → returns stored response

### CallerIpTrackingFilter

**File:** `fineract-core/.../core/filters/CallerIpTrackingFilter.java`
**Mode:** Both (conditional on `fineract.ip-tracking.enabled`)

Extracts client IP from proxy headers (`X-Forwarded-For`, `Proxy-Client-IP`, etc.) and stores in request attribute.

## ThreadLocal Context

All filters coordinate via `ThreadLocalContextUtil`:

| Context        | Set By              | Purpose                            |
| -------------- | ------------------- | ---------------------------------- |
| Tenant         | Tenant filters      | Database routing, tenant isolation |
| Business Dates | BusinessDate filter | Backdating support for COB         |
| Authentication | Spring Security     | User identity, permissions         |
| Correlation ID | Correlation filter  | MDC for distributed tracing        |
| Caller IP      | IP tracking filter  | Audit, request attribute           |

All values are **reset in `finally` blocks** to prevent context leakage.

## Configuration Properties

```properties
# Authentication mode (mutually exclusive)
fineract.security.basicauth.enabled=false
fineract.security.oauth2.enabled=true

# JWT claim mapping
fineract.security.oauth2.jwt.principal-claim=preferred_username
fineract.security.oauth2.jwt.principal-claim-fallbacks=email,sub
fineract.security.oauth2.jwt.tenant-claim=tenant
fineract.security.oauth2.jwt.tenant-claim-fallbacks=realm,org

# Two-Factor Authentication
fineract.security.twofactor.enabled=false

# Correlation
fineract.correlation.enabled=true
fineract.correlation.header-name=X-Correlation-ID

# IP Tracking
fineract.ip-tracking.enabled=false

# Instance Mode
fineract.mode.read-enabled=true
fineract.mode.write-enabled=true
fineract.mode.batch-manager-enabled=true

# CORS
fineract.security.cors.enabled=false

# Idempotency
fineract.idempotency-key-header-name=Idempotency-Key
```

## Key Files

| Component                               | Path                                                                                    |
| --------------------------------------- | --------------------------------------------------------------------------------------- |
| SecurityConfig (Basic Auth)             | `fineract-provider/.../core/config/SecurityConfig.java`                                 |
| AuthorizationServerConfig (OAuth2)      | `fineract-provider/.../security/config/AuthorizationServerConfig.java`                  |
| TenantAwareBasicAuthenticationFilter    | `fineract-provider/.../security/filter/TenantAwareBasicAuthenticationFilter.java`       |
| TenantAwareAuthenticationFilter         | `fineract-provider/.../security/filter/TenantAwareAuthenticationFilter.java`            |
| BusinessDateFilter                      | `fineract-provider/.../security/filter/BusinessDateFilter.java`                         |
| TwoFactorAuthenticationFilter           | `fineract-provider/.../security/filter/TwoFactorAuthenticationFilter.java`              |
| FineractJwtAuthenticationTokenConverter | `fineract-provider/.../security/converter/FineractJwtAuthenticationTokenConverter.java` |
| FineractInstanceModeApiFilter           | `fineract-provider/.../instancemode/filter/FineractInstanceModeApiFilter.java`          |
| LoanCOBApiFilter                        | `fineract-provider/.../jobs/filter/LoanCOBApiFilter.java`                               |
| IdempotencyStoreFilter                  | `fineract-core/.../core/filters/IdempotencyStoreFilter.java`                            |
| CorrelationHeaderFilter                 | `fineract-core/.../core/filters/CorrelationHeaderFilter.java`                           |
| RequestResponseFilter                   | `fineract-core/.../core/filters/RequestResponseFilter.java`                             |
| CallerIpTrackingFilter                  | `fineract-core/.../core/filters/CallerIpTrackingFilter.java`                            |
