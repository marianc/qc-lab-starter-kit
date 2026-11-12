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

**Description:** GxP and 21 CFR Part 11 compliant audit trail log table. Automatically populated via the PostgreSQL trigger function 'process_audit_log()' whenever INSERT, UPDATE, or DELETE operations occur on critical quality tables (certificates, certificate_tests, forms, form_params, measurements, measurement_params, measurement_tests, reports, report_tests, specs, spec_tests). Application user context and justification are injected into PostgreSQL session variables ('app.current_user_id' and 'app.reason_for_change') by the server DbCommandInterceptor 'AuditSessionDbCommandInterceptor'.

**Primary Key:** `id`

**Foreign Keys:**
- `user_id` -> `users(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique synthetic 64-bit integer identifier for each audit trail entry. |
| `table_name` | `character varying(100) NOT NULL` | Name of the database table where the DML modification took place (e.g., 'measurements', 'forms', 'specs'). Populated automatically by the trigger via TG_TABLE_NAME. |
| `record_keys` | `jsonb` | JSONB object capturing the primary key column names and values of the audited record (e.g., {"id": 105} or composite keys like {"form_id": 2, "test_id": 14, "idx": 0}). Enables exact historical row tracking. |
| `action` | `character varying(10) NOT NULL` | DML operation type performed on the record: 'INSERT', 'UPDATE', or 'DELETE'. Populated via TG_OP in the audit trigger. |
| `old_data` | `jsonb` | JSONB snapshot of the entire table row before the change occurred. Set to NULL for INSERT actions; contains pre-modification state for UPDATE and DELETE actions. |
| `new_data` | `jsonb` | JSONB snapshot of the entire table row after the change occurred. Set to NULL for DELETE actions; contains post-modification state for INSERT and UPDATE actions. |
| `changed_fields` | `ARRAY` | PostgreSQL text array (TEXT[]) listing the column names whose values were modified during an UPDATE operation. Allows rapid filtering and visual highlighting of specific edited fields in the audit viewer (AuditLogsTable.tsx). |
| `user_id` | `bigint NOT NULL` | Foreign key referencing public.users(id). Identifies the laboratory analyst or QC supervisor who executed the transaction. Sourced from the transaction session variable 'app.current_user_id' set by AuditSessionDbCommandInterceptor. |
| `reason_for_change` | `text` | Mandatory user-supplied justification for the modification. Captured in the UI via modal dialogs (e.g. CommentDialog) and transferred into PostgreSQL via the session variable 'app.reason_for_change' to ensure compliance with 21 CFR Part 11 requirements. |
| `timestamp` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Timestamp with time zone indicating the exact database transaction time when the audit entry was written. Defaults to clock_timestamp() to capture accurate wall-clock execution time. |
| `client_ip` | `character varying(45)` | Network IP address (IPv4 or IPv6, up to 45 characters) of the client machine that initiated the API request. Captured by ASP.NET Core HttpContextAccessor and recorded for forensic cybersecurity and compliance traceability. |

---

## Table: `categories`
<a id="table-categories"></a>

**Description:** Master classification table grouping materials and products into logical families (e.g., 'Finished Products', 'Active Pharmaceutical Ingredients', 'Excipients', 'Solvents'). Used for organizing catalog items and driving ad-hoc Category Verification sample receptions.

**Primary Key:** `id`

**Unique Constraints:** `categories_code_key(code), categories_name_key(name)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the category. |
| `name` | `character varying(50) NOT NULL` | Unique name of the material category (3 to 50 characters). Validated for uniqueness on blur in CategoryDialog.tsx. |
| `code` | `character varying(5) NOT NULL` | Unique 2 to 5 character uppercase alphanumeric classification code (regex /^[A-Z][A-Z0-9]*$/). Validated for uniqueness on the client and server. |
| `description` | `text` | Optional extended description of the category scope and materials covered. |
| `date_created` | `timestamp with time zone NOT NULL` | Timestamp with time zone when the category was established. |
| `is_obsolete` | `boolean NOT NULL DEFAULT false` | Soft-deletion flag. When true, prevents the category from being selected in new material definitions or category verification receptions while preserving historical records. |
| `date_obsolete` | `timestamp with time zone` | Timestamp with time zone when the category was retired. Cleared to NULL if reactivated. |
| `comments_obsolete` | `text` | Documented reason recorded when retiring the category. Cleared to NULL if reactivated. |

---

## Table: `category_tests`
<a id="table-category-tests"></a>

**Description:** Many-to-many junction table associating laboratory test definitions with material categories. Defines the standard battery of tests applicable to an entire category. When creating a Category Verification sample reception (CategoryVerificationDialog.tsx), selecting a category dynamically pre-populates the list of available tests from this table.

**Primary Key:** `category_id, test_id`

