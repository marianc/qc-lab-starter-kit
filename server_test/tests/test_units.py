import pytest
import urllib3
from models import Units

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_get_units(migrated_db, auth_session, base_url):
    """
    Test GET /api/units.
    """
    url = f"{base_url}/api/units"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    units = response.json()
    
    assert isinstance(units, list)
    assert len(units) == 10
    
    names = [u['name'] for u in units]
    assert "kg" in names
    assert "box" in names

def test_get_unit_by_id(migrated_db, auth_session, base_url):
    """
    Test GET /api/units/{id}.
    """
    unit_id = 6
    url = f"{base_url}/api/units/{unit_id}"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    unit = response.json()
    
    assert unit['id'] == 6
    assert unit['name'] == "box"
    assert unit['description'] == "Count"

def test_create_unit(migrated_db, auth_session, base_url, db_session):
    """
    Test POST /api/units.
    """
    url = f"{base_url}/api/units"
    payload = {
        "name": "km",
        "description": "Measure length"
    }
    
    initial_count = db_session.query(Units).count()
    
    response = auth_session.post(url, json=payload)
    
    # 1. Verify API Response
    assert response.status_code == 200
    created_id_dto = response.json()
    new_id = created_id_dto.get('id')
    assert new_id is not None
    
    # 2. Verify Database Changes
    db_session.expire_all()
    assert db_session.query(Units).count() == initial_count + 1
    
    db_unit = db_session.query(Units).filter(Units.id == new_id).first()
    assert db_unit.name == "km"
    assert db_unit.description == "Measure length"
    assert db_unit.date_created is not None

def test_update_unit(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/units/{id}.
    Verifies that only the name changes.
    """
    unit_id = 6
    url = f"{base_url}/api/units/{unit_id}"
    payload = {
        "name": "box changed",
        "description": "Count"
    }
    
    # Initial state
    initial_unit = db_session.query(Units).filter(Units.id == unit_id).first()
    initial_name = initial_unit.name
    initial_desc = initial_unit.description
    initial_date = initial_unit.date_created
    
    assert initial_name == "box"
    
    response = auth_session.put(url, json=payload)
    
    # 1. Verify API Response
    assert response.status_code == 200
    
    # 2. Verify Database Changes
    db_session.expire_all()
    updated_unit = db_session.query(Units).filter(Units.id == unit_id).first()
    
    assert updated_unit.name == "box changed"
    
    # Verify others didn't change
    assert updated_unit.description == initial_desc
    assert updated_unit.date_created == initial_date
