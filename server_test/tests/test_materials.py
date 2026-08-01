import pytest
import urllib3
import config
from models import Materials, t_material_tests

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_get_material_by_id(migrated_db, auth_session, base_url):
    """
    Test GET /api/materials/{id}.
    """
    mat_id = 1
    url = f"{base_url}/api/materials/{mat_id}"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    mat = response.json()
    
    assert mat['id'] == 1
    assert mat['name'] == "Material A"
    assert mat['code'] == "MA"

def test_create_material(migrated_db, auth_session, base_url, db_session):
    """
    Test POST /api/materials.
    """
    url = f"{base_url}/api/materials"
    payload = {
        "name": "Material Z",
        "code": "MZ",
        "description": "Description for Material Z",
        "normId": 1,
        "isProduct": False,
        "isRawMaterial": False,
        "isObsolete": False
    }
    
    initial_count = db_session.query(Materials).count()
    
    response = auth_session.post(url, json=payload)
    
    # 1. Verify API Response
    assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}. Response: {response.text}"
    created_id_dto = response.json()
    new_id = created_id_dto.get('id')
    assert new_id is not None
    
    # 2. Verify Database Changes
    db_session.expire_all()
    assert db_session.query(Materials).count() == initial_count + 1
    
    db_mat = db_session.query(Materials).filter(Materials.id == new_id).first()
    assert db_mat.name == "Material Z"
    assert db_mat.code == "MZ"
    assert db_mat.norm_id == 1
    assert db_mat.is_product is False
    assert db_mat.is_raw_material is False
    assert db_mat.is_obsolete is False
    assert db_mat.date_created is not None

def test_update_material(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/materials/{id}.
    Verifies that only the name changes.
    """
    mat_id = 1
    url = f"{base_url}/api/materials/{mat_id}"
    payload = {
        "name": "Material A changed",
        "code": "MA",
        "description": "Description for Material A",
        "normId": 2,
        "isProduct": False,
        "isRawMaterial": False,
        "isObsolete": False
    }
    
    # Initial state
    initial_mat = db_session.query(Materials).filter(Materials.id == mat_id).first()
    initial_name = initial_mat.name
    initial_code = initial_mat.code
    initial_norm_id = initial_mat.norm_id
    initial_is_product = initial_mat.is_product
    initial_is_raw_material = initial_mat.is_raw_material
    initial_date_created = initial_mat.date_created
    
    response = auth_session.put(url, json=payload)
    
    # 1. Verify API Response
    assert response.status_code == 200
    
    # 2. Verify Database Changes
    db_session.expire_all()
    updated_mat = db_session.query(Materials).filter(Materials.id == mat_id).first()
    
    assert updated_mat.name == "Material A changed"
    
    # Verify others didn't change (User specifically asked to make sure only name is changing)
    # Note: Even though payload had normId: 2, if the server implementation 
    # strictly only updates Name (per user comment), we assert that.
    # However, usually PUT updates all fields. I will check the actual server behavior.
    assert updated_mat.code == initial_code
    assert updated_mat.norm_id == initial_norm_id
    assert updated_mat.is_product == initial_is_product
    assert updated_mat.is_raw_material == initial_is_raw_material
    assert updated_mat.date_created == initial_date_created

def test_toggle_obsolete_material(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/materials/{id}/toggle_obsolete.
    """
    mat_id = 1
    url = f"{base_url}/api/materials/{mat_id}/toggle_obsolete"
    payload = {
        "isObsolete": True,
        "comments": "Some explanations ..."
    }
    
    response = auth_session.put(url, json=payload)
    
    # 1. Verify API Response
    assert response.status_code == 200
    
    # 2. Verify Database Changes
    db_session.expire_all()
    updated_mat = db_session.query(Materials).filter(Materials.id == mat_id).first()
    
    assert updated_mat.is_obsolete is True
    assert updated_mat.date_obsolete is not None
    assert updated_mat.comments_obsolete == "Some explanations ..."

def test_update_material_tests(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/materials/{id}/tests.
    """
    mat_id = 1
    url = f"{base_url}/api/materials/{mat_id}/tests"
    payload = {
        "testIds": [2, 3, 1, 4, 5]
    }
    
    response = auth_session.put(url, json=payload)
    
    # 1. Verify API Response
    assert response.status_code == 200
    
    # 2. Verify Database Changes
    db_session.expire_all()
    
    # Query join table
    current_tests = db_session.query(t_material_tests).filter(t_material_tests.c.material_id == mat_id).all()
    current_test_ids = sorted([r.test_id for r in current_tests])
    
    assert current_test_ids == [1, 2, 3, 4, 5]

def test_reactivate_material(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/materials/{id}/toggle_obsolete to reactivate a material.
    """
    mat_id = 11
    url = f"{base_url}/api/materials/{mat_id}/toggle_obsolete"
    payload = {
        "isObsolete": False,
        "comments": None
    }
    
    # Verify initial state (obsolete)
    initial_mat = db_session.query(Materials).filter(Materials.id == mat_id).first()
    assert initial_mat.is_obsolete is True
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    updated_mat = db_session.query(Materials).filter(Materials.id == mat_id).first()
    assert updated_mat.is_obsolete is False
    assert updated_mat.date_obsolete is None
    assert updated_mat.comments_obsolete is None

def test_get_materials_with_valid_spec(migrated_db, auth_session, base_url):
    """
    Test GET /api/materials/with_valid_spec.
    """
    url = f"{base_url}/api/materials/with_valid_spec"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    materials = response.json()
    assert isinstance(materials, list)
    
    # Material 5 has spec 11 which is submitted
    ids = [m['id'] for m in materials]
    assert 5 in ids

def test_get_control_codes_for_certificate_mat2(migrated_db, auth_session, base_url):
    """
    GET /api/materials/2/control_codes_for_certificate.
    """
    url = f"{base_url}/api/materials/2/control_codes_for_certificate"
    response = auth_session.get(url)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)

@pytest.mark.skipif(config.TEST_SERVER != "blazor", reason="UI fallback route only exists in Blazor implementation")
def test_get_specifications_ui_fallback(migrated_db, auth_session, base_url):
    """
    GET /specifications (UI fallback).
    """
    url = f"{base_url}/specifications"
    response = auth_session.get(url)
    # This is a UI route in Blazor, returns HTML
    assert response.status_code == 200
    assert "text/html" in response.headers["Content-Type"]