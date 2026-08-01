# QC Lab PDF Reporting Service

A Python FastAPI microservice responsible for generating professional, paged PDF reports for the Quality Control LIMS application using **WeasyPrint**, **Jinja2**, and **CSS Paged Media**.

## Features

- **Dedicated FastAPI Endpoints**: 
  - `POST /testing-report-pdf`: Generates testing report PDFs using `testing_report.html`.
  - `POST /quality-certificate-pdf`: Generates quality certificate PDFs using `quality_certificate.html`.
  - `POST /specification-pdf`: Generates specification PDFs using `specification.html`.
- **Modular Project Structure**:
  - `src/dtos/`: Dedicated Pydantic data transfer objects (`report_dtos.py`, `certificate_dtos.py`, `spec_dtos.py`).
  - `src/routes/`: Dedicated API route handlers (`report_routes.py`, `certificate_routes.py`, `spec_routes.py`).
  - `src/templates/`: Jinja2 HTML templates styled with CSS Paged Media.
- **WeasyPrint**: Converts HTML/CSS to PDF documents entirely in memory.

---

## Requirements

- Python 3.11+
- [uv](https://github.com/astral-sh/uv) package manager

---

## Installation & Setup

1. Navigate to the `reporting_pdf` directory:
   ```bash
   cd reporting_pdf
   ```

2. Install dependencies using `uv`:
   ```bash
   uv sync
   ```

---

## Running the Service

Start the FastAPI server using `uv run`:

```bash
uv run uvicorn src.main:app --reload --host 127.0.0.1 --port 8000
```

---

## API Endpoints

### 1. Health Check
- **URL**: `GET /health`
- **Response**: `{"status": "ok"}`

### 2. Testing Report PDF
- **URL**: `POST /testing-report-pdf`
- **Payload**: JSON matching `report_dtos.py`.
- **Response**: `application/pdf` binary stream (`testing_report_{id}.pdf`).

### 3. Quality Certificate PDF
- **URL**: `POST /quality-certificate-pdf`
- **Payload**: JSON matching `certificate_dtos.py`.
- **Response**: `application/pdf` binary stream (`quality_certificate_{id}.pdf`).

### 4. Specification PDF
- **URL**: `POST /specification-pdf`
- **Payload**: JSON matching `spec_dtos.py`.
- **Response**: `application/pdf` binary stream (`specification_{id}.pdf`).


## Licensing

This project may contain portions from other free and/or open source resources (e.g. code, documentation or binaries).
For more information on licensing please check [NOTICE.md](NOTICE.md) and the content of '_thirdPartyLicenses' folder located in this sub-project.
