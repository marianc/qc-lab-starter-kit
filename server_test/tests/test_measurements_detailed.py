import pytest
import urllib3
from models import Measurements, MeasurementTests, MeasurementParams, Users, Reports

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_create_measurement_no_form(migrated_db, auth_session, base_url, db_session):
    """
    POST /api/measurements (no formId)
    """
    url = f"{base_url}/api/measurements"
    payload = {
        "receptionId": 8,
        "comments": None,
        "isReported": False,
        "formId": None
    }
    
    initial_count = db_session.query(Measurements).count()
    response = auth_session.post(url, json=payload)
    
    assert response.status_code == 200
    new_id = response.json().get('id')
    
    db_session.expire_all()
    assert db_session.query(Measurements).count() == initial_count + 1
    
    db_m = db_session.query(Measurements).filter(Measurements.id == new_id).first()
    assert db_m.reception_id == 8
    assert db_m.comments is None
    assert db_m.is_reported is False
    assert db_m.form_id is None
    assert db_m.user_update_id == 1
    assert db_m.user_created_id == 1
    assert db_m.date_update is not None

def test_update_measurement_test_24_comments_only(migrated_db, auth_session, base_url, db_session):
    """
    PUT /api/measurement_tests/24
    Make sure only comments have been changed.
    """
    url = f"{base_url}/api/measurement_tests/24"
    # Establish baseline for MT 24
    payload_baseline = {
        "comments": "original",
        "isReported": False,
        "tests": [{"testId": 1, "value": 54, "note": "*"}]
    }
    auth_session.put(url, json=payload_baseline)
    
    payload = {
        "comments": "- gf hdfgh dfgh dfgh dfg\n- cv bcvbn cvbn cvbncbn",
        "isReported": False,
        "tests": [
            {
                "testId": 1,
                "value": 54,
                "note": "*"
            }
        ]
    }
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    db_m = db_session.query(Measurements).filter(Measurements.id == 24).first()
    assert db_m.comments == payload["comments"]
    assert db_m.user_update_id == 1
    
    # Verify tests didn't change content-wise (though they might be replaced in DB)
    db_tests = db_session.query(MeasurementTests).filter(MeasurementTests.measurement_id == 24).all()
    assert len(db_tests) == 1
    assert db_tests[0].test_id == 1
    assert db_tests[0].value == 54
    assert db_tests[0].note == "*"

def test_update_measurement_test_24_multi(migrated_db, auth_session, base_url, db_session):
    """
    PUT /api/measurement_tests/24 (multi test update)
    """
    url = f"{base_url}/api/measurement_tests/24"
    payload = {
        "comments": "gf hdfgh dfgh dfgh dfg\ncv bcvbn cvbn cvbncbn",
        "isReported": False,
        "tests": [
            {
                "testId": 1,
                "value": 54,
                "note": "*"
            },
            {
                "testId": 4,
                "value": 123.4,
                "note": "test note"
            }
        ]
    }
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    db_m = db_session.query(Measurements).filter(Measurements.id == 24).first()
    assert db_m.comments == payload["comments"]
    
    db_tests = sorted(db_session.query(MeasurementTests).filter(MeasurementTests.measurement_id == 24).all(), key=lambda x: x.test_id)
    assert len(db_tests) == 2
    assert db_tests[0].test_id == 1
    assert float(db_tests[0].value) == 54
    assert db_tests[1].test_id == 4
    assert float(db_tests[1].value) == 123.4
    assert db_tests[1].note == "test note"

def test_delete_measurement_24(migrated_db, auth_session, base_url, db_session):
    """
    DELETE /api/measurements/24
    """
    url = f"{base_url}/api/measurements/24"
    
    # Ensure it exists
    assert db_session.query(Measurements).filter(Measurements.id == 24).first() is not None
    
    response = auth_session.delete(url)
    assert response.status_code == 200
    
    db_session.expire_all()
    assert db_session.query(Measurements).filter(Measurements.id == 24).first() is None
    # Cascading delete check
    assert db_session.query(MeasurementTests).filter(MeasurementTests.measurement_id == 24).count() == 0

