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
    test_count integer DEFAULT 0 NOT NULL,
    note_spec character varying(25) NOT NULL,
    is_conforming_spec boolean DEFAULT false NOT NULL
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
    is_reception_received boolean DEFAULT false NOT NULL
);


ALTER TABLE public.control_codes OWNER TO postgres;

--
-- Name: electronic_signatures; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.electronic_signatures (
    id bigint NOT NULL,
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
-- Name: equipment_calibrations; Type: TABLE; Schema: public; Owner: postgres
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
    status character varying(20) DEFAULT 'Active'::character varying NOT NULL,
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
    code character varying(5) NOT NULL,
    description text,
    norm_id bigint,
    is_product boolean DEFAULT false NOT NULL,
    is_raw_material boolean DEFAULT false NOT NULL,
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
    is_reported boolean DEFAULT false NOT NULL,
    user_reported_id bigint,
    is_readonly boolean DEFAULT false NOT NULL,
    user_update_id bigint NOT NULL,
    date_update timestamp with time zone NOT NULL
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
    value numeric NOT NULL
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
    test_frequency integer NOT NULL,
    condition character varying(255) NOT NULL,
    note character varying(150) NOT NULL
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
    unit_id bigint,
    norm_id bigint,
    norm_ref character varying(50),
    for_certification boolean DEFAULT false NOT NULL,
    nr_ord bigint DEFAULT 0 NOT NULL,
    is_form_validated boolean DEFAULT false NOT NULL,
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


--
-- Data for Name: certificate_tests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.certificate_tests VALUES (6, 25, 39, 3, 0, 150, 1, '> 100', true);
INSERT INTO public.certificate_tests VALUES (6, 25, 39, 4, 0, 600.5, 1, '< 1000', true);
INSERT INTO public.certificate_tests VALUES (6, 25, 46, 3, 0, 454.34, 1, '> 100', true);
INSERT INTO public.certificate_tests VALUES (6, 25, 46, 28, 0, 175.5, 1, '<= 50 or > 100', true);
INSERT INTO public.certificate_tests VALUES (6, 25, 46, 37, 0, 111, 1, '> 100 and <= 500', true);
INSERT INTO public.certificate_tests VALUES (6, 25, 46, 37, 1, 333, 1, '> 100 and <= 500', true);
INSERT INTO public.certificate_tests VALUES (6, 25, 46, 37, 2, 444, 1, '> 100 and <= 500', true);
INSERT INTO public.certificate_tests VALUES (6, 25, 46, 38, 0, 3, 1, '''Item KB'' or ''Item KC''', true);
INSERT INTO public.certificate_tests VALUES (7, 26, 47, 28, 0, 252.4, 1, '<= 50 or > 100', true);
INSERT INTO public.certificate_tests VALUES (7, 26, 47, 37, 0, 222, 1, '> 100 and <= 500', true);
INSERT INTO public.certificate_tests VALUES (7, 26, 47, 37, 1, 333, 1, '> 100 and <= 500', true);
INSERT INTO public.certificate_tests VALUES (7, 26, 47, 38, 0, 3, 1, '''Item KB'' or ''Item KC''', true);
INSERT INTO public.certificate_tests VALUES (7, 25, 39, 3, 0, 150, 2, '> 100', true);
INSERT INTO public.certificate_tests VALUES (7, 25, 39, 4, 0, 600.5, 2, '< 1000', true);
INSERT INTO public.certificate_tests VALUES (7, 25, 46, 3, 0, 454.34, 2, '> 100', true);
INSERT INTO public.certificate_tests VALUES (8, 25, 39, 4, 0, 600.5, 3, '< 1000', true);
INSERT INTO public.certificate_tests VALUES (8, 28, 48, 28, 0, 192.6, 1, '<= 50 or > 100', true);
INSERT INTO public.certificate_tests VALUES (8, 28, 48, 37, 0, 333, 1, '> 100 and <= 500', true);
INSERT INTO public.certificate_tests VALUES (8, 28, 48, 37, 1, 444, 1, '> 100 and <= 500', true);
INSERT INTO public.certificate_tests VALUES (8, 28, 48, 38, 0, 2, 1, '''Item KB'' or ''Item KC''', true);
INSERT INTO public.certificate_tests VALUES (8, 28, 49, 3, 0, 862.4, 1, '> 100', true);
INSERT INTO public.certificate_tests VALUES (9, 29, 54, 51, 0, 44.4, 1, '>= 40', true);
INSERT INTO public.certificate_tests VALUES (9, 29, 54, 52, 0, 2, 1, '>= 1.75 and <= 2.10', true);
INSERT INTO public.certificate_tests VALUES (10, 30, 55, 55, 0, 25, 1, '<= 30', true);
INSERT INTO public.certificate_tests VALUES (10, 30, 55, 56, 0, 3.27, 1, '<= 5', true);
INSERT INTO public.certificate_tests VALUES (10, 30, 55, 57, 0, 4, 1, '>= 3 and <= 20', true);
INSERT INTO public.certificate_tests VALUES (11, 31, 56, 62, 0, 0.4, 1, '<= 0.50', true);
INSERT INTO public.certificate_tests VALUES (11, 31, 56, 62, 1, 0.38, 1, '<= 0.50', true);
INSERT INTO public.certificate_tests VALUES (11, 31, 56, 62, 2, 0.42, 1, '<= 0.50', true);
INSERT INTO public.certificate_tests VALUES (11, 31, 56, 62, 3, 0.44, 1, '<= 0.50', true);
INSERT INTO public.certificate_tests VALUES (11, 31, 56, 62, 4, 0.36, 1, '<= 0.50', true);
INSERT INTO public.certificate_tests VALUES (11, 31, 56, 63, 0, 0.4, 1, '<= 0.50', true);
INSERT INTO public.certificate_tests VALUES (11, 31, 56, 64, 0, 0.032, 1, '<= 0.050', true);
INSERT INTO public.certificate_tests VALUES (11, 31, 56, 65, 0, 5, 1, '>= 3 and <= 5', true);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 66, 0, 52.1, 1, '>= 45.0', true);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 66, 1, 49.5, 1, '>= 45.0', true);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 66, 2, 50.8, 1, '>= 45.0', true);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 66, 3, 51.6, 1, '>= 45.0', true);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 72, 0, 51.0, 1, '>= 50.0', true);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 73, 0, 2.312, 1, '>= 0', true);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 73, 1, 2.298, 1, '>= 0', true);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 73, 2, 2.325, 1, '>= 0', true);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 73, 3, 2.305, 1, '>= 0', true);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 74, 0, 0.47, 1, '<= 1.30', true);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 75, 0, 4, 1, '>= 3', true);
INSERT INTO public.certificate_tests VALUES (12, 32, 57, 76, 0, 93.9, 1, '>= 92.0 and <= 97.0', true);
INSERT INTO public.certificate_tests VALUES (13, 33, 58, 78, 0, 5015, 1, '>= 5000.0', true);
INSERT INTO public.certificate_tests VALUES (13, 33, 58, 91, 0, 100, 1, '== 100', true);
INSERT INTO public.certificate_tests VALUES (13, 33, 58, 92, 0, 95, 1, '>= 90 and <= 100', true);
INSERT INTO public.certificate_tests VALUES (13, 33, 58, 93, 0, 60, 1, '>= 40 and <= 65', true);
INSERT INTO public.certificate_tests VALUES (13, 33, 58, 94, 0, 30, 1, '>= 15 and <= 35', true);
INSERT INTO public.certificate_tests VALUES (13, 33, 58, 95, 0, 10.1, 1, '>= 2.0 and <= 12.0', true);
INSERT INTO public.certificate_tests VALUES (13, 33, 58, 96, 0, 0.10, 1, '<= 0.30', true);


