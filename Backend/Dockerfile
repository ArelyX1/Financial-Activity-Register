FROM python:3.11-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    pkg-config \
    libssl-dev \
    patchelf \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app

COPY requirements.txt .
RUN python -m venv /venv && \
    /venv/bin/pip install --no-cache-dir -r requirements.txt

COPY . .

RUN cd rust_services && \
    /venv/bin/maturin build --release --out /tmp/wheels && \
    /venv/bin/pip install --no-cache-dir /tmp/wheels/*.whl && \
    rm -rf /app/rust_services/target

FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r perripopo && useradd -r -g perripopo perripopo

COPY --from=builder /venv /venv
COPY --from=builder /app /app

ENV PATH="/venv/bin:${PATH}" \
    PYTHONPATH="/app:${PYTHONPATH}" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    APP_PORT=5000 \
    DATABASE_URL="postgresql://arelyxl:elmomero123@localhost:5432/lidercom?sslmode=prefer" \
    REDIS_URL="redis://localhost:6379/0" \
    PERMISSION_CACHE_TTL_MINUTES=15 \
    JWT_SECRET_KEY="super-secret-key-change-in-production" \
    JWT_ALGORITHM=HS256 \
    ACCESS_TOKEN_EXPIRE_MINUTES=15 \
    REFRESH_TOKEN_EXPIRE_DAYS=7

WORKDIR /app
USER perripopo

EXPOSE 5000

CMD ["sh", "-c", "uvicorn graphql.server:app --host 0.0.0.0 --port ${APP_PORT:-5000}"]
