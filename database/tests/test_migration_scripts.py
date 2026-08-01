import os
import sys
import json
import shutil
import subprocess
import pytest
from unittest.mock import patch, MagicMock, mock_open

# Adjust path to import local modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Import scripts under test
import generate_init
import test_migration
import finalize_release
import migrate_tenants
import manage

@pytest.fixture(autouse=True)
def setup_and_teardown_dirs():
    """Ensure test files/folders are cleaned up before and after tests."""
    temp_dirs = ["db_init", "db_test", "migrations", "releases", "logs"]
    temp_files = ["releases.json", "databases.txt", ".env"]
    
    # Save current working directory
    orig_cwd = os.getcwd()
    # Go to database folder
    db_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    os.chdir(db_dir)
    
    # Backup existing folders
    backups = {}
    for d in temp_dirs:
        if os.path.exists(d):
            backups[d] = f"{d}_backup_test"
            if os.path.exists(backups[d]):
                shutil.rmtree(backups[d])
            shutil.copytree(d, backups[d])
            shutil.rmtree(d)
        os.makedirs(d, exist_ok=True)
        
    for f in temp_files:
        if os.path.exists(f):
            backups[f] = f"{f}_backup_test"
            if os.path.exists(backups[f]):
                os.remove(backups[f])
            shutil.copy2(f, backups[f])
            os.remove(f)

    yield

    # Clean up created folders and restore backups
    for d in temp_dirs:
        if os.path.exists(d):
            shutil.rmtree(d)
        if d in backups:
            shutil.copytree(backups[d], d)
            shutil.rmtree(backups[d])
            
    for f in temp_files:
        if os.path.exists(f):
            os.remove(f)
        if f in backups:
            shutil.copy2(backups[f], f)
            os.remove(backups[f])
            
    # Restore original working dir
    os.chdir(orig_cwd)

# ==================== generate_init.py Tests ====================

@patch("subprocess.run")
def test_generate_init_success(mock_sub_run):
    # Mock successful subprocess execution (returncode = 0)
    mock_sub_run.return_value = MagicMock(returncode=0)
    
    # Make sure target dir exists
    os.makedirs("db_init", exist_ok=True)
    
    # Run main
    generate_init.main()
    
    # Assert pg_dump was called twice (schema + data)
    assert mock_sub_run.call_count == 2
    assert os.path.exists("db_init/init_schema.sql")

@patch("subprocess.run")
@patch("sys.exit")
def test_generate_init_failure_schema(mock_sys_exit, mock_sub_run):
    # Mock pg_dump schema failing
    mock_sub_run.return_value = MagicMock(returncode=1, stderr=b"pg_dump error")
    mock_sys_exit.side_effect = SystemExit
    
    with pytest.raises(SystemExit):
        generate_init.main()
    
    mock_sys_exit.assert_called_once_with(1)

# ==================== test_migration.py Tests ====================

@patch("subprocess.run")
@patch("test_migration.run_psql")
def test_test_migration_success(mock_run_psql, mock_sub_run, monkeypatch):
    mock_run_psql.return_value = MagicMock(returncode=0)
    mock_sub_run.return_value = MagicMock(returncode=0, stdout="Applied migrations", stderr="")
    
    # Create a dummy snapshot file
    os.makedirs("db_test", exist_ok=True)
    dummy_snapshot = "db_test/dummy_snapshot.sql"
    with open(dummy_snapshot, "w") as f:
        f.write("CREATE TABLE test();")
        
    monkeypatch.setattr(sys, "argv", ["test_migration.py", dummy_snapshot])
    
    test_migration.main()
    
    assert mock_run_psql.call_count == 2  # DROP then CREATE
    assert mock_sub_run.call_count == 2   # restore_snapshot (psql) + test_apply (atlas)

@patch("test_migration.run_psql")
@patch("sys.exit")
def test_test_migration_missing_snapshot(mock_sys_exit, mock_run_psql, monkeypatch):
    monkeypatch.setattr(sys, "argv", ["test_migration.py", "nonexistent.sql"])
    mock_sys_exit.side_effect = SystemExit
    
    with pytest.raises(SystemExit):
        test_migration.main()
        
    mock_sys_exit.assert_called_once_with(1)

# ==================== finalize_release.py Tests ====================

def test_finalize_release_success():
    # Setup migration and initialization files
    os.makedirs("migrations", exist_ok=True)
    os.makedirs("db_init", exist_ok=True)
    
    with open("migrations/0001_test.sql", "w", encoding="utf-8") as f:
        f.write("CREATE TABLE m1();")
    with open("db_init/init_schema.sql", "w", encoding="utf-8") as f:
        f.write("CREATE TABLE init();")
        
    # Finalize first release
    success = finalize_release.finalize_release("First release")
    assert success
    
    assert os.path.exists("releases.json")
    assert os.path.exists("releases/release_1_migration.sql")
    assert os.path.exists("releases/release_1_init.sql")
    
    with open("releases.json", "r", encoding="utf-8") as f:
        data = json.load(f)
        assert len(data) == 1
        assert data[0]["id"] == 1
        assert data[0]["is_obsolete"] is False
        
    # Finalize second release (verifies incrementing and obsoleting previous version)
    success2 = finalize_release.finalize_release("Second release")
    assert success2
    
    with open("releases.json", "r", encoding="utf-8") as f:
        data = json.load(f)
        assert len(data) == 2
        assert data[0]["is_obsolete"] is True
        assert data[1]["id"] == 2
        assert data[1]["is_obsolete"] is False

