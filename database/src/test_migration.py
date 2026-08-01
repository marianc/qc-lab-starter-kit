import subprocess
import os
import sys

from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Configuration
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "Pass@word1")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
TEST_DB = os.getenv("TEST_DB", "atlas_migration_test")
MIGRATIONS_DIR = "file://migrations"

def run_psql(db_name, command):
    env = os.environ.copy()
    env["PGPASSWORD"] = DB_PASS
    result = subprocess.run(
        ["psql", "-h", DB_HOST, "-p", DB_PORT, "-U", DB_USER, "-d", db_name, "-c", command],
        env=env, capture_output=True, text=True
    )
    return result

def setup_test_db():
    print(f"Recreating test database: {TEST_DB}...")
    run_psql("postgres", f"DROP DATABASE IF EXISTS {TEST_DB} WITH (FORCE);")
    run_psql("postgres", f"CREATE DATABASE {TEST_DB};")

def restore_snapshot(snapshot_path):
    print(f"Restoring snapshot: {snapshot_path}...")
    env = os.environ.copy()
    env["PGPASSWORD"] = DB_PASS
    # Use psql to restore plain text dump
    with open(snapshot_path, "r") as f:
        result = subprocess.run(
            ["psql", "-h", DB_HOST, "-p", DB_PORT, "-U", DB_USER, "-d", TEST_DB],
            env=env, stdin=f, capture_output=True, text=True
        )
    if result.returncode != 0:
        print(f"Error restoring snapshot: {result.stderr}")
        return False
    return True

def test_apply():
    print("Applying migrations to test database...")
    db_url = f"postgres://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{TEST_DB}?sslmode=disable"
    result = subprocess.run(
        ["atlas", "migrate", "apply", "--url", db_url, "--dir", MIGRATIONS_DIR, "--baseline", "20260725134952"],
        capture_output=True, text=True
    )
    print(result.stdout)
    if result.returncode != 0:
        print(f"Migration failed!\n{result.stderr}")
        return False
    return True

def main():
    if len(sys.argv) < 2:
        print("Usage: python test_migration.py <snapshot_file_path>")
        print("Example: python test_migration.py backups/qc_pg_dump_20260626_184558.sql")
        sys.exit(1)

    snapshot = sys.argv[1]
    if not os.path.exists(snapshot):
        print(f"Snapshot not found: {snapshot}")
        sys.exit(1)

    setup_test_db()
    if restore_snapshot(snapshot):
        if test_apply():
            print("\n✅ Migration test PASSED!")
            print(f"The database '{TEST_DB}' is now at the latest version and can be inspected.")
        else:
            print("\n❌ Migration test FAILED!")
            sys.exit(1)

if __name__ == "__main__":
    if os.path.basename(os.getcwd()) != "db_migrations":
        if os.path.exists("db_migrations"):
            os.chdir("db_migrations")
    main()
