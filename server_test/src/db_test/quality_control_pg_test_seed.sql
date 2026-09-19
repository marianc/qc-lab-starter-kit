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

ALTER TABLE IF EXISTS ONLY public.tests DROP CONSTRAINT IF EXISTS tests_value_type_id_fkey;
ALTER TABLE IF EXISTS ONLY public.tests DROP CONSTRAINT IF EXISTS tests_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY public.tests DROP CONSTRAINT IF EXISTS tests_sop_id_fkey;
ALTER TABLE IF EXISTS ONLY public.tests DROP CONSTRAINT IF EXISTS tests_norm_id_fkey;
ALTER TABLE IF EXISTS ONLY public.test_reagents DROP CONSTRAINT IF EXISTS test_reagents_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.test_reagents DROP CONSTRAINT IF EXISTS test_reagents_material_id_fkey;
ALTER TABLE IF EXISTS ONLY public.test_equipments DROP CONSTRAINT IF EXISTS test_equipments_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.test_equipments DROP CONSTRAINT IF EXISTS test_equipments_equipment_id_fkey;
ALTER TABLE IF EXISTS ONLY public.test_enums DROP CONSTRAINT IF EXISTS test_enums_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.specs DROP CONSTRAINT IF EXISTS specs_user_submitted_id_fkey;
ALTER TABLE IF EXISTS ONLY public.specs DROP CONSTRAINT IF EXISTS specs_user_cancelled_id_fkey;
ALTER TABLE IF EXISTS ONLY public.specs DROP CONSTRAINT IF EXISTS specs_spec_replaced_id_fkey;
ALTER TABLE IF EXISTS ONLY public.specs DROP CONSTRAINT IF EXISTS specs_material_id_fkey;
ALTER TABLE IF EXISTS ONLY public.spec_tests DROP CONSTRAINT IF EXISTS spec_tests_tests_id_fkey;
ALTER TABLE IF EXISTS ONLY public.spec_tests DROP CONSTRAINT IF EXISTS spec_tests_specs_id_fkey;
ALTER TABLE IF EXISTS ONLY public.spec_test_evals DROP CONSTRAINT IF EXISTS spec_test_evals_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.spec_test_evals DROP CONSTRAINT IF EXISTS spec_test_evals_spec_id_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.spec_test_evals DROP CONSTRAINT IF EXISTS spec_test_evals_spec_id_fkey;
ALTER TABLE IF EXISTS ONLY public.sops DROP CONSTRAINT IF EXISTS sops_norm_id_fkey;
ALTER TABLE IF EXISTS ONLY public.sop_versions DROP CONSTRAINT IF EXISTS sop_versions_sop_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reports DROP CONSTRAINT IF EXISTS reports_user_submitted_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reports DROP CONSTRAINT IF EXISTS reports_user_cancelled_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reports DROP CONSTRAINT IF EXISTS reports_report_replaced_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reports DROP CONSTRAINT IF EXISTS reports_reception_id_fkey;
ALTER TABLE IF EXISTS ONLY public.report_tests DROP CONSTRAINT IF EXISTS report_tests_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.report_tests DROP CONSTRAINT IF EXISTS report_tests_report_id_fkey;
ALTER TABLE IF EXISTS ONLY public.report_tests DROP CONSTRAINT IF EXISTS report_tests_measurement_id_fkey;
ALTER TABLE IF EXISTS ONLY public.receptions DROP CONSTRAINT IF EXISTS receptions_user_submitted_id_fkey;
ALTER TABLE IF EXISTS ONLY public.receptions DROP CONSTRAINT IF EXISTS receptions_user_rejected_id_fkey;
ALTER TABLE IF EXISTS ONLY public.receptions DROP CONSTRAINT IF EXISTS receptions_user_received_id_fkey;
ALTER TABLE IF EXISTS ONLY public.receptions DROP CONSTRAINT IF EXISTS receptions_reception_type_id_fkey;
ALTER TABLE IF EXISTS ONLY public.receptions DROP CONSTRAINT IF EXISTS receptions_control_code_id_fkey;
ALTER TABLE IF EXISTS ONLY public.receptions DROP CONSTRAINT IF EXISTS receptions_category_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reception_tests DROP CONSTRAINT IF EXISTS reception_tests_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reception_tests DROP CONSTRAINT IF EXISTS reception_tests_reception_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reagent_supplier_lots DROP CONSTRAINT IF EXISTS reagent_supplier_lots_supplier_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reagent_supplier_lots DROP CONSTRAINT IF EXISTS reagent_supplier_lots_control_code_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reagent_production_lots DROP CONSTRAINT IF EXISTS reagent_production_lots_ingredient_control_code_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reagent_production_lots DROP CONSTRAINT IF EXISTS reagent_production_lots_control_code_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reagent_lots DROP CONSTRAINT IF EXISTS reagent_lots_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reagent_lots DROP CONSTRAINT IF EXISTS reagent_lots_status_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reagent_lots DROP CONSTRAINT IF EXISTS reagent_lots_produced_by_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reagent_lots DROP CONSTRAINT IF EXISTS reagent_lots_control_code_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurements DROP CONSTRAINT IF EXISTS measurements_user_update_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurements DROP CONSTRAINT IF EXISTS measurements_user_reported_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurements DROP CONSTRAINT IF EXISTS measurements_user_created_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurements DROP CONSTRAINT IF EXISTS measurements_reception_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurements DROP CONSTRAINT IF EXISTS measurements_form_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurement_tests DROP CONSTRAINT IF EXISTS measurement_tests_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurement_tests DROP CONSTRAINT IF EXISTS measurement_tests_measurement_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurement_sop_versions DROP CONSTRAINT IF EXISTS measurement_sop_versions_sop_version_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurement_sop_versions DROP CONSTRAINT IF EXISTS measurement_sop_versions_measurement_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurement_reagent_lots DROP CONSTRAINT IF EXISTS measurement_reagent_lots_measurement_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurement_reagent_lots DROP CONSTRAINT IF EXISTS measurement_reagent_lots_control_code_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurement_params DROP CONSTRAINT IF EXISTS measurement_params_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurement_params DROP CONSTRAINT IF EXISTS measurement_params_measurement_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurement_params DROP CONSTRAINT IF EXISTS measurement_params_form_id_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurement_params DROP CONSTRAINT IF EXISTS measurement_params_form_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurement_equipments DROP CONSTRAINT IF EXISTS measurement_equipments_measurement_id_fkey;
ALTER TABLE IF EXISTS ONLY public.measurement_equipments DROP CONSTRAINT IF EXISTS measurement_equipments_equipment_id_fkey;
ALTER TABLE IF EXISTS ONLY public.materials DROP CONSTRAINT IF EXISTS materials_norm_id_fkey;
ALTER TABLE IF EXISTS ONLY public.material_tests DROP CONSTRAINT IF EXISTS material_tests_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.material_tests DROP CONSTRAINT IF EXISTS material_tests_material_id_fkey;
ALTER TABLE IF EXISTS ONLY public.forms DROP CONSTRAINT IF EXISTS forms_user_validated_id_fkey;
ALTER TABLE IF EXISTS ONLY public.forms DROP CONSTRAINT IF EXISTS forms_user_submitted_id_fkey;
ALTER TABLE IF EXISTS ONLY public.forms DROP CONSTRAINT IF EXISTS forms_user_canceled_id_fkey;
ALTER TABLE IF EXISTS ONLY public.forms DROP CONSTRAINT IF EXISTS forms_form_group_id_fkey;
ALTER TABLE IF EXISTS ONLY public.form_params DROP CONSTRAINT IF EXISTS form_params_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.form_params DROP CONSTRAINT IF EXISTS form_params_form_id_fkey;
ALTER TABLE IF EXISTS ONLY public.form_evals DROP CONSTRAINT IF EXISTS form_evals_form_id_fkey;
ALTER TABLE IF EXISTS ONLY public.form_eval_params DROP CONSTRAINT IF EXISTS form_eval_params_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.form_eval_params DROP CONSTRAINT IF EXISTS form_eval_params_form_id_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.form_eval_params DROP CONSTRAINT IF EXISTS form_eval_params_form_id_fkey;
ALTER TABLE IF EXISTS ONLY public.form_eval_params DROP CONSTRAINT IF EXISTS form_eval_params_eval_id_fkey;
ALTER TABLE IF EXISTS ONLY public.form_condition_evals DROP CONSTRAINT IF EXISTS form_condition_evals_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.form_condition_evals DROP CONSTRAINT IF EXISTS form_condition_evals_form_id_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.form_condition_evals DROP CONSTRAINT IF EXISTS form_condition_evals_form_id_fkey;
ALTER TABLE IF EXISTS ONLY public.equipment_calibrations DROP CONSTRAINT IF EXISTS equipment_calibrations_equipment_id_fkey;
ALTER TABLE IF EXISTS ONLY public.electronic_signatures DROP CONSTRAINT IF EXISTS electronic_signatures_signer_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.control_codes DROP CONSTRAINT IF EXISTS control_codes_material_id_fkey;
ALTER TABLE IF EXISTS ONLY public.certificates DROP CONSTRAINT IF EXISTS certificates_user_submitted_id_fkey;
ALTER TABLE IF EXISTS ONLY public.certificates DROP CONSTRAINT IF EXISTS certificates_user_cancelled_id_fkey;
ALTER TABLE IF EXISTS ONLY public.certificates DROP CONSTRAINT IF EXISTS certificates_specs_id_fkey;
ALTER TABLE IF EXISTS ONLY public.certificates DROP CONSTRAINT IF EXISTS certificates_control_code_id_fkey;
ALTER TABLE IF EXISTS ONLY public.certificates DROP CONSTRAINT IF EXISTS certificates_certificate_replaced_id_fkey;
ALTER TABLE IF EXISTS ONLY public.certificate_tests DROP CONSTRAINT IF EXISTS certificate_tests_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.certificate_tests DROP CONSTRAINT IF EXISTS certificate_tests_report_id_measurement_id_test_id_idx_fkey;
ALTER TABLE IF EXISTS ONLY public.certificate_tests DROP CONSTRAINT IF EXISTS certificate_tests_report_id_fkey;
ALTER TABLE IF EXISTS ONLY public.certificate_tests DROP CONSTRAINT IF EXISTS certificate_tests_measurement_id_fkey;
ALTER TABLE IF EXISTS ONLY public.certificate_tests DROP CONSTRAINT IF EXISTS certificate_tests_certificates_id_fkey;
ALTER TABLE IF EXISTS ONLY public.category_tests DROP CONSTRAINT IF EXISTS category_tests_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.category_tests DROP CONSTRAINT IF EXISTS category_tests_category_id_fkey;
ALTER TABLE IF EXISTS ONLY public.audit_logs DROP CONSTRAINT IF EXISTS audit_logs_user_id_fkey;
DROP TRIGGER IF EXISTS audit_measurements_trigger ON public.measurements;
DROP TRIGGER IF EXISTS audit_measurement_tests_trigger ON public.measurement_tests;
DROP TRIGGER IF EXISTS audit_measurement_params_trigger ON public.measurement_params;
DROP INDEX IF EXISTS public.unq_single_active_sop_version;
ALTER TABLE IF EXISTS ONLY public.value_types DROP CONSTRAINT IF EXISTS value_types_pkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_tag_key;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_session_id_key;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_code_key;
ALTER TABLE IF EXISTS ONLY public.sop_versions DROP CONSTRAINT IF EXISTS unq_sop_version_number;
ALTER TABLE IF EXISTS ONLY public.units DROP CONSTRAINT IF EXISTS units_pkey;
ALTER TABLE IF EXISTS ONLY public.units DROP CONSTRAINT IF EXISTS units_name_key;
ALTER TABLE IF EXISTS ONLY public.tests DROP CONSTRAINT IF EXISTS tests_pkey;
ALTER TABLE IF EXISTS ONLY public.tests DROP CONSTRAINT IF EXISTS tests_name_key;
ALTER TABLE IF EXISTS ONLY public.tests DROP CONSTRAINT IF EXISTS tests_code_key;
ALTER TABLE IF EXISTS ONLY public.test_reagents DROP CONSTRAINT IF EXISTS test_reagents_pkey;
ALTER TABLE IF EXISTS ONLY public.test_equipments DROP CONSTRAINT IF EXISTS test_equipments_pkey;
ALTER TABLE IF EXISTS ONLY public.test_enums DROP CONSTRAINT IF EXISTS test_enums_test_id_name_key;
ALTER TABLE IF EXISTS ONLY public.test_enums DROP CONSTRAINT IF EXISTS test_enums_pkey;
ALTER TABLE IF EXISTS ONLY public.specs DROP CONSTRAINT IF EXISTS specs_pkey;
ALTER TABLE IF EXISTS ONLY public.spec_tests DROP CONSTRAINT IF EXISTS spec_tests_pkey;
ALTER TABLE IF EXISTS ONLY public.spec_test_evals DROP CONSTRAINT IF EXISTS spec_test_evals_pkey;
ALTER TABLE IF EXISTS ONLY public.sops DROP CONSTRAINT IF EXISTS sops_pkey;
ALTER TABLE IF EXISTS ONLY public.sops DROP CONSTRAINT IF EXISTS sops_doc_code_key;
ALTER TABLE IF EXISTS ONLY public.sop_versions DROP CONSTRAINT IF EXISTS sop_versions_pkey;
ALTER TABLE IF EXISTS ONLY public.reports DROP CONSTRAINT IF EXISTS reports_pkey;
ALTER TABLE IF EXISTS ONLY public.report_tests DROP CONSTRAINT IF EXISTS report_tests_pkey;
ALTER TABLE IF EXISTS ONLY public.receptions DROP CONSTRAINT IF EXISTS receptions_pkey;
ALTER TABLE IF EXISTS ONLY public.reception_types DROP CONSTRAINT IF EXISTS reception_types_pkey;
ALTER TABLE IF EXISTS ONLY public.reception_tests DROP CONSTRAINT IF EXISTS reception_tests_pkey;
ALTER TABLE IF EXISTS ONLY public.reagent_suppliers DROP CONSTRAINT IF EXISTS reagent_suppliers_pkey;
ALTER TABLE IF EXISTS ONLY public.reagent_suppliers DROP CONSTRAINT IF EXISTS reagent_suppliers_name_key;
ALTER TABLE IF EXISTS ONLY public.reagent_supplier_lots DROP CONSTRAINT IF EXISTS reagent_supplier_lots_pkey;
ALTER TABLE IF EXISTS ONLY public.reagent_production_lots DROP CONSTRAINT IF EXISTS reagent_production_lots_pkey;
ALTER TABLE IF EXISTS ONLY public.reagent_lots DROP CONSTRAINT IF EXISTS reagent_lots_pkey;
ALTER TABLE IF EXISTS ONLY public.reagent_lot_statuses DROP CONSTRAINT IF EXISTS reagent_lot_statuses_pkey;
ALTER TABLE IF EXISTS ONLY public.reagent_lot_statuses DROP CONSTRAINT IF EXISTS reagent_lot_statuses_name_key;
ALTER TABLE IF EXISTS ONLY public.norms DROP CONSTRAINT IF EXISTS norms_pkey;
ALTER TABLE IF EXISTS ONLY public.norms DROP CONSTRAINT IF EXISTS norms_name_key;
ALTER TABLE IF EXISTS ONLY public.measurements DROP CONSTRAINT IF EXISTS measurements_pkey;
ALTER TABLE IF EXISTS ONLY public.measurement_tests DROP CONSTRAINT IF EXISTS measurement_tests_pkey;
ALTER TABLE IF EXISTS ONLY public.measurement_sop_versions DROP CONSTRAINT IF EXISTS measurement_sop_versions_pkey;
ALTER TABLE IF EXISTS ONLY public.measurement_reagent_lots DROP CONSTRAINT IF EXISTS measurement_reagent_lots_pkey;
ALTER TABLE IF EXISTS ONLY public.measurement_params DROP CONSTRAINT IF EXISTS measurement_params_pkey;
ALTER TABLE IF EXISTS ONLY public.measurement_equipments DROP CONSTRAINT IF EXISTS measurement_equipments_pkey;
ALTER TABLE IF EXISTS ONLY public.materials DROP CONSTRAINT IF EXISTS materials_pkey;
ALTER TABLE IF EXISTS ONLY public.materials DROP CONSTRAINT IF EXISTS materials_name_key;
ALTER TABLE IF EXISTS ONLY public.materials DROP CONSTRAINT IF EXISTS materials_code_key;
ALTER TABLE IF EXISTS ONLY public.material_tests DROP CONSTRAINT IF EXISTS material_tests_pkey;
ALTER TABLE IF EXISTS ONLY public.forms DROP CONSTRAINT IF EXISTS forms_pkey;
ALTER TABLE IF EXISTS ONLY public.form_params DROP CONSTRAINT IF EXISTS form_params_pkey;
ALTER TABLE IF EXISTS ONLY public.form_groups DROP CONSTRAINT IF EXISTS form_groups_pkey;
ALTER TABLE IF EXISTS ONLY public.form_evals DROP CONSTRAINT IF EXISTS form_evals_pkey;
ALTER TABLE IF EXISTS ONLY public.form_eval_params DROP CONSTRAINT IF EXISTS form_eval_params_pkey;
ALTER TABLE IF EXISTS ONLY public.form_condition_evals DROP CONSTRAINT IF EXISTS form_condition_evals_pkey;
ALTER TABLE IF EXISTS ONLY public.equipments DROP CONSTRAINT IF EXISTS equipment_pkey;
ALTER TABLE IF EXISTS ONLY public.equipments DROP CONSTRAINT IF EXISTS equipment_equipment_code_key;
ALTER TABLE IF EXISTS ONLY public.equipment_calibrations DROP CONSTRAINT IF EXISTS equipment_calibrations_pkey;
ALTER TABLE IF EXISTS ONLY public.electronic_signatures DROP CONSTRAINT IF EXISTS electronic_signatures_pkey;
ALTER TABLE IF EXISTS ONLY public.control_codes DROP CONSTRAINT IF EXISTS control_codes_pkey;
ALTER TABLE IF EXISTS ONLY public.certificates DROP CONSTRAINT IF EXISTS certificates_pkey;
ALTER TABLE IF EXISTS ONLY public.certificate_tests DROP CONSTRAINT IF EXISTS certificate_tests_pkey;
ALTER TABLE IF EXISTS ONLY public.category_tests DROP CONSTRAINT IF EXISTS category_tests_pkey;
ALTER TABLE IF EXISTS ONLY public.categories DROP CONSTRAINT IF EXISTS categories_pkey;
ALTER TABLE IF EXISTS ONLY public.categories DROP CONSTRAINT IF EXISTS categories_name_key;
ALTER TABLE IF EXISTS ONLY public.categories DROP CONSTRAINT IF EXISTS categories_code_key;
ALTER TABLE IF EXISTS ONLY public.audit_logs DROP CONSTRAINT IF EXISTS audit_logs_pkey;
DROP TABLE IF EXISTS public.value_types;
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.units;
DROP TABLE IF EXISTS public.tests;
DROP TABLE IF EXISTS public.test_reagents;
DROP TABLE IF EXISTS public.test_equipments;
DROP TABLE IF EXISTS public.test_enums;
DROP TABLE IF EXISTS public.spec_tests;
DROP TABLE IF EXISTS public.spec_test_evals;
DROP TABLE IF EXISTS public.specs;
DROP TABLE IF EXISTS public.sops;
DROP TABLE IF EXISTS public.sop_versions;
DROP TABLE IF EXISTS public.reports;
DROP TABLE IF EXISTS public.report_tests;
DROP TABLE IF EXISTS public.receptions;
DROP TABLE IF EXISTS public.reception_types;
DROP TABLE IF EXISTS public.reception_tests;
DROP TABLE IF EXISTS public.reagent_suppliers;
DROP TABLE IF EXISTS public.reagent_supplier_lots;
DROP TABLE IF EXISTS public.reagent_production_lots;
DROP TABLE IF EXISTS public.reagent_lots;
DROP TABLE IF EXISTS public.reagent_lot_statuses;
DROP TABLE IF EXISTS public.norms;
DROP TABLE IF EXISTS public.measurement_tests;
DROP TABLE IF EXISTS public.measurement_sop_versions;
DROP TABLE IF EXISTS public.measurement_reagent_lots;
DROP TABLE IF EXISTS public.measurement_params;
DROP TABLE IF EXISTS public.measurement_equipments;
DROP TABLE IF EXISTS public.measurements;
DROP TABLE IF EXISTS public.materials;
DROP TABLE IF EXISTS public.material_tests;
DROP TABLE IF EXISTS public.forms;
DROP TABLE IF EXISTS public.form_params;
DROP TABLE IF EXISTS public.form_groups;
DROP TABLE IF EXISTS public.form_evals;
DROP TABLE IF EXISTS public.form_eval_params;
DROP TABLE IF EXISTS public.form_condition_evals;
DROP TABLE IF EXISTS public.equipments;
DROP TABLE IF EXISTS public.equipment_calibrations;
DROP TABLE IF EXISTS public.electronic_signatures;
DROP TABLE IF EXISTS public.control_codes;
DROP TABLE IF EXISTS public.certificates;
DROP TABLE IF EXISTS public.certificate_tests;
DROP TABLE IF EXISTS public.category_tests;
DROP TABLE IF EXISTS public.categories;
DROP TABLE IF EXISTS public.audit_logs;
DROP FUNCTION IF EXISTS public.process_audit_log();
--
-- Name: process_audit_log(); Type: FUNCTION; Schema: public; Owner: -
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


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id bigint NOT NULL,
    name character varying(50) NOT NULL,
    code character varying(3) NOT NULL,
    description text,
    date_created timestamp with time zone NOT NULL,
    is_obsolete boolean DEFAULT false NOT NULL,
    date_obsolete timestamp with time zone,
    comments_obsolete text
);


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: category_tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.category_tests (
    category_id bigint NOT NULL,
    test_id bigint NOT NULL
);


