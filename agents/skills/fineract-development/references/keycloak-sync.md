# Keycloak Sync Module

The `fineract-keycloak-sync` module is a **standalone Spring Boot sidecar service** that synchronizes Fineract permissions, roles, and users into Keycloak. It runs alongside Fineract and Keycloak as an independent microservice.

**Direction:** One-way (Fineract DB → Keycloak Admin API)
**Port:** 8085 (configurable via `SYNC_SERVER_PORT`)

## Module Location

```
fineract-keycloak-sync/
  src/main/java/org/apache/fineract/keycloak/sync/
    KeycloakSyncApplication.java          # Entry point
    config/
      KeycloakProperties.java             # Keycloak connection config
      SyncProperties.java                 # Sync behavior config
      KeycloakAdminClientConfig.java      # Keycloak admin client bean
      ShedLockConfig.java                 # Distributed locking
    domain/
      FineractUser.java                   # Read-only projection of m_appuser
      FineractRole.java                   # Read-only projection of m_role
      FineractPermission.java             # Read-only projection of m_permission
      SyncCheckpoint.java                 # Sync state tracking
    repository/
      FineractUserRepository.java
      FineractRoleRepository.java
      FineractPermissionRepository.java
      SyncCheckpointRepository.java
    service/
      KeycloakAdminService.java           # Keycloak Admin API facade
      PermissionSyncService.java          # Permission → client role sync
      RoleSyncService.java                # Role → composite realm role sync
      UserSyncService.java                # User attribute + role assignment sync
      SyncCheckpointService.java          # Checkpoint management
    scheduler/
      SyncScheduler.java                  # Cron-based scheduler
    web/
      SyncController.java                 # Manual sync REST API
    health/
      KeycloakHealthIndicator.java        # Health check
  src/main/resources/
    application.yml                       # Configuration
    db/migration/
      V1__create_sync_tables.sql          # Flyway migration
```

## Entry Point

```java
@SpringBootApplication
@EnableScheduling
@EnableRetry
public class KeycloakSyncApplication {
    public static void main(String[] args) {
        SpringApplication.run(KeycloakSyncApplication.class, args);
    }
}
```

- `@EnableScheduling` — activates cron-based scheduled tasks
- `@EnableRetry` — enables Spring Retry for resilient Keycloak API calls

## Configuration

### Keycloak Connection (`KeycloakProperties`)

```java
@ConfigurationProperties(prefix = "keycloak")
public class KeycloakProperties {
    private String serverUrl;      // KC_SERVER_URL (default: http://localhost:8080)
    private String realm;          // KC_REALM (default: master)
    private String clientId;       // KC_FINERACT_CLIENT_ID (default: fineract-api)
    private String clientSecret;   // KC_FINERACT_CLIENT_SECRET
    private String adminUsername;  // KC_ADMIN_USERNAME
    private String adminPassword;  // KC_ADMIN_PASSWORD
}
```

### Sync Behavior (`SyncProperties`)

```java
@ConfigurationProperties(prefix = "sync")
public class SyncProperties {
    private String tenantId;        // FINERACT_TENANT_ID (default: "default")
    private String rolePrefix;      // SYNC_ROLE_PREFIX (default: "fineract")
    private int batchSize = 200;    // SYNC_BATCH_SIZE

    // Cron expressions
    private Cron cron;              // permissions: every 5 min, roles: every 5 min, users: every 2 min

    // Retry config
    private Retry retry;            // maxAttempts: 3, initialDelay: 1000ms, multiplier: 2.0x

    // Per-dimension toggles
    private Enabled enabled;        // permissions: true, roles: true, users: true

    // Converts "Super user" → "fineract:super-user"
    public String toKeycloakRoleName(String fineractRoleName) { ... }
}
```

### Key Environment Variables

