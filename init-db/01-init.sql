--
-- PostgreSQL database dump
--

\restrict sZmYx8MXSK6kk7oRdSnseMI1e96cKJckzLpHmhDNY3fRVYHq279OkEKwMlFzHie

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: sync_production_line_text(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sync_production_line_text() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    bm_text varchar(100);
    fg_text varchar(100);
BEGIN
    IF NEW.bm_production_line_code IS NOT NULL THEN
        SELECT canonical_line_text INTO bm_text
        FROM production_lines WHERE production_line_code = NEW.bm_production_line_code;
        IF bm_text IS NOT NULL THEN
            NEW.bm_production_line := bm_text;
        END IF;
    END IF;

    IF NEW.fg_production_line_code IS NOT NULL THEN
        SELECT canonical_line_text INTO fg_text
        FROM production_lines WHERE production_line_code = NEW.fg_production_line_code;
        IF fg_text IS NOT NULL THEN
            NEW.fg_production_line := fg_text;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.sync_production_line_text() OWNER TO postgres;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: activities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activities (
    id integer NOT NULL,
    inventory_id character varying(50) NOT NULL,
    type character varying(20),
    item_id text,
    activity_name text NOT NULL,
    class character varying(10),
    class_1 character varying(10),
    pax integer,
    machine integer,
    time_min double precision,
    sort_order integer,
    run_time double precision,
    labor_min double precision,
    mc_min double precision,
    dl_units double precision,
    dl double precision,
    voh double precision,
    foh double precision
);


ALTER TABLE public.activities OWNER TO postgres;

--
-- Name: activities_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.activities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.activities_id_seq OWNER TO postgres;

--
-- Name: activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.activities_id_seq OWNED BY public.activities.id;


--
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity_logs (
    id bigint NOT NULL,
    logged_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id integer,
    username character varying(50) NOT NULL,
    user_role character varying(20) NOT NULL,
    action character varying(80) NOT NULL,
    description text NOT NULL,
    target_type character varying(40),
    target_id character varying(100),
    ip_address character varying(45),
    extra jsonb
);


ALTER TABLE public.activity_logs OWNER TO postgres;

--
-- Name: TABLE activity_logs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.activity_logs IS 'Human-readable audit trail. Rows older than 90 days are purged automatically by the /api/logs/cleanup endpoint or a scheduled job.';


--
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.activity_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.activity_logs_id_seq OWNER TO postgres;

--
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.activity_logs_id_seq OWNED BY public.activity_logs.id;


--
-- Name: line_activities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.line_activities (
    id integer NOT NULL,
    production_line_code character varying(20) NOT NULL,
    activity_name text NOT NULL,
    sort_order integer NOT NULL,
    stage character varying(10)
);


ALTER TABLE public.line_activities OWNER TO postgres;

--
-- Name: line_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.line_activities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.line_activities_id_seq OWNER TO postgres;

--
-- Name: line_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.line_activities_id_seq OWNED BY public.line_activities.id;


--
-- Name: pending_approvals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pending_approvals (
    id integer NOT NULL,
    inventory_id character varying(50) NOT NULL,
    action character varying(10) NOT NULL,
    requested_by character varying(50) NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    payload jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    resolved_at timestamp with time zone,
    resolved_by character varying(50)
);


ALTER TABLE public.pending_approvals OWNER TO postgres;

--
-- Name: pending_approvals_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pending_approvals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pending_approvals_id_seq OWNER TO postgres;

--
-- Name: pending_approvals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pending_approvals_id_seq OWNED BY public.pending_approvals.id;


--
-- Name: product_revisions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_revisions (
    id integer NOT NULL,
    inventory_id character varying(50) NOT NULL,
    revision character varying(10) NOT NULL,
    snapshot jsonb NOT NULL,
    archived_by character varying(50),
    archived_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.product_revisions OWNER TO postgres;

--
-- Name: product_revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_revisions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_revisions_id_seq OWNER TO postgres;

--
-- Name: product_revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_revisions_id_seq OWNED BY public.product_revisions.id;


--
-- Name: production_lines; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.production_lines (
    production_line_code character varying(20) NOT NULL,
    production_line_name text NOT NULL,
    canonical_line_text character varying(100)
);


ALTER TABLE public.production_lines OWNER TO postgres;

--
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products (
    inventory_id character varying(50) NOT NULL,
    revision_descr text,
    revision character varying(10),
    notes text,
    bm_production_line text,
    bm_production_line_code character varying(20),
    fg_production_line text,
    fg_production_line_code character varying(20),
    product_type character varying(50),
    quantity double precision,
    total_run_time double precision,
    total_labor_min double precision,
    total_mc_min double precision,
    total_dl_units double precision,
    total_dl double precision,
    total_voh double precision,
    total_foh double precision,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.products OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(50) NOT NULL,
    password_hash text NOT NULL,
    role character varying(20) DEFAULT 'user'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT valid_role CHECK (((role)::text = ANY ((ARRAY['user'::character varying, 'superuser'::character varying, 'admin'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: activities id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities ALTER COLUMN id SET DEFAULT nextval('public.activities_id_seq'::regclass);


--
-- Name: activity_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs ALTER COLUMN id SET DEFAULT nextval('public.activity_logs_id_seq'::regclass);


--
-- Name: line_activities id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.line_activities ALTER COLUMN id SET DEFAULT nextval('public.line_activities_id_seq'::regclass);


--
-- Name: pending_approvals id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_approvals ALTER COLUMN id SET DEFAULT nextval('public.pending_approvals_id_seq'::regclass);


--
-- Name: product_revisions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_revisions ALTER COLUMN id SET DEFAULT nextval('public.product_revisions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: activities; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.activities (id, inventory_id, type, item_id, activity_name, class, class_1, pax, machine, time_min, sort_order, run_time, labor_min, mc_min, dl_units, dl, voh, foh) FROM stdin;
1	1AF2202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2	1AF2202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
3	1AF2202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
4	1AF2202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
5	1AF2202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
6	1AF29233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
7	1AF29233	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
8	1AF29233	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
9	1AF29233	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
10	1AF29233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
11	1APC2009	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
12	1APC2009	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
13	1APC2009	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
14	1APC2010	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
15	1APC2010	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
16	1APC2010	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
17	1APC2012	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
18	1APC2012	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
19	1APC2012	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
20	1APC2016	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
21	1APC2016	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
22	1APC2016	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
23	1APC2019	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
24	1APC2019	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
25	1APC2019	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
26	1APU5A5I04	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
27	1APU5A5I04	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
28	1APU5A5I04	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
29	1APU5A5I04	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
30	1APU5A5I04	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
31	1APU5A5I04	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
32	1APU5A5I04	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
33	1BBA6A1I01	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
34	1BBA6A1I01	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
35	1BBA6A1I01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
36	1BBI9B14	Labor	L04B CODING	CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
37	1BBI9B14	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
38	1BBI9B14	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
39	1BBT3A9A01	Labor	L02 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
40	1BBT3A9A01	Labor	L02 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
41	1BCD4123	Labor	L14 FILLING	FILLING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
42	1BCD4123	Labor	L14 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
43	1BCR5A2Q01	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
44	1BCR5A2Q01	Labor	L12 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
45	1BCR5A2Q01	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
46	1BGR612J	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
47	1BGR612J	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
48	1BGR612J	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
49	1BGR612J	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
50	1BGR612J	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
51	1BSC9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
52	1BSC9229	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
53	1BSC9229	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
54	1BSC9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
55	1BWW434L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
56	1BWW434L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
57	1BWW434L	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
58	1BWW434L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
59	1BWW612J	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
60	1BWW612J	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
61	1BWW612J	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
62	1CB1304W	Labor	L10 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
63	1CB1304W	Labor	L10 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
64	1CB1304W	Labor	L10 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
65	1CB3325B	Labor	L02 FILLING	FILLING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
66	1CB3325B	Labor	L02 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
67	1CB43260	Labor	L02 FILLING	FILLING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
68	1CB43260	Labor	L02 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
69	1CB5325B	Labor	L02 FILLING	FILLING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
70	1CB5325B	Labor	L02 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
71	1CB6325B	Labor	L02 FILLING	FILLING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
72	1CB6325B	Labor	L02 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
73	1CBE1A2H01	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
74	1CBE1A2H01	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
75	1CBE1A2H01	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
76	1CEC2009	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
77	1CEC2009	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
78	1CEC2009	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
79	1CEC2010	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
80	1CEC2010	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
81	1CEC2010	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
82	1CEC2012	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
83	1CEC2012	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
84	1CEC2012	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
85	1CHV1A5A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
86	1CHV1A5A01	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
87	1CHV1A5A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
88	1CLC2009	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
89	1CLC2009	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
90	1CLC2009	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
91	1CLC2010	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
92	1CLC2010	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
93	1CLC2010	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
94	1CLV1A5A01	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
95	1CLV1A5A01	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
96	1CLV1A5A01	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
97	1COD1A1A01	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
98	1COD1A1A01	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
99	1COD1A1A01	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
100	1CTA610N	Labor	L13 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
101	1CTA610N	Labor	L13 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
102	1DSC2009	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
103	1DSC2009	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
104	1DSC2009	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
105	1DSC2010	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
106	1DSC2010	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
107	1DSC2010	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
108	1E2M2029	Labor	L04B CODING	CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
109	1E2M2029	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
110	1E2M2029	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
111	1E2M2033	Labor	L04B CODING	CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
112	1E2M2033	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
113	1E2M2033	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
114	1E2M2036	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
115	1E2M2036	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
116	1E2M2036	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
117	1E2M204Q	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
118	1E2M204Q	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
119	1E2M204Q	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
120	1E2M5843	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
121	1E2M5843	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
122	1E2M5843	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
123	1E3P5843	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
124	1E3P5843	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
125	1E3P5843	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
126	1E3P5846	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
127	1E3P5846	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
128	1E3P5846	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
129	1E3P929G	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
130	1E3P929G	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
131	1E3P929G	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
132	1E3P929H	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
133	1E3P929H	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
134	1E3P929H	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
135	1EFC202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
136	1EFC202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
137	1EFC202L	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
138	1EFC202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
139	1EFG2009	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
140	1EFG2009	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
141	1EFG2009	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
142	1EFG2009	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
143	1EFG2009	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
144	1EFG2009	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
145	1ELB202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
146	1ELB202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
147	1ELB202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
148	1ELB202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
149	1ELB202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
150	1EMW202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
151	1EMW202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
152	1EMW202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
153	1EMW202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
154	1EMW202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
155	1ENC2009	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
156	1ENC2009	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
157	1ENC2009	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
158	1ENC2010	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
159	1ENC2010	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
160	1ENC2010	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
161	1ENC2012	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
162	1ENC2012	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
163	1ENC2012	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
164	1ENC2016	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
165	1ENC2016	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
166	1ENC2016	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
167	1ENC2019	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
168	1ENC2019	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
169	1ENC2019	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
170	1EPA202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
171	1EPA202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
172	1EPA202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
173	1EPA202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
174	1EPA202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
175	1EPB202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
176	1EPB202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
177	1EPB202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
178	1EPB202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
179	1EPB202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
180	1EPC202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
181	1EPC202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
182	1EPC202L	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
183	1EPC202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
184	1EPE1A5E22	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
185	1EPE1A5E22	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
186	1EPE1A5E22	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
187	1EPE1A5E22	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
188	1EPE1A5E22	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
189	1EPE1A5E22	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
190	1EPE1A5E22	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
191	1EPE1A5E23	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
192	1EPE1A5E23	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
193	1EPE1A5E23	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
194	1EPE1A5E23	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
195	1EPE1A5E23	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
196	1EPE1A5E23	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
197	1EPE1A5E23	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
198	1EPE1A5E25	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
199	1EPE1A5E25	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
200	1EPE1A5E25	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
201	1EPE1A5E28	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
202	1EPE1A5E28	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
203	1EPE1A5E28	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
204	1EPF1A1A01	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
205	1EPF1A1A01	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
206	1EPF1A1A01	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
207	1EPF1A5E02	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
208	1EPF1A5E02	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
209	1EPF1A5E02	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
210	1EPG200G	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
211	1EPG200G	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
212	1EPG200G	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
213	1EPG202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
214	1EPG202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
215	1EPG202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
216	1EPG202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
217	1EPG202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
218	1EPG5A2M01	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
219	1EPG5A2M01	Labor	L12 FILLING PART A	FILLING PART A	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
220	1EPG5A2M01	Labor	L12 FILLING PART B	FILLING PART B	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
221	1EPG5A2M01	Labor	L12 FILLING PARTC	FILLING PARTC	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
222	1EPG5A2M01	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
223	1EPG9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
224	1EPG9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
225	1EPG9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
226	1EPI202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
227	1EPI202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
228	1EPI202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
229	1EPI202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
230	1EPI202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
231	1EPK202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
232	1EPK202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
233	1EPK202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
234	1EPK202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
235	1EPK202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
236	1EPP202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
237	1EPP202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
238	1EPP202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
239	1EPP202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
240	1EPP202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
241	1EPR200G	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
242	1EPR200G	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
243	1EPR200G	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
244	1EPR2029	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
245	1EPR2029	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
246	1EPR2029	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
247	1EPR2033	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
248	1EPR2033	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
249	1EPR2033	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
250	1EPW200F	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
251	1EPW200F	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
252	1EPW200F	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
253	1EPW200G	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
254	1EPW200G	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
255	1EPW200G	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
256	1EPW202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
257	1EPW202L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
258	1EPW202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
259	1ES16743	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
260	1ES16743	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
261	1ES16743	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
262	1ESG202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
263	1ESG202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
264	1ESG202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
265	1ESG202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
266	1ESG202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
267	1ETF6A1I01	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
268	1ETF6A1I01	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
269	1ETF6A1I01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
270	1ETL202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
271	1ETL202L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
272	1ETL202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
273	1FBW612J	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
274	1FBW612J	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
275	1FBW612J	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
276	1FBW612J	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
277	1FBW612J	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
278	1FCB2009	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
279	1FCB2009	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
280	1FCB2009	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
281	1FCB2012	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
282	1FCB2012	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
283	1FCB2012	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
284	1FCG480L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
285	1FCG480L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
286	1FCG480L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
287	1FCG480L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
288	1FCG480L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
289	1FDB202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
290	1FDB202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
291	1FDB202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
292	1FDB202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
293	1FDB202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
294	1FKG922L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
295	1FKG922L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
296	1FKG922L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
297	1FKG922L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
298	1FKG922L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
299	1FLG480L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
300	1FLG480L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
301	1FLG480L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
302	1FLG9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
303	1FLG9229	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
304	1FLG9229	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
305	1FLG9229	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
306	1FLG9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
307	1FMG480L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
308	1FMG480L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
309	1FMG480L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
310	1FRP205S	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
311	1FRP205S	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
312	1FRP205S	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
313	1FSG922L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
314	1FSG922L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
315	1FSG922L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
316	1FSG922L	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
317	1FSG922L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
318	1FSG922L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
319	1FTB922L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
320	1FTB922L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
321	1FTB922L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
322	1FTB922L	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
323	1FTB922L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
324	1FTB922L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
325	1FTC202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
326	1FTC202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
327	1FTC202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
328	1FTC202L	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
329	1FTC202L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
330	1FTC202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
331	1FTE922L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
332	1FTE922L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
333	1FTE922L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
334	1FTE922L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
335	1FTE922L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
336	1FTL922L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
337	1FTL922L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
338	1FTL922L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
339	1FTY202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
340	1FTY202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
341	1FTY202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
342	1FTY202L	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
343	1FTY202L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
344	1FTY202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
345	1GAB202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
346	1GAB202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
347	1GAB202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
348	1GAB202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
349	1GAB202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
350	1GAB8013	Labor	L11 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
351	1GDF202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
352	1GDF202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
353	1GDF202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
354	1GDF202L	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
355	1GDF202L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
356	1GDF202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
357	1GDG202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
358	1GDG202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
359	1GDG202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
360	1GDG202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
361	1GDG202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
362	1GDW202L	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
363	1GDW922L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
364	1GDW922L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
365	1GDW922L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
366	1GDW922L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
367	1GDW922L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
368	1GEG202L	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
369	1GEG202L	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
370	1GEG202L	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
371	1GEG202L	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
372	1GEG202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
373	1GEG202L	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
374	1GEG202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
375	1GF21A1A01	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
376	1GF21A1A01	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
377	1GF21A1A01	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
378	1GF31A1A17	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
379	1GF31A1A17	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
380	1GF31A1A17	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
381	1GF31A5E01	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
382	1GF31A5E01	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
383	1GF31A5E01	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
384	1GFB922L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
385	1GFB922L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
386	1GFB922L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
387	1GFB922L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
388	1GFB922L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
389	1GFG202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
390	1GFG202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
391	1GFG202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
392	1GFG202L	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
393	1GFG202L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
394	1GFG202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
395	1GFX202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
396	1GFX202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
397	1GFX202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
398	1GFX202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
399	1GFX202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
400	1GNG202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
401	1GNG202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
402	1GNG202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
403	1GNG202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
404	1GNG202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
405	1GPB202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
406	1GPB202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
407	1GPB202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
408	1GPB202L	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
409	1GPB202L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
410	1GPB202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
411	1GPD202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
412	1GPD202L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
413	1GPD202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
414	1GPG202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
415	1GPG202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
416	1GPG202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
417	1GPG202L	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
418	1GPG202L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
419	1GPG202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
420	1GPH202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
421	1GPH202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
422	1GPH202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
423	1GPH202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
424	1GPH202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
425	1GPI202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
426	1GPI202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
427	1GPI202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
428	1GPI202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
429	1GPI202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
430	1GPK202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
431	1GPK202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
432	1GPK202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
433	1GPK202L	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
434	1GPK202L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
435	1GPK202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
436	1GPL202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
437	1GPL202L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
438	1GPL202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
439	1GPR202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
440	1GPR202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
441	1GPR202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
442	1GPR202L	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
443	1GPR202L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
444	1GPR202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
445	1GPW202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
446	1GPW202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
447	1GPW202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
448	1GPW202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
449	1GPW202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
450	1GPY202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
451	1GPY202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
452	1GPY202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
453	1GPY202L	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
454	1GPY202L	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
455	1GPY202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
456	1GSL202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
457	1GSL202L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
458	1GSL202L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
459	1GSL202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
460	1GSL202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
461	1GUB202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
462	1GUB202L	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
463	1GUB202L	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
464	1GUB202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
465	1HVC2009	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
466	1HVC2009	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
467	1HVC2009	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
468	1HVC2010	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
469	1HVC2010	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
470	1HVC2010	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
471	1IET1A2H01	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
472	1IET1A2H01	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
473	1IET1A2H01	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
474	1LSC5A9A01	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
475	1LSC5A9A01	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
476	1LSC5A9A01	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
477	1LVC2009	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
478	1LVC2009	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
479	1LVC2009	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
480	1LVC2010	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
481	1LVC2010	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
482	1LVC2010	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
483	1LWG922L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
484	1LWG922L	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
485	1LWG922L	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
486	1LWG922L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
487	1LWG922L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
488	1M101069	Labor	L03 FILLING	FILLING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
489	1M101069	Labor	L03 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
490	1M2C2009	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
491	1M2C2009	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
492	1M2C2009	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
493	1M2C2010	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
494	1M2C2010	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
495	1M2C2010	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
496	1M2C2012	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
497	1M2C2012	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
498	1M2C2012	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
499	1M2C2016	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
500	1M2C2016	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
501	1M2C2016	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
502	1M2C2017	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
503	1M2C2017	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
504	1M2C2017	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
505	1MBN336B	Labor	L02 FILLING	FILLING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
506	1MBN336B	Labor	L02 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
507	1MGR3A3Z01	Labor	L11 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
508	1MGR3A3Z01	Labor	L11 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
509	1MGR3A3Z01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
510	1MPV2009	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
511	1MPV2009	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
512	1MPV2009	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
513	1MPV2010	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
514	1MPV2010	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
515	1MPV2010	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
516	1MPV2012	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
517	1MPV2012	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
518	1MPV2012	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
519	1MPV2016	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
520	1MPV2016	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
521	1MPV2016	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
522	1N1C2009	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
523	1N1C2009	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
524	1N1C2009	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
525	1N1C2010	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
526	1N1C2010	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
527	1N1C2010	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
528	1N1C2012	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
529	1N1C2012	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
530	1N1C2012	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
531	1N1C2016	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
532	1N1C2016	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
533	1N1C2016	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
534	1N1C2017	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
535	1N1C2017	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
536	1N1C2017	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
537	1OFX3A9A01	Labor	L02 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
538	1OFX3A9A01	Labor	L02 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
539	1OFX6A3U01	Labor	L11 CODING	CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
540	1OFX6A3U01	Labor	L11 FILLING	FILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
541	1OFX6A3U01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	Subcon	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
542	1OFX6A3X01	Labor	L11 CODING	CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
543	1OFX6A3X01	Labor	L11 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
544	1OFX6A3X01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
545	1P5C2009	Labor	L12 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
546	1P5C2009	Labor	L12 FILLING	FILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
547	1P5C2009	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
548	1P5C2010	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
549	1P5C2010	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
550	1P5C2010	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
551	1PBA999J	Labor	L11 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
552	1PBA999J	Labor	L11 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
553	1PBA999J	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
554	1PBB2008	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
555	1PBB2008	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
556	1PBB2008	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
557	1PBB999J	Labor	L04B LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
558	1PBB999J	Labor	L04B FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
559	1PBB999J	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
560	1PBB9B13	Labor	L04B CODING	CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
561	1PBB9B13	Labor	L04B FILLING	FILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
562	1PBB9B13	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
563	1PBC9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
564	1PBC9233	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
565	1PBC9233	Labor	L01 MILLING	MILLING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
566	1PBC9233	Labor	L01 TINTING	TINTING	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
567	1PBC9233	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
568	1PBC9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
569	1PBD9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
570	1PBD9233	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
571	1PBD9233	Labor	L01 MILLING	MILLING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
572	1PBD9233	Labor	L01 LETDOWN	LETDOWN	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
573	1PBD9233	Labor	L01 TINTING	TINTING	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
574	1PBD9233	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
575	1PBD9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
576	1PBI9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
577	1PBI9229	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
578	1PBI9229	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
579	1PBI9229	Labor	L01 FILLING	FILLING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
580	1PBI9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
581	1PBI9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
582	1PBI9233	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
583	1PBI9233	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
584	1PBI9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
585	1PBI9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
586	1PBL9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
587	1PBL9229	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
588	1PBL9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
589	1PBL9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
590	1PBL9233	Labor	L01 FILLING	FILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
591	1PBL9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
592	1PBS9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
593	1PBS9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
594	1PBS9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
595	1PBS9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
596	1PBS9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
597	1PBS9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
598	1PCT2009	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
599	1PCT2009	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
600	1PCT2009	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
601	1PCW325A	Labor	L12 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
602	1PCW325A	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
603	1PCW325A	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
604	1PCW325B	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
605	1PCW325B	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
606	1PCY9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
607	1PCY9229	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
608	1PCY9229	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
609	1PCY9229	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
610	1PCY9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
611	1PCY9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
612	1PEC9B5L	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
613	1PEC9B5L	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
614	1PEC9B5L	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
615	1PER9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
616	1PER9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
617	1PER9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
618	1PFG9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
619	1PFG9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
620	1PFG9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
621	1PFH612J	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
622	1PFH612J	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
623	1PFH612J	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
624	1PFW612J	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
625	1PFW612J	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
626	1PFW612J	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
627	1PGC9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
628	1PGC9229	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
629	1PGC9229	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
630	1PGC9229	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
631	1PGC9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
632	1PGC9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
633	1PGD9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
634	1PGD9229	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
635	1PGD9229	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
636	1PGD9229	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
637	1PGD9229	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
638	1PGD9229	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
639	1PGD9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
640	1PGI920G	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
641	1PGI920G	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
642	1PGI920G	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
643	1PGO200F	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
644	1PGO200F	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
645	1PGO200F	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
646	1PGO200G	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
647	1PGO200G	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
648	1PGO200G	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
649	1PGS1A5D02	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
650	1PGS1A5D02	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
651	1PGS1A5D02	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
652	1PGS1A5E02	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
653	1PGS1A5E02	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
654	1PGS1A5E02	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
655	1PGS9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
656	1PGS9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
657	1PGS9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
658	1PGS9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
659	1PGS9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
660	1PGS9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
661	1PGT920G	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
662	1PGT920G	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
663	1PGT920G	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
664	1PGT920G	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
665	1PGT920G	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
666	1PGW9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
667	1PGW9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
668	1PGW9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
669	1PGW9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
670	1PGW9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
671	1PGW9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
672	1PIB9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
673	1PIB9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
674	1PIB9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
675	1PIB9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
676	1PIB9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
677	1PIB9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
678	1PIF9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
679	1PIF9233	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
680	1PIF9233	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
681	1PIF9233	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
682	1PIF9233	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
683	1PIF9233	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
684	1PIF9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
685	1PIG9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
686	1PIG9229	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
687	1PIG9229	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
688	1PIG9229	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
689	1PIG9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
690	1PIG9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
691	1PIG9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
692	1PIG9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
693	1PIG9233	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
694	1PIG9233	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
695	1PIG9233	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
696	1PIG9233	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
697	1PIO9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
698	1PIO9229	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
699	1PIO9229	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
700	1PIO9229	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
701	1PIO9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
702	1PIO9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
703	1PIO9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
704	1PIO9233	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
705	1PIO9233	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
706	1PIO9233	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
707	1PIO9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
708	1PIO9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
709	1PIR9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
710	1PIR9229	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
711	1PIR9229	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
712	1PIR9229	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
713	1PIR9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
714	1PIR9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
715	1PIR9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
716	1PIR9233	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
717	1PIR9233	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
718	1PIR9233	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
719	1PIR9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
720	1PIR9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
721	1PIW9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
722	1PIW9229	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
723	1PIW9229	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
724	1PIW9229	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
725	1PIW9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
726	1PIW9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
727	1PIW9233	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
728	1PIW9233	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
729	1PIW9233	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
730	1PIW9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
731	1PIY9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
732	1PIY9229	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
733	1PIY9229	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
734	1PIY9229	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
735	1PIY9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
736	1PIY9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
737	1PIY9233	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
738	1PIY9233	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
739	1PIY9233	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
740	1PIY9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
741	1PIY9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
742	1PJE2009	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
743	1PJE2009	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
744	1PJE2009	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
745	1PJE2010	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
746	1PJE2010	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
747	1PJE2010	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
748	1PLS9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
749	1PLS9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
750	1PLS9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
751	1PLS9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
752	1PLS9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
753	1PLS9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
754	1POS9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
755	1POS9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
756	1POS9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
757	1POS9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
758	1POS9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
759	1POS9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
760	1PRS9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
761	1PRS9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
762	1PRS9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
763	1PRS9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
764	1PRS9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
765	1PRS9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
766	1PSB9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
767	1PSB9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
768	1PSB9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
769	1PSB9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
770	1PSB9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
771	1PSB9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
772	1PSC9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
773	1PSC9229	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
774	1PSC9229	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
775	1PSC9229	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
776	1PSC9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
777	1PSC9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
778	1PSC9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
779	1PSC9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
780	1PSC9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
781	1PSC966D	Labor	L14 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
782	1PSC966D	Labor	L14 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
783	1PSC966D	Labor	L14 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
784	1PSG9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
785	1PSG9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
786	1PSG9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
787	1PSG9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
788	1PSG9233	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
789	1PSG9233	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
790	1PSG9233	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
791	1PSG9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
792	1PSO9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
793	1PSO9229	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
794	1PSO9229	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
795	1PSO9229	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
796	1PSO9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
797	1PSO9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
798	1PSO9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
799	1PSO9233	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
800	1PSO9233	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
801	1PSO9233	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
802	1PSO9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
803	1PSO9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
804	1PSR9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
805	1PSR9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
806	1PSR9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
807	1PSR9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
808	1PSR9233	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
809	1PSR9233	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
810	1PSR9233	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
811	1PSR9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
812	1PSR9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
813	1PSY9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
814	1PSY9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
815	1PSY9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
816	1PSY9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
817	1PSY9233	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
818	1PSY9233	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
819	1PSY9233	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
820	1PSY9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
821	1PSY9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
822	1PUB9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
823	1PUB9229	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
824	1PUB9229	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
825	1PUB9229	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
826	1PUB9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
827	1PUB9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
828	1PUB9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
829	1PUB9233	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
830	1PUB9233	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
831	1PUB9233	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
832	1PUB9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
833	1PUB9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
834	1PUC1A5E01	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
835	1PUC1A5E01	Labor	L01 NITROGEN PURGING	NITROGEN PURGING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
836	1PUC1A5E01	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
837	1PUC1A5E01	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
838	1PUG0000	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
839	1PUI920G	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
840	1PUI920G	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
841	1PUI920G	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
842	1PUI920G	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
843	1PUI920G	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
844	1PUI920G	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
845	1PUI930G	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
846	1PUI930G	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
847	1PUI930G	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
848	1PUI930G	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
849	1PUI930G	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
850	1PUI930G	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
851	1PUS9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
852	1PUS9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
853	1PUS9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
854	1PUS9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
855	1PUS9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
856	1PUS9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
857	1PWS9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
858	1PWS9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
859	1PWS9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
860	1PWS9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
861	1PWS9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
862	1PWS9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
863	1PYS9229	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
864	1PYS9229	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
865	1PYS9229	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
866	1PYS9233	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
867	1PYS9233	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
868	1PYS9233	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
869	1QDE1A5E41	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
870	1QDE1A5E41	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
871	1QDE1A5E41	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
872	1QDE1A5E42	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
873	1QDE1A5E42	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
874	1QDE1A5E42	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
875	1QDE1A5E43	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
876	1QDE1A5E43	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
877	1QDE1A5E43	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
878	1QDE1A5E44	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
879	1QDE1A5E44	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
880	1QDE1A5E44	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
881	1S010000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
882	1S020000	Labor	L09A CUTTING	CUTTING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
883	1S025000	Labor	L09 PRE-EXPANSION	PRE-EXPANSION	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
884	1S025000	Labor	L09 MOLDING	MOLDING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
885	1S0A0000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
886	1S0B0000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
887	1S0C0000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
888	1S110000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
889	1S110204	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
890	1S120000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
891	1S140000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
892	1S1A0000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
893	1S1C0000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
894	1S1Z0000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
895	1S220000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
896	1S240000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
897	1S420000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
898	1S430000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
899	1S4C0000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
900	1S4E0000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
901	1S5A0000	Labor	L09A CUTTING	CUTTING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
902	1S860000	Labor	L09 PRE-EXPANSION	PRE-EXPANSION	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
903	1S860000	Labor	L09 MOLDING	MOLDING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
904	1SEC2009	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
905	1SEC2009	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
906	1SEC2009	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
907	1SF00064	Labor	L09 PRE-EXPANSION	PRE-EXPANSION	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
908	1SF00064	Labor	L09 MOLDING	MOLDING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
909	1SF25000	Labor	L09 PRE-EXPANSION	PRE-EXPANSION	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
910	1SF25000	Labor	L09 MOLDING	MOLDING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
911	1SF54000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
912	1SF90001	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
913	1ST20000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
914	1ST30000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
915	1ST40000	Labor	L09A CUTTING	CUTTING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
916	1SUW202L	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
917	1SUW202L	Labor	L12 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
918	1SUW202L	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
919	1TAD7723-IH	Labor	L14 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
920	1TAD7723-IH	Labor	L14 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
921	1TAD7723-IH	Labor	L14 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
922	1VTS951W	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
923	1VTS951W	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
924	1VTS951W	Labor	L04B SHRINKPACKING	SHRINKPACKING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
925	1VTS951W	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
926	1W205A5J03	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
927	1W205A5J03	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
928	1W205A5J03	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
929	1W205A5J04	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
930	1W205A5J04	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
931	1W205A5J04	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
932	1W205A5J05	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
933	1W205A5J05	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
934	1W205A5J05	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
935	1W205A5J06	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
936	1W205A5J06	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
937	1W205A5J06	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
938	1WEB9B13	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
939	1WEB9B13	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
940	1WEB9B13	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
941	1WEC2009	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
942	1WEC2009	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
943	1WEC2009	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
944	1WEC2010	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
945	1WEC2010	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
946	1WEC2010	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
947	1WEC2012	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
948	1WEC2012	Labor	L12 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
949	1WEC2012	Labor	L12 FILLING	FILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
950	1WEC2012	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
951	1WTE2396	Labor	L14 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
952	1WTE2396	Labor	L14 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
953	1WTE612J	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
954	1WTE612J	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
955	1WTE612J	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
956	1WTE612J	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
957	1WTE612J	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
958	1WTE920K	Labor	L14 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
959	1WTE920K	Labor	L14 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
960	1WTE920K	Labor	L14 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
961	1WTT572W	Labor	L13 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
962	1WTT572W	Labor	L13 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
963	1WTT572W	Labor	L13 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
964	1WTT920K	Labor	L13 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
965	1WTT920K	Labor	L13 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
966	1WTT920K	Labor	L13 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
967	2AAM6107	Labor	L13 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
968	2AAM6107	Labor	L13 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
969	2BCE0826	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
970	2BCE0826	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
971	2BCE0826	Labor	L12 FILLING	FILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
972	2BPA434L	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
973	2BPA434L	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
974	2BPA434L	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
975	2BYG434L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
976	2BYG434L	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
977	2BYG434L	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
978	2BYG434L	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
979	2BYG434L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
980	2CAC6107	Labor	L13 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
981	2CAC6107	Labor	L13 FILLING	FILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
982	2EPF4B2501	Labor	L09A CUTTING	CUTTING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
983	2EPF4B6501	Labor	L09A CUTTING	CUTTING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
984	2EPF4B6601	Labor	L09A CUTTING	CUTTING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
985	2EPF4B9A01	Labor	L09A CUTTING	CUTTING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
986	2EPF4B9A02	Labor	L09A CUTTING	CUTTING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
987	2EPF4B9A03	Labor	L09 PRE-EXPANSION	PRE-EXPANSION	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
988	2EPF4B9A03	Labor	L09 MOLDING	MOLDING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
989	2EPF4B9A04	Labor	L09 PRE-EXPANSION	PRE-EXPANSION	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
990	2EPF4B9A04	Labor	L09 MOLDING	MOLDING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
991	2FCW020K	Labor	L13 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
992	2FCW020K	Labor	L13 FILLING	FILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
993	2FCW612J	Labor	L13 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
994	2FCW612J	Labor	L13 FILLING	FILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
995	2FFC2009	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
996	2FFC2009	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
997	2FFC2009	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
998	2GDG202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
999	2GDG202L	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1000	2GDG202L	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1001	2GDG202L	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1002	2GDG202L	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1003	2GDG202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
1004	2GLG202L	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1005	2GLG202L	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1006	2GLG202L	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1007	2GLG202L	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1008	2GLG202L	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1009	2I7C2009	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1010	2I7C2009	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1011	2I7C2009	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1012	2IDC2009	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1013	2IDC2009	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1014	2IDC2009	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1015	2ILC203W	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1016	2ILC203W	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1017	2ILC203W	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1018	2JFC2009	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1019	2JFC2009	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1020	2JFC2009	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1021	2JFC2010	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1022	2JFC2010	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1023	2JFC2010	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1024	2JTC6130	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1025	2JTC6130	Labor	L12 MIXING	MIXING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1026	2JTC6130	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1027	2MBC2009	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1028	2MBC2009	Labor	L12 FILLING	FILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1029	2MCE201G	Labor	L06 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1030	2MCE201G	Labor	L06 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1031	2MCE201G	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1032	2MLC201G	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1033	2MLC201G	Labor	L12 FILLING	FILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1034	2PBT9B13	Labor	L04B LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1035	2PBT9B13	Labor	L04B FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1036	2PBT9B13	Labor	L04B SHRINKPACKING	SHRINKPACKING	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1037	2PSE6109	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1038	2PSE6109	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1039	2PSE6109	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1040	2TMC7001	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1041	2TMC7001	Labor	L12 FILLING	FILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1042	2UEB2009	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1043	2UEB2009	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1044	2UEB2009	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1045	3AGS6A1O01	Labor	L11 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1046	3AGS6A1O01	Labor	L11 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1047	3AGS6A1O01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1048	3ANC3A9A01	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1049	3ANC3A9A01	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1050	3ANC3A9A01	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1051	3BBA3A3Z01	Labor	L04B CODING	CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1052	3BBA3A3Z01	Labor	L04B FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1053	3BBA3A3Z01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1054	3BBA6A1O01	Labor	L04B LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1055	3BBA6A1O01	Labor	L04B FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1056	3BBA6A1O01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1057	3BC43B5E01	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1058	3BC43B5E01	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1059	3BC43B5E01	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1060	3CB11192	Labor	L11 FILLING	FILLING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1061	3CB11193	Labor	L11 FILLING	FILLING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1062	3CHV1A1A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1063	3CHV1A1A01	Labor	L06 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1064	3CHV1A1A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1065	3CHV1A2A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1066	3CHV1A2A01	Labor	L06 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1067	3CHV1A2A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1068	3CLE1A1A01	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1069	3CLE1A1A01	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1070	3CLE1A1A01	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1071	3CLP1A3A01	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1072	3CLP1A3A01	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1073	3CLP1A3A01	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1074	3CLP1A4A01	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1075	3CLP1A4A01	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1076	3CLP1A4A01	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1077	3CLP1A5A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1078	3CLP1A5A01	Labor	L06 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1079	3CLP1A5A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1080	3CLV1A1A01	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1081	3CLV1A1A01	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1082	3CLV1A1A01	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1083	3CLV1A2A01	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1084	3CLV1A2A01	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1085	3CLV1A2A01	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1086	3CY13B1M01	Labor	L02 STICKERING	STICKERING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1087	3CY13B1M01	Labor	L02 FILLING AND CAPP	FILLING AND CAPP	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1088	3CY13B1M01	Labor	L02 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1089	3CY23B1H01	Labor	L02 STICKERING	STICKERING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1090	3CY23B1H01	Labor	L02 FILLING AND CAPP	FILLING AND CAPP	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1091	3CY23B1H01	Labor	L02 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1092	3CY23B1M01	Labor	L02 STICKERING	STICKERING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1093	3CY23B1M01	Labor	L02 FILLING AND CAPP	FILLING AND CAPP	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1094	3CY23B1M01	Labor	L02 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1095	3D5F1B1G01	Labor	L07 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1096	3D5F1B1L01	Labor	L07 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1097	3DFA1354	Labor	L07 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1098	3DFA1354	Labor	L07 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1099	3DFA1462	Labor	L07 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1100	3DFA1462	Labor	L07 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1101	3DFB1354	Labor	L07 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1102	3DFB1354	Labor	L07 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1103	3DFB1462	Labor	L07 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1104	3DFB1462	Labor	L07 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1105	3ECP003N	Labor	L05 CUTTING	CUTTING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1106	3ECP003N	Labor	L05 FOILING	FOILING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1107	3EPA1354	Labor	L07 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1108	3EPA1354	Labor	L07 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1109	3EPB1354	Labor	L07 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1110	3EPB1354	Labor	L07 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1111	3ESC6A3U01	Labor	L11 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1112	3ESC6A3U01	Labor	L11 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1113	3ESC6A3U01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1114	3ESC6A3X01	Labor	L11 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1115	3ESC6A3X01	Labor	L11 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1116	3ESC6A3X01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1117	3ETF6A1N01	Labor	L04B LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1118	3ETF6A1N01	Labor	L04B FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1119	3ETF6A1N01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1120	3ETF6A1T01	Labor	L04B LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1121	3ETF6A1T01	Labor	L04B FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1122	3ETF6A1T01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1123	3GBT0001	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1124	3GBT0001	Labor	L01 MILLING	MILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1125	3GBT0002	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1126	3GBT0002	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1127	3GBT702K	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1128	3GBT702K	Labor	L01 MILLING	MILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1129	3GGE1049	Labor	L11 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1130	3GGE1049	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1131	3GGT0005	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1132	3GGT0005	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1133	3GGT0005	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1134	3GYO0004	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1135	3GYO0004	Labor	L01 MILLING	MILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1136	3GYT0003	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1137	3GYT0003	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1138	3GYT0003	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1139	3IET1A2H01	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1140	3IET1A2H01	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1141	3IET1A2H01	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1142	3MB41169	Labor	L03 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1143	3MB41169	Labor	L03 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1144	3MBA1B1C01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1145	3MBH1B1C01	Labor	L03 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	Subcon	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1146	3MBR1B1C01	Labor	L03 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1147	3MBS0000	Labor	L03 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1148	3MBS0000	Labor	L03 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1149	3MBX109D	Labor	L03 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1150	3MBX109D	Labor	L03 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1151	3MBX1B1C01	Labor	L03 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1152	3MFS6000	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1153	3MGB163M	Labor	L11 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1154	3MGB163M	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1155	3MGB1B1N01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	Subcon	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1156	3MGB1B1N02	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1157	3MGB9449	Labor	L11 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1158	3MGB9449	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1159	3MGG163M	Labor	L11 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1160	3MGG163M	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1161	3MGR163M	Labor	L11 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1162	3MGR163M	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1163	3MGR1B1N01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	Subcon	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1164	3MGR1B1N02	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1165	3MGR9449	Labor	L11 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1166	3MGR9449	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1167	3MNC1049	Labor	L11 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1168	3MNC1049	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1169	3MR0337C	Labor	L03 FILLING	FILLING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1170	3MSM1A1A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1171	3MSM1A1A01	Labor	L06 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1172	3MSM1A1A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1173	3MSM1A2A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1174	3MSM1A2A01	Labor	L06 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1175	3MSM1A2A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1176	3MSM1A3A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1177	3MSM1A3A01	Labor	L06 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1178	3MSM1A3A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1179	3MSM1A4A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1180	3MSM1A4A01	Labor	L06 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1181	3MSM1A4A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1182	3MSM1A5A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1183	3MSM1A5A01	Labor	L06 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1184	3MSM1A5A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1185	3MSW105B	Labor	L11 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1186	3MSW105B	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1187	3P5A1362	Labor	L07 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1188	3P5A1362	Labor	L07 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1189	3P5A1473	Labor	L07 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1190	3P5A1473	Labor	L07 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1191	3P5B1362	Labor	L07 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1192	3P5B1362	Labor	L07 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1193	3P5B1473	Labor	L07 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1194	3P5B1473	Labor	L07 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1195	3PEA002T	Labor	L05 CUTTING	CUTTING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1196	3PEA002T	Labor	L05 FOILING	FOILING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1197	3PEA003N	Labor	L05 CUTTING	CUTTING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1198	3PEA003N	Labor	L05 FOILING	FOILING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1199	3PER7000	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1200	3PES002T	Labor	L05 CUTTING	CUTTING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1201	3PES002T	Labor	L05 FOILING	FOILING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1202	3PES003N	Labor	L05 CUTTING	CUTTING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1203	3PES003N	Labor	L05 FOILING	FOILING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1204	3PGE7000	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1205	3PGE7000	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1206	3PGE7000	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1207	3PGG1A5D21	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1208	3PGG1A5D21	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1209	3PGG1A5D21	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1210	3PGG1A5D25	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1211	3PGG1A5D25	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1212	3PGG1A5D25	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1213	3PGG1A5D26	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1214	3PGG1A5D26	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1215	3PGG1A5D26	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1216	3PGG1A5E23	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1217	3PGG1A5E23	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1218	3PGG1A5E23	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1219	3PGG1A5E25	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1220	3PGG1A5E25	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1221	3PGG1A5E25	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1222	3PGG1A5E26	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1223	3PGG1A5E26	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1224	3PGG1A5E26	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1225	3PGK7000	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1226	3PGK7000	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1227	3PGO7000	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1228	3PGO7000	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1229	3PGR7000	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1230	3PGR7000	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1231	3PGY7000	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1232	3PGY7000	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1233	3PGY7000	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1234	3PJP1A4A01	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1235	3PJP1A4A01	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1236	3PJP1A4A01	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1237	3RC11A3W01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1238	3SUE1A2G01	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1239	3SUE1A2G01	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1240	3SUE1A2G01	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1241	3W101A2J01	Labor	L13 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1242	3W101A2J01	Labor	L13 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1243	3W101A2J01	Labor	L13 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1244	3W106A1R01	Labor	L13 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1245	3W106A1R01	Labor	L13 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1246	3W106A1R01	Labor	L13 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1247	3W415A2Q01	Labor	L13 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1248	3W415A2Q01	Labor	L13 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1249	3W415A2Q01	Labor	L13 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1250	3W415A9A01	Labor	L13 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1251	3W415A9A01	Labor	L13 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1252	3W415A9A01	Labor	L13 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1253	3WDG5A2B01	Labor	L13 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1254	3WDG5A2L01	Labor	L13 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1255	3WPF5A5E01	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1256	3WPF5A5E01	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1257	3WPF5A5E01	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1258	3WPF5A5I01	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1259	3WPF5A5I01	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1260	3WPF5A5I01	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1261	4BBA4A8A01	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1262	4BBA4A8A01	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1263	4BBA4A8A01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1264	4BRB2A9A01	Labor	L13 FILLING/STITCHIN	FILLING/STITCHIN	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1265	4BRB2A9A01	Labor	L13 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1266	4ERB2A9A01	Labor	L13 FILLING/STITCHIN	FILLING/STITCHIN	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1267	4ERB2A9A01	Labor	L13 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1268	4ETF4A8A01	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1269	4ETF4A8A01	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1270	4ETF4A8A01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1271	4ETF6A1I01	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1272	4ETF6A1I01	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1273	4ETF6A1I01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1274	4WPF5A5E01	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1275	4WPF5A5E01	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1276	4WPF5A5E01	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1277	4WPF5A5I01	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1278	4WPF5A5I01	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1279	4WPF5A5I01	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1280	5APE1A1A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1281	5APE1A1A01	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1282	5APE1A1A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1283	5APE1A1L01	Labor	L07 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1284	5APE1A2A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1285	5APE1A2A01	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1286	5APE1A2A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1287	5APE1A3A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1288	5APE1A3A01	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1289	5APE1A3A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1290	5APE1A4A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1291	5APE1A4A01	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1292	5APE1A4A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1293	5APE1A5A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1294	5APE1A5A01	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1295	5APE1A5A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1296	5BBA6A1O01	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1297	5BBA6A1O01	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1298	5BBA6A1O01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1299	5CBA1B3S01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1300	5D5F1B1L01	Labor	L07 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1301	5D5F8A1G01	Labor	L07 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1302	5ECA7A7B01	Labor	L05 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1303	5ECA7A7C01	Labor	L05 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1304	5ECP7A1M01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1305	5ECS7A1M01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1306	5ECS7A7B01	Labor	L05 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1307	5EPP1A5E01	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1308	5EPP1A5E01	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1309	5EPP1A5E01	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1310	5ESC3A3Z01	Labor	L11 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1311	5ESC3A3Z01	Labor	L11 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1312	5ESC3A3Z01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1313	5ESC6A3U01	Labor	L11 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1314	5ESC6A3U01	Labor	L11 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1315	5ESC6A3U01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1316	5ESC6A3X01	Labor	L11 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1317	5ESC6A3X01	Labor	L11 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1318	5ESC6A3X01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1319	5ESP1A5E01	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1320	5ESP1A5E01	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1321	5ESP1A5E01	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1322	5ETF1A5B01	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1323	5ETF1A5B01	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1324	5ETF1A5B01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1325	5ETF1A5C01	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1326	5ETF1A5C01	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1327	5ETF1A5C01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1328	5ETF1A5D01	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1329	5ETF1A5D01	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1330	5ETF1A5D01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1331	5ETF1A5E01	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1332	5ETF1A5E01	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1333	5ETF1A5E01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1334	5ETF3A3Z01	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1335	5ETF3A3Z01	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1336	5ETF3A3Z01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1337	5ETF6A1O01	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1338	5ETF6A1O01	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1339	5ETF6A1O01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1340	5ETF6A1T01	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1341	5ETF6A1T01	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1342	5ETF6A1T01	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1343	5MAE1A1A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1344	5MAE1A1A01	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1345	5MAE1A1A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1346	5MAE1A2A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1347	5MAE1A2A01	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1348	5MAE1A2A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1349	5MAE1A3A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1350	5MAE1A3A01	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1351	5MAE1A3A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1352	5MAE1A4A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1353	5MAE1A4A01	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1354	5MAE1A4A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1355	5MAE1A5A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1356	5MAE1A5A01	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1357	5MAE1A5A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1358	5MBH1B1C01	Labor	L03 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1359	5MBR1B1C01	Labor	L03 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1360	5MBR8A1C01	Labor	L03 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1361	5MBX1B1C01	Labor	L03 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1362	5MGB1B1K01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1363	5MGB1B1N01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1364	5MGG1B1G01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1365	5MGG1B1K01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1366	5MGG1B1N01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1367	5MGR1B1K01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1368	5MGR1B1N01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1369	5MSB3A3Z01	Labor	L11 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1370	5MSB3A3Z01	Labor	L11 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1371	5MSB3A3Z01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1372	5MSG1B1N01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1373	5MSM1A1A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1374	5MSM1A1A01	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1375	5MSM1A1A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1376	5MSM1A2A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1377	5MSM1A2A01	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1378	5MSM1A2A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1379	5MSM1A3A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1380	5MSM1A3A01	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1381	5MSM1A3A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1382	5MSM1A4A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1383	5MSM1A4A01	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1384	5MSM1A4A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1385	5MSM1A5A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1386	5MSM1A5A01	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1387	5MSM1A5A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1388	5NSE1A1A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1389	5NSE1A1A01	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1390	5NSE1A1A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1391	5NSE1A2A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1392	5NSE1A2A01	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1393	5NSE1A2A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1394	5NSE1A3A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1395	5NSE1A3A01	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1396	5NSE1A3A01	Labor	L06 SHRINKPACKING	SHRINKPACKING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1397	5NSE1A3A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1398	5NSE1A4A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1399	5NSE1A4A01	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1400	5NSE1A4A01	Labor	L06 SHRINKPACKING	SHRINKPACKING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1401	5NSE1A4A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1402	5NSE1A5A01	Labor	L06 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1403	5NSE1A5A01	Labor	L06 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1404	5NSE1A5A01	Labor	L06 SHRINKPACKING	SHRINKPACKING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1405	5NSE1A5A01	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1406	5P5E1B1G01	Labor	L07 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1407	5PGG1A5D01	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1408	5PGG1A5D01	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1409	5PGG1A5D01	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1410	5PGG1A5E01	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1411	5PGG1A5E01	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1412	5PGG1A5E01	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1413	5RC11A3W01	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1414	5WDG3B2B01	Labor	L13 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1415	5WDG3B2B01	Labor	L13 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1416	6BBT3A9A01	Labor	L02 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1417	B10000001	Labor	L12 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1418	B10000002	Labor	L12 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1419	B10000003	Labor	L12 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1420	B10000004	Labor	L12 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1421	B10000005	Labor	L12 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1422	B10000006	Labor	L12 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1423	B10000007	Labor	L12 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1424	B10000008	Labor	L12 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1425	B10000009	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1426	B10000010	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1427	B35000001	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1428	B35000002	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1429	B35000003	Labor	L12 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1430	B35000004	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1431	B35000005	Labor	L12 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1432	B35000006	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1433	B35000007	Labor	L13 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1434	B35000008	Labor	L13 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1435	B50000013	Labor	L13 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1436	B50000014	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1437	B60000025	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1438	B60000025	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1439	B60000025	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1440	B60000025	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1441	B60000053	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1442	B60000053	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1443	B60000053	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1444	B60000053	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1445	B60000059	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1446	B60000059	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1447	B60000059	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1448	B60000059	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1449	B60000071	Labor	L01 MIXING	MIXING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1450	B60000071	Labor	L01 TINTING	TINTING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1451	B60000085	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1452	B60000085	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1453	B60000085	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1454	B60000085	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1455	B60000093	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1456	B60000093	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1457	B60000093	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1458	B60000106	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1459	B60000106	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1460	B60000106	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1461	B60000115	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1462	B60000116	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1463	B60000116	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1464	B60000116	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1465	B60000122	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1466	B60000122	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1467	B60000125	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1468	B60000125	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1469	B60000125	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1470	B60000125	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1471	B60000131	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1472	B60000131	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1473	B60000131	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1474	B60000131	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1475	B60000144	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1476	B60000144	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1477	B60000144	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1478	B60000144	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1479	B60000149	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1480	B60000149	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1481	B60000149	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1482	B60000149	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1483	B60000151	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1484	B60000151	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1485	B60000151	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1486	B60000156	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1487	B60000156	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1488	B60000156	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1489	B60000156	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1490	B60000157	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1491	B60000157	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1492	B60000157	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1493	B60000157	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1494	B60000158	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1495	B60000158	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1496	B60000158	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1497	B60000159	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1498	B60000159	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1499	B60000159	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1500	B60000159	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1501	B60000160	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1502	B60000160	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1503	B60000160	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1504	B60000161	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1505	B60000161	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1506	B60000161	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1507	B60000161	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1508	B60000164	Labor	L01 MIXING	MIXING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1509	B60000164	Labor	L01 LETDOWN	LETDOWN	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1510	B60000165	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1511	B60000165	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1512	B60000165	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1513	B60000165	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1514	B60000166	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1515	B60000167	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1516	B60000167	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1517	B60000167	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1518	B60000168	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1519	B60000168	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1520	B60000168	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1521	B60000168	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1522	B60000169	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1523	B60000169	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1524	B60000169	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1525	B60000170	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1526	B60000170	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1527	B60000170	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1528	B60000170	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1529	B60000171	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1530	B60000171	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1531	B60000171	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1532	B60000174	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1533	B60000174	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1534	B60000176	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1535	B60000176	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1536	B60000176	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1537	B60000177	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1538	B60000177	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1539	B60000177	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1540	B60000177	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1541	B60000178	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1542	B60000178	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1543	B60000178	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1544	B60000178	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1545	B60000179	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1546	B60000179	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1547	B60000179	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1548	B60000179	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1549	B60000180	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1550	B60000180	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1551	B60000180	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1552	B60000181	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1553	B60000181	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1554	B60000181	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1555	B60000181	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1556	B60000183	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1557	B60000183	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1558	B60000190	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1559	B60000190	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1560	B60000190	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1561	B60000197	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1562	B60000197	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1563	B60000197	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1564	B60000197	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1565	B60000198	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1566	B60000198	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1567	B60000199	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1568	B60000199	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1569	B60000199	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1570	B60000199	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1571	B60000200	Labor	L01 MIXING	MIXING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1572	B60000200	Labor	L01 MILLING	MILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1573	B60000200	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1574	B60000200	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1575	B60000203	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1576	B60000203	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1577	B60000203	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1578	B60000203	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1579	B60000213	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1580	B60000214	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1581	B60000214	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1582	B60000214	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1583	B60000217	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1584	B60000217	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1585	B60000217	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1586	B60000223	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1587	B60000223	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1588	B60000223	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1589	B60000224	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1590	B60000224	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1591	B60000224	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1592	B60000227	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1593	B60000227	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1594	B60000227	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1595	B60000227	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1596	B60000230	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1597	B60000230	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1598	B60000230	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1599	B60000230	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1600	B60000232	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1601	B60000232	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1602	B60000232	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1603	B60000232	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1604	B60000234	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1605	B60000234	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1606	B60000234	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1607	B60000234	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1608	B60000249	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1609	B60000249	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1610	B60000249	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1611	B60000250	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1612	B60000250	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1613	B60000250	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1614	B60000250	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1615	B60000251	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1616	B60000251	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1617	B60000251	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1618	B60000251	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1619	B60000253	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1620	B60000253	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1621	B60000253	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1622	B60000254	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1623	B60000255	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1624	B60000255	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1625	B60000255	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1626	B60000255	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1627	B60000269	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1628	B60000269	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1629	B60000270	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1630	B60000270	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1631	B60000270	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1632	B60000270	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1633	B60000272	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1634	B60000272	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1635	B60000275	Labor	L01 MIXING	MIXING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1636	B60000275	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1637	B60000275	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1638	B60000275	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1639	B60000276	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1640	B60000276	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1641	B60000276	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1642	B60000276	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1643	B60000277	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1644	B60000278	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1645	B60000278	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1646	B60000278	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1647	B60000278	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1648	B60000280	Labor	L01 MIXING	MIXING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1649	B60000280	Labor	L01 MILLING	MILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1650	B60000280	Labor	L01 LETDOWN	LETDOWN	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1651	B60000280	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1652	B60000293	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1653	B60000293	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1654	B65000001	Labor	L12 MELTING	MELTING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1655	B65000001	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1656	B65000002	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1657	BM000003	Labor	L06 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1658	BM000004	Labor	L06 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1659	BM000005	Labor	L04A MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1660	BM000006	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1661	BM000008	Labor	L06 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1662	BM000009	Labor	L06 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1663	BM000010	Labor	L04A MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1664	BM000011	Labor	L12 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1665	BM000012	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1666	BM000013	Labor	L06 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1667	BM000014	Labor	L06 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1668	BM000015	Labor	L04A MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1669	BM000016	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1670	BM000017	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1671	BM000018	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1672	BM000019	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1673	BM000020	Labor	L12 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1674	BM000021	Labor	L12 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1675	BM000026	Labor	L12 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1676	BM000027	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1677	BM000028	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1678	BM000029	Labor	L13 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1679	BM000030	Labor	L13 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1680	BM000031	Labor	L13 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1681	BM000032	Labor	L14 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1682	BM000033	Labor	L13 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1683	BM000034	Labor	L14 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1684	BM000035	Labor	L13 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1685	BM000038	Labor	L14 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1686	BM000039	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1687	BM000040	Labor	L04A MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1688	BM000044	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1689	BM000045	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1690	BM000047	Labor	L12 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1691	BM000048	Labor	L12 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1692	BM000049	Labor	L12 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1693	BM000050	Labor	L12 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1694	BM000051	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1695	BM000052	Labor	L12 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1696	BM000053	Labor	L06 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1697	BM000054	Labor	L06 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1698	BM000055	Labor	L06 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1699	BM000056	Labor	L06 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1700	BM000057	Labor	L06 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1701	BM000058	Labor	L06 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1702	BM000059	Labor	L14 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1703	BM000060	Labor	L04A MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1704	BM000061	Labor	L04A MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1705	BM000062	Labor	L04A MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1706	BM000063	Labor	L13 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1707	BM000066	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1708	BM000067	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1709	BM000070	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1710	BM000071	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1711	BM000072	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1712	BM000078	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1713	BM000078	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1714	BM000078	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1715	BM000079	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1716	BM000081	Labor	L14 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1717	BM000082	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1718	BM000083	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1719	BM000085	Labor	L06 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1720	BM000086	Labor	L04A MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1721	BM000087	Labor	L14 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1722	BM000088	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1723	BM000089	Labor	L12 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1724	BM000090	Labor	L01 MIXING	MIXING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1725	BM000092	Labor	L14 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1726	BM000131	Labor	L12 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1727	BM000152	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1728	BM000152	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1729	BM000152	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1730	BM000152	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1731	BM000160	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1732	BM000161	Labor	L14 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1733	BM000166	Labor	L06 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1734	BM000173	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1735	BM000173	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1736	BM000173	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1737	BM000173	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1738	BM000174	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1739	BM000174	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1740	BM000174	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1741	BM000175	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1742	BM000175	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1743	BM000175	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1744	BM000175	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1745	BM000176	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1746	BM000176	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1747	BM000176	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1748	BM000176	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1749	BM000177	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1750	BM000177	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1751	BM000177	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1752	BM000179	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1753	BM000180	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1754	BM000180	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1755	BM000180	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1756	BM000180	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1757	BM000181	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1758	BM000181	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1759	BM000181	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1760	BM000181	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1761	BM000182	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1762	BM000182	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1763	BM000182	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1764	BM000182	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1765	BM000183	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1766	BM000183	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1767	BM000183	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1768	BM000183	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1769	BM000185	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1770	BM000185	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1771	BM000185	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1772	BM000185	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1773	BM000187	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1774	BM000187	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1775	BM000187	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1776	BM000187	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1777	BM000188	Labor	L01 MIXING	MIXING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1778	BM000188	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1779	BM000188	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1780	BM000188	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1781	BM000189	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1782	BM000189	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1783	BM000189	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1784	BM000189	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1785	BM000190	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1786	BM000191	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1787	BM000192	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1788	BM000192	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1789	BM000192	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1790	BM000192	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1791	BM1E2M2029	Labor	L04A MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1792	BM1PEC9B5L	Labor	L04A MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1793	FGI00011	Labor	L04B LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1794	FGI00011	Labor	L04B FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1795	FGI00011	Labor	L04B SHRINKPACKING	SHRINKPACKING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1796	FGI00011	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1797	FGI00042	Labor	L04B LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1798	FGI00042	Labor	L04B FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1799	FGI00042	Labor	L04B SHRINKPACKING	SHRINKPACKING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1800	FGI00042	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1801	FGI00043	Labor	L04B LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1802	FGI00043	Labor	L04B FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1803	FGI00043	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1804	FGI00044	Labor	L04B LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1805	FGI00044	Labor	L04B FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1806	FGI00044	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1807	FGI00047	Labor	L11 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1808	FGI00047	Labor	L11 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1809	FGI00047	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1810	FGI00048	Labor	L06 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1811	FGI00048	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1812	FGI00049	Labor	L04B LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1813	FGI00049	Labor	L04B FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1814	FGI00049	Labor	L04B SHRINKPACKING	SHRINKPACKING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1815	FGI00049	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1816	FGI00057	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1817	FGI00057	Labor	L01 MIXING	MIXING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1818	FGI00057	Labor	L01 MILLING	MILLING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1819	FGI00057	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1820	FGI00057	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1821	FGI00062	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1822	FGI00062	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1823	FGI00062	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1824	FGI00062	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1825	FGI00063	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1826	FGI00063	Labor	L01 MILLING	MILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1827	FGI00063	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1828	FGI00063	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1829	FGI00068	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1830	FGI00068	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1831	FGI00068	Labor	L01 MILLING	MILLING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1832	FGI00068	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1833	FGI00068	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1834	FGI00069	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1835	FGI00069	Labor	L01 MIXING	MIXING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1836	FGI00069	Labor	L01 MILLING	MILLING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1837	FGI00069	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1838	FGI00069	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1839	FGI00070	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1840	FGI00070	Labor	L01 MILLING	MILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1841	FGI00070	Labor	L01 TINTING	TINTING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1842	FGI00070	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1843	FGI00070	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1844	FGI00077	Labor	L12 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1845	FGI00077	Labor	L12 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1846	FGI00077	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1847	FGI00080	Labor	L12 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1848	FGI00080	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1849	FGI00080	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1850	FGI00085	Labor	L04B LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1851	FGI00085	Labor	L04B FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1852	FGI00085	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1853	FGI00099	Labor	L13 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1854	FGI00099	Labor	L13 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1855	FGI00099	Labor	L13 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1856	FGI00100	Labor	L06 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1857	FGI00100	Labor	L06 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1858	FGI00100	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1859	FGI00101	Labor	L04B LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1860	FGI00101	Labor	L04B FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1861	FGI00101	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1862	FGI00102	Labor	L10 FILLING	FILLING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1863	FGI00102	Labor	L10 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1864	FGI00117	Labor	L04C LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1865	FGI00117	Labor	L04C FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1866	FGI00117	Labor	L04C PACKING/PALLETI	PACKING/PALLETI	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1867	FGI00118	Labor	L06 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1868	FGI00118	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1869	FGI00118	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1870	FGI00120	Labor	L12 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1871	FGI00120	Labor	L12 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1872	FGI00120	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1873	FGI00124	Labor	L06 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1874	FGI00124	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1875	FGI00124	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1876	FGI00131	Labor	L06 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1877	FGI00131	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1878	FGI00131	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1879	FGI00132	Labor	L06 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1880	FGI00132	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1881	FGI00132	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1882	FGI00133	Labor	L06 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1883	FGI00133	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1884	FGI00133	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1885	FGI00134	Labor	L06 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1886	FGI00134	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1887	FGI00134	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1888	FGI00135	Labor	L06 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1889	FGI00135	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1890	FGI00135	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1891	FGI00136	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1892	FGI00136	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1893	FGI00137	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1894	FGI00137	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1895	FGI00138	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1896	FGI00138	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1897	FGI00139	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1898	FGI00139	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1899	FGI00140	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1900	FGI00140	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1901	FGI00141	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1902	FGI00141	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1903	FGI00141	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1904	FGI00141	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1905	FGI00141	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1906	FGI00141	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
1907	FGI00143	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1908	FGI00143	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1909	FGI00143	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1910	FGI00144	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1911	FGI00144	Labor	L01 FILLING	FILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1912	FGI00144	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1913	FGI00145	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1914	FGI00145	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1915	FGI00145	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1916	FGI00145	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1917	FGI00145	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1918	FGI00146	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1919	FGI00146	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1920	FGI00146	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1921	FGI00146	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1922	FGI00146	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1923	FGI00147	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1924	FGI00147	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1925	FGI00147	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1926	FGI00147	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1927	FGI00147	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1928	FGI00147	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
1929	FGI00147	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
1930	FGI00148	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1931	FGI00148	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1932	FGI00148	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1933	FGI00148	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1934	FGI00148	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1935	FGI00148	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
1936	FGI00148	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
1937	FGI00149	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1938	FGI00149	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1939	FGI00149	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1940	FGI00149	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1941	FGI00149	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1942	FGI00149	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
1943	FGI00149	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
1944	FGI00150	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1945	FGI00150	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1946	FGI00150	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1947	FGI00150	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1948	FGI00150	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1949	FGI00150	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
1950	FGI00150	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
1951	FGI00151	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1952	FGI00151	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1953	FGI00151	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1954	FGI00151	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1955	FGI00151	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1956	FGI00151	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
1957	FGI00151	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
1958	FGI00152	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1959	FGI00152	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1960	FGI00152	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1961	FGI00152	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1962	FGI00152	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1963	FGI00152	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
1964	FGI00152	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
1965	FGI00153	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1966	FGI00153	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1967	FGI00153	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1968	FGI00155	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1969	FGI00155	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1970	FGI00155	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1971	FGI00156	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1972	FGI00156	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1973	FGI00156	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1974	FGI00156	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1975	FGI00156	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1976	FGI00156	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
1977	FGI00157	Labor	L04B LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1978	FGI00157	Labor	L04B FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1979	FGI00157	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1980	FGI00170	Labor	L06 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1981	FGI00170	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1982	FGI00170	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1983	FGI00171	Labor	L06 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1984	FGI00171	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1985	FGI00171	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1986	FGI00172	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1987	FGI00172	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1988	FGI00172	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1989	FGI00172	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1990	FGI00172	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1991	FGI00172	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
1992	FGI00172	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
1993	FGI00173	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
1994	FGI00173	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
1995	FGI00173	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
1996	FGI00173	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
1997	FGI00173	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
1998	FGI00173	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
1999	FGI00173	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2000	FGI00177	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2001	FGI00177	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2002	FGI00177	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2003	FGI00178	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2004	FGI00178	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2005	FGI00178	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2006	FGP00006	Labor	L12 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2007	FGP00006	Labor	L12 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2008	FGP00006	Labor	L12 FILLING	FILLING	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2009	FGP00006	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2010	FGP00013	Labor	L12 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2011	FGP00013	Labor	L12 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2012	FGP00013	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2013	FGP00014	Labor	L12 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2014	FGP00014	Labor	L12 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2015	FGP00014	Labor	L12 FILLING	FILLING	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2016	FGP00014	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2017	FGP00021	Labor	L12 PAINTING OF DRUM	PAINTING OF DRUM	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2018	FGP00021	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2019	FGP00023	Labor	L12 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2020	FGP00023	Labor	L12 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2021	FGP00023	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2022	FGP00024	Labor	L12 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2023	FGP00024	Labor	L12 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2024	FGP00024	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2025	FGP00031	Labor	L12 FILLING	FILLING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2026	FGP00031	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2027	FGP00032	Labor	L12 FILLING	FILLING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2028	FGP00032	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2029	FGP00045	Labor	L12 FILLING	FILLING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2030	FGP00045	Labor	L12 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2031	FGP00045	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2032	FGP00051	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2033	FGP00051	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2034	FGP00051	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2035	FGP00055	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2036	FGP00055	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2037	FGP00055	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2038	FGP00060	Labor	L01 LABELING/CODING	LABELING/CODING	DL	Subcon	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2039	FGP00060	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2040	FGP00060	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2041	FGT00031	Labor	L06 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2042	FGT00031	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2043	FGT00031	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2044	FGT00032	Labor	L06 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2045	FGT00032	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2046	FGT00032	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2047	FGT00033	Labor	L06 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2048	FGT00033	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2049	FGT00033	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2050	FGT00034	Labor	L06 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2051	FGT00034	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2052	FGT00034	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2053	FGT00035	Labor	L06 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2054	FGT00035	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2055	FGT00035	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2056	FGT00065	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2057	FGT00065	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2058	FGT00065	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2059	FGT00066	Labor	L01 LABELING/CODING	LABELING/CODING	DL	Subcon	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2060	FGT00066	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2061	FGT00066	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2062	FGT00092-IH	Labor	L14 LABELING/CODING	LABELING/CODING	DL	Subcon	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2063	FGT00092-IH	Labor	L14 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2064	FGT00092-IH	Labor	L14 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2065	FGT00103	Labor	L12 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2066	FGT00103	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2067	FGT00103	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2068	FGT00104	Labor	L10 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2069	FGT00104	Labor	L10 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2070	FGT00105	Labor	L10 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2071	FGT00105	Labor	L10 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2072	FGT00105	Labor	L10 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2073	FGT00106	Labor	L10 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2074	FGT00106	Labor	L10 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2075	FGT00106	Labor	L10 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2076	FGT00111	Labor	L12 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2077	FGT00111	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2078	FGT00114	Labor	L10 LABELING/CODING	LABELING/CODING	DL	Subcon	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2079	FGT00114	Labor	L10 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2080	FGT00114	Labor	L10 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2081	FGT00117	Labor	L11 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2082	FGT00117	Labor	L11 FILLING	FILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2083	FGT00117	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2084	FGT00118	Labor	L11 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2085	FGT00118	Labor	L11 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2086	FGT00118	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2087	FGT00119	Labor	L11 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2088	FGT00119	Labor	L11 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2089	FGT00119	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2090	FGT00122	Labor	L11 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2091	FGT00122	Labor	L11 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2092	FGT00122	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2093	FGT00128	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2094	FGT00128	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2095	FGT00128	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2096	FGT00128	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2097	FGT00128	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2098	FGT00128	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2099	FGT00129	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2100	FGT00129	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2101	FGT00129	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2102	FGT00129	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2103	FGT00129	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2104	FGT00129	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2105	FGT00141	Labor	L04B LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2106	FGT00141	Labor	L04B FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2107	FGT00141	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2108	FGT00142	Labor	L04B LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2109	FGT00142	Labor	L04B FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2110	FGT00142	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2111	FGT00143	Labor	L04B LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2112	FGT00143	Labor	L04B FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2113	FGT00143	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2114	FGT00144	Labor	L04B LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2115	FGT00144	Labor	L04B FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2116	FGT00144	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2117	FGT00145	Labor	L04C LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2118	FGT00145	Labor	L04C FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2119	FGT00145	Labor	L04C PACKING/PALLETI	PACKING/PALLETI	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2120	FGT00146	Labor	L04C LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2121	FGT00146	Labor	L04C FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2122	FGT00146	Labor	L04C PACKING/PALLETI	PACKING/PALLETI	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2123	FGT00147	Labor	L04C LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2124	FGT00147	Labor	L04C FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2125	FGT00147	Labor	L04C PACKING/PALLETI	PACKING/PALLETI	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2126	FGT00148	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2127	FGT00148	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2128	FGT00148	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2129	FGT00148	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2130	FGT00148	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2131	FGT00155	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2132	FGT00155	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2133	FGT00155	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2134	FGT00155	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2135	FGT00155	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2136	FGT00158	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2137	FGT00158	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2138	FGT00158	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2139	FGT00158	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2140	FGT00158	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2141	FGT00158	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2142	FGT00158	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2143	FGT00159	Labor	L10 FILLING	FILLING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2144	FGT00159	Labor	L10 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2145	FGT00164	Labor	L12 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2146	FGT00164	Labor	L12 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2147	FGT00164	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2148	FGT00165	Labor	L12 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2149	FGT00165	Labor	L12 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2150	FGT00165	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2151	FGT00167	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2152	FGT00167	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2153	FGT00167	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2154	FGT00167	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2155	FGT00167	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2156	FGT00167	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2157	FGT00169	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2158	FGT00169	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2159	FGT00169	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2160	FGT00169	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2161	FGT00169	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2162	FGT00169	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2163	FGT00169	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2164	FGT00175	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2165	FGT00175	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2166	FGT00175	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2167	FGT00176	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2168	FGT00176	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2169	FGT00176	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2170	FGT00177	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2171	FGT00177	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2172	FGT00177	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2173	FGT00178	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2174	FGT00178	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2175	FGT00178	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2176	FGT00182	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2177	FGT00182	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2178	FGT00182	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2179	FGT00182	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2180	FGT00182	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2181	FGT00182	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2182	FGT00185	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2183	FGT00185	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2184	FGT00185	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2185	FGT00185	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2186	FGT00185	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2187	FGT00185	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2188	FGT00186	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2189	FGT00186	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2190	FGT00186	Labor	L01 FILLING	FILLING	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2191	FGT00186	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2192	FGT00187	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2193	FGT00187	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2194	FGT00187	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2195	FGT00188	Labor	L12 FILLING	FILLING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2196	FGT00188	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2197	FGT00193	Labor	L06 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2198	FGT00193	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2199	FGT00193	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2200	FGT00208	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2201	FGT00208	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2202	FGT00208	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2203	FGT00208	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2204	FGT00208	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2205	FGT00208	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2206	FGT00210	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2207	FGT00210	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2208	FGT00210	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2209	FGT00210	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2210	FGT00210	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2211	FGT00210	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2212	FGT00210	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2213	FGT00211	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2214	FGT00211	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2215	FGT00211	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2216	FGT00212	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2217	FGT00212	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2218	FGT00212	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2219	FGT00213	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2220	FGT00213	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2221	FGT00213	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2222	FGT00214	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2223	FGT00214	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2224	FGT00214	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2225	FGT00215	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2226	FGT00215	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2227	FGT00215	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2228	FGT00216	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2229	FGT00216	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2230	FGT00216	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2231	FGT00217	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2232	FGT00217	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2233	FGT00217	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2234	FGT00217	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2235	FGT00217	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2236	FGT00217	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2237	FGT00221	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2238	FGT00221	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2239	FGT00221	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2240	FGT00221	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2241	FGT00221	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2242	FGT00221	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2243	FGT00222	Labor	L12 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2244	FGT00222	Labor	L12 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2245	FGT00222	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2246	FGT00224	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2247	FGT00224	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2248	FGT00224	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2249	FGT00237	Labor	L01 LABELING/CODING	LABELING/CODING	DL	Subcon	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2250	FGT00237	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2251	FGT00237	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2252	FGT00249	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2253	FGT00249	Labor	L01 FILLING	FILLING	DL	Subcon	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2254	FGT00249	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2255	FGT00281	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2256	FGT00281	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2257	FGT00281	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2258	FGT00281	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2259	FGT00281	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2260	FGT00281	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2261	FGT00282	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2262	FGT00282	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2263	FGT00282	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2264	FGT00282	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2265	FGT00282	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2266	FGT00282	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2267	FGT00284	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2268	FGT00284	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2269	FGT00284	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2270	FGT00287	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2271	FGT00287	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2272	FGT00287	Labor	L01 MILLING	MILLING	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2273	FGT00287	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2274	FGT00287	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2275	FGT00288	Labor	L10 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2276	FGT00289	Labor	L13 FILLING	FILLING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2277	FGT00289	Labor	L13 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2278	FGT00314	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2279	FGT00314	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2280	FGT00314	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2281	FGT00315	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2282	FGT00315	Labor	L01 FILLING	FILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2283	FGT00315	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2284	FGT00317	Labor	L12 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2285	FGT00317	Labor	L12 FILLING	FILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2286	FGT00317	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2287	FGT00334	Labor	L06 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2288	FGT00334	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2289	FGT00334	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2290	FGT00335	Labor	L06 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2291	FGT00335	Labor	L06 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2292	FGT00335	Labor	L06 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2293	FGT00354	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2294	FGT00354	Labor	L01 FILLING	FILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2295	FGT00354	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2296	FGT00355	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2297	FGT00355	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2298	FGT00355	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2299	FGT00355	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2300	FGT00355	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2301	FGT00355	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	Subcon	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2302	FGT00356	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2303	FGT00356	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2304	FGT00356	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2305	FGT00356	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2306	FGT00356	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2307	FGT00356	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2308	FGT00357	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2309	FGT00357	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2310	FGT00357	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2311	FGT00357	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2312	FGT00358	Labor	L13 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2313	FGT00358	Labor	L13 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2314	FGT00358	Labor	L13 FILLING	FILLING	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2315	FGT00359	Labor	L13 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2316	FGT00359	Labor	L13 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2317	FGT00359	Labor	L13 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2318	FGT00362	Labor	L01 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2319	FGT00362	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2320	FGT00362	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2321	FGT00362	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2322	FGT00362	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2323	FGT00362	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2406	FGT00392	Labor	L01 MIXING	MIXING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2324	FGT00363	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2325	FGT00363	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2326	FGT00363	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2327	FGT00364	Labor	L12 FILLING	FILLING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2328	FGT00364	Labor	L12 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2329	FGT00364	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2330	FGT00366	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2331	FGT00366	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2332	FGT00366	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2333	FGT00366	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2334	FGT00366	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2335	FGT00366	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2336	FGT00369	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2337	FGT00369	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2338	FGT00369	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2339	FGT00370	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2340	FGT00370	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2341	FGT00370	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2342	FGT00371	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2343	FGT00371	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2344	FGT00371	Labor	L01 MILLING	MILLING	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2345	FGT00371	Labor	L01 TINTING	TINTING	DL	BM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2346	FGT00371	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2347	FGT00371	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2348	FGT00372	Labor	L01 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2349	FGT00372	Labor	L01 FILLING	FILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2350	FGT00372	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2351	FGT00374	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2352	FGT00374	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2353	FGT00374	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2354	FGT00375	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2355	FGT00375	Labor	L01 MIXING	MIXING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2356	FGT00375	Labor	L01 MILLING	MILLING	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2357	FGT00375	Labor	L01 LETDOWN	LETDOWN	DL	BM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2358	FGT00375	Labor	L01 TINTING	TINTING	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2359	FGT00375	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2360	FGT00375	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2361	FGT00376	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2362	FGT00376	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2363	FGT00376	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2364	FGT00376	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2365	FGT00376	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2366	FGT00377	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2367	FGT00377	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2368	FGT00377	Labor	L01 MILLING	MILLING	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2369	FGT00377	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2370	FGT00377	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2371	FGT00378	Labor	L01 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2372	FGT00378	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2373	FGT00378	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2374	FGT00378	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2375	FGT00379	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2376	FGT00379	Labor	L01 MIXING	MIXING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2377	FGT00379	Labor	L01 FILLING	FILLING	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2378	FGT00379	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2379	FGT00380	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2380	FGT00380	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2381	FGT00380	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2382	FGT00380	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2383	FGT00381	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2384	FGT00381	Labor	L01 FILLING	FILLING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2385	FGT00381	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2386	FGT00383	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2387	FGT00383	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2388	FGT00383	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2389	FGT00383	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2390	FGT00383	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2391	FGT00383	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2392	FGT00384	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2393	FGT00384	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2394	FGT00384	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2395	FGT00385	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2396	FGT00385	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2397	FGT00385	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2398	FGT00388	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2399	FGT00388	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2400	FGT00388	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2401	FGT00388	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2402	FGT00391	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2403	FGT00391	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2404	FGT00391	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2405	FGT00392	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2407	FGT00392	Labor	L01 MILLING	MILLING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2408	FGT00392	Labor	L01 LETDOWN	LETDOWN	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2409	FGT00392	Labor	L01 TINTING	TINTING	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2410	FGT00392	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2411	FGT00392	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2412	FGT00393	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2413	FGT00393	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2414	FGT00393	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2415	FGT00393	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2416	FGT00393	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2417	FGT00394	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2418	FGT00394	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2419	FGT00394	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2420	FGT00394	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2421	FGT00394	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2422	FGT00403	Labor	L01 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2423	FGT00403	Labor	L01 FILLING	FILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2424	FGT00403	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2425	FGT00404	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2426	FGT00404	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2427	FGT00404	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2428	FGT00428	Labor	L12 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2429	FGT00428	Labor	L12 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2430	FGT00428	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2431	FGT00429	Labor	L12 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2432	FGT00429	Labor	L12 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2433	FGT00429	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2434	FGT00432	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2435	FGT00432	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2436	FGT00432	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2437	FGT00432	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2438	FGT00459	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2439	FGT00459	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2440	FGT00459	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2441	FGT00460	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2442	FGT00460	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2443	FGT00460	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2444	FGT00460	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2445	FGT00460	Labor	L01 TINTING	TINTING	DL	BM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2446	FGT00460	Labor	L01 FILLING	FILLING	DL	BM	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2447	FGT00460	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2448	FGT00461	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2449	FGT00461	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2450	FGT00461	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2451	FGT00461	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2452	FGT00461	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2453	FGT00461	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2454	FGT00461	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2455	FGT00462	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2456	FGT00462	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2457	FGT00462	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2458	FGT00462	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2459	FGT00462	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2460	FGT00462	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2461	FGT00462	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2462	FGT00463	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2463	FGT00463	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2464	FGT00463	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2465	FGT00463	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2466	FGT00463	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2467	FGT00463	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2468	FGT00463	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2469	FGT00464	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2470	FGT00464	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2471	FGT00464	Labor	L01 MILLING	MILLING	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2472	FGT00464	Labor	L01 LETDOWN	LETDOWN	DL	BM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2473	FGT00464	Labor	L01 TINTING	TINTING	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2474	FGT00464	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2475	FGT00464	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2476	FGT00465	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2477	FGT00465	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2478	FGT00465	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2479	FGT00468	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2480	FGT00468	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2481	FGT00468	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2482	FGT00470	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2483	FGT00470	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2484	FGT00470	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2485	FGT00472	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2486	FGT00472	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2487	FGT00472	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2488	FGT00473	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2489	FGT00473	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2490	FGT00473	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2491	FGT00477	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2492	FGT00477	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2493	FGT00477	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2494	FGT00483	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2495	FGT00483	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2496	FGT00483	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2497	FGT00483	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2498	FGT00483	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2499	FGT00483	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2500	FGT00483	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2501	FGT00484	Labor	L01 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2502	FGT00484	Labor	L01 FILLING	FILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2503	FGT00484	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2504	FGT00485	Labor	L04B LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2505	FGT00485	Labor	L04B FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2506	FGT00485	Labor	L04B PACKING/PALLETI	PACKING/PALLETI	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2507	FGT00486	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2508	FGT00486	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2509	FGT00486	Labor	L01 LETDOWN	LETDOWN	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2510	FGT00486	Labor	L01 TINTING	TINTING	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2511	FGT00486	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2512	FGT00486	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2513	FGT00487	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2514	FGT00487	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2515	FGT00487	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2516	FGT00487	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2517	FGT00487	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2518	FGT00487	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2519	FGT00489	Labor	L01 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2520	FGT00489	Labor	L01 FILLING	FILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2521	FGT00489	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2522	FGT00498	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2523	FGT00498	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2524	FGT00498	Labor	L01 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2525	FGT00498	Labor	L01 FILLING	FILLING	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2526	FGT00498	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2527	FGT00499	Labor	L12 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2528	FGT00499	Labor	L12 FILLING	FILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2529	FGT00499	Labor	L12 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2530	FGT00502	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2531	FGT00502	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2532	FGT00502	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2533	FGT00502	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2534	FGT00502	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2535	FGT00502	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2536	FGT00502	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2537	FGT00504	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2538	FGT00504	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2539	FGT00504	Labor	L01 MILLING	MILLING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2540	FGT00504	Labor	L01 LETDOWN	LETDOWN	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2541	FGT00504	Labor	L01 TINTING	TINTING	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2542	FGT00504	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2543	FGT00504	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2544	FGT00507	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2545	FGT00507	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2546	FGT00507	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	Subcon	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2547	FGT00508	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2548	FGT00508	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2549	FGT00508	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2550	FGT00510	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2551	FGT00510	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2552	FGT00510	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2553	FGT00510	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2554	FGT00510	Labor	L01 TINTING	TINTING	DL	DL	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2555	FGT00510	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2556	FGT00510	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2557	FGT00511	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2558	FGT00511	Labor	L01 MIXING	MIXING	DL	BM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2559	FGT00511	Labor	L01 MILLING	MILLING	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2560	FGT00511	Labor	L01 LETDOWN	LETDOWN	DL	BM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2561	FGT00511	Labor	L01 TINTING	TINTING	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2562	FGT00511	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2563	FGT00511	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2564	FGT00514	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2565	FGT00514	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2566	FGT00514	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2567	FGT00515	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2568	FGT00515	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2569	FGT00515	Labor	L01 MILLING	MILLING	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2570	FGT00515	Labor	L01 LETDOWN	LETDOWN	DL	BM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2571	FGT00515	Labor	L01 TINTING	TINTING	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2572	FGT00515	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2573	FGT00515	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2574	FGT00516	Labor	L01 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2575	FGT00516	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2576	FGT00516	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2577	FGT00516	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2578	FGT00516	Labor	L01 TINTING	TINTING	DL	RM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2579	FGT00516	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2580	FGT00516	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2581	FGT00517	Labor	L01 LABELING/CODING	LABELING/CODING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2582	FGT00517	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2583	FGT00517	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2584	FGT00518	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2585	FGT00518	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2586	FGT00518	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2587	FGT00518	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2588	FGT00518	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2589	FGT00518	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2590	FGT00519	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2591	FGT00519	Labor	L01 FILLING	FILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2592	FGT00519	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2593	FGT00536	Labor	L14 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2594	FGT00536	Labor	L14 FILLING	FILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2595	FGT00536	Labor	L14 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2596	FGT00538	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2597	FGT00538	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2598	FGT00538	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2599	FGT00538	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2600	FGT00538	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2601	FGT00538	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2602	FGT00541	Labor	L01 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2603	FGT00541	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2604	FGT00541	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2605	FGT00541	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2606	FGT00541	Labor	L01 FILLING	FILLING	DL	RM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2607	FGT00541	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2608	FGT00543	Labor	L01 LABELING/CODING	LABELING/CODING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2609	FGT00543	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2610	FGT00543	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2611	FGT00543	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2612	FGT00543	Labor	L01 FILLING	FILLING	DL	RM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2613	FGT00543	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2614	FGT00545	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2615	FGT00545	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2616	FGT00545	Labor	L01 MILLING	MILLING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2617	FGT00545	Labor	L01 LETDOWN	LETDOWN	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2618	FGT00545	Labor	L01 TINTING	TINTING	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2619	FGT00545	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2620	FGT00545	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2621	FGT00547	Labor	L01 LABELING/CODING	LABELING/CODING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2622	FGT00547	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2623	FGT00547	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2624	FGT00547	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2625	FGT00547	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2626	FGT00547	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2627	FGT00549	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2628	FGT00549	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2629	FGT00549	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2630	FGT00549	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2631	FGT00549	Labor	L01 TINTING	TINTING	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2632	FGT00549	Labor	L01 FILLING	FILLING	DL	FOH	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2633	FGT00549	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2634	FGT00553	Labor	L01 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2635	FGT00553	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2636	FGT00553	Labor	L01 MILLING	MILLING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2637	FGT00553	Labor	L01 LETDOWN	LETDOWN	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2638	FGT00553	Labor	L01 TINTING	TINTING	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2639	FGT00553	Labor	L01 FILLING	FILLING	DL	RM	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2640	FGT00553	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N
2641	FGT00555	Labor	L01 LABELING/CODING	LABELING/CODING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2642	FGT00555	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2643	FGT00555	Labor	L01 MILLING	MILLING	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2644	FGT00555	Labor	L01 LETDOWN	LETDOWN	DL	PM	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2645	FGT00555	Labor	L01 FILLING	FILLING	DL	PM	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
2646	FGT00555	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	PM	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N
2647	GIP000005	Labor	L11 FILLING	FILLING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2648	GIP000005	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2649	GIP000041	Labor	L07 LABELING/CODING	LABELING/CODING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2650	GIP000041	Labor	L07 FILLING	FILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2651	GIP000049	Labor	L03 FILLING	FILLING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2652	GIP000049	Labor	L03 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2653	GIP000050	Labor	L11 FILLING	FILLING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2654	GIP000050	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2655	GIP000051	Labor	L11 FILLING	FILLING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2656	GIP000051	Labor	L11 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2657	GIP000053	Labor	L03 FILLING	FILLING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2658	GIP000053	Labor	L03 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2659	GIP000058	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2660	GIP000058	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2661	GIP000059	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2662	GIP000059	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2663	GIP000060	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2664	GIP000060	Labor	L01 MILLING	MILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2665	GIP000061	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2666	GIP000061	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2667	GIP000063	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2668	GIP000063	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2669	GIP000064	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2670	GIP000064	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2671	GIP000065	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2672	GIP000065	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2673	GIP000066	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2674	GIP000066	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2675	GIP000067	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2676	GIP000067	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2677	GIP000067	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2678	GIP000068	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2679	GIP000068	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2680	GIP000068	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2681	GIP000069	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2682	GIP000069	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2683	GIP000070	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2684	GIP000070	Labor	L01 MILLING	MILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2685	GIP000071	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2686	GIP000071	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2687	GIP000072	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2688	GIP000072	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2689	GIP000073	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2690	GIP000073	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2691	GIP000076	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2692	GIP000077	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2693	GIP000077	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2694	GIP000077	Labor	L01 LETDOWN	LETDOWN	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2695	GIP000078	Labor	L01 MIXING	MIXING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2696	GIP000078	Labor	L01 MILLING	MILLING	DL	PM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2697	GIP000078	Labor	L01 LETDOWN	LETDOWN	DL	PM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2698	GIP000081	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2699	GIP000081	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2700	GIP000085	Labor	L01 MIXING	MIXING	DL	PM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2701	GIP000085	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2702	GIP000085	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2703	GIP000086	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2704	GIP000086	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2705	GIP000086	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2706	GIP000087	Labor	L01 MIXING	MIXING	DL	FOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2707	GIP000087	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2708	GIP000087	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2709	GIP000088	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2710	GIP000088	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2711	GIP000088	Labor	L01 LETDOWN	LETDOWN	DL	BM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2712	GIP000095	Labor	L01 MIXING	MIXING	DL	BM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2713	GIP000095	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2714	GIP000096	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2715	GIP000096	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2716	GIP000097	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2717	GIP000097	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2718	GIP000107	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2719	GIP000108	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2720	GIP000108	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2721	GIP000109	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2722	GIP000115	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2723	GIP000115	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2724	GIP000116	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2725	GIP000116	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2726	GIP000116	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2727	GIP000117	Labor	L01 MIXING	MIXING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2728	GIP000117	Labor	L01 MILLING	MILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2729	GIP000129	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2730	GIP000129	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2731	GIP000129	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2732	GIP000130	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2733	GIP000130	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2734	GIP000130	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2735	GIP000143	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2736	GIP000143	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2737	GIP000143	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2738	GIP000147	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2739	GIP000147	Labor	L01 MILLING	MILLING	DL	FOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2740	GIP000147	Labor	L01 LETDOWN	LETDOWN	DL	DL	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2741	GIP000148	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2742	GIP000148	Labor	L01 MILLING	MILLING	DL	RM	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2743	GIP000148	Labor	L01 LETDOWN	LETDOWN	DL	RM	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2744	GIP000149	Labor	L01 MIXING	MIXING	DL	RM	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2745	GIP000149	Labor	L01 MILLING	MILLING	DL	DL	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2746	GIP000149	Labor	L01 LETDOWN	LETDOWN	DL	VOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2747	1KPH5A5J01	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2748	1KPH5A5J01	Labor	L01 FILLING	FILLING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2749	1KPH5A5J01	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2750	1KRT5A9A12	Labor	L01 LABELING/CODING	LABELING/CODING	DL	DL	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N
2751	1KRT5A9A12	Labor	L01 MIXING	MIXING	DL	VOH	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N
2752	1KRT5A9A12	Labor	L01 TINTING	TINTING	DL	FOH	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N
2753	1KRT5A9A12	Labor	L01 FILLING	FILLING	DL	DL	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N
2754	1KRT5A9A12	Labor	L01 PACKING/PALLETIZ	PACKING/PALLETIZ	DL	VOH	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: activity_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.activity_logs (id, logged_at, user_id, username, user_role, action, description, target_type, target_id, ip_address, extra) FROM stdin;
\.


--
-- Data for Name: line_activities; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.line_activities (id, production_line_code, activity_name, sort_order, stage) FROM stdin;
1	L01	MIXING	1	BM
2	L01	MILLING	2	BM
3	L01	LETDOWN	3	BM
4	L01	TINTING	4	BM
5	L01	CODING	5	FG
6	L01	LABELING	6	FG
7	L01	BOX PREPARATION	7	FG
8	L01	MANUAL TRANSFER BM TO FILLING TANK	8	BM
9	L01	FILLING	9	FG
10	L01	CAPPING	10	FG
11	L01	PACKING/PALLETIZING	11	FG
12	L02	STICKERING	1	FG
13	L02	CODING	2	FG
14	L02	FILLING	3	FG
15	L02	NOZZLE & CAPPING	4	FG
16	L02	CAP TIGHTENING	5	FG
17	L02	PLUNGERING	6	FG
18	L02	TWIST TIE	7	FG
19	L02	PACKING/PALLETIZING	8	FG
20	L03	FILLING	1	FG
21	L03	PACKING/PALLETIZING	2	FG
22	L03	TRANSFER TO SUBCON	3	FG
23	L04A	MIXING	1	BM
24	L04A	CODING	2	FG
25	L04A	BOX PREPARATION	3	FG
26	L04A	TRANSFER BM TO ARO PUMP	4	BM
27	L04A	SCOOPING	5	FG
28	L04A	FILLING	6	FG
29	L04A	PLUNGERING	7	FG
30	L04A	SEALING	8	FG
31	L04A	CAPPING	9	FG
32	L04A	PACKING/PALLETIZING	10	FG
33	L04B	MIXING	1	BM
34	L04B	CODING	2	FG
35	L04B	BOX PREPARATION	3	FG
36	L04B	TRANSFER BM TO ARO PUMP	4	BM
37	L04B	SCOOPING	5	FG
38	L04B	FILLING	6	FG
39	L04B	PLUNGERING	7	FG
40	L04B	SEALING	8	FG
41	L04B	CAPPING	9	FG
42	L04B	PACKING/PALLETIZING	10	FG
43	L04C	MIXING	1	BM
44	L04C	CODING	2	FG
45	L04C	BOX PREPARATION	3	FG
46	L04C	TRANSFER BM TO ARO PUMP	4	BM
47	L04C	SCOOPING	5	FG
48	L04C	FILLING	6	FG
49	L04C	PLUNGERING	7	FG
50	L04C	SEALING	8	FG
51	L04C	CAPPING	9	FG
52	L04C	PACKING/PALLETIZING	10	FG
53	L05	CUTTING	1	BM
54	L05	STICKERING	2	FG
55	L05	PACKING/PALLETIZING	3	FG
56	L06	MIXING	1	BM
57	L06	CODING	2	FG
58	L06	LABELING	3	FG
59	L06	BOX PREPARATION	4	FG
60	L06	TRANSFER OF BM TO ARO PUMP	5	BM
61	L06	FILLING	6	FG
62	L06	CAPPING	7	FG
63	L06	PACKING/PALLETIZING	8	FG
64	L07	MIXING	1	BM
65	L07	PRE HEAT OF BM	2	BM
66	L07	FILLING	3	FG
67	L07	PACKING/PALLETIZING	4	FG
68	L07	TRANSFER TO SUBCON	5	FG
69	L09	BEADS PRE EXPANSION	1	BM
70	L09	MOLDING	2	BM
71	L09	CUTTING	3	BM
72	L09A	BEADS PRE EXPANSION	1	BM
73	L09A	MOLDING	2	BM
74	L09A	CUTTING	3	BM
75	L10	CODING	1	FG
76	L10	LABELING	2	FG
77	L10	BOX PREPARATION	3	FG
78	L10	FILLING	4	FG
79	L10	CAPPING	5	FG
80	L10	PACKING/PALLETIZING	6	FG
81	L11	CODING	1	FG
82	L11	FILLING	2	FG
83	L11	SCOOPING	3	FG
84	L11	PLUNGERING	4	FG
85	L11	SEALING	5	FG
86	L11	STICKERING	6	FG
87	L11	PACKING/PALLETIZING	7	FG
88	L11	TRANSFER TO SUBCON	8	FG
89	L12	MIXING	1	BM
90	L12	MELTING	2	BM
91	L12	CODING	3	FG
92	L12	LABELING	4	FG
93	L12	BOX PREPARATION	5	FG
94	L12	MANUAL TRANSFER BM TO FILLING TANK	6	BM
95	L12	FILLING	7	FG
96	L12	CAPPING	8	FG
97	L12	SEALING	9	FG
98	L12	PLUNGERING	10	FG
99	L12	PACKING/PALLETIZING	11	FG
100	L13	MIXING	1	BM
101	L13	MELTING	2	BM
102	L13	CODING	3	FG
103	L13	LABELING	4	FG
104	L13	BOX PREPARATION	5	FG
105	L13	MANUAL TRANSFER BM TO FILLING TANK	6	BM
106	L13	FILLING	7	FG
107	L13	CAPPING	8	FG
108	L13	SEALING	9	FG
109	L13	PLUNGERING	10	FG
110	L13	PACKING/PALLETIZING	11	FG
111	L14	MIXING	1	BM
112	L14	SIEVING	2	BM
113	L14	CODING	3	FG
114	L14	LABELING	4	FG
115	L14	BOX PREPARATION	5	FG
116	L14	FILLING	6	FG
117	L14	CAPPING	7	FG
118	L14	SEALING	8	FG
119	L14	PACKING/PALLETIZING	9	FG
120	SIPS	BEADS PRE EXPANSION	1	BM
121	SIPS	MOLDING (BLOCK)	2	BM
122	SIPS	CUTTING (LAMINATE)	3	FG
123	SIPS	GLUING	4	FG
124	SIPS	PANEL ASSEMBLY	5	FG
125	L01	PACKING/PALLETIZ	12	\N
126	L01	NITROGEN PURGING	13	\N
127	L02	FILLING AND CAPP	9	\N
128	L03	PACKING/PALLETIZ	4	\N
129	L04B	LABELING/CODING	11	\N
130	L04B	SHRINKPACKING	12	\N
131	L04C	LABELING/CODING	11	\N
132	L05	FOILING	4	\N
133	L06	LABELING/CODING	9	\N
134	L06	SHRINKPACKING	10	\N
135	L07	LABELING/CODING	6	\N
136	L10	LABELING/CODING	7	\N
137	L10	PACKING/PALLETIZ	8	\N
138	L11	LABELING/CODING	9	\N
139	L11	PACKING/PALLETIZ	10	\N
141	L13	LABELING/CODING	12	\N
142	L13	PACKING/PALLETIZ	13	\N
144	L14	PACKING/PALLETIZ	10	\N
145	L14	LABELING/CODING	11	\N
140	L12	PAINTING OF DRUM	12	\N
143	L13	FILLING/STITCHIN	14	\N
146	Subcon	SUBCON	1	\N
147	L06	PACKING/PALLETIZ	11	\N
\.


--
-- Data for Name: pending_approvals; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pending_approvals (id, inventory_id, action, requested_by, status, payload, created_at, resolved_at, resolved_by) FROM stdin;
\.


--
-- Data for Name: product_revisions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_revisions (id, inventory_id, revision, snapshot, archived_by, archived_at) FROM stdin;
\.


--
-- Data for Name: production_lines; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.production_lines (production_line_code, production_line_name, canonical_line_text) FROM stdin;
LEGACY	Legacy line	\N
L01	Line 01 COATINGS	L01 - L1 COATINGS
L02	Line 02 CYANO BOTTLE FILLING	L02 - L2 CYANO BOTTLE FILLING
L03	Line 03 CYANO TUBE FILLING	\N
L04A	Line 04A ELASTO MIXING	L04A - L4A ELASTO MIXING
L04B	Line 04B SEMI AUTO FILLING	L04B - L4B SEMI AUTO FILLING
L04C	Line 04C AUTO FILLING	L04C - L4C ATO FILLING
L05	Line 05 EPOXY CLAY	\N
L06	Line 06 EPOXY LINE	L06 - L6 EPOXY LINE
L07	Line 07 EPOXY TUBE FILLING	\N
L09	Line 09 EPS - BLOCKS	L09 - L9 EPS - BLOCKS
L09A	Line 09A EPS - CUTTING	\N
L10	Line 10 CONTACT BOND	L10 - L10 CONTACT BOND
L11	Line 11 SILICONE FILLING LINE	L11 - L11 SILICONE FILLING LINE
L12	Line 12 SPECIAL PRODUCTS - EPOXY BASED	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED
L13	Line 13 SPECIAL PRODUCTS - WATER BASED	L13 - L13 SPECIAL PRODUCTS - WATER BASED
L14	Line 14 SKIM COAT	L14 - L14 SKIM COAT
SIPS	STRUCTURAL INSULATED PANEL	\N
Subcon	Subcon	\N
L08	Line08	\N
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.products (inventory_id, revision_descr, revision, notes, bm_production_line, bm_production_line_code, fg_production_line, fg_production_line_code, product_type, quantity, total_run_time, total_labor_min, total_mc_min, total_dl_units, total_dl, total_voh, total_foh, created_at, updated_at) FROM stdin;
1AF2202L	PG ANTI FOULING PAINT RED 4L	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1AF29233	PG ANTI FOULING PAINT RED 1L	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1APC2009	ALL PURPOSE EPOXY  GALLON	03	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1APC2010	ALL PURPOSE EPOXY  QUART	03	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1APC2012	ALL PURPOSE EPOXY  PINT	03	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1APC2016	ALL PURPOSE EPOXY 1/2 PINT	03	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1APC2019	ALL PURPOSE EPOXY 1/4 PINT	04	CRN RD25-CR019	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1APU5A5I04	PIOTHANE PU TOPCOAT RAL 5011 16L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1BBA6A1I01	BUILDERS BOND 25G SAMPLE	00	DOMESTIC	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1BBI9B14	TRANSITION TO PRINTED CARTRIDGE	03	PCMR-26-005	L04A - L4A ELASTO MIXING	L04A	L04A - L4A ELASTO MIXING	L04A	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1BBT3A9A01	BUILDERS BOND TURBO 260ML	02	CRN RD23-CR055	L02 - L2 CYANO BOTTLE FILLING	L02	L02 - L2 CYANO BOTTLE FILLING	L02	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1BCD4123	BASECOAT DRY MIX	01	PHASE 2 APM PACKAGE	L14 - L14 SKIM COAT	L14	L14 - L14 SKIM COAT	L14	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1BCR5A2Q01	BACKING COMPOUND EPOXY GRAY 20KG SET	03	CRN RD25-CR002	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1BGR612J	PPRO BARRICADE COUNTRY HOMES	01	CRN RD23-CR029	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1BSC9229	BUTTONSHIELD CLEAR	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1BWW434L	WATER-TITE 200 BARRICADE WHITE 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1BWW612J	WATER-TITE 200 BARRICADE WHITE 20L	02	CRN RD23-CR043	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1CB1304W	CONTACT BOND 45ML BOTTLE	02	CRN RD23-CR047	L10 - L10 CONTACT BOND	L10	L10 - L10 CONTACT BOND	L10	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1CB3325B	CYNO (100 CPS)50G W/ Label	03	CRN RD23-CR055	L02 - L2 CYANO BOTTLE FILLING	L02	L02 - L2 CYANO BOTTLE FILLING	L02	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1CB43260	CYNO (2 CPS) - 20G.	03	CRN RD23-CR055	L02 - L2 CYANO BOTTLE FILLING	L02	L02 - L2 CYANO BOTTLE FILLING	L02	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1CB5325B	CYNO (2 CPS) - 50G.	03	CRN RD23-CR055	L02 - L2 CYANO BOTTLE FILLING	L02	L02 - L2 CYANO BOTTLE FILLING	L02	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1CB6325B	CYNO (100 CPS) 50G NO Label	02	CRN RD23-CR055	L02 - L2 CYANO BOTTLE FILLING	L02	L02 - L2 CYANO BOTTLE FILLING	L02	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1CBE1A2H01	CONCRETE BINDER EPOXY 3.8KG SET	01	NO ISSUED CRN DUE TO NO TRANSACTION	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1CEC2009	CLEAR EPOXY GALLON	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1CEC2010	CLEAR EPOXY QUART	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1CEC2012	CLEAR EPOXY PINT	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1CHV1A5A01	INITIAL BOM-DOMESTIC (SAMPLE ONLY, NOT FOR COMMERCIAL SALE)	00	\N	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1CLC2009	PIONEER CONCRETE EPOXY LV GALLON	03	PCMR-25-001	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1CLC2010	PIONEER CONCRETE EPOXY LV QUART	03	PCMR-25-001	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1CLV1A5A01	INITIAL BOM-DOMESTIC (SAMPLE ONLY, NOT FOR COMMERCIAL SALE)	00	\N	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1COD1A1A01	CONCRETE DENSIFIER GALLON	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1CTA610N	SANDBLAST 621 (CAC 621)	01	PHASE 2 APM PACKAGE	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1DSC2009	DURASTEEL EPOXY GALLON	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1DSC2010	DURASTEEL EPOXY QUART	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1E2M2029	LITHOGRAPH CAN	02	PCMR-26-011	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1E2M2033	LITHOGRAPH CAN	02	PCMR-26-011	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1E2M2036	ELASTOSEAL 1/2L	02	CRN RD23-CR025	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1E2M204Q	ELASTOSEAL 1/4L	02	PHASE 2 APM PACKAGE	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1E2M5843	ELASTOSEAL PISIL	01	PHASE 2 APM PACKAGE	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1E3P5843	PROSEAL 111 ELASTOBOND 250G	03	PCMR-25-001	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1E3P5846	PROSEAL 111 ELASTOBOND 100G	03	PCMR-25-001	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1E3P929G	PROSEAL 111 ELASTOBOND 490G	03	PCMR-25-001	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1E3P929H	PROSEAL 111 ELASTOBOND 980G	03	PCMR-25-001	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EFC202L	EFC CLEAR	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EFG2009	EFC GRAY	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1ELB202L	PPRO EPOXY TANK LINING BLACK	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EMW202L	EFC MOONSTONE WHITE	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1ENC2009	NON-SAG EPOXY GALLON	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1ENC2010	NON-SAG EPOXY QUART	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1ENC2012	NON-SAG EPOXY PINT	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1ENC2016	NON-SAG EPOXY 1/2 PINT	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1ENC2019	NON-SAG EPOXY 1/4 PINT	03	CRN RD25-CR019	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPA202L	GF100 STD COLOR  GRAY 4L	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPB202L	GF100 SPL COLOR  BLACK  4L	02	CRN RD23-CR043	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPC202L	GF100 STD COLOR  CLEAR  4L	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPE1A5E22	EPOXY ENAMEL SATIN SIGNAL RED 4L	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPE1A5E23	EPOXY ENAMEL SATIN RD GREEN 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPE1A5E25	EPOXY ENAMEL SIGNAL VIOLET 4L	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPE1A5E28	EPOXY ENAMEL CHELSEA GREEN 4L	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPF1A1A01	GREAT FLOOR 200 GRAY GALLON	01	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPF1A5E02	GREAT FLOOR 300 OFF-WHITE 4L SET	01	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPG200G	EPOXY PRIMER GRAY 4L	04	CRN RD25-CR020	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPG202L	GF100 SPL COLOR  DARK GREEN	01	PHASE 2 APM PACKAGE -INACTIVE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPG5A2M01	EPOXY GROUT 12KG ABC SET	00	PCI	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPG9233	EPOXY PRIMER GRAY 1L	02	CRN RD25-CR020	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPI202L	GF100 SPL COLOR  ISUZU GREEN 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPK202L	GF100 SPL COLOR  COKE BEIGE 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPP202L	GF100 STD COLOR  WHITE 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPR200G	EPOXY PRIMER RED OXIDE 4L	03	CRN RD25-CR020	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPR2029	EPOXY PRIMER RED OXIDE 4L	03	CRN RD25-CR020	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPR2033	EPOXY PRIMER RED OXIDE 1L	03	CRN RD25-CR020	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPW200F	EPOXY PRIMER WHITE 1L	03	CRN RD25-CR020	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPW200G	EPOXY PRIMER WHITE 4L	03	CRN RD25-CR020	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1EPW202L	EPOXY PRIMER WHITE 4L	02	CRN RD25-CR020	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1ES16743	ELASTOSEAL PISILITO	01	PHASE 2 APM PACKAGE	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1ESG202L	GF100 SPL COLOR  SULPICIO GREEN 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1ETF6A1I01	ELASTOSEAL 25G SAMPLE	00	DOMESTIC	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1ETL202L	EPOXY TANK LINING WHITE 4L	04	CRN RD24-CR019	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1FBW612J	FIRESTOP WHITE	01	CRN RD23-CR040	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1FCB2009	PB FCBE - GALLON SET	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1FCB2012	PB FCBE - PINT SET	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1FCG480L	GF300 SPL COLOR  COOL GRAY 2C 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1FDB202L	GF200 SPL COLOR  DARK BLUE 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1FKG922L	GF300 SPL COLOR  KIWI GREEN 4L	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1FLG480L	GF300 STD COLOR  LIGHT GRAY	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1FLG9229	FLOORSHIELD STERLING GRAY	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1FMG480L	GF300 SPL COLOR  MINT GREEN 4L	01	CRN RD25-CR014	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1M2C2012	MARINE EPOXY PINT	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1FRP205S	FRP ADHESIVE 2K EPOXY	02	CRN RD25-CR028 (FOR REVIEW)	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1FSG922L	GF300 SPL COLOR  DARK GREEN 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1FTB922L	GF300 STD COLOR  BLUE 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1FTC202L	GF300 STD COLOR  RED 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1FTE922L	GF300 STD COLOR  BEIGE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1FTL922L	GF300 SPL COLOR  GREEN	02	CRN RD25-CR024	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1FTY202L	GF300 STD COLOR  YELLOW 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GAB202L	GF300 SPL COLOR  AQUA BLUE 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GAB8013	PAINTER'S BUDDY GAP SEALANT CARTRIDGE 480G	01	CONCESSION # 25-029 (TYC DELIVERY - NO REBOXING)	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GDF202L	GF200 SPL COLOR  FOREST GREEN 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GDG202L	GF200 SPL COLOR  SULPICIO GREEN 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GDW202L	GF200 SPL COLOR  DAWN GRAY 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GDW922L	GF300 SPL COLOR  DAWN GRAY 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GEG202L	GF200 SPL COLOR  LEAF GREEN 4L	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GF21A1A01	GF200 SPL COLOR PEBBLE GREY 4L	01	CRN RD25-CR013	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GF31A1A17	GF300 ALESON GREEN 4L SET	01	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GF31A5E01	GF300 SPL COLOR BLUE-GREEN 4L	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GFB922L	GF300 SPL COLOR  BLACK  4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GFG202L	GF200 SPL COLOR  SUMMERLAND GREEN 4L	01	PHASE 2 APM PACKAGE -INACTIVE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GFX202L	GF200 SPL COLOR  FLOORSPEX GREEN 4L	01	PHASE 2 APM PACKAGE -INACTIVE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GNG202L	GF300 SPL COLOR  NILE GREEN 4L	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GPB202L	GF200 STD COLOR  BLUE 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GPD202L	GF200 STD COLOR  DARK GRAY 4L	03	CRN RD24-CR017	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GPG202L	GF200 SPL COLOR  MINT GREEN 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GPH202L	GF200 SPL COLOR  LIGHT GREEN 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GPI202L	GF200 SPL COLOR  ISUZU GREEN 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GPK202L	GF200 STD COLOR  BEIGE 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GPL202L	GF200 STD COLOR  LIGHT GRAY 4L	03	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GPR202L	GF200 STD COLOR  RED 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GPW202L	GF200 STD COLOR  WHITE 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GPY202L	GF200 STD COLOR  YELLOW 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GSL202L	GF200 SPL COLOR  SLEX GREEN 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1GUB202L	GF200 STD COLOR  ULTRAMARINE BLUE 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1HVC2009	CONCRETE EPOXY HIGH VISCOSITY GALLON	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1HVC2010	CONCRETE EPOXY HIGH VISCOSITY QUART	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1IET1A2H01	INJECTABLE EPOXY TH 3.8KG SET	01	PCI - NO CRN DUE TO NO TRANSACTION	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1LSC5A9A01	LIQUID SKIMCOAT 4 KG	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1LVC2009	CONCRETE EPOXY LOW VISCOSITY GALLON	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1LVC2010	CONCRETE EPOXY LOW VISCOSITY QUART	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1LWG922L	GF300 SPL COLOR  LIWAYWAY GRAY 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1M101069	M. BOND 3 GMS.-WHITE UNPRINTED	01	PHASE 2 APM PACKAGE	L03 - L3 CYANO TUBE FILLING	L03	L03 - L3 CYANO TUBE FILLING	L03	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1M2C2009	MARINE EPOXY GALLON	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1M2C2010	MARINE EPOXY QUART	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PUC1A5E01	GREAT FLOOR 400 PU LIGHT GRAY	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1M2C2016	MARINE EPOXY 1/2 PINT	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1M2C2017	MARINE EPOXY 1/4 PINT	02	CRN RD25-CR019	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1MBN336B	MIGHTY BOND 10G BOTTLE	01	PHASE 2 APM PACKAGE	L02 - L2 CYANO BOTTLE FILLING	L02	L02 - L2 CYANO BOTTLE FILLING	L02	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1MGR3A3Z01	MIGHTY GASKET RED 300ML CRTG	00	0	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1MPV2009	511 MULTI PURPOSE EPOXY GALLON	03	PCMR-25-001	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1MPV2010	511 MULTI PURPOSE EPOXY QUART	03	PCMR-25-001	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1MPV2012	511 MULTI PURPOSE EPOXY PINT	03	PCMR-25-001	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1MPV2016	511 MULTI PURPOSE EPOXY 1/2 PT	03	PCMR-25-001	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1N1C2009	NON-SAG EPOXY GALLON	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1N1C2010	NON-SAG EPOXY QUART	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1N1C2012	NON-SAG EPOXY PINT	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1N1C2016	NON-SAG EPOXY 1/2 PINT	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1N1C2017	NON-SAG EPOXY 1/4 PINT	02	CRN RD25-CR019	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1OFX3A9A01	PIONEER PRO OMNIFIX 260ML	03	CRN RD24-CR026	L02 - L2 CYANO BOTTLE FILLING	L02	L02 - L2 CYANO BOTTLE FILLING	L02	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1OFX6A3U01	INITIAL BOM	00	\N	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1OFX6A3X01	INITIAL BOM	00	\N	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1P5C2009	PLUS FIVE EPOXY GALLON	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1P5C2010	PLUS FIVE EPOXY QUART	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PBA999J	PAINTER'S BUDDY GAP SEALANT  POUCH 100G	01	PHASE 2 APM PACKAGE	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PBB2008	PSBSI BUILDERS BOND GAL 3.8KG	01	PHASE 2 APM PACKAGE	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PBB999J	BUILDER'S BOND POUCH 100G	01	PHASE 2 APM PACKAGE	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PBB9B13	TRANSITION TO PRINTED CARTRIDGE	02	PCMR-26-005	L04A - L4A ELASTO MIXING	L04A	L04A - L4A ELASTO MIXING	L04A	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PBC9233	PEARL GLAZE GLOSS CATERPILLAR YELLOW 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PBD9233	PEARL GLAZE GLOSS DEEP GRAY 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PBI9229	PEARL GLAZE GLOSS SAFETY BLACK 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PBI9233	PEARL GLAZE GLOSS SAFETY BLACK 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PBL9229	PEARL GLAZE GLOSS SAFETY BLACK 4L	03	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PBL9233	PEARL GLAZE GLOSS SAFETY BLACK 1L	03	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PBS9229	PEARL GLAZE SATIN SAFETY BLUE 4L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PBS9233	PEARL GLAZE SATIN SAFETY BLUE 1L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PCT2009	PPRO COAL TAR EPOXY	03	CRN RD24-CR014	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PCW325A	CARPENTERS' WOODWORK 500ML	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PCW325B	WHITE GLUE 500ML BOTTLE	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PCY9229	PEARL GLAZE GLOSS CATERPILLAR YELLOW 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PEC9B5L	PPRO ELASTOSEAL CARTRIDGE -	01	PHASE 2 APM PACKAGE	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PER9229	EPOXY REDUCER 4L	03	CRN RD25-CR010	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PFG9229	PEARL GLAZE GLOSS FLANNEL GRAY 4L	02	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PFH612J	PSBSI POLYFLEX WHITE 20L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PFW612J	PIOFLEX WHITE - 20LTRS/PAIL	02	CRN RD23-CR043	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PGC9229	PEARL GLAZE GLOSS CATERPILLAR 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PGD9229	PEARL GLAZE GLOSS DEEP GRAY 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PGI920G	PEARL GLAZE GLOSS DARK GREEN 4L	02	CRN RD23-CR004	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PGO200F	PEARL GLAZE GLOSS ORANGE ET 300 1L	01	CRN RD23-CR056	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PGO200G	PEARL GLAZE GLOSS ORANGE ET 300 4L	01	CRN RD23-CR056	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PGS1A5D02	INITIAL BOM	00	\N	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PGS1A5E02	INITIAL BOM	00	\N	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PGS9229	PEARL GLAZE SATIN SAFETY GREEN 4L	02	CRN RD25-CR020	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PGS9233	PEARL GLAZE SATIN SAFETY GREEN 1L	02	CRN RD25-CR020	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PGT920G	PG GLOSS DARK GREEN 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PGW9229	PEARL GLAZE GLOSS WHITE 4L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PGW9233	PEARL GLAZE GLOSS WHITE 1L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PIB9229	PEARL GLAZE GLOSS SAFETY BLUE 4L	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PIB9233	PEARL GLAZE GLOSS SAFETY BLUE 1L	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PIF9233	PEARL GLAZE GLOSS FLANNEL GRAY 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PIG9229	PEARL GLAZE GLOSS SAFETY GREEN 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PIG9233	PEARL GLAZE GLOSS SAFETY GREEN 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PIO9229	PEARL GLAZE GLOSS SAFETY ORANGE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PIO9233	PEARL GLAZE GLOSS SAFETY ORANGE 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PIR9229	PEARL GLAZE GLOSS SAFETY RED 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PIR9233	PEARL GLAZE GLOSS SAFETY RED 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PIW9229	PEARL GLAZE GLOSS WHITE 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PIW9233	PEARL GLAZE GLOSS WHITE 1L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PIY9229	PEARL GLAZE GLOSS SAFETY YELLOW 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PIY9233	PEARL GLAZE GLOSS SAFETY YELLOW 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PJE2009	PIPE JOINTING EPOXY PUTTY GALLON	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PJE2010	PIPE JOINTING EPOXY PUTTY QUART	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PLS9229	PEARL GLAZE SATIN SAFETY BLACK 4L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PLS9233	PEARL GLAZE SATIN SAFETY BLACK 1L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1POS9229	PEARL GLAZE SATIN SAFETY ORANGE 4L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1POS9233	PEARL GLAZE SATIN SAFETY ORANGE 1L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PRS9229	PEARL GLAZE SATIN SAFETY RED 4L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PRS9233	PEARL GLAZE SATIN SAFETY RED 1L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PSB9229	PEARL GLAZE GLOSS SAFETY BLUE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PSB9233	PEARL GLAZE GLOSS SAFETY BLUE 1L	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PSC9229	PEARL GLAZE SATIN CATERPILLAR YELLOW 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PSC9233	PEARL GLAZE SATIN CATERPILLAR YELLOW 1L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PSC966D	PAINTER'S BUDDY SKIMCOAT GRAY	02	CRN RD24-CR027	L14 - L14 SKIM COAT	L14	L14 - L14 SKIM COAT	L14	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PSG9229	TO OPTIMIZE BATCHING	03	\N	L01 LABELING/CODING	L01	L01 LABELING/CODING	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PSG9233	PEARL GLAZE GLOSS SAFETY GREEN 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PSO9229	PEARL GLAZE GLOSS SAFETY ORANGE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PSO9233	PEARL GLAZE GLOSS SAFETY ORANGE 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PSR9229	PEARL GLAZE GLOSS SAFETY RED 4L	03	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PSR9233	PEARL GLAZE GLOSS SAFETY RED 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PSY9229	PEARL GLAZE GLOSS SAFETY YELLOW 4L	03	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PSY9233	PEARL GLAZE GLOSS SAFETY YELLOW 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PUB9229	PEARL GLAZE GLOSS ULTRAMARINE BLUE ET 501 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PUB9233	PEARL GLAZE GLOSS ULTRAMARINE BLUE ET 501 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PUG0000	FLEX-O-SEAL GUN 15"	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PUI920G	PEARL GLAZE GLOSS ULTRAMARINE BLUE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PUI930G	PEARL GLAZE GLOSS ULTRAMARINE BLUE 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PUS9229	PEARL GLAZE SATIN ULTRAMARINE BLUE 4L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PUS9233	PEARL GLAZE SATIN ULTRAMARINE BLUE 1L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PWS9229	PEARL GLAZE SATIN WHITE 4L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PWS9233	PEARL GLAZE SATIN WHITE 1L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PYS9229	PEARL GLAZE SATIN SAFETY YELLOW 4L	03	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1PYS9233	PEARL GLAZE SATIN SAFETY YELLOW 1L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1QDE1A5E41	QUICK DRY ENAMEL DELFT BLUE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1QDE1A5E42	QUICK DRY ENAMEL CHELSEA GREEN 4L	01	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1QDE1A5E43	QUICK DRY ENAMEL SEENSAM CREAM IVORY 3305 4L	01	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1QDE1A5E44	QUICK DRY ENAMEL BAGUIO GREEN 4L	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S010000	EPS P-TYPE 1.0-1 X 4 X 8	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S020000	EPS P-TYPE 1.0-2 X 4 X 8	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S025000	EPS P-TYPE 1.0-25 X 4 X 8	01	PHASE 2 APM PACKAGE	L09 - L9 EPS - BLOCKS	L09	L09 - L9 EPS - BLOCKS	L09	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S0A0000	EPS P-TYPE 1.0-1/2 X 4 X 8	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S0B0000	EPS P-TYPE 1.0-3/4 X 4 X 8	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S0C0000	EPS P-TYPE 1.0-1 1/2 X 4 X 8	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S110000	EPS F-TYPE 1.0-1 X 4 X 8	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S110204	EPS F-Type 1.0 - 1 x 2 x 4	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S120000	EPS F-TYPE 1.0-2 X 4 X 8	02	CRN RD25-CR032	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S140000	EPS F-TYPE 1.0-4 X 4 X 8	02	CRN RD25-CR032	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S1A0000	EPS F-TYPE 1.0-1/2 X 4 X 8	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S1C0000	EPS F-TYPE 1.0-1 1/2 X 4 X 8	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S1Z0000	EPS F-TYPE 1.0-25 X 4 X 8	03	CRN RD25-CR032	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S220000	EPS F-TYPE 1.5-2 X 4 X 8	00	0	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S240000	EPS F-TYPE 1.5-4 X 4 X 8	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S420000	EPS P-TYPE 1.5-2 X 4 X 8	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S430000	EPS P-TYPE 1.5-3 X 4 X 8	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S4C0000	EPS P-TYPE 1.5-1 1/2 X 4 X 8	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S4E0000	EPS P-TYPE 1.5-2 1/2 X 4 X 8	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S5A0000	EPS P-TYPE 2.0-1/2 X 4 X 8	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1S860000	EPS P-TYPE 1.5-25 X 4 X 8	01	PHASE 2 APM PACKAGE	L09 - L9 EPS - BLOCKS	L09	L09 - L9 EPS - BLOCKS	L09	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1SEC2009	STRUCTURAL EPOXY GALLON	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1SF00064	EPS F-TYPE 2.0 25" X 4' X 8'	02	CRN RD24-CR004	L09 - L9 EPS - BLOCKS	L09	L09 - L9 EPS - BLOCKS	L09	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1SF25000	EPS F-TYPE 1.5-25 X 4 X 8	02	CRN RD24-CR004	L09 - L9 EPS - BLOCKS	L09	L09 - L9 EPS - BLOCKS	L09	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1SF54000	EPS F-TYPE 2.0 2" X 4 X 8`	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1SF90001	EPS F-TYPE 1.5- 6" x 4' X 8'	00	PSBSI	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1ST20000	EPS F-TYPE 1.0-2" X 2` X 4`	02	CRN RD25-CR032	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1ST30000	EPS F-TYPE 1.0-3 X 2 X 4	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1ST40000	EPS F-TYPE 1.0 - 4 X 2 X 4	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2MCE201G	MULTI-FILLA 8.55KG	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1SUW202L	PSBSI SATURANT UNDERWATER	02	CRN RD25-CR018	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1TAD7723-IH	TILE ADHESIVE IN HOUSE	00	CRN RD24-CR027	L14 - L14 SKIM COAT	L14	L14 - L14 SKIM COAT	L14	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1VTS951W	VIETSEAL 123 - 300ML	03	PCMR-25-001	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1W205A5J03	WATER-TITE 200 BARRICADE LAVENDER BLUE 20L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1W205A5J04	WATER-TITE 200 BARRICADE RICH LILAC 20L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1W205A5J05	WATER-TITE 200 BARRICADE CAROLINA BLUE 20L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1W205A5J06	WATER-TITE 200 BARRICADE SLATE GRAY 20L	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1WEB9B13	WINDMILL E-BOND CONSTRUCTION	02	CRN RD23-CR055	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1WEC2009	WHITE EPOXY GALLON	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1WEC2010	WHITE EPOXY QUART	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1WEC2012	WHITE EPOXY PINT	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1WTE2396	WATER-TITE 101	01	PHASE 2 APM PACKAGE	L14 - L14 SKIM COAT	L14	L14 - L14 SKIM COAT	L14	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1WTE612J	WATER-TITE 201 PROFLEX	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1WTE920K	WATER-TITE 101	01	PHASE 2 APM PACKAGE	L14 - L14 SKIM COAT	L14	L14 - L14 SKIM COAT	L14	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1WTT572W	WATER-TITE 100 POUCH	00	0	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1WTT920K	WATER-TITE 100	01	PHASE 2 APM PACKAGE	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2AAM6107	ADHESIVE 76 (AAC101)	01	PHASE 2 APM PACKAGE	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2BCE0826	BACKING COMPOUND EPOXY - 10	02	CRN RD35-CR005	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2BPA434L	BONDCRETE 400	02	CRN RD25-CR021	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2BYG434L	PAINTERS BUDDY BARRICADE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2CAC6107	FINISHER 611	01	PHASE 2 APM PACKAGE	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2EPF4B2501	EPS F-TYPE 1.0 PCF 113MM X 4' X 8'	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2EPF4B6501	EPS F-TYPE 1.0  2" X  16" X 16"	00	0	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2EPF4B6601	F-Type D 1.0  1in X 8in X 40 in (25.4mm X 203mm X 1016mm)	00	0	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2EPF4B9A01	EPS F-TYPE 1.0 PCF 188MM X 4' X 8'	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2EPF4B9A02	EPS F-TYPE 1.0 PCF 88MM X 4' X 8'	01	PHASE 2 APM PACKAGE	L09A - L9A EPS - CUTTING	L09A	L09A - L9A EPS - CUTTING	L09A	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2EPF4B9A03	EPS F-TYPE D 1.0 50" x 4' X 8'	00	0	L09 - L9 EPS - BLOCKS	L09	L09 - L9 EPS - BLOCKS	L09	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2EPF4B9A04	EPS F-TYPE D 1.5  50" x 4' X 8'	00	0	L09 - L9 EPS - BLOCKS	L09	L09 - L9 EPS - BLOCKS	L09	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2FCW020K	WATER-TITE 102	01	PHASE 2 APM PACKAGE	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2FCW612J	WATER-TITE 103	01	PHASE 2 APM PACKAGE	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2FFC2009	FORMULA #5 GALLON	01	CRN RD25-CR028 (FOR REVIEW)	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2GDG202L	GF300 STD COLOR  DARK GRAY 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2GLG202L	GF100 SPL COLOR  GRAY SLEX PROJ 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2I7C2009	PRC7 LAMINATING EPOXY	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2IDC2009	JDJS - GALLON SET	03	CRN RD25-CR028 (FOR REVIEW)	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2ILC203W	LCRB INJECTABLE EPOXY 3.8KG	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2JFC2009	JF INJECTABLE EPOXY	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2JFC2010	JF INJECTABLE - QUART SET	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2JTC6130	PPRO PB JOINTING COMPOUND	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2MBC2009	MACRO BOND-EPOXY BINDER 7.4L	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2MLC201G	MELVEST LAM 45M EPOXY-GALLON	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2PBT9B13	PPRO POWERBOND - 300 ML.	01	PHASE 2 APM PACKAGE	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2PSE6109	PILE SPLICING EPOXY	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2TMC7001	TMC EPOXY VERSION 4 - DRUM SET	02	CRN RD25-CR028 (FOR REVIEW)	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
2UEB2009	UNDERWATER EPOXY PUTTY (BLACK)	02	CRN RD25-CR028 (FOR REVIEW)	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3AGS6A1O01	INITIAL BOM - PT PAI	00	\N	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3ANC3A9A01	INITIAL BOM	00	PT PAI	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3BBA3A3Z01	TRANSITION TO PRINTED CARTRIDGE	01	PCMR-26-005	L04A - L4A ELASTO MIXING	L04A	L04A - L4A ELASTO MIXING	L04A	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3BBA6A1O01	BUILDER'S BOND POUCH 100G	00	PT PAI	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3BC43B5E01	PPRO BONDCRETE 400 4L	00	PT PAI	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3CB11192	GIP-CONTACT BOND 15ML	02	CRN RD25-CR001	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3CB11193	GIP-CONTACT BOND 50ML	02	CRN RD25-CR001	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3CHV1A1A01	CONCRETE EPOXY HV GALLON	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3CHV1A2A01	CONCRETE EPOXY HV QUART	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3CLE1A1A01	INITIAL BOM	00	PT PAI	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3CLP1A3A01	CLEAR MULTIPURPOSE EPOXY 1.6KG SET QUART	01	CRN RD23-CR055	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3CLP1A4A01	CLEAR MULTIPURPOSE EPOXY 350G SET 1/2 PINT	01	CRN RD23-CR055	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3CLP1A5A01	CLEAR MULTIPURPOSE EPOXY 195G SET 1/4 PINT	01	CRN RD25-CR019	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3CLV1A1A01	CONCRETE EPOXY LV GALLON	02	CRN RD23-CR055	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3CLV1A2A01	CONCRETE EPOXY LV QUART	02	CRN RD23-CR055	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3CY13B1M01	CYNO (100 CPS)50G W/ LABEL	00	PT PAI	L02 - L2 CYANO BOTTLE FILLING	L02	L02 - L2 CYANO BOTTLE FILLING	L02	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3CY23B1H01	CYNO (2 CPS) - 20G.	00	PT PAI	L02 - L2 CYANO BOTTLE FILLING	L02	L02 - L2 CYANO BOTTLE FILLING	L02	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3CY23B1M01	CYNO (2 CPS) - 50G.	00	PT PAI	L02 - L2 CYANO BOTTLE FILLING	L02	L02 - L2 CYANO BOTTLE FILLING	L02	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3D5F1B1G01	DURASTEEL FIVE EPOXY 15G TUBE STRIP	SC00	_	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3D5F1B1L01	DURASTEEL FIVE EPOXY 35G TUBE	SC00	_	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3DFA1354	GIP-DURASTEEL 5 35G A NP	01	PHASE 2 APM PACKAGE	L07 - L7 EPOXY TUBE FILLING	L07	L07 - L7 EPOXY TUBE FILLING	L07	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3DFA1462	GIP-DURASTEEL 5 15G A NP	01	PHASE 2 APM PACKAGE	L07 - L7 EPOXY TUBE FILLING	L07	L07 - L7 EPOXY TUBE FILLING	L07	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3DFB1354	GIP-DURASTEEL 5 35G B NP	01	PHASE 2 APM PACKAGE	L07 - L7 EPOXY TUBE FILLING	L07	L07 - L7 EPOXY TUBE FILLING	L07	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3DFB1462	GIP-DURASTEEL 5 15G B NP	01	PHASE 2 APM PACKAGE	L07 - L7 EPOXY TUBE FILLING	L07	L07 - L7 EPOXY TUBE FILLING	L07	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3ECP003N	GIP-EPOXYCLAY ALL PURPOSE 3"	01	PHASE 2 APM PACKAGE	L05 - L5 EPOXY CLAY	L05	L05 - L5 EPOXY CLAY	L05	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3EPA1354	GIP-ALL PURPOSE 35G A NP	01	PHASE 2 APM PACKAGE	L07 - L7 EPOXY TUBE FILLING	L07	L07 - L7 EPOXY TUBE FILLING	L07	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3EPB1354	GIP-ALL PURPOSE 35G B NP	01	PHASE 2 APM PACKAGE	L07 - L7 EPOXY TUBE FILLING	L07	L07 - L7 EPOXY TUBE FILLING	L07	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3ESC6A3U01	INITIAL BOM - PT PAI	00	\N	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3ESC6A3X01	INITIAL BOM - PT PAI	00	\N	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3ETF6A1N01	ELASTOSEAL PISILITO	00	PT PAI	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3ETF6A1T01	ELASTOSEAL PISIL	00	PT PAI	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3GBT0001	BM-GF 200 BLUE TINT KG	01	CRN RD23-CR040	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3GBT0002	BM-GF 200 BLACK TINT KG	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3GBT702K	BM-GF 100 BLACK TINT DRUM	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3GGE1049	GIP-MIGHTY GASKET GREY 85G	01	PHASE 2 APM PACKAGE	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3GGT0005	BM-GF 200 GREEN TINT KG	02	CRN RD23-CR018	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000165	BM - PG GLOSS IMG ORANGE PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3GYO0004	BM-GF 200 YELLOW OXIDE TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3GYT0003	BM-GF 200 YELLOW TINT KG	01	CRN RD23-CR043	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3IET1A2H01	INJECTABLE EPOXY TH 3.8KG SET	00	PT PAI	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MB41169	GIP-M.BOND 3G FLAG TYPE	01	PHASE 2 APM PACKAGE	L03 - L3 CYANO TUBE FILLING	L03	L03 - L3 CYANO TUBE FILLING	L03	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MBA1B1C01	INITIAL  BOM	00	PT PAI	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MBH1B1C01	MIGHTY BOND SHOES 3G	SC00	_	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MBR1B1C01	MIGHTY BOND 3G FLAG TYPE	SC00	_	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MBS0000	GIP-MIGHTY BOND SHOT 1GM W/O	01	PHASE 2 APM PACKAGE	L03 - L3 CYANO TUBE FILLING	L03	L03 - L3 CYANO TUBE FILLING	L03	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MBX109D	GIP-MIGHTY BOND XTREME 3G	01	PHASE 2 APM PACKAGE	L03 - L3 CYANO TUBE FILLING	L03	L03 - L3 CYANO TUBE FILLING	L03	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MBX1B1C01	MIGHTY BOND XTREME 3G	SC00	_	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MFS6000	BM-MODAFLOW RESIN SOLUTION	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MGB163M	GIP-MIGHTY GASKET BLACK 30G	01	PHASE 2 APM PACKAGE	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MGB1B1N01	MIGHTY GASKET BLACK 30G	SC01	CRN RD23-CR055	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MGB1B1N02	PIONEER MIGHTY GASKET BLACK 85G	SC00	_	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MGB9449	GIP-MIGHTY GASKET BLACK 85G	01	PHASE 2 APM PACKAGE	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MGG163M	GIP-MIGHTY GASKET GREY 30G	01	PHASE 2 APM PACKAGE	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MGR163M	GIP-MIGHTY GASKET RED 30G	01	PHASE 2 APM PACKAGE	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MGR1B1N01	MIGHTY GASKET RED 85G	SC01	CRN RD23-CR055	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MGR1B1N02	MIGHTY GASKET RED 30G	SC01	CRN RD23-CR055	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MGR9449	GIP-MIGHTY GASKET RED 85G	01	PHASE 2 APM PACKAGE	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MNC1049	GIP-MIGHTY SEAL CLEAR 85G	01	PHASE 2 APM PACKAGE	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MR0337C	GIP-MIGHTY REMOVER 7.5ML	01	PHASE 2 APM PACKAGE	L03 - L3 CYANO TUBE FILLING	L03	L03 - L3 CYANO TUBE FILLING	L03	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MSM1A1A01	MAESTRO MARINE EPOXY GALLON	03	CRN RD23-CR053_PT PAI	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MSM1A2A01	MAESTRO MARINE EPOXY QUART	03	CRN RD23-CR053_PT PAI	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MSM1A3A01	MAESTRO MARINE EPOXY PINT	03	CRN RD23-CR053_PT PAI	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MSM1A4A01	MAESTRO MARINE EPOXY 1/2 PINT	03	CRN RD23-CR053_PT PAI	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MSM1A5A01	MAESTRO MARINE EPOXY 1/4 PINT	04	CRN RD25-CR019	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3MSW105B	GIP-MIGHTY SEAL WINDSCREEN &	01	PHASE 2 APM PACKAGE	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3P5A1362	GIP-PLUS 5 CLEAR 15G A NP	01	PHASE 2 APM PACKAGE	L07 - L7 EPOXY TUBE FILLING	L07	L07 - L7 EPOXY TUBE FILLING	L07	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3P5A1473	GIP-PLUS 5 CLEAR 6G A NP	01	PHASE 2 APM PACKAGE	L07 - L7 EPOXY TUBE FILLING	L07	L07 - L7 EPOXY TUBE FILLING	L07	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3P5B1362	GIP-PLUS 5 CLEAR 15G B NP	01	PHASE 2 APM PACKAGE	L07 - L7 EPOXY TUBE FILLING	L07	L07 - L7 EPOXY TUBE FILLING	L07	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3P5B1473	GIP-PLUS 5 CLEAR 6G B NP	01	PHASE 2 APM PACKAGE	L07 - L7 EPOXY TUBE FILLING	L07	L07 - L7 EPOXY TUBE FILLING	L07	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PEA002T	GIP-EPOXYCLAY AQUA 1.5"	01	PHASE 2 APM PACKAGE	L05 - L5 EPOXY CLAY	L05	L05 - L5 EPOXY CLAY	L05	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PEA003N	GIP-EPOXYCLAY AQUA 3"	01	PHASE 2 APM PACKAGE	L05 - L5 EPOXY CLAY	L05	L05 - L5 EPOXY CLAY	L05	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PER7000	BM-EPOXY REDUCER KG	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PES002T	GIP-EPOXYCLAY STEEL 1.5"	01	PHASE 2 APM PACKAGE	L05 - L5 EPOXY CLAY	L05	L05 - L5 EPOXY CLAY	L05	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PES003N	GIP-EPOXYCLAY STEEL 3"	01	PHASE 2 APM PACKAGE	L05 - L5 EPOXY CLAY	L05	L05 - L5 EPOXY CLAY	L05	Other / Intermediate	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PGE7000	BM-PG GLOSS TINT YELLOW OXIDE	02	CRN RD23-CR040	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PGG1A5D21	PG GLOSS LEAF GREEN 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PGG1A5D25	PEARL GLAZE GLOSS DEEP GRAY 1L	00	PT PAI	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PGG1A5D26	PEARL GLAZE GLOSS CATERPILLAR YELLOW 1L	00	PT PAI	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PGG1A5E23	PG GLOSS LEAF GREEN 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PGG1A5E25	PEARL GLAZE GLOSS DEEP GRAY 4L	00	PT PAI	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PGG1A5E26	PEARL GLAZE GLOSS CATERPILLAR YELLOW 4L	00	PT PAI	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PGK7000	BM-PG GLOSS TINT BLACK	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PGO7000	BM-PG GLOSS TINT ORANGE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PGR7000	BM-PG GLOSS TINT RED	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PGY7000	BM-PG GLOSS TINT YELLOW KG	02	CRN RD23-CR040	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3PJP1A4A01	PPRO PIPE JOINTING EPOXY PUTTY	00	PT PAI	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3RC11A3W01	RC1 LUBRICATING SPRAY 100ML	00	PT PAI	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3SUE1A2G01	INITIAL BOM	00	PT PAI	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3W101A2J01	WATERTITE 100 4.54 KG	02	CRN RD23-CR055	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3W106A1R01	WATERTITE 100 200G POUCH	02	CRN RD23-CR055	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3W415A2Q01	WATER-TITE 401 PU PLUS 20KG PAIL	00	PT PAI	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3W415A9A01	WATER-TITE 401 PU PLUS 4 KG	03	CRN RD23-CR055	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3WDG5A2B01	PIONEER WOOD GLUE D3 500G	00	PT PAI	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3WDG5A2L01	WOOD GLUE 10KG	00	PT PAI	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3WPF5A5E01	WATER-TITE POWERFLEX 4L	00	PT PAI	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
3WPF5A5I01	INITIAL BOM - PT PAI	00	\N	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
4BBA4A8A01	BUILDERS BOND INDIA 180L	00	1. TEMPORARY ARRANGEMENT ONLY\n2. STEEL DRUM OPEN TYPE 200L NOT PART OF THE BOM (Recycled drum to be used, ex. Silicone Drum)	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
4BRB2A9A01	BUILDERS BOND RESIN BLEND 20 KGS	00	PAPL	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
4ERB2A9A01	ELASTOSEAL RESIN BLEND 20 KGS	00	PAPL	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
4ETF4A8A01	ELASTOSEAL INDIA 180L	00	1. TEMPORARY ARRANGEMENT ONLY\n2. STEEL DRUM OPEN TYPE 200L NOT PART OF THE BOM (Recycled drum to be used, ex. Silicone Drum)	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
4ETF6A1I01	ELASTOSEAL 25G SAMPLE	00	PAPL	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
4WPF5A5E01	WATER-TITE POWERFLEX 4L	00	PAPL	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
4WPF5A5I01	WATER-TITE POWERFLEX 16L	00	PAPL	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5APE1A1A01	ALL PURPOSE EPOXY GALLON_ING TAT MALAYSIA	01	\N	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5APE1A1L01	ALL PURPOSE EPOXY TUBE 35G	SC00	ING TAT	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5APE1A2A01	ALL PURPOSE EPOXY QUART_ING TAT MALAYSIA	01	\N	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5APE1A3A01	ALL PURPOSE EPOXY PINT_ING TAT MALAYSIA	02	\N	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5APE1A4A01	ALL PURPOSE EPOXY 1/2 PINT_ING TAT MALAYSIA	02	\N	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5APE1A5A01	ALL PURPOSE EPOXY 1/4 PINT_ING TAT MALAYSIA	02	\N	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5BBA6A1O01	BUILDERS BOND 100G	00	PACIFIC INTERNATIONAL-IMG	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5CBA1B3S01	CONTACT BOND-50 ML BLISTERED	SC00	PACIFIC INTERNATIONAL-IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5D5F1B1L01	EPOXYTUBE-DURASTEEL FIVE 35G	SC00	PACIFIC INTERNATIONAL-IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5D5F8A1G01	DURASTEEL FIVE STRIP 15G	SC00	PACIFIC INTERNATIONAL-IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5ECA7A7B01	EPOXYCLAY AQUA - 1.5"	SC00	PACIFIC INTERNATIONAL-IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5ECA7A7C01	EPOXYCLAY AQUA 3"	SC00	PACIFIC INTERNATIONAL-IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5ECP7A1M01	PIONEER EPOXY CLAY ALL PURPOSE 3"	SC00	INGTAT	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5ECS7A1M01	PIONEER EPOXY CLAY STEEL 3"	SC00	INGTAT	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5ECS7A7B01	EPOXYCLAY STEEL 1.5"	SC00	PACIFIC INTERNATIONAL-IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5EPP1A5E01	EPOXY PRIMER GRAY 4 LITERS	00	IMG	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5ESC3A3Z01	ELASTOSEAL CLEAR 300ML	00	PACIFIC INTERNATIONAL-IMG	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5ESC6A3U01	ELASTOSEAL CLEAR 65ML	00	PACIFIC INTERNATIONAL-IMG	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5ESC6A3X01	ELASTOSEAL CLEAR 185ML	00	PACIFIC INTERNATIONAL-IMG	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5ESP1A5E01	EPOXY STEEL PRIMER GRAY 4L	00	IMG	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5ETF1A5B01	PPRO ELASTOSEAL 1/4 LITER	00	PACIFIC INTERNATIONAL-IMG	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5ETF1A5C01	PPRO ELASTOSEAL 1/2 LITER	00	PACIFIC INTERNATIONAL-IMG	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5ETF1A5D01	PPRO ELASTOSEAL 1 LITER	00	PACIFIC INTERNATIONAL-IMG	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5ETF1A5E01	PPRO ELASTOSEAL 4 LITER	00	PACIFIC INTERNATIONAL-IMG	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5ETF3A3Z01	PPRO ELASTOSEAL 300ML X 24	00	PACIFIC INTERNATIONAL-IMG	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5ETF6A1O01	PIONEER ELASTOSEAL 100GMS	00	PACIFIC INTERNATIONAL-IMG	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5ETF6A1T01	PPRO ELASTOSEAL PISIL - 250G	00	PACIFIC INTERNATIONAL-IMG	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MAE1A1A01	MARINE EPOXY-GALLON SET	00	PACIFIC INTERNATIONAL-IMG	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MAE1A2A01	MARINE EPOXY - QUART SET	00	PACIFIC INTERNATIONAL-IMG	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MAE1A3A01	MARINE EPOXY - PINT SET	00	PACIFIC INTERNATIONAL-IMG	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MAE1A4A01	MARINE EPOXY - 1/2 PINT SET	00	PACIFIC INTERNATIONAL-IMG	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MAE1A5A01	MARINE EPOXY - 1/4 PINT SET	01	CRN RD25-CR019	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MBH1B1C01	MIGHTY BOND SHOES 3G	SC00	PACIFIC INTERNATIONAL-IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MBR1B1C01	PIONEER MIGHTY BOND 3G	SC00	PACIFIC INTERNATIONAL-IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MBR8A1C01	M. BOND - STRIP, 5 X 3 GMS.	SC00	PACIFIC INTERNATIONAL-IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MBX1B1C01	MIGHTY BOND XTREME 3G	SC00	PACIFIC INTERNATIONAL-IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MGB1B1K01	MIGHTY GASKET BLACK 30G	SC00	IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MGB1B1N01	MIGHTY GASKET BLACK - 85G	SC00	PACIFIC INTERNATIONAL-IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MGG1B1G01	PIONEER AUTOMOTO-MIGHTY GASKET GREY15G	00	IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MGG1B1K01	PIONEER AUTOMOTO-MIGHTY GASKET GREY 30 G	SC00	IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MGG1B1N01	PIONEER MIGHTY GASKET GREY 85G	SC00	IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MGR1B1K01	MIGHTY GASKET RED 30G	SC00	IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MGR1B1N01	MIGHTY GASKET RED - 85G	SC00	PACIFIC INTERNATIONAL-IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MSB3A3Z01	MIGHTY SEAL BIOCIDE CLEAR 300 ML	00	PACIFIC INTERNATIONAL-IMG	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MSG1B1N01	MIGHTY SEAL TRANSLUCENT 85G	SC00	PACIFIC INTERNATIONAL-IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MSM1A1A01	MAESTRO EPOXY 1 YEAR GALLON	00	PACIFIC INTERNATIONAL-IMG	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MSM1A2A01	MAESTRO EPOXY 1YEAR QUART	00	PACIFIC INTERNATIONAL-IMG	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MSM1A3A01	MAESTRO EPOXY 1 YEAR PINT	00	PACIFIC INTERNATIONAL-IMG	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MSM1A4A01	MAESTRO EPOXY 1 YEAR 1/2 PINT	00	PACIFIC INTERNATIONAL-IMG	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5MSM1A5A01	MAESTRO EPOXY 1 YEAR 1/4 PINT	01	CRN RD25-CR019	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5NSE1A1A01	PIONEER NON-SAG EPOXY GALLON	00	ING TAT	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5NSE1A2A01	PIONEER NON-SAG EPOXY QUART	00	ING TAT	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5NSE1A3A01	PIONEER NON-SAG EPOXY PINT	00	ING TAT	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5NSE1A4A01	PIONEER NON-SAG EPOXY 1/2 PINT	00	ING TAT	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5NSE1A5A01	PIONEER NON-SAG EPOXY 1/4 PINT	00	ING TAT	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5P5E1B1G01	PLUS FIVE EPOXY - TUBES 15 GMS	SC00	PACIFIC INTERNATIONAL-IMG	SUBCON - SUBCON	Subcon	SUBCON - SUBCON	Subcon	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5PGG1A5D01	PEARL GLAZE GLOSS FLANNEL GRAY 1L	00	DIREX-IMG	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5PGG1A5E01	PEARL GLAZE GLOSS FLANNEL GRAY 4LITERS	00	IMG	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5RC11A3W01	RC1 LUBRICATING SPRAY 100ML	00	IMG	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
5WDG3B2B01	PIONEER WOOD GLUE 500G BOTTLE	00	PACIFIC INTERNATIONAL	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
6BBT3A9A01	UNLABELED HYBRID CONSTRUCTION ADHESIVE 260ML	01	CRN RD23-CR055	L02 - L2 CYANO BOTTLE FILLING	L02	L02 - L2 CYANO BOTTLE FILLING	L02	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B10000001	BULKMIX - FORMULA #5 B	00	FOR REVIEW	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000166	BM - PG SATIN SAFETY GREEN PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B10000002	BULKMIX -  FRP A	00	FOR REVIEW	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B10000003	BULKMIX -  JDJS A	00	FOR REVIEW	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B10000004	BULKMIX -  JDJS B	00	FOR REVIEW	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B10000005	BULKMIX -  SATURANT UNDERWATER EPOXY B	00	0	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B10000006	BULKMIX -  TMC EPOXY VERSION 4 A	00	FOR REVIEW	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B10000007	BULKMIX - TMC EPOXY VERSION 4 B	00	FOR REVIEW	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B10000008	BULKMIX -  TRANSFORMER ADHESIVE A	00	FOR REVIEW	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B10000009	BULKMIX -  TRANSFORMER ADHESIVE B	00	FOR REVIEW	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B10000010	BULKMIX -  UNDERWATER EPOXY PUTTY (BLACK) A	00	FOR REVIEW	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B35000001	BM - WEARING COMPOUND COMBI A	00	0	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B35000002	BM - WEARING COMPOUND COMBI B	00	0	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B35000003	BULKMIX BACKING COMPOUND HEAVY DUTY A	00	CRN RD23-CR024	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B35000004	BULKMIX BACKING COMPOUND HEAVY DUTY B	00	CRN RD23-CR024	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B35000005	BULKMIX BACKING COMPOUND STANDARD A	00	RD23-CR024 -FROM EXPLODED TO BMs	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B35000006	BULKMIX BACKING COMPOUND STANDARD B	00	RD23-CR024 -FROM EXPLODED TO BMs	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B35000007	BULKMIX- BUILDERS BOND RESIN BLEND	01	CRN RD24-CR030	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B35000008	BULKMIX- ELASTOSEAL INDIA RESIN BLEND	01	CRN RD24-CR030	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B50000013	BULKMIX - WATERTITE 401	00	CRN RD23-CR022	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B50000014	BULKMIX BONDCRETE 400	00	0	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000025	BULKMIX QUICK DRY ENAMEL SEENSAM CREAM IVORY  3305	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000053	BULKMIX QDE SILVER GREY	00	REPROCESS	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000059	BM - PG GLOSS SAFETY BLUE PART A	02	CRN RD22-CR038	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000071	BULKMIX GF 200 GATEWAY GRAY PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000085	BULKMIX - EPOXY ENAMEL SIGNAL VIOLET	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000093	BM - PG ANTI FOULING PAINT RED PART A	00	FOR REVIEW	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000106	BM - EFC/GF100 (MOONSTONE) WHITE PART A	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000115	BM - GF 200 PART B	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000116	BM - EPOXY PRIMER RED OXIDE PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000122	BM - BARRICADE PANTONE 7686U	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000125	INITIAL BOM	00	CRN RD25-CR035	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000131	BM - GF 300 GREEN PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000144	BM - GF 200 DARK GREY PART A	01	CRN RD25-CR008	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000149	BM - GF 200 LIGHT GREY PART A	00	FOR REVIEW	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000151	BM - GF 200 WHITE PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000156	BM - PG GLOSS CATEPILLAR YELLOW PART A	02	PT PAI	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000157	BM - PG GLOSS DEEP GRAY PART A	00	PT PAI	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000158	BM - PG GLOSS SAFETY BLACK PART A	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000159	BM - PG SATIN SAFETY BLUE PART A	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000160	BM - COAL TAR EPOXY PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000161	BM - PG GLOSS FLANNEL GRAY PART A	00	IMG	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000164	BM - BARRICADE PANTONE 284U	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000167	BM - PG GLOSS WHITE PART A	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000168	BM - PG GLOSS SAFETY YELLOW PART A	00	FOR REVIEW	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000169	BM - PG SATIN SAFETY BLACK PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000170	BM - PG SATIN SAFETY ORANGE PART A	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000171	BM - PG SATIN SAFETY RED PART A	00	FOR REVIEW	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000174	INITIAL BOM	00	RELATED TO PCMR-26-008	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000176	BM - PG GLOSS SAFETY ORANGE PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000177	BM - PG GLOSS SAFETY RED PART A	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000178	BM - PG GLOSS ULTRAMARINE BLUE PART A	00	PT PAI	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000179	BM - PG SATIN ULTRAMARINE BLUE PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000180	BM - PG SATIN WHITE PART A	00	FOR REVIEW	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000181	BM - PG SATIN SAFETY YELLOW PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000183	BM - BARRICADE EGGSHELL WHITE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000190	BM - GF 300 WHITE PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000197	BM - PG SATIN NILE GREEN PART A	00	FOR REVIEW	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000198	BM - BARRICADE PANTONE 535U	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000199	BM - PG SATIN VISMIN ORANGE PART A	00	FOR REVIEW	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000200	BM - PG SATIN VM ULTRAMARINE BLUE PART A	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000203	BM - PG SATIN NANCY GRAY PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000213	BM - PIOPOXY STEEL PRIME PART B	00	CRN RD24-CR001	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000214	BM - PIOPOXY STEEL PRIME GREY PART A	00	CRN RD24-CR001	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000217	BM - PIOPOXY MASTIC RED PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000223	BULKMIX QDE CHELSEA GREEN	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000224	BULKMIX EPOXY ENAMEL CHELSEA GREEN	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000227	BM - QDE SURF GRAY	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000230	BM - EPOXY ENAMEL INTL ORANGE PART A	00	INITIAL	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000232	BM - EPOXY ENAMEL PIO NILE GREEN PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000234	BM - EPOXY ENAMEL STN DECK GREEN PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000249	BM - ACRYLIC WHITE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000250	BM - QDE DELFT BLUE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000251	BULKMIX - GREATFLOOR 300 ALESON GREEN PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000253	BULKMIX GF 300 OFF-WHITE PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000254	BULKMIX  AF TIE COAT PART B	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000255	BULKMIX QUICK DRY ENAMEL BAGUIO GREEN	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000269	BULKMIX COAL TAR EPOXY BLACK PART B	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000270	BULKMIX _GF 300 BLUE GREEN_PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000272	BULKMIX  WATER-TITE 200 BARRICADE SLATE GRAY	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000275	BULKMIX  AF TIE COAT LIGHT GRAY PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000276	BM- GF 200 SPL. COLOR PEBBLE GREY PART A	01	CRN RD25-CR013	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000277	BM- GF 200 SPL. COLOR PEBBLE GREY PART B	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000278	BM - GF 300 SPL. COLOR MINT GREEN PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000280	BM- PU FLOORING LIGHT GRAY PART A	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B60000293	INITIAL BOM	00	\N	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B65000001	BULKMIX WATER-TITE 400	00	0	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
B65000002	BULKMIX -  PU ADHESIVE	00	FOR REVIEW	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000003	BULK MIX - MAESTRO EPOXY GAL A	02	CRN RD23-CR020	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00394	ANTIFOULING 1K 20L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000004	BULK MIX - MAESTRO EPOXY GAL B	02	CRN RD23-CR043	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000005	BULK MIX - PB36 CONSTRUCTION	02	CRN RD24-CR030	L04A - L4A ELASTO MIXING	L04A	L04A - L4A ELASTO MIXING	L04A	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000006	BULK MIX - CONCRETE EPOXY 10LV A	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000008	BULK MIX - CONCRETE EPOXY 10HV A	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000009	BULK MIX - CONCRETE EPOXY 10HV B	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000010	BULK MIX - E2M SEALANT	02	CRN RD24-CR030	L04A - L4A ELASTO MIXING	L04A	L04A - L4A ELASTO MIXING	L04A	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000011	BULK MIX - CLEAR EPOX A KG	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000012	BULKMIX - CLEAR EPOXY B KG	02	CRN RD23-CR043	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000013	BULK MIX - MULTIFILLA EPOXY A 1KG	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000014	BULKMIX MULTIFILLA EPOXY B-1KG	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000015	BULK MIX - ELASTOSEAL DUCTSEALANT	02	CRN RD24-CR030	L04A - L4A ELASTO MIXING	L04A	L04A - L4A ELASTO MIXING	L04A	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000016	BULK MIX - DURASTEEL FIVE 3%	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000017	BULK MIX - DURASTEEL FIVE 3%	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000018	BULKMIX- DURASTEEL 3% B	02	CRN RD23-CR043	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000019	BM  - DURASTEEL 3% A	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000020	BULK MIX - PLUS FIVE CLEAR B	02	CRN RD23-CR043	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000021	BULK MIX - PLUS FIVE CLEAR A	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000026	BULK MIX WHITE EPOXY B	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000027	BULK MIX WHITE EPOXY A	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000028	BULK MIX - PVC SOLVENT CEMENT	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000029	BULK MIX - CAC 611	03	CRN RD25-CR021	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000030	BULK MIX - CAC 621	03	CRN RD25-CR022	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000031	BULK MIX - WATERTITE 102 LIQUID	02	CRN RD25-CR025	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000032	BM- WATERTITE 102 POWDER	03	CRN RD25-CR016	L14 - L14 SKIM COAT	L14	L14 - L14 SKIM COAT	L14	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000033	BULK MIX- WATERTITE 103 LIQUID	02	CRN RD25-CR025	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000034	BULK MIX- WATERTITE 103 POWDER	03	CRN RD25-CR016	L14 - L14 SKIM COAT	L14	L14 - L14 SKIM COAT	L14	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000035	BULK MIX - AAC 101 (MODIFIED)	02	PHASE 2 APM PACKAGE	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000038	BULK MIX - BASE COAT DRY MIX	01	CRN RD23-CR037	L14 - L14 SKIM COAT	L14	L14 - L14 SKIM COAT	L14	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000039	BULK MIX - PIONEER WHITE GLUE	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000040	BULK MIX - VIETSEAL	02	CRN RD24-CR030	L04A - L4A ELASTO MIXING	L04A	L04A - L4A ELASTO MIXING	L04A	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000044	BULK MIX - LCRB A	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000045	BULK MIX - LCRB B	02	CRN RD23-CR043	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000047	BULK MIX-PILE SPLICING EPOXY A	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000048	BULK MIX-PILE SPLICING EPOXY B	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000049	BULK MIX - PIPE JOINTING PUTTY A	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000050	BULK MIX - PIPE JOINTING PUTTY B	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000051	BULKMIX- MELVEST LAMINATING A	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000052	BULKMIX- MELVEST LAMINATING B	02	CRN RD23-CR043	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00555	QDE BOOTTOPING RED 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000053	BULK MIX - NON SAG EPOXY A	03	CRN RD23-CR041	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000054	BULK MIX - NON SAG EPOXY B	02	CRN RD23-CR041	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000055	OPTIMIZED BM MIXING PROCESS FOR PAPE PART A – Line 6	05	\N	L06 MIXING	L06	L06 MIXING	L06	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000056	BULK MIX - ALL PURPOSE EPOXY B	02	CRN RD23-CR041	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000057	BULK MIX - MARINE EPOXY  A	03	CRN RD23-CR045	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000058	BULK MIX - MARINE EPOXY  B	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000059	BULK MIX-CEMENT TILE ADHESIVE	02	CRN RD24-CR027	L14 - L14 SKIM COAT	L14	L14 - L14 SKIM COAT	L14	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000060	BULK MIX - ELASTOSEAL TOL FREE	02	CRN RD23-CR039	L04A - L4A ELASTO MIXING	L04A	L04A - L4A ELASTO MIXING	L04A	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000061	BULK MIX - ELASTOKWIK	01	PHASE 2 APM PACKAGE	L04A - L4A ELASTO MIXING	L04A	L04A - L4A ELASTO MIXING	L04A	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000062	BULK MIX - CONTACT BOND	01	PHASE 2 APM PACKAGE	L04A - L4A ELASTO MIXING	L04A	L04A - L4A ELASTO MIXING	L04A	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000063	BULKMIX- MODIFIED CAC FINISHER	01	PHASE 2 APM PACKAGE	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000066	BULKMIX- PG GLOSS DARK GREEN PART A	01	CRN RD23-CR018	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000067	BULKMIX-PG EPOXY ENAMEL PART B	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000070	BULKMIX- ETL WHITE PART A	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000071	BULKMIX- ETL WHITE PART B	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000072	EPOXY PRIMER GRAY PART A	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000078	BM- EPOXY PRIMER WHITE PART A	03	CRN RD23-CR043	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000079	BM- EPOXY PRIMER WHITE PART B	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000081	BULK MIX - IN-HOUSE SKIMCOAT - WHITE	02	CRN RD24-CR027	L14 - L14 SKIM COAT	L14	L14 - L14 SKIM COAT	L14	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000082	BULKMIX- PG ANTI FOULING PAINT BLUE A	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000083	BULKMIX- PG ANTI FOULING PAINT BLUE B	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000085	BULKMIX- MAESTRO FURNITURE A	02	CRN RD23-CR020	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000086	BULK MIX- SPRAYABLE CONTACT	01	PHASE 2 APM PACKAGE	L04A - L4A ELASTO MIXING	L04A	L04A - L4A ELASTO MIXING	L04A	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000087	BULK MIX - IN-HOUSE SKIMCOAT - GREY	02	CRN RD24-CR027	L14 - L14 SKIM COAT	L14	L14 - L14 SKIM COAT	L14	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000088	BULK MIX - ANCHORING EPOXY A	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000089	BULK MIX - ANCHORING EPOXY B	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000090	BULKMIX-LIQUID SKIMCOAT	02	CRN RD24-CR023	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000092	BULK MIX - WATERTITE 100 IN HOUSE	04	CRN RD25-CR016	L14 - L14 SKIM COAT	L14	L14 - L14 SKIM COAT	L14	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000131	BUKLMIX-WHITE GLUE SCENTED	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000152	BULKMIX- PG SATIN CATERPILLAR YELLOW	00	FOR REVIEW	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000160	BULKMIX-POWERFLEX	03	CRN RD24-CR011	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000161	BULKMIX-WATERTITE 101 AP	03	PCMR-25-002	L14 - L14 SKIM COAT	L14	L14 - L14 SKIM COAT	L14	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000166	BULKMIX- MAESTRO TEAKWOOD#4 B	02	CRN RD23-CR043	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000173	BULKMIX-QDE SAFETY YELLOW	02	CRN RD25-CR033, CRN RD23-CR005	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000174	BULKMIX - QDE WHITE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000175	BULK MIX QDE CHOCOLATE BROWN	02	CRN RD25-CR033, CRN RD23-CR005	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000176	BULKMIX - QDE SAFETY RED	02	CRN RD25-CR033, CRN RD23-CR005	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000177	BULKMIX - QDE BLACK	02	CRN RD25-CR033	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000179	BM- LATEX S/G CLEAR BASE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000180	BULKMIX QUICK DRY ENAMEL JADE GREEN	00	REPROCESS	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000181	BM- QDE SAFETY BLUE	02	CRN RD25-CR033, CRN RD23-CR005	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000182	BM - QDE SAFETY GREEN	01	CRN RD25-CR017	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000183	BM- QDE SAFETY ORANGE	02	CRN RD25-CR033, CRN RD23-CR005	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000185	BM - QDE SKY BLUE	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000187	BULKMIX - QDE CATERPILLAR YELLOW	02	CRN RD25-CR033, CRN RD23-CR005	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000188	BULKMIX - PG GLOSS SAND IVORY	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000189	BM- PG GLOSS LEAF GREEN A	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000190	BM- LATEX FLAT WHITE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000191	BM- SEMIGLOSS WHITE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM000192	BM- EPOXY ENAMEL SURF GRAY	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM1E2M2029	BULK MIX - ELASTOSEAL	01	PHASE 2 APM PACKAGE	L04A - L4A ELASTO MIXING	L04A	L04A - L4A ELASTO MIXING	L04A	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
BM1PEC9B5L	BULKMIX- ELASTOSEAL CARTRIDGE	02	CRN RD24-CR030	L04A - L4A ELASTO MIXING	L04A	L04A - L4A ELASTO MIXING	L04A	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00011	BUILDERS BOND 300ML	03	PCMR-25-001	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00042	BUILDERS BOND 384G	02	CRN RD23-CR055	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00043	ELASTOSEAL 500G	03	CRN RD23-CR055	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00044	ELASTOSEAL 85G	02	CRN RD23-CR055	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00047	PB ACRYLIC GAP SEALANT 100G	02	CRN RD23-CR055	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00048	CONCRETE EPOXY 10HV 2.5KG	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00049	PPRO ELASTOSEAL 300ML X 24	02	CRN RD23-CR055	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00057	PG ANTI-FOULING PAINT RED-1L	01	CRN RD23-CR032	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00062	PG ANTI FOULING PAINT BLUE 4L	00	0	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00063	PG ANTI FOULING PAINT BLUE 1L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00068	EPOXY PRIMER LIGHT GRAY 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00069	EPOXY PRIMER LIGHT GRAY 1L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00070	PEARL GLAZE GLOSS DARK GREEN 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00077	CLEAR EPOXY (STANDARD)-800G	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00080	CLEAR EPOXY (PREMIUM)-800G	02	CRN RD23-CR055	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00085	ELASTOSEAL 1KG	02	CRN RD23-CR055	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00099	WATERTITE 100 200G	02	CRN RD23-CR055	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00100	CONCRETE EPOXY 10HV 495G	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00101	BUILDERS BOND 100G	02	CRN RD23-CR055	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00102	CONTACT BOND 10ML	03	CRN RD25-CR001	L10 - L10 CONTACT BOND	L10	L10 - L10 CONTACT BOND	L10	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00117	MIGHTY SEAL LIQUID SEALANT 25G	02	CRN RD23-CR055	L04C - L4C ATO FILLING	L04C	L04C - L4C ATO FILLING	L04C	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00118	MAESTRO FURNITURE 1/2 PINT	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00120	CLADDING EPOXY 1.5KG	02	CRN RD23-CR055	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00124	MAESTRO FURNITURE PINT	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00131	PIONEER ALL PURPOSE EPOXY GALLON	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00132	ALL PURPOSE EPOXY  QUART	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00133	PIONEER ALL PURPOSE EPOXY PINT	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00134	PIONEER ALL PURPOSE EPOXY 1/2	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00135	PIONEER ALL PURPOSE EPOXY 1/4	03	CRN RD25-CR019	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00136	PIONEER NON-SAG EPOXY GALLON	03	CRN RD24-CR013	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00137	NON-SAG EPOXY QUART	03	CRN RD24-CR013	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00138	NON-SAG EPOXY PINT	03	CRN RD24-CR013	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00139	NON-SAG EPOXY 1/2 PINT	03	CRN RD24-CR013	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00140	NON-SAG EPOXY 1/4 PINT	04	CRN RD25-CR019	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00141	PG GLOSS SAFETY BLACK 1 LITER	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00143	PG GLOSS SAFETY BLUE 1 LITER	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00144	PG GLOSS SAFETY BLUE 4 LITERS	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00145	PG GLOSS SAFETY GREEN 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00146	PG GLOSS SAFETY GREEN 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00147	PG GLOSS SAFETY ORANGE 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00148	PG GLOSS SAFETY ORANGE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00149	PG GLOSS SAFETY RED 1 LITER	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00150	PG GLOSS SAFETY RED 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00151	PG GLOSS SAFETY YELLOW 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00152	PG GLOSS SAFETY YELLOW 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00153	PEARL GLAZE GLOSS ULTRAMARINE BLUE 1L	00	PT PAI	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00155	PG GLOSS WHITE 1L	03	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00156	PG GLOSS WHITE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00157	ELASTOSEAL 250G POUCH - INDIA	02	CRN RD23-CR055	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00170	MAESTRO FURNITURE QUART	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00171	MAESTRO FURNITURE EPOXY GALLON	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00172	PG GLOSS U. BLUE ET501 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00173	PEARL GLAZE GLOSS ULTRAMARINE BLUE ET 501 1L	01	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00177	PG GLOSS LEAF GREEN 1L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGI00178	PG GLOSS LEAF GREEN 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGP00006	LCRB INJECTABLE EPOXY	02	CRN RD23-CR043	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGP00013	PVC SOLVENT CEMENT 400ML	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGP00014	PIPE JOINTING (PVC SOLVENT	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGP00021	PU ADHESIVE 220KG	02	CRN RD25-CR028 (FOR REVIEW)	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGP00023	PU ADHESIVE 20 KG	02	CRN RD25-CR028 (FOR REVIEW)	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGP00024	PILE SPLICING EPOXY 3.0 KG	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGP00031	LCRB Epoxy-UNLABELLED 3.8 KG	01	0	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGP00032	LCRB Epoxy-UNLABELLED 3.0 KG	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGP00045	SATURANT UNDERWATER LV 3KG KIT	03	CRN RD25-CR018	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGP00051	LATEX PAINT FLAT WHITE 16L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGP00055	LATEX PAINT SEMGLOSS WHITE 16L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGP00060	LATEX PAINT SG CLEAR BASE 16L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00031	MAESTRO EPOXY GALLON	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00032	MAESTRO EPOXY QUART	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00033	MAESTRO EPOXY PINT	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00034	MAESTRO EPOXY 1/2 PINT	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00035	MAESTRO EPOXY 1/4 PINT	02	CRN RD25-CR019	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00065	PEARL GLAZE ANTI-FOULING PAINT 4L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00066	PEARL GLAZE ANTI-FOULING PAINT 1L	03	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00092-IH	PAINTER'S BUDDY SKIMCOAT WHITE IN HOUSE	00	CRN RD24-CR027	L14 - L14 SKIM COAT	L14	L14 - L14 SKIM COAT	L14	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00103	PVC SOLVENT CEMENT 85ML	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00104	CONTACT BOND BOTTLE 50ML TWIN	01	PHASE 2 APM PACKAGE	L10 - L10 CONTACT BOND	L10	L10 - L10 CONTACT BOND	L10	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00105	CONTACT BOND 1L	02	CRN RD25-CR001	L10 - L10 CONTACT BOND	L10	L10 - L10 CONTACT BOND	L10	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00106	CONTACT BOND 1 GALLON	02	CRN RD25-CR001	L10 - L10 CONTACT BOND	L10	L10 - L10 CONTACT BOND	L10	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00111	PIPE JOINTING EPOXY PUTTY 1/2 PINT	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00114	CONTACT BOND 300ML BOTTLE	02	CRN RD25-CR001	L10 - L10 CONTACT BOND	L10	L10 - L10 CONTACT BOND	L10	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00117	ELASTOSEAL CLEAR PISILITO	01	PHASE 2 APM PACKAGE	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00118	ELASTOSEAL CLEAR PISIL	01	PHASE 2 APM PACKAGE	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00119	ELASTOSEAL CLEAR CARTRIDGE	01	PHASE 2 APM PACKAGE	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00122	MIGHTY SEAL BIOCIDE 300ML	01	PHASE 2 APM PACKAGE	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00128	GF200 SPL COLOR  LIGHT GRAY HONDA ILOILO 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00129	GF200 SPL COLOR  LIGHT BEIGE HONDA ILOILO 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00141	ELASTOKWIK 4L	01	PHASE 2 APM PACKAGE	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00142	ELASTOKWIK 1L	01	PHASE 2 APM PACKAGE	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00143	ELASTOKWIK 1/2L	02	CRN RD23-CR025	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00144	ELASTOKWIK 1/4L	01	PHASE 2 APM PACKAGE	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00145	ELASTOKWIK 30 ML	01	PHASE 2 APM PACKAGE	L04C - L4C ATO FILLING	L04C	L04C - L4C ATO FILLING	L04C	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00146	ELASTOKWIK PISILITO	01	PHASE 2 APM PACKAGE	L04C - L4C ATO FILLING	L04C	L04C - L4C ATO FILLING	L04C	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00147	ELASTOKWIK PISIL	01	PHASE 2 APM PACKAGE	L04C - L4C ATO FILLING	L04C	L04C - L4C ATO FILLING	L04C	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00148	GF300 STD COLOR  WHITE 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00155	GF200 STD COLOR  TOYOTA DARK GREEN 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00158	GF200 SPL COLOR  TOYOTA YELLOW 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00159	CONTACT BOND 10ML SACHET	03	CRN RD25-CR001	L10 - L10 CONTACT BOND	L10	L10 - L10 CONTACT BOND	L10	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00164	TRANSFORMER ADHESIVE PART A - RESIN	02	CRN RD25-CR028 (FOR REVIEW)	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00165	TRANSFORMER ADHESIVE PART B - HARDENER	02	CRN RD25-CR028 (FOR REVIEW)	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00167	GF300 SPL COLOR  GINEBRA GREEN	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00169	GF200 SPL COLOR  LIGHT GRAY ULTRADE 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00175	EPOXY STEEL PRIMER GRAY 1L	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00176	EPOXY STEEL PRIMER GRAY 4L	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00177	EPOXY STEEL PRIMER WHITE 4L	02	CRN RD23-CR043	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00178	EPOXY STEEL PRIMER WHITE 1L	02	CRN RD23-CR043	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00182	GF300 SPL COLOR  SULPICIO GREEN 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00185	GF200 SPL COLOR  NEON GREEN 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00186	EPOXY REDUCER 300ML BOTTLE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00187	EPOXY REDUCER 1L	02	CRN RD25-CR010	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00188	FRP ADHESIVE - COMPONENT B	01	PHASE 2 APM PACKAGE	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00193	MULTI-FILLA 2.16KG	01	PHASE 2 APM PACKAGE	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00208	GF 300 LS PILOT BLUE 4L	01	PHASE 2 APM PACKAGE-INACTIVE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00210	GF300 SPL COLOR  TOYOTA YELLOW 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00211	PEARL GLAZE SATIN NILE GREEN 4L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00212	PEARL GLAZE SATIN NILE GREEN 1L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00213	PEARL GLAZE SATIN VISMIN ORANGE 4L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00214	PEARL GLAZE SATIN VISMIN ORANGE 1L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00215	PEARL GLAZE SATIN VISMIN ULTRAMARINE BLUE 4L	03	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00216	PEARL GLAZE SATIN VISMIN ULTRAMARINE BLUE 1L	03	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00217	GF 300 TOYOTA NILE GREEN 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00221	PG SATIN SIGNAL GREEN 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00222	SEPERATE THE ITEM CODE OF COAXIAL CARTRIDGE AND PISTON RING	02	\N	L12 LABELING/CODING	L12	L12 LABELING/CODING	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00224	LIQUID SKIMCOAT	03	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00237	MARINE QUICK DRY ENAMEL SAFETY RED 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00249	PG SATIN NANCY GRAY 4L	02	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00281	GF200 MAROON  4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00282	PPRO GF 200 PANTONE 7521C	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00284	WATER-TITE 400 PU MODIFIED WATERPROOFING MEMBRANE	03	CRN RD25-CR006; CRN RD25-CR034	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00287	EPOXY TANK LINING PREMIUM WHITE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00288	WHITE GLUE 10ML	02	CRN RD23-CR055	L10 - L10 CONTACT BOND	L10	L10 - L10 CONTACT BOND	L10	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00289	WHITE GLUE 120G	02	CRN RD23-CR055	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00314	WATER-TITE POWERFLEX 4L	02	CRN RD22-CR034	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00315	WATER-TITE POWERFLEX 16L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00317	CLEAR LAMINATING EPOXY	03	CRN RD25-CR028 (FOR REVIEW)	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00334	STRUCTURAL EPOXY NON SAG GAL	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00335	STRUCTURAL EPOXY NON SAG QUART	02	CRN RD23-CR055	L06 - L6 EPOXY LINE	L06	L06 - L6 EPOXY LINE	L06	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00354	EPOXY CLEAR COAT SELAER 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00355	EPOXY FLOORING LIGHT GRAY 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00356	POLYURETHANE LIGHT GRAY 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00357	POLYURETHANE REDUCER 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00358	WATER-TITE 401 PU PLUS 20KG PAIL	03	CRN RD23-CR055	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00359	WATER-TITE 401 PU PLUS 4KG PAIL	03	CRN RD23-CR055	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	L13 - L13 SPECIAL PRODUCTS - WATER BASED	L13	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00362	EPOXY STEEL PRIMER RED 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00363	EPOXY STEEL PRIMER GRAY 4L	02	CRN RD24-CR001	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00364	WEARING COMPOUND 15KG	04	CRN RD25-CR002, CRN RD25-CR007	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00366	PG SATIN INSIGNIA BLUE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00369	EPOXY PRIMER MASTIC RED 4L	02	CRN RD23-CR036	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00370	EPOXY PRIMER MASTIC RED 20L	02	CRN RD23-CR036	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00371	ALKYD PRIMER RED 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00372	PIOCRYL WHITE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00374	ALKYD HIGH GLOSS WHITE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00375	HIGH BUILD EPOXY S. ORANGE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00376	ANTIFOULING TIE COAT B.RED 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00377	ANTIFOULING 1K 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00378	EPOXY MASTIC REDUCER 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00379	ACRYLIC LACQUER THINNER 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00380	LACQUER THINNER 4L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00381	PAINT THINNER 4L	01	CRN RD21-CR042	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00383	EPOXY STEEL PRIMER RED 16L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00384	EPOXY STEEL PRIMER GRAY 16L	03	CRN RD24-CR001	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00385	PIOCRYL WHITE 20L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00388	ALIPHATIC POLYURETHANE WHITE 16L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00391	ALKYD HIGH GLOSS WHITE 20L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00392	HIGH BUILD EPOXY S. ORANGE 16L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00393	ANTIFOULING TIE COAT B.RED 16L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00403	PIOPOXY AF TIE COAT LIGHT GRAY 4L	02	CRN RD24-CR031	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00404	PIOPOXY AF TIE COAT LIGHT GRAY 16L	01	CRN RD24-CR031	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00428	FUJI PVC SOLVENT CEMENT 85 ML	02	CRN RD23-CR055	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00429	FUJI PVC SOLVENT CEMENT 400 ML	02	CRN RD23-CR055	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00432	GF 300 STAR MIST 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00459	EPOXY ENAMEL SAFETY GREEN 4L	03	CRN RD25-CR020	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00460	EPOXY ENAMEL SAFETY ORANGE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00461	EPOXY ENAMEL SAFETY RED 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00462	EPOXY ENAMEL SAFETY YELLOW 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00463	EPOXY ENAMEL U. BLUE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00464	EPOXY ENAMEL WHITE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00465	EPOXY ENAMEL BLACK 4L	03	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00468	QUICK DRY ENAMEL BLACK 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00470	QUICK DRY ENAMEL SAFETY BLUE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00472	QUICK DRY ENAMEL SAFETY ORANGE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00473	QUICK DRY ENAMEL SAFETY RED 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00477	QUICK DRY ENAMEL WHITE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00483	QUICK DRY ENAMEL OCEAN BLUE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00484	QUICK DRY ENAMEL SURF GRAY 4L	03	CRN RD24-CR035	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00485	SPRAYABLE CONTACT ADH 20L	01	PHASE 2 APM PACKAGE	L04B - L4B SEMI AUTO FILLING	L04B	L04B - L4B SEMI AUTO FILLING	L04B	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00486	EPOXY ENAMEL FRENCH BLUE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00487	EPOXY ENAMEL JADE GREEN 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00489	EPOXY ENAMEL SURF GRAY 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00498	WATERTITE 200 BARRICADE GRAY 4L	01	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00499	BACKING COMPOUND HD 20KG SET	02	CRN RD23-CR024	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	L12 - L12 SPECIAL PRODUCTS - EPOXY BASED	L12	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00502	EPOXY ENAMEL VISMIN U. BLUE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00504	EPOXY ENAMEL CATERPILLAR YELLOW 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00507	QUICK DRY ENAMEL CHOCOLATE BROWN  4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00508	QUICK DRY ENAMEL CATERPILLAR YELLOW 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00510	EPOXY ENAMEL SIGNAL GREEN 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00511	EPOXY ENAMEL CITIMAX BLUE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00514	EPOXY ENAMEL INTL ORANGE 4L	03	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00515	EPOXY ENAMEL PENINSULA GRAY 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00516	QDE PIO NILE GREEN 4L INTL	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00517	EPOXY ENAMEL PIO NILE GREEN 4L	03	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00518	EPOXY ENAMEL GLS DECK GREEN 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00519	EPOXY ENAMEL STN DECK GREEN 4L	03	CRN RD25-CR035 (FOR REVIEW)	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00536	LITEBLOCK ADHESIVES 25KG	01	PHASE 2 APM PACKAGE	L14 - L14 SKIM COAT	L14	L14 - L14 SKIM COAT	L14	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00538	PIOMASTIC BLACK 20L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00541	QDE PIO INTL ORANGE 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00543	QDE PIO INTL DECK GREEN 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00545	QDE PIO INTL YELLOW 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00547	QDE PIO INTL RED 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00549	QDE FRENCH GREY 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
FGT00553	QDE CREAM IVORY 4L	02	CRN RD23-CR055	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000005	GIP-MIGHTY SEAL TRANSLUCENT	01	PHASE 2 APM PACKAGE	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000041	GIP-CLEAR EPOXY SYRINGE 6ML	02	CRN RD25-CR011	L07 - L7 EPOXY TUBE FILLING	L07	L07 - L7 EPOXY TUBE FILLING	L07	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000049	GIP-MIGHTY BOND XTREME 1G	01	PHASE 2 APM PACKAGE	L03 - L3 CYANO TUBE FILLING	L03	L03 - L3 CYANO TUBE FILLING	L03	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000050	GIP-MIGHTY GASKET BLACK 15G	01	PHASE 2 APM PACKAGE	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000051	GIP-MIGHTY GASKET GREY 15G	01	PHASE 2 APM PACKAGE	L11 - L11 SILICONE FILLING LINE	L11	L11 - L11 SILICONE FILLING LINE	L11	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000053	GIP-MIGHTY BOND SHOES 3G	01	PHASE 2 APM PACKAGE	L03 - L3 CYANO TUBE FILLING	L03	L03 - L3 CYANO TUBE FILLING	L03	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000058	BM-GF 300 BLACK TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000059	BM-GF 300 YELLOW OXIDE TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000060	BM-PG GLOSS GREEN TINT	02	CRN RD23-CR018	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000061	BM-PG GLOSS ULTRAMARINE BLUE 8	02	CRN RD23-CR040	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000063	BULKMIX - PG GLOSS TICO ORANGE 640	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000064	BM-PG GLOSS CHROMOFINE BLUE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000065	BM-PG GLOSS ULTRAMARINE BLUE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000066	BULKMIX - HITOX  BUFF TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000067	BM-PG GLOSS CLEAR BASE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000068	BM-GF300 FAST YELLOW 5GX TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000069	BM-GF 300 GREEN 7 TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000070	BM-GF 200 WHITE TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000071	BM-GF 300 WHITE TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000072	BM-GF 300 FS RED BBN48:1 TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000073	BM-GF 200 FAST BLUE BGS TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000076	BULKMIX - EMULSION INTERMEDIATE SC100	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000077	BM-ENAMEL BLACK TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000078	BULKMIX - ENAMEL CLEAR BASE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000081	BM - ENAMEL PHTHALO BLUE TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000085	BM-ENAMEL WHITE TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000086	BM-ENAMEL YELLOW 74 TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000087	BM- ENAMEL YELLOW IRON OXIDE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000088	BULKMIX - ENAMEL CHROMOFINE BLUE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000095	BM-PG SATIN WHITE BASE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000096	BM-GF 300 FAST BLUE TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000097	BM-GF 100 WHITE TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000107	BM-PU MIX SOLVENTS	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000108	BM-GF 200 RED TINT	02	CRN RD23-CR040	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000109	BM-BENTONE GEL F2	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000115	BM-PU BLACK TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000116	BM-PU YELLOW OXIDE TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000117	BM-PU WHITE BASE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000129	BM-PU YELLOW 74 TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000130	BM-PU SCARLET RED TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000143	BM-PU ORANGE RL70 TINT	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000147	BULKMIX - PG SATIN CLEAR BASE	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000148	BULKMIX -  ENAMEL CHOCO BROWN F8660	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
GIP000149	BULK MIX-ENAMEL PERMANENT RED R170	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Base Material (BM)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1KPH5A5J01	FG_KOPHENOL HIGHWAY YELLOW	00	PACKAGING MATERIAL: REUSE THE TIN PAIL OF KOPHENOL CREAM	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
1KRT5A9A12	KORETHAN TC UT6581 RAL 5011 URETHANE TOPCOAT SOLVENT BASED BLUE 16L	01	PHASE 2 APM PACKAGE	L01 - L1 COATINGS	L01	L01 - L1 COATINGS	L01	Finished Good (FG)	\N	\N	\N	\N	\N	\N	\N	\N	2026-07-07 15:16:36.455308+08	2026-07-07 15:16:36.455308+08
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, password_hash, role, is_active, created_at, updated_at) FROM stdin;
2	dell	$argon2id$v=19$m=65536,t=3,p=4$gnPaeY1Kz0g/BywRj9eYPw$gFdnesLRnt3jWqBaOqaRgszHADxBTzWdBs4ybHMBCtU	admin	t	2026-06-18 15:34:24.750689+08	2026-06-18 15:34:24.750689+08
4	macky	$argon2id$v=19$m=65536,t=3,p=4$1k7II7us7fbuXGu/3ALzqg$2vBLFYTP2dv3bUJC7sSlFK1qtvYfm4vMxNxxcGxvse0	superuser	t	2026-06-18 16:16:45.624111+08	2026-06-18 16:16:45.624111+08
5	eson	$argon2id$v=19$m=65536,t=3,p=4$vgy3/BCkOaicNmUcPLo4bA$/h7JIqFDuF9TJfehKtJebsiuhp4Z/E4mwWFeoCVxZ0A	user	t	2026-06-22 09:27:05.753881+08	2026-06-26 08:55:58.192524+08
7	Aerial	$argon2id$v=19$m=65536,t=3,p=4$I/7UeKipgoG4qhxy0KZNjQ$+bH7rWfL2unv1jU7TnHgJtXNgjD4BYy4sBd4q8AhIjI	user	f	2026-06-23 09:09:40.506552+08	2026-06-26 09:11:05.6355+08
29	Eson	$argon2id$v=19$m=65536,t=3,p=4$CqPBGcmvGFU2XA8BSSiNCw$txNuegZJvlViUM4ASUWBIveVaZH0DTOUagO+v1hqJVs	superuser	t	2026-07-02 13:37:32.291962+08	2026-07-02 13:37:32.291962+08
30	user	$argon2id$v=19$m=65536,t=3,p=4$CaoV6Kkxxz0cQP7w+3oGzQ$DWIokts0a1gMWqliFmy6DZ0XQKModwfrOifHkM9hlSU	user	t	2026-07-07 13:15:39.661585+08	2026-07-07 13:15:39.661585+08
\.


--
-- Name: activities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.activities_id_seq', 2754, true);


--
-- Name: activity_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.activity_logs_id_seq', 1, false);


--
-- Name: line_activities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.line_activities_id_seq', 147, true);


--
-- Name: pending_approvals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pending_approvals_id_seq', 1, false);


--
-- Name: product_revisions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_revisions_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 30, true);


--
-- Name: activities activities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_pkey PRIMARY KEY (id);


--
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: line_activities line_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.line_activities
    ADD CONSTRAINT line_activities_pkey PRIMARY KEY (id);


--
-- Name: line_activities line_activities_production_line_code_activity_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.line_activities
    ADD CONSTRAINT line_activities_production_line_code_activity_name_key UNIQUE (production_line_code, activity_name);


--
-- Name: pending_approvals pending_approvals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_approvals
    ADD CONSTRAINT pending_approvals_pkey PRIMARY KEY (id);


--
-- Name: product_revisions product_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_revisions
    ADD CONSTRAINT product_revisions_pkey PRIMARY KEY (id);


--
-- Name: production_lines production_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_lines
    ADD CONSTRAINT production_lines_pkey PRIMARY KEY (production_line_code);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (inventory_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: idx_activities_inventory_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activities_inventory_id ON public.activities USING btree (inventory_id);


--
-- Name: idx_activity_logs_logged_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_logged_at ON public.activity_logs USING btree (logged_at DESC);


--
-- Name: idx_activity_logs_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_user_id ON public.activity_logs USING btree (user_id);


--
-- Name: idx_line_activities_line_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_line_activities_line_code ON public.line_activities USING btree (production_line_code);


--
-- Name: idx_product_revisions_inventory_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_product_revisions_inventory_id ON public.product_revisions USING btree (inventory_id);


--
-- Name: idx_product_revisions_inventory_revision; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_product_revisions_inventory_revision ON public.product_revisions USING btree (inventory_id, revision);


--
-- Name: idx_users_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_active ON public.users USING btree (id) WHERE (is_active = true);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_role ON public.users USING btree (role);


--
-- Name: idx_users_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_username ON public.users USING btree (username);


--
-- Name: products set_products_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users trigger_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: activity_logs activity_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: line_activities line_activities_production_line_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.line_activities
    ADD CONSTRAINT line_activities_production_line_code_fkey FOREIGN KEY (production_line_code) REFERENCES public.production_lines(production_line_code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict sZmYx8MXSK6kk7oRdSnseMI1e96cKJckzLpHmhDNY3fRVYHq279OkEKwMlFzHie

