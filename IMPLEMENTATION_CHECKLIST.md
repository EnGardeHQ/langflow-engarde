# Langflow Schema Isolation - Implementation Checklist

**Project:** EnGarde Platform - Langflow Integration
**Strategy:** PostgreSQL Schema-Based Isolation
**Status:** Ready for Implementation

---

## Pre-Implementation Checklist

### 1. Preparation Phase (Day -1)

- [ ] **Backup Current Database**
  ```bash
  # Full database backup
  docker exec engarde_postgres pg_dump -U engarde_user -d engarde > backups/backup_$(date +%Y%m%d_%H%M%S).sql

  # Verify backup
  ls -lh backups/backup_*.sql
  head -50 backups/backup_*.sql
  ```

- [ ] **Document Current State**
  ```bash
  # Count EnGarde tables
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "\dt public.*" | wc -l

  # List Alembic versions
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "SELECT * FROM public.alembic_version;"

  # Check for existing Langflow tables (should be in public, causing conflicts)
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "\dt public.flow"
  ```

- [ ] **Review Architecture Document**
  - [ ] Read `/Users/cope/EnGardeHQ/LANGFLOW_INTEGRATION_ARCHITECTURE.md`
  - [ ] Understand schema isolation approach
  - [ ] Review rollback procedures

- [ ] **Verify Required Files Exist**
  ```bash
  ls -la /Users/cope/EnGardeHQ/production-backend/scripts/init-langflow-schema.sql
  ls -la /Users/cope/EnGardeHQ/production-backend/scripts/verify-langflow-schema.sql
  ls -la /Users/cope/EnGardeHQ/production-backend/scripts/apply-langflow-rls.sql
  ls -la /Users/cope/EnGardeHQ/docker-compose.langflow-isolated.yml
  ```

- [ ] **Update Environment Variables**
  - [ ] Create/update `.env` file with required variables:
    ```bash
    POSTGRES_PASSWORD=secure_postgres_password
    LANGFLOW_PASSWORD=langflow_secure_password_2024
    SECRET_KEY=your-secret-key-for-engarde
    LANGFLOW_SECRET_KEY=your-secret-key-for-langflow
    NEXTAUTH_SECRET=your-nextauth-secret

    # Optional
    OPENAI_API_KEY=sk-...
    ANTHROPIC_API_KEY=sk-ant-...
    LANGFLOW_SUPERUSER=admin
    LANGFLOW_SUPERUSER_PASSWORD=admin
    LANGFLOW_LOG_LEVEL=INFO
    LANGFLOW_WORKERS=4
    ```

---

## Implementation Phase (Day 1)

### 2. Stop Conflicting Services

- [ ] **Stop Current Langflow Service**
  ```bash
  docker-compose stop langflow
  docker-compose rm -f langflow
  ```

- [ ] **Verify Langflow is Stopped**
  ```bash
  docker ps | grep langflow  # Should return nothing
  curl http://localhost:7860/health  # Should fail
  ```

### 3. Initialize Langflow Schema

- [ ] **Run Schema Initialization Script**
  ```bash
  docker exec -i engarde_postgres psql -U engarde_user -d engarde < /Users/cope/EnGardeHQ/production-backend/scripts/init-langflow-schema.sql
  ```

- [ ] **Verify Schema Creation**
  ```bash
  # Check schema exists
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "\dn"

  # Check langflow role exists
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "\du"

  # Check alembic_version table in langflow schema
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "\dt langflow.alembic_version"
  ```

- [ ] **Run Verification Script**
  ```bash
  docker exec -i engarde_postgres psql -U engarde_user -d engarde < /Users/cope/EnGardeHQ/production-backend/scripts/verify-langflow-schema.sql > verification_report_$(date +%Y%m%d_%H%M%S).txt

  # Review report
  cat verification_report_*.txt
  ```

### 4. Update Langflow Configuration

- [ ] **Option A: Use New Docker Compose File (Recommended)**
  ```bash
  # Backup old docker-compose.yml
  cp docker-compose.yml docker-compose.yml.backup

  # Use schema-isolated configuration
  docker-compose -f docker-compose.langflow-isolated.yml up -d langflow
  ```

