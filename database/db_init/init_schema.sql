--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: process_audit_log(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.process_audit_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_user_id bigint;
    v_reason text;
    v_old_json jsonb := NULL;
    v_new_json jsonb := NULL;
    v_changed_fields text[] := ARRAY[]::text[];
    v_record_keys jsonb := '{}'::jsonb;
    v_row record;
    v_pk_col text;
    v_pk_data_type text;
    v_pk_val bigint;
    v_pk_count int := 0;
BEGIN
    -- Extract session settings passed from backend API transaction
    v_user_id := NULLIF(current_setting('app.current_user_id', true), '')::bigint;
    v_reason := NULLIF(current_setting('app.reason_for_change', true), '');

    -- Enforce User Attribution (21 CFR Part 11 Requirement)
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Audit Enforcement Error: Session variable "app.current_user_id" must be set prior to modifying data.';
    END IF;

    -- Enforce Reason for Change on UPDATE or DELETE
    IF (TG_OP IN ('UPDATE', 'DELETE')) AND (v_reason IS NULL OR trim(v_reason) = '') THEN
        RAISE EXCEPTION 'Audit Enforcement Error: A non-empty "app.reason_for_change" is required for UPDATE or DELETE operations.';
    END IF;

    -- Capture JSON Snapshots
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        v_old_json := to_jsonb(OLD);
    END IF;

    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        v_new_json := to_jsonb(NEW);
    END IF;

    -- Determine modified column names on UPDATE
    IF TG_OP = 'UPDATE' THEN
        SELECT array_agg(key) INTO v_changed_fields
        FROM jsonb_each(v_old_json)
        WHERE v_old_json -> key IS DISTINCT FROM v_new_json -> key;
    END IF;

    -- Resolve row record
    v_row := COALESCE(NEW, OLD);

    -- Dynamically discover primary key columns and enforce integer/bigint types
    FOR v_pk_col, v_pk_data_type IN 
        SELECT kcu.column_name, c.data_type
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu 
          ON tc.constraint_name = kcu.constraint_name 
         AND tc.table_schema = kcu.table_schema
        JOIN information_schema.columns c
          ON c.table_schema = tc.table_schema
         AND c.table_name = tc.table_name
         AND c.column_name = kcu.column_name
        WHERE tc.table_schema = TG_TABLE_SCHEMA 
          AND tc.table_name = TG_TABLE_NAME 
          AND tc.constraint_type = 'PRIMARY KEY'
        ORDER BY kcu.ordinal_position
    LOOP
        v_pk_count := v_pk_count + 1;

        -- Enforce integer/bigint primary key types
        IF v_pk_data_type NOT IN ('integer', 'bigint', 'smallint') THEN
            RAISE EXCEPTION 'Audit Configuration Error: Table "%" primary key column "%" has data type "%". Audit requires integer/bigint primary keys.', 
                TG_TABLE_NAME, v_pk_col, v_pk_data_type;
        END IF;

        -- Extract primary key value
        EXECUTE format('SELECT ($1.%I)::bigint', v_pk_col) USING v_row INTO v_pk_val;
        v_record_keys := jsonb_set(v_record_keys, ARRAY[v_pk_col], to_jsonb(v_pk_val));
    END LOOP;

    -- If no primary key constraint exists on the table, raise an error
    IF v_pk_count = 0 THEN
        RAISE EXCEPTION 'Audit Configuration Error: Table "%" has no primary key constraint. Audit is not applicable.', TG_TABLE_NAME;
    END IF;

    -- Persist record to audit_logs table
    INSERT INTO public.audit_logs (
        table_name,
        record_keys,
        action,
        old_data,
        new_data,
        changed_fields,
        user_id,
        reason_for_change,
        client_ip
    ) VALUES (
        TG_TABLE_NAME,
        v_record_keys,
        TG_OP,
        v_old_json,
        v_new_json,
        v_changed_fields,
        v_user_id,
        v_reason,
        NULLIF(current_setting('app.client_ip', true), '')
    );

    RETURN COALESCE(NEW, OLD);
END;
$_$;


ALTER FUNCTION public.process_audit_log() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    table_name character varying(100) NOT NULL,
    record_keys jsonb,
    action character varying(10) NOT NULL,
    old_data jsonb,
    new_data jsonb,
    changed_fields text[],
    user_id bigint NOT NULL,
    reason_for_change text,
    "timestamp" timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    client_ip character varying(45)
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- Name: TABLE audit_logs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.audit_logs IS 'GxP and 21 CFR Part 11 compliant audit trail log table. Automatically populated via the PostgreSQL trigger function ''process_audit_log()'' whenever INSERT, UPDATE, or DELETE operations occur on critical quality tables (certificates, certificate_tests, forms, form_params, measurements, measurement_params, measurement_tests, reports, report_tests, specs, spec_tests). Application user context and justification are injected into PostgreSQL session variables (''app.current_user_id'' and ''app.reason_for_change'') by the server DbCommandInterceptor ''AuditSessionDbCommandInterceptor''.';


--
-- Name: COLUMN audit_logs.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.audit_logs.id IS 'Primary key. Unique synthetic 64-bit integer identifier for each audit trail entry.';


--
-- Name: COLUMN audit_logs.table_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.audit_logs.table_name IS 'Name of the database table where the DML modification took place (e.g., ''measurements'', ''forms'', ''specs''). Populated automatically by the trigger via TG_TABLE_NAME.';


--
-- Name: COLUMN audit_logs.record_keys; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.audit_logs.record_keys IS 'JSONB object capturing the primary key column names and values of the audited record (e.g., {"id": 105} or composite keys like {"form_id": 2, "test_id": 14, "idx": 0}). Enables exact historical row tracking.';


--
-- Name: COLUMN audit_logs.action; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.audit_logs.action IS 'DML operation type performed on the record: ''INSERT'', ''UPDATE'', or ''DELETE''. Populated via TG_OP in the audit trigger.';


--
-- Name: COLUMN audit_logs.old_data; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.audit_logs.old_data IS 'JSONB snapshot of the entire table row before the change occurred. Set to NULL for INSERT actions; contains pre-modification state for UPDATE and DELETE actions.';


--
-- Name: COLUMN audit_logs.new_data; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.audit_logs.new_data IS 'JSONB snapshot of the entire table row after the change occurred. Set to NULL for DELETE actions; contains post-modification state for INSERT and UPDATE actions.';


--
-- Name: COLUMN audit_logs.changed_fields; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.audit_logs.changed_fields IS 'PostgreSQL text array (TEXT[]) listing the column names whose values were modified during an UPDATE operation. Allows rapid filtering and visual highlighting of specific edited fields in the audit viewer (AuditLogsTable.tsx).';


--
-- Name: COLUMN audit_logs.user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.audit_logs.user_id IS 'Foreign key referencing public.users(id). Identifies the laboratory analyst or QC supervisor who executed the transaction. Sourced from the transaction session variable ''app.current_user_id'' set by AuditSessionDbCommandInterceptor.';


--
-- Name: COLUMN audit_logs.reason_for_change; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.audit_logs.reason_for_change IS 'Mandatory user-supplied justification for the modification. Captured in the UI via modal dialogs (e.g. CommentDialog) and transferred into PostgreSQL via the session variable ''app.reason_for_change'' to ensure compliance with 21 CFR Part 11 requirements.';


--
-- Name: COLUMN audit_logs."timestamp"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.audit_logs."timestamp" IS 'Timestamp with time zone indicating the exact database transaction time when the audit entry was written. Defaults to clock_timestamp() to capture accurate wall-clock execution time.';


--
-- Name: COLUMN audit_logs.client_ip; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.audit_logs.client_ip IS 'Network IP address (IPv4 or IPv6, up to 45 characters) of the client machine that initiated the API request. Captured by ASP.NET Core HttpContextAccessor and recorded for forensic cybersecurity and compliance traceability.';


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.audit_logs ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    id bigint NOT NULL,
    name character varying(50) NOT NULL,
    code character varying(5) NOT NULL,
    description text,
    date_created timestamp with time zone NOT NULL,
    is_obsolete boolean DEFAULT false NOT NULL,
    date_obsolete timestamp with time zone,
    comments_obsolete text
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- Name: TABLE categories; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.categories IS 'Master classification table grouping materials and products into logical families (e.g., ''Finished Products'', ''Active Pharmaceutical Ingredients'', ''Excipients'', ''Solvents''). Used for organizing catalog items and driving ad-hoc Category Verification sample receptions.';


--
-- Name: COLUMN categories.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.categories.id IS 'Primary key. Unique 64-bit integer identifier for the category.';


--
-- Name: COLUMN categories.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.categories.name IS 'Unique name of the material category (3 to 50 characters). Validated for uniqueness on blur in CategoryDialog.tsx.';


--
-- Name: COLUMN categories.code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.categories.code IS 'Unique 2 to 5 character uppercase alphanumeric classification code (regex /^[A-Z][A-Z0-9]*$/). Validated for uniqueness on the client and server.';


--
-- Name: COLUMN categories.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.categories.description IS 'Optional extended description of the category scope and materials covered.';


--
-- Name: COLUMN categories.date_created; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.categories.date_created IS 'Timestamp with time zone when the category was established.';


--
-- Name: COLUMN categories.is_obsolete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.categories.is_obsolete IS 'Soft-deletion flag. When true, prevents the category from being selected in new material definitions or category verification receptions while preserving historical records.';


--
-- Name: COLUMN categories.date_obsolete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.categories.date_obsolete IS 'Timestamp with time zone when the category was retired. Cleared to NULL if reactivated.';


--
-- Name: COLUMN categories.comments_obsolete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.categories.comments_obsolete IS 'Documented reason recorded when retiring the category. Cleared to NULL if reactivated.';


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.categories ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: category_tests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.category_tests (
    category_id bigint NOT NULL,
    test_id bigint NOT NULL
);


ALTER TABLE public.category_tests OWNER TO postgres;

--
-- Name: TABLE category_tests; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.category_tests IS 'Many-to-many junction table associating laboratory test definitions with material categories. Defines the standard battery of tests applicable to an entire category. When creating a Category Verification sample reception (CategoryVerificationDialog.tsx), selecting a category dynamically pre-populates the list of available tests from this table.';


--
-- Name: COLUMN category_tests.category_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.category_tests.category_id IS 'Primary key and foreign key referencing public.categories(id). The material category receiving the test assignment.';


--
-- Name: COLUMN category_tests.test_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.category_tests.test_id IS 'Primary key and foreign key referencing public.tests(id). The analytical test assigned to the category.';


--
-- Name: certificate_tests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.certificate_tests (
    certificate_id bigint NOT NULL,
    report_id bigint NOT NULL,
    measurement_id bigint NOT NULL,
    test_id bigint NOT NULL,
    idx integer DEFAULT 0 NOT NULL,
    value numeric NOT NULL,
    uncertainty_value numeric,
    coverage_factor_k numeric,
    is_conforming_spec boolean DEFAULT false NOT NULL,
    is_conforming_uncertainty boolean DEFAULT true NOT NULL,
    note_spec character varying(25) NOT NULL,
    test_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.certificate_tests OWNER TO postgres;

--
-- Name: TABLE certificate_tests; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.certificate_tests IS 'Line-item analytical test evaluations displayed on the Quality Certificate / Certificate of Analysis (COA). Contains evaluated test results, expanded uncertainty values, individual specification compliance flags (is_conforming_spec), guard-band compliance flags (is_conforming_uncertainty), and snapshots of specification limits (note_spec).';


--
-- Name: COLUMN certificate_tests.certificate_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificate_tests.certificate_id IS 'Primary key and foreign key referencing public.certificates(id). The parent quality certificate.';


--
-- Name: COLUMN certificate_tests.report_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificate_tests.report_id IS 'Primary key and foreign key referencing public.reports(id). The source test report providing the data.';


--
-- Name: COLUMN certificate_tests.measurement_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificate_tests.measurement_id IS 'Primary key and foreign key referencing public.measurements(id). The raw measurement session.';


--
-- Name: COLUMN certificate_tests.test_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificate_tests.test_id IS 'Primary key and foreign key referencing public.tests(id). The analytical test evaluated.';


--
-- Name: COLUMN certificate_tests.idx; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificate_tests.idx IS 'Primary key. Determination index (0 for scalar, 0..N for replicated arrays).';


--
-- Name: COLUMN certificate_tests.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificate_tests.value IS 'Certified analytical test result value.';


--
-- Name: COLUMN certificate_tests.uncertainty_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificate_tests.uncertainty_value IS 'Expanded measurement uncertainty U associated with the certified result.';


--
-- Name: COLUMN certificate_tests.coverage_factor_k; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificate_tests.coverage_factor_k IS 'Coverage factor k (typically 2.0) applied to the uncertainty estimate.';


--
-- Name: COLUMN certificate_tests.is_conforming_spec; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificate_tests.is_conforming_spec IS 'Boolean flag. Evaluated by executing the specification condition formula (spec_tests.condition) against the measured value. True if value meets specification limits; false otherwise.';


--
-- Name: COLUMN certificate_tests.is_conforming_uncertainty; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificate_tests.is_conforming_uncertainty IS 'Boolean flag. Evaluated by checking whether both [value - uncertainty_value] AND [value + uncertainty_value] satisfy the specification condition formula. Enforces ILAC-G8 guard-banding rules for ISO/IEC 17025 accredited reporting.';


--
-- Name: COLUMN certificate_tests.note_spec; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificate_tests.note_spec IS 'Historical snapshot text of the specification acceptance criteria in effect at the time of certification (maximum 25 characters, e.g., ''>= 98.0%'', ''Clear liquid''). Preserves exact historical limits regardless of future spec revisions.';


--
-- Name: COLUMN certificate_tests.test_count; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificate_tests.test_count IS 'Integer count of determinations or replicates performed to establish this result (defaults to 0).';


--
-- Name: certificates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.certificates (
    id bigint NOT NULL,
    control_code_id bigint NOT NULL,
    spec_id bigint NOT NULL,
    is_conforming_spec boolean DEFAULT false NOT NULL,
    is_conforming_uncertainty boolean DEFAULT true NOT NULL,
    is_submitted boolean DEFAULT false NOT NULL,
    user_submitted_id bigint,
    date_submitted timestamp with time zone,
    comments_submitted text,
    certificate_replaced_id bigint,
    is_cancelled boolean DEFAULT false NOT NULL,
    user_cancelled_id bigint,
    date_cancelled timestamp with time zone,
    comments_cancelled text
);


ALTER TABLE public.certificates OWNER TO postgres;

--
-- Name: TABLE certificates; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.certificates IS 'Official Quality Certificates / Certificates of Analysis (COA) issued for a manufactured batch or raw material lot (control_code_id). Evaluates laboratory test results against the active specification (spec_id). Computes both direct specification conformance and uncertainty guard-band conformance (ISO/IEC 17025 / ILAC-G8). Enforces 21 CFR Part 11 digital signatures on approval.';


--
-- Name: COLUMN certificates.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificates.id IS 'Primary key. Unique 64-bit integer identifier for the quality certificate.';


--
-- Name: COLUMN certificates.control_code_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificates.control_code_id IS 'Foreign key referencing public.control_codes(id). The batch or inventory lot covered by this certificate.';


--
-- Name: COLUMN certificates.spec_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificates.spec_id IS 'Foreign key referencing public.specs(id). The active specification used to evaluate batch conformance.';


--
-- Name: COLUMN certificates.is_conforming_spec; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificates.is_conforming_spec IS 'Boolean conformance flag. True indicates that ALL required tests meet specification limits and no mandatory specification tests are missing. Calculated automatically by CertificatesService.CalculateAndSaveCertificateTests.';


--
-- Name: COLUMN certificates.is_conforming_uncertainty; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificates.is_conforming_uncertainty IS 'Boolean guard-band conformance flag implementing ISO/IEC 17025 / ILAC-G8 decision rules. True indicates that both the lower bound [value - U] and upper bound [value + U] fall within the specification acceptance range for all tests.';


--
-- Name: COLUMN certificates.is_submitted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificates.is_submitted IS 'Boolean status flag. True indicates the Quality Certificate has been formally approved and released with a 21 CFR Part 11 electronic signature.';


--
-- Name: COLUMN certificates.user_submitted_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificates.user_submitted_id IS 'Foreign key referencing public.users(id) (nullable). The authorized QC manager / Qualified Person who signed and released the certificate.';


--
-- Name: COLUMN certificates.date_submitted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificates.date_submitted IS 'Timestamp with time zone when the certificate was signed and released.';


--
-- Name: COLUMN certificates.comments_submitted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificates.comments_submitted IS 'Quality assurance release disposition notes, authorized deviations, or release comments.';


--
-- Name: COLUMN certificates.certificate_replaced_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificates.certificate_replaced_id IS 'Foreign key referencing public.certificates(id) (nullable). Points to the previous certificate revision that this document supersedes.';


--
-- Name: COLUMN certificates.is_cancelled; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificates.is_cancelled IS 'Boolean status flag. True indicates the certificate was officially revoked or cancelled.';


--
-- Name: COLUMN certificates.user_cancelled_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificates.user_cancelled_id IS 'Foreign key referencing public.users(id) (nullable). The user who revoked the certificate.';


--
-- Name: COLUMN certificates.date_cancelled; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificates.date_cancelled IS 'Timestamp with time zone when the certificate was cancelled.';


--
-- Name: COLUMN certificates.comments_cancelled; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.certificates.comments_cancelled IS 'Mandatory documented justification explaining why the quality certificate was revoked.';


--
-- Name: certification_headers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.certificates ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.certification_headers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: control_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.control_codes (
    id bigint NOT NULL,
    material_id bigint NOT NULL,
    code character varying(50) NOT NULL,
    is_reception_received boolean DEFAULT false NOT NULL,
    date_created timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE public.control_codes OWNER TO postgres;

--
-- Name: TABLE control_codes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.control_codes IS 'Central batch/lot identification and inventory tracking table. Every physical batch of manufactured product, raw material delivery, purchased reagent lot, or in-house prepared reagent is assigned a unique control code linked to its material. Serves as the primary traceability anchor across sample receptions, testing worksheets, quality certificates, and reagent genealogy.';


--
-- Name: COLUMN control_codes.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.control_codes.id IS 'Primary key. Unique 64-bit integer identifier for the control code record.';


--
-- Name: COLUMN control_codes.material_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.control_codes.material_id IS 'Foreign key referencing public.materials(id). The specific material, chemical, or product to which this batch/lot belongs.';


--
-- Name: COLUMN control_codes.code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.control_codes.code IS 'Alphanumeric batch/control code string (up to 50 characters). Unique per material. Must contain no whitespace (enforced by regex /^\S*$/). In sample reception dialogs (CertificationDialog, VerificationDialog), users can select an existing control code or enter a new one, which is verified for uniqueness against the selected material via UniquenessChecker.';


--
-- Name: COLUMN control_codes.is_reception_received; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.control_codes.is_reception_received IS 'Boolean status flag. Automatically updated from false to true when any sample reception referencing this control code is accepted into the laboratory (ReceptionsService.ReceiveReception). Signals that physical samples of this batch have been received in the lab.';


--
-- Name: COLUMN control_codes.date_created; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.control_codes.date_created IS 'Timestamp with time zone when the control code was generated. Defaults to clock_timestamp().';


--
-- Name: electronic_signatures; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.electronic_signatures (
    id bigint NOT NULL,
    version bigint DEFAULT 1 NOT NULL,
    entity_name character varying(50) NOT NULL,
    entity_id bigint NOT NULL,
    signer_user_id bigint NOT NULL,
    signature_meaning character varying(50) NOT NULL,
    signing_timestamp timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    payload_sha256 character varying(64) NOT NULL,
    signature_manifest_text text NOT NULL,
    client_ip character varying(45) NOT NULL
);


ALTER TABLE public.electronic_signatures OWNER TO postgres;

--
-- Name: TABLE electronic_signatures; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.electronic_signatures IS 'Cryptographic electronic signature ledger enforcing 21 CFR Part 11 and EU GMP Annex 11 compliance. Stores legally binding digital signatures executed when laboratory personnel submit, validate, approve, or cancel critical quality documents (forms, specifications, test reports, quality certificates). Includes SHA-256 payload digests and human-readable signature manifests.';


--
-- Name: COLUMN electronic_signatures.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.electronic_signatures.id IS 'Primary key. Unique 64-bit integer identifier for the electronic signature record.';


--
-- Name: COLUMN electronic_signatures.version; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.electronic_signatures.version IS 'Monotonically increasing sequence number (defaults to 1) indicating the revision of the signature on a given entity record (e.g., Version 1 for initial submission, Version 2 for revision/approval, Version 3 for cancellation).';


--
-- Name: COLUMN electronic_signatures.entity_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.electronic_signatures.entity_name IS 'Name of the audited domain entity/table to which the signature applies (e.g., ''forms'', ''specs'', ''reports'', ''certificates'').';


--
-- Name: COLUMN electronic_signatures.entity_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.electronic_signatures.entity_id IS 'Primary key identifier of the specific domain record being digitally signed (e.g., forms.id, specs.id, certificates.id).';


--
-- Name: COLUMN electronic_signatures.signer_user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.electronic_signatures.signer_user_id IS 'Foreign key referencing public.users(id). The authenticated user who entered their credentials and executed the signature.';


--
-- Name: COLUMN electronic_signatures.signature_meaning; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.electronic_signatures.signature_meaning IS 'Legally defined statement of intent / meaning of the signature (e.g., ''Submission'', ''Validation'', ''Approval'', ''Cancellation''). Specifies the signer''s regulatory responsibility pursuant to 21 CFR § 11.50.';


--
-- Name: COLUMN electronic_signatures.signing_timestamp; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.electronic_signatures.signing_timestamp IS 'Cryptographic timestamp with time zone at the exact instant the signature was sealed. Defaults to clock_timestamp().';


--
-- Name: COLUMN electronic_signatures.payload_sha256; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.electronic_signatures.payload_sha256 IS 'Hex-encoded 64-character SHA-256 cryptographic hash of the canonical JSON representation of the entity state at the moment of signing. Guarantees tamper-evidence and data integrity: any post-signature tampering invalidates the hash verification.';


--
-- Name: COLUMN electronic_signatures.signature_manifest_text; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.electronic_signatures.signature_manifest_text IS 'Human-readable text manifest summarizing the signed record details, signer full name, user tag, signature meaning, and timestamp. Rendered in the client UI via SignatureManifestBlock.tsx for inspection during audits.';


--
-- Name: COLUMN electronic_signatures.client_ip; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.electronic_signatures.client_ip IS 'Network IPv4/IPv6 client IP address from which the signature action was executed.';


--
-- Name: electronic_signatures_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.electronic_signatures ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.electronic_signatures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: equipment_calibration_statuses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipment_calibration_statuses (
    id bigint NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.equipment_calibration_statuses OWNER TO postgres;

--
-- Name: TABLE equipment_calibration_statuses; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.equipment_calibration_statuses IS 'Lookup catalog for metrological calibration outcomes: 1 = ''Pass'' (metrology results conform fully to manufacturer tolerances and uncertainty limits), 2 = ''Fail'' (out-of-tolerance calibration requiring instrument repair or retirement), 3 = ''Limited Use'' (calibrated with restricted operational range or derated accuracy limits).';


--
-- Name: COLUMN equipment_calibration_statuses.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipment_calibration_statuses.id IS 'Primary key. Unique identifier for the calibration outcome status.';


--
-- Name: COLUMN equipment_calibration_statuses.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipment_calibration_statuses.name IS 'Unique name of the calibration status (''Pass'', ''Fail'', ''Limited Use'').';


--
-- Name: equipment_calibrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipment_calibrations (
    id bigint NOT NULL,
    equipment_id bigint NOT NULL,
    calibration_date date NOT NULL,
    expiration_date date NOT NULL,
    certificate_number character varying(100) NOT NULL,
    calibrated_by character varying(100) NOT NULL,
    status_id bigint NOT NULL,
    reference_standards_used text,
    expanded_uncertainty numeric,
    date_created timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE public.equipment_calibrations OWNER TO postgres;

--
-- Name: TABLE equipment_calibrations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.equipment_calibrations IS 'Historical calibration log and certificate registry for laboratory instruments. Adding or updating a calibration certificate in EquipmentCalibrationDialog.tsx automatically propagates the expiration_date to equipments.next_calibration_due and restores the instrument status to ''Active''.';


--
-- Name: COLUMN equipment_calibrations.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipment_calibrations.id IS 'Primary key. Unique 64-bit integer identifier for the calibration event.';


--
-- Name: COLUMN equipment_calibrations.equipment_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipment_calibrations.equipment_id IS 'Foreign key referencing public.equipments(id). The laboratory instrument subjected to calibration.';


--
-- Name: COLUMN equipment_calibrations.calibration_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipment_calibrations.calibration_date IS 'Date when the physical calibration procedure was performed.';


--
-- Name: COLUMN equipment_calibrations.expiration_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipment_calibrations.expiration_date IS 'Date when this calibration certificate expires. Automatically updates equipments.next_calibration_due.';


--
-- Name: COLUMN equipment_calibrations.certificate_number; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipment_calibrations.certificate_number IS 'Unique external or internal calibration certificate tracking number (maximum 100 characters, e.g., ''CAL-2026-09871'').';


--
-- Name: COLUMN equipment_calibrations.calibrated_by; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipment_calibrations.calibrated_by IS 'Name of the accredited metrology calibration service provider or internal calibration technician (maximum 100 characters).';


--
-- Name: COLUMN equipment_calibrations.status_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipment_calibrations.status_id IS 'Foreign key referencing public.equipment_calibration_statuses(id) (1=''Pass'', 2=''Fail'', 3=''Limited Use'').';


--
-- Name: COLUMN equipment_calibrations.reference_standards_used; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipment_calibrations.reference_standards_used IS 'Text details of traceable reference standards (e.g., NIST-traceable weights, calibrated quartz cuvettes) utilized during the calibration.';


--
-- Name: COLUMN equipment_calibrations.expanded_uncertainty; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipment_calibrations.expanded_uncertainty IS 'Expanded measurement uncertainty of the calibration method itself (NUMERIC), as stated on the calibration certificate.';


--
-- Name: COLUMN equipment_calibrations.date_created; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipment_calibrations.date_created IS 'Timestamp with time zone when the calibration record was logged into the system. Defaults to clock_timestamp().';


--
-- Name: equipment_calibrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.equipment_calibrations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.equipment_calibrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: equipments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipments (
    id bigint NOT NULL,
    equipment_code character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    manufacturer character varying(100),
    model character varying(100),
    serial_number character varying(100) NOT NULL,
    location character varying(100),
    status_id bigint NOT NULL,
    calibration_interval_days integer DEFAULT 365,
    next_calibration_due date,
    date_created timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE public.equipments OWNER TO postgres;

--
-- Name: TABLE equipments; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.equipments IS 'Master inventory register of laboratory instruments, analytical balances, chromatography systems, and spectrophotometers. Tracks physical location, serial numbers, calibration schedules, and operational readiness under ISO/IEC 17025 and 21 CFR Part 211.';


--
-- Name: COLUMN equipments.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipments.id IS 'Primary key. Unique 64-bit integer identifier for the equipment asset.';


--
-- Name: COLUMN equipments.equipment_code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipments.equipment_code IS 'Unique laboratory internal asset tag or barcode (2 to 20 characters, e.g., ''BAL-001'', ''HPLC-UV-03''). Used on sample worksheets and equipment selection dialogs.';


--
-- Name: COLUMN equipments.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipments.name IS 'Descriptive equipment title (2 to 100 characters, e.g., ''Analytical Balance XP205'', ''UV-Vis Spectrophotometer Evolution 300'').';


--
-- Name: COLUMN equipments.manufacturer; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipments.manufacturer IS 'Name of the equipment manufacturer or OEM (maximum 100 characters, e.g., ''Mettler Toledo'', ''Waters'', ''Agilent'').';


--
-- Name: COLUMN equipments.model; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipments.model IS 'Manufacturer model number or instrument family (maximum 100 characters, e.g., ''Alliance e2695'', ''XS204'').';


--
-- Name: COLUMN equipments.serial_number; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipments.serial_number IS 'Unique manufacturer serial number (maximum 100 characters). Enforces instrument hardware identity.';


--
-- Name: COLUMN equipments.location; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipments.location IS 'Laboratory room, bench, or cleanroom zone where the instrument is installed (maximum 100 characters, e.g., ''QC Phys-Chem Room 204'').';


--
-- Name: COLUMN equipments.status_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipments.status_id IS 'Foreign key referencing public.equipment_statuses(id). Operational state of the instrument. Automatically set to ''Active'' when a successful calibration is recorded in EquipmentsService.AddEquipmentCalibration.';


--
-- Name: COLUMN equipments.calibration_interval_days; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipments.calibration_interval_days IS 'Number of days between required periodic recalibrations (integer, defaults to 365 days / 1 year).';


--
-- Name: COLUMN equipments.next_calibration_due; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipments.next_calibration_due IS 'Calendar date when the instrument must next undergo calibration. Automatically updated from the expiration_date of the most recently recorded calibration certificate.';


--
-- Name: COLUMN equipments.date_created; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipments.date_created IS 'Timestamp with time zone when the equipment asset was registered in the database. Defaults to clock_timestamp().';


--
-- Name: equipment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.equipments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.equipment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: equipment_statuses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipment_statuses (
    id bigint NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.equipment_statuses OWNER TO postgres;

--
-- Name: TABLE equipment_statuses; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.equipment_statuses IS 'Lookup catalog for operational status of analytical laboratory instruments: 1 = ''Active'' (calibrated, qualified, and authorized for routine testing), 2 = ''Inactive'' (standby or temporarily decommissioned), 3 = ''Calibration Due'' (calibration overdue, locked from testing), 4 = ''Out of Service'' (defective, undergoing repair, or failed calibration).';


--
-- Name: COLUMN equipment_statuses.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipment_statuses.id IS 'Primary key. Unique identifier for the equipment operational status.';


--
-- Name: COLUMN equipment_statuses.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipment_statuses.name IS 'Unique status name (''Active'', ''Inactive'', ''Calibration Due'', ''Out of Service'').';


--
-- Name: form_condition_evals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.form_condition_evals (
    id bigint NOT NULL,
    form_id bigint NOT NULL,
    test_id bigint NOT NULL,
    value numeric NOT NULL,
    result numeric,
    expected_result numeric NOT NULL,
    is_match boolean DEFAULT false NOT NULL,
    note character varying(20)
);


ALTER TABLE public.form_condition_evals OWNER TO postgres;

--
-- Name: TABLE form_condition_evals; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.form_condition_evals IS 'Benchmark test cases verifying parameter condition logic (form_params.condition). Validates that conditional acceptance rules correctly yield 1 (pass) or 0 (fail) against known test input values.';


--
-- Name: COLUMN form_condition_evals.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_condition_evals.id IS 'Primary key. Unique 64-bit integer identifier for the condition evaluation test row.';


--
-- Name: COLUMN form_condition_evals.form_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_condition_evals.form_id IS 'Foreign key referencing public.forms(id). The parent form template.';


--
-- Name: COLUMN form_condition_evals.test_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_condition_evals.test_id IS 'Foreign key referencing public.tests(id). The parameter whose condition is being verified.';


--
-- Name: COLUMN form_condition_evals.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_condition_evals.value IS 'Test input value passed into the condition expression.';


--
-- Name: COLUMN form_condition_evals.result; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_condition_evals.result IS 'Actual boolean outcome evaluated by the rule engine (1 for true/conforming, 0 for false/non-conforming).';


--
-- Name: COLUMN form_condition_evals.expected_result; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_condition_evals.expected_result IS 'Expected outcome (1 for pass, 0 for fail) specified by the form author.';


--
-- Name: COLUMN form_condition_evals.is_match; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_condition_evals.is_match IS 'Boolean flag. True indicates result matches expected_result.';


--
-- Name: COLUMN form_condition_evals.note; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_condition_evals.note IS 'Short explanation of the test condition boundary (maximum 20 characters, e.g., ''Upper limit'', ''Nominal pass'').';


--
-- Name: form_condition_evals_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.form_condition_evals ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.form_condition_evals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: form_eval_params; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.form_eval_params (
    eval_id bigint NOT NULL,
    form_id bigint NOT NULL,
    test_id bigint NOT NULL,
    idx integer NOT NULL,
    value numeric,
    expected_value numeric,
    is_match boolean DEFAULT false NOT NULL
);


ALTER TABLE public.form_eval_params OWNER TO postgres;

--
-- Name: TABLE form_eval_params; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.form_eval_params IS 'Input variables and expected calculated outputs for form validation test cases (form_evals). During form verification, the QCFormula engine calculates the actual results for all formulas and compares them against expected_value. If all match, is_match is stamped true.';


--
-- Name: COLUMN form_eval_params.eval_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_eval_params.eval_id IS 'Primary key and foreign key referencing public.form_evals(id). The parent validation test case.';


--
-- Name: COLUMN form_eval_params.form_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_eval_params.form_id IS 'Foreign key referencing public.forms(id). The form template.';


--
-- Name: COLUMN form_eval_params.test_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_eval_params.test_id IS 'Foreign key referencing public.tests(id). The parameter under test.';


--
-- Name: COLUMN form_eval_params.idx; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_eval_params.idx IS 'Primary key. Array determination index (0 for scalar parameters, 0..N for replicated array values).';


--
-- Name: COLUMN form_eval_params.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_eval_params.value IS 'Input test value (for manual parameters) or engine-calculated result (for formula parameters).';


--
-- Name: COLUMN form_eval_params.expected_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_eval_params.expected_value IS 'Authoritative pre-calculated benchmark value. Used to verify formula accuracy.';


--
-- Name: COLUMN form_eval_params.is_match; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_eval_params.is_match IS 'Boolean verification flag. True indicates the calculated formula result matches expected_value within tolerance.';


--
-- Name: form_evals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.form_evals (
    id bigint NOT NULL,
    form_id bigint NOT NULL,
    description text
);


ALTER TABLE public.form_evals OWNER TO postgres;

--
-- Name: TABLE form_evals; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.form_evals IS 'Validation benchmark test cases designed to prove the algorithmic accuracy of form formulas under 21 CFR Part 11 software verification rules. Before a form template can be validated (is_validated = true), all defined test cases must evaluate successfully without errors.';


--
-- Name: COLUMN form_evals.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_evals.id IS 'Primary key. Unique 64-bit integer identifier for the validation test case.';


--
-- Name: COLUMN form_evals.form_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_evals.form_id IS 'Foreign key referencing public.forms(id). The form template being verified.';


--
-- Name: COLUMN form_evals.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_evals.description IS 'Descriptive title or test scenario name (e.g., ''Nominal standard weight test case'', ''Boundary condition - maximum LOD'').';


--
-- Name: form_evals_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.form_evals ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.form_evals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: form_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.form_groups (
    id bigint NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    is_form_validated boolean DEFAULT false NOT NULL,
    nr_ord bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.form_groups OWNER TO postgres;

--
-- Name: TABLE form_groups; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.form_groups IS 'Logical family or category of dynamic analytical worksheet forms (e.g., ''Dissolution Testing Forms'', ''Heavy Metals Assay Forms'', ''Loss on Drying Forms''). Controls overarching validation status across form versions.';


--
-- Name: COLUMN form_groups.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_groups.id IS 'Primary key. Unique 64-bit integer identifier for the form group.';


--
-- Name: COLUMN form_groups.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_groups.name IS 'Unique name of the form family (3 to 50 characters). Validated for uniqueness via FormGroupDialog.tsx.';


--
-- Name: COLUMN form_groups.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_groups.description IS 'Optional extended description of the testing domain and analytical methodologies handled by this form group.';


--
-- Name: COLUMN form_groups.is_form_validated; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_groups.is_form_validated IS 'Boolean status flag. Automatically updated to true when any form version within this group achieves validation approval (FormsService.ValidateForm). Signals that test definitions associated with this group are locked from structurally breaking changes.';


--
-- Name: COLUMN form_groups.nr_ord; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_groups.nr_ord IS 'Numeric display order index (defaults to 0) controlling grouping sequence in client menus.';


--
-- Name: form_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.form_groups ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.form_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: form_params; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.form_params (
    form_id bigint NOT NULL,
    test_id bigint NOT NULL,
    is_calculated boolean DEFAULT false NOT NULL,
    formula text,
    formula_dependencies text,
    code_related_arrays character varying(50),
    has_condition boolean DEFAULT false NOT NULL,
    condition character varying(255),
    condition_note character varying(150),
    is_required boolean DEFAULT false NOT NULL,
    default_value numeric,
    nr_ord_calc bigint DEFAULT 0 NOT NULL,
    nr_ord bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.form_params OWNER TO postgres;

--
-- Name: TABLE form_params; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.form_params IS 'Parameter definitions within a form template. Maps analytical tests (tests) into form fields as raw inputs or calculated formulas. Defines mathematical expressions evaluated by QCFormula, topological evaluation order (nr_ord_calc), array relationships, and conditional pass/fail criteria.';


--
-- Name: COLUMN form_params.form_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_params.form_id IS 'Primary key and foreign key referencing public.forms(id). The parent form template.';


--
-- Name: COLUMN form_params.test_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_params.test_id IS 'Primary key and foreign key referencing public.tests(id). The analytical test or parameter mapped to this form field.';


--
-- Name: COLUMN form_params.is_calculated; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_params.is_calculated IS 'Boolean flag indicating whether this parameter is derived via a mathematical formula (true) or entered as a manual raw measurement (false).';


--
-- Name: COLUMN form_params.formula; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_params.formula IS 'Mathematical expression evaluated by the QCFormula ANTLR engine (e.g., ''ROUND(([tare_plus_sample] - [tare_dry]) / [sample_mass] * 100, 4)''). References scalar parameters as [code] and array parameters as [[code]]. Mandatory if is_calculated is true.';


--
-- Name: COLUMN form_params.formula_dependencies; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_params.formula_dependencies IS 'Extracted list of test variable codes upon which this formula depends. Populated automatically by the QCFormula dependency resolver.';


--
-- Name: COLUMN form_params.code_related_arrays; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_params.code_related_arrays IS 'Test code string (maximum 50 characters) identifying an associated array test if this calculation parameter aggregates or relates to array determinations.';


--
-- Name: COLUMN form_params.has_condition; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_params.has_condition IS 'Boolean flag indicating that this parameter possesses an acceptance rule / condition. In FormParamDialog.tsx, when true, condition and condition_note are mandatory, and at least one condition evaluation verification test case is required.';


--
-- Name: COLUMN form_params.condition; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_params.condition IS 'Boolean condition expression (maximum 255 characters, e.g., ''[value] >= 95.0 && [value] <= 105.0''). Validated via FormsService.ValidateCondition.';


--
-- Name: COLUMN form_params.condition_note; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_params.condition_note IS 'Human-readable specification note or warning text displayed if the condition is not met (maximum 150 characters, e.g., ''Between 95.0% and 105.0%'').';


--
-- Name: COLUMN form_params.is_required; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_params.is_required IS 'Boolean flag specifying whether a value for this parameter is strictly required before the worksheet can be completed.';


--
-- Name: COLUMN form_params.default_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_params.default_value IS 'Default preset numeric value (e.g., 1.000 for standard volume, or 0).';


--
-- Name: COLUMN form_params.nr_ord_calc; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_params.nr_ord_calc IS 'Topological calculation sequence order. Derived automatically by resolving the Directed Acyclic Graph (DAG) of formula dependencies. Formulas are evaluated strictly in ascending order of nr_ord_calc to guarantee all dependent inputs are calculated prior to consumption.';


--
-- Name: COLUMN form_params.nr_ord; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.form_params.nr_ord IS 'Visual display sequence order controlling the arrangement of parameter input rows in the user interface.';


--
-- Name: forms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forms (
    id bigint NOT NULL,
    form_group_id bigint NOT NULL,
    version character varying(50) NOT NULL,
    days_active_for_editing integer DEFAULT 10 NOT NULL,
    is_customized boolean DEFAULT false NOT NULL,
    custom_nav text,
    is_submitted boolean DEFAULT false NOT NULL,
    user_submitted_id bigint,
    date_submitted timestamp with time zone,
    comments_submitted text,
    is_validated boolean DEFAULT false NOT NULL,
    user_validated_id bigint,
    date_validated timestamp with time zone,
    comments_validated text,
    is_cancelled boolean DEFAULT false NOT NULL,
    user_cancelled_id bigint,
    date_cancelled timestamp with time zone,
    comments_cancelled text
);


ALTER TABLE public.forms OWNER TO postgres;

--
-- Name: TABLE forms; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.forms IS 'Version-controlled dynamic analytical worksheet templates. Encapsulates formula calculation graphs, topological evaluation orders, conditional rules, and software validation datasets. Enforces GxP lifecycle state progression: Draft -> Submitted -> Validated -> Cancelled, accompanied by 21 CFR Part 11 electronic signatures.';


--
-- Name: COLUMN forms.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.id IS 'Primary key. Unique 64-bit integer identifier for the form template.';


--
-- Name: COLUMN forms.form_group_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.form_group_id IS 'Foreign key referencing public.form_groups(id). The parent group / test family to which this form template belongs.';


--
-- Name: COLUMN forms.version; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.version IS 'Version number string (maximum 50 characters, e.g., ''1.0'', ''2.1''). Unique per form group.';


--
-- Name: COLUMN forms.days_active_for_editing; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.days_active_for_editing IS 'Grace period in days (integer, defaults to 10) during which a worksheet instance generated from this form remains editable. Once this elapsed time expires following creation, the worksheet automatically becomes locked (is_readonly = true).';


--
-- Name: COLUMN forms.is_customized; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.is_customized IS 'Boolean flag indicating that this form relies on a dedicated, specialized frontend UI component rather than standard auto-rendered grid layout. In FormDialog.tsx, when checked, custom_nav is mandatory.';


--
-- Name: COLUMN forms.custom_nav; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.custom_nav IS 'Frontend component route or navigation tag (e.g., ''TestingFormA'') defining the custom layout renderer. Mandatory if is_customized is true; nullable if standard generic rendering is used.';


--
-- Name: COLUMN forms.is_submitted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.is_submitted IS 'Boolean lifecycle flag. True indicates the form template has been finalized and submitted for formal verification.';


--
-- Name: COLUMN forms.user_submitted_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.user_submitted_id IS 'Foreign key referencing public.users(id) (nullable). The form author who submitted the template.';


--
-- Name: COLUMN forms.date_submitted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.date_submitted IS 'Timestamp with time zone when the form was submitted.';


--
-- Name: COLUMN forms.comments_submitted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.comments_submitted IS 'Author notes, design rationale, or change summary recorded at submission.';


--
-- Name: COLUMN forms.is_validated; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.is_validated IS 'Boolean approval flag. When true, the form is validated for routine production testing. Validation requires that all verification test cases (form_evals) PASS. Approving a form creates an electronic signature, marks form_groups.is_form_validated = true, and locks tests.is_form_validated = true for all referenced tests.';


--
-- Name: COLUMN forms.user_validated_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.user_validated_id IS 'Foreign key referencing public.users(id) (nullable). The QC supervisor / system owner who validated and approved the form.';


--
-- Name: COLUMN forms.date_validated; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.date_validated IS 'Timestamp with time zone when validation approval was granted.';


--
-- Name: COLUMN forms.comments_validated; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.comments_validated IS 'Formal validation approval remarks recorded by the QC reviewer.';


--
-- Name: COLUMN forms.is_cancelled; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.is_cancelled IS 'Boolean lifecycle flag. True indicates the form template was cancelled or superseded. Cancelled forms cannot be selected for new sample receptions or measurements.';


--
-- Name: COLUMN forms.user_cancelled_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.user_cancelled_id IS 'Foreign key referencing public.users(id) (nullable). The user who cancelled the form template.';


--
-- Name: COLUMN forms.date_cancelled; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.date_cancelled IS 'Timestamp with time zone when the form was cancelled.';


--
-- Name: COLUMN forms.comments_cancelled; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.forms.comments_cancelled IS 'Mandatory documented justification explaining why the form was cancelled.';


--
-- Name: forms_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.forms ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.forms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: material_tests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.material_tests (
    material_id bigint NOT NULL,
    test_id bigint NOT NULL
);


ALTER TABLE public.material_tests OWNER TO postgres;

--
-- Name: TABLE material_tests; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.material_tests IS 'Many-to-many junction table associating candidate analytical tests with a material. Represents the universe of tests that can be configured on specifications or performed on samples of this material. Restricted to non-parameter tests (is_param = false).';


--
-- Name: COLUMN material_tests.material_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.material_tests.material_id IS 'Primary key and foreign key referencing public.materials(id). The material to which the test is assigned.';


--
-- Name: COLUMN material_tests.test_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.material_tests.test_id IS 'Primary key and foreign key referencing public.tests(id). The analytical test eligible to be performed on the material.';


--
-- Name: materials; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.materials (
    id bigint NOT NULL,
    name character varying(50) NOT NULL,
    code character varying(10) NOT NULL,
    description text,
    norm_id bigint,
    is_product boolean DEFAULT false NOT NULL,
    is_raw_material boolean DEFAULT false NOT NULL,
    is_reagent boolean DEFAULT false NOT NULL,
    is_certified_reference boolean DEFAULT false NOT NULL,
    cas_number character varying(20),
    date_created timestamp with time zone NOT NULL,
    is_obsolete boolean DEFAULT false NOT NULL,
    date_obsolete timestamp with time zone,
    comments_obsolete text
);


ALTER TABLE public.materials OWNER TO postgres;

--
-- Name: TABLE materials; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.materials IS 'Master item catalog covering manufactured finished products, raw materials, intermediates, chemical reagents, and certified reference materials (CRMs). Dictates whether an item undergoes standard QC release testing, is tracked as a reagent in lab inventory, or requires strict metrological traceability.';


--
-- Name: COLUMN materials.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.materials.id IS 'Primary key. Unique 64-bit integer identifier for the material.';


--
-- Name: COLUMN materials.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.materials.name IS 'Unique descriptive name of the material (3 to 50 characters, e.g., ''Aspirin Active Substance'', ''Ethanol 96%'', ''Potassium Dichromate CRM''). Validated for uniqueness on the server and client.';


--
-- Name: COLUMN materials.code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.materials.code IS 'Unique uppercase alphanumeric material code (2 to 10 characters, regex /^[A-Z][A-Z0-9]*$/). Used for inventory identification and batch code generation.';


--
-- Name: COLUMN materials.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.materials.description IS 'Optional text notes detailing chemical grade, storage conditions, or physical specifications.';


--
-- Name: COLUMN materials.norm_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.materials.norm_id IS 'Foreign key referencing public.norms(id) (nullable). Identifies the primary pharmacopeial monograph or compendial standard governing this material.';


--
-- Name: COLUMN materials.is_product; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.materials.is_product IS 'Boolean flag designating the item as a manufactured finished product eligible for production release and customer Certificate of Analysis generation.';


--
-- Name: COLUMN materials.is_raw_material; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.materials.is_raw_material IS 'Boolean flag designating the item as an incoming raw material, active substance, or excipient requiring intake QC verification.';


--
-- Name: COLUMN materials.is_reagent; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.materials.is_reagent IS 'Boolean flag designating the item as a laboratory chemical reagent or volumetric solution. Reagents are filtered out in general views unless the user possesses lab or QC roles (is_lab_pers or is_qc_pers). Managed via ReagentsPage.tsx and reagent_lots.';


--
-- Name: COLUMN materials.is_certified_reference; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.materials.is_certified_reference IS 'Boolean flag indicating that this material is a Certified Reference Material (CRM) requiring strict metrological traceability and certificate of analysis validation under ISO 17034 / ISO/IEC 17025.';


--
-- Name: COLUMN materials.cas_number; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.materials.cas_number IS 'Chemical Abstracts Service (CAS) registry number (maximum 20 characters, e.g., ''50-78-2'' for Acetylsalicylic acid). Used primarily for chemical identification and reagent safety.';


--
-- Name: COLUMN materials.date_created; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.materials.date_created IS 'Timestamp with time zone when the material was registered in the database.';


--
-- Name: COLUMN materials.is_obsolete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.materials.is_obsolete IS 'Soft-deletion flag. Set via MaterialsService.ToggleObsolete. When true, prevents initiating new sample receptions or specifications. Setting to true stamps date_obsolete with UTC timestamp and stores comments_obsolete; reactivating clears both fields to NULL.';


--
-- Name: COLUMN materials.date_obsolete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.materials.date_obsolete IS 'Timestamp with time zone when the material was retired. Cleared to NULL if reactivated.';


--
-- Name: COLUMN materials.comments_obsolete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.materials.comments_obsolete IS 'Mandatory documented justification explaining why the material was marked obsolete. Cleared to NULL if reactivated.';


--
-- Name: materials_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.materials ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.materials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: measurements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.measurements (
    id bigint NOT NULL,
    reception_id bigint NOT NULL,
    form_id bigint,
    comments text,
    use_default_equipment boolean DEFAULT true NOT NULL,
    is_reported boolean DEFAULT false NOT NULL,
    user_reported_id bigint,
    date_reported timestamp with time zone,
    is_readonly boolean DEFAULT false NOT NULL,
    date_readonly timestamp with time zone,
    user_updated_id bigint,
    date_updated timestamp with time zone,
    user_created_id bigint NOT NULL,
    date_created timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE public.measurements OWNER TO postgres;

--
-- Name: TABLE measurements; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.measurements IS 'Laboratory testing worksheet execution sessions. Records raw observations, formula evaluations, and test results for a sample reception. Captures exact instrument serial numbers, chemical reagent lots, and SOP revisions used during execution. Enforces automatic read-only locking upon report inclusion or expiration of form editing days.';


--
-- Name: COLUMN measurements.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurements.id IS 'Primary key. Unique 64-bit integer identifier for the measurement worksheet session.';


--
-- Name: COLUMN measurements.reception_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurements.reception_id IS 'Foreign key referencing public.receptions(id). The sample reception being analyzed.';


--
-- Name: COLUMN measurements.form_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurements.form_id IS 'Foreign key referencing public.forms(id) (nullable). The structured dynamic form template used for executing calculations, if applicable.';


--
-- Name: COLUMN measurements.comments; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurements.comments IS 'Analyst bench notes, environmental conditions, or procedural observations recorded during worksheet execution.';


--
-- Name: COLUMN measurements.use_default_equipment; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurements.use_default_equipment IS 'Boolean flag (defaults to true). When true, the worksheet utilizes the standard instruments defined in test_equipments; when false, analyst custom-selects specific instrument assets stored in measurement_equipments.';


--
-- Name: COLUMN measurements.is_reported; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurements.is_reported IS 'Boolean status flag. True indicates that the test results from this worksheet have been included into a formal submitted test report (reports). Prevents subsequent tampering with raw data.';


--
-- Name: COLUMN measurements.user_reported_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurements.user_reported_id IS 'Foreign key referencing public.users(id) (nullable). The user who incorporated this measurement session into a test report.';


--
-- Name: COLUMN measurements.date_reported; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurements.date_reported IS 'Timestamp with time zone when the results were reported.';


--
-- Name: COLUMN measurements.is_readonly; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurements.is_readonly IS 'Boolean lock flag (defaults to false). Automatically set to true when results are reported or after forms.days_active_for_editing has elapsed. Locks all child measurement_tests and measurement_params from modification.';


--
-- Name: COLUMN measurements.date_readonly; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurements.date_readonly IS 'Timestamp with time zone when the worksheet was transitioned to read-only status.';


--
-- Name: COLUMN measurements.user_updated_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurements.user_updated_id IS 'Foreign key referencing public.users(id) (nullable). The user who performed the most recent edit.';


--
-- Name: COLUMN measurements.date_updated; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurements.date_updated IS 'Timestamp with time zone of the most recent worksheet modification.';


--
-- Name: COLUMN measurements.user_created_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurements.user_created_id IS 'Foreign key referencing public.users(id). The laboratory analyst who initiated the measurement worksheet.';


--
-- Name: COLUMN measurements.date_created; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurements.date_created IS 'Timestamp with time zone when the worksheet session was created. Defaults to clock_timestamp().';


--
-- Name: measurement_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.measurements ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.measurement_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: measurement_equipments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.measurement_equipments (
    measurement_id bigint NOT NULL,
    equipment_id bigint NOT NULL
);


ALTER TABLE public.measurement_equipments OWNER TO postgres;

--
-- Name: TABLE measurement_equipments; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.measurement_equipments IS 'Many-to-many junction table logging the specific laboratory instruments and balances (equipments) utilized during a measurement worksheet session. Guarantees complete hardware traceability for ISO/IEC 17025 audits.';


--
-- Name: COLUMN measurement_equipments.measurement_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_equipments.measurement_id IS 'Primary key and foreign key referencing public.measurements(id). The testing worksheet session.';


--
-- Name: COLUMN measurement_equipments.equipment_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_equipments.equipment_id IS 'Primary key and foreign key referencing public.equipments(id). The instrument utilized during the test.';


--
-- Name: measurement_params; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.measurement_params (
    measurement_id bigint NOT NULL,
    form_id bigint NOT NULL,
    test_id bigint NOT NULL,
    idx integer DEFAULT 0 NOT NULL,
    value numeric NOT NULL,
    is_conforming_condition boolean DEFAULT false NOT NULL,
    certified_reference_certificate_id bigint,
    certified_reference_control_code_id bigint,
    user_updated_id bigint,
    date_updated timestamp with time zone,
    user_created_id bigint NOT NULL,
    date_created timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE public.measurement_params OWNER TO postgres;

--
-- Name: TABLE measurement_params; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.measurement_params IS 'Intermediate calculation variables and raw parameter inputs captured during dynamic form worksheet execution. Maintains parameter-level acceptance status (is_conforming_condition) and metrological links to Certified Reference Materials (CRMs).';


--
-- Name: COLUMN measurement_params.measurement_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_params.measurement_id IS 'Primary key and foreign key referencing public.measurements(id). The parent worksheet session.';


--
-- Name: COLUMN measurement_params.form_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_params.form_id IS 'Primary key and foreign key referencing public.forms(id). The active form template.';


--
-- Name: COLUMN measurement_params.test_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_params.test_id IS 'Primary key and foreign key referencing public.tests(id). The specific parameter test definition.';


--
-- Name: COLUMN measurement_params.idx; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_params.idx IS 'Primary key. Array determination index (0 for scalar parameters, 0..N for array inputs).';


--
-- Name: COLUMN measurement_params.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_params.value IS 'Input raw measurement value or formula-calculated intermediate result.';


--
-- Name: COLUMN measurement_params.is_conforming_condition; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_params.is_conforming_condition IS 'Boolean status flag. True indicates the parameter satisfies the conditional acceptance rule defined in form_params.condition.';


--
-- Name: COLUMN measurement_params.certified_reference_certificate_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_params.certified_reference_certificate_id IS 'Foreign key referencing public.certificates(id) (nullable). Populated when this parameter value is calibrated against or sourced from an internal Quality Certificate for a certified reference batch via SelectCrmDialog.tsx.';


--
-- Name: COLUMN measurement_params.certified_reference_control_code_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_params.certified_reference_control_code_id IS 'Foreign key referencing public.control_codes(id) (nullable). Populated when this parameter value is sourced from a supplier CRM reagent lot Certificate of Analysis (reagent_supplier_lot_cert_tests) via SelectCrmDialog.tsx.';


--
-- Name: COLUMN measurement_params.user_updated_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_params.user_updated_id IS 'Foreign key referencing public.users(id) (nullable). The user who last edited this parameter value.';


--
-- Name: COLUMN measurement_params.date_updated; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_params.date_updated IS 'Timestamp with time zone of the most recent parameter edit.';


--
-- Name: COLUMN measurement_params.user_created_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_params.user_created_id IS 'Foreign key referencing public.users(id). The user who originally recorded the parameter.';


--
-- Name: COLUMN measurement_params.date_created; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_params.date_created IS 'Timestamp with time zone when the parameter was created. Defaults to clock_timestamp().';


--
-- Name: measurement_reagent_lots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.measurement_reagent_lots (
    measurement_id bigint NOT NULL,
    control_code_id bigint NOT NULL
);


ALTER TABLE public.measurement_reagent_lots OWNER TO postgres;

--
-- Name: TABLE measurement_reagent_lots; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.measurement_reagent_lots IS 'Many-to-many junction table recording the chemical reagent lots and volumetric solutions (control_codes) consumed during a measurement worksheet session. Guarantees chemical consumable traceability.';


--
-- Name: COLUMN measurement_reagent_lots.measurement_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_reagent_lots.measurement_id IS 'Primary key and foreign key referencing public.measurements(id). The testing worksheet session.';


--
-- Name: COLUMN measurement_reagent_lots.control_code_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_reagent_lots.control_code_id IS 'Primary key and foreign key referencing public.control_codes(id). The specific reagent lot consumed during testing.';


--
-- Name: measurement_sop_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.measurement_sop_versions (
    measurement_id bigint NOT NULL,
    sop_version_id bigint NOT NULL
);


ALTER TABLE public.measurement_sop_versions OWNER TO postgres;

--
-- Name: TABLE measurement_sop_versions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.measurement_sop_versions IS 'Many-to-many junction table capturing the exact revisions of Standard Operating Procedures (sop_versions) followed by the analyst during execution of a measurement worksheet. Ensures procedural compliance traceability.';


--
-- Name: COLUMN measurement_sop_versions.measurement_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_sop_versions.measurement_id IS 'Primary key and foreign key referencing public.measurements(id). The testing worksheet session.';


--
-- Name: COLUMN measurement_sop_versions.sop_version_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_sop_versions.sop_version_id IS 'Primary key and foreign key referencing public.sop_versions(id). The active SOP revision utilized for the test execution.';


--
-- Name: measurement_tests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.measurement_tests (
    measurement_id bigint NOT NULL,
    test_id bigint NOT NULL,
    idx integer DEFAULT 0 NOT NULL,
    value numeric NOT NULL,
    note character varying(20),
    user_updated_id bigint,
    date_updated timestamp with time zone,
    user_created_id bigint NOT NULL,
    date_created timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE public.measurement_tests OWNER TO postgres;

--
-- Name: TABLE measurement_tests; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.measurement_tests IS 'Final measured test results recorded during a worksheet session. Supports both scalar results (idx = 0) and multi-replicate array results (idx = 0..N). Serves as the raw data source for testing reports (report_tests) and quality certificates (certificate_tests).';


--
-- Name: COLUMN measurement_tests.measurement_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_tests.measurement_id IS 'Primary key and foreign key referencing public.measurements(id). The parent worksheet execution session.';


--
-- Name: COLUMN measurement_tests.test_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_tests.test_id IS 'Primary key and foreign key referencing public.tests(id). The analytical test whose result was determined.';


--
-- Name: COLUMN measurement_tests.idx; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_tests.idx IS 'Primary key. Numeric replicate index (0 for scalar tests, 0..N for replicated array determinations).';


--
-- Name: COLUMN measurement_tests.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_tests.value IS 'The measured numerical result (or encoded enum key from test_enums). Captured via MeasurementTestDialog.tsx or auto-calculated from form parameters.';


--
-- Name: COLUMN measurement_tests.note; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_tests.note IS 'Short analyst footnote or qualitative observation (maximum 20 characters, e.g., ''Re-injected'', ''Outlier rejected'').';


--
-- Name: COLUMN measurement_tests.user_updated_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_tests.user_updated_id IS 'Foreign key referencing public.users(id) (nullable). The user who last updated this test value.';


--
-- Name: COLUMN measurement_tests.date_updated; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_tests.date_updated IS 'Timestamp with time zone when this test value was last updated.';


--
-- Name: COLUMN measurement_tests.user_created_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_tests.user_created_id IS 'Foreign key referencing public.users(id). The analyst who recorded the initial measurement.';


--
-- Name: COLUMN measurement_tests.date_created; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.measurement_tests.date_created IS 'Timestamp with time zone when the measurement was originally logged. Defaults to clock_timestamp().';


--
-- Name: norms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.norms (
    id bigint NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    date_created timestamp with time zone NOT NULL,
    is_obsolete boolean DEFAULT false NOT NULL,
    date_obsolete timestamp with time zone,
    comments_obsolete text
);


ALTER TABLE public.norms OWNER TO postgres;

--
-- Name: TABLE norms; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.norms IS 'Compendial standards, pharmacopeias, or regulatory references (e.g., ''USP 43'', ''Ph. Eur. 10'', ''ISO/IEC 17025'', ''ASTM D1298'', ''Internal QC Standard''). Provides governing normative authority for test methods, specifications, and standard operating procedures (SOPs).';


--
-- Name: COLUMN norms.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.norms.id IS 'Primary key. Unique 64-bit integer identifier for the norm record.';


--
-- Name: COLUMN norms.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.norms.name IS 'Unique title or designation of the governing standard (3 to 50 characters). Validated for uniqueness in NormDialog.tsx.';


--
-- Name: COLUMN norms.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.norms.description IS 'Detailed description of the standard, governing body, publication edition, or scope.';


--
-- Name: COLUMN norms.date_created; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.norms.date_created IS 'Timestamp with time zone when the norm was registered.';


--
-- Name: COLUMN norms.is_obsolete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.norms.is_obsolete IS 'Soft-deletion flag. When true, prevents associating this norm with new materials, tests, or SOPs.';


--
-- Name: COLUMN norms.date_obsolete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.norms.date_obsolete IS 'Timestamp with time zone when the norm was marked obsolete. Cleared to NULL if reactivated.';


--
-- Name: COLUMN norms.comments_obsolete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.norms.comments_obsolete IS 'Documented justification explaining why the norm is no longer valid or applicable. Cleared to NULL if reactivated.';


--
-- Name: norms_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.norms ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.norms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: reagent_lot_statuses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reagent_lot_statuses (
    id bigint NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.reagent_lot_statuses OWNER TO postgres;

--
-- Name: TABLE reagent_lot_statuses; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.reagent_lot_statuses IS 'Lifecycle status lookup table for physical laboratory reagent lots: 1 = ''Quarantined'' (pending incoming inspection or CoA verification), 2 = ''Active'' (approved for use in testing and production), 3 = ''Expired'' (past manufacturer expiration date, locked from usage), 4 = ''Depleted'' (inventory exhausted). Only lots in ''Active'' status can be consumed in measurement worksheets or used as ingredients in lab preparations.';


--
-- Name: COLUMN reagent_lot_statuses.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_lot_statuses.id IS 'Primary key. Numeric identifier corresponding to the reagent lot status.';


--
-- Name: COLUMN reagent_lot_statuses.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_lot_statuses.name IS 'Unique name of the lot status (''Quarantined'', ''Active'', ''Expired'', ''Depleted'').';


--
-- Name: reagent_lots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reagent_lots (
    control_code_id bigint NOT NULL,
    is_produced boolean DEFAULT false NOT NULL,
    produced_by_user_id bigint,
    status_id bigint DEFAULT 1 NOT NULL,
    quantity numeric NOT NULL,
    unit_id bigint,
    expiration_date date NOT NULL
);


ALTER TABLE public.reagent_lots OWNER TO postgres;

--
-- Name: TABLE reagent_lots; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.reagent_lots IS 'Core inventory table tracking physical containers and batches of chemical reagents, volumetric solutions, and standards in the laboratory. Each lot is identified by a control_code_id. Differentiates purchased vendor lots from in-house prepared solutions (is_produced). Enforces expiration date controls and stock balances.';


--
-- Name: COLUMN reagent_lots.control_code_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_lots.control_code_id IS 'Primary key and foreign key referencing public.control_codes(id). Serves as the unique tracking lot identifier for this physical batch.';


--
-- Name: COLUMN reagent_lots.is_produced; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_lots.is_produced IS 'Boolean flag distinguishing in-house prepared reagents (true) from commercially purchased supplier lots (false). When true, produced_by_user_id and ingredient relationships in reagent_production_lots are enabled.';


--
-- Name: COLUMN reagent_lots.produced_by_user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_lots.produced_by_user_id IS 'Foreign key referencing public.users(id) (nullable). The laboratory analyst who formulated or prepared the reagent solution. Populated only when is_produced is true.';


--
-- Name: COLUMN reagent_lots.status_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_lots.status_id IS 'Foreign key referencing public.reagent_lot_statuses(id) (defaults to 1 = ''Quarantined''). Only lots in status 2 (''Active'') can be selected as worksheet consumables or production ingredients.';


--
-- Name: COLUMN reagent_lots.quantity; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_lots.quantity IS 'Numeric stock quantity remaining in inventory (e.g., 500.0). Enforced to be non-negative on the client and server.';


--
-- Name: COLUMN reagent_lots.unit_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_lots.unit_id IS 'Foreign key referencing public.units(id) (nullable). Specifies the unit of measurement for stock inventory (e.g., ''mL'', ''g'', ''L'').';


--
-- Name: COLUMN reagent_lots.expiration_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_lots.expiration_date IS 'Calendar date when the reagent lot expires. The system blocks using expired lots in analytical testing.';


--
-- Name: reagent_production_lots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reagent_production_lots (
    control_code_id bigint NOT NULL,
    ingredient_control_code_id bigint NOT NULL
);


ALTER TABLE public.reagent_production_lots OWNER TO postgres;

--
-- Name: TABLE reagent_production_lots; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.reagent_production_lots IS 'Genealogy / Bill of Materials (BOM) junction table tracking internal laboratory reagent preparation. Associates an in-house produced reagent lot with the parent ingredient reagent lots consumed in its preparation. In ProductionLotDialog.tsx, circular dependencies (selecting the lot itself as an ingredient) are strictly prevented, and only active lots (status_id = 2) are eligible for selection.';


--
-- Name: COLUMN reagent_production_lots.control_code_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_production_lots.control_code_id IS 'Primary key and foreign key referencing public.control_codes(id). Identifies the newly prepared/produced child reagent lot.';


--
-- Name: COLUMN reagent_production_lots.ingredient_control_code_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_production_lots.ingredient_control_code_id IS 'Primary key and foreign key referencing public.control_codes(id). Identifies an active parent reagent lot consumed as an ingredient.';


--
-- Name: reagent_supplier_lot_cert_tests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reagent_supplier_lot_cert_tests (
    control_code_id bigint NOT NULL,
    test_id bigint NOT NULL,
    value numeric NOT NULL,
    uncertainty_value numeric,
    coverage_factor_k numeric,
    traceability_statement text
);


ALTER TABLE public.reagent_supplier_lot_cert_tests OWNER TO postgres;

--
-- Name: TABLE reagent_supplier_lot_cert_tests; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.reagent_supplier_lot_cert_tests IS 'Certified reference parameter values transcribed from manufacturer Certificates of Analysis (CoA) for Certified Reference Materials (CRMs). Enables strict metrological traceability under ISO 17034 and ISO/IEC 17025. When executing a worksheet with CRM-dependent parameters (tests.for_certified_reference = true), the analyst selects active values from this table via SelectCrmDialog.tsx.';


--
-- Name: COLUMN reagent_supplier_lot_cert_tests.control_code_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_supplier_lot_cert_tests.control_code_id IS 'Primary key and foreign key referencing public.control_codes(id). Identifies the supplier CRM reagent lot.';


--
-- Name: COLUMN reagent_supplier_lot_cert_tests.test_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_supplier_lot_cert_tests.test_id IS 'Primary key and foreign key referencing public.tests(id). The analytical property or analyte certified on the supplier CoA.';


--
-- Name: COLUMN reagent_supplier_lot_cert_tests.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_supplier_lot_cert_tests.value IS 'Certified reference numerical value stated on the manufacturer CoA (e.g., 99.98% purity, 0.1002 N titer).';


--
-- Name: COLUMN reagent_supplier_lot_cert_tests.uncertainty_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_supplier_lot_cert_tests.uncertainty_value IS 'Stated expanded measurement uncertainty U from the manufacturer certificate (e.g., 0.05).';


--
-- Name: COLUMN reagent_supplier_lot_cert_tests.coverage_factor_k; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_supplier_lot_cert_tests.coverage_factor_k IS 'Coverage factor k stated on the certificate (typically 2.0 for approx. 95% confidence interval).';


--
-- Name: COLUMN reagent_supplier_lot_cert_tests.traceability_statement; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_supplier_lot_cert_tests.traceability_statement IS 'Formal metrological traceability text transcribed from the CoA (maximum 500 characters, e.g., ''Traceable to NIST SRM 84k'').';


--
-- Name: reagent_supplier_lots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reagent_supplier_lots (
    control_code_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    catalog_number character varying(50),
    manufacturer_lot_number character varying(50) NOT NULL,
    certificate_of_analysis_ref character varying(255),
    comments character varying(255),
    is_readonly boolean DEFAULT false NOT NULL,
    date_readonly timestamp with time zone
);


ALTER TABLE public.reagent_supplier_lots OWNER TO postgres;

--
-- Name: TABLE reagent_supplier_lots; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.reagent_supplier_lots IS 'Specialization table for commercially purchased reagent lots (reagent_lots where is_produced = false). Maintains manufacturer traceability, vendor catalog numbers, manufacturer batch numbers, and Certificate of Analysis (CoA) references. Locked into read-only mode once utilized in certified worksheets.';


--
-- Name: COLUMN reagent_supplier_lots.control_code_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_supplier_lots.control_code_id IS 'Primary key and foreign key referencing public.control_codes(id) (and implicitly public.reagent_lots). Unique lot identifier.';


--
-- Name: COLUMN reagent_supplier_lots.supplier_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_supplier_lots.supplier_id IS 'Foreign key referencing public.reagent_suppliers(id). Identifies the vendor or manufacturer who supplied the batch. In SupplierLotDialog.tsx, user can either select an existing supplier or input a new one, which creates a new supplier record.';


--
-- Name: COLUMN reagent_supplier_lots.catalog_number; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_supplier_lots.catalog_number IS 'Vendor catalog or product article number (maximum 50 characters, e.g., ''1.00014.1000'').';


--
-- Name: COLUMN reagent_supplier_lots.manufacturer_lot_number; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_supplier_lots.manufacturer_lot_number IS 'Original manufacturer production lot number printed on the container label (maximum 50 characters).';


--
-- Name: COLUMN reagent_supplier_lots.certificate_of_analysis_ref; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_supplier_lots.certificate_of_analysis_ref IS 'Reference identifier, document number, or URL to the manufacturer''s Certificate of Analysis (maximum 255 characters).';


--
-- Name: COLUMN reagent_supplier_lots.comments; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_supplier_lots.comments IS 'Optional comments, container condition, or receiving notes (maximum 255 characters).';


--
-- Name: COLUMN reagent_supplier_lots.is_readonly; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_supplier_lots.is_readonly IS 'Boolean lock flag (defaults to false). Automatically set to true when the lot is consumed in approved/submitted testing worksheets or quality certificates to guarantee immutable historical records.';


--
-- Name: COLUMN reagent_supplier_lots.date_readonly; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_supplier_lots.date_readonly IS 'Timestamp with time zone when the record was locked against modifications.';


--
-- Name: reagent_suppliers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reagent_suppliers (
    id bigint NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.reagent_suppliers OWNER TO postgres;

--
-- Name: TABLE reagent_suppliers; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.reagent_suppliers IS 'Catalog of external commercial vendors, manufacturers, and distributors of laboratory reagents, solvents, standards, and chemicals (e.g., ''Merck'', ''Sigma-Aldrich'', ''Fisher Scientific'', ''VWR''). Can be selected from an existing list or created on-the-fly during supplier lot entry in SupplierLotDialog.tsx.';


--
-- Name: COLUMN reagent_suppliers.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_suppliers.id IS 'Primary key. Unique 64-bit integer identifier for the reagent supplier.';


--
-- Name: COLUMN reagent_suppliers.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reagent_suppliers.name IS 'Unique name of the supplier company (up to 50 characters). Validated for uniqueness via ReagentsService.ValidateSupplierUniqueness.';


--
-- Name: reagent_suppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.reagent_suppliers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.reagent_suppliers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: reception_tests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reception_tests (
    reception_id bigint NOT NULL,
    test_id bigint NOT NULL
);


ALTER TABLE public.reception_tests OWNER TO postgres;

--
-- Name: TABLE reception_tests; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.reception_tests IS 'Many-to-many junction table recording the analytical tests assigned to a specific sample reception. For Certification receptions, populated automatically with all active tests from the material''s submitted specification; for Verification receptions, populated from user selection in VerificationDialog.tsx; for Category Verification, populated from category_tests in CategoryVerificationDialog.tsx.';


--
-- Name: COLUMN reception_tests.reception_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reception_tests.reception_id IS 'Primary key and foreign key referencing public.receptions(id). The sample reception receiving the test assignments.';


--
-- Name: COLUMN reception_tests.test_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reception_tests.test_id IS 'Primary key and foreign key referencing public.tests(id). The analytical test scheduled to be performed on the sample.';


--
-- Name: reception_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reception_types (
    id bigint NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.reception_types OWNER TO postgres;

--
-- Name: TABLE reception_types; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.reception_types IS 'Lookup table defining the standard workflows for sample intake and laboratory login: 1 = ''Certification'' (full release testing against active material specification), 2 = ''Verification'' (custom test subset on an established material), 3 = ''Category Verification'' (ad-hoc testing of unlisted or experimental samples classified by category).';


--
-- Name: COLUMN reception_types.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reception_types.id IS 'Primary key. Numeric identifier of the reception type.';


--
-- Name: COLUMN reception_types.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reception_types.name IS 'Unique workflow title (''Certification'', ''Verification'', ''Category Verification''). Determines client dialog layout (CertificationDialog, VerificationDialog, or CategoryVerificationDialog) and backend test population logic.';


--
-- Name: receptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.receptions (
    id bigint NOT NULL,
    type_id bigint NOT NULL,
    control_code_id bigint,
    material_name character varying(50),
    category_id bigint,
    is_submitted boolean DEFAULT false NOT NULL,
    user_submitted_id bigint,
    date_submitted timestamp with time zone,
    comments_submitted text,
    is_received boolean DEFAULT false NOT NULL,
    user_received_id bigint,
    date_received timestamp with time zone,
    comments_received text,
    is_rejected boolean DEFAULT false NOT NULL,
    user_rejected_id bigint,
    date_rejected timestamp with time zone,
    comments_rejected text
);


ALTER TABLE public.receptions OWNER TO postgres;

--
-- Name: TABLE receptions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.receptions IS 'Laboratory sample intake, login, and chain-of-custody tracking table. Captures sample submission, laboratory physical receipt, or rejection. Drives subsequent measurement worksheet creation, testing report issuance, and certificate generation.';


--
-- Name: COLUMN receptions.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.id IS 'Primary key. Unique 64-bit integer identifier for the sample reception event.';


--
-- Name: COLUMN receptions.type_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.type_id IS 'Foreign key referencing public.reception_types(id). Specifies whether this reception represents Certification (1), Verification (2), or Category Verification (3).';


--
-- Name: COLUMN receptions.control_code_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.control_code_id IS 'Foreign key referencing public.control_codes(id) (nullable). Identifies the physical batch/lot being sampled. Mandatory for Certification and Verification receptions; NULL for Category Verification receptions.';


--
-- Name: COLUMN receptions.material_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.material_name IS 'Free-text description of the sampled material (maximum 50 characters). Used exclusively for Category Verification receptions (type_id = 3) where the sample does not correspond to a formally registered catalog item in public.materials.';


--
-- Name: COLUMN receptions.category_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.category_id IS 'Foreign key referencing public.categories(id) (nullable). Classifies the sample under an established category for Category Verification receptions (type_id = 3). NULL for standard Certification and Verification receptions.';


--
-- Name: COLUMN receptions.is_submitted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.is_submitted IS 'Boolean status flag. True indicates the sample reception request has been formally submitted by sampling/production personnel.';


--
-- Name: COLUMN receptions.user_submitted_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.user_submitted_id IS 'Foreign key referencing public.users(id) (nullable). The user who submitted the sample reception.';


--
-- Name: COLUMN receptions.date_submitted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.date_submitted IS 'Timestamp with time zone when the sample reception was formally submitted.';


--
-- Name: COLUMN receptions.comments_submitted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.comments_submitted IS 'Optional comments, delivery instructions, or sampling conditions noted by the submitter.';


--
-- Name: COLUMN receptions.is_received; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.is_received IS 'Boolean status flag. True indicates the laboratory has physically accepted the sample into custody. Setting this to true automatically marks control_codes.is_reception_received = true (ReceptionsService.ReceiveReception).';


--
-- Name: COLUMN receptions.user_received_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.user_received_id IS 'Foreign key referencing public.users(id) (nullable). The laboratory analyst who checked in and accepted the physical sample.';


--
-- Name: COLUMN receptions.date_received; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.date_received IS 'Timestamp with time zone when the laboratory physically received the sample.';


--
-- Name: COLUMN receptions.comments_received; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.comments_received IS 'Laboratory intake notes regarding sample integrity, packaging, seals, or temperature upon arrival.';


--
-- Name: COLUMN receptions.is_rejected; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.is_rejected IS 'Boolean status flag. True indicates the laboratory rejected the sample intake (e.g. broken seal, insufficient volume, incorrect storage temperature). A rejected reception cannot be received and requires a mandatory reason.';


--
-- Name: COLUMN receptions.user_rejected_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.user_rejected_id IS 'Foreign key referencing public.users(id) (nullable). The laboratory user who executed the sample rejection.';


--
-- Name: COLUMN receptions.date_rejected; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.date_rejected IS 'Timestamp with time zone when the sample was rejected.';


--
-- Name: COLUMN receptions.comments_rejected; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.receptions.comments_rejected IS 'Mandatory documented justification explaining why the sample was rejected by the laboratory.';


--
-- Name: receptions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.control_codes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.receptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: receptions_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.receptions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.receptions_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: report_tests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.report_tests (
    report_id bigint NOT NULL,
    measurement_id bigint NOT NULL,
    test_id bigint NOT NULL,
    idx integer DEFAULT 0 NOT NULL,
    value numeric NOT NULL,
    uncertainty_value numeric,
    coverage_factor_k numeric
);


ALTER TABLE public.report_tests OWNER TO postgres;

--
-- Name: TABLE report_tests; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.report_tests IS 'Analytical test results included in a formal testing report. Encapsulates measured values alongside calculated expanded measurement uncertainties (U) and coverage factors (k) in compliance with ISO/IEC 17025.';


--
-- Name: COLUMN report_tests.report_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.report_tests.report_id IS 'Primary key and foreign key referencing public.reports(id). The parent testing report.';


--
-- Name: COLUMN report_tests.measurement_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.report_tests.measurement_id IS 'Primary key and foreign key referencing public.measurements(id). The source worksheet from which the measurement was obtained.';


--
-- Name: COLUMN report_tests.test_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.report_tests.test_id IS 'Primary key and foreign key referencing public.tests(id). The analytical test evaluated.';


--
-- Name: COLUMN report_tests.idx; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.report_tests.idx IS 'Primary key. Determination replicate index (0 for scalar tests, 0..N for replicated arrays).';


--
-- Name: COLUMN report_tests.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.report_tests.value IS 'Reported test value (numerical measurement or enum key).';


--
-- Name: COLUMN report_tests.uncertainty_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.report_tests.uncertainty_value IS 'Calculated expanded measurement uncertainty U = (value * relative_uncertainty_pct / 100), as established in test definitions. Defines the boundary of the measurement result at approximately 95% confidence.';


--
-- Name: COLUMN report_tests.coverage_factor_k; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.report_tests.coverage_factor_k IS 'Coverage factor k (typically 2.0) applied during uncertainty calculation.';


--
-- Name: reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reports (
    id bigint NOT NULL,
    reception_id bigint NOT NULL,
    is_submitted boolean DEFAULT false NOT NULL,
    user_submitted_id bigint,
    date_submitted timestamp with time zone,
    comments_submitted text,
    report_replaced_id bigint,
    is_cancelled boolean DEFAULT false NOT NULL,
    user_cancelled_id bigint,
    date_cancelled timestamp with time zone,
    comments_cancelled text
);


ALTER TABLE public.reports OWNER TO postgres;

--
-- Name: TABLE reports; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.reports IS 'Formal analytical Testing Reports compiling completed laboratory measurements for a sample reception. Serves as the laboratory''s technical release document before final quality certification. Governed by formal submission, revision/replacement, and cancellation lifecycles with electronic signatures.';


--
-- Name: COLUMN reports.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reports.id IS 'Primary key. Unique 64-bit integer identifier for the testing report.';


--
-- Name: COLUMN reports.reception_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reports.reception_id IS 'Foreign key referencing public.receptions(id). The sample reception for which this test report is generated.';


--
-- Name: COLUMN reports.is_submitted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reports.is_submitted IS 'Boolean status flag. True indicates the test report has been formally signed and submitted by authorized lab personnel. Submitting a report automatically transitions underlying measurements to read-only status.';


--
-- Name: COLUMN reports.user_submitted_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reports.user_submitted_id IS 'Foreign key referencing public.users(id) (nullable). The laboratory user who submitted the test report.';


--
-- Name: COLUMN reports.date_submitted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reports.date_submitted IS 'Timestamp with time zone when the test report was submitted.';


--
-- Name: COLUMN reports.comments_submitted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reports.comments_submitted IS 'Technical comments, summary of findings, or analytical caveats recorded at report submission.';


--
-- Name: COLUMN reports.report_replaced_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reports.report_replaced_id IS 'Foreign key referencing public.reports(id) (nullable). Points to the earlier report revision that this report replaces / amends.';


--
-- Name: COLUMN reports.is_cancelled; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reports.is_cancelled IS 'Boolean status flag. True indicates the report was officially invalidated or cancelled.';


--
-- Name: COLUMN reports.user_cancelled_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reports.user_cancelled_id IS 'Foreign key referencing public.users(id) (nullable). The user who cancelled the test report.';


--
-- Name: COLUMN reports.date_cancelled; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reports.date_cancelled IS 'Timestamp with time zone when the report was cancelled.';


--
-- Name: COLUMN reports.comments_cancelled; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reports.comments_cancelled IS 'Mandatory documented justification explaining why the test report was cancelled.';


--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.reports ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sop_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sop_versions (
    id bigint NOT NULL,
    sop_id bigint NOT NULL,
    version_number character varying(20) NOT NULL,
    external_edms_id character varying(100),
    comments text,
    is_active boolean DEFAULT true NOT NULL,
    date_activated timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE public.sop_versions OWNER TO postgres;

--
-- Name: TABLE sop_versions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.sop_versions IS 'Versioned document releases of Standard Operating Procedures (SOPs). Ensures compliance with document control guidelines by tracking active versus retired revisions and linking to external Electronic Document Management Systems (EDMS). Individual test measurements link to the exact sop_version_id in effect during execution.';


--
-- Name: COLUMN sop_versions.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.sop_versions.id IS 'Primary key. Unique 64-bit integer identifier for the SOP version revision.';


--
-- Name: COLUMN sop_versions.sop_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.sop_versions.sop_id IS 'Foreign key referencing public.sops(id). Identifies the parent SOP to which this revision belongs.';


--
-- Name: COLUMN sop_versions.version_number; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.sop_versions.version_number IS 'Revision string (maximum 20 characters, e.g., ''1.0'', ''2.3'', ''Rev C''). Unique per parent SOP.';


--
-- Name: COLUMN sop_versions.external_edms_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.sop_versions.external_edms_id IS 'External document management system identifier or hyperlink (maximum 100 characters) pointing to the controlled document PDF in the EDMS.';


--
-- Name: COLUMN sop_versions.comments; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.sop_versions.comments IS 'Change control summary or revision history notes describing the updates introduced in this version.';


--
-- Name: COLUMN sop_versions.is_active; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.sop_versions.is_active IS 'Boolean flag indicating whether this specific SOP version is currently active and authorized for analytical testing. Worksheet sessions query active SOP versions for logging test execution methods.';


--
-- Name: COLUMN sop_versions.date_activated; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.sop_versions.date_activated IS 'Timestamp with time zone when this SOP version was officially authorized and released into production. Defaults to clock_timestamp().';


--
-- Name: sop_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.sop_versions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.sop_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sops; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sops (
    id bigint NOT NULL,
    doc_code character varying(50) NOT NULL,
    title character varying(150) NOT NULL,
    norm_id bigint,
    nr_ord bigint DEFAULT 0 NOT NULL,
    date_created timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE public.sops OWNER TO postgres;

--
-- Name: TABLE sops; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.sops IS 'Standard Operating Procedures (SOPs) defining laboratory test methods and testing protocols. Optionally linked to a parent norm (norms). In TestDialog.tsx, choosing a norm filters the SOP dropdown to show only SOPs that reference that norm.';


--
-- Name: COLUMN sops.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.sops.id IS 'Primary key. Unique 64-bit integer identifier for the SOP.';


--
-- Name: COLUMN sops.doc_code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.sops.doc_code IS 'Unique official SOP document code (maximum 50 characters, e.g., ''SOP-QC-MET-0042''). Validated for uniqueness via UniquenessChecker.';


--
-- Name: COLUMN sops.title; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.sops.title IS 'Descriptive title of the standard operating procedure (up to 150 characters, e.g., ''Determination of Water Content by Karl Fischer Titration'').';


--
-- Name: COLUMN sops.norm_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.sops.norm_id IS 'Foreign key referencing public.norms(id) (nullable). Identifies the governing compendial norm or pharmacopeia from which this SOP is derived.';


--
-- Name: COLUMN sops.nr_ord; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.sops.nr_ord IS 'Numeric display and sequence ordering index (defaults to 0).';


--
-- Name: COLUMN sops.date_created; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.sops.date_created IS 'Timestamp with time zone when the SOP record was created. Defaults to clock_timestamp().';


--
-- Name: sops_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.sops ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.sops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: specs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.specs (
    id bigint NOT NULL,
    material_id bigint NOT NULL,
    is_submitted boolean DEFAULT false NOT NULL,
    user_submitted_id bigint,
    date_submitted timestamp with time zone,
    comments_submitted text,
    spec_replaced_id bigint,
    is_cancelled boolean DEFAULT false NOT NULL,
    user_cancelled_id bigint,
    date_cancelled timestamp with time zone,
    comments_cancelled text
);


ALTER TABLE public.specs OWNER TO postgres;

--
-- Name: TABLE specs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.specs IS 'Product and material quality specifications. Defines release limits, compendial monographs, and acceptance criteria used to judge whether manufactured batches or raw material deliveries conform to registered quality standards. Governed by formal submission, replacement/revision, and cancellation lifecycles with electronic signatures.';


--
-- Name: COLUMN specs.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.specs.id IS 'Primary key. Unique 64-bit integer identifier for the specification.';


--
-- Name: COLUMN specs.material_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.specs.material_id IS 'Foreign key referencing public.materials(id). The material or product governed by this specification.';


--
-- Name: COLUMN specs.is_submitted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.specs.is_submitted IS 'Boolean status flag. True indicates the specification has been approved and activated for release testing. Only submitted and non-cancelled specifications are active for sample receptions and certificate generation.';


--
-- Name: COLUMN specs.user_submitted_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.specs.user_submitted_id IS 'Foreign key referencing public.users(id) (nullable). The QC authority who approved and submitted the specification.';


--
-- Name: COLUMN specs.date_submitted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.specs.date_submitted IS 'Timestamp with time zone when the specification was officially activated.';


--
-- Name: COLUMN specs.comments_submitted; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.specs.comments_submitted IS 'Regulatory remarks, change control numbers, or justification recorded at submission.';


--
-- Name: COLUMN specs.spec_replaced_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.specs.spec_replaced_id IS 'Foreign key referencing public.specs(id) (nullable). Points to the previous specification version that this new revision supersedes.';


--
-- Name: COLUMN specs.is_cancelled; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.specs.is_cancelled IS 'Boolean status flag. True indicates this specification has been cancelled or retired.';


--
-- Name: COLUMN specs.user_cancelled_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.specs.user_cancelled_id IS 'Foreign key referencing public.users(id) (nullable). The user who cancelled the specification.';


--
-- Name: COLUMN specs.date_cancelled; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.specs.date_cancelled IS 'Timestamp with time zone when the specification was cancelled.';


--
-- Name: COLUMN specs.comments_cancelled; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.specs.comments_cancelled IS 'Mandatory documented explanation explaining why the specification was cancelled.';


--
-- Name: spec_headers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.specs ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.spec_headers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: spec_test_evals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.spec_test_evals (
    id bigint NOT NULL,
    spec_id bigint NOT NULL,
    test_id bigint NOT NULL,
    value numeric NOT NULL,
    result numeric,
    expected_result numeric NOT NULL,
    is_match boolean DEFAULT false NOT NULL,
    note character varying(20)
);


ALTER TABLE public.spec_test_evals OWNER TO postgres;

--
-- Name: TABLE spec_test_evals; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.spec_test_evals IS 'Verification benchmark test cases for specification test conditions (spec_tests.condition). In SpecTestDialog.tsx, authors define test values and expected results (1=pass, 0=fail). The backend recalculates and verifies all cases to guarantee formula correctness before specification activation.';


--
-- Name: COLUMN spec_test_evals.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spec_test_evals.id IS 'Primary key. Unique 64-bit integer identifier for the evaluation test row.';


--
-- Name: COLUMN spec_test_evals.spec_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spec_test_evals.spec_id IS 'Foreign key referencing public.specs(id). The parent specification.';


--
-- Name: COLUMN spec_test_evals.test_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spec_test_evals.test_id IS 'Foreign key referencing public.tests(id). The test being verified.';


--
-- Name: COLUMN spec_test_evals.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spec_test_evals.value IS 'Test input value passed into the specification condition expression.';


--
-- Name: COLUMN spec_test_evals.result; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spec_test_evals.result IS 'Actual boolean result evaluated by the rule engine (1 for conforming, 0 for non-conforming).';


--
-- Name: COLUMN spec_test_evals.expected_result; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spec_test_evals.expected_result IS 'Expected outcome (1 for pass, 0 for fail) defined by the specification author.';


--
-- Name: COLUMN spec_test_evals.is_match; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spec_test_evals.is_match IS 'Boolean flag. True indicates result matches expected_result.';


--
-- Name: COLUMN spec_test_evals.note; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spec_test_evals.note IS 'Short descriptive note explaining the test scenario (maximum 20 characters, e.g., ''Lower limit fail'', ''Target pass'').';


--
-- Name: spec_test_evals_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.spec_test_evals ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.spec_test_evals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: spec_tests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.spec_tests (
    spec_id bigint NOT NULL,
    test_id bigint NOT NULL,
    condition character varying(255) NOT NULL,
    note character varying(150) NOT NULL,
    use_uncertainty boolean DEFAULT false NOT NULL,
    test_frequency integer NOT NULL
);


ALTER TABLE public.spec_tests OWNER TO postgres;

--
-- Name: TABLE spec_tests; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.spec_tests IS 'Acceptance limits and testing criteria for each analytical test within a specification. Encapsulates executable boolean condition formulas, human-readable specification notes, testing frequency, and ISO/IEC 17025 measurement uncertainty guard-band evaluation rules.';


--
-- Name: COLUMN spec_tests.spec_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spec_tests.spec_id IS 'Primary key and foreign key referencing public.specs(id). The parent specification.';


--
-- Name: COLUMN spec_tests.test_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spec_tests.test_id IS 'Primary key and foreign key referencing public.tests(id). The analytical test evaluated under this specification.';


--
-- Name: COLUMN spec_tests.condition; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spec_tests.condition IS 'Executable boolean expression string (maximum 255 characters, e.g., ''[value] >= 98.0 && [value] <= 102.0'', ''[value] == 1''). Validated on blur in SpecTestDialog.tsx via SpecificationsService.ValidateCondition. Evaluated during certificate generation.';


--
-- Name: COLUMN spec_tests.note; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spec_tests.note IS 'Human-readable specification limit text (maximum 150 characters, e.g., ''98.0% - 102.0%'', ''Clear colorless liquid'', ''NMT 0.5%''). Printed on analytical test reports and Quality Certificates.';


--
-- Name: COLUMN spec_tests.use_uncertainty; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spec_tests.use_uncertainty IS 'Boolean flag implementing ISO/IEC 17025 / ILAC-G8 decision rules. When true, certificate evaluation takes expanded measurement uncertainty into account by verifying that both the lower bound [value - U] and upper bound [value + U] satisfy the condition.';


--
-- Name: COLUMN spec_tests.test_frequency; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spec_tests.test_frequency IS 'Integer testing frequency rule (e.g., 1 indicates testing is performed on every batch; 5 indicates skip-lot testing every 5 batches).';


--
-- Name: test_enums; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_enums (
    test_id bigint NOT NULL,
    value bigint NOT NULL,
    name character varying(50) NOT NULL,
    nr_ord bigint DEFAULT 0 NOT NULL,
    is_obsolete boolean DEFAULT false NOT NULL
);


ALTER TABLE public.test_enums OWNER TO postgres;

--
-- Name: TABLE test_enums; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.test_enums IS 'Discrete lookup choice options for enum-type analytical tests (value_types.id = 4). When creating a new enum test in TestDialog.tsx, the analyst must supply at least two unique items (parsed from enumListString by newline, comma, or semicolon). Individual items can be added or edited via TestEnumDialog.tsx.';


--
-- Name: COLUMN test_enums.test_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.test_enums.test_id IS 'Primary key and foreign key referencing public.tests(id). The parent test to which this enumeration item belongs.';


--
-- Name: COLUMN test_enums.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.test_enums.value IS 'Primary key. Integer numeric code stored in measurement tables (measurement_tests.value, measurement_params.value) when this enum option is selected (e.g., 1 for ''Clear'', 2 for ''Slightly Opalescent'', 3 for ''Turbid'').';


--
-- Name: COLUMN test_enums.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.test_enums.name IS 'Human-readable display label (1 to 50 characters, e.g., ''Conforms'', ''Positive'', ''Clear colorless liquid'') shown in dropdowns and printed on analytical certificates.';


--
-- Name: COLUMN test_enums.nr_ord; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.test_enums.nr_ord IS 'Numeric display order index (defaults to 0) controlling the sequence of options in client select menus.';


--
-- Name: COLUMN test_enums.is_obsolete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.test_enums.is_obsolete IS 'Soft-deletion flag. When true, hides this enum option from future selection while preserving historical test result interpretation.';


--
-- Name: test_equipments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_equipments (
    test_id bigint NOT NULL,
    equipment_id bigint NOT NULL
);


ALTER TABLE public.test_equipments OWNER TO postgres;

--
-- Name: TABLE test_equipments; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.test_equipments IS 'Many-to-many junction table associating laboratory test definitions with required or default equipment models (equipments). When creating a measurement worksheet, tests automatically identify eligible instruments based on these assignments.';


--
-- Name: COLUMN test_equipments.test_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.test_equipments.test_id IS 'Primary key and foreign key referencing public.tests(id). The analytical test requiring instrument allocation.';


--
-- Name: COLUMN test_equipments.equipment_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.test_equipments.equipment_id IS 'Primary key and foreign key referencing public.equipments(id). The laboratory instrument authorized for executing this test.';


--
-- Name: test_reagents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_reagents (
    test_id bigint NOT NULL,
    material_id bigint NOT NULL
);


ALTER TABLE public.test_reagents OWNER TO postgres;

--
-- Name: TABLE test_reagents; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.test_reagents IS 'Many-to-many junction table associating analytical tests with consumable chemical reagents or volumetric solutions (materials where is_reagent = true). Specifies which chemical reagents are consumed during test execution and drives reagent lot traceability on worksheets.';


--
-- Name: COLUMN test_reagents.test_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.test_reagents.test_id IS 'Primary key and foreign key referencing public.tests(id). The analytical test that consumes the reagent.';


--
-- Name: COLUMN test_reagents.material_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.test_reagents.material_id IS 'Primary key and foreign key referencing public.materials(id). The chemical reagent material required for this test.';


--
-- Name: tests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tests (
    id bigint NOT NULL,
    name character varying(50) NOT NULL,
    code character varying(50) NOT NULL,
    description text,
    type_id bigint NOT NULL,
    is_array boolean DEFAULT false NOT NULL,
    is_param boolean DEFAULT false NOT NULL,
    for_environmental_control boolean DEFAULT false NOT NULL,
    for_certification boolean DEFAULT false NOT NULL,
    relative_uncertainty_pct numeric(5,2),
    default_coverage_factor_k numeric(3,1),
    for_certified_reference boolean DEFAULT false NOT NULL,
    unit_id bigint,
    norm_id bigint,
    norm_ref character varying(50),
    sop_id bigint,
    is_form_validated boolean DEFAULT false NOT NULL,
    date_form_validated timestamp with time zone,
    nr_ord bigint DEFAULT 0 NOT NULL,
    date_created timestamp with time zone NOT NULL,
    is_obsolete boolean DEFAULT false NOT NULL,
    date_obsolete timestamp with time zone,
    comments_obsolete text
);


ALTER TABLE public.tests OWNER TO postgres;

--
-- Name: TABLE tests; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.tests IS 'Master analytical test definition and calculation parameter dictionary. Defines physical, chemical, and biological tests, as well as intermediate variables used in formulas. Controls measurement data types, replicated array behavior, metrological uncertainty defaults, CRM requirements, norm/SOP method bindings, and validation immutability locks.';


--
-- Name: COLUMN tests.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.id IS 'Primary key. Unique 64-bit integer identifier for the test/parameter definition.';


--
-- Name: COLUMN tests.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.name IS 'Unique descriptive name of the test (3 to 50 characters, e.g., ''Assay by HPLC'', ''Loss on Drying'', ''pH at 25°C''). Locked from editing if is_form_validated is true.';


--
-- Name: COLUMN tests.code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.code IS 'Unique identifier token (2 to 50 characters) used as a mathematical variable in QC formulas (e.g., ''assay'', ''lod_wt_loss'', ''ph_val''). Must conform to regex /^(?!.*__)[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]$/ (starts with letter, ends with alphanumeric, only alphanumeric and single underscores). Locked from editing if is_form_validated is true to maintain formula AST parsing validity.';


--
-- Name: COLUMN tests.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.description IS 'Extended explanatory text describing the test scope, analytical principle, or sampling preparation.';


--
-- Name: COLUMN tests.type_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.type_id IS 'Foreign key referencing public.value_types(id). Specifies whether results are stored as integer (1), real (2), boolean (3), or enum (4). Locked from editing if is_form_validated is true.';


--
-- Name: COLUMN tests.is_array; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.is_array IS 'Boolean flag indicating whether the test yields multiple replicated measurement determinations (e.g., parallel injections, duplicate titrations) rather than a single scalar value. In formulas, arrays are referenced as [[code]]. In TestDialog.tsx, setting is_array to true automatically resets and disables for_certified_reference. Locked from editing if is_form_validated is true.';


--
-- Name: COLUMN tests.is_param; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.is_param IS 'Boolean flag designating this test as an intermediate calculation parameter or raw input (e.g. tare weight, sample mass, dilution factor) rather than a reportable specification test. In TestDialog.tsx, setting is_param to true resets and disables for_certification, for_environmental_control, and for_certified_reference. Locked from editing if is_form_validated is true.';


--
-- Name: COLUMN tests.for_environmental_control; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.for_environmental_control IS 'Boolean flag designating this test for cleanroom and environmental monitoring (e.g., ambient temperature, relative humidity, air particulates). In TestDialog.tsx, enabling this flag enforces mutual exclusivity by automatically resetting for_certification, for_certified_reference, and is_param to false.';


--
-- Name: COLUMN tests.for_certification; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.for_certification IS 'Boolean flag indicating that this is a critical specification test that must be reported on official Quality Certificates / Certificates of Analysis (COA). In TestDialog.tsx, checking this box automatically defaults relative_uncertainty_pct to 3.00% and default_coverage_factor_k to 2.0 (if null/0), and resets for_environmental_control and is_param to false. Unchecking it resets uncertainty fields to NULL.';


--
-- Name: COLUMN tests.relative_uncertainty_pct; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.relative_uncertainty_pct IS 'Expanded relative measurement uncertainty percentage (NUMERIC(5,2), e.g., 3.00 for ±3.00%). Used by the reporting engine to calculate absolute expanded measurement uncertainty: U = (value * relative_uncertainty_pct / 100). Editable only when for_certification is true; automatically cleared to NULL when for_certification is false.';


--
-- Name: COLUMN tests.default_coverage_factor_k; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.default_coverage_factor_k IS 'Default coverage factor k (NUMERIC(3,1), typically 2.0 corresponding to approximately 95% level of confidence under a normal distribution). Used in accordance with ISO/IEC 17025 and GUM (Guide to the Expression of Uncertainty in Measurement). Cleared to NULL when for_certification is false.';


--
-- Name: COLUMN tests.for_certified_reference; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.for_certified_reference IS 'Boolean flag enforcing strict metrological traceability. When true, during worksheet execution (SelectCrmDialog.tsx), the analyst cannot manually type an arbitrary numeric value; they must select an active, certified value from a Certified Reference Material (CRM) inventory lot or prior CRM certificate. In TestDialog.tsx, enabling this flag resets and disables is_array, is_param, and for_environmental_control.';


--
-- Name: COLUMN tests.unit_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.unit_id IS 'Foreign key referencing public.units(id) (nullable). Identifies the default unit of measure associated with this test''s results.';


--
-- Name: COLUMN tests.norm_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.norm_id IS 'Foreign key referencing public.norms(id) (nullable). Identifies the governing compendial standard. In TestDialog.tsx, selecting a norm filters available SOPs to those belonging to that norm, and clearing the norm resets norm_ref to NULL, sop_id to NULL, and empties the SOP list.';


--
-- Name: COLUMN tests.norm_ref; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.norm_ref IS 'Textual citation (maximum 50 characters) identifying the exact clause, section, or monograph within the governing norm (e.g., ''Ph. Eur. 2.2.3'', ''USP <621>''). Enabled in TestDialog.tsx only when norm_id is selected.';


--
-- Name: COLUMN tests.sop_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.sop_id IS 'Foreign key referencing public.sops(id) (nullable). Links the test definition to its approved operating procedure. Filtered by norm_id in the client UI.';


--
-- Name: COLUMN tests.is_form_validated; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.is_form_validated IS 'Boolean validation lock. Automatically set to true by FormsService.ValidateForm when any form containing this test is validated and approved. Once true, the client UI disables and server rejects edits to test name, code, type_id, and is_array to guarantee that validated mathematical formulas and calculation ASTs do not become corrupt or broken.';


--
-- Name: COLUMN tests.date_form_validated; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.date_form_validated IS 'Timestamp with time zone when the test definition was locked following form validation approval.';


--
-- Name: COLUMN tests.nr_ord; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.nr_ord IS 'Default numeric presentation and sorting order index (defaults to 0) used when displaying tests in tables and reports.';


--
-- Name: COLUMN tests.date_created; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.date_created IS 'Timestamp with time zone when the test was originally registered.';


--
-- Name: COLUMN tests.is_obsolete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.is_obsolete IS 'Soft-deletion flag. Under GxP requirements, test definitions cannot be physically removed if referenced in historical worksheets, specifications, or certificates. When true, hides the test from new templates and specifications.';


--
-- Name: COLUMN tests.date_obsolete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.date_obsolete IS 'Timestamp with time zone when the test was decommissioned. Cleared to NULL if reactivated.';


--
-- Name: COLUMN tests.comments_obsolete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tests.comments_obsolete IS 'Documented reason recorded when deactivating the test definition. Cleared to NULL if reactivated.';


--
-- Name: tests_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.tests ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: units; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.units (
    id bigint NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    date_created timestamp with time zone NOT NULL
);


ALTER TABLE public.units OWNER TO postgres;

--
-- Name: TABLE units; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.units IS 'Lookup catalog of units of measurement (UOM) utilized across analytical test definitions, laboratory equipment, chemical reagents, and parameter calculations (e.g., ''mg'', ''mL'', ''g/cm3'', ''%'', ''pH'', ''°C'', ''rpm'', ''AU'').';


--
-- Name: COLUMN units.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.units.id IS 'Primary key. Unique 64-bit integer identifier for the measurement unit.';


--
-- Name: COLUMN units.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.units.name IS 'Unique symbol or name of the unit of measure (maximum 50 characters, e.g., ''mg/kg'', ''mPa.s'', ''Abs''). Displayed alongside test inputs, results, and specification notes.';


--
-- Name: COLUMN units.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.units.description IS 'Full descriptive name or context for the measurement unit (e.g., ''Milligrams per kilogram'', ''Degrees Celsius'').';


--
-- Name: COLUMN units.date_created; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.units.date_created IS 'Timestamp with time zone when the measurement unit record was created in the system.';


--
-- Name: units_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.units ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.units_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    tag character varying(12) NOT NULL,
    code character varying(3) NOT NULL,
    email character varying(50) NOT NULL,
    first_name character varying(50),
    last_name character varying(50),
    is_admin boolean DEFAULT false NOT NULL,
    is_lab_pers boolean DEFAULT false NOT NULL,
    is_qc_pers boolean DEFAULT false NOT NULL,
    password_hash text,
    password_salt text,
    must_change_password boolean DEFAULT false NOT NULL,
    date_password_changed timestamp with time zone,
    failed_login_attempts integer DEFAULT 0 NOT NULL,
    is_locked boolean DEFAULT false NOT NULL,
    lock_expiration timestamp with time zone,
    session_id character varying(255),
    date_session_created timestamp with time zone,
    date_session_expire timestamp with time zone,
    refresh_token character varying,
    date_created timestamp with time zone NOT NULL,
    is_obsolete boolean DEFAULT false NOT NULL,
    date_obsolete timestamp with time zone,
    comments_obsolete text
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.users IS 'User accounts and role-based access control table for laboratory personnel, QC managers, and system administrators. Maintains authentication credentials, session tracking, account security (lockout, password expiration), and soft-deletion status for GxP auditability.';


--
-- Name: COLUMN users.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.id IS 'Primary key. Unique 64-bit integer identifier for each laboratory system user.';


--
-- Name: COLUMN users.tag; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.tag IS 'Unique user login username/handle (3 to 12 characters). Enforced by client regex /^[a-z][a-z0-9_]*[a-z0-9]$/ (must start with a lowercase letter, end with alphanumeric, contain only lowercase letters, digits, or underscores). Used for authentication and audit log displays.';


--
-- Name: COLUMN users.code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.code IS 'Unique 2 to 3 uppercase alphanumeric identifier (regex /^[A-Z][A-Z0-9]*$/) representing the user''s initials. Displayed on compact laboratory worksheets, test result tags, and sample labels.';


--
-- Name: COLUMN users.email; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.email IS 'Unique email address of the user (maximum 50 characters). Validated via standard email format rules.';


--
-- Name: COLUMN users.first_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.first_name IS 'User''s given first name (maximum 50 characters).';


--
-- Name: COLUMN users.last_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.last_name IS 'User''s family/surname (maximum 50 characters).';


--
-- Name: COLUMN users.is_admin; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.is_admin IS 'Boolean role flag. When true, grants full administrative privileges including user management, role assignments, system settings, and master data configuration.';


--
-- Name: COLUMN users.is_lab_pers; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.is_lab_pers IS 'Boolean role flag. When true, identifies the user as Laboratory Personnel, granting authorization to execute sample receptions, input raw measurement readings, prepare reagent lots, and operate worksheets.';


--
-- Name: COLUMN users.is_qc_pers; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.is_qc_pers IS 'Boolean role flag. When true, identifies the user as Quality Control Personnel, granting authorization to review, validate, and approve forms, specifications, testing reports, and official quality certificates.';


--
-- Name: COLUMN users.password_hash; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.password_hash IS 'Secure cryptographic salted hash of the user''s authentication password.';


--
-- Name: COLUMN users.password_salt; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.password_salt IS 'Cryptographic salt value applied during password hashing to prevent rainbow table attacks.';


--
-- Name: COLUMN users.must_change_password; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.must_change_password IS 'Boolean flag forcing the user to update their password upon next login. Automatically set to true when an administrator creates a user account or executes an administrative password reset via ResetPasswordDialog.tsx.';


--
-- Name: COLUMN users.date_password_changed; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.date_password_changed IS 'Timestamp with time zone when the user''s password was last modified. Used for password aging policies.';


--
-- Name: COLUMN users.failed_login_attempts; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.failed_login_attempts IS 'Integer counter tracking consecutive failed login attempts. Reset to 0 upon successful login; used to trigger temporary or administrative account lockout after exceeding maximum allowed thresholds.';


--
-- Name: COLUMN users.is_locked; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.is_locked IS 'Boolean flag indicating whether the account is currently locked against login attempts due to repeated authentication failures or manual administrative suspension.';


--
-- Name: COLUMN users.lock_expiration; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.lock_expiration IS 'Timestamp with time zone indicating when the temporary account lockout expires and authentication attempts may resume.';


--
-- Name: COLUMN users.session_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.session_id IS 'Unique GUID string representing the user''s active session. Stored in the secure HTTP cookie ''QCLabSession_{tenantTag}''. Cleared (set to NULL) upon explicit logout, session expiration, password reset, or account deactivation.';


--
-- Name: COLUMN users.date_session_created; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.date_session_created IS 'Timestamp with time zone when the current session_id was generated upon successful login.';


--
-- Name: COLUMN users.date_session_expire; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.date_session_expire IS 'Timestamp with time zone when the current session_id expires (typically 12 hours from generation). Checked by SessionAuthMiddleware.';


--
-- Name: COLUMN users.refresh_token; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.refresh_token IS 'Cryptographic refresh token string used for renewing API sessions.';


--
-- Name: COLUMN users.date_created; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.date_created IS 'Timestamp with time zone when the user profile was originally registered in the system.';


--
-- Name: COLUMN users.is_obsolete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.is_obsolete IS 'Soft-deletion flag. Under GxP and 21 CFR Part 11 regulations, user records cannot be physically deleted because they are referenced across audit trails, electronic signatures, and test worksheets. True indicates the user is deactivated.';


--
-- Name: COLUMN users.date_obsolete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.date_obsolete IS 'Timestamp with time zone when the user was marked obsolete / deactivated. Cleared to NULL if reactivated.';


--
-- Name: COLUMN users.comments_obsolete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.comments_obsolete IS 'Mandatory documented explanation recorded when deactivating the user profile. Cleared to NULL if reactivated.';


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.users ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: value_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.value_types (
    id bigint NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.value_types OWNER TO postgres;

--
-- Name: TABLE value_types; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.value_types IS 'Static foundational reference table defining data types supported for analytical tests and formula parameters: 1 = ''integer'' (whole numbers), 2 = ''real'' (floating point / decimal numbers), 3 = ''boolean'' (binary pass/fail / true/false), 4 = ''enum'' (discrete selection options defined in test_enums).';


--
-- Name: COLUMN value_types.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.value_types.id IS 'Primary key. Unique identifier corresponding to the primitive value type enumeration.';


--
-- Name: COLUMN value_types.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.value_types.name IS 'Unique name of the data type (''integer'', ''real'', ''boolean'', ''enum''). Used by the UI to dynamically render appropriate input controls (number input, checkbox/toggle, or select dropdown) and by the QCFormula engine for type inference.';


--
-- Name: value_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.value_types ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.value_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: categories categories_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_code_key UNIQUE (code);


--
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: category_tests category_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.category_tests
    ADD CONSTRAINT category_tests_pkey PRIMARY KEY (category_id, test_id);


--
-- Name: certificate_tests certificate_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_pkey PRIMARY KEY (certificate_id, report_id, test_id, idx, measurement_id);


--
-- Name: certificates certificates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_pkey PRIMARY KEY (id);


--
-- Name: control_codes control_codes_material_id_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.control_codes
    ADD CONSTRAINT control_codes_material_id_code_key UNIQUE (material_id, code);


--
-- Name: control_codes control_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.control_codes
    ADD CONSTRAINT control_codes_pkey PRIMARY KEY (id);


--
-- Name: electronic_signatures electronic_signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.electronic_signatures
    ADD CONSTRAINT electronic_signatures_pkey PRIMARY KEY (id);


--
-- Name: equipment_calibration_statuses equipment_calibration_statuses_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_calibration_statuses
    ADD CONSTRAINT equipment_calibration_statuses_name_key UNIQUE (name);


--
-- Name: equipment_calibration_statuses equipment_calibration_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_calibration_statuses
    ADD CONSTRAINT equipment_calibration_statuses_pkey PRIMARY KEY (id);


--
-- Name: equipment_calibrations equipment_calibrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_calibrations
    ADD CONSTRAINT equipment_calibrations_pkey PRIMARY KEY (id);


--
-- Name: equipments equipment_equipment_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipments
    ADD CONSTRAINT equipment_equipment_code_key UNIQUE (equipment_code);


--
-- Name: equipments equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipments
    ADD CONSTRAINT equipment_pkey PRIMARY KEY (id);


--
-- Name: equipment_statuses equipment_statuses_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_statuses
    ADD CONSTRAINT equipment_statuses_name_key UNIQUE (name);


--
-- Name: equipment_statuses equipment_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_statuses
    ADD CONSTRAINT equipment_statuses_pkey PRIMARY KEY (id);


--
-- Name: equipments equipments_serial_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipments
    ADD CONSTRAINT equipments_serial_number_key UNIQUE (serial_number);


--
-- Name: form_condition_evals form_condition_evals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_condition_evals
    ADD CONSTRAINT form_condition_evals_pkey PRIMARY KEY (id);


--
-- Name: form_eval_params form_eval_params_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_pkey PRIMARY KEY (eval_id, form_id, test_id, idx);


--
-- Name: form_evals form_evals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_evals
    ADD CONSTRAINT form_evals_pkey PRIMARY KEY (id);


--
-- Name: form_groups form_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_groups
    ADD CONSTRAINT form_groups_pkey PRIMARY KEY (id);


--
-- Name: form_params form_params_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_params
    ADD CONSTRAINT form_params_pkey PRIMARY KEY (form_id, test_id);


--
-- Name: forms forms_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forms
    ADD CONSTRAINT forms_pkey PRIMARY KEY (id);


--
-- Name: material_tests material_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_tests
    ADD CONSTRAINT material_tests_pkey PRIMARY KEY (material_id, test_id);


--
-- Name: materials materials_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_code_key UNIQUE (code);


--
-- Name: materials materials_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_name_key UNIQUE (name);


--
-- Name: materials materials_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_pkey PRIMARY KEY (id);


--
-- Name: measurement_equipments measurement_equipments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_equipments
    ADD CONSTRAINT measurement_equipments_pkey PRIMARY KEY (measurement_id, equipment_id);


--
-- Name: measurement_params measurement_params_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_pkey PRIMARY KEY (measurement_id, form_id, test_id, idx);


--
-- Name: measurement_reagent_lots measurement_reagent_lots_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_reagent_lots
    ADD CONSTRAINT measurement_reagent_lots_pkey PRIMARY KEY (measurement_id, control_code_id);


--
-- Name: measurement_sop_versions measurement_sop_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_sop_versions
    ADD CONSTRAINT measurement_sop_versions_pkey PRIMARY KEY (measurement_id, sop_version_id);


--
-- Name: measurement_tests measurement_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_tests
    ADD CONSTRAINT measurement_tests_pkey PRIMARY KEY (measurement_id, test_id, idx);


--
-- Name: measurements measurements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_pkey PRIMARY KEY (id);


--
-- Name: norms norms_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.norms
    ADD CONSTRAINT norms_name_key UNIQUE (name);


--
-- Name: norms norms_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.norms
    ADD CONSTRAINT norms_pkey PRIMARY KEY (id);


--
-- Name: reagent_lot_statuses reagent_lot_statuses_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_lot_statuses
    ADD CONSTRAINT reagent_lot_statuses_name_key UNIQUE (name);


--
-- Name: reagent_lot_statuses reagent_lot_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_lot_statuses
    ADD CONSTRAINT reagent_lot_statuses_pkey PRIMARY KEY (id);


--
-- Name: reagent_lots reagent_lots_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_lots
    ADD CONSTRAINT reagent_lots_pkey PRIMARY KEY (control_code_id);


--
-- Name: reagent_production_lots reagent_production_lots_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_production_lots
    ADD CONSTRAINT reagent_production_lots_pkey PRIMARY KEY (control_code_id, ingredient_control_code_id);


--
-- Name: reagent_supplier_lot_cert_tests reagent_supplier_lot_cert_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_supplier_lot_cert_tests
    ADD CONSTRAINT reagent_supplier_lot_cert_tests_pkey PRIMARY KEY (control_code_id);


--
-- Name: reagent_supplier_lots reagent_supplier_lots_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_supplier_lots
    ADD CONSTRAINT reagent_supplier_lots_pkey PRIMARY KEY (control_code_id);


--
-- Name: reagent_suppliers reagent_suppliers_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_suppliers
    ADD CONSTRAINT reagent_suppliers_name_key UNIQUE (name);


--
-- Name: reagent_suppliers reagent_suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_suppliers
    ADD CONSTRAINT reagent_suppliers_pkey PRIMARY KEY (id);


--
-- Name: reception_tests reception_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reception_tests
    ADD CONSTRAINT reception_tests_pkey PRIMARY KEY (reception_id, test_id);


--
-- Name: reception_types reception_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reception_types
    ADD CONSTRAINT reception_types_pkey PRIMARY KEY (id);


--
-- Name: receptions receptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_pkey PRIMARY KEY (id);


--
-- Name: report_tests report_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_tests
    ADD CONSTRAINT report_tests_pkey PRIMARY KEY (report_id, measurement_id, test_id, idx);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: sop_versions sop_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sop_versions
    ADD CONSTRAINT sop_versions_pkey PRIMARY KEY (id);


--
-- Name: sops sops_doc_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sops
    ADD CONSTRAINT sops_doc_code_key UNIQUE (doc_code);


--
-- Name: sops sops_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sops
    ADD CONSTRAINT sops_pkey PRIMARY KEY (id);


--
-- Name: spec_test_evals spec_test_evals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spec_test_evals
    ADD CONSTRAINT spec_test_evals_pkey PRIMARY KEY (id);


--
-- Name: spec_tests spec_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spec_tests
    ADD CONSTRAINT spec_tests_pkey PRIMARY KEY (spec_id, test_id);


--
-- Name: specs specs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specs
    ADD CONSTRAINT specs_pkey PRIMARY KEY (id);


--
-- Name: test_enums test_enums_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_enums
    ADD CONSTRAINT test_enums_pkey PRIMARY KEY (test_id, value);


--
-- Name: test_enums test_enums_test_id_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_enums
    ADD CONSTRAINT test_enums_test_id_name_key UNIQUE (test_id, name);


--
-- Name: test_equipments test_equipments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_equipments
    ADD CONSTRAINT test_equipments_pkey PRIMARY KEY (test_id, equipment_id);


--
-- Name: test_reagents test_reagents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_reagents
    ADD CONSTRAINT test_reagents_pkey PRIMARY KEY (test_id, material_id);


--
-- Name: tests tests_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_code_key UNIQUE (code);


--
-- Name: tests tests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_pkey PRIMARY KEY (id);


--
-- Name: units units_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_name_key UNIQUE (name);


--
-- Name: units units_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_pkey PRIMARY KEY (id);


--
-- Name: sop_versions unq_sop_version_number; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sop_versions
    ADD CONSTRAINT unq_sop_version_number UNIQUE (sop_id, version_number);


--
-- Name: users users_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_code_key UNIQUE (code);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_session_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_session_id_key UNIQUE (session_id);


--
-- Name: users users_tag_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_tag_key UNIQUE (tag);


--
-- Name: value_types value_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.value_types
    ADD CONSTRAINT value_types_pkey PRIMARY KEY (id);


--
-- Name: unq_single_active_sop_version; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX unq_single_active_sop_version ON public.sop_versions USING btree (sop_id) WHERE (is_active = true);


--
-- Name: certificate_tests audit_certificate_tests_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_certificate_tests_trigger AFTER INSERT OR DELETE OR UPDATE ON public.certificate_tests FOR EACH ROW EXECUTE FUNCTION public.process_audit_log();


--
-- Name: certificates audit_certificates_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_certificates_trigger AFTER INSERT OR DELETE OR UPDATE ON public.certificates FOR EACH ROW EXECUTE FUNCTION public.process_audit_log();


--
-- Name: form_params audit_form_params_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_form_params_trigger AFTER INSERT OR DELETE OR UPDATE ON public.form_params FOR EACH ROW EXECUTE FUNCTION public.process_audit_log();


--
-- Name: forms audit_forms_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_forms_trigger AFTER INSERT OR DELETE OR UPDATE ON public.forms FOR EACH ROW EXECUTE FUNCTION public.process_audit_log();


--
-- Name: measurement_params audit_measurement_params_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_measurement_params_trigger AFTER INSERT OR DELETE OR UPDATE ON public.measurement_params FOR EACH ROW EXECUTE FUNCTION public.process_audit_log();


--
-- Name: measurement_tests audit_measurement_tests_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_measurement_tests_trigger AFTER INSERT OR DELETE OR UPDATE ON public.measurement_tests FOR EACH ROW EXECUTE FUNCTION public.process_audit_log();


--
-- Name: measurements audit_measurements_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_measurements_trigger AFTER INSERT OR DELETE OR UPDATE ON public.measurements FOR EACH ROW EXECUTE FUNCTION public.process_audit_log();


--
-- Name: report_tests audit_report_tests_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_report_tests_trigger AFTER INSERT OR DELETE OR UPDATE ON public.report_tests FOR EACH ROW EXECUTE FUNCTION public.process_audit_log();


--
-- Name: reports audit_reports_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_reports_trigger AFTER INSERT OR DELETE OR UPDATE ON public.reports FOR EACH ROW EXECUTE FUNCTION public.process_audit_log();


--
-- Name: spec_tests audit_spec_tests_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_spec_tests_trigger AFTER INSERT OR DELETE OR UPDATE ON public.spec_tests FOR EACH ROW EXECUTE FUNCTION public.process_audit_log();


--
-- Name: specs audit_specs_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_specs_trigger AFTER INSERT OR DELETE OR UPDATE ON public.specs FOR EACH ROW EXECUTE FUNCTION public.process_audit_log();


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: category_tests category_tests_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.category_tests
    ADD CONSTRAINT category_tests_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- Name: category_tests category_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.category_tests
    ADD CONSTRAINT category_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: certificate_tests certificate_tests_certificates_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_certificates_id_fkey FOREIGN KEY (certificate_id) REFERENCES public.certificates(id) ON DELETE CASCADE;


--
-- Name: certificate_tests certificate_tests_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id);


--
-- Name: certificate_tests certificate_tests_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(id);


--
-- Name: certificate_tests certificate_tests_report_id_measurement_id_test_id_idx_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_report_id_measurement_id_test_id_idx_fkey FOREIGN KEY (report_id, measurement_id, test_id, idx) REFERENCES public.report_tests(report_id, measurement_id, test_id, idx);


--
-- Name: certificate_tests certificate_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: certificates certificates_certificate_replaced_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_certificate_replaced_id_fkey FOREIGN KEY (certificate_replaced_id) REFERENCES public.certificates(id);


--
-- Name: certificates certificates_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_control_code_id_fkey FOREIGN KEY (control_code_id) REFERENCES public.control_codes(id);


--
-- Name: certificates certificates_specs_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_specs_id_fkey FOREIGN KEY (spec_id) REFERENCES public.specs(id);


--
-- Name: certificates certificates_user_cancelled_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_user_cancelled_id_fkey FOREIGN KEY (user_cancelled_id) REFERENCES public.users(id);


--
-- Name: certificates certificates_user_submitted_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_user_submitted_id_fkey FOREIGN KEY (user_submitted_id) REFERENCES public.users(id);


--
-- Name: control_codes control_codes_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.control_codes
    ADD CONSTRAINT control_codes_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: electronic_signatures electronic_signatures_signer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.electronic_signatures
    ADD CONSTRAINT electronic_signatures_signer_user_id_fkey FOREIGN KEY (signer_user_id) REFERENCES public.users(id);


--
-- Name: equipment_calibrations equipment_calibrations_equipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_calibrations
    ADD CONSTRAINT equipment_calibrations_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipments(id) ON DELETE CASCADE;


--
-- Name: equipment_calibrations equipment_calibrations_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_calibrations
    ADD CONSTRAINT equipment_calibrations_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.equipment_calibration_statuses(id);


--
-- Name: equipments equipments_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipments
    ADD CONSTRAINT equipments_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.equipment_statuses(id);


--
-- Name: form_condition_evals form_condition_evals_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_condition_evals
    ADD CONSTRAINT form_condition_evals_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id) ON DELETE CASCADE;


--
-- Name: form_condition_evals form_condition_evals_form_id_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_condition_evals
    ADD CONSTRAINT form_condition_evals_form_id_test_id_fkey FOREIGN KEY (form_id, test_id) REFERENCES public.form_params(form_id, test_id) ON DELETE CASCADE;


--
-- Name: form_condition_evals form_condition_evals_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_condition_evals
    ADD CONSTRAINT form_condition_evals_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: form_eval_params form_eval_params_eval_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_eval_id_fkey FOREIGN KEY (eval_id) REFERENCES public.form_evals(id) ON DELETE CASCADE;


--
-- Name: form_eval_params form_eval_params_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id) ON DELETE CASCADE;


--
-- Name: form_eval_params form_eval_params_form_id_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_form_id_test_id_fkey FOREIGN KEY (form_id, test_id) REFERENCES public.form_params(form_id, test_id) ON DELETE CASCADE;


--
-- Name: form_eval_params form_eval_params_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: form_evals form_evals_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_evals
    ADD CONSTRAINT form_evals_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id) ON DELETE CASCADE;


--
-- Name: form_params form_params_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_params
    ADD CONSTRAINT form_params_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id) ON DELETE CASCADE;


--
-- Name: form_params form_params_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_params
    ADD CONSTRAINT form_params_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: forms forms_form_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forms
    ADD CONSTRAINT forms_form_group_id_fkey FOREIGN KEY (form_group_id) REFERENCES public.form_groups(id);


--
-- Name: forms forms_user_canceled_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forms
    ADD CONSTRAINT forms_user_canceled_id_fkey FOREIGN KEY (user_cancelled_id) REFERENCES public.users(id);


--
-- Name: forms forms_user_submitted_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forms
    ADD CONSTRAINT forms_user_submitted_id_fkey FOREIGN KEY (user_submitted_id) REFERENCES public.users(id);


--
-- Name: forms forms_user_validated_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forms
    ADD CONSTRAINT forms_user_validated_id_fkey FOREIGN KEY (user_validated_id) REFERENCES public.users(id);


--
-- Name: material_tests material_tests_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_tests
    ADD CONSTRAINT material_tests_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id) ON DELETE CASCADE;


--
-- Name: material_tests material_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_tests
    ADD CONSTRAINT material_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: materials materials_norm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_norm_id_fkey FOREIGN KEY (norm_id) REFERENCES public.norms(id);


--
-- Name: measurement_equipments measurement_equipments_equipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_equipments
    ADD CONSTRAINT measurement_equipments_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipments(id);


--
-- Name: measurement_equipments measurement_equipments_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_equipments
    ADD CONSTRAINT measurement_equipments_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id) ON DELETE CASCADE;


--
-- Name: measurement_params measurement_params_certified_reference_certificate_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_certified_reference_certificate_id_fkey FOREIGN KEY (certified_reference_certificate_id) REFERENCES public.certificates(id) NOT VALID;


--
-- Name: measurement_params measurement_params_certified_reference_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_certified_reference_control_code_id_fkey FOREIGN KEY (certified_reference_control_code_id) REFERENCES public.reagent_supplier_lots(control_code_id) NOT VALID;


--
-- Name: measurement_params measurement_params_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id);


--
-- Name: measurement_params measurement_params_form_id_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_form_id_test_id_fkey FOREIGN KEY (form_id, test_id) REFERENCES public.form_params(form_id, test_id);


--
-- Name: measurement_params measurement_params_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id) ON DELETE CASCADE;


--
-- Name: measurement_params measurement_params_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: measurement_params measurement_params_user_created_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_user_created_id_fkey FOREIGN KEY (user_created_id) REFERENCES public.users(id);


--
-- Name: measurement_params measurement_params_user_updated_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_user_updated_id_fkey FOREIGN KEY (user_updated_id) REFERENCES public.users(id);


--
-- Name: measurement_reagent_lots measurement_reagent_lots_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_reagent_lots
    ADD CONSTRAINT measurement_reagent_lots_control_code_id_fkey FOREIGN KEY (control_code_id) REFERENCES public.reagent_lots(control_code_id);


--
-- Name: measurement_reagent_lots measurement_reagent_lots_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_reagent_lots
    ADD CONSTRAINT measurement_reagent_lots_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id) ON DELETE CASCADE;


--
-- Name: measurement_sop_versions measurement_sop_versions_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_sop_versions
    ADD CONSTRAINT measurement_sop_versions_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id) ON DELETE CASCADE;


--
-- Name: measurement_sop_versions measurement_sop_versions_sop_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_sop_versions
    ADD CONSTRAINT measurement_sop_versions_sop_version_id_fkey FOREIGN KEY (sop_version_id) REFERENCES public.sop_versions(id);


--
-- Name: measurement_tests measurement_tests_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_tests
    ADD CONSTRAINT measurement_tests_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id) ON DELETE CASCADE;


--
-- Name: measurement_tests measurement_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_tests
    ADD CONSTRAINT measurement_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: measurement_tests measurement_tests_user_created_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_tests
    ADD CONSTRAINT measurement_tests_user_created_id_fkey FOREIGN KEY (user_created_id) REFERENCES public.users(id);


--
-- Name: measurement_tests measurement_tests_user_updated_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_tests
    ADD CONSTRAINT measurement_tests_user_updated_id_fkey FOREIGN KEY (user_updated_id) REFERENCES public.users(id);


--
-- Name: measurements measurements_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id);


--
-- Name: measurements measurements_reception_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_reception_id_fkey FOREIGN KEY (reception_id) REFERENCES public.receptions(id);


--
-- Name: measurements measurements_user_created_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_user_created_id_fkey FOREIGN KEY (user_created_id) REFERENCES public.users(id);


--
-- Name: measurements measurements_user_reported_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_user_reported_id_fkey FOREIGN KEY (user_reported_id) REFERENCES public.users(id);


--
-- Name: measurements measurements_user_updated_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_user_updated_id_fkey FOREIGN KEY (user_updated_id) REFERENCES public.users(id);


--
-- Name: reagent_lots reagent_lots_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_lots
    ADD CONSTRAINT reagent_lots_control_code_id_fkey FOREIGN KEY (control_code_id) REFERENCES public.control_codes(id);


--
-- Name: reagent_lots reagent_lots_produced_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_lots
    ADD CONSTRAINT reagent_lots_produced_by_user_id_fkey FOREIGN KEY (produced_by_user_id) REFERENCES public.users(id);


--
-- Name: reagent_lots reagent_lots_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_lots
    ADD CONSTRAINT reagent_lots_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.reagent_lot_statuses(id);


--
-- Name: reagent_lots reagent_lots_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_lots
    ADD CONSTRAINT reagent_lots_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id);


--
-- Name: reagent_production_lots reagent_production_lots_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_production_lots
    ADD CONSTRAINT reagent_production_lots_control_code_id_fkey FOREIGN KEY (control_code_id) REFERENCES public.reagent_lots(control_code_id);


--
-- Name: reagent_production_lots reagent_production_lots_ingredient_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_production_lots
    ADD CONSTRAINT reagent_production_lots_ingredient_control_code_id_fkey FOREIGN KEY (ingredient_control_code_id) REFERENCES public.reagent_lots(control_code_id);


--
-- Name: reagent_supplier_lot_cert_tests reagent_supplier_lot_cert_tests_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_supplier_lot_cert_tests
    ADD CONSTRAINT reagent_supplier_lot_cert_tests_control_code_id_fkey FOREIGN KEY (control_code_id) REFERENCES public.reagent_supplier_lots(control_code_id) NOT VALID;


--
-- Name: reagent_supplier_lot_cert_tests reagent_supplier_lot_cert_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_supplier_lot_cert_tests
    ADD CONSTRAINT reagent_supplier_lot_cert_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) NOT VALID;


--
-- Name: reagent_supplier_lots reagent_supplier_lots_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_supplier_lots
    ADD CONSTRAINT reagent_supplier_lots_control_code_id_fkey FOREIGN KEY (control_code_id) REFERENCES public.reagent_lots(control_code_id);


--
-- Name: reagent_supplier_lots reagent_supplier_lots_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reagent_supplier_lots
    ADD CONSTRAINT reagent_supplier_lots_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.reagent_suppliers(id);


--
-- Name: reception_tests reception_tests_reception_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reception_tests
    ADD CONSTRAINT reception_tests_reception_id_fkey FOREIGN KEY (reception_id) REFERENCES public.receptions(id);


--
-- Name: reception_tests reception_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reception_tests
    ADD CONSTRAINT reception_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: receptions receptions_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: receptions receptions_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_control_code_id_fkey FOREIGN KEY (control_code_id) REFERENCES public.control_codes(id);


--
-- Name: receptions receptions_reception_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_reception_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.reception_types(id);


--
-- Name: receptions receptions_user_received_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_user_received_id_fkey FOREIGN KEY (user_received_id) REFERENCES public.users(id);


--
-- Name: receptions receptions_user_rejected_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_user_rejected_id_fkey FOREIGN KEY (user_rejected_id) REFERENCES public.users(id);


--
-- Name: receptions receptions_user_submitted_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_user_submitted_id_fkey FOREIGN KEY (user_submitted_id) REFERENCES public.users(id);


--
-- Name: report_tests report_tests_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_tests
    ADD CONSTRAINT report_tests_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id);


--
-- Name: report_tests report_tests_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_tests
    ADD CONSTRAINT report_tests_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(id) ON DELETE CASCADE;


--
-- Name: report_tests report_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_tests
    ADD CONSTRAINT report_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: reports reports_reception_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_reception_id_fkey FOREIGN KEY (reception_id) REFERENCES public.receptions(id);


--
-- Name: reports reports_report_replaced_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_report_replaced_id_fkey FOREIGN KEY (report_replaced_id) REFERENCES public.reports(id);


--
-- Name: reports reports_user_cancelled_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_user_cancelled_id_fkey FOREIGN KEY (user_cancelled_id) REFERENCES public.users(id);


--
-- Name: reports reports_user_submitted_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_user_submitted_id_fkey FOREIGN KEY (user_submitted_id) REFERENCES public.users(id);


--
-- Name: sop_versions sop_versions_sop_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sop_versions
    ADD CONSTRAINT sop_versions_sop_id_fkey FOREIGN KEY (sop_id) REFERENCES public.sops(id) ON DELETE CASCADE;


--
-- Name: sops sops_norm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sops
    ADD CONSTRAINT sops_norm_id_fkey FOREIGN KEY (norm_id) REFERENCES public.norms(id) ON DELETE CASCADE;


--
-- Name: spec_test_evals spec_test_evals_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spec_test_evals
    ADD CONSTRAINT spec_test_evals_spec_id_fkey FOREIGN KEY (spec_id) REFERENCES public.specs(id);


--
-- Name: spec_test_evals spec_test_evals_spec_id_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spec_test_evals
    ADD CONSTRAINT spec_test_evals_spec_id_test_id_fkey FOREIGN KEY (spec_id, test_id) REFERENCES public.spec_tests(spec_id, test_id) ON DELETE CASCADE;


--
-- Name: spec_test_evals spec_test_evals_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spec_test_evals
    ADD CONSTRAINT spec_test_evals_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: spec_tests spec_tests_specs_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spec_tests
    ADD CONSTRAINT spec_tests_specs_id_fkey FOREIGN KEY (spec_id) REFERENCES public.specs(id) ON DELETE CASCADE;


--
-- Name: spec_tests spec_tests_tests_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spec_tests
    ADD CONSTRAINT spec_tests_tests_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: specs specs_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specs
    ADD CONSTRAINT specs_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: specs specs_spec_replaced_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specs
    ADD CONSTRAINT specs_spec_replaced_id_fkey FOREIGN KEY (spec_replaced_id) REFERENCES public.specs(id);


--
-- Name: specs specs_user_cancelled_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specs
    ADD CONSTRAINT specs_user_cancelled_id_fkey FOREIGN KEY (user_cancelled_id) REFERENCES public.users(id);


--
-- Name: specs specs_user_submitted_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specs
    ADD CONSTRAINT specs_user_submitted_id_fkey FOREIGN KEY (user_submitted_id) REFERENCES public.users(id);


--
-- Name: test_enums test_enums_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_enums
    ADD CONSTRAINT test_enums_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) ON DELETE CASCADE;


--
-- Name: test_equipments test_equipments_equipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_equipments
    ADD CONSTRAINT test_equipments_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipments(id) NOT VALID;


--
-- Name: test_equipments test_equipments_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_equipments
    ADD CONSTRAINT test_equipments_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) ON DELETE CASCADE;


