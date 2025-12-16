# EnGarde Agent Deployment Checklist

**Quick reference for all deployment and code change tasks**

---

## 1. PRE-TASK CHECKLIST

```
□ Read and understand the user's request completely
□ Identify change type: code / config / dependency / schema / Docker
□ Check current Docker environment status (docker ps)
□ Verify which services will be affected
□ Plan the deployment approach (hot-reload vs rebuild)
□ Identify verification criteria for success
```

---

## 2. DURING TASK EXECUTION

### For Code Changes
```
□ Make file modifications in correct directory
□ Verify watch mode will pick up changes (or plan rebuild)
□ Check file permissions and ownership
□ Update related documentation if needed
□ Track all files modified for documentation
```

### For Docker Changes
```
□ Identify correct Docker Compose file (dev/staging/production)
□ Preserve data volumes unless explicitly told to delete
□ Use appropriate flags: --build / --no-cache / --force-recreate
□ Monitor startup logs during deployment
□ Verify health checks pass after startup
```

### For Dependency Changes
```
□ Update requirements.txt or package.json
□ Plan service rebuild (cannot hot-reload dependencies)
□ Document new dependency purpose
□ Check for version conflicts
□ Verify compatibility with existing code
```

### For Database/Schema Changes
```
□ Create migration file if applicable
□ Backup data if needed
□ Test migration in development first
□ Verify schema changes applied
□ Update models/types if needed
```

---

## 3. VERIFICATION CHECKLIST (MANDATORY)

**Never skip these steps - verify every deployment**

```
□ Container status: All required containers running and healthy
□ Service endpoints: Responding correctly (curl or browser test)
□ Hot-reload: Working as expected (if applicable)
□ Error logs: No critical errors in service logs
□ User-facing changes: Visible and functioning correctly
□ Browser cache: Cleared if frontend changes not visible
□ Performance: No degradation or increased latency
□ Database: Connections working, queries executing
```

---

## 4. DOCUMENTATION CHECKLIST

```
□ Document what was changed (files, services, configs)
□ Document why it was changed (purpose, issue resolved)
□ Update relevant README or documentation files
□ Note any breaking changes or migration requirements
□ Record commands used for future reference
```

---

## 5. COMPLETION CHECKLIST

```
□ All verification steps passed successfully
□ No errors or warnings in logs
□ Changes are visible and working locally
□ User informed of results with details
□ Task marked complete in todo list
□ Environment is stable and healthy
```

---

## 6. COMMON SCENARIOS QUICK REFERENCE

### Scenario: Python Code Change
```
□ Edit file in production-backend/app/
□ Watch for uvicorn reload message in logs
□ Test endpoint with curl or Postman
□ Verify no import or syntax errors
□ Check response format and data
```

### Scenario: React Component Change
```
□ Edit file in production-frontend/src/
□ Watch for "Fast Refresh" or webpack reload message
□ Check browser console for errors
□ Verify visual changes render correctly
□ Test component functionality
```

### Scenario: Add New Python Dependency
```
□ Update production-backend/requirements.txt
□ Run: docker compose -f docker-compose.dev.yml up --build backend
□ Watch logs for successful pip install
□ Verify import works in Python code
□ Test functionality that uses new package
```

### Scenario: Add New npm Package
```
□ Update production-frontend/package.json
□ Run: docker compose -f docker-compose.dev.yml up --build frontend
□ Watch logs for successful npm install
□ Verify import/usage in React code
□ Check for dependency conflicts or warnings
```

### Scenario: Environment Variable Change
```
□ Update appropriate .env file (.env, .env.dev, etc.)
□ Restart affected services (down + up or restart)
□ Verify new variable loaded (check logs or test endpoint)
□ Test functionality that depends on the variable
□ Update .env.example if variable should be documented
```

### Scenario: Database Schema Change
```
□ Create migration file or update schema definition
□ Backup database if production/staging
□ Run migration command
□ Verify schema changes in database
□ Update backend models/types to match
□ Test CRUD operations on affected tables
```

### Scenario: Nginx/Proxy Configuration
```
□ Update nginx config file
□ Test config syntax (nginx -t in container)
□ Reload or restart nginx service
□ Test routing with curl or browser
□ Verify SSL/TLS if applicable
```

### Scenario: Full Environment Rebuild
```
□ Document current state and reason for rebuild
□ Run: ./scripts/dev-rebuild.sh
□ Monitor rebuild logs for errors
□ Verify all services start successfully
□ Run full verification checklist
□ Test critical user flows
```

---

## 7. EMERGENCY PROCEDURES

### If Services Fail to Start
```
□ Check logs immediately: ./scripts/dev-logs.sh
□ Identify error messages and root cause
□ Check docker ps for container status
□ Verify ports not in use by other processes
□ Check disk space and Docker resources
```

### If Changes Don't Appear
```
□ Verify file was saved correctly
□ Check volume mounts in docker-compose.yml
□ Verify watch mode is running (check logs)
□ Clear browser cache (Ctrl+Shift+R)
□ Check file permissions in container
□ Rebuild if hot-reload not applicable
```

### If Errors Occur After Deployment
```
□ Check dev-health.sh output for service status
□ Review error logs for all affected services
□ Verify environment variables loaded correctly
□ Check database connection and schema
□ Test with curl to isolate frontend vs backend issues
```

### If Environment Is Unstable
```
□ Try restart: docker compose -f docker-compose.dev.yml restart
□ If restart fails: Run ./scripts/dev-rebuild.sh
□ Check for conflicting processes on ports
□ Verify Docker daemon is healthy
□ Check system resources (CPU, memory, disk)
```

### If Completely Broken (NUCLEAR OPTION)
```
□ Confirm with user before proceeding
□ Run: ./scripts/dev-reset.sh
□ WARNING: This destroys all data volumes
□ Wait for complete rebuild
□ Run full verification checklist
□ Restore data from backup if needed
```

---

## 8. QUICK COMMAND REFERENCE

### Check Status
```bash
docker ps                                    # Container status
./scripts/dev-health.sh                      # Health check all services
./scripts/dev-logs.sh                        # View all logs
docker compose -f docker-compose.dev.yml logs -f [service]  # Single service logs
```

### Common Operations
```bash
# Restart service with rebuild
docker compose -f docker-compose.dev.yml up --build [service]

# Restart without rebuild
docker compose -f docker-compose.dev.yml restart [service]

# Full rebuild
./scripts/dev-rebuild.sh

# Nuclear reset (DELETES DATA)
./scripts/dev-reset.sh
```

### Debugging
```bash
# Execute commands in container
docker compose -f docker-compose.dev.yml exec [service] sh

# Check container logs
docker logs [container-name]

# Inspect container
docker inspect [container-name]

# Check volumes
docker volume ls
```

---

## 9. VALIDATION CRITERIA

**Before marking any task complete, ensure:**

```
□ All affected services are running (docker ps shows "healthy")
□ No ERROR or CRITICAL messages in logs
□ Changes are visible and functional
□ Tests pass (if applicable)
□ Documentation updated
□ User can verify the change
□ Environment is stable for next task
```

---

## 10. BEST PRACTICES

```
□ Always verify before marking complete
□ Document unexpected issues encountered
□ Keep changes focused and atomic
□ Test thoroughly in development first
□ Preserve data unless explicitly told to delete
□ Ask for clarification when requirements unclear
□ Use hot-reload when possible (faster)
□ Rebuild when necessary (dependencies, configs)
□ Monitor logs during and after changes
□ Communicate status and results clearly
```

---

**Remember: Quality over speed. A properly verified deployment prevents future issues.**

**Last Updated:** 2025-10-29
