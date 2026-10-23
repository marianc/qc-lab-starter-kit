# QC LIS Database Dictionary & Reference Manual

This document is automatically generated from the live PostgreSQL database schema and comments. It provides a comprehensive reference manual of all tables, columns, data types, and functional descriptions in the QC LIS (Laboratory Information Management System).

---

## Table of Contents

- [audit_logs](#table-audit-logs)
- [categories](#table-categories)
- [category_tests](#table-category-tests)
- [certificate_tests](#table-certificate-tests)
- [certificates](#table-certificates)
- [control_codes](#table-control-codes)
- [electronic_signatures](#table-electronic-signatures)
- [equipment_calibration_statuses](#table-equipment-calibration-statuses)
- [equipment_calibrations](#table-equipment-calibrations)
- [equipment_statuses](#table-equipment-statuses)
- [equipments](#table-equipments)
- [form_condition_evals](#table-form-condition-evals)
- [form_eval_params](#table-form-eval-params)
- [form_evals](#table-form-evals)
- [form_groups](#table-form-groups)
- [form_params](#table-form-params)
- [forms](#table-forms)
- [material_tests](#table-material-tests)
- [materials](#table-materials)
- [measurement_equipments](#table-measurement-equipments)
- [measurement_params](#table-measurement-params)
- [measurement_reagent_lots](#table-measurement-reagent-lots)
- [measurement_sop_versions](#table-measurement-sop-versions)
- [measurement_tests](#table-measurement-tests)
- [measurements](#table-measurements)
- [norms](#table-norms)
- [reagent_lot_statuses](#table-reagent-lot-statuses)
- [reagent_lots](#table-reagent-lots)
- [reagent_production_lots](#table-reagent-production-lots)
- [reagent_supplier_lot_cert_tests](#table-reagent-supplier-lot-cert-tests)
- [reagent_supplier_lots](#table-reagent-supplier-lots)
- [reagent_suppliers](#table-reagent-suppliers)
- [reception_tests](#table-reception-tests)
- [reception_types](#table-reception-types)
- [receptions](#table-receptions)
- [report_tests](#table-report-tests)
- [reports](#table-reports)
- [sop_versions](#table-sop-versions)
- [sops](#table-sops)
- [spec_test_evals](#table-spec-test-evals)
- [spec_tests](#table-spec-tests)
- [specs](#table-specs)
- [test_enums](#table-test-enums)
- [test_equipments](#table-test-equipments)
- [test_reagents](#table-test-reagents)
- [tests](#table-tests)
- [units](#table-units)
- [users](#table-users)
- [value_types](#table-value-types)

---

## Table: `audit_logs`
<a id="table-audit-logs"></a>

**Description:** Table audit_logs in QC LIS database.

**Primary Key:** `id`

**Foreign Keys:**
- `user_id` -> `users(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `table_name` | `character varying(100) NOT NULL` | Column table_name. |
| `record_keys` | `jsonb` | Column record_keys. |
| `action` | `character varying(10) NOT NULL` | Column action. |
| `old_data` | `jsonb` | Column old_data. |
| `new_data` | `jsonb` | Column new_data. |
| `changed_fields` | `ARRAY` | Column changed_fields. |
| `user_id` | `bigint NOT NULL` | Column user_id. |
| `reason_for_change` | `text` | Column reason_for_change. |
| `timestamp` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Column timestamp. |
| `client_ip` | `character varying(45)` | Column client_ip. |

---

## Table: `categories`
<a id="table-categories"></a>

**Description:** Table categories in QC LIS database.

**Primary Key:** `id`

**Unique Constraints:** `categories_code_key(code), categories_name_key(name)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `name` | `character varying(50) NOT NULL` | Column name. |
| `code` | `character varying(5) NOT NULL` | Column code. |
| `description` | `text` | Column description. |
| `date_created` | `timestamp with time zone NOT NULL` | Column date_created. |
| `is_obsolete` | `boolean NOT NULL DEFAULT false` | Column is_obsolete. |
| `date_obsolete` | `timestamp with time zone` | Column date_obsolete. |
| `comments_obsolete` | `text` | Column comments_obsolete. |

---

## Table: `category_tests`
<a id="table-category-tests"></a>

**Description:** Table category_tests in QC LIS database.

**Primary Key:** `category_id, test_id`

**Foreign Keys:**
- `category_id` -> `categories(id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `category_id` | `bigint NOT NULL` | Column category_id. |
| `test_id` | `bigint NOT NULL` | Column test_id. |

---

## Table: `certificate_tests`
<a id="table-certificate-tests"></a>

**Description:** Table certificate_tests in QC LIS database.

**Primary Key:** `certificate_id, report_id, test_id, idx, measurement_id`

**Foreign Keys:**
- `certificate_id` -> `certificates(id)`
- `measurement_id` -> `measurements(id)`
- `report_id` -> `reports(id)`
- `report_id` -> `report_tests(report_id)`
- `report_id` -> `report_tests(measurement_id)`
- `report_id` -> `report_tests(test_id)`
- `report_id` -> `report_tests(idx)`
- `measurement_id` -> `report_tests(report_id)`
- `measurement_id` -> `report_tests(measurement_id)`
- `measurement_id` -> `report_tests(test_id)`
- `measurement_id` -> `report_tests(idx)`
- `test_id` -> `report_tests(report_id)`
- `test_id` -> `report_tests(measurement_id)`
- `test_id` -> `report_tests(test_id)`
- `test_id` -> `report_tests(idx)`
- `idx` -> `report_tests(report_id)`
- `idx` -> `report_tests(measurement_id)`
- `idx` -> `report_tests(test_id)`
- `idx` -> `report_tests(idx)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `certificate_id` | `bigint NOT NULL` | Column certificate_id. |
| `report_id` | `bigint NOT NULL` | Column report_id. |
| `measurement_id` | `bigint NOT NULL` | Column measurement_id. |
| `test_id` | `bigint NOT NULL` | Column test_id. |
| `idx` | `integer NOT NULL DEFAULT 0` | Column idx. |
| `value` | `numeric NOT NULL` | Column value. |
| `uncertainty_value` | `numeric` | Column uncertainty_value. |
| `coverage_factor_k` | `numeric` | Column coverage_factor_k. |
| `is_conforming_spec` | `boolean NOT NULL DEFAULT false` | Column is_conforming_spec. |
| `is_conforming_uncertainty` | `boolean NOT NULL DEFAULT true` | Column is_conforming_uncertainty. |
| `note_spec` | `character varying(25) NOT NULL` | Column note_spec. |
| `test_count` | `integer NOT NULL DEFAULT 0` | Column test_count. |

---

## Table: `certificates`
<a id="table-certificates"></a>

**Description:** Table certificates in QC LIS database.

**Primary Key:** `id`

**Foreign Keys:**
- `certificate_replaced_id` -> `certificates(id)`
- `control_code_id` -> `control_codes(id)`
- `spec_id` -> `specs(id)`
- `user_cancelled_id` -> `users(id)`
- `user_submitted_id` -> `users(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `control_code_id` | `bigint NOT NULL` | Column control_code_id. |
| `spec_id` | `bigint NOT NULL` | Column spec_id. |
| `is_conforming_spec` | `boolean NOT NULL DEFAULT false` | Column is_conforming_spec. |
| `is_conforming_uncertainty` | `boolean NOT NULL DEFAULT true` | Column is_conforming_uncertainty. |
| `is_submitted` | `boolean NOT NULL DEFAULT false` | Column is_submitted. |
| `user_submitted_id` | `bigint` | Column user_submitted_id. |
| `date_submitted` | `timestamp with time zone` | Column date_submitted. |
| `comments_submitted` | `text` | Column comments_submitted. |
| `certificate_replaced_id` | `bigint` | Column certificate_replaced_id. |
| `is_cancelled` | `boolean NOT NULL DEFAULT false` | Column is_cancelled. |
| `user_cancelled_id` | `bigint` | Column user_cancelled_id. |
| `date_cancelled` | `timestamp with time zone` | Column date_cancelled. |
| `comments_cancelled` | `text` | Column comments_cancelled. |

---

## Table: `control_codes`
<a id="table-control-codes"></a>

**Description:** Table control_codes in QC LIS database.

**Primary Key:** `id`

**Unique Constraints:** `control_codes_material_id_code_key(material_id, code)`

**Foreign Keys:**
- `material_id` -> `materials(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `material_id` | `bigint NOT NULL` | Column material_id. |
| `code` | `character varying(50) NOT NULL` | Column code. |
| `is_reception_received` | `boolean NOT NULL DEFAULT false` | Column is_reception_received. |
| `date_created` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Column date_created. |

---

## Table: `electronic_signatures`
<a id="table-electronic-signatures"></a>

**Description:** Table electronic_signatures in QC LIS database.

**Primary Key:** `id`

**Foreign Keys:**
- `signer_user_id` -> `users(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `version` | `bigint NOT NULL DEFAULT 1` | Column version. |
| `entity_name` | `character varying(50) NOT NULL` | Column entity_name. |
| `entity_id` | `bigint NOT NULL` | Column entity_id. |
| `signer_user_id` | `bigint NOT NULL` | Column signer_user_id. |
| `signature_meaning` | `character varying(50) NOT NULL` | Column signature_meaning. |
| `signing_timestamp` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Column signing_timestamp. |
| `payload_sha256` | `character varying(64) NOT NULL` | Column payload_sha256. |
| `signature_manifest_text` | `text NOT NULL` | Column signature_manifest_text. |
| `client_ip` | `character varying(45) NOT NULL` | Column client_ip. |

---

## Table: `equipment_calibration_statuses`
<a id="table-equipment-calibration-statuses"></a>

**Description:** Table equipment_calibration_statuses in QC LIS database.

**Primary Key:** `id`

**Unique Constraints:** `equipment_calibration_statuses_name_key(name)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `name` | `character varying(50) NOT NULL` | Column name. |

---

## Table: `equipment_calibrations`
<a id="table-equipment-calibrations"></a>

**Description:** Table equipment_calibrations in QC LIS database.

**Primary Key:** `id`

**Foreign Keys:**
- `equipment_id` -> `equipments(id)`
- `status_id` -> `equipment_calibration_statuses(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `equipment_id` | `bigint NOT NULL` | Column equipment_id. |
| `calibration_date` | `date NOT NULL` | Column calibration_date. |
| `expiration_date` | `date NOT NULL` | Column expiration_date. |
| `certificate_number` | `character varying(100) NOT NULL` | Column certificate_number. |
| `calibrated_by` | `character varying(100) NOT NULL` | Column calibrated_by. |
| `status_id` | `bigint NOT NULL` | Column status_id. |
| `reference_standards_used` | `text` | Column reference_standards_used. |
| `expanded_uncertainty` | `numeric` | Column expanded_uncertainty. |
| `date_created` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Column date_created. |

---

## Table: `equipment_statuses`
<a id="table-equipment-statuses"></a>

**Description:** Table equipment_statuses in QC LIS database.

**Primary Key:** `id`

**Unique Constraints:** `equipment_statuses_name_key(name)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `name` | `character varying(50) NOT NULL` | Column name. |

---

## Table: `equipments`
<a id="table-equipments"></a>

**Description:** Table equipments in QC LIS database.

**Primary Key:** `id`

**Unique Constraints:** `equipment_equipment_code_key(equipment_code), equipments_serial_number_key(serial_number)`

**Foreign Keys:**
- `status_id` -> `equipment_statuses(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `equipment_code` | `character varying(50) NOT NULL` | Column equipment_code. |
| `name` | `character varying(100) NOT NULL` | Column name. |
| `manufacturer` | `character varying(100)` | Column manufacturer. |
| `model` | `character varying(100)` | Column model. |
| `serial_number` | `character varying(100) NOT NULL` | Column serial_number. |
| `location` | `character varying(100)` | Column location. |
| `status_id` | `bigint NOT NULL` | Column status_id. |
| `calibration_interval_days` | `integer DEFAULT 365` | Column calibration_interval_days. |
| `next_calibration_due` | `date` | Column next_calibration_due. |
| `date_created` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Column date_created. |

---

## Table: `form_condition_evals`
<a id="table-form-condition-evals"></a>

**Description:** Table form_condition_evals in QC LIS database.

**Primary Key:** `id`

**Foreign Keys:**
- `form_id` -> `forms(id)`
- `form_id` -> `form_params(form_id)`
- `form_id` -> `form_params(test_id)`
- `test_id` -> `form_params(form_id)`
- `test_id` -> `form_params(test_id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `form_id` | `bigint NOT NULL` | Column form_id. |
| `test_id` | `bigint NOT NULL` | Column test_id. |
| `value` | `numeric NOT NULL` | Column value. |
| `result` | `numeric` | Column result. |
| `expected_result` | `numeric NOT NULL` | Column expected_result. |
| `is_match` | `boolean NOT NULL DEFAULT false` | Column is_match. |
| `note` | `character varying(20)` | Column note. |

---

## Table: `form_eval_params`
<a id="table-form-eval-params"></a>

**Description:** Table form_eval_params in QC LIS database.

**Primary Key:** `eval_id, form_id, test_id, idx`

**Foreign Keys:**
- `eval_id` -> `form_evals(id)`
- `form_id` -> `forms(id)`
- `form_id` -> `form_params(form_id)`
- `form_id` -> `form_params(test_id)`
- `test_id` -> `form_params(form_id)`
- `test_id` -> `form_params(test_id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `eval_id` | `bigint NOT NULL` | Column eval_id. |
| `form_id` | `bigint NOT NULL` | Column form_id. |
| `test_id` | `bigint NOT NULL` | Column test_id. |
| `idx` | `integer NOT NULL` | Column idx. |
| `value` | `numeric` | Column value. |
| `expected_value` | `numeric` | Column expected_value. |
| `is_match` | `boolean NOT NULL DEFAULT false` | Column is_match. |

---

## Table: `form_evals`
<a id="table-form-evals"></a>

**Description:** Table form_evals in QC LIS database.

**Primary Key:** `id`

**Foreign Keys:**
- `form_id` -> `forms(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `form_id` | `bigint NOT NULL` | Column form_id. |
| `description` | `text` | Column description. |

---

## Table: `form_groups`
<a id="table-form-groups"></a>

**Description:** Table form_groups in QC LIS database.

**Primary Key:** `id`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `name` | `character varying(50) NOT NULL` | Column name. |
| `description` | `text` | Column description. |
| `is_form_validated` | `boolean NOT NULL DEFAULT false` | Column is_form_validated. |
| `nr_ord` | `bigint NOT NULL DEFAULT 0` | Column nr_ord. |

---

## Table: `form_params`
<a id="table-form-params"></a>

**Description:** Table form_params in QC LIS database.

**Primary Key:** `form_id, test_id`

**Foreign Keys:**
- `form_id` -> `forms(id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `form_id` | `bigint NOT NULL` | Column form_id. |
| `test_id` | `bigint NOT NULL` | Column test_id. |
| `is_calculated` | `boolean NOT NULL DEFAULT false` | Column is_calculated. |
| `formula` | `text` | Column formula. |
| `formula_dependencies` | `text` | Column formula_dependencies. |
| `code_related_arrays` | `character varying(50)` | Column code_related_arrays. |
| `has_condition` | `boolean NOT NULL DEFAULT false` | Column has_condition. |
| `condition` | `character varying(255)` | Column condition. |
| `condition_note` | `character varying(150)` | Column condition_note. |
| `is_required` | `boolean NOT NULL DEFAULT false` | Column is_required. |
| `default_value` | `numeric` | Column default_value. |
| `nr_ord_calc` | `bigint NOT NULL DEFAULT 0` | Column nr_ord_calc. |
| `nr_ord` | `bigint NOT NULL DEFAULT 0` | Column nr_ord. |

---

## Table: `forms`
<a id="table-forms"></a>

**Description:** Table forms in QC LIS database.

**Primary Key:** `id`

**Foreign Keys:**
- `form_group_id` -> `form_groups(id)`
- `user_cancelled_id` -> `users(id)`
- `user_submitted_id` -> `users(id)`
- `user_validated_id` -> `users(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `form_group_id` | `bigint NOT NULL` | Column form_group_id. |
| `version` | `character varying(50) NOT NULL` | Column version. |
| `days_active_for_editing` | `integer NOT NULL DEFAULT 10` | Column days_active_for_editing. |
| `is_customized` | `boolean NOT NULL DEFAULT false` | Column is_customized. |
| `custom_nav` | `text` | Column custom_nav. |
| `is_submitted` | `boolean NOT NULL DEFAULT false` | Column is_submitted. |
| `user_submitted_id` | `bigint` | Column user_submitted_id. |
| `date_submitted` | `timestamp with time zone` | Column date_submitted. |
| `comments_submitted` | `text` | Column comments_submitted. |
| `is_validated` | `boolean NOT NULL DEFAULT false` | Column is_validated. |
| `user_validated_id` | `bigint` | Column user_validated_id. |
| `date_validated` | `timestamp with time zone` | Column date_validated. |
| `comments_validated` | `text` | Column comments_validated. |
| `is_cancelled` | `boolean NOT NULL DEFAULT false` | Column is_cancelled. |
| `user_cancelled_id` | `bigint` | Column user_cancelled_id. |
| `date_cancelled` | `timestamp with time zone` | Column date_cancelled. |
| `comments_cancelled` | `text` | Column comments_cancelled. |

---

## Table: `material_tests`
<a id="table-material-tests"></a>

**Description:** Table material_tests in QC LIS database.

**Primary Key:** `material_id, test_id`

**Foreign Keys:**
- `material_id` -> `materials(id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `material_id` | `bigint NOT NULL` | Column material_id. |
| `test_id` | `bigint NOT NULL` | Column test_id. |

---

## Table: `materials`
<a id="table-materials"></a>

**Description:** Table materials in QC LIS database.

**Primary Key:** `id`

**Unique Constraints:** `materials_code_key(code), materials_name_key(name)`

**Foreign Keys:**
- `norm_id` -> `norms(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `name` | `character varying(50) NOT NULL` | Column name. |
| `code` | `character varying(10) NOT NULL` | Column code. |
| `description` | `text` | Column description. |
| `norm_id` | `bigint` | Column norm_id. |
| `is_product` | `boolean NOT NULL DEFAULT false` | Column is_product. |
| `is_raw_material` | `boolean NOT NULL DEFAULT false` | Column is_raw_material. |
| `is_reagent` | `boolean NOT NULL DEFAULT false` | Column is_reagent. |
| `is_certified_reference` | `boolean NOT NULL DEFAULT false` | Flags whether this material requires strict metrological traceability and certificate validation (CRM vs generic reagent). |
| `cas_number` | `character varying(20)` | Column cas_number. |
| `date_created` | `timestamp with time zone NOT NULL` | Column date_created. |
| `is_obsolete` | `boolean NOT NULL DEFAULT false` | Column is_obsolete. |
| `date_obsolete` | `timestamp with time zone` | Column date_obsolete. |
| `comments_obsolete` | `text` | Column comments_obsolete. |

---

## Table: `measurement_equipments`
<a id="table-measurement-equipments"></a>

**Description:** Table measurement_equipments in QC LIS database.

**Primary Key:** `measurement_id, equipment_id`

**Foreign Keys:**
- `equipment_id` -> `equipments(id)`
- `measurement_id` -> `measurements(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `measurement_id` | `bigint NOT NULL` | Column measurement_id. |
| `equipment_id` | `bigint NOT NULL` | Column equipment_id. |

---

## Table: `measurement_params`
<a id="table-measurement-params"></a>

**Description:** Table measurement_params in QC LIS database.

**Primary Key:** `measurement_id, form_id, test_id, idx`

**Foreign Keys:**
- `certified_reference_certificate_id` -> `certificates(id)`
- `certified_reference_control_code_id` -> `reagent_supplier_lots(control_code_id)`
- `form_id` -> `forms(id)`
- `form_id` -> `form_params(form_id)`
- `form_id` -> `form_params(test_id)`
- `test_id` -> `form_params(form_id)`
- `test_id` -> `form_params(test_id)`
- `measurement_id` -> `measurements(id)`
- `test_id` -> `tests(id)`
- `user_created_id` -> `users(id)`
- `user_updated_id` -> `users(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `measurement_id` | `bigint NOT NULL` | Column measurement_id. |
| `form_id` | `bigint NOT NULL` | Column form_id. |
| `test_id` | `bigint NOT NULL` | Column test_id. |
| `idx` | `integer NOT NULL DEFAULT 0` | Column idx. |
| `value` | `numeric NOT NULL` | Column value. |
| `is_conforming_condition` | `boolean NOT NULL DEFAULT false` | Column is_conforming_condition. |
| `certified_reference_certificate_id` | `bigint` | Foreign key pointing to the certified parameter value pulled from the active CRM inventory lot for tracking. |
| `certified_reference_control_code_id` | `bigint` | Foreign key pointing to the certified parameter value pulled from the active CRM inventory lot for tracking. |
| `user_updated_id` | `bigint` | Column user_updated_id. |
| `date_updated` | `timestamp with time zone` | Column date_updated. |
| `user_created_id` | `bigint NOT NULL` | Column user_created_id. |
| `date_created` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Column date_created. |

---

## Table: `measurement_reagent_lots`
<a id="table-measurement-reagent-lots"></a>

**Description:** Table measurement_reagent_lots in QC LIS database.

**Primary Key:** `measurement_id, control_code_id`

**Foreign Keys:**
- `control_code_id` -> `reagent_lots(control_code_id)`
- `measurement_id` -> `measurements(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `measurement_id` | `bigint NOT NULL` | Column measurement_id. |
| `control_code_id` | `bigint NOT NULL` | Column control_code_id. |

---

## Table: `measurement_sop_versions`
<a id="table-measurement-sop-versions"></a>

**Description:** Table measurement_sop_versions in QC LIS database.

**Primary Key:** `measurement_id, sop_version_id`

**Foreign Keys:**
- `measurement_id` -> `measurements(id)`
- `sop_version_id` -> `sop_versions(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `measurement_id` | `bigint NOT NULL` | Column measurement_id. |
| `sop_version_id` | `bigint NOT NULL` | Column sop_version_id. |

---

## Table: `measurement_tests`
<a id="table-measurement-tests"></a>

**Description:** Table measurement_tests in QC LIS database.

**Primary Key:** `measurement_id, test_id, idx`

**Foreign Keys:**
- `measurement_id` -> `measurements(id)`
- `test_id` -> `tests(id)`
- `user_created_id` -> `users(id)`
- `user_updated_id` -> `users(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `measurement_id` | `bigint NOT NULL` | Column measurement_id. |
| `test_id` | `bigint NOT NULL` | Column test_id. |
| `idx` | `integer NOT NULL DEFAULT 0` | Column idx. |
| `value` | `numeric NOT NULL` | Column value. |
| `note` | `character varying(20)` | Column note. |
| `user_updated_id` | `bigint` | Column user_updated_id. |
| `date_updated` | `timestamp with time zone` | Column date_updated. |
| `user_created_id` | `bigint NOT NULL` | Column user_created_id. |
| `date_created` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Column date_created. |

---

## Table: `measurements`
<a id="table-measurements"></a>

**Description:** Table measurements in QC LIS database.

**Primary Key:** `id`

**Foreign Keys:**
- `form_id` -> `forms(id)`
- `reception_id` -> `receptions(id)`
- `user_created_id` -> `users(id)`
- `user_reported_id` -> `users(id)`
- `user_updated_id` -> `users(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `reception_id` | `bigint NOT NULL` | Column reception_id. |
| `form_id` | `bigint` | Column form_id. |
| `comments` | `text` | Column comments. |
| `use_default_equipment` | `boolean NOT NULL DEFAULT true` | Column use_default_equipment. |
| `is_reported` | `boolean NOT NULL DEFAULT false` | Column is_reported. |
| `user_reported_id` | `bigint` | Column user_reported_id. |
| `date_reported` | `timestamp with time zone` | Column date_reported. |
| `is_readonly` | `boolean NOT NULL DEFAULT false` | Column is_readonly. |
| `date_readonly` | `timestamp with time zone` | Column date_readonly. |
| `user_updated_id` | `bigint` | Column user_updated_id. |
| `date_updated` | `timestamp with time zone` | Column date_updated. |
| `user_created_id` | `bigint NOT NULL` | Column user_created_id. |
| `date_created` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Column date_created. |

---

## Table: `norms`
<a id="table-norms"></a>

**Description:** Table norms in QC LIS database.

**Primary Key:** `id`

**Unique Constraints:** `norms_name_key(name)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `name` | `character varying(50) NOT NULL` | Column name. |
| `description` | `text` | Column description. |
| `date_created` | `timestamp with time zone NOT NULL` | Column date_created. |
| `is_obsolete` | `boolean NOT NULL DEFAULT false` | Column is_obsolete. |
| `date_obsolete` | `timestamp with time zone` | Column date_obsolete. |
| `comments_obsolete` | `text` | Column comments_obsolete. |

---

## Table: `reagent_lot_statuses`
<a id="table-reagent-lot-statuses"></a>

**Description:** Table reagent_lot_statuses in QC LIS database.

**Primary Key:** `id`

**Unique Constraints:** `reagent_lot_statuses_name_key(name)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `name` | `character varying(50) NOT NULL` | Column name. |

---

## Table: `reagent_lots`
<a id="table-reagent-lots"></a>

**Description:** Table reagent_lots in QC LIS database.

**Primary Key:** `control_code_id`

**Foreign Keys:**
- `control_code_id` -> `control_codes(id)`
- `produced_by_user_id` -> `users(id)`
- `status_id` -> `reagent_lot_statuses(id)`
- `unit_id` -> `units(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `control_code_id` | `bigint NOT NULL` | Column control_code_id. |
| `is_produced` | `boolean NOT NULL DEFAULT false` | Column is_produced. |
| `produced_by_user_id` | `bigint` | Column produced_by_user_id. |
| `status_id` | `bigint NOT NULL DEFAULT 1` | Column status_id. |
| `quantity` | `numeric NOT NULL` | Column quantity. |
| `unit_id` | `bigint` | Column unit_id. |
| `expiration_date` | `date NOT NULL` | Column expiration_date. |

---

## Table: `reagent_production_lots`
<a id="table-reagent-production-lots"></a>

**Description:** Table reagent_production_lots in QC LIS database.

**Primary Key:** `control_code_id, ingredient_control_code_id`

**Foreign Keys:**
- `control_code_id` -> `reagent_lots(control_code_id)`
- `ingredient_control_code_id` -> `reagent_lots(control_code_id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `control_code_id` | `bigint NOT NULL` | Column control_code_id. |
| `ingredient_control_code_id` | `bigint NOT NULL` | Column ingredient_control_code_id. |

---

## Table: `reagent_supplier_lot_cert_tests`
<a id="table-reagent-supplier-lot-cert-tests"></a>

**Description:** Table reagent_supplier_lot_cert_tests in QC LIS database.

**Primary Key:** `control_code_id`

**Foreign Keys:**
- `control_code_id` -> `reagent_supplier_lots(control_code_id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `control_code_id` | `bigint NOT NULL` | Column control_code_id. |
| `test_id` | `bigint NOT NULL` | Column test_id. |
| `value` | `numeric NOT NULL` | Column value. |
| `uncertainty_value` | `numeric` | Column uncertainty_value. |
| `coverage_factor_k` | `numeric` | Column coverage_factor_k. |
| `traceability_statement` | `text` | Column traceability_statement. |

---

## Table: `reagent_supplier_lots`
<a id="table-reagent-supplier-lots"></a>

**Description:** Table reagent_supplier_lots in QC LIS database.

**Primary Key:** `control_code_id`

**Foreign Keys:**
- `control_code_id` -> `reagent_lots(control_code_id)`
- `supplier_id` -> `reagent_suppliers(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `control_code_id` | `bigint NOT NULL` | Column control_code_id. |
| `supplier_id` | `bigint NOT NULL` | Column supplier_id. |
| `catalog_number` | `character varying(50)` | Column catalog_number. |
| `manufacturer_lot_number` | `character varying(50) NOT NULL` | Column manufacturer_lot_number. |
| `certificate_of_analysis_ref` | `character varying(255)` | Column certificate_of_analysis_ref. |
| `comments` | `character varying(255)` | Column comments. |
| `is_readonly` | `boolean NOT NULL DEFAULT false` | Column is_readonly. |
| `date_readonly` | `timestamp with time zone` | Column date_readonly. |

---

## Table: `reagent_suppliers`
<a id="table-reagent-suppliers"></a>

**Description:** Table reagent_suppliers in QC LIS database.

**Primary Key:** `id`

**Unique Constraints:** `reagent_suppliers_name_key(name)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `name` | `character varying(100) NOT NULL` | Column name. |

---

## Table: `reception_tests`
<a id="table-reception-tests"></a>

**Description:** Table reception_tests in QC LIS database.

**Primary Key:** `reception_id, test_id`

**Foreign Keys:**
- `reception_id` -> `receptions(id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `reception_id` | `bigint NOT NULL` | Column reception_id. |
| `test_id` | `bigint NOT NULL` | Column test_id. |

---

## Table: `reception_types`
<a id="table-reception-types"></a>

**Description:** Table reception_types in QC LIS database.

**Primary Key:** `id`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `name` | `character varying(50) NOT NULL` | Column name. |

---

## Table: `receptions`
<a id="table-receptions"></a>

**Description:** Table receptions in QC LIS database.

**Primary Key:** `id`

**Foreign Keys:**
- `category_id` -> `categories(id)`
- `control_code_id` -> `control_codes(id)`
- `type_id` -> `reception_types(id)`
- `user_received_id` -> `users(id)`
- `user_rejected_id` -> `users(id)`
- `user_submitted_id` -> `users(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `type_id` | `bigint NOT NULL` | Column type_id. |
| `control_code_id` | `bigint` | Column control_code_id. |
| `material_name` | `character varying(50)` | Column material_name. |
| `category_id` | `bigint` | Column category_id. |
| `is_submitted` | `boolean NOT NULL DEFAULT false` | Column is_submitted. |
| `user_submitted_id` | `bigint` | Column user_submitted_id. |
| `date_submitted` | `timestamp with time zone` | Column date_submitted. |
| `comments_submitted` | `text` | Column comments_submitted. |
| `is_received` | `boolean NOT NULL DEFAULT false` | Column is_received. |
| `user_received_id` | `bigint` | Column user_received_id. |
| `date_received` | `timestamp with time zone` | Column date_received. |
| `comments_received` | `text` | Column comments_received. |
| `is_rejected` | `boolean NOT NULL DEFAULT false` | Column is_rejected. |
| `user_rejected_id` | `bigint` | Column user_rejected_id. |
| `date_rejected` | `timestamp with time zone` | Column date_rejected. |
| `comments_rejected` | `text` | Column comments_rejected. |

---

## Table: `report_tests`
<a id="table-report-tests"></a>

**Description:** Table report_tests in QC LIS database.

**Primary Key:** `report_id, measurement_id, test_id, idx`

**Foreign Keys:**
- `measurement_id` -> `measurements(id)`
- `report_id` -> `reports(id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `report_id` | `bigint NOT NULL` | Column report_id. |
| `measurement_id` | `bigint NOT NULL` | Column measurement_id. |
| `test_id` | `bigint NOT NULL` | Column test_id. |
| `idx` | `integer NOT NULL DEFAULT 0` | Column idx. |
| `value` | `numeric NOT NULL` | Column value. |
| `uncertainty_value` | `numeric` | Column uncertainty_value. |
| `coverage_factor_k` | `numeric` | Column coverage_factor_k. |

---

## Table: `reports`
<a id="table-reports"></a>

**Description:** Table reports in QC LIS database.

**Primary Key:** `id`

**Foreign Keys:**
- `reception_id` -> `receptions(id)`
- `report_replaced_id` -> `reports(id)`
- `user_cancelled_id` -> `users(id)`
- `user_submitted_id` -> `users(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `reception_id` | `bigint NOT NULL` | Column reception_id. |
| `is_submitted` | `boolean NOT NULL DEFAULT false` | Column is_submitted. |
| `user_submitted_id` | `bigint` | Column user_submitted_id. |
| `date_submitted` | `timestamp with time zone` | Column date_submitted. |
| `comments_submitted` | `text` | Column comments_submitted. |
| `report_replaced_id` | `bigint` | Column report_replaced_id. |
| `is_cancelled` | `boolean NOT NULL DEFAULT false` | Column is_cancelled. |
| `user_cancelled_id` | `bigint` | Column user_cancelled_id. |
| `date_cancelled` | `timestamp with time zone` | Column date_cancelled. |
| `comments_cancelled` | `text` | Column comments_cancelled. |

---

## Table: `sop_versions`
<a id="table-sop-versions"></a>

**Description:** Table sop_versions in QC LIS database.

**Primary Key:** `id`

**Unique Constraints:** `unq_sop_version_number(sop_id, version_number)`

**Foreign Keys:**
- `sop_id` -> `sops(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `sop_id` | `bigint NOT NULL` | Column sop_id. |
| `version_number` | `character varying(20) NOT NULL` | Column version_number. |
| `external_edms_id` | `character varying(100)` | Column external_edms_id. |
| `comments` | `text` | Column comments. |
| `is_active` | `boolean NOT NULL DEFAULT true` | Column is_active. |
| `date_activated` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Column date_activated. |

---

## Table: `sops`
<a id="table-sops"></a>

**Description:** Table sops in QC LIS database.

**Primary Key:** `id`

**Unique Constraints:** `sops_doc_code_key(doc_code)`

**Foreign Keys:**
- `norm_id` -> `norms(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `doc_code` | `character varying(50) NOT NULL` | Column doc_code. |
| `title` | `character varying(150) NOT NULL` | Column title. |
| `norm_id` | `bigint` | Column norm_id. |
| `nr_ord` | `bigint NOT NULL DEFAULT 0` | Column nr_ord. |
| `date_created` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Column date_created. |

---

## Table: `spec_test_evals`
<a id="table-spec-test-evals"></a>

**Description:** Table spec_test_evals in QC LIS database.

**Primary Key:** `id`

**Foreign Keys:**
- `spec_id` -> `specs(id)`
- `spec_id` -> `spec_tests(spec_id)`
- `spec_id` -> `spec_tests(test_id)`
- `test_id` -> `spec_tests(spec_id)`
- `test_id` -> `spec_tests(test_id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `spec_id` | `bigint NOT NULL` | Column spec_id. |
| `test_id` | `bigint NOT NULL` | Column test_id. |
| `value` | `numeric NOT NULL` | Column value. |
| `result` | `numeric` | Column result. |
| `expected_result` | `numeric NOT NULL` | Column expected_result. |
| `is_match` | `boolean NOT NULL DEFAULT false` | Column is_match. |
| `note` | `character varying(20)` | Column note. |

---

## Table: `spec_tests`
<a id="table-spec-tests"></a>

**Description:** Table spec_tests in QC LIS database.

**Primary Key:** `spec_id, test_id`

**Foreign Keys:**
- `spec_id` -> `specs(id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `spec_id` | `bigint NOT NULL` | Column spec_id. |
| `test_id` | `bigint NOT NULL` | Column test_id. |
| `condition` | `character varying(255) NOT NULL` | Column condition. |
| `note` | `character varying(150) NOT NULL` | Column note. |
| `use_uncertainty` | `boolean NOT NULL DEFAULT false` | Column use_uncertainty. |
| `test_frequency` | `integer NOT NULL` | Column test_frequency. |

---

## Table: `specs`
<a id="table-specs"></a>

**Description:** Table specs in QC LIS database.

**Primary Key:** `id`

**Foreign Keys:**
- `material_id` -> `materials(id)`
- `spec_replaced_id` -> `specs(id)`
- `user_cancelled_id` -> `users(id)`
- `user_submitted_id` -> `users(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `material_id` | `bigint NOT NULL` | Column material_id. |
| `is_submitted` | `boolean NOT NULL DEFAULT false` | Column is_submitted. |
| `user_submitted_id` | `bigint` | Column user_submitted_id. |
| `date_submitted` | `timestamp with time zone` | Column date_submitted. |
| `comments_submitted` | `text` | Column comments_submitted. |
| `spec_replaced_id` | `bigint` | Column spec_replaced_id. |
| `is_cancelled` | `boolean NOT NULL DEFAULT false` | Column is_cancelled. |
| `user_cancelled_id` | `bigint` | Column user_cancelled_id. |
| `date_cancelled` | `timestamp with time zone` | Column date_cancelled. |
| `comments_cancelled` | `text` | Column comments_cancelled. |

---

## Table: `test_enums`
<a id="table-test-enums"></a>

**Description:** Table test_enums in QC LIS database.

**Primary Key:** `test_id, value`

**Unique Constraints:** `test_enums_test_id_name_key(test_id, name)`

**Foreign Keys:**
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `test_id` | `bigint NOT NULL` | Column test_id. |
| `value` | `bigint NOT NULL` | Column value. |
| `name` | `character varying(50) NOT NULL` | Column name. |
| `nr_ord` | `bigint NOT NULL DEFAULT 0` | Column nr_ord. |
| `is_obsolete` | `boolean NOT NULL DEFAULT false` | Column is_obsolete. |

---

## Table: `test_equipments`
<a id="table-test-equipments"></a>

**Description:** Table test_equipments in QC LIS database.

**Primary Key:** `test_id, equipment_id`

**Foreign Keys:**
- `equipment_id` -> `equipments(id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `test_id` | `bigint NOT NULL` | Column test_id. |
| `equipment_id` | `bigint NOT NULL` | Column equipment_id. |

---

## Table: `test_reagents`
<a id="table-test-reagents"></a>

**Description:** Table test_reagents in QC LIS database.

**Primary Key:** `test_id, material_id`

**Foreign Keys:**
- `material_id` -> `materials(id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `test_id` | `bigint NOT NULL` | Column test_id. |
| `material_id` | `bigint NOT NULL` | Column material_id. |

---

## Table: `tests`
<a id="table-tests"></a>

**Description:** Table tests in QC LIS database.

**Primary Key:** `id`

**Unique Constraints:** `tests_code_key(code)`

**Foreign Keys:**
- `norm_id` -> `norms(id)`
- `sop_id` -> `sops(id)`
- `unit_id` -> `units(id)`
- `type_id` -> `value_types(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `name` | `character varying(50) NOT NULL` | Column name. |
| `code` | `character varying(50) NOT NULL` | Column code. |
| `description` | `text` | Column description. |
| `type_id` | `bigint NOT NULL` | Column type_id. |
| `is_array` | `boolean NOT NULL DEFAULT false` | Column is_array. |
| `is_param` | `boolean NOT NULL DEFAULT false` | Column is_param. |
| `for_environmental_control` | `boolean NOT NULL DEFAULT false` | Column for_environmental_control. |
| `for_certification` | `boolean NOT NULL DEFAULT false` | Column for_certification. |
| `relative_uncertainty_pct` | `numeric` | Column relative_uncertainty_pct. |
| `default_coverage_factor_k` | `numeric` | Column default_coverage_factor_k. |
| `for_certified_reference` | `boolean NOT NULL DEFAULT false` | Enforces that data entered into this template field during validation must map to an active CRM parameter row. |
| `unit_id` | `bigint` | Column unit_id. |
| `norm_id` | `bigint` | Column norm_id. |
| `norm_ref` | `character varying(50)` | Column norm_ref. |
| `sop_id` | `bigint` | Column sop_id. |
| `is_form_validated` | `boolean NOT NULL DEFAULT false` | Column is_form_validated. |
| `date_form_validated` | `timestamp with time zone` | Column date_form_validated. |
| `nr_ord` | `bigint NOT NULL DEFAULT 0` | Column nr_ord. |
| `date_created` | `timestamp with time zone NOT NULL` | Column date_created. |
| `is_obsolete` | `boolean NOT NULL DEFAULT false` | Column is_obsolete. |
| `date_obsolete` | `timestamp with time zone` | Column date_obsolete. |
| `comments_obsolete` | `text` | Column comments_obsolete. |

---

## Table: `units`
<a id="table-units"></a>

**Description:** Table units in QC LIS database.

**Primary Key:** `id`

**Unique Constraints:** `units_name_key(name)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `name` | `character varying(50) NOT NULL` | Column name. |
| `description` | `text` | Column description. |
| `date_created` | `timestamp with time zone NOT NULL` | Column date_created. |

---

## Table: `users`
<a id="table-users"></a>

**Description:** Table users in QC LIS database.

**Primary Key:** `id`

**Unique Constraints:** `users_code_key(code), users_email_key(email), users_session_id_key(session_id), users_tag_key(tag)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `tag` | `character varying(12) NOT NULL` | Column tag. |
| `code` | `character varying(3) NOT NULL` | Column code. |
| `email` | `character varying(50) NOT NULL` | Column email. |
| `first_name` | `character varying(50)` | Column first_name. |
| `last_name` | `character varying(50)` | Column last_name. |
| `is_admin` | `boolean NOT NULL DEFAULT false` | Column is_admin. |
| `is_lab_pers` | `boolean NOT NULL DEFAULT false` | Column is_lab_pers. |
| `is_qc_pers` | `boolean NOT NULL DEFAULT false` | Column is_qc_pers. |
| `password_hash` | `text` | Column password_hash. |
| `password_salt` | `text` | Column password_salt. |
| `must_change_password` | `boolean NOT NULL DEFAULT false` | Column must_change_password. |
| `date_password_changed` | `timestamp with time zone` | Column date_password_changed. |
| `failed_login_attempts` | `integer NOT NULL DEFAULT 0` | Column failed_login_attempts. |
| `is_locked` | `boolean NOT NULL DEFAULT false` | Column is_locked. |
| `lock_expiration` | `timestamp with time zone` | Column lock_expiration. |
| `session_id` | `character varying(255)` | Column session_id. |
| `date_session_created` | `timestamp with time zone` | Column date_session_created. |
| `date_session_expire` | `timestamp with time zone` | Column date_session_expire. |
| `refresh_token` | `character varying` | Column refresh_token. |
| `date_created` | `timestamp with time zone NOT NULL` | Column date_created. |
| `is_obsolete` | `boolean NOT NULL DEFAULT false` | Column is_obsolete. |
| `date_obsolete` | `timestamp with time zone` | Column date_obsolete. |
| `comments_obsolete` | `text` | Column comments_obsolete. |

---

## Table: `value_types`
<a id="table-value-types"></a>

**Description:** Table value_types in QC LIS database.

**Primary Key:** `id`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Column id. |
| `name` | `character varying(50) NOT NULL` | Column name. |

---
