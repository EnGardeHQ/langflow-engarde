# Langflow Deployment Checklist

Complete checklist for deploying and validating the Langflow integration with EnGarde.

## Pre-Deployment Checklist

### 1. Environment Setup

- [ ] Docker installed (version 20.10+)
  ```bash
  docker --version
  ```

- [ ] Docker Compose installed (version 2.0+)
  ```bash
  docker-compose --version
  ```

- [ ] PostgreSQL client tools installed
  ```bash
  psql --version
  ```

- [ ] Required utilities available
  ```bash
  curl --version
  nc -h
  ```

### 2. Configuration Files

- [ ] Environment file created
  ```bash
  cp .env.example .env
  ```

- [ ] Database credentials configured in `.env`
  ```bash
  grep -E "POSTGRES_|LANGFLOW_" .env
  ```

- [ ] Langflow superuser credentials set (change defaults!)
  ```bash
  grep LANGFLOW_SUPERUSER .env
  ```

- [ ] All required environment variables present
  ```bash
  cat .env.example  # Reference for required vars
  ```

### 3. File Permissions

- [ ] All scripts are executable
  ```bash
  chmod +x /Users/cope/EnGardeHQ/scripts/*.sh
  chmod +x /Users/cope/EnGardeHQ/production-backend/docker/langflow/entrypoint.sh
  ```

- [ ] Verify permissions
  ```bash
  ls -l /Users/cope/EnGardeHQ/scripts/*.sh
  ```

### 4. Database Scripts

- [ ] Schema initialization scripts exist
  ```bash
  ls -l /Users/cope/EnGardeHQ/production-backend/scripts/init_schemas.sql
  ls -l /Users/cope/EnGardeHQ/production-backend/scripts/init-langflow-schema.sql
  ```

- [ ] Docker Compose volume mounts configured
  ```bash
  grep -A 5 "docker-entrypoint-initdb.d" /Users/cope/EnGardeHQ/docker-compose.yml
  ```

## Deployment Steps

### Phase 1: Infrastructure Startup

#### Step 1: Start PostgreSQL

- [ ] Start PostgreSQL container
  ```bash
  cd /Users/cope/EnGardeHQ
  docker-compose up -d postgres
  ```

- [ ] Wait for healthy status (30-60 seconds)
  ```bash
  docker-compose ps postgres
  # Should show "Up (healthy)"
  ```

- [ ] Verify database connection
  ```bash
  docker-compose exec postgres psql -U engarde_user -d engarde -c "SELECT version();"
  ```

- [ ] Check schemas were created
  ```bash
  docker-compose exec postgres psql -U engarde_user -d engarde -c "\dn"
  # Should show: public, langflow
  ```

#### Step 2: Start Redis

- [ ] Start Redis container
  ```bash
  docker-compose up -d redis
  ```

- [ ] Verify Redis is healthy
  ```bash
  docker-compose ps redis
  docker-compose exec redis redis-cli ping
  # Should return: PONG
  ```

### Phase 2: Langflow Database Initialization

#### Step 3: Initialize Langflow Schema

- [ ] Run initialization script
  ```bash
  /Users/cope/EnGardeHQ/scripts/init-langflow.sh
  ```

- [ ] Verify schema exists
  ```bash
  docker-compose exec postgres psql -U engarde_user -d engarde -c "
    SELECT schema_name FROM information_schema.schemata
    WHERE schema_name = 'langflow';
  "
  # Should return: langflow
  ```

- [ ] Verify langflow_user exists
  ```bash
  docker-compose exec postgres psql -U engarde_user -d engarde -c "\du langflow_user"
  ```

- [ ] Verify permissions
  ```bash
  docker-compose exec postgres psql -U engarde_user -d engarde -c "
    SELECT has_schema_privilege('langflow_user', 'langflow', 'CREATE');
  "
  # Should return: t
  ```

### Phase 3: Langflow Service Deployment

#### Step 4: Build Langflow Image

- [ ] Build Langflow Docker image
  ```bash
  docker-compose build langflow
  ```

- [ ] Verify image was created
  ```bash
  docker images | grep langflow
  ```

- [ ] Check image size (should be < 2GB)
  ```bash
  docker images | grep langflow | awk '{print $7}'
  ```

#### Step 5: Start Langflow Service

- [ ] Start Langflow container
  ```bash
  docker-compose up -d langflow
  ```

