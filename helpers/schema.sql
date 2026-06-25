--
-- PostgreSQL database dump
--

\restrict NTJxsMl7xzSzr33x8dYomSkBYpM116CI3jpKsHsCBzdbbI745MD8T9eHyTtqSid

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
    sort_order integer
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
    CONSTRAINT products_quantity_whole_number CHECK (((quantity IS NULL) OR (quantity = floor(quantity))))
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
-- Name: product_revisions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_revisions ALTER COLUMN id SET DEFAULT nextval('public.product_revisions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


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
-- Name: users trigger_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: activities activities_inventory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_inventory_id_fkey FOREIGN KEY (inventory_id) REFERENCES public.products(inventory_id) ON DELETE CASCADE;


--
-- Name: activity_logs activity_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: products fk_products_bm_line; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT fk_products_bm_line FOREIGN KEY (bm_production_line_code) REFERENCES public.production_lines(production_line_code);


--
-- Name: products fk_products_fg_line; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT fk_products_fg_line FOREIGN KEY (fg_production_line_code) REFERENCES public.production_lines(production_line_code) ON UPDATE CASCADE;


--
-- Name: line_activities line_activities_production_line_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.line_activities
    ADD CONSTRAINT line_activities_production_line_code_fkey FOREIGN KEY (production_line_code) REFERENCES public.production_lines(production_line_code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict NTJxsMl7xzSzr33x8dYomSkBYpM116CI3jpKsHsCBzdbbI745MD8T9eHyTtqSid

