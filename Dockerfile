# ═══════════════════════════════════════════════════════════════════
# CP2 — Production-ready Dockerfile với multi-stage build
# ═══════════════════════════════════════════════════════════════════

# ─── Stage 1: Builder ─────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

# Cài build tools (chỉ cần trong stage này, bị vứt sau)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements TRƯỚC để tận dụng Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ─── Stage 2: Runtime ─────────────────────────────────────────────
FROM python:3.11-slim AS runtime

WORKDIR /app

# Tạo user thường (không chạy root)
RUN useradd --create-home --uid 10001 appuser

# Copy đã cài đặt từ builder stage
COPY --from=builder /install /usr/local

# Copy source code SAU (để tận dụng cache khi chỉ sửa code)
COPY app ./app
COPY utils ./utils

# Chuyển sang user thường
USER appuser

EXPOSE 8000

# Healthcheck: gọi /health mỗi 30s
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health').read()" || exit 1

# Đọc PORT từ biến môi trường (cloud tự gán)
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
