import pytest
import urllib3
from models import Certificates

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_get_certification_status(migrated_db, auth_session, base_url):
    """
    GET /api/certification_status.
    """
    url = f"{base_url}/api/certification_status"
    response = auth_session.get(url)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)

def test_get_certificates_paginated(migrated_db, auth_session, base_url):
    """
    GET /api/certificates?page=1&pageSize=15&isQCPersonnel=true.
    """
    url = f"{base_url}/api/certificates"
    params = {"page": 1, "pageSize": 15, "isQCPersonnel": "true"}
    response = auth_session.get(url, params=params)
    assert response.status_code == 200
    data = response.json()
    # Based on Program.cs, it likely returns PaginatedCertificatesDto
    assert "certificates" in data or isinstance(data, list)

def test_get_certificate_by_id(migrated_db, auth_session, base_url):
    """
    GET /api/certificates/6.
    """
    url = f"{base_url}/api/certificates/6"
    response = auth_session.get(url)
    assert response.status_code == 200
    cert = response.json()
    assert cert["id"] == 6

def test_cancel_certificate_6(migrated_db, auth_session, base_url, db_session):
    """
    PUT /api/certificates/6/cancel.
    """
    url = f"{base_url}/api/certificates/6/cancel"
    payload = {
        "userId": 1,
        "commentsSubmitted": None,
        "commentsCancelled": "Some explanation ..."
    }
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    db_c = db_session.query(Certificates).filter(Certificates.id == 6).first()
    assert db_c.is_cancelled is True
    assert db_c.user_cancelled_id == 1
    assert db_c.comments_cancelled == payload["commentsCancelled"]

def test_generate_certificate_mat3(migrated_db, auth_session, base_url, db_session):
    """
    POST /api/certificates/generate (material 3).
    """
    url = f"{base_url}/api/certificates/generate"
    payload = {
        "materialId": 3,
        "controlCodeId": 69,
        "userId": 1
    }
    
    initial_count = db_session.query(Certificates).count()
    response = auth_session.post(url, json=payload)
    assert response.status_code == 200
    new_id = response.json().get('id')
    
    db_session.expire_all()
    assert db_session.query(Certificates).count() == initial_count + 1
    db_c = db_session.query(Certificates).filter(Certificates.id == new_id).first()
    assert db_c.control_code_id == 69

def test_certificate_8_workflow(migrated_db, auth_session, base_url, db_session):
    """
    Workflow for certificate 8: Refresh, Analyze, Submit.
    """
    # 1. Refresh tests
    refresh_url = f"{base_url}/api/certificates/8/refresh_tests"
    response = auth_session.put(refresh_url)
    assert response.status_code == 200
    
    # 2. Analyze results
    analyze_url = f"{base_url}/api/certificates/8/analyze_results"
    response = auth_session.get(analyze_url)
    assert response.status_code == 200
    
    # 3. Submit
    submit_url = f"{base_url}/api/certificates/8/submit"
    payload = {
        "userId": 1,
        "commentsSubmitted": "0 of testing results are out of specification\nMissing tests:\nTest C\nTest G\nTest J\nTest K\n------------\nSome explanations ...",
        "commentsCancelled": None
    }
    
    response = auth_session.put(submit_url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    db_c = db_session.query(Certificates).filter(Certificates.id == 8).first()
    assert db_c.is_submitted is True
    assert db_c.comments_submitted == payload["commentsSubmitted"]

def test_generate_certificate_mat2(migrated_db, auth_session, base_url, db_session):
    """
    POST /api/certificates/generate (material 2).
    """
    url = f"{base_url}/api/certificates/generate"
    payload = {
        "materialId": 2,
        "controlCodeId": 60,
        "userId": 1
    }
    
    response = auth_session.post(url, json=payload)
    assert response.status_code == 200