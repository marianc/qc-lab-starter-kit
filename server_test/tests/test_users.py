import pytest
import urllib3
from models import Users

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_get_users(migrated_db, auth_session, base_url):
    """
    Test GET api/users.
    Assesses the response against the expected data in the reference database.
    """
    url = f"{base_url}/api/users"
    response = auth_session.get(url)
    
    # Assert successful response
    assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}. Response: {response.text}"
    
    users = response.json()
    
    # Based on db_test, we expect 8 users
    assert isinstance(users, list)
    assert len(users) == 8, f"Expected 8 users, but found {len(users)}"
    
    # Verify Alice is in the list
    alice = next((u for u in users if u.get('email') == 'alice@qc.lab'), None)
    assert alice is not None, "Alice was not found in the users list"
    
    # Verify Alice's data matches db_test (using camelCase as observed in API)
    assert alice['tag'] == 'alice'
    assert alice['isAdmin'] is True
    assert alice['isLabPers'] is True
    assert alice['isQcPers'] is True

def test_get_user_by_id(migrated_db, auth_session, base_url):
    """
    Test GET /api/users/{id}.
    """
    user_id = 2
    url = f"{base_url}/api/users/{user_id}"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    user = response.json()
    
    assert user['id'] == 2
    assert user['tag'] == "bob"
    assert user['email'] == "bob@qc.lab"
    assert user['code'] == "BO"
    assert user['firstName'] == "Bob"

def test_create_user(migrated_db, auth_session, base_url, db_session):
    """
    Test POST /api/users.
    Verifies API response and database changes using SQLAlchemy models.
    """
    url = f"{base_url}/api/users"
    new_user_data = {
        "tag": "albert",
        "code": "AB",
        "email": "albert@qc.lab",
        "firstName": "Albert",
        "lastName": None,
        "isAdmin": False,
        "isLabPers": False,
        "isQcPers": False,
        "password": "Pass@word1"
    }
    
    # Pre-check: count users in DB
    initial_count = db_session.query(Users).count()
    
    response = auth_session.post(url, json=new_user_data)
    
    # 1. Verify API Response
    assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}. Response: {response.text}"
    created_id_dto = response.json()
    new_id = created_id_dto.get('id')
    assert new_id is not None
    
    # 2. Verify Database Changes using SQLAlchemy
    # Re-fetch session data or clear cache if needed, though usually fresh query is fine
    db_session.expire_all()
    
    # Assert exactly 1 new user in users table (total count should be 9)
    final_count = db_session.query(Users).count()
    assert final_count == initial_count + 1
    
    # Fetch the newly created user from DB
    db_user = db_session.query(Users).filter(Users.id == new_id).first()
    assert db_user is not None
    
    # Assess submitted data and other fields
    assert db_user.tag == "albert"
    assert db_user.code == "AB"
    assert db_user.email == "albert@qc.lab"
    assert db_user.first_name == "Albert"
    assert db_user.last_name is None
    assert db_user.is_admin is False
    assert db_user.is_lab_pers is False
    assert db_user.is_qc_pers is False
    
    # Assess system-generated fields
    assert db_user.must_change_password is True
    assert db_user.date_created is not None
    assert db_user.date_password_changed is not None
    assert db_user.password_hash is not None
    assert db_user.password_salt is not None
    
    # Assess nulls for fields not set
    assert db_user.session_id is None
    assert db_user.date_session_created is None
    assert db_user.date_session_expire is None
    assert db_user.refresh_token is None
    assert db_user.is_obsolete is False
    assert db_user.date_obsolete is None
    assert db_user.comments_obsolete is None

def test_reset_password(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/users/{id}/reset_password.
    Verifies that the user's password fields are updated and session is cleared in the database.
    """
    user_id = 2
    url = f"{base_url}/api/users/{user_id}/reset_password"
    payload = {
        "newPassword": "Pass@word2",
        "confirmPassword": "Pass@word2"
    }
    
    # 1. Fetch initial state of User 2
    initial_user = db_session.query(Users).filter(Users.id == user_id).first()
    assert initial_user.must_change_password is False
    
    # Store initial values to avoid object reference issues after refresh
    initial_hash = initial_user.password_hash
    initial_salt = initial_user.password_salt
    initial_tag = initial_user.tag
    initial_email = initial_user.email
    
    response = auth_session.put(url, json=payload)
    
    # 2. Verify API Response
    assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}. Response: {response.text}"
    
    # 3. Verify Database Changes
    db_session.expire_all()
    updated_user = db_session.query(Users).filter(Users.id == user_id).first()
    
    # Check that specific fields changed as expected
    assert updated_user.password_hash != initial_hash
    assert updated_user.password_salt != initial_salt
    assert updated_user.must_change_password is True
    assert updated_user.date_password_changed is not None
    
    # Session fields must be cleared
    assert updated_user.session_id is None
    assert updated_user.date_session_created is None
    assert updated_user.date_session_expire is None
    
    # These should remain the same
    assert updated_user.tag == initial_tag
    assert updated_user.email == initial_email
    assert updated_user.id == user_id
    
    # Confirm count hasn't changed
    assert db_session.query(Users).count() == 8

def test_toggle_obsolete_user(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/users/{id}/toggle_obsolete.
    Verifies that the user's obsolete status is updated and session is cleared.
    """
    user_id = 2
    url = f"{base_url}/api/users/{user_id}/toggle_obsolete"
    payload = {
        "isObsolete": True,
        "comments": "Some explanations ..."
    }
    
    # 1. Fetch initial state
    initial_user = db_session.query(Users).filter(Users.id == user_id).first()
    assert initial_user.is_obsolete is False
    assert initial_user.date_obsolete is None
    assert initial_user.comments_obsolete is None
    
    response = auth_session.put(url, json=payload)
    
    # 2. Verify API Response
    assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}. Response: {response.text}"
    
    # 3. Verify Database Changes
    db_session.expire_all()
    updated_user = db_session.query(Users).filter(Users.id == user_id).first()
    
    assert updated_user.is_obsolete is True
    assert updated_user.date_obsolete is not None
    assert updated_user.comments_obsolete == "Some explanations ..."
    
    # Session must be cleared when made obsolete
    assert updated_user.session_id is None
    assert updated_user.date_session_created is None
    assert updated_user.date_session_expire is None
    
    # Confirm other users (like Alice) are not affected except for auth session refresh
    # which we generally ignore as requested, but we can verify Alice is still not obsolete.
    alice = db_session.query(Users).filter(Users.id == 1).first()
    assert alice.is_obsolete is False
    
    # Confirm count remains the same (no rows added or deleted)
    assert db_session.query(Users).count() == 8

def test_reactivate_user(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/users/{id}/toggle_obsolete to reactivate a user.
    """
    user_id = 4
    url = f"{base_url}/api/users/{user_id}/toggle_obsolete"
    payload = {
        "isObsolete": False,
        "comments": None
    }
    
    # Verify initial state (obsolete)
    initial_user = db_session.query(Users).filter(Users.id == user_id).first()
    assert initial_user.is_obsolete is True
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    updated_user = db_session.query(Users).filter(Users.id == user_id).first()
    assert updated_user.is_obsolete is False
    assert updated_user.date_obsolete is None
    assert updated_user.comments_obsolete is None
