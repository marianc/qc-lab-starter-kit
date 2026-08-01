import os
import subprocess
from datetime import datetime

# Configuration
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "Pass@word1")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
SOURCE_DB = os.getenv("SOURCE_DB", "quality_control")

BACKUP_DIR = "backups"

def run_command(cmd, env, input_file=None):
    """Run a subprocess command with environment variables and optional stdin."""
    if input_file:
        result = subprocess.run(cmd, env=env, stdin=input_file, capture_output=True, text=True)
    else:
        result = subprocess.run(cmd, env=env, capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"Error executing command: {' '.join(cmd)}")
        print(f"Error: {result.stderr}")
        return False
    return True

def get_env():
    env = os.environ.copy()
    env["PGPASSWORD"] = DB_PASS
    return env

def backup_db():
    if not os.path.exists(BACKUP_DIR):
        os.makedirs(BACKUP_DIR)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"qc_pg_dump_{timestamp}.sql"
    filepath = os.path.join(BACKUP_DIR, filename)
    
    print(f"Creating backup: {filepath}...")
    
    env = get_env()
    with open(filepath, "w", encoding="utf-8") as f:
        cmd = [
            "pg_dump",
            "-h", DB_HOST,
            "-p", DB_PORT,
            "-U", DB_USER,
            "--inserts",
            "-d", SOURCE_DB
        ]
        result = subprocess.run(cmd, env=env, stdout=f, stderr=subprocess.PIPE, text=True)
    
    if result.returncode == 0:
        print(f"Backup created successfully: {filepath}")
        return True
    else:
        print(f"Backup failed: {result.stderr}")
        if os.path.exists(filepath):
            os.remove(filepath)
        return False

def restore_db(dump_file=None):
    if not dump_file:
        files = [f for f in os.listdir(BACKUP_DIR) if f.startswith("qc_pg_dump_") and f.endswith(".sql")]
        if not files:
            print("No backup files found.")
            return False
        dump_file = os.path.join(BACKUP_DIR, max(files))
    
    if not os.path.exists(dump_file):
        print(f"Dump file not found: {dump_file}")
        return False

    print(f"Restoring database '{SOURCE_DB}' from: {dump_file}...")
    
    env = get_env()
    
    # 1. Drop existing database
    print("Dropping existing database...")
    run_command(["psql", "-h", DB_HOST, "-p", DB_PORT, "-U", DB_USER, "-d", "postgres", "-c", f"DROP DATABASE IF EXISTS {SOURCE_DB} WITH (FORCE);"], env=env)
    
    # 2. Create database
    print("Creating new database...")
    run_command(["psql", "-h", DB_HOST, "-p", DB_PORT, "-U", DB_USER, "-d", "postgres", "-c", f"CREATE DATABASE {SOURCE_DB};"], env=env)
    
    # 3. Restore dump
    print("Restoring data...")
    with open(dump_file, "r", encoding="utf-8") as f:
        success = run_command(["psql", "-h", DB_HOST, "-p", DB_PORT, "-U", DB_USER, "-d", SOURCE_DB], env=env, input_file=f)
    
    if success:
        print(f"Database restored successfully from {dump_file}")
    return success