- [ ] Monitor startup logs
  ```bash
  docker-compose logs -f langflow
  # Wait for "Application startup complete" or "Uvicorn running"
  # Press Ctrl+C after confirmation
  ```

- [ ] Verify container is running
  ```bash
  docker-compose ps langflow
  # Should show: Up
  ```

- [ ] Wait for health check to pass (60-90 seconds)
  ```bash
  docker inspect --format='{{.State.Health.Status}}' engarde_langflow
  # Should show: healthy
  ```

### Phase 4: Validation

#### Step 6: Run Validation Script

- [ ] Execute comprehensive validation
  ```bash
  /Users/cope/EnGardeHQ/scripts/validate-langflow.sh
  ```

- [ ] Verify all tests pass
  ```
  Expected output:
  ========================================
  ✓ ALL CRITICAL TESTS PASSED
  ========================================
  ```

- [ ] Review any warnings (acceptable if non-critical)

#### Step 7: Manual Health Checks

- [ ] Check health endpoint
  ```bash
  curl -f http://localhost:7860/health
  # Should return: 200 OK
  ```

- [ ] Check API endpoint
  ```bash
  curl -I http://localhost:7860/api/v1/version
  # Should return: 200 or 401 (auth required)
  ```

- [ ] Access Web UI
  ```bash
  open http://localhost:7860
  # or curl http://localhost:7860 | grep -i langflow
  ```

- [ ] Verify login works
  ```
  URL: http://localhost:7860
  Username: admin (or your configured LANGFLOW_SUPERUSER)
  Password: admin (or your configured LANGFLOW_SUPERUSER_PASSWORD)
  ```

### Phase 5: Integration Testing

#### Step 8: Database Integration

- [ ] Verify Langflow tables were created
  ```bash
  docker-compose exec postgres psql -U langflow_user -d engarde -c "\dt langflow.*"
  # Should show Langflow tables (flow, user, etc.)
  ```

- [ ] Check cross-schema access
  ```bash
  docker-compose exec postgres psql -U engarde_user -d engarde -c "
    SELECT COUNT(*) FROM information_schema.tables
    WHERE table_schema = 'langflow';
  "
  # Should return: > 0
  ```

- [ ] Verify EnGarde can read Langflow schema
  ```bash
  docker-compose exec postgres psql -U engarde_user -d engarde -c "
    SELECT has_schema_privilege('engarde_user', 'langflow', 'USAGE');
  "
  # Should return: t
  ```

#### Step 9: Network Integration

- [ ] Verify all containers on same network
  ```bash
  docker network inspect engarde_network --format '{{range .Containers}}{{.Name}} {{end}}'
  # Should include: postgres, redis, langflow
  ```

- [ ] Test container-to-container connectivity
  ```bash
  docker-compose exec langflow ping -c 3 postgres
  docker-compose exec langflow ping -c 3 redis
  ```

#### Step 10: Volume Persistence

- [ ] Verify volumes exist
  ```bash
  docker volume ls | grep langflow
  # Should show: langflow_logs, langflow_data
  ```

- [ ] Check log files are being written
  ```bash
  docker-compose exec langflow ls -lh /app/logs/
  ```

- [ ] Verify custom components are mounted
  ```bash
  docker-compose exec langflow ls -R /app/custom_components/
  ```

## Post-Deployment Verification

### Security Checks

- [ ] Default credentials changed
  ```bash
  grep LANGFLOW_SUPERUSER_PASSWORD .env
  # Should NOT be "admin"
  ```

- [ ] Database passwords are strong
  ```bash
  grep -E "PASSWORD" .env | grep -v "admin\|password\|changeme"
  ```

- [ ] Secrets not in version control
  ```bash
  git status .env
  # Should show: ignored or not tracked
  ```

### Performance Checks

- [ ] Memory usage acceptable
  ```bash
  docker stats engarde_langflow --no-stream
  # Check MEM USAGE %
  ```

- [ ] Database connection pool configured
  ```bash
  docker-compose exec langflow printenv | grep POOL
  # Should show LANGFLOW_POOL_SIZE and MAX_OVERFLOW
  ```

- [ ] Redis cache working
  ```bash
  docker-compose exec redis redis-cli INFO stats
  # Check keyspace_hits and keyspace_misses
  ```

### Monitoring Setup

