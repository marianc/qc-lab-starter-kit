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

SET default_tablespace = '';

SET default_table_access_method = heap;

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
-- Name: category_tests category_tests_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.category_tests
    ADD CONSTRAINT category_tests_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) NOT VALID;


--
-- Name: category_tests category_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.category_tests
    ADD CONSTRAINT category_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) NOT VALID;


--
-- Name: certificate_tests certificate_tests_certificates_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_certificates_id_fkey FOREIGN KEY (certificate_id) REFERENCES public.certificates(id) NOT VALID;


--
-- Name: certificate_tests certificate_tests_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id) NOT VALID;


--
-- Name: certificate_tests certificate_tests_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(id) NOT VALID;


--
-- Name: certificate_tests certificate_tests_report_id_measurement_id_test_id_idx_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_report_id_measurement_id_test_id_idx_fkey FOREIGN KEY (report_id, measurement_id, test_id, idx) REFERENCES public.report_tests(report_id, measurement_id, test_id, idx) NOT VALID;


--
-- Name: certificate_tests certificate_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificate_tests
    ADD CONSTRAINT certificate_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) NOT VALID;


--
-- Name: certificates certificates_certificate_replaced_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_certificate_replaced_id_fkey FOREIGN KEY (certificate_replaced_id) REFERENCES public.certificates(id) NOT VALID;


--
-- Name: certificates certificates_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_control_code_id_fkey FOREIGN KEY (control_code_id) REFERENCES public.control_codes(id) NOT VALID;


--
-- Name: certificates certificates_specs_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_specs_id_fkey FOREIGN KEY (spec_id) REFERENCES public.specs(id) NOT VALID;


--
-- Name: certificates certificates_user_cancelled_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_user_cancelled_id_fkey FOREIGN KEY (user_cancelled_id) REFERENCES public.users(id) NOT VALID;


--
-- Name: certificates certificates_user_submitted_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_user_submitted_id_fkey FOREIGN KEY (user_submitted_id) REFERENCES public.users(id) NOT VALID;


--
-- Name: control_codes control_codes_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.control_codes
    ADD CONSTRAINT control_codes_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id) NOT VALID;


--
-- Name: form_condition_evals form_condition_evals_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_condition_evals
    ADD CONSTRAINT form_condition_evals_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id) NOT VALID;


--
-- Name: form_condition_evals form_condition_evals_form_id_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_condition_evals
    ADD CONSTRAINT form_condition_evals_form_id_test_id_fkey FOREIGN KEY (form_id, test_id) REFERENCES public.form_params(form_id, test_id) NOT VALID;


--
-- Name: form_condition_evals form_condition_evals_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_condition_evals
    ADD CONSTRAINT form_condition_evals_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) NOT VALID;


--
-- Name: form_eval_params form_eval_params_eval_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_eval_id_fkey FOREIGN KEY (eval_id) REFERENCES public.form_evals(id) NOT VALID;


--
-- Name: form_eval_params form_eval_params_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id) NOT VALID;


--
-- Name: form_eval_params form_eval_params_form_id_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_form_id_test_id_fkey FOREIGN KEY (form_id, test_id) REFERENCES public.form_params(form_id, test_id) NOT VALID;


--
-- Name: form_eval_params form_eval_params_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_eval_params
    ADD CONSTRAINT form_eval_params_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) NOT VALID;


--
-- Name: form_evals form_evals_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_evals
    ADD CONSTRAINT form_evals_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id);


--
-- Name: form_params form_params_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_params
    ADD CONSTRAINT form_params_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id) NOT VALID;


--
-- Name: form_params form_params_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.form_params
    ADD CONSTRAINT form_params_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) NOT VALID;


--
-- Name: forms forms_form_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forms
    ADD CONSTRAINT forms_form_group_id_fkey FOREIGN KEY (form_group_id) REFERENCES public.form_groups(id) NOT VALID;


--
-- Name: forms forms_user_canceled_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forms
    ADD CONSTRAINT forms_user_canceled_id_fkey FOREIGN KEY (user_cancelled_id) REFERENCES public.users(id) NOT VALID;


--
-- Name: forms forms_user_submitted_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forms
    ADD CONSTRAINT forms_user_submitted_id_fkey FOREIGN KEY (user_submitted_id) REFERENCES public.users(id) NOT VALID;


--
-- Name: forms forms_user_validated_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forms
    ADD CONSTRAINT forms_user_validated_id_fkey FOREIGN KEY (user_validated_id) REFERENCES public.users(id) NOT VALID;


--
-- Name: material_tests material_tests_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_tests
    ADD CONSTRAINT material_tests_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id) NOT VALID;


--
-- Name: material_tests material_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_tests
    ADD CONSTRAINT material_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) NOT VALID;


--
-- Name: materials materials_norm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_norm_id_fkey FOREIGN KEY (norm_id) REFERENCES public.norms(id) NOT VALID;


--
-- Name: measurement_params measurement_params_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id) NOT VALID;


--
-- Name: measurement_params measurement_params_form_id_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_form_id_test_id_fkey FOREIGN KEY (form_id, test_id) REFERENCES public.form_params(form_id, test_id) NOT VALID;


--
-- Name: measurement_params measurement_params_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id) NOT VALID;


--
-- Name: measurement_params measurement_params_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_params
    ADD CONSTRAINT measurement_params_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) NOT VALID;


