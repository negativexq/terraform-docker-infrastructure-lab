from fastapi.testclient import TestClient

from main import app


client = TestClient(app)


def test_root_contains_application_name():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["application"] == "terraform-docker-infrastructure-lab"


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_metrics_exposes_prometheus_samples():
    client.get("/health")

    response = client.get("/metrics")

    assert response.status_code == 200
    assert "fastapi_http_requests_total" in response.text
    assert "fastapi_http_request_duration_seconds" in response.text
    assert "GET" in response.text


def test_test_endpoints_are_disabled_by_default(monkeypatch):
    monkeypatch.delenv("ENABLE_TEST_ENDPOINTS", raising=False)

    assert client.get("/_test/error").status_code == 404
    assert client.get("/_test/latency").status_code == 404


def test_controlled_error_endpoint(monkeypatch):
    monkeypatch.setenv("ENABLE_TEST_ENDPOINTS", "true")

    response = client.get("/_test/error")

    assert response.status_code == 500
    assert response.json() == {"detail": "Controlled test error"}


def test_controlled_latency_endpoint_validates_bounds(monkeypatch):
    monkeypatch.setenv("ENABLE_TEST_ENDPOINTS", "true")

    response = client.get("/_test/latency?delay_ms=50")
    too_short = client.get("/_test/latency?delay_ms=49")
    too_long = client.get("/_test/latency?delay_ms=2001")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "delay_ms": 50}
    assert too_short.status_code == 422
    assert too_long.status_code == 422
