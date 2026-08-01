# Database Migrations with Atlas

This project uses a **Database-First** approach for migrations. Development is driven by manual changes to a PostgreSQL database, which are then captured as versioned migration scripts using [Atlas](https://atlasgo.io/).

It is structured as a Python project managed by **uv**.

---

## Environment Configuration

Copy the `.env.example` file to `.env` and adjust the variables to match your environment:

```bash
cp .env.example .env
```

### Configuration Variables
*   **Database Credentials (`DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASS`)**: Connection settings for target Postgres servers.
*   **Source Database (`SOURCE_DB`)**: Set to `quality_control` for development. The schema of this database is the source of truth for capturing new migrations.
*   **Target Databases (`TARGET_DBS`)**: A comma-separated list of database instances to migrate (e.g. `qc_stage_1,qc_stage_2`). This acts as the default targets if no databases are passed via the command line.

### Shadow Database (Atlas Internal)
*   **Database:** `atlas_dev`
*   **Purpose:** Used by Atlas as a "Shadow Database" to safely calculate the difference between your current migration files and the live database state. It is automatically managed by Atlas and should remain empty.

## Environment Setup

Before running Atlas for the first time, ensure the `atlas_dev` database exists:
```bash
psql -h localhost -U postgres -d postgres -c "CREATE DATABASE atlas_dev;"
```

---

## Project Setup (with uv)

First, make sure [uv](https://github.com/astral-sh/uv) is installed. Then, create the virtual environment and install dependencies:

```bash
# Sync dependencies
uv sync
```

Ensure the `atlas_dev` database exists on your PostgreSQL server:
```bash
psql -h localhost -U postgres -d postgres -c "CREATE DATABASE atlas_dev;"
```

### Baselining Existing Databases
If your target databases **already have the initial schema**, you must tell Atlas to start tracking without re-running the initial SQL:

You can use the helper CLI command:
```bash
./mdb init_migrations quality_control 20260725134952
```
Or directly via Atlas:
```bash
# Run this once for each existing database
atlas migrate apply \
  --url "postgres://postgres:Pass@word1@localhost:5432/target_db_name?sslmode=disable" \
  --dir "file://migrations" \
  --baseline "20260725134952"
```
*(Replace the baseline version with the timestamp of your actual initial migration file).*

---

## CLI Helper Tool (`manage.py`)

A python command-line helper tool is provided in `src/` to streamline the development, testing, and deployment operations. 

You can run the CLI tool using `uv run python src/manage.py <command>`.

**Windows Shortcut:**
On Windows, you can also use the shorthand batch script `mdb.bat`:
```cmd
.\mdb.bat <command>
```

### Available Commands:

1.  **Backup the development database** (`backup`):
    Creates a full backup (schema + data) of the `quality_control` database in `backups/`.
    ```bash
    uv run python src/manage.py backup
    ```

2.  **Restore the development database** (`restore`):
    Restores the `quality_control` database from a specified dump file, or the most recent one if no file is provided.
    ```bash
    # Restore specific backup:
    uv run python src/manage.py restore backups/qc_pg_dump_20260710_020631.sql
    
    # Restore latest backup:
    uv run python src/manage.py restore
    ```

3.  **Export current database schema & seed data** (`init`):
    Generates the baseline schema in `db_init/init_schema.sql` (runs `generate_init.py`).
    ```bash
    uv run python src/manage.py init
    ```

4.  **Generate a new migration script** (`diff`):
    Generates a versioned schema migration file using `atlas migrate diff`.
    ```bash
    uv run python src/manage.py diff <migration_name>
    ```

5.  **Finalize a release** (`finalize`):
    Concatenates migrations and records the release in `releases.json` (runs `finalize_release.py`).
    ```bash
    uv run python src/manage.py finalize "Release Description"
    ```

6.  **Restore snapshot and test migrations** (`test`):
    Recreates a test database, loads a snapshot, and verifies migrations apply cleanly (runs `test_migration.py`).
    ```bash
    uv run python src/manage.py test backups/qc_pg_dump_20260626_184558.sql
    ```

7.  **Deploy migrations to target databases** (`deploy`):
    Applies migrations to databases (runs `migrate_tenants.py`). You can pass database names as optional arguments, or it will fall back to default databases.
    ```bash
    # Deploy to defaults:
    uv run python src/manage.py deploy
    
    # Deploy to specific databases:
    uv run python src/manage.py deploy qc_db_1 qc_db_2
    ```

8.  **Initialize migrations with baseline** (`init_migrations`):
    Prepares an existing database for Atlas migrations by setting a baseline version without re-running prior migrations.
    ```bash
    ./mdb init_migrations <database_name> <baseline>

    # Example:
    ./mdb init_migrations quality_control 20260725134952
    ```

---

## Development Workflow

### 1. Manual Database Changes
Perform any necessary schema changes (tables, columns, indexes) or data seeding directly on the `quality_control` development database using your preferred SQL tool (e.g., pgAdmin, DBeaver).

### 2. Capture Migration
Once you are satisfied with the changes, use Atlas to generate a new migration script by comparing the current state of the `quality_control` database with the existing migration files.

```bash
# Generate a new migration file
atlas migrate diff <migration_name> \
  --to "postgres://postgres:Pass@word1@localhost:5432/quality_control?sslmode=disable" \
  --dev-url "postgres://postgres:Pass@word1@localhost:5432/atlas_dev?sslmode=disable" \
  --dir "file://migrations"
```

If you need to perform complex data migrations (e.g., transforming data while moving it between columns), you can manually edit the generated `.sql` file in the `migrations/` directory.

#### Adding Custom Logic to Migrations

Sometimes, Atlas cannot automatically determine how to migrate data (e.g., when splitting a `full_name` column into `first_name` and `last_name`). In these cases, follow these steps:

1.  **Generate the diff**: Run `atlas migrate diff <name>` as usual.
2.  **Edit the SQL**: Open the newly created `.sql` file in `migrations/` and add your custom DML (Data Manipulation Language) statements.
3.  **Update the Sum**: After editing any migration file manually, you **must** update the `atlas.sum` file:
    ```bash
    atlas migrate hash --dir "file://migrations"
    ```

#### Example 1: Data Transformation (Splitting Columns)
If you added `first_name` and `last_name` and want to populate them from an old `name` column:
```sql
-- Generated by Atlas:
ALTER TABLE "users" ADD COLUMN "first_name" varchar(255), ADD COLUMN "last_name" varchar(255);

-- Manual addition for data migration:
UPDATE "users" SET 
    "first_name" = split_part("name", ' ', 1),
    "last_name" = split_part("name", ' ', 2);

-- Generated by Atlas (cleanup):
ALTER TABLE "users" DROP COLUMN "name";
```

#### Example 2: Setting Default Values for Existing Rows
```sql
-- Add a new status column
ALTER TABLE "samples" ADD COLUMN "internal_status" varchar(50);

-- Populate existing rows based on logic
UPDATE "samples" SET "internal_status" = 'completed' WHERE "is_verified" = TRUE;
UPDATE "samples" SET "internal_status" = 'pending' WHERE "is_verified" = FALSE;

-- Make it NOT NULL after population
ALTER TABLE "samples" ALTER COLUMN "internal_status" SET NOT NULL;
```

### Merging & Squashing Migrations

If you have created many small migration files during development and want to merge them into a single "Release" script before deployment, you have two options:

#### Option A: Atlas Squash (Best for Schema-only)
This command takes all migration files and collapses them into one. 
**Warning:** Standard squashing re-calculates the schema diff and may ignore manual `UPDATE/INSERT` statements.
```bash
atlas migrate squash --dir "file://migrations"
```

#### Option B: Snapshot-to-Snapshot Diff (Best for Data-First)
This is the most reliable way to create a "Master" migration script using your `db_test` dumps:

1.  **Restore the Baseline**: Load your starting snapshot (e.g., `dump_0001.sql`) into a temporary database (or your `atlas_dev`).
2.  **Generate a Master Diff**: Compare that baseline directly against your current `quality_control` development database.
    ```bash
    atlas migrate diff master_release \
      --from "postgres://postgres:Pass@word1@localhost:5432/atlas_dev?sslmode=disable" \
      --to "postgres://postgres:Pass@word1@localhost:5432/quality_control?sslmode=disable" \
      --dev-url "postgres://postgres:Pass@word1@localhost:5432/atlas_dev?sslmode=disable" \
      --dir "file://migrations"
    ```
3.  **Manually Append Data Scripts**: Open the generated `master_release.sql` and copy/paste all the custom `UPDATE` logic you wrote during development into this one file.
4.  **Clean up**: Delete the old iterative migration files and run `atlas migrate hash`.

### Using Checkpoints

A **Checkpoint** is a special migration file that represents the entire schema state at a specific version. It is used to speed up migrations for new databases and provide a "source of truth".

#### 1. Create a Checkpoint
When you finalize a release, turn that state into a checkpoint:
```bash
# In the migrations directory
atlas migrate checkpoint --dir "file://migrations"
```
This will create a new migration file ending in `_checkpoint.sql`. This file contains the full `CREATE TABLE` statements for the entire database.

#### 2. Benefits for your Workflow
- **New Tenants**: When initializing a new tenant, Atlas will see the checkpoint and jump directly to it, applying only subsequent scripts.
- **Verification**: It acts as a baseline that is easier to manage than dozens of iterative files.

### 3. Snapshot for Testing (`backups/`)
Before and after significant changes, use a full database backup (schema + test data) from the `backups/` folder. These are used as reference points for testing the migration process.

Pattern: `qc_pg_dump_{DATE}_{TIME}.sql` (e.g., `qc_pg_dump_20260626_184558.sql`).

To create a dump:
```bash
pg_dump -U postgres --inserts -d quality_control -f backups/qc_pg_dump_{DATE}_{TIME}.sql
# or
pg_dump -h localhost -U postgres --inserts -d quality_control -F p > backups/qc_pg_dump_{DATE}_{TIME}.sql
```

### 4. Initialization Script (`db_init/`)
When a version is ready for deployment, update the initialization script in `db_init/`. This script should contain the latest schema and essential seed data (but NO test data). This is used for setting up new databases.

To generate this script automatically with the current schema and full content of `reception_types` and `value_types`:
```bash
uv run python generate_init.py
```

---

## Testing & Validation

Before deploying a release to live databases, you **must** verify that your migrations correctly update the previous version's snapshot.

### Automated Migration Test
The `test_migration.py` script automates this process by restoring a previous snapshot to a temporary database and then applying the migrations.

```bash
# Test starting from Version 1 snapshot
uv run python test_migration.py backups/qc_pg_dump_20260626_184558.sql
```

If successful, the script will output `✅ Migration test PASSED!`. You can then manually connect to the `atlas_migration_test` database to verify the final data state.

---

## Deployment to Database Instances

To deploy migrations to one or target databases, use the `migrate_tenants.py` script.

### Specifying Target Databases
You can specify which databases to migrate using one of three methods (in order of priority):
1.  **CLI Arguments**:
    ```bash
    uv run python migrate_tenants.py qc_db_1 qc_db_2
    ```
2.  **Environment Variable**: Set `TARGET_DBS` in `.env` (e.g. `TARGET_DBS=qc_db_1,qc_db_2`).
3.  **databases.txt**: Add database names line-by-line (one per line) in `database/databases.txt`.

### Execution and Rollback Behavior
- **Automatic Database Creation**: If any of the target databases do not exist, the migration runner automatically connects to the server and creates them on-the-fly before applying the migrations.
- **Transaction Protection**: Atlas runs migration scripts inside transactions. If a script fails, changes to that database are automatically rolled back.
- **Log Archiving**: Execution logs for all databases are created and saved under `database/logs/migration_YYYYMMDD_HHMMSS.log` containing stdout/stderr of Atlas commands.
- **Immediate Halt**: If a migration fails for any database in the list, the script immediately halts further migrations to prevent propagation, allowing for investigation.

---

## Release Management

A "Release" consists of:
1.  A set of **Migration Scripts** in `migrations/`.
2.  A reference **Test Snapshot** in `db_test/`.
3.  An updated **Initialization Script** in `db_init/`.
4.  A new record in the local `releases.json` tracking file.

### Release Checklist

#### 1. Finalize Migrations & Snapshots
Make sure all iterative scripts are squashed or finalized, and update the hash:
```bash
atlas migrate hash --dir "file://migrations"
```
Take a full reference snapshot dump:
```bash
pg_dump -h localhost -U postgres -d quality_control -F p > db_test/quality_control_pg_dump_0002.sql
```

#### 2. Update Initialization Script
Generate the latest `db_init/init_schema.sql`:
```bash
uv run python generate_init.py
```

#### 3. Register the Release
Use the `finalize_release.py` script to generate a consolidated release script and register it in `releases.json`:
```bash
uv run python finalize_release.py "Release Description (e.g. Release 1.1.0)"
```
This updates the local history, copies scripts to `releases/` (e.g., `releases/release_2_migration.sql` and `releases/release_2_init.sql`), and marks previous releases as obsolete.

#### 4. Run Deployments
Deploy the migration across staging database instances:
```bash
uv run python migrate_tenants.py qc_stage_1 qc_stage_2
```
If stage checks pass, deploy to production:
```bash
uv run python migrate_tenants.py qc_prod_1 qc_prod_2
```

### Rollback Strategy
If a migration fails for a specific tenant:
1.  **Atomic Transactions**: Atlas wraps each tenant migration in a transaction. If it fails, the tenant's database is automatically rolled back to its previous state.
2.  **Investigation**: Check the logs from `migrate_tenants.py` to identify the failing SQL statement.
3.  **Fix & Retry**: Fix the migration script in `migrations/`, run `atlas migrate hash`, and run `migrate_tenants.py` again. Only the failed/pending tenants will be processed.

---

## Unit Testing

To ensure the reliability of the administrative scripts, unit tests are provided under `database/tests`.

### Running Tests
You can run the pytest suite inside the virtual environment:
```bash
uv run pytest
```

### Coverage
The test suite covers:
- **`generate_init.py`**: Exports database schema and seed tables, and handles failure modes if pg_dump commands fail.
- **`test_migration.py`**: Deletes, creates, restores database snapshots, and verifies migration applications. Handles missing snapshots and command failures.
- **`finalize_release.py`**: Compiles migration scripts, updates local release status inside `releases.json`, creates version-specific release dumps, and handles missing prerequisites.
- **`migrate_tenants.py`**: Parses target databases from arguments/TXT files/ENV configurations, applies migrations, ensures transactional safety, writes outputs to logging files, and halts execution immediately on failure.
- **`manage.py`**: Verifies routing of command arguments.

All tests utilize mocks where necessary to avoid modifying any active production databases, and feature automated setup and teardown fixtures that restore your local database folder status when complete.


## Alternative: Manual Local Installation

Restore database in the local PostgreSQL instance, using just PostgreSQL command line tools.

### 1. Prerequisites
- **PostgreSQL** running locally with user `postgres` and password `Pass@word1`. 
  *(If your local PostgreSQL uses a different password, you can change it instantly from your command line:)*

  **On Windows:**
  ```cmd
  set PGPASSWORD=YourOldPassword
  psql -h localhost -p 5432 -U postgres -c "ALTER USER postgres WITH PASSWORD 'Pass@word1';"
  ```
  **On macOS / Linux:**
  ```bash
  PGPASSWORD=YourOldPassword psql -h localhost -p 5432 -U postgres -c "ALTER USER postgres WITH PASSWORD 'Pass@word1';"
  ```

### 2. Restore the Database
Create and restore the latest database backup (`backups/qc_pg_dump_20260725_130836.sql`):

**On Windows (Command Prompt / PowerShell):**
```cmd
dropdb -h localhost -p 5432 -U postgres -f --if-exists quality_control
createdb -h localhost -p 5432 -U postgres quality_control
set PGPASSWORD=Pass@word1
psql -h localhost -p 5432 -U postgres -d quality_control -f backups/qc_pg_dump_20260725_130836.sql
```

**On macOS / Linux:**
```bash
dropdb -h localhost -p 5432 -U postgres -f --if-exists quality_control
createdb -h localhost -p 5432 -U postgres quality_control
PGPASSWORD=Pass@word1 psql -h localhost -p 5432 -U postgres -d quality_control -f backups/qc_pg_dump_20260725_130836.sql
```



