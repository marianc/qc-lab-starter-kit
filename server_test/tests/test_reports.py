import pytest
import urllib3
from models import Reports

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_get_reports_paginated(migrated_db, auth_session, base_url):
    """
    Test GET /api/reports?page=1&pageSize=15&userId=1.
    """
    url = f"{base_url}/api/reports"
    params = {"page": 1, "pageSize": 15, "userId": 1}
    response = auth_session.get(url, params=params)
    
    assert response.status_code == 200
    data = response.json()
    # PaginatedReportsDto uses 'reports' for items
    assert "reports" in data
    assert "totalCount" in data

def test_get_report_by_id(migrated_db, auth_session, base_url):
    """
    Test GET /api/reports/28.
    """
    url = f"{base_url}/api/reports/28"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    report = response.json()
    assert report["id"] == 28

def test_cancel_report_28(migrated_db, auth_session, base_url, db_session):
    """
    PUT /api/reports/28/cancel.
    """
    url = f"{base_url}/api/reports/28/cancel"
    payload = {
        "userId": 1,
        "commentsCancelled": "Some explanations ..."
    }
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    db_r = db_session.query(Reports).filter(Reports.id == 28).first()
    assert db_r.is_cancelled is True
    assert db_r.user_cancelled_id == 1
    assert db_r.comments_cancelled == payload["commentsCancelled"]
    assert db_r.date_cancelled is not None
