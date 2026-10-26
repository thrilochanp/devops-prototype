"""orders-api: a small service that exercises every part of the DevOps prototype platform.

Endpoints: health and readiness probes, a tiny in-memory orders CRUD, Prometheus metrics,
and a chaos switch (dev only) that injects HTTP 500s so alerts can be tested end to end.
"""

import json
import logging
import os
import random
import sys
import time
import uuid

from fastapi import FastAPI, HTTPException, Request, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
from pydantic import BaseModel, Field
from starlette.routing import Match

APP_VERSION = os.getenv("APP_VERSION", "dev")
CHAOS_ENABLED = os.getenv("CHAOS_ENABLED", "false").lower() == "true"

REQUESTS = Counter(
    "http_requests_total", "HTTP requests handled", ["method", "route", "status"]
)
LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "route"],
    buckets=(0.01, 0.025, 0.05, 0.1, 0.25, 0.3, 0.5, 1.0, 2.5),
)

logging.basicConfig(stream=sys.stdout, level=logging.INFO, format="%(message)s")
log = logging.getLogger("orders-api")

app = FastAPI(title="orders-api", version=APP_VERSION)

_orders: dict[str, dict] = {}
_chaos = {"error_rate": 0.0}


class OrderIn(BaseModel):
    item: str = Field(min_length=1, max_length=64)
    quantity: int = Field(ge=1, le=100)


class ChaosIn(BaseModel):
    error_rate: float = Field(ge=0.0, le=1.0)


def _route_template(request: Request) -> str:
    """Return the route pattern (e.g. /orders/{order_id}) so metrics stay low-cardinality."""
    for route in app.router.routes:
        match, _ = route.matches(request.scope)
        if match == Match.FULL:
            return getattr(route, "path", "unmatched")
    return "unmatched"


@app.middleware("http")
async def observe(request: Request, call_next):
    route = _route_template(request)
    start = time.perf_counter()
    status = 500
    try:
        response = await call_next(request)
        status = response.status_code
        return response
    finally:
        elapsed = time.perf_counter() - start
        REQUESTS.labels(request.method, route, str(status)).inc()
        LATENCY.labels(request.method, route).observe(elapsed)
        if route not in ("/healthz", "/readyz", "/metrics"):
            log.info(
                json.dumps(
                    {
                        "msg": "request",
                        "method": request.method,
                        "route": route,
                        "status": status,
                        "duration_ms": round(elapsed * 1000, 2),
                        "version": APP_VERSION,
                    }
                )
            )


def _maybe_fail() -> None:
    if _chaos["error_rate"] > 0 and random.random() < _chaos["error_rate"]:
        raise HTTPException(status_code=500, detail="chaos: injected failure")


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/readyz")
def readyz():
    return {"status": "ready"}


@app.get("/version")
def version():
    return {"version": APP_VERSION}


@app.get("/orders")
def list_orders():
    _maybe_fail()
    return list(_orders.values())


@app.post("/orders", status_code=201)
def create_order(order: OrderIn):
    _maybe_fail()
    order_id = uuid.uuid4().hex[:12]
    record = {"id": order_id, **order.model_dump()}
    _orders[order_id] = record
    return record


@app.get("/orders/{order_id}")
def get_order(order_id: str):
    _maybe_fail()
    if order_id not in _orders:
        raise HTTPException(status_code=404, detail="order not found")
    return _orders[order_id]


@app.post("/chaos")
def set_chaos(chaos: ChaosIn):
    if not CHAOS_ENABLED:
        raise HTTPException(status_code=404, detail="chaos endpoint disabled")
    _chaos["error_rate"] = chaos.error_rate
    log.info(json.dumps({"msg": "chaos updated", "error_rate": chaos.error_rate}))
    return _chaos


@app.get("/metrics")
def metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)
