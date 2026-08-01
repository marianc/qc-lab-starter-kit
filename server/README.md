# QCLab .NET API

This project is a **.NET 10 Web API** implementation of the Quality Control (QC) Laboratory Management System.

This project is part of a .NET monorepo using **Central Package Management (CPM)**. Package versions are managed in `Directory.Packages.props` at the root of the `projects_dotnet` directory.

## Overview

The QCLab API manages the entire lifecycle of quality control data, from initial sample reception to final certification. It features a robust data model and a specialized formula parsing engine for dynamic calculations.

## Tech Stack

*   **Runtime:** .NET 10
*   **API Framework:** ASP.NET Core Web API
*   **ORM:** Entity Framework Core
*   **Database:** PostgreSQL (via Npgsql)
*   **Security:** 
    *   **BCrypt.Net-Next** for password hashing.
    *   **Custom Session Cookie** authentication.
*   **Parser:** ANTLR 4 (used by the QCFormula engine).

## Project Structure

*   **`QCLab`**: The main Web API project containing controllers, models, services, and middleware.
*   **`QCFormula`**: A dedicated C# library that ports the formula parsing logic from the original TypeScript implementation. It uses ANTLR 4 to evaluate complex QC calculations.

## Core Features

*   **User Management:** Role-based access control with automatic Admin creation on first run.
*   **Laboratory & Materials:** Management of lab entities, departments, and material databases.
*   **Standards & Specifications:** Support for official standards (ASTM, ISO) and material-specific test limits.
*   **Sample Lifecycle:** Comprehensive tracking of incoming samples, linked measurements, and results.
*   **Formula Engine:** dynamic evaluation of user-defined formulas supporting arithmetic, variables, and built-in functions (SQRT, SUM, AVG, IF, etc.).
*   **Certifications:** Generation of Certificates of Analysis (CoA) based on validated test results.

## Getting Started

### Prerequisites

*   [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0)
*   [PostgreSQL](https://www.postgresql.org/download/)

### Configuration

The application uses environment variables for configuration. You can use a `.env` file in the `QCLab` directory or update `appsettings.json`.

Key settings include:
*   `DB_CONNECTION_STRING`: The PostgreSQL connection string.
*   `SESSION_COOKIE_NAME`: Name for the authentication cookie.

### Build and Run

1.  Navigate to the `projects_dotnet` root:
    ```bash
    cd projects_dotnet
    ```
2.  Clean the project (optional):
    ```bash
    dotnet clean
    ```
3.  Restore dependencies:
    ```bash
    dotnet restore
    ```
4.  Apply database migrations (if any):
    ```bash
    dotnet ef database update --project server_dotnetapi/QCLab
    ```
5.  Run the application:
    ```bash
    dotnet run --project server_dotnetapi/QCLab
    ```

The API will typically be available at `http://localhost:5000` or `https://localhost:5001`. Swagger documentation can be accessed at `/swagger` if enabled in the development environment.

## Authentication

The system uses a custom session-based authentication mechanism. Upon successful login, a session ID is generated, stored in the database, and sent to the client via a secure cookie. All subsequent requests must include this cookie to be authenticated.

## Licensing

This project may contain portions from other free and/or open source resources (e.g. code, documentation or binaries).
For more information on licensing please check [NOTICE.md](NOTICE.md) and the content of '_thirdPartyLicenses' folder located in this sub-project.
