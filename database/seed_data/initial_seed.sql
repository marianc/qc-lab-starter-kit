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

