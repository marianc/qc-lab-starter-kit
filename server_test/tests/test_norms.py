import pytest
import urllib3
from models import Norms

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_get_norms(migrated_db, auth_session, base_url):
    """
    Test GET /api/norms (mapped from /norms in user request).
    Note: Program.cs maps apiGroup.MapGet("/norms", ...)
    """
    url = f"{base_url}/api/norms"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    norms = response.json()
    
    assert isinstance(norms, list)
    assert len(norms) == 4
    
    names = [n['name'] for n in norms]
    assert "Norm A" in names
    assert "Norm B" in names

def test_get_norm_by_id(migrated_db, auth_session, base_url):
    """
    Test GET /api/norms/{id}.
    """
    norm_id = 2
    url = f"{base_url}/api/norms/{norm_id}"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    norm = response.json()
    
    assert norm['id'] == 2
    assert norm['name'] == "Norm B"
    assert norm['description'] == "Description Norm B"

def test_update_norm(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/norms/{id}.
    Verifies that only the name changes.
    """
    norm_id = 2
    url = f"{base_url}/api/norms/{norm_id}"
    payload = {
        "name": "Norm A changed",
        "description": "Description Norm B"
    }
    
    # Initial state
    initial_norm = db_session.query(Norms).filter(Norms.id == norm_id).first()
    initial_desc = initial_norm.description
    initial_date = initial_norm.date_created
    initial_obsolete = initial_norm.is_obsolete
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    updated_norm = db_session.query(Norms).filter(Norms.id == norm_id).first()
    
    assert updated_norm.name == "Norm A changed"
    # Verify others didn't change
    assert updated_norm.description == initial_desc
    assert updated_norm.date_created == initial_date
    assert updated_norm.is_obsolete == initial_obsolete

def test_toggle_obsolete_norm_true(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/norms/{id}/toggle_obsolete to make obsolete.
    """
    norm_id = 2
    url = f"{base_url}/api/norms/{norm_id}/toggle_obsolete"
    payload = {
        "isObsolete": True,
        "comments": "Some explanations ..."
    }
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    updated_norm = db_session.query(Norms).filter(Norms.id == norm_id).first()
    
    assert updated_norm.is_obsolete is True
    assert updated_norm.date_obsolete is not None
    assert updated_norm.comments_obsolete == "Some explanations ..."

def test_toggle_obsolete_norm_false(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/norms/{id}/toggle_obsolete to reactivate.
    """
    norm_id = 3
    url = f"{base_url}/api/norms/{norm_id}/toggle_obsolete"
    payload = {
        "isObsolete": False,
        "comments": None
    }
    
    # Verify initial state (obsolete)
    initial_norm = db_session.query(Norms).filter(Norms.id == norm_id).first()
    assert initial_norm.is_obsolete is True
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    updated_norm = db_session.query(Norms).filter(Norms.id == norm_id).first()
    
    assert updated_norm.is_obsolete is False
    assert updated_norm.date_obsolete is None
    assert updated_norm.comments_obsolete is None

def test_create_norm(migrated_db, auth_session, base_url, db_session):
    """
    Test POST /api/norms.
    """
    url = f"{base_url}/api/norms"
    payload = {
        "name": "Norm Z",
        "description": "Description for Norm Z"
    }
    
    initial_count = db_session.query(Norms).count()
    
    response = auth_session.post(url, json=payload)
    assert response.status_code == 200
    
    new_id = response.json().get('id')
    assert new_id is not None
    
    db_session.expire_all()
    assert db_session.query(Norms).count() == initial_count + 1
    db_norm = db_session.query(Norms).filter(Norms.id == new_id).first()
    assert db_norm.name == "Norm Z"
    assert db_norm.description == "Description for Norm Z"