**Foreign Keys:**
- `category_id` -> `categories(id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `category_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.categories(id). The material category receiving the test assignment. |
| `test_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.tests(id). The analytical test assigned to the category. |

---

## Table: `certificate_tests`
<a id="table-certificate-tests"></a>

**Description:** Line-item analytical test evaluations displayed on the Quality Certificate / Certificate of Analysis (COA). Contains evaluated test results, expanded uncertainty values, individual specification compliance flags (is_conforming_spec), guard-band compliance flags (is_conforming_uncertainty), and snapshots of specification limits (note_spec).

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
| `certificate_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.certificates(id). The parent quality certificate. |
| `report_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.reports(id). The source test report providing the data. |
| `measurement_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.measurements(id). The raw measurement session. |
| `test_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.tests(id). The analytical test evaluated. |
| `idx` | `integer NOT NULL DEFAULT 0` | Primary key. Determination index (0 for scalar, 0..N for replicated arrays). |
| `value` | `numeric NOT NULL` | Certified analytical test result value. |
| `uncertainty_value` | `numeric` | Expanded measurement uncertainty U associated with the certified result. |
| `coverage_factor_k` | `numeric` | Coverage factor k (typically 2.0) applied to the uncertainty estimate. |
| `is_conforming_spec` | `boolean NOT NULL DEFAULT false` | Boolean flag. Evaluated by executing the specification condition formula (spec_tests.condition) against the measured value. True if value meets specification limits; false otherwise. |
| `is_conforming_uncertainty` | `boolean NOT NULL DEFAULT true` | Boolean flag. Evaluated by checking whether both [value - uncertainty_value] AND [value + uncertainty_value] satisfy the specification condition formula. Enforces ILAC-G8 guard-banding rules for ISO/IEC 17025 accredited reporting. |
| `note_spec` | `character varying(25) NOT NULL` | Historical snapshot text of the specification acceptance criteria in effect at the time of certification (maximum 25 characters, e.g., '>= 98.0%', 'Clear liquid'). Preserves exact historical limits regardless of future spec revisions. |
| `test_count` | `integer NOT NULL DEFAULT 0` | Integer count of determinations or replicates performed to establish this result (defaults to 0). |

---

## Table: `certificates`
<a id="table-certificates"></a>

**Description:** Official Quality Certificates / Certificates of Analysis (COA) issued for a manufactured batch or raw material lot (control_code_id). Evaluates laboratory test results against the active specification (spec_id). Computes both direct specification conformance and uncertainty guard-band conformance (ISO/IEC 17025 / ILAC-G8). Enforces 21 CFR Part 11 digital signatures on approval.

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
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the quality certificate. |
| `control_code_id` | `bigint NOT NULL` | Foreign key referencing public.control_codes(id). The batch or inventory lot covered by this certificate. |
| `spec_id` | `bigint NOT NULL` | Foreign key referencing public.specs(id). The active specification used to evaluate batch conformance. |
| `is_conforming_spec` | `boolean NOT NULL DEFAULT false` | Boolean conformance flag. True indicates that ALL required tests meet specification limits and no mandatory specification tests are missing. Calculated automatically by CertificatesService.CalculateAndSaveCertificateTests. |
| `is_conforming_uncertainty` | `boolean NOT NULL DEFAULT true` | Boolean guard-band conformance flag implementing ISO/IEC 17025 / ILAC-G8 decision rules. True indicates that both the lower bound [value - U] and upper bound [value + U] fall within the specification acceptance range for all tests. |
| `is_submitted` | `boolean NOT NULL DEFAULT false` | Boolean status flag. True indicates the Quality Certificate has been formally approved and released with a 21 CFR Part 11 electronic signature. |
| `user_submitted_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The authorized QC manager / Qualified Person who signed and released the certificate. |
| `date_submitted` | `timestamp with time zone` | Timestamp with time zone when the certificate was signed and released. |
| `comments_submitted` | `text` | Quality assurance release disposition notes, authorized deviations, or release comments. |
| `certificate_replaced_id` | `bigint` | Foreign key referencing public.certificates(id) (nullable). Points to the previous certificate revision that this document supersedes. |
| `is_cancelled` | `boolean NOT NULL DEFAULT false` | Boolean status flag. True indicates the certificate was officially revoked or cancelled. |
| `user_cancelled_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The user who revoked the certificate. |
| `date_cancelled` | `timestamp with time zone` | Timestamp with time zone when the certificate was cancelled. |
| `comments_cancelled` | `text` | Mandatory documented justification explaining why the quality certificate was revoked. |

---

## Table: `control_codes`
<a id="table-control-codes"></a>

**Description:** Central batch/lot identification and inventory tracking table. Every physical batch of manufactured product, raw material delivery, purchased reagent lot, or in-house prepared reagent is assigned a unique control code linked to its material. Serves as the primary traceability anchor across sample receptions, testing worksheets, quality certificates, and reagent genealogy.

**Primary Key:** `id`

**Unique Constraints:** `control_codes_material_id_code_key(material_id, code)`

**Foreign Keys:**
- `material_id` -> `materials(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the control code record. |
| `material_id` | `bigint NOT NULL` | Foreign key referencing public.materials(id). The specific material, chemical, or product to which this batch/lot belongs. |
| `code` | `character varying(50) NOT NULL` | Alphanumeric batch/control code string (up to 50 characters). Unique per material. Must contain no whitespace (enforced by regex /^\S*$/). In sample reception dialogs (CertificationDialog, VerificationDialog), users can select an existing control code or enter a new one, which is verified for uniqueness against the selected material via UniquenessChecker. |
| `is_reception_received` | `boolean NOT NULL DEFAULT false` | Boolean status flag. Automatically updated from false to true when any sample reception referencing this control code is accepted into the laboratory (ReceptionsService.ReceiveReception). Signals that physical samples of this batch have been received in the lab. |
| `date_created` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Timestamp with time zone when the control code was generated. Defaults to clock_timestamp(). |

---

## Table: `electronic_signatures`
<a id="table-electronic-signatures"></a>

**Description:** Cryptographic electronic signature ledger enforcing 21 CFR Part 11 and EU GMP Annex 11 compliance. Stores legally binding digital signatures executed when laboratory personnel submit, validate, approve, or cancel critical quality documents (forms, specifications, test reports, quality certificates). Includes SHA-256 payload digests and human-readable signature manifests.

**Primary Key:** `id`

**Foreign Keys:**
- `signer_user_id` -> `users(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the electronic signature record. |
| `version` | `bigint NOT NULL DEFAULT 1` | Monotonically increasing sequence number (defaults to 1) indicating the revision of the signature on a given entity record (e.g., Version 1 for initial submission, Version 2 for revision/approval, Version 3 for cancellation). |
| `entity_name` | `character varying(50) NOT NULL` | Name of the audited domain entity/table to which the signature applies (e.g., 'forms', 'specs', 'reports', 'certificates'). |
| `entity_id` | `bigint NOT NULL` | Primary key identifier of the specific domain record being digitally signed (e.g., forms.id, specs.id, certificates.id). |
| `signer_user_id` | `bigint NOT NULL` | Foreign key referencing public.users(id). The authenticated user who entered their credentials and executed the signature. |
| `signature_meaning` | `character varying(50) NOT NULL` | Legally defined statement of intent / meaning of the signature (e.g., 'Submission', 'Validation', 'Approval', 'Cancellation'). Specifies the signer's regulatory responsibility pursuant to 21 CFR § 11.50. |
| `signing_timestamp` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Cryptographic timestamp with time zone at the exact instant the signature was sealed. Defaults to clock_timestamp(). |
| `payload_sha256` | `character varying(64) NOT NULL` | Hex-encoded 64-character SHA-256 cryptographic hash of the canonical JSON representation of the entity state at the moment of signing. Guarantees tamper-evidence and data integrity: any post-signature tampering invalidates the hash verification. |
| `signature_manifest_text` | `text NOT NULL` | Human-readable text manifest summarizing the signed record details, signer full name, user tag, signature meaning, and timestamp. Rendered in the client UI via SignatureManifestBlock.tsx for inspection during audits. |
| `client_ip` | `character varying(45) NOT NULL` | Network IPv4/IPv6 client IP address from which the signature action was executed. |

---

## Table: `equipment_calibration_statuses`
<a id="table-equipment-calibration-statuses"></a>

**Description:** Lookup catalog for metrological calibration outcomes: 1 = 'Pass' (metrology results conform fully to manufacturer tolerances and uncertainty limits), 2 = 'Fail' (out-of-tolerance calibration requiring instrument repair or retirement), 3 = 'Limited Use' (calibrated with restricted operational range or derated accuracy limits).

**Primary Key:** `id`

**Unique Constraints:** `equipment_calibration_statuses_name_key(name)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique identifier for the calibration outcome status. |
| `name` | `character varying(50) NOT NULL` | Unique name of the calibration status ('Pass', 'Fail', 'Limited Use'). |

---

## Table: `equipment_calibrations`
<a id="table-equipment-calibrations"></a>

**Description:** Historical calibration log and certificate registry for laboratory instruments. Adding or updating a calibration certificate in EquipmentCalibrationDialog.tsx automatically propagates the expiration_date to equipments.next_calibration_due and restores the instrument status to 'Active'.

**Primary Key:** `id`

**Foreign Keys:**
- `equipment_id` -> `equipments(id)`
- `status_id` -> `equipment_calibration_statuses(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the calibration event. |
| `equipment_id` | `bigint NOT NULL` | Foreign key referencing public.equipments(id). The laboratory instrument subjected to calibration. |
| `calibration_date` | `date NOT NULL` | Date when the physical calibration procedure was performed. |
| `expiration_date` | `date NOT NULL` | Date when this calibration certificate expires. Automatically updates equipments.next_calibration_due. |
| `certificate_number` | `character varying(100) NOT NULL` | Unique external or internal calibration certificate tracking number (maximum 100 characters, e.g., 'CAL-2026-09871'). |
| `calibrated_by` | `character varying(100) NOT NULL` | Name of the accredited metrology calibration service provider or internal calibration technician (maximum 100 characters). |
| `status_id` | `bigint NOT NULL` | Foreign key referencing public.equipment_calibration_statuses(id) (1='Pass', 2='Fail', 3='Limited Use'). |
| `reference_standards_used` | `text` | Text details of traceable reference standards (e.g., NIST-traceable weights, calibrated quartz cuvettes) utilized during the calibration. |
| `expanded_uncertainty` | `numeric` | Expanded measurement uncertainty of the calibration method itself (NUMERIC), as stated on the calibration certificate. |
| `date_created` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Timestamp with time zone when the calibration record was logged into the system. Defaults to clock_timestamp(). |

---

## Table: `equipment_statuses`
<a id="table-equipment-statuses"></a>

**Description:** Lookup catalog for operational status of analytical laboratory instruments: 1 = 'Active' (calibrated, qualified, and authorized for routine testing), 2 = 'Inactive' (standby or temporarily decommissioned), 3 = 'Calibration Due' (calibration overdue, locked from testing), 4 = 'Out of Service' (defective, undergoing repair, or failed calibration).

**Primary Key:** `id`

**Unique Constraints:** `equipment_statuses_name_key(name)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique identifier for the equipment operational status. |
| `name` | `character varying(50) NOT NULL` | Unique status name ('Active', 'Inactive', 'Calibration Due', 'Out of Service'). |

---

## Table: `equipments`
<a id="table-equipments"></a>

**Description:** Master inventory register of laboratory instruments, analytical balances, chromatography systems, and spectrophotometers. Tracks physical location, serial numbers, calibration schedules, and operational readiness under ISO/IEC 17025 and 21 CFR Part 211.

**Primary Key:** `id`

**Unique Constraints:** `equipment_equipment_code_key(equipment_code), equipments_serial_number_key(serial_number)`

**Foreign Keys:**
- `status_id` -> `equipment_statuses(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the equipment asset. |
| `equipment_code` | `character varying(50) NOT NULL` | Unique laboratory internal asset tag or barcode (2 to 20 characters, e.g., 'BAL-001', 'HPLC-UV-03'). Used on sample worksheets and equipment selection dialogs. |
| `name` | `character varying(100) NOT NULL` | Descriptive equipment title (2 to 100 characters, e.g., 'Analytical Balance XP205', 'UV-Vis Spectrophotometer Evolution 300'). |
| `manufacturer` | `character varying(100)` | Name of the equipment manufacturer or OEM (maximum 100 characters, e.g., 'Mettler Toledo', 'Waters', 'Agilent'). |
| `model` | `character varying(100)` | Manufacturer model number or instrument family (maximum 100 characters, e.g., 'Alliance e2695', 'XS204'). |
| `serial_number` | `character varying(100) NOT NULL` | Unique manufacturer serial number (maximum 100 characters). Enforces instrument hardware identity. |
| `location` | `character varying(100)` | Laboratory room, bench, or cleanroom zone where the instrument is installed (maximum 100 characters, e.g., 'QC Phys-Chem Room 204'). |
| `status_id` | `bigint NOT NULL` | Foreign key referencing public.equipment_statuses(id). Operational state of the instrument. Automatically set to 'Active' when a successful calibration is recorded in EquipmentsService.AddEquipmentCalibration. |
| `calibration_interval_days` | `integer DEFAULT 365` | Number of days between required periodic recalibrations (integer, defaults to 365 days / 1 year). |
| `next_calibration_due` | `date` | Calendar date when the instrument must next undergo calibration. Automatically updated from the expiration_date of the most recently recorded calibration certificate. |
| `date_created` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Timestamp with time zone when the equipment asset was registered in the database. Defaults to clock_timestamp(). |

---

## Table: `form_condition_evals`
<a id="table-form-condition-evals"></a>

**Description:** Benchmark test cases verifying parameter condition logic (form_params.condition). Validates that conditional acceptance rules correctly yield 1 (pass) or 0 (fail) against known test input values.

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
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the condition evaluation test row. |
| `form_id` | `bigint NOT NULL` | Foreign key referencing public.forms(id). The parent form template. |
| `test_id` | `bigint NOT NULL` | Foreign key referencing public.tests(id). The parameter whose condition is being verified. |
| `value` | `numeric NOT NULL` | Test input value passed into the condition expression. |
| `result` | `numeric` | Actual boolean outcome evaluated by the rule engine (1 for true/conforming, 0 for false/non-conforming). |
| `expected_result` | `numeric NOT NULL` | Expected outcome (1 for pass, 0 for fail) specified by the form author. |
| `is_match` | `boolean NOT NULL DEFAULT false` | Boolean flag. True indicates result matches expected_result. |
| `note` | `character varying(20)` | Short explanation of the test condition boundary (maximum 20 characters, e.g., 'Upper limit', 'Nominal pass'). |

---

## Table: `form_eval_params`
<a id="table-form-eval-params"></a>

**Description:** Input variables and expected calculated outputs for form validation test cases (form_evals). During form verification, the QCFormula engine calculates the actual results for all formulas and compares them against expected_value. If all match, is_match is stamped true.

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
| `eval_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.form_evals(id). The parent validation test case. |
| `form_id` | `bigint NOT NULL` | Foreign key referencing public.forms(id). The form template. |
| `test_id` | `bigint NOT NULL` | Foreign key referencing public.tests(id). The parameter under test. |
| `idx` | `integer NOT NULL` | Primary key. Array determination index (0 for scalar parameters, 0..N for replicated array values). |
| `value` | `numeric` | Input test value (for manual parameters) or engine-calculated result (for formula parameters). |
| `expected_value` | `numeric` | Authoritative pre-calculated benchmark value. Used to verify formula accuracy. |
| `is_match` | `boolean NOT NULL DEFAULT false` | Boolean verification flag. True indicates the calculated formula result matches expected_value within tolerance. |

---

## Table: `form_evals`
<a id="table-form-evals"></a>

**Description:** Validation benchmark test cases designed to prove the algorithmic accuracy of form formulas under 21 CFR Part 11 software verification rules. Before a form template can be validated (is_validated = true), all defined test cases must evaluate successfully without errors.

**Primary Key:** `id`

**Foreign Keys:**
- `form_id` -> `forms(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the validation test case. |
| `form_id` | `bigint NOT NULL` | Foreign key referencing public.forms(id). The form template being verified. |
| `description` | `text` | Descriptive title or test scenario name (e.g., 'Nominal standard weight test case', 'Boundary condition - maximum LOD'). |

---

## Table: `form_groups`
<a id="table-form-groups"></a>

**Description:** Logical family or category of dynamic analytical worksheet forms (e.g., 'Dissolution Testing Forms', 'Heavy Metals Assay Forms', 'Loss on Drying Forms'). Controls overarching validation status across form versions.

**Primary Key:** `id`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the form group. |
| `name` | `character varying(50) NOT NULL` | Unique name of the form family (3 to 50 characters). Validated for uniqueness via FormGroupDialog.tsx. |
| `description` | `text` | Optional extended description of the testing domain and analytical methodologies handled by this form group. |
| `is_form_validated` | `boolean NOT NULL DEFAULT false` | Boolean status flag. Automatically updated to true when any form version within this group achieves validation approval (FormsService.ValidateForm). Signals that test definitions associated with this group are locked from structurally breaking changes. |
| `nr_ord` | `bigint NOT NULL DEFAULT 0` | Numeric display order index (defaults to 0) controlling grouping sequence in client menus. |

---

## Table: `form_params`
<a id="table-form-params"></a>

**Description:** Parameter definitions within a form template. Maps analytical tests (tests) into form fields as raw inputs or calculated formulas. Defines mathematical expressions evaluated by QCFormula, topological evaluation order (nr_ord_calc), array relationships, and conditional pass/fail criteria.

**Primary Key:** `form_id, test_id`

**Foreign Keys:**
- `form_id` -> `forms(id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `form_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.forms(id). The parent form template. |
| `test_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.tests(id). The analytical test or parameter mapped to this form field. |
| `is_calculated` | `boolean NOT NULL DEFAULT false` | Boolean flag indicating whether this parameter is derived via a mathematical formula (true) or entered as a manual raw measurement (false). |
| `formula` | `text` | Mathematical expression evaluated by the QCFormula ANTLR engine (e.g., 'ROUND(([tare_plus_sample] - [tare_dry]) / [sample_mass] * 100, 4)'). References scalar parameters as [code] and array parameters as [[code]]. Mandatory if is_calculated is true. |
| `formula_dependencies` | `text` | Extracted list of test variable codes upon which this formula depends. Populated automatically by the QCFormula dependency resolver. |
| `code_related_arrays` | `character varying(50)` | Test code string (maximum 50 characters) identifying an associated array test if this calculation parameter aggregates or relates to array determinations. |
| `has_condition` | `boolean NOT NULL DEFAULT false` | Boolean flag indicating that this parameter possesses an acceptance rule / condition. In FormParamDialog.tsx, when true, condition and condition_note are mandatory, and at least one condition evaluation verification test case is required. |
| `condition` | `character varying(255)` | Boolean condition expression (maximum 255 characters, e.g., '[value] >= 95.0 && [value] <= 105.0'). Validated via FormsService.ValidateCondition. |
| `condition_note` | `character varying(150)` | Human-readable specification note or warning text displayed if the condition is not met (maximum 150 characters, e.g., 'Between 95.0% and 105.0%'). |
| `is_required` | `boolean NOT NULL DEFAULT false` | Boolean flag specifying whether a value for this parameter is strictly required before the worksheet can be completed. |
| `default_value` | `numeric` | Default preset numeric value (e.g., 1.000 for standard volume, or 0). |
| `nr_ord_calc` | `bigint NOT NULL DEFAULT 0` | Topological calculation sequence order. Derived automatically by resolving the Directed Acyclic Graph (DAG) of formula dependencies. Formulas are evaluated strictly in ascending order of nr_ord_calc to guarantee all dependent inputs are calculated prior to consumption. |
| `nr_ord` | `bigint NOT NULL DEFAULT 0` | Visual display sequence order controlling the arrangement of parameter input rows in the user interface. |

---

## Table: `forms`
<a id="table-forms"></a>

**Description:** Version-controlled dynamic analytical worksheet templates. Encapsulates formula calculation graphs, topological evaluation orders, conditional rules, and software validation datasets. Enforces GxP lifecycle state progression: Draft -> Submitted -> Validated -> Cancelled, accompanied by 21 CFR Part 11 electronic signatures.

**Primary Key:** `id`

**Foreign Keys:**
- `form_group_id` -> `form_groups(id)`
- `user_cancelled_id` -> `users(id)`
- `user_submitted_id` -> `users(id)`
- `user_validated_id` -> `users(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the form template. |
| `form_group_id` | `bigint NOT NULL` | Foreign key referencing public.form_groups(id). The parent group / test family to which this form template belongs. |
| `version` | `character varying(50) NOT NULL` | Version number string (maximum 50 characters, e.g., '1.0', '2.1'). Unique per form group. |
| `days_active_for_editing` | `integer NOT NULL DEFAULT 10` | Grace period in days (integer, defaults to 10) during which a worksheet instance generated from this form remains editable. Once this elapsed time expires following creation, the worksheet automatically becomes locked (is_readonly = true). |
| `is_customized` | `boolean NOT NULL DEFAULT false` | Boolean flag indicating that this form relies on a dedicated, specialized frontend UI component rather than standard auto-rendered grid layout. In FormDialog.tsx, when checked, custom_nav is mandatory. |
| `custom_nav` | `text` | Frontend component route or navigation tag (e.g., 'TestingFormA') defining the custom layout renderer. Mandatory if is_customized is true; nullable if standard generic rendering is used. |
| `is_submitted` | `boolean NOT NULL DEFAULT false` | Boolean lifecycle flag. True indicates the form template has been finalized and submitted for formal verification. |
| `user_submitted_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The form author who submitted the template. |
| `date_submitted` | `timestamp with time zone` | Timestamp with time zone when the form was submitted. |
| `comments_submitted` | `text` | Author notes, design rationale, or change summary recorded at submission. |
| `is_validated` | `boolean NOT NULL DEFAULT false` | Boolean approval flag. When true, the form is validated for routine production testing. Validation requires that all verification test cases (form_evals) PASS. Approving a form creates an electronic signature, marks form_groups.is_form_validated = true, and locks tests.is_form_validated = true for all referenced tests. |
| `user_validated_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The QC supervisor / system owner who validated and approved the form. |
| `date_validated` | `timestamp with time zone` | Timestamp with time zone when validation approval was granted. |
| `comments_validated` | `text` | Formal validation approval remarks recorded by the QC reviewer. |
| `is_cancelled` | `boolean NOT NULL DEFAULT false` | Boolean lifecycle flag. True indicates the form template was cancelled or superseded. Cancelled forms cannot be selected for new sample receptions or measurements. |
| `user_cancelled_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The user who cancelled the form template. |
| `date_cancelled` | `timestamp with time zone` | Timestamp with time zone when the form was cancelled. |
| `comments_cancelled` | `text` | Mandatory documented justification explaining why the form was cancelled. |

---

## Table: `material_tests`
<a id="table-material-tests"></a>

**Description:** Many-to-many junction table associating candidate analytical tests with a material. Represents the universe of tests that can be configured on specifications or performed on samples of this material. Restricted to non-parameter tests (is_param = false).

**Primary Key:** `material_id, test_id`

**Foreign Keys:**
- `material_id` -> `materials(id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `material_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.materials(id). The material to which the test is assigned. |
| `test_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.tests(id). The analytical test eligible to be performed on the material. |

---

## Table: `materials`
<a id="table-materials"></a>

**Description:** Master item catalog covering manufactured finished products, raw materials, intermediates, chemical reagents, and certified reference materials (CRMs). Dictates whether an item undergoes standard QC release testing, is tracked as a reagent in lab inventory, or requires strict metrological traceability.

**Primary Key:** `id`

**Unique Constraints:** `materials_code_key(code), materials_name_key(name)`

**Foreign Keys:**
- `norm_id` -> `norms(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the material. |
| `name` | `character varying(50) NOT NULL` | Unique descriptive name of the material (3 to 50 characters, e.g., 'Aspirin Active Substance', 'Ethanol 96%', 'Potassium Dichromate CRM'). Validated for uniqueness on the server and client. |
| `code` | `character varying(10) NOT NULL` | Unique uppercase alphanumeric material code (2 to 10 characters, regex /^[A-Z][A-Z0-9]*$/). Used for inventory identification and batch code generation. |
| `description` | `text` | Optional text notes detailing chemical grade, storage conditions, or physical specifications. |
| `norm_id` | `bigint` | Foreign key referencing public.norms(id) (nullable). Identifies the primary pharmacopeial monograph or compendial standard governing this material. |
| `is_product` | `boolean NOT NULL DEFAULT false` | Boolean flag designating the item as a manufactured finished product eligible for production release and customer Certificate of Analysis generation. |
| `is_raw_material` | `boolean NOT NULL DEFAULT false` | Boolean flag designating the item as an incoming raw material, active substance, or excipient requiring intake QC verification. |
| `is_reagent` | `boolean NOT NULL DEFAULT false` | Boolean flag designating the item as a laboratory chemical reagent or volumetric solution. Reagents are filtered out in general views unless the user possesses lab or QC roles (is_lab_pers or is_qc_pers). Managed via ReagentsPage.tsx and reagent_lots. |
| `is_certified_reference` | `boolean NOT NULL DEFAULT false` | Boolean flag indicating that this material is a Certified Reference Material (CRM) requiring strict metrological traceability and certificate of analysis validation under ISO 17034 / ISO/IEC 17025. |
| `cas_number` | `character varying(20)` | Chemical Abstracts Service (CAS) registry number (maximum 20 characters, e.g., '50-78-2' for Acetylsalicylic acid). Used primarily for chemical identification and reagent safety. |
| `date_created` | `timestamp with time zone NOT NULL` | Timestamp with time zone when the material was registered in the database. |
| `is_obsolete` | `boolean NOT NULL DEFAULT false` | Soft-deletion flag. Set via MaterialsService.ToggleObsolete. When true, prevents initiating new sample receptions or specifications. Setting to true stamps date_obsolete with UTC timestamp and stores comments_obsolete; reactivating clears both fields to NULL. |
| `date_obsolete` | `timestamp with time zone` | Timestamp with time zone when the material was retired. Cleared to NULL if reactivated. |
| `comments_obsolete` | `text` | Mandatory documented justification explaining why the material was marked obsolete. Cleared to NULL if reactivated. |

---

## Table: `measurement_equipments`
<a id="table-measurement-equipments"></a>

**Description:** Many-to-many junction table logging the specific laboratory instruments and balances (equipments) utilized during a measurement worksheet session. Guarantees complete hardware traceability for ISO/IEC 17025 audits.

**Primary Key:** `measurement_id, equipment_id`

**Foreign Keys:**
- `equipment_id` -> `equipments(id)`
- `measurement_id` -> `measurements(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `measurement_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.measurements(id). The testing worksheet session. |
| `equipment_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.equipments(id). The instrument utilized during the test. |

---

## Table: `measurement_params`
<a id="table-measurement-params"></a>

**Description:** Intermediate calculation variables and raw parameter inputs captured during dynamic form worksheet execution. Maintains parameter-level acceptance status (is_conforming_condition) and metrological links to Certified Reference Materials (CRMs).

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
| `measurement_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.measurements(id). The parent worksheet session. |
| `form_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.forms(id). The active form template. |
| `test_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.tests(id). The specific parameter test definition. |
| `idx` | `integer NOT NULL DEFAULT 0` | Primary key. Array determination index (0 for scalar parameters, 0..N for array inputs). |
| `value` | `numeric NOT NULL` | Input raw measurement value or formula-calculated intermediate result. |
| `is_conforming_condition` | `boolean NOT NULL DEFAULT false` | Boolean status flag. True indicates the parameter satisfies the conditional acceptance rule defined in form_params.condition. |
| `certified_reference_certificate_id` | `bigint` | Foreign key referencing public.certificates(id) (nullable). Populated when this parameter value is calibrated against or sourced from an internal Quality Certificate for a certified reference batch via SelectCrmDialog.tsx. |
| `certified_reference_control_code_id` | `bigint` | Foreign key referencing public.control_codes(id) (nullable). Populated when this parameter value is sourced from a supplier CRM reagent lot Certificate of Analysis (reagent_supplier_lot_cert_tests) via SelectCrmDialog.tsx. |
| `user_updated_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The user who last edited this parameter value. |
| `date_updated` | `timestamp with time zone` | Timestamp with time zone of the most recent parameter edit. |
| `user_created_id` | `bigint NOT NULL` | Foreign key referencing public.users(id). The user who originally recorded the parameter. |
| `date_created` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Timestamp with time zone when the parameter was created. Defaults to clock_timestamp(). |

---

## Table: `measurement_reagent_lots`
<a id="table-measurement-reagent-lots"></a>

**Description:** Many-to-many junction table recording the chemical reagent lots and volumetric solutions (control_codes) consumed during a measurement worksheet session. Guarantees chemical consumable traceability.

**Primary Key:** `measurement_id, control_code_id`

**Foreign Keys:**
- `control_code_id` -> `reagent_lots(control_code_id)`
- `measurement_id` -> `measurements(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `measurement_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.measurements(id). The testing worksheet session. |
| `control_code_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.control_codes(id). The specific reagent lot consumed during testing. |

---

## Table: `measurement_sop_versions`
<a id="table-measurement-sop-versions"></a>

**Description:** Many-to-many junction table capturing the exact revisions of Standard Operating Procedures (sop_versions) followed by the analyst during execution of a measurement worksheet. Ensures procedural compliance traceability.

**Primary Key:** `measurement_id, sop_version_id`

**Foreign Keys:**
- `measurement_id` -> `measurements(id)`
- `sop_version_id` -> `sop_versions(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `measurement_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.measurements(id). The testing worksheet session. |
| `sop_version_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.sop_versions(id). The active SOP revision utilized for the test execution. |

---

## Table: `measurement_tests`
<a id="table-measurement-tests"></a>

**Description:** Final measured test results recorded during a worksheet session. Supports both scalar results (idx = 0) and multi-replicate array results (idx = 0..N). Serves as the raw data source for testing reports (report_tests) and quality certificates (certificate_tests).

**Primary Key:** `measurement_id, test_id, idx`

**Foreign Keys:**
- `measurement_id` -> `measurements(id)`
- `test_id` -> `tests(id)`
- `user_created_id` -> `users(id)`
- `user_updated_id` -> `users(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `measurement_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.measurements(id). The parent worksheet execution session. |
| `test_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.tests(id). The analytical test whose result was determined. |
| `idx` | `integer NOT NULL DEFAULT 0` | Primary key. Numeric replicate index (0 for scalar tests, 0..N for replicated array determinations). |
| `value` | `numeric NOT NULL` | The measured numerical result (or encoded enum key from test_enums). Captured via MeasurementTestDialog.tsx or auto-calculated from form parameters. |
| `note` | `character varying(20)` | Short analyst footnote or qualitative observation (maximum 20 characters, e.g., 'Re-injected', 'Outlier rejected'). |
| `user_updated_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The user who last updated this test value. |
| `date_updated` | `timestamp with time zone` | Timestamp with time zone when this test value was last updated. |
| `user_created_id` | `bigint NOT NULL` | Foreign key referencing public.users(id). The analyst who recorded the initial measurement. |
| `date_created` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Timestamp with time zone when the measurement was originally logged. Defaults to clock_timestamp(). |

---

## Table: `measurements`
<a id="table-measurements"></a>

**Description:** Laboratory testing worksheet execution sessions. Records raw observations, formula evaluations, and test results for a sample reception. Captures exact instrument serial numbers, chemical reagent lots, and SOP revisions used during execution. Enforces automatic read-only locking upon report inclusion or expiration of form editing days.

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
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the measurement worksheet session. |
| `reception_id` | `bigint NOT NULL` | Foreign key referencing public.receptions(id). The sample reception being analyzed. |
| `form_id` | `bigint` | Foreign key referencing public.forms(id) (nullable). The structured dynamic form template used for executing calculations, if applicable. |
| `comments` | `text` | Analyst bench notes, environmental conditions, or procedural observations recorded during worksheet execution. |
| `use_default_equipment` | `boolean NOT NULL DEFAULT true` | Boolean flag (defaults to true). When true, the worksheet utilizes the standard instruments defined in test_equipments; when false, analyst custom-selects specific instrument assets stored in measurement_equipments. |
| `is_reported` | `boolean NOT NULL DEFAULT false` | Boolean status flag. True indicates that the test results from this worksheet have been included into a formal submitted test report (reports). Prevents subsequent tampering with raw data. |
| `user_reported_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The user who incorporated this measurement session into a test report. |
| `date_reported` | `timestamp with time zone` | Timestamp with time zone when the results were reported. |
| `is_readonly` | `boolean NOT NULL DEFAULT false` | Boolean lock flag (defaults to false). Automatically set to true when results are reported or after forms.days_active_for_editing has elapsed. Locks all child measurement_tests and measurement_params from modification. |
| `date_readonly` | `timestamp with time zone` | Timestamp with time zone when the worksheet was transitioned to read-only status. |
| `user_updated_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The user who performed the most recent edit. |
| `date_updated` | `timestamp with time zone` | Timestamp with time zone of the most recent worksheet modification. |
| `user_created_id` | `bigint NOT NULL` | Foreign key referencing public.users(id). The laboratory analyst who initiated the measurement worksheet. |
| `date_created` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Timestamp with time zone when the worksheet session was created. Defaults to clock_timestamp(). |

---

## Table: `norms`
<a id="table-norms"></a>

**Description:** Compendial standards, pharmacopeias, or regulatory references (e.g., 'USP 43', 'Ph. Eur. 10', 'ISO/IEC 17025', 'ASTM D1298', 'Internal QC Standard'). Provides governing normative authority for test methods, specifications, and standard operating procedures (SOPs).

**Primary Key:** `id`

**Unique Constraints:** `norms_name_key(name)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the norm record. |
| `name` | `character varying(50) NOT NULL` | Unique title or designation of the governing standard (3 to 50 characters). Validated for uniqueness in NormDialog.tsx. |
| `description` | `text` | Detailed description of the standard, governing body, publication edition, or scope. |
| `date_created` | `timestamp with time zone NOT NULL` | Timestamp with time zone when the norm was registered. |
| `is_obsolete` | `boolean NOT NULL DEFAULT false` | Soft-deletion flag. When true, prevents associating this norm with new materials, tests, or SOPs. |
| `date_obsolete` | `timestamp with time zone` | Timestamp with time zone when the norm was marked obsolete. Cleared to NULL if reactivated. |
| `comments_obsolete` | `text` | Documented justification explaining why the norm is no longer valid or applicable. Cleared to NULL if reactivated. |

---

## Table: `reagent_lot_statuses`
<a id="table-reagent-lot-statuses"></a>

**Description:** Lifecycle status lookup table for physical laboratory reagent lots: 1 = 'Quarantined' (pending incoming inspection or CoA verification), 2 = 'Active' (approved for use in testing and production), 3 = 'Expired' (past manufacturer expiration date, locked from usage), 4 = 'Depleted' (inventory exhausted). Only lots in 'Active' status can be consumed in measurement worksheets or used as ingredients in lab preparations.

**Primary Key:** `id`

**Unique Constraints:** `reagent_lot_statuses_name_key(name)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Numeric identifier corresponding to the reagent lot status. |
| `name` | `character varying(50) NOT NULL` | Unique name of the lot status ('Quarantined', 'Active', 'Expired', 'Depleted'). |

---

## Table: `reagent_lots`
<a id="table-reagent-lots"></a>

**Description:** Core inventory table tracking physical containers and batches of chemical reagents, volumetric solutions, and standards in the laboratory. Each lot is identified by a control_code_id. Differentiates purchased vendor lots from in-house prepared solutions (is_produced). Enforces expiration date controls and stock balances.

**Primary Key:** `control_code_id`

**Foreign Keys:**
- `control_code_id` -> `control_codes(id)`
- `produced_by_user_id` -> `users(id)`
- `status_id` -> `reagent_lot_statuses(id)`
- `unit_id` -> `units(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `control_code_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.control_codes(id). Serves as the unique tracking lot identifier for this physical batch. |
| `is_produced` | `boolean NOT NULL DEFAULT false` | Boolean flag distinguishing in-house prepared reagents (true) from commercially purchased supplier lots (false). When true, produced_by_user_id and ingredient relationships in reagent_production_lots are enabled. |
| `produced_by_user_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The laboratory analyst who formulated or prepared the reagent solution. Populated only when is_produced is true. |
| `status_id` | `bigint NOT NULL DEFAULT 1` | Foreign key referencing public.reagent_lot_statuses(id) (defaults to 1 = 'Quarantined'). Only lots in status 2 ('Active') can be selected as worksheet consumables or production ingredients. |
| `quantity` | `numeric NOT NULL` | Numeric stock quantity remaining in inventory (e.g., 500.0). Enforced to be non-negative on the client and server. |
| `unit_id` | `bigint` | Foreign key referencing public.units(id) (nullable). Specifies the unit of measurement for stock inventory (e.g., 'mL', 'g', 'L'). |
| `expiration_date` | `date NOT NULL` | Calendar date when the reagent lot expires. The system blocks using expired lots in analytical testing. |

---

## Table: `reagent_production_lots`
<a id="table-reagent-production-lots"></a>

**Description:** Genealogy / Bill of Materials (BOM) junction table tracking internal laboratory reagent preparation. Associates an in-house produced reagent lot with the parent ingredient reagent lots consumed in its preparation. In ProductionLotDialog.tsx, circular dependencies (selecting the lot itself as an ingredient) are strictly prevented, and only active lots (status_id = 2) are eligible for selection.

**Primary Key:** `control_code_id, ingredient_control_code_id`

**Foreign Keys:**
- `control_code_id` -> `reagent_lots(control_code_id)`
- `ingredient_control_code_id` -> `reagent_lots(control_code_id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `control_code_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.control_codes(id). Identifies the newly prepared/produced child reagent lot. |
| `ingredient_control_code_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.control_codes(id). Identifies an active parent reagent lot consumed as an ingredient. |

---

## Table: `reagent_supplier_lot_cert_tests`
<a id="table-reagent-supplier-lot-cert-tests"></a>

**Description:** Certified reference parameter values transcribed from manufacturer Certificates of Analysis (CoA) for Certified Reference Materials (CRMs). Enables strict metrological traceability under ISO 17034 and ISO/IEC 17025. When executing a worksheet with CRM-dependent parameters (tests.for_certified_reference = true), the analyst selects active values from this table via SelectCrmDialog.tsx.

**Primary Key:** `control_code_id`

**Foreign Keys:**
- `control_code_id` -> `reagent_supplier_lots(control_code_id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `control_code_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.control_codes(id). Identifies the supplier CRM reagent lot. |
| `test_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.tests(id). The analytical property or analyte certified on the supplier CoA. |
| `value` | `numeric NOT NULL` | Certified reference numerical value stated on the manufacturer CoA (e.g., 99.98% purity, 0.1002 N titer). |
| `uncertainty_value` | `numeric` | Stated expanded measurement uncertainty U from the manufacturer certificate (e.g., 0.05). |
| `coverage_factor_k` | `numeric` | Coverage factor k stated on the certificate (typically 2.0 for approx. 95% confidence interval). |
| `traceability_statement` | `text` | Formal metrological traceability text transcribed from the CoA (maximum 500 characters, e.g., 'Traceable to NIST SRM 84k'). |

---

## Table: `reagent_supplier_lots`
<a id="table-reagent-supplier-lots"></a>

**Description:** Specialization table for commercially purchased reagent lots (reagent_lots where is_produced = false). Maintains manufacturer traceability, vendor catalog numbers, manufacturer batch numbers, and Certificate of Analysis (CoA) references. Locked into read-only mode once utilized in certified worksheets.

**Primary Key:** `control_code_id`

**Foreign Keys:**
- `control_code_id` -> `reagent_lots(control_code_id)`
- `supplier_id` -> `reagent_suppliers(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `control_code_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.control_codes(id) (and implicitly public.reagent_lots). Unique lot identifier. |
| `supplier_id` | `bigint NOT NULL` | Foreign key referencing public.reagent_suppliers(id). Identifies the vendor or manufacturer who supplied the batch. In SupplierLotDialog.tsx, user can either select an existing supplier or input a new one, which creates a new supplier record. |
| `catalog_number` | `character varying(50)` | Vendor catalog or product article number (maximum 50 characters, e.g., '1.00014.1000'). |
| `manufacturer_lot_number` | `character varying(50) NOT NULL` | Original manufacturer production lot number printed on the container label (maximum 50 characters). |
| `certificate_of_analysis_ref` | `character varying(255)` | Reference identifier, document number, or URL to the manufacturer's Certificate of Analysis (maximum 255 characters). |
| `comments` | `character varying(255)` | Optional comments, container condition, or receiving notes (maximum 255 characters). |
| `is_readonly` | `boolean NOT NULL DEFAULT false` | Boolean lock flag (defaults to false). Automatically set to true when the lot is consumed in approved/submitted testing worksheets or quality certificates to guarantee immutable historical records. |
| `date_readonly` | `timestamp with time zone` | Timestamp with time zone when the record was locked against modifications. |

---

## Table: `reagent_suppliers`
<a id="table-reagent-suppliers"></a>

**Description:** Catalog of external commercial vendors, manufacturers, and distributors of laboratory reagents, solvents, standards, and chemicals (e.g., 'Merck', 'Sigma-Aldrich', 'Fisher Scientific', 'VWR'). Can be selected from an existing list or created on-the-fly during supplier lot entry in SupplierLotDialog.tsx.

**Primary Key:** `id`

**Unique Constraints:** `reagent_suppliers_name_key(name)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the reagent supplier. |
| `name` | `character varying(100) NOT NULL` | Unique name of the supplier company (up to 50 characters). Validated for uniqueness via ReagentsService.ValidateSupplierUniqueness. |

---

## Table: `reception_tests`
<a id="table-reception-tests"></a>

**Description:** Many-to-many junction table recording the analytical tests assigned to a specific sample reception. For Certification receptions, populated automatically with all active tests from the material's submitted specification; for Verification receptions, populated from user selection in VerificationDialog.tsx; for Category Verification, populated from category_tests in CategoryVerificationDialog.tsx.

**Primary Key:** `reception_id, test_id`

**Foreign Keys:**
- `reception_id` -> `receptions(id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `reception_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.receptions(id). The sample reception receiving the test assignments. |
| `test_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.tests(id). The analytical test scheduled to be performed on the sample. |

---

## Table: `reception_types`
<a id="table-reception-types"></a>

**Description:** Lookup table defining the standard workflows for sample intake and laboratory login: 1 = 'Certification' (full release testing against active material specification), 2 = 'Verification' (custom test subset on an established material), 3 = 'Category Verification' (ad-hoc testing of unlisted or experimental samples classified by category).

**Primary Key:** `id`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Numeric identifier of the reception type. |
| `name` | `character varying(50) NOT NULL` | Unique workflow title ('Certification', 'Verification', 'Category Verification'). Determines client dialog layout (CertificationDialog, VerificationDialog, or CategoryVerificationDialog) and backend test population logic. |

---

## Table: `receptions`
<a id="table-receptions"></a>

**Description:** Laboratory sample intake, login, and chain-of-custody tracking table. Captures sample submission, laboratory physical receipt, or rejection. Drives subsequent measurement worksheet creation, testing report issuance, and certificate generation.

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
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the sample reception event. |
| `type_id` | `bigint NOT NULL` | Foreign key referencing public.reception_types(id). Specifies whether this reception represents Certification (1), Verification (2), or Category Verification (3). |
| `control_code_id` | `bigint` | Foreign key referencing public.control_codes(id) (nullable). Identifies the physical batch/lot being sampled. Mandatory for Certification and Verification receptions; NULL for Category Verification receptions. |
| `material_name` | `character varying(50)` | Free-text description of the sampled material (maximum 50 characters). Used exclusively for Category Verification receptions (type_id = 3) where the sample does not correspond to a formally registered catalog item in public.materials. |
| `category_id` | `bigint` | Foreign key referencing public.categories(id) (nullable). Classifies the sample under an established category for Category Verification receptions (type_id = 3). NULL for standard Certification and Verification receptions. |
| `is_submitted` | `boolean NOT NULL DEFAULT false` | Boolean status flag. True indicates the sample reception request has been formally submitted by sampling/production personnel. |
| `user_submitted_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The user who submitted the sample reception. |
| `date_submitted` | `timestamp with time zone` | Timestamp with time zone when the sample reception was formally submitted. |
| `comments_submitted` | `text` | Optional comments, delivery instructions, or sampling conditions noted by the submitter. |
| `is_received` | `boolean NOT NULL DEFAULT false` | Boolean status flag. True indicates the laboratory has physically accepted the sample into custody. Setting this to true automatically marks control_codes.is_reception_received = true (ReceptionsService.ReceiveReception). |
| `user_received_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The laboratory analyst who checked in and accepted the physical sample. |
| `date_received` | `timestamp with time zone` | Timestamp with time zone when the laboratory physically received the sample. |
| `comments_received` | `text` | Laboratory intake notes regarding sample integrity, packaging, seals, or temperature upon arrival. |
| `is_rejected` | `boolean NOT NULL DEFAULT false` | Boolean status flag. True indicates the laboratory rejected the sample intake (e.g. broken seal, insufficient volume, incorrect storage temperature). A rejected reception cannot be received and requires a mandatory reason. |
| `user_rejected_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The laboratory user who executed the sample rejection. |
| `date_rejected` | `timestamp with time zone` | Timestamp with time zone when the sample was rejected. |
| `comments_rejected` | `text` | Mandatory documented justification explaining why the sample was rejected by the laboratory. |

---

## Table: `report_tests`
<a id="table-report-tests"></a>

**Description:** Analytical test results included in a formal testing report. Encapsulates measured values alongside calculated expanded measurement uncertainties (U) and coverage factors (k) in compliance with ISO/IEC 17025.

**Primary Key:** `report_id, measurement_id, test_id, idx`

**Foreign Keys:**
- `measurement_id` -> `measurements(id)`
- `report_id` -> `reports(id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `report_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.reports(id). The parent testing report. |
| `measurement_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.measurements(id). The source worksheet from which the measurement was obtained. |
| `test_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.tests(id). The analytical test evaluated. |
| `idx` | `integer NOT NULL DEFAULT 0` | Primary key. Determination replicate index (0 for scalar tests, 0..N for replicated arrays). |
| `value` | `numeric NOT NULL` | Reported test value (numerical measurement or enum key). |
| `uncertainty_value` | `numeric` | Calculated expanded measurement uncertainty U = (value * relative_uncertainty_pct / 100), as established in test definitions. Defines the boundary of the measurement result at approximately 95% confidence. |
| `coverage_factor_k` | `numeric` | Coverage factor k (typically 2.0) applied during uncertainty calculation. |

---

## Table: `reports`
<a id="table-reports"></a>

**Description:** Formal analytical Testing Reports compiling completed laboratory measurements for a sample reception. Serves as the laboratory's technical release document before final quality certification. Governed by formal submission, revision/replacement, and cancellation lifecycles with electronic signatures.

**Primary Key:** `id`

**Foreign Keys:**
- `reception_id` -> `receptions(id)`
- `report_replaced_id` -> `reports(id)`
- `user_cancelled_id` -> `users(id)`
- `user_submitted_id` -> `users(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the testing report. |
| `reception_id` | `bigint NOT NULL` | Foreign key referencing public.receptions(id). The sample reception for which this test report is generated. |
| `is_submitted` | `boolean NOT NULL DEFAULT false` | Boolean status flag. True indicates the test report has been formally signed and submitted by authorized lab personnel. Submitting a report automatically transitions underlying measurements to read-only status. |
| `user_submitted_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The laboratory user who submitted the test report. |
| `date_submitted` | `timestamp with time zone` | Timestamp with time zone when the test report was submitted. |
| `comments_submitted` | `text` | Technical comments, summary of findings, or analytical caveats recorded at report submission. |
| `report_replaced_id` | `bigint` | Foreign key referencing public.reports(id) (nullable). Points to the earlier report revision that this report replaces / amends. |
| `is_cancelled` | `boolean NOT NULL DEFAULT false` | Boolean status flag. True indicates the report was officially invalidated or cancelled. |
| `user_cancelled_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The user who cancelled the test report. |
| `date_cancelled` | `timestamp with time zone` | Timestamp with time zone when the report was cancelled. |
| `comments_cancelled` | `text` | Mandatory documented justification explaining why the test report was cancelled. |

---

## Table: `sop_versions`
<a id="table-sop-versions"></a>

**Description:** Versioned document releases of Standard Operating Procedures (SOPs). Ensures compliance with document control guidelines by tracking active versus retired revisions and linking to external Electronic Document Management Systems (EDMS). Individual test measurements link to the exact sop_version_id in effect during execution.

**Primary Key:** `id`

**Unique Constraints:** `unq_sop_version_number(sop_id, version_number)`

**Foreign Keys:**
- `sop_id` -> `sops(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the SOP version revision. |
| `sop_id` | `bigint NOT NULL` | Foreign key referencing public.sops(id). Identifies the parent SOP to which this revision belongs. |
| `version_number` | `character varying(20) NOT NULL` | Revision string (maximum 20 characters, e.g., '1.0', '2.3', 'Rev C'). Unique per parent SOP. |
| `external_edms_id` | `character varying(100)` | External document management system identifier or hyperlink (maximum 100 characters) pointing to the controlled document PDF in the EDMS. |
| `comments` | `text` | Change control summary or revision history notes describing the updates introduced in this version. |
| `is_active` | `boolean NOT NULL DEFAULT true` | Boolean flag indicating whether this specific SOP version is currently active and authorized for analytical testing. Worksheet sessions query active SOP versions for logging test execution methods. |
| `date_activated` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Timestamp with time zone when this SOP version was officially authorized and released into production. Defaults to clock_timestamp(). |

---

## Table: `sops`
<a id="table-sops"></a>

**Description:** Standard Operating Procedures (SOPs) defining laboratory test methods and testing protocols. Optionally linked to a parent norm (norms). In TestDialog.tsx, choosing a norm filters the SOP dropdown to show only SOPs that reference that norm.

**Primary Key:** `id`

**Unique Constraints:** `sops_doc_code_key(doc_code)`

**Foreign Keys:**
- `norm_id` -> `norms(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the SOP. |
| `doc_code` | `character varying(50) NOT NULL` | Unique official SOP document code (maximum 50 characters, e.g., 'SOP-QC-MET-0042'). Validated for uniqueness via UniquenessChecker. |
| `title` | `character varying(150) NOT NULL` | Descriptive title of the standard operating procedure (up to 150 characters, e.g., 'Determination of Water Content by Karl Fischer Titration'). |
| `norm_id` | `bigint` | Foreign key referencing public.norms(id) (nullable). Identifies the governing compendial norm or pharmacopeia from which this SOP is derived. |
| `nr_ord` | `bigint NOT NULL DEFAULT 0` | Numeric display and sequence ordering index (defaults to 0). |
| `date_created` | `timestamp with time zone NOT NULL DEFAULT clock_timestamp()` | Timestamp with time zone when the SOP record was created. Defaults to clock_timestamp(). |

---

## Table: `spec_test_evals`
<a id="table-spec-test-evals"></a>

**Description:** Verification benchmark test cases for specification test conditions (spec_tests.condition). In SpecTestDialog.tsx, authors define test values and expected results (1=pass, 0=fail). The backend recalculates and verifies all cases to guarantee formula correctness before specification activation.

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
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the evaluation test row. |
| `spec_id` | `bigint NOT NULL` | Foreign key referencing public.specs(id). The parent specification. |
| `test_id` | `bigint NOT NULL` | Foreign key referencing public.tests(id). The test being verified. |
| `value` | `numeric NOT NULL` | Test input value passed into the specification condition expression. |
| `result` | `numeric` | Actual boolean result evaluated by the rule engine (1 for conforming, 0 for non-conforming). |
| `expected_result` | `numeric NOT NULL` | Expected outcome (1 for pass, 0 for fail) defined by the specification author. |
| `is_match` | `boolean NOT NULL DEFAULT false` | Boolean flag. True indicates result matches expected_result. |
| `note` | `character varying(20)` | Short descriptive note explaining the test scenario (maximum 20 characters, e.g., 'Lower limit fail', 'Target pass'). |

---

## Table: `spec_tests`
<a id="table-spec-tests"></a>

**Description:** Acceptance limits and testing criteria for each analytical test within a specification. Encapsulates executable boolean condition formulas, human-readable specification notes, testing frequency, and ISO/IEC 17025 measurement uncertainty guard-band evaluation rules.

**Primary Key:** `spec_id, test_id`

**Foreign Keys:**
- `spec_id` -> `specs(id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `spec_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.specs(id). The parent specification. |
| `test_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.tests(id). The analytical test evaluated under this specification. |
| `condition` | `character varying(255) NOT NULL` | Executable boolean expression string (maximum 255 characters, e.g., '[value] >= 98.0 && [value] <= 102.0', '[value] == 1'). Validated on blur in SpecTestDialog.tsx via SpecificationsService.ValidateCondition. Evaluated during certificate generation. |
| `note` | `character varying(150) NOT NULL` | Human-readable specification limit text (maximum 150 characters, e.g., '98.0% - 102.0%', 'Clear colorless liquid', 'NMT 0.5%'). Printed on analytical test reports and Quality Certificates. |
| `use_uncertainty` | `boolean NOT NULL DEFAULT false` | Boolean flag implementing ISO/IEC 17025 / ILAC-G8 decision rules. When true, certificate evaluation takes expanded measurement uncertainty into account by verifying that both the lower bound [value - U] and upper bound [value + U] satisfy the condition. |
| `test_frequency` | `integer NOT NULL` | Integer testing frequency rule (e.g., 1 indicates testing is performed on every batch; 5 indicates skip-lot testing every 5 batches). |

---

## Table: `specs`
<a id="table-specs"></a>

**Description:** Product and material quality specifications. Defines release limits, compendial monographs, and acceptance criteria used to judge whether manufactured batches or raw material deliveries conform to registered quality standards. Governed by formal submission, replacement/revision, and cancellation lifecycles with electronic signatures.

**Primary Key:** `id`

**Foreign Keys:**
- `material_id` -> `materials(id)`
- `spec_replaced_id` -> `specs(id)`
- `user_cancelled_id` -> `users(id)`
- `user_submitted_id` -> `users(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the specification. |
| `material_id` | `bigint NOT NULL` | Foreign key referencing public.materials(id). The material or product governed by this specification. |
| `is_submitted` | `boolean NOT NULL DEFAULT false` | Boolean status flag. True indicates the specification has been approved and activated for release testing. Only submitted and non-cancelled specifications are active for sample receptions and certificate generation. |
| `user_submitted_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The QC authority who approved and submitted the specification. |
| `date_submitted` | `timestamp with time zone` | Timestamp with time zone when the specification was officially activated. |
| `comments_submitted` | `text` | Regulatory remarks, change control numbers, or justification recorded at submission. |
| `spec_replaced_id` | `bigint` | Foreign key referencing public.specs(id) (nullable). Points to the previous specification version that this new revision supersedes. |
| `is_cancelled` | `boolean NOT NULL DEFAULT false` | Boolean status flag. True indicates this specification has been cancelled or retired. |
| `user_cancelled_id` | `bigint` | Foreign key referencing public.users(id) (nullable). The user who cancelled the specification. |
| `date_cancelled` | `timestamp with time zone` | Timestamp with time zone when the specification was cancelled. |
| `comments_cancelled` | `text` | Mandatory documented explanation explaining why the specification was cancelled. |

---

## Table: `test_enums`
<a id="table-test-enums"></a>

**Description:** Discrete lookup choice options for enum-type analytical tests (value_types.id = 4). When creating a new enum test in TestDialog.tsx, the analyst must supply at least two unique items (parsed from enumListString by newline, comma, or semicolon). Individual items can be added or edited via TestEnumDialog.tsx.

**Primary Key:** `test_id, value`

**Unique Constraints:** `test_enums_test_id_name_key(test_id, name)`

**Foreign Keys:**
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `test_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.tests(id). The parent test to which this enumeration item belongs. |
| `value` | `bigint NOT NULL` | Primary key. Integer numeric code stored in measurement tables (measurement_tests.value, measurement_params.value) when this enum option is selected (e.g., 1 for 'Clear', 2 for 'Slightly Opalescent', 3 for 'Turbid'). |
| `name` | `character varying(50) NOT NULL` | Human-readable display label (1 to 50 characters, e.g., 'Conforms', 'Positive', 'Clear colorless liquid') shown in dropdowns and printed on analytical certificates. |
| `nr_ord` | `bigint NOT NULL DEFAULT 0` | Numeric display order index (defaults to 0) controlling the sequence of options in client select menus. |
| `is_obsolete` | `boolean NOT NULL DEFAULT false` | Soft-deletion flag. When true, hides this enum option from future selection while preserving historical test result interpretation. |

---

## Table: `test_equipments`
<a id="table-test-equipments"></a>

**Description:** Many-to-many junction table associating laboratory test definitions with required or default equipment models (equipments). When creating a measurement worksheet, tests automatically identify eligible instruments based on these assignments.

**Primary Key:** `test_id, equipment_id`

**Foreign Keys:**
- `equipment_id` -> `equipments(id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `test_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.tests(id). The analytical test requiring instrument allocation. |
| `equipment_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.equipments(id). The laboratory instrument authorized for executing this test. |

---

## Table: `test_reagents`
<a id="table-test-reagents"></a>

**Description:** Many-to-many junction table associating analytical tests with consumable chemical reagents or volumetric solutions (materials where is_reagent = true). Specifies which chemical reagents are consumed during test execution and drives reagent lot traceability on worksheets.

**Primary Key:** `test_id, material_id`

**Foreign Keys:**
- `material_id` -> `materials(id)`
- `test_id` -> `tests(id)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `test_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.tests(id). The analytical test that consumes the reagent. |
| `material_id` | `bigint NOT NULL` | Primary key and foreign key referencing public.materials(id). The chemical reagent material required for this test. |

---

## Table: `tests`
<a id="table-tests"></a>

**Description:** Master analytical test definition and calculation parameter dictionary. Defines physical, chemical, and biological tests, as well as intermediate variables used in formulas. Controls measurement data types, replicated array behavior, metrological uncertainty defaults, CRM requirements, norm/SOP method bindings, and validation immutability locks.

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
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the test/parameter definition. |
| `name` | `character varying(50) NOT NULL` | Unique descriptive name of the test (3 to 50 characters, e.g., 'Assay by HPLC', 'Loss on Drying', 'pH at 25°C'). Locked from editing if is_form_validated is true. |
| `code` | `character varying(50) NOT NULL` | Unique identifier token (2 to 50 characters) used as a mathematical variable in QC formulas (e.g., 'assay', 'lod_wt_loss', 'ph_val'). Must conform to regex /^(?!.*__)[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]$/ (starts with letter, ends with alphanumeric, only alphanumeric and single underscores). Locked from editing if is_form_validated is true to maintain formula AST parsing validity. |
| `description` | `text` | Extended explanatory text describing the test scope, analytical principle, or sampling preparation. |
| `type_id` | `bigint NOT NULL` | Foreign key referencing public.value_types(id). Specifies whether results are stored as integer (1), real (2), boolean (3), or enum (4). Locked from editing if is_form_validated is true. |
| `is_array` | `boolean NOT NULL DEFAULT false` | Boolean flag indicating whether the test yields multiple replicated measurement determinations (e.g., parallel injections, duplicate titrations) rather than a single scalar value. In formulas, arrays are referenced as [[code]]. In TestDialog.tsx, setting is_array to true automatically resets and disables for_certified_reference. Locked from editing if is_form_validated is true. |
| `is_param` | `boolean NOT NULL DEFAULT false` | Boolean flag designating this test as an intermediate calculation parameter or raw input (e.g. tare weight, sample mass, dilution factor) rather than a reportable specification test. In TestDialog.tsx, setting is_param to true resets and disables for_certification, for_environmental_control, and for_certified_reference. Locked from editing if is_form_validated is true. |
| `for_environmental_control` | `boolean NOT NULL DEFAULT false` | Boolean flag designating this test for cleanroom and environmental monitoring (e.g., ambient temperature, relative humidity, air particulates). In TestDialog.tsx, enabling this flag enforces mutual exclusivity by automatically resetting for_certification, for_certified_reference, and is_param to false. |
| `for_certification` | `boolean NOT NULL DEFAULT false` | Boolean flag indicating that this is a critical specification test that must be reported on official Quality Certificates / Certificates of Analysis (COA). In TestDialog.tsx, checking this box automatically defaults relative_uncertainty_pct to 3.00% and default_coverage_factor_k to 2.0 (if null/0), and resets for_environmental_control and is_param to false. Unchecking it resets uncertainty fields to NULL. |
| `relative_uncertainty_pct` | `numeric` | Expanded relative measurement uncertainty percentage (NUMERIC(5,2), e.g., 3.00 for ±3.00%). Used by the reporting engine to calculate absolute expanded measurement uncertainty: U = (value * relative_uncertainty_pct / 100). Editable only when for_certification is true; automatically cleared to NULL when for_certification is false. |
| `default_coverage_factor_k` | `numeric` | Default coverage factor k (NUMERIC(3,1), typically 2.0 corresponding to approximately 95% level of confidence under a normal distribution). Used in accordance with ISO/IEC 17025 and GUM (Guide to the Expression of Uncertainty in Measurement). Cleared to NULL when for_certification is false. |
| `for_certified_reference` | `boolean NOT NULL DEFAULT false` | Boolean flag enforcing strict metrological traceability. When true, during worksheet execution (SelectCrmDialog.tsx), the analyst cannot manually type an arbitrary numeric value; they must select an active, certified value from a Certified Reference Material (CRM) inventory lot or prior CRM certificate. In TestDialog.tsx, enabling this flag resets and disables is_array, is_param, and for_environmental_control. |
| `unit_id` | `bigint` | Foreign key referencing public.units(id) (nullable). Identifies the default unit of measure associated with this test's results. |
| `norm_id` | `bigint` | Foreign key referencing public.norms(id) (nullable). Identifies the governing compendial standard. In TestDialog.tsx, selecting a norm filters available SOPs to those belonging to that norm, and clearing the norm resets norm_ref to NULL, sop_id to NULL, and empties the SOP list. |
| `norm_ref` | `character varying(50)` | Textual citation (maximum 50 characters) identifying the exact clause, section, or monograph within the governing norm (e.g., 'Ph. Eur. 2.2.3', 'USP <621>'). Enabled in TestDialog.tsx only when norm_id is selected. |
| `sop_id` | `bigint` | Foreign key referencing public.sops(id) (nullable). Links the test definition to its approved operating procedure. Filtered by norm_id in the client UI. |
| `is_form_validated` | `boolean NOT NULL DEFAULT false` | Boolean validation lock. Automatically set to true by FormsService.ValidateForm when any form containing this test is validated and approved. Once true, the client UI disables and server rejects edits to test name, code, type_id, and is_array to guarantee that validated mathematical formulas and calculation ASTs do not become corrupt or broken. |
| `date_form_validated` | `timestamp with time zone` | Timestamp with time zone when the test definition was locked following form validation approval. |
| `nr_ord` | `bigint NOT NULL DEFAULT 0` | Default numeric presentation and sorting order index (defaults to 0) used when displaying tests in tables and reports. |
| `date_created` | `timestamp with time zone NOT NULL` | Timestamp with time zone when the test was originally registered. |
| `is_obsolete` | `boolean NOT NULL DEFAULT false` | Soft-deletion flag. Under GxP requirements, test definitions cannot be physically removed if referenced in historical worksheets, specifications, or certificates. When true, hides the test from new templates and specifications. |
| `date_obsolete` | `timestamp with time zone` | Timestamp with time zone when the test was decommissioned. Cleared to NULL if reactivated. |
| `comments_obsolete` | `text` | Documented reason recorded when deactivating the test definition. Cleared to NULL if reactivated. |

---

## Table: `units`
<a id="table-units"></a>

**Description:** Lookup catalog of units of measurement (UOM) utilized across analytical test definitions, laboratory equipment, chemical reagents, and parameter calculations (e.g., 'mg', 'mL', 'g/cm3', '%', 'pH', '°C', 'rpm', 'AU').

**Primary Key:** `id`

**Unique Constraints:** `units_name_key(name)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for the measurement unit. |
| `name` | `character varying(50) NOT NULL` | Unique symbol or name of the unit of measure (maximum 50 characters, e.g., 'mg/kg', 'mPa.s', 'Abs'). Displayed alongside test inputs, results, and specification notes. |
| `description` | `text` | Full descriptive name or context for the measurement unit (e.g., 'Milligrams per kilogram', 'Degrees Celsius'). |
| `date_created` | `timestamp with time zone NOT NULL` | Timestamp with time zone when the measurement unit record was created in the system. |

---

## Table: `users`
<a id="table-users"></a>

**Description:** User accounts and role-based access control table for laboratory personnel, QC managers, and system administrators. Maintains authentication credentials, session tracking, account security (lockout, password expiration), and soft-deletion status for GxP auditability.

**Primary Key:** `id`

**Unique Constraints:** `users_code_key(code), users_email_key(email), users_session_id_key(session_id), users_tag_key(tag)`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique 64-bit integer identifier for each laboratory system user. |
| `tag` | `character varying(12) NOT NULL` | Unique user login username/handle (3 to 12 characters). Enforced by client regex /^[a-z][a-z0-9_]*[a-z0-9]$/ (must start with a lowercase letter, end with alphanumeric, contain only lowercase letters, digits, or underscores). Used for authentication and audit log displays. |
| `code` | `character varying(3) NOT NULL` | Unique 2 to 3 uppercase alphanumeric identifier (regex /^[A-Z][A-Z0-9]*$/) representing the user's initials. Displayed on compact laboratory worksheets, test result tags, and sample labels. |
| `email` | `character varying(50) NOT NULL` | Unique email address of the user (maximum 50 characters). Validated via standard email format rules. |
| `first_name` | `character varying(50)` | User's given first name (maximum 50 characters). |
| `last_name` | `character varying(50)` | User's family/surname (maximum 50 characters). |
| `is_admin` | `boolean NOT NULL DEFAULT false` | Boolean role flag. When true, grants full administrative privileges including user management, role assignments, system settings, and master data configuration. |
| `is_lab_pers` | `boolean NOT NULL DEFAULT false` | Boolean role flag. When true, identifies the user as Laboratory Personnel, granting authorization to execute sample receptions, input raw measurement readings, prepare reagent lots, and operate worksheets. |
| `is_qc_pers` | `boolean NOT NULL DEFAULT false` | Boolean role flag. When true, identifies the user as Quality Control Personnel, granting authorization to review, validate, and approve forms, specifications, testing reports, and official quality certificates. |
| `password_hash` | `text` | Secure cryptographic salted hash of the user's authentication password. |
| `password_salt` | `text` | Cryptographic salt value applied during password hashing to prevent rainbow table attacks. |
| `must_change_password` | `boolean NOT NULL DEFAULT false` | Boolean flag forcing the user to update their password upon next login. Automatically set to true when an administrator creates a user account or executes an administrative password reset via ResetPasswordDialog.tsx. |
| `date_password_changed` | `timestamp with time zone` | Timestamp with time zone when the user's password was last modified. Used for password aging policies. |
| `failed_login_attempts` | `integer NOT NULL DEFAULT 0` | Integer counter tracking consecutive failed login attempts. Reset to 0 upon successful login; used to trigger temporary or administrative account lockout after exceeding maximum allowed thresholds. |
| `is_locked` | `boolean NOT NULL DEFAULT false` | Boolean flag indicating whether the account is currently locked against login attempts due to repeated authentication failures or manual administrative suspension. |
| `lock_expiration` | `timestamp with time zone` | Timestamp with time zone indicating when the temporary account lockout expires and authentication attempts may resume. |
| `session_id` | `character varying(255)` | Unique GUID string representing the user's active session. Stored in the secure HTTP cookie 'QCLabSession_{tenantTag}'. Cleared (set to NULL) upon explicit logout, session expiration, password reset, or account deactivation. |
| `date_session_created` | `timestamp with time zone` | Timestamp with time zone when the current session_id was generated upon successful login. |
| `date_session_expire` | `timestamp with time zone` | Timestamp with time zone when the current session_id expires (typically 12 hours from generation). Checked by SessionAuthMiddleware. |
| `refresh_token` | `character varying` | Cryptographic refresh token string used for renewing API sessions. |
| `date_created` | `timestamp with time zone NOT NULL` | Timestamp with time zone when the user profile was originally registered in the system. |
| `is_obsolete` | `boolean NOT NULL DEFAULT false` | Soft-deletion flag. Under GxP and 21 CFR Part 11 regulations, user records cannot be physically deleted because they are referenced across audit trails, electronic signatures, and test worksheets. True indicates the user is deactivated. |
| `date_obsolete` | `timestamp with time zone` | Timestamp with time zone when the user was marked obsolete / deactivated. Cleared to NULL if reactivated. |
| `comments_obsolete` | `text` | Mandatory documented explanation recorded when deactivating the user profile. Cleared to NULL if reactivated. |

---

## Table: `value_types`
<a id="table-value-types"></a>

**Description:** Static foundational reference table defining data types supported for analytical tests and formula parameters: 1 = 'integer' (whole numbers), 2 = 'real' (floating point / decimal numbers), 3 = 'boolean' (binary pass/fail / true/false), 4 = 'enum' (discrete selection options defined in test_enums).

**Primary Key:** `id`

### Columns

| Column Name | Data Type & Definition | Description |
| :--- | :--- | :--- |
| `id` | `bigint NOT NULL` | Primary key. Unique identifier corresponding to the primitive value type enumeration. |
| `name` | `character varying(50) NOT NULL` | Unique name of the data type ('integer', 'real', 'boolean', 'enum'). Used by the UI to dynamically render appropriate input controls (number input, checkbox/toggle, or select dropdown) and by the QCFormula engine for type inference. |

---
