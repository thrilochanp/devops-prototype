import pytest
from fastapi.testclient import TestClient

import main

client = TestClient(main.app)


@pytest.fixture(autouse=True)
def reset_state(monkeypatch):
    main._orders.clear()
    main._chaos["error_rate"] = 0.0
    monkeypatch.setattr(main, "CHAOS_ENABLED", False)
    yield


def test_health_and_ready():
    assert client.get("/healthz").json() == {"status": "ok"}
    assert client.get("/readyz").json() == {"status": "ready"}


def test_create_then_get_order():
    created = client.post("/orders", json={"item": "keyboard", "quantity": 2})
    assert created.status_code == 201
    order_id = created.json()["id"]
    fetched = client.get(f"/orders/{order_id}")
    assert fetched.status_code == 200
    assert fetched.json()["item"] == "keyboard"
    assert len(client.get("/orders").json()) == 1


@pytest.mark.parametrize("payload", [{"item": "", "quantity": 1}, {"item": "x", "quantity": 0}])
def test_validation_rejects_bad_orders(payload):
    assert client.post("/orders", json=payload).status_code == 422


def test_missing_order_is_404():
    assert client.get("/orders/nope").status_code == 404


def test_metrics_use_route_templates():
    client.get("/orders/abc")
    body = client.get("/metrics").text
    assert "http_requests_total" in body
    assert 'route="/orders/{order_id}"' in body
    assert 'route="/orders/abc"' not in body


def test_chaos_disabled_by_default():
    assert client.post("/chaos", json={"error_rate": 1.0}).status_code == 404


def test_chaos_injects_errors_when_enabled(monkeypatch):
    monkeypatch.setattr(main, "CHAOS_ENABLED", True)
    assert client.post("/chaos", json={"error_rate": 1.0}).status_code == 200
    assert client.get("/orders").status_code == 500
    client.post("/chaos", json={"error_rate": 0.0})
    assert client.get("/orders").status_code == 200


def test_version_endpoint():
    assert "version" in client.get("/version").json()
