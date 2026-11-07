# Build stage
FROM python:3.12.7-slim-bookworm AS builder

WORKDIR /app

COPY requirements.txt .

RUN python -m venv /opt/venv


# Runtime stage
FROM python:3.12.7-slim-bookworm

WORKDIR /app

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080

RUN useradd --uid 10001 --create-home appuser

COPY --from=builder /opt/venv /opt/venv
COPY app.py .

USER appuser

EXPOSE 8080

CMD ["python", "app.py"]
