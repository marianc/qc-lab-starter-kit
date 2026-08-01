import pytest
import urllib3

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_get_measurement_test_by_id(migrated_db, auth_session, base_url):
    """
    Test GET /api/measurement_tests/48.
    """
    url = f"{base_url}/api/measurement_tests/48"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    data = response.json()
    assert data['id'] == 48
    assert data['receptionId'] == 22
    assert isinstance(data['tests'], list)
    assert len(data['tests']) == 3

def test_get_measurement_param_by_id(migrated_db, auth_session, base_url):
    """
    Test GET /api/measurement_params/50.
    """
    url = f"{base_url}/api/measurement_params/50"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    data = response.json()
    assert data['id'] == 50
    assert data['receptionId'] == 22
    assert data['formId'] == 7
    assert isinstance(data['measurementData'], dict)