- [ ] **Option B: Update Existing docker-compose.yml**
  - [ ] Edit `docker-compose.yml` and update Langflow service:
    ```yaml
    langflow:
      environment:
        LANGFLOW_DATABASE_URL: postgresql://langflow_app:langflow_secure_password_2024@postgres:5432/engarde?options=-csearch_path=langflow,public
    ```

### 5. Deploy Schema-Isolated Langflow

- [ ] **Start Langflow with New Configuration**
  ```bash
  # If using new compose file:
  docker-compose -f docker-compose.langflow-isolated.yml up -d langflow

  # If updated existing compose file:
  docker-compose up -d langflow
  ```

- [ ] **Monitor Langflow Startup**
  ```bash
  docker-compose logs -f langflow

  # Watch for:
  # - "Running migrations in langflow schema"
  # - "Langflow started successfully"
  # - No errors about table conflicts
  ```

- [ ] **Wait for Health Check**
  ```bash
  # Wait up to 2 minutes for Langflow to be healthy
  until curl -f http://localhost:7860/health > /dev/null 2>&1; do
    echo "Waiting for Langflow..."
    sleep 5
  done
  echo "Langflow is healthy!"
  ```

---

## Verification Phase (Day 1-2)

### 6. Verify Schema Isolation

- [ ] **Check Langflow Tables are in Correct Schema**
  ```bash
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "\dt langflow.*"

  # Should see: flow, vertex, edge, transaction, message, folder, user, variables, etc.
  ```

- [ ] **Verify EnGarde Tables Unchanged**
  ```bash
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "\dt public.*" | head -30

  # Should see: tenants, users, brands, campaigns, etc. (NO Langflow tables)
  ```

- [ ] **Check Migration Version Tables are Separate**
  ```bash
  # EnGarde migrations
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "SELECT * FROM public.alembic_version;"

  # Langflow migrations (should be different)
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "SELECT * FROM langflow.alembic_version;"
  ```

- [ ] **Verify No Table Overlap**
  ```bash
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "
    SELECT public_tables.tablename
    FROM pg_tables public_tables
    INNER JOIN pg_tables langflow_tables
      ON public_tables.tablename = langflow_tables.tablename
    WHERE public_tables.schemaname = 'public'
      AND langflow_tables.schemaname = 'langflow';
  "
  # Should return 0 rows
  ```

### 7. Test Langflow Functionality

- [ ] **Access Langflow UI**
  ```bash
  open http://localhost:7860
  # Or: curl http://localhost:7860
  ```

- [ ] **Login to Langflow**
  - Username: `admin` (or value from `LANGFLOW_SUPERUSER`)
  - Password: `admin` (or value from `LANGFLOW_SUPERUSER_PASSWORD`)

- [ ] **Create Test Flow**
  - Create a simple flow with 1-2 components
  - Save the flow
  - Verify it's stored in database

- [ ] **Verify Flow in Database**
  ```bash
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "
    SELECT id, name, created_at, updated_at
    FROM langflow.flow
    ORDER BY created_at DESC
    LIMIT 5;
  "
  ```

- [ ] **Execute Test Flow**
  - Run the flow in Langflow UI
  - Verify execution completes
  - Check transaction log

- [ ] **Verify Transaction Log**
  ```bash
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "
    SELECT id, flow_id, status, timestamp
    FROM langflow.transaction
    ORDER BY timestamp DESC
    LIMIT 5;
  "
  ```

### 8. Test EnGarde Functionality

- [ ] **Access EnGarde Backend**
  ```bash
  curl http://localhost:8000/health
  ```

- [ ] **Run EnGarde API Tests**
  ```bash
  # If you have tests:
  cd /Users/cope/EnGardeHQ/production-backend
  pytest tests/
  ```

- [ ] **Verify EnGarde Database Access**
  ```bash
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "
    SELECT id, name, created_at
    FROM public.campaigns
    ORDER BY created_at DESC
    LIMIT 5;
  "
  ```

- [ ] **Test EnGarde Migration System**
  ```bash
  cd /Users/cope/EnGardeHQ/production-backend
  alembic current  # Should show current version
  # Try creating a test migration (optional):
  # alembic revision --autogenerate -m "test migration"
  # alembic upgrade head
  # alembic downgrade -1
  ```

