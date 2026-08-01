import pytest
import urllib3

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_get_control_codes_by_material(migrated_db, auth_session, base_url):
    """
    Test GET /api/control_codes/by_material/5.
    """
    url = f"{base_url}/api/control_codes/by_material/5"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    codes = response.json()
    assert isinstance(codes, list)
    assert len(codes) == 4
    
    code_strings = [c['code'] for c in codes]
    assert 'GEN-5-2025-04-26' in code_strings
