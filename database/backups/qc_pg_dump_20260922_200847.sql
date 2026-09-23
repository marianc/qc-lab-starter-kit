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
    code character varying(3) NOT NULL,
    description text,
    date_created timestamp with time zone NOT NULL,
    is_obsolete boolean DEFAULT false NOT NULL,
    date_obsolete timestamp with time zone,
    comments_obsolete text
);


ALTER TABLE public.categories OWNER TO postgres;

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
-- Name: form_evals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.form_evals (
    id bigint NOT NULL,
    form_id bigint NOT NULL,
    description text
);


ALTER TABLE public.form_evals OWNER TO postgres;

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
    nr_ord bigint DEFAULT 0 NOT NULL,
    is_form_validated boolean DEFAULT false NOT NULL
);


ALTER TABLE public.form_groups OWNER TO postgres;

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
    nr_ord bigint DEFAULT 0 NOT NULL,
    nr_ord_calc bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.form_params OWNER TO postgres;

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
    cas_number character varying(20),
    date_created timestamp with time zone NOT NULL,
    is_obsolete boolean DEFAULT false NOT NULL,
    date_obsolete timestamp with time zone,
    comments_obsolete text
);


ALTER TABLE public.materials OWNER TO postgres;

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
    user_update_id bigint NOT NULL,
    date_update timestamp with time zone NOT NULL,
    is_reported boolean DEFAULT false NOT NULL,
    user_reported_id bigint,
    date_reported timestamp with time zone,
    is_readonly boolean DEFAULT false NOT NULL,
    date_readonly timestamp with time zone,
    user_created_id bigint NOT NULL,
    date_created timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE public.measurements OWNER TO postgres;

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
-- Name: measurement_params; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.measurement_params (
    measurement_id bigint NOT NULL,
    form_id bigint NOT NULL,
    test_id bigint NOT NULL,
    idx integer DEFAULT 0 NOT NULL,
    value numeric NOT NULL,
    condition_value numeric
);


ALTER TABLE public.measurement_params OWNER TO postgres;

--
-- Name: measurement_reagent_lots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.measurement_reagent_lots (
    measurement_id bigint NOT NULL,
    control_code_id bigint NOT NULL
);


ALTER TABLE public.measurement_reagent_lots OWNER TO postgres;

--
-- Name: measurement_sop_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.measurement_sop_versions (
    measurement_id bigint NOT NULL,
    sop_version_id bigint NOT NULL
);


ALTER TABLE public.measurement_sop_versions OWNER TO postgres;

--
-- Name: measurement_tests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.measurement_tests (
    measurement_id bigint NOT NULL,
    test_id bigint NOT NULL,
    idx integer DEFAULT 0 NOT NULL,
    value numeric NOT NULL,
    note character varying(20)
);


ALTER TABLE public.measurement_tests OWNER TO postgres;

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
-- Name: reagent_production_lots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reagent_production_lots (
    control_code_id bigint NOT NULL,
    ingredient_control_code_id bigint NOT NULL
);


ALTER TABLE public.reagent_production_lots OWNER TO postgres;

--
-- Name: reagent_supplier_lots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reagent_supplier_lots (
    control_code_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    catalog_number character varying(50),
    manufacturer_lot_number character varying(50) NOT NULL,
    certificate_of_analysis_ref character varying(255),
    comments character varying(255)
);


ALTER TABLE public.reagent_supplier_lots OWNER TO postgres;

--
-- Name: reagent_suppliers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reagent_suppliers (
    id bigint NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.reagent_suppliers OWNER TO postgres;

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
-- Name: reception_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reception_types (
    id bigint NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.reception_types OWNER TO postgres;

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
    date_created timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


ALTER TABLE public.sops OWNER TO postgres;

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
-- Name: test_equipments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_equipments (
    test_id bigint NOT NULL,
    equipment_id bigint NOT NULL
);


ALTER TABLE public.test_equipments OWNER TO postgres;

--
-- Name: test_reagents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_reagents (
    test_id bigint NOT NULL,
    material_id bigint NOT NULL
);


ALTER TABLE public.test_reagents OWNER TO postgres;

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
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (1, 'measurements', '{"id": 59}', 'INSERT', NULL, '{"id": 59, "form_id": 15, "comments": null, "date_update": "2026-09-15T21:17:24.177049+03:00", "is_readonly": false, "is_reported": false, "date_created": "2026-09-15T21:17:24.225516+03:00", "reception_id": 28, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": null, "use_default_equipment": true}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.255968+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (2, 'measurements', '{"id": 59}', 'UPDATE', '{"id": 59, "form_id": 15, "comments": null, "date_update": "2026-09-15T21:17:24.177049+03:00", "is_readonly": false, "is_reported": false, "date_created": "2026-09-15T21:17:24.225516+03:00", "reception_id": 28, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": null, "use_default_equipment": true}', '{"id": 59, "form_id": 15, "comments": null, "date_update": "2026-09-15T21:17:24.325603+03:00", "is_readonly": false, "is_reported": false, "date_created": "2026-09-15T21:17:24.225516+03:00", "reception_id": 28, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": null, "use_default_equipment": true}', '{date_update}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.335973+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (3, 'measurement_params', '{"idx": 0, "form_id": 15, "test_id": 102, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 0, "value": 21.5, "form_id": 15, "test_id": 102, "measurement_id": 59, "condition_value": 1}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.544116+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (4, 'measurement_params', '{"idx": 0, "form_id": 15, "test_id": 103, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 0, "value": 48.2, "form_id": 15, "test_id": 103, "measurement_id": 59, "condition_value": 1}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.550542+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (5, 'measurement_params', '{"idx": 0, "form_id": 15, "test_id": 107, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 0, "value": 0, "form_id": 15, "test_id": 107, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.557279+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (6, 'measurement_params', '{"idx": 1, "form_id": 15, "test_id": 107, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 1, "value": 10.04, "form_id": 15, "test_id": 107, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.566314+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (7, 'measurement_params', '{"idx": 2, "form_id": 15, "test_id": 107, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 2, "value": 20.06, "form_id": 15, "test_id": 107, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.574423+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (8, 'measurement_params', '{"idx": 0, "form_id": 15, "test_id": 108, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 0, "value": 10.04, "form_id": 15, "test_id": 108, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.584371+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (9, 'measurement_params', '{"idx": 1, "form_id": 15, "test_id": 108, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 1, "value": 20.06, "form_id": 15, "test_id": 108, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.588233+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (10, 'measurement_params', '{"idx": 2, "form_id": 15, "test_id": 108, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 2, "value": 30.09, "form_id": 15, "test_id": 108, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.591544+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (11, 'measurement_params', '{"idx": 0, "form_id": 15, "test_id": 109, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 0, "value": 10.04, "form_id": 15, "test_id": 109, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.594609+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (12, 'measurement_params', '{"idx": 1, "form_id": 15, "test_id": 109, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 1, "value": 10.02, "form_id": 15, "test_id": 109, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.597565+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (13, 'measurement_params', '{"idx": 2, "form_id": 15, "test_id": 109, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 2, "value": 10.03, "form_id": 15, "test_id": 109, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.600279+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (14, 'measurement_params', '{"idx": 0, "form_id": 15, "test_id": 110, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 0, "value": 0.016667, "form_id": 15, "test_id": 110, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.603133+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (15, 'measurement_params', '{"idx": 0, "form_id": 15, "test_id": 111, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 0, "value": 0.099604, "form_id": 15, "test_id": 111, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.605951+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (16, 'measurement_params', '{"idx": 1, "form_id": 15, "test_id": 111, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 1, "value": 0.099802, "form_id": 15, "test_id": 111, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.608829+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (17, 'measurement_params', '{"idx": 2, "form_id": 15, "test_id": 111, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 2, "value": 0.099703, "form_id": 15, "test_id": 111, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.611779+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (18, 'measurement_params', '{"idx": 0, "form_id": 15, "test_id": 112, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 0, "value": 0.099703, "form_id": 15, "test_id": 112, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.614709+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (19, 'measurement_params', '{"idx": 0, "form_id": 15, "test_id": 113, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 0, "value": 0.000099, "form_id": 15, "test_id": 113, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.617711+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (20, 'measurement_params', '{"idx": 0, "form_id": 15, "test_id": 114, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 0, "value": 0.10, "form_id": 15, "test_id": 114, "measurement_id": 59, "condition_value": 1}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.622202+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (21, 'measurement_params', '{"idx": 0, "form_id": 15, "test_id": 115, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 0, "value": 1.2258, "form_id": 15, "test_id": 115, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.624928+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (22, 'measurement_params', '{"idx": 0, "form_id": 15, "test_id": 116, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 0, "value": 10, "form_id": 15, "test_id": 116, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.627848+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (23, 'measurement_params', '{"idx": 1, "form_id": 15, "test_id": 116, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 1, "value": 10, "form_id": 15, "test_id": 116, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.630661+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (24, 'measurement_params', '{"idx": 2, "form_id": 15, "test_id": 116, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 2, "value": 10, "form_id": 15, "test_id": 116, "measurement_id": 59, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.633341+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (25, 'measurement_params', '{"idx": 0, "form_id": 15, "test_id": 117, "measurement_id": 59}', 'INSERT', NULL, '{"idx": 0, "value": 3, "form_id": 15, "test_id": 117, "measurement_id": 59, "condition_value": 1}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:17:24.636044+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (26, 'measurements', '{"id": 59}', 'UPDATE', '{"id": 59, "form_id": 15, "comments": null, "date_update": "2026-09-15T21:17:24.325603+03:00", "is_readonly": false, "is_reported": false, "date_created": "2026-09-15T21:17:24.225516+03:00", "reception_id": 28, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": null, "use_default_equipment": true}', '{"id": 59, "form_id": 15, "comments": null, "date_update": "2026-09-15T21:17:24.325603+03:00", "is_readonly": false, "is_reported": true, "date_created": "2026-09-15T21:17:24.225516+03:00", "reception_id": 28, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": 1, "use_default_equipment": true}', '{is_reported,user_reported_id}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:28:19.323375+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (27, 'measurements', '{"id": 59}', 'UPDATE', '{"id": 59, "form_id": 15, "comments": null, "date_update": "2026-09-15T21:17:24.325603+03:00", "is_readonly": false, "is_reported": true, "date_created": "2026-09-15T21:17:24.225516+03:00", "reception_id": 28, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": 1, "use_default_equipment": true}', '{"id": 59, "form_id": 15, "comments": null, "date_update": "2026-09-15T21:17:24.325603+03:00", "is_readonly": true, "is_reported": true, "date_created": "2026-09-15T21:17:24.225516+03:00", "reception_id": 28, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": 1, "use_default_equipment": true}', '{is_readonly}', 1, 'Operation performed via QCLab system API', '2026-09-15 21:29:01.223722+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (28, 'measurements', '{"id": 60}', 'INSERT', NULL, '{"id": 60, "form_id": 16, "comments": null, "date_update": "2026-09-16T22:35:49.300829+03:00", "is_readonly": false, "is_reported": false, "date_created": "2026-09-16T22:35:49.343915+03:00", "reception_id": 29, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": null, "use_default_equipment": true}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.375356+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (29, 'measurements', '{"id": 60}', 'UPDATE', '{"id": 60, "form_id": 16, "comments": null, "date_update": "2026-09-16T22:35:49.300829+03:00", "is_readonly": false, "is_reported": false, "date_created": "2026-09-16T22:35:49.343915+03:00", "reception_id": 29, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": null, "use_default_equipment": true}', '{"id": 60, "form_id": 16, "comments": null, "date_update": "2026-09-16T22:35:49.416688+03:00", "is_readonly": false, "is_reported": false, "date_created": "2026-09-16T22:35:49.343915+03:00", "reception_id": 29, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": null, "use_default_equipment": true}', '{date_update}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.426166+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (30, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 102, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 21.5, "form_id": 16, "test_id": 102, "measurement_id": 60, "condition_value": 1}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.526872+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (31, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 103, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 48.2, "form_id": 16, "test_id": 103, "measurement_id": 60, "condition_value": 1}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.531707+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (32, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 104, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 0.51, "form_id": 16, "test_id": 104, "measurement_id": 60, "condition_value": 1}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.536797+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (33, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 118, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 14.2851, "form_id": 16, "test_id": 118, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.542415+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (34, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 119, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 26.5448, "form_id": 16, "test_id": 119, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.548792+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (35, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 120, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 1, "form_id": 16, "test_id": 120, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.555719+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (36, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 121, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 0.2502, "form_id": 16, "test_id": 121, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.558044+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (37, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 122, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 10, "form_id": 16, "test_id": 122, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.560549+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (38, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 123, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 0, "form_id": 16, "test_id": 123, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.562763+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (39, 'measurement_params', '{"idx": 1, "form_id": 16, "test_id": 123, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 1, "value": 10.02, "form_id": 16, "test_id": 123, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.564954+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (40, 'measurement_params', '{"idx": 2, "form_id": 16, "test_id": 123, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 2, "value": 0, "form_id": 16, "test_id": 123, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.567163+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (41, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 124, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 10.02, "form_id": 16, "test_id": 124, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.569357+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (42, 'measurement_params', '{"idx": 1, "form_id": 16, "test_id": 124, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 1, "value": 20, "form_id": 16, "test_id": 124, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.571507+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (43, 'measurement_params', '{"idx": 2, "form_id": 16, "test_id": 124, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 2, "value": 10, "form_id": 16, "test_id": 124, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.573648+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (44, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 125, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 10.02, "form_id": 16, "test_id": 125, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.576117+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (45, 'measurement_params', '{"idx": 1, "form_id": 16, "test_id": 125, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 1, "value": 9.98, "form_id": 16, "test_id": 125, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.578431+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (46, 'measurement_params', '{"idx": 2, "form_id": 16, "test_id": 125, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 2, "value": 10, "form_id": 16, "test_id": 125, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.580721+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (47, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 126, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 0.0416734, "form_id": 16, "test_id": 126, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.583083+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (48, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 127, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 0.250040, "form_id": 16, "test_id": 127, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.585465+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (49, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 128, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 0.0638, "form_id": 16, "test_id": 128, "measurement_id": 60, "condition_value": 1}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.587763+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (50, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 129, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 0.02, "form_id": 16, "test_id": 129, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.589966+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (51, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 130, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 3, "form_id": 16, "test_id": 130, "measurement_id": 60, "condition_value": 1}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.592316+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (52, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 131, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 0.200, "form_id": 16, "test_id": 131, "measurement_id": 60, "condition_value": 1}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.59449+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (53, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 132, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 10.00, "form_id": 16, "test_id": 132, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.596696+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (54, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 133, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 0.041700, "form_id": 16, "test_id": 133, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.599094+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (55, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 135, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 0.0417, "form_id": 16, "test_id": 135, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.601341+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (56, 'measurement_params', '{"idx": 0, "form_id": 16, "test_id": 136, "measurement_id": 60}', 'INSERT', NULL, '{"idx": 0, "value": 0.2500, "form_id": 16, "test_id": 136, "measurement_id": 60, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:35:49.603563+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (57, 'measurements', '{"id": 60}', 'UPDATE', '{"id": 60, "form_id": 16, "comments": null, "date_update": "2026-09-16T22:35:49.416688+03:00", "is_readonly": false, "is_reported": false, "date_created": "2026-09-16T22:35:49.343915+03:00", "reception_id": 29, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": null, "use_default_equipment": true}', '{"id": 60, "form_id": 16, "comments": null, "date_update": "2026-09-16T22:35:49.416688+03:00", "is_readonly": false, "is_reported": true, "date_created": "2026-09-16T22:35:49.343915+03:00", "reception_id": 29, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": 1, "use_default_equipment": true}', '{is_reported,user_reported_id}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:37:21.383042+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (58, 'measurements', '{"id": 60}', 'UPDATE', '{"id": 60, "form_id": 16, "comments": null, "date_update": "2026-09-16T22:35:49.416688+03:00", "is_readonly": false, "is_reported": true, "date_created": "2026-09-16T22:35:49.343915+03:00", "reception_id": 29, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": 1, "use_default_equipment": true}', '{"id": 60, "form_id": 16, "comments": null, "date_update": "2026-09-16T22:35:49.416688+03:00", "is_readonly": true, "is_reported": true, "date_created": "2026-09-16T22:35:49.343915+03:00", "reception_id": 29, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": 1, "use_default_equipment": true}', '{is_readonly}', 1, 'Operation performed via QCLab system API', '2026-09-16 22:47:00.233964+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (59, 'measurements', '{"id": 61}', 'INSERT', NULL, '{"id": 61, "form_id": 17, "comments": null, "date_update": "2026-09-17T15:38:02.687853+03:00", "is_readonly": false, "is_reported": false, "date_created": "2026-09-17T15:38:02.726919+03:00", "reception_id": 30, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": null, "use_default_equipment": true}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-17 15:38:02.784382+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (60, 'measurements', '{"id": 61}', 'UPDATE', '{"id": 61, "form_id": 17, "comments": null, "date_update": "2026-09-17T15:38:02.687853+03:00", "is_readonly": false, "is_reported": false, "date_created": "2026-09-17T15:38:02.726919+03:00", "reception_id": 30, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": null, "use_default_equipment": true}', '{"id": 61, "form_id": 17, "comments": null, "date_update": "2026-09-17T15:38:02.838647+03:00", "is_readonly": false, "is_reported": false, "date_created": "2026-09-17T15:38:02.726919+03:00", "reception_id": 30, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": null, "use_default_equipment": true}', '{date_update}', 1, 'Operation performed via QCLab system API', '2026-09-17 15:38:02.868316+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (61, 'measurement_params', '{"idx": 0, "form_id": 17, "test_id": 102, "measurement_id": 61}', 'INSERT', NULL, '{"idx": 0, "value": 21.5, "form_id": 17, "test_id": 102, "measurement_id": 61, "condition_value": 1}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-17 15:38:03.152052+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (62, 'measurement_params', '{"idx": 0, "form_id": 17, "test_id": 103, "measurement_id": 61}', 'INSERT', NULL, '{"idx": 0, "value": 52, "form_id": 17, "test_id": 103, "measurement_id": 61, "condition_value": 1}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-17 15:38:03.157461+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (63, 'measurement_params', '{"idx": 0, "form_id": 17, "test_id": 104, "measurement_id": 61}', 'INSERT', NULL, '{"idx": 0, "value": 0.51, "form_id": 17, "test_id": 104, "measurement_id": 61, "condition_value": 1}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-17 15:38:03.163147+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (64, 'measurement_params', '{"idx": 0, "form_id": 17, "test_id": 105, "measurement_id": 61}', 'INSERT', NULL, '{"idx": 0, "value": 96.2, "form_id": 17, "test_id": 105, "measurement_id": 61, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-17 15:38:03.169304+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (65, 'measurement_params', '{"idx": 0, "form_id": 17, "test_id": 137, "measurement_id": 61}', 'INSERT', NULL, '{"idx": 0, "value": 10, "form_id": 17, "test_id": 137, "measurement_id": 61, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-17 15:38:03.175576+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (66, 'measurement_params', '{"idx": 0, "form_id": 17, "test_id": 138, "measurement_id": 61}', 'INSERT', NULL, '{"idx": 0, "value": 14.85, "form_id": 17, "test_id": 138, "measurement_id": 61, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-17 15:38:03.182193+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (67, 'measurement_params', '{"idx": 0, "form_id": 17, "test_id": 139, "measurement_id": 61}', 'INSERT', NULL, '{"idx": 0, "value": 13.65, "form_id": 17, "test_id": 139, "measurement_id": 61, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-17 15:38:03.184386+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (68, 'measurement_params', '{"idx": 0, "form_id": 17, "test_id": 140, "measurement_id": 61}', 'INSERT', NULL, '{"idx": 0, "value": 8.6, "form_id": 17, "test_id": 140, "measurement_id": 61, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-17 15:38:03.186595+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (69, 'measurement_params', '{"idx": 0, "form_id": 17, "test_id": 141, "measurement_id": 61}', 'INSERT', NULL, '{"idx": 0, "value": 0.1002, "form_id": 17, "test_id": 141, "measurement_id": 61, "condition_value": null}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-17 15:38:03.188922+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (70, 'measurement_params', '{"idx": 0, "form_id": 17, "test_id": 143, "measurement_id": 61}', 'INSERT', NULL, '{"idx": 0, "value": 100.200000, "form_id": 17, "test_id": 143, "measurement_id": 61, "condition_value": 1}', '{}', 1, 'Operation performed via QCLab system API', '2026-09-17 15:38:03.191026+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (71, 'measurements', '{"id": 61}', 'UPDATE', '{"id": 61, "form_id": 17, "comments": null, "date_update": "2026-09-17T15:38:02.838647+03:00", "is_readonly": false, "is_reported": false, "date_created": "2026-09-17T15:38:02.726919+03:00", "reception_id": 30, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": null, "use_default_equipment": true}', '{"id": 61, "form_id": 17, "comments": null, "date_update": "2026-09-17T15:38:02.838647+03:00", "is_readonly": false, "is_reported": true, "date_created": "2026-09-17T15:38:02.726919+03:00", "reception_id": 30, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": 1, "use_default_equipment": true}', '{is_reported,user_reported_id}', 1, 'Operation performed via QCLab system API', '2026-09-17 15:42:25.30787+03', '::1');
INSERT INTO public.audit_logs OVERRIDING SYSTEM VALUE VALUES (72, 'measurements', '{"id": 61}', 'UPDATE', '{"id": 61, "form_id": 17, "comments": null, "date_update": "2026-09-17T15:38:02.838647+03:00", "is_readonly": false, "is_reported": true, "date_created": "2026-09-17T15:38:02.726919+03:00", "reception_id": 30, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": 1, "use_default_equipment": true}', '{"id": 61, "form_id": 17, "comments": null, "date_update": "2026-09-17T15:38:02.838647+03:00", "is_readonly": true, "is_reported": true, "date_created": "2026-09-17T15:38:02.726919+03:00", "reception_id": 30, "date_readonly": null, "date_reported": null, "user_update_id": 1, "user_created_id": 1, "user_reported_id": 1, "use_default_equipment": true}', '{is_readonly}', 1, 'Operation performed via QCLab system API', '2026-09-17 15:44:36.797712+03', '::1');


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.categories OVERRIDING SYSTEM VALUE VALUES (1, 'Category A', 'CA', 'Description for Category A', '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.categories OVERRIDING SYSTEM VALUE VALUES (2, 'Category B', 'CB', 'Description for Category B', '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.categories OVERRIDING SYSTEM VALUE VALUES (3, 'Category C', 'CC', 'Description for Category C', '2026-01-23 22:46:06.788548+02', true, '2026-01-23 22:46:55.808578+02', 'Some explanations ...');
INSERT INTO public.categories OVERRIDING SYSTEM VALUE VALUES (4, 'Concrete', 'CT', 'Description of concrete category', '2026-07-06 15:15:53.81626+03', false, NULL, NULL);
INSERT INTO public.categories OVERRIDING SYSTEM VALUE VALUES (5, 'Wastewater Effluent', 'WE', 'Occaecati iusto explicabo excepturi beatae quibusdam', '2026-07-07 20:17:49.175189+03', false, NULL, NULL);
INSERT INTO public.categories OVERRIDING SYSTEM VALUE VALUES (6, 'Citric Acid Anhydrous', 'CAA', 'Officia dignissimos tempora commodi', '2026-07-11 18:43:20.158588+03', false, NULL, NULL);
INSERT INTO public.categories OVERRIDING SYSTEM VALUE VALUES (7, 'Pavement Cors', 'PC', 'Commodi ratione vero dicta maxime', '2026-07-11 23:12:38.364789+03', false, NULL, NULL);


--
-- Data for Name: category_tests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.category_tests VALUES (2, 2);
INSERT INTO public.category_tests VALUES (2, 4);
INSERT INTO public.category_tests VALUES (1, 1);
INSERT INTO public.category_tests VALUES (1, 3);
INSERT INTO public.category_tests VALUES (1, 4);
INSERT INTO public.category_tests VALUES (3, 1);
INSERT INTO public.category_tests VALUES (3, 2);
INSERT INTO public.category_tests VALUES (3, 5);
INSERT INTO public.category_tests VALUES (3, 28);
INSERT INTO public.category_tests VALUES (3, 37);
INSERT INTO public.category_tests VALUES (3, 45);
INSERT INTO public.category_tests VALUES (4, 51);
INSERT INTO public.category_tests VALUES (4, 52);
INSERT INTO public.category_tests VALUES (5, 55);
INSERT INTO public.category_tests VALUES (5, 56);
INSERT INTO public.category_tests VALUES (5, 57);
INSERT INTO public.category_tests VALUES (6, 62);
INSERT INTO public.category_tests VALUES (6, 63);
INSERT INTO public.category_tests VALUES (6, 64);
INSERT INTO public.category_tests VALUES (6, 65);
INSERT INTO public.category_tests VALUES (7, 66);
INSERT INTO public.category_tests VALUES (7, 72);
INSERT INTO public.category_tests VALUES (7, 73);
INSERT INTO public.category_tests VALUES (7, 74);
INSERT INTO public.category_tests VALUES (7, 75);
INSERT INTO public.category_tests VALUES (7, 76);
INSERT INTO public.category_tests VALUES (5, 102);
INSERT INTO public.category_tests VALUES (5, 103);
INSERT INTO public.category_tests VALUES (5, 104);
INSERT INTO public.category_tests VALUES (5, 105);
INSERT INTO public.category_tests VALUES (5, 143);


--
-- Data for Name: certificate_tests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.certificate_tests VALUES (6, 25, 39, 3, 0, 150, NULL, NULL, true, true, '> 100', 1);
INSERT INTO public.certificate_tests VALUES (6, 25, 39, 4, 0, 600.5, NULL, NULL, true, true, '< 1000', 1);
INSERT INTO public.certificate_tests VALUES (6, 25, 46, 3, 0, 454.34, NULL, NULL, true, true, '> 100', 1);
INSERT INTO public.certificate_tests VALUES (6, 25, 46, 28, 0, 175.5, NULL, NULL, true, true, '<= 50 or > 100', 1);
INSERT INTO public.certificate_tests VALUES (6, 25, 46, 37, 0, 111, NULL, NULL, true, true, '> 100 and <= 500', 1);
INSERT INTO public.certificate_tests VALUES (6, 25, 46, 37, 1, 333, NULL, NULL, true, true, '> 100 and <= 500', 1);
INSERT INTO public.certificate_tests VALUES (6, 25, 46, 37, 2, 444, NULL, NULL, true, true, '> 100 and <= 500', 1);
INSERT INTO public.certificate_tests VALUES (6, 25, 46, 38, 0, 3, NULL, NULL, true, true, '''Item KB'' or ''Item KC''', 1);
INSERT INTO public.certificate_tests VALUES (7, 26, 47, 28, 0, 252.4, NULL, NULL, true, true, '<= 50 or > 100', 1);
INSERT INTO public.certificate_tests VALUES (7, 26, 47, 37, 0, 222, NULL, NULL, true, true, '> 100 and <= 500', 1);
INSERT INTO public.certificate_tests VALUES (7, 26, 47, 37, 1, 333, NULL, NULL, true, true, '> 100 and <= 500', 1);
INSERT INTO public.certificate_tests VALUES (7, 26, 47, 38, 0, 3, NULL, NULL, true, true, '''Item KB'' or ''Item KC''', 1);
INSERT INTO public.certificate_tests VALUES (7, 25, 39, 3, 0, 150, NULL, NULL, true, true, '> 100', 2);
INSERT INTO public.certificate_tests VALUES (7, 25, 39, 4, 0, 600.5, NULL, NULL, true, true, '< 1000', 2);
INSERT INTO public.certificate_tests VALUES (7, 25, 46, 3, 0, 454.34, NULL, NULL, true, true, '> 100', 2);
INSERT INTO public.certificate_tests VALUES (8, 25, 39, 4, 0, 600.5, NULL, NULL, true, true, '< 1000', 3);
INSERT INTO public.certificate_tests VALUES (8, 28, 48, 28, 0, 192.6, NULL, NULL, true, true, '<= 50 or > 100', 1);
INSERT INTO public.certificate_tests VALUES (8, 28, 48, 37, 0, 333, NULL, NULL, true, true, '> 100 and <= 500', 1);
INSERT INTO public.certificate_tests VALUES (8, 28, 48, 37, 1, 444, NULL, NULL, true, true, '> 100 and <= 500', 1);
INSERT INTO public.certificate_tests VALUES (8, 28, 48, 38, 0, 2, NULL, NULL, true, true, '''Item KB'' or ''Item KC''', 1);
INSERT INTO public.certificate_tests VALUES (8, 28, 49, 3, 0, 862.4, NULL, NULL, true, true, '> 100', 1);
INSERT INTO public.certificate_tests VALUES (9, 29, 54, 51, 0, 44.4, NULL, NULL, true, true, '>= 40', 1);
INSERT INTO public.certificate_tests VALUES (9, 29, 54, 52, 0, 2, NULL, NULL, true, true, '>= 1.75 and <= 2.10', 1);
INSERT INTO public.certificate_tests VALUES (10, 30, 55, 55, 0, 25, NULL, NULL, true, true, '<= 30', 1);
INSERT INTO public.certificate_tests VALUES (10, 30, 55, 56, 0, 3.27, NULL, NULL, true, true, '<= 5', 1);
INSERT INTO public.certificate_tests VALUES (10, 30, 55, 57, 0, 4, NULL, NULL, true, true, '>= 3 and <= 20', 1);
INSERT INTO public.certificate_tests VALUES (11, 31, 56, 62, 0, 0.4, NULL, NULL, true, true, '<= 0.50', 1);
INSERT INTO public.certificate_tests VALUES (11, 31, 56, 62, 1, 0.38, NULL, NULL, true, true, '<= 0.50', 1);
INSERT INTO public.certificate_tests VALUES (11, 31, 56, 62, 2, 0.42, NULL, NULL, true, true, '<= 0.50', 1);
INSERT INTO public.certificate_tests VALUES (11, 31, 56, 62, 3, 0.44, NULL, NULL, true, true, '<= 0.50', 1);
INSERT INTO public.certificate_tests VALUES (11, 31, 56, 62, 4, 0.36, NULL, NULL, true, true, '<= 0.50', 1);
INSERT INTO public.certificate_tests VALUES (11, 31, 56, 63, 0, 0.4, NULL, NULL, true, true, '<= 0.50', 1);
INSERT INTO public.certificate_tests VALUES (11, 31, 56, 64, 0, 0.032, NULL, NULL, true, true, '<= 0.050', 1);
INSERT INTO public.certificate_tests VALUES (11, 31, 56, 65, 0, 5, NULL, NULL, true, true, '>= 3 and <= 5', 1);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 66, 0, 52.1, NULL, NULL, true, true, '>= 45.0', 1);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 66, 1, 49.5, NULL, NULL, true, true, '>= 45.0', 1);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 66, 2, 50.8, NULL, NULL, true, true, '>= 45.0', 1);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 66, 3, 51.6, NULL, NULL, true, true, '>= 45.0', 1);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 72, 0, 51.0, NULL, NULL, true, true, '>= 50.0', 1);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 73, 0, 2.312, NULL, NULL, true, true, '>= 0', 1);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 73, 1, 2.298, NULL, NULL, true, true, '>= 0', 1);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 73, 2, 2.325, NULL, NULL, true, true, '>= 0', 1);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 73, 3, 2.305, NULL, NULL, true, true, '>= 0', 1);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 74, 0, 0.47, NULL, NULL, true, true, '<= 1.30', 1);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 75, 0, 4, NULL, NULL, true, true, '>= 3', 1);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 76, 0, 93.9, NULL, NULL, true, true, '>= 92.0 and <= 97.0', 1);
INSERT INTO public.certificate_tests VALUES (13, 33, 58, 78, 0, 5015, NULL, NULL, true, true, '>= 5000.0', 1);
INSERT INTO public.certificate_tests VALUES (13, 33, 58, 91, 0, 100, NULL, NULL, true, true, '== 100', 1);
INSERT INTO public.certificate_tests VALUES (13, 33, 58, 92, 0, 95, NULL, NULL, true, true, '>= 90 and <= 100', 1);
INSERT INTO public.certificate_tests VALUES (13, 33, 58, 93, 0, 60, NULL, NULL, true, true, '>= 40 and <= 65', 1);
INSERT INTO public.certificate_tests VALUES (13, 33, 58, 94, 0, 30, NULL, NULL, true, true, '>= 15 and <= 35', 1);
INSERT INTO public.certificate_tests VALUES (13, 33, 58, 95, 0, 10.1, NULL, NULL, true, true, '>= 2.0 and <= 12.0', 1);
INSERT INTO public.certificate_tests VALUES (13, 33, 58, 96, 0, 0.10, NULL, NULL, true, true, '<= 0.30', 1);
INSERT INTO public.certificate_tests VALUES (14, 34, 59, 112, 0, 0.099703, NULL, NULL, true, true, '>= 0.0950 and <= 0.1050', 1);
INSERT INTO public.certificate_tests VALUES (15, 35, 60, 135, 0, 0.0417, NULL, NULL, true, true, '>= 0.04117 and <= 0.04217', 1);
INSERT INTO public.certificate_tests VALUES (16, 36, 61, 105, 0, 96.2, NULL, NULL, true, true, '<= 125.0', 1);


--
-- Data for Name: certificates; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (6, 34, 11, true, true, true, 1, '2025-12-13 18:17:42.218999+02', 'All testing results are according to specification
All mandatory tests have been performed', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (7, 35, 11, true, true, true, 1, '2025-12-13 18:17:42.218999+02', 'All testing results are according to specification
All mandatory tests have been performed', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (8, 63, 11, true, true, false, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (11, 74, 20, true, true, true, 1, '2026-07-10 02:01:33.83174+03', 'All testing results are according to specification
------------
Officia dignissimos tempora commodi est sunt saepe veniam recusandae ex fuga id', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (9, 72, 18, true, true, true, 1, '2026-07-07 20:05:58.791421+03', 'All testing results are according to specification
------------
Veritatis itaque quis soluta labore tenetur', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (10, 73, 19, true, true, true, 1, '2026-07-07 20:07:20.403415+03', 'All testing results are according to specification
------------
Commodi ratione vero dicta maxime', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (12, 75, 21, true, true, true, 1, '2026-07-11 23:07:07.87595+03', 'All testing results are according to specification
------------
Veritatis itaque quis soluta labore tenetur', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (13, 76, 22, true, true, true, 1, '2026-07-17 22:01:52.032873+03', 'All testing results are according to specification
------------
Commodi ratione vero dicta maxime', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (14, 127, 23, true, true, true, 1, '2026-09-15 21:29:01.581003+03', 'Consequuntur iusto optio impedit iusto nihil quia', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (15, 102, 24, true, true, true, 1, '2026-09-16 22:47:00.687117+03', 'Occaecati iusto explicabo excepturi beatae quibusdam', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (16, 143, 25, true, true, true, 1, '2026-09-17 15:44:37.189251+03', 'Sunt saepe veniam recusandae ex fuga id', NULL, false, NULL, NULL, NULL);


--
-- Data for Name: control_codes; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (1, 15, 'BATCH-REC-1-1', false, '2026-09-08 17:42:18.762014+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (2, 15, 'SN-REC-1-2', false, '2026-09-08 17:42:18.762861+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (3, 18, 'BATCH-REC-1-3', false, '2026-09-08 17:42:18.762865+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (4, 15, 'SN-REC-1-4', false, '2026-09-08 17:42:18.762866+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (5, 20, 'BATCH-REC-1-5', false, '2026-09-08 17:42:18.762868+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (6, 1, 'SN-REC-2-1', false, '2026-09-08 17:42:18.762869+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (7, 15, 'SN-REC-2-2', false, '2026-09-08 17:42:18.76287+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (8, 15, 'SN-REC-2-3', false, '2026-09-08 17:42:18.762871+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (9, 20, 'SN-REC-2-4', false, '2026-09-08 17:42:18.762873+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (10, 17, 'DEL-CODE-3-1', false, '2026-09-08 17:42:18.762874+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (11, 17, 'DEL-CODE-3-2', false, '2026-09-08 17:42:18.762875+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (12, 21, 'DEL-CODE-4-1', false, '2026-09-08 17:42:18.762876+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (13, 17, 'DEL-CODE-4-2', false, '2026-09-08 17:42:18.762877+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (14, 19, 'DEL-CODE-4-3', false, '2026-09-08 17:42:18.762881+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (15, 1, 'STORAGE-CODE-5-1', false, '2026-09-08 17:42:18.762882+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (16, 18, 'STORAGE-CODE-5-2', false, '2026-09-08 17:42:18.762884+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (17, 20, 'STORAGE-CODE-5-3', false, '2026-09-08 17:42:18.762885+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (18, 18, 'STORAGE-CODE-6-1', false, '2026-09-08 17:42:18.762887+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (19, 18, 'STORAGE-CODE-6-2', false, '2026-09-08 17:42:18.762888+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (20, 18, 'OWNERSHIP-CODE-7-1', false, '2026-09-08 17:42:18.762889+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (21, 8, 'OWNERSHIP-CODE-7-2', false, '2026-09-08 17:42:18.76289+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (22, 15, 'OWNERSHIP-CODE-7-3', false, '2026-09-08 17:42:18.762892+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (23, 18, 'OWNERSHIP-CODE-8-1', false, '2026-09-08 17:42:18.762893+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (24, 17, 'OWNERSHIP-CODE-8-2', false, '2026-09-08 17:42:18.762894+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (25, 17, 'OWNERSHIP-CODE-8-3', false, '2026-09-08 17:42:18.762896+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (26, 20, 'GEN-1-CODE-9-1', false, '2026-09-08 17:42:18.762897+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (27, 11, 'GEN-1-CODE-9-2', false, '2026-09-08 17:42:18.762899+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (28, 6, 'GEN-1-CODE-9-3', false, '2026-09-08 17:42:18.7629+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (29, 15, 'GEN-1-CODE-9-4', false, '2026-09-08 17:42:18.762901+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (30, 3, 'GEN-2-CODE-10-1', false, '2026-09-08 17:42:18.762902+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (31, 19, 'GEN-2-CODE-10-2', false, '2026-09-08 17:42:18.762904+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (32, 15, 'GEN-2-CODE-10-3', false, '2026-09-08 17:42:18.762905+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (33, 4, 'GEN-2-CODE-10-4', false, '2026-09-08 17:42:18.762906+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (34, 5, 'GEN-2-CODE-10-5', true, '2026-09-08 17:42:18.762908+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (35, 5, 'GEN-3-CODE-11-1', true, '2026-09-08 17:42:18.762909+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (36, 13, 'GEN-3-CODE-11-2', false, '2026-09-08 17:42:18.76291+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (37, 20, 'GEN-3-CODE-11-3', false, '2026-09-08 17:42:18.762911+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (38, 20, 'GEN-3-CODE-11-4', false, '2026-09-08 17:42:18.762913+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (39, 13, 'GEN-3-CODE-11-5', false, '2026-09-08 17:42:18.762914+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (40, 21, 'PROD-A-1-212858', false, '2026-09-08 17:42:18.762915+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (41, 1, 'GEN-1-2025-07-15', false, '2026-09-08 17:42:18.762916+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (42, 2, 'GEN-2-2025-07-15', false, '2026-09-08 17:42:18.762918+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (43, 3, 'GEN-3-2025-07-15', false, '2026-09-08 17:42:18.762919+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (44, 21, 'PROD-A-2-212858', false, '2026-09-08 17:42:18.76292+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (45, 1, 'GEN-1-2025-07-05', false, '2026-09-08 17:42:18.762921+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (46, 2, 'GEN-2-2025-07-05', false, '2026-09-08 17:42:18.762923+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (47, 21, 'PROD-A-3-212858', false, '2026-09-08 17:42:18.762924+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (48, 1, 'GEN-1-2025-06-25', false, '2026-09-08 17:42:18.762925+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (49, 2, 'GEN-2-2025-06-25', false, '2026-09-08 17:42:18.762927+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (50, 3, 'GEN-3-2025-06-25', false, '2026-09-08 17:42:18.762928+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (51, 21, 'PROD-A-4-212858', false, '2026-09-08 17:42:18.762929+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (52, 1, 'GEN-1-2025-06-15', false, '2026-09-08 17:42:18.76293+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (53, 2, 'GEN-2-2025-06-15', false, '2026-09-08 17:42:18.762932+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (54, 21, 'PROD-A-5-212858', false, '2026-09-08 17:42:18.762935+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (55, 1, 'GEN-1-2025-06-05', false, '2026-09-08 17:42:18.762937+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (56, 2, 'GEN-2-2025-06-05', false, '2026-09-08 17:42:18.762938+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (57, 3, 'GEN-3-2025-06-05', false, '2026-09-08 17:42:18.762939+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (58, 21, 'PROD-A-6-212858', false, '2026-09-08 17:42:18.76294+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (59, 1, 'GEN-1-2025-05-26', true, '2026-09-08 17:42:18.762941+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (60, 2, 'GEN-2-2025-05-26', true, '2026-09-08 17:42:18.762943+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (62, 4, 'GEN-4-2025-06-25', false, '2026-09-08 17:42:18.762944+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (63, 5, 'GEN-5-2025-06-25', true, '2026-09-08 17:42:18.762945+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (64, 3, 'GEN-3-2025-05-26', false, '2026-09-08 17:42:18.762947+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (65, 4, 'GEN-4-2025-05-26', false, '2026-09-08 17:42:18.762948+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (66, 3, 'GEN-3-2025-04-26', false, '2026-09-08 17:42:18.762949+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (67, 4, 'GEN-4-2025-04-26', false, '2026-09-08 17:42:18.76295+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (68, 5, 'GEN-5-2025-04-26', false, '2026-09-08 17:42:18.762951+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (69, 3, 'GEN-3-2025-03-27', true, '2026-09-08 17:42:18.762953+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (70, 4, 'GEN-4-2025-03-27', true, '2026-09-08 17:42:18.762954+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (71, 2, 'WERT-TER-ERT-ER', false, '2026-09-08 17:42:18.762955+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (72, 22, 'GEN-5-2026-07-06', true, '2026-09-08 17:42:18.762956+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (73, 23, 'GEN-5-2026-07-07', true, '2026-09-08 17:42:18.762957+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (74, 24, 'GEN-5-2026-07-08', true, '2026-09-08 17:42:18.762958+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (75, 25, 'LOT-04-BND-I95', true, '2026-09-08 17:42:18.76296+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (76, 26, 'LOT-04-BASE-01', true, '2026-09-08 17:42:18.762961+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (77, 27, 'CC-FAS01-001', true, '2026-09-08 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (78, 27, 'CC-FAS01-002', true, '2026-09-07 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (79, 27, 'CC-FAS01-003', true, '2026-09-06 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (80, 27, 'CC-FAS01-004', true, '2026-09-05 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (81, 27, 'CC-FAS01-005', true, '2026-09-04 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (82, 28, 'CC-PDC01-001', true, '2026-09-08 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (83, 28, 'CC-PDC01-002', true, '2026-09-07 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (84, 28, 'CC-PDC01-003', true, '2026-09-06 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (85, 28, 'CC-PDC01-004', true, '2026-09-05 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (86, 28, 'CC-PDC01-005', true, '2026-09-04 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (87, 29, 'CC-H2SO4-001', true, '2026-09-08 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (88, 29, 'CC-H2SO4-002', true, '2026-09-07 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (89, 29, 'CC-H2SO4-003', true, '2026-09-06 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (90, 29, 'CC-H2SO4-004', true, '2026-09-05 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (91, 29, 'CC-H2SO4-005', true, '2026-09-04 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (92, 30, 'CC-FER01-001', true, '2026-09-08 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (93, 30, 'CC-FER01-002', true, '2026-09-07 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (94, 30, 'CC-FER01-003', true, '2026-09-06 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (95, 30, 'CC-FER01-004', true, '2026-09-05 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (96, 30, 'CC-FER01-005', true, '2026-09-04 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (97, 31, 'CC-H2O01-001', true, '2026-09-08 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (98, 31, 'CC-H2O01-002', true, '2026-09-07 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (99, 31, 'CC-H2O01-003', true, '2026-09-06 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (100, 31, 'CC-H2O01-004', true, '2026-09-05 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (101, 31, 'CC-H2O01-005', true, '2026-09-04 12:41:39.363522+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (102, 32, 'RL-COD-COD01-001', true, '2026-09-09 16:35:09.356936+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (103, 32, 'RL-COD-COD01-002', true, '2026-09-09 16:35:09.36803+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (104, 32, 'RL-COD-COD01-003', true, '2026-09-09 16:35:09.368418+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (105, 32, 'RL-COD-COD01-004', true, '2026-09-09 16:35:09.3687+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (106, 32, 'RL-COD-COD01-005', true, '2026-09-09 16:35:09.368974+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (107, 33, 'RL-COD-COD02-001', true, '2026-09-09 16:35:09.369352+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (108, 33, 'RL-COD-COD02-002', true, '2026-09-09 16:35:09.369701+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (109, 33, 'RL-COD-COD02-003', true, '2026-09-09 16:35:09.369792+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (110, 33, 'RL-COD-COD02-004', true, '2026-09-09 16:35:09.369872+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (111, 33, 'RL-COD-COD02-005', true, '2026-09-09 16:35:09.369956+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (112, 34, 'RL-COD-COD04-001', true, '2026-09-09 16:35:09.37011+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (113, 34, 'RL-COD-COD04-002', true, '2026-09-09 16:35:09.370196+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (114, 34, 'RL-COD-COD04-003', true, '2026-09-09 16:35:09.370277+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (115, 34, 'RL-COD-COD04-004', true, '2026-09-09 16:35:09.371495+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (116, 34, 'RL-COD-COD04-005', true, '2026-09-09 16:35:09.3716+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (117, 35, 'RL-COD-COD05-001', true, '2026-09-09 16:35:09.371836+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (118, 35, 'RL-COD-COD05-002', true, '2026-09-09 16:35:09.371952+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (119, 35, 'RL-COD-COD05-003', true, '2026-09-09 16:35:09.372083+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (120, 35, 'RL-COD-COD05-004', true, '2026-09-09 16:35:09.372212+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (121, 35, 'RL-COD-COD05-005', true, '2026-09-09 16:35:09.372356+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (122, 36, 'RL-RAW-FAS-001', true, '2026-09-09 16:50:16.133322+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (123, 36, 'RL-RAW-FAS-002', true, '2026-09-09 16:50:16.149866+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (124, 36, 'RL-RAW-FAS-003', true, '2026-09-09 16:50:16.150412+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (125, 36, 'RL-RAW-FAS-004', true, '2026-09-09 16:50:16.150863+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (126, 36, 'RL-RAW-FAS-005', true, '2026-09-09 16:50:16.1513+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (127, 27, 'SOL-FAS-20260909-01', true, '2026-09-12 18:24:23.016849+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (128, 29, 'H2SO4-7741', true, '2026-09-15 20:29:23.901934+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (129, 29, 'H2SO4-7742', true, '2026-09-15 20:29:23.908804+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (130, 29, 'H2SO4-7743', true, '2026-09-15 20:29:23.909297+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (131, 29, 'H2SO4-7744', true, '2026-09-15 20:29:23.909697+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (132, 29, 'H2SO4-7745', true, '2026-09-15 20:29:23.910083+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (133, 38, 'HgSO4-3321', true, '2026-09-15 20:29:23.910545+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (134, 38, 'HgSO4-3322', true, '2026-09-15 20:29:23.911073+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (135, 38, 'HgSO4-3323', true, '2026-09-15 20:29:23.911291+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (136, 38, 'HgSO4-3324', true, '2026-09-15 20:29:23.9115+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (137, 38, 'HgSO4-3325', true, '2026-09-15 20:29:23.911709+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (138, 39, 'UPW-20260915-01', true, '2026-09-15 20:29:23.91206+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (139, 39, 'UPW-20260914-01', true, '2026-09-15 20:29:23.912379+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (140, 39, 'UPW-20260913-01', true, '2026-09-15 20:29:23.912585+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (141, 39, 'UPW-20260912-01', true, '2026-09-15 20:29:23.912784+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (142, 39, 'UPW-20260911-01', true, '2026-09-15 20:29:23.913002+03');
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (143, 40, 'WW-EFF-2026-0907-01', true, '2026-09-17 15:36:20.873312+03');


--
-- Data for Name: electronic_signatures; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: equipment_calibration_statuses; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.equipment_calibration_statuses VALUES (1, 'Pass');
INSERT INTO public.equipment_calibration_statuses VALUES (2, 'Fail');
INSERT INTO public.equipment_calibration_statuses VALUES (3, 'Limited Use');


--
-- Data for Name: equipment_calibrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (1, 1, '2023-07-01', '2024-07-01', 'CERT-CM-2023-01', 'Instron Calibration Services', 1, 'Class Load Cell #LC-500 (Cert #CAL-8820)', 0.15, '2026-08-24 15:37:15.245797+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (2, 1, '2024-07-02', '2025-07-02', 'CERT-CM-2024-01', 'Instron Calibration Services', 1, 'Class Load Cell #LC-500 (Cert #CAL-9104)', 0.14, '2026-08-24 15:37:15.246661+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (3, 1, '2025-07-03', '2026-07-03', 'CERT-CM-2025-01', 'Instron Calibration Services', 1, 'Class Load Cell #LC-500 (Cert #CAL-9541)', 0.12, '2026-08-24 15:37:15.24668+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (4, 1, '2026-07-01', '2027-07-01', 'CERT-CM-2026-01', 'Instron Calibration Services', 1, 'Class Load Cell #LC-500 (Cert #CAL-9980)', 0.12, '2026-08-24 15:37:15.246689+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (5, 2, '2023-07-10', '2024-07-10', 'CERT-OV-2023-A', 'Thermal Tech Metrology', 1, 'Calibrated Thermocouple Array #TC-04 (Cert #T-1021)', 0.40, '2026-08-24 15:37:15.24722+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (6, 2, '2024-07-10', '2025-07-10', 'CERT-OV-2024-A', 'Thermal Tech Metrology', 1, 'Calibrated Thermocouple Array #TC-04 (Cert #T-1402)', 0.35, '2026-08-24 15:37:15.24723+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (7, 2, '2025-07-08', '2026-07-08', 'CERT-OV-2025-A', 'Thermal Tech Metrology', 1, 'Calibrated Thermocouple Array #TC-04 (Cert #T-1899)', 0.30, '2026-08-24 15:37:15.247237+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (8, 2, '2026-07-08', '2027-07-08', 'CERT-OV-2026-A', 'Thermal Tech Metrology', 1, 'Calibrated Thermocouple Array #TC-04 (Cert #T-2201)', 0.30, '2026-08-24 15:37:15.247242+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (9, 3, '2023-07-12', '2024-07-12', 'CERT-SHK-2023-01', 'Precision Mechanical Metrology', 1, 'Digital Tachometer & Timer Standard #ST-01', 0.05, '2026-08-24 15:37:15.247493+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (10, 3, '2024-07-12', '2025-07-12', 'CERT-SHK-2024-01', 'Precision Mechanical Metrology', 1, 'Digital Tachometer & Timer Standard #ST-01', 0.05, '2026-08-24 15:37:15.247503+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (11, 3, '2025-07-11', '2026-07-11', 'CERT-SHK-2025-01', 'Precision Mechanical Metrology', 1, 'Digital Tachometer & Timer Standard #ST-01', 0.04, '2026-08-24 15:37:15.24751+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (12, 3, '2026-07-10', '2027-07-10', 'CERT-SHK-2026-01', 'Precision Mechanical Metrology', 1, 'Digital Tachometer & Timer Standard #ST-01', 0.04, '2026-08-24 15:37:15.247516+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (13, 4, '2024-12-10', '2025-06-08', 'CERT-BAL1-2024-2', 'Accredited Weights & Measures', 1, 'Class E2 Mass Standard Set (Cert #W-8812)', 0.00015, '2026-08-24 15:37:15.24773+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (14, 4, '2025-06-08', '2025-12-05', 'CERT-BAL1-2025-1', 'Accredited Weights & Measures', 1, 'Class E2 Mass Standard Set (Cert #W-9102)', 0.00012, '2026-08-24 15:37:15.247738+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (15, 4, '2025-12-05', '2026-06-03', 'CERT-BAL1-2025-2', 'Accredited Weights & Measures', 1, 'Class E2 Mass Standard Set (Cert #W-9400)', 0.00010, '2026-08-24 15:37:15.247744+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (16, 4, '2026-06-02', '2026-11-29', 'CERT-BAL1-2026-1', 'Accredited Weights & Measures', 1, 'Class E2 Mass Standard Set (Cert #W-9811)', 0.00010, '2026-08-24 15:37:15.247752+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (17, 5, '2024-12-15', '2025-06-13', 'CERT-BAL2-2024-2', 'Accredited Weights & Measures', 1, 'Class F Heavy Mass Set (Cert #HW-2021)', 0.08, '2026-08-24 15:37:15.247941+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (18, 5, '2025-06-12', '2025-12-09', 'CERT-BAL2-2025-1', 'Accredited Weights & Measures', 1, 'Class F Heavy Mass Set (Cert #HW-2401)', 0.08, '2026-08-24 15:37:15.24795+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (19, 5, '2025-12-08', '2026-06-06', 'CERT-BAL2-2025-2', 'Accredited Weights & Measures', 1, 'Class F Heavy Mass Set (Cert #HW-2810)', 0.05, '2026-08-24 15:37:15.247957+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (20, 5, '2026-06-05', '2026-12-02', 'CERT-BAL2-2026-1', 'Accredited Weights & Measures', 1, 'Class F Heavy Mass Set (Cert #HW-3102)', 0.05, '2026-08-24 15:37:15.247963+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (21, 6, '2023-07-05', '2024-07-05', 'CERT-OV101-2023', 'Thermal Tech Metrology', 1, 'NIST Traceable Calibrated Thermocouple Array #TC-02 (Cert #T-8810)', 0.25, '2026-08-25 20:50:39.640105+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (22, 6, '2024-07-05', '2025-07-05', 'CERT-OV101-2024', 'Thermal Tech Metrology', 1, 'NIST Traceable Calibrated Thermocouple Array #TC-02 (Cert #T-9201)', 0.25, '2026-08-25 20:50:39.641318+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (23, 6, '2025-07-05', '2026-07-05', 'CERT-OV101-2025', 'Thermal Tech Metrology', 1, 'NIST Traceable Calibrated Thermocouple Array #TC-02 (Cert #T-9650)', 0.20, '2026-08-25 20:50:39.641334+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (24, 6, '2026-07-05', '2027-07-05', 'CERT-OV101-2026', 'Thermal Tech Metrology', 1, 'NIST Traceable Calibrated Thermocouple Array #TC-02 (Cert #T-10042)', 0.20, '2026-08-25 20:50:39.641342+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (124, 28, '2025-09-15', '2026-09-15', 'Internal QC-2025-01', 'Internal Quality Control', 1, 'Silica Gel Indicator Inspection', NULL, '2026-09-15 19:57:03.786404+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (125, 28, '2026-09-15', '2027-09-15', 'Internal QC-001', 'Internal Quality Control', 1, 'Silica Gel Indicator Inspection', NULL, '2026-09-15 19:57:03.786408+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (25, 7, '2023-07-01', '2024-07-01', 'CERT-CAL-2023-01', 'Precision Metrology Inc.', 1, 'Metric Gauge Block Set Class 0 (Cert #GB-1029)', 0.02, '2026-08-25 21:18:24.147114+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (26, 7, '2024-07-01', '2025-07-01', 'CERT-CAL-2024-01', 'Precision Metrology Inc.', 1, 'Metric Gauge Block Set Class 0 (Cert #GB-1410)', 0.02, '2026-08-25 21:18:24.147673+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (27, 7, '2025-07-01', '2026-07-01', 'CERT-CAL-2025-01', 'Precision Metrology Inc.', 1, 'Metric Gauge Block Set Class 0 (Cert #GB-1892)', 0.01, '2026-08-25 21:18:24.147684+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (28, 7, '2026-07-01', '2027-07-01', 'CERT-CAL-2026-01', 'Precision Metrology Inc.', 1, 'Metric Gauge Block Set Class 0 (Cert #GB-2204)', 0.01, '2026-08-25 21:18:24.147693+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (29, 8, '2023-07-02', '2024-07-02', 'CERT-WB-2023-01', 'Thermal Tech Metrology', 1, 'NIST Traceable Temperature Standard Probe #PR-09', 0.10, '2026-08-25 21:18:24.148377+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (30, 8, '2024-07-02', '2025-07-02', 'CERT-WB-2024-01', 'Thermal Tech Metrology', 1, 'NIST Traceable Temperature Standard Probe #PR-09', 0.10, '2026-08-25 21:18:24.148395+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (31, 8, '2025-07-02', '2026-07-02', 'CERT-WB-2025-01', 'Thermal Tech Metrology', 1, 'NIST Traceable Temperature Standard Probe #PR-09', 0.08, '2026-08-25 21:18:24.148409+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (32, 8, '2026-07-02', '2027-07-02', 'CERT-WB-2026-01', 'Thermal Tech Metrology', 1, 'NIST Traceable Temperature Standard Probe #PR-09', 0.08, '2026-08-25 21:18:24.148421+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (33, 9, '2023-06-15', '2024-06-15', 'CERT-TH-2023-01', 'Primary Metrology Standards Lab', 1, 'Standard Platinum Resistance Thermometer (SPRT #112)', 0.02, '2026-08-25 21:18:24.148716+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (34, 9, '2024-06-15', '2025-06-15', 'CERT-TH-2024-01', 'Primary Metrology Standards Lab', 1, 'Standard Platinum Resistance Thermometer (SPRT #112)', 0.02, '2026-08-25 21:18:24.148727+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (35, 9, '2025-06-15', '2026-06-15', 'CERT-TH-2025-01', 'Primary Metrology Standards Lab', 1, 'Standard Platinum Resistance Thermometer (SPRT #112)', 0.01, '2026-08-25 21:18:24.148735+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (36, 9, '2026-06-15', '2027-06-15', 'CERT-TH-2026-01', 'Primary Metrology Standards Lab', 1, 'Standard Platinum Resistance Thermometer (SPRT #112)', 0.01, '2026-08-25 21:18:24.148742+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (37, 10, '2023-07-04', '2024-07-04', 'CERT-CAL2-2023', 'Precision Metrology Inc.', 1, 'Metric Gauge Block Set Class 0 (Cert #GB-1029)', 0.02, '2026-08-25 21:37:36.086478+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (38, 10, '2024-07-04', '2025-07-04', 'CERT-CAL2-2024', 'Precision Metrology Inc.', 1, 'Metric Gauge Block Set Class 0 (Cert #GB-1410)', 0.02, '2026-08-25 21:37:36.087247+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (39, 10, '2025-07-04', '2026-07-04', 'CERT-CAL2-2025', 'Precision Metrology Inc.', 1, 'Metric Gauge Block Set Class 0 (Cert #GB-1892)', 0.01, '2026-08-25 21:37:36.08726+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (40, 10, '2026-07-04', '2027-07-04', 'CERT-CAL2-2026', 'Precision Metrology Inc.', 1, 'Metric Gauge Block Set Class 0 (Cert #GB-2204)', 0.01, '2026-08-25 21:37:36.08727+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (41, 11, '2023-07-01', '2024-07-01', 'CERT-CTK2-2023', 'Thermal Tech Metrology', 1, 'NIST Traceable Reference Thermometer Probe #PR-04', 0.15, '2026-08-25 21:37:36.088068+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (42, 11, '2024-07-01', '2025-07-01', 'CERT-CTK2-2024', 'Thermal Tech Metrology', 1, 'NIST Traceable Reference Thermometer Probe #PR-04', 0.15, '2026-08-25 21:37:36.088093+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (43, 11, '2025-07-01', '2026-07-01', 'CERT-CTK2-2025', 'Thermal Tech Metrology', 1, 'NIST Traceable Reference Thermometer Probe #PR-04', 0.10, '2026-08-25 21:37:36.088107+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (44, 11, '2026-07-01', '2027-07-01', 'CERT-CTK2-2026', 'Thermal Tech Metrology', 1, 'NIST Traceable Reference Thermometer Probe #PR-04', 0.10, '2026-08-25 21:37:36.08812+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (45, 12, '2023-06-28', '2024-06-28', 'CERT-FEEL-2023', 'Quality Assurance Calibration LLC', 1, 'Optical Flat & Master Micrometer Set (Cert #MM-8012)', 0.005, '2026-08-25 21:37:36.088529+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (46, 12, '2024-06-28', '2025-06-28', 'CERT-FEEL-2024', 'Quality Assurance Calibration LLC', 1, 'Optical Flat & Master Micrometer Set (Cert #MM-8410)', 0.005, '2026-08-25 21:37:36.088551+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (47, 12, '2025-06-28', '2026-06-28', 'CERT-FEEL-2025', 'Quality Assurance Calibration LLC', 1, 'Optical Flat & Master Micrometer Set (Cert #MM-8901)', 0.003, '2026-08-25 21:37:36.088564+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (48, 12, '2026-06-28', '2027-06-28', 'CERT-FEEL-2026', 'Quality Assurance Calibration LLC', 1, 'Optical Flat & Master Micrometer Set (Cert #MM-9204)', 0.003, '2026-08-25 21:37:36.088582+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (49, 13, '2023-07-10', '2024-07-10', 'CERT-SEV-2023', 'Optical Metrology Services', 1, 'NIST-Traceable Automated Optical Comparator (Cert #OPT-4011)', 0.005, '2026-08-25 21:57:42.807021+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (50, 13, '2024-07-10', '2025-07-10', 'CERT-SEV-2024', 'Optical Metrology Services', 1, 'NIST-Traceable Automated Optical Comparator (Cert #OPT-4450)', 0.005, '2026-08-25 21:57:42.807792+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (51, 13, '2025-07-10', '2026-07-10', 'CERT-SEV-2025', 'Optical Metrology Services', 1, 'NIST-Traceable Automated Optical Comparator (Cert #OPT-4902)', 0.003, '2026-08-25 21:57:42.809092+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (52, 13, '2026-07-10', '2027-07-10', 'CERT-SEV-2026', 'Optical Metrology Services', 1, 'NIST-Traceable Automated Optical Comparator (Cert #OPT-5310)', 0.003, '2026-08-25 21:57:42.809111+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (53, 14, '2023-07-05', '2024-07-05', 'CERT-SPL-2023', 'Quality Assurance Calibration LLC', 1, 'Digital Caliper Standard #CAL-02 (Cert #GB-1029)', 0.05, '2026-08-25 21:57:42.809849+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (54, 14, '2024-07-05', '2025-07-05', 'CERT-SPL-2024', 'Quality Assurance Calibration LLC', 1, 'Digital Caliper Standard #CAL-02 (Cert #GB-1410)', 0.05, '2026-08-25 21:57:42.809865+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (55, 14, '2025-07-05', '2026-07-05', 'CERT-SPL-2025', 'Quality Assurance Calibration LLC', 1, 'Digital Caliper Standard #CAL-02 (Cert #GB-1892)', 0.03, '2026-08-25 21:57:42.809875+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (56, 14, '2026-07-05', '2027-07-05', 'CERT-SPL-2026', 'Quality Assurance Calibration LLC', 1, 'Digital Caliper Standard #CAL-02 (Cert #GB-2204)', 0.03, '2026-08-25 21:57:42.809884+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (57, 15, '2023-06-20', '2024-06-20', 'CERT-TMR-2023', 'Primary Metrology Standards Lab', 1, 'Atomic Frequency Standard Master Clock #CLK-01', 0.001, '2026-08-25 21:57:42.810186+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (58, 15, '2024-06-20', '2025-06-20', 'CERT-TMR-2024', 'Primary Metrology Standards Lab', 1, 'Atomic Frequency Standard Master Clock #CLK-01', 0.001, '2026-08-25 21:57:42.810198+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (59, 15, '2025-06-20', '2026-06-20', 'CERT-TMR-2025', 'Primary Metrology Standards Lab', 1, 'Atomic Frequency Standard Master Clock #CLK-01', 0.001, '2026-08-25 21:57:42.810207+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (60, 15, '2026-06-20', '2027-06-20', 'CERT-TMR-2026', 'Primary Metrology Standards Lab', 1, 'Atomic Frequency Standard Master Clock #CLK-01', 0.001, '2026-08-25 21:57:42.810218+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (61, 16, '2022-01-27', '2023-01-27', 'CAL-EQ-COD-01-2022-001', 'Internal Metrology Department', 1, 'Fluke Pt100 Reference Sensor (SN-FLK-1523-88)', 0.0015, '2022-01-27 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (62, 16, '2023-02-08', '2024-02-08', 'CAL-EQ-COD-01-2023-002', 'ISO/IEC 17025 Accredited Calib Lab Ltd', 1, 'Fluke Pt100 Reference Sensor (SN-FLK-1523-88)', 0.0020, '2023-02-08 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (63, 16, '2024-02-20', '2025-02-20', 'CAL-EQ-COD-01-2024-003', 'Internal Metrology Department', 1, 'Fluke Pt100 Reference Sensor (SN-FLK-1523-88)', 0.0025, '2024-02-20 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (64, 16, '2025-03-04', '2026-03-04', 'CAL-EQ-COD-01-2025-004', 'ISO/IEC 17025 Accredited Calib Lab Ltd', 1, 'Fluke Pt100 Reference Sensor (SN-FLK-1523-88)', 0.0030, '2025-03-04 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (65, 16, '2026-03-16', '2027-03-16', 'CAL-EQ-COD-01-2026-005', 'Internal Metrology Department', 1, 'Fluke Pt100 Reference Sensor (SN-FLK-1523-88)', 0.0035, '2026-03-16 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (66, 17, '2022-01-27', '2023-01-27', 'CAL-EQ-BUR-03-2022-001', 'Internal Metrology Department', 1, 'NIST Traceable Reference Standards Set #4', 0.0015, '2022-01-27 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (67, 17, '2023-02-08', '2024-02-08', 'CAL-EQ-BUR-03-2023-002', 'ISO/IEC 17025 Accredited Calib Lab Ltd', 1, 'NIST Traceable Reference Standards Set #4', 0.0020, '2023-02-08 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (68, 17, '2024-02-20', '2025-02-20', 'CAL-EQ-BUR-03-2024-003', 'Internal Metrology Department', 1, 'NIST Traceable Reference Standards Set #4', 0.0025, '2024-02-20 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (69, 17, '2025-03-04', '2026-03-04', 'CAL-EQ-BUR-03-2025-004', 'ISO/IEC 17025 Accredited Calib Lab Ltd', 1, 'NIST Traceable Reference Standards Set #4', 0.0030, '2025-03-04 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (70, 17, '2026-03-16', '2027-03-16', 'CAL-EQ-BUR-03-2026-005', 'Internal Metrology Department', 1, 'NIST Traceable Reference Standards Set #4', 0.0035, '2026-03-16 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (71, 18, '2022-01-27', '2023-01-27', 'CAL-EQ-BAL-02-2022-001', 'Internal Metrology Department', 1, 'Troemner E1 Class Mass Set (SN-TRM-E1-0042)', 0.0015, '2022-01-27 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (72, 18, '2023-02-08', '2024-02-08', 'CAL-EQ-BAL-02-2023-002', 'ISO/IEC 17025 Accredited Calib Lab Ltd', 1, 'Troemner E1 Class Mass Set (SN-TRM-E1-0042)', 0.0020, '2023-02-08 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (73, 18, '2024-02-20', '2025-02-20', 'CAL-EQ-BAL-02-2024-003', 'Internal Metrology Department', 1, 'Troemner E1 Class Mass Set (SN-TRM-E1-0042)', 0.0025, '2024-02-20 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (74, 18, '2025-03-04', '2026-03-04', 'CAL-EQ-BAL-02-2025-004', 'ISO/IEC 17025 Accredited Calib Lab Ltd', 1, 'Troemner E1 Class Mass Set (SN-TRM-E1-0042)', 0.0030, '2025-03-04 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (75, 18, '2026-03-16', '2027-03-16', 'CAL-EQ-BAL-02-2026-005', 'Internal Metrology Department', 1, 'Troemner E1 Class Mass Set (SN-TRM-E1-0042)', 0.0035, '2026-03-16 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (76, 19, '2022-01-27', '2023-01-27', 'CAL-EQ-ENV-01-2022-001', 'Internal Metrology Department', 1, 'Fluke Pt100 Reference Sensor (SN-FLK-1523-88)', 0.0015, '2022-01-27 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (77, 19, '2023-02-08', '2024-02-08', 'CAL-EQ-ENV-01-2023-002', 'ISO/IEC 17025 Accredited Calib Lab Ltd', 1, 'Fluke Pt100 Reference Sensor (SN-FLK-1523-88)', 0.0020, '2023-02-08 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (78, 19, '2024-02-20', '2025-02-20', 'CAL-EQ-ENV-01-2024-003', 'Internal Metrology Department', 1, 'Fluke Pt100 Reference Sensor (SN-FLK-1523-88)', 0.0025, '2024-02-20 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (79, 19, '2025-03-04', '2026-03-04', 'CAL-EQ-ENV-01-2025-004', 'ISO/IEC 17025 Accredited Calib Lab Ltd', 1, 'Fluke Pt100 Reference Sensor (SN-FLK-1523-88)', 0.0030, '2025-03-04 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (80, 19, '2026-03-16', '2027-03-16', 'CAL-EQ-ENV-01-2026-005', 'Internal Metrology Department', 1, 'Fluke Pt100 Reference Sensor (SN-FLK-1523-88)', 0.0035, '2026-03-16 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (81, 20, '2022-01-27', '2023-01-27', 'CAL-EQ-ENV-02-2022-001', 'Internal Metrology Department', 1, 'Fluke Pt100 Reference Sensor (SN-FLK-1523-88)', 0.0015, '2022-01-27 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (82, 20, '2023-02-08', '2024-02-08', 'CAL-EQ-ENV-02-2023-002', 'ISO/IEC 17025 Accredited Calib Lab Ltd', 1, 'Fluke Pt100 Reference Sensor (SN-FLK-1523-88)', 0.0020, '2023-02-08 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (83, 20, '2024-02-20', '2025-02-20', 'CAL-EQ-ENV-02-2024-003', 'Internal Metrology Department', 1, 'Fluke Pt100 Reference Sensor (SN-FLK-1523-88)', 0.0025, '2024-02-20 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (84, 20, '2025-03-04', '2026-03-04', 'CAL-EQ-ENV-02-2025-004', 'ISO/IEC 17025 Accredited Calib Lab Ltd', 1, 'Fluke Pt100 Reference Sensor (SN-FLK-1523-88)', 0.0030, '2025-03-04 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (85, 20, '2026-03-16', '2027-03-16', 'CAL-EQ-ENV-02-2026-005', 'Internal Metrology Department', 1, 'Fluke Pt100 Reference Sensor (SN-FLK-1523-88)', 0.0035, '2026-03-16 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (86, 21, '2022-01-27', '2023-01-27', 'CAL-EQ-THM-01-2022-001', 'Internal Metrology Department', 1, 'NIST Traceable Reference Standards Set #4', 0.0015, '2022-01-27 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (87, 21, '2023-02-08', '2024-02-08', 'CAL-EQ-THM-01-2023-002', 'ISO/IEC 17025 Accredited Calib Lab Ltd', 1, 'NIST Traceable Reference Standards Set #4', 0.0020, '2023-02-08 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (88, 21, '2024-02-20', '2025-02-20', 'CAL-EQ-THM-01-2024-003', 'Internal Metrology Department', 1, 'NIST Traceable Reference Standards Set #4', 0.0025, '2024-02-20 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (89, 21, '2025-03-04', '2026-03-04', 'CAL-EQ-THM-01-2025-004', 'ISO/IEC 17025 Accredited Calib Lab Ltd', 1, 'NIST Traceable Reference Standards Set #4', 0.0030, '2025-03-04 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (90, 21, '2026-03-16', '2027-03-16', 'CAL-EQ-THM-01-2026-005', 'Internal Metrology Department', 1, 'NIST Traceable Reference Standards Set #4', 0.0035, '2026-03-16 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (91, 22, '2022-01-27', '2023-01-27', 'CAL-EQ-MASS-01-2022-001', 'Internal Metrology Department', 1, 'NIST Traceable Reference Standards Set #4', 0.0015, '2022-01-27 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (92, 22, '2023-02-08', '2024-02-08', 'CAL-EQ-MASS-01-2023-002', 'ISO/IEC 17025 Accredited Calib Lab Ltd', 1, 'NIST Traceable Reference Standards Set #4', 0.0020, '2023-02-08 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (93, 22, '2024-02-20', '2025-02-20', 'CAL-EQ-MASS-01-2024-003', 'Internal Metrology Department', 1, 'NIST Traceable Reference Standards Set #4', 0.0025, '2024-02-20 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (94, 22, '2025-03-04', '2026-03-04', 'CAL-EQ-MASS-01-2025-004', 'ISO/IEC 17025 Accredited Calib Lab Ltd', 1, 'NIST Traceable Reference Standards Set #4', 0.0030, '2025-03-04 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (95, 22, '2026-03-16', '2027-03-16', 'CAL-EQ-MASS-01-2026-005', 'Internal Metrology Department', 1, 'NIST Traceable Reference Standards Set #4', 0.0035, '2026-03-16 00:00:00+02');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (96, 23, '2021-11-15', '2022-11-15', 'CERT-2021-00891', 'Metrology Tech Services', 1, 'Fluke 1524 Reference Thermometer (SN: 349102)', 0.15, '2026-09-12 15:32:30.758015+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (97, 23, '2022-11-10', '2023-11-10', 'CERT-2022-01102', 'Metrology Tech Services', 1, 'Fluke 1524 Reference Thermometer (SN: 349102)', 0.12, '2026-09-12 15:32:30.766459+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (98, 23, '2023-11-12', '2024-11-12', 'CERT-2023-01450', 'Apex Calibration Labs', 1, 'Fluke 1524 Reference Thermometer (SN: 481029)', 0.14, '2026-09-12 15:32:30.766625+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (99, 23, '2024-11-14', '2025-11-14', 'CERT-2024-01892', 'Apex Calibration Labs', 1, 'Fluke 1524 Reference Thermometer (SN: 481029)', 0.10, '2026-09-12 15:32:30.766629+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (100, 23, '2025-11-15', '2026-11-15', 'CERT-2025-02301', 'Apex Calibration Labs', 1, 'Fluke 1524 Reference Thermometer (SN: 481029)', 0.11, '2026-09-12 15:32:30.766633+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (101, 24, '2022-01-15', '2023-01-15', 'CC-2022-0112', 'Metrology Services Inc.', 1, 'E2 Class Mass Set (Std-001)', 0.0001, '2026-09-15 19:57:03.775333+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (102, 24, '2023-01-15', '2024-01-15', 'CC-2023-0145', 'Metrology Services Inc.', 1, 'E2 Class Mass Set (Std-001)', 0.0001, '2026-09-15 19:57:03.784459+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (103, 24, '2024-01-15', '2025-01-15', 'CC-2024-0162', 'Metrology Services Inc.', 1, 'E2 Class Mass Set (Std-001)', 0.0001, '2026-09-15 19:57:03.784471+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (104, 24, '2025-01-15', '2026-01-15', 'CC-2025-0178', 'Metrology Services Inc.', 1, 'E2 Class Mass Set (Std-001)', 0.0001, '2026-09-15 19:57:03.784476+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (105, 24, '2026-01-15', '2027-01-15', 'CC-2026-0189', 'Metrology Services Inc.', 1, 'E2 Class Mass Set (Std-001)', 0.0001, '2026-09-15 19:57:03.78448+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (106, 25, '2022-06-30', '2023-06-30', 'CC-2022-0010', 'Volumetric Calib Lab', 1, 'ISO 4787 Gravimetric Water Std', 0.40, '2026-09-15 19:57:03.785662+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (107, 25, '2023-06-30', '2024-06-30', 'CC-2023-0021', 'Volumetric Calib Lab', 1, 'ISO 4787 Gravimetric Water Std', 0.40, '2026-09-15 19:57:03.78568+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (108, 25, '2024-06-30', '2025-06-30', 'CC-2024-0033', 'Volumetric Calib Lab', 1, 'ISO 4787 Gravimetric Water Std', 0.40, '2026-09-15 19:57:03.785684+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (109, 25, '2025-06-30', '2026-06-30', 'CC-2025-0039', 'Volumetric Calib Lab', 1, 'ISO 4787 Gravimetric Water Std', 0.40, '2026-09-15 19:57:03.78569+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (110, 25, '2026-06-30', '2027-06-30', 'CC-2026-0044', 'Volumetric Calib Lab', 1, 'ISO 4787 Gravimetric Water Std', 0.40, '2026-09-15 19:57:03.785693+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (111, 26, '2021-11-20', '2022-11-20', 'CC-2021-0301', 'Metrohm Field Service', 1, 'Gravimetric/Potentiometric Std', 0.001, '2026-09-15 19:57:03.785923+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (112, 26, '2022-11-20', '2023-11-20', 'CC-2022-0335', 'Metrohm Field Service', 1, 'Gravimetric/Potentiometric Std', 0.001, '2026-09-15 19:57:03.785931+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (113, 26, '2023-11-20', '2024-11-20', 'CC-2023-0370', 'Metrohm Field Service', 1, 'Gravimetric/Potentiometric Std', 0.001, '2026-09-15 19:57:03.785935+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (114, 26, '2024-11-20', '2025-11-20', 'CC-2024-0398', 'Metrohm Field Service', 1, 'Gravimetric/Potentiometric Std', 0.001, '2026-09-15 19:57:03.785938+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (115, 26, '2025-11-20', '2026-11-20', 'CC-2026-0412', 'Metrohm Field Service', 1, 'Gravimetric/Potentiometric Std', 0.001, '2026-09-15 19:57:03.785941+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (116, 27, '2022-02-28', '2023-02-28', 'CC-2022-0210', 'Precision Calib Services', 1, 'ISO 8655 Gravimetric Method', 0.020, '2026-09-15 19:57:03.786182+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (117, 27, '2023-02-28', '2024-02-28', 'CC-2023-0245', 'Precision Calib Services', 1, 'ISO 8655 Gravimetric Method', 0.020, '2026-09-15 19:57:03.786191+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (118, 27, '2024-02-28', '2025-02-28', 'CC-2024-0272', 'Precision Calib Services', 1, 'ISO 8655 Gravimetric Method', 0.020, '2026-09-15 19:57:03.786195+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (119, 27, '2025-02-28', '2026-02-28', 'CC-2025-0289', 'Precision Calib Services', 1, 'ISO 8655 Gravimetric Method', 0.020, '2026-09-15 19:57:03.786199+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (120, 27, '2026-02-28', '2027-02-28', 'CC-2026-0301', 'Precision Calib Services', 1, 'ISO 8655 Gravimetric Method', 0.020, '2026-09-15 19:57:03.786202+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (121, 28, '2022-09-15', '2023-09-15', 'Internal QC-2022-01', 'Internal Quality Control', 1, 'Silica Gel Indicator Inspection', NULL, '2026-09-15 19:57:03.78639+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (122, 28, '2023-09-15', '2024-09-15', 'Internal QC-2023-01', 'Internal Quality Control', 1, 'Silica Gel Indicator Inspection', NULL, '2026-09-15 19:57:03.786397+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (123, 28, '2024-09-15', '2025-09-15', 'Internal QC-2024-01', 'Internal Quality Control', 1, 'Silica Gel Indicator Inspection', NULL, '2026-09-15 19:57:03.786401+03');


--
-- Data for Name: equipment_statuses; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.equipment_statuses VALUES (1, 'Active');
INSERT INTO public.equipment_statuses VALUES (2, 'Inactive');
INSERT INTO public.equipment_statuses VALUES (3, 'Calibration Due');
INSERT INTO public.equipment_statuses VALUES (4, 'Out of Service');


--
-- Data for Name: equipments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (24, 'BAL-003', 'Analytical Balance  (5-Dec)', 'Mettler Toledo', 'XPE205', 'MT-XPE205-8841', 'Lab Control Zone 3', 1, 365, '2027-01-15', '2026-09-15 19:57:03.77107+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (18, 'BAL-004', 'Analytical Balance (0.1 mg)', 'Mettler Toledo', 'MS204TS', 'SN-MS204-7731', 'Weighing Room 102', 1, 365, '2027-01-20', '2026-09-09 11:57:15.378238+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (28, 'DES-001', 'Desiccator Vessel', 'Schott Duran', 'Glass (Silica)', 'DES-001-SN', 'Lab Control Zone 3', 1, 365, '2027-09-15', '2026-09-15 19:57:03.774715+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (27, 'PIP-010', 'Volumetric Pipette (10 mL)', 'Eppendorf', 'Reference 2 Class A', 'PIP-010-SN', 'Lab Control Zone 3', 1, 365, '2027-02-28', '2026-09-15 19:57:03.774642+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (26, 'TIT-007', 'Digital Piston Titrator', 'Metrohm', 'Eco Titrator 20 mL', 'TIT-007-SN', 'Lab Control Zone 3', 1, 365, '2026-11-20', '2026-09-15 19:57:03.774554+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (25, 'VF-1000-02', 'Volumetric Flask (1000 mL)', 'Brand E-MIL', 'Class A', 'VF-1000-02-SN', 'Lab Control Zone 3', 1, 365, '2027-06-30', '2026-09-15 19:57:03.774434+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (23, 'OV-103', 'Drying Oven: Memmert UN55 Universal Oven', 'Memmert', 'UN55', 'SN-MEM-2021-5501', 'Analytical Prep Lab - Room 204', 1, 365, '2026-11-15', '2026-09-12 15:32:30.753728+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (22, 'EQ-MASS-01', 'E1 Class Stainless Steel Calibration Weights', 'Troemner', 'E1 Mass Set (1mg - 200g)', 'SN-TRM-E1-0042', 'Metrology Cabinet A', 1, 365, '2027-04-18', '2026-09-09 11:57:15.378257+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (21, 'EQ-THM-01', 'Reference Pt100 Temperature Probe Standard', 'Fluke Calibration', '1523 Handheld', 'SN-FLK-1523-88', 'Metrology Cabinet A', 1, 365, '2027-05-10', '2026-09-09 11:57:15.378252+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (20, 'EQ-ENV-02', 'Thermal Anemometer (Fume Hood Face Velocity)', 'TSI', 'AccuBalance 8380', 'SN-TSI-8380-09', 'Fume Hood FH-01', 1, 365, '2026-12-15', '2026-09-09 11:57:15.378247+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (19, 'EQ-ENV-01', 'Digital Thermo-Hygrometer (Ambient Temp & RH)', 'Vaisala', 'HM70', 'SN-HM70-3310', 'QC Lab Main Area', 1, 365, '2027-03-01', '2026-09-09 11:57:15.378243+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (17, 'EQ-BUR-03', 'Digital Auto-Burette (0.001 mL)', 'Metrohm', '876 Dosimat', 'SN-876-44120', 'QC Lab Room 101', 1, 365, '2026-11-10', '2026-09-09 11:57:15.378231+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (16, 'EQ-COD-01', 'COD Digestion Block (Dual-Zone 150°C)', 'Thermo Scientific', 'SP012', 'SN-SP012-9981', 'QC Lab Room 101', 1, 365, '2027-02-15', '2026-09-09 11:57:15.37805+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (15, 'TMR-001', 'Digital Calibration Stopwatch / Process Timer', 'Traceable Products', '5004 Precision Timer', 'SN-TMR001-1120', 'Aggregate & Soils Lab - Room 108', 1, 365, '2027-06-20', '2026-08-25 21:57:42.804502+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (14, 'SPL-001', 'Mechanical Riffle Sample Splitter', 'Gilson Company', 'SP-1 Universal', 'SN-SPL001-3049', 'Aggregate & Soils Lab - Room 108', 1, 365, '2027-07-05', '2026-08-25 21:57:42.804464+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (13, 'SEV-SET-01', 'ASTM E11 8-inch Certified Test Sieve Stack', 'W.S. Tyler', '8in Full Height SS Set', 'SN-SEV8820-SET', 'Aggregate & Soils Lab - Room 108', 1, 365, '2027-07-10', '2026-08-25 21:57:42.802935+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (12, 'FEEL-001', 'Precision Straightedge & Feeler Gauge Set', 'Starrett', '270 / 380-12', 'SN-FEEL001-4091', 'Concrete Testing Lab - Room 102', 1, 365, '2027-06-28', '2026-08-25 21:37:36.083359+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (11, 'CTK-002', 'Curing Tank #2 Temperature Monitoring System', 'Gilson Company', 'HM-652', 'SN-CTK002-1102', 'Concrete Curing Room - Water Tank #2', 1, 365, '2027-07-01', '2026-08-25 21:37:36.083335+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (10, 'CAL-002', 'Digital Heavy-Duty Caliper (0-300mm)', 'Mitutoyo', '500-197-30', 'SN-CAL002-8841', 'Concrete Testing Lab - Room 102', 1, 365, '2027-07-04', '2026-08-25 21:37:36.08147+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (9, 'TH-101', 'Precision Digital Reference Thermometer', 'Fluke Calibration', '1523', 'SN-TH101-3310', 'Physical Testing Lab - Room 104', 1, 365, '2027-06-15', '2026-08-25 21:18:24.145398+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (8, 'WB-101', 'Recirculating Hydrostatic Water Bath', 'Humboldt Mfg.', 'H-1390', 'SN-WB101-9012', 'Physical Testing Lab - Room 104', 1, 365, '2027-07-02', '2026-08-25 21:18:24.145389+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (7, 'CAL-001', 'Digital Depth Caliper (0-300mm)', 'Mitutoyo', 'CD-12"CX', 'SN-CAL001-5541', 'Physical Testing Lab - Bench C', 1, 365, '2027-07-01', '2026-08-25 21:18:24.144206+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (6, 'OV-101', 'Forced Air Convection Drying Oven (103-105°C)', 'Thermo Scientific', 'Heratherm OGH100', 'SN-OV101-7720', 'Environmental Chemistry Lab - Room 202', 1, 365, '2027-07-05', '2026-08-25 20:50:39.636872+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (5, 'BAL-002', 'High-Capacity Precision Balance (0.1g)', 'Ohaus', 'Ranger 7000', 'SN-BAL002-3301', 'Physical Testing Lab - Bench C', 1, 180, '2026-12-02', '2026-08-24 15:37:15.24518+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (4, 'BAL-001', 'Micro/Analytical Balance (0.1mg)', 'Mettler Toledo', 'XPR204S', 'SN-BAL001-9931', 'Analytical Chemistry Lab - Bench A', 1, 180, '2026-11-29', '2026-08-24 15:37:15.245176+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (3, 'SHK-04', '8-inch Mechanical Sieve Shaker', 'W.S. Tyler', 'Ro-Tap RX-29', 'SN-SHK04-1092', 'Aggregate & Soils Lab - Room 108', 1, 365, '2027-07-10', '2026-08-24 15:37:15.245172+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (2, 'OV-102', 'Vacuum Drying Oven', 'Hasuc Equipment', 'DHG-9030A', 'SN-OV102-4419', 'Raw Material Quality Lab - Room 204', 1, 365, '2027-07-08', '2026-08-24 15:37:15.24514+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (1, 'CM-400', 'Digital Compression Press', 'Forney Test Equipment', 'CM-400', 'SN-CM400-8812', 'Concrete Testing Lab - Room 102', 1, 365, '2027-07-01', '2026-08-24 15:37:15.243265+03');


--
-- Data for Name: form_condition_evals; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (72, 14, 85, 0, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (73, 14, 85, -225, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (74, 14, 85, 1995, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (75, 14, 85, 2000, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (76, 14, 85, 2004, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (77, 14, 86, 0, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (78, 14, 86, -225, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (79, 14, 86, 1995, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (80, 14, 86, 2000, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (81, 14, 86, 2004, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (82, 14, 87, 0, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (83, 14, 87, -225, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (84, 14, 87, 1995, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (85, 14, 87, 2000, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (86, 14, 87, 2004, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (87, 14, 88, 0, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (88, 14, 88, -225, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (89, 14, 88, 1995, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (90, 14, 88, 2000, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (91, 14, 88, 2004, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (92, 14, 89, 0, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (93, 14, 89, -225, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (23, 14, 78, 4530, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (24, 14, 78, 5000, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (25, 14, 78, 5015, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (94, 14, 89, 1995, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (95, 14, 89, 2000, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (96, 14, 89, 2004, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (103, 14, 96, 0.3, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (104, 14, 96, 0.15, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (105, 14, 96, 0.35, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (106, 14, 96, -0.5, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (107, 14, 96, 0, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (67, 14, 90, 0, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (68, 14, 90, 1995, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (69, 14, 90, -225, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (70, 14, 90, 2000, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (71, 14, 90, 2004, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (108, 13, 66, 43, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (109, 13, 66, 45, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (110, 13, 66, 45.5, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (132, 15, 102, 19.9, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (133, 15, 102, 25, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (134, 15, 102, 22.5, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (135, 15, 102, 20, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (136, 15, 102, 25.5, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (137, 15, 103, 65.6, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (138, 15, 103, 65, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (139, 15, 103, 45, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (140, 15, 103, 30, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (141, 15, 103, 29.9, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (142, 15, 114, 0.49, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (143, 15, 114, 0.5, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (144, 15, 114, 0.51, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (145, 15, 117, 2, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (146, 15, 117, 3, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (147, 15, 117, 4, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (156, 16, 102, 16.5, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (157, 16, 102, 17, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (158, 16, 102, 21.5, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (159, 16, 102, 23, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (160, 16, 102, 23.5, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (161, 16, 103, 29.5, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (162, 16, 103, 30, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (163, 16, 103, 41.5, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (164, 16, 103, 60, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (165, 16, 103, 60.5, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (171, 16, 104, 0.65, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (172, 16, 104, 0.35, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (173, 16, 104, 0.4, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (174, 16, 104, 0.53, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (175, 16, 104, 0.6, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (188, 16, 131, 0.5, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (189, 16, 131, 0.49, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (190, 16, 131, 0.53, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (191, 16, 128, 0.5, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (192, 16, 128, 0.49, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (193, 16, 128, 0.53, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (194, 16, 130, 2, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (195, 16, 130, 3, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (196, 16, 130, 4, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (197, 17, 102, 16.5, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (198, 17, 102, 17, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (199, 17, 102, 21.5, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (200, 17, 102, 23, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (201, 17, 102, 23.5, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (202, 17, 103, 39.5, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (203, 17, 103, 40, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (204, 17, 103, 49, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (205, 17, 103, 65, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (206, 17, 103, 65.5, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (207, 17, 104, 0.39, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (208, 17, 104, 0.4, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (209, 17, 104, 0.53, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (210, 17, 104, 0.6, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (211, 17, 104, 0.61, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (217, 17, 143, 105.3, 0, 0, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (218, 17, 143, 105, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (219, 17, 143, 102, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (220, 17, 143, 95, 1, 1, true, NULL);
INSERT INTO public.form_condition_evals OVERRIDING SYSTEM VALUE VALUES (221, 17, 143, 94.9, 0, 0, true, NULL);


--
-- Data for Name: form_eval_params; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.form_eval_params VALUES (1, 1, 3, 0, 1288.87, 1288.87, true);
INSERT INTO public.form_eval_params VALUES (1, 1, 6, 0, 434.54, NULL, false);
INSERT INTO public.form_eval_params VALUES (1, 1, 7, 0, 433.234, NULL, false);
INSERT INTO public.form_eval_params VALUES (1, 1, 8, 0, 3, NULL, false);
INSERT INTO public.form_eval_params VALUES (1, 1, 9, 0, 645, NULL, false);
INSERT INTO public.form_eval_params VALUES (1, 1, 10, 0, 0, NULL, false);
INSERT INTO public.form_eval_params VALUES (1, 1, 11, 0, 643.87, NULL, false);
INSERT INTO public.form_eval_params VALUES (2, 1, 3, 0, 1100.74, 1100.74, true);
INSERT INTO public.form_eval_params VALUES (2, 1, 6, 0, 645.4, NULL, false);
INSERT INTO public.form_eval_params VALUES (2, 1, 7, 0, 455.34, NULL, false);
INSERT INTO public.form_eval_params VALUES (2, 1, 8, 0, 2, NULL, false);
INSERT INTO public.form_eval_params VALUES (2, 1, 9, 0, 546.89, NULL, false);
INSERT INTO public.form_eval_params VALUES (2, 1, 10, 0, 1, NULL, false);
INSERT INTO public.form_eval_params VALUES (2, 1, 11, 0, 433.45, NULL, false);
INSERT INTO public.form_eval_params VALUES (3, 2, 1, 0, 456.5, 456.5, true);
INSERT INTO public.form_eval_params VALUES (3, 2, 12, 0, 756.7, NULL, false);
INSERT INTO public.form_eval_params VALUES (3, 2, 13, 0, 2, NULL, false);
INSERT INTO public.form_eval_params VALUES (3, 2, 14, 0, 456.5, NULL, false);
INSERT INTO public.form_eval_params VALUES (4, 2, 1, 0, 45.545, 45.545, true);
INSERT INTO public.form_eval_params VALUES (4, 2, 12, 0, 45.545, NULL, false);
INSERT INTO public.form_eval_params VALUES (4, 2, 13, 0, 1, NULL, false);
INSERT INTO public.form_eval_params VALUES (4, 2, 14, 0, 65.645, NULL, false);
INSERT INTO public.form_eval_params VALUES (5, 3, 1, 0, 259073, 259073, true);
INSERT INTO public.form_eval_params VALUES (5, 3, 2, 0, 1024.01, 1024.01, true);
INSERT INTO public.form_eval_params VALUES (5, 3, 3, 0, 567.47, NULL, false);
INSERT INTO public.form_eval_params VALUES (5, 3, 19, 0, 456.54, NULL, false);
INSERT INTO public.form_eval_params VALUES (6, 3, 1, 0, 2501.47, 2501.47, true);
INSERT INTO public.form_eval_params VALUES (6, 3, 2, 0, 100.427, 100.427, true);
INSERT INTO public.form_eval_params VALUES (6, 3, 3, 0, 45.75, NULL, false);
INSERT INTO public.form_eval_params VALUES (6, 3, 19, 0, 54.677, NULL, false);
INSERT INTO public.form_eval_params VALUES (7, 4, 1, 0, 459.962, 459.962, true);
INSERT INTO public.form_eval_params VALUES (7, 4, 21, 0, 346.45, NULL, false);
INSERT INTO public.form_eval_params VALUES (7, 4, 22, 0, 56.756, NULL, false);
INSERT INTO public.form_eval_params VALUES (8, 4, 1, 0, 192.112, 192.112, true);
INSERT INTO public.form_eval_params VALUES (8, 4, 21, 0, 56.756, NULL, false);
INSERT INTO public.form_eval_params VALUES (8, 4, 22, 0, 67.678, NULL, false);
INSERT INTO public.form_eval_params VALUES (9, 5, 2, 0, 379.299, 379.299, true);
INSERT INTO public.form_eval_params VALUES (9, 5, 24, 0, 645.65, NULL, false);
INSERT INTO public.form_eval_params VALUES (9, 5, 25, 0, 56.474, NULL, false);
INSERT INTO public.form_eval_params VALUES (10, 5, 2, 0, 1140.74, 1140.74, true);
INSERT INTO public.form_eval_params VALUES (10, 5, 24, 0, 564.576, NULL, false);
INSERT INTO public.form_eval_params VALUES (10, 5, 25, 0, 858.456, NULL, false);
INSERT INTO public.form_eval_params VALUES (11, 6, 4, 0, 304.317, 304.317, true);
INSERT INTO public.form_eval_params VALUES (11, 6, 27, 0, 456.476, NULL, false);
INSERT INTO public.form_eval_params VALUES (12, 6, 4, 0, 4304.44, 4304.44, true);
INSERT INTO public.form_eval_params VALUES (12, 6, 27, 0, 6456.65, NULL, false);
INSERT INTO public.form_eval_params VALUES (13, 7, 28, 0, 494.829, 494.829, true);
INSERT INTO public.form_eval_params VALUES (13, 7, 29, 0, 567.5, NULL, false);
INSERT INTO public.form_eval_params VALUES (13, 7, 30, 0, 345.357, NULL, false);
INSERT INTO public.form_eval_params VALUES (13, 7, 30, 1, 564.564, NULL, false);
INSERT INTO public.form_eval_params VALUES (13, 7, 30, 2, 574.567, NULL, false);
INSERT INTO public.form_eval_params VALUES (13, 7, 31, 0, 5674, NULL, false);
INSERT INTO public.form_eval_params VALUES (13, 7, 36, 0, 456.867, NULL, false);
INSERT INTO public.form_eval_params VALUES (13, 7, 36, 1, 456.566, NULL, false);
INSERT INTO public.form_eval_params VALUES (13, 7, 36, 2, 756.75, NULL, false);
INSERT INTO public.form_eval_params VALUES (13, 7, 37, 0, 2788250, 2788250, true);
INSERT INTO public.form_eval_params VALUES (13, 7, 37, 1, 2910940, 2910940, true);
INSERT INTO public.form_eval_params VALUES (13, 7, 37, 2, 4619870, 4619870, true);
INSERT INTO public.form_eval_params VALUES (13, 7, 38, 0, 2, NULL, false);
INSERT INTO public.form_eval_params VALUES (15, 7, 28, 0, 74.7087, 74.7087, true);
INSERT INTO public.form_eval_params VALUES (15, 7, 29, 0, 64.5657, NULL, false);
INSERT INTO public.form_eval_params VALUES (15, 7, 30, 0, 64.564, NULL, false);
INSERT INTO public.form_eval_params VALUES (15, 7, 30, 1, 73.4568, NULL, false);
INSERT INTO public.form_eval_params VALUES (15, 7, 30, 2, 67.347, NULL, false);
INSERT INTO public.form_eval_params VALUES (15, 7, 30, 3, 93.467, NULL, false);
INSERT INTO public.form_eval_params VALUES (15, 7, 31, 0, 45.345, NULL, false);
INSERT INTO public.form_eval_params VALUES (15, 7, 36, 0, 85.4342, NULL, false);
INSERT INTO public.form_eval_params VALUES (15, 7, 36, 1, 89.7366, NULL, false);
INSERT INTO public.form_eval_params VALUES (15, 7, 36, 2, 78.4335, NULL, false);
INSERT INTO public.form_eval_params VALUES (15, 7, 36, 3, 54.5357, NULL, false);
INSERT INTO public.form_eval_params VALUES (15, 7, 37, 0, 8042.63, 8042.63, true);
INSERT INTO public.form_eval_params VALUES (15, 7, 37, 1, 8811.89, 8811.89, true);
INSERT INTO public.form_eval_params VALUES (15, 7, 37, 2, 7904.87, 7904.87, true);
INSERT INTO public.form_eval_params VALUES (15, 7, 37, 3, 8507.68, 8507.68, true);
INSERT INTO public.form_eval_params VALUES (15, 7, 38, 0, 4, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 29, 0, 53.453, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 30, 0, 63.4345, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 30, 1, 65.456, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 30, 2, 66.423, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 31, 0, 45.6456, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 36, 0, 34.5345, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 36, 1, 45.6456, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 36, 2, 84.57, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 38, 0, 4, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 39, 0, 2, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 39, 1, 3, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 39, 2, 1, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 40, 0, 0, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 40, 1, 0, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 40, 2, 0, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 41, 0, 0, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 45, 0, 1, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 45, 1, 2, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 45, 3, 2, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 28, 0, 65.1045, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 37, 0, 4969.11, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 37, 1, 5585.34, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 37, 2, 7411.76, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 42, 0, 1, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 43, 0, 1, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 43, 1, 1, NULL, false);
INSERT INTO public.form_eval_params VALUES (14, 8, 43, 2, 1, NULL, false);
INSERT INTO public.form_eval_params VALUES (16, 10, 46, 0, 150.2, NULL, false);
INSERT INTO public.form_eval_params VALUES (16, 10, 47, 0, 149.8, NULL, false);
INSERT INTO public.form_eval_params VALUES (16, 10, 48, 0, 300.1, NULL, false);
INSERT INTO public.form_eval_params VALUES (16, 10, 49, 0, 299.9, NULL, false);
INSERT INTO public.form_eval_params VALUES (16, 10, 50, 0, 785.4, NULL, false);
INSERT INTO public.form_eval_params VALUES (16, 10, 51, 0, 44.4, 44.4, true);
INSERT INTO public.form_eval_params VALUES (16, 10, 52, 0, 2, 2, true);
INSERT INTO public.form_eval_params VALUES (17, 11, 56, 0, 3.27, 3.27, true);
INSERT INTO public.form_eval_params VALUES (17, 11, 53, 0, 1, NULL, false);
INSERT INTO public.form_eval_params VALUES (17, 11, 53, 1, 0.5, NULL, false);
INSERT INTO public.form_eval_params VALUES (17, 11, 53, 2, 0.25, NULL, false);
INSERT INTO public.form_eval_params VALUES (17, 11, 53, 3, 0.2, NULL, false);
INSERT INTO public.form_eval_params VALUES (17, 11, 54, 0, 25, NULL, false);
INSERT INTO public.form_eval_params VALUES (17, 11, 54, 1, 13, NULL, false);
INSERT INTO public.form_eval_params VALUES (17, 11, 54, 2, 6, NULL, false);
INSERT INTO public.form_eval_params VALUES (17, 11, 54, 3, 5, NULL, false);
INSERT INTO public.form_eval_params VALUES (17, 11, 55, 0, 25, 25, true);
INSERT INTO public.form_eval_params VALUES (17, 11, 57, 0, 4, 4, true);
INSERT INTO public.form_eval_params VALUES (17, 11, 58, 0, 25, 25, true);
INSERT INTO public.form_eval_params VALUES (17, 11, 58, 1, 26, 26, true);
INSERT INTO public.form_eval_params VALUES (17, 11, 58, 2, 24, 24, true);
INSERT INTO public.form_eval_params VALUES (17, 11, 58, 3, 25, 25, true);
INSERT INTO public.form_eval_params VALUES (18, 12, 65, 0, 5, 5, true);
INSERT INTO public.form_eval_params VALUES (18, 12, 59, 0, 12.4502, NULL, false);
INSERT INTO public.form_eval_params VALUES (18, 12, 59, 1, 11.8905, NULL, false);
INSERT INTO public.form_eval_params VALUES (18, 12, 59, 2, 13.1104, NULL, false);
INSERT INTO public.form_eval_params VALUES (18, 12, 59, 3, 12.0231, NULL, false);
INSERT INTO public.form_eval_params VALUES (18, 12, 59, 4, 12.7844, NULL, false);
INSERT INTO public.form_eval_params VALUES (18, 12, 60, 0, 17.4502, NULL, false);
INSERT INTO public.form_eval_params VALUES (18, 12, 60, 1, 16.8905, NULL, false);
INSERT INTO public.form_eval_params VALUES (18, 12, 60, 2, 18.1104, NULL, false);
INSERT INTO public.form_eval_params VALUES (18, 12, 60, 3, 17.0231, NULL, false);
INSERT INTO public.form_eval_params VALUES (18, 12, 60, 4, 17.7844, NULL, false);
INSERT INTO public.form_eval_params VALUES (18, 12, 61, 0, 17.4302, NULL, false);
INSERT INTO public.form_eval_params VALUES (18, 12, 61, 1, 16.8715, NULL, false);
INSERT INTO public.form_eval_params VALUES (18, 12, 61, 2, 18.0894, NULL, false);
INSERT INTO public.form_eval_params VALUES (18, 12, 61, 3, 17.0011, NULL, false);
INSERT INTO public.form_eval_params VALUES (18, 12, 61, 4, 17.7664, NULL, false);
INSERT INTO public.form_eval_params VALUES (18, 12, 62, 0, 0.4, 0.4, true);
INSERT INTO public.form_eval_params VALUES (18, 12, 62, 1, 0.38, 0.38, true);
INSERT INTO public.form_eval_params VALUES (18, 12, 62, 2, 0.42, 0.42, true);
INSERT INTO public.form_eval_params VALUES (18, 12, 62, 3, 0.44, 0.44, true);
INSERT INTO public.form_eval_params VALUES (18, 12, 62, 4, 0.36, 0.36, true);
INSERT INTO public.form_eval_params VALUES (18, 12, 63, 0, 0.4, 0.4, true);
INSERT INTO public.form_eval_params VALUES (18, 12, 64, 0, 0.032, 0.032, true);
INSERT INTO public.form_eval_params VALUES (19, 13, 72, 0, 51.0, 51, true);
INSERT INTO public.form_eval_params VALUES (19, 13, 73, 0, 2.312, 2.312, true);
INSERT INTO public.form_eval_params VALUES (19, 13, 73, 1, 2.298, 2.298, true);
INSERT INTO public.form_eval_params VALUES (19, 13, 73, 2, 2.325, 2.325, true);
INSERT INTO public.form_eval_params VALUES (19, 13, 73, 3, 2.305, 2.305, true);
INSERT INTO public.form_eval_params VALUES (19, 13, 74, 0, 0.47, 0.47, true);
INSERT INTO public.form_eval_params VALUES (19, 13, 75, 0, 4, 4, true);
INSERT INTO public.form_eval_params VALUES (19, 13, 76, 0, 93.9, 93.9, true);
INSERT INTO public.form_eval_params VALUES (19, 13, 66, 3, 51.6, NULL, false);
INSERT INTO public.form_eval_params VALUES (19, 13, 67, 0, 1201.2, NULL, false);
INSERT INTO public.form_eval_params VALUES (19, 13, 67, 1, 1195.4, NULL, false);
INSERT INTO public.form_eval_params VALUES (19, 13, 67, 2, 1210.6, NULL, false);
INSERT INTO public.form_eval_params VALUES (19, 13, 77, 0, 93.9928, 93.9928, true);
INSERT INTO public.form_eval_params VALUES (19, 13, 77, 1, 93.4131, 93.4131, true);
INSERT INTO public.form_eval_params VALUES (19, 13, 77, 2, 94.5100, 94.51, true);
INSERT INTO public.form_eval_params VALUES (19, 13, 77, 3, 93.6974, 93.6974, true);
INSERT INTO public.form_eval_params VALUES (19, 13, 66, 0, 52.1, NULL, false);
INSERT INTO public.form_eval_params VALUES (19, 13, 66, 1, 49.5, NULL, false);
INSERT INTO public.form_eval_params VALUES (19, 13, 66, 2, 50.8, NULL, false);
INSERT INTO public.form_eval_params VALUES (19, 13, 67, 3, 1204.8, NULL, false);
INSERT INTO public.form_eval_params VALUES (19, 13, 68, 0, 1206.8, NULL, false);
INSERT INTO public.form_eval_params VALUES (19, 13, 68, 1, 1202.1, NULL, false);
INSERT INTO public.form_eval_params VALUES (19, 13, 68, 2, 1215.1, NULL, false);
INSERT INTO public.form_eval_params VALUES (19, 13, 68, 3, 1210.9, NULL, false);
INSERT INTO public.form_eval_params VALUES (19, 13, 69, 0, 687.3, NULL, false);
INSERT INTO public.form_eval_params VALUES (19, 13, 69, 1, 681.9, NULL, false);
INSERT INTO public.form_eval_params VALUES (19, 13, 69, 2, 694.4, NULL, false);
INSERT INTO public.form_eval_params VALUES (19, 13, 69, 3, 688.2, NULL, false);
INSERT INTO public.form_eval_params VALUES (20, 14, 78, 0, 5015, NULL, false);
INSERT INTO public.form_eval_params VALUES (20, 14, 79, 0, 0, NULL, false);
INSERT INTO public.form_eval_params VALUES (20, 14, 80, 0, 250, NULL, false);
INSERT INTO public.form_eval_params VALUES (20, 14, 81, 0, 2000, NULL, false);
INSERT INTO public.form_eval_params VALUES (20, 14, 82, 0, 3500, NULL, false);
INSERT INTO public.form_eval_params VALUES (20, 14, 83, 0, 4510, NULL, false);
INSERT INTO public.form_eval_params VALUES (20, 14, 84, 0, 5010, NULL, false);
INSERT INTO public.form_eval_params VALUES (20, 14, 85, 0, 0, 0, true);
INSERT INTO public.form_eval_params VALUES (20, 14, 86, 0, 250, 250, true);
INSERT INTO public.form_eval_params VALUES (20, 14, 87, 0, 1750, 1750, true);
INSERT INTO public.form_eval_params VALUES (20, 14, 88, 0, 1500, 1500, true);
INSERT INTO public.form_eval_params VALUES (20, 14, 89, 0, 1010, 1010, true);
INSERT INTO public.form_eval_params VALUES (20, 14, 90, 0, 500, 500, true);
INSERT INTO public.form_eval_params VALUES (20, 14, 91, 0, 100, 100, true);
INSERT INTO public.form_eval_params VALUES (20, 14, 92, 0, 95, 95, true);
INSERT INTO public.form_eval_params VALUES (20, 14, 93, 0, 60, 60, true);
INSERT INTO public.form_eval_params VALUES (20, 14, 94, 0, 30, 30, true);
INSERT INTO public.form_eval_params VALUES (20, 14, 95, 0, 10.1, 10.1, true);
INSERT INTO public.form_eval_params VALUES (20, 14, 96, 0, 0.10, 0.1, true);
INSERT INTO public.form_eval_params VALUES (21, 15, 102, 0, 21.5, NULL, false);
INSERT INTO public.form_eval_params VALUES (21, 15, 103, 0, 48.2, NULL, false);
INSERT INTO public.form_eval_params VALUES (21, 15, 107, 0, 0, NULL, false);
INSERT INTO public.form_eval_params VALUES (21, 15, 107, 1, 10.04, NULL, false);
INSERT INTO public.form_eval_params VALUES (21, 15, 107, 2, 20.06, NULL, false);
INSERT INTO public.form_eval_params VALUES (21, 15, 108, 0, 10.04, NULL, false);
INSERT INTO public.form_eval_params VALUES (21, 15, 108, 1, 20.06, NULL, false);
INSERT INTO public.form_eval_params VALUES (21, 15, 108, 2, 30.09, NULL, false);
INSERT INTO public.form_eval_params VALUES (21, 15, 109, 0, 10.04, 10.04, true);
INSERT INTO public.form_eval_params VALUES (21, 15, 109, 1, 10.02, 10.02, true);
INSERT INTO public.form_eval_params VALUES (21, 15, 109, 2, 10.03, 10.03, true);
INSERT INTO public.form_eval_params VALUES (21, 15, 110, 0, 0.016667, 0.016667, true);
INSERT INTO public.form_eval_params VALUES (21, 15, 111, 0, 0.099604, 0.099604, true);
INSERT INTO public.form_eval_params VALUES (21, 15, 111, 1, 0.099802, 0.099802, true);
INSERT INTO public.form_eval_params VALUES (21, 15, 111, 2, 0.099703, 0.099703, true);
INSERT INTO public.form_eval_params VALUES (21, 15, 112, 0, 0.099703, 0.099703, true);
INSERT INTO public.form_eval_params VALUES (21, 15, 113, 0, 0.000099, 0.000099, true);
INSERT INTO public.form_eval_params VALUES (21, 15, 114, 0, 0.10, 0.1, true);
INSERT INTO public.form_eval_params VALUES (21, 15, 115, 0, 1.2258, NULL, false);
INSERT INTO public.form_eval_params VALUES (21, 15, 116, 0, 10, NULL, false);
INSERT INTO public.form_eval_params VALUES (21, 15, 116, 1, 10, NULL, false);
INSERT INTO public.form_eval_params VALUES (21, 15, 116, 2, 10, NULL, false);
INSERT INTO public.form_eval_params VALUES (21, 15, 117, 0, 3, 3, true);
INSERT INTO public.form_eval_params VALUES (22, 16, 126, 0, 0.0416734, 0.0416734, true);
INSERT INTO public.form_eval_params VALUES (22, 16, 127, 0, 0.250040, 0.25004, true);
INSERT INTO public.form_eval_params VALUES (22, 16, 128, 0, 0.0638, 0.0638, true);
INSERT INTO public.form_eval_params VALUES (22, 16, 129, 0, 0.02, 0.02, true);
INSERT INTO public.form_eval_params VALUES (22, 16, 130, 0, 3, 3, true);
INSERT INTO public.form_eval_params VALUES (22, 16, 131, 0, 0.200, 0.2, true);
INSERT INTO public.form_eval_params VALUES (22, 16, 132, 0, 10.00, 10, true);
INSERT INTO public.form_eval_params VALUES (22, 16, 133, 0, 0.041700, 0.0417, true);
INSERT INTO public.form_eval_params VALUES (22, 16, 135, 0, 0.0417, 0.0417, true);
INSERT INTO public.form_eval_params VALUES (22, 16, 136, 0, 0.2500, 0.25, true);
INSERT INTO public.form_eval_params VALUES (23, 17, 102, 0, 21.5, NULL, false);
INSERT INTO public.form_eval_params VALUES (23, 17, 103, 0, 52, NULL, false);
INSERT INTO public.form_eval_params VALUES (23, 17, 104, 0, 0.51, NULL, false);
INSERT INTO public.form_eval_params VALUES (23, 17, 137, 0, 10, NULL, false);
INSERT INTO public.form_eval_params VALUES (23, 17, 138, 0, 14.85, NULL, false);
INSERT INTO public.form_eval_params VALUES (23, 17, 139, 0, 13.65, NULL, false);
INSERT INTO public.form_eval_params VALUES (23, 17, 140, 0, 8.6, NULL, false);
INSERT INTO public.form_eval_params VALUES (23, 17, 141, 0, 0.1002, NULL, false);
INSERT INTO public.form_eval_params VALUES (22, 16, 102, 0, 21.5, NULL, false);
INSERT INTO public.form_eval_params VALUES (22, 16, 103, 0, 48.2, NULL, false);
INSERT INTO public.form_eval_params VALUES (22, 16, 104, 0, 0.51, NULL, false);
INSERT INTO public.form_eval_params VALUES (22, 16, 118, 0, 14.2851, NULL, false);
INSERT INTO public.form_eval_params VALUES (22, 16, 119, 0, 26.5448, NULL, false);
INSERT INTO public.form_eval_params VALUES (22, 16, 120, 0, 1, NULL, false);
INSERT INTO public.form_eval_params VALUES (22, 16, 121, 0, 0.2502, NULL, false);
INSERT INTO public.form_eval_params VALUES (22, 16, 122, 0, 10, NULL, false);
INSERT INTO public.form_eval_params VALUES (22, 16, 123, 0, 0, NULL, false);
INSERT INTO public.form_eval_params VALUES (22, 16, 123, 1, 10.02, NULL, false);
INSERT INTO public.form_eval_params VALUES (22, 16, 123, 2, 0, NULL, false);
INSERT INTO public.form_eval_params VALUES (22, 16, 124, 0, 10.02, NULL, false);
INSERT INTO public.form_eval_params VALUES (22, 16, 124, 1, 20, NULL, false);
INSERT INTO public.form_eval_params VALUES (22, 16, 124, 2, 10, NULL, false);
INSERT INTO public.form_eval_params VALUES (22, 16, 125, 0, 10.02, 10.02, true);
INSERT INTO public.form_eval_params VALUES (22, 16, 125, 1, 9.98, 9.98, true);
INSERT INTO public.form_eval_params VALUES (22, 16, 125, 2, 10, 10, true);
INSERT INTO public.form_eval_params VALUES (23, 17, 105, 0, 96.2, 96.2, true);
INSERT INTO public.form_eval_params VALUES (23, 17, 143, 0, 100.200000, 100.2, true);


--
-- Data for Name: form_evals; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (1, 1, 'Test Case 1');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (2, 1, 'Test Case 2');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (3, 2, 'Test Case 1');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (4, 2, 'Test Case 2');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (5, 3, 'Test Case 1');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (6, 3, 'Test Case 2');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (7, 4, 'Test Case 1');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (8, 4, 'Test Case 2');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (9, 5, 'Test Case 1');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (10, 5, 'Test Case 2');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (11, 6, 'Test Case 1');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (12, 6, 'Test Case 2');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (13, 7, 'Test Case 1');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (14, 8, 'Test Case 1');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (15, 7, 'Test Case 2');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (16, 10, 'Test Case 1');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (17, 11, 'Test Case 1');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (19, 13, 'Test Case 1');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (20, 14, 'Test Case 1');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (18, 12, 'Test Case 1');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (21, 15, 'Test Case 1');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (22, 16, 'Test Case 1');
INSERT INTO public.form_evals OVERRIDING SYSTEM VALUE VALUES (23, 17, 'Test Case 1');


--
-- Data for Name: form_groups; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.form_groups OVERRIDING SYSTEM VALUE VALUES (1, 'Testing Form A', 'Description Testing Form A', 1, true);
INSERT INTO public.form_groups OVERRIDING SYSTEM VALUE VALUES (2, 'Testing Form B', 'Description Testing Form B', 2, true);
INSERT INTO public.form_groups OVERRIDING SYSTEM VALUE VALUES (3, 'Testing Form C', 'Description Testing Form C', 3, true);
INSERT INTO public.form_groups OVERRIDING SYSTEM VALUE VALUES (4, 'Testing Form D', 'Description Testing Form D', 4, true);
INSERT INTO public.form_groups OVERRIDING SYSTEM VALUE VALUES (5, 'Testing Form E', 'Description Testing Form E', 5, true);
INSERT INTO public.form_groups OVERRIDING SYSTEM VALUE VALUES (6, 'Testing Form F', 'Description Testing Form F', 6, true);
INSERT INTO public.form_groups OVERRIDING SYSTEM VALUE VALUES (8, 'Testing Form G', 'Description Testing Form G', 7, true);
INSERT INTO public.form_groups OVERRIDING SYSTEM VALUE VALUES (10, 'Total Suspended Solids (TSS)', 'WASTEWATER EFFLUENT ANALYSIS form', 9, true);
INSERT INTO public.form_groups OVERRIDING SYSTEM VALUE VALUES (11, 'Loss on Drying (LOD)', 'Excepturi beatae quibusdam', 10, true);
INSERT INTO public.form_groups OVERRIDING SYSTEM VALUE VALUES (12, 'Pavement Core Analysis', 'Officia dignissimos tempora commodi', 11, true);
INSERT INTO public.form_groups OVERRIDING SYSTEM VALUE VALUES (9, 'Concrete Compressive Strength', 'Description of Concrete Compressive Strength form', 8, true);
INSERT INTO public.form_groups OVERRIDING SYSTEM VALUE VALUES (13, 'Aggregate Analysis', 'Officia dignissimos tempora commodi', 12, true);
INSERT INTO public.form_groups OVERRIDING SYSTEM VALUE VALUES (14, 'Molarity of Ferrous Ammonium Sulfate (FAS)', 'Standardization & molarity determination of Ferrous Ammonium Sulfate (FAS)', 13, true);
INSERT INTO public.form_groups OVERRIDING SYSTEM VALUE VALUES (15, 'Molarity of COD Digestion Solution (K2Cr2O7)', 'Molarity Verification of COD Digestion Solution (K2Cr2O7)', 14, true);
INSERT INTO public.form_groups OVERRIDING SYSTEM VALUE VALUES (16, 'Chemical Oxygen Demand (COD) - Closed Reflux', 'Chemical Oxygen Demand (COD) - Closed Reflux, Titrimetric Method', 15, true);


--
-- Data for Name: form_params; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.form_params VALUES (1, 6, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 2, 1);
INSERT INTO public.form_params VALUES (1, 7, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 3, 2);
INSERT INTO public.form_params VALUES (1, 8, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 4, 3);
INSERT INTO public.form_params VALUES (1, 9, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 5, 4);
INSERT INTO public.form_params VALUES (1, 10, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 6, 5);
INSERT INTO public.form_params VALUES (1, 3, true, '// [param_aa], [param_ab], [param_ac], [param_ad], [param_ae], [param_af]
IF([param_ac] < 3, [param_aa] + [param_ab], [param_ad] + [param_ae] + [param_af])', 'param_aa,param_ab,param_ac,param_ad,param_ae,param_af', NULL, false, NULL, NULL, false, NULL, 1, 7);
INSERT INTO public.form_params VALUES (2, 12, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 2, 1);
INSERT INTO public.form_params VALUES (2, 13, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 3, 2);
INSERT INTO public.form_params VALUES (2, 14, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 4, 3);
INSERT INTO public.form_params VALUES (2, 1, true, '// [param_ba], [param_bb], [param_bc]
IF([param_bb] == 1, [param_ba], [param_bc])', 'param_ba,param_bb,param_bc', NULL, false, NULL, NULL, false, NULL, 1, 4);
INSERT INTO public.form_params VALUES (3, 1, true, '// [test_b], [test_c], [param_cd]
[test_c] * [param_cd]', 'param_cd,test_c', NULL, false, NULL, NULL, false, NULL, 1, 3);
INSERT INTO public.form_params VALUES (3, 2, true, '// [test_a], [test_c], [param_cd]
[test_c] + [param_cd]', 'param_cd,test_c', NULL, false, NULL, NULL, false, NULL, 2, 4);
INSERT INTO public.form_params VALUES (3, 3, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 3, 1);
INSERT INTO public.form_params VALUES (3, 19, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 4, 2);
INSERT INTO public.form_params VALUES (4, 1, true, '// [param_db], [param_dc]
[param_db] + 2 * [param_dc]', 'param_db,param_dc', NULL, false, NULL, NULL, false, NULL, 1, 3);
INSERT INTO public.form_params VALUES (4, 21, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 2, 1);
INSERT INTO public.form_params VALUES (4, 22, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 3, 2);
INSERT INTO public.form_params VALUES (5, 2, true, '// [param_eb], [param_ec]
[param_eb] / 2 + [param_ec]', 'param_eb,param_ec', NULL, false, NULL, NULL, false, NULL, 1, 3);
INSERT INTO public.form_params VALUES (5, 24, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 2, 1);
INSERT INTO public.form_params VALUES (5, 25, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 3, 2);
INSERT INTO public.form_params VALUES (6, 4, true, '// [param_fb]
[param_fb] * 2 / 3', 'param_fb', NULL, false, NULL, NULL, false, NULL, 1, 2);
INSERT INTO public.form_params VALUES (6, 27, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 2, 1);
INSERT INTO public.form_params VALUES (7, 28, true, '// [[test_j]], [test_k], [pga], [[pgb]], [[pgd]], [pgc]
AVG([[pgb]])', 'pgb', NULL, false, NULL, NULL, false, NULL, 1, 5);
INSERT INTO public.form_params VALUES (7, 29, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 5, 3);
INSERT INTO public.form_params VALUES (7, 30, false, NULL, NULL, 'arr5', false, NULL, NULL, false, NULL, 6, 4);
INSERT INTO public.form_params VALUES (7, 31, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 8, 7);
INSERT INTO public.form_params VALUES (7, 36, false, NULL, NULL, 'arr5', false, NULL, NULL, false, NULL, 7, 6);
INSERT INTO public.form_params VALUES (7, 37, true, '// [test_g], [test_k], [pga], [[pgb]], [[pgd]], [pgc]
[[pgb]] * [pga] + [[pgd]] * [pgc]', 'pga,pgb,pgc,pgd', NULL, false, NULL, NULL, false, NULL, 2, 8);
INSERT INTO public.form_params VALUES (7, 38, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 3, 1);
INSERT INTO public.form_params VALUES (8, 28, true, '// [[test_j]], [test_k], [pga], [[pgb]], [[pgd]], [pgc]
AVG([[pgb]])', 'pgb', NULL, false, NULL, NULL, false, NULL, 1, 9);
INSERT INTO public.form_params VALUES (8, 29, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 9, 6);
INSERT INTO public.form_params VALUES (8, 30, false, NULL, NULL, 'arr5', false, NULL, NULL, true, NULL, 11, 8);
INSERT INTO public.form_params VALUES (8, 31, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 10, 7);
INSERT INTO public.form_params VALUES (8, 36, false, NULL, NULL, 'arr5', false, NULL, NULL, false, NULL, 12, 10);
INSERT INTO public.form_params VALUES (8, 37, true, '// [test_g], [test_k], [pga], [[pgb]], [[pgd]], [pgc], [[pge]], [[pgf]]
[[pgb]] * [pga] + [[pgd]] * [pgc] + [[pge]] + [[pgf]]', 'pga,pgb,pgc,pgd,pge,pgf', NULL, false, NULL, NULL, false, NULL, 3, 13);
INSERT INTO public.form_params VALUES (8, 38, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 4, 3);
INSERT INTO public.form_params VALUES (9, 28, true, '// [[test_j]], [test_k], [pga], [[pgb]], [[pgd]], [pgc]
AVG([[pgb]])', 'pgb', NULL, false, NULL, NULL, false, NULL, 1, 4);
INSERT INTO public.form_params VALUES (9, 29, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 4, 2);
INSERT INTO public.form_params VALUES (9, 30, false, NULL, NULL, 'arr5', false, NULL, NULL, false, NULL, 5, 3);
INSERT INTO public.form_params VALUES (9, 31, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 7, 6);
INSERT INTO public.form_params VALUES (9, 36, false, NULL, NULL, 'arr5', false, NULL, NULL, false, NULL, 6, 5);
INSERT INTO public.form_params VALUES (9, 37, true, '// [test_g], [test_k], [pga], [[pgb]], [[pgd]], [pgc]
[[pgb]] * [pga] + [[pgd]] * [pgc]', 'pga,pgb,pgc,pgd', NULL, false, NULL, NULL, false, NULL, 2, 7);
INSERT INTO public.form_params VALUES (9, 38, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 3, 1);
INSERT INTO public.form_params VALUES (8, 39, false, NULL, NULL, 'arr5', false, NULL, NULL, false, NULL, 13, 11);
INSERT INTO public.form_params VALUES (8, 40, false, NULL, NULL, 'arr5', false, NULL, NULL, true, 0, 14, 12);
INSERT INTO public.form_params VALUES (1, 11, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 7, 6);
INSERT INTO public.form_params VALUES (8, 41, false, NULL, NULL, NULL, false, NULL, NULL, true, 0, 2, 1);
INSERT INTO public.form_params VALUES (7, 41, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 4, 2);
INSERT INTO public.form_params VALUES (8, 42, true, '// [test_g], [test_h], [[test_j]], [test_k], [pga], [pgc], [[pgb]], [[pgd]], [[pge]], [[pgf]]
IF([test_h],0,1) // equivalent for NOT', 'test_h', NULL, false, NULL, NULL, false, NULL, 5, 2);
INSERT INTO public.form_params VALUES (8, 43, true, '// [test_g], [test_h], [[test_j]], [test_k], [tlb], [pga], [pgc], [[pgb]], [[pgd]], [[pge]], [[pgf]]
IF([[pgf]],0,1) // equivalent for NOT', 'pgf', NULL, false, NULL, NULL, false, NULL, 6, 14);
INSERT INTO public.form_params VALUES (8, 44, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 7, 4);
INSERT INTO public.form_params VALUES (8, 45, false, NULL, NULL, NULL, false, NULL, NULL, false, NULL, 8, 5);
INSERT INTO public.form_params VALUES (10, 51, true, '// [mco_d1], [mco_d2], [mco_h1], [mco_h2], [mco_P]
pi = 3.141592653589793;
d = ([mco_d1] + [mco_d2]) / 2;
// h = ([mco_h1] + [mco_h2]) / 2;
A = pi * (d / 2)^2;
sigma = ([mco_P] * 1000) / A;
ROUND(sigma, 1)', 'mco_d1,mco_d2,mco_P', '', false, NULL, NULL, false, NULL, 1, 7);
INSERT INTO public.form_params VALUES (10, 50, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 7, 6);
INSERT INTO public.form_params VALUES (10, 49, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 6, 4);
INSERT INTO public.form_params VALUES (10, 52, true, '// [mco_d1], [mco_d2], [mco_h1], [mco_h2], [mco_P], [mco_sigma]
d = ([mco_d1] + [mco_d2]) / 2;
h = ([mco_h1] + [mco_h2]) / 2;
R = h / d;
ROUND(R, 1)', 'mco_d1,mco_d2,mco_h1,mco_h2', '', false, NULL, NULL, false, NULL, 2, 5);
INSERT INTO public.form_params VALUES (10, 46, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 3, 1);
INSERT INTO public.form_params VALUES (10, 47, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 4, 2);
INSERT INTO public.form_params VALUES (10, 48, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 5, 3);
INSERT INTO public.form_params VALUES (11, 55, true, '// [[tss_V]], [[tss_W]], [[tss_Xi]], [tss_RSD], [tss_n]
tss = AVG([[tss_Xi]]);
IF(tss >= 10, ROUND(tss), ROUND(tss, 1))', 'tss_Xi', '', false, NULL, NULL, false, NULL, 1, 4);
INSERT INTO public.form_params VALUES (11, 53, false, '', '', 'col1', false, NULL, NULL, false, NULL, 5, 1);
INSERT INTO public.form_params VALUES (11, 56, true, '// [[tss_V]], [[tss_W]], [[tss_Xi]], [tss_X], [tss_n]
// Squared deviations from the mean
sdm = ([[tss_Xi]] - [tss_X])^2;
//Sample Standard Deviation
s = SQRT(SUM(sdm) / ([tss_n] - 1));
rsd = (s / [tss_X]) * 100;
ROUND(rsd, 2)', 'tss_n,tss_X,tss_Xi', '', false, NULL, NULL, false, NULL, 2, 6);
INSERT INTO public.form_params VALUES (11, 54, false, '', '', 'col1', false, NULL, NULL, false, NULL, 6, 2);
INSERT INTO public.form_params VALUES (11, 57, true, '// [[tss_V]], [[tss_W]], [[tss_Xi]], [tss_X], [tss_RSD]
COUNT([[tss_Xi]])', 'tss_Xi', '', false, NULL, NULL, false, NULL, 3, 5);
INSERT INTO public.form_params VALUES (11, 58, true, '// [[tss_V]], [[tss_W]], [tss_X], [tss_RSD], [tss_n]
[[tss_W]] / [[tss_V]]', 'tss_V,tss_W', '', false, NULL, NULL, false, NULL, 4, 3);
INSERT INTO public.form_params VALUES (12, 60, false, '', '', 'grp1', false, NULL, NULL, false, NULL, 6, 2);
INSERT INTO public.form_params VALUES (12, 65, true, '// [[lod_m0]], [[lod_m1]], [[lod_m2]], [[lod_i]], [lod_X], [lod_s]
COUNT([[lod_i]])', 'lod_i', '', false, NULL, NULL, false, NULL, 4, 6);
INSERT INTO public.form_params VALUES (12, 59, false, '', '', 'grp1', false, NULL, NULL, false, NULL, 5, 1);
INSERT INTO public.form_params VALUES (12, 61, false, '', '', 'grp1', false, NULL, NULL, false, NULL, 7, 3);
INSERT INTO public.form_params VALUES (12, 62, true, '// [[lod_m0]], [[lod_m1]], [[lod_m2]], [lod_X], [lod_s], [lod_n]
sm = (([[lod_m1]] - [[lod_m2]]) / ([[lod_m1]] - [[lod_m0]])) * 100;
ROUND(sm, 2)', 'lod_m0,lod_m1,lod_m2', '', false, NULL, NULL, false, NULL, 1, 4);
INSERT INTO public.form_params VALUES (12, 64, true, '// [[lod_m0]], [[lod_m1]], [[lod_m2]], [[lod_i]], [lod_X], [lod_n]
sdm = ([[lod_i]] - [lod_X])^2;
s = SQRT(SUM(sdm) / ([lod_n] - 1));
ROUND(s, 3)', 'lod_i,lod_n,lod_X', '', false, NULL, NULL, false, NULL, 3, 7);
INSERT INTO public.form_params VALUES (12, 63, true, '// [[lod_m0]], [[lod_m1]], [[lod_m2]], [[lod_i]], [lod_s], [lod_n]
mm = AVG([[lod_i]]);
ROUND(mm, 2)', 'lod_i', '', false, NULL, NULL, false, NULL, 2, 5);
INSERT INTO public.form_params VALUES (13, 77, true, '// [[pca_H]], [[pca_A]], [[pca_B]], [[pca_C]], [[pca_G_mb]], [pca_MH], [[pca_MC]], [pca_s_c], [pca_n]
gmm = 2.460;
gmb = [[pca_A]] / ([[pca_B]] - [[pca_C]]);
ci = (gmb / gmm) * 100;
ROUND(ci, 4)', 'pca_A,pca_B,pca_C', '', false, NULL, NULL, false, NULL, 3, 7);
INSERT INTO public.form_params VALUES (13, 72, true, '// [[pca_H]], [[pca_A]], [[pca_B]], [[pca_C]], [[pca_G_mb]], [pca_MH], [[pca_MC]], [pca_s_c], [pca_n]
mh = AVG([[pca_H]]);
ROUND(mh, 1)', 'pca_H', '', false, NULL, NULL, false, NULL, 1, 2);
INSERT INTO public.form_params VALUES (13, 73, true, '// [[pca_H]], [[pca_A]], [[pca_B]], [[pca_C]], [[pca_G_mb]], [pca_MH], [[pca_MC]], [pca_s_c], [pca_n]
gmb = [[pca_A]] / ([[pca_B]] - [[pca_C]]);
ROUND(gmb, 3)', 'pca_A,pca_B,pca_C', '', false, NULL, NULL, false, NULL, 2, 6);
INSERT INTO public.form_params VALUES (13, 76, true, '// [[pca_H]], [[pca_A]], [[pca_B]], [[pca_C]], [[pca_G_mb]], [pca_MH], [[pca_C_i]], [pca_s_c], [pca_n]
mc = AVG([[pca_C_i]]);
ROUND(mc, 1)', 'pca_C_i', NULL, false, NULL, NULL, false, NULL, 4, 8);
INSERT INTO public.form_params VALUES (13, 74, true, '// [[pca_H]], [[pca_A]], [[pca_B]], [[pca_C]], [[pca_G_mb]], [pca_MH], [[pca_C_i]], [pca_MC], [pca_n]
sdm = ([[pca_C_i]] - [pca_MC])^2;
s = SQRT(SUM(sdm) / ([pca_n] - 1));
ROUND(s, 2)
', 'pca_C_i,pca_MC,pca_n', NULL, false, NULL, NULL, false, NULL, 5, 10);
INSERT INTO public.form_params VALUES (13, 75, true, '// [[pca_H]], [[pca_A]], [[pca_B]], [[pca_C]], [[pca_G_mb]], [pca_MH], [[pca_C_i]], [pca_MC], [pca_s_c]
COUNT([[pca_C_i]])', 'pca_C_i', NULL, false, NULL, NULL, false, NULL, 6, 9);
INSERT INTO public.form_params VALUES (13, 67, false, '', '', 'grp1', false, NULL, NULL, false, NULL, 8, 3);
INSERT INTO public.form_params VALUES (13, 68, false, '', '', 'grp1', false, NULL, NULL, false, NULL, 9, 4);
INSERT INTO public.form_params VALUES (13, 69, false, '', '', 'grp1', false, NULL, NULL, false, NULL, 10, 5);
INSERT INTO public.form_params VALUES (14, 81, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 4, 8);
INSERT INTO public.form_params VALUES (14, 80, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 3, 5);
INSERT INTO public.form_params VALUES (14, 78, false, NULL, '', NULL, true, '[value] >= 5000.0', '>= 5000.0', false, NULL, 1, 1);
INSERT INTO public.form_params VALUES (14, 79, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 2, 2);
INSERT INTO public.form_params VALUES (14, 86, true, '// [saa_M_initial], [saa_cw_1_inch], [saa_cw_3_4_inch], [saa_cw_no_4], [saa_cw_no_40], [saa_cw_no_200], [saa_cw_pan], [saa_Mi_1_inch], [saa_Mi_no_4], [saa_Mi_no_40], [saa_Mi_no_200], [saa_Mi_pan], [saa_PPi_1_inch], [saa_PPi_3_4_inch], [saa_PPi_no_4], [saa_PPi_no_40], [saa_PPi_no_200], [saa_loss], [saa_MV_3_4_inch], [saa_MV_no_4], [saa_MV_no_40], [saa_MV_no_200], [saa_MV_pan]
[saa_cw_3_4_inch] - [saa_cw_1_inch]', 'saa_cw_1_inch,saa_cw_3_4_inch', NULL, true, '[value] >= 0 && [value] <= 2000.0', '>= 0 and <= 2000.0', false, NULL, 9, 6);
INSERT INTO public.form_params VALUES (14, 87, true, '// [saa_M_initial], [saa_cw_1_inch], [saa_cw_3_4_inch], [saa_cw_no_4], [saa_cw_no_40], [saa_cw_no_200], [saa_cw_pan], [saa_Mi_1_inch], [saa_Mi_3_4_inch], [saa_Mi_no_40], [saa_Mi_no_200], [saa_Mi_pan], [saa_PPi_1_inch], [saa_PPi_3_4_inch], [saa_PPi_no_4], [saa_PPi_no_40], [saa_PPi_no_200], [saa_loss], [saa_MV_3_4_inch], [saa_MV_no_4], [saa_MV_no_40], [saa_MV_no_200], [saa_MV_pan]
[saa_cw_no_4] - [saa_cw_3_4_inch]', 'saa_cw_3_4_inch,saa_cw_no_4', NULL, true, '[value] >= 0 && [value] <= 2000.0', '>= 0 and <= 2000.0', false, NULL, 10, 9);
INSERT INTO public.form_params VALUES (14, 82, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 5, 11);
INSERT INTO public.form_params VALUES (14, 88, true, '// [saa_M_initial], [saa_cw_1_inch], [saa_cw_3_4_inch], [saa_cw_no_4], [saa_cw_no_40], [saa_cw_no_200], [saa_cw_pan], [saa_Mi_1_inch], [saa_Mi_3_4_inch], [saa_Mi_no_4], [saa_Mi_no_200], [saa_Mi_pan], [saa_PPi_1_inch], [saa_PPi_3_4_inch], [saa_PPi_no_4], [saa_PPi_no_40], [saa_PPi_no_200], [saa_loss], [saa_MV_3_4_inch], [saa_MV_no_4], [saa_MV_no_40], [saa_MV_no_200], [saa_MV_pan]
[saa_cw_no_40] - [saa_cw_no_4]', 'saa_cw_no_4,saa_cw_no_40', NULL, true, '[value] >= 0 && [value] <= 2000.0', '>= 0 and <= 2000.0', false, NULL, 11, 12);
INSERT INTO public.form_params VALUES (14, 83, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 6, 14);
INSERT INTO public.form_params VALUES (14, 84, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 7, 17);
INSERT INTO public.form_params VALUES (14, 91, true, '// [saa_M_initial], [saa_cw_1_inch], [saa_cw_3_4_inch], [saa_cw_no_4], [saa_cw_no_40], [saa_cw_no_200], [saa_cw_pan], [saa_Mi_1_inch], [saa_Mi_3_4_inch], [saa_Mi_no_4], [saa_Mi_no_40], [saa_Mi_no_200], [saa_Mi_pan], [saa_PPi_3_4_inch], [saa_PPi_no_4], [saa_PPi_no_40], [saa_PPi_no_200], [saa_loss]
ppi = (1 - [saa_cw_1_inch] / [saa_M_initial]) * 100;
ROUND(ppi)', 'saa_cw_1_inch,saa_M_initial', NULL, false, NULL, NULL, false, NULL, 14, 4);
INSERT INTO public.form_params VALUES (14, 96, true, '// [saa_M_initial], [saa_cw_1_inch], [saa_cw_3_4_inch], [saa_cw_no_4], [saa_cw_no_40], [saa_cw_no_200], [saa_cw_pan], [saa_Mi_1_inch], [saa_Mi_3_4_inch], [saa_Mi_no_4], [saa_Mi_no_40], [saa_Mi_no_200], [saa_Mi_pan], [saa_PPi_1_inch], [saa_PPi_3_4_inch], [saa_PPi_no_4], [saa_PPi_no_40], [saa_PPi_no_200]
loss = (([saa_M_initial] - [saa_cw_pan]) / [saa_M_initial]) * 100;
ROUND(loss, 2)', 'saa_cw_pan,saa_M_initial', NULL, true, '[value] >= 0 && [value] <= 0.30', '>= 0 and <= 0.30', false, NULL, 19, 19);
INSERT INTO public.form_params VALUES (14, 92, true, '// [saa_M_initial], [saa_cw_1_inch], [saa_cw_3_4_inch], [saa_cw_no_4], [saa_cw_no_40], [saa_cw_no_200], [saa_cw_pan], [saa_Mi_1_inch], [saa_Mi_3_4_inch], [saa_Mi_no_4], [saa_Mi_no_40], [saa_Mi_no_200], [saa_Mi_pan], [saa_PPi_1_inch], [saa_PPi_no_4], [saa_PPi_no_40], [saa_PPi_no_200], [saa_loss]
ppi = (1 - [saa_cw_3_4_inch] / [saa_M_initial]) * 100;
ROUND(ppi)', 'saa_cw_3_4_inch,saa_M_initial', NULL, false, NULL, NULL, false, NULL, 15, 7);
INSERT INTO public.form_params VALUES (14, 93, true, '// [saa_M_initial], [saa_cw_1_inch], [saa_cw_3_4_inch], [saa_cw_no_4], [saa_cw_no_40], [saa_cw_no_200], [saa_cw_pan], [saa_Mi_1_inch], [saa_Mi_3_4_inch], [saa_Mi_no_4], [saa_Mi_no_40], [saa_Mi_no_200], [saa_Mi_pan], [saa_PPi_1_inch], [saa_PPi_3_4_inch], [saa_PPi_no_40], [saa_PPi_no_200], [saa_loss]
ppi = (1 - [saa_cw_no_4] / [saa_M_initial]) * 100;
ROUND(ppi)', 'saa_cw_no_4,saa_M_initial', NULL, false, NULL, NULL, false, NULL, 16, 10);
INSERT INTO public.form_params VALUES (14, 94, true, '// [saa_M_initial], [saa_cw_1_inch], [saa_cw_3_4_inch], [saa_cw_no_4], [saa_cw_no_40], [saa_cw_no_200], [saa_cw_pan], [saa_Mi_1_inch], [saa_Mi_3_4_inch], [saa_Mi_no_4], [saa_Mi_no_40], [saa_Mi_no_200], [saa_Mi_pan], [saa_PPi_1_inch], [saa_PPi_3_4_inch], [saa_PPi_no_4], [saa_PPi_no_200], [saa_loss]
ppi = (1 - [saa_cw_no_40] / [saa_M_initial]) * 100;
ROUND(ppi)', 'saa_cw_no_40,saa_M_initial', NULL, false, NULL, NULL, false, NULL, 17, 13);
INSERT INTO public.form_params VALUES (14, 90, true, '// [saa_M_initial], [saa_cw_1_inch], [saa_cw_3_4_inch], [saa_cw_no_4], [saa_cw_no_40], [saa_cw_no_200], [saa_cw_pan], [saa_Mi_1_inch], [saa_Mi_3_4_inch], [saa_Mi_no_4], [saa_Mi_no_40], [saa_Mi_no_200], [saa_PPi_1_inch], [saa_PPi_3_4_inch], [saa_PPi_no_4], [saa_PPi_no_40], [saa_PPi_no_200], [saa_loss], [saa_MV_3_4_inch], [saa_MV_no_4], [saa_MV_no_40], [saa_MV_no_200], [saa_MV_pan]
[saa_cw_pan] - [saa_cw_no_200]', 'saa_cw_no_200,saa_cw_pan', NULL, true, '[value] >= 0 && [value] <= 2000.0', '>= 0 and <= 2000.0', false, NULL, 13, 18);
INSERT INTO public.form_params VALUES (14, 95, true, '// [saa_M_initial], [saa_cw_1_inch], [saa_cw_3_4_inch], [saa_cw_no_4], [saa_cw_no_40], [saa_cw_no_200], [saa_cw_pan], [saa_Mi_1_inch], [saa_Mi_3_4_inch], [saa_Mi_no_4], [saa_Mi_no_40], [saa_Mi_no_200], [saa_Mi_pan], [saa_PPi_1_inch], [saa_PPi_3_4_inch], [saa_PPi_no_4], [saa_PPi_no_40], [saa_loss]
ppi = (1 - [saa_cw_no_200] / [saa_M_initial]) * 100;
ROUND(ppi, 1)', 'saa_cw_no_200,saa_M_initial', NULL, false, NULL, NULL, false, NULL, 18, 16);
INSERT INTO public.form_params VALUES (13, 66, false, NULL, '', 'grp1', true, '[value] >= 45.0', '>= 45.0', false, NULL, 7, 1);
INSERT INTO public.form_params VALUES (14, 85, true, '// [saa_M_initial], [saa_cw_1_inch], [saa_cw_3_4_inch], [saa_cw_no_4], [saa_cw_no_40], [saa_cw_no_200], [saa_cw_pan], [saa_Mi_3_4_inch], [saa_Mi_no_4], [saa_Mi_no_40], [saa_Mi_no_200], [saa_Mi_pan], [saa_PPi_1_inch], [saa_PPi_3_4_inch], [saa_PPi_no_4], [saa_PPi_no_40], [saa_PPi_no_200], [saa_loss], [saa_MV_3_4_inch], [saa_MV_no_4], [saa_MV_no_40], [saa_MV_no_200], [saa_MV_pan]
[saa_cw_1_inch]', 'saa_cw_1_inch', NULL, true, '[value] >= 0 && [value] <= 2000.0', '>= 0 and <= 2000.0', false, NULL, 8, 3);
INSERT INTO public.form_params VALUES (14, 89, true, '// [saa_M_initial], [saa_cw_1_inch], [saa_cw_3_4_inch], [saa_cw_no_4], [saa_cw_no_40], [saa_cw_no_200], [saa_cw_pan], [saa_Mi_1_inch], [saa_Mi_3_4_inch], [saa_Mi_no_4], [saa_Mi_no_40], [saa_Mi_pan], [saa_PPi_1_inch], [saa_PPi_3_4_inch], [saa_PPi_no_4], [saa_PPi_no_40], [saa_PPi_no_200], [saa_loss], [saa_MV_3_4_inch], [saa_MV_no_4], [saa_MV_no_40], [saa_MV_no_200], [saa_MV_pan]
[saa_cw_no_200] - [saa_cw_no_40]', 'saa_cw_no_200,saa_cw_no_40', NULL, true, '[value] >= 0 && [value] <= 2000.0', '>= 0 and <= 2000.0', false, NULL, 12, 15);
INSERT INTO public.form_params VALUES (15, 110, true, '// [[fas_V_K2Cr2O7_initial]], [[fas_V_K2Cr2O7_final]], [[fas_V]], [fas_nm_K2Cr2O7], [[fas_M_i]], [fas_M], [fas_s], [fas_rsd], [env_temp], [env_rh]
MW_K2Cr2O7 = 294.185; // g/mol
V_flask = 0.25000; // L
m = [fas_nm_K2Cr2O7] / (MW_K2Cr2O7 * V_flask);
ROUND(m, 6)', 'fas_nm_K2Cr2O7', NULL, false, NULL, NULL, false, NULL, 6, 6);
INSERT INTO public.form_params VALUES (15, 111, true, '// [[fas_V_K2Cr2O7]], [[fas_V_K2Cr2O7_initial]], [[fas_V_K2Cr2O7_final]], [[fas_V]], [fas_nm_K2Cr2O7], [fas_M_K2Cr2O7], [fas_M], [fas_s], [fas_rsd], [env_temp], [env_rh]
M_i = (6 * [fas_M_K2Cr2O7] * [[fas_V_K2Cr2O7]]) / [[fas_V]];
ROUND(M_i, 6)', 'fas_M_K2Cr2O7,fas_V,fas_V_K2Cr2O7', NULL, false, NULL, NULL, false, NULL, 7, 7);
INSERT INTO public.form_params VALUES (15, 109, true, '// [[fas_V_K2Cr2O7_initial]], [[fas_V_K2Cr2O7_final]], [fas_nm_K2Cr2O7], [fas_M_K2Cr2O7], [[fas_M_i]], [fas_M], [fas_s], [fas_rsd], [env_temp], [env_rh]
[[fas_V_K2Cr2O7_final]] - [[fas_V_K2Cr2O7_initial]]', 'fas_V_K2Cr2O7_final,fas_V_K2Cr2O7_initial', NULL, false, NULL, NULL, false, NULL, 4, 4);
INSERT INTO public.form_params VALUES (15, 115, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 5, 5);
INSERT INTO public.form_params VALUES (15, 116, false, NULL, '', 'grp1', false, NULL, NULL, false, NULL, 1, 1);
INSERT INTO public.form_params VALUES (15, 107, false, NULL, '', 'grp1', false, NULL, NULL, false, NULL, 2, 2);
INSERT INTO public.form_params VALUES (15, 108, false, NULL, '', 'grp1', false, NULL, NULL, false, NULL, 3, 3);
INSERT INTO public.form_params VALUES (15, 112, true, '// [[fas_V_K2Cr2O7]], [[fas_V_K2Cr2O7_initial]], [[fas_V_K2Cr2O7_final]], [[fas_V]], [fas_nm_K2Cr2O7], [fas_M_K2Cr2O7], [[fas_M_i]], [fas_s], [fas_rsd], [env_temp], [env_rh]
AVG([[fas_M_i]])', 'fas_M_i', NULL, false, NULL, NULL, false, NULL, 8, 8);
INSERT INTO public.form_params VALUES (15, 113, true, '// [[fas_V_K2Cr2O7]], [[fas_V_K2Cr2O7_initial]], [[fas_V_K2Cr2O7_final]], [[fas_V]], [fas_nm_K2Cr2O7], [fas_M_K2Cr2O7], [[fas_M_i]], [fas_M], [fas_rsd], [env_temp], [env_rh]
sdm = ([[fas_M_i]] - [fas_M])^2;
n = COUNT([[fas_M_i]]);
s = SQRT(SUM(sdm) / (n - 1));
ROUND(s, 8)
', 'fas_M,fas_M_i', NULL, false, NULL, NULL, false, NULL, 10, 9);
INSERT INTO public.form_params VALUES (15, 114, true, '// [[fas_V_K2Cr2O7]], [[fas_V_K2Cr2O7_initial]], [[fas_V_K2Cr2O7_final]], [[fas_V]], [fas_nm_K2Cr2O7], [fas_M_K2Cr2O7], [[fas_M_i]], [fas_M], [fas_s], [env_temp], [env_rh]
rsd = ([fas_s] / [fas_M]) * 100;
ROUND(rsd, 2)', 'fas_M,fas_s', NULL, true, '[value] <= 0.5', '<= 0.5', false, NULL, 11, 10);
INSERT INTO public.form_params VALUES (15, 102, false, NULL, '', NULL, true, '[value] >= 20.0 && [value] <= 25.0', '>= 20.0 and <= 25.0', true, NULL, 12, 12);
INSERT INTO public.form_params VALUES (15, 103, false, NULL, '', NULL, true, '[value] >= 30.0 && [value] <= 65.0', '>= 30.0 and <= 65.0', true, NULL, 13, 13);
INSERT INTO public.form_params VALUES (15, 117, true, '// [[fas_V_K2Cr2O7]], [[fas_V_K2Cr2O7_initial]], [[fas_V_K2Cr2O7_final]], [[fas_V]], [fas_nm_K2Cr2O7], [fas_M_K2Cr2O7], [[fas_M_i]], [fas_M], [fas_s], [fas_rsd], [env_temp], [env_rh]
COUNT([[fas_M_i]])', 'fas_M_i', NULL, true, '[value] >= 3', '>= 3', false, NULL, 9, 11);
INSERT INTO public.form_params VALUES (16, 121, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 4, 8);
INSERT INTO public.form_params VALUES (16, 122, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 5, 9);
INSERT INTO public.form_params VALUES (16, 123, false, NULL, '', 'grp1', false, NULL, NULL, false, NULL, 6, 10);
INSERT INTO public.form_params VALUES (16, 126, true, '// [dcr_m1], [dcr_m2], [dcr_V_flask], [dcr_M_FAS], [dcr_V_dig], [[dcr_V_init]], [[dcr_V_final]], [[dcr_V_FAS_i]], [dcr_V_FAS], [dcr_N_grav], [dcr_n], [dcr_Bias], [dcr_s], [dcr_RSD], [env_temp], [env_rh], [env_airvel]
m_net = [dcr_m2] - [dcr_m1];
MW_K2Cr2O7 = 294.185; // g/mol
M_grav = m_net / (MW_K2Cr2O7 * [dcr_V_flask]);
ROUND(M_grav, 7)', 'dcr_m1,dcr_m2,dcr_V_flask', NULL, false, NULL, NULL, false, NULL, 10, 4);
INSERT INTO public.form_params VALUES (16, 127, true, '// [dcr_m1], [dcr_m2], [dcr_V_flask], [dcr_M_FAS], [dcr_V_dig], [[dcr_V_init]], [[dcr_V_final]], [[dcr_V_FAS_i]], [dcr_V_FAS], [dcr_M_grav], [dcr_n], [dcr_Bias], [dcr_s], [dcr_RSD], [env_temp], [env_rh], [env_airvel]
N_grav = 6 * [dcr_M_grav];
ROUND(N_grav, 6)
', 'dcr_M_grav', NULL, false, NULL, NULL, false, NULL, 11, 5);
INSERT INTO public.form_params VALUES (16, 102, false, NULL, '', NULL, true, '[value] >= 17.0 && [value] <= 23.0', '>= 17.0 and <= 23.0', false, NULL, 20, 20);
INSERT INTO public.form_params VALUES (16, 103, false, NULL, '', NULL, true, '[value] >= 30.0 && [value] <= 60.0', '>= 30.0 and <= 60.0', false, NULL, 21, 21);
INSERT INTO public.form_params VALUES (16, 129, true, '// [dcr_m1], [dcr_m2], [dcr_V_flask], [dcr_M_FAS], [dcr_V_dig], [[dcr_V_init]], [[dcr_V_final]], [[dcr_V_FAS_i]], [dcr_V_FAS], [dcr_M_grav], [dcr_N_grav], [dcr_M_titr], [dcr_N_titr], [dcr_Bias], [dcr_M_cert], [dcr_N_cert], [dcr_n], [dcr_RSD], [env_temp], [env_rh], [env_airvel]
sdm = ([[dcr_V_FAS_i]] - [dcr_V_FAS])^2;
s = SQRT(SUM(sdm) / ([dcr_n] - 1));
s', 'dcr_n,dcr_V_FAS,dcr_V_FAS_i', NULL, false, NULL, NULL, false, NULL, 18, 17);
INSERT INTO public.form_params VALUES (16, 130, true, '// [dcr_m1], [dcr_m2], [dcr_V_flask], [dcr_M_FAS], [dcr_V_dig], [[dcr_V_init]], [[dcr_V_final]], [[dcr_V_FAS_i]], [dcr_V_FAS], [dcr_M_grav], [dcr_N_grav], [dcr_Bias], [dcr_s], [dcr_RSD], [env_temp], [env_rh], [env_airvel]
COUNT([[dcr_V_FAS_i]])', 'dcr_V_FAS_i', NULL, true, '[value] >= 3', '>= 3', false, NULL, 17, 16);
INSERT INTO public.form_params VALUES (16, 124, false, NULL, '', 'grp1', false, NULL, NULL, false, NULL, 7, 11);
INSERT INTO public.form_params VALUES (16, 118, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 1, 1);
INSERT INTO public.form_params VALUES (16, 119, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 2, 2);
INSERT INTO public.form_params VALUES (16, 120, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 3, 3);
INSERT INTO public.form_params VALUES (16, 125, true, '// [dcr_m1], [dcr_m2], [dcr_V_flask], [dcr_M_FAS], [dcr_V_dig], [[dcr_V_init]], [[dcr_V_final]], [dcr_V_FAS], [dcr_M_grav], [dcr_N_grav], [dcr_n], [dcr_Bias], [dcr_s], [dcr_RSD], [env_temp], [env_rh], [env_airvel]
[[dcr_V_final]] - [[dcr_V_init]]', 'dcr_V_final,dcr_V_init', NULL, false, NULL, NULL, false, NULL, 8, 12);
INSERT INTO public.form_params VALUES (16, 128, true, '// [dcr_m1], [dcr_m2], [dcr_V_flask], [dcr_M_FAS], [dcr_V_dig], [[dcr_V_init]], [[dcr_V_final]], [[dcr_V_FAS_i]], [dcr_V_FAS], [dcr_M_grav], [dcr_N_grav], [dcr_M_titr], [dcr_N_titr], [dcr_M_cert], [dcr_N_cert], [dcr_n], [dcr_s], [dcr_RSD], [env_temp], [env_rh], [env_airvel]
bias = IF([dcr_M_titr] >= [dcr_M_grav], [dcr_M_titr] - [dcr_M_grav], [dcr_M_grav] - [dcr_M_titr]) / [dcr_M_grav];
bias = bias * 100;
ROUND(bias, 4)', 'dcr_M_grav,dcr_M_titr', NULL, true, '[value] <= 0.5', '<= 0.5', false, NULL, 14, 15);
INSERT INTO public.form_params VALUES (16, 131, true, '// [dcr_m1], [dcr_m2], [dcr_V_flask], [dcr_M_FAS], [dcr_V_dig], [[dcr_V_init]], [[dcr_V_final]], [[dcr_V_FAS_i]], [dcr_V_FAS], [dcr_M_grav], [dcr_N_grav], [dcr_M_titr], [dcr_N_titr], [dcr_Bias], [dcr_M_cert], [dcr_N_cert], [dcr_n], [dcr_s], [env_temp], [env_rh], [env_airvel]
rsd = [dcr_s] / [dcr_V_FAS] * 100;
rsd', 'dcr_s,dcr_V_FAS', NULL, true, '[value] <= 0.5', '<= 0.5', false, NULL, 19, 18);
INSERT INTO public.form_params VALUES (16, 132, true, '// [dcr_m1], [dcr_m2], [dcr_V_flask], [dcr_M_FAS], [dcr_V_dig], [[dcr_V_init]], [[dcr_V_final]], [[dcr_V_FAS_i]], [dcr_M_grav], [dcr_N_grav], [dcr_n], [dcr_Bias], [dcr_s], [dcr_RSD], [env_temp], [env_rh], [env_airvel]
AVG([[dcr_V_FAS_i]])', 'dcr_V_FAS_i', NULL, false, NULL, NULL, false, NULL, 9, 13);
INSERT INTO public.form_params VALUES (16, 133, true, '// [dcr_m1], [dcr_m2], [dcr_V_flask], [dcr_M_FAS], [dcr_V_dig], [[dcr_V_init]], [[dcr_V_final]], [[dcr_V_FAS_i]], [dcr_V_FAS], [dcr_M_grav], [dcr_N_grav], [dcr_N_titr], [dcr_Bias], [dcr_M_cert], [dcr_N_cert], [dcr_n], [dcr_s], [dcr_RSD], [env_temp], [env_rh], [env_airvel]
M_titr = [dcr_M_FAS] * [dcr_V_FAS] / (6 * [dcr_V_dig]);
M_titr', 'dcr_M_FAS,dcr_V_dig,dcr_V_FAS', NULL, false, NULL, NULL, false, NULL, 12, 14);
INSERT INTO public.form_params VALUES (16, 135, true, '// [dcr_m1], [dcr_m2], [dcr_V_flask], [dcr_M_FAS], [dcr_V_dig], [[dcr_V_init]], [[dcr_V_final]], [[dcr_V_FAS_i]], [dcr_V_FAS], [dcr_M_grav], [dcr_N_grav], [dcr_M_titr], [dcr_N_titr], [dcr_Bias], [dcr_N_cert], [dcr_n], [dcr_s], [dcr_RSD], [env_temp], [env_rh], [env_airvel]
ROUND([dcr_M_grav], 4)', 'dcr_M_grav', NULL, false, NULL, NULL, false, NULL, 15, 7);
INSERT INTO public.form_params VALUES (16, 136, true, '// [dcr_m1], [dcr_m2], [dcr_V_flask], [dcr_M_FAS], [dcr_V_dig], [[dcr_V_init]], [[dcr_V_final]], [[dcr_V_FAS_i]], [dcr_V_FAS], [dcr_M_grav], [dcr_N_grav], [dcr_M_titr], [dcr_N_titr], [dcr_Bias], [dcr_M_cert], [dcr_n], [dcr_s], [dcr_RSD], [env_temp], [env_rh], [env_airvel]
ROUND([dcr_N_grav], 4)', 'dcr_N_grav', NULL, false, NULL, NULL, false, NULL, 16, 6);
INSERT INTO public.form_params VALUES (17, 140, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 4, 4);
INSERT INTO public.form_params VALUES (16, 104, false, NULL, '', NULL, true, '[value] >= 0.4 && [value] <= 0.6', '>= 0.4 and <= 0.6', false, NULL, 22, 22);
INSERT INTO public.form_params VALUES (17, 141, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 5, 5);
INSERT INTO public.form_params VALUES (17, 105, true, '// [cod_V_sample], [cod_V_B], [cod_V_S], [cod_V_STD], [cod_M_FAS], [cod_recovery], [env_temp], [env_rh], [env_airvel]
cod = ([cod_V_B] - [cod_V_S]) * [cod_M_FAS] * 8000 / [cod_V_sample];
ROUND(cod, 1)', 'cod_M_FAS,cod_V_B,cod_V_S,cod_V_sample', NULL, false, NULL, NULL, false, NULL, 6, 6);
INSERT INTO public.form_params VALUES (17, 102, false, NULL, '', NULL, true, '[value] >= 17.0 && [value] <= 23.0', '>= 17.0 and <= 23.0', false, NULL, 8, 8);
INSERT INTO public.form_params VALUES (17, 143, true, '// [cod_V_sample], [cod_V_B], [cod_V_S], [cod_V_STD], [cod_M_FAS], [cod], [env_temp], [env_rh], [env_airvel]
cod_target = 500; // mg/L O2
cod_measured = ([cod_V_B] - [cod_V_STD]) * [cod_M_FAS] * 8000 / [cod_V_sample];
recovery = (cod_measured / cod_target) * 100;
recovery', 'cod_M_FAS,cod_V_B,cod_V_sample,cod_V_STD', NULL, true, '[value] >= 95.0 && [value] <= 105.0', '>= 95.0 and <= 105.0', false, NULL, 7, 7);
INSERT INTO public.form_params VALUES (17, 103, false, NULL, '', NULL, true, '[value] >= 40.0 && [value] <= 65.0', '>= 40.0 and <= 65.0', false, NULL, 9, 9);
INSERT INTO public.form_params VALUES (17, 104, false, NULL, '', NULL, true, '[value] >= 0.40 && [value] <= 0.60', '>= 0.40 and <= 0.60', false, NULL, 10, 10);
INSERT INTO public.form_params VALUES (17, 137, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 1, 1);
INSERT INTO public.form_params VALUES (17, 138, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 2, 2);
INSERT INTO public.form_params VALUES (17, 139, false, NULL, '', NULL, false, NULL, NULL, false, NULL, 3, 3);


--
-- Data for Name: forms; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (8, 8, 'v1', 10, false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (9, 8, 'v2', 10, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (1, 1, 'v0', 10, true, 'TestingFormA', true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 16:41:53.493203+02', 'Qui quis eum blanditiis accusantium accusamus.', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (2, 2, 'v0', 10, false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 16:43:14.869321+02', 'Sequi veritatis distinctio delectus atque nesciunt fugit.
Aliquam placeat iste qui unde eaque.', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (3, 3, 'v0', 10, false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 16:47:43.20068+02', '- Atque quisquam inventore labore a eaque
- Consectetur consectetur incidunt deleniti mollitia sint', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (4, 4, 'v0', 10, false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 17:00:21.39342+02', '- Accusamus quas id asperiores placeat voluptatem
- Atque ex facilis non magni error quis', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (5, 5, 'v0', 10, false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 17:46:34.396668+02', '- Assumenda eligendi illum voluptatum perspiciatis vel
- Harum soluta nihil excepturi
- Vero quidem alias tempora', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (6, 6, 'v0', 10, false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 17:48:50.759892+02', '- Itaque veniam consequuntur ipsa 
- Saepe error vel voluptas laborum dolore
- Nesciunt sed quibusdam molestiae non ', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (7, 8, 'v0', 10, false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 18:03:04.415193+02', 'Occaecati iusto explicabo excepturi beatae quibusdam', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (10, 9, 'Rev. 3', 10, false, NULL, true, 1, '2026-07-06 04:48:51.328592+03', NULL, true, 1, '2026-07-06 17:47:12.555158+03', 'Occaecati iusto explicabo excepturi beatae quibusdam', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (11, 10, 'v0', 10, false, NULL, true, 1, '2026-07-07 18:33:55.310236+03', NULL, true, 1, '2026-07-07 19:13:30.471004+03', 'Officia dignissimos tempora commodi est sunt saepe veniam recusandae ex fuga id', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (12, 11, 'v0', 10, false, NULL, true, 1, '2026-07-09 16:17:27.170738+03', NULL, true, 1, '2026-07-09 16:34:18.790669+03', 'Officia dignissimos tempora commodi est sunt saepe veniam recusandae ex fuga id', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (14, 13, 'v0', 10, false, NULL, true, 1, '2026-07-17 20:04:53.080888+03', NULL, true, 1, '2026-07-17 21:57:56.002485+03', 'Officia dignissimos tempora commodi est sunt saepe veniam recusandae ex fuga id', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (13, 12, 'v0', 10, false, NULL, true, 1, '2026-07-11 22:12:27.54704+03', NULL, true, 1, '2026-08-10 14:57:09.819953+03', 'Officia dignissimos tempora commodi est sunt saepe veniam recusandae ex fuga id', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (15, 14, 'v0', 10, false, NULL, true, 1, '2026-09-12 15:48:52.634305+03', NULL, true, 1, '2026-09-14 19:38:36.184043+03', 'Occaecati iusto explicabo excepturi beatae quibusdam', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (16, 15, 'v0', 10, false, NULL, true, 1, '2026-09-16 17:50:48.157858+03', NULL, true, 1, '2026-09-16 21:23:10.803475+03', 'Consequuntur iusto optio impedit iusto nihil quia', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (17, 16, 'v0', 10, false, NULL, true, 1, '2026-09-17 12:28:09.548804+03', NULL, true, 1, '2026-09-17 12:58:58.028836+03', 'Excepturi beatae quibusdam', false, NULL, NULL, NULL);


--
-- Data for Name: material_tests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.material_tests VALUES (4, 1);
INSERT INTO public.material_tests VALUES (4, 4);
INSERT INTO public.material_tests VALUES (4, 5);
INSERT INTO public.material_tests VALUES (21, 2);
INSERT INTO public.material_tests VALUES (21, 3);
INSERT INTO public.material_tests VALUES (21, 5);
INSERT INTO public.material_tests VALUES (1, 3);
INSERT INTO public.material_tests VALUES (1, 2);
INSERT INTO public.material_tests VALUES (2, 3);
INSERT INTO public.material_tests VALUES (2, 4);
INSERT INTO public.material_tests VALUES (2, 1);
INSERT INTO public.material_tests VALUES (3, 4);
INSERT INTO public.material_tests VALUES (3, 5);
INSERT INTO public.material_tests VALUES (6, 5);
INSERT INTO public.material_tests VALUES (6, 4);
INSERT INTO public.material_tests VALUES (6, 1);
INSERT INTO public.material_tests VALUES (7, 3);
INSERT INTO public.material_tests VALUES (7, 2);
INSERT INTO public.material_tests VALUES (15, 5);
INSERT INTO public.material_tests VALUES (15, 4);
INSERT INTO public.material_tests VALUES (15, 1);
INSERT INTO public.material_tests VALUES (9, 3);
INSERT INTO public.material_tests VALUES (9, 1);
INSERT INTO public.material_tests VALUES (14, 1);
INSERT INTO public.material_tests VALUES (14, 2);
INSERT INTO public.material_tests VALUES (14, 3);
INSERT INTO public.material_tests VALUES (14, 5);
INSERT INTO public.material_tests VALUES (18, 3);
INSERT INTO public.material_tests VALUES (18, 4);
INSERT INTO public.material_tests VALUES (18, 5);
INSERT INTO public.material_tests VALUES (17, 1);
INSERT INTO public.material_tests VALUES (17, 2);
INSERT INTO public.material_tests VALUES (17, 4);
INSERT INTO public.material_tests VALUES (17, 5);
INSERT INTO public.material_tests VALUES (19, 1);
INSERT INTO public.material_tests VALUES (19, 3);
INSERT INTO public.material_tests VALUES (19, 4);
INSERT INTO public.material_tests VALUES (19, 5);
INSERT INTO public.material_tests VALUES (20, 5);
INSERT INTO public.material_tests VALUES (20, 3);
INSERT INTO public.material_tests VALUES (20, 2);
INSERT INTO public.material_tests VALUES (5, 3);
INSERT INTO public.material_tests VALUES (5, 4);
INSERT INTO public.material_tests VALUES (5, 28);
INSERT INTO public.material_tests VALUES (5, 37);
INSERT INTO public.material_tests VALUES (5, 38);
INSERT INTO public.material_tests VALUES (5, 41);
INSERT INTO public.material_tests VALUES (4, 2);
INSERT INTO public.material_tests VALUES (4, 3);
INSERT INTO public.material_tests VALUES (2, 2);
INSERT INTO public.material_tests VALUES (3, 1);
INSERT INTO public.material_tests VALUES (3, 2);
INSERT INTO public.material_tests VALUES (3, 3);
INSERT INTO public.material_tests VALUES (4, 28);
INSERT INTO public.material_tests VALUES (5, 42);
INSERT INTO public.material_tests VALUES (5, 43);
INSERT INTO public.material_tests VALUES (5, 44);
INSERT INTO public.material_tests VALUES (5, 45);
INSERT INTO public.material_tests VALUES (11, 1);
INSERT INTO public.material_tests VALUES (11, 2);
INSERT INTO public.material_tests VALUES (11, 3);
INSERT INTO public.material_tests VALUES (11, 4);
INSERT INTO public.material_tests VALUES (11, 5);
INSERT INTO public.material_tests VALUES (22, 51);
INSERT INTO public.material_tests VALUES (22, 52);
INSERT INTO public.material_tests VALUES (23, 55);
INSERT INTO public.material_tests VALUES (23, 56);
INSERT INTO public.material_tests VALUES (23, 57);
INSERT INTO public.material_tests VALUES (24, 62);
INSERT INTO public.material_tests VALUES (24, 63);
INSERT INTO public.material_tests VALUES (24, 64);
INSERT INTO public.material_tests VALUES (24, 65);
INSERT INTO public.material_tests VALUES (25, 66);
INSERT INTO public.material_tests VALUES (25, 72);
INSERT INTO public.material_tests VALUES (25, 73);
INSERT INTO public.material_tests VALUES (25, 74);
INSERT INTO public.material_tests VALUES (25, 75);
INSERT INTO public.material_tests VALUES (25, 76);
INSERT INTO public.material_tests VALUES (26, 78);
INSERT INTO public.material_tests VALUES (26, 85);
INSERT INTO public.material_tests VALUES (26, 86);
INSERT INTO public.material_tests VALUES (26, 87);
INSERT INTO public.material_tests VALUES (26, 88);
INSERT INTO public.material_tests VALUES (26, 89);
INSERT INTO public.material_tests VALUES (26, 90);
INSERT INTO public.material_tests VALUES (26, 91);
INSERT INTO public.material_tests VALUES (26, 92);
INSERT INTO public.material_tests VALUES (26, 93);
INSERT INTO public.material_tests VALUES (26, 94);
INSERT INTO public.material_tests VALUES (26, 95);
INSERT INTO public.material_tests VALUES (26, 96);
INSERT INTO public.material_tests VALUES (27, 102);
INSERT INTO public.material_tests VALUES (27, 103);
INSERT INTO public.material_tests VALUES (27, 112);
INSERT INTO public.material_tests VALUES (27, 114);
INSERT INTO public.material_tests VALUES (27, 117);
INSERT INTO public.material_tests VALUES (32, 102);
INSERT INTO public.material_tests VALUES (32, 103);
INSERT INTO public.material_tests VALUES (32, 104);
INSERT INTO public.material_tests VALUES (32, 128);
INSERT INTO public.material_tests VALUES (32, 129);
INSERT INTO public.material_tests VALUES (32, 130);
INSERT INTO public.material_tests VALUES (32, 131);
INSERT INTO public.material_tests VALUES (32, 135);
INSERT INTO public.material_tests VALUES (32, 136);
INSERT INTO public.material_tests VALUES (40, 102);
INSERT INTO public.material_tests VALUES (40, 103);
INSERT INTO public.material_tests VALUES (40, 104);
INSERT INTO public.material_tests VALUES (40, 105);
INSERT INTO public.material_tests VALUES (40, 143);
INSERT INTO public.material_tests VALUES (23, 102);
INSERT INTO public.material_tests VALUES (23, 103);
INSERT INTO public.material_tests VALUES (23, 104);
INSERT INTO public.material_tests VALUES (23, 105);
INSERT INTO public.material_tests VALUES (23, 143);
INSERT INTO public.material_tests VALUES (40, 55);
INSERT INTO public.material_tests VALUES (40, 56);
INSERT INTO public.material_tests VALUES (40, 57);


--
-- Data for Name: materials; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (1, 'Material A', 'MA', 'Description for Material A', 2, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (2, 'Material B', 'MB', 'Description for Material B', 4, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (3, 'Material C', 'MC', 'Description for Material C', 1, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (4, 'Material D', 'MD', 'Description for Material D', 3, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (5, 'Material E', 'ME', 'Description for Material E', 1, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (6, 'Material F', 'NF', 'Description for Material F', 2, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (7, 'Material G', 'MG', 'Description for Material G', 3, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (8, 'Material H', 'MH', 'Description for Material H', 3, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (9, 'Material I', 'MI', 'Description for Material I', 4, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (10, 'Material J', 'MJ', 'Description for Material J', 4, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (11, 'Material K', 'MK', 'Description for Material K', 4, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', true, '2026-01-23 22:43:26.698445+02', 'Some explanations ...');
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (12, 'Material L', 'ML', 'Description for Material L', 1, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (13, 'Material M', 'MM', 'Description for Material M', 1, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (14, 'Material N', 'MN', 'Description for Material N', 2, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (15, 'Material O', 'MO', 'Description for Material O', 4, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (16, 'Material P', 'MP', 'Description for Material P', 3, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (17, 'Material Q', 'MQ', 'Description for Material Q', 3, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (18, 'Material R', 'MR', 'Description for Material R', 1, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (19, 'Material S', 'MS', 'Description for Material S', 2, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (20, 'Material T', 'MT', 'Description for Material T', 4, false, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (21, 'Finished Product A', 'FPA', 'A product made from various materials', 3, true, false, false, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (22, 'Concrete TS', 'CTS', 'Description for Concrete TS', 6, true, false, false, NULL, '2026-07-06 15:04:17.472048+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (24, 'Citric Acid Anhydrous', 'CAA', 'Occaecati iusto explicabo excepturi beatae quibusdam', 8, false, true, false, NULL, '2026-07-09 16:36:08.376573+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (25, 'Pavement Cors', 'PC', 'Excepturi beatae quibusdam', 10, false, false, false, NULL, '2026-07-11 22:47:51.622353+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (26, 'Aggregate TC', 'TC', 'Occaecati iusto explicabo excepturi beatae quibusdam', 12, false, true, false, NULL, '2026-07-17 20:35:52.843489+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (31, 'Type I Ultrapure Water', 'H2O01', 'ASTM Type I Ultrapure Water (18.2 MΩ·cm)', NULL, false, false, true, '7732-18-5', '2026-09-09 12:41:39.363522+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (33, 'Catalyst Reagent Ag2SO4/H2SO4', 'COD02', 'Silver sulfate catalyst solution in sulfuric acid', NULL, false, false, true, '10294-26-5', '2026-09-09 16:35:09.369281+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (34, 'KHP Check Standard 500mg/L', 'COD04', 'Potassium hydrogen phthalate standard (500 mg/L O2)', NULL, false, false, true, '877-24-7', '2026-09-09 16:35:09.37007+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (35, 'Distilled Water Blank', 'COD05', 'Reagent grade distilled water for blanks and dilutions', NULL, false, false, true, '7732-18-5', '2026-09-09 16:35:09.371781+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (36, 'Ferrous Ammonium Sulfate', 'FAS02', 'Ferrous ammonium sulfate hexahydrate, ACS reagent grade for in-house titrant preparation', NULL, false, true, true, '7783-85-9', '2026-09-09 16:50:16.129883+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (28, 'Potassium Dichromate K2Cr2O7 (99.98 %)', 'PDC01', 'ACS Primary Standard Grade (99.98% purity)', NULL, false, false, true, '7778-50-9', '2026-09-09 12:41:39.363522+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (29, 'Sulfuric Acid H2SO4 (98.0%)', 'H2SO4', 'Concentrated Sulfuric Acid (98.0% ACS Grade)', NULL, false, false, true, '7664-93-9', '2026-09-09 12:41:39.363522+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (30, 'Ferroin Indicator Solution (0.025 M)', 'FER01', '0.025 M 1,10-Phenanthroline Ferrous Sulfate', NULL, false, false, true, '14634-91-5', '2026-09-09 12:41:39.363522+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (38, 'Mercuric Sulfate', 'HGSO4', 'Mercuric Sulfate ACS Grade Powder', NULL, false, false, true, '7783-35-9', '2026-09-15 20:29:23.883828+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (39, 'Ultrapure Water', 'H2OUP', 'Ultrapure Water 18.2 MΩ·cm at 25.0°C', NULL, false, false, true, '7732-18-5', '2026-09-15 20:29:23.884648+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (27, 'FAS Titrant Solution (0.1 M)', 'FAS01', 'Ferrous ammonium sulfate titrant solution (~0.1000 M) for COD determination', 13, false, false, true, '7783-85-9', '2026-09-09 12:41:39.363522+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (32, 'Digestion Solution K2Cr2O7 (0.25 N)', 'COD01', 'Potassium dichromate digestion solution (0.04167 M/0.2500 N)', 13, false, false, true, '7778-50-9', '2026-09-09 16:35:09.354516+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (40, 'Wastewater Treatment Plant Effluent', 'WWTPE', 'Wastewater Treatment Plant Effluent', 13, false, false, false, NULL, '2026-09-17 13:01:00.266391+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (23, 'Outfall Pipeline #4', 'OP4', 'Wastewater Treatment Plant Effluent - Outfall Pipeline #4', 7, false, false, false, NULL, '2026-07-07 19:19:57.222801+03', false, NULL, NULL);


--
-- Data for Name: measurement_equipments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.measurement_equipments VALUES (59, 4);
INSERT INTO public.measurement_equipments VALUES (59, 19);
INSERT INTO public.measurement_equipments VALUES (59, 23);
INSERT INTO public.measurement_equipments VALUES (60, 19);
INSERT INTO public.measurement_equipments VALUES (60, 20);
INSERT INTO public.measurement_equipments VALUES (60, 23);
INSERT INTO public.measurement_equipments VALUES (60, 24);
INSERT INTO public.measurement_equipments VALUES (60, 25);
INSERT INTO public.measurement_equipments VALUES (60, 26);
INSERT INTO public.measurement_equipments VALUES (60, 27);
INSERT INTO public.measurement_equipments VALUES (61, 16);
INSERT INTO public.measurement_equipments VALUES (61, 17);
INSERT INTO public.measurement_equipments VALUES (61, 18);
INSERT INTO public.measurement_equipments VALUES (61, 19);
INSERT INTO public.measurement_equipments VALUES (61, 20);


--
-- Data for Name: measurement_params; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.measurement_params VALUES (41, 7, 31, 0, 534, NULL);
INSERT INTO public.measurement_params VALUES (42, 8, 28, 0, 740, NULL);
INSERT INTO public.measurement_params VALUES (42, 8, 38, 0, 4, NULL);
INSERT INTO public.measurement_params VALUES (42, 8, 29, 0, 456, NULL);
INSERT INTO public.measurement_params VALUES (42, 8, 30, 0, 555, NULL);
INSERT INTO public.measurement_params VALUES (42, 8, 30, 1, 777, NULL);
INSERT INTO public.measurement_params VALUES (42, 8, 30, 2, 888, NULL);
INSERT INTO public.measurement_params VALUES (42, 8, 36, 0, 555, NULL);
INSERT INTO public.measurement_params VALUES (42, 8, 36, 1, 777, NULL);
INSERT INTO public.measurement_params VALUES (42, 8, 36, 2, 888, NULL);
INSERT INTO public.measurement_params VALUES (42, 8, 39, 0, 1, NULL);
INSERT INTO public.measurement_params VALUES (42, 8, 39, 1, 2, NULL);
INSERT INTO public.measurement_params VALUES (42, 8, 39, 2, 3, NULL);
INSERT INTO public.measurement_params VALUES (42, 8, 40, 0, 1, NULL);
INSERT INTO public.measurement_params VALUES (9, 3, 3, 0, 8, NULL);
INSERT INTO public.measurement_params VALUES (9, 3, 19, 0, 456.7, NULL);
INSERT INTO public.measurement_params VALUES (9, 3, 1, 0, 3653.6, NULL);
INSERT INTO public.measurement_params VALUES (9, 3, 2, 0, 464.7, NULL);
INSERT INTO public.measurement_params VALUES (18, 3, 3, 0, 23, NULL);
INSERT INTO public.measurement_params VALUES (18, 3, 19, 0, 456.7, NULL);
INSERT INTO public.measurement_params VALUES (18, 3, 1, 0, 10504.1, NULL);
INSERT INTO public.measurement_params VALUES (18, 3, 2, 0, 479.7, NULL);
INSERT INTO public.measurement_params VALUES (6, 1, 6, 0, 3645640, NULL);
INSERT INTO public.measurement_params VALUES (6, 1, 7, 0, 567567, NULL);
INSERT INTO public.measurement_params VALUES (6, 1, 8, 0, 4, NULL);
INSERT INTO public.measurement_params VALUES (6, 1, 9, 0, 567567, NULL);
INSERT INTO public.measurement_params VALUES (6, 1, 10, 0, 0, NULL);
INSERT INTO public.measurement_params VALUES (6, 1, 11, 0, 42.4, NULL);
INSERT INTO public.measurement_params VALUES (6, 1, 3, 0, 567609, NULL);
INSERT INTO public.measurement_params VALUES (7, 1, 6, 0, 4564, NULL);
INSERT INTO public.measurement_params VALUES (7, 1, 7, 0, 45645, NULL);
INSERT INTO public.measurement_params VALUES (7, 1, 8, 0, 3, NULL);
INSERT INTO public.measurement_params VALUES (7, 1, 9, 0, 45645, NULL);
INSERT INTO public.measurement_params VALUES (7, 1, 10, 0, 1, NULL);
INSERT INTO public.measurement_params VALUES (7, 1, 11, 0, 14.8, NULL);
INSERT INTO public.measurement_params VALUES (7, 1, 3, 0, 45660.8, NULL);
INSERT INTO public.measurement_params VALUES (5, 1, 6, 0, 145, NULL);
INSERT INTO public.measurement_params VALUES (5, 1, 7, 0, 345, NULL);
INSERT INTO public.measurement_params VALUES (5, 1, 8, 0, 5, NULL);
INSERT INTO public.measurement_params VALUES (5, 1, 9, 0, 345, NULL);
INSERT INTO public.measurement_params VALUES (5, 1, 10, 0, 1, NULL);
INSERT INTO public.measurement_params VALUES (5, 1, 11, 0, 45.2, NULL);
INSERT INTO public.measurement_params VALUES (5, 1, 3, 0, 391.2, NULL);
INSERT INTO public.measurement_params VALUES (8, 2, 12, 0, 6, NULL);
INSERT INTO public.measurement_params VALUES (8, 2, 13, 0, 2, NULL);
INSERT INTO public.measurement_params VALUES (8, 2, 14, 0, 18, NULL);
INSERT INTO public.measurement_params VALUES (8, 2, 1, 0, 18, NULL);
INSERT INTO public.measurement_params VALUES (15, 3, 3, 0, 5, NULL);
INSERT INTO public.measurement_params VALUES (15, 3, 19, 0, 234.5, NULL);
INSERT INTO public.measurement_params VALUES (15, 3, 1, 0, 1172.5, NULL);
INSERT INTO public.measurement_params VALUES (15, 3, 2, 0, 239.5, NULL);
INSERT INTO public.measurement_params VALUES (31, 2, 12, 0, 4654, NULL);
INSERT INTO public.measurement_params VALUES (31, 2, 13, 0, 1, NULL);
INSERT INTO public.measurement_params VALUES (31, 2, 14, 0, 456, NULL);
INSERT INTO public.measurement_params VALUES (31, 2, 1, 0, 4654, NULL);
INSERT INTO public.measurement_params VALUES (17, 1, 6, 0, 567, NULL);
INSERT INTO public.measurement_params VALUES (17, 1, 7, 0, 567, NULL);
INSERT INTO public.measurement_params VALUES (17, 1, 8, 0, 2, NULL);
INSERT INTO public.measurement_params VALUES (17, 1, 9, 0, 67867, NULL);
INSERT INTO public.measurement_params VALUES (17, 1, 10, 0, 1, NULL);
INSERT INTO public.measurement_params VALUES (17, 1, 11, 0, 45.3, NULL);
INSERT INTO public.measurement_params VALUES (17, 1, 3, 0, 1134, NULL);
INSERT INTO public.measurement_params VALUES (12, 1, 6, 0, 45645, NULL);
INSERT INTO public.measurement_params VALUES (12, 1, 7, 0, 456456, NULL);
INSERT INTO public.measurement_params VALUES (12, 1, 8, 0, 2, NULL);
INSERT INTO public.measurement_params VALUES (12, 1, 9, 0, 45645, NULL);
INSERT INTO public.measurement_params VALUES (12, 1, 10, 0, 1, NULL);
INSERT INTO public.measurement_params VALUES (13, 2, 12, 0, 5, NULL);
INSERT INTO public.measurement_params VALUES (13, 2, 13, 0, 1, NULL);
INSERT INTO public.measurement_params VALUES (13, 2, 14, 0, 456567, NULL);
INSERT INTO public.measurement_params VALUES (13, 2, 1, 0, 5, NULL);
INSERT INTO public.measurement_params VALUES (22, 1, 6, 0, 34534, NULL);
INSERT INTO public.measurement_params VALUES (22, 1, 7, 0, 6456, NULL);
INSERT INTO public.measurement_params VALUES (25, 1, 6, 0, 75675, NULL);
INSERT INTO public.measurement_params VALUES (20, 2, 12, 0, 25, NULL);
INSERT INTO public.measurement_params VALUES (20, 2, 13, 0, 2, NULL);
INSERT INTO public.measurement_params VALUES (20, 2, 14, 0, 789, NULL);
INSERT INTO public.measurement_params VALUES (20, 2, 1, 0, 789, NULL);
INSERT INTO public.measurement_params VALUES (21, 3, 3, 0, 89, NULL);
INSERT INTO public.measurement_params VALUES (21, 3, 19, 0, 456.7, NULL);
INSERT INTO public.measurement_params VALUES (21, 3, 1, 0, 40646.3, NULL);
INSERT INTO public.measurement_params VALUES (21, 3, 2, 0, 545.7, NULL);
INSERT INTO public.measurement_params VALUES (28, 2, 12, 0, 5345, NULL);
INSERT INTO public.measurement_params VALUES (28, 2, 13, 0, 1, NULL);
INSERT INTO public.measurement_params VALUES (28, 2, 14, 0, 56756, NULL);
INSERT INTO public.measurement_params VALUES (28, 2, 1, 0, 5345, NULL);
INSERT INTO public.measurement_params VALUES (27, 3, 3, 0, 167, NULL);
INSERT INTO public.measurement_params VALUES (27, 3, 19, 0, 456.7, NULL);
INSERT INTO public.measurement_params VALUES (27, 3, 1, 0, 76268.9, NULL);
INSERT INTO public.measurement_params VALUES (27, 3, 2, 0, 623.7, NULL);
INSERT INTO public.measurement_params VALUES (40, 7, 38, 0, 2, NULL);
INSERT INTO public.measurement_params VALUES (40, 7, 29, 0, 45, NULL);
INSERT INTO public.measurement_params VALUES (40, 7, 30, 0, 2222, NULL);
INSERT INTO public.measurement_params VALUES (40, 7, 30, 1, 3333, NULL);
INSERT INTO public.measurement_params VALUES (40, 7, 30, 2, 444, NULL);
INSERT INTO public.measurement_params VALUES (40, 7, 36, 0, 2222, NULL);
INSERT INTO public.measurement_params VALUES (40, 7, 36, 1, 3333, NULL);
INSERT INTO public.measurement_params VALUES (40, 7, 36, 2, 444, NULL);
INSERT INTO public.measurement_params VALUES (40, 7, 31, 0, 56, NULL);
INSERT INTO public.measurement_params VALUES (40, 7, 28, 0, 1999.67, NULL);
INSERT INTO public.measurement_params VALUES (40, 7, 37, 0, 224422, NULL);
INSERT INTO public.measurement_params VALUES (40, 7, 37, 1, 336633, NULL);
INSERT INTO public.measurement_params VALUES (40, 7, 37, 2, 44844, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 41, 0, 1, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 38, 0, 1, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 29, 0, 56756, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 30, 0, 6756, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 30, 1, 565, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 30, 2, 56756, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 30, 3, 3423, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 30, 4, 545, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 36, 0, 56567, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 36, 1, 4343, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 36, 2, 434, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 36, 3, 345, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 36, 4, 53545, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 31, 0, 5657, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 39, 0, 3, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 39, 1, 1, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 39, 2, 2, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 39, 3, 2, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 39, 4, 1, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 40, 0, 1, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 40, 1, 1, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 40, 2, 1, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 40, 3, 0, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 40, 4, 0, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 28, 0, 13609, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 37, 0, 703443000, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 37, 1, 56635500, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 37, 2, 3223700000, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 37, 3, 196227000, NULL);
INSERT INTO public.measurement_params VALUES (51, 8, 37, 4, 333836000, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 38, 0, 2, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 29, 0, 756756, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 30, 0, 123, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 30, 1, 43, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 30, 2, 111, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 30, 3, 534, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 30, 4, 345, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 30, 5, 534, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 30, 6, 432, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 36, 0, 333, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 36, 1, 555, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 36, 2, 45, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 36, 3, 700, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 36, 4, 45, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 36, 5, 452, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 36, 6, 54, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 31, 0, 34.8, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 28, 0, 303.143, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 37, 0, 93092600, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 37, 1, 32559800, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 37, 2, 84001500, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 37, 3, 404132000, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 37, 4, 261082000, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 37, 5, 404123000, NULL);
INSERT INTO public.measurement_params VALUES (50, 7, 37, 6, 326920000, NULL);
INSERT INTO public.measurement_params VALUES (54, 10, 46, 0, 150.2, NULL);
INSERT INTO public.measurement_params VALUES (54, 10, 47, 0, 149.8, NULL);
INSERT INTO public.measurement_params VALUES (54, 10, 48, 0, 300.1, NULL);
INSERT INTO public.measurement_params VALUES (54, 10, 49, 0, 299.9, NULL);
INSERT INTO public.measurement_params VALUES (54, 10, 50, 0, 785.4, NULL);
INSERT INTO public.measurement_params VALUES (54, 10, 51, 0, 44.4, NULL);
INSERT INTO public.measurement_params VALUES (54, 10, 52, 0, 2, NULL);
INSERT INTO public.measurement_params VALUES (55, 11, 53, 0, 1, NULL);
INSERT INTO public.measurement_params VALUES (55, 11, 53, 1, 0.5, NULL);
INSERT INTO public.measurement_params VALUES (55, 11, 53, 2, 0.25, NULL);
INSERT INTO public.measurement_params VALUES (55, 11, 53, 3, 0.2, NULL);
INSERT INTO public.measurement_params VALUES (55, 11, 54, 0, 25, NULL);
INSERT INTO public.measurement_params VALUES (55, 11, 54, 1, 13, NULL);
INSERT INTO public.measurement_params VALUES (55, 11, 54, 2, 6, NULL);
INSERT INTO public.measurement_params VALUES (55, 11, 54, 3, 5, NULL);
INSERT INTO public.measurement_params VALUES (55, 11, 55, 0, 25, NULL);
INSERT INTO public.measurement_params VALUES (55, 11, 56, 0, 3.27, NULL);
INSERT INTO public.measurement_params VALUES (55, 11, 57, 0, 4, NULL);
INSERT INTO public.measurement_params VALUES (55, 11, 58, 0, 25, NULL);
INSERT INTO public.measurement_params VALUES (55, 11, 58, 1, 26, NULL);
INSERT INTO public.measurement_params VALUES (55, 11, 58, 2, 24, NULL);
INSERT INTO public.measurement_params VALUES (55, 11, 58, 3, 25, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 59, 0, 12.4502, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 59, 1, 11.8905, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 59, 2, 13.1104, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 59, 3, 12.0231, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 59, 4, 12.7844, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 60, 0, 17.4502, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 60, 1, 16.8905, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 60, 2, 18.1104, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 60, 3, 17.0231, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 60, 4, 17.7844, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 61, 0, 17.4302, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 61, 1, 16.8715, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 61, 2, 18.0894, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 61, 3, 17.0011, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 61, 4, 17.7664, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 62, 0, 0.4, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 62, 1, 0.38, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 62, 2, 0.42, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 62, 3, 0.44, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 62, 4, 0.36, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 63, 0, 0.4, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 64, 0, 0.032, NULL);
INSERT INTO public.measurement_params VALUES (56, 12, 65, 0, 5, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 66, 0, 52.1, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 66, 1, 49.5, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 66, 2, 50.8, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 66, 3, 51.6, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 67, 0, 1201.2, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 67, 1, 1195.4, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 67, 2, 1210.6, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 67, 3, 1204.8, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 68, 0, 1206.8, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 68, 1, 1202.1, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 68, 2, 1215.1, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 68, 3, 1210.9, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 69, 0, 687.3, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 69, 1, 681.9, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 69, 2, 694.4, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 69, 3, 688.2, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 72, 0, 51.0, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 73, 0, 2.312, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 73, 1, 2.298, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 73, 2, 2.325, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 73, 3, 2.305, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 74, 0, 0.47, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 75, 0, 4, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 76, 0, 93.9, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 77, 0, 93.9928, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 77, 1, 93.4131, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 77, 2, 94.5100, NULL);
INSERT INTO public.measurement_params VALUES (57, 13, 77, 3, 93.6974, NULL);
INSERT INTO public.measurement_params VALUES (58, 14, 78, 0, 5015, 1);
INSERT INTO public.measurement_params VALUES (58, 14, 79, 0, 0, NULL);
INSERT INTO public.measurement_params VALUES (58, 14, 80, 0, 250, NULL);
INSERT INTO public.measurement_params VALUES (58, 14, 81, 0, 2000, NULL);
INSERT INTO public.measurement_params VALUES (58, 14, 82, 0, 3500, NULL);
INSERT INTO public.measurement_params VALUES (58, 14, 83, 0, 4510, NULL);
INSERT INTO public.measurement_params VALUES (58, 14, 84, 0, 5010, NULL);
INSERT INTO public.measurement_params VALUES (58, 14, 85, 0, 0, 1);
INSERT INTO public.measurement_params VALUES (58, 14, 86, 0, 250, 1);
INSERT INTO public.measurement_params VALUES (58, 14, 87, 0, 1750, 1);
INSERT INTO public.measurement_params VALUES (58, 14, 88, 0, 1500, 1);
INSERT INTO public.measurement_params VALUES (58, 14, 89, 0, 1010, 1);
INSERT INTO public.measurement_params VALUES (58, 14, 90, 0, 500, 1);
INSERT INTO public.measurement_params VALUES (58, 14, 91, 0, 100, NULL);
INSERT INTO public.measurement_params VALUES (58, 14, 92, 0, 95, NULL);
INSERT INTO public.measurement_params VALUES (58, 14, 93, 0, 60, NULL);
INSERT INTO public.measurement_params VALUES (58, 14, 94, 0, 30, NULL);
INSERT INTO public.measurement_params VALUES (58, 14, 95, 0, 10.1, NULL);
INSERT INTO public.measurement_params VALUES (58, 14, 96, 0, 0.10, 1);
INSERT INTO public.measurement_params VALUES (59, 15, 102, 0, 21.5, 1);
INSERT INTO public.measurement_params VALUES (59, 15, 103, 0, 48.2, 1);
INSERT INTO public.measurement_params VALUES (59, 15, 107, 0, 0, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 107, 1, 10.04, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 107, 2, 20.06, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 108, 0, 10.04, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 108, 1, 20.06, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 108, 2, 30.09, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 109, 0, 10.04, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 109, 1, 10.02, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 109, 2, 10.03, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 110, 0, 0.016667, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 111, 0, 0.099604, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 111, 1, 0.099802, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 111, 2, 0.099703, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 112, 0, 0.099703, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 113, 0, 0.000099, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 114, 0, 0.10, 1);
INSERT INTO public.measurement_params VALUES (59, 15, 115, 0, 1.2258, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 116, 0, 10, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 116, 1, 10, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 116, 2, 10, NULL);
INSERT INTO public.measurement_params VALUES (59, 15, 117, 0, 3, 1);
INSERT INTO public.measurement_params VALUES (60, 16, 102, 0, 21.5, 1);
INSERT INTO public.measurement_params VALUES (60, 16, 103, 0, 48.2, 1);
INSERT INTO public.measurement_params VALUES (60, 16, 104, 0, 0.51, 1);
INSERT INTO public.measurement_params VALUES (60, 16, 118, 0, 14.2851, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 119, 0, 26.5448, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 120, 0, 1, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 121, 0, 0.2502, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 122, 0, 10, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 123, 0, 0, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 123, 1, 10.02, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 123, 2, 0, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 124, 0, 10.02, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 124, 1, 20, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 124, 2, 10, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 125, 0, 10.02, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 125, 1, 9.98, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 125, 2, 10, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 126, 0, 0.0416734, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 127, 0, 0.250040, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 128, 0, 0.0638, 1);
INSERT INTO public.measurement_params VALUES (60, 16, 129, 0, 0.02, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 130, 0, 3, 1);
INSERT INTO public.measurement_params VALUES (60, 16, 131, 0, 0.200, 1);
INSERT INTO public.measurement_params VALUES (60, 16, 132, 0, 10.00, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 133, 0, 0.041700, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 135, 0, 0.0417, NULL);
INSERT INTO public.measurement_params VALUES (60, 16, 136, 0, 0.2500, NULL);
INSERT INTO public.measurement_params VALUES (61, 17, 102, 0, 21.5, 1);
INSERT INTO public.measurement_params VALUES (61, 17, 103, 0, 52, 1);
INSERT INTO public.measurement_params VALUES (61, 17, 104, 0, 0.51, 1);
INSERT INTO public.measurement_params VALUES (61, 17, 105, 0, 96.2, NULL);
INSERT INTO public.measurement_params VALUES (61, 17, 137, 0, 10, NULL);
INSERT INTO public.measurement_params VALUES (61, 17, 138, 0, 14.85, NULL);
INSERT INTO public.measurement_params VALUES (61, 17, 139, 0, 13.65, NULL);
INSERT INTO public.measurement_params VALUES (61, 17, 140, 0, 8.6, NULL);
INSERT INTO public.measurement_params VALUES (61, 17, 141, 0, 0.1002, NULL);
INSERT INTO public.measurement_params VALUES (61, 17, 143, 0, 100.200000, 1);


--
-- Data for Name: measurement_reagent_lots; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.measurement_reagent_lots VALUES (59, 82);
INSERT INTO public.measurement_reagent_lots VALUES (59, 87);
INSERT INTO public.measurement_reagent_lots VALUES (59, 92);
INSERT INTO public.measurement_reagent_lots VALUES (59, 97);
INSERT INTO public.measurement_reagent_lots VALUES (60, 77);
INSERT INTO public.measurement_reagent_lots VALUES (60, 82);
INSERT INTO public.measurement_reagent_lots VALUES (60, 87);
INSERT INTO public.measurement_reagent_lots VALUES (60, 92);
INSERT INTO public.measurement_reagent_lots VALUES (60, 122);
INSERT INTO public.measurement_reagent_lots VALUES (60, 133);
INSERT INTO public.measurement_reagent_lots VALUES (60, 138);
INSERT INTO public.measurement_reagent_lots VALUES (61, 77);
INSERT INTO public.measurement_reagent_lots VALUES (61, 102);
INSERT INTO public.measurement_reagent_lots VALUES (61, 107);
INSERT INTO public.measurement_reagent_lots VALUES (61, 112);
INSERT INTO public.measurement_reagent_lots VALUES (61, 117);


--
-- Data for Name: measurement_sop_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.measurement_sop_versions VALUES (59, 121);
INSERT INTO public.measurement_sop_versions VALUES (59, 124);
INSERT INTO public.measurement_sop_versions VALUES (60, 124);
INSERT INTO public.measurement_sop_versions VALUES (60, 125);
INSERT INTO public.measurement_sop_versions VALUES (60, 139);
INSERT INTO public.measurement_sop_versions VALUES (61, 120);
INSERT INTO public.measurement_sop_versions VALUES (61, 124);
INSERT INTO public.measurement_sop_versions VALUES (61, 125);


--
-- Data for Name: measurement_tests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.measurement_tests VALUES (2, 2, 0, 212, 'trt');
INSERT INTO public.measurement_tests VALUES (4, 2, 0, 455645, 'dfg');
INSERT INTO public.measurement_tests VALUES (10, 4, 0, 123, '***');
INSERT INTO public.measurement_tests VALUES (11, 1, 0, 21321, '*');
INSERT INTO public.measurement_tests VALUES (14, 1, 0, 434, '*');
INSERT INTO public.measurement_tests VALUES (16, 1, 0, 5467, '*');
INSERT INTO public.measurement_tests VALUES (19, 1, 0, 156, '*');
INSERT INTO public.measurement_tests VALUES (23, 2, 0, 24, NULL);
INSERT INTO public.measurement_tests VALUES (24, 1, 0, 54, '*');
INSERT INTO public.measurement_tests VALUES (26, 1, 0, 185, '*');
INSERT INTO public.measurement_tests VALUES (30, 1, 0, 123, '*');
INSERT INTO public.measurement_tests VALUES (36, 1, 0, 5675, '*');
INSERT INTO public.measurement_tests VALUES (26, 3, 0, 3453, '/*');
INSERT INTO public.measurement_tests VALUES (38, 1, 0, 64564, '**');
INSERT INTO public.measurement_tests VALUES (38, 3, 0, 4564, '/**');
INSERT INTO public.measurement_tests VALUES (39, 3, 0, 150, '*');
INSERT INTO public.measurement_tests VALUES (39, 4, 0, 600.5, '**');
INSERT INTO public.measurement_tests VALUES (46, 3, 0, 454.34, '[2]');
INSERT INTO public.measurement_tests VALUES (46, 37, 0, 111, '[6]');
INSERT INTO public.measurement_tests VALUES (46, 37, 1, 333, '[6]');
INSERT INTO public.measurement_tests VALUES (46, 37, 2, 444, '[6]');
INSERT INTO public.measurement_tests VALUES (46, 38, 0, 3, '[5]');
INSERT INTO public.measurement_tests VALUES (46, 41, 0, 1, '[4]');
INSERT INTO public.measurement_tests VALUES (46, 28, 0, 75.5, '**');
INSERT INTO public.measurement_tests VALUES (47, 28, 0, 252.4, NULL);
INSERT INTO public.measurement_tests VALUES (47, 37, 0, 222, NULL);
INSERT INTO public.measurement_tests VALUES (47, 37, 1, 333, NULL);
INSERT INTO public.measurement_tests VALUES (47, 38, 0, 3, NULL);
INSERT INTO public.measurement_tests VALUES (48, 38, 0, 2, NULL);
INSERT INTO public.measurement_tests VALUES (48, 37, 0, 333, NULL);
INSERT INTO public.measurement_tests VALUES (48, 37, 1, 444, NULL);
INSERT INTO public.measurement_tests VALUES (48, 28, 0, 192.6, NULL);
INSERT INTO public.measurement_tests VALUES (49, 3, 0, 862.4, NULL);


--
-- Data for Name: measurements; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (1, 2, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474395+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (3, 2, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474658+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (29, 1, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.47466+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (35, 10, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474661+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (36, 2, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474661+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (37, 2, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474662+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (38, 11, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474662+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (39, 20, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474663+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (43, 20, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474663+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (44, 20, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474664+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (45, 20, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474664+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (49, 22, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474665+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (52, 11, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474665+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (53, 11, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474666+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (5, 2, 1, 'quis nobis qui sit', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474666+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (8, 2, 2, 'libero dicta in culpa nihil ', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474667+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (9, 2, 3, '- Architecto nulla voluptas pariatur quam ex velit quaerat debitis a at.
- Laborum voluptates enim libero soluta.
- Minus harum harum non qui blanditiis itaque quaerat doloremque numquam at sed officia.', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474668+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (11, 6, NULL, 'iure vero tenetur eaque iusto ea exercitationem', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474669+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (12, 6, 1, 'commodi porro quos', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.47467+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (13, 6, 2, 'veritatis autem tempora velit', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.47467+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (14, 1, NULL, 'aut voluptatem odit quaerat perspiciatis quia', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474671+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (15, 1, 3, 'quam aliquid molestiae odio vero', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474672+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (16, 3, NULL, ' et assumenda debitis dolor aliquid', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474672+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (17, 3, 1, ' dolore repellendus hic possimus maiores ', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474673+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (18, 2, 3, ' ducimus', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474673+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (19, 8, NULL, 'iure officiis laboriosam praesentium fuga amet at', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474676+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (20, 8, 2, ' explicabo repudiandae', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474677+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (21, 8, 3, ' error sunt enim ipsa temporibus', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474677+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (22, 8, 1, 'assumenda facilis facere quidem', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474678+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (23, 3, NULL, 'quasi dolore assumenda quod illum quis', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474678+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (24, 8, NULL, 'dignissimos in explicabo itaque quos
nostrum id porro accusantium', true, 8, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474679+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (25, 8, 1, 'ab quia mollitia reiciendis et', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474679+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (26, 11, NULL, 'eum sed repellendus harum magni', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.47468+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (2, 2, NULL, 'ea quae rem vero 
nam minus totam ', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474681+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (4, 2, NULL, 'Reprehenderit quos voluptas voluptatibus hic.
Qui fuga enim.
Voluptate ducimus nobis.
', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474681+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (7, 2, 1, ' velit iste totam', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474682+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (27, 11, 3, 'quaerat reiciendis nam aspernatur ab', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474682+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (28, 11, 2, 'reprehenderit quo nihil iure similique porro', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474683+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (31, 3, 2, 'minus ipsa minus eos eos', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474684+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (41, 20, 7, 'id eligendi ad excepturi quae quis', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474684+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (42, 20, 7, '- Non impedit quod totam veritatis cupiditate
- Eum expedita exercitationem ipsam quisquam consequuntur laboriosam dicta.', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474685+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (46, 20, NULL, '- Provident ducimus dolorem aperiam qui perferendis necessitatibus.
- Nam ad id cumque tempora repellat commodi.
- Libero quos iure mollitia ducimus.', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474685+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (47, 21, NULL, 'repellat fuga unde facilis ab similique', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474686+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (48, 22, NULL, 'libero eaque repellendus iste', true, 1, '2025-12-13 18:17:42.218999+02', true, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474687+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (50, 22, 7, 'nobis harum sequi', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474687+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (51, 22, 7, 'dicta porro expedita commodi', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474688+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (10, 2, NULL, 'Sint accusamus consectetur a exercitationem.
Adipisci optio nostrum quam.', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.474688+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (6, 2, 1, 'vitae aspernatur eligendi', true, 1, '2025-12-13 18:17:42.218999+02', true, 1, NULL, false, NULL, 1, '2026-08-27 19:38:52.474689+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (30, 1, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, false, NULL, 1, '2026-08-27 19:38:52.47469+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (54, 23, 10, 'Officia dignissimos tempora commodi est sunt saepe veniam recusandae ex fuga id', true, 1, '2026-07-06 19:36:43.104787+03', true, 1, NULL, true, NULL, 1, '2026-08-27 19:38:52.474691+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (55, 24, 11, '- Error numquam dicta cum.
- Veritatis itaque quis soluta labore tenetur.
- Commodi ratione vero dicta maxime.', true, 1, '2026-07-07 19:59:50.502542+03', true, 1, NULL, true, NULL, 1, '2026-08-27 19:38:52.474692+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (40, 20, 7, 'Error numquam dicta cum.
Veritatis itaque quis soluta labore tenetur.
Commodi ratione vero dicta maxime.', true, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL, true, NULL, 1, '2026-08-27 19:38:52.474693+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (56, 25, 12, '- Error numquam dicta cum.
- Veritatis itaque quis soluta labore tenetur.
- Commodi ratione vero dicta maxime.
', true, 1, '2026-07-09 18:56:38.708763+03', true, 1, NULL, true, NULL, 1, '2026-08-27 19:38:52.474694+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (57, 26, 13, '- Error numquam dicta cum.
- Veritatis itaque quis soluta labore tenetur.
- Commodi ratione vero dicta maxime.
', true, 1, '2026-07-11 23:05:15.65936+03', true, 1, NULL, true, NULL, 1, '2026-08-27 19:38:52.474694+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (58, 27, 14, '- Error numquam dicta cum.
- Veritatis itaque quis soluta labore tenetur.
- Commodi ratione vero dicta maxime.
', true, 1, '2026-07-17 21:59:09.149834+03', true, 1, NULL, true, NULL, 1, '2026-08-27 19:38:52.474695+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (59, 28, 15, NULL, true, 1, '2026-09-15 21:17:24.325603+03', true, 1, NULL, true, NULL, 1, '2026-09-15 21:17:24.225516+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (60, 29, 16, NULL, true, 1, '2026-09-16 22:35:49.416688+03', true, 1, NULL, true, NULL, 1, '2026-09-16 22:35:49.343915+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (61, 30, 17, NULL, true, 1, '2026-09-17 15:38:02.838647+03', true, 1, NULL, true, NULL, 1, '2026-09-17 15:38:02.726919+03');


--
-- Data for Name: norms; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.norms OVERRIDING SYSTEM VALUE VALUES (1, 'Norm A', 'Description Norm A', '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.norms OVERRIDING SYSTEM VALUE VALUES (2, 'Norm B', 'Description Norm B', '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.norms OVERRIDING SYSTEM VALUE VALUES (3, 'Norm C', 'Description Norm C', '2025-12-13 18:17:42.218999+02', true, '2026-01-23 22:44:28.171813+02', 'Some explanations ...');
INSERT INTO public.norms OVERRIDING SYSTEM VALUE VALUES (4, 'Norm D', 'Description Norm D', '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.norms OVERRIDING SYSTEM VALUE VALUES (6, 'ASTM C42', 'Standard for concrete cores', '2026-07-06 15:05:04.214306+03', false, NULL, NULL);
INSERT INTO public.norms OVERRIDING SYSTEM VALUE VALUES (5, 'ASTM C39', 'Standard for molded cylinders', '2026-07-06 15:04:48.662185+03', false, NULL, NULL);
INSERT INTO public.norms OVERRIDING SYSTEM VALUE VALUES (7, 'EPA Method 160.2', 'WASTEWATER EFFLUENT ANALYSIS (Total Suspended Solids - TSS)', '2026-07-07 17:34:06.275007+03', false, NULL, NULL);
INSERT INTO public.norms OVERRIDING SYSTEM VALUE VALUES (8, 'USP <731> / EP 2.2.32', 'Harmonized Loss on Drying (LOD)', '2026-07-09 15:11:56.803047+03', false, NULL, NULL);
INSERT INTO public.norms OVERRIDING SYSTEM VALUE VALUES (9, 'ASTM D3549', 'Thickness', '2026-07-11 18:50:10.475241+03', false, NULL, NULL);
INSERT INTO public.norms OVERRIDING SYSTEM VALUE VALUES (10, 'AASHTO T 166', 'Bulk Specific Gravity of Compacted HMA', '2026-07-11 18:50:32.53821+03', false, NULL, NULL);
INSERT INTO public.norms OVERRIDING SYSTEM VALUE VALUES (11, 'ASTM C136', 'Gradation of Fine and Coarse Aggregates', '2026-07-17 09:27:59.605043+03', false, NULL, NULL);
INSERT INTO public.norms OVERRIDING SYSTEM VALUE VALUES (12, 'AASHTO T 27', 'Gradation of Fine and Coarse Aggregates', '2026-07-17 09:28:24.246464+03', false, NULL, NULL);
INSERT INTO public.norms OVERRIDING SYSTEM VALUE VALUES (14, 'ISO/IEC 17025:2017', 'General requirements for the competence of testing and calibration laboratories', '2026-01-10 10:00:00+02', false, NULL, NULL);
INSERT INTO public.norms OVERRIDING SYSTEM VALUE VALUES (13, 'ISO 6060:1989', 'Water quality - Determination of chemical oxygen demand (Closed reflux, titrimetric method)', '2026-01-10 10:00:00+02', false, NULL, NULL);


--
-- Data for Name: reagent_lot_statuses; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.reagent_lot_statuses VALUES (1, 'Quarantined');
INSERT INTO public.reagent_lot_statuses VALUES (2, 'Active');
INSERT INTO public.reagent_lot_statuses VALUES (3, 'Expired');
INSERT INTO public.reagent_lot_statuses VALUES (4, 'Depleted');


--
-- Data for Name: reagent_lots; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.reagent_lots VALUES (113, false, NULL, 1, 1000.00, NULL, '2027-03-08');
INSERT INTO public.reagent_lots VALUES (114, false, NULL, 1, 1000.00, NULL, '2027-06-06');
INSERT INTO public.reagent_lots VALUES (115, false, NULL, 1, 1000.00, NULL, '2027-09-04');
INSERT INTO public.reagent_lots VALUES (116, false, NULL, 1, 1000.00, NULL, '2027-12-03');
INSERT INTO public.reagent_lots VALUES (112, false, NULL, 2, 1000.00, NULL, '2026-12-08');
INSERT INTO public.reagent_lots VALUES (128, false, NULL, 1, 2500.0, 4, '2028-09-11');
INSERT INTO public.reagent_lots VALUES (129, false, NULL, 1, 2500.0, 4, '2028-09-12');
INSERT INTO public.reagent_lots VALUES (130, false, NULL, 1, 2500.0, 4, '2028-09-13');
INSERT INTO public.reagent_lots VALUES (131, false, NULL, 1, 2500.0, 4, '2028-09-14');
INSERT INTO public.reagent_lots VALUES (132, false, NULL, 1, 2500.0, 4, '2028-09-15');
INSERT INTO public.reagent_lots VALUES (134, false, NULL, 1, 500.0, 2, '2028-09-12');
INSERT INTO public.reagent_lots VALUES (135, false, NULL, 1, 500.0, 2, '2028-09-13');
INSERT INTO public.reagent_lots VALUES (136, false, NULL, 1, 500.0, 2, '2028-09-14');
INSERT INTO public.reagent_lots VALUES (137, false, NULL, 1, 500.0, 2, '2028-09-15');
INSERT INTO public.reagent_lots VALUES (101, false, NULL, 1, 1000.00, 3, '2027-12-03');
INSERT INTO public.reagent_lots VALUES (100, false, NULL, 1, 1000.00, 3, '2027-09-04');
INSERT INTO public.reagent_lots VALUES (99, false, NULL, 1, 1000.00, 3, '2027-06-06');
INSERT INTO public.reagent_lots VALUES (98, false, NULL, 1, 1000.00, 3, '2027-03-08');
INSERT INTO public.reagent_lots VALUES (97, false, NULL, 2, 1000.00, 3, '2026-12-08');
INSERT INTO public.reagent_lots VALUES (91, false, NULL, 1, 1000.00, 4, '2027-12-03');
INSERT INTO public.reagent_lots VALUES (90, false, NULL, 1, 1000.00, 4, '2027-09-04');
INSERT INTO public.reagent_lots VALUES (89, false, NULL, 1, 1000.00, 4, '2027-06-06');
INSERT INTO public.reagent_lots VALUES (88, false, NULL, 1, 1000.00, 4, '2027-03-08');
INSERT INTO public.reagent_lots VALUES (87, false, NULL, 2, 1000.00, 4, '2026-12-08');
INSERT INTO public.reagent_lots VALUES (121, false, NULL, 1, 1000.00, 3, '2027-12-03');
INSERT INTO public.reagent_lots VALUES (120, false, NULL, 1, 1000.00, 3, '2027-09-04');
INSERT INTO public.reagent_lots VALUES (119, false, NULL, 1, 1000.00, 3, '2027-06-06');
INSERT INTO public.reagent_lots VALUES (118, false, NULL, 1, 1000.00, 3, '2027-03-08');
INSERT INTO public.reagent_lots VALUES (117, false, NULL, 2, 1000.00, 3, '2026-12-08');
INSERT INTO public.reagent_lots VALUES (86, false, NULL, 1, 1000.00, 2, '2027-12-03');
INSERT INTO public.reagent_lots VALUES (85, false, NULL, 1, 1000.00, 2, '2027-09-04');
INSERT INTO public.reagent_lots VALUES (84, false, NULL, 1, 1000.00, 2, '2027-06-06');
INSERT INTO public.reagent_lots VALUES (82, false, NULL, 2, 1000.00, 2, '2026-12-08');
INSERT INTO public.reagent_lots VALUES (83, false, NULL, 1, 1000.00, 2, '2027-03-08');
INSERT INTO public.reagent_lots VALUES (126, false, NULL, 1, 500.00, 2, '2029-02-25');
INSERT INTO public.reagent_lots VALUES (125, false, NULL, 1, 500.00, 2, '2028-08-29');
INSERT INTO public.reagent_lots VALUES (124, false, NULL, 1, 500.00, 2, '2028-03-02');
INSERT INTO public.reagent_lots VALUES (123, false, NULL, 1, 500.00, 2, '2027-09-04');
INSERT INTO public.reagent_lots VALUES (122, false, NULL, 2, 500.00, 2, '2027-03-08');
INSERT INTO public.reagent_lots VALUES (111, false, NULL, 1, 1000.00, 4, '2027-12-03');
INSERT INTO public.reagent_lots VALUES (110, false, NULL, 1, 1000.00, 4, '2027-09-04');
INSERT INTO public.reagent_lots VALUES (109, false, NULL, 1, 1000.00, 4, '2027-06-06');
INSERT INTO public.reagent_lots VALUES (108, false, NULL, 1, 1000.00, 4, '2027-03-08');
INSERT INTO public.reagent_lots VALUES (107, false, NULL, 2, 1000.00, 4, '2026-12-08');
INSERT INTO public.reagent_lots VALUES (106, false, NULL, 1, 1000.00, 4, '2027-12-03');
INSERT INTO public.reagent_lots VALUES (105, false, NULL, 1, 1000.00, 4, '2027-09-04');
INSERT INTO public.reagent_lots VALUES (104, false, NULL, 1, 1000.00, 4, '2027-06-06');
INSERT INTO public.reagent_lots VALUES (103, false, NULL, 1, 1000.00, 4, '2027-03-08');
INSERT INTO public.reagent_lots VALUES (102, false, NULL, 2, 1000.00, 4, '2026-12-08');
INSERT INTO public.reagent_lots VALUES (81, false, NULL, 1, 1000.00, 4, '2027-12-03');
INSERT INTO public.reagent_lots VALUES (80, false, NULL, 1, 1000.00, 4, '2027-09-04');
INSERT INTO public.reagent_lots VALUES (79, false, NULL, 1, 1000.00, 4, '2027-06-06');
INSERT INTO public.reagent_lots VALUES (78, false, NULL, 1, 1000.00, 4, '2027-03-08');
INSERT INTO public.reagent_lots VALUES (77, false, NULL, 2, 1000.00, 4, '2026-12-08');
INSERT INTO public.reagent_lots VALUES (96, false, NULL, 1, 1000.00, 4, '2027-12-03');
INSERT INTO public.reagent_lots VALUES (95, false, NULL, 1, 1000.00, 4, '2027-09-04');
INSERT INTO public.reagent_lots VALUES (94, false, NULL, 1, 1000.00, 4, '2027-06-06');
INSERT INTO public.reagent_lots VALUES (93, false, NULL, 1, 1000.00, 4, '2027-03-08');
INSERT INTO public.reagent_lots VALUES (92, false, NULL, 2, 1000.00, 4, '2026-12-08');
INSERT INTO public.reagent_lots VALUES (133, false, NULL, 2, 500.0, 2, '2028-09-11');
INSERT INTO public.reagent_lots VALUES (139, true, 1, 1, 10.0, 3, '2027-09-21');
INSERT INTO public.reagent_lots VALUES (140, true, 1, 1, 10.0, 3, '2027-06-20');
INSERT INTO public.reagent_lots VALUES (141, true, 1, 1, 10.0, 3, '2027-03-19');
INSERT INTO public.reagent_lots VALUES (138, true, 1, 2, 10.0, 3, '2026-12-22');
INSERT INTO public.reagent_lots VALUES (142, true, 1, 1, 10.0, 3, '2027-12-18');


--
-- Data for Name: reagent_production_lots; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.reagent_production_lots VALUES (142, 97);
INSERT INTO public.reagent_production_lots VALUES (141, 97);
INSERT INTO public.reagent_production_lots VALUES (140, 97);
INSERT INTO public.reagent_production_lots VALUES (139, 97);
INSERT INTO public.reagent_production_lots VALUES (138, 97);


--
-- Data for Name: reagent_supplier_lots; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.reagent_supplier_lots VALUES (126, 1, 'CAT-FAS-500G', 'MFG-FAS-2026-05', 'COA-RL-RAW-FAS-005', 'Ferrous Ammonium Sulfate Hexahydrate Lot 5');
INSERT INTO public.reagent_supplier_lots VALUES (125, 1, 'CAT-FAS-500G', 'MFG-FAS-2026-04', 'COA-RL-RAW-FAS-004', 'Ferrous Ammonium Sulfate Hexahydrate Lot 4');
INSERT INTO public.reagent_supplier_lots VALUES (124, 1, 'CAT-FAS-500G', 'MFG-FAS-2026-03', 'COA-RL-RAW-FAS-003', 'Ferrous Ammonium Sulfate Hexahydrate Lot 3');
INSERT INTO public.reagent_supplier_lots VALUES (123, 1, 'CAT-FAS-500G', 'MFG-FAS-2026-02', 'COA-RL-RAW-FAS-002', 'Ferrous Ammonium Sulfate Hexahydrate Lot 2');
INSERT INTO public.reagent_supplier_lots VALUES (122, 1, 'CAT-FAS-500G', 'MFG-FAS-2026-01', 'COA-RL-RAW-FAS-001', 'Ferrous Ammonium Sulfate Hexahydrate Lot 1');
INSERT INTO public.reagent_supplier_lots VALUES (86, 2, 'CAT-PDC-105', 'MFG-PDC01-2026-05', 'CoA-PDC01-2026-05.pdf', 'Potassium Dichromate Lot 5');
INSERT INTO public.reagent_supplier_lots VALUES (85, 2, 'CAT-PDC-104', 'MFG-PDC01-2026-04', 'CoA-PDC01-2026-04.pdf', 'Potassium Dichromate Lot 4');
INSERT INTO public.reagent_supplier_lots VALUES (84, 2, 'CAT-PDC-103', 'MFG-PDC01-2026-03', 'CoA-PDC01-2026-03.pdf', 'Potassium Dichromate Lot 3');
INSERT INTO public.reagent_supplier_lots VALUES (83, 2, 'CAT-PDC-102', 'MFG-PDC01-2026-02', 'CoA-PDC01-2026-02.pdf', 'Potassium Dichromate Lot 2');
INSERT INTO public.reagent_supplier_lots VALUES (82, 2, 'CAT-PDC-101', 'MFG-PDC01-2026-01', 'CoA-PDC01-2026-01.pdf', 'Potassium Dichromate Lot 1');
INSERT INTO public.reagent_supplier_lots VALUES (121, 3, 'CAT-COD05', 'MFG-LOT-202605', 'COA-RL-COD-COD05-005', 'Distilled Water Blank Lot 5');
INSERT INTO public.reagent_supplier_lots VALUES (120, 3, 'CAT-COD05', 'MFG-LOT-202604', 'COA-RL-COD-COD05-004', 'Distilled Water Blank Lot 4');
INSERT INTO public.reagent_supplier_lots VALUES (119, 3, 'CAT-COD05', 'MFG-LOT-202603', 'COA-RL-COD-COD05-003', 'Distilled Water Blank Lot 3');
INSERT INTO public.reagent_supplier_lots VALUES (118, 3, 'CAT-COD05', 'MFG-LOT-202602', 'COA-RL-COD-COD05-002', 'Distilled Water Blank Lot 2');
INSERT INTO public.reagent_supplier_lots VALUES (117, 3, 'CAT-COD05', 'MFG-LOT-202601', 'COA-RL-COD-COD05-001', 'Distilled Water Blank Lot 1');
INSERT INTO public.reagent_supplier_lots VALUES (116, 3, 'CAT-COD04', 'MFG-LOT-202605', 'COA-RL-COD-COD04-005', 'KHP Check Standard 500mg/L Lot 5');
INSERT INTO public.reagent_supplier_lots VALUES (115, 3, 'CAT-COD04', 'MFG-LOT-202604', 'COA-RL-COD-COD04-004', 'KHP Check Standard 500mg/L Lot 4');
INSERT INTO public.reagent_supplier_lots VALUES (114, 3, 'CAT-COD04', 'MFG-LOT-202603', 'COA-RL-COD-COD04-003', 'KHP Check Standard 500mg/L Lot 3');
INSERT INTO public.reagent_supplier_lots VALUES (113, 3, 'CAT-COD04', 'MFG-LOT-202602', 'COA-RL-COD-COD04-002', 'KHP Check Standard 500mg/L Lot 2');
INSERT INTO public.reagent_supplier_lots VALUES (112, 3, 'CAT-COD04', 'MFG-LOT-202601', 'COA-RL-COD-COD04-001', 'KHP Check Standard 500mg/L Lot 1');
INSERT INTO public.reagent_supplier_lots VALUES (111, 3, 'CAT-COD02', 'MFG-LOT-202605', 'COA-RL-COD-COD02-005', 'Catalyst Reagent Ag2SO4/H2SO4 Lot 5');
INSERT INTO public.reagent_supplier_lots VALUES (110, 3, 'CAT-COD02', 'MFG-LOT-202604', 'COA-RL-COD-COD02-004', 'Catalyst Reagent Ag2SO4/H2SO4 Lot 4');
INSERT INTO public.reagent_supplier_lots VALUES (109, 3, 'CAT-COD02', 'MFG-LOT-202603', 'COA-RL-COD-COD02-003', 'Catalyst Reagent Ag2SO4/H2SO4 Lot 3');
INSERT INTO public.reagent_supplier_lots VALUES (108, 3, 'CAT-COD02', 'MFG-LOT-202602', 'COA-RL-COD-COD02-002', 'Catalyst Reagent Ag2SO4/H2SO4 Lot 2');
INSERT INTO public.reagent_supplier_lots VALUES (107, 3, 'CAT-COD02', 'MFG-LOT-202601', 'COA-RL-COD-COD02-001', 'Catalyst Reagent Ag2SO4/H2SO4 Lot 1');
INSERT INTO public.reagent_supplier_lots VALUES (106, 3, 'CAT-COD01', 'MFG-LOT-202605', 'COA-RL-COD-COD01-005', 'Digestion Solution K2Cr2O7 Lot 5');
INSERT INTO public.reagent_supplier_lots VALUES (105, 3, 'CAT-COD01', 'MFG-LOT-202604', 'COA-RL-COD-COD01-004', 'Digestion Solution K2Cr2O7 Lot 4');
INSERT INTO public.reagent_supplier_lots VALUES (104, 3, 'CAT-COD01', 'MFG-LOT-202603', 'COA-RL-COD-COD01-003', 'Digestion Solution K2Cr2O7 Lot 3');
INSERT INTO public.reagent_supplier_lots VALUES (103, 3, 'CAT-COD01', 'MFG-LOT-202602', 'COA-RL-COD-COD01-002', 'Digestion Solution K2Cr2O7 Lot 2');
INSERT INTO public.reagent_supplier_lots VALUES (102, 3, 'CAT-COD01', 'MFG-LOT-202601', 'COA-RL-COD-COD01-001', 'Digestion Solution K2Cr2O7 Lot 1');
INSERT INTO public.reagent_supplier_lots VALUES (96, 3, 'CAT-FER-105', 'MFG-FER01-2026-05', 'CoA-FER01-2026-05.pdf', 'Ferroin Indicator Lot 5');
INSERT INTO public.reagent_supplier_lots VALUES (95, 3, 'CAT-FER-104', 'MFG-FER01-2026-04', 'CoA-FER01-2026-04.pdf', 'Ferroin Indicator Lot 4');
INSERT INTO public.reagent_supplier_lots VALUES (94, 3, 'CAT-FER-103', 'MFG-FER01-2026-03', 'CoA-FER01-2026-03.pdf', 'Ferroin Indicator Lot 3');
INSERT INTO public.reagent_supplier_lots VALUES (93, 3, 'CAT-FER-102', 'MFG-FER01-2026-02', 'CoA-FER01-2026-02.pdf', 'Ferroin Indicator Lot 2');
INSERT INTO public.reagent_supplier_lots VALUES (92, 3, 'CAT-FER-101', 'MFG-FER01-2026-01', 'CoA-FER01-2026-01.pdf', 'Ferroin Indicator Lot 1');
INSERT INTO public.reagent_supplier_lots VALUES (91, 3, 'CAT-SA-105', 'MFG-H2SO4-2026-05', 'CoA-H2SO4-2026-05.pdf', 'Sulfuric Acid Lot 5');
INSERT INTO public.reagent_supplier_lots VALUES (90, 3, 'CAT-SA-104', 'MFG-H2SO4-2026-04', 'CoA-H2SO4-2026-04.pdf', 'Sulfuric Acid Lot 4');
INSERT INTO public.reagent_supplier_lots VALUES (89, 3, 'CAT-SA-103', 'MFG-H2SO4-2026-03', 'CoA-H2SO4-2026-03.pdf', 'Sulfuric Acid Lot 3');
INSERT INTO public.reagent_supplier_lots VALUES (88, 3, 'CAT-SA-102', 'MFG-H2SO4-2026-02', 'CoA-H2SO4-2026-02.pdf', 'Sulfuric Acid Lot 2');
INSERT INTO public.reagent_supplier_lots VALUES (87, 3, 'CAT-SA-101', 'MFG-H2SO4-2026-01', 'CoA-H2SO4-2026-01.pdf', 'Sulfuric Acid Lot 1');
INSERT INTO public.reagent_supplier_lots VALUES (81, 3, 'CAT-FAS-105', 'MFG-FAS01-2026-05', 'CoA-FAS01-2026-05.pdf', 'Ferrous Ammonium Sulfate Lot 5');
INSERT INTO public.reagent_supplier_lots VALUES (80, 3, 'CAT-FAS-104', 'MFG-FAS01-2026-04', 'CoA-FAS01-2026-04.pdf', 'Ferrous Ammonium Sulfate Lot 4');
INSERT INTO public.reagent_supplier_lots VALUES (79, 3, 'CAT-FAS-103', 'MFG-FAS01-2026-03', 'CoA-FAS01-2026-03.pdf', 'Ferrous Ammonium Sulfate Lot 3');
INSERT INTO public.reagent_supplier_lots VALUES (78, 3, 'CAT-FAS-102', 'MFG-FAS01-2026-02', 'CoA-FAS01-2026-02.pdf', 'Ferrous Ammonium Sulfate Lot 2');
INSERT INTO public.reagent_supplier_lots VALUES (77, 3, 'CAT-FAS-101', 'MFG-FAS01-2026-01', 'CoA-FAS01-2026-01.pdf', 'Ferrous Ammonium Sulfate Lot 1');
INSERT INTO public.reagent_supplier_lots VALUES (101, 4, 'CAT-H2O-105', 'MFG-H2O01-2026-05', 'CoA-H2O01-2026-05.pdf', 'Type I Ultrapure Water Lot 5');
INSERT INTO public.reagent_supplier_lots VALUES (100, 4, 'CAT-H2O-104', 'MFG-H2O01-2026-04', 'CoA-H2O01-2026-04.pdf', 'Type I Ultrapure Water Lot 4');
INSERT INTO public.reagent_supplier_lots VALUES (99, 4, 'CAT-H2O-103', 'MFG-H2O01-2026-03', 'CoA-H2O01-2026-03.pdf', 'Type I Ultrapure Water Lot 3');
INSERT INTO public.reagent_supplier_lots VALUES (98, 4, 'CAT-H2O-102', 'MFG-H2O01-2026-02', 'CoA-H2O01-2026-02.pdf', 'Type I Ultrapure Water Lot 2');
INSERT INTO public.reagent_supplier_lots VALUES (97, 4, 'CAT-H2O-101', 'MFG-H2O01-2026-01', 'CoA-H2O01-2026-01.pdf', 'Type I Ultrapure Water Lot 1');
INSERT INTO public.reagent_supplier_lots VALUES (128, 3, '258105', 'H2SO4-7741', 'COA-H2SO4-7741', 'Ultrapure Grade 95.0-98.0%');
INSERT INTO public.reagent_supplier_lots VALUES (129, 3, '258105', 'H2SO4-7742', 'COA-H2SO4-7742', 'Ultrapure Grade 95.0-98.0%');
INSERT INTO public.reagent_supplier_lots VALUES (130, 3, '258105', 'H2SO4-7743', 'COA-H2SO4-7743', 'Ultrapure Grade 95.0-98.0%');
INSERT INTO public.reagent_supplier_lots VALUES (131, 3, '258105', 'H2SO4-7744', 'COA-H2SO4-7744', 'Ultrapure Grade 95.0-98.0%');
INSERT INTO public.reagent_supplier_lots VALUES (132, 3, '258105', 'H2SO4-7745', 'COA-H2SO4-7745', 'Ultrapure Grade 95.0-98.0%');
INSERT INTO public.reagent_supplier_lots VALUES (133, 3, 'M2837', 'HgSO4-3321', 'COA-HgSO4-3321', 'ACS Grade Powder');
INSERT INTO public.reagent_supplier_lots VALUES (134, 3, 'M2837', 'HgSO4-3322', 'COA-HgSO4-3322', 'ACS Grade Powder');
INSERT INTO public.reagent_supplier_lots VALUES (135, 3, 'M2837', 'HgSO4-3323', 'COA-HgSO4-3323', 'ACS Grade Powder');
INSERT INTO public.reagent_supplier_lots VALUES (136, 3, 'M2837', 'HgSO4-3324', 'COA-HgSO4-3324', 'ACS Grade Powder');
INSERT INTO public.reagent_supplier_lots VALUES (137, 3, 'M2837', 'HgSO4-3325', 'COA-HgSO4-3325', 'ACS Grade Powder');


--
-- Data for Name: reagent_suppliers; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.reagent_suppliers OVERRIDING SYSTEM VALUE VALUES (1, 'Merck / Sigma-Aldrich');
INSERT INTO public.reagent_suppliers OVERRIDING SYSTEM VALUE VALUES (2, 'NIST / Sigma');
INSERT INTO public.reagent_suppliers OVERRIDING SYSTEM VALUE VALUES (3, 'Sigma-Aldrich');
INSERT INTO public.reagent_suppliers OVERRIDING SYSTEM VALUE VALUES (4, 'In-House Purifier');
INSERT INTO public.reagent_suppliers OVERRIDING SYSTEM VALUE VALUES (5, 'Millipore');


--
-- Data for Name: reception_tests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.reception_tests VALUES (2, 1);
INSERT INTO public.reception_tests VALUES (2, 5);
INSERT INTO public.reception_tests VALUES (6, 1);
INSERT INTO public.reception_tests VALUES (6, 3);
INSERT INTO public.reception_tests VALUES (7, 1);
INSERT INTO public.reception_tests VALUES (7, 3);
INSERT INTO public.reception_tests VALUES (7, 4);
INSERT INTO public.reception_tests VALUES (3, 1);
INSERT INTO public.reception_tests VALUES (3, 3);
INSERT INTO public.reception_tests VALUES (3, 4);
INSERT INTO public.reception_tests VALUES (10, 2);
INSERT INTO public.reception_tests VALUES (10, 3);
INSERT INTO public.reception_tests VALUES (12, 2);
INSERT INTO public.reception_tests VALUES (12, 4);
INSERT INTO public.reception_tests VALUES (13, 4);
INSERT INTO public.reception_tests VALUES (13, 5);
INSERT INTO public.reception_tests VALUES (15, 1);
INSERT INTO public.reception_tests VALUES (15, 3);
INSERT INTO public.reception_tests VALUES (15, 4);
INSERT INTO public.reception_tests VALUES (17, 1);
INSERT INTO public.reception_tests VALUES (17, 3);
INSERT INTO public.reception_tests VALUES (17, 4);
INSERT INTO public.reception_tests VALUES (5, 2);
INSERT INTO public.reception_tests VALUES (5, 3);
INSERT INTO public.reception_tests VALUES (18, 2);
INSERT INTO public.reception_tests VALUES (18, 3);
INSERT INTO public.reception_tests VALUES (19, 4);
INSERT INTO public.reception_tests VALUES (19, 1);
INSERT INTO public.reception_tests VALUES (19, 3);


--
-- Data for Name: reception_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.reception_types VALUES (1, 'Certification');
INSERT INTO public.reception_types VALUES (2, 'Verification');
INSERT INTO public.reception_types VALUES (3, 'Category Verification');


--
-- Data for Name: receptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (5, 2, 59, NULL, NULL, false, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (16, 1, 6, NULL, NULL, false, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (18, 2, 59, NULL, NULL, false, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (7, 2, 60, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'eum', false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (9, 1, 69, NULL, NULL, false, 1, '2025-12-13 18:17:42.218999+02', 'ipsa veniam eos aperiam ad voluptatibus', false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (10, 2, 59, NULL, NULL, true, 8, '2025-12-13 18:17:42.218999+02', 'laborum accusantium alias facere
omnis fuga velit eaque mollitia reprehenderit
a aperiam veritatis impedit
', true, 8, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (11, 1, 60, NULL, NULL, true, 8, '2025-12-13 18:17:42.218999+02', 'earum reprehenderit natus officiis voluptas neque
occaecati dolor ea dicta
 vitae explicabo exercitationem', true, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (13, 2, 69, NULL, NULL, false, 8, '2025-12-13 18:17:42.218999+02', 'minima ea quo maxime expedita placeat
laudantium dolor eos corporis asperiores vel', false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (14, 1, 66, NULL, NULL, false, 8, '2025-12-13 18:17:42.218999+02', 'similique dolorem nam aut blanditiis', false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (15, 2, 56, NULL, NULL, false, 8, '2025-12-13 18:17:42.218999+02', 'vitae in omnis iusto cumque', false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (20, 1, 34, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'eos odio iste sed facere rem natus', true, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (21, 1, 35, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'perspiciatis vero amet qui vero', true, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (22, 1, 63, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'odio voluptatibus quidem voluptatum expedita', true, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (1, 1, 60, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'dolorem ullam est ipsum aspernatur cumque libero deserunt', true, 1, '2025-12-13 18:17:42.218999+02', 'officia dignissimos tempora commodi est sunt saepe veniam recusandae ex fuga id', false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (2, 2, 70, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'voluptas soluta similique nam deleniti tempora', true, 1, '2025-12-13 18:17:42.218999+02', 'accusantium blanditiis perferendis voluptate cum porro omnis tempore magnam', false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (4, 2, 60, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'nobis', true, 1, '2025-12-13 18:17:42.218999+02', 'eligendi quo vero hic', false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (8, 1, 69, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'tempora ducimus cupiditate molestias repudiandae', true, 1, '2025-12-13 18:17:42.218999+02', 'cumque architecto hic ea', false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (19, 3, NULL, 'harum optio magni repellendus modi', 1, false, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (12, 3, NULL, 'quos explicabo iusto cum modi ipsam', 2, false, 8, '2025-12-13 18:17:42.218999+02', 'id consectetur nihil quae est
error aut enim adipisci voluptatum', false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (3, 3, NULL, 'Et Laudantium Dicta', 1, true, 1, '2025-12-13 18:17:42.218999+02', 'sunt quam sunt ipsum quibusdam', true, 1, '2025-12-13 18:17:42.218999+02', 'accusamus veniam maiores ad sequi sapiente deleniti', false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (6, 3, NULL, 'quibusdam', 1, true, 1, '2025-12-13 18:17:42.218999+02', 'in', true, 1, '2025-12-13 18:17:42.218999+02', 'explicabo voluptatem id', false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (17, 2, 60, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', '- Minima voluptates hic commodi id iure accusamus.
- Reprehenderit dolorem exercitationem laboriosam quidem autem.
- Quas minus dignissimos neque corrupti consectetur', false, NULL, NULL, NULL, true, 1, '2025-12-13 18:17:42.218999+02', '- Quam soluta eius cupiditate atque labore modi.
- Quos tempore explicabo iste voluptas laborum pariatur.');
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (23, 1, 72, NULL, NULL, true, 1, '2026-07-06 17:54:38.07391+03', 'Occaecati iusto explicabo excepturi beatae quibusdam', true, 1, '2026-07-06 17:54:38.092545+03', 'Automatically received', false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (24, 1, 73, NULL, NULL, true, 1, '2026-07-07 19:56:30.874243+03', '', true, 1, '2026-07-07 19:56:30.890227+03', 'Automatically received', false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (25, 1, 74, NULL, NULL, true, 1, '2026-07-09 18:53:03.930895+03', 'Occaecati iusto explicabo excepturi beatae quibusdam', true, 1, '2026-07-09 18:53:03.948756+03', 'Automatically received', false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (26, 1, 75, NULL, NULL, true, 1, '2026-07-11 23:02:03.447387+03', 'Occaecati iusto explicabo excepturi beatae quibusdam', true, 1, '2026-07-11 23:02:03.460037+03', 'Automatically received', false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (27, 1, 76, NULL, NULL, true, 1, '2026-07-17 21:45:07.062129+03', 'Veritatis itaque quis soluta labore tenetur', true, 1, '2026-07-17 21:45:07.08018+03', 'Automatically received', false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (28, 1, 127, NULL, NULL, true, 1, '2026-09-12 18:24:23.346017+03', 'Nesciunt sed quibusdam molestiae non.', true, 1, '2026-09-12 18:24:23.391077+03', 'Automatically received', false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (29, 1, 102, NULL, NULL, true, 1, '2026-09-16 22:27:19.140992+03', 'Sunt saepe veniam recusandae ex fuga id', true, 1, '2026-09-16 22:27:19.160927+03', 'Automatically received', false, NULL, NULL, NULL);
INSERT INTO public.receptions OVERRIDING SYSTEM VALUE VALUES (30, 1, 143, NULL, NULL, true, 1, '2026-09-17 15:36:20.977287+03', 'Officia dignissimos tempora commodi ', true, 1, '2026-09-17 15:36:21.01911+03', 'Automatically received', false, NULL, NULL, NULL);


--
-- Data for Name: report_tests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.report_tests VALUES (20, 14, 1, 0, 434, NULL, NULL);
INSERT INTO public.report_tests VALUES (20, 15, 1, 0, 1172.5, NULL, NULL);
INSERT INTO public.report_tests VALUES (20, 15, 2, 0, 239.5, NULL, NULL);
INSERT INTO public.report_tests VALUES (20, 15, 3, 0, 5, NULL, NULL);
INSERT INTO public.report_tests VALUES (21, 2, 2, 0, 212, NULL, NULL);
INSERT INTO public.report_tests VALUES (21, 5, 3, 0, 391.2, NULL, NULL);
INSERT INTO public.report_tests VALUES (21, 9, 1, 0, 3653.6, NULL, NULL);
INSERT INTO public.report_tests VALUES (21, 9, 2, 0, 464.7, NULL, NULL);
INSERT INTO public.report_tests VALUES (21, 9, 3, 0, 8, NULL, NULL);
INSERT INTO public.report_tests VALUES (22, 16, 1, 0, 5467, NULL, NULL);
INSERT INTO public.report_tests VALUES (22, 17, 3, 0, 1134, NULL, NULL);
INSERT INTO public.report_tests VALUES (22, 31, 1, 0, 4654, NULL, NULL);
INSERT INTO public.report_tests VALUES (23, 19, 1, 0, 156, NULL, NULL);
INSERT INTO public.report_tests VALUES (23, 20, 1, 0, 789, NULL, NULL);
INSERT INTO public.report_tests VALUES (23, 21, 1, 0, 40646.3, NULL, NULL);
INSERT INTO public.report_tests VALUES (23, 21, 2, 0, 545.7, NULL, NULL);
INSERT INTO public.report_tests VALUES (23, 21, 3, 0, 89, NULL, NULL);
INSERT INTO public.report_tests VALUES (24, 40, 28, 0, 1999.67, NULL, NULL);
INSERT INTO public.report_tests VALUES (24, 40, 38, 0, 2, NULL, NULL);
INSERT INTO public.report_tests VALUES (24, 40, 37, 0, 224422, NULL, NULL);
INSERT INTO public.report_tests VALUES (24, 40, 37, 1, 336633, NULL, NULL);
INSERT INTO public.report_tests VALUES (24, 40, 37, 2, 44844, NULL, NULL);
INSERT INTO public.report_tests VALUES (25, 39, 3, 0, 150, NULL, NULL);
INSERT INTO public.report_tests VALUES (25, 39, 4, 0, 600.5, NULL, NULL);
INSERT INTO public.report_tests VALUES (25, 46, 3, 0, 454.34, NULL, NULL);
INSERT INTO public.report_tests VALUES (25, 46, 28, 0, 175.5, NULL, NULL);
INSERT INTO public.report_tests VALUES (25, 46, 37, 0, 111, NULL, NULL);
INSERT INTO public.report_tests VALUES (25, 46, 37, 1, 333, NULL, NULL);
INSERT INTO public.report_tests VALUES (25, 46, 37, 2, 444, NULL, NULL);
INSERT INTO public.report_tests VALUES (25, 46, 38, 0, 3, NULL, NULL);
INSERT INTO public.report_tests VALUES (25, 46, 41, 0, 1, NULL, NULL);
INSERT INTO public.report_tests VALUES (26, 47, 28, 0, 252.4, NULL, NULL);
INSERT INTO public.report_tests VALUES (26, 47, 37, 0, 222, NULL, NULL);
INSERT INTO public.report_tests VALUES (26, 47, 37, 1, 333, NULL, NULL);
INSERT INTO public.report_tests VALUES (26, 47, 38, 0, 3, NULL, NULL);
INSERT INTO public.report_tests VALUES (27, 48, 28, 0, 192.6, NULL, NULL);
INSERT INTO public.report_tests VALUES (27, 48, 37, 0, 333, NULL, NULL);
INSERT INTO public.report_tests VALUES (27, 48, 37, 1, 444, NULL, NULL);
INSERT INTO public.report_tests VALUES (27, 48, 38, 0, 2, NULL, NULL);
INSERT INTO public.report_tests VALUES (28, 48, 28, 0, 192.6, NULL, NULL);
INSERT INTO public.report_tests VALUES (28, 48, 37, 0, 333, NULL, NULL);
INSERT INTO public.report_tests VALUES (28, 48, 37, 1, 444, NULL, NULL);
INSERT INTO public.report_tests VALUES (28, 48, 38, 0, 2, NULL, NULL);
INSERT INTO public.report_tests VALUES (28, 49, 3, 0, 862.4, NULL, NULL);
INSERT INTO public.report_tests VALUES (29, 54, 51, 0, 44.4, NULL, NULL);
INSERT INTO public.report_tests VALUES (29, 54, 52, 0, 2, NULL, NULL);
INSERT INTO public.report_tests VALUES (30, 55, 55, 0, 25, NULL, NULL);
INSERT INTO public.report_tests VALUES (30, 55, 56, 0, 3.27, NULL, NULL);
INSERT INTO public.report_tests VALUES (30, 55, 57, 0, 4, NULL, NULL);
INSERT INTO public.report_tests VALUES (31, 56, 62, 0, 0.4, NULL, NULL);
INSERT INTO public.report_tests VALUES (31, 56, 63, 0, 0.4, NULL, NULL);
INSERT INTO public.report_tests VALUES (31, 56, 64, 0, 0.032, NULL, NULL);
INSERT INTO public.report_tests VALUES (31, 56, 65, 0, 5, NULL, NULL);
INSERT INTO public.report_tests VALUES (31, 56, 62, 4, 0.36, NULL, NULL);
INSERT INTO public.report_tests VALUES (31, 56, 62, 3, 0.44, NULL, NULL);
INSERT INTO public.report_tests VALUES (31, 56, 62, 2, 0.42, NULL, NULL);
INSERT INTO public.report_tests VALUES (31, 56, 62, 1, 0.38, NULL, NULL);
INSERT INTO public.report_tests VALUES (32, 57, 66, 0, 52.1, NULL, NULL);
INSERT INTO public.report_tests VALUES (32, 57, 66, 1, 49.5, NULL, NULL);
INSERT INTO public.report_tests VALUES (32, 57, 66, 2, 50.8, NULL, NULL);
INSERT INTO public.report_tests VALUES (32, 57, 66, 3, 51.6, NULL, NULL);
INSERT INTO public.report_tests VALUES (32, 57, 72, 0, 51.0, NULL, NULL);
INSERT INTO public.report_tests VALUES (32, 57, 73, 0, 2.312, NULL, NULL);
INSERT INTO public.report_tests VALUES (32, 57, 73, 1, 2.298, NULL, NULL);
INSERT INTO public.report_tests VALUES (32, 57, 73, 2, 2.325, NULL, NULL);
INSERT INTO public.report_tests VALUES (32, 57, 73, 3, 2.305, NULL, NULL);
INSERT INTO public.report_tests VALUES (32, 57, 74, 0, 0.47, NULL, NULL);
INSERT INTO public.report_tests VALUES (32, 57, 75, 0, 4, NULL, NULL);
INSERT INTO public.report_tests VALUES (32, 57, 76, 0, 93.9, NULL, NULL);
INSERT INTO public.report_tests VALUES (33, 58, 78, 0, 5015, NULL, NULL);
INSERT INTO public.report_tests VALUES (33, 58, 85, 0, 0, NULL, NULL);
INSERT INTO public.report_tests VALUES (33, 58, 86, 0, 250, NULL, NULL);
INSERT INTO public.report_tests VALUES (33, 58, 87, 0, 1750, NULL, NULL);
INSERT INTO public.report_tests VALUES (33, 58, 88, 0, 1500, NULL, NULL);
INSERT INTO public.report_tests VALUES (33, 58, 89, 0, 1010, NULL, NULL);
INSERT INTO public.report_tests VALUES (33, 58, 90, 0, 500, NULL, NULL);
INSERT INTO public.report_tests VALUES (33, 58, 91, 0, 100, NULL, NULL);
INSERT INTO public.report_tests VALUES (33, 58, 92, 0, 95, NULL, NULL);
INSERT INTO public.report_tests VALUES (33, 58, 93, 0, 60, NULL, NULL);
INSERT INTO public.report_tests VALUES (33, 58, 94, 0, 30, NULL, NULL);
INSERT INTO public.report_tests VALUES (33, 58, 95, 0, 10.1, NULL, NULL);
INSERT INTO public.report_tests VALUES (33, 58, 96, 0, 0.10, NULL, NULL);
INSERT INTO public.report_tests VALUES (34, 59, 102, 0, 21.5, NULL, NULL);
INSERT INTO public.report_tests VALUES (34, 59, 103, 0, 48.2, NULL, NULL);
INSERT INTO public.report_tests VALUES (34, 59, 112, 0, 0.099703, NULL, NULL);
INSERT INTO public.report_tests VALUES (34, 59, 114, 0, 0.10, NULL, NULL);
INSERT INTO public.report_tests VALUES (34, 59, 117, 0, 3, NULL, NULL);
INSERT INTO public.report_tests VALUES (35, 60, 102, 0, 21.5, NULL, NULL);
INSERT INTO public.report_tests VALUES (35, 60, 103, 0, 48.2, NULL, NULL);
INSERT INTO public.report_tests VALUES (35, 60, 104, 0, 0.51, NULL, NULL);
INSERT INTO public.report_tests VALUES (35, 60, 128, 0, 0.0638, NULL, NULL);
INSERT INTO public.report_tests VALUES (35, 60, 129, 0, 0.02, NULL, NULL);
INSERT INTO public.report_tests VALUES (35, 60, 130, 0, 3, NULL, NULL);
INSERT INTO public.report_tests VALUES (35, 60, 131, 0, 0.200, NULL, NULL);
INSERT INTO public.report_tests VALUES (35, 60, 135, 0, 0.0417, NULL, NULL);
INSERT INTO public.report_tests VALUES (35, 60, 136, 0, 0.2500, NULL, NULL);
INSERT INTO public.report_tests VALUES (36, 61, 102, 0, 21.5, NULL, NULL);
INSERT INTO public.report_tests VALUES (36, 61, 103, 0, 52, NULL, NULL);
INSERT INTO public.report_tests VALUES (36, 61, 104, 0, 0.51, NULL, NULL);
INSERT INTO public.report_tests VALUES (36, 61, 105, 0, 96.2, NULL, NULL);
INSERT INTO public.report_tests VALUES (36, 61, 143, 0, 100.200000, NULL, NULL);


--
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (20, 1, true, 1, '2025-12-13 18:17:42.218999+02', 'quisquam hic eius iste aliquid ', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (21, 2, true, 1, '2025-12-13 18:17:42.218999+02', 'dolore ad quibusdam ea temporibus', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (22, 3, true, 1, '2025-12-13 18:17:42.218999+02', 'ipsa dolorem a rem est fugiat', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (23, 8, true, 1, '2025-12-13 18:17:42.218999+02', 'optio praesentium quidem impedit molestiae reprehenderit', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (24, 20, true, 1, '2025-12-13 18:17:42.218999+02', 'reprehenderit itaque eius ', NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'Replaced by new report #25');
INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (25, 20, true, 1, '2025-12-13 18:17:42.218999+02', 'soluta reiciendis ipsam optio suscipit officia ', 24, false, NULL, NULL, NULL);
INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (26, 21, true, 1, '2025-12-13 18:17:42.218999+02', 'velit autem minima dolore', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (27, 22, true, 1, '2025-12-13 18:17:42.218999+02', 'quia quia magni a veritatis', NULL, true, 1, '2025-12-13 18:17:42.218999+02', 'Replaced by new report #28');
INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (28, 22, true, 1, '2025-12-13 18:17:42.218999+02', 'libero perspiciatis laboriosam iusto similique', 27, false, NULL, NULL, NULL);
INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (29, 23, true, 1, '2026-07-06 19:38:26.681426+03', 'Occaecati iusto explicabo excepturi beatae quibusdam', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (30, 24, true, 1, '2026-07-07 20:03:14.961252+03', 'Occaecati iusto explicabo excepturi beatae quibusdam', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (31, 25, true, 1, '2026-07-10 01:38:28.67761+03', 'Occaecati iusto explicabo excepturi beatae quibusdam', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (32, 26, true, 1, '2026-07-11 23:06:01.264019+03', 'Occaecati iusto explicabo excepturi beatae quibusdam', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (33, 27, true, 1, '2026-07-17 22:00:16.161079+03', 'Occaecati iusto explicabo excepturi beatae quibusdam', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (34, 28, true, 1, '2026-09-15 21:29:01.088395+03', 'Consequuntur iusto optio impedit iusto nihil quia', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (35, 29, true, 1, '2026-09-16 22:47:00.112933+03', 'Occaecati iusto explicabo excepturi beatae quibusdam', NULL, false, NULL, NULL, NULL);
INSERT INTO public.reports OVERRIDING SYSTEM VALUE VALUES (36, 30, true, 1, '2026-09-17 15:44:36.667571+03', 'Sunt saepe veniam recusandae ex fuga id', NULL, false, NULL, NULL, NULL);


--
-- Data for Name: sop_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (1, 1, '1.0', 'EDMS-SOP-N1-01-V1_0', 'Initial superseded draft version', false, '2026-08-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (2, 1, '2.0', 'EDMS-SOP-N1-01-V2_0', 'Current active version approved for testing', true, '2026-09-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (3, 2, '1.0', 'EDMS-SOP-N1-02-V1_0', 'Initial superseded draft version', false, '2026-07-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (4, 2, '2.0', 'EDMS-SOP-N1-02-V2_0', 'Current active version approved for testing', true, '2026-08-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (5, 3, '1.0', 'EDMS-SOP-N1-03-V1_0', 'Initial superseded draft version', false, '2026-06-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (6, 3, '2.0', 'EDMS-SOP-N1-03-V2_0', 'Current active version approved for testing', true, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (7, 4, '1.0', 'EDMS-SOP-N1-04-V1_0', 'Initial superseded draft version', false, '2026-05-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (8, 4, '2.0', 'EDMS-SOP-N1-04-V2_0', 'Current active version approved for testing', true, '2026-06-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (9, 5, '1.0', 'EDMS-SOP-N1-05-V1_0', 'Initial superseded draft version', false, '2026-04-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (10, 5, '2.0', 'EDMS-SOP-N1-05-V2_0', 'Current active version approved for testing', true, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (11, 6, '1.0', 'EDMS-SOP-N2-01-V1_0', 'Initial superseded draft version', false, '2026-08-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (12, 6, '2.0', 'EDMS-SOP-N2-01-V2_0', 'Current active version approved for testing', true, '2026-09-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (13, 7, '1.0', 'EDMS-SOP-N2-02-V1_0', 'Initial superseded draft version', false, '2026-07-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (14, 7, '2.0', 'EDMS-SOP-N2-02-V2_0', 'Current active version approved for testing', true, '2026-08-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (15, 8, '1.0', 'EDMS-SOP-N2-03-V1_0', 'Initial superseded draft version', false, '2026-06-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (16, 8, '2.0', 'EDMS-SOP-N2-03-V2_0', 'Current active version approved for testing', true, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (17, 9, '1.0', 'EDMS-SOP-N2-04-V1_0', 'Initial superseded draft version', false, '2026-05-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (18, 9, '2.0', 'EDMS-SOP-N2-04-V2_0', 'Current active version approved for testing', true, '2026-06-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (19, 10, '1.0', 'EDMS-SOP-N3-01-V1_0', 'Initial superseded draft version', false, '2026-08-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (20, 10, '2.0', 'EDMS-SOP-N3-01-V2_0', 'Current active version approved for testing', true, '2026-09-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (21, 11, '1.0', 'EDMS-SOP-N3-02-V1_0', 'Initial superseded draft version', false, '2026-07-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (22, 11, '2.0', 'EDMS-SOP-N3-02-V2_0', 'Current active version approved for testing', true, '2026-08-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (23, 12, '1.0', 'EDMS-SOP-N3-03-V1_0', 'Initial superseded draft version', false, '2026-06-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (24, 12, '2.0', 'EDMS-SOP-N3-03-V2_0', 'Current active version approved for testing', true, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (25, 13, '1.0', 'EDMS-SOP-N3-04-V1_0', 'Initial superseded draft version', false, '2026-05-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (26, 13, '2.0', 'EDMS-SOP-N3-04-V2_0', 'Current active version approved for testing', true, '2026-06-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (27, 14, '1.0', 'EDMS-SOP-N3-05-V1_0', 'Initial superseded draft version', false, '2026-04-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (28, 14, '2.0', 'EDMS-SOP-N3-05-V2_0', 'Current active version approved for testing', true, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (29, 15, '1.0', 'EDMS-SOP-N4-01-V1_0', 'Initial superseded draft version', false, '2026-08-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (30, 15, '2.0', 'EDMS-SOP-N4-01-V2_0', 'Current active version approved for testing', true, '2026-09-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (31, 16, '1.0', 'EDMS-SOP-N4-02-V1_0', 'Initial superseded draft version', false, '2026-07-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (32, 16, '2.0', 'EDMS-SOP-N4-02-V2_0', 'Current active version approved for testing', true, '2026-08-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (33, 17, '1.0', 'EDMS-SOP-N4-03-V1_0', 'Initial superseded draft version', false, '2026-06-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (34, 17, '2.0', 'EDMS-SOP-N4-03-V2_0', 'Current active version approved for testing', true, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (35, 18, '1.0', 'EDMS-SOP-N4-04-V1_0', 'Initial superseded draft version', false, '2026-05-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (36, 18, '2.0', 'EDMS-SOP-N4-04-V2_0', 'Current active version approved for testing', true, '2026-06-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (37, 19, '1.0', 'EDMS-SOP-N6-01-V1_0', 'Initial superseded draft version', false, '2026-08-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (38, 19, '2.0', 'EDMS-SOP-N6-01-V2_0', 'Current active version approved for testing', true, '2026-09-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (39, 20, '1.0', 'EDMS-SOP-N6-02-V1_0', 'Initial superseded draft version', false, '2026-07-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (40, 20, '2.0', 'EDMS-SOP-N6-02-V2_0', 'Current active version approved for testing', true, '2026-08-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (41, 21, '1.0', 'EDMS-SOP-N6-03-V1_0', 'Initial superseded draft version', false, '2026-06-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (42, 21, '2.0', 'EDMS-SOP-N6-03-V2_0', 'Current active version approved for testing', true, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (43, 22, '1.0', 'EDMS-SOP-N6-04-V1_0', 'Initial superseded draft version', false, '2026-05-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (44, 22, '2.0', 'EDMS-SOP-N6-04-V2_0', 'Current active version approved for testing', true, '2026-06-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (45, 23, '1.0', 'EDMS-SOP-N5-01-V1_0', 'Initial superseded draft version', false, '2026-08-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (46, 23, '2.0', 'EDMS-SOP-N5-01-V2_0', 'Current active version approved for testing', true, '2026-09-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (47, 24, '1.0', 'EDMS-SOP-N5-02-V1_0', 'Initial superseded draft version', false, '2026-07-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (48, 24, '2.0', 'EDMS-SOP-N5-02-V2_0', 'Current active version approved for testing', true, '2026-08-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (49, 25, '1.0', 'EDMS-SOP-N5-03-V1_0', 'Initial superseded draft version', false, '2026-06-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (50, 25, '2.0', 'EDMS-SOP-N5-03-V2_0', 'Current active version approved for testing', true, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (51, 26, '1.0', 'EDMS-SOP-N5-04-V1_0', 'Initial superseded draft version', false, '2026-05-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (52, 26, '2.0', 'EDMS-SOP-N5-04-V2_0', 'Current active version approved for testing', true, '2026-06-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (53, 27, '1.0', 'EDMS-SOP-N5-05-V1_0', 'Initial superseded draft version', false, '2026-04-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (54, 27, '2.0', 'EDMS-SOP-N5-05-V2_0', 'Current active version approved for testing', true, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (55, 28, '1.0', 'EDMS-SOP-N7-01-V1_0', 'Initial superseded draft version', false, '2026-08-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (56, 28, '2.0', 'EDMS-SOP-N7-01-V2_0', 'Current active version approved for testing', true, '2026-09-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (57, 29, '1.0', 'EDMS-SOP-N7-02-V1_0', 'Initial superseded draft version', false, '2026-07-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (58, 29, '2.0', 'EDMS-SOP-N7-02-V2_0', 'Current active version approved for testing', true, '2026-08-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (59, 30, '1.0', 'EDMS-SOP-N7-03-V1_0', 'Initial superseded draft version', false, '2026-06-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (60, 30, '2.0', 'EDMS-SOP-N7-03-V2_0', 'Current active version approved for testing', true, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (61, 31, '1.0', 'EDMS-SOP-N7-04-V1_0', 'Initial superseded draft version', false, '2026-05-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (62, 31, '2.0', 'EDMS-SOP-N7-04-V2_0', 'Current active version approved for testing', true, '2026-06-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (63, 32, '1.0', 'EDMS-SOP-N7-05-V1_0', 'Initial superseded draft version', false, '2026-04-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (64, 32, '2.0', 'EDMS-SOP-N7-05-V2_0', 'Current active version approved for testing', true, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (65, 33, '1.0', 'EDMS-SOP-N8-01-V1_0', 'Initial superseded draft version', false, '2026-08-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (66, 33, '2.0', 'EDMS-SOP-N8-01-V2_0', 'Current active version approved for testing', true, '2026-09-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (67, 34, '1.0', 'EDMS-SOP-N8-02-V1_0', 'Initial superseded draft version', false, '2026-07-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (68, 34, '2.0', 'EDMS-SOP-N8-02-V2_0', 'Current active version approved for testing', true, '2026-08-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (69, 35, '1.0', 'EDMS-SOP-N8-03-V1_0', 'Initial superseded draft version', false, '2026-06-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (70, 35, '2.0', 'EDMS-SOP-N8-03-V2_0', 'Current active version approved for testing', true, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (71, 36, '1.0', 'EDMS-SOP-N8-04-V1_0', 'Initial superseded draft version', false, '2026-05-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (72, 36, '2.0', 'EDMS-SOP-N8-04-V2_0', 'Current active version approved for testing', true, '2026-06-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (73, 37, '1.0', 'EDMS-SOP-N9-01-V1_0', 'Initial superseded draft version', false, '2026-08-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (74, 37, '2.0', 'EDMS-SOP-N9-01-V2_0', 'Current active version approved for testing', true, '2026-09-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (75, 38, '1.0', 'EDMS-SOP-N9-02-V1_0', 'Initial superseded draft version', false, '2026-07-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (76, 38, '2.0', 'EDMS-SOP-N9-02-V2_0', 'Current active version approved for testing', true, '2026-08-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (77, 39, '1.0', 'EDMS-SOP-N9-03-V1_0', 'Initial superseded draft version', false, '2026-06-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (78, 39, '2.0', 'EDMS-SOP-N9-03-V2_0', 'Current active version approved for testing', true, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (79, 40, '1.0', 'EDMS-SOP-N9-04-V1_0', 'Initial superseded draft version', false, '2026-05-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (80, 40, '2.0', 'EDMS-SOP-N9-04-V2_0', 'Current active version approved for testing', true, '2026-06-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (81, 41, '1.0', 'EDMS-SOP-N9-05-V1_0', 'Initial superseded draft version', false, '2026-04-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (82, 41, '2.0', 'EDMS-SOP-N9-05-V2_0', 'Current active version approved for testing', true, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (83, 42, '1.0', 'EDMS-SOP-N10-01-V1_0', 'Initial superseded draft version', false, '2026-08-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (84, 42, '2.0', 'EDMS-SOP-N10-01-V2_0', 'Current active version approved for testing', true, '2026-09-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (85, 43, '1.0', 'EDMS-SOP-N10-02-V1_0', 'Initial superseded draft version', false, '2026-07-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (86, 43, '2.0', 'EDMS-SOP-N10-02-V2_0', 'Current active version approved for testing', true, '2026-08-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (87, 44, '1.0', 'EDMS-SOP-N10-03-V1_0', 'Initial superseded draft version', false, '2026-06-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (88, 44, '2.0', 'EDMS-SOP-N10-03-V2_0', 'Current active version approved for testing', true, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (89, 45, '1.0', 'EDMS-SOP-N10-04-V1_0', 'Initial superseded draft version', false, '2026-05-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (90, 45, '2.0', 'EDMS-SOP-N10-04-V2_0', 'Current active version approved for testing', true, '2026-06-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (91, 46, '1.0', 'EDMS-SOP-N11-01-V1_0', 'Initial superseded draft version', false, '2026-08-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (92, 46, '2.0', 'EDMS-SOP-N11-01-V2_0', 'Current active version approved for testing', true, '2026-09-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (93, 47, '1.0', 'EDMS-SOP-N11-02-V1_0', 'Initial superseded draft version', false, '2026-07-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (94, 47, '2.0', 'EDMS-SOP-N11-02-V2_0', 'Current active version approved for testing', true, '2026-08-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (95, 48, '1.0', 'EDMS-SOP-N11-03-V1_0', 'Initial superseded draft version', false, '2026-06-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (96, 48, '2.0', 'EDMS-SOP-N11-03-V2_0', 'Current active version approved for testing', true, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (97, 49, '1.0', 'EDMS-SOP-N11-04-V1_0', 'Initial superseded draft version', false, '2026-05-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (98, 49, '2.0', 'EDMS-SOP-N11-04-V2_0', 'Current active version approved for testing', true, '2026-06-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (99, 50, '1.0', 'EDMS-SOP-N11-05-V1_0', 'Initial superseded draft version', false, '2026-04-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (100, 50, '2.0', 'EDMS-SOP-N11-05-V2_0', 'Current active version approved for testing', true, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (101, 51, '1.0', 'EDMS-SOP-N12-01-V1_0', 'Initial superseded draft version', false, '2026-08-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (102, 51, '2.0', 'EDMS-SOP-N12-01-V2_0', 'Current active version approved for testing', true, '2026-09-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (103, 52, '1.0', 'EDMS-SOP-N12-02-V1_0', 'Initial superseded draft version', false, '2026-07-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (104, 52, '2.0', 'EDMS-SOP-N12-02-V2_0', 'Current active version approved for testing', true, '2026-08-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (105, 53, '1.0', 'EDMS-SOP-N12-03-V1_0', 'Initial superseded draft version', false, '2026-06-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (106, 53, '2.0', 'EDMS-SOP-N12-03-V2_0', 'Current active version approved for testing', true, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (107, 54, '1.0', 'EDMS-SOP-N12-04-V1_0', 'Initial superseded draft version', false, '2026-05-04 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (108, 54, '2.0', 'EDMS-SOP-N12-04-V2_0', 'Current active version approved for testing', true, '2026-06-02 23:41:34.840384+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (109, 55, '1.0', 'SOP-COD-001-V1', 'Initial publication.', false, '2022-01-15 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (110, 56, '1.0', 'SOP-COD-002-V1', 'Initial publication.', false, '2022-01-15 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (111, 57, '1.0', 'SOP-COD-003-V1', 'Initial publication.', false, '2022-01-15 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (112, 58, '1.0', 'SOP-COD-004-V1', 'Initial publication.', false, '2022-01-15 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (113, 59, '1.0', 'SOP-COD-005-V1', 'Initial publication.', false, '2022-01-15 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (114, 60, '1.0', 'SOP-ENV-001-V1', 'Initial publication.', false, '2022-01-15 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (115, 61, '1.0', 'SOP-ENV-002-V1', 'Initial publication.', false, '2022-01-15 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (116, 62, '1.0', 'SOP-EQP-001-V1', 'Initial publication.', false, '2022-01-15 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (117, 63, '1.0', 'SOP-QC-001-V1', 'Initial publication.', false, '2022-01-15 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (118, 64, '1.0', 'SOP-DAT-001-V1', 'Initial publication.', false, '2022-01-15 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (119, 55, '2.0', 'SOP-COD-001-V2', 'Periodic review update conforming to ISO/IEC 17025:2017.', true, '2024-01-10 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (120, 56, '2.0', 'SOP-COD-002-V2', 'Periodic review update conforming to ISO/IEC 17025:2017.', true, '2024-01-10 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (121, 57, '2.0', 'SOP-COD-003-V2', 'Periodic review update conforming to ISO/IEC 17025:2017.', true, '2024-01-10 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (122, 58, '2.0', 'SOP-COD-004-V2', 'Periodic review update conforming to ISO/IEC 17025:2017.', true, '2024-01-10 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (123, 59, '2.0', 'SOP-COD-005-V2', 'Periodic review update conforming to ISO/IEC 17025:2017.', true, '2024-01-10 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (124, 60, '2.0', 'SOP-ENV-001-V2', 'Periodic review update conforming to ISO/IEC 17025:2017.', true, '2024-01-10 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (125, 61, '2.0', 'SOP-ENV-002-V2', 'Periodic review update conforming to ISO/IEC 17025:2017.', true, '2024-01-10 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (126, 62, '2.0', 'SOP-EQP-001-V2', 'Periodic review update conforming to ISO/IEC 17025:2017.', true, '2024-01-10 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (127, 63, '2.0', 'SOP-QC-001-V2', 'Periodic review update conforming to ISO/IEC 17025:2017.', true, '2024-01-10 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (128, 64, '2.0', 'SOP-DAT-001-V2', 'Periodic review update conforming to ISO/IEC 17025:2017.', true, '2024-01-10 12:00:00+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (129, 65, '2.0', 'EDMS-2025-014', 'Updated dual-zone temp validation parameters', true, '2026-03-09 15:21:56.121192+02');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (130, 65, '1.0', 'EDMS-2024-001', 'Initial release', false, '2024-09-09 15:21:56.121192+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (131, 66, '2.0', 'EDMS-2025-015', 'Revised FAS standardization and KHP check protocol', true, '2026-04-09 15:21:56.121192+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (132, 66, '1.0', 'EDMS-2024-002', 'Initial release', false, '2024-09-09 15:21:56.121192+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (133, 67, '2.0', 'EDMS-2025-016', 'Updated dispension volume uncertainty tolerances', true, '2026-05-09 15:21:56.121192+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (134, 67, '1.0', 'EDMS-2024-003', 'Initial release', false, '2024-09-09 15:21:56.121192+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (135, 68, '2.0', 'EDMS-2025-017', 'Added daily internal check procedure', true, '2026-06-09 15:21:56.121192+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (136, 68, '1.0', 'EDMS-2024-004', 'Initial release', false, '2024-09-09 15:21:56.121192+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (137, 69, '2.0', 'EDMS-2025-018', 'Included fume hood face velocity verification procedures', true, '2026-07-09 15:21:56.121192+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (138, 69, '1.0', 'EDMS-2024-005', 'Initial release', false, '2024-09-09 15:21:56.121192+03');
INSERT INTO public.sop_versions OVERRIDING SYSTEM VALUE VALUES (139, 70, '1.0', 'EDMS-12345', 'Consequuntur iusto optio impedit iusto nihil quia', true, '2026-09-16 21:37:01.390793+03');


--
-- Data for Name: sops; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (1, 'SOP-N1-01', 'SOP 1 for Norm A', 1, '2026-08-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (2, 'SOP-N1-02', 'SOP 2 for Norm A', 1, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (3, 'SOP-N1-03', 'SOP 3 for Norm A', 1, '2026-06-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (4, 'SOP-N1-04', 'SOP 4 for Norm A', 1, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (5, 'SOP-N1-05', 'SOP 5 for Norm A', 1, '2026-04-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (6, 'SOP-N2-01', 'SOP 1 for Norm B', 2, '2026-08-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (7, 'SOP-N2-02', 'SOP 2 for Norm B', 2, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (8, 'SOP-N2-03', 'SOP 3 for Norm B', 2, '2026-06-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (9, 'SOP-N2-04', 'SOP 4 for Norm B', 2, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (10, 'SOP-N3-01', 'SOP 1 for Norm C', 3, '2026-08-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (11, 'SOP-N3-02', 'SOP 2 for Norm C', 3, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (12, 'SOP-N3-03', 'SOP 3 for Norm C', 3, '2026-06-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (13, 'SOP-N3-04', 'SOP 4 for Norm C', 3, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (14, 'SOP-N3-05', 'SOP 5 for Norm C', 3, '2026-04-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (15, 'SOP-N4-01', 'SOP 1 for Norm D', 4, '2026-08-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (16, 'SOP-N4-02', 'SOP 2 for Norm D', 4, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (17, 'SOP-N4-03', 'SOP 3 for Norm D', 4, '2026-06-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (18, 'SOP-N4-04', 'SOP 4 for Norm D', 4, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (19, 'SOP-N6-01', 'SOP 1 for ASTM C42', 6, '2026-08-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (20, 'SOP-N6-02', 'SOP 2 for ASTM C42', 6, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (21, 'SOP-N6-03', 'SOP 3 for ASTM C42', 6, '2026-06-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (22, 'SOP-N6-04', 'SOP 4 for ASTM C42', 6, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (23, 'SOP-N5-01', 'SOP 1 for ASTM C39', 5, '2026-08-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (24, 'SOP-N5-02', 'SOP 2 for ASTM C39', 5, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (25, 'SOP-N5-03', 'SOP 3 for ASTM C39', 5, '2026-06-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (26, 'SOP-N5-04', 'SOP 4 for ASTM C39', 5, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (27, 'SOP-N5-05', 'SOP 5 for ASTM C39', 5, '2026-04-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (28, 'SOP-N7-01', 'SOP 1 for EPA Method 160.2', 7, '2026-08-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (29, 'SOP-N7-02', 'SOP 2 for EPA Method 160.2', 7, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (30, 'SOP-N7-03', 'SOP 3 for EPA Method 160.2', 7, '2026-06-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (31, 'SOP-N7-04', 'SOP 4 for EPA Method 160.2', 7, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (32, 'SOP-N7-05', 'SOP 5 for EPA Method 160.2', 7, '2026-04-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (33, 'SOP-N8-01', 'SOP 1 for USP <731> / EP 2.2.32', 8, '2026-08-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (34, 'SOP-N8-02', 'SOP 2 for USP <731> / EP 2.2.32', 8, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (35, 'SOP-N8-03', 'SOP 3 for USP <731> / EP 2.2.32', 8, '2026-06-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (36, 'SOP-N8-04', 'SOP 4 for USP <731> / EP 2.2.32', 8, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (37, 'SOP-N9-01', 'SOP 1 for ASTM D3549', 9, '2026-08-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (38, 'SOP-N9-02', 'SOP 2 for ASTM D3549', 9, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (39, 'SOP-N9-03', 'SOP 3 for ASTM D3549', 9, '2026-06-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (40, 'SOP-N9-04', 'SOP 4 for ASTM D3549', 9, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (41, 'SOP-N9-05', 'SOP 5 for ASTM D3549', 9, '2026-04-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (42, 'SOP-N10-01', 'SOP 1 for AASHTO T 166', 10, '2026-08-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (43, 'SOP-N10-02', 'SOP 2 for AASHTO T 166', 10, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (44, 'SOP-N10-03', 'SOP 3 for AASHTO T 166', 10, '2026-06-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (45, 'SOP-N10-04', 'SOP 4 for AASHTO T 166', 10, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (46, 'SOP-N11-01', 'SOP 1 for ASTM C136', 11, '2026-08-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (47, 'SOP-N11-02', 'SOP 2 for ASTM C136', 11, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (48, 'SOP-N11-03', 'SOP 3 for ASTM C136', 11, '2026-06-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (49, 'SOP-N11-04', 'SOP 4 for ASTM C136', 11, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (50, 'SOP-N11-05', 'SOP 5 for ASTM C136', 11, '2026-04-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (51, 'SOP-N12-01', 'SOP 1 for AASHTO T 27', 12, '2026-08-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (52, 'SOP-N12-02', 'SOP 2 for AASHTO T 27', 12, '2026-07-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (53, 'SOP-N12-03', 'SOP 3 for AASHTO T 27', 12, '2026-06-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (54, 'SOP-N12-04', 'SOP 4 for AASHTO T 27', 12, '2026-05-03 23:41:34.840384+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (55, 'SOP-COD-001', 'Operational Procedure for COD Digestion Block', 13, '2022-01-10 11:00:00+02');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (56, 'SOP-COD-002', 'Closed Reflux Titrimetric Method for Chemical Oxygen Demand', 13, '2021-06-01 12:00:00+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (57, 'SOP-COD-003', 'Daily Standardization of Ferrous Ammonium Sulfate (FAS) Titrant', 13, '2022-02-14 11:00:00+02');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (58, 'SOP-COD-004', 'Preparation and Certification of KHP Quality Control Standards', 13, '2021-09-05 12:00:00+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (59, 'SOP-COD-005', 'Reagent Blank and Analytical Batch QC Validation Rules', 13, '2022-05-18 12:00:00+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (60, 'SOP-ENV-001', 'Monitoring and Logging Ambient Temperature and Relative Humidity', 14, '2020-04-10 12:00:00+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (61, 'SOP-ENV-002', 'Fume Hood Airflow Velocity Calibration and Maintenance Protocol', 14, '2021-03-01 11:00:00+02');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (62, 'SOP-EQP-001', 'Equipment Calibration Schedule, Maintenance, and Metrological Traceability', 14, '2020-11-12 11:00:00+02');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (63, 'SOP-QC-001', 'Estimation of Measurement Uncertainty in Titrimetric Analysis', 14, '2021-08-20 12:00:00+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (64, 'SOP-DAT-001', 'Technical Records Integrity, Audit Trails, and LIMS Data Logging Rules', 14, '2022-01-15 11:00:00+02');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (65, 'SOP-COD-006', 'Standard Operating Procedure for COD Digestion Block Operation', 13, '2026-09-09 15:21:56.121192+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (66, 'SOP-COD-007', 'Standard Operating Procedure for Titrimetric COD Determination', 13, '2026-09-09 15:21:56.121192+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (67, 'SOP-COD-008', 'Calibration and Maintenance of Digital Auto-Burettes', 13, '2026-09-09 15:21:56.121192+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (68, 'SOP-COD-009', 'Analytical Balance Operation and Daily Check', 13, '2026-09-09 15:21:56.121192+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (69, 'SOP-COD-010', 'Environmental Monitoring of Chemical Testing Laboratories', 13, '2026-09-09 15:21:56.121192+03');
INSERT INTO public.sops OVERRIDING SYSTEM VALUE VALUES (70, 'SOP-COD-011', 'Preparation And Molarity Verification Of Cod Digestion Solution (K2Cr2O7)', 13, '2026-09-16 21:36:40.546173+03');


--
-- Data for Name: spec_test_evals; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (27, 11, 3, 100, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (28, 11, 3, 58, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (29, 11, 3, 101, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (33, 11, 4, 789, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (34, 11, 4, 1000, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (35, 11, 4, 1001, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (41, 11, 28, 35, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (42, 11, 28, 50, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (43, 11, 28, 75, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (44, 11, 28, 100, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (45, 11, 28, 101, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (46, 11, 37, 100, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (47, 11, 37, 99, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (48, 11, 37, 273, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (49, 11, 37, 500, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (50, 11, 37, 501, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (56, 11, 38, 1, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (57, 11, 38, 2, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (58, 11, 38, 3, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (59, 11, 38, 4, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (60, 11, 38, 5, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (87, 3, 1, 10, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (88, 3, 1, 11, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (89, 3, 1, 99, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (90, 3, 3, 1000, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (91, 3, 3, 999, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (92, 3, 3, 1001, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (93, 3, 3, 527, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (94, 3, 4, 100, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (95, 3, 4, 99, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (96, 3, 4, 101, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (97, 3, 4, 8787, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (98, 3, 4, 2, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (99, 2, 1, 10, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (100, 2, 1, 5, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (101, 2, 1, 11, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (102, 2, 1, 457, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (103, 2, 2, 1000, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (104, 2, 2, 1001, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (105, 2, 2, 999, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (106, 2, 2, 142, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (107, 2, 3, 10, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (108, 2, 3, 11, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (109, 2, 3, 1000, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (110, 2, 3, 999, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (111, 2, 3, 145, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (112, 2, 4, 100, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (113, 2, 4, 99, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (114, 2, 4, 101, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (115, 2, 4, 45, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (116, 2, 4, 145, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (117, 1, 1, 1000, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (118, 1, 1, 999, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (119, 1, 1, 458, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (120, 1, 1, 1254, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (121, 1, 2, 10, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (122, 1, 2, 9, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (123, 1, 2, 11, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (124, 1, 2, 125, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (125, 1, 2, 3, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (126, 1, 3, 100, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (127, 1, 3, 99, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (128, 1, 3, 101, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (129, 1, 3, 55, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (130, 1, 3, 148, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (145, 16, 1, 1000, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (146, 16, 1, 999, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (147, 16, 1, 458, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (148, 16, 1, 1254, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (149, 16, 2, 10, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (150, 16, 2, 9, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (151, 16, 2, 11, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (152, 16, 2, 125, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (153, 16, 2, 3, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (154, 16, 3, 100, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (155, 16, 3, 99, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (156, 16, 3, 101, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (157, 16, 3, 55, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (158, 16, 3, 148, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (159, 17, 3, 100, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (160, 17, 3, 58, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (161, 17, 3, 101, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (162, 17, 4, 789, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (163, 17, 4, 1000, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (164, 17, 4, 1001, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (165, 17, 28, 35, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (166, 17, 28, 50, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (167, 17, 28, 75, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (168, 17, 28, 100, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (169, 17, 28, 101, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (170, 17, 37, 100, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (171, 17, 37, 99, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (172, 17, 37, 273, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (173, 17, 37, 500, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (174, 17, 37, 501, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (175, 17, 38, 1, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (176, 17, 38, 2, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (177, 17, 38, 3, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (178, 17, 38, 4, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (179, 17, 38, 5, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (180, 18, 51, 38, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (181, 18, 51, 40, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (182, 18, 51, 43, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (206, 18, 52, 2.2, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (207, 18, 52, 2.1, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (208, 18, 52, 2, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (209, 18, 52, 1.8, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (210, 18, 52, 1.75, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (211, 18, 52, 1.72, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (212, 19, 55, 25, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (213, 19, 55, 30, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (214, 19, 55, 35, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (215, 19, 56, 3, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (216, 19, 56, 5, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (217, 19, 56, 5.5, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (223, 19, 57, 2, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (224, 19, 57, 3, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (225, 19, 57, 4, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (226, 19, 57, 20, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (227, 19, 57, 22, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (236, 20, 64, 0.048, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (237, 20, 64, 0.05, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (238, 20, 64, 0.054, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (239, 20, 63, 0.4, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (240, 20, 63, 0.5, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (241, 20, 63, 0.52, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (242, 20, 62, 0.4, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (243, 20, 62, 0.5, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (244, 20, 62, 0.53, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (245, 20, 65, 2, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (246, 20, 65, 3, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (247, 20, 65, 4, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (248, 20, 65, 5, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (249, 20, 65, 6, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (250, 21, 66, 43, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (251, 21, 66, 45, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (252, 21, 66, 45.5, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (258, 21, 73, 0, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (259, 21, 73, 1.45, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (263, 21, 75, 2, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (264, 21, 75, 3, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (265, 21, 75, 4, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (266, 21, 76, 91.5, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (267, 21, 76, 92, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (268, 21, 76, 93.5, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (269, 21, 76, 97, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (270, 21, 76, 97.4, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (271, 21, 74, 0.65, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (272, 21, 74, 1.3, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (273, 21, 74, 1.35, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (274, 21, 72, 49.5, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (275, 21, 72, 50, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (276, 21, 72, 50.5, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (277, 22, 78, 4500, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (278, 22, 78, 5000, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (279, 22, 78, 5050, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (280, 22, 91, 95, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (281, 22, 91, 100, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (282, 22, 92, 85, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (283, 22, 92, 90, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (284, 22, 92, 95, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (285, 22, 92, 100, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (286, 22, 93, 35, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (287, 22, 93, 40, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (288, 22, 93, 45, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (289, 22, 93, 65, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (290, 22, 93, 70, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (291, 22, 94, 12, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (292, 22, 94, 15, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (293, 22, 94, 20, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (294, 22, 94, 35, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (295, 22, 94, 42, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (296, 22, 95, 1.7, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (297, 22, 95, 2, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (298, 22, 95, 8, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (299, 22, 95, 12, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (300, 22, 95, 12.5, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (301, 22, 96, 0.28, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (302, 22, 96, 0.3, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (303, 22, 96, 0.32, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (304, 23, 112, 0.094, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (305, 23, 112, 0.095, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (306, 23, 112, 0.1001, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (307, 23, 112, 0.105, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (308, 23, 112, 0.1051, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (309, 24, 135, 0.04116, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (310, 24, 135, 0.04117, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (311, 24, 135, 0.0412, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (312, 24, 135, 0.04217, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (313, 24, 135, 0.04218, 0, 0, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (317, 25, 105, 124.8, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (318, 25, 105, 125, 1, 1, true, NULL);
INSERT INTO public.spec_test_evals OVERRIDING SYSTEM VALUE VALUES (319, 25, 105, 125.2, 0, 0, true, NULL);


--
-- Data for Name: spec_tests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.spec_tests VALUES (2, 1, '[value] > 10', '> 10', false, 2);
INSERT INTO public.spec_tests VALUES (2, 2, '[value] < 1000', '< 1000', false, 1);
INSERT INTO public.spec_tests VALUES (2, 3, '[value] > 10 && [value] < 1000', '> 10 and < 1000', false, 1);
INSERT INTO public.spec_tests VALUES (2, 4, '[value] == 100', '== 100', false, 1);
INSERT INTO public.spec_tests VALUES (1, 2, '[value] > 10', '> 10', false, 2);
INSERT INTO public.spec_tests VALUES (1, 1, '[value] < 1000', '< 1000', false, 1);
INSERT INTO public.spec_tests VALUES (1, 3, '[value] == 100', '== 100', false, 1);
INSERT INTO public.spec_tests VALUES (3, 1, '[value] > 10', '> 10', false, 1);
INSERT INTO public.spec_tests VALUES (3, 3, '[value] < 1000', '< 1000', false, 1);
INSERT INTO public.spec_tests VALUES (3, 4, '[value] == 100', '== 100', false, 1);
INSERT INTO public.spec_tests VALUES (11, 3, '[value] > 100', '> 100', false, 2);
INSERT INTO public.spec_tests VALUES (11, 4, '[value] < 1000', '< 1000', false, 3);
INSERT INTO public.spec_tests VALUES (11, 28, '[value] <= 50 || [value] > 100', '<= 50 or > 100', false, 1);
INSERT INTO public.spec_tests VALUES (11, 37, '[value] > 100 && [value] <= 500', '> 100 and <= 500', false, 1);
INSERT INTO public.spec_tests VALUES (11, 38, '[value] == 2 || [value] == 3 // Item KB or Item KC', '''Item KB'' or ''Item KC''', false, 1);
INSERT INTO public.spec_tests VALUES (16, 1, '[value] < 1000', '< 1000', false, 1);
INSERT INTO public.spec_tests VALUES (16, 2, '[value] > 10', '> 10', false, 2);
INSERT INTO public.spec_tests VALUES (16, 3, '[value] == 100', '== 100', false, 1);
INSERT INTO public.spec_tests VALUES (17, 3, '[value] > 100', '> 100', false, 2);
INSERT INTO public.spec_tests VALUES (17, 4, '[value] < 1000', '< 1000', false, 3);
INSERT INTO public.spec_tests VALUES (17, 28, '[value] <= 50 || [value] > 100', '<= 50 or > 100', false, 1);
INSERT INTO public.spec_tests VALUES (17, 37, '[value] > 100 && [value] <= 500', '> 100 and <= 500', false, 1);
INSERT INTO public.spec_tests VALUES (17, 38, '[value] == 2 || [value] == 3 // Item KB or Item KC', '''Item KB'' or ''Item KC''', false, 1);
INSERT INTO public.spec_tests VALUES (18, 51, '[value] >= 40', '>= 40', false, 1);
INSERT INTO public.spec_tests VALUES (18, 52, '[value] >= 1.75 && [value] <= 2.10', '>= 1.75 and <= 2.10', false, 1);
INSERT INTO public.spec_tests VALUES (19, 55, '[value] <= 30', '<= 30', false, 1);
INSERT INTO public.spec_tests VALUES (19, 56, '[value] <= 5', '<= 5', false, 1);
INSERT INTO public.spec_tests VALUES (19, 57, '[value] >= 3 && [value] <= 20', '>= 3 and <= 20', false, 1);
INSERT INTO public.spec_tests VALUES (20, 64, '[value] <= 0.050', '<= 0.050', false, 1);
INSERT INTO public.spec_tests VALUES (20, 63, '[value] <= 0.50', '<= 0.50', false, 1);
INSERT INTO public.spec_tests VALUES (20, 62, '[value] <= 0.50', '<= 0.50', false, 1);
INSERT INTO public.spec_tests VALUES (20, 65, '[value] >= 3 && [value] <= 5', '>= 3 and <= 5', false, 1);
INSERT INTO public.spec_tests VALUES (21, 66, '[value] >= 45.0', '>= 45.0', false, 1);
INSERT INTO public.spec_tests VALUES (21, 73, '[value] >= 0', '>= 0', false, 1);
INSERT INTO public.spec_tests VALUES (21, 75, '[value] >= 3', '>= 3', false, 1);
INSERT INTO public.spec_tests VALUES (21, 76, '[value] >= 92.0 && [value] <= 97.0', '>= 92.0 and <= 97.0', false, 1);
INSERT INTO public.spec_tests VALUES (21, 74, '[value] <= 1.30', '<= 1.30', false, 1);
INSERT INTO public.spec_tests VALUES (21, 72, '[value] >= 50.0', '>= 50.0', false, 1);
INSERT INTO public.spec_tests VALUES (22, 78, '[value] >= 5000.0', '>= 5000.0', false, 1);
INSERT INTO public.spec_tests VALUES (22, 91, '[value] == 100', '== 100', false, 1);
INSERT INTO public.spec_tests VALUES (22, 92, '[value] >= 90 && [value] <= 100', '>= 90 and <= 100', false, 1);
INSERT INTO public.spec_tests VALUES (22, 93, '[value] >= 40 && [value] <= 65', '>= 40 and <= 65', false, 1);
INSERT INTO public.spec_tests VALUES (22, 94, '[value] >= 15 && [value] <= 35', '>= 15 and <= 35', false, 1);
INSERT INTO public.spec_tests VALUES (22, 95, '[value] >= 2.0 && [value] <= 12.0', '>= 2.0 and <= 12.0', false, 1);
INSERT INTO public.spec_tests VALUES (22, 96, '[value] <= 0.30', '<= 0.30', false, 1);
INSERT INTO public.spec_tests VALUES (23, 112, '[value] >= 0.0950 && [value] <= 0.1050', '>= 0.0950 and <= 0.1050', false, 1);
INSERT INTO public.spec_tests VALUES (24, 135, '[value] >= 0.04117 && [value] <= 0.04217', '>= 0.04117 and <= 0.04217', false, 1);
INSERT INTO public.spec_tests VALUES (25, 105, '[value] <= 125.0', '<= 125.0', false, 1);


--
-- Data for Name: specs; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.specs OVERRIDING SYSTEM VALUE VALUES (1, 3, true, 1, '2025-12-29 18:48:38.884957+02', '- Blanditiis iure ducimus harum facere quidem
- Consequuntur iusto optio impedit iusto nihil quia
- A  hic laboriosam quod consectetur', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs OVERRIDING SYSTEM VALUE VALUES (2, 1, true, 1, '2025-12-29 18:45:15.130498+02', '- Quae sit nobis quisquam laudantium reprehenderit
- Eligendi et provident neque natus', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs OVERRIDING SYSTEM VALUE VALUES (3, 2, true, 1, '2025-12-29 18:36:47.186175+02', '- Doloremque beatae quos
- Vel cum aliquid deserunt tempore', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs OVERRIDING SYSTEM VALUE VALUES (11, 5, true, 1, '2025-12-29 18:21:09.946285+02', 'Voluptatum voluptates laboriosam vel cum quidem.
Perferendis praesentium accusamus mollitia quibusdam praesentium fugiat natus.', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs OVERRIDING SYSTEM VALUE VALUES (16, 3, false, 1, '2025-12-29 18:49:21.202506+02', 'Repudiandae neque officiis #1', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs OVERRIDING SYSTEM VALUE VALUES (17, 5, false, 1, '2025-12-29 18:51:02.864669+02', 'Asperiores accusamus quisquam #11', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs OVERRIDING SYSTEM VALUE VALUES (18, 22, true, 1, '2026-07-06 17:51:06.009122+03', 'Consequuntur iusto optio impedit iusto nihil quia', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs OVERRIDING SYSTEM VALUE VALUES (19, 23, true, 1, '2026-07-07 19:56:07.427749+03', 'Occaecati iusto explicabo excepturi beatae quibusdam', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs OVERRIDING SYSTEM VALUE VALUES (20, 24, true, 1, '2026-07-09 18:51:21.375693+03', 'Officia dignissimos tempora commodi est sunt saepe veniam recusandae ex fuga id', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs OVERRIDING SYSTEM VALUE VALUES (21, 25, true, 1, '2026-07-11 23:01:14.117198+03', 'Officia dignissimos tempora commodi est sunt saepe veniam recusandae ex fuga id', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs OVERRIDING SYSTEM VALUE VALUES (22, 26, true, 1, '2026-07-17 21:44:10.365097+03', 'Occaecati iusto explicabo excepturi beatae quibusdam', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs OVERRIDING SYSTEM VALUE VALUES (23, 27, true, 1, '2026-09-12 18:19:50.101784+03', 'Qui quis eum blanditiis accusantium accusamus.', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs OVERRIDING SYSTEM VALUE VALUES (24, 32, true, 1, '2026-09-16 22:23:44.233063+03', 'Consequuntur iusto optio impedit iusto nihil quia
', NULL, false, NULL, NULL, NULL);
INSERT INTO public.specs OVERRIDING SYSTEM VALUE VALUES (25, 40, true, 1, '2026-09-17 15:12:16.436238+03', 'Sunt saepe veniam recusandae ex fuga id', NULL, false, NULL, NULL, NULL);


--
-- Data for Name: test_enums; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.test_enums VALUES (13, 1, 'Item BA', 1, false);
INSERT INTO public.test_enums VALUES (13, 2, 'Item BB', 2, false);
INSERT INTO public.test_enums VALUES (8, 1, 'Item AA', 1, false);
INSERT INTO public.test_enums VALUES (8, 2, 'Item AB', 2, false);
INSERT INTO public.test_enums VALUES (8, 3, 'Item AC', 3, false);
INSERT INTO public.test_enums VALUES (8, 4, 'Item AD', 4, false);
INSERT INTO public.test_enums VALUES (8, 5, 'Item AE', 5, false);
INSERT INTO public.test_enums VALUES (38, 1, 'Item KA', 1, false);
INSERT INTO public.test_enums VALUES (38, 2, 'Item KB', 2, false);
INSERT INTO public.test_enums VALUES (38, 3, 'Item KC', 3, false);
INSERT INTO public.test_enums VALUES (38, 4, 'Item KD', 4, false);
INSERT INTO public.test_enums VALUES (38, 5, 'Item KE', 5, false);
INSERT INTO public.test_enums VALUES (39, 1, 'Item GEA', 1, false);
INSERT INTO public.test_enums VALUES (39, 2, 'Item GEB', 2, false);
INSERT INTO public.test_enums VALUES (39, 3, 'Item GEC', 3, false);
INSERT INTO public.test_enums VALUES (44, 1, 'Item ME1', 1, false);
INSERT INTO public.test_enums VALUES (44, 2, 'Item ME2', 2, false);
INSERT INTO public.test_enums VALUES (44, 3, 'Item ME3', 3, false);
INSERT INTO public.test_enums VALUES (44, 4, 'Item ME4', 4, false);
INSERT INTO public.test_enums VALUES (44, 5, 'Item ME5', 5, false);
INSERT INTO public.test_enums VALUES (45, 1, 'Item MAE1', 1, false);
INSERT INTO public.test_enums VALUES (45, 2, 'Item MAE2', 2, false);
INSERT INTO public.test_enums VALUES (45, 3, 'Item MAE3', 3, false);
INSERT INTO public.test_enums VALUES (45, 4, 'Item MAE4', 4, false);
INSERT INTO public.test_enums VALUES (45, 5, 'Item MAE5', 5, false);


--
-- Data for Name: test_equipments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.test_equipments VALUES (50, 1);
INSERT INTO public.test_equipments VALUES (54, 4);
INSERT INTO public.test_equipments VALUES (54, 6);
INSERT INTO public.test_equipments VALUES (59, 4);
INSERT INTO public.test_equipments VALUES (60, 4);
INSERT INTO public.test_equipments VALUES (61, 2);
INSERT INTO public.test_equipments VALUES (61, 4);
INSERT INTO public.test_equipments VALUES (66, 7);
INSERT INTO public.test_equipments VALUES (67, 5);
INSERT INTO public.test_equipments VALUES (67, 6);
INSERT INTO public.test_equipments VALUES (68, 5);
INSERT INTO public.test_equipments VALUES (68, 6);
INSERT INTO public.test_equipments VALUES (69, 5);
INSERT INTO public.test_equipments VALUES (69, 9);
INSERT INTO public.test_equipments VALUES (46, 10);
INSERT INTO public.test_equipments VALUES (47, 10);
INSERT INTO public.test_equipments VALUES (48, 10);
INSERT INTO public.test_equipments VALUES (49, 10);
INSERT INTO public.test_equipments VALUES (50, 12);
INSERT INTO public.test_equipments VALUES (78, 5);
INSERT INTO public.test_equipments VALUES (79, 3);
INSERT INTO public.test_equipments VALUES (79, 5);
INSERT INTO public.test_equipments VALUES (80, 3);
INSERT INTO public.test_equipments VALUES (80, 5);
INSERT INTO public.test_equipments VALUES (81, 3);
INSERT INTO public.test_equipments VALUES (81, 5);
INSERT INTO public.test_equipments VALUES (82, 3);
INSERT INTO public.test_equipments VALUES (82, 5);
INSERT INTO public.test_equipments VALUES (83, 3);
INSERT INTO public.test_equipments VALUES (83, 5);
INSERT INTO public.test_equipments VALUES (84, 3);
INSERT INTO public.test_equipments VALUES (84, 5);
INSERT INTO public.test_equipments VALUES (79, 13);
INSERT INTO public.test_equipments VALUES (79, 14);
INSERT INTO public.test_equipments VALUES (79, 15);
INSERT INTO public.test_equipments VALUES (80, 13);
INSERT INTO public.test_equipments VALUES (80, 14);
INSERT INTO public.test_equipments VALUES (80, 15);
INSERT INTO public.test_equipments VALUES (81, 13);
INSERT INTO public.test_equipments VALUES (81, 14);
INSERT INTO public.test_equipments VALUES (81, 15);
INSERT INTO public.test_equipments VALUES (82, 13);
INSERT INTO public.test_equipments VALUES (82, 14);
INSERT INTO public.test_equipments VALUES (82, 15);
INSERT INTO public.test_equipments VALUES (83, 13);
INSERT INTO public.test_equipments VALUES (83, 14);
INSERT INTO public.test_equipments VALUES (83, 15);
INSERT INTO public.test_equipments VALUES (84, 13);
INSERT INTO public.test_equipments VALUES (84, 14);
INSERT INTO public.test_equipments VALUES (84, 15);
INSERT INTO public.test_equipments VALUES (102, 19);
INSERT INTO public.test_equipments VALUES (103, 19);
INSERT INTO public.test_equipments VALUES (104, 20);
INSERT INTO public.test_equipments VALUES (105, 16);
INSERT INTO public.test_equipments VALUES (105, 17);
INSERT INTO public.test_equipments VALUES (105, 18);
INSERT INTO public.test_equipments VALUES (115, 4);
INSERT INTO public.test_equipments VALUES (115, 23);
INSERT INTO public.test_equipments VALUES (109, 23);
INSERT INTO public.test_equipments VALUES (110, 23);
INSERT INTO public.test_equipments VALUES (118, 24);
INSERT INTO public.test_equipments VALUES (119, 24);
INSERT INTO public.test_equipments VALUES (120, 25);
INSERT INTO public.test_equipments VALUES (119, 23);
INSERT INTO public.test_equipments VALUES (121, 26);
INSERT INTO public.test_equipments VALUES (122, 27);
INSERT INTO public.test_equipments VALUES (123, 26);
INSERT INTO public.test_equipments VALUES (124, 26);
INSERT INTO public.test_equipments VALUES (138, 17);
INSERT INTO public.test_equipments VALUES (139, 17);
INSERT INTO public.test_equipments VALUES (140, 17);
INSERT INTO public.test_equipments VALUES (137, 16);


--
-- Data for Name: test_reagents; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.test_reagents VALUES (115, 28);
INSERT INTO public.test_reagents VALUES (110, 28);
INSERT INTO public.test_reagents VALUES (110, 31);
INSERT INTO public.test_reagents VALUES (109, 28);
INSERT INTO public.test_reagents VALUES (109, 29);
INSERT INTO public.test_reagents VALUES (109, 30);
INSERT INTO public.test_reagents VALUES (109, 31);
INSERT INTO public.test_reagents VALUES (119, 28);
INSERT INTO public.test_reagents VALUES (121, 27);
INSERT INTO public.test_reagents VALUES (122, 28);
INSERT INTO public.test_reagents VALUES (122, 29);
INSERT INTO public.test_reagents VALUES (122, 30);
INSERT INTO public.test_reagents VALUES (122, 36);
INSERT INTO public.test_reagents VALUES (122, 38);
INSERT INTO public.test_reagents VALUES (122, 39);
INSERT INTO public.test_reagents VALUES (123, 27);
INSERT INTO public.test_reagents VALUES (124, 27);
INSERT INTO public.test_reagents VALUES (137, 34);
INSERT INTO public.test_reagents VALUES (137, 35);
INSERT INTO public.test_reagents VALUES (138, 27);
INSERT INTO public.test_reagents VALUES (138, 35);
INSERT INTO public.test_reagents VALUES (139, 27);
INSERT INTO public.test_reagents VALUES (140, 27);
INSERT INTO public.test_reagents VALUES (140, 34);
INSERT INTO public.test_reagents VALUES (137, 33);
INSERT INTO public.test_reagents VALUES (137, 32);
INSERT INTO public.test_reagents VALUES (141, 27);


--
-- Data for Name: tests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (40, 'Parameter GF', 'pgf', NULL, 3, true, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, 41, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (46, 'Diameter 1', 'mco_d1', 'First diameter measurement of cylindrical specimen', 2, false, true, false, false, NULL, NULL, 11, NULL, NULL, NULL, true, NULL, 44, '2026-07-04 23:47:20.474144+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (47, 'Diameter 2', 'mco_d2', 'Second diameter measurement of cylindrical specimen', 2, false, true, false, false, NULL, NULL, 11, NULL, NULL, NULL, true, NULL, 45, '2026-07-04 23:48:04.628515+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (48, 'Height 1', 'mco_h1', 'First height measurement of cylindrical specimen', 2, false, true, false, false, NULL, NULL, 11, NULL, NULL, NULL, true, NULL, 46, '2026-07-04 23:48:44.605356+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (49, 'Height 2', 'mco_h2', 'Second height measurement of cylindrical specimen', 2, false, true, false, false, NULL, NULL, 11, NULL, NULL, NULL, true, NULL, 47, '2026-07-04 23:49:24.318518+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (50, 'Maximum Load', 'mco_P', 'Value at failure', 2, false, true, false, false, NULL, NULL, 12, NULL, NULL, NULL, true, NULL, 48, '2026-07-06 03:27:42.807334+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (53, 'Aliquot Volume', 'tss_V', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, true, true, false, false, NULL, NULL, 3, NULL, '', NULL, true, NULL, 53, '2026-07-07 17:40:56.8302+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (54, 'Dry Residue Weight', 'tss_W', 'Consequuntur iusto optio impedit iusto nihil quia', 2, true, true, false, false, NULL, NULL, 14, NULL, '', NULL, true, NULL, 54, '2026-07-07 17:42:18.803509+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (58, 'Normalized Value', 'tss_Xi', 'Excepturi beatae quibusdam', 2, true, true, false, false, NULL, NULL, 15, NULL, '', NULL, true, NULL, 52, '2026-07-07 18:10:17.482345+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (59, 'Tare Weight', 'lod_m0', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, true, true, false, false, NULL, NULL, 2, NULL, '', NULL, true, NULL, 59, '2026-07-09 15:25:02.623865+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (60, 'Wet + Bottle', 'lod_m1', 'Consequuntur iusto optio impedit iusto nihil quia', 2, true, true, false, false, NULL, NULL, 2, NULL, '', NULL, true, NULL, 60, '2026-07-09 15:26:46.785417+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (61, 'Dry + Bottle', 'lod_m2', 'Officia dignissimos tempora commodi ', 2, true, true, false, false, NULL, NULL, 2, NULL, '', NULL, true, NULL, 61, '2026-07-09 15:28:42.886268+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (29, 'Parameter GA', 'pga', NULL, 2, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, true, NULL, 36, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (30, 'Parameter GB', 'pgb', NULL, 2, true, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, true, NULL, 37, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (31, 'Parameter GC', 'pgc', NULL, 2, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, true, NULL, 38, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (36, 'Parameter GD', 'pgd', NULL, 2, true, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, true, NULL, 39, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (39, 'Parameter GE', 'pge', NULL, 4, true, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, 40, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (69, 'Submerged Mass', 'pca_C', 'Excepturi beatae quibusdam', 2, true, true, false, false, NULL, NULL, 2, 10, '', 43, true, NULL, 71, '2026-07-11 19:09:24.462621+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (41, 'Test H', 'test_h', 'Description Test H', 3, false, false, false, true, 3.00, 2.0, 10, NULL, NULL, NULL, true, NULL, 29, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (37, 'Test J', 'test_j', NULL, 2, true, false, false, true, 3.00, 2.0, NULL, NULL, NULL, NULL, true, NULL, 30, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (57, 'Sample Size', 'tss_n', 'Sunt saepe veniam recusandae ex fuga id', 1, false, false, false, true, 3.00, 2.0, NULL, NULL, '', NULL, true, NULL, 51, '2026-07-07 17:58:54.090721+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (64, 'Standard Deviation', 'lod_s', 'Officia dignissimos tempora commodi ', 2, false, false, false, true, 3.00, 2.0, 9, NULL, '', NULL, true, NULL, 57, '2026-07-09 15:53:53.339483+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (65, 'Sample Count', 'lod_n', 'Sunt saepe veniam recusandae ex fuga id', 1, false, false, false, true, 3.00, 2.0, NULL, NULL, '', NULL, true, NULL, 58, '2026-07-09 15:57:47.072723+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (74, 'Compaction Standard Deviation', 'pca_s_c', 'Excepturi beatae quibusdam', 2, false, false, false, true, 3.00, 2.0, 9, NULL, '', NULL, true, NULL, 67, '2026-07-11 21:11:04.522057+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (75, 'Core Sample Count', 'pca_n', 'Sunt saepe veniam recusandae ex fuga id', 1, false, false, false, true, 3.00, 2.0, NULL, NULL, '', NULL, true, NULL, 68, '2026-07-11 21:13:53.951992+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (38, 'Test K', 'test_k', NULL, 4, false, false, false, true, 3.00, 2.0, NULL, NULL, NULL, NULL, true, NULL, 31, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (67, 'Dry Mass', 'pca_A', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, true, true, false, false, NULL, NULL, 2, 10, '', 43, true, NULL, 69, '2026-07-11 19:03:06.2863+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (68, 'Saturated Surface-Dry Mass', 'pca_B', 'Officia dignissimos tempora commodi', 2, true, true, false, false, NULL, NULL, 2, 10, '', 43, true, NULL, 70, '2026-07-11 19:05:13.668253+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (44, 'Test ME', 'tme', 'Description Test ME', 4, false, false, false, false, NULL, NULL, 2, 3, NULL, 12, false, NULL, 34, '2025-12-27 21:27:51.890718+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (77, 'In-Place Compaction', 'pca_C_i', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, true, true, false, false, NULL, NULL, 9, 10, '', 43, true, NULL, 65, '2026-07-11 21:54:52.724803+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (5, 'Test E', 'test_e', 'Description Test E', 2, false, false, false, false, NULL, NULL, 2, 3, 'ref E', 12, false, NULL, 5, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (6, 'Parameter AA', 'param_aa', 'Description Parameter AA', 2, false, true, false, false, NULL, NULL, 2, 1, NULL, 5, true, NULL, 6, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (7, 'Parameter AB', 'param_ab', 'Description Parameter AB', 2, false, true, false, false, NULL, NULL, 2, 1, NULL, 5, true, NULL, 7, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (8, 'Parameter AC', 'param_ac', 'Description Parameter AC', 4, false, true, false, false, NULL, NULL, 2, 1, NULL, 5, true, NULL, 8, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (9, 'Parameter AD', 'param_ad', 'Description Parameter AD', 2, false, true, false, false, NULL, NULL, 2, 1, NULL, 5, true, NULL, 9, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (10, 'Parameter AE', 'param_ae', 'Description Parameter AE', 3, false, true, false, false, NULL, NULL, 2, 1, NULL, 5, true, NULL, 10, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (11, 'Parameter AF', 'param_af', 'Description Parameter AF', 2, false, true, false, false, NULL, NULL, 2, 1, NULL, 5, true, NULL, 11, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (12, 'Parameter BA', 'param_ba', 'Description Parameter BA', 2, false, true, false, false, NULL, NULL, 2, 2, NULL, 6, true, NULL, 12, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (13, 'Parameter BB', 'param_bb', 'Description Parameter BB', 4, false, true, false, false, NULL, NULL, 2, 2, NULL, 6, true, NULL, 13, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (14, 'Parameter BC', 'param_bc', 'Description Parameter BC', 2, false, true, false, false, NULL, NULL, 2, 2, NULL, 6, true, NULL, 14, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (15, 'Parameter BD', 'pbd', 'Description Parameter BD', 2, false, true, false, false, NULL, NULL, 2, 2, NULL, 6, false, NULL, 15, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (16, 'Parameter CA', 'param_ca', 'Description Parameter CA', 2, false, true, false, false, NULL, NULL, 2, 1, NULL, 5, false, NULL, 16, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (17, 'Parameter CB', 'param_cb', 'Description Parameter CB', 2, false, true, false, false, NULL, NULL, 2, 1, NULL, 5, false, NULL, 17, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (18, 'Parameter CC', 'param_cc', 'Description Parameter CC', 2, false, true, false, false, NULL, NULL, 2, 1, NULL, 5, false, NULL, 18, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (19, 'Parameter CD', 'param_cd', 'Description Parameter CD', 2, false, true, false, false, NULL, NULL, 2, 1, NULL, 5, true, NULL, 19, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (20, 'Parameter DA', 'param_da', 'Description Parameter DA', 2, false, true, false, false, NULL, NULL, 2, 2, NULL, 6, false, NULL, 20, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (21, 'Parameter DB', 'param_db', 'Description Parameter DB', 2, false, true, false, false, NULL, NULL, 2, 2, NULL, 6, true, NULL, 21, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (22, 'Parameter DC', 'param_dc', 'Description Parameter DC', 2, false, true, false, false, NULL, NULL, 2, 2, NULL, 6, true, NULL, 22, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (24, 'Parameter EB', 'param_eb', 'Description Parameter EB', 2, false, true, false, false, NULL, NULL, 2, 3, NULL, 12, true, NULL, 24, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (25, 'Parameter EC', 'param_ec', 'Description Parameter EC', 2, false, true, false, false, NULL, NULL, 2, 3, NULL, 12, true, NULL, 25, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (26, 'Parameter FA', 'param_fa', 'Description Parameter FA', 2, false, true, false, false, NULL, NULL, 2, 2, NULL, 6, false, NULL, 26, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (27, 'Parameter FB', 'param_fb', 'Description Parameter FB', 2, false, true, false, false, NULL, NULL, 2, 2, NULL, 6, true, NULL, 27, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (23, 'Parameter EA', 'param_ea', 'Description Parameter EA', 2, false, true, false, false, NULL, NULL, 2, 3, NULL, 12, false, NULL, 23, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (79, 'Cumulative Weight 1 inch', 'saa_cw_1_inch', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, true, false, false, NULL, NULL, 2, 12, '', 54, true, NULL, 73, '2026-07-17 13:22:09.84019+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (80, 'Cumulative Weight 3/4 inch', 'saa_cw_3_4_inch', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, true, false, false, NULL, NULL, 2, 12, '', 54, true, NULL, 74, '2026-07-17 13:23:10.505012+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (81, 'Cumulative Weight No. 4', 'saa_cw_no_4', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, true, false, false, NULL, NULL, 2, 12, '', 54, true, NULL, 75, '2026-07-17 13:24:47.212141+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (82, 'Cumulative Weight No. 40', 'saa_cw_no_40', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, true, false, false, NULL, NULL, 2, 12, '', 54, true, NULL, 76, '2026-07-17 13:26:36.087361+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (83, 'Cumulative Weight No. 200', 'saa_cw_no_200', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, true, false, false, NULL, NULL, 2, 12, '', 54, true, NULL, 77, '2026-07-17 13:27:37.566801+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (84, 'Cumulative Weight Pan', 'saa_cw_pan', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, true, false, false, NULL, NULL, 2, 12, '', 54, true, NULL, 78, '2026-07-17 13:30:46.876739+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (85, 'Individual Mass 1 inch', 'saa_Mi_1_inch', 'Officia dignissimos tempora commodi ', 2, false, false, false, false, NULL, NULL, 2, 12, '', 54, true, NULL, 79, '2026-07-17 13:34:03.488872+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (86, 'Individual Mass 3/4 inch', 'saa_Mi_3_4_inch', 'Officia dignissimos tempora commodi ', 2, false, false, false, false, NULL, NULL, 2, 12, '', 54, true, NULL, 80, '2026-07-17 13:34:55.375851+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (87, 'Individual Mass No. 4', 'saa_Mi_no_4', 'Officia dignissimos tempora commodi', 2, false, false, false, false, NULL, NULL, 2, 12, '', 54, true, NULL, 81, '2026-07-17 13:35:39.91469+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (88, 'Individual Mass No. 40', 'saa_Mi_no_40', 'Officia dignissimos tempora commodi ', 2, false, false, false, false, NULL, NULL, 2, 12, '', 54, true, NULL, 82, '2026-07-17 13:37:37.10508+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (89, 'Individual Mass No. 200', 'saa_Mi_no_200', 'Officia dignissimos tempora commodi', 2, false, false, false, false, NULL, NULL, 2, 12, '', 54, true, NULL, 83, '2026-07-17 13:39:50.594124+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (90, 'Individual Mass Pan', 'saa_Mi_pan', 'Officia dignissimos tempora commodi', 2, false, false, false, false, NULL, NULL, 2, 12, '', 54, true, NULL, 84, '2026-07-17 13:40:52.598601+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (73, 'Core Specific Gravity', 'pca_G_mb', 'Excepturi beatae quibusdam', 2, true, false, false, true, 3.00, 2.0, NULL, 10, '', 43, true, NULL, 64, '2026-07-11 20:39:28.774076+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (42, 'Test LB', 'tlb', 'Description Test LB', 3, false, false, false, true, 3.00, 2.0, 2, 1, NULL, 5, false, NULL, 32, '2025-12-27 21:25:52.613339+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (43, 'Test LBA', 'tlba', 'Description Test LBA', 3, true, false, false, true, 3.00, 2.0, 2, 2, NULL, 6, false, NULL, 33, '2025-12-27 21:26:41.616588+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (45, 'Test MAE', 'tmae', 'Description Test MAE', 4, true, false, false, true, 3.00, 2.0, 2, 2, NULL, 6, false, NULL, 35, '2025-12-27 21:29:25.300316+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (51, ' Compressive Strength', 'mco_sigma', 'Compressive strength is defined as the maximum force applied divided by the cross-sectional area.', 2, false, false, false, true, 3.00, 2.0, 13, 6, NULL, 20, true, NULL, 42, '2026-07-06 03:30:35.730139+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (52, 'Aspect Ratio', 'mco_ldr', 'Length-to-Diameter ratio.', 2, false, false, false, true, 3.00, 2.0, NULL, 6, NULL, 20, true, NULL, 43, '2026-07-06 04:44:58.706412+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (55, 'Total Suspended Solids', 'tss_X', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, false, false, true, 3.00, 2.0, 15, 7, '', 31, true, NULL, 49, '2026-07-07 17:54:28.497264+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (56, 'Relative Standard Deviation', 'tss_RSD', 'Officia dignissimos tempora commodi ', 2, false, false, false, true, 3.00, 2.0, 9, 7, '', 31, true, NULL, 50, '2026-07-07 17:56:01.722304+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (62, 'Sample Moisture', 'lod_i', 'Excepturi beatae quibusdam', 2, true, false, false, true, 3.00, 2.0, 9, 8, '', 34, true, NULL, 56, '2026-07-09 15:41:38.255198+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (63, 'Mean Moisture', 'lod_X', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, false, false, true, 3.00, 2.0, 9, 8, '', 34, true, NULL, 55, '2026-07-09 15:45:58.044612+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (72, 'Average Pavement Thickness', 'pca_MH', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, false, false, true, 3.00, 2.0, 11, 9, '', 41, true, NULL, 62, '2026-07-11 19:48:30.052621+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (66, 'Core Height', 'pca_H', 'Consequuntur iusto optio impedit iusto nihil quia', 2, true, false, false, true, 3.00, 2.0, 11, 9, '', 41, true, NULL, 63, '2026-07-11 19:01:44.239687+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (76, 'Average Compaction', 'pca_MC', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, false, false, true, 3.00, 2.0, 9, 10, '', 43, true, NULL, 66, '2026-07-11 21:51:30.902295+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (1, 'Test A', 'test_a', 'Description Test A', 2, false, false, false, true, 3.00, 2.0, 2, 1, 'ref A', 5, true, NULL, 1, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (2, 'Test B', 'test_b', 'Description Test B', 2, false, false, false, true, 3.00, 2.0, 2, 2, 'ref B', 6, true, NULL, 2, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (3, 'Test C', 'test_c', 'Description Test C', 2, false, false, false, true, 3.00, 2.0, 2, 1, 'ref C', 5, true, NULL, 3, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (4, 'Test D', 'test_d', 'Description Test D', 2, false, false, false, true, 3.00, 2.0, 2, 2, 'ref D', 6, true, NULL, 4, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (28, 'Test G', 'test_g', 'Description Test G', 2, false, false, false, true, 3.00, 2.0, 2, 1, NULL, 5, true, NULL, 28, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (78, 'Initial Dry Sample Weight', 'saa_M_initial', 'Consequuntur iusto optio impedit iusto nihil quia', 2, false, false, false, true, 3.00, 2.0, 2, 12, '', 54, true, NULL, 72, '2026-07-17 12:57:37.57851+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (91, 'Percent Passing 1 inch', 'saa_PPi_1_inch', 'Excepturi beatae quibusdam', 2, false, false, false, true, 3.00, 2.0, 9, 12, '', 54, true, NULL, 85, '2026-07-17 13:44:56.420411+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (92, 'Percent Passing 3/4 inch', 'saa_PPi_3_4_inch', 'Excepturi beatae quibusdam', 2, false, false, false, true, 3.00, 2.0, 9, 12, '', 54, true, NULL, 86, '2026-07-17 13:52:31.975998+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (93, 'Percent Passing No. 4', 'saa_PPi_no_4', 'Excepturi beatae quibusdam', 2, false, false, false, true, 3.00, 2.0, 9, 12, '', 54, true, NULL, 87, '2026-07-17 14:03:55.093966+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (94, 'Percent Passing No. 40', 'saa_PPi_no_40', 'Excepturi beatae quibusdam', 2, false, false, false, true, 3.00, 2.0, 9, 12, '', 54, true, NULL, 88, '2026-07-17 14:05:31.566425+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (95, 'Percent Passing No. 200', 'saa_PPi_no_200', 'Excepturi beatae quibusdam', 2, false, false, false, true, 3.00, 2.0, 9, 12, '', 54, true, NULL, 89, '2026-07-17 14:07:32.07714+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (96, 'Sieve Loss', 'saa_loss', 'Excepturi beatae quibusdam', 2, false, false, false, true, 3.00, 2.0, 9, 12, '', 54, true, NULL, 90, '2026-07-17 14:15:54.980197+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (102, 'Ambient Laboratory Temperature', 'env_temp', 'Continuous room temperature monitoring (Target: 20.0°C ± 3.0°C)', 2, false, false, true, false, NULL, NULL, 16, 14, '', 60, true, NULL, 127, '2026-01-10 10:00:00+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (103, 'Ambient Relative Humidity', 'env_rh', 'Continuous room humidity monitoring (Target: 40% - 65%)', 2, false, false, true, false, NULL, NULL, 17, 14, '', 60, true, NULL, 128, '2026-01-10 10:00:00+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (104, 'Fume Hood Air Velocity', 'env_airvel', 'Fume hood face velocity monitoring (Target: 0.40 - 0.60 m/s)', 2, false, false, true, false, NULL, NULL, 18, 14, '', 61, true, NULL, 129, '2026-01-10 10:00:00+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (110, 'Molarity of Standard K2Cr2O7 Solution', 'fas_M_K2Cr2O7', 'Molarity of Primary Standard K2Cr2O7 Solution', 2, false, true, false, false, NULL, NULL, 21, 13, '', 57, true, NULL, 96, '2026-09-12 13:11:50.515505+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (105, 'Chemical Oxygen Demand', 'cod', 'Closed Reflux Titrimetric COD Analysis', 2, false, false, false, true, 3.00, 2.0, 15, 13, '', 56, true, NULL, 125, '2026-09-09 15:21:56.121192+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (107, 'Initial Burette Reading', 'fas_V_K2Cr2O7_initial', 'Initial Burette Reading', 2, true, true, false, false, NULL, NULL, 4, 13, '', 57, true, NULL, 92, '2026-09-12 12:46:35.60068+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (108, 'Final Burette Reading', 'fas_V_K2Cr2O7_final', 'Final Burette Reading', 2, true, true, false, false, NULL, NULL, 4, 13, '', 57, true, NULL, 93, '2026-09-12 12:53:07.357891+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (111, 'Molarity of Individual Titration Replicates', 'fas_M_i', 'Molarity of Individual Titration Replicates', 2, true, true, false, false, NULL, NULL, 21, 13, '', 57, true, NULL, 97, '2026-09-12 13:36:55.351662+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (112, 'FAS Molarity', 'fas_M', 'Mean FAS Molarity', 2, false, false, false, true, NULL, NULL, 21, 13, '', NULL, true, NULL, 98, '2026-09-12 13:54:12.166195+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (109, 'FAS Net Titrant Volume', 'fas_V', 'Net Titrant Volume', 2, true, true, false, false, NULL, NULL, 4, 13, '', 57, true, NULL, 94, '2026-09-12 12:55:19.785631+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (113, 'FAS Standard Deviation', 'fas_s', 'Sample Standard Deviation', 2, false, true, false, false, NULL, NULL, 21, NULL, '', NULL, true, NULL, 100, '2026-09-12 13:59:35.682935+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (114, 'FAS Relative Standard Deviation', 'fas_rsd', 'Relative Standard Deviation (Precision)', 2, false, false, false, false, NULL, NULL, 9, NULL, '', NULL, true, NULL, 101, '2026-09-12 14:02:33.487218+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (115, 'Net Mass of Primary Standard  K2Cr2O7', 'fas_nm_K2Cr2O7', 'Net Mass of Primary Standard  K2Cr2O7', 2, false, true, false, false, NULL, NULL, 2, 13, NULL, NULL, true, NULL, 95, '2026-09-12 14:33:34.844492+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (116, 'Primary Standard Volum', 'fas_V_K2Cr2O7', 'Volume of K2Cr2O7 solution in water (Type I Ultrapure Water)', 2, true, true, false, false, NULL, NULL, 4, 13, '', 57, true, NULL, 91, '2026-09-12 16:29:22.415053+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (117, 'FAS Replicate Count', 'fas_n', 'Replicate Count', 1, false, false, false, false, NULL, NULL, NULL, NULL, '', NULL, true, NULL, 99, '2026-09-14 19:25:56.04938+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (118, 'Mass of Empty Glass Weighing Boat', 'dcr_m1', 'Mass of Empty Glass Weighing Boat', 2, false, true, false, false, NULL, NULL, 2, 13, '', 70, true, NULL, 102, '2026-09-16 17:05:17.836387+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (121, 'Ferrous Ammonium Sulfate Molarity', 'dcr_M_FAS', 'Standardized Ferrous Ammonium Sulfate Molarity', 2, false, true, false, false, NULL, NULL, 21, 13, '', 70, true, NULL, 105, '2026-09-16 17:12:59.383846+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (122, 'Aliquot Volume Digestion Solution', 'dcr_V_dig', 'Aliquot Volume Digestion Solution', 2, false, true, false, false, NULL, NULL, 4, 13, '', 70, true, NULL, 106, '2026-09-16 17:19:13.856815+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (123, 'Initial Buret Volume', 'dcr_V_init', 'Initial Buret Volume', 2, true, true, false, false, NULL, NULL, 4, 13, '', 70, true, NULL, 107, '2026-09-16 17:20:13.352771+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (124, 'Final Buret Volume', 'dcr_V_final', 'Final Buret Volume', 2, true, true, false, false, NULL, NULL, 4, 13, '', 70, true, NULL, 108, '2026-09-16 17:20:49.751802+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (125, 'Net Titrant Volume', 'dcr_V_FAS_i', 'Net Titrant Volume of Ferrous Ammonium Sulfate (FAS) required for oxidation', 2, true, true, false, false, NULL, NULL, 4, 13, '', 70, true, NULL, 109, '2026-09-16 17:22:41.452201+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (126, 'Gravimetric Molarity', 'dcr_M_grav', 'Gravimetric Molarity', 2, false, true, false, false, NULL, NULL, 21, 13, '', 70, true, NULL, 110, '2026-09-16 17:24:00.73559+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (127, 'Gravimetric Normality', 'dcr_N_grav', 'Gravimetric Normality', 2, false, true, false, false, NULL, NULL, 22, 13, '', 70, true, NULL, 111, '2026-09-16 17:26:09.579786+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (128, 'Percentage Relative Bias', 'dcr_Bias', 'Percentage Relative Bias', 2, false, false, false, false, NULL, NULL, 9, 13, '', 70, true, NULL, 113, '2026-09-16 17:32:11.669093+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (129, 'Titrant Volume Standard Deviation', 'dcr_s', 'Titrant Volume Standard Deviation', 2, false, false, false, false, NULL, NULL, 4, 13, '', 70, true, NULL, 115, '2026-09-16 17:43:30.447771+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (130, 'Aliquot Sample Count', 'dcr_n', 'Aliquot Sample Count', 2, false, false, false, false, NULL, NULL, NULL, 13, '', 70, true, NULL, 114, '2026-09-16 17:44:42.531844+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (131, 'Titrant Volume Relative Standard Deviation', 'dcr_RSD', 'Titrant Volume Relative Standard Deviation', 2, false, false, false, false, NULL, NULL, 9, 13, '', 70, true, NULL, 116, '2026-09-16 17:49:09.934146+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (132, 'Average Titrant Volume', 'dcr_V_FAS', 'Average Titrant Volume', 2, false, true, false, false, NULL, NULL, 4, 13, '', 70, true, NULL, 117, '2026-09-16 18:18:00.726498+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (133, 'Volumetric Verification Molarity', 'dcr_M_titr', 'Volumetric Verification Molarity', 2, false, true, false, false, NULL, NULL, 21, 13, '', 70, true, NULL, 112, '2026-09-16 18:44:05.781227+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (119, 'Mass of Boat + Pre-Dried K2Cr2O7', 'dcr_m2', 'Mass of Boat + Pre-Dried K2Cr2O7', 2, false, true, false, false, NULL, NULL, 2, 13, '', 70, true, NULL, 103, '2026-09-16 17:06:30.524424+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (120, 'Flask Nominal Volume', 'dcr_V_flask', 'Target Volumetric Flask Nominal Volume', 2, false, true, false, false, NULL, NULL, 4, 13, '', 70, true, NULL, 104, '2026-09-16 17:08:13.802054+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (135, 'Digestion Solution Molarity', 'dcr_M_cert', 'Digestion Solution Molarity', 2, false, false, false, true, 3.00, 2.0, 21, 13, '', 70, true, NULL, 118, '2026-09-16 18:57:01.909521+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (136, 'Digestion Solution Normality', 'dcr_N_cert', 'Digestion Solution Normality', 2, false, false, false, false, NULL, NULL, 22, 13, '', 70, true, NULL, 119, '2026-09-16 18:58:16.989484+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (138, 'FAS Titrant Volume for Reagent Blank', 'cod_V_B', 'FAS Titrant Volume for Reagent Blank', 2, false, true, false, false, NULL, NULL, 4, 13, '', 56, true, NULL, 121, '2026-09-17 11:23:33.366527+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (139, 'FAS Titrant Volume for Sample', 'cod_V_S', 'FAS Titrant Volume for Sample', 2, false, true, false, false, NULL, NULL, 4, 13, '', 56, true, NULL, 122, '2026-09-17 11:43:14.024374+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (141, 'Standardized FAS Molarity', 'cod_M_FAS', 'Standardized FAS Molarity', 2, false, true, false, false, NULL, NULL, 21, 13, '', 56, true, NULL, 124, '2026-09-17 11:47:21.228918+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (143, 'Quality Check Recovery (KHP Standard)', 'cod_recovery', 'Quality Check Recovery (KHP Standard)', 2, false, false, false, false, NULL, NULL, 9, 13, '', 56, true, NULL, 126, '2026-09-17 12:09:08.920187+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (137, 'Sample Volume', 'cod_V_sample', 'Sample Volume', 2, false, true, false, false, NULL, NULL, 4, 13, '', 56, true, NULL, 120, '2026-09-17 11:16:26.22189+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (140, 'FAS Titrant Volume for KHP Standard', 'cod_V_STD', 'FAS Titrant Volume for KHP Check Standard', 2, false, true, false, false, NULL, NULL, 4, 13, '', 56, true, NULL, 123, '2026-09-17 11:45:53.503766+03', false, NULL, NULL);


--
-- Data for Name: units; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (5, 'pcs', 'Count', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (6, 'box', 'Count', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (7, 'pack', 'Count', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (8, 'Unit', 'Count', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (9, '%', 'Percentage', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (10, 'n.a.', 'Not Applicable', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (3, 'L', 'Liters (Volume)', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (16, '°C', 'Degrees Celsius (Temperature)', '2026-01-10 10:00:00+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (17, '% RH', 'Percentage Relative Humidity', '2026-01-10 10:00:00+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (19, 'mg/L O2', 'Milligrams Oxygen per Liter', '2026-01-10 10:00:00+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (20, 'mol/L', 'Molar concentration', '2026-09-12 13:12:21.4765+03');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (18, 'm/s', 'Meters per second (Velocity)', '2026-01-10 10:00:00+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (14, 'mg', 'Milligrams (Mass)', '2026-07-07 17:33:10.295159+03');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (15, 'mg/L', 'Milligram per Liter (Concentration)', '2026-07-07 17:45:38.624869+03');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (11, 'mm', 'Millimeters (Length)', '2026-07-04 23:31:32.732861+03');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (4, 'mL', 'Milliliters (Volume)', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (13, 'MPa', 'Megapascals (Force)', '2026-07-04 23:36:03.197749+03');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (12, 'kN', 'Kilo Newtons (Force)', '2026-07-04 23:33:34.00052+03');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (1, 'kg', 'Kilo Grams (Weight)', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (2, 'g', 'Grams (Weight)', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (22, 'eq/L (N)', 'Normal (Concentration)', '2026-09-15 19:27:20.683085+03');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (21, 'mol/L (M)', 'Molar Concentration', '2026-09-12 13:37:25.553825+03');


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (2, 'bob', 'BO', 'bob@qc.lab', 'Bob', 'Johnson', false, false, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', 0, false, NULL, NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (3, 'charlie', 'CH', 'charlie@qc.lab', 'Charlie', 'Brown', false, false, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', 0, false, NULL, NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (4, 'david', 'DV', 'david@qc.lab', 'David', 'Miller', false, false, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', 0, false, NULL, NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', true, '2026-01-23 22:42:12.337979+02', 'Some explanations ...');
INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (5, 'eve', 'EV', 'eve@qc.lab', 'Eve', 'Adams', false, true, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', 0, false, NULL, NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (6, 'frank', 'FR', 'frank@qc.lab', 'Frank', 'Wright', false, true, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', 0, false, NULL, NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (7, 'grace', 'GR', 'grace@qc.lab', 'Grace', 'Davis', false, false, true, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', 0, false, NULL, NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (8, 'heidi', 'HE', 'heidi@qc.lab', 'Heidi', 'Turner', true, false, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', 0, false, NULL, '646582b1-660d-4823-9c1e-3528d41a2d1b', '2025-12-13 18:17:42.218999+02', NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (1, 'alice', 'AL', 'alice@qc.lab', 'Alice', 'Smith', true, true, true, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', 0, false, NULL, '28817067-d3a2-47a3-ada6-4480408a6222', '2026-09-19 15:14:40.37922+03', '2026-09-20 03:14:40.379364+03', NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);


--
-- Data for Name: value_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.value_types OVERRIDING SYSTEM VALUE VALUES (1, 'integer');
INSERT INTO public.value_types OVERRIDING SYSTEM VALUE VALUES (2, 'real');
INSERT INTO public.value_types OVERRIDING SYSTEM VALUE VALUES (3, 'boolean');
INSERT INTO public.value_types OVERRIDING SYSTEM VALUE VALUES (4, 'enum');


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 72, true);


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categories_id_seq', 7, true);


--
-- Name: certification_headers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.certification_headers_id_seq', 16, true);


--
-- Name: electronic_signatures_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.electronic_signatures_id_seq', 1, false);


--
-- Name: equipment_calibrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.equipment_calibrations_id_seq', 125, true);


--
-- Name: equipment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.equipment_id_seq', 28, true);


--
-- Name: form_condition_evals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.form_condition_evals_id_seq', 221, true);


--
-- Name: form_evals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.form_evals_id_seq', 23, true);


--
-- Name: form_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.form_groups_id_seq', 16, true);


--
-- Name: forms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.forms_id_seq', 17, true);


--
-- Name: materials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.materials_id_seq', 40, true);


--
-- Name: measurement_details_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.measurement_details_id_seq', 61, true);


--
-- Name: norms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.norms_id_seq', 14, true);


--
-- Name: reagent_suppliers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reagent_suppliers_id_seq', 5, true);


--
-- Name: receptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.receptions_id_seq', 143, true);


--
-- Name: receptions_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.receptions_id_seq1', 30, true);


--
-- Name: reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reports_id_seq', 36, true);


--
-- Name: sop_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sop_versions_id_seq', 139, true);


--
-- Name: sops_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sops_id_seq', 70, true);


--
-- Name: spec_headers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.spec_headers_id_seq', 25, true);


--
-- Name: spec_test_evals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.spec_test_evals_id_seq', 319, true);


--
-- Name: tests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tests_id_seq', 143, true);


--
-- Name: units_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.units_id_seq', 22, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 9, true);


--
-- Name: value_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.value_types_id_seq', 5, false);


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
-- Name: measurements measurements_user_update_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_user_update_id_fkey FOREIGN KEY (user_update_id) REFERENCES public.users(id);


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