- [ ] Log aggregation configured
  ```bash
  docker-compose logs langflow | tail -20
  # Verify logs are structured and readable
  ```

- [ ] Health check interval appropriate
  ```bash
  grep -A 5 "langflow:" docker-compose.yml | grep interval
  # Should be: 30s or similar
  ```

- [ ] Restart policy set
  ```bash
  grep -A 10 "langflow:" docker-compose.yml | grep restart
  # Should be: unless-stopped or always
  ```

## Production Readiness Checklist

### Critical Items

- [ ] SSL/TLS configured for database connections
- [ ] All default passwords changed
- [ ] Firewall rules configured (only necessary ports exposed)
- [ ] Backup strategy implemented
- [ ] Monitoring and alerting configured
- [ ] Log rotation configured
- [ ] Resource limits set in docker-compose.yml
- [ ] Health checks passing consistently

### Recommended Items

- [ ] Redis persistence enabled
- [ ] Database replication configured
- [ ] Automated backups scheduled
- [ ] Disaster recovery plan documented
- [ ] Performance baseline established
- [ ] Load testing completed
- [ ] Documentation updated
- [ ] Team trained on management scripts

### Optional Items

- [ ] External secrets management (Vault, AWS Secrets Manager)
- [ ] Service mesh integration
- [ ] Distributed tracing configured
- [ ] A/B testing framework
- [ ] Blue-green deployment pipeline
- [ ] Canary deployment capability

## Rollback Procedure

If deployment fails at any step:

### Quick Rollback

```bash
# 1. Stop Langflow
docker-compose stop langflow

# 2. Check logs for errors
docker-compose logs --tail=100 langflow

# 3. Try restart
/Users/cope/EnGardeHQ/scripts/restart-langflow.sh --rebuild
```

### Full Rollback

```bash
# 1. Complete cleanup
/Users/cope/EnGardeHQ/scripts/cleanup-langflow.sh --full --yes

# 2. Fix issues in configuration

# 3. Redeploy from scratch
/Users/cope/EnGardeHQ/scripts/init-langflow.sh
docker-compose up -d langflow
/Users/cope/EnGardeHQ/scripts/validate-langflow.sh
```

## Troubleshooting Reference

### Common Issues

| Symptom | Likely Cause | Solution |
|---------|-------------|----------|
| Container won't start | Missing schema | Run `init-langflow.sh` |
| Health check failing | Service not ready | Wait 60s, check logs |
| Permission denied | Wrong DB user | Check DATABASE_URL in .env |
| Port already in use | Another service on 7860 | Stop conflicting service or change port |
| Out of memory | Insufficient resources | Increase Docker memory limit |

### Quick Diagnostic Commands

```bash
# View all service status
docker-compose ps

# Check logs for errors
docker-compose logs --tail=50 langflow | grep -i error

# Test database connection
docker-compose exec postgres psql -U langflow_user -d engarde -c "SELECT 1;"

# Check port availability
nc -zv localhost 7860

# Monitor resource usage
docker stats --no-stream
```

## Success Criteria

Deployment is successful when:

- [ ] All validation tests pass
- [ ] Web UI accessible at http://localhost:7860
- [ ] Login works with configured credentials
- [ ] Health endpoint returns 200 OK
- [ ] Database tables created in langflow schema
- [ ] Cross-schema queries work
- [ ] No critical errors in logs
- [ ] Memory usage < 80%
- [ ] Health check status: healthy
- [ ] Container restart policy active

## Next Steps

After successful deployment:

1. **Create first flow**: Test workflow creation in UI
2. **Configure integrations**: Set up EnGarde backend integration
3. **Set up monitoring**: Configure external monitoring
4. **Schedule backups**: Implement backup automation
5. **Document workflows**: Create team documentation
6. **Train team**: Share management scripts and procedures

## Support Resources

- **Setup Documentation**: `/Users/cope/EnGardeHQ/LANGFLOW_SETUP.md`
- **Scripts Reference**: `/Users/cope/EnGardeHQ/scripts/README.md`
- **Docker Compose**: `/Users/cope/EnGardeHQ/docker-compose.yml`
- **Validation Script**: `/Users/cope/EnGardeHQ/scripts/validate-langflow.sh`

---

**Version**: 1.0.0
**Last Updated**: 2025-10-05
**Deployment Date**: ________________
**Deployed By**: ____________________
**Sign-off**: _______________________
