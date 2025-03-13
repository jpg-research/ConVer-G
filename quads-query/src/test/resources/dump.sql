--
-- PostgreSQL database dump
--

-- Dumped from database version 17.0 (Debian 17.0-1.pgdg120+1)
-- Dumped by pg_dump version 17.0 (Debian 17.0-1.pgdg120+1)

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

ALTER TABLE IF EXISTS ONLY public.versioned_quad DROP CONSTRAINT IF EXISTS versioned_quad_id_subject_fkey;
ALTER TABLE IF EXISTS ONLY public.versioned_quad DROP CONSTRAINT IF EXISTS versioned_quad_id_predicate_fkey;
ALTER TABLE IF EXISTS ONLY public.versioned_quad DROP CONSTRAINT IF EXISTS versioned_quad_id_object_fkey;
ALTER TABLE IF EXISTS ONLY public.versioned_quad DROP CONSTRAINT IF EXISTS versioned_quad_id_named_graph_fkey;
ALTER TABLE IF EXISTS ONLY public.versioned_named_graph DROP CONSTRAINT IF EXISTS versioned_named_graph_id_versioned_named_graph_fkey;
ALTER TABLE IF EXISTS ONLY public.versioned_named_graph DROP CONSTRAINT IF EXISTS versioned_named_graph_id_named_graph_fkey;
ALTER TABLE IF EXISTS ONLY public.metadata DROP CONSTRAINT IF EXISTS metadata_id_subject_fkey;
ALTER TABLE IF EXISTS ONLY public.metadata DROP CONSTRAINT IF EXISTS metadata_id_predicate_fkey;
ALTER TABLE IF EXISTS ONLY public.metadata DROP CONSTRAINT IF EXISTS metadata_id_object_fkey;
DROP INDEX IF EXISTS public.versioned_quad_ng_s_p_o;
DROP INDEX IF EXISTS public.versioned_quad_ng_s_o_p;
DROP INDEX IF EXISTS public.versioned_quad_ng_p_s_o;
DROP INDEX IF EXISTS public.versioned_quad_ng_p_o_s;
DROP INDEX IF EXISTS public.versioned_quad_ng_o_s_p;
DROP INDEX IF EXISTS public.versioned_quad_ng_o_p_s;
DROP INDEX IF EXISTS public.resource_or_literal_idx;
ALTER TABLE IF EXISTS ONLY public.versioned_quad DROP CONSTRAINT IF EXISTS versioned_quad_pkey;
ALTER TABLE IF EXISTS ONLY public.versioned_named_graph DROP CONSTRAINT IF EXISTS versioned_named_graph_pkey;
ALTER TABLE IF EXISTS ONLY public.version DROP CONSTRAINT IF EXISTS version_pkey;
ALTER TABLE IF EXISTS ONLY public.resource_or_literal DROP CONSTRAINT IF EXISTS resource_or_literal_pkey;
ALTER TABLE IF EXISTS ONLY public.metadata DROP CONSTRAINT IF EXISTS metadata_pkey;
ALTER TABLE IF EXISTS ONLY public.flat_model_triple DROP CONSTRAINT IF EXISTS flat_model_triple_pkey;
ALTER TABLE IF EXISTS ONLY public.flat_model_quad DROP CONSTRAINT IF EXISTS flat_model_quad_pkey;
DROP TABLE IF EXISTS public.versioned_quad;
DROP TABLE IF EXISTS public.versioned_named_graph;
DROP TABLE IF EXISTS public.version;
DROP TABLE IF EXISTS public.resource_or_literal;
DROP TABLE IF EXISTS public.metadata;
DROP TABLE IF EXISTS public.flat_model_triple;
DROP TABLE IF EXISTS public.flat_model_quad;
DROP FUNCTION IF EXISTS public.version_named_graph(named_graph character varying, filename character varying, version integer);
--
-- Name: version_named_graph(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.version_named_graph(named_graph character varying, filename character varying, version integer) RETURNS TABLE(id_named_graph integer, id_version integer, id_version_named_graph integer)
    LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
    RETURN QUERY
        WITH ng AS (INSERT INTO resource_or_literal
            VALUES (DEFAULT, named_graph, NULL)
            ON CONFLICT (sha512(name::bytea), type) DO UPDATE SET type = EXCLUDED.type
            RETURNING *),
             v AS (INSERT INTO resource_or_literal
                 VALUES (DEFAULT, 'https://github.com/VCityTeam/ConVer-G/Version#' || filename, NULL)
                 ON CONFLICT (sha512(name::bytea), type) DO UPDATE SET type = EXCLUDED.type
                 RETURNING *),
             vng AS (INSERT INTO resource_or_literal
                 VALUES (DEFAULT, 'https://github.com/VCityTeam/ConVer-G/Versioned-Named-Graph#' ||
                                  encode(sha512((named_graph || filename)::bytea), 'hex'), NULL)
                 ON CONFLICT (sha512(name::bytea), type) DO UPDATE SET type = EXCLUDED.type
                 RETURNING *),
             versioned AS (INSERT INTO versioned_named_graph
                 VALUES ((SELECT id_resource_or_literal FROM vng), (SELECT id_resource_or_literal FROM ng), version)
                 ON CONFLICT (id_versioned_named_graph) DO UPDATE SET id_named_graph = EXCLUDED.id_named_graph
                 RETURNING *),
             metadata AS (INSERT INTO metadata (id_subject, id_predicate, id_object)
                 VALUES ((SELECT id_resource_or_literal FROM vng), (SELECT id_resource_or_literal
                                                                    FROM resource_or_literal
                                                                    WHERE name = 'https://github.com/VCityTeam/ConVer-G/Version#is-version-of'),
                         (SELECT id_resource_or_literal FROM ng)),
                        ((SELECT id_resource_or_literal FROM vng), (SELECT id_resource_or_literal
                                                                    FROM resource_or_literal
                                                                    WHERE name = 'https://github.com/VCityTeam/ConVer-G/Version#is-in-version'),
                         (SELECT v.id_resource_or_literal FROM v))
                 ON CONFLICT ON CONSTRAINT metadata_pkey
                     DO UPDATE SET id_subject = EXCLUDED.id_subject
                 RETURNING *
             ),
             result AS (
                 SELECT ng.id_resource_or_literal as id_named_graph, v.id_resource_or_literal as id_version, vng.id_resource_or_literal as id_versioned_named_graph
                 FROM ng, v, vng
             )
            TABLE result;
END;
$$;


ALTER FUNCTION public.version_named_graph(named_graph character varying, filename character varying, version integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: flat_model_quad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.flat_model_quad (
                                        id_record integer NOT NULL,
                                        subject text,
                                        subject_type character varying,
                                        predicate text,
                                        predicate_type character varying,
                                        object text,
                                        object_type character varying,
                                        named_graph text,
                                        version integer
);


ALTER TABLE public.flat_model_quad OWNER TO postgres;

--
-- Name: flat_model_quad_id_record_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.flat_model_quad ALTER COLUMN id_record ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.flat_model_quad_id_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
    );


--
-- Name: flat_model_triple; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.flat_model_triple (
                                          id_record integer NOT NULL,
                                          subject text,
                                          subject_type character varying,
                                          predicate text,
                                          predicate_type character varying,
                                          object text,
                                          object_type character varying
);


ALTER TABLE public.flat_model_triple OWNER TO postgres;

--
-- Name: flat_model_triple_id_record_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.flat_model_triple ALTER COLUMN id_record ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.flat_model_triple_id_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
    );


