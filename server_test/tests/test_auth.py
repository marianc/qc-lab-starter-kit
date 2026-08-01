import pytest
import urllib3

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_get_auth_me(migrated_db, auth_session, base_url):
    """
    Test GET /api/auth/me.
    Verifies that the server returns the session info for the currently logged-in user (Alice).
    """
    url = f"{base_url}/api/auth/me"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    user = response.json()
    
    # UserSessionDto has camelCase keys: id, name, email, roles, mustChangePassword
    assert user['email'] == "alice@qc.lab"
    assert user['name'] == "alice"
    assert "Admin" in user['roles']
    assert user['mustChangePassword'] is False
