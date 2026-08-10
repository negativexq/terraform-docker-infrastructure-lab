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
