import pytest
import urllib3
from models import Specs, SpecTests, SpecTestEvals

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_get_specs_paginated(migrated_db, auth_session, base_url):
    """
    GET /api/specs?userId=1&isQCPersonnel=true.
    """
    url = f"{base_url}/api/specs"
    params = {"userId": 1, "isQCPersonnel": "true"}
    response = auth_session.get(url, params=params)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)

def test_get_spec_by_id(migrated_db, auth_session, base_url):
    """
    Test GET /api/specs/11.
    """
    url = f"{base_url}/api/specs/11"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    spec = response.json()
    assert spec['id'] == 11
    assert spec['materialId'] == 5
    assert spec['isSubmitted'] is True

def test_duplicate_spec_11(migrated_db, auth_session, base_url, db_session):
    """
    POST /api/specs/11/duplicate.
    """
    url = f"{base_url}/api/specs/11/duplicate"
    payload = {
        "userId": 1,
        "commentsSubmitted": None,
        "commentsCancelled": None
    }
    
    initial_count = db_session.query(Specs).count()
    response = auth_session.post(url, json=payload)
    assert response.status_code == 200
    new_id = response.json().get('id')
    
    db_session.expire_all()
    assert db_session.query(Specs).count() == initial_count + 1
    db_s = db_session.query(Specs).filter(Specs.id == new_id).first()
    assert db_s.material_id == 5 # Spec 11 material

def test_cancel_spec_1(migrated_db, auth_session, base_url, db_session):
    """
    PUT /api/specs/1/cancel.
    """
    url = f"{base_url}/api/specs/1/cancel"
    # Note: Payload was not provided in request, assuming empty or default action dto
    response = auth_session.put(url, json={"userId": 1})
    assert response.status_code == 200
    
    db_session.expire_all()
    db_s = db_session.query(Specs).filter(Specs.id == 1).first()
    assert db_s.is_cancelled is True

def test_create_spec(migrated_db, auth_session, base_url, db_session):
    """
    POST /api/specs.
    """
    url = f"{base_url}/api/specs"
    payload = {
        "materialId": 11,
        "userId": 1,
        "commentsSubmitted": None
    }
    
    initial_count = db_session.query(Specs).count()
    response = auth_session.post(url, json=payload)
    assert response.status_code == 200
    new_id = response.json().get('id')
    
    db_session.expire_all()
    assert db_session.query(Specs).count() == initial_count + 1
    db_s = db_session.query(Specs).filter(Specs.id == new_id).first()
    assert db_s.material_id == 11

def test_validate_condition(migrated_db, auth_session, base_url):
    """
    POST /api/specs/validate-condition.
    """
    url = f"{base_url}/api/specs/validate-condition"
    payload = "[value] > 0"
    response = auth_session.post(url, json=payload)
    assert response.status_code == 200

def test_create_spec_test_16(migrated_db, auth_session, base_url, db_session):
    """
    POST /api/specs/16/tests.
    """
    url = f"{base_url}/api/specs/16/tests"
    payload = {
        "testId": 4,
        "condition": "[value] > 0",
        "note": "> 0",
        "testFrequency": 1,
        "evals": [
            {
                "id": 0,
                "value": 4534,
                "result": None,
                "expectedResult": 1,
                "isMatch": False,
                "note": None
            }
        ]
    }
    
    response = auth_session.post(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    # Check SpecTests
    st = db_session.query(SpecTests).filter(SpecTests.spec_id == 16, SpecTests.test_id == 4).first()
    assert st is not None
    assert st.condition == payload["condition"]
    
    # Check Evals
    evals = db_session.query(SpecTestEvals).filter(SpecTestEvals.spec_id == 16, SpecTestEvals.test_id == 4).all()
    assert len(evals) == 1
    assert evals[0].value == 4534

def test_update_spec_test_16(migrated_db, auth_session, base_url, db_session):
    """
    PUT /api/specs/16/tests/1.
    """
    url = f"{base_url}/api/specs/16/tests/1"
    payload = {
        "condition": "[value] < 1100",
        "note": "< 1100",
        "testFrequency": 1,
        "evals": [
            {"id": 147, "value": 458, "result": 1, "expectedResult": 1, "isMatch": True, "note": None},
            {"id": 146, "value": 999, "result": 1, "expectedResult": 1, "isMatch": True, "note": None},
            {"id": 145, "value": 1000, "result": 0, "expectedResult": 0, "isMatch": True, "note": None},
            {"id": 148, "value": 1254, "result": 0, "expectedResult": 0, "isMatch": True, "note": None}
        ]
    }
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    st = db_session.query(SpecTests).filter(SpecTests.spec_id == 16, SpecTests.test_id == 1).first()
    assert st.condition == payload["condition"]
    
    evals = db_session.query(SpecTestEvals).filter(SpecTestEvals.spec_id == 16, SpecTestEvals.test_id == 1).all()
    assert len(evals) == 4

def test_submit_spec_17(migrated_db, auth_session, base_url, db_session):
    """
    PUT /api/specs/17/submit.
    """
    url = f"{base_url}/api/specs/17/submit"
    payload = {
        "userId": 1,
        "commentsSubmitted": "Some explanations ...",
        "commentsCancelled": None
    }
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    db_s = db_session.query(Specs).filter(Specs.id == 17).first()
    assert db_s.is_submitted is True
    assert db_s.comments_submitted == payload["commentsSubmitted"]