--
-- Name: metadata; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.metadata (
                                 id_object integer NOT NULL,
                                 id_predicate integer NOT NULL,
                                 id_subject integer NOT NULL
);


ALTER TABLE public.metadata OWNER TO postgres;

--
-- Name: resource_or_literal; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resource_or_literal (
                                            id_resource_or_literal integer NOT NULL,
                                            name text,
                                            type character varying(255)
);


ALTER TABLE public.resource_or_literal OWNER TO postgres;

--
-- Name: resource_or_literal_id_resource_or_literal_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.resource_or_literal ALTER COLUMN id_resource_or_literal ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.resource_or_literal_id_resource_or_literal_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
    );


--
-- Name: version; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.version (
                                index_version integer NOT NULL,
                                message character varying(255),
                                transaction_time_start timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
                                transaction_time_end timestamp with time zone
);


ALTER TABLE public.version OWNER TO postgres;

--
-- Name: version_index_version_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.version ALTER COLUMN index_version ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.version_index_version_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
    );


--
-- Name: versioned_named_graph; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.versioned_named_graph (
                                              id_versioned_named_graph integer NOT NULL,
                                              id_named_graph integer,
                                              index_version integer
);


ALTER TABLE public.versioned_named_graph OWNER TO postgres;

--
-- Name: versioned_quad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.versioned_quad (
                                       id_object integer NOT NULL,
                                       id_predicate integer NOT NULL,
                                       id_subject integer NOT NULL,
                                       id_named_graph integer NOT NULL,
                                       validity bit varying
);


ALTER TABLE public.versioned_quad OWNER TO postgres;

--
-- Data for Name: flat_model_quad; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: flat_model_triple; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: metadata; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: resource_or_literal; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.resource_or_literal OVERRIDING SYSTEM VALUE VALUES (1, 'https://github.com/VCityTeam/ConVer-G/Version#is-in-version', NULL);
INSERT INTO public.resource_or_literal OVERRIDING SYSTEM VALUE VALUES (2, 'https://github.com/VCityTeam/ConVer-G/Version#is-version-of', NULL);
INSERT INTO public.resource_or_literal OVERRIDING SYSTEM VALUE VALUES (3, 'https://github.com/VCityTeam/ConVer-G/Named-Graph#default-graph', NULL);


--
-- Data for Name: version; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: versioned_named_graph; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: versioned_quad; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: flat_model_quad_id_record_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.flat_model_quad_id_record_seq', 1, false);


--
-- Name: flat_model_triple_id_record_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.flat_model_triple_id_record_seq', 1, false);


