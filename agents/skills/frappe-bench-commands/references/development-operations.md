# Development Operations

## Start Development Server

### Standard Start
```bash
bench start
```

Starts all services:
- Web server (port 8000)
- SocketIO server (port 9000)
- Schedule (background jobs)
- Worker (queue processing)

### Background Start
```bash
bench start &
```

Runs bench in background. Output is still visible in terminal.

## Stop Development Server

### Foreground Process
```
Ctrl+C
```

Stops bench if running in foreground.

### Background/Stuck Processes
```bash
pkill -SIGINT -f bench
pkill -SIGINT -f socketio
```

Forcefully stops all bench and socketio processes.

**VS Code Task:** "Clean Honcho SocketIO Watch Schedule Worker" - Runs the same cleanup.

**When to use:**
- Server won't stop with Ctrl+C
- Orphaned processes after debugging
- Port conflicts

## Build Assets

### Build All Apps
```bash
bench build
```

Builds production assets for all apps (JS, CSS, etc.).

**When to run:**
- After JavaScript/CSS changes
- After pulling code updates
- After installing new apps
- Before production deployment

### Build Specific App
```bash
bench build --app soldamundo
```

Faster - only rebuilds assets for the specified app.

### Clear Cache and Rebuild
```bash
bench clear-cache
bench build
```

**Use when:**
- Assets aren't updating
- Seeing stale JavaScript
- After configuration changes

## Watch Assets (Development)

### Frappe Watch Mode
```bash
bench watch
```

Watches for file changes and automatically rebuilds assets.

**Best for:** Frappe/ERPNext JavaScript development

### Nuxt Development Server (soldamundo)
```bash
cd apps/soldamundo && yarn dev
```

Starts Nuxt dev server with hot reload.

**Best for:** Nuxt/Vue frontend development in soldamundo app

## Clear Cache

### Clear All Caches
```bash
bench clear-cache
```

Clears all caches across all sites and apps.

### Clear Specific Site Cache
```bash
bench --site development.localhost clear-cache
```

Clears cache only for the specified site.

**When to clear cache:**
- After code changes not reflecting
- After configuration changes
- After DocType modifications
- Strange behavior or errors

## Developer Mode

### Enable Developer Mode
```bash
bench --site development.localhost set-config developer_mode 1
bench --site development.localhost clear-cache
```

**Benefits:**
- Automatic DocType reloading
- Detailed error pages
- JavaScript source maps
- No asset caching
- Better debugging tools

### Disable Developer Mode
```bash
bench --site development.localhost set-config developer_mode 0
```

**Best Practices:**
- Always enable for development
- Disable for production
- Clear cache after toggling

## Reload DocType

```bash
bench --site development.localhost reload-doctype "DocType Name"
```

Reloads a specific DocType from JSON definition.

**Use when:**
- DocType JSON changes not reflecting
- Manual DocType modifications
- Fixing DocType corruption

## Common Development Workflow

```bash
# 1. Start with clean slate
bench clear-cache

# 2. Make code changes
# ... edit files ...

# 3. Rebuild if needed
bench build --app myapp

# 4. Restart server to see changes
pkill -SIGINT -f bench
bench start
```

## Frontend Development Workflow

### For Frappe/ERPNext JavaScript
```bash
# Terminal 1: Start bench
bench start

# Terminal 2: Watch for changes
bench watch
```

### For Nuxt (soldamundo app)
```bash
# Terminal 1: Start bench
bench start

# Terminal 2: Start Nuxt dev server
cd apps/soldamundo && yarn dev
```

## Troubleshooting

### Assets Not Updating
```bash
bench clear-cache
bench build
pkill -SIGINT -f bench
bench start
```

### Port Already in Use
```bash
# Kill existing processes
pkill -SIGINT -f bench
pkill -SIGINT -f socketio

# Check ports
lsof -i :8000
lsof -i :9000

# Start again
bench start
```

### Build Errors
```bash
# Clear node_modules and reinstall
cd apps/frappe && yarn install
cd ../soldamundo && yarn install

# Rebuild
bench build
```
