from fastapi import FastAPI, HTTPException
import subprocess
import os
import sys
import logging

# Ensure src is in sys.path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

import config

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Database Reset Service")

def run_migration():
    """Helper to run the migration script."""
    migration_script = os.path.abspath(os.path.join(os.path.dirname(__file__), 'data_migrations', config.MIGRATION_SCRIPT))
    
    if not os.path.exists(migration_script):
        error_msg = f"Migration script not found at {migration_script}"
        logger.error(error_msg)
        return False, error_msg

    env = os.environ.copy()

    logger.info(f"Running migration script: {migration_script} for profile: {config.TEST_SERVER}")
    
    try:
        result = subprocess.run([sys.executable, migration_script], capture_output=True, text=True, env=env)
        if result.returncode != 0:
            logger.error(f"Migration failed with return code {result.returncode}")
            logger.error(f"Stderr: {result.stderr}")
            return False, result.stderr
        
        logger.info("Migration completed successfully")
        return True, result.stdout
    except Exception as e:
        logger.exception("Unexpected error during migration")
        return False, str(e)

@app.put("/reset_db")
async def reset_db():
    """Endpoint to reset the database for the current test profile."""
    success, output = run_migration()
    if not success:
        raise HTTPException(status_code=500, detail=f"Database migration failed: {output}")
    return {
        "message": "Database reset successful", 
        "profile": config.TEST_SERVER, 
        "db_type": config.DB_TYPE,
        "details": output.splitlines()[-1] if output.strip() else ""
    }

@app.get("/health")
async def health():
    """Health check endpoint."""
    return {
        "status": "ok", 
        "profile": config.TEST_SERVER, 
        "db_type": config.DB_TYPE
    }

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "once":
        logger.info("Running migration once and exiting...")
        success, output = run_migration()
        if not success:
            logger.error(f"Migration failed: {output}")
            sys.exit(1)
        else:
            logger.info("Migration successful")
            sys.exit(0)
    else:
        import uvicorn
        # Default port 8000
        uvicorn.run(app, host="0.0.0.0", port=8000)