--
-- Name: resource_or_literal_id_resource_or_literal_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.resource_or_literal_id_resource_or_literal_seq', 3, true);


--
-- Name: version_index_version_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.version_index_version_seq', 1, false);


--
-- Name: flat_model_quad flat_model_quad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.flat_model_quad
    ADD CONSTRAINT flat_model_quad_pkey PRIMARY KEY (id_record);


--
-- Name: flat_model_triple flat_model_triple_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.flat_model_triple
    ADD CONSTRAINT flat_model_triple_pkey PRIMARY KEY (id_record);


--
-- Name: metadata metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.metadata
    ADD CONSTRAINT metadata_pkey PRIMARY KEY (id_object, id_predicate, id_subject);


--
-- Name: resource_or_literal resource_or_literal_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_or_literal
    ADD CONSTRAINT resource_or_literal_pkey PRIMARY KEY (id_resource_or_literal);


--
-- Name: version version_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.version
    ADD CONSTRAINT version_pkey PRIMARY KEY (index_version);


--
-- Name: versioned_named_graph versioned_named_graph_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versioned_named_graph
    ADD CONSTRAINT versioned_named_graph_pkey PRIMARY KEY (id_versioned_named_graph);


--
-- Name: versioned_quad versioned_quad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versioned_quad
    ADD CONSTRAINT versioned_quad_pkey PRIMARY KEY (id_object, id_predicate, id_subject, id_named_graph);


--
-- Name: resource_or_literal_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX resource_or_literal_idx ON public.resource_or_literal USING btree (sha512((name)::bytea), type) NULLS NOT DISTINCT;


--
-- Name: versioned_quad_ng_o_p_s; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX versioned_quad_ng_o_p_s ON public.versioned_quad USING btree (id_named_graph, id_object, id_predicate, id_subject);


--
-- Name: versioned_quad_ng_o_s_p; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX versioned_quad_ng_o_s_p ON public.versioned_quad USING btree (id_named_graph, id_object, id_subject, id_predicate);


--
-- Name: versioned_quad_ng_p_o_s; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX versioned_quad_ng_p_o_s ON public.versioned_quad USING btree (id_named_graph, id_predicate, id_object, id_subject);


--
-- Name: versioned_quad_ng_p_s_o; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX versioned_quad_ng_p_s_o ON public.versioned_quad USING btree (id_named_graph, id_predicate, id_subject, id_object);


--
-- Name: versioned_quad_ng_s_o_p; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX versioned_quad_ng_s_o_p ON public.versioned_quad USING btree (id_named_graph, id_subject, id_object, id_predicate);


--
-- Name: versioned_quad_ng_s_p_o; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX versioned_quad_ng_s_p_o ON public.versioned_quad USING btree (id_named_graph, id_subject, id_predicate, id_object);


--
-- Name: metadata metadata_id_object_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.metadata
    ADD CONSTRAINT metadata_id_object_fkey FOREIGN KEY (id_object) REFERENCES public.resource_or_literal(id_resource_or_literal);


--
-- Name: metadata metadata_id_predicate_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.metadata
    ADD CONSTRAINT metadata_id_predicate_fkey FOREIGN KEY (id_predicate) REFERENCES public.resource_or_literal(id_resource_or_literal);


--
-- Name: metadata metadata_id_subject_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.metadata
    ADD CONSTRAINT metadata_id_subject_fkey FOREIGN KEY (id_subject) REFERENCES public.resource_or_literal(id_resource_or_literal);


--
-- Name: versioned_named_graph versioned_named_graph_id_named_graph_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versioned_named_graph
    ADD CONSTRAINT versioned_named_graph_id_named_graph_fkey FOREIGN KEY (id_named_graph) REFERENCES public.resource_or_literal(id_resource_or_literal);


--
-- Name: versioned_named_graph versioned_named_graph_id_versioned_named_graph_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versioned_named_graph
    ADD CONSTRAINT versioned_named_graph_id_versioned_named_graph_fkey FOREIGN KEY (id_versioned_named_graph) REFERENCES public.resource_or_literal(id_resource_or_literal);


--
-- Name: versioned_quad versioned_quad_id_named_graph_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versioned_quad
    ADD CONSTRAINT versioned_quad_id_named_graph_fkey FOREIGN KEY (id_named_graph) REFERENCES public.resource_or_literal(id_resource_or_literal);


--
-- Name: versioned_quad versioned_quad_id_object_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versioned_quad
    ADD CONSTRAINT versioned_quad_id_object_fkey FOREIGN KEY (id_object) REFERENCES public.resource_or_literal(id_resource_or_literal);


--
-- Name: versioned_quad versioned_quad_id_predicate_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versioned_quad
    ADD CONSTRAINT versioned_quad_id_predicate_fkey FOREIGN KEY (id_predicate) REFERENCES public.resource_or_literal(id_resource_or_literal);


--
-- Name: versioned_quad versioned_quad_id_subject_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versioned_quad
    ADD CONSTRAINT versioned_quad_id_subject_fkey FOREIGN KEY (id_subject) REFERENCES public.resource_or_literal(id_resource_or_literal);


--
-- PostgreSQL database dump complete
--

