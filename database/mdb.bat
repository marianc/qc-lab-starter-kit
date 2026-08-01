@echo off
REM Helper batch script for running management commands via uv in the database directory
uv run python src/manage.py %*