--
-- Name: test_reagents test_reagents_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_reagents
    ADD CONSTRAINT test_reagents_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: test_reagents test_reagents_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_reagents
    ADD CONSTRAINT test_reagents_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) ON DELETE CASCADE;


--
-- Name: tests tests_norm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_norm_id_fkey FOREIGN KEY (norm_id) REFERENCES public.norms(id);


--
-- Name: tests tests_sop_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_sop_id_fkey FOREIGN KEY (sop_id) REFERENCES public.sops(id) NOT VALID;


--
-- Name: tests tests_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id);


--
-- Name: tests tests_value_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_value_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.value_types(id);


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: equipment_calibration_statuses; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.equipment_calibration_statuses VALUES (1, 'Pass');
INSERT INTO public.equipment_calibration_statuses VALUES (2, 'Fail');
INSERT INTO public.equipment_calibration_statuses VALUES (3, 'Limited Use');
INSERT INTO public.equipment_calibration_statuses VALUES (4, 'Passed');


--
-- Data for Name: equipment_statuses; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.equipment_statuses VALUES (1, 'Active');
INSERT INTO public.equipment_statuses VALUES (2, 'Inactive');
INSERT INTO public.equipment_statuses VALUES (3, 'Calibration Due');
INSERT INTO public.equipment_statuses VALUES (4, 'Out of Service');


--
-- Data for Name: reagent_lot_statuses; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.reagent_lot_statuses VALUES (1, 'Quarantined');
INSERT INTO public.reagent_lot_statuses VALUES (2, 'Active');
INSERT INTO public.reagent_lot_statuses VALUES (3, 'Expired');
INSERT INTO public.reagent_lot_statuses VALUES (4, 'Depleted');


--
-- Data for Name: reception_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.reception_types VALUES (1, 'Certification');
INSERT INTO public.reception_types VALUES (2, 'Verification');
INSERT INTO public.reception_types VALUES (3, 'Category Verification');


--
-- Data for Name: value_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.value_types OVERRIDING SYSTEM VALUE VALUES (1, 'integer');
INSERT INTO public.value_types OVERRIDING SYSTEM VALUE VALUES (2, 'real');
INSERT INTO public.value_types OVERRIDING SYSTEM VALUE VALUES (3, 'boolean');
INSERT INTO public.value_types OVERRIDING SYSTEM VALUE VALUES (4, 'enum');


--
-- Name: value_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.value_types_id_seq', 5, false);


--
-- PostgreSQL database dump complete
--

