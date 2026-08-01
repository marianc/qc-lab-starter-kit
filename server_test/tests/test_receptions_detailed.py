import pytest
import urllib3
from models import Reports

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_check_report_conflict_8(migrated_db, auth_session, base_url):
    """
    GET /api/receptions/8/check_report_conflict
    """
    url = f"{base_url}/api/receptions/8/check_report_conflict"
    response = auth_session.get(url)
    assert response.status_code == 200
    data = response.json()
    # The API returns { conflict: bool }
    assert "conflict" in data

def test_create_report_8(migrated_db, auth_session, base_url, db_session):
    """
    POST /api/receptions/8/create_report
    """
    url = f"{base_url}/api/receptions/8/create_report"
    payload = {
        "userId": 1,
        "comments": "Some explanations ..."
    }
    
    initial_count = db_session.query(Reports).count()
    response = auth_session.post(url, json=payload)
    
    assert response.status_code == 200
    data = response.json()
    new_id = data.get('id')
    assert new_id is not None
    
    db_session.expire_all()
    assert db_session.query(Reports).count() == initial_count + 1
    
    db_r = db_session.query(Reports).filter(Reports.id == new_id).first()
    assert db_r.reception_id == 8
    assert db_r.comments_submitted == payload["comments"]
    assert db_r.user_submitted_id == 1
    assert db_r.date_submitted is not None
    assert db_r.is_submitted is True
    assert db_r.is_cancelled is False
    # Verified: it replaces previous report 23 for reception 8
    assert db_r.report_replaced_id == 23
    
    # Verify report 23 was cancelled
    old_report = db_session.query(Reports).filter(Reports.id == 23).first()
    assert old_report.is_cancelled is True
    assert old_report.user_cancelled_id == 1
    assert old_report.date_cancelled is not None
