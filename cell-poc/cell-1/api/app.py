from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from redis import Redis
import psycopg2
import os
from typing import Optional
from prometheus_client import Counter, Histogram, generate_latest
from fastapi.responses import Response
import time

app = FastAPI()
redis_client = Redis(
    host=os.getenv("REDIS_HOST", "cell-1-redis"), port=6379, decode_responses=True
)

REQUEST_COUNT = Counter("api_requests_total", "Total requests", ["cell", "endpoint"])
REQUEST_DURATION = Histogram(
    "api_request_duration_seconds", "Request duration", ["cell", "endpoint"]
)


class DataItem(BaseModel):
    key: str
    value: str


def get_db_connection():
    return psycopg2.connect(
        host=os.getenv("POSTGRES_HOST", "cell-1-postgres"),
        database=os.getenv("DB_NAME", "celldb"),
        user=os.getenv("DB_USER", "celluser"),
        password=os.getenv("DB_PASS", "cellpass123"),
    )


@app.middleware("http")
async def add_metrics(request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time

    cell_id = os.getenv("CELL_ID", "unknown")
    endpoint = request.url.path
    REQUEST_COUNT.labels(cell=cell_id, endpoint=endpoint).inc()
    REQUEST_DURATION.labels(cell=cell_id, endpoint=endpoint).observe(duration)

    return response


@app.get("/health")
def health():
    return {"status": "healthy", "cell": os.getenv("CELL_ID", "unknown")}


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type="text/plain")


@app.get("/data/{key}")
def get_data(key: str):
    cached = redis_client.get(key)
    if cached:
        return {"value": cached, "source": "cache", "cell": os.getenv("CELL_ID")}

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT value FROM data WHERE key=%s", (key,))
    result = cur.fetchone()
    conn.close()

    if result:
        redis_client.set(key, result[0], ex=300)
        return {"value": result[0], "source": "database", "cell": os.getenv("CELL_ID")}

    raise HTTPException(status_code=404, detail="not found")


@app.post("/data")
def post_data(item: DataItem):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        """INSERT INTO data (key, value) 
           VALUES (%s, %s) 
           ON CONFLICT (key) DO UPDATE SET value=EXCLUDED.value""",
        (item.key, item.value),
    )
    conn.commit()
    conn.close()
    redis_client.delete(item.key)
    return {"status": "ok", "cell": os.getenv("CELL_ID")}


@app.delete("/data/{key}")
def delete_data(key: str):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM data WHERE key=%s", (key,))
    conn.commit()
    conn.close()
    redis_client.delete(key)
    return {"status": "deleted", "cell": os.getenv("CELL_ID")}
