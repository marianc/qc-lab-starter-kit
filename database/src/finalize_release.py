import os
import sys
import glob
import json
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

MIGRATIONS_DIR = "migrations"
RELEASES_DIR = "releases"
RELEASES_JSON = "releases.json"

def get_latest_migration_content():
    """Concatenates all migration scripts in the migrations folder."""
    sql_files = sorted(glob.glob(os.path.join(MIGRATIONS_DIR, "*.sql")))
    content = ""
    for file_path in sql_files:
        with open(file_path, "r", encoding="utf-8") as f:
            content += f"-- File: {os.path.basename(file_path)}\n"
            content += f.read() + "\n\n"
    return content

def finalize_release(description):
    migration_up = get_latest_migration_content()

    os.makedirs(RELEASES_DIR, exist_ok=True)

    # Load existing releases history
    releases = []
    if os.path.exists(RELEASES_JSON):
        try:
            with open(RELEASES_JSON, "r", encoding="utf-8") as f:
                releases = json.load(f)
        except Exception as e:
            print(f"Warning: Failed to load {RELEASES_JSON}, creating new: {e}")

    # Determine current/new IDs
    if not releases:
        current_id = 0
    else:
        current_id = releases[-1]["id"]
        # Mark previous release as obsolete
        releases[-1]["is_obsolete"] = True
        releases[-1]["date_obsolete"] = datetime.now().isoformat()
        releases[-1]["script_migration_up_length"] = len(migration_up)

    new_id = current_id + 1
    print(f"Registering new release version: {new_id}...")

    # Write release-specific files
    release_mig_path = os.path.join(RELEASES_DIR, f"release_{new_id}_migration.sql")

    try:
        with open(release_mig_path, "w", encoding="utf-8") as f:
            f.write(migration_up)
    except Exception as e:
        print(f"Error writing release SQL files: {e}")
        return False

    new_release = {
        "id": new_id,
        "description": description,
        "date_created": datetime.now().isoformat(),
        "is_obsolete": False,
        "date_obsolete": None,
        "migration_script_file": release_mig_path
    }
    
    releases.append(new_release)

    try:
        with open(RELEASES_JSON, "w", encoding="utf-8") as f:
            json.dump(releases, f, indent=2)
        print(f"Successfully finalized release {new_id}.")
        return True
    except Exception as e:
        print(f"Error writing to {RELEASES_JSON}: {e}")
        return False

def main():
    if len(sys.argv) < 2:
        print("Usage: python finalize_release.py \"Description of the release\"")
        print("Example: python finalize_release.py \"Release 1.1.0 - Schema updates for formulas\"")
        sys.exit(1)
        
    description = sys.argv[1]
    if finalize_release(description):
        print(f"\n✅ Release finalized locally in {RELEASES_JSON}.")
    else:
        print("\n❌ Failed to finalize release.")
        sys.exit(1)

if __name__ == "__main__":
    # Ensure we are in the correct directory if run from project root
    if os.path.basename(os.getcwd()) != "database":
        if os.path.exists("database"):
            os.chdir("database")
    main()
