import os

import psycopg
from fastapi import FastAPI, HTTPException

app = FastAPI(title="Terraform Docker Infrastructure Lab API", version="1.0.0")


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
