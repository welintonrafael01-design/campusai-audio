from fastapi.testclient import TestClient

from app.main import app


def test_cors_preflight_allows_ephemeral_flutter_web_loopback_origin():
    origin = "http://localhost:45678"
    response = TestClient(app).options(
        "/cloud/library-documents",
        headers={
            "Origin": origin,
            "Access-Control-Request-Method": "GET",
            "Access-Control-Request-Headers": "authorization,content-type",
        },
    )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == origin


def test_cors_preflight_rejects_non_loopback_untrusted_origin():
    response = TestClient(app).options(
        "/cloud/library-documents",
        headers={
            "Origin": "https://untrusted.example",
            "Access-Control-Request-Method": "GET",
        },
    )

    assert response.status_code == 400
    assert "access-control-allow-origin" not in response.headers
