import pytest
import urllib3
from models import Tests, TestEnums, ValueTypes

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_get_tests(migrated_db, auth_session, base_url):
    """
    Test GET /api/tests.
    """
    url = f"{base_url}/api/tests"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    tests = response.json()
    assert isinstance(tests, list)
    assert len(tests) == 41

def test_get_value_types(migrated_db, auth_session, base_url):
    """
    Test GET /api/value_types.
    """
    url = f"{base_url}/api/value_types"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    types = response.json()
    assert isinstance(types, list)
    assert len(types) == 4

def test_get_test_by_id(migrated_db, auth_session, base_url):
    """
    Test GET /api/tests/{id}.
    """
    test_id = 3
    url = f"{base_url}/api/tests/{test_id}"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    test = response.json()
    assert test['id'] == 3
    assert test['name'] == "Test C"

def test_create_test_with_enums(migrated_db, auth_session, base_url, db_session):
    """
    Test POST /api/tests.
    """
    url = f"{base_url}/api/tests"
    payload = {
        "name": "Test Z",
        "description": "Description for Test Z",
        "code": "test_z",
        "typeId": 4,
        "isParam": False,
        "unitId": 10,
        "normId": 2,
        "normRef": None,
        "nrOrd": 0,
        "isObsolete": False,
        "isArray": False,
        "enums": [
            {"value": 1, "name": "Item Z1", "nrOrd": 1},
            {"value": 2, "name": "Item Z2", "nrOrd": 2},
            {"value": 3, "name": "Item Z3", "nrOrd": 3},
            {"value": 4, "name": "Item Z4", "nrOrd": 4}
        ]
    }
    
    initial_test_count = db_session.query(Tests).count()
    
    response = auth_session.post(url, json=payload)
    assert response.status_code == 200
    new_id = response.json().get('id')
    
    db_session.expire_all()
    assert db_session.query(Tests).count() == initial_test_count + 1
    
    db_test = db_session.query(Tests).filter(Tests.id == new_id).first()
    assert db_test.name == "Test Z"
    assert db_test.code == "test_z"
    
    # Verify enums
    db_enums = db_session.query(TestEnums).filter(TestEnums.test_id == new_id).all()
    assert len(db_enums) == 4
    assert sorted([e.value for e in db_enums]) == [1, 2, 3, 4]

def test_update_test(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/tests/{id}.
    Verifies only name is changing.
    """
    test_id = 5
    url = f"{base_url}/api/tests/{test_id}"
    payload = {
        "name": "Test E changed",
        "description": "Description Test E",
        "code": "test_e",
        "typeId": 2,
        "isParam": False,
        "unitId": 2,
        "normId": 3,
        "normRef": "ref E",
        "nrOrd": 5,
        "isObsolete": False,
        "isArray": False,
        "enums": None
    }
    
    initial_test = db_session.query(Tests).filter(Tests.id == test_id).first()
    initial_code = initial_test.code
    initial_type_id = initial_test.type_id
    initial_unit_id = initial_test.unit_id
    initial_norm_id = initial_test.norm_id
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    updated_test = db_session.query(Tests).filter(Tests.id == test_id).first()
    assert updated_test.name == "Test E changed"
    assert updated_test.code == initial_code
    assert updated_test.type_id == initial_type_id
    assert updated_test.unit_id == initial_unit_id
    assert updated_test.norm_id == initial_norm_id

def test_toggle_obsolete_test_true(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/tests/{id}/toggle_obsolete to make obsolete.
    """
    test_id = 5
    url = f"{base_url}/api/tests/{test_id}/toggle_obsolete"
    payload = {"isObsolete": True, "comments": "Some explanations ..."}
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    db_test = db_session.query(Tests).filter(Tests.id == test_id).first()
    assert db_test.is_obsolete is True
    assert db_test.date_obsolete is not None
    assert db_test.comments_obsolete == "Some explanations ..."

def test_toggle_obsolete_test_false(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/tests/{id}/toggle_obsolete to reactivate.
    """
    test_id = 15
    url = f"{base_url}/api/tests/{test_id}/toggle_obsolete"
    payload = {"isObsolete": False, "comments": None}
    
    # Verify initial state
    initial_test = db_session.query(Tests).filter(Tests.id == test_id).first()
    assert initial_test.is_obsolete is True
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    db_test = db_session.query(Tests).filter(Tests.id == test_id).first()
    assert db_test.is_obsolete is False
    assert db_test.date_obsolete is None
    assert db_test.comments_obsolete is None

def test_add_test_enum(migrated_db, auth_session, base_url, db_session):
    """
    Test POST /api/tests/{id}/enums.
    """
    test_id = 44
    url = f"{base_url}/api/tests/{test_id}/enums"
    payload = {"value": 6, "name": "Item ME6", "nrOrd": 6}
    
    response = auth_session.post(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    enum = db_session.query(TestEnums).filter(TestEnums.test_id == test_id, TestEnums.value == 6).first()
    assert enum is not None
    assert enum.name == "Item ME6"

def test_update_test_enum(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/tests/{id}/enums/{enumValue}.
    """
    test_id = 44
    enum_value = 3
    url = f"{base_url}/api/tests/{test_id}/enums/{enum_value}"
    payload = {"value": 3, "name": "Item ME3 changed", "nrOrd": 3}
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    enum = db_session.query(TestEnums).filter(TestEnums.test_id == test_id, TestEnums.value == enum_value).first()
    assert enum.name == "Item ME3 changed"

def test_delete_test_enum(migrated_db, auth_session, base_url, db_session):
    """
    Test DELETE /api/tests/{id}/enums/{enumValue}.
    """
    test_id = 44
    enum_value = 4
    url = f"{base_url}/api/tests/{test_id}/enums/{enum_value}"
    
    response = auth_session.delete(url)
    assert response.status_code == 200
    
    db_session.expire_all()
    enum = db_session.query(TestEnums).filter(TestEnums.test_id == test_id, TestEnums.value == enum_value).first()
    assert enum is None

def test_get_test_enums(migrated_db, auth_session, base_url):
    """
    Test GET /api/tests/{id}/enums.
    """
    test_id = 45
    url = f"{base_url}/api/tests/{test_id}/enums"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    enums = response.json()
    assert isinstance(enums, list)
    assert len(enums) == 5

def test_reorder_test_enums(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/tests/{id}/enums/reorder.
    """
    test_id = 45
    url = f"{base_url}/api/tests/{test_id}/enums/reorder"
    payload = [
        {"value": 1, "nrOrd": 1},
        {"value": 3, "nrOrd": 2},
        {"value": 2, "nrOrd": 3},
        {"value": 4, "nrOrd": 4},
        {"value": 5, "nrOrd": 5}
    ]
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    enums = db_session.query(TestEnums).filter(TestEnums.test_id == test_id).all()
    
    for item in payload:
        enum = next(e for e in enums if e.value == item['value'])
        assert enum.nr_ord == item['nrOrd']

def test_reorder_tests(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/tests/reorder.
    """
    url = f"{base_url}/api/tests/reorder"
    # Using a subset of the reorder list for the test to be concise
    payload = [
        {"id": 1, "nrOrd": 1},
        {"id": 2, "nrOrd": 2},
        {"id": 3, "nrOrd": 3}
    ]
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    for item in payload:
        db_test = db_session.query(Tests).filter(Tests.id == item['id']).first()
        assert db_test.nr_ord == item['nrOrd']