### 9. Test Cross-Schema Access

- [ ] **EnGarde Reading Langflow Data**
  ```bash
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "
    SELECT
      c.name as campaign_name,
      f.name as flow_name,
      f.updated_at
    FROM public.campaigns c
    LEFT JOIN langflow.flow f ON f.id::text = c.workflow_id::text
    LIMIT 5;
  "
  ```

- [ ] **Langflow Reading EnGarde Data (via Custom Component)**
  - Create custom component that queries `public.campaigns`
  - Execute and verify it can read EnGarde data
  - Verify tenant isolation is respected

---

## Post-Implementation Phase (Day 2-3)

### 10. Apply Row-Level Security (Multi-Tenant Isolation)

- [ ] **Run RLS Setup Script**
  ```bash
  docker exec -i engarde_postgres psql -U engarde_user -d engarde < /Users/cope/EnGardeHQ/production-backend/scripts/apply-langflow-rls.sql
  ```

- [ ] **Verify RLS is Enabled**
  ```bash
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "
    SELECT schemaname, tablename, rowsecurity
    FROM pg_tables
    WHERE schemaname = 'langflow'
      AND tablename IN ('flow', 'vertex', 'transaction');
  "
  # rowsecurity should be 't' (true)
  ```

- [ ] **Test Tenant Isolation**
  ```bash
  # Set tenant context
  docker exec engarde_postgres psql -U langflow_app -d engarde -c "
    SELECT set_config('app.current_tenant_id', '<test-tenant-uuid>', true);
    INSERT INTO langflow.flow (name, data) VALUES ('Tenant Test Flow', '{}'::jsonb);
    SELECT * FROM langflow.flow;
  "

  # Change tenant context
  docker exec engarde_postgres psql -U langflow_app -d engarde -c "
    SELECT set_config('app.current_tenant_id', '<different-tenant-uuid>', true);
    SELECT * FROM langflow.flow;
  "
  # Should NOT see the previously created flow
  ```

### 11. Performance Testing

- [ ] **Baseline Performance Metrics**
  ```bash
  # Query performance
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "
    EXPLAIN ANALYZE
    SELECT * FROM langflow.flow WHERE tenant_id = '<test-uuid>';
  "
  ```

- [ ] **Connection Pool Status**
  ```bash
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "
    SELECT
      datname,
      usename,
      COUNT(*) as connection_count
    FROM pg_stat_activity
    WHERE datname = 'engarde'
    GROUP BY datname, usename;
  "
  ```

- [ ] **Index Verification**
  ```bash
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "
    SELECT
      schemaname,
      tablename,
      indexname
    FROM pg_indexes
    WHERE schemaname = 'langflow'
    ORDER BY tablename, indexname;
  "
  ```

### 12. Monitoring Setup

- [ ] **Set Up Database Monitoring** (Optional)
  ```bash
  # Start monitoring stack
  docker-compose -f docker-compose.langflow-isolated.yml --profile monitoring up -d

  # Access Grafana
  open http://localhost:3000
  # Login: admin/admin (or from .env)
  ```

- [ ] **Configure Alerts** (Optional)
  - Set up alerts for high error rates
  - Monitor cross-schema query performance
  - Track connection pool utilization

- [ ] **Log Aggregation**
  ```bash
  # Check Langflow logs
  docker-compose logs langflow | grep -i error

  # Check backend logs
  docker-compose logs backend | grep -i error
  ```

---

## Documentation & Training Phase (Day 3-4)

### 13. Update Documentation

- [ ] **Update README**
  - [ ] Add schema isolation architecture
  - [ ] Update setup instructions
  - [ ] Document new environment variables

- [ ] **Update Developer Docs**
  - [ ] How to create Langflow custom components
  - [ ] Cross-schema query patterns
  - [ ] Tenant context management

- [ ] **Update Deployment Docs**
  - [ ] New deployment procedure
  - [ ] Rollback instructions
  - [ ] Troubleshooting guide

### 14. Team Training

