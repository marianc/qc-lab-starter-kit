import os
import sys
import subprocess
import psycopg2
from psycopg2 import sql
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

MIGRATIONS_DIR = "file://migrations"
LOGS_DIR = "logs"

DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "Pass@word1")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")

def get_target_databases():
    """Determines target databases from CLI args, environment variable, or databases.txt."""
    # 1. From CLI arguments
    if len(sys.argv) > 1:
        return sys.argv[1:]

    # 2. From env variable
    env_dbs = os.getenv("TARGET_DBS")
    if env_dbs:
        return [db.strip() for db in env_dbs.split(",") if db.strip()]

    # 3. From databases.txt
    if os.path.exists("databases.txt"):
        try:
            with open("databases.txt", "r", encoding="utf-8") as f:
                dbs = [line.strip() for line in f if line.strip() and not line.strip().startswith("#")]
                if dbs:
                    return dbs
        except Exception as e:
            print(f"Warning: Failed to read databases.txt: {e}")

    return []

def database_exists(db_name):
    """Checks if a database exists in the PostgreSQL catalog."""
    try:
        conn = psycopg2.connect(
            user=DB_USER,
            password=DB_PASS,
            host=DB_HOST,
            port=DB_PORT,
            database="postgres"
        )
        conn.autocommit = True
        cur = conn.cursor()
        cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (db_name,))
        exists = cur.fetchone() is not None
        cur.close()
        conn.close()
        return exists
    except Exception as e:
        print(f"Warning: Failed to check existence of database '{db_name}': {e}")
        return False

def create_database(db_name):
    """Creates a database in PostgreSQL."""
    try:
        conn = psycopg2.connect(
            user=DB_USER,
            password=DB_PASS,
            host=DB_HOST,
            port=DB_PORT,
            database="postgres"
        )
        conn.autocommit = True
        cur = conn.cursor()
        cur.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(db_name)))
        cur.close()
        conn.close()
        print(f"Created missing database: '{db_name}'")
        return True
    except Exception as e:
        print(f"Error creating database '{db_name}': {e}")
        return False

def seed_database(db_name):
    """Applies initial seed data from seed_data/initial_seed.sql to the database."""
    seed_path = os.path.join("seed_data", "initial_seed.sql")
    if not os.path.exists(seed_path):
        print(f"Warning: Seed file not found at {seed_path}")
        return True

    print(f"Seeding database: {db_name}...")
    env = os.environ.copy()
    env["PGPASSWORD"] = DB_PASS
    try:
        with open(seed_path, "r", encoding="utf-8") as f:
            result = subprocess.run(
                ["psql", "-h", DB_HOST, "-p", DB_PORT, "-U", DB_USER, "-d", db_name],
                env=env, stdin=f, capture_output=True, text=True
            )
        if result.returncode != 0:
            print(f"Warning/Error seeding database {db_name}: {result.stderr}")
            # If primary key conflicts occur due to idempotent re-seeding, we can log or ignore, or let it output
            return False
        print(f"Successfully seeded database {db_name}.")
        return True
    except Exception as e:
        print(f"Exception occurred while seeding database {db_name}: {e}")
        return False

def apply_migrations(db_name):
    """Applies pending Atlas migrations to a specific database."""
    print(f"\n--- Migrating Database: {db_name} ---")
    
    # Check if database exists, create if missing
    if not database_exists(db_name):
        print(f"Database '{db_name}' does not exist. Creating it...")
        if not create_database(db_name):
            return False, f"Database '{db_name}' does not exist and could not be created.", ""

    db_url = f"postgres://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{db_name}?sslmode=disable"
    
    # Verify connectivity first
    try:
        conn = psycopg2.connect(
            user=DB_USER,
            password=DB_PASS,
            host=DB_HOST,
            port=DB_PORT,
            database=db_name
        )
        conn.close()
    except Exception as e:
        err_msg = f"Failed to connect to database '{db_name}': {e}"
        print(err_msg)
        return False, err_msg, ""

    try:
        # Run Atlas migrate apply
        result = subprocess.run(
            ["atlas", "migrate", "apply", "--url", db_url, "--dir", MIGRATIONS_DIR],
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            print(f"Error applying migrations to {db_name}:")
            print(result.stderr)
            return False, result.stderr, result.stdout
            
        print(f"Successfully applied migrations to {db_name}.")
        if result.stdout:
            print(result.stdout)
            
        # Seed database after successful migration apply
        seed_database(db_name)

        return True, "", result.stdout
    except Exception as e:
        err_msg = f"Exception occurred while applying migrations to {db_name}: {e}"
        print(err_msg)
        return False, err_msg, ""

def main():
    # Ensure we are in the correct directory if run from project root
    if os.path.basename(os.getcwd()) != "database":
        if os.path.exists("database"):
            os.chdir("database")

    databases = get_target_databases()
    if not databases:
        print("Error: No target databases specified.")
        print("Please provide them as CLI arguments:")
        print("  python migrate_tenants.py db_name1 db_name2")
        print("Or set the TARGET_DBS environment variable in .env, or create a 'databases.txt' file.")
        sys.exit(1)

    os.makedirs(LOGS_DIR, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file_path = os.path.join(LOGS_DIR, f"migration_{timestamp}.log")

    print(f"Starting migration run for: {', '.join(databases)}")
    print(f"Migration details will be logged to: {log_file_path}")

    results = {}
    success_count = 0
    failure_count = 0

    log_content = []
    log_content.append(f"Migration run started at: {datetime.now().isoformat()}")
    log_content.append(f"Target databases: {', '.join(databases)}")
    log_content.append("=" * 60 + "\n")

    for db_name in databases:
        success, error_output, std_output = apply_migrations(db_name)
        status = "PASS" if success else "FAIL"
        results[db_name] = status
        
        log_content.append(f"Database: {db_name}")
        log_content.append(f"Status: {status}")
        if std_output:
            log_content.append("--- Atlas Output ---")
            log_content.append(std_output)
        if error_output:
            log_content.append("--- Error Output ---")
            log_content.append(error_output)
        log_content.append("-" * 40 + "\n")

        if success:
            success_count += 1
        else:
            failure_count += 1
            # If migration fails, we halt further migrations per user instructions:
            # "if the migration was not successful the database rolled back to the previous state and all the migration process was halted for investigation"
            log_content.append(f"HALTING migration process due to failure on {db_name}.")
            print(f"\n❌ Migration failed on database: {db_name}. Halting all further migrations.")
            break

    log_content.append("=" * 60)
    log_content.append("Migration Run Summary:")
    for db, stat in results.items():
        log_content.append(f"  {db}: {stat}")
    log_content.append(f"Total attempted: {len(results)}")
    log_content.append(f"Successes: {success_count}")
    log_content.append(f"Failures: {failure_count}")
    log_content.append(f"Migration run ended at: {datetime.now().isoformat()}")

    # Write log file
    try:
        with open(log_file_path, "w", encoding="utf-8") as lf:
            lf.write("\n".join(log_content))
    except Exception as e:
        print(f"Warning: Failed to write to log file: {e}")

    # Output CLI summary
    print("\n--- Migration Summary ---")
    for db, stat in results.items():
        print(f"{db}: {stat}")
    
    print(f"\nDetails logged to: {log_file_path}")

    if failure_count > 0:
        sys.exit(1)
    else:
        print("\n✅ All migrations completed successfully.")

if __name__ == "__main__":
    main()
