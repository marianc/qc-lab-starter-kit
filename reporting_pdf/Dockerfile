FROM python:3.11-alpine

# Install Pango, GObject, Fontconfig, and WeasyPrint dependencies
RUN apk add --no-cache \
    so:libgobject-2.0.so.0 \
    so:libpango-1.0.so.0 \
    so:libharfbuzz.so.0 \
    so:libharfbuzz-subset.so.0 \
    so:libfontconfig.so.1 \
    so:libpangoft2-1.0.so.0 \
    weasyprint \
    font-liberation \
    font-liberation-sans-narrow \
    ttf-linux-libertine

WORKDIR /app

# Copy dependency definition and install python packages (fastapi, uvicorn, jinja2, etc.)
COPY pyproject.toml ./
RUN pip install --no-cache-dir .

# Copy application source code
COPY src/ ./src/

EXPOSE 8000

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