--
-- Name: certificate_tests; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: certificates; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: certification_headers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: control_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.control_codes (
    id bigint NOT NULL,
    material_id bigint NOT NULL,
    code character varying(50) NOT NULL,
    is_reception_received boolean DEFAULT false NOT NULL,
    date_created timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: electronic_signatures; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: electronic_signatures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: equipment_calibrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.equipment_calibrations (
    id bigint NOT NULL,
    equipment_id bigint NOT NULL,
    calibration_date date NOT NULL,
    expiration_date date NOT NULL,
    certificate_number character varying(100) NOT NULL,
    calibrated_by character varying(100) NOT NULL,
    result_status character varying(20) NOT NULL,
    reference_standards_used text,
    expanded_uncertainty numeric,
    date_created timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: equipment_calibrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: equipments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.equipments (
    id bigint NOT NULL,
    equipment_code character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    manufacturer character varying(100),
    model character varying(100),
    serial_number character varying(100) NOT NULL,
    location character varying(100),
    status character varying(20) DEFAULT 'Active'::character varying NOT NULL,
    calibration_interval_days integer DEFAULT 365,
    next_calibration_due date,
    date_created timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: equipment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: form_condition_evals; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: form_condition_evals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: form_eval_params; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: form_evals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.form_evals (
    id bigint NOT NULL,
    form_id bigint NOT NULL,
    description text
);


--
-- Name: form_evals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: form_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.form_groups (
    id bigint NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    nr_ord bigint DEFAULT 0 NOT NULL,
    is_form_validated boolean DEFAULT false NOT NULL
);


--
-- Name: form_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: form_params; Type: TABLE; Schema: public; Owner: -
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
    nr_ord bigint DEFAULT 0 NOT NULL,
    nr_ord_calc bigint DEFAULT 0 NOT NULL
);


--
-- Name: forms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.forms (
    id bigint NOT NULL,
    form_group_id bigint NOT NULL,
    version character varying(50) NOT NULL,
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


--
-- Name: forms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: material_tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.material_tests (
    material_id bigint NOT NULL,
    test_id bigint NOT NULL
);


--
-- Name: materials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materials (
    id bigint NOT NULL,
    name character varying(50) NOT NULL,
    code character varying(5) NOT NULL,
    description text,
    norm_id bigint,
    is_product boolean DEFAULT false NOT NULL,
    is_raw_material boolean DEFAULT false NOT NULL,
    is_reagent boolean DEFAULT false NOT NULL,
    cas_number character varying(20),
    date_created timestamp with time zone NOT NULL,
    is_obsolete boolean DEFAULT false NOT NULL,
    date_obsolete timestamp with time zone,
    comments_obsolete text
);


--
-- Name: materials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: measurements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.measurements (
    id bigint NOT NULL,
    reception_id bigint NOT NULL,
    form_id bigint,
    comments text,
    use_default_equipment boolean DEFAULT true NOT NULL,
    user_update_id bigint NOT NULL,
    date_update timestamp with time zone NOT NULL,
    is_reported boolean DEFAULT false NOT NULL,
    user_reported_id bigint,
    date_reported timestamp with time zone,
    is_readonly boolean DEFAULT false NOT NULL,
    date_readonly timestamp with time zone,
    user_created_id bigint DEFAULT 1 NOT NULL,
    date_created timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: measurement_details_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: measurement_equipments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.measurement_equipments (
    measurement_id bigint NOT NULL,
    equipment_id bigint NOT NULL
);


--
-- Name: measurement_params; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.measurement_params (
    measurement_id bigint NOT NULL,
    form_id bigint NOT NULL,
    test_id bigint NOT NULL,
    idx integer DEFAULT 0 NOT NULL,
    value numeric NOT NULL,
    condition_value numeric
);


--
-- Name: measurement_reagent_lots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.measurement_reagent_lots (
    measurement_id bigint NOT NULL,
    control_code_id bigint NOT NULL
);


--
-- Name: measurement_sop_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.measurement_sop_versions (
    measurement_id bigint NOT NULL,
    sop_version_id bigint NOT NULL
);


--
-- Name: measurement_tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.measurement_tests (
    measurement_id bigint NOT NULL,
    test_id bigint NOT NULL,
    idx integer DEFAULT 0 NOT NULL,
    value numeric NOT NULL,
    note character varying(20)
);


--
-- Name: norms; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: norms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: reagent_lot_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reagent_lot_statuses (
    id bigint NOT NULL,
    name character varying(50) NOT NULL
);


--
-- Name: reagent_lots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reagent_lots (
    control_code_id bigint NOT NULL,
    is_produced boolean DEFAULT false NOT NULL,
    produced_by_user_id bigint,
    status_id bigint DEFAULT 1 NOT NULL,
    unit_id bigint,
    quantity numeric NOT NULL,
    expiration_date date NOT NULL
);


--
-- Name: reagent_production_lots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reagent_production_lots (
    control_code_id bigint NOT NULL,
    ingredient_control_code_id bigint NOT NULL
);


--
-- Name: reagent_supplier_lots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reagent_supplier_lots (
    control_code_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    catalog_number character varying(50),
    manufacturer_lot_number character varying(50) NOT NULL,
    certificate_of_analysis_ref character varying(255),
    comments character varying(100)
);


--
-- Name: reagent_suppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reagent_suppliers (
    id bigint NOT NULL,
    name character varying(100) NOT NULL
);


--
-- Name: reagent_suppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: reception_tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reception_tests (
    reception_id bigint NOT NULL,
    test_id bigint NOT NULL
);


--
-- Name: reception_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reception_types (
    id bigint NOT NULL,
    name character varying(50) NOT NULL
);


--
-- Name: receptions; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: receptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: receptions_id_seq1; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: report_tests; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: reports; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: sop_versions; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: sop_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: sops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sops (
    id bigint NOT NULL,
    doc_code character varying(50) NOT NULL,
    title character varying(150) NOT NULL,
    norm_id bigint,
    date_created timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: sops_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: specs; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: spec_headers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: spec_test_evals; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: spec_test_evals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: spec_tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.spec_tests (
    spec_id bigint NOT NULL,
    test_id bigint NOT NULL,
    condition character varying(255) NOT NULL,
    note character varying(150) NOT NULL,
    use_uncertainty boolean DEFAULT false NOT NULL,
    test_frequency integer NOT NULL
);


--
-- Name: test_enums; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_enums (
    test_id bigint NOT NULL,
    value bigint NOT NULL,
    name character varying(50) NOT NULL,
    nr_ord bigint DEFAULT 0 NOT NULL,
    is_obsolete boolean DEFAULT false NOT NULL
);


--
-- Name: test_equipments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_equipments (
    test_id bigint NOT NULL,
    equipment_id bigint NOT NULL
);


--
-- Name: test_reagents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_reagents (
    test_id bigint NOT NULL,
    material_id bigint NOT NULL
);


--
-- Name: tests; Type: TABLE; Schema: public; Owner: -
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
    unit_id bigint,
    norm_id bigint,
    norm_ref character varying(50),
    sop_id bigint,
    for_certification boolean DEFAULT false NOT NULL,
    relative_uncertainty_pct numeric(5,2),
    default_coverage_factor_k numeric(3,1),
    nr_ord bigint DEFAULT 0 NOT NULL,
    is_form_validated boolean DEFAULT false NOT NULL,
    date_form_validated timestamp with time zone,
    date_created timestamp with time zone NOT NULL,
    is_obsolete boolean DEFAULT false NOT NULL,
    date_obsolete timestamp with time zone,
    comments_obsolete text
);


--
-- Name: tests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: units; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.units (
    id bigint NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    date_created timestamp with time zone NOT NULL
);


--
-- Name: units_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: users; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: value_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.value_types (
    id bigint NOT NULL,
    name character varying(50) NOT NULL
);


--
-- Name: value_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.categories (id, name, code, description, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (1, 'Category A', 'CA', 'Description for Category A', '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.categories (id, name, code, description, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (2, 'Category B', 'CB', 'Description for Category B', '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.categories (id, name, code, description, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (3, 'Category C', 'CC', 'Description for Category C', '2026-01-23 22:46:06.788548+02', true, '2026-01-23 22:46:55.808578+02', 'Some explanations ...');


--
-- Data for Name: category_tests; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.category_tests (category_id, test_id) VALUES (2, 2);
INSERT INTO public.category_tests (category_id, test_id) VALUES (2, 4);
INSERT INTO public.category_tests (category_id, test_id) VALUES (1, 1);
INSERT INTO public.category_tests (category_id, test_id) VALUES (1, 3);
INSERT INTO public.category_tests (category_id, test_id) VALUES (1, 4);
INSERT INTO public.category_tests (category_id, test_id) VALUES (3, 1);
INSERT INTO public.category_tests (category_id, test_id) VALUES (3, 2);
INSERT INTO public.category_tests (category_id, test_id) VALUES (3, 5);
INSERT INTO public.category_tests (category_id, test_id) VALUES (3, 28);
INSERT INTO public.category_tests (category_id, test_id) VALUES (3, 37);
INSERT INTO public.category_tests (category_id, test_id) VALUES (3, 45);


--
-- Data for Name: certificate_tests; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (6, 25, 39, 3, 0, 150, NULL, NULL, true, true, '> 100', 1);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (6, 25, 39, 4, 0, 600.5, NULL, NULL, true, true, '< 1000', 1);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (6, 25, 46, 3, 0, 454.34, NULL, NULL, true, true, '> 100', 1);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (6, 25, 46, 28, 0, 175.5, NULL, NULL, true, true, '<= 50 or > 100', 1);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (6, 25, 46, 37, 0, 111, NULL, NULL, true, true, '> 100 and <= 500', 1);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (6, 25, 46, 37, 1, 333, NULL, NULL, true, true, '> 100 and <= 500', 1);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (6, 25, 46, 37, 2, 444, NULL, NULL, true, true, '> 100 and <= 500', 1);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (6, 25, 46, 38, 0, 3, NULL, NULL, true, true, '''Item KB'' or ''Item KC''', 1);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (7, 26, 47, 28, 0, 252.4, NULL, NULL, true, true, '<= 50 or > 100', 1);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (7, 26, 47, 37, 0, 222, NULL, NULL, true, true, '> 100 and <= 500', 1);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (7, 26, 47, 37, 1, 333, NULL, NULL, true, true, '> 100 and <= 500', 1);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (7, 26, 47, 38, 0, 3, NULL, NULL, true, true, '''Item KB'' or ''Item KC''', 1);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (7, 25, 39, 3, 0, 150, NULL, NULL, true, true, '> 100', 2);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (7, 25, 39, 4, 0, 600.5, NULL, NULL, true, true, '< 1000', 2);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (7, 25, 46, 3, 0, 454.34, NULL, NULL, true, true, '> 100', 2);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (8, 25, 39, 4, 0, 600.5, NULL, NULL, true, true, '< 1000', 3);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (8, 28, 48, 28, 0, 192.6, NULL, NULL, true, true, '<= 50 or > 100', 1);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (8, 28, 48, 37, 0, 333, NULL, NULL, true, true, '> 100 and <= 500', 1);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (8, 28, 48, 37, 1, 444, NULL, NULL, true, true, '> 100 and <= 500', 1);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (8, 28, 48, 38, 0, 2, NULL, NULL, true, true, '''Item KB'' or ''Item KC''', 1);
INSERT INTO public.certificate_tests (certificate_id, report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k, is_conforming_spec, is_conforming_uncertainty, note_spec, test_count) VALUES (8, 28, 49, 3, 0, 862.4, NULL, NULL, true, true, '> 100', 1);


--
-- Data for Name: certificates; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.certificates (id, control_code_id, spec_id, is_conforming_spec, is_conforming_uncertainty, is_submitted, user_submitted_id, date_submitted, comments_submitted, certificate_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (6, 34, 11, true, true, true, 1, '2025-12-13 18:17:42.218999+02', 'All testing results are according to specification
All mandatory tests have been performed', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates (id, control_code_id, spec_id, is_conforming_spec, is_conforming_uncertainty, is_submitted, user_submitted_id, date_submitted, comments_submitted, certificate_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (7, 35, 11, true, true, true, 1, '2025-12-13 18:17:42.218999+02', 'All testing results are according to specification
All mandatory tests have been performed', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates (id, control_code_id, spec_id, is_conforming_spec, is_conforming_uncertainty, is_submitted, user_submitted_id, date_submitted, comments_submitted, certificate_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (8, 63, 11, true, true, false, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL);


--
-- Data for Name: control_codes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (1, 15, 'BATCH-REC-1-1', false, '2026-09-08 17:52:10.340701+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (2, 15, 'SN-REC-1-2', false, '2026-09-08 17:52:10.341082+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (3, 18, 'BATCH-REC-1-3', false, '2026-09-08 17:52:10.341086+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (4, 15, 'SN-REC-1-4', false, '2026-09-08 17:52:10.341088+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (5, 20, 'BATCH-REC-1-5', false, '2026-09-08 17:52:10.341089+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (6, 1, 'SN-REC-2-1', false, '2026-09-08 17:52:10.34109+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (7, 15, 'SN-REC-2-2', false, '2026-09-08 17:52:10.341092+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (8, 15, 'SN-REC-2-3', false, '2026-09-08 17:52:10.341093+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (9, 20, 'SN-REC-2-4', false, '2026-09-08 17:52:10.341094+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (10, 17, 'DEL-CODE-3-1', false, '2026-09-08 17:52:10.341095+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (11, 17, 'DEL-CODE-3-2', false, '2026-09-08 17:52:10.341097+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (12, 21, 'DEL-CODE-4-1', false, '2026-09-08 17:52:10.341098+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (13, 17, 'DEL-CODE-4-2', false, '2026-09-08 17:52:10.341099+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (14, 19, 'DEL-CODE-4-3', false, '2026-09-08 17:52:10.3411+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (15, 1, 'STORAGE-CODE-5-1', false, '2026-09-08 17:52:10.341102+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (16, 18, 'STORAGE-CODE-5-2', false, '2026-09-08 17:52:10.341103+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (17, 20, 'STORAGE-CODE-5-3', false, '2026-09-08 17:52:10.341104+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (18, 18, 'STORAGE-CODE-6-1', false, '2026-09-08 17:52:10.341105+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (19, 18, 'STORAGE-CODE-6-2', false, '2026-09-08 17:52:10.341106+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (20, 18, 'OWNERSHIP-CODE-7-1', false, '2026-09-08 17:52:10.341107+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (21, 8, 'OWNERSHIP-CODE-7-2', false, '2026-09-08 17:52:10.341108+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (22, 15, 'OWNERSHIP-CODE-7-3', false, '2026-09-08 17:52:10.341109+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (23, 18, 'OWNERSHIP-CODE-8-1', false, '2026-09-08 17:52:10.34111+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (24, 17, 'OWNERSHIP-CODE-8-2', false, '2026-09-08 17:52:10.341111+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (25, 17, 'OWNERSHIP-CODE-8-3', false, '2026-09-08 17:52:10.341112+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (26, 20, 'GEN-1-CODE-9-1', false, '2026-09-08 17:52:10.341113+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (27, 11, 'GEN-1-CODE-9-2', false, '2026-09-08 17:52:10.341115+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (28, 6, 'GEN-1-CODE-9-3', false, '2026-09-08 17:52:10.341116+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (29, 15, 'GEN-1-CODE-9-4', false, '2026-09-08 17:52:10.34112+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (30, 3, 'GEN-2-CODE-10-1', false, '2026-09-08 17:52:10.341122+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (31, 19, 'GEN-2-CODE-10-2', false, '2026-09-08 17:52:10.341123+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (32, 15, 'GEN-2-CODE-10-3', false, '2026-09-08 17:52:10.341124+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (33, 4, 'GEN-2-CODE-10-4', false, '2026-09-08 17:52:10.341125+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (34, 5, 'GEN-2-CODE-10-5', true, '2026-09-08 17:52:10.341126+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (35, 5, 'GEN-3-CODE-11-1', true, '2026-09-08 17:52:10.341127+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (36, 13, 'GEN-3-CODE-11-2', false, '2026-09-08 17:52:10.341128+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (37, 20, 'GEN-3-CODE-11-3', false, '2026-09-08 17:52:10.341147+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (38, 20, 'GEN-3-CODE-11-4', false, '2026-09-08 17:52:10.341165+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (39, 13, 'GEN-3-CODE-11-5', false, '2026-09-08 17:52:10.341166+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (40, 21, 'PROD-A-1-212858', false, '2026-09-08 17:52:10.341168+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (41, 1, 'GEN-1-2025-07-15', false, '2026-09-08 17:52:10.341169+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (42, 2, 'GEN-2-2025-07-15', false, '2026-09-08 17:52:10.34117+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (43, 3, 'GEN-3-2025-07-15', false, '2026-09-08 17:52:10.341171+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (44, 21, 'PROD-A-2-212858', false, '2026-09-08 17:52:10.341172+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (45, 1, 'GEN-1-2025-07-05', false, '2026-09-08 17:52:10.341173+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (46, 2, 'GEN-2-2025-07-05', false, '2026-09-08 17:52:10.341174+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (47, 21, 'PROD-A-3-212858', false, '2026-09-08 17:52:10.341175+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (48, 1, 'GEN-1-2025-06-25', false, '2026-09-08 17:52:10.341176+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (49, 2, 'GEN-2-2025-06-25', false, '2026-09-08 17:52:10.341177+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (50, 3, 'GEN-3-2025-06-25', false, '2026-09-08 17:52:10.341178+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (51, 21, 'PROD-A-4-212858', false, '2026-09-08 17:52:10.34118+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (52, 1, 'GEN-1-2025-06-15', false, '2026-09-08 17:52:10.341181+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (53, 2, 'GEN-2-2025-06-15', false, '2026-09-08 17:52:10.341182+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (54, 21, 'PROD-A-5-212858', false, '2026-09-08 17:52:10.341183+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (55, 1, 'GEN-1-2025-06-05', false, '2026-09-08 17:52:10.341184+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (56, 2, 'GEN-2-2025-06-05', false, '2026-09-08 17:52:10.341185+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (57, 3, 'GEN-3-2025-06-05', false, '2026-09-08 17:52:10.341186+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (58, 21, 'PROD-A-6-212858', false, '2026-09-08 17:52:10.341187+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (59, 1, 'GEN-1-2025-05-26', true, '2026-09-08 17:52:10.341188+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (60, 2, 'GEN-2-2025-05-26', true, '2026-09-08 17:52:10.341189+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (62, 4, 'GEN-4-2025-06-25', false, '2026-09-08 17:52:10.341191+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (63, 5, 'GEN-5-2025-06-25', true, '2026-09-08 17:52:10.341192+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (64, 3, 'GEN-3-2025-05-26', false, '2026-09-08 17:52:10.341193+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (65, 4, 'GEN-4-2025-05-26', false, '2026-09-08 17:52:10.341194+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (66, 3, 'GEN-3-2025-04-26', false, '2026-09-08 17:52:10.341195+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (67, 4, 'GEN-4-2025-04-26', false, '2026-09-08 17:52:10.341196+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (68, 5, 'GEN-5-2025-04-26', false, '2026-09-08 17:52:10.341197+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (69, 3, 'GEN-3-2025-03-27', true, '2026-09-08 17:52:10.341203+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (70, 4, 'GEN-4-2025-03-27', true, '2026-09-08 17:52:10.341205+03');
INSERT INTO public.control_codes (id, material_id, code, is_reception_received, date_created) OVERRIDING SYSTEM VALUE VALUES (71, 2, 'WERT-TER-ERT-ER', false, '2026-09-08 17:52:10.341206+03');


--
-- Data for Name: electronic_signatures; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: equipment_calibrations; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: equipments; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: form_condition_evals; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: form_eval_params; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (1, 1, 3, 0, 1288.87, 1288.87, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (1, 1, 6, 0, 434.54, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (1, 1, 7, 0, 433.234, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (1, 1, 8, 0, 3, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (1, 1, 9, 0, 645, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (1, 1, 10, 0, 0, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (1, 1, 11, 0, 643.87, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (2, 1, 3, 0, 1100.74, 1100.74, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (2, 1, 6, 0, 645.4, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (2, 1, 7, 0, 455.34, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (2, 1, 8, 0, 2, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (2, 1, 9, 0, 546.89, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (2, 1, 10, 0, 1, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (2, 1, 11, 0, 433.45, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (3, 2, 1, 0, 456.5, 456.5, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (3, 2, 12, 0, 756.7, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (3, 2, 13, 0, 2, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (3, 2, 14, 0, 456.5, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (4, 2, 1, 0, 45.545, 45.545, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (4, 2, 12, 0, 45.545, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (4, 2, 13, 0, 1, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (4, 2, 14, 0, 65.645, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (5, 3, 1, 0, 259073, 259073, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (5, 3, 2, 0, 1024.01, 1024.01, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (5, 3, 3, 0, 567.47, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (5, 3, 19, 0, 456.54, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (6, 3, 1, 0, 2501.47, 2501.47, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (6, 3, 2, 0, 100.427, 100.427, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (6, 3, 3, 0, 45.75, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (6, 3, 19, 0, 54.677, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (7, 4, 1, 0, 459.962, 459.962, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (7, 4, 21, 0, 346.45, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (7, 4, 22, 0, 56.756, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (8, 4, 1, 0, 192.112, 192.112, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (8, 4, 21, 0, 56.756, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (8, 4, 22, 0, 67.678, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (9, 5, 2, 0, 379.299, 379.299, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (9, 5, 24, 0, 645.65, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (9, 5, 25, 0, 56.474, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (10, 5, 2, 0, 1140.74, 1140.74, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (10, 5, 24, 0, 564.576, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (10, 5, 25, 0, 858.456, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (11, 6, 4, 0, 304.317, 304.317, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (11, 6, 27, 0, 456.476, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (12, 6, 4, 0, 4304.44, 4304.44, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (12, 6, 27, 0, 6456.65, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (13, 7, 28, 0, 494.829, 494.829, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (13, 7, 29, 0, 567.5, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (13, 7, 30, 0, 345.357, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (13, 7, 30, 1, 564.564, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (13, 7, 30, 2, 574.567, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (13, 7, 31, 0, 5674, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (13, 7, 36, 0, 456.867, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (13, 7, 36, 1, 456.566, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (13, 7, 36, 2, 756.75, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (13, 7, 37, 0, 2788250, 2788250, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (13, 7, 37, 1, 2910940, 2910940, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (13, 7, 37, 2, 4619870, 4619870, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (13, 7, 38, 0, 2, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (15, 7, 28, 0, 74.7087, 74.7087, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (15, 7, 29, 0, 64.5657, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (15, 7, 30, 0, 64.564, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (15, 7, 30, 1, 73.4568, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (15, 7, 30, 2, 67.347, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (15, 7, 30, 3, 93.467, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (15, 7, 31, 0, 45.345, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (15, 7, 36, 0, 85.4342, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (15, 7, 36, 1, 89.7366, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (15, 7, 36, 2, 78.4335, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (15, 7, 36, 3, 54.5357, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (15, 7, 37, 0, 8042.63, 8042.63, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (15, 7, 37, 1, 8811.89, 8811.89, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (15, 7, 37, 2, 7904.87, 7904.87, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (15, 7, 37, 3, 8507.68, 8507.68, true);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (15, 7, 38, 0, 4, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 29, 0, 53.453, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 30, 0, 63.4345, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 30, 1, 65.456, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 30, 2, 66.423, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 31, 0, 45.6456, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 36, 0, 34.5345, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 36, 1, 45.6456, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 36, 2, 84.57, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 38, 0, 4, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 39, 0, 2, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 39, 1, 3, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 39, 2, 1, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 40, 0, 0, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 40, 1, 0, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 40, 2, 0, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 41, 0, 0, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 45, 0, 1, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 45, 1, 2, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 45, 3, 2, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 28, 0, 65.1045, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 37, 0, 4969.11, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 37, 1, 5585.34, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 37, 2, 7411.76, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 42, 0, 1, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 43, 0, 1, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 43, 1, 1, NULL, false);
INSERT INTO public.form_eval_params (eval_id, form_id, test_id, idx, value, expected_value, is_match) VALUES (14, 8, 43, 2, 1, NULL, false);


--
-- Data for Name: form_evals; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.form_evals (id, form_id, description) OVERRIDING SYSTEM VALUE VALUES (1, 1, 'Test Case 1');
INSERT INTO public.form_evals (id, form_id, description) OVERRIDING SYSTEM VALUE VALUES (2, 1, 'Test Case 2');
INSERT INTO public.form_evals (id, form_id, description) OVERRIDING SYSTEM VALUE VALUES (3, 2, 'Test Case 1');
INSERT INTO public.form_evals (id, form_id, description) OVERRIDING SYSTEM VALUE VALUES (4, 2, 'Test Case 2');
INSERT INTO public.form_evals (id, form_id, description) OVERRIDING SYSTEM VALUE VALUES (5, 3, 'Test Case 1');
INSERT INTO public.form_evals (id, form_id, description) OVERRIDING SYSTEM VALUE VALUES (6, 3, 'Test Case 2');
INSERT INTO public.form_evals (id, form_id, description) OVERRIDING SYSTEM VALUE VALUES (7, 4, 'Test Case 1');
INSERT INTO public.form_evals (id, form_id, description) OVERRIDING SYSTEM VALUE VALUES (8, 4, 'Test Case 2');
INSERT INTO public.form_evals (id, form_id, description) OVERRIDING SYSTEM VALUE VALUES (9, 5, 'Test Case 1');
INSERT INTO public.form_evals (id, form_id, description) OVERRIDING SYSTEM VALUE VALUES (10, 5, 'Test Case 2');
INSERT INTO public.form_evals (id, form_id, description) OVERRIDING SYSTEM VALUE VALUES (11, 6, 'Test Case 1');
INSERT INTO public.form_evals (id, form_id, description) OVERRIDING SYSTEM VALUE VALUES (12, 6, 'Test Case 2');
INSERT INTO public.form_evals (id, form_id, description) OVERRIDING SYSTEM VALUE VALUES (13, 7, 'Test Case 1');
INSERT INTO public.form_evals (id, form_id, description) OVERRIDING SYSTEM VALUE VALUES (14, 8, 'Test Case 1');
INSERT INTO public.form_evals (id, form_id, description) OVERRIDING SYSTEM VALUE VALUES (15, 7, 'Test Case 2');


--
-- Data for Name: form_groups; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.form_groups (id, name, description, nr_ord, is_form_validated) OVERRIDING SYSTEM VALUE VALUES (1, 'Testing Form A', 'Description Testing Form A', 1, true);
INSERT INTO public.form_groups (id, name, description, nr_ord, is_form_validated) OVERRIDING SYSTEM VALUE VALUES (2, 'Testing Form B', 'Description Testing Form B', 2, true);
INSERT INTO public.form_groups (id, name, description, nr_ord, is_form_validated) OVERRIDING SYSTEM VALUE VALUES (3, 'Testing Form C', 'Description Testing Form C', 3, true);
INSERT INTO public.form_groups (id, name, description, nr_ord, is_form_validated) OVERRIDING SYSTEM VALUE VALUES (4, 'Testing Form D', 'Description Testing Form D', 4, true);
INSERT INTO public.form_groups (id, name, description, nr_ord, is_form_validated) OVERRIDING SYSTEM VALUE VALUES (5, 'Testing Form E', 'Description Testing Form E', 5, true);
INSERT INTO public.form_groups (id, name, description, nr_ord, is_form_validated) OVERRIDING SYSTEM VALUE VALUES (6, 'Testing Form F', 'Description Testing Form F', 6, true);
INSERT INTO public.form_groups (id, name, description, nr_ord, is_form_validated) OVERRIDING SYSTEM VALUE VALUES (8, 'Testing Form G', 'Description Testing Form G', 7, true);


--
-- Data for Name: form_params; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (1, 6, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 2, 1);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (1, 7, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 3, 2);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (1, 8, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 4, 3);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (1, 9, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 5, 4);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (1, 10, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 6, 5);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (1, 3, true, '// [param_aa], [param_ab], [param_ac], [param_ad], [param_ae], [param_af]
IF([param_ac] < 3, [param_aa] + [param_ab], [param_ad] + [param_ae] + [param_af])', 'param_aa,param_ab,param_ac,param_ad,param_ae,param_af', NULL, false, NULL, NULL, false, NULL, 1, 7);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (2, 12, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 2, 1);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (2, 13, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 3, 2);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (2, 14, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 4, 3);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (2, 1, true, '// [param_ba], [param_bb], [param_bc]
IF([param_bb] == 1, [param_ba], [param_bc])', 'param_ba,param_bb,param_bc', NULL, false, NULL, NULL, false, NULL, 1, 4);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (3, 1, true, '// [test_b], [test_c], [param_cd]
[test_c] * [param_cd]', 'param_cd,test_c', NULL, false, NULL, NULL, false, NULL, 1, 3);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (3, 2, true, '// [test_a], [test_c], [param_cd]
[test_c] + [param_cd]', 'param_cd,test_c', NULL, false, NULL, NULL, false, NULL, 2, 4);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (3, 3, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 3, 1);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (3, 19, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 4, 2);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (4, 1, true, '// [param_db], [param_dc]
[param_db] + 2 * [param_dc]', 'param_db,param_dc', NULL, false, NULL, NULL, false, NULL, 1, 3);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (4, 21, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 2, 1);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (4, 22, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 3, 2);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (5, 2, true, '// [param_eb], [param_ec]
[param_eb] / 2 + [param_ec]', 'param_eb,param_ec', NULL, false, NULL, NULL, false, NULL, 1, 3);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (5, 24, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 2, 1);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (5, 25, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 3, 2);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (6, 4, true, '// [param_fb]
[param_fb] * 2 / 3', 'param_fb', NULL, false, NULL, NULL, false, NULL, 1, 2);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (6, 27, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 2, 1);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (7, 28, true, '// [[test_j]], [test_k], [pga], [[pgb]], [[pgd]], [pgc]
AVG([[pgb]])', 'pgb', NULL, false, NULL, NULL, false, NULL, 1, 5);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (7, 29, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 5, 3);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (7, 30, false, NULL, NULL, 'arr5', false, NULL, NULL, false, NULL, 6, 4);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (7, 31, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 8, 7);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (7, 36, false, NULL, NULL, 'arr5', false, NULL, NULL, false, NULL, 7, 6);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (7, 37, true, '// [test_g], [test_k], [pga], [[pgb]], [[pgd]], [pgc]
[[pgb]] * [pga] + [[pgd]] * [pgc]', 'pga,pgb,pgc,pgd', NULL, false, NULL, NULL, false, NULL, 2, 8);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (7, 38, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 3, 1);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (8, 28, true, '// [[test_j]], [test_k], [pga], [[pgb]], [[pgd]], [pgc]
AVG([[pgb]])', 'pgb', NULL, false, NULL, NULL, false, NULL, 1, 9);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (8, 29, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 9, 6);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (8, 30, false, NULL, NULL, 'arr5', false, NULL, NULL, true, NULL, 11, 8);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (8, 31, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 10, 7);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (8, 36, false, NULL, NULL, 'arr5', false, NULL, NULL, false, NULL, 12, 10);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (8, 37, true, '// [test_g], [test_k], [pga], [[pgb]], [[pgd]], [pgc], [[pge]], [[pgf]]
[[pgb]] * [pga] + [[pgd]] * [pgc] + [[pge]] + [[pgf]]', 'pga,pgb,pgc,pgd,pge,pgf', NULL, false, NULL, NULL, false, NULL, 3, 13);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (8, 38, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 4, 3);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (9, 28, true, '// [[test_j]], [test_k], [pga], [[pgb]], [[pgd]], [pgc]
AVG([[pgb]])', 'pgb', NULL, false, NULL, NULL, false, NULL, 1, 4);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (9, 29, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 4, 2);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (9, 30, false, NULL, NULL, 'arr5', false, NULL, NULL, false, NULL, 5, 3);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (9, 31, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 7, 6);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (9, 36, false, NULL, NULL, 'arr5', false, NULL, NULL, false, NULL, 6, 5);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (9, 37, true, '// [test_g], [test_k], [pga], [[pgb]], [[pgd]], [pgc]
[[pgb]] * [pga] + [[pgd]] * [pgc]', 'pga,pgb,pgc,pgd', NULL, false, NULL, NULL, false, NULL, 2, 7);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (9, 38, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 3, 1);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (8, 39, false, NULL, NULL, 'arr5', false, NULL, NULL, false, NULL, 13, 11);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (8, 40, false, NULL, NULL, 'arr5', false, NULL, NULL, true, 0, 14, 12);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (1, 11, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 7, 6);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (8, 41, false, NULL, NULL, NULL, false, NULL, NULL, true, 0, 2, 1);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (7, 41, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 4, 2);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (8, 42, true, '// [test_g], [test_h], [[test_j]], [test_k], [pga], [pgc], [[pgb]], [[pgd]], [[pge]], [[pgf]]
IF([test_h],0,1) // equivalent for NOT', 'test_h', NULL, false, NULL, NULL, false, NULL, 5, 2);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (8, 43, true, '// [test_g], [test_h], [[test_j]], [test_k], [tlb], [pga], [pgc], [[pgb]], [[pgd]], [[pge]], [[pgf]]
IF([[pgf]],0,1) // equivalent for NOT', 'pgf', NULL, false, NULL, NULL, false, NULL, 6, 14);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (8, 44, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 7, 4);
INSERT INTO public.form_params (form_id, test_id, is_calculated, formula, formula_dependencies, code_related_arrays, has_condition, condition, condition_note, is_required, default_value, nr_ord, nr_ord_calc) VALUES (8, 45, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 8, 5);


--
-- Data for Name: forms; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.forms (id, form_group_id, version, is_customized, custom_nav, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_validated, user_validated_id, date_validated, comments_validated, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (1, 1, 'v0', true, 'TestingFormA', true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 16:41:53.493203+02', 'Erewrew wer wqerwert wert wert we.', false, NULL, NULL, NULL);
INSERT INTO public.forms (id, form_group_id, version, is_customized, custom_nav, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_validated, user_validated_id, date_validated, comments_validated, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (2, 2, 'v0', false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 16:43:14.869321+02', 'Rtretert ert ert ert ert ert er.
Tfgdfgsdfg sdfg sdfg sdfg sdfg sdfg.', false, NULL, NULL, NULL);
INSERT INTO public.forms (id, form_group_id, version, is_customized, custom_nav, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_validated, user_validated_id, date_validated, comments_validated, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (3, 3, 'v0', false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 16:47:43.20068+02', '- Rrwerwer wer wer wer wer werwe
- Tsdafasdf sadf asdf asdf asdf asf', false, NULL, NULL, NULL);
INSERT INTO public.forms (id, form_group_id, version, is_customized, custom_nav, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_validated, user_validated_id, date_validated, comments_validated, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (4, 4, 'v0', false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 17:00:21.39342+02', '- Erewrtertew ert wert wert wert wer
- Urtsadf asdf asdf asdf asdf asdf asfd', false, NULL, NULL, NULL);
INSERT INTO public.forms (id, form_group_id, version, is_customized, custom_nav, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_validated, user_validated_id, date_validated, comments_validated, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (5, 5, 'v0', false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 17:46:34.396668+02', '- Rewer ewr wertw ert wert wer
- Gert ertertwertwert ewrt wert
- Rytdfghfd dfghdfghdfgh fdgh dfgh', false, NULL, NULL, NULL);
INSERT INTO public.forms (id, form_group_id, version, is_customized, custom_nav, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_validated, user_validated_id, date_validated, comments_validated, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (6, 6, 'v0', false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 17:48:50.759892+02', '- Yredsfgsdf dsfg sdfg sdfg 
- Ddfgd fgh fdgh dfgh dfghdfgh dfgh
- Ddfg sdfgsdfg sdfg sdfg sdfgsfg ', false, NULL, NULL, NULL);
INSERT INTO public.forms (id, form_group_id, version, is_customized, custom_nav, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_validated, user_validated_id, date_validated, comments_validated, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (7, 8, 'v0', false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 18:03:04.415193+02', 'Eert ert ert ert ert ert', false, NULL, NULL, NULL);
INSERT INTO public.forms (id, form_group_id, version, is_customized, custom_nav, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_validated, user_validated_id, date_validated, comments_validated, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (8, 8, 'v1', false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.forms (id, form_group_id, version, is_customized, custom_nav, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_validated, user_validated_id, date_validated, comments_validated, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (9, 8, 'v2', false, NULL, false, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL, false, NULL, NULL, NULL);


--
-- Data for Name: material_tests; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.material_tests (material_id, test_id) VALUES (4, 1);
INSERT INTO public.material_tests (material_id, test_id) VALUES (4, 4);
INSERT INTO public.material_tests (material_id, test_id) VALUES (4, 5);
INSERT INTO public.material_tests (material_id, test_id) VALUES (21, 2);
INSERT INTO public.material_tests (material_id, test_id) VALUES (21, 3);
INSERT INTO public.material_tests (material_id, test_id) VALUES (21, 5);
INSERT INTO public.material_tests (material_id, test_id) VALUES (1, 3);
INSERT INTO public.material_tests (material_id, test_id) VALUES (1, 2);
INSERT INTO public.material_tests (material_id, test_id) VALUES (2, 3);
INSERT INTO public.material_tests (material_id, test_id) VALUES (2, 4);
INSERT INTO public.material_tests (material_id, test_id) VALUES (2, 1);
INSERT INTO public.material_tests (material_id, test_id) VALUES (3, 4);
INSERT INTO public.material_tests (material_id, test_id) VALUES (3, 5);
INSERT INTO public.material_tests (material_id, test_id) VALUES (6, 5);
INSERT INTO public.material_tests (material_id, test_id) VALUES (6, 4);
INSERT INTO public.material_tests (material_id, test_id) VALUES (6, 1);
INSERT INTO public.material_tests (material_id, test_id) VALUES (7, 3);
INSERT INTO public.material_tests (material_id, test_id) VALUES (7, 2);
INSERT INTO public.material_tests (material_id, test_id) VALUES (15, 5);
INSERT INTO public.material_tests (material_id, test_id) VALUES (15, 4);
INSERT INTO public.material_tests (material_id, test_id) VALUES (15, 1);
INSERT INTO public.material_tests (material_id, test_id) VALUES (9, 3);
INSERT INTO public.material_tests (material_id, test_id) VALUES (9, 1);
INSERT INTO public.material_tests (material_id, test_id) VALUES (14, 1);
INSERT INTO public.material_tests (material_id, test_id) VALUES (14, 2);
INSERT INTO public.material_tests (material_id, test_id) VALUES (14, 3);
INSERT INTO public.material_tests (material_id, test_id) VALUES (14, 5);
INSERT INTO public.material_tests (material_id, test_id) VALUES (18, 3);
INSERT INTO public.material_tests (material_id, test_id) VALUES (18, 4);
INSERT INTO public.material_tests (material_id, test_id) VALUES (18, 5);
INSERT INTO public.material_tests (material_id, test_id) VALUES (17, 1);
INSERT INTO public.material_tests (material_id, test_id) VALUES (17, 2);
INSERT INTO public.material_tests (material_id, test_id) VALUES (17, 4);
INSERT INTO public.material_tests (material_id, test_id) VALUES (17, 5);
INSERT INTO public.material_tests (material_id, test_id) VALUES (19, 1);
INSERT INTO public.material_tests (material_id, test_id) VALUES (19, 3);
INSERT INTO public.material_tests (material_id, test_id) VALUES (19, 4);
INSERT INTO public.material_tests (material_id, test_id) VALUES (19, 5);
INSERT INTO public.material_tests (material_id, test_id) VALUES (20, 5);
INSERT INTO public.material_tests (material_id, test_id) VALUES (20, 3);
INSERT INTO public.material_tests (material_id, test_id) VALUES (20, 2);
INSERT INTO public.material_tests (material_id, test_id) VALUES (5, 3);
INSERT INTO public.material_tests (material_id, test_id) VALUES (5, 4);
INSERT INTO public.material_tests (material_id, test_id) VALUES (5, 28);
INSERT INTO public.material_tests (material_id, test_id) VALUES (5, 37);
INSERT INTO public.material_tests (material_id, test_id) VALUES (5, 38);
INSERT INTO public.material_tests (material_id, test_id) VALUES (5, 41);
INSERT INTO public.material_tests (material_id, test_id) VALUES (4, 2);
INSERT INTO public.material_tests (material_id, test_id) VALUES (4, 3);
INSERT INTO public.material_tests (material_id, test_id) VALUES (2, 2);
INSERT INTO public.material_tests (material_id, test_id) VALUES (3, 1);
INSERT INTO public.material_tests (material_id, test_id) VALUES (3, 2);
INSERT INTO public.material_tests (material_id, test_id) VALUES (3, 3);
INSERT INTO public.material_tests (material_id, test_id) VALUES (4, 28);
INSERT INTO public.material_tests (material_id, test_id) VALUES (5, 42);
INSERT INTO public.material_tests (material_id, test_id) VALUES (5, 43);
INSERT INTO public.material_tests (material_id, test_id) VALUES (5, 44);
INSERT INTO public.material_tests (material_id, test_id) VALUES (5, 45);
INSERT INTO public.material_tests (material_id, test_id) VALUES (11, 1);
INSERT INTO public.material_tests (material_id, test_id) VALUES (11, 2);
INSERT INTO public.material_tests (material_id, test_id) VALUES (11, 3);
INSERT INTO public.material_tests (material_id, test_id) VALUES (11, 4);
INSERT INTO public.material_tests (material_id, test_id) VALUES (11, 5);


--
-- Data for Name: materials; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (1, 'Material A', 'MA', 'Description for Material A', 2, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (2, 'Material B', 'MB', 'Description for Material B', 4, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (3, 'Material C', 'MC', 'Description for Material C', 1, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (4, 'Material D', 'MD', 'Description for Material D', 3, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (5, 'Material E', 'ME', 'Description for Material E', 1, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (6, 'Material F', 'NF', 'Description for Material F', 2, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (7, 'Material G', 'MG', 'Description for Material G', 3, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (8, 'Material H', 'MH', 'Description for Material H', 3, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (9, 'Material I', 'MI', 'Description for Material I', 4, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (10, 'Material J', 'MJ', 'Description for Material J', 4, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (11, 'Material K', 'MK', 'Description for Material K', 4, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', true, '2026-01-23 22:43:26.698445+02', 'Some explanations ...');
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (12, 'Material L', 'ML', 'Description for Material L', 1, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (13, 'Material M', 'MM', 'Description for Material M', 1, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (14, 'Material N', 'MN', 'Description for Material N', 2, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (15, 'Material O', 'MO', 'Description for Material O', 4, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (16, 'Material P', 'MP', 'Description for Material P', 3, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (17, 'Material Q', 'MQ', 'Description for Material Q', 3, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (18, 'Material R', 'MR', 'Description for Material R', 1, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (19, 'Material S', 'MS', 'Description for Material S', 2, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (20, 'Material T', 'MT', 'Description for Material T', 4, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials (id, name, code, description, norm_id, is_product, is_raw_material, is_reagent, cas_number, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (21, 'Finished Product A', 'FPA', 'A product made from various materials', 3, true, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);


--
-- Data for Name: measurement_equipments; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: measurement_params; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (41, 7, 31, 0, 534, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (42, 8, 28, 0, 740, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (42, 8, 38, 0, 4, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (42, 8, 29, 0, 456, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (42, 8, 30, 0, 555, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (42, 8, 30, 1, 777, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (42, 8, 30, 2, 888, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (42, 8, 36, 0, 555, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (42, 8, 36, 1, 777, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (42, 8, 36, 2, 888, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (42, 8, 39, 0, 1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (42, 8, 39, 1, 2, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (42, 8, 39, 2, 3, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (42, 8, 40, 0, 1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (9, 3, 3, 0, 8, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (9, 3, 19, 0, 456.7, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (9, 3, 1, 0, 3653.6, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (9, 3, 2, 0, 464.7, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (18, 3, 3, 0, 23, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (18, 3, 19, 0, 456.7, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (18, 3, 1, 0, 10504.1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (18, 3, 2, 0, 479.7, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (6, 1, 6, 0, 3645640, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (6, 1, 7, 0, 567567, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (6, 1, 8, 0, 4, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (6, 1, 9, 0, 567567, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (6, 1, 10, 0, 0, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (6, 1, 11, 0, 42.4, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (6, 1, 3, 0, 567609, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (7, 1, 6, 0, 4564, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (7, 1, 7, 0, 45645, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (7, 1, 8, 0, 3, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (7, 1, 9, 0, 45645, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (7, 1, 10, 0, 1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (7, 1, 11, 0, 14.8, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (7, 1, 3, 0, 45660.8, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (5, 1, 6, 0, 145, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (5, 1, 7, 0, 345, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (5, 1, 8, 0, 5, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (5, 1, 9, 0, 345, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (5, 1, 10, 0, 1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (5, 1, 11, 0, 45.2, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (5, 1, 3, 0, 391.2, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (8, 2, 12, 0, 6, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (8, 2, 13, 0, 2, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (8, 2, 14, 0, 18, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (8, 2, 1, 0, 18, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (15, 3, 3, 0, 5, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (15, 3, 19, 0, 234.5, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (15, 3, 1, 0, 1172.5, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (15, 3, 2, 0, 239.5, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (31, 2, 12, 0, 4654, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (31, 2, 13, 0, 1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (31, 2, 14, 0, 456, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (31, 2, 1, 0, 4654, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (17, 1, 6, 0, 567, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (17, 1, 7, 0, 567, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (17, 1, 8, 0, 2, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (17, 1, 9, 0, 67867, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (17, 1, 10, 0, 1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (17, 1, 11, 0, 45.3, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (17, 1, 3, 0, 1134, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (12, 1, 6, 0, 45645, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (12, 1, 7, 0, 456456, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (12, 1, 8, 0, 2, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (12, 1, 9, 0, 45645, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (12, 1, 10, 0, 1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (13, 2, 12, 0, 5, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (13, 2, 13, 0, 1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (13, 2, 14, 0, 456567, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (13, 2, 1, 0, 5, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (22, 1, 6, 0, 34534, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (22, 1, 7, 0, 6456, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (25, 1, 6, 0, 75675, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (20, 2, 12, 0, 25, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (20, 2, 13, 0, 2, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (20, 2, 14, 0, 789, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (20, 2, 1, 0, 789, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (21, 3, 3, 0, 89, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (21, 3, 19, 0, 456.7, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (21, 3, 1, 0, 40646.3, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (21, 3, 2, 0, 545.7, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (28, 2, 12, 0, 5345, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (28, 2, 13, 0, 1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (28, 2, 14, 0, 56756, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (28, 2, 1, 0, 5345, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (27, 3, 3, 0, 167, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (27, 3, 19, 0, 456.7, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (27, 3, 1, 0, 76268.9, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (27, 3, 2, 0, 623.7, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (40, 7, 38, 0, 2, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (40, 7, 29, 0, 45, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (40, 7, 30, 0, 2222, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (40, 7, 30, 1, 3333, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (40, 7, 30, 2, 444, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (40, 7, 36, 0, 2222, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (40, 7, 36, 1, 3333, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (40, 7, 36, 2, 444, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (40, 7, 31, 0, 56, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (40, 7, 28, 0, 1999.67, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (40, 7, 37, 0, 224422, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (40, 7, 37, 1, 336633, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (40, 7, 37, 2, 44844, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 41, 0, 1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 38, 0, 1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 29, 0, 56756, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 30, 0, 6756, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 30, 1, 565, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 30, 2, 56756, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 30, 3, 3423, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 30, 4, 545, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 36, 0, 56567, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 36, 1, 4343, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 36, 2, 434, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 36, 3, 345, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 36, 4, 53545, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 31, 0, 5657, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 39, 0, 3, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 39, 1, 1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 39, 2, 2, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 39, 3, 2, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 39, 4, 1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 40, 0, 1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 40, 1, 1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 40, 2, 1, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 40, 3, 0, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 40, 4, 0, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 28, 0, 13609, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 37, 0, 703443000, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 37, 1, 56635500, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 37, 2, 3223700000, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 37, 3, 196227000, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (51, 8, 37, 4, 333836000, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 38, 0, 2, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 29, 0, 756756, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 30, 0, 123, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 30, 1, 43, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 30, 2, 111, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 30, 3, 534, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 30, 4, 345, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 30, 5, 534, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 30, 6, 432, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 36, 0, 333, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 36, 1, 555, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 36, 2, 45, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 36, 3, 700, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 36, 4, 45, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 36, 5, 452, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 36, 6, 54, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 31, 0, 34.8, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 28, 0, 303.143, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 37, 0, 93092600, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 37, 1, 32559800, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 37, 2, 84001500, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 37, 3, 404132000, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 37, 4, 261082000, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 37, 5, 404123000, NULL);
INSERT INTO public.measurement_params (measurement_id, form_id, test_id, idx, value, condition_value) VALUES (50, 7, 37, 6, 326920000, NULL);


--
-- Data for Name: measurement_reagent_lots; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: measurement_sop_versions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: measurement_tests; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (2, 2, 0, 212, 'trt');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (4, 2, 0, 455645, 'dfg');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (10, 4, 0, 123, '***');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (11, 1, 0, 21321, '*');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (14, 1, 0, 434, '*');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (16, 1, 0, 5467, '*');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (19, 1, 0, 156, '*');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (23, 2, 0, 24, NULL);
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (24, 1, 0, 54, '*');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (26, 1, 0, 185, '*');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (30, 1, 0, 123, '*');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (36, 1, 0, 5675, '*');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (26, 3, 0, 3453, '/*');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (38, 1, 0, 64564, '**');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (38, 3, 0, 4564, '/**');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (39, 3, 0, 150, '*');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (39, 4, 0, 600.5, '**');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (46, 3, 0, 454.34, '[2]');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (46, 37, 0, 111, '[6]');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (46, 37, 1, 333, '[6]');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (46, 37, 2, 444, '[6]');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (46, 38, 0, 3, '[5]');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (46, 41, 0, 1, '[4]');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (46, 28, 0, 75.5, '**');
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (47, 28, 0, 252.4, NULL);
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (47, 37, 0, 222, NULL);
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (47, 37, 1, 333, NULL);
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (47, 38, 0, 3, NULL);
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (48, 38, 0, 2, NULL);
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (48, 37, 0, 333, NULL);
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (48, 37, 1, 444, NULL);
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (48, 28, 0, 192.6, NULL);
INSERT INTO public.measurement_tests (measurement_id, test_id, idx, value, note) VALUES (49, 3, 0, 862.4, NULL);


--
-- Data for Name: measurements; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (1, 2, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628516+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (2, 2, NULL, 'sdfgsdfgsdf dsfg sdfg sdfg 
sdf gsdfg sdgf ', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.628833+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (3, 2, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628838+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (4, 2, NULL, 'Gsdfgs dfg sdfg sdfg sdfg.
Sdf gsdfg sdfg.
Sdfg sdfg sdfg.
', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628839+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (5, 2, 1, 'gsdfg sdfg sdfg sdfg', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.62884+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (6, 2, 1, 'fgsdfg sdfg sdfg', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628842+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (7, 2, 1, ' ghdfgh dfgh dfgh', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628843+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (8, 2, 2, 'fgsdfgs dfg sdfg sdfg sdfg ', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628844+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (9, 2, 3, '- Dfghd dfgh hgdf hdfgh dfgh dfgh dfgh dfgh dfgh dfgh dfg.
- Dfg hdfgh dfgh dfgh fdgh.
- Dfg hdfgh dfgh dfgh dfgh dfgh dfgh dfgh dfgh dfgh dfghdfgh dfgh fg.', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.628846+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (10, 2, NULL, 'Jfghj fghj fghj fhjf ghj.
Tghfghfgh dfgdfgdf gdfgd fg.', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628848+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (11, 6, NULL, 'hdfgh dfgh dfg gfh dfgh dgfh dfg', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628849+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (12, 6, 1, 'hfghdfg hdfgh fd', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.62885+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (13, 6, 2, 'hjdfg hfdgh dfgh dfgh', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628851+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (14, 1, NULL, 'bxb xcvb xcvb xcvb xcvb xcvb', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.628852+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (15, 1, 3, 'fgh sdfg sdfg sdfg sdfg', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.628853+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (16, 3, NULL, ' hdfgh dfgh dfgh dfgh dfgh', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.628855+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (17, 3, 1, ' dfgh dfgh dfgh dfgh dfghdfg ', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.628856+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (18, 2, 3, ' zzz', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628857+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (19, 8, NULL, 'sdfg sdfg sdfg sdfg sdfg sdfg s', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.628858+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (20, 8, 2, ' fghdfgh dfgh', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.628859+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (21, 8, 3, ' fsdfg sdfg sdfg sdfg sdf', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.62886+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (22, 8, 1, 'sdfg sdfg sdfgs dfg', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628862+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (23, 3, NULL, 'fgh dfgh dfgh dfgh dfgh dfg', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628863+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (24, 8, NULL, 'gf hdfgh dfgh dfgh dfg
cv bcvbn cvbn cvbncbn', true, 8, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628866+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (25, 8, 1, 'd dfgh dfgh dfgh dfgh', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628868+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (26, 11, NULL, 'fdg dfgh dfgh dfgh dfgh', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628869+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (27, 11, 3, 'cvbxcvb xcvb xcvbxc vb xcvb', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.62887+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (28, 11, 2, 'dfg sdfg sdfg sdfg sdfg df', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628871+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (29, 1, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628872+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (30, 1, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628873+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (31, 3, 2, 'dfg sdfg sdfg sdfg sdfg', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.628874+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (35, 10, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628876+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (36, 2, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628877+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (37, 2, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628878+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (38, 11, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628879+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (39, 20, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.62888+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (40, 20, 7, 'Edfgdfg dfg dfg df.
Rfghfgh fghfgh fgh fgh fgh fghfg.
Trwerwer wer wer wer werer.', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.628881+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (41, 20, 7, 'dfgh dfgh dfghdf ghdfgh dfgh dfgh', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628883+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (42, 20, 7, '- Fghj fghj fghj fghj fghj gj
- Fghj fghj fghj fghj fghj fghj fghj fghj.', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628884+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (43, 20, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628885+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (44, 20, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628886+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (45, 20, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628887+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (46, 20, NULL, '- Eterte ert ert ert ert ert ter.
- Gfgdfgdfgdf dfg dfg dfg dfg dfg dgfdf.
- Ydfgsdfg sdfg sdfgsdf gsdfg sdfg.', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.628889+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (47, 21, NULL, 'sdfg sdfg sdfg sdfg sdfg sdfg', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.62889+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (48, 22, NULL, 'zxcv zxcv zxcv zxcv', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.628891+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (49, 22, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:39:32.628892+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (50, 22, 7, 'hdfgh dfgh dfgh', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628893+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (51, 22, 7, 'fghj fghj fghj fghj', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628895+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (52, 11, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628896+03');
INSERT INTO public.measurements (id, reception_id, form_id, comments, use_default_equipment, user_update_id, date_update, is_reported, user_reported_id, date_reported, is_readonly, date_readonly, user_created_id, date_created) OVERRIDING SYSTEM VALUE VALUES (53, 11, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:39:32.628897+03');


--
-- Data for Name: norms; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.norms (id, name, description, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (1, 'Norm A', 'Description Norm A', '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.norms (id, name, description, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (2, 'Norm B', 'Description Norm B', '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.norms (id, name, description, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (3, 'Norm C', 'Description Norm C', '2025-12-13 18:17:42.218999+02', true, '2026-01-23 22:44:28.171813+02', 'Some explanations ...');
INSERT INTO public.norms (id, name, description, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (4, 'Norm D', 'Description Norm D', '2025-12-13 18:17:42.218999+02', false, NULL, NULL);


--
-- Data for Name: reagent_lot_statuses; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.reagent_lot_statuses (id, name) VALUES (1, 'Quarantined');
INSERT INTO public.reagent_lot_statuses (id, name) VALUES (2, 'Active');
INSERT INTO public.reagent_lot_statuses (id, name) VALUES (3, 'Expired');
INSERT INTO public.reagent_lot_statuses (id, name) VALUES (4, 'Depleted');


--
-- Data for Name: reagent_lots; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: reagent_production_lots; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: reagent_supplier_lots; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: reagent_suppliers; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: reception_tests; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.reception_tests (reception_id, test_id) VALUES (2, 1);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (2, 5);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (6, 1);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (6, 3);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (7, 1);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (7, 3);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (7, 4);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (3, 1);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (3, 3);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (3, 4);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (10, 2);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (10, 3);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (12, 2);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (12, 4);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (13, 4);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (13, 5);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (15, 1);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (15, 3);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (15, 4);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (17, 1);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (17, 3);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (17, 4);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (5, 2);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (5, 3);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (18, 2);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (18, 3);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (19, 4);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (19, 1);
INSERT INTO public.reception_tests (reception_id, test_id) VALUES (19, 3);


--
-- Data for Name: reception_types; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.reception_types (id, name) VALUES (1, 'Certification');
INSERT INTO public.reception_types (id, name) VALUES (2, 'Verification');
INSERT INTO public.reception_types (id, name) VALUES (3, 'Category Verification');


--
-- Data for Name: receptions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (1, 1, 60, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'v vzx cv zxcv zxcv zxcv zxcvzxc zvxc', true, 1, '2025-12-13 18:17:42.218999+02', 'h dfgh dfgh dfgh dfgh dfgh dfgh dfgh dfgh dfgh dfghd fg', false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (2, 2, 70, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'xcvbxcvb xcvb xcvb xcvb xcvb xcv', true, 1, '2025-12-13 18:17:42.218999+02', 'rt yert erty erty erty erty erty eryt rt', false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (3, 3, NULL, 'Material Name Diverse', 1, true, 1, '2025-12-13 18:17:42.218999+02', 'df asdf asdf asdf asdfasd', true, 1, '2025-12-13 18:17:42.218999+02', 'gdfsgs dfg sdfg sdfg sdfg sdfg df', false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (4, 2, 60, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'sdfgsdfgsdfgsdfgsdfg', true, 1, '2025-12-13 18:17:42.218999+02', 'rty erty erty erty', false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (5, 2, 59, NULL, NULL, false, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (6, 3, NULL, 'sdfgsdfgsdfgsdfg', 1, true, 1, '2025-12-13 18:17:42.218999+02', 'sdfgsdfgsdfgsdfg', true, 1, '2025-12-13 18:17:42.218999+02', 'ert yertyertyer rt', false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (7, 2, 60, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'tyytytututu', false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (8, 1, 69, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'hjkghjkghj khgjk ghjk ghjk ghj', true, 1, '2025-12-13 18:17:42.218999+02', 'rt yrty erty rt', false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (9, 1, 69, NULL, NULL, false, 1, '2025-12-13 18:17:42.218999+02', 'dfgh dfgh dfgh dfgh dfgh dfgh', false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (10, 2, 59, NULL, NULL, true, 8, '2025-12-13 18:17:42.218999+02', 'fdfg sdfg sdfg sdf
sdfg sdfg sdfg sdfg sdfgd s
sdf gsdfg dfsg sdfg
', true, 8, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (11, 1, 60, NULL, NULL, true, 8, '2025-12-13 18:17:42.218999+02', 'gfh dfgh dfgh dfgh dfgh dfgh
dfg hdfgh dfgh dfghdfg
 dfgh dfgh dfgh', true, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (12, 3, NULL, 'fg dsfg sdfg sdfg sdfg sdgf', 2, false, 8, '2025-12-13 18:17:42.218999+02', 's adfasdf asdf asdf asdf
a sdfasdf asdf asdf asfd', false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (13, 2, 69, NULL, NULL, false, 8, '2025-12-13 18:17:42.218999+02', 'sdfg sdfg sdfg sdfg sdfg sdfg
dsfg sdfg sdfg sdfg sdfg sdfg', false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (14, 1, 66, NULL, NULL, false, 8, '2025-12-13 18:17:42.218999+02', 'hfgh ghfdg dfgh dfgh dfgh', false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (15, 2, 56, NULL, NULL, false, 8, '2025-12-13 18:17:42.218999+02', 'sdfg sdfg sdfg sdfg sdfgsdf', false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (16, 1, 6, NULL, NULL, false, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (17, 2, 60, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', '- Aerwer wer wer wer wer wer we.
- Rttrty rtyr yrty rty rty rty.
- Ertertertert ert ert ert ert er', false, NULL, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', '- Eerte ert ert ert ert ert er.
- Detrtryrty erty erty erty erty erty ert.');
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (18, 2, 59, NULL, NULL, false, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (19, 3, NULL, 'fdgs dfg sdfg sdfg df', 1, false, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (20, 1, 34, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'fdg dsfg sdfg sdfg sdfg sdgf dsf', true, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (21, 1, 35, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'd fsdfg sdfg sdfg sdfg', true, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions (id, type_id, control_code_id, material_name, category_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, is_received, user_received_id, date_received, comments_received, is_rejected, user_rejected_id, date_rejected, comments_rejected) OVERRIDING SYSTEM VALUE VALUES (22, 1, 63, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'vzxcv zxcv zxcv zxcv z', true, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL);


--
-- Data for Name: report_tests; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (20, 14, 1, 0, 434, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (20, 15, 1, 0, 1172.5, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (20, 15, 2, 0, 239.5, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (20, 15, 3, 0, 5, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (21, 2, 2, 0, 212, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (21, 5, 3, 0, 391.2, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (21, 9, 1, 0, 3653.6, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (21, 9, 2, 0, 464.7, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (21, 9, 3, 0, 8, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (22, 16, 1, 0, 5467, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (22, 17, 3, 0, 1134, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (22, 31, 1, 0, 4654, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (23, 19, 1, 0, 156, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (23, 20, 1, 0, 789, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (23, 21, 1, 0, 40646.3, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (23, 21, 2, 0, 545.7, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (23, 21, 3, 0, 89, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (24, 40, 28, 0, 1999.67, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (24, 40, 38, 0, 2, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (24, 40, 37, 0, 224422, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (24, 40, 37, 1, 336633, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (24, 40, 37, 2, 44844, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (25, 39, 3, 0, 150, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (25, 39, 4, 0, 600.5, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (25, 46, 3, 0, 454.34, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (25, 46, 28, 0, 175.5, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (25, 46, 37, 0, 111, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (25, 46, 37, 1, 333, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (25, 46, 37, 2, 444, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (25, 46, 38, 0, 3, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (25, 46, 41, 0, 1, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (26, 47, 28, 0, 252.4, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (26, 47, 37, 0, 222, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (26, 47, 37, 1, 333, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (26, 47, 38, 0, 3, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (27, 48, 28, 0, 192.6, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (27, 48, 37, 0, 333, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (27, 48, 37, 1, 444, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (27, 48, 38, 0, 2, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (28, 48, 28, 0, 192.6, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (28, 48, 37, 0, 333, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (28, 48, 37, 1, 444, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (28, 48, 38, 0, 2, NULL, NULL);
INSERT INTO public.report_tests (report_id, measurement_id, test_id, idx, value, uncertainty_value, coverage_factor_k) VALUES (28, 49, 3, 0, 862.4, NULL, NULL);


--
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.reports (id, reception_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, report_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (20, 1, true, 1, '2025-12-13 18:17:42.218999+02', 'fgsdfg sdfg sdfg sdfg sdfgs ', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports (id, reception_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, report_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (21, 2, true, 1, '2025-12-13 18:17:42.218999+02', 'dfgs dfg sdfg sdfg sdgf', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports (id, reception_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, report_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (22, 3, true, 1, '2025-12-13 18:17:42.218999+02', 'h fghd fgh dfgh dfgh dfhgg', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports (id, reception_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, report_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (23, 8, true, 1, '2025-12-13 18:17:42.218999+02', 'd fgsdfg sdfg sdfg sdfg sdgf', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports (id, reception_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, report_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (24, 20, true, 1, '2025-12-13 18:17:42.218999+02', 'fgsdfg sdfg sdfg ', NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'Replaced by new report #25');
INSERT INTO public.reports (id, reception_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, report_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (25, 20, true, 1, '2025-12-13 18:17:42.218999+02', 'l hlkjh ljh ljkh ljh lj ', 24, false, NULL, NULL, NULL);
INSERT INTO public.reports (id, reception_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, report_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (26, 21, true, 1, '2025-12-13 18:17:42.218999+02', 'ghdfgh dfgh dfgh dfgh', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports (id, reception_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, report_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (27, 22, true, 1, '2025-12-13 18:17:42.218999+02', 'fafasdf asdf asdf asfd asdf', NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'Replaced by new report #28');
INSERT INTO public.reports (id, reception_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, report_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (28, 22, true, 1, '2025-12-13 18:17:42.218999+02', 'fasdf asdfasfd asdf asdf asdf', 27, false, NULL, NULL, NULL);


--
-- Data for Name: sop_versions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: sops; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: spec_test_evals; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (27, 11, 3, 100, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (28, 11, 3, 58, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (29, 11, 3, 101, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (33, 11, 4, 789, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (34, 11, 4, 1000, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (35, 11, 4, 1001, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (41, 11, 28, 35, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (42, 11, 28, 50, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (43, 11, 28, 75, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (44, 11, 28, 100, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (45, 11, 28, 101, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (46, 11, 37, 100, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (47, 11, 37, 99, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (48, 11, 37, 273, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (49, 11, 37, 500, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (50, 11, 37, 501, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (56, 11, 38, 1, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (57, 11, 38, 2, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (58, 11, 38, 3, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (59, 11, 38, 4, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (60, 11, 38, 5, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (87, 3, 1, 10, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (88, 3, 1, 11, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (89, 3, 1, 99, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (90, 3, 3, 1000, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (91, 3, 3, 999, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (92, 3, 3, 1001, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (93, 3, 3, 527, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (94, 3, 4, 100, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (95, 3, 4, 99, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (96, 3, 4, 101, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (97, 3, 4, 8787, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (98, 3, 4, 2, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (99, 2, 1, 10, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (100, 2, 1, 5, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (101, 2, 1, 11, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (102, 2, 1, 457, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (103, 2, 2, 1000, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (104, 2, 2, 1001, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (105, 2, 2, 999, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (106, 2, 2, 142, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (107, 2, 3, 10, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (108, 2, 3, 11, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (109, 2, 3, 1000, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (110, 2, 3, 999, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (111, 2, 3, 145, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (112, 2, 4, 100, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (113, 2, 4, 99, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (114, 2, 4, 101, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (115, 2, 4, 45, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (116, 2, 4, 145, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (117, 1, 1, 1000, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (118, 1, 1, 999, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (119, 1, 1, 458, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (120, 1, 1, 1254, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (121, 1, 2, 10, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (122, 1, 2, 9, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (123, 1, 2, 11, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (124, 1, 2, 125, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (125, 1, 2, 3, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (126, 1, 3, 100, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (127, 1, 3, 99, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (128, 1, 3, 101, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (129, 1, 3, 55, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (130, 1, 3, 148, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (145, 16, 1, 1000, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (146, 16, 1, 999, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (147, 16, 1, 458, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (148, 16, 1, 1254, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (149, 16, 2, 10, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (150, 16, 2, 9, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (151, 16, 2, 11, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (152, 16, 2, 125, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (153, 16, 2, 3, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (154, 16, 3, 100, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (155, 16, 3, 99, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (156, 16, 3, 101, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (157, 16, 3, 55, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (158, 16, 3, 148, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (159, 17, 3, 100, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (160, 17, 3, 58, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (161, 17, 3, 101, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (162, 17, 4, 789, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (163, 17, 4, 1000, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (164, 17, 4, 1001, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (165, 17, 28, 35, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (166, 17, 28, 50, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (167, 17, 28, 75, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (168, 17, 28, 100, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (169, 17, 28, 101, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (170, 17, 37, 100, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (171, 17, 37, 99, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (172, 17, 37, 273, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (173, 17, 37, 500, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (174, 17, 37, 501, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (175, 17, 38, 1, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (176, 17, 38, 2, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (177, 17, 38, 3, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (178, 17, 38, 4, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals (id, spec_id, test_id, value, result, expected_result, is_match, note) OVERRIDING SYSTEM VALUE VALUES (179, 17, 38, 5, 0, 0, true, NULL);


--
-- Data for Name: spec_tests; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (2, 1, '[value] > 10', '> 10', false, 2);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (2, 2, '[value] < 1000', '< 1000', false, 1);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (2, 3, '[value] > 10 && [value] < 1000', '> 10 and < 1000', false, 1);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (2, 4, '[value] == 100', '== 100', false, 1);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (1, 2, '[value] > 10', '> 10', false, 2);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (1, 1, '[value] < 1000', '< 1000', false, 1);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (1, 3, '[value] == 100', '== 100', false, 1);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (3, 1, '[value] > 10', '> 10', false, 1);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (3, 3, '[value] < 1000', '< 1000', false, 1);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (3, 4, '[value] == 100', '== 100', false, 1);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (11, 3, '[value] > 100', '> 100', false, 2);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (11, 4, '[value] < 1000', '< 1000', false, 3);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (11, 28, '[value] <= 50 || [value] > 100', '<= 50 or > 100', false, 1);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (11, 37, '[value] > 100 && [value] <= 500', '> 100 and <= 500', false, 1);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (11, 38, '[value] == 2 || [value] == 3 // Item KB or Item KC', '''Item KB'' or ''Item KC''', false, 1);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (16, 1, '[value] < 1000', '< 1000', false, 1);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (16, 2, '[value] > 10', '> 10', false, 2);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (16, 3, '[value] == 100', '== 100', false, 1);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (17, 3, '[value] > 100', '> 100', false, 2);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (17, 4, '[value] < 1000', '< 1000', false, 3);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (17, 28, '[value] <= 50 || [value] > 100', '<= 50 or > 100', false, 1);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (17, 37, '[value] > 100 && [value] <= 500', '> 100 and <= 500', false, 1);
INSERT INTO public.spec_tests (spec_id, test_id, condition, note, use_uncertainty, test_frequency) VALUES (17, 38, '[value] == 2 || [value] == 3 // Item KB or Item KC', '''Item KB'' or ''Item KC''', false, 1);


--
-- Data for Name: specs; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.specs (id, material_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, spec_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (1, 3, true, 1, '2025-12-29 18:48:38.884957+02', '- Fewrwer erty rty rty rty rt
- Hdfg sdfg sdfg sdfg sdfgs dfg sdf
- Tsdfgsdfgsdfg  dsfgsd fgsdfg sdfg sd', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs (id, material_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, spec_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (2, 1, true, 1, '2025-12-29 18:45:15.130498+02', '- Frtdfg sdfg sdfg try erthy fghdf
- Tvdfgsdf sdfg sdfg dfgsdfg sdfgsdfg', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs (id, material_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, spec_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (3, 2, true, 1, '2025-12-29 18:36:47.186175+02', '- Dsadasdas dfsadf asdf
- Rrdgsdfg sdfg sdfg sdfg s', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs (id, material_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, spec_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (11, 5, true, 1, '2025-12-29 18:21:09.946285+02', 'Rwert wertwe rtwert wert wertwer wert.
Ertw dfgdfgh dfgh dfgh dfgh dfghd fgh dfgh.', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs (id, material_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, spec_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (16, 3, false, 1, '2025-12-29 18:49:21.202506+02', 'Duplicated from spec #1', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs (id, material_id, is_submitted, user_submitted_id, date_submitted, comments_submitted, spec_replaced_id, is_cancelled, user_cancelled_id, date_cancelled, comments_cancelled) OVERRIDING SYSTEM VALUE VALUES (17, 5, false, 1, '2025-12-29 18:51:02.864669+02', 'Duplicated from spec #11', NULL, false, NULL, NULL, NULL);


--
-- Data for Name: test_enums; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (13, 1, 'Item BA', 1, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (13, 2, 'Item BB', 2, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (8, 1, 'Item AA', 1, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (8, 2, 'Item AB', 2, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (8, 3, 'Item AC', 3, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (8, 4, 'Item AD', 4, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (8, 5, 'Item AE', 5, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (38, 1, 'Item KA', 1, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (38, 2, 'Item KB', 2, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (38, 3, 'Item KC', 3, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (38, 4, 'Item KD', 4, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (38, 5, 'Item KE', 5, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (39, 1, 'Item GEA', 1, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (39, 2, 'Item GEB', 2, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (39, 3, 'Item GEC', 3, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (44, 1, 'Item ME1', 1, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (44, 2, 'Item ME2', 2, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (44, 3, 'Item ME3', 3, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (44, 4, 'Item ME4', 4, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (44, 5, 'Item ME5', 5, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (45, 1, 'Item MAE1', 1, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (45, 2, 'Item MAE2', 2, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (45, 3, 'Item MAE3', 3, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (45, 4, 'Item MAE4', 4, false);
INSERT INTO public.test_enums (test_id, value, name, nr_ord, is_obsolete) VALUES (45, 5, 'Item MAE5', 5, false);


--
-- Data for Name: test_equipments; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: test_reagents; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: tests; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (1, 'Test A', 'test_a', 'Description Test A', 2, false, false, false, 2, 1, 'ref A', NULL, true, NULL, NULL, 1, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (2, 'Test B', 'test_b', 'Description Test B', 2, false, false, false, 2, 2, 'ref B', NULL, true, NULL, NULL, 2, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (3, 'Test C', 'test_c', 'Description Test C', 2, false, false, false, 2, 1, 'ref C', NULL, true, NULL, NULL, 3, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (4, 'Test D', 'test_d', 'Description Test D', 2, false, false, false, 2, 2, 'ref D', NULL, true, NULL, NULL, 4, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (5, 'Test E', 'test_e', 'Description Test E', 2, false, false, false, 2, 3, 'ref E', NULL, false, NULL, NULL, 5, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (6, 'Parameter AA', 'param_aa', 'Description Parameter AA', 2, false, true, false, 2, 1, NULL, NULL, false, NULL, NULL, 6, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (7, 'Parameter AB', 'param_ab', 'Description Parameter AB', 2, false, true, false, 2, 1, NULL, NULL, false, NULL, NULL, 7, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (8, 'Parameter AC', 'param_ac', 'Description Parameter AC', 4, false, true, false, 2, 1, NULL, NULL, false, NULL, NULL, 8, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (9, 'Parameter AD', 'param_ad', 'Description Parameter AD', 2, false, true, false, 2, 1, NULL, NULL, false, NULL, NULL, 9, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (10, 'Parameter AE', 'param_ae', 'Description Parameter AE', 3, false, true, false, 2, 1, NULL, NULL, false, NULL, NULL, 10, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (11, 'Parameter AF', 'param_af', 'Description Parameter AF', 2, false, true, false, 2, 1, NULL, NULL, false, NULL, NULL, 11, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (12, 'Parameter BA', 'param_ba', 'Description Parameter BA', 2, false, true, false, 2, 2, NULL, NULL, false, NULL, NULL, 12, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (13, 'Parameter BB', 'param_bb', 'Description Parameter BB', 4, false, true, false, 2, 2, NULL, NULL, false, NULL, NULL, 13, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (14, 'Parameter BC', 'param_bc', 'Description Parameter BC', 2, false, true, false, 2, 2, NULL, NULL, false, NULL, NULL, 14, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (15, 'Parameter BD', 'pbd', 'Description Parameter BD', 2, false, true, false, 2, 2, NULL, NULL, false, NULL, NULL, 15, false, NULL, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (16, 'Parameter CA', 'param_ca', 'Description Parameter CA', 2, false, true, false, 2, 1, NULL, NULL, false, NULL, NULL, 16, false, NULL, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (17, 'Parameter CB', 'param_cb', 'Description Parameter CB', 2, false, true, false, 2, 1, NULL, NULL, false, NULL, NULL, 17, false, NULL, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (18, 'Parameter CC', 'param_cc', 'Description Parameter CC', 2, false, true, false, 2, 1, NULL, NULL, false, NULL, NULL, 18, false, NULL, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (19, 'Parameter CD', 'param_cd', 'Description Parameter CD', 2, false, true, false, 2, 1, NULL, NULL, false, NULL, NULL, 19, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (20, 'Parameter DA', 'param_da', 'Description Parameter DA', 2, false, true, false, 2, 2, NULL, NULL, false, NULL, NULL, 20, false, NULL, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (21, 'Parameter DB', 'param_db', 'Description Parameter DB', 2, false, true, false, 2, 2, NULL, NULL, false, NULL, NULL, 21, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (22, 'Parameter DC', 'param_dc', 'Description Parameter DC', 2, false, true, false, 2, 2, NULL, NULL, false, NULL, NULL, 22, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (23, 'Parameter EA', 'param_ea', 'Description Parameter EA', 2, false, true, false, 2, 3, NULL, NULL, false, NULL, NULL, 23, false, NULL, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (24, 'Parameter EB', 'param_eb', 'Description Parameter EB', 2, false, true, false, 2, 3, NULL, NULL, false, NULL, NULL, 24, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (25, 'Parameter EC', 'param_ec', 'Description Parameter EC', 2, false, true, false, 2, 3, NULL, NULL, false, NULL, NULL, 25, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (26, 'Parameter FA', 'param_fa', 'Description Parameter FA', 2, false, true, false, 2, 2, NULL, NULL, false, NULL, NULL, 26, false, NULL, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (27, 'Parameter FB', 'param_fb', 'Description Parameter FB', 2, false, true, false, 2, 2, NULL, NULL, false, NULL, NULL, 27, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (28, 'Test G', 'test_g', 'Description Test G', 2, false, false, false, 2, 1, NULL, NULL, true, NULL, NULL, 28, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (29, 'Parameter GA', 'pga', NULL, 2, false, true, false, NULL, NULL, NULL, NULL, false, NULL, NULL, 36, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (30, 'Parameter GB', 'pgb', NULL, 2, true, true, false, NULL, NULL, NULL, NULL, false, NULL, NULL, 37, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (31, 'Parameter GC', 'pgc', NULL, 2, false, true, false, NULL, NULL, NULL, NULL, false, NULL, NULL, 38, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (36, 'Parameter GD', 'pgd', NULL, 2, true, true, false, NULL, NULL, NULL, NULL, false, NULL, NULL, 39, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (37, 'Test J', 'test_j', NULL, 2, true, false, false, NULL, NULL, NULL, NULL, true, NULL, NULL, 30, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (38, 'Test K', 'test_k', NULL, 4, false, false, false, NULL, NULL, NULL, NULL, true, NULL, NULL, 31, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (39, 'Parameter GE', 'pge', NULL, 4, true, true, false, NULL, NULL, NULL, NULL, false, NULL, NULL, 40, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (40, 'Parameter GF', 'pgf', NULL, 3, true, true, false, NULL, NULL, NULL, NULL, false, NULL, NULL, 41, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (41, 'Test H', 'test_h', 'Description Test H', 3, false, false, false, 10, NULL, NULL, NULL, true, NULL, NULL, 29, true, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (42, 'Test LB', 'tlb', 'Description Test LB', 3, false, false, false, 2, 1, NULL, NULL, true, NULL, NULL, 32, false, NULL, '2025-12-27 21:25:52.613339+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (43, 'Test LBA', 'tlba', 'Description Test LBA', 3, true, false, false, 2, 2, NULL, NULL, true, NULL, NULL, 33, false, NULL, '2025-12-27 21:26:41.616588+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (44, 'Test ME', 'tme', 'Description Test ME', 4, false, false, false, 2, 3, NULL, NULL, false, NULL, NULL, 34, false, NULL, '2025-12-27 21:27:51.890718+02', false, NULL, NULL);
INSERT INTO public.tests (id, name, code, description, type_id, is_array, is_param, for_environmental_control, unit_id, norm_id, norm_ref, sop_id, for_certification, relative_uncertainty_pct, default_coverage_factor_k, nr_ord, is_form_validated, date_form_validated, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (45, 'Test MAE', 'tmae', 'Description Test MAE', 4, true, false, false, 2, 2, NULL, NULL, true, NULL, NULL, 35, false, NULL, '2025-12-27 21:29:25.300316+02', false, NULL, NULL);


--
-- Data for Name: units; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.units (id, name, description, date_created) OVERRIDING SYSTEM VALUE VALUES (1, 'kg', 'Weight', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units (id, name, description, date_created) OVERRIDING SYSTEM VALUE VALUES (2, 'g', 'Weight', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units (id, name, description, date_created) OVERRIDING SYSTEM VALUE VALUES (3, 'L', 'Volume', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units (id, name, description, date_created) OVERRIDING SYSTEM VALUE VALUES (4, 'mL', 'Volume', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units (id, name, description, date_created) OVERRIDING SYSTEM VALUE VALUES (5, 'pcs', 'Count', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units (id, name, description, date_created) OVERRIDING SYSTEM VALUE VALUES (6, 'box', 'Count', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units (id, name, description, date_created) OVERRIDING SYSTEM VALUE VALUES (7, 'pack', 'Count', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units (id, name, description, date_created) OVERRIDING SYSTEM VALUE VALUES (8, 'Unit', 'Count', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units (id, name, description, date_created) OVERRIDING SYSTEM VALUE VALUES (9, '%', 'Percentage', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units (id, name, description, date_created) OVERRIDING SYSTEM VALUE VALUES (10, 'n.a.', 'Not Applicable', '2025-12-13 18:17:42.218999+02');


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.users (id, tag, code, email, first_name, last_name, is_admin, is_lab_pers, is_qc_pers, password_hash, password_salt, must_change_password, date_password_changed, failed_login_attempts, is_locked, lock_expiration, session_id, date_session_created, date_session_expire, refresh_token, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (1, 'alice', 'AL', 'alice@qc.lab', 'Alice', NULL, true, true, true, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', 0, false, NULL, NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users (id, tag, code, email, first_name, last_name, is_admin, is_lab_pers, is_qc_pers, password_hash, password_salt, must_change_password, date_password_changed, failed_login_attempts, is_locked, lock_expiration, session_id, date_session_created, date_session_expire, refresh_token, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (2, 'bob', 'BO', 'bob@qc.lab', 'Bob', NULL, false, false, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', 0, false, NULL, NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users (id, tag, code, email, first_name, last_name, is_admin, is_lab_pers, is_qc_pers, password_hash, password_salt, must_change_password, date_password_changed, failed_login_attempts, is_locked, lock_expiration, session_id, date_session_created, date_session_expire, refresh_token, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (3, 'charlie', 'CH', 'charlie@qc.lab', 'Charlie', NULL, false, false, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', 0, false, NULL, NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users (id, tag, code, email, first_name, last_name, is_admin, is_lab_pers, is_qc_pers, password_hash, password_salt, must_change_password, date_password_changed, failed_login_attempts, is_locked, lock_expiration, session_id, date_session_created, date_session_expire, refresh_token, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (4, 'david', 'DV', 'david@qc.lab', 'David', NULL, false, false, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', 0, false, NULL, NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', true, '2026-01-23 22:42:12.337979+02', 'Some explanations ...');
INSERT INTO public.users (id, tag, code, email, first_name, last_name, is_admin, is_lab_pers, is_qc_pers, password_hash, password_salt, must_change_password, date_password_changed, failed_login_attempts, is_locked, lock_expiration, session_id, date_session_created, date_session_expire, refresh_token, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (5, 'eve', 'EV', 'eve@qc.lab', 'Eve', NULL, false, true, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', 0, false, NULL, NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users (id, tag, code, email, first_name, last_name, is_admin, is_lab_pers, is_qc_pers, password_hash, password_salt, must_change_password, date_password_changed, failed_login_attempts, is_locked, lock_expiration, session_id, date_session_created, date_session_expire, refresh_token, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (6, 'frank', 'FR', 'frank@qc.lab', 'Frank', NULL, false, true, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', 0, false, NULL, NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users (id, tag, code, email, first_name, last_name, is_admin, is_lab_pers, is_qc_pers, password_hash, password_salt, must_change_password, date_password_changed, failed_login_attempts, is_locked, lock_expiration, session_id, date_session_created, date_session_expire, refresh_token, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (7, 'grace', 'GR', 'grace@qc.lab', 'Grace', NULL, false, false, true, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', 0, false, NULL, NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users (id, tag, code, email, first_name, last_name, is_admin, is_lab_pers, is_qc_pers, password_hash, password_salt, must_change_password, date_password_changed, failed_login_attempts, is_locked, lock_expiration, session_id, date_session_created, date_session_expire, refresh_token, date_created, is_obsolete, date_obsolete, comments_obsolete) OVERRIDING SYSTEM VALUE VALUES (8, 'heidi', 'HE', 'heidi@qc.lab', 'Heidi', NULL, true, false, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', 0, false, NULL, '646582b1-660d-4823-9c1e-3528d41a2d1b', '2025-12-13 18:17:42.218999+02', NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);


--
-- Data for Name: value_types; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.value_types (id, name) OVERRIDING SYSTEM VALUE VALUES (1, 'integer');
INSERT INTO public.value_types (id, name) OVERRIDING SYSTEM VALUE VALUES (2, 'real');
INSERT INTO public.value_types (id, name) OVERRIDING SYSTEM VALUE VALUES (3, 'boolean');
INSERT INTO public.value_types (id, name) OVERRIDING SYSTEM VALUE VALUES (4, 'enum');


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 1, false);


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.categories_id_seq', 4, false);


--
-- Name: certification_headers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.certification_headers_id_seq', 9, false);


--
-- Name: electronic_signatures_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.electronic_signatures_id_seq', 1, false);


--
-- Name: equipment_calibrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.equipment_calibrations_id_seq', 1, false);


--
-- Name: equipment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.equipment_id_seq', 1, false);


--
-- Name: form_condition_evals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.form_condition_evals_id_seq', 1, false);


--
-- Name: form_evals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.form_evals_id_seq', 16, false);


--
-- Name: form_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.form_groups_id_seq', 9, false);


--
-- Name: forms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.forms_id_seq', 10, false);


--
-- Name: materials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.materials_id_seq', 22, false);


--
-- Name: measurement_details_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.measurement_details_id_seq', 54, false);


--
-- Name: norms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.norms_id_seq', 5, false);


--
-- Name: reagent_suppliers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reagent_suppliers_id_seq', 1, false);


--
-- Name: receptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.receptions_id_seq', 72, false);


--
-- Name: receptions_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.receptions_id_seq1', 23, false);


--
-- Name: reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reports_id_seq', 29, false);


--
-- Name: sop_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sop_versions_id_seq', 1, false);


--
-- Name: sops_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sops_id_seq', 1, false);


--
-- Name: spec_headers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.spec_headers_id_seq', 18, false);


--
-- Name: spec_test_evals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.spec_test_evals_id_seq', 180, false);


--
-- Name: tests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tests_id_seq', 46, false);


--
-- Name: units_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.units_id_seq', 11, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 9, false);


--
-- Name: value_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.value_types_id_seq', 5, false);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: categories categories_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_code_key UNIQUE (code);


--
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: category_tests category_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.category_tests
    ADD CONSTRAINT category_tests_pkey PRIMARY KEY (category_id, test_id);


--
-- Name: certificate_tests certificate_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_pkey PRIMARY KEY (certificate_id, report_id, test_id, idx, measurement_id);


--
-- Name: certificates certificates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_pkey PRIMARY KEY (id);


--
-- Name: control_codes control_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.control_codes
    ADD CONSTRAINT control_codes_pkey PRIMARY KEY (id);


--
-- Name: electronic_signatures electronic_signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.electronic_signatures
    ADD CONSTRAINT electronic_signatures_pkey PRIMARY KEY (id);


--
-- Name: equipment_calibrations equipment_calibrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipment_calibrations
    ADD CONSTRAINT equipment_calibrations_pkey PRIMARY KEY (id);


--
-- Name: equipments equipment_equipment_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipments
    ADD CONSTRAINT equipment_equipment_code_key UNIQUE (equipment_code);


--
-- Name: equipments equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipments
    ADD CONSTRAINT equipment_pkey PRIMARY KEY (id);


--
-- Name: form_condition_evals form_condition_evals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_condition_evals
    ADD CONSTRAINT form_condition_evals_pkey PRIMARY KEY (id);


--
-- Name: form_eval_params form_eval_params_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_pkey PRIMARY KEY (eval_id, form_id, test_id, idx);


--
-- Name: form_evals form_evals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_evals
    ADD CONSTRAINT form_evals_pkey PRIMARY KEY (id);


--
-- Name: form_groups form_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_groups
    ADD CONSTRAINT form_groups_pkey PRIMARY KEY (id);


--
-- Name: form_params form_params_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_params
    ADD CONSTRAINT form_params_pkey PRIMARY KEY (form_id, test_id);


--
-- Name: forms forms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forms
    ADD CONSTRAINT forms_pkey PRIMARY KEY (id);


--
-- Name: material_tests material_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_tests
    ADD CONSTRAINT material_tests_pkey PRIMARY KEY (material_id, test_id);


--
-- Name: materials materials_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_code_key UNIQUE (code);


--
-- Name: materials materials_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_name_key UNIQUE (name);


--
-- Name: materials materials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_pkey PRIMARY KEY (id);


--
-- Name: measurement_equipments measurement_equipments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_equipments
    ADD CONSTRAINT measurement_equipments_pkey PRIMARY KEY (measurement_id, equipment_id);


--
-- Name: measurement_params measurement_params_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_pkey PRIMARY KEY (measurement_id, form_id, test_id, idx);


--
-- Name: measurement_reagent_lots measurement_reagent_lots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_reagent_lots
    ADD CONSTRAINT measurement_reagent_lots_pkey PRIMARY KEY (measurement_id, control_code_id);


--
-- Name: measurement_sop_versions measurement_sop_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_sop_versions
    ADD CONSTRAINT measurement_sop_versions_pkey PRIMARY KEY (measurement_id, sop_version_id);


--
-- Name: measurement_tests measurement_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_tests
    ADD CONSTRAINT measurement_tests_pkey PRIMARY KEY (measurement_id, test_id, idx);


--
-- Name: measurements measurements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_pkey PRIMARY KEY (id);


--
-- Name: norms norms_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.norms
    ADD CONSTRAINT norms_name_key UNIQUE (name);


--
-- Name: norms norms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.norms
    ADD CONSTRAINT norms_pkey PRIMARY KEY (id);


--
-- Name: reagent_lot_statuses reagent_lot_statuses_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_lot_statuses
    ADD CONSTRAINT reagent_lot_statuses_name_key UNIQUE (name);


--
-- Name: reagent_lot_statuses reagent_lot_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_lot_statuses
    ADD CONSTRAINT reagent_lot_statuses_pkey PRIMARY KEY (id);


--
-- Name: reagent_lots reagent_lots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_lots
    ADD CONSTRAINT reagent_lots_pkey PRIMARY KEY (control_code_id);


--
-- Name: reagent_production_lots reagent_production_lots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_production_lots
    ADD CONSTRAINT reagent_production_lots_pkey PRIMARY KEY (control_code_id, ingredient_control_code_id);


--
-- Name: reagent_supplier_lots reagent_supplier_lots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_supplier_lots
    ADD CONSTRAINT reagent_supplier_lots_pkey PRIMARY KEY (control_code_id);


--
-- Name: reagent_suppliers reagent_suppliers_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_suppliers
    ADD CONSTRAINT reagent_suppliers_name_key UNIQUE (name);


--
-- Name: reagent_suppliers reagent_suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_suppliers
    ADD CONSTRAINT reagent_suppliers_pkey PRIMARY KEY (id);


--
-- Name: reception_tests reception_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reception_tests
    ADD CONSTRAINT reception_tests_pkey PRIMARY KEY (reception_id, test_id);


--
-- Name: reception_types reception_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reception_types
    ADD CONSTRAINT reception_types_pkey PRIMARY KEY (id);


--
-- Name: receptions receptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_pkey PRIMARY KEY (id);


--
-- Name: report_tests report_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_tests
    ADD CONSTRAINT report_tests_pkey PRIMARY KEY (report_id, measurement_id, test_id, idx);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: sop_versions sop_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sop_versions
    ADD CONSTRAINT sop_versions_pkey PRIMARY KEY (id);


--
-- Name: sops sops_doc_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sops
    ADD CONSTRAINT sops_doc_code_key UNIQUE (doc_code);


--
-- Name: sops sops_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sops
    ADD CONSTRAINT sops_pkey PRIMARY KEY (id);


--
-- Name: spec_test_evals spec_test_evals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spec_test_evals
    ADD CONSTRAINT spec_test_evals_pkey PRIMARY KEY (id);


--
-- Name: spec_tests spec_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spec_tests
    ADD CONSTRAINT spec_tests_pkey PRIMARY KEY (spec_id, test_id);


--
-- Name: specs specs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specs
    ADD CONSTRAINT specs_pkey PRIMARY KEY (id);


--
-- Name: test_enums test_enums_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_enums
    ADD CONSTRAINT test_enums_pkey PRIMARY KEY (test_id, value);


--
-- Name: test_enums test_enums_test_id_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_enums
    ADD CONSTRAINT test_enums_test_id_name_key UNIQUE (test_id, name);


--
-- Name: test_equipments test_equipments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_equipments
    ADD CONSTRAINT test_equipments_pkey PRIMARY KEY (test_id, equipment_id);


--
-- Name: test_reagents test_reagents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_reagents
    ADD CONSTRAINT test_reagents_pkey PRIMARY KEY (test_id, material_id);


--
-- Name: tests tests_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_code_key UNIQUE (code);


--
-- Name: tests tests_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_name_key UNIQUE (name);


--
-- Name: tests tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_pkey PRIMARY KEY (id);


--
-- Name: units units_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_name_key UNIQUE (name);


--
-- Name: units units_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_pkey PRIMARY KEY (id);


--
-- Name: sop_versions unq_sop_version_number; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sop_versions
    ADD CONSTRAINT unq_sop_version_number UNIQUE (sop_id, version_number);


--
-- Name: users users_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_code_key UNIQUE (code);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_session_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_session_id_key UNIQUE (session_id);


--
-- Name: users users_tag_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_tag_key UNIQUE (tag);


--
-- Name: value_types value_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.value_types
    ADD CONSTRAINT value_types_pkey PRIMARY KEY (id);


--
-- Name: unq_single_active_sop_version; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unq_single_active_sop_version ON public.sop_versions USING btree (sop_id) WHERE (is_active = true);


--
-- Name: measurement_params audit_measurement_params_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_measurement_params_trigger AFTER INSERT OR DELETE OR UPDATE ON public.measurement_params FOR EACH ROW EXECUTE FUNCTION public.process_audit_log();


--
-- Name: measurement_tests audit_measurement_tests_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_measurement_tests_trigger AFTER INSERT OR DELETE OR UPDATE ON public.measurement_tests FOR EACH ROW EXECUTE FUNCTION public.process_audit_log();


--
-- Name: measurements audit_measurements_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_measurements_trigger AFTER INSERT OR DELETE OR UPDATE ON public.measurements FOR EACH ROW EXECUTE FUNCTION public.process_audit_log();


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: category_tests category_tests_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.category_tests
    ADD CONSTRAINT category_tests_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- Name: category_tests category_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.category_tests
    ADD CONSTRAINT category_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: certificate_tests certificate_tests_certificates_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_certificates_id_fkey FOREIGN KEY (certificate_id) REFERENCES public.certificates(id) ON DELETE CASCADE;


--
-- Name: certificate_tests certificate_tests_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id);


--
-- Name: certificate_tests certificate_tests_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(id);


--
-- Name: certificate_tests certificate_tests_report_id_measurement_id_test_id_idx_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_report_id_measurement_id_test_id_idx_fkey FOREIGN KEY (report_id, measurement_id, test_id, idx) REFERENCES public.report_tests(report_id, measurement_id, test_id, idx);


--
-- Name: certificate_tests certificate_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: certificates certificates_certificate_replaced_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_certificate_replaced_id_fkey FOREIGN KEY (certificate_replaced_id) REFERENCES public.certificates(id);


--
-- Name: certificates certificates_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_control_code_id_fkey FOREIGN KEY (control_code_id) REFERENCES public.control_codes(id);


--
-- Name: certificates certificates_specs_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_specs_id_fkey FOREIGN KEY (spec_id) REFERENCES public.specs(id);


--
-- Name: certificates certificates_user_cancelled_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_user_cancelled_id_fkey FOREIGN KEY (user_cancelled_id) REFERENCES public.users(id);


--
-- Name: certificates certificates_user_submitted_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_user_submitted_id_fkey FOREIGN KEY (user_submitted_id) REFERENCES public.users(id);


--
-- Name: control_codes control_codes_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.control_codes
    ADD CONSTRAINT control_codes_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: electronic_signatures electronic_signatures_signer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.electronic_signatures
    ADD CONSTRAINT electronic_signatures_signer_user_id_fkey FOREIGN KEY (signer_user_id) REFERENCES public.users(id);


--
-- Name: equipment_calibrations equipment_calibrations_equipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipment_calibrations
    ADD CONSTRAINT equipment_calibrations_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipments(id) ON DELETE CASCADE;


--
-- Name: form_condition_evals form_condition_evals_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_condition_evals
    ADD CONSTRAINT form_condition_evals_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id) ON DELETE CASCADE;


--
-- Name: form_condition_evals form_condition_evals_form_id_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_condition_evals
    ADD CONSTRAINT form_condition_evals_form_id_test_id_fkey FOREIGN KEY (form_id, test_id) REFERENCES public.form_params(form_id, test_id) ON DELETE CASCADE;


--
-- Name: form_condition_evals form_condition_evals_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_condition_evals
    ADD CONSTRAINT form_condition_evals_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: form_eval_params form_eval_params_eval_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_eval_id_fkey FOREIGN KEY (eval_id) REFERENCES public.form_evals(id) ON DELETE CASCADE;


--
-- Name: form_eval_params form_eval_params_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id) ON DELETE CASCADE;


--
-- Name: form_eval_params form_eval_params_form_id_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_form_id_test_id_fkey FOREIGN KEY (form_id, test_id) REFERENCES public.form_params(form_id, test_id) ON DELETE CASCADE;


--
-- Name: form_eval_params form_eval_params_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: form_evals form_evals_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_evals
    ADD CONSTRAINT form_evals_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id) ON DELETE CASCADE;


--
-- Name: form_params form_params_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_params
    ADD CONSTRAINT form_params_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id) ON DELETE CASCADE;


--
-- Name: form_params form_params_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_params
    ADD CONSTRAINT form_params_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: forms forms_form_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forms
    ADD CONSTRAINT forms_form_group_id_fkey FOREIGN KEY (form_group_id) REFERENCES public.form_groups(id);


--
-- Name: forms forms_user_canceled_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forms
    ADD CONSTRAINT forms_user_canceled_id_fkey FOREIGN KEY (user_cancelled_id) REFERENCES public.users(id);


--
-- Name: forms forms_user_submitted_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forms
    ADD CONSTRAINT forms_user_submitted_id_fkey FOREIGN KEY (user_submitted_id) REFERENCES public.users(id);


--
-- Name: forms forms_user_validated_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forms
    ADD CONSTRAINT forms_user_validated_id_fkey FOREIGN KEY (user_validated_id) REFERENCES public.users(id);


--
-- Name: material_tests material_tests_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_tests
    ADD CONSTRAINT material_tests_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id) ON DELETE CASCADE;


--
-- Name: material_tests material_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_tests
    ADD CONSTRAINT material_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: materials materials_norm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_norm_id_fkey FOREIGN KEY (norm_id) REFERENCES public.norms(id);


--
-- Name: measurement_equipments measurement_equipments_equipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_equipments
    ADD CONSTRAINT measurement_equipments_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipments(id);


--
-- Name: measurement_equipments measurement_equipments_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_equipments
    ADD CONSTRAINT measurement_equipments_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id) ON DELETE CASCADE;


--
-- Name: measurement_params measurement_params_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id);


--
-- Name: measurement_params measurement_params_form_id_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_form_id_test_id_fkey FOREIGN KEY (form_id, test_id) REFERENCES public.form_params(form_id, test_id);


--
-- Name: measurement_params measurement_params_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id) ON DELETE CASCADE;


--
-- Name: measurement_params measurement_params_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: measurement_reagent_lots measurement_reagent_lots_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_reagent_lots
    ADD CONSTRAINT measurement_reagent_lots_control_code_id_fkey FOREIGN KEY (control_code_id) REFERENCES public.reagent_lots(control_code_id);


--
-- Name: measurement_reagent_lots measurement_reagent_lots_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_reagent_lots
    ADD CONSTRAINT measurement_reagent_lots_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id) ON DELETE CASCADE;


--
-- Name: measurement_sop_versions measurement_sop_versions_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_sop_versions
    ADD CONSTRAINT measurement_sop_versions_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id) ON DELETE CASCADE;


--
-- Name: measurement_sop_versions measurement_sop_versions_sop_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_sop_versions
    ADD CONSTRAINT measurement_sop_versions_sop_version_id_fkey FOREIGN KEY (sop_version_id) REFERENCES public.sop_versions(id);


--
-- Name: measurement_tests measurement_tests_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_tests
    ADD CONSTRAINT measurement_tests_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id) ON DELETE CASCADE;


--
-- Name: measurement_tests measurement_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_tests
    ADD CONSTRAINT measurement_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: measurements measurements_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id);


--
-- Name: measurements measurements_reception_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_reception_id_fkey FOREIGN KEY (reception_id) REFERENCES public.receptions(id);


--
-- Name: measurements measurements_user_created_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_user_created_id_fkey FOREIGN KEY (user_created_id) REFERENCES public.users(id);


--
-- Name: measurements measurements_user_reported_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_user_reported_id_fkey FOREIGN KEY (user_reported_id) REFERENCES public.users(id);


--
-- Name: measurements measurements_user_update_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_user_update_id_fkey FOREIGN KEY (user_update_id) REFERENCES public.users(id);


--
-- Name: reagent_lots reagent_lots_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_lots
    ADD CONSTRAINT reagent_lots_control_code_id_fkey FOREIGN KEY (control_code_id) REFERENCES public.control_codes(id);


--
-- Name: reagent_lots reagent_lots_produced_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_lots
    ADD CONSTRAINT reagent_lots_produced_by_user_id_fkey FOREIGN KEY (produced_by_user_id) REFERENCES public.users(id);


--
-- Name: reagent_lots reagent_lots_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_lots
    ADD CONSTRAINT reagent_lots_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.reagent_lot_statuses(id);


--
-- Name: reagent_lots reagent_lots_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_lots
    ADD CONSTRAINT reagent_lots_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id);


--
-- Name: reagent_production_lots reagent_production_lots_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_production_lots
    ADD CONSTRAINT reagent_production_lots_control_code_id_fkey FOREIGN KEY (control_code_id) REFERENCES public.reagent_lots(control_code_id);


--
-- Name: reagent_production_lots reagent_production_lots_ingredient_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_production_lots
    ADD CONSTRAINT reagent_production_lots_ingredient_control_code_id_fkey FOREIGN KEY (ingredient_control_code_id) REFERENCES public.reagent_lots(control_code_id);


--
-- Name: reagent_supplier_lots reagent_supplier_lots_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_supplier_lots
    ADD CONSTRAINT reagent_supplier_lots_control_code_id_fkey FOREIGN KEY (control_code_id) REFERENCES public.reagent_lots(control_code_id);


--
-- Name: reagent_supplier_lots reagent_supplier_lots_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_supplier_lots
    ADD CONSTRAINT reagent_supplier_lots_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.reagent_suppliers(id);


--
-- Name: reception_tests reception_tests_reception_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reception_tests
    ADD CONSTRAINT reception_tests_reception_id_fkey FOREIGN KEY (reception_id) REFERENCES public.receptions(id);


--
-- Name: reception_tests reception_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reception_tests
    ADD CONSTRAINT reception_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: receptions receptions_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: receptions receptions_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_control_code_id_fkey FOREIGN KEY (control_code_id) REFERENCES public.control_codes(id);


--
-- Name: receptions receptions_reception_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_reception_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.reception_types(id);


--
-- Name: receptions receptions_user_received_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_user_received_id_fkey FOREIGN KEY (user_received_id) REFERENCES public.users(id);


--
-- Name: receptions receptions_user_rejected_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_user_rejected_id_fkey FOREIGN KEY (user_rejected_id) REFERENCES public.users(id);


--
-- Name: receptions receptions_user_submitted_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_user_submitted_id_fkey FOREIGN KEY (user_submitted_id) REFERENCES public.users(id);


--
-- Name: report_tests report_tests_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_tests
    ADD CONSTRAINT report_tests_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id);


--
-- Name: report_tests report_tests_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_tests
    ADD CONSTRAINT report_tests_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(id) ON DELETE CASCADE;


--
-- Name: report_tests report_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_tests
    ADD CONSTRAINT report_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: reports reports_reception_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_reception_id_fkey FOREIGN KEY (reception_id) REFERENCES public.receptions(id);


--
-- Name: reports reports_report_replaced_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_report_replaced_id_fkey FOREIGN KEY (report_replaced_id) REFERENCES public.reports(id);


--
-- Name: reports reports_user_cancelled_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_user_cancelled_id_fkey FOREIGN KEY (user_cancelled_id) REFERENCES public.users(id);


--
-- Name: reports reports_user_submitted_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_user_submitted_id_fkey FOREIGN KEY (user_submitted_id) REFERENCES public.users(id);


--
-- Name: sop_versions sop_versions_sop_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sop_versions
    ADD CONSTRAINT sop_versions_sop_id_fkey FOREIGN KEY (sop_id) REFERENCES public.sops(id) ON DELETE CASCADE;


--
-- Name: sops sops_norm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sops
    ADD CONSTRAINT sops_norm_id_fkey FOREIGN KEY (norm_id) REFERENCES public.norms(id) ON DELETE CASCADE;


--
-- Name: spec_test_evals spec_test_evals_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spec_test_evals
    ADD CONSTRAINT spec_test_evals_spec_id_fkey FOREIGN KEY (spec_id) REFERENCES public.specs(id);


--
-- Name: spec_test_evals spec_test_evals_spec_id_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spec_test_evals
    ADD CONSTRAINT spec_test_evals_spec_id_test_id_fkey FOREIGN KEY (spec_id, test_id) REFERENCES public.spec_tests(spec_id, test_id) ON DELETE CASCADE;


--
-- Name: spec_test_evals spec_test_evals_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spec_test_evals
    ADD CONSTRAINT spec_test_evals_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: spec_tests spec_tests_specs_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spec_tests
    ADD CONSTRAINT spec_tests_specs_id_fkey FOREIGN KEY (spec_id) REFERENCES public.specs(id) ON DELETE CASCADE;


--
-- Name: spec_tests spec_tests_tests_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spec_tests
    ADD CONSTRAINT spec_tests_tests_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: specs specs_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specs
    ADD CONSTRAINT specs_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: specs specs_spec_replaced_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specs
    ADD CONSTRAINT specs_spec_replaced_id_fkey FOREIGN KEY (spec_replaced_id) REFERENCES public.specs(id);


--
-- Name: specs specs_user_cancelled_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specs
    ADD CONSTRAINT specs_user_cancelled_id_fkey FOREIGN KEY (user_cancelled_id) REFERENCES public.users(id);


--
-- Name: specs specs_user_submitted_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specs
    ADD CONSTRAINT specs_user_submitted_id_fkey FOREIGN KEY (user_submitted_id) REFERENCES public.users(id);


--
-- Name: test_enums test_enums_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_enums
    ADD CONSTRAINT test_enums_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) ON DELETE CASCADE;


--
-- Name: test_equipments test_equipments_equipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_equipments
    ADD CONSTRAINT test_equipments_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipments(id) NOT VALID;


--
-- Name: test_equipments test_equipments_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_equipments
    ADD CONSTRAINT test_equipments_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) ON DELETE CASCADE;


--
-- Name: test_reagents test_reagents_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_reagents
    ADD CONSTRAINT test_reagents_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: test_reagents test_reagents_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_reagents
    ADD CONSTRAINT test_reagents_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) ON DELETE CASCADE;


--
-- Name: tests tests_norm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_norm_id_fkey FOREIGN KEY (norm_id) REFERENCES public.norms(id);


--
-- Name: tests tests_sop_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_sop_id_fkey FOREIGN KEY (sop_id) REFERENCES public.sops(id) NOT VALID;


--
-- Name: tests tests_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id);


--
-- Name: tests tests_value_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_value_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.value_types(id);


--
-- PostgreSQL database dump complete
--

