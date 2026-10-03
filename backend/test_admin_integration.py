"""Test otomatis integrasi backend gabungan (mobile + admin)."""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health():
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json()["status"] == "healthy"

def test_admin_flow():
    # 1. Login admin
    login_res = client.post("/api/admin/auth/login", json={
        "email": "admin@mindpal.id",
        "password": "admin123"
    })
    assert login_res.status_code == 200, f"Login failed: {login_res.text}"
    body = login_res.json()
    assert body["success"] is True
    token = body["data"]["access_token"]
    assert token is not None

    headers = {"Authorization": f"Bearer {token}"}

    # 2. Get /me
    me_res = client.get("/api/admin/auth/me", headers=headers)
    assert me_res.status_code == 200
    assert me_res.json()["data"]["role"] == "admin"

    # 3. Get /dashboard/stats
    stats_res = client.get("/api/admin/dashboard/stats", headers=headers)
    assert stats_res.status_code == 200
    assert "total_users" in stats_res.json()["data"]

    # 4. List doctors
    doctors_res = client.get("/api/admin/doctors", headers=headers)
    assert doctors_res.status_code == 200
    assert isinstance(doctors_res.json()["data"], list)

    # 5. List users
    users_res = client.get("/api/admin/users", headers=headers)
    assert users_res.status_code == 200
    assert isinstance(users_res.json()["data"], list)

    # 6. List sliders
    sliders_res = client.get("/api/admin/sliders", headers=headers)
    assert sliders_res.status_code == 200
    assert isinstance(sliders_res.json()["data"], list)

    # 7. List reports
    reports_res = client.get("/api/admin/reports", headers=headers)
    assert reports_res.status_code == 200
    assert isinstance(reports_res.json()["data"], list)

    print("\nALL ADMIN TESTS PASSED!")

if __name__ == "__main__":
    test_health()
    test_admin_flow()