| Variable                   | Default                                             | Description                  |
| -------------------------- | --------------------------------------------------- | ---------------------------- |
| `FINERACT_DB_URL`          | `jdbc:postgresql://localhost:5432/fineract_default` | Fineract database URL        |
| `KC_SERVER_URL`            | `http://localhost:8080`                             | Keycloak server URL          |
| `KC_REALM`                 | `master`                                            | Target Keycloak realm        |
| `KC_FINERACT_CLIENT_ID`    | `fineract-api`                                      | OAuth2 client ID             |
| `FINERACT_TENANT_ID`       | `default`                                           | Fineract tenant identifier   |
| `SYNC_BATCH_SIZE`          | `200`                                               | User pagination batch size   |
| `SYNC_ROLE_PREFIX`         | `fineract`                                          | Keycloak realm role prefix   |
| `SYNC_CRON_USERS`          | `0 */2 * * * *`                                     | User sync cron (every 2 min) |
| `SYNC_PERMISSIONS_ENABLED` | `true`                                              | Toggle permission sync       |

## Database Schema

Uses **Flyway** (not Liquibase) with schema `keycloak_sync`:

```sql
-- V1__create_sync_tables.sql
CREATE TABLE IF NOT EXISTS sync_checkpoint (
    entity_type   VARCHAR(50)  NOT NULL,
    state_hash    VARCHAR(64)  NOT NULL,
    last_sync_at  TIMESTAMP    NOT NULL DEFAULT NOW(),
    duration_ms   BIGINT       DEFAULT 0,
    synced_count  INTEGER      DEFAULT 0,
    error_count   INTEGER      DEFAULT 0,
    last_error    TEXT,
    PRIMARY KEY (entity_type)
);

CREATE TABLE IF NOT EXISTS shedlock (
    name       VARCHAR(64)  NOT NULL,
    lock_until TIMESTAMP    NOT NULL,
    locked_at  TIMESTAMP    NOT NULL,
    locked_by  VARCHAR(255) NOT NULL,
    PRIMARY KEY (name)
);
```

## Sync Strategy: Incremental Hash-Based Reconciliation

All three sync dimensions use the same approach:

1. Read all entities from Fineract DB in **deterministic order** (by ID)
2. Compute **SHA-256 hash** of the current state
3. Compare hash with last checkpoint — **skip if unchanged**
4. If changed: diff against Keycloak and apply minimal changes
5. Record new checkpoint with hash, timestamp, metrics

This avoids redundant Keycloak API calls when data hasn't changed.

## Sync Dimensions

### Permission Sync (Fineract permissions → Keycloak client roles)

**Service:** `PermissionSyncService`

- Reads ~951 permissions from `m_permission`
- Creates Keycloak **client roles** on the `fineract-api` client
- Deletes orphaned client roles no longer in Fineract
- Description format: `[Synced] {grouping} – {actionName} {entityName}`

### Role Sync (Fineract roles → Keycloak composite realm roles)

**Service:** `RoleSyncService`

Mapping:

```
Fineract "Super user" → Keycloak realm role "fineract:super-user"
  └── composites: [client roles for all assigned permissions]
```

