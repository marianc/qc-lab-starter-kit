# Test Servers

This project provides an automated API testing framework for the Quality Control Laboratory Management System. It validates both API responses and database state changes natively using PostgreSQL.

## Prerequisites

1.  **Python 3.11+** and **[uv](https://github.com/astral-sh/uv)** installed.
2.  **Reference Server Running**: An instance of the chosen server (e.g. FastAPI/Blazor).
3.  **Reference Database**: The source schema and data reside in `src/db_test/quality_control_pg_test_seed.sql`.

## Setup

1.  Install dependencies:
    ```bash
    cd test_servers
    uv sync
    ```

2.  (Optional) Regenerate SQLAlchemy models if the schema changes:
    ```bash
    uv run sqlacodegen postgresql://postgres:Pass%40word1@localhost:5432/quality_control > src/models.py
    ```

3.  (Optional) Update test database schema if the development schema changes:
    ```bash
    # create test database
    createdb -U postgres quality_control_test_seed 

    # restore test database
    psql -U postgres -d quality_control_test_seed -f ./src/db_test/quality_control_pg_test_seed.sql

    # update schema for test database from development database
    atlas schema apply \
        --url "postgres://postgres:Pass@word1@localhost:5432/quality_control_test_seed?sslmode=disable" \
        --to "postgres://postgres:Pass@word1@localhost:5432/quality_control?sslmode=disable" \
        --exclude "atlas_schema_revisions" \
        --auto-approve

    # save schema and data for test database
    pg_dump -U postgres -d quality_control_test_seed --clean --if-exists --no-owner --no-privileges --attribute-inserts --file=./src/db_test/quality_control_pg_test_seed.sql
    ```

## Running Tests

The tests are built using `pytest`. They automatically handle database mapping, seeding via the `.sql` reference, and migration resets natively before relevant tests run.

### Run all tests
```bash
uv run pytest tests
```

### Run all tests except a specific module
```bash
uv run pytest tests --ignore=tests/test_signup.py
```

### Run tests for a specific module
```bash
uv run pytest tests/test_users.py
```

### Run a specific test case
```bash
uv run pytest tests/test_users.py::test_create_user
```

### View output (stdout)
Use the `-s` flag to see print statements or debug info:
```bash
uv run pytest -s tests/test_users.py
```

## How it Works

- **Database Initialization & Synchronization**: Upon starting a session, the framework connects to your PostgreSQL instance, creates a mock `quality_control_seed` database running the provided SQL dump, and cleans up itself via tear-down dropping logic. Before tests that modify data, the framework runs `src/data_migrations/migrate_to_postgresql.py` to seamlessly copy data over into your local app DB and sync identity sequences.
- **Authentication**: Fixtures in `tests/conftest.py` handle logging in as `alice@qc.lab` and maintaining a valid session cookie even after database resets.
- **Database Verification**: Tests use SQLAlchemy models in `src/models.py` to query the application database and verify that rows are correctly inserted, updated, or deleted as a result of API calls.

## Manual Migration & Utilities

- **Migrate Data**:
  - To PostgreSQL Target: `uv run src/data_migrations/migrate_to_postgresql.py`

## Database Reset Service

A lightweight web server is provided to allow external tools to trigger a database reset (migration) via an API call. It uses the current `TEST_SERVER` profile defined in `.env`.

### Start the service
```bash
cd test_servers
# To start the HTTP server (default)
uv run python src/reset_server.py

# To run the migration once and exit
uv run python src/reset_server.py once
```
The server will start on `http://localhost:8000`.

### Endpoints

- `PUT /reset_db`: Truncates the destination database tables and sequences, copying identical data structures from the seed Postgres database.
- `GET /health`: Returns the current profile and database type.

### Example usage (curl)
```bash
curl -X PUT http://localhost:8000/reset_db
```

## Licensing

This project may contain portions from other free and/or open source resources (e.g. code, documentation or binaries).
For more information on licensing please check [NOTICE.md](NOTICE.md) and the content of '_thirdPartyLicenses' folder located in this sub-project.
