import pytest
import urllib3
from models import Categories, t_category_tests

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_get_categories(migrated_db, auth_session, base_url):
    """
    Test GET /api/categories.
    """
    url = f"{base_url}/api/categories"
    response = auth_session.get(url)
    assert response.status_code == 200
    categories = response.json()
    assert isinstance(categories, list)
    # In db_test we have 3 categories now (based on previous check)
    assert len(categories) == 3

def test_get_category_by_id(migrated_db, auth_session, base_url):
    """
    Test GET /api/categories/{id}.
    """
    cat_id = 2
    url = f"{base_url}/api/categories/{cat_id}"
    response = auth_session.get(url)
    
    assert response.status_code == 200
    cat = response.json()
    assert cat['id'] == 2
    assert cat['name'] == "Category B"
    assert cat['code'] == "CB"

def test_create_category(migrated_db, auth_session, base_url, db_session):
    """
    Test POST /api/categories.
    """
    url = f"{base_url}/api/categories"
    new_category_data = {
        "name": "New Category",
        "code": "NC",
        "description": "Description for new category"
    }
    
    initial_count = db_session.query(Categories).count()
    
    response = auth_session.post(url, json=new_category_data)
    
    # 1. Verify API Response
    assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}. Response: {response.text}"
    created_category = response.json()
    new_id = created_category.get('id')
    assert new_id is not None
    
    # 2. Verify Database Changes
    db_session.expire_all()
    assert db_session.query(Categories).count() == initial_count + 1
    db_cat = db_session.query(Categories).filter(Categories.id == new_id).first()
    assert db_cat.name == "New Category"
    assert db_cat.code == "NC"

def test_update_category(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/categories/{id}.
    Verifies name update.
    """
    cat_id = 2
    url = f"{base_url}/api/categories/{cat_id}"
    payload = {
        "name": "Category B changed",
        "code": "CB",
        "description": "Description for Category B"
    }
    
    initial_cat = db_session.query(Categories).filter(Categories.id == cat_id).first()
    initial_code = initial_cat.code
    initial_desc = initial_cat.description
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    updated_cat = db_session.query(Categories).filter(Categories.id == cat_id).first()
    assert updated_cat.name == "Category B changed"
    assert updated_cat.code == initial_code
    assert updated_cat.description == initial_desc

def test_toggle_obsolete_category_true(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/categories/{id}/toggle_obsolete to make obsolete.
    """
    cat_id = 2
    url = f"{base_url}/api/categories/{cat_id}/toggle_obsolete"
    payload = {
        "isObsolete": True,
        "comments": "Some explanations ..."
    }
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    db_cat = db_session.query(Categories).filter(Categories.id == cat_id).first()
    assert db_cat.is_obsolete is True
    assert db_cat.date_obsolete is not None
    assert db_cat.comments_obsolete == "Some explanations ..."

def test_toggle_obsolete_category_false(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/categories/{id}/toggle_obsolete to reactivate.
    """
    cat_id = 3
    url = f"{base_url}/api/categories/{cat_id}/toggle_obsolete"
    payload = {
        "isObsolete": False,
        "comments": None
    }
    
    # Verify initial state (obsolete)
    initial_cat = db_session.query(Categories).filter(Categories.id == cat_id).first()
    assert initial_cat.is_obsolete is True
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    db_cat = db_session.query(Categories).filter(Categories.id == cat_id).first()
    assert db_cat.is_obsolete is False
    assert db_cat.date_obsolete is None
    assert db_cat.comments_obsolete is None

def test_update_category_tests(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/categories/{id}/tests.
    """
    cat_id = 2
    url = f"{base_url}/api/categories/{cat_id}/tests"
    payload = {
        "testIds": [1, 3, 4, 5, 28, 42]
    }
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    current_tests = db_session.query(t_category_tests).filter(t_category_tests.c.category_id == cat_id).all()
    current_test_ids = sorted([r.test_id for r in current_tests])
    
    assert current_test_ids == [1, 3, 4, 5, 28, 42]