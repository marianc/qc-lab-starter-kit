@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM Pure PostgreSQL Database Management Script for Evaluators (No Python Required)
REM ============================================================================

set DB_HOST=localhost
set DB_PORT=5432
set DB_USER=postgres
set PGPASSWORD=Pass@word1
set TARGET_DB=quality_control

if "%~1"=="restore" goto restore
if "%~1"=="backup" goto backup

echo Usage: mdb restore [backup_filename]
echo        mdb backup
goto :eof

:restore
set DUMP_FILE=%~2

if "%DUMP_FILE%"=="" (
    echo [INFO] Finding the latest backup file in backups\...
    for /f "delims=" %%i in ('dir /b /o-d backups\qc_pg_dump_*.sql') do (
        set DUMP_FILE=backups\%%i
        goto found_latest
    )
    echo [ERROR] No backup files found in backups\ directory!
    exit /b 1
) else (
    set DUMP_FILE=backups\%DUMP_FILE%
)

:found_latest
if not exist "%DUMP_FILE%" (
    echo [ERROR] Backup file not found: %DUMP_FILE%
    exit /b 1
)

echo [INFO] Restoring database '%TARGET_DB%' from '%DUMP_FILE%'...

echo [INFO] Terminating existing connections to '%TARGET_DB%'...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '%TARGET_DB%' AND pid <> pg_backend_pid();" >nul 2>&1

echo [INFO] Dropping database '%TARGET_DB%' if it exists...
dropdb -h %DB_HOST% -p %DB_PORT% -U %DB_USER% --if-exists %TARGET_DB%

echo [INFO] Creating fresh database '%TARGET_DB%'...
createdb -h %DB_HOST% -p %DB_PORT% -U %DB_USER% %TARGET_DB%

echo [INFO] Applying SQL dump...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %TARGET_DB% -f "%DUMP_FILE%"

if %errorlevel% equ 0 (
    echo [SUCCESS] Database restored successfully from %DUMP_FILE%!
) else (
    echo [ERROR] Database restoration encountered an error.
    exit /b %errorlevel%
)
goto :eof

:backup
set TIMESTAMP=%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_FILE=backups\qc_pg_dump_%TIMESTAMP%.sql
echo [INFO] Creating backup to %BACKUP_FILE%...
pg_dump -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %TARGET_DB% -F p -b -v -f "%BACKUP_FILE%"
if %errorlevel% equ 0 (
    echo [SUCCESS] Backup created successfully: %BACKUP_FILE%
) else (
    echo [ERROR] Backup failed.
    exit /b %errorlevel%
)
goto :eof