--
-- Name: measurement_tests measurement_tests_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_tests
    ADD CONSTRAINT measurement_tests_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id) NOT VALID;


--
-- Name: measurement_tests measurement_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_tests
    ADD CONSTRAINT measurement_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) NOT VALID;


--
-- Name: measurements measurements_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(id) NOT VALID;


--
-- Name: measurements measurements_reception_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_reception_id_fkey FOREIGN KEY (reception_id) REFERENCES public.receptions(id) NOT VALID;


--
-- Name: measurements measurements_user_reported_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_user_reported_id_fkey FOREIGN KEY (user_reported_id) REFERENCES public.users(id) NOT VALID;


--
-- Name: measurements measurements_user_update_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_user_update_id_fkey FOREIGN KEY (user_update_id) REFERENCES public.users(id) NOT VALID;


--
-- Name: reception_tests reception_tests_reception_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reception_tests
    ADD CONSTRAINT reception_tests_reception_id_fkey FOREIGN KEY (reception_id) REFERENCES public.receptions(id) NOT VALID;


--
-- Name: reception_tests reception_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reception_tests
    ADD CONSTRAINT reception_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) NOT VALID;


--
-- Name: receptions receptions_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) NOT VALID;


--
-- Name: receptions receptions_control_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_control_code_id_fkey FOREIGN KEY (control_code_id) REFERENCES public.control_codes(id) NOT VALID;


--
-- Name: receptions receptions_reception_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_reception_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.reception_types(id) NOT VALID;


--
-- Name: receptions receptions_user_received_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_user_received_id_fkey FOREIGN KEY (user_received_id) REFERENCES public.users(id) NOT VALID;


--
-- Name: receptions receptions_user_rejected_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_user_rejected_id_fkey FOREIGN KEY (user_rejected_id) REFERENCES public.users(id) NOT VALID;


--
-- Name: receptions receptions_user_submitted_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_user_submitted_id_fkey FOREIGN KEY (user_submitted_id) REFERENCES public.users(id) NOT VALID;


--
-- Name: report_tests report_tests_measurement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_tests
    ADD CONSTRAINT report_tests_measurement_id_fkey FOREIGN KEY (measurement_id) REFERENCES public.measurements(id) NOT VALID;


--
-- Name: report_tests report_tests_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_tests
    ADD CONSTRAINT report_tests_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(id) NOT VALID;


--
-- Name: report_tests report_tests_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_tests
    ADD CONSTRAINT report_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) NOT VALID;


--
-- Name: reports reports_reception_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_reception_id_fkey FOREIGN KEY (reception_id) REFERENCES public.receptions(id) NOT VALID;


--
-- Name: reports reports_report_replaced_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_report_replaced_id_fkey FOREIGN KEY (report_replaced_id) REFERENCES public.reports(id) NOT VALID;


--
-- Name: reports reports_user_cancelled_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_user_cancelled_id_fkey FOREIGN KEY (user_cancelled_id) REFERENCES public.users(id) NOT VALID;


--
-- Name: reports reports_user_submitted_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_user_submitted_id_fkey FOREIGN KEY (user_submitted_id) REFERENCES public.users(id) NOT VALID;


--
-- Name: spec_test_evals spec_test_evals_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spec_test_evals
    ADD CONSTRAINT spec_test_evals_spec_id_fkey FOREIGN KEY (spec_id) REFERENCES public.specs(id) NOT VALID;


--
-- Name: spec_test_evals spec_test_evals_spec_id_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spec_test_evals
    ADD CONSTRAINT spec_test_evals_spec_id_test_id_fkey FOREIGN KEY (spec_id, test_id) REFERENCES public.spec_tests(spec_id, test_id) NOT VALID;


--
-- Name: spec_test_evals spec_test_evals_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spec_test_evals
    ADD CONSTRAINT spec_test_evals_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) NOT VALID;


--
-- Name: spec_tests spec_tests_specs_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spec_tests
    ADD CONSTRAINT spec_tests_specs_id_fkey FOREIGN KEY (spec_id) REFERENCES public.specs(id) NOT VALID;


--
-- Name: spec_tests spec_tests_tests_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spec_tests
    ADD CONSTRAINT spec_tests_tests_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) NOT VALID;


--
-- Name: specs specs_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specs
    ADD CONSTRAINT specs_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id) NOT VALID;


--
-- Name: specs specs_spec_replaced_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specs
    ADD CONSTRAINT specs_spec_replaced_id_fkey FOREIGN KEY (spec_replaced_id) REFERENCES public.specs(id) NOT VALID;


--
-- Name: specs specs_user_cancelled_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specs
    ADD CONSTRAINT specs_user_cancelled_id_fkey FOREIGN KEY (user_cancelled_id) REFERENCES public.users(id) NOT VALID;


--
-- Name: specs specs_user_submitted_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specs
    ADD CONSTRAINT specs_user_submitted_id_fkey FOREIGN KEY (user_submitted_id) REFERENCES public.users(id) NOT VALID;


--
-- Name: test_enums test_enums_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_enums
    ADD CONSTRAINT test_enums_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id);


--
-- Name: tests tests_norm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_norm_id_fkey FOREIGN KEY (norm_id) REFERENCES public.norms(id) NOT VALID;


--
-- Name: tests tests_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id) NOT VALID;


--
-- Name: tests tests_value_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_value_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.value_types(id) NOT VALID;


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

