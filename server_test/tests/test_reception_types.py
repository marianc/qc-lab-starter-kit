import pytest
import urllib3

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_get_reception_types(migrated_db, auth_session, base_url):
    """
    Test GET /api/reception_types.
    """
    url = f"{base_url}/api/reception_types"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    types = response.json()
    assert isinstance(types, list)
    assert len(types) == 3