- Creates/updates **realm roles** with composite permission mappings
- Disabled roles get `[DISABLED]` prefix in description
- Only manages roles with the configured prefix (won't touch other realm roles)
- Permission changes propagate automatically via Keycloak composites

### User Sync (Fineract users → Keycloak user attributes + role assignments)

**Service:** `UserSyncService`

- **Paginated** (batch size 200) to handle large user sets
- Per-user hash includes: id, username, officeId, staffId, enabled, role list
- Compares with Keycloak user's `_sync_hash` attribute
- Synced attributes: `tenant_id`, `branch_id`, `user_id`, `staff_id`
- Creates missing users with `UPDATE_PASSWORD` required action
- Reconciles realm role assignments (adds missing, removes stale)

## Scheduler

```java
@Scheduled(cron = "${sync.cron.permissions}")
@SchedulerLock(name = "syncPermissions", lockAtLeastFor = "30s", lockAtMostFor = "5m")
public void syncPermissions()

@Scheduled(cron = "${sync.cron.roles}")
@SchedulerLock(name = "syncRoles", lockAtLeastFor = "30s", lockAtMostFor = "5m")
public void syncRoles()

@Scheduled(cron = "${sync.cron.users}")
@SchedulerLock(name = "syncUsers", lockAtLeastFor = "30s", lockAtMostFor = "10m")
public void syncUsers()
```

- **ShedLock** prevents concurrent execution across multiple instances
- Each dimension can be individually disabled via `sync.enabled.*`
- Dependency order: permissions → roles → users

## REST API (Manual Triggers)

Base path: `/api/v1/sync`

| Method | Path                       | Description                             |
| ------ | -------------------------- | --------------------------------------- |
| `POST` | `/api/v1/sync/permissions` | Trigger permission sync                 |
| `POST` | `/api/v1/sync/roles`       | Trigger role sync                       |
| `POST` | `/api/v1/sync/users`       | Trigger user sync                       |
| `POST` | `/api/v1/sync/all`         | Full sync (permissions → roles → users) |

Response format:

```json
{ "entity": "permissions", "changes": 5 }
```

## Health Check

`KeycloakHealthIndicator` verifies Keycloak connectivity via server-info call:

```
GET /actuate/health → { "status": "UP", "components": { "keycloakHealthIndicator": { "status": "UP", "details": { "keycloak_version": "26.2.5" } } } }
```

## Observability (Micrometer)

| Metric                      | Type    | Description                    |
| --------------------------- | ------- | ------------------------------ |
| `sync.permissions.duration` | Timer   | Permission sync execution time |
| `sync.permissions.synced`   | Counter | Total permission changes       |
| `sync.permissions.errors`   | Counter | Permission sync failures       |
| `sync.roles.duration`       | Timer   | Role sync execution time       |
| `sync.roles.synced`         | Counter | Total role changes             |
| `sync.users.duration`       | Timer   | User sync execution time       |
| `sync.users.synced`         | Counter | Users created/updated          |
| `sync.users.skipped`        | Counter | Users with unchanged hash      |
| `sync.users.errors`         | Counter | User sync errors               |

Prometheus scrape endpoint: `/actuate/prometheus`

## Keycloak Admin Service

`KeycloakAdminService` wraps the Keycloak Admin REST API with `@Retryable` (3 attempts, exponential backoff):

**Client Role Operations:** `getClientRoles()`, `createClientRoleIfAbsent()`, `deleteClientRole()`
**Realm Role Operations:** `getRealmRoles()`, `createRealmRoleIfAbsent()`, `updateRealmRole()`, `deleteRealmRole()`, `setRealmRoleComposites()`
**User Operations:** `findUserByUsername()`, `updateUserAttributes()`, `reconcileUserRealmRoles()`, `createUser()`

## Key Dependencies

- `org.keycloak:keycloak-admin-client:26.2.5` — Keycloak Admin API
- `org.flywaydb:flyway-core` + `flyway-database-postgresql` — Migrations
- `net.javacrumbs.shedlock:shedlock-spring:6.3.1` — Distributed locking
- `org.springframework.retry:spring-retry` — Retry logic
- `io.micrometer:micrometer-registry-prometheus` — Metrics
- `org.postgresql:postgresql` — Database driver

## Docker Deployment

```yaml
fineract-keycloak-sync:
  image: ghcr.io/beninfintech/fineract-keycloak-sync:${VERSION}
  ports:
    - '8085:8085'
  environment:
    FINERACT_DB_URL: jdbc:postgresql://postgres:5432/fineract_default
    KC_SERVER_URL: http://keycloak:8080
    KC_REALM: master
    KC_FINERACT_CLIENT_ID: fineract-api
    KC_FINERACT_CLIENT_SECRET: ${KEYCLOAK_CLIENT_SECRET}
    KC_ADMIN_USERNAME: admin
    KC_ADMIN_PASSWORD: ${KEYCLOAK_ADMIN_PASSWORD}
    FINERACT_TENANT_ID: default
  depends_on:
    - postgres
    - keycloak
```

Built via Jib: `./gradlew :fineract-keycloak-sync:jibDockerBuild`
