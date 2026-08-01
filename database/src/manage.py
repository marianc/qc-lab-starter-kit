import os
import sys
import subprocess
import argparse
from dotenv import load_dotenv
import db_utils

# Load environment variables
load_dotenv()

DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "Pass@word1")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
SOURCE_DB = os.getenv("SOURCE_DB", "quality_control")

def ensure_correct_dir():
    """Ensure the script runs in the database folder context."""
    if os.path.basename(os.getcwd()) != "database":
        if os.path.exists("database"):
            os.chdir("database")

def run_command(cmd, desc="Running command"):
    print(f"\n🚀 {desc}...")
    print(f"Executing: {' '.join(cmd)}")
    result = subprocess.run(cmd)
    if result.returncode == 0:
        print("✅ Success!")
        return True
    else:
        print(f"❌ Failed with exit code {result.returncode}")
        return False

def cmd_backup(args):
    """Backup the development database."""
    ensure_correct_dir()
    db_utils.backup_db()

def cmd_restore(args):
    """Restore the development database from a backup."""
    ensure_correct_dir()
    db_utils.restore_db(args.dump_file)

def cmd_diff(args):
    """Generate a new migration script using Atlas."""
    ensure_correct_dir()
    name = args.name
    to_url = f"postgres://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{SOURCE_DB}?sslmode=disable"
    dev_url = f"postgres://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/atlas_dev?sslmode=disable"
    
    cmd = [
        "atlas", "migrate", "diff", name,
        "--to", to_url,
        "--dev-url", dev_url,
        "--dir", "file://migrations"
    ]
    run_command(cmd, f"Generating migration diff: {name}")

def cmd_init(args):
    """Generate the initial schema from the source database."""
    ensure_correct_dir()
    cmd = [sys.executable, os.path.join("src", "generate_init.py")]
    run_command(cmd, "Generating initialization SQL schema")

def cmd_test(args):
    """Test applying migrations on a dump snapshot database."""
    ensure_correct_dir()
    snapshot = args.snapshot
    cmd = [sys.executable, os.path.join("src", "test_migration.py"), snapshot]
    run_command(cmd, f"Testing migration starting from snapshot: {snapshot}")

def cmd_finalize(args):
    """Finalize a release locally in releases.json and releases/."""
    ensure_correct_dir()
    description = args.description
    cmd = [sys.executable, os.path.join("src", "finalize_release.py"), description]
    run_command(cmd, f"Finalizing release with description: '{description}'")

def cmd_deploy(args):
    """Deploy migrations to target databases."""
    ensure_correct_dir()
    cmd = [sys.executable, os.path.join("src", "migrate_tenants.py")]
    if args.databases:
        cmd.extend(args.databases)
    run_command(cmd, f"Deploying migrations to target databases: {', '.join(args.databases) if args.databases else 'configured defaults'}")

def cmd_init_migrations(args):
    """Prepare an existing database for atlas migrations using a baseline version."""
    ensure_correct_dir()
    database_name = args.database
    baseline_version = args.baseline
    
    url = f"postgres://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{database_name}?sslmode=disable"
    
    cmd = [
        "atlas", "migrate", "apply",
        "--dir", "file://migrations",
        "--url", url,
        "--baseline", baseline_version
    ]
    run_command(cmd, f"Initializing migrations for database '{database_name}' with baseline '{baseline_version}'")

def main():
    parser = argparse.ArgumentParser(
        description="QC Lab Database Migrations CLI helper tool."
    )
    subparsers = parser.add_subparsers(dest="command", required=True, help="Subcommand to run")

    # backup command
    parser_backup = subparsers.add_parser("backup", help="Backup the development database.")
    parser_backup.set_defaults(func=cmd_backup)

    # restore command
    parser_restore = subparsers.add_parser("restore", help="Restore the development database from a dump file.")
    parser_restore.add_argument("dump_file", nargs="?", help="Optional path to pg_dump SQL file. If not provided, restores the latest backup.")
    parser_restore.set_defaults(func=cmd_restore)

    # init command
    parser_init = subparsers.add_parser("init", help="Export latest quality_control schema & seed data to init_schema.sql.")
    parser_init.set_defaults(func=cmd_init)

    # diff command
    parser_diff = subparsers.add_parser("diff", help="Generate a new migration script comparing quality_control database to migrations.")
    parser_diff.add_argument("name", help="Name of the migration script.")
    parser_diff.set_defaults(func=cmd_diff)

    # finalize command
    parser_finalize = subparsers.add_parser("finalize", help="Register all pending migrations into a new release in releases.json.")
    parser_finalize.add_argument("description", help="Description of the release (e.g. 'Release 1.1.0').")
    parser_finalize.set_defaults(func=cmd_finalize)

    # test command
    parser_test = subparsers.add_parser("test", help="Restore a database snapshot and test applying migrations.")
    parser_test.add_argument("snapshot", help="Path to pg_dump snapshot SQL file (e.g. backups/qc_pg_dump_20260626_184558.sql).")
    parser_test.set_defaults(func=cmd_test)

    # deploy command
    parser_deploy = subparsers.add_parser("deploy", help="Apply migrations on target databases.")
    parser_deploy.add_argument("databases", nargs="*", help="Optional database names. If empty, uses configured default databases.")
    parser_deploy.set_defaults(func=cmd_deploy)

    # init_migrations command
    parser_init_mig = subparsers.add_parser("init_migrations", help="Prepare an existing database for atlas migrations with a baseline.")
    parser_init_mig.add_argument("database", help="Target database name.")
    parser_init_mig.add_argument("baseline", help="Baseline migration version (e.g. 20260725134952).")
    parser_init_mig.set_defaults(func=cmd_init_migrations)

    args = parser.parse_args()
    args.func(args)

if __name__ == "__main__":
    main()
