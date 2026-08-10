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
