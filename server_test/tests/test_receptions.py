import pytest
import urllib3

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_get_receptions_page_1(migrated_db, auth_session, base_url):
    """
    Test GET /api/receptions?page=1&per_page=15&user_id=1.
    """
    url = f"{base_url}/api/receptions"
    params = {"page": 1, "per_page": 15, "user_id": 1}
    response = auth_session.get(url, params=params)
    
    assert response.status_code == 200
    data = response.json()
    
    items = data.get('receptions')
    total_count = data.get('totalCount')
    
    assert items is not None
    assert len(items) == 15
    # For user_id=1, there are 18 receptions where he is involved (submitted, received or rejected)
    assert total_count == 18

def test_get_receptions_page_2(migrated_db, auth_session, base_url):
    """
    Test GET /api/receptions?page=2&per_page=15&user_id=1.
    """
    url = f"{base_url}/api/receptions"
    params = {"page": 2, "per_page": 15, "user_id": 1}
    response = auth_session.get(url, params=params)
    
    assert response.status_code == 200
    data = response.json()
    
    items = data.get('receptions')
    assert len(items) == 3 # 18 - 15 = 3

def test_get_reception_by_id(migrated_db, auth_session, base_url):
    """
    Test GET /api/receptions/22.
    """
    url = f"{base_url}/api/receptions/22"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    reception = response.json()
    
    assert reception['id'] == 22
    assert reception['typeId'] == 1
    assert reception['controlCodeId'] == 63
    assert reception['isSubmitted'] is True
    assert reception['userSubmittedId'] == 1

def test_get_reception_measurement_tests(migrated_db, auth_session, base_url):
    """
    Test GET /api/receptions/22/measurement_tests.
    Returns a list of MeasurementTestDetailDto.
    """
    url = f"{base_url}/api/receptions/22/measurement_tests"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    measurements = response.json()
    assert isinstance(measurements, list)
    assert len(measurements) == 2
    
    # Measurement 48 has test_ids: 28, 37, 38 (3 unique)
    # Measurement 49 has test_ids: 3 (1 unique)
    # Total unique tests = 4
    total_tests = sum(len(m['tests']) for m in measurements)
    assert total_tests == 4

def test_get_reception_reports(migrated_db, auth_session, base_url):
    """
    Test GET /api/receptions/22/reports.
    """
    url = f"{base_url}/api/receptions/22/reports"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    reports = response.json()
    assert isinstance(reports, list)
    assert len(reports) == 2

def test_get_reception_measurement_params(migrated_db, auth_session, base_url):
    """
    Test GET /api/receptions/22/measurement_params.
    """
    url = f"{base_url}/api/receptions/22/measurement_params"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    measurements = response.json()
    assert isinstance(measurements, list)
    assert len(measurements) == 2

def test_get_reception_preview(migrated_db, auth_session, base_url):
    """
    Test GET /api/receptions/22/preview.
    """
    url = f"{base_url}/api/receptions/22/preview"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    data = response.json()
    assert data is not None
    # As observed in failure output and PreviewReportDto definition:
    assert 'activeSpecId' in data
    assert 'controlCodeName' in data
    assert 'tests' in data
    assert isinstance(data['tests'], list)
