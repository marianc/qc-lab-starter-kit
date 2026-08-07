# LIMS for Quality Control Laboratories, Starter Kit (QC Lab LIMS Starter Kit)

This repository contains the Quality Control Laboratory Information Management System, composed of:
1. **.NET C# Server (`server/`)**: Backend API and application core.
2. **React Client (`packages/client_react/`)**: Modern frontend user interface.
3. **Python PDF Reporting Service (`reporting_pdf/`)**: FastAPI & WeasyPrint microservice for generating professional paged PDF reports.
4. **Python Excel Reporting Service (`reporting_xl/`)**: FastAPI & openpyxl microservice for generating multi-sheet Excel reports (`testing_reports.xlsx` and `quality_certificates.xlsx`).
5. **Database Management & Migrations (`database/`)**: Database-first tooling and SQL migration scripts for PostgreSQL.

---

## 🚀 One-Command Demo Mode (Zero Installation!)

You can run the entire system—including a pre-configured PostgreSQL database with all seed data automatically restored—using Docker Compose:

### 1. Build & Run with Docker
Build and start the application containers from the root folder:
```bash
docker compose -f docker-compose.demo.yml up --build -d
```

### 2. Access the Application
Once running, open your browser at **[http://localhost:9090](http://localhost:9090)** and log in with:
- **User**: `alice@qc.lab`
- **Password**: `Pass@word1`

*(Other test users in the database use the exact same password `Pass@word1` for testing various roles).*

### 3. Stopping the Standard Services
To stop the demo stack when finished:
```bash
docker compose -f docker-compose.demo.yml down
```

---

## About this project

This software is only about processing testing data. No inventory management or equipment calibration or metrological verification or other aspects that need to be managed by the laboratories.

Also this application is working, it represent just a minimum viable product (MVP) or a proof of concept (PoC), and it is not recommended to be used as is in high risk production environments, but rather in low risk environments, in the situation where *'anything is better than Excel spreadsheets'*.

Another use for this 'Starter Kit' is for the situations where a quality control laboratory is looking for implementing a LIMS system, but often is so difficult to convey the expectations to the software suppliers. Having this 'Starter Kit' as a reference implementation, that is working out of the box, it becomes very simple to explain, on this concrete example, what features are expected the LIMS to have or not (do's and don'ts).

Every quality control laboratory has it’s specific requirements regarding workflows, reporting and data processing, security or compliance with different standards, therefore in most cases this will involve further software development and testing to make sure it fits the purpose.

This software is not intended to go beyond the 'Starter Kit' status and to cover every possible use cases. It is intended to be minimal, to be customized and adapted as needed. Using of 'Starter Kit' may result in faster implementation, reduced costs and more predictable outcome.

The author of the original implementation, that had to deal with the pain of using paper records early in it's career, had multiple attempts, to implement custom solutions using Access + SQL and later using Silverlight and .NET. Unfortunately this solutions could not be reused with minimal effort in other quality control laboratories. He wanted a universal solution that can be easily adapted, with minimal effort, to other quality control laboratories. During time, he explored various ideas about how this could be done, and failed to find a reasonable solution.

However, in recent years, the AI appeared, and he had decided to explore some new ideas, by using AI as it's coding assistant, while he was mostly focus on the solution architecture. He developed the LIMS application over a span of approximately 6 months and used Gemini CLI (with Gemini models) almost exclusively. He barely written any manual code (almost none), but kept the project structure and code organization under his control. He experimented various ideas and 'sculpted' this application prompt by prompt.

For a preview, without installing the software, you can check YouTube video presentation channel [https://www.youtube.com/@qualityassistant5648](https://www.youtube.com/@qualityassistant5648), where you can experience the core functionality in a guided concise manner.

---

## Contribution Policy

This project does not accept PRs but it welcomes suggestions for improvement and bug reports.

If you need a specific feature for your laboratory, you are encouraged to fork the repository, customize it internally, or hire a developer to build it on top of this core framework.

---

## Licensing

This project is licensed [Apache-2.0](LICENSE.txt) and it may contain portions from other free and/or open source resources (e.g. code, documentation or binaries).
For more information on licensing please check [NOTICE.md](NOTICE.md) and sub-project/NOTICE.md and the content of '_thirdPartyLicenses' folder located in each of the sub-projects.

Copyright (c) 2026 Marian Cruceru.
