# QC Lab Docker Deployment

This directory contains the configuration to build and run the consolidated QC Lab application (React Client + .NET Server) in a single Docker container.

## Prerequisites

- Docker Desktop installed and running.
- PostgreSQL database accessible from the container.

## Configuration

The application requires a PostgreSQL database. Ensure the following environment variables are set in `docker-compose.yml` to connect to your database:

```yaml
environment:
  - CONNECTION_STRING=Host=<db-host>;Username=postgres;Password=Pass@word1;Database=quality_control
```

*Replace `<db-host>` with the appropriate hostname (e.g., `host.docker.internal` if the DB is running on the host machine).*

## Building and Running

1. Open a terminal in the project root directory.

2. Build and start the container:
   ```bash
   docker compose up --build -d
   ```

3. The application will be accessible at:
   `http://localhost:9090`

## Stopping the container

```bash
docker compose down
```
