# Reporting Excel Service (`reporting_xl`)

A FastAPI microservice responsible for generating multi-sheet Excel reports (`testing_reports.xlsx` and `quality_certificates.xlsx`) using `openpyxl`.

## Features
- Generates Excel workbooks from structured JSON data payloads provided by the .NET C# backend.
- Supports **Testing Reports** exports (Certification, Verification, and Category Verification sheets with custom formatting, date formatting `dd.mm.yyyy`, array value multi-row layouts, and blue table headers).
- Supports **Quality Certificates** exports (Material sheets with custom formatting, date formatting `dd.mm.yyyy`, array value multi-row layouts, and dark red table headers).
- Fully containerized with Docker (`python:3.11-alpine`).

## API Endpoints
- `POST /testing-reports-excel`: Generates and returns `testing_reports.xlsx`.
- `POST /quality-certificates-excel`: Generates and returns `quality_certificates.xlsx`.
- `GET /health`: Health check endpoint.

## Development & Running
```bash
uv venv
source .venv/bin/activate  # or .venv\Scripts\activate on Windows
uv pip install -e .
uvicorn src.main:app --reload --port 8000
```

## Licensing

This project may contain portions from other free and/or open source resources (e.g. code, documentation or binaries).
For more information on licensing please check [NOTICE.md](NOTICE.md) and the content of '_thirdPartyLicenses' folder located in this sub-project.
