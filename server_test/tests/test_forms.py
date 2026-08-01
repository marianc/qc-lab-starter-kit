import pytest
import urllib3
from decimal import Decimal
from models import FormGroups, Forms, FormParams, FormEvals, FormEvalParams, Tests

# Suppress insecure request warnings for localhost
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_get_form_groups(migrated_db, auth_session, base_url):
    """
    Test GET /api/form_groups.
    """
    url = f"{base_url}/api/form_groups"
    response = auth_session.get(url)
    assert response.status_code == 200
    groups = response.json()
    assert isinstance(groups, list)
    assert len(groups) == 7

def test_get_form_group_by_id(migrated_db, auth_session, base_url):
    """
    Test GET /api/form_groups/{id}.
    """
    group_id = 1
    url = f"{base_url}/api/form_groups/{group_id}"
    response = auth_session.get(url)
    assert response.status_code == 200
    group = response.json()
    assert group['id'] == 1

def test_get_form_by_id(migrated_db, auth_session, base_url):
    """
    Test GET /api/forms/{id}.
    """
    form_id = 8
    url = f"{base_url}/api/forms/{form_id}"
    response = auth_session.get(url)
    assert response.status_code == 200
    form = response.json()
    assert form['id'] == 8

def test_add_form_param(migrated_db, auth_session, base_url, db_session):
    """
    Test POST /api/forms/{id}/params.
    """
    form_id = 8
    url = f"{base_url}/api/forms/{form_id}/params"
    payload = {
        "testId": 1,
        "isCalculated": False,
        "formula": None,
        "codeRelatedArrays": None,
        "isRequired": False,
        "defaultValue": None,
        "nrOrd": 15,
        "nrOrdCalc": 0
    }
    
    initial_count = db_session.query(FormParams).filter(FormParams.form_id == form_id).count()
    
    response = auth_session.post(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    assert db_session.query(FormParams).filter(FormParams.form_id == form_id).count() == initial_count + 1

def test_get_form_evals(migrated_db, auth_session, base_url):
    """
    Test GET /api/forms/{id}/evals.
    """
    form_id = 8
    url = f"{base_url}/api/forms/{form_id}/evals"
    response = auth_session.get(url)
    assert response.status_code == 200
    evals = response.json()
    assert isinstance(evals, list)
    assert len(evals) >= 1

def test_delete_form_param(migrated_db, auth_session, base_url, db_session):
    """
    Test DELETE /api/forms/{id}/params/{testId}.
    """
    form_id = 8
    test_id = 43
    url = f"{base_url}/api/forms/{form_id}/params/{test_id}"
    
    response = auth_session.delete(url)
    assert response.status_code == 200
    
    db_session.expire_all()
    param = db_session.query(FormParams).filter(FormParams.form_id == form_id, FormParams.test_id == test_id).first()
    assert param is None

def test_update_form_param(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/forms/{id}/params/{testId}.
    """
    form_id = 8
    test_id = 37
    url = f"{base_url}/api/forms/{form_id}/params/{test_id}"
    payload = {
        "testId": 37,
        "isCalculated": True,
        "formula": "// [test_g], [test_k], [pga], [[pgb__]], [[pgd__]], [pgc], [[pge__]], [[pgf__]]\n[[pgb]] * [pga] + [[pgd]] * [pgc] + [[pge]] + [[pgf]]",
        "codeRelatedArrays": None,
        "isRequired": False,
        "defaultValue": None,
        "nrOrd": 3,
        "nrOrdCalc": 13
    }
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    param = db_session.query(FormParams).filter(FormParams.form_id == form_id, FormParams.test_id == test_id).first()
    assert param.is_calculated is True

def test_reorder_form_params(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/forms/{id}/params/reorder.
    """
    form_id = 8
    url = f"{base_url}/api/forms/{form_id}/params/reorder"
    payload = [
        {"testId": 28, "nrOrd": 1},
        {"testId": 41, "nrOrd": 2},
        {"testId": 38, "nrOrd": 3}
    ]
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    for item in payload:
        param = db_session.query(FormParams).filter(FormParams.form_id == form_id, FormParams.test_id == item['testId']).first()
        assert param.nr_ord == item['nrOrd']

def test_validate_form(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/forms/{id}/validate.
    """
    form_id = 8
    
    # 1. Prepare evaluations to pass
    # First, get ALL form parameters to know which are calculated
    params_info = (db_session.query(FormParams, Tests.code, FormParams.is_calculated)
                  .join(Tests, FormParams.test_id == Tests.id)
                  .filter(FormParams.form_id == form_id).all())
    
    calc_codes = {p.code for p in params_info if p.is_calculated}
    input_codes = {p.code for p in params_info if not p.is_calculated}

    evals = db_session.query(FormEvals).filter(FormEvals.form_id == form_id).all()
    for ev in evals:
        # Trigger calculation to get latest 'value' from engine
        auth_session.post(f"{base_url}/api/form-evals/{ev.id}/calculate")
        
        db_session.expire_all()
        # Fetch all params from DB
        params = (db_session.query(FormEvalParams, Tests.code, Tests.is_array)
            .join(Tests, FormEvalParams.test_id == Tests.id)
            .filter(FormEvalParams.eval_id == ev.id).all())
        
        # Build m_data and e_results
        m_data = {}
        e_results = {}
        processed_test_ids = set()
        
        for p in params:
            tid = p.FormEvalParams.test_id
            if tid in processed_test_ids: continue
            processed_test_ids.add(tid)
            
            code = p.code
            all_idx = (db_session.query(FormEvalParams)
                .filter(FormEvalParams.eval_id == ev.id, FormEvalParams.test_id == tid)
                .order_by(FormEvalParams.idx).all())
            
            vals = [float(x.value) if isinstance(x.value, Decimal) else x.value for x in all_idx]
            if p.is_array:
                if code in input_codes: m_data[code] = vals
                if code in calc_codes: e_results[code] = vals
            else:
                val = vals[0] if vals else None
                if code in input_codes: m_data[code] = val
                if code in calc_codes: e_results[code] = val
        
        # Sync: send back calculated values as expected results
        update_payload = {
            "description": ev.description,
            "measurementData": {k: (float(v) if isinstance(v, Decimal) else v) for k, v in m_data.items()},
            "expectedResults": {k: (float(v) if isinstance(v, Decimal) else v) for k, v in e_results.items()}
        }
        auth_session.put(f"{base_url}/api/form-evals/{ev.id}", json=update_payload)
        # Final calculation to ensure is_match=True
        auth_session.post(f"{base_url}/api/form-evals/{ev.id}/calculate")
    
    url = f"{base_url}/api/forms/{form_id}/validate"
    payload = {
        "userId": 1,
        "commentsValidated": "Validated in test",
        "commentsCancelled": None
    }
    
    response = auth_session.put(url, json=payload)
    if response.status_code != 200:
        # Debugging print
        print(f"\nFinal Validation Error: {response.text}")
        db_session.expire_all()
        debug_params = (db_session.query(FormEvalParams, Tests.code)
                       .join(Tests, FormEvalParams.test_id == Tests.id)
                       .filter(FormEvalParams.eval_id == 14).all())
        for dp in debug_params:
            print(f"DEBUG: {dp.code}[{dp.FormEvalParams.idx}] val={dp.FormEvalParams.value} exp={dp.FormEvalParams.expected_value} match={dp.FormEvalParams.is_match}")

    assert response.status_code == 200
    
    db_session.expire_all()
    form = db_session.query(Forms).filter(Forms.id == form_id).first()
    assert form.is_validated is True

def test_create_form_eval(migrated_db, auth_session, base_url, db_session):
    """
    Test POST /api/form-evals.
    """
    url = f"{base_url}/api/form-evals"
    payload = {"formId": 8, "description": "Test Case 2"}
    
    initial_count = db_session.query(FormEvals).count()
    response = auth_session.post(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    assert db_session.query(FormEvals).count() == initial_count + 1

def test_duplicate_form(migrated_db, auth_session, base_url, db_session):
    """
    Test POST /api/forms/{id}/duplicate.
    """
    form_id = 7
    url = f"{base_url}/api/forms/{form_id}/duplicate"
    payload = {"userId": 1, "commentsValidated": None, "commentsCancelled": None}
    
    response = auth_session.post(url, json=payload)
    assert response.status_code == 200
    new_id = response.json().get('id')
    
    db_session.expire_all()
    duplicated = db_session.query(Forms).filter(Forms.id == new_id).first()
    assert duplicated.is_validated is False
    assert duplicated.is_submitted is True 

def test_update_form_eval(migrated_db, auth_session, base_url, db_session):
    """
    Test PUT /api/form-evals/{id}.
    """
    eval_id = 14
    url = f"{base_url}/api/form-evals/{eval_id}"
    payload = {
        "description": "Test Case 1 Updated",
        "measurementData": {
            "test_h": 0, "test_k": 4, "tme": 2, "pga": 53.453, "pgc": 45.6456,
            "pgb": [63.4345, 65.456, 66.423], "pgd": [34.5345, 45.6456, 84.57],
            "pge": [2, 3, 1], "pgf": [0, 0, 0]
        },
        "expectedResults": {
            "test_g": 43.45, "test_j": [53.453, 67.546], "tlb": 0, "tlba": [1, 0, 1]
        }
    }
    
    response = auth_session.put(url, json=payload)
    assert response.status_code == 200
    
    db_session.expire_all()
    db_eval = db_session.query(FormEvals).filter(FormEvals.id == eval_id).first()
    assert db_eval.description == "Test Case 1 Updated"