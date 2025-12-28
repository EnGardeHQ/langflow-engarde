# EasyAppointments PostgreSQL Configuration

## ✅ Yes, EasyAppointments Supports PostgreSQL!

EasyAppointments uses CodeIgniter framework which supports PostgreSQL via the 'postgre' driver.

## Changes Made

### 1. Dockerfile Updated
- ✅ Added `libpq-dev` (PostgreSQL client library)
- ✅ Changed PHP extensions from `pdo_mysql` to `pdo_pgsql` and `pgsql`
- ✅ Container now supports PostgreSQL connections

### 2. Database Configuration Updated
- ✅ Changed driver from `'mysqli'` to `'postgre'`
- ✅ Updated character set from `utf8mb4` to `utf8` (PostgreSQL standard)
- ✅ Updated collation to `utf8_general_ci`

## Railway Environment Variables

Since you're using PostgreSQL in Railway, update your environment variables:

### Remove MySQL Variables:
- ❌ Remove: `DB_HOST`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`, `DB_PORT` (MySQL references)

### Add PostgreSQL Variables:
```
Variable Name: DB_HOST
Value: ${{Postgres.PGHOST}}
(Click "Reference" button and select Postgres → PGHOST)

Variable Name: DB_NAME  
Value: ${{Postgres.PGDATABASE}}
(Click "Reference" button and select Postgres → PGDATABASE)

Variable Name: DB_USERNAME
Value: ${{Postgres.PGUSER}}
(Click "Reference" button and select Postgres → PGUSER)

Variable Name: DB_PASSWORD
Value: ${{Postgres.PGPASSWORD}}
(Click "Reference" button and select Postgres → PGPASSWORD)

Variable Name: DB_PORT
Value: ${{Postgres.PGPORT}}
(Click "Reference" button and select Postgres → PGPORT)
```

**Note:** Railway PostgreSQL service provides these variables:
- `PGHOST` - Database host
- `PGDATABASE` - Database name
- `PGUSER` - Database user
- `PGPASSWORD` - Database password
- `PGPORT` - Database port (usually 5432)

## Railway Setup Steps

1. **Add PostgreSQL Database:**
   - In Railway project dashboard
   - Click "New" → "Database" → "PostgreSQL"
   - Wait for provisioning

2. **Update Environment Variables:**
   - Go to EasyAppointments service → Variables
   - Remove old MySQL variables
   - Add PostgreSQL variables using Railway reference syntax (see above)

3. **Redeploy:**
   - Railway will automatically redeploy with new variables

## Database Configuration File

The `application/config/database.php` file is now configured for PostgreSQL:
- Driver: `'postgre'`
- Character set: `'utf8'`
- Uses environment variables: `Config::DB_HOST`, `Config::DB_NAME`, etc.

## Verification

After deployment, check Railway logs:
- Should see successful database connection
- No MySQL-related errors
- EasyAppointments installation wizard should connect to PostgreSQL

## Migration from MySQL to PostgreSQL

If you have existing MySQL data:
1. Export MySQL data
2. Convert to PostgreSQL format (may need manual adjustments)
3. Import to PostgreSQL database
4. Run EasyAppointments installation wizard (it will detect existing tables)

## Notes

- PostgreSQL driver in CodeIgniter: `'postgre'` (not `'postgresql'`)
- Port is usually 5432 for PostgreSQL
- Character set is `utf8` (not `utf8mb4` like MySQL)
- EasyAppointments tables will be created with `ea_` prefix