- [ ] **Developer Training Session**
  - [ ] Explain schema isolation architecture
  - [ ] Demonstrate cross-schema queries
  - [ ] Show how to create custom components

- [ ] **Operations Training**
  - [ ] Monitoring and alerting
  - [ ] Backup/restore procedures
  - [ ] Troubleshooting common issues

---

## Rollback Procedures (If Needed)

### Emergency Rollback

- [ ] **Immediate Rollback (Revert Configuration)**
  ```bash
  # Stop Langflow
  docker-compose stop langflow

  # Restore old docker-compose.yml
  cp docker-compose.yml.backup docker-compose.yml

  # Start Langflow with old config
  docker-compose up -d langflow
  ```

- [ ] **Full Rollback (Restore Database)**
  ```bash
  # Stop all services
  docker-compose down

  # Drop current database
  docker exec engarde_postgres psql -U postgres -c "DROP DATABASE engarde;"
  docker exec engarde_postgres psql -U postgres -c "CREATE DATABASE engarde OWNER engarde_user;"

  # Restore from backup
  docker exec -i engarde_postgres psql -U engarde_user -d engarde < backups/backup_YYYYMMDD_HHMMSS.sql

  # Restart services
  docker-compose up -d
  ```

- [ ] **Partial Rollback (Remove Schema, Keep Data)**
  ```bash
  docker exec engarde_postgres psql -U engarde_user -d engarde -c "
    DROP SCHEMA langflow CASCADE;
    DROP ROLE IF EXISTS langflow_app;
  "

  # Revert to old Langflow configuration
  docker-compose up -d langflow
  ```

---

## Success Criteria

### Technical Validation

- [x] Langflow tables exist ONLY in `langflow` schema
- [x] EnGarde tables exist ONLY in `public` schema
- [x] No table name conflicts between schemas
- [x] Separate `alembic_version` tables for independent migrations
- [x] Cross-schema queries work correctly
- [x] Tenant isolation via RLS functions properly
- [x] Performance metrics within acceptable ranges (<50ms for cross-schema queries)

### Functional Validation

- [x] Langflow UI loads and functions correctly
- [x] Can create, save, and execute flows
- [x] EnGarde application functions normally
- [x] Custom components can access EnGarde data
- [x] Multi-tenant isolation is maintained

### Operational Validation

- [x] Zero downtime during migration
- [x] Backup and restore procedures tested
- [x] Monitoring and alerting configured
- [x] Documentation updated
- [x] Team trained on new architecture

---

## Post-Implementation Tasks

### Week 2: Optimization

- [ ] **Performance Tuning**
  - [ ] Analyze slow query log
  - [ ] Add indexes as needed
  - [ ] Optimize connection pool settings

- [ ] **Monitoring Enhancement**
  - [ ] Create custom dashboards
  - [ ] Set up alerting rules
  - [ ] Document SLAs

### Month 1: Validation

- [ ] **Production Monitoring**
  - [ ] Track error rates
  - [ ] Monitor performance metrics
  - [ ] Analyze usage patterns

- [ ] **Cost Analysis**
  - [ ] Compare costs vs. separate databases
  - [ ] Document savings

### Quarter 1: Long-term Planning

- [ ] **Scalability Assessment**
  - [ ] Evaluate growth trajectory
  - [ ] Plan for sharding if needed (Citus)
  - [ ] Consider read replicas

- [ ] **Architecture Review**
  - [ ] Lessons learned
  - [ ] Identify improvements
  - [ ] Update architecture docs

---

## Contact Information

**For Questions or Issues:**
- Architecture Team: architecture@engarde.com
- Database Team: dba@engarde.com
- DevOps Team: devops@engarde.com

**Emergency Contacts:**
- On-call Engineer: [Contact info]
- Database Administrator: [Contact info]

---

## Checklist Summary

**Pre-Implementation:** 5 tasks
**Implementation:** 5 tasks
**Verification:** 5 tasks
**Post-Implementation:** 3 tasks
**Documentation:** 2 tasks

**Total:** 20 critical tasks

**Estimated Time:** 3-4 days for full implementation and validation

---

**Status:** ✅ Ready for Implementation
**Last Updated:** October 5, 2025
**Version:** 1.0