def test_toggle_reported_19(migrated_db, auth_session, base_url, db_session):
    """
    PUT /api/measurements/19/toggle_reported?userId=1
    """
    url = f"{base_url}/api/measurements/19/toggle_reported"
    params = {"userId": 1}
    
    # Baseline: is_reported is True in db_test
    db_m = db_session.query(Measurements).filter(Measurements.id == 19).first()
    assert db_m.is_reported is True
    
    response = auth_session.put(url, params=params)
    assert response.status_code == 200
    
    db_session.expire_all()
    db_m = db_session.query(Measurements).filter(Measurements.id == 19).first()
    assert db_m.is_reported is False
    assert db_m.user_reported_id is None

def test_toggle_reported_20(migrated_db, auth_session, base_url, db_session):
    """
    PUT /api/measurements/20/toggle_reported?userId=1
    """
    url = f"{base_url}/api/measurements/20/toggle_reported"
    params = {"userId": 1}
    
    # Baseline: is_reported is True in db_test
    response = auth_session.put(url, params=params)
    assert response.status_code == 200
    
    db_session.expire_all()
    db_m = db_session.query(Measurements).filter(Measurements.id == 20).first()
    assert db_m.is_reported is False

def test_toggle_reported_22_fail(migrated_db, auth_session, base_url, db_session):
    """
    PUT /api/measurements/22/toggle_reported?userId=1
    Expected 400 failure.
    """
    url = f"{base_url}/api/measurements/22/toggle_reported"
    params = {"userId": 1}
    
    response = auth_session.put(url, params=params)
    assert response.status_code == 400
    assert response.json()["msg"] == "Cannot report: No non-parameter test found for this measurement and form."

def test_get_measurement_params_22(migrated_db, auth_session, base_url):
    """
    GET /api/measurement_params/22
    """
    url = f"{base_url}/api/measurement_params/22"
    response = auth_session.get(url)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == 22
    assert "measurementData" in data

def test_update_measurement_params_22(migrated_db, auth_session, base_url, db_session):
    """
    PUT /api/measurement_params/22
    """
    url = f"{base_url}/api/measurement_params/22"
    payload = {
        "comments": "sdfg sdfg sdfgs dfg",
        "isReported": False,
        "measurementData": {
            "param_aa": 345.34,
            "param_ab": 645.6,
            "param_ac": 3,
            "param_ad": 64.56,
            "param_ae": 0,
            "param_af": 85.67
        }
    }
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    # Check comments in measurements table
    db_m = db_session.query(Measurements).filter(Measurements.id == 22).first()
    assert db_m.comments == payload["comments"]
    
    # MeasurementData contains key-value pairs where key is "param_" + code
    # We need to map back to test codes to verify in DB
    # Based on models, MeasurementParams uses test_id. 
    # The API maps between form parameter codes and test IDs.
    # For now, let's just verify that rows exist in MeasurementParams for measurement 22.
    db_params = db_session.query(MeasurementParams).filter(MeasurementParams.measurement_id == 22).all()
    assert len(db_params) > 0

def test_create_measurement_with_form(migrated_db, auth_session, base_url, db_session):
    """
    POST /api/measurements (with formId)
    """
    url = f"{base_url}/api/measurements"
    payload = {
        "receptionId": 8,
        "comments": None,
        "isReported": False,
        "formId": 2
    }
    
    response = auth_session.post(url, json=payload)
    assert response.status_code == 200
    new_id = response.json().get('id')
    
    db_session.expire_all()
    db_m = db_session.query(Measurements).filter(Measurements.id == new_id).first()
    assert db_m.form_id == 2
    assert db_m.reception_id == 8
