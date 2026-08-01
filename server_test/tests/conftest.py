import pytest
import requests
import subprocess
import os
import sys
import urllib3

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Add src to sys.path to allow importing models and migration script
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from models import Base
import config

@pytest.fixture(scope="session")
def base_url():
    return config.BASE_URL

@pytest.fixture(scope="session")
def db_engine():
    """Provides a SQLAlchemy engine for the application database."""
    engine = create_engine(config.SQLALCHEMY_DATABASE_URL)
    return engine

@pytest.fixture(scope="function")
def db_session(db_engine):
    """Provides a SQLAlchemy session for database verification."""
    Session = sessionmaker(bind=db_engine)
    session = Session()
    try:
        yield session
    finally:
        session.close()

def run_migration():
    """Helper to run the migration script."""
    migration_script = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src', 'data_migrations', config.MIGRATION_SCRIPT))
    
    env = os.environ.copy()

    result = subprocess.run([sys.executable, migration_script], capture_output=True, text=True, env=env)
    if result.returncode != 0:
        pytest.fail(f"Database migration failed: {result.stderr}")

@pytest.fixture(scope="session", autouse=True)
def initial_migration():
    """Runs migration once at the start of the test session, including automated seed generation."""
    import psycopg2
    import subprocess
    import os

    db_user = os.getenv("DB_USER", "postgres")
    db_pass = os.getenv("DB_PASS", "Pass@word1")
    db_host = os.getenv("DB_HOST", "localhost")
    db_port = int(os.getenv("DB_PORT", "5432"))

    # Connect to default postgres DB to create the seed DB
    conn = psycopg2.connect(host=db_host, port=db_port, database="postgres", user=db_user, password=db_pass)
    conn.autocommit = True
    with conn.cursor() as cur:
        cur.execute("DROP DATABASE IF EXISTS quality_control_seed;")
        cur.execute("CREATE DATABASE quality_control_seed;")
    conn.close()
    
    seed_sql_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src', 'db_test', 'quality_control_pg_test_seed.sql'))
    env = os.environ.copy()
    env["PGPASSWORD"] = db_pass
    
    res = subprocess.run(["psql", "-U", db_user, "-h", db_host, "-p", str(db_port), "-d", "quality_control_seed", "-f", seed_sql_path], env=env, capture_output=True, text=True)
    if res.returncode != 0:
        pytest.fail(f"Failed to restore seed db from {seed_sql_path}: {res.stderr}")

    run_migration()
    yield
    
    # Cleanup: Drop the database after the test session is over
    conn = psycopg2.connect(host=db_host, port=db_port, database="postgres", user=db_user, password=db_pass)
    conn.autocommit = True
    with conn.cursor() as cur:
        # Disconnect active connections to allow dropping
        cur.execute("SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'quality_control_seed' AND pid <> pg_backend_pid();")
        cur.execute("DROP DATABASE IF EXISTS quality_control_seed;")
    conn.close()

@pytest.fixture(scope="session")
def auth_session(base_url):
    """Provides an authenticated session. Depends on initial migration."""
    session = requests.Session()
    session.verify = False
    session.headers.update({
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    })
    
    login_url = f"{base_url}/api/auth/login"
    credentials = {
        "email": "alice@qc.lab",
        "password": "Pass@word1"
    }
    
    response = session.post(login_url, json=credentials)
    if response.status_code != 200:
        pytest.fail(f"Login failed: {response.status_code} - {response.text}")
    
    return session

@pytest.fixture(scope="function")
def migrated_db(auth_session, base_url):
    """
    Ensures the database is migrated before the test AND Alice is logged in again 
    to refresh the session in the DB, because migration overwrites the session data.
    """
    run_migration()
    # Re-login to update the session in the newly migrated database
    login_url = f"{base_url}/api/auth/login"
    credentials = {
        "email": "alice@qc.lab",
        "password": "Pass@word1"
    }
    response = auth_session.post(login_url, json=credentials)
    if response.status_code != 200:
        pytest.fail(f"Re-login after migration failed: {response.status_code}")
    
    return True