def test_finalize_release_missing_init_script():
    success = finalize_release.finalize_release("Should fail")
    assert not success

# ==================== migrate_tenants.py Tests ====================

@patch("migrate_tenants.database_exists")
@patch("migrate_tenants.create_database")
@patch("psycopg2.connect")
@patch("subprocess.run")
def test_migrate_tenants_cli_arguments_success(mock_sub_run, mock_connect, mock_create, mock_exists):
    mock_sub_run.return_value = MagicMock(returncode=0, stdout="Migration applied", stderr="")
    mock_connect.return_value = MagicMock()
    mock_exists.return_value = True
    
    # Pass target databases as CLI args
    with patch("sys.argv", ["migrate_tenants.py", "db_test_1", "db_test_2"]):
        migrate_tenants.main()
        
    # Assert logs folder contains a log file
    logs = os.listdir("logs")
    assert len(logs) == 1
    assert logs[0].startswith("migration_")
    
    with open(os.path.join("logs", logs[0]), "r", encoding="utf-8") as lf:
        content = lf.read()
        assert "db_test_1: PASS" in content
        assert "db_test_2: PASS" in content
        assert "Successes: 2" in content
    mock_create.assert_not_called()

@patch("migrate_tenants.database_exists")
@patch("migrate_tenants.create_database")
@patch("psycopg2.connect")
@patch("subprocess.run")
def test_migrate_tenants_creates_missing_database(mock_sub_run, mock_connect, mock_create, mock_exists):
    mock_sub_run.return_value = MagicMock(returncode=0, stdout="Migration applied", stderr="")
    mock_connect.return_value = MagicMock()
    mock_exists.return_value = False
    mock_create.return_value = True
    
    with patch("sys.argv", ["migrate_tenants.py", "missing_db"]):
        migrate_tenants.main()
        
    mock_exists.assert_called_once_with("missing_db")
    mock_create.assert_called_once_with("missing_db")

@patch("migrate_tenants.database_exists")
@patch("psycopg2.connect")
@patch("subprocess.run")
@patch("sys.exit")
def test_migrate_tenants_failure_halts_execution(mock_sys_exit, mock_sub_run, mock_connect, mock_exists):
    mock_exists.return_value = True
    mock_connect.return_value = MagicMock()
    mock_sys_exit.side_effect = SystemExit
    # Mock subprocess.run failing for the first database
    mock_sub_run.return_value = MagicMock(returncode=1, stdout="", stderr="Atlas execution failed")
    
    with patch("sys.argv", ["migrate_tenants.py", "db_fail", "db_should_be_skipped"]):
        with pytest.raises(SystemExit):
            migrate_tenants.main()
        
    mock_sys_exit.assert_called_once_with(1)
    
    # Verify skipped database was not processed because migration process halted
    logs = os.listdir("logs")
    with open(os.path.join("logs", logs[0]), "r", encoding="utf-8") as lf:
        content = lf.read()
        assert "db_fail: FAIL" in content
        assert "Database: db_should_be_skipped" not in content
        assert "HALTING migration process" in content

def test_get_target_databases_from_txt():
    with open("databases.txt", "w", encoding="utf-8") as f:
        f.write("# This is a comment\n\n\n\n\n\n\n\n\n  \n\n  \n\n  \n\n\ndb_from_txt_1\n# Another comment\ndb_from_txt_2\n")
        
    with patch("sys.argv", ["migrate_tenants.py"]):
        dbs = migrate_tenants.get_target_databases()
        assert dbs == ["db_from_txt_1", "db_from_txt_2"]

# ==================== manage.py Tests ====================

@patch("manage.cmd_diff")
def test_manage_cli_diff_routing(mock_diff):
    with patch("sys.argv", ["manage.py", "diff", "add_users_table"]):
        manage.main()
        mock_diff.assert_called_once()
        args = mock_diff.call_args[0][0]
        assert args.name == "add_users_table"

@patch("manage.cmd_deploy")
def test_manage_cli_deploy_routing(mock_deploy):
    with patch("sys.argv", ["manage.py", "deploy", "db_arg_1", "db_arg_2"]):
        manage.main()
        mock_deploy.assert_called_once()
        args = mock_deploy.call_args[0][0]
        assert args.databases == ["db_arg_1", "db_arg_2"]
