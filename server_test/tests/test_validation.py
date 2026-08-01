import pytest
import urllib3

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

@pytest.mark.parametrize("entity, property_name, value, record_id, scope_id, expected_unique", [
    ("User", "Name", "alice", 0, None, False),
    ("User", "Name", "albert", 0, None, True),
    ("User", "Code", "AL", 0, None, False),
    ("User", "Code", "AB", 0, None, True),
    ("User", "Email", "alice@qc.lab", 0, None, False),
    ("User", "Email", "albert@qc.lab", 0, None, True),
    ("Material", "Name", "Material A", 0, None, False),
    ("Material", "Name", "Material Z", 0, None, True),
    ("Material", "Code", "MA", 0, None, False),
    ("Material", "Code", "MZ", 0, None, True),
    ("Material", "Name", "Material A changed", 1, None, True),
    ("Material", "Code", "MA", 1, None, True),
    ("Unit", "Name", "box", 0, None, False),
    ("Unit", "Name", "km", 0, None, True),
    ("Unit", "Name", "box changed", 6, None, True),
    ("Unit", "Name", "kg", 6, None, False),
    ("Norm", "Name", "Norm A", 0, None, False),
    ("Norm", "Name", "Norm Z", 0, None, True),
    ("Norm", "Name", "Norm A", 2, None, False),
    ("Norm", "Name", "Norm A changed", 2, None, True),
    ("Category", "Name", "Category A", 0, None, False),
    ("Category", "Name", "Category Z", 0, None, True),
    ("Category", "Code", "CA", 0, None, False),
    ("Category", "Code", "CZ", 0, None, True),
    ("Category", "Name", "Category A", 2, None, False),
    ("Category", "Code", "CA", 2, None, False),
    ("Test", "Name", "Test A", 0, None, False),
    ("Test", "Name", "Test Z", 0, None, True),
    ("Test", "Code", "test_a", 0, None, False),
    ("Test", "Code", "test_z", 0, None, True),
    ("Test", "Name", "Test A", 5, None, False),
    ("Test", "Code", "test_a", 5, None, False),
    ("TestEnum", "Name", "Item ME3", 6, 44, False),
    ("TestEnum", "Name", "Item ME6", 6, 44, True),
    ("TestEnum", "Name", "Item ME2", 3, 44, False),
    ("TestEnum", "Name", "Item ME3 changed", 3, 44, True),
])
def test_validate_unique(migrated_db, auth_session, base_url, entity, property_name, value, record_id, scope_id, expected_unique):
    """
    Test GET /api/validate/unique for various entities and properties.
    """
    url = f"{base_url}/api/validate/unique"
    params = {
        "entity": entity,
        "property": property_name,
        "value": value,
        "id": record_id
    }
    if scope_id is not None:
        params["scope_id"] = scope_id
    
    response = auth_session.get(url, params=params)
    
    assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}. Response: {response.text}"
    
    data = response.json()
    is_unique = data.get('is_unique') if 'is_unique' in data else data.get('isUnique')
    
    assert is_unique == expected_unique, (
        f"Uniqueness validation failed for {entity}.{property_name} with value '{value}', id {record_id} and scope_id {scope_id}. "
        f"Expected {expected_unique}, but got {is_unique}."
    )

@pytest.mark.parametrize("formula, expected_valid", [
    ("// [test_g], [test_k], [pga], [[pgb__]], [[pgd__]], [pgc], [[pge__]], [[pgf__]]\n[[pgb]] * [pga] + [[pgd]] * [pgc] + [[pge]] + [[pgf]]}", True),
    ("// [test_g], [test_k], [pga], [[pgb__]], [[pgd__]], [pgc], [[pge__]], [[pgf__]]\n[[pgb]] * [pga] + [[pgd]] * [pgc] + [[pge]] + [[pgf]", False),
    ("// [test_g], [test_k], [pga], [[pgb__]], [[pgd__]], [pgc], [[pge__]], [[pgf__]]\n[[pgb]] * [pga] + [[pgd]] * [pgc] + [[pge]] + [[pgr]]", False),
    ("// [test_g], [test_k], [pga], [[pgb__]], [[pgd__]], [pgc], [[pge__]], [[pgf__]]\n[[pgb]] * [pga] + [[pgd]] * [pgc] + [[pge]] + [[pgf]]", True),
    ("// [test_g], [test_k], [pga], [[pgb__]], [[pgd__]], [pgc], [[pge__]], [[pgf__]], [[test_j__]]\n[[pgb]] * [pga] + [[pgd]] * [pgc] + [[pge]] + [[pgf]] + [[test_j]]", True),
])
def test_validate_formula(migrated_db, auth_session, base_url, formula, expected_valid):
    """
    Test GET /api/validate/formula.
    """
    url = f"{base_url}/api/validate/formula"
    # Using testId=43 (tlba) which is a calculated ARRAY test in form 8
    params = {
        "formId": 8,
        "testId": 43,
        "isCalculated": True,
        "formula": formula
    }
    
    response = auth_session.get(url, params=params)
    assert response.status_code == 200
    
    data = response.json()
    assert data['valid'] == expected_valid
