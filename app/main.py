import os
import time

import psycopg
from fastapi import FastAPI, HTTPException
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
from starlette.requests import Request
from starlette.responses import Response

app = FastAPI(title="Terraform Docker Infrastructure Lab API", version="1.0.0")

HTTP_REQUESTS = Counter(
    "fastapi_http_requests_total",
    "Total HTTP requests handled by the FastAPI application.",
    ("method", "path", "status"),
)
HTTP_REQUEST_DURATION = Histogram(
    "fastapi_http_request_duration_seconds",
    "HTTP request duration in seconds.",
    ("method", "path"),
)


@app.middleware("http")
async def record_http_metrics(request: Request, call_next):
    started_at = time.perf_counter()
    response = await call_next(request)
    path = request.url.path
    HTTP_REQUESTS.labels(request.method, path, str(response.status_code)).inc()
    HTTP_REQUEST_DURATION.labels(request.method, path).observe(time.perf_counter() - started_at)
    return response


def database_connection():
    return psycopg.connect(
        host=os.getenv("POSTGRES_HOST", "localhost"),
        dbname=os.getenv("POSTGRES_DB", "appdb"),
        user=os.getenv("POSTGRES_USER", "appuser"),
        password=os.getenv("POSTGRES_PASSWORD", ""),
        connect_timeout=3,
    )


@app.get("/")
def root():
    return {
        "application": "terraform-docker-infrastructure-lab",
        "environment": os.getenv("APP_ENV", "development"),
        "message": "FastAPI is running behind Nginx",
    }


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/metrics", include_in_schema=False)
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/db-health")
def db_health():
    try:
        with database_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                cursor.fetchone()
        return {"status": "ok", "database": "reachable"}
    except psycopg.Error as error:
        raise HTTPException(
            status_code=503,
            detail={"status": "error", "database": "unreachable", "detail": str(error)},
        ) from error
