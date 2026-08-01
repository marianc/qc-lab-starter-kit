# Stage 1: Build React Client
FROM node:22-alpine AS build-client
WORKDIR /app

# Copy root package files for workspaces
COPY package.json package-lock.json ./
COPY packages/client_react/package.json ./packages/client_react/

# Install dependencies for the workspace
RUN npm install --workspace=packages/client_react

# Copy source code
COPY packages/client_react ./packages/client_react

# Build React client
RUN npm run build --workspace=packages/client_react


# Stage 2: Build .NET API Server
FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build-server
WORKDIR /src

# Copy project files
COPY Directory.Packages.props Directory.Build.props ./
COPY server/QCLab/QCLab.csproj ./server/QCLab/
COPY server_formula/QCFormula/QCFormula.csproj ./server_formula/QCFormula/

# Restore dependencies
RUN dotnet restore server/QCLab/QCLab.csproj

# Copy the rest of the source
COPY server_formula/ ./server_formula/
COPY server/ ./server/

# Build and publish
WORKDIR /src/server/QCLab
RUN dotnet publish QCLab.csproj -c Release -o /app/publish /p:UseAppHost=false


# Stage 3: Runtime Stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine
WORKDIR /app

# Install supervisor and nginx
RUN apk add --no-cache supervisor nginx

# Copy React static files to nginx
COPY --from=build-client /app/packages/client_react/dist /usr/share/nginx/html

# Copy .NET server files
COPY --from=build-server /app/publish .

# Copy nginx config
COPY docker/nginx.conf /etc/nginx/http.d/default.conf

# Copy supervisord config
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Ensure keys directory exists for Data Protection
RUN mkdir -p /app/keys

# Expose ports
EXPOSE 80 5000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