--
-- Data for Name: certificates; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (6, 34, 11, true, true, 1, '2025-12-13 18:17:42.218999+02', 'All testing results are according to specification
All mandatory tests have been performed', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (7, 35, 11, true, true, 1, '2025-12-13 18:17:42.218999+02', 'All testing results are according to specification
All mandatory tests have been performed', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (8, 63, 11, true, false, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (11, 74, 20, true, true, 1, '2026-07-10 02:01:33.83174+03', 'All testing results are according to specification
------------
Officia dignissimos tempora commodi est sunt saepe veniam recusandae ex fuga id', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (9, 72, 18, true, true, 1, '2026-07-07 20:05:58.791421+03', 'All testing results are according to specification
------------
Veritatis itaque quis soluta labore tenetur', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (10, 73, 19, true, true, 1, '2026-07-07 20:07:20.403415+03', 'All testing results are according to specification
------------
Commodi ratione vero dicta maxime', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (12, 75, 21, true, true, 1, '2026-07-11 23:07:07.87595+03', 'All testing results are according to specification
------------
Veritatis itaque quis soluta labore tenetur', NULL, false, NULL, NULL, NULL);
INSERT INTO public.certificates OVERRIDING SYSTEM VALUE VALUES (13, 76, 22, true, true, 1, '2026-07-17 22:01:52.032873+03', 'All testing results are according to specification
------------
Commodi ratione vero dicta maxime', NULL, false, NULL, NULL, NULL);


--
-- Data for Name: control_codes; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (1, 15, 'BATCH-REC-1-1', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (2, 15, 'SN-REC-1-2', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (3, 18, 'BATCH-REC-1-3', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (4, 15, 'SN-REC-1-4', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (5, 20, 'BATCH-REC-1-5', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (6, 1, 'SN-REC-2-1', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (7, 15, 'SN-REC-2-2', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (8, 15, 'SN-REC-2-3', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (9, 20, 'SN-REC-2-4', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (10, 17, 'DEL-CODE-3-1', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (11, 17, 'DEL-CODE-3-2', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (12, 21, 'DEL-CODE-4-1', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (13, 17, 'DEL-CODE-4-2', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (14, 19, 'DEL-CODE-4-3', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (15, 1, 'STORAGE-CODE-5-1', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (16, 18, 'STORAGE-CODE-5-2', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (17, 20, 'STORAGE-CODE-5-3', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (18, 18, 'STORAGE-CODE-6-1', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (19, 18, 'STORAGE-CODE-6-2', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (20, 18, 'OWNERSHIP-CODE-7-1', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (21, 8, 'OWNERSHIP-CODE-7-2', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (22, 15, 'OWNERSHIP-CODE-7-3', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (23, 18, 'OWNERSHIP-CODE-8-1', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (24, 17, 'OWNERSHIP-CODE-8-2', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (25, 17, 'OWNERSHIP-CODE-8-3', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (26, 20, 'GEN-1-CODE-9-1', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (27, 11, 'GEN-1-CODE-9-2', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (28, 6, 'GEN-1-CODE-9-3', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (29, 15, 'GEN-1-CODE-9-4', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (30, 3, 'GEN-2-CODE-10-1', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (31, 19, 'GEN-2-CODE-10-2', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (32, 15, 'GEN-2-CODE-10-3', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (33, 4, 'GEN-2-CODE-10-4', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (34, 5, 'GEN-2-CODE-10-5', true);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (35, 5, 'GEN-3-CODE-11-1', true);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (36, 13, 'GEN-3-CODE-11-2', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (37, 20, 'GEN-3-CODE-11-3', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (38, 20, 'GEN-3-CODE-11-4', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (39, 13, 'GEN-3-CODE-11-5', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (40, 21, 'PROD-A-1-212858', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (41, 1, 'GEN-1-2025-07-15', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (42, 2, 'GEN-2-2025-07-15', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (43, 3, 'GEN-3-2025-07-15', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (44, 21, 'PROD-A-2-212858', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (45, 1, 'GEN-1-2025-07-05', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (46, 2, 'GEN-2-2025-07-05', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (47, 21, 'PROD-A-3-212858', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (48, 1, 'GEN-1-2025-06-25', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (49, 2, 'GEN-2-2025-06-25', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (50, 3, 'GEN-3-2025-06-25', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (51, 21, 'PROD-A-4-212858', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (52, 1, 'GEN-1-2025-06-15', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (53, 2, 'GEN-2-2025-06-15', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (54, 21, 'PROD-A-5-212858', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (55, 1, 'GEN-1-2025-06-05', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (56, 2, 'GEN-2-2025-06-05', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (57, 3, 'GEN-3-2025-06-05', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (58, 21, 'PROD-A-6-212858', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (59, 1, 'GEN-1-2025-05-26', true);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (60, 2, 'GEN-2-2025-05-26', true);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (62, 4, 'GEN-4-2025-06-25', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (63, 5, 'GEN-5-2025-06-25', true);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (64, 3, 'GEN-3-2025-05-26', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (65, 4, 'GEN-4-2025-05-26', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (66, 3, 'GEN-3-2025-04-26', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (67, 4, 'GEN-4-2025-04-26', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (68, 5, 'GEN-5-2025-04-26', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (69, 3, 'GEN-3-2025-03-27', true);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (70, 4, 'GEN-4-2025-03-27', true);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (71, 2, 'WERT-TER-ERT-ER', false);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (72, 22, 'GEN-5-2026-07-06', true);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (73, 23, 'GEN-5-2026-07-07', true);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (74, 24, 'GEN-5-2026-07-08', true);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (75, 25, 'LOT-04-BND-I95', true);
INSERT INTO public.control_codes OVERRIDING SYSTEM VALUE VALUES (76, 26, 'LOT-04-BASE-01', true);


--
-- Data for Name: electronic_signatures; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: equipment_calibrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (1, 1, '2023-07-01', '2024-07-01', 'CERT-CM-2023-01', 'Instron Calibration Services', 'Pass', 'Class Load Cell #LC-500 (Cert #CAL-8820)', 0.15, '2026-08-24 15:37:15.245797+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (2, 1, '2024-07-02', '2025-07-02', 'CERT-CM-2024-01', 'Instron Calibration Services', 'Pass', 'Class Load Cell #LC-500 (Cert #CAL-9104)', 0.14, '2026-08-24 15:37:15.246661+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (3, 1, '2025-07-03', '2026-07-03', 'CERT-CM-2025-01', 'Instron Calibration Services', 'Pass', 'Class Load Cell #LC-500 (Cert #CAL-9541)', 0.12, '2026-08-24 15:37:15.24668+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (4, 1, '2026-07-01', '2027-07-01', 'CERT-CM-2026-01', 'Instron Calibration Services', 'Pass', 'Class Load Cell #LC-500 (Cert #CAL-9980)', 0.12, '2026-08-24 15:37:15.246689+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (5, 2, '2023-07-10', '2024-07-10', 'CERT-OV-2023-A', 'Thermal Tech Metrology', 'Pass', 'Calibrated Thermocouple Array #TC-04 (Cert #T-1021)', 0.40, '2026-08-24 15:37:15.24722+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (6, 2, '2024-07-10', '2025-07-10', 'CERT-OV-2024-A', 'Thermal Tech Metrology', 'Pass', 'Calibrated Thermocouple Array #TC-04 (Cert #T-1402)', 0.35, '2026-08-24 15:37:15.24723+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (7, 2, '2025-07-08', '2026-07-08', 'CERT-OV-2025-A', 'Thermal Tech Metrology', 'Pass', 'Calibrated Thermocouple Array #TC-04 (Cert #T-1899)', 0.30, '2026-08-24 15:37:15.247237+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (8, 2, '2026-07-08', '2027-07-08', 'CERT-OV-2026-A', 'Thermal Tech Metrology', 'Pass', 'Calibrated Thermocouple Array #TC-04 (Cert #T-2201)', 0.30, '2026-08-24 15:37:15.247242+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (9, 3, '2023-07-12', '2024-07-12', 'CERT-SHK-2023-01', 'Precision Mechanical Metrology', 'Pass', 'Digital Tachometer & Timer Standard #ST-01', 0.05, '2026-08-24 15:37:15.247493+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (10, 3, '2024-07-12', '2025-07-12', 'CERT-SHK-2024-01', 'Precision Mechanical Metrology', 'Pass', 'Digital Tachometer & Timer Standard #ST-01', 0.05, '2026-08-24 15:37:15.247503+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (11, 3, '2025-07-11', '2026-07-11', 'CERT-SHK-2025-01', 'Precision Mechanical Metrology', 'Pass', 'Digital Tachometer & Timer Standard #ST-01', 0.04, '2026-08-24 15:37:15.24751+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (12, 3, '2026-07-10', '2027-07-10', 'CERT-SHK-2026-01', 'Precision Mechanical Metrology', 'Pass', 'Digital Tachometer & Timer Standard #ST-01', 0.04, '2026-08-24 15:37:15.247516+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (13, 4, '2024-12-10', '2025-06-08', 'CERT-BAL1-2024-2', 'Accredited Weights & Measures', 'Pass', 'Class E2 Mass Standard Set (Cert #W-8812)', 0.00015, '2026-08-24 15:37:15.24773+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (14, 4, '2025-06-08', '2025-12-05', 'CERT-BAL1-2025-1', 'Accredited Weights & Measures', 'Pass', 'Class E2 Mass Standard Set (Cert #W-9102)', 0.00012, '2026-08-24 15:37:15.247738+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (15, 4, '2025-12-05', '2026-06-03', 'CERT-BAL1-2025-2', 'Accredited Weights & Measures', 'Pass', 'Class E2 Mass Standard Set (Cert #W-9400)', 0.00010, '2026-08-24 15:37:15.247744+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (16, 4, '2026-06-02', '2026-11-29', 'CERT-BAL1-2026-1', 'Accredited Weights & Measures', 'Pass', 'Class E2 Mass Standard Set (Cert #W-9811)', 0.00010, '2026-08-24 15:37:15.247752+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (17, 5, '2024-12-15', '2025-06-13', 'CERT-BAL2-2024-2', 'Accredited Weights & Measures', 'Pass', 'Class F Heavy Mass Set (Cert #HW-2021)', 0.08, '2026-08-24 15:37:15.247941+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (18, 5, '2025-06-12', '2025-12-09', 'CERT-BAL2-2025-1', 'Accredited Weights & Measures', 'Pass', 'Class F Heavy Mass Set (Cert #HW-2401)', 0.08, '2026-08-24 15:37:15.24795+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (19, 5, '2025-12-08', '2026-06-06', 'CERT-BAL2-2025-2', 'Accredited Weights & Measures', 'Pass', 'Class F Heavy Mass Set (Cert #HW-2810)', 0.05, '2026-08-24 15:37:15.247957+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (20, 5, '2026-06-05', '2026-12-02', 'CERT-BAL2-2026-1', 'Accredited Weights & Measures', 'Pass', 'Class F Heavy Mass Set (Cert #HW-3102)', 0.05, '2026-08-24 15:37:15.247963+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (21, 6, '2023-07-05', '2024-07-05', 'CERT-OV101-2023', 'Thermal Tech Metrology', 'Pass', 'NIST Traceable Calibrated Thermocouple Array #TC-02 (Cert #T-8810)', 0.25, '2026-08-25 20:50:39.640105+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (22, 6, '2024-07-05', '2025-07-05', 'CERT-OV101-2024', 'Thermal Tech Metrology', 'Pass', 'NIST Traceable Calibrated Thermocouple Array #TC-02 (Cert #T-9201)', 0.25, '2026-08-25 20:50:39.641318+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (23, 6, '2025-07-05', '2026-07-05', 'CERT-OV101-2025', 'Thermal Tech Metrology', 'Pass', 'NIST Traceable Calibrated Thermocouple Array #TC-02 (Cert #T-9650)', 0.20, '2026-08-25 20:50:39.641334+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (24, 6, '2026-07-05', '2027-07-05', 'CERT-OV101-2026', 'Thermal Tech Metrology', 'Pass', 'NIST Traceable Calibrated Thermocouple Array #TC-02 (Cert #T-10042)', 0.20, '2026-08-25 20:50:39.641342+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (25, 7, '2023-07-01', '2024-07-01', 'CERT-CAL-2023-01', 'Precision Metrology Inc.', 'Pass', 'Metric Gauge Block Set Class 0 (Cert #GB-1029)', 0.02, '2026-08-25 21:18:24.147114+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (26, 7, '2024-07-01', '2025-07-01', 'CERT-CAL-2024-01', 'Precision Metrology Inc.', 'Pass', 'Metric Gauge Block Set Class 0 (Cert #GB-1410)', 0.02, '2026-08-25 21:18:24.147673+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (27, 7, '2025-07-01', '2026-07-01', 'CERT-CAL-2025-01', 'Precision Metrology Inc.', 'Pass', 'Metric Gauge Block Set Class 0 (Cert #GB-1892)', 0.01, '2026-08-25 21:18:24.147684+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (28, 7, '2026-07-01', '2027-07-01', 'CERT-CAL-2026-01', 'Precision Metrology Inc.', 'Pass', 'Metric Gauge Block Set Class 0 (Cert #GB-2204)', 0.01, '2026-08-25 21:18:24.147693+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (29, 8, '2023-07-02', '2024-07-02', 'CERT-WB-2023-01', 'Thermal Tech Metrology', 'Pass', 'NIST Traceable Temperature Standard Probe #PR-09', 0.10, '2026-08-25 21:18:24.148377+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (30, 8, '2024-07-02', '2025-07-02', 'CERT-WB-2024-01', 'Thermal Tech Metrology', 'Pass', 'NIST Traceable Temperature Standard Probe #PR-09', 0.10, '2026-08-25 21:18:24.148395+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (31, 8, '2025-07-02', '2026-07-02', 'CERT-WB-2025-01', 'Thermal Tech Metrology', 'Pass', 'NIST Traceable Temperature Standard Probe #PR-09', 0.08, '2026-08-25 21:18:24.148409+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (32, 8, '2026-07-02', '2027-07-02', 'CERT-WB-2026-01', 'Thermal Tech Metrology', 'Pass', 'NIST Traceable Temperature Standard Probe #PR-09', 0.08, '2026-08-25 21:18:24.148421+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (33, 9, '2023-06-15', '2024-06-15', 'CERT-TH-2023-01', 'Primary Metrology Standards Lab', 'Pass', 'Standard Platinum Resistance Thermometer (SPRT #112)', 0.02, '2026-08-25 21:18:24.148716+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (34, 9, '2024-06-15', '2025-06-15', 'CERT-TH-2024-01', 'Primary Metrology Standards Lab', 'Pass', 'Standard Platinum Resistance Thermometer (SPRT #112)', 0.02, '2026-08-25 21:18:24.148727+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (35, 9, '2025-06-15', '2026-06-15', 'CERT-TH-2025-01', 'Primary Metrology Standards Lab', 'Pass', 'Standard Platinum Resistance Thermometer (SPRT #112)', 0.01, '2026-08-25 21:18:24.148735+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (36, 9, '2026-06-15', '2027-06-15', 'CERT-TH-2026-01', 'Primary Metrology Standards Lab', 'Pass', 'Standard Platinum Resistance Thermometer (SPRT #112)', 0.01, '2026-08-25 21:18:24.148742+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (37, 10, '2023-07-04', '2024-07-04', 'CERT-CAL2-2023', 'Precision Metrology Inc.', 'Pass', 'Metric Gauge Block Set Class 0 (Cert #GB-1029)', 0.02, '2026-08-25 21:37:36.086478+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (38, 10, '2024-07-04', '2025-07-04', 'CERT-CAL2-2024', 'Precision Metrology Inc.', 'Pass', 'Metric Gauge Block Set Class 0 (Cert #GB-1410)', 0.02, '2026-08-25 21:37:36.087247+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (39, 10, '2025-07-04', '2026-07-04', 'CERT-CAL2-2025', 'Precision Metrology Inc.', 'Pass', 'Metric Gauge Block Set Class 0 (Cert #GB-1892)', 0.01, '2026-08-25 21:37:36.08726+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (40, 10, '2026-07-04', '2027-07-04', 'CERT-CAL2-2026', 'Precision Metrology Inc.', 'Pass', 'Metric Gauge Block Set Class 0 (Cert #GB-2204)', 0.01, '2026-08-25 21:37:36.08727+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (41, 11, '2023-07-01', '2024-07-01', 'CERT-CTK2-2023', 'Thermal Tech Metrology', 'Pass', 'NIST Traceable Reference Thermometer Probe #PR-04', 0.15, '2026-08-25 21:37:36.088068+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (42, 11, '2024-07-01', '2025-07-01', 'CERT-CTK2-2024', 'Thermal Tech Metrology', 'Pass', 'NIST Traceable Reference Thermometer Probe #PR-04', 0.15, '2026-08-25 21:37:36.088093+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (43, 11, '2025-07-01', '2026-07-01', 'CERT-CTK2-2025', 'Thermal Tech Metrology', 'Pass', 'NIST Traceable Reference Thermometer Probe #PR-04', 0.10, '2026-08-25 21:37:36.088107+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (44, 11, '2026-07-01', '2027-07-01', 'CERT-CTK2-2026', 'Thermal Tech Metrology', 'Pass', 'NIST Traceable Reference Thermometer Probe #PR-04', 0.10, '2026-08-25 21:37:36.08812+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (45, 12, '2023-06-28', '2024-06-28', 'CERT-FEEL-2023', 'Quality Assurance Calibration LLC', 'Pass', 'Optical Flat & Master Micrometer Set (Cert #MM-8012)', 0.005, '2026-08-25 21:37:36.088529+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (46, 12, '2024-06-28', '2025-06-28', 'CERT-FEEL-2024', 'Quality Assurance Calibration LLC', 'Pass', 'Optical Flat & Master Micrometer Set (Cert #MM-8410)', 0.005, '2026-08-25 21:37:36.088551+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (47, 12, '2025-06-28', '2026-06-28', 'CERT-FEEL-2025', 'Quality Assurance Calibration LLC', 'Pass', 'Optical Flat & Master Micrometer Set (Cert #MM-8901)', 0.003, '2026-08-25 21:37:36.088564+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (48, 12, '2026-06-28', '2027-06-28', 'CERT-FEEL-2026', 'Quality Assurance Calibration LLC', 'Pass', 'Optical Flat & Master Micrometer Set (Cert #MM-9204)', 0.003, '2026-08-25 21:37:36.088582+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (49, 13, '2023-07-10', '2024-07-10', 'CERT-SEV-2023', 'Optical Metrology Services', 'Pass', 'NIST-Traceable Automated Optical Comparator (Cert #OPT-4011)', 0.005, '2026-08-25 21:57:42.807021+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (50, 13, '2024-07-10', '2025-07-10', 'CERT-SEV-2024', 'Optical Metrology Services', 'Pass', 'NIST-Traceable Automated Optical Comparator (Cert #OPT-4450)', 0.005, '2026-08-25 21:57:42.807792+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (51, 13, '2025-07-10', '2026-07-10', 'CERT-SEV-2025', 'Optical Metrology Services', 'Pass', 'NIST-Traceable Automated Optical Comparator (Cert #OPT-4902)', 0.003, '2026-08-25 21:57:42.809092+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (52, 13, '2026-07-10', '2027-07-10', 'CERT-SEV-2026', 'Optical Metrology Services', 'Pass', 'NIST-Traceable Automated Optical Comparator (Cert #OPT-5310)', 0.003, '2026-08-25 21:57:42.809111+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (53, 14, '2023-07-05', '2024-07-05', 'CERT-SPL-2023', 'Quality Assurance Calibration LLC', 'Pass', 'Digital Caliper Standard #CAL-02 (Cert #GB-1029)', 0.05, '2026-08-25 21:57:42.809849+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (54, 14, '2024-07-05', '2025-07-05', 'CERT-SPL-2024', 'Quality Assurance Calibration LLC', 'Pass', 'Digital Caliper Standard #CAL-02 (Cert #GB-1410)', 0.05, '2026-08-25 21:57:42.809865+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (55, 14, '2025-07-05', '2026-07-05', 'CERT-SPL-2025', 'Quality Assurance Calibration LLC', 'Pass', 'Digital Caliper Standard #CAL-02 (Cert #GB-1892)', 0.03, '2026-08-25 21:57:42.809875+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (56, 14, '2026-07-05', '2027-07-05', 'CERT-SPL-2026', 'Quality Assurance Calibration LLC', 'Pass', 'Digital Caliper Standard #CAL-02 (Cert #GB-2204)', 0.03, '2026-08-25 21:57:42.809884+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (57, 15, '2023-06-20', '2024-06-20', 'CERT-TMR-2023', 'Primary Metrology Standards Lab', 'Pass', 'Atomic Frequency Standard Master Clock #CLK-01', 0.001, '2026-08-25 21:57:42.810186+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (58, 15, '2024-06-20', '2025-06-20', 'CERT-TMR-2024', 'Primary Metrology Standards Lab', 'Pass', 'Atomic Frequency Standard Master Clock #CLK-01', 0.001, '2026-08-25 21:57:42.810198+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (59, 15, '2025-06-20', '2026-06-20', 'CERT-TMR-2025', 'Primary Metrology Standards Lab', 'Pass', 'Atomic Frequency Standard Master Clock #CLK-01', 0.001, '2026-08-25 21:57:42.810207+03');
INSERT INTO public.equipment_calibrations OVERRIDING SYSTEM VALUE VALUES (60, 15, '2026-06-20', '2027-06-20', 'CERT-TMR-2026', 'Primary Metrology Standards Lab', 'Pass', 'Atomic Frequency Standard Master Clock #CLK-01', 0.001, '2026-08-25 21:57:42.810218+03');


--
-- Data for Name: equipments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (1, 'CM-400', 'Digital Compression Press', 'Forney Test Equipment', 'CM-400', 'SN-CM400-8812', 'Concrete Testing Lab - Room 102', 'Active', 365, '2027-07-01', '2026-08-24 15:37:15.243265+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (2, 'OV-102', 'Vacuum Drying Oven', 'Hasuc Equipment', 'DHG-9030A', 'SN-OV102-4419', 'Raw Material Quality Lab - Room 204', 'Active', 365, '2027-07-08', '2026-08-24 15:37:15.24514+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (3, 'SHK-04', '8-inch Mechanical Sieve Shaker', 'W.S. Tyler', 'Ro-Tap RX-29', 'SN-SHK04-1092', 'Aggregate & Soils Lab - Room 108', 'Active', 365, '2027-07-10', '2026-08-24 15:37:15.245172+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (4, 'BAL-001', 'Micro/Analytical Balance (0.1mg)', 'Mettler Toledo', 'XPR204S', 'SN-BAL001-9931', 'Analytical Chemistry Lab - Bench A', 'Active', 180, '2026-11-29', '2026-08-24 15:37:15.245176+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (5, 'BAL-002', 'High-Capacity Precision Balance (0.1g)', 'Ohaus', 'Ranger 7000', 'SN-BAL002-3301', 'Physical Testing Lab - Bench C', 'Active', 180, '2026-12-02', '2026-08-24 15:37:15.24518+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (6, 'OV-101', 'Forced Air Convection Drying Oven (103-105°C)', 'Thermo Scientific', 'Heratherm OGH100', 'SN-OV101-7720', 'Environmental Chemistry Lab - Room 202', 'Active', 365, '2027-07-05', '2026-08-25 20:50:39.636872+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (7, 'CAL-001', 'Digital Depth Caliper (0-300mm)', 'Mitutoyo', 'CD-12"CX', 'SN-CAL001-5541', 'Physical Testing Lab - Bench C', 'Active', 365, '2027-07-01', '2026-08-25 21:18:24.144206+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (8, 'WB-101', 'Recirculating Hydrostatic Water Bath', 'Humboldt Mfg.', 'H-1390', 'SN-WB101-9012', 'Physical Testing Lab - Room 104', 'Active', 365, '2027-07-02', '2026-08-25 21:18:24.145389+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (9, 'TH-101', 'Precision Digital Reference Thermometer', 'Fluke Calibration', '1523', 'SN-TH101-3310', 'Physical Testing Lab - Room 104', 'Active', 365, '2027-06-15', '2026-08-25 21:18:24.145398+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (10, 'CAL-002', 'Digital Heavy-Duty Caliper (0-300mm)', 'Mitutoyo', '500-197-30', 'SN-CAL002-8841', 'Concrete Testing Lab - Room 102', 'Active', 365, '2027-07-04', '2026-08-25 21:37:36.08147+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (11, 'CTK-002', 'Curing Tank #2 Temperature Monitoring System', 'Gilson Company', 'HM-652', 'SN-CTK002-1102', 'Concrete Curing Room - Water Tank #2', 'Active', 365, '2027-07-01', '2026-08-25 21:37:36.083335+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (12, 'FEEL-001', 'Precision Straightedge & Feeler Gauge Set', 'Starrett', '270 / 380-12', 'SN-FEEL001-4091', 'Concrete Testing Lab - Room 102', 'Active', 365, '2027-06-28', '2026-08-25 21:37:36.083359+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (13, 'SEV-SET-01', 'ASTM E11 8-inch Certified Test Sieve Stack', 'W.S. Tyler', '8in Full Height SS Set', 'SN-SEV8820-SET', 'Aggregate & Soils Lab - Room 108', 'Active', 365, '2027-07-10', '2026-08-25 21:57:42.802935+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (14, 'SPL-001', 'Mechanical Riffle Sample Splitter', 'Gilson Company', 'SP-1 Universal', 'SN-SPL001-3049', 'Aggregate & Soils Lab - Room 108', 'Active', 365, '2027-07-05', '2026-08-25 21:57:42.804464+03');
INSERT INTO public.equipments OVERRIDING SYSTEM VALUE VALUES (15, 'TMR-001', 'Digital Calibration Stopwatch / Process Timer', 'Traceable Products', '5004 Precision Timer', 'SN-TMR001-1120', 'Aggregate & Soils Lab - Room 108', 'Active', 365, '2027-06-20', '2026-08-25 21:57:42.804502+03');


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


--
-- Data for Name: forms; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (8, 8, 'v1', false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (9, 8, 'v2', false, NULL, false, 1, '2025-12-13 18:17:42.218999+02', NULL, false, NULL, NULL, NULL, false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (1, 1, 'v0', true, 'TestingFormA', true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 16:41:53.493203+02', 'Qui quis eum blanditiis accusantium accusamus.', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (2, 2, 'v0', false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 16:43:14.869321+02', 'Sequi veritatis distinctio delectus atque nesciunt fugit.
Aliquam placeat iste qui unde eaque.', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (3, 3, 'v0', false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 16:47:43.20068+02', '- Atque quisquam inventore labore a eaque
- Consectetur consectetur incidunt deleniti mollitia sint', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (4, 4, 'v0', false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 17:00:21.39342+02', '- Accusamus quas id asperiores placeat voluptatem
- Atque ex facilis non magni error quis', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (5, 5, 'v0', false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 17:46:34.396668+02', '- Assumenda eligendi illum voluptatum perspiciatis vel
- Harum soluta nihil excepturi
- Vero quidem alias tempora', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (6, 6, 'v0', false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 17:48:50.759892+02', '- Itaque veniam consequuntur ipsa 
- Saepe error vel voluptas laborum dolore
- Nesciunt sed quibusdam molestiae non ', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (7, 8, 'v0', false, NULL, true, 1, '2025-12-13 18:17:42.218999+02', NULL, true, 1, '2026-01-08 18:03:04.415193+02', 'Occaecati iusto explicabo excepturi beatae quibusdam', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (10, 9, 'Rev. 3', false, NULL, true, 1, '2026-07-06 04:48:51.328592+03', NULL, true, 1, '2026-07-06 17:47:12.555158+03', 'Occaecati iusto explicabo excepturi beatae quibusdam', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (11, 10, 'v0', false, NULL, true, 1, '2026-07-07 18:33:55.310236+03', NULL, true, 1, '2026-07-07 19:13:30.471004+03', 'Officia dignissimos tempora commodi est sunt saepe veniam recusandae ex fuga id', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (12, 11, 'v0', false, NULL, true, 1, '2026-07-09 16:17:27.170738+03', NULL, true, 1, '2026-07-09 16:34:18.790669+03', 'Officia dignissimos tempora commodi est sunt saepe veniam recusandae ex fuga id', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (14, 13, 'v0', false, NULL, true, 1, '2026-07-17 20:04:53.080888+03', NULL, true, 1, '2026-07-17 21:57:56.002485+03', 'Officia dignissimos tempora commodi est sunt saepe veniam recusandae ex fuga id', false, NULL, NULL, NULL);
INSERT INTO public.forms OVERRIDING SYSTEM VALUE VALUES (13, 12, 'v0', false, NULL, true, 1, '2026-07-11 22:12:27.54704+03', NULL, true, 1, '2026-08-10 14:57:09.819953+03', 'Officia dignissimos tempora commodi est sunt saepe veniam recusandae ex fuga id', false, NULL, NULL, NULL);


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


--
-- Data for Name: materials; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (1, 'Material A', 'MA', 'Description for Material A', 2, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (2, 'Material B', 'MB', 'Description for Material B', 4, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (3, 'Material C', 'MC', 'Description for Material C', 1, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (4, 'Material D', 'MD', 'Description for Material D', 3, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (5, 'Material E', 'ME', 'Description for Material E', 1, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (6, 'Material F', 'NF', 'Description for Material F', 2, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (7, 'Material G', 'MG', 'Description for Material G', 3, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (8, 'Material H', 'MH', 'Description for Material H', 3, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (9, 'Material I', 'MI', 'Description for Material I', 4, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (10, 'Material J', 'MJ', 'Description for Material J', 4, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (11, 'Material K', 'MK', 'Description for Material K', 4, false, false, '2025-12-13 18:17:42.218999+02', true, '2026-01-23 22:43:26.698445+02', 'Some explanations ...');
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (12, 'Material L', 'ML', 'Description for Material L', 1, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (13, 'Material M', 'MM', 'Description for Material M', 1, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (14, 'Material N', 'MN', 'Description for Material N', 2, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (15, 'Material O', 'MO', 'Description for Material O', 4, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (16, 'Material P', 'MP', 'Description for Material P', 3, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (17, 'Material Q', 'MQ', 'Description for Material Q', 3, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (18, 'Material R', 'MR', 'Description for Material R', 1, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (19, 'Material S', 'MS', 'Description for Material S', 2, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (20, 'Material T', 'MT', 'Description for Material T', 4, false, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (21, 'Finished Product A', 'FPA', 'A product made from various materials', 3, true, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (22, 'Concrete TS', 'CTS', 'Description for Concrete TS', 6, true, false, '2026-07-06 15:04:17.472048+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (23, 'Outfall Pipeline #4', 'OP4', 'Occaecati iusto explicabo excepturi beatae quibusdam', 7, false, false, '2026-07-07 19:19:57.222801+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (24, 'Citric Acid Anhydrous', 'CAA', 'Occaecati iusto explicabo excepturi beatae quibusdam', 8, false, true, '2026-07-09 16:36:08.376573+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (25, 'Pavement Cors', 'PC', 'Excepturi beatae quibusdam', 10, false, false, '2026-07-11 22:47:51.622353+03', false, NULL, NULL);
INSERT INTO public.materials OVERRIDING SYSTEM VALUE VALUES (26, 'Aggregate TC', 'TC', 'Occaecati iusto explicabo excepturi beatae quibusdam', 12, false, true, '2026-07-17 20:35:52.843489+03', false, NULL, NULL);


--
-- Data for Name: measurement_equipments; Type: TABLE DATA; Schema: public; Owner: postgres
--



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

INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (1, 2, NULL, NULL, true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (3, 2, NULL, NULL, true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (29, 1, NULL, NULL, true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (35, 10, NULL, NULL, true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (36, 2, NULL, NULL, true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (37, 2, NULL, NULL, true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (38, 11, NULL, NULL, true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (39, 20, NULL, NULL, true, true, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (43, 20, NULL, NULL, true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (44, 20, NULL, NULL, true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (45, 20, NULL, NULL, true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (49, 22, NULL, NULL, true, true, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (52, 11, NULL, NULL, true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (53, 11, NULL, NULL, true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (5, 2, 1, 'quis nobis qui sit', true, true, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (8, 2, 2, 'libero dicta in culpa nihil ', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (9, 2, 3, '- Architecto nulla voluptas pariatur quam ex velit quaerat debitis a at.
- Laborum voluptates enim libero soluta.
- Minus harum harum non qui blanditiis itaque quaerat doloremque numquam at sed officia.', true, true, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (11, 6, NULL, 'iure vero tenetur eaque iusto ea exercitationem', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (12, 6, 1, 'commodi porro quos', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (13, 6, 2, 'veritatis autem tempora velit', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (14, 1, NULL, 'aut voluptatem odit quaerat perspiciatis quia', true, true, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (15, 1, 3, 'quam aliquid molestiae odio vero', true, true, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (16, 3, NULL, ' et assumenda debitis dolor aliquid', true, true, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (17, 3, 1, ' dolore repellendus hic possimus maiores ', true, true, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (18, 2, 3, ' ducimus', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (19, 8, NULL, 'iure officiis laboriosam praesentium fuga amet at', true, true, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (20, 8, 2, ' explicabo repudiandae', true, true, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (21, 8, 3, ' error sunt enim ipsa temporibus', true, true, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (22, 8, 1, 'assumenda facilis facere quidem', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (23, 3, NULL, 'quasi dolore assumenda quod illum quis', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (24, 8, NULL, 'dignissimos in explicabo itaque quos
nostrum id porro accusantium', true, false, NULL, false, 8, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (25, 8, 1, 'ab quia mollitia reiciendis et', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (26, 11, NULL, 'eum sed repellendus harum magni', true, true, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (2, 2, NULL, 'ea quae rem vero 
nam minus totam ', true, true, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (4, 2, NULL, 'Reprehenderit quos voluptas voluptatibus hic.
Qui fuga enim.
Voluptate ducimus nobis.
', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (7, 2, 1, ' velit iste totam', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (27, 11, 3, 'quaerat reiciendis nam aspernatur ab', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (28, 11, 2, 'reprehenderit quo nihil iure similique porro', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (31, 3, 2, 'minus ipsa minus eos eos', true, true, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (41, 20, 7, 'id eligendi ad excepturi quae quis', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (42, 20, 7, '- Non impedit quod totam veritatis cupiditate
- Eum expedita exercitationem ipsam quisquam consequuntur laboriosam dicta.', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (46, 20, NULL, '- Provident ducimus dolorem aperiam qui perferendis necessitatibus.
- Nam ad id cumque tempora repellat commodi.
- Libero quos iure mollitia ducimus.', true, true, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (47, 21, NULL, 'repellat fuga unde facilis ab similique', true, true, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (48, 22, NULL, 'libero eaque repellendus iste', true, true, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (50, 22, 7, 'nobis harum sequi', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (51, 22, 7, 'dicta porro expedita commodi', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (10, 2, NULL, 'Sint accusamus consectetur a exercitationem.
Adipisci optio nostrum quam.', true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (6, 2, 1, 'vitae aspernatur eligendi', true, true, 1, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (30, 1, NULL, NULL, true, false, NULL, false, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (54, 23, 10, 'Officia dignissimos tempora commodi est sunt saepe veniam recusandae ex fuga id', true, true, 1, true, 1, '2026-07-06 19:36:43.104787+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (55, 24, 11, '- Error numquam dicta cum.
- Veritatis itaque quis soluta labore tenetur.
- Commodi ratione vero dicta maxime.', true, true, 1, true, 1, '2026-07-07 19:59:50.502542+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (40, 20, 7, 'Error numquam dicta cum.
Veritatis itaque quis soluta labore tenetur.
Commodi ratione vero dicta maxime.', true, false, NULL, true, 1, '2025-12-13 18:17:42.218999+02');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (56, 25, 12, '- Error numquam dicta cum.
- Veritatis itaque quis soluta labore tenetur.
- Commodi ratione vero dicta maxime.
', true, true, 1, true, 1, '2026-07-09 18:56:38.708763+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (57, 26, 13, '- Error numquam dicta cum.
- Veritatis itaque quis soluta labore tenetur.
- Commodi ratione vero dicta maxime.
', true, true, 1, true, 1, '2026-07-11 23:05:15.65936+03');
INSERT INTO public.measurements OVERRIDING SYSTEM VALUE VALUES (58, 27, 14, '- Error numquam dicta cum.
- Veritatis itaque quis soluta labore tenetur.
- Commodi ratione vero dicta maxime.
', true, true, 1, true, 1, '2026-07-17 21:59:09.149834+03');


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


--
-- Data for Name: report_tests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.report_tests VALUES (20, 14, 1, 0, 434);
INSERT INTO public.report_tests VALUES (20, 15, 1, 0, 1172.5);
INSERT INTO public.report_tests VALUES (20, 15, 2, 0, 239.5);
INSERT INTO public.report_tests VALUES (20, 15, 3, 0, 5);
INSERT INTO public.report_tests VALUES (21, 2, 2, 0, 212);
INSERT INTO public.report_tests VALUES (21, 5, 3, 0, 391.2);
INSERT INTO public.report_tests VALUES (21, 9, 1, 0, 3653.6);
INSERT INTO public.report_tests VALUES (21, 9, 2, 0, 464.7);
INSERT INTO public.report_tests VALUES (21, 9, 3, 0, 8);
INSERT INTO public.report_tests VALUES (22, 16, 1, 0, 5467);
INSERT INTO public.report_tests VALUES (22, 17, 3, 0, 1134);
INSERT INTO public.report_tests VALUES (22, 31, 1, 0, 4654);
INSERT INTO public.report_tests VALUES (23, 19, 1, 0, 156);
INSERT INTO public.report_tests VALUES (23, 20, 1, 0, 789);
INSERT INTO public.report_tests VALUES (23, 21, 1, 0, 40646.3);
INSERT INTO public.report_tests VALUES (23, 21, 2, 0, 545.7);
INSERT INTO public.report_tests VALUES (23, 21, 3, 0, 89);
INSERT INTO public.report_tests VALUES (24, 40, 28, 0, 1999.67);
INSERT INTO public.report_tests VALUES (24, 40, 38, 0, 2);
INSERT INTO public.report_tests VALUES (24, 40, 37, 0, 224422);
INSERT INTO public.report_tests VALUES (24, 40, 37, 1, 336633);
INSERT INTO public.report_tests VALUES (24, 40, 37, 2, 44844);
INSERT INTO public.report_tests VALUES (25, 39, 3, 0, 150);
INSERT INTO public.report_tests VALUES (25, 39, 4, 0, 600.5);
INSERT INTO public.report_tests VALUES (25, 46, 3, 0, 454.34);
INSERT INTO public.report_tests VALUES (25, 46, 28, 0, 175.5);
INSERT INTO public.report_tests VALUES (25, 46, 37, 0, 111);
INSERT INTO public.report_tests VALUES (25, 46, 37, 1, 333);
INSERT INTO public.report_tests VALUES (25, 46, 37, 2, 444);
INSERT INTO public.report_tests VALUES (25, 46, 38, 0, 3);
INSERT INTO public.report_tests VALUES (25, 46, 41, 0, 1);
INSERT INTO public.report_tests VALUES (26, 47, 28, 0, 252.4);
INSERT INTO public.report_tests VALUES (26, 47, 37, 0, 222);
INSERT INTO public.report_tests VALUES (26, 47, 37, 1, 333);
INSERT INTO public.report_tests VALUES (26, 47, 38, 0, 3);
INSERT INTO public.report_tests VALUES (27, 48, 28, 0, 192.6);
INSERT INTO public.report_tests VALUES (27, 48, 37, 0, 333);
INSERT INTO public.report_tests VALUES (27, 48, 37, 1, 444);
INSERT INTO public.report_tests VALUES (27, 48, 38, 0, 2);
INSERT INTO public.report_tests VALUES (28, 48, 28, 0, 192.6);
INSERT INTO public.report_tests VALUES (28, 48, 37, 0, 333);
INSERT INTO public.report_tests VALUES (28, 48, 37, 1, 444);
INSERT INTO public.report_tests VALUES (28, 48, 38, 0, 2);
INSERT INTO public.report_tests VALUES (28, 49, 3, 0, 862.4);
INSERT INTO public.report_tests VALUES (29, 54, 51, 0, 44.4);
INSERT INTO public.report_tests VALUES (29, 54, 52, 0, 2);
INSERT INTO public.report_tests VALUES (30, 55, 55, 0, 25);
INSERT INTO public.report_tests VALUES (30, 55, 56, 0, 3.27);
INSERT INTO public.report_tests VALUES (30, 55, 57, 0, 4);
INSERT INTO public.report_tests VALUES (31, 56, 62, 0, 0.4);
INSERT INTO public.report_tests VALUES (31, 56, 63, 0, 0.4);
INSERT INTO public.report_tests VALUES (31, 56, 64, 0, 0.032);
INSERT INTO public.report_tests VALUES (31, 56, 65, 0, 5);
INSERT INTO public.report_tests VALUES (31, 56, 62, 4, 0.36);
INSERT INTO public.report_tests VALUES (31, 56, 62, 3, 0.44);
INSERT INTO public.report_tests VALUES (31, 56, 62, 2, 0.42);
INSERT INTO public.report_tests VALUES (31, 56, 62, 1, 0.38);
INSERT INTO public.report_tests VALUES (32, 57, 66, 0, 52.1);
INSERT INTO public.report_tests VALUES (32, 57, 66, 1, 49.5);
INSERT INTO public.report_tests VALUES (32, 57, 66, 2, 50.8);
INSERT INTO public.report_tests VALUES (32, 57, 66, 3, 51.6);
INSERT INTO public.report_tests VALUES (32, 57, 72, 0, 51.0);
INSERT INTO public.report_tests VALUES (32, 57, 73, 0, 2.312);
INSERT INTO public.report_tests VALUES (32, 57, 73, 1, 2.298);
INSERT INTO public.report_tests VALUES (32, 57, 73, 2, 2.325);
INSERT INTO public.report_tests VALUES (32, 57, 73, 3, 2.305);
INSERT INTO public.report_tests VALUES (32, 57, 74, 0, 0.47);
INSERT INTO public.report_tests VALUES (32, 57, 75, 0, 4);
INSERT INTO public.report_tests VALUES (32, 57, 76, 0, 93.9);
INSERT INTO public.report_tests VALUES (33, 58, 78, 0, 5015);
INSERT INTO public.report_tests VALUES (33, 58, 85, 0, 0);
INSERT INTO public.report_tests VALUES (33, 58, 86, 0, 250);
INSERT INTO public.report_tests VALUES (33, 58, 87, 0, 1750);
INSERT INTO public.report_tests VALUES (33, 58, 88, 0, 1500);
INSERT INTO public.report_tests VALUES (33, 58, 89, 0, 1010);
INSERT INTO public.report_tests VALUES (33, 58, 90, 0, 500);
INSERT INTO public.report_tests VALUES (33, 58, 91, 0, 100);
INSERT INTO public.report_tests VALUES (33, 58, 92, 0, 95);
INSERT INTO public.report_tests VALUES (33, 58, 93, 0, 60);
INSERT INTO public.report_tests VALUES (33, 58, 94, 0, 30);
INSERT INTO public.report_tests VALUES (33, 58, 95, 0, 10.1);
INSERT INTO public.report_tests VALUES (33, 58, 96, 0, 0.10);


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


--
-- Data for Name: spec_tests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.spec_tests VALUES (2, 1, 2, '[value] > 10', '> 10');
INSERT INTO public.spec_tests VALUES (2, 2, 1, '[value] < 1000', '< 1000');
INSERT INTO public.spec_tests VALUES (2, 3, 1, '[value] > 10 && [value] < 1000', '> 10 and < 1000');
INSERT INTO public.spec_tests VALUES (2, 4, 1, '[value] == 100', '== 100');
INSERT INTO public.spec_tests VALUES (1, 2, 2, '[value] > 10', '> 10');
INSERT INTO public.spec_tests VALUES (1, 1, 1, '[value] < 1000', '< 1000');
INSERT INTO public.spec_tests VALUES (1, 3, 1, '[value] == 100', '== 100');
INSERT INTO public.spec_tests VALUES (3, 1, 1, '[value] > 10', '> 10');
INSERT INTO public.spec_tests VALUES (3, 3, 1, '[value] < 1000', '< 1000');
INSERT INTO public.spec_tests VALUES (3, 4, 1, '[value] == 100', '== 100');
INSERT INTO public.spec_tests VALUES (11, 3, 2, '[value] > 100', '> 100');
INSERT INTO public.spec_tests VALUES (11, 4, 3, '[value] < 1000', '< 1000');
INSERT INTO public.spec_tests VALUES (11, 28, 1, '[value] <= 50 || [value] > 100', '<= 50 or > 100');
INSERT INTO public.spec_tests VALUES (11, 37, 1, '[value] > 100 && [value] <= 500', '> 100 and <= 500');
INSERT INTO public.spec_tests VALUES (11, 38, 1, '[value] == 2 || [value] == 3 // Item KB or Item KC', '''Item KB'' or ''Item KC''');
INSERT INTO public.spec_tests VALUES (16, 1, 1, '[value] < 1000', '< 1000');
INSERT INTO public.spec_tests VALUES (16, 2, 2, '[value] > 10', '> 10');
INSERT INTO public.spec_tests VALUES (16, 3, 1, '[value] == 100', '== 100');
INSERT INTO public.spec_tests VALUES (17, 3, 2, '[value] > 100', '> 100');
INSERT INTO public.spec_tests VALUES (17, 4, 3, '[value] < 1000', '< 1000');
INSERT INTO public.spec_tests VALUES (17, 28, 1, '[value] <= 50 || [value] > 100', '<= 50 or > 100');
INSERT INTO public.spec_tests VALUES (17, 37, 1, '[value] > 100 && [value] <= 500', '> 100 and <= 500');
INSERT INTO public.spec_tests VALUES (17, 38, 1, '[value] == 2 || [value] == 3 // Item KB or Item KC', '''Item KB'' or ''Item KC''');
INSERT INTO public.spec_tests VALUES (18, 51, 1, '[value] >= 40', '>= 40');
INSERT INTO public.spec_tests VALUES (18, 52, 1, '[value] >= 1.75 && [value] <= 2.10', '>= 1.75 and <= 2.10');
INSERT INTO public.spec_tests VALUES (19, 55, 1, '[value] <= 30', '<= 30');
INSERT INTO public.spec_tests VALUES (19, 56, 1, '[value] <= 5', '<= 5');
INSERT INTO public.spec_tests VALUES (19, 57, 1, '[value] >= 3 && [value] <= 20', '>= 3 and <= 20');
INSERT INTO public.spec_tests VALUES (20, 64, 1, '[value] <= 0.050', '<= 0.050');
INSERT INTO public.spec_tests VALUES (20, 63, 1, '[value] <= 0.50', '<= 0.50');
INSERT INTO public.spec_tests VALUES (20, 62, 1, '[value] <= 0.50', '<= 0.50');
INSERT INTO public.spec_tests VALUES (20, 65, 1, '[value] >= 3 && [value] <= 5', '>= 3 and <= 5');
INSERT INTO public.spec_tests VALUES (21, 66, 1, '[value] >= 45.0', '>= 45.0');
INSERT INTO public.spec_tests VALUES (21, 73, 1, '[value] >= 0', '>= 0');
INSERT INTO public.spec_tests VALUES (21, 75, 1, '[value] >= 3', '>= 3');
INSERT INTO public.spec_tests VALUES (21, 76, 1, '[value] >= 92.0 && [value] <= 97.0', '>= 92.0 and <= 97.0');
INSERT INTO public.spec_tests VALUES (21, 74, 1, '[value] <= 1.30', '<= 1.30');
INSERT INTO public.spec_tests VALUES (21, 72, 1, '[value] >= 50.0', '>= 50.0');
INSERT INTO public.spec_tests VALUES (22, 78, 1, '[value] >= 5000.0', '>= 5000.0');
INSERT INTO public.spec_tests VALUES (22, 91, 1, '[value] == 100', '== 100');
INSERT INTO public.spec_tests VALUES (22, 92, 1, '[value] >= 90 && [value] <= 100', '>= 90 and <= 100');
INSERT INTO public.spec_tests VALUES (22, 93, 1, '[value] >= 40 && [value] <= 65', '>= 40 and <= 65');
INSERT INTO public.spec_tests VALUES (22, 94, 1, '[value] >= 15 && [value] <= 35', '>= 15 and <= 35');
INSERT INTO public.spec_tests VALUES (22, 95, 1, '[value] >= 2.0 && [value] <= 12.0', '>= 2.0 and <= 12.0');
INSERT INTO public.spec_tests VALUES (22, 96, 1, '[value] <= 0.30', '<= 0.30');


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


--
-- Data for Name: tests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (67, 'Dry Mass', 'pca_A', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, true, true, 2, 10, '', false, 69, true, '2026-07-11 19:03:06.2863+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (68, 'Saturated Surface-Dry Mass', 'pca_B', 'Officia dignissimos tempora commodi', 2, true, true, 2, 10, '', false, 70, true, '2026-07-11 19:05:13.668253+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (69, 'Submerged Mass', 'pca_C', 'Excepturi beatae quibusdam', 2, true, true, 2, 10, '', false, 71, true, '2026-07-11 19:09:24.462621+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (73, 'Core Specific Gravity', 'pca_G_mb', 'Excepturi beatae quibusdam', 2, true, false, NULL, 10, '', true, 64, true, '2026-07-11 20:39:28.774076+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (40, 'Parameter GF', 'pgf', NULL, 3, true, true, NULL, NULL, NULL, false, 41, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (41, 'Test H', 'test_h', 'Description Test H', 3, false, false, 10, NULL, NULL, true, 29, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (42, 'Test LB', 'tlb', 'Description Test LB', 3, false, false, 2, 1, NULL, true, 32, false, '2025-12-27 21:25:52.613339+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (43, 'Test LBA', 'tlba', 'Description Test LBA', 3, true, false, 2, 2, NULL, true, 33, false, '2025-12-27 21:26:41.616588+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (44, 'Test ME', 'tme', 'Description Test ME', 4, false, false, 2, 3, NULL, false, 34, false, '2025-12-27 21:27:51.890718+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (45, 'Test MAE', 'tmae', 'Description Test MAE', 4, true, false, 2, 2, NULL, true, 35, false, '2025-12-27 21:29:25.300316+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (46, 'Diameter 1', 'mco_d1', 'First diameter measurement of cylindrical specimen', 2, false, true, 11, NULL, NULL, false, 44, true, '2026-07-04 23:47:20.474144+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (47, 'Diameter 2', 'mco_d2', 'Second diameter measurement of cylindrical specimen', 2, false, true, 11, NULL, NULL, false, 45, true, '2026-07-04 23:48:04.628515+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (48, 'Height 1', 'mco_h1', 'First height measurement of cylindrical specimen', 2, false, true, 11, NULL, NULL, false, 46, true, '2026-07-04 23:48:44.605356+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (49, 'Height 2', 'mco_h2', 'Second height measurement of cylindrical specimen', 2, false, true, 11, NULL, NULL, false, 47, true, '2026-07-04 23:49:24.318518+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (50, 'Maximum Load', 'mco_P', 'Value at failure', 2, false, true, 12, NULL, NULL, false, 48, true, '2026-07-06 03:27:42.807334+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (51, ' Compressive Strength', 'mco_sigma', 'Compressive strength is defined as the maximum force applied divided by the cross-sectional area.', 2, false, false, 13, 6, NULL, true, 42, true, '2026-07-06 03:30:35.730139+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (52, 'Aspect Ratio', 'mco_ldr', 'Length-to-Diameter ratio.', 2, false, false, NULL, 6, NULL, true, 43, true, '2026-07-06 04:44:58.706412+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (53, 'Aliquot Volume', 'tss_V', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, true, true, 3, NULL, '', false, 53, true, '2026-07-07 17:40:56.8302+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (54, 'Dry Residue Weight', 'tss_W', 'Consequuntur iusto optio impedit iusto nihil quia', 2, true, true, 14, NULL, '', false, 54, true, '2026-07-07 17:42:18.803509+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (55, 'Total Suspended Solids', 'tss_X', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, false, 15, 7, '', true, 49, true, '2026-07-07 17:54:28.497264+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (56, 'Relative Standard Deviation', 'tss_RSD', 'Officia dignissimos tempora commodi ', 2, false, false, 9, 7, '', true, 50, true, '2026-07-07 17:56:01.722304+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (57, 'Sample Size', 'tss_n', 'Sunt saepe veniam recusandae ex fuga id', 1, false, false, NULL, NULL, '', true, 51, true, '2026-07-07 17:58:54.090721+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (58, 'Normalized Value', 'tss_Xi', 'Excepturi beatae quibusdam', 2, true, true, 15, NULL, '', false, 52, true, '2026-07-07 18:10:17.482345+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (59, 'Tare Weight', 'lod_m0', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, true, true, 2, NULL, '', false, 59, true, '2026-07-09 15:25:02.623865+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (60, 'Wet + Bottle', 'lod_m1', 'Consequuntur iusto optio impedit iusto nihil quia', 2, true, true, 2, NULL, '', false, 60, true, '2026-07-09 15:26:46.785417+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (61, 'Dry + Bottle', 'lod_m2', 'Officia dignissimos tempora commodi ', 2, true, true, 2, NULL, '', false, 61, true, '2026-07-09 15:28:42.886268+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (62, 'Sample Moisture', 'lod_i', 'Excepturi beatae quibusdam', 2, true, false, 9, 8, '', true, 56, true, '2026-07-09 15:41:38.255198+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (63, 'Mean Moisture', 'lod_X', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, false, 9, 8, '', true, 55, true, '2026-07-09 15:45:58.044612+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (64, 'Standard Deviation', 'lod_s', 'Officia dignissimos tempora commodi ', 2, false, false, 9, NULL, '', true, 57, true, '2026-07-09 15:53:53.339483+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (65, 'Sample Count', 'lod_n', 'Sunt saepe veniam recusandae ex fuga id', 1, false, false, NULL, NULL, '', true, 58, true, '2026-07-09 15:57:47.072723+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (72, 'Average Pavement Thickness', 'pca_MH', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, false, 11, 9, '', true, 62, true, '2026-07-11 19:48:30.052621+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (66, 'Core Height', 'pca_H', 'Consequuntur iusto optio impedit iusto nihil quia', 2, true, false, 11, 9, '', true, 63, true, '2026-07-11 19:01:44.239687+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (74, 'Compaction Standard Deviation', 'pca_s_c', 'Excepturi beatae quibusdam', 2, false, false, 9, NULL, '', true, 67, true, '2026-07-11 21:11:04.522057+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (75, 'Core Sample Count', 'pca_n', 'Sunt saepe veniam recusandae ex fuga id', 1, false, false, NULL, NULL, '', true, 68, true, '2026-07-11 21:13:53.951992+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (76, 'Average Compaction', 'pca_MC', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, false, 9, 10, '', true, 66, true, '2026-07-11 21:51:30.902295+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (77, 'In-Place Compaction', 'pca_C_i', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, true, true, 9, 10, '', false, 65, true, '2026-07-11 21:54:52.724803+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (1, 'Test A', 'test_a', 'Description Test A', 2, false, false, 2, 1, 'ref A', true, 1, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (2, 'Test B', 'test_b', 'Description Test B', 2, false, false, 2, 2, 'ref B', true, 2, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (3, 'Test C', 'test_c', 'Description Test C', 2, false, false, 2, 1, 'ref C', true, 3, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (4, 'Test D', 'test_d', 'Description Test D', 2, false, false, 2, 2, 'ref D', true, 4, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (5, 'Test E', 'test_e', 'Description Test E', 2, false, false, 2, 3, 'ref E', false, 5, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (6, 'Parameter AA', 'param_aa', 'Description Parameter AA', 2, false, true, 2, 1, NULL, false, 6, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (7, 'Parameter AB', 'param_ab', 'Description Parameter AB', 2, false, true, 2, 1, NULL, false, 7, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (8, 'Parameter AC', 'param_ac', 'Description Parameter AC', 4, false, true, 2, 1, NULL, false, 8, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (9, 'Parameter AD', 'param_ad', 'Description Parameter AD', 2, false, true, 2, 1, NULL, false, 9, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (10, 'Parameter AE', 'param_ae', 'Description Parameter AE', 3, false, true, 2, 1, NULL, false, 10, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (11, 'Parameter AF', 'param_af', 'Description Parameter AF', 2, false, true, 2, 1, NULL, false, 11, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (12, 'Parameter BA', 'param_ba', 'Description Parameter BA', 2, false, true, 2, 2, NULL, false, 12, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (13, 'Parameter BB', 'param_bb', 'Description Parameter BB', 4, false, true, 2, 2, NULL, false, 13, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (14, 'Parameter BC', 'param_bc', 'Description Parameter BC', 2, false, true, 2, 2, NULL, false, 14, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (15, 'Parameter BD', 'pbd', 'Description Parameter BD', 2, false, true, 2, 2, NULL, false, 15, false, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (16, 'Parameter CA', 'param_ca', 'Description Parameter CA', 2, false, true, 2, 1, NULL, false, 16, false, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (17, 'Parameter CB', 'param_cb', 'Description Parameter CB', 2, false, true, 2, 1, NULL, false, 17, false, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (18, 'Parameter CC', 'param_cc', 'Description Parameter CC', 2, false, true, 2, 1, NULL, false, 18, false, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (19, 'Parameter CD', 'param_cd', 'Description Parameter CD', 2, false, true, 2, 1, NULL, false, 19, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (20, 'Parameter DA', 'param_da', 'Description Parameter DA', 2, false, true, 2, 2, NULL, false, 20, false, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (21, 'Parameter DB', 'param_db', 'Description Parameter DB', 2, false, true, 2, 2, NULL, false, 21, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (22, 'Parameter DC', 'param_dc', 'Description Parameter DC', 2, false, true, 2, 2, NULL, false, 22, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (24, 'Parameter EB', 'param_eb', 'Description Parameter EB', 2, false, true, 2, 3, NULL, false, 24, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (25, 'Parameter EC', 'param_ec', 'Description Parameter EC', 2, false, true, 2, 3, NULL, false, 25, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (26, 'Parameter FA', 'param_fa', 'Description Parameter FA', 2, false, true, 2, 2, NULL, false, 26, false, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (27, 'Parameter FB', 'param_fb', 'Description Parameter FB', 2, false, true, 2, 2, NULL, false, 27, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (28, 'Test G', 'test_g', 'Description Test G', 2, false, false, 2, 1, NULL, true, 28, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (23, 'Parameter EA', 'param_ea', 'Description Parameter EA', 2, false, true, 2, 3, NULL, false, 23, false, '2025-12-13 18:17:42.218999+02', true, '2025-12-13 18:17:42.218999+02', NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (29, 'Parameter GA', 'pga', NULL, 2, false, true, NULL, NULL, NULL, false, 36, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (30, 'Parameter GB', 'pgb', NULL, 2, true, true, NULL, NULL, NULL, false, 37, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (31, 'Parameter GC', 'pgc', NULL, 2, false, true, NULL, NULL, NULL, false, 38, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (36, 'Parameter GD', 'pgd', NULL, 2, true, true, NULL, NULL, NULL, false, 39, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (37, 'Test J', 'test_j', NULL, 2, true, false, NULL, NULL, NULL, true, 30, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (38, 'Test K', 'test_k', NULL, 4, false, false, NULL, NULL, NULL, true, 31, true, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (39, 'Parameter GE', 'pge', NULL, 4, true, true, NULL, NULL, NULL, false, 40, false, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (78, 'Initial Dry Sample Weight', 'saa_M_initial', 'Consequuntur iusto optio impedit iusto nihil quia', 2, false, false, 2, 12, '', true, 72, true, '2026-07-17 12:57:37.57851+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (79, 'Cumulative Weight 1 inch', 'saa_cw_1_inch', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, true, 2, 12, '', false, 73, true, '2026-07-17 13:22:09.84019+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (80, 'Cumulative Weight 3/4 inch', 'saa_cw_3_4_inch', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, true, 2, 12, '', false, 74, true, '2026-07-17 13:23:10.505012+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (81, 'Cumulative Weight No. 4', 'saa_cw_no_4', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, true, 2, 12, '', false, 75, true, '2026-07-17 13:24:47.212141+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (82, 'Cumulative Weight No. 40', 'saa_cw_no_40', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, true, 2, 12, '', false, 76, true, '2026-07-17 13:26:36.087361+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (83, 'Cumulative Weight No. 200', 'saa_cw_no_200', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, true, 2, 12, '', false, 77, true, '2026-07-17 13:27:37.566801+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (84, 'Cumulative Weight Pan', 'saa_cw_pan', 'Occaecati iusto explicabo excepturi beatae quibusdam', 2, false, true, 2, 12, '', false, 78, true, '2026-07-17 13:30:46.876739+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (85, 'Individual Mass 1 inch', 'saa_Mi_1_inch', 'Officia dignissimos tempora commodi ', 2, false, false, 2, 12, '', false, 79, true, '2026-07-17 13:34:03.488872+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (86, 'Individual Mass 3/4 inch', 'saa_Mi_3_4_inch', 'Officia dignissimos tempora commodi ', 2, false, false, 2, 12, '', false, 80, true, '2026-07-17 13:34:55.375851+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (87, 'Individual Mass No. 4', 'saa_Mi_no_4', 'Officia dignissimos tempora commodi', 2, false, false, 2, 12, '', false, 81, true, '2026-07-17 13:35:39.91469+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (88, 'Individual Mass No. 40', 'saa_Mi_no_40', 'Officia dignissimos tempora commodi ', 2, false, false, 2, 12, '', false, 82, true, '2026-07-17 13:37:37.10508+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (89, 'Individual Mass No. 200', 'saa_Mi_no_200', 'Officia dignissimos tempora commodi', 2, false, false, 2, 12, '', false, 83, true, '2026-07-17 13:39:50.594124+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (90, 'Individual Mass Pan', 'saa_Mi_pan', 'Officia dignissimos tempora commodi', 2, false, false, 2, 12, '', false, 84, true, '2026-07-17 13:40:52.598601+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (91, 'Percent Passing 1 inch', 'saa_PPi_1_inch', 'Excepturi beatae quibusdam', 2, false, false, 9, 12, '', true, 85, true, '2026-07-17 13:44:56.420411+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (92, 'Percent Passing 3/4 inch', 'saa_PPi_3_4_inch', 'Excepturi beatae quibusdam', 2, false, false, 9, 12, '', true, 86, true, '2026-07-17 13:52:31.975998+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (93, 'Percent Passing No. 4', 'saa_PPi_no_4', 'Excepturi beatae quibusdam', 2, false, false, 9, 12, '', true, 87, true, '2026-07-17 14:03:55.093966+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (94, 'Percent Passing No. 40', 'saa_PPi_no_40', 'Excepturi beatae quibusdam', 2, false, false, 9, 12, '', true, 88, true, '2026-07-17 14:05:31.566425+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (95, 'Percent Passing No. 200', 'saa_PPi_no_200', 'Excepturi beatae quibusdam', 2, false, false, 9, 12, '', true, 89, true, '2026-07-17 14:07:32.07714+03', false, NULL, NULL);
INSERT INTO public.tests OVERRIDING SYSTEM VALUE VALUES (96, 'Sieve Loss', 'saa_loss', 'Excepturi beatae quibusdam', 2, false, false, 9, 12, '', true, 90, true, '2026-07-17 14:15:54.980197+03', false, NULL, NULL);


--
-- Data for Name: units; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (1, 'kg', 'Weight', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (2, 'g', 'Weight', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (4, 'mL', 'Volume', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (5, 'pcs', 'Count', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (6, 'box', 'Count', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (7, 'pack', 'Count', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (8, 'Unit', 'Count', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (9, '%', 'Percentage', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (10, 'n.a.', 'Not Applicable', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (12, 'kN', 'KiloNewtons', '2026-07-04 23:33:34.00052+03');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (11, 'mm', 'Millimeters', '2026-07-04 23:31:32.732861+03');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (13, 'MPa', 'Megapascals', '2026-07-04 23:36:03.197749+03');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (3, 'L', 'Liters (Volume)', '2025-12-13 18:17:42.218999+02');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (14, 'mg', 'Milligrams', '2026-07-07 17:33:10.295159+03');
INSERT INTO public.units OVERRIDING SYSTEM VALUE VALUES (15, 'mg/L', 'Concentration', '2026-07-07 17:45:38.624869+03');


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (2, 'bob', 'BO', 'bob@qc.lab', 'Bob', 'Johnson', false, false, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (3, 'charlie', 'CH', 'charlie@qc.lab', 'Charlie', 'Brown', false, false, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (4, 'david', 'DV', 'david@qc.lab', 'David', 'Miller', false, false, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', true, '2026-01-23 22:42:12.337979+02', 'Some explanations ...');
INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (5, 'eve', 'EV', 'eve@qc.lab', 'Eve', 'Adams', false, true, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (6, 'frank', 'FR', 'frank@qc.lab', 'Frank', 'Wright', false, true, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (7, 'grace', 'GR', 'grace@qc.lab', 'Grace', 'Davis', false, false, true, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', NULL, NULL, NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (8, 'heidi', 'HE', 'heidi@qc.lab', 'Heidi', 'Turner', true, false, false, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', '646582b1-660d-4823-9c1e-3528d41a2d1b', '2025-12-13 18:17:42.218999+02', NULL, NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);
INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (1, 'alice', 'AL', 'alice@qc.lab', 'Alice', 'Smith', true, true, true, '$2b$12$2r5/qy12nsTXwZCtEAO/8.G1GimD5JzdgCjMqvtUlRGYHQldOcaNC', '204b3731437142bd9e914c3accc943be', false, '2025-12-13 18:17:42.218999+02', '4408a117-9b39-4a95-a5ce-a16a9885cf48', '2026-08-25 20:24:00.855627+03', '2026-08-26 08:24:00.855746+03', NULL, '2025-12-13 18:17:42.218999+02', false, NULL, NULL);


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

SELECT pg_catalog.setval('public.audit_logs_id_seq', 1, false);


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categories_id_seq', 7, true);


--
-- Name: certification_headers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.certification_headers_id_seq', 13, true);


--
-- Name: electronic_signatures_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.electronic_signatures_id_seq', 1, false);


--
-- Name: equipment_calibrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.equipment_calibrations_id_seq', 60, true);


--
-- Name: equipment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.equipment_id_seq', 15, true);


--
-- Name: form_condition_evals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.form_condition_evals_id_seq', 110, true);


--
-- Name: form_evals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.form_evals_id_seq', 20, true);


--
-- Name: form_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.form_groups_id_seq', 13, true);


--
-- Name: forms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.forms_id_seq', 14, true);


--
-- Name: materials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.materials_id_seq', 26, true);


--
-- Name: measurement_details_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.measurement_details_id_seq', 58, true);


--
-- Name: norms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.norms_id_seq', 12, true);


--
-- Name: receptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.receptions_id_seq', 76, true);


--
-- Name: receptions_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.receptions_id_seq1', 27, true);


--
-- Name: reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reports_id_seq', 33, true);


--
-- Name: spec_headers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.spec_headers_id_seq', 22, true);


--
-- Name: spec_test_evals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.spec_test_evals_id_seq', 303, true);


--
-- Name: tests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tests_id_seq', 101, true);


--
-- Name: units_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.units_id_seq', 15, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 9, false);


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
-- Name: tests tests_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_code_key UNIQUE (code);


--
-- Name: tests tests_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_name_key UNIQUE (name);


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
    ADD CONSTRAINT category_tests_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: category_tests category_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.category_tests
    ADD CONSTRAINT category_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: certificate_tests certificate_tests_certificates_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_certificates_id_fkey FOREIGN KEY (certificate_id) REFERENCES public.certificates(id);


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
    ADD CONSTRAINT equipment_calibrations_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipments(id);


--
-- Name: form_condition_evals form_condition_evals_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_condition_evals
    ADD CONSTRAINT form_condition_evals_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id);


--
-- Name: form_condition_evals form_condition_evals_form_id_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_condition_evals
    ADD CONSTRAINT form_condition_evals_form_id_test_id_fkey FOREIGN KEY (form_id, test_id) REFERENCES public.form_params(form_id, test_id);


--
-- Name: form_condition_evals form_condition_evals_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_condition_evals
    ADD CONSTRAINT form_condition_evals_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: form_eval_params form_eval_params_eval_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_eval_id_fkey FOREIGN KEY (eval_id) REFERENCES public.form_evals(id);


--
-- Name: form_eval_params form_eval_params_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id);


--
-- Name: form_eval_params form_eval_params_form_id_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_form_id_test_id_fkey FOREIGN KEY (form_id, test_id) REFERENCES public.form_params(form_id, test_id);


--
-- Name: form_eval_params form_eval_params_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: form_evals form_evals_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_evals
    ADD CONSTRAINT form_evals_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id);


--
-- Name: form_params form_params_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_params
    ADD CONSTRAINT form_params_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id);


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
    ADD CONSTRAINT material_tests_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


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
    ADD CONSTRAINT measurement_equipments_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id);


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
    ADD CONSTRAINT measurement_params_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id);


--
-- Name: measurement_params measurement_params_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: measurement_tests measurement_tests_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_tests
    ADD CONSTRAINT measurement_tests_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id);


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
    ADD CONSTRAINT report_tests_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(id);


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
-- Name: spec_test_evals spec_test_evals_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spec_test_evals
    ADD CONSTRAINT spec_test_evals_spec_id_fkey FOREIGN KEY (spec_id) REFERENCES public.specs(id);


--
-- Name: spec_test_evals spec_test_evals_spec_id_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spec_test_evals
    ADD CONSTRAINT spec_test_evals_spec_id_test_id_fkey FOREIGN KEY (spec_id, test_id) REFERENCES public.spec_tests(spec_id, test_id);


--
-- Name: spec_test_evals spec_test_evals_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spec_test_evals
    ADD CONSTRAINT spec_test_evals_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: spec_tests spec_tests_specs_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spec_tests
    ADD CONSTRAINT spec_tests_specs_id_fkey FOREIGN KEY (spec_id) REFERENCES public.specs(id);


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
    ADD CONSTRAINT test_enums_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: test_equipments test_equipments_equipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_equipments
    ADD CONSTRAINT test_equipments_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipments(id) NOT VALID;


--
-- Name: test_equipments test_equipments_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_equipments
    ADD CONSTRAINT test_equipments_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) NOT VALID;


--
-- Name: tests tests_norm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_norm_id_fkey FOREIGN KEY (norm_id) REFERENCES public.norms(id);


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

