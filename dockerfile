# ── Stage 1: build dependencies ───────────────────────────────────────────────
# Use a full image to compile psycopg2 and argon2-cffi (need gcc + libpq-dev)
FROM python:3.12-slim AS builder

WORKDIR /build

# Install build tools and PostgreSQL client headers (needed by psycopg2-binary)
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc \
        libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python deps into an isolated prefix
COPY requirements.txt .
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt


# ── Stage 2: lean runtime image ───────────────────────────────────────────────
FROM python:3.12-slim AS runtime

# libpq5 is the runtime-only PostgreSQL client library (no headers/gcc needed)
RUN apt-get update && apt-get install -y --no-install-recommends \
        libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Non-root user — never run app code as root inside a container
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy installed packages from builder stage
COPY --from=builder /install /usr/local

# Copy application source
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Expose the port gunicorn will bind to (matches GUNICORN_PORT / default 5000)
EXPOSE 5000

# Health check — Docker marks container unhealthy if this fails 3× in a row.
# Unhealthy containers are restarted automatically by Docker Compose.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/api/health')"

# Entrypoint: gunicorn reads config from gunicorn.conf.py which reads .env
CMD ["gunicorn", "app:create_app()", "-c", "gunicorn.conf.py"]