import os
from dotenv import load_dotenv

# Load .env file from the test_servers directory
load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "Pass@word1")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")

# Get the server type from environment variable, default to 'blazor'
TEST_SERVER = os.getenv("TEST_SERVER", "blazor").lower()

# URL encode password if it contains special characters like @
import urllib.parse
encoded_pass = urllib.parse.quote_plus(DB_PASS)

CONFIGS = {
    "dotnetapi": {
        "base_url": "http://localhost:5010",
        "db_type": "postgresql",
        "migration_script": "migrate_to_postgresql.py",
        "sqlalchemy_url": f"postgresql+psycopg2://{DB_USER}:{encoded_pass}@{DB_HOST}:{DB_PORT}/quality_control"
    }
}

if TEST_SERVER not in CONFIGS:
    raise ValueError(f"Unknown TEST_SERVER: {TEST_SERVER}. Valid options: {list(CONFIGS.keys())}")

current_config = CONFIGS[TEST_SERVER]

# Export variables for easy access
TEST_SERVER = TEST_SERVER # Re-export for clarity
BASE_URL = current_config["base_url"]
DB_TYPE = current_config["db_type"]
MIGRATION_SCRIPT = current_config["migration_script"]
SQLALCHEMY_DATABASE_URL = current_config["sqlalchemy_url"]
