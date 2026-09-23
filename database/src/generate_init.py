import subprocess
import os
import sys
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Configuration
DB_NAME = os.getenv("SOURCE_DB", "quality_control")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "Pass@word1")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
OUTPUT_FILE = "db_init/init_schema.sql"
SEED_TABLES = ["reception_types", "value_types", "reagent_lot_statuses", "equipment_statuses", "equipment_calibration_statuses"]

def run_command(cmd, append=False):
    env = os.environ.copy()
    env["PGPASSWORD"] = DB_PASS
    
    mode = "ab" if append else "wb"
    with open(OUTPUT_FILE, mode) as f:
        result = subprocess.run(cmd, env=env, stdout=f, stderr=subprocess.PIPE, text=False)
        if result.returncode != 0:
            print(f"Error executing command: {result.stderr.decode()}")
            return False
    return True

def main():
    print(f"Generating initialization script: {OUTPUT_FILE}...")
    
    # 1. Export Schema only
    print("Exporting schema...")
    schema_cmd = [
        "pg_dump", "-h", DB_HOST, "-p", DB_PORT, "-U", DB_USER, "-d", DB_NAME,
        "-s", # Schema only
        "-F", "p" # Plain text
    ]
    if not run_command(schema_cmd):
        sys.exit(1)
        
    # 2. Export Seed Data
    print(f"Exporting seed data for tables: {', '.join(SEED_TABLES)}...")
    data_cmd = [
        "pg_dump", "-h", DB_HOST, "-p", DB_PORT, "-U", DB_USER, "-d", DB_NAME,
        "-a", # Data only
        "--inserts", # Use INSERT statements (more portable/readable for init)
    ]
    for table in SEED_TABLES:
        data_cmd.extend(["-t", table])
        
    if not run_command(data_cmd, append=True):
        sys.exit(1)
        
    print("Successfully generated initialization script.")

if __name__ == "__main__":
    # Ensure we are in the correct directory if run from project root
    if os.path.basename(os.getcwd()) != "db_migrations":
        if os.path.exists("db_migrations"):
            os.chdir("db_migrations")
            
    main()
