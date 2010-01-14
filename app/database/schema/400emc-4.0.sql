--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = FALSE;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

SET search_path = public, pg_catalog;

SET DEFAULT_tablespace = '';

SET DEFAULT_with_oids = FALSE;

--
-- Name: billing_claim; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE billing_claim (
    rec_id INTEGER NOT NULL,
    billing_file_id INTEGER,
    staff_id INTEGER,
    client_id INTEGER,
    client_insurance_id INTEGER,
    insurance_rank INTEGER,
    client_insurance_authorization_id INTEGER
);



--
-- Name: TABLE billing_claim; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE billing_claim IS 'List of claims for one billing file';


--
-- Name: billing_claim_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE billing_claim_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: billing_claim_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE billing_claim_rec_id_seq OWNED BY billing_claim.rec_id;


--
-- Name: billing_claim_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('billing_claim_rec_id_seq', 1, FALSE);


--
-- Name: billing_cycle; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE billing_cycle (
    rec_id INTEGER NOT NULL,
    creation_date date DEFAULT ('now'::text)::date NOT NULL,
    staff_id INTEGER NOT NULL,
    step INTEGER DEFAULT 1 NOT NULL,
    status character varying(20)
);



--
-- Name: TABLE billing_cycle; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE billing_cycle IS 'Billing cycles, current AND previous';


--
-- Name: billing_cycle_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE billing_cycle_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: billing_cycle_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE billing_cycle_rec_id_seq OWNED BY billing_cycle.rec_id;


--
-- Name: billing_cycle_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('billing_cycle_rec_id_seq', 1, FALSE);


--
-- Name: billing_file; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE billing_file (
    rec_id INTEGER NOT NULL,
    billing_cycle_id INTEGER,
    group_control_number INTEGER,
    SET_control_number INTEGER,
    purpose character varying(2),
    "type" character varying(2),
    is_production boolean,
    submission_date timestamp without time zone,
    rolodex_id INTEGER,
    edi text
);



--
-- Name: TABLE billing_file; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE billing_file IS 'Billing files for one billing cycle';


--
-- Name: billing_file_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE billing_file_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: billing_file_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE billing_file_rec_id_seq OWNED BY billing_file.rec_id;


--
-- Name: billing_file_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('billing_file_rec_id_seq', 1, FALSE);


--
-- Name: billing_payment; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE billing_payment (
    rec_id INTEGER NOT NULL,
    edi_filename character varying(50),
    interchange_control_number INTEGER,
    is_production boolean,
    transaction_handling_code character varying(2),
    payment_amount numeric(18,2) NOT NULL,
    payment_method character varying(3),
    payment_date date NOT NULL,
    payment_number character varying(30),
    payment_company_id character varying(10),
    interchange_date DATE,
    date_received DATE,
    entered_by_staff_id INTEGER,
    rolodex_id INTEGER,
    edi text
);



--
-- Name: TABLE billing_payment; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE billing_payment IS 'Billing payment file';


--
-- Name: billing_payment_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE billing_payment_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: billing_payment_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE billing_payment_rec_id_seq OWNED BY billing_payment.rec_id;


--
-- Name: billing_payment_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('billing_payment_rec_id_seq', 1, FALSE);


--
-- Name: billing_prognote; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE billing_prognote (
    rec_id INTEGER NOT NULL,
    billing_service_id INTEGER,
    prognote_id INTEGER
);



--
-- Name: TABLE billing_prognote; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE billing_prognote IS 'List of prognotes associated with a service line';


--
-- Name: billing_prognote_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE billing_prognote_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: billing_prognote_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE billing_prognote_rec_id_seq OWNED BY billing_prognote.rec_id;


--
-- Name: billing_prognote_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('billing_prognote_rec_id_seq', 1, FALSE);


--
-- Name: billing_service; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE billing_service (
    rec_id INTEGER NOT NULL,
    billing_claim_id INTEGER,
    billed_amount numeric(18,2),
    billed_units INTEGER,
    line_number INTEGER
);



--
-- Name: TABLE billing_service; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE billing_service IS 'List of service lines associated with a single claim';


--
-- Name: billing_service_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE billing_service_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: billing_service_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE billing_service_rec_id_seq OWNED BY billing_service.rec_id;


--
-- Name: billing_service_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('billing_service_rec_id_seq', 1, FALSE);


--
-- Name: claims_processor; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE claims_processor (
    rec_id INTEGER NOT NULL,
    interchange_id_qualifier character varying(2),
    interchange_id character varying(15),
    code character varying(15),
    name character varying(35),
    primary_id character varying(80),
    clinic_trading_partner_id character varying(15),
    clinic_submitter_id character varying(80),
    requires_rendering_provider_ids BOOLEAN DEFAULT FALSE,
    template_837 character varying(30),
    password_active_days INTEGER,
    password_expires DATE,
    password_min_char INTEGER,
    username character varying(25),
    "password" character varying(25),
    sftp_host character varying(250),
    sftp_port INTEGER,
    dialup_number character varying(18),
    put_directory character varying(100),
    get_directory character varying(100),
    send_personnel_id BOOLEAN DEFAULT FALSE,
    send_production_files BOOLEAN DEFAULT FALSE
);



--
-- Name: TABLE claims_processor; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE claims_processor IS 'Insurance claims processors';


--
-- Name: claims_processor_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE claims_processor_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: claims_processor_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE claims_processor_rec_id_seq OWNED BY claims_processor.rec_id;


--
-- Name: claims_processor_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('claims_processor_rec_id_seq', 1, FALSE);


--
-- Name: client_client_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_client_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_client_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_client_id_seq', 1, TRUE);


--
-- Name: client; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client (
    client_id INTEGER DEFAULT nextval('client_client_id_seq'::regclass) NOT NULL,
    chart_id character varying(16),
    aka character varying(25),
    post_code character varying(10),
    phone character varying(18),
    phone_2 character varying(18),
    email character varying(64),
    sex character varying(25),
    race character varying(25),
    marital_status character varying(25),
    substance_abuse character varying(25),
    alcohol_abuse character varying(25),
    gambling_abuse character varying(25),
    religion character varying(25),
    acct_id character varying(10),
    county character varying(25),
    language_spoken character varying(25),
    sexual_identity character varying(25),
    state_specific_id INTEGER,
    edu_level INTEGER,
    working character(1),
    section_eight INTEGER,
    comment_text text,
    has_declaration_of_mh_treatment INTEGER,
    declaration_of_mh_treatment_date DATE,
    addr_2 character varying(255),
    city character varying(50),
    state character varying(50),
    prev_addr character varying(40),
    prev_addr_2 character varying(40),
    prev_city character varying(50),
    prev_state character varying(50),
    prev_post_code character varying(10),
    is_veteran INTEGER,
    is_citizen INTEGER,
    consent_to_treat INTEGER,
    addr character varying(255),
    living_arrangement character varying(255),
    renewal_date DATE,
    dont_call boolean,
    dob DATE,
    ssn character(11),
    mname character(15),
    fname character varying(30),
    lname character varying(30),
    name_suffix character varying(10)
);



--
-- Name: client_allergy; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_allergy (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    allergy character varying(255),
    created DATE,
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE client_allergy; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_allergy IS 'Patient Allergies';


--
-- Name: client_allergy_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_allergy_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_allergy_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_allergy_rec_id_seq OWNED BY client_allergy.rec_id;


--
-- Name: client_allergy_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_allergy_rec_id_seq', 1, FALSE);


--
-- Name: client_assessment; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_assessment (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    staff_id INTEGER NOT NULL,
    chart_id character varying(16),
    start_date DATE,
    end_date DATE,
    admit_reason text,
    refer_reason text,
    social_environ text,
    audit_trail text,
    esof_id INTEGER,
    esof_date DATE,
    esof_name text,
    esof_note text,
    danger_others text,
    danger_self text,
    chemical_abuse text,
    side_effects text,
    sharps_disposal text,
    alert_medical text,
    alert_other text,
    alert_note text,
    physical_abuse text,
    special_diet text,
    history_birth text,
    history_child text,
    history_milestone text,
    history_school text,
    history_social text,
    history_sexual text,
    history_dating text,
    medical_strengths text,
    medical_limits text,
    history_diag text,
    illness_past text,
    illness_family text,
    history_dental text,
    nutrition_needs text,
    appearance text,
    manner text,
    orientation character varying(24),
    functional character varying(24),
    mood character varying(24),
    affect character varying(24),
    mood_note text,
    relevant character varying(24),
    coherent character varying(24),
    tangential character varying(24),
    circumstantial character varying(24),
    blocking character varying(24),
    neologisms character varying(24),
    word_salad character varying(24),
    perseveration character varying(24),
    echolalia character varying(24),
    delusions character varying(24),
    hallucination character varying(24),
    suicidal character varying(24),
    homicidal character varying(24),
    obsessive character varying(24),
    thought_content text,
    psycho_motor character varying(24),
    speech_tone character varying(24),
    impulse_control character varying(24),
    speech_flow character varying(24),
    memory_recent character varying(24),
    memory_remote character varying(24),
    judgement character varying(24),
    insight character varying(24),
    intelligence character varying(24),
    present_problem text,
    psych_history text,
    homeless_history text,
    social_portrait text,
    work_history text,
    social_skills text,
    mica_history text,
    social_strengths text,
    financial_status text,
    legal_status text,
    military_history text,
    spiritual_orient text
);



--
-- Name: TABLE client_assessment; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_assessment IS 'Patient Assessment';


--
-- Name: client_assessment_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_assessment_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_assessment_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_assessment_rec_id_seq OWNED BY client_assessment.rec_id;


--
-- Name: client_assessment_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_assessment_rec_id_seq', 1, FALSE);


--
-- Name: client_contacts; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_contacts (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    rolodex_contacts_id INTEGER NOT NULL,
    contact_type_id INTEGER,
    comment_text text,
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE client_contacts; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_contacts IS 'Patient Contacts';


--
-- Name: client_contacts_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_contacts_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_contacts_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_contacts_rec_id_seq OWNED BY client_contacts.rec_id;


--
-- Name: client_contacts_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_contacts_rec_id_seq', 1, FALSE);


--
-- Name: client_diagnosis; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_diagnosis (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    diagnosis_date DATE,
    diagnosis_1a character varying(255),
    diagnosis_1b character varying(255),
    diagnosis_1c character varying(255),
    diagnosis_2a character varying(255),
    diagnosis_2b character varying(255),
    diagnosis_3 text,
    diagnosis_4 text,
    diagnosis_5_highest character varying(8),
    diagnosis_5_current character varying(8),
    comment_text text
);



--
-- Name: TABLE client_diagnosis; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_diagnosis IS 'Patient Diagnostic History';


--
-- Name: client_diagnosis_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_diagnosis_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_diagnosis_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_diagnosis_rec_id_seq OWNED BY client_diagnosis.rec_id;


--
-- Name: client_diagnosis_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_diagnosis_rec_id_seq', 1, FALSE);


--
-- Name: client_discharge; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_discharge (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    chart_id character varying(16),
    staff_name character varying(255),
    physician character varying(255),
    initial_diag_id INTEGER,
    final_diag_id INTEGER,
    admit_note text,
    history_clinical text,
    history_psych text,
    history_medical text,
    discharge_note text,
    after_care text,
    addr character(255),
    addr_2 character varying(255),
    city character varying(50),
    state character varying(50),
    post_code character(10),
    phone character(18),
    ref_agency character(255),
    ref_cont character(255),
    ref_date DATE,
    sent_summary character(1),
    sent_psycho_social character(1),
    sent_mental_stat character(1),
    sent_tx_plan character(1),
    sent_other character varying(255),
    sent_to text,
    sent_physical character(1),
    esof_id INTEGER,
    esof_date DATE,
    esof_name character varying(50),
    esof_note character varying(255),
    last_contact_date DATE,
    termination_notice_sent_date DATE,
    client_contests_termination INTEGER,
    education text,
    income numeric(19,2),
    employment_status text,
    employability_factor character varying(255),
    criminal_justice INTEGER,
    termination_reason character varying(255),
    "committed" INTEGER,
    client_placement_event_id INTEGER NOT NULL,
    audit_trail text
);



--
-- Name: TABLE client_discharge; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_discharge IS 'Patient Discharge Data';


--
-- Name: client_discharge_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_discharge_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_discharge_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_discharge_rec_id_seq OWNED BY client_discharge.rec_id;


--
-- Name: client_discharge_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_discharge_rec_id_seq', 1, FALSE);


--
-- Name: client_employment; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_employment (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    rolodex_employment_id INTEGER NOT NULL,
    job_title character varying(50),
    supervisor character varying(50),
    work_phone character varying(20),
    start_date DATE,
    end_date DATE,
    comment_text text,
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: client_employment_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_employment_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_employment_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_employment_rec_id_seq OWNED BY client_employment.rec_id;


--
-- Name: client_employment_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_employment_rec_id_seq', 1, FALSE);


--
-- Name: client_group; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_group (
    unit_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    track_id INTEGER NOT NULL,
    staff_id INTEGER NOT NULL,
    start_date DATE,
    group_site character varying(65),
    group_note text,
    attendance text,
    input_by character varying(30),
    timer character varying(8),
    group_category character varying(255)
);



--
-- Name: TABLE client_group; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_group IS 'Patient Group Notes';


--
-- Name: client_income; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_income (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    source_type_id INTEGER,
    start_date DATE,
    end_date DATE,
    income_amount numeric(19,2),
    account_id character varying(50),
    certification_date DATE,
    recertification_date DATE,
    has_direct_deposit INTEGER,
    is_recurring_income INTEGER,
    comment_text text
);



--
-- Name: TABLE client_income; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_income IS 'Patient Income';


--
-- Name: client_income_metadata; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_income_metadata (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    self_pay character(1),
    rep_payee character(1),
    bank_account character varying(80),
    css_id character varying(50)
);



--
-- Name: TABLE client_income_metadata; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_income_metadata IS 'Client data about income data';


--
-- Name: client_income_metadata_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_income_metadata_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_income_metadata_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_income_metadata_rec_id_seq OWNED BY client_income_metadata.rec_id;


--
-- Name: client_income_metadata_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_income_metadata_rec_id_seq', 1, FALSE);


--
-- Name: client_income_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_income_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_income_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_income_rec_id_seq OWNED BY client_income.rec_id;


--
-- Name: client_income_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_income_rec_id_seq', 1, FALSE);


--
-- Name: client_inpatient; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_inpatient (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    start_date DATE,
    end_date DATE,
    hospital character varying(50),
    addr character varying(40),
    hTYPE character varying(16),
    voluntary INTEGER,
    state_hosp character varying(3),
    reason text,
    comments text
);



--
-- Name: TABLE client_inpatient; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_inpatient IS 'Patient Inpatient History';


--
-- Name: client_inpatient_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_inpatient_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_inpatient_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_inpatient_rec_id_seq OWNED BY client_inpatient.rec_id;


--
-- Name: client_inpatient_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_inpatient_rec_id_seq', 1, FALSE);


--
-- Name: client_insurance; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_insurance (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    rolodex_insurance_id INTEGER NOT NULL,
    rank character varying(20),
    carrier_TYPE character varying(80),
    carrier_contact character varying(80),
    insurance_name character varying(50),
    insurance_id character varying(50),
    insured_name character varying(50),
    insured_addr character varying(50),
    insured_city character varying(50),
    insured_state character varying(50),
    insured_postcode character varying(50),
    insured_phone character varying(50),
    insured_group character varying(50),
    insured_dob character varying(10),
    insured_sex character varying(25),
    insured_employer character varying(50),
    other_plan character varying(8),
    other_name character varying(50),
    other_group character varying(50),
    other_dob character varying(10),
    other_sex character varying(25),
    other_employer character varying(50),
    other_plan_name character varying(50),
    co_pay_amount numeric(19,2),
    deductible_amount numeric(19,2),
    license_required character varying(80),
    comment_text text,
    start_date DATE,
    end_date DATE,
    insured_group_id character varying(30),
    insured_relationship_id INTEGER,
    insured_fname character varying(25),
    insured_lname character varying(35),
    insured_mname character varying(25),
    insured_name_suffix character varying(10),
    insured_addr2 character varying(50),
    patient_insurance_id character varying(50),
    insurance_type_id INTEGER
);



--
-- Name: TABLE client_insurance; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_insurance IS 'Patient Insurance Plan Data';


--
-- Name: client_insurance_authorization; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_insurance_authorization (
    rec_id INTEGER NOT NULL,
    client_insurance_id INTEGER NOT NULL,
    allowed_amount INTEGER,
    code character varying(80),
    "type" character varying(80),
    start_date DATE,
    end_date DATE,
    capitation_amount numeric(18,2),
    capitation_last_date date
);



--
-- Name: TABLE client_insurance_authorization; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_insurance_authorization IS 'Client insurance authorizations history';


--
-- Name: client_insurance_authorization_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_insurance_authorization_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_insurance_authorization_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_insurance_authorization_rec_id_seq OWNED BY client_insurance_authorization.rec_id;


--
-- Name: client_insurance_authorization_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_insurance_authorization_rec_id_seq', 1, FALSE);


--
-- Name: client_insurance_authorization_request; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_insurance_authorization_request (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    start_date DATE,
    end_date DATE,
    form text,
    provider_agency text,
    "location" text,
    diagnosis_primary text,
    diagnosis_secondary text,
    ohp text,
    medicare text,
    general_fund text,
    ohp_id text,
    medicare_id text,
    general_fund_id text,
    date_requested DATE,
    client_insurance_authorization_id INTEGER
);



--
-- Name: TABLE client_insurance_authorization_request; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_insurance_authorization_request IS 'Client insurance reauthorization request history';


--
-- Name: client_insurance_authorization_request_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_insurance_authorization_request_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_insurance_authorization_request_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_insurance_authorization_request_rec_id_seq OWNED BY client_insurance_authorization_request.rec_id;


--
-- Name: client_insurance_authorization_request_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_insurance_authorization_request_rec_id_seq', 1, FALSE);


--
-- Name: client_insurance_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_insurance_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_insurance_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_insurance_rec_id_seq OWNED BY client_insurance.rec_id;


--
-- Name: client_insurance_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_insurance_rec_id_seq', 1, FALSE);


--
-- Name: client_legal_history; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_legal_history (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    status_id INTEGER NOT NULL,
    location_id INTEGER NOT NULL,
    reason text,
    start_date DATE,
    end_date DATE,
    comment_text text
);



--
-- Name: TABLE client_legal_history; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_legal_history IS 'Patient Legal History';


--
-- Name: client_legal_history_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_legal_history_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_legal_history_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_legal_history_rec_id_seq OWNED BY client_legal_history.rec_id;


--
-- Name: client_legal_history_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_legal_history_rec_id_seq', 1, FALSE);


--
-- Name: client_letter_history; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_letter_history (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    rolodex_relationship_id INTEGER NOT NULL,
    relationship_role character varying NOT NULL,
    letter_TYPE character varying(255),
    letter text,
    sent_date date NOT NULL,
    print_header_id INTEGER
);



--
-- Name: TABLE client_letter_history; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_letter_history IS 'Patient PCP Letter History';


--
-- Name: client_letter_history_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_letter_history_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_letter_history_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_letter_history_rec_id_seq OWNED BY client_letter_history.rec_id;


--
-- Name: client_letter_history_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_letter_history_rec_id_seq', 1, FALSE);


--
-- Name: client_medication; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_medication (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    start_date DATE,
    end_date DATE,
    medication character varying(255),
    dosage character varying(25),
    frequency character varying(255),
    rolodex_treaters_id INTEGER NOT NULL,
    "location" character varying(60),
    inject_date DATE,
    instructions text,
    num_refills INTEGER,
    no_subs INTEGER,
    audit_trail text,
    quantity INTEGER,
    notes text,
    print_header_id INTEGER,
    print_date date
);



--
-- Name: TABLE client_medication; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_medication IS 'Patient Medication History';


--
-- Name: client_medication_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_medication_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_medication_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_medication_rec_id_seq OWNED BY client_medication.rec_id;


--
-- Name: client_medication_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_medication_rec_id_seq', 1, FALSE);


--
-- Name: client_placement_event; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_placement_event (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    dept_id INTEGER,
    program_id INTEGER,
    level_of_care_id INTEGER,
    staff_id INTEGER,
    event_date DATE,
    input_date timestamp without time zone DEFAULT now(),
    input_by_staff_id INTEGER,
    is_intake INTEGER DEFAULT 0,
    level_of_care_locked boolean
);



--
-- Name: TABLE client_placement_event; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_placement_event IS 'Patient Placement Data';


--
-- Name: client_placement_event_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_placement_event_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_placement_event_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_placement_event_rec_id_seq OWNED BY client_placement_event.rec_id;


--
-- Name: client_placement_event_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_placement_event_rec_id_seq', 1, FALSE);


--
-- Name: client_referral; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_referral (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    rolodex_referral_id INTEGER NOT NULL,
    agency_contact character varying(255),
    agency_TYPE character varying(255),
    active INTEGER DEFAULT 1 NOT NULL,
    client_placement_event_id INTEGER NOT NULL
);



--
-- Name: TABLE client_referral; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_referral IS 'Patient Referral Information';


--
-- Name: client_referral_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_referral_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_referral_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_referral_rec_id_seq OWNED BY client_referral.rec_id;


--
-- Name: client_referral_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_referral_rec_id_seq', 1, FALSE);


--
-- Name: client_release; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_release (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    rolodex_id INTEGER NOT NULL,
    standard INTEGER,
    release_list character varying(50),
    print_date DATE,
    renewal_date DATE,
    print_header_id INTEGER,
    release_from INTEGER,
    release_to INTEGER,
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE client_release; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_release IS 'Patient Release of Information';


--
-- Name: client_release_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_release_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_release_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_release_rec_id_seq OWNED BY client_release.rec_id;


--
-- Name: client_release_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_release_rec_id_seq', 1, FALSE);


--
-- Name: client_scanned_record; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_scanned_record (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    filename character varying(100) NOT NULL,
    description character varying(255),
    created timestamp without time zone NOT NULL,
    created_by INTEGER NOT NULL
);



--
-- Name: TABLE client_scanned_record; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_scanned_record IS 'Scanned medical record files associated with a client';


--
-- Name: client_scanned_record_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_scanned_record_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_scanned_record_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_scanned_record_rec_id_seq OWNED BY client_scanned_record.rec_id;


--
-- Name: client_scanned_record_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_scanned_record_rec_id_seq', 1, FALSE);


--
-- Name: client_treaters; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_treaters (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    rolodex_treaters_id INTEGER NOT NULL,
    last_visit DATE,
    start_date DATE,
    end_date DATE,
    start_time INTEGER,
    treater_agency character varying(255),
    treater_licence character varying(80),
    treater_type_id INTEGER,
    audit_trail text,
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: client_treaters_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_treaters_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_treaters_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_treaters_rec_id_seq OWNED BY client_treaters.rec_id;


--
-- Name: client_treaters_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_treaters_rec_id_seq', 1, FALSE);


--
-- Name: client_verification; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE client_verification (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    apid_num INTEGER NOT NULL,
    verif_date date NOT NULL,
    rolodex_treaters_id INTEGER,
    created date DEFAULT ('now'::text)::date,
    staff_id INTEGER NOT NULL
);



--
-- Name: TABLE client_verification; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE client_verification IS 'Patient Verification Letter Info';


--
-- Name: client_verification_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE client_verification_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: client_verification_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE client_verification_rec_id_seq OWNED BY client_verification.rec_id;


--
-- Name: client_verification_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('client_verification_rec_id_seq', 1, FALSE);


--
-- Name: config; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE config (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    value text
);



--
-- Name: TABLE config; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE config IS 'Application configuration';


--
-- Name: config_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE config_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: config_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE config_rec_id_seq OWNED BY config.rec_id;


--
-- Name: config_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('config_rec_id_seq', 32, TRUE);


--
-- Name: ecs_file_downloaded; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE ecs_file_downloaded (
    rec_id INTEGER NOT NULL,
    claims_processor_id INTEGER,
    name character varying(255),
    date_received timestamp without time zone
);



--
-- Name: TABLE ecs_file_downloaded; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE ecs_file_downloaded IS 'ECS files downloaded FROM each claims processor';


--
-- Name: ecs_file_downloaded_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE ecs_file_downloaded_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: ecs_file_downloaded_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE ecs_file_downloaded_rec_id_seq OWNED BY ecs_file_downloaded.rec_id;


--
-- Name: ecs_file_downloaded_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('ecs_file_downloaded_rec_id_seq', 1, FALSE);


--
-- Name: group_attendance; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE group_attendance (
    rec_id INTEGER NOT NULL,
    group_note_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    "action" character varying(20),
    prognote_id INTEGER
);



--
-- Name: group_attendance_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE group_attendance_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: group_attendance_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE group_attendance_rec_id_seq OWNED BY group_attendance.rec_id;


--
-- Name: group_attendance_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('group_attendance_rec_id_seq', 1, FALSE);


--
-- Name: group_members; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE group_members (
    rec_id INTEGER NOT NULL,
    group_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: group_members_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE group_members_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: group_members_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE group_members_rec_id_seq OWNED BY group_members.rec_id;


--
-- Name: group_members_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('group_members_rec_id_seq', 1, FALSE);


--
-- Name: group_notes; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE group_notes (
    rec_id INTEGER NOT NULL,
    group_id INTEGER NOT NULL,
    staff_id INTEGER NOT NULL,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    note_body text,
    data_entry_id INTEGER,
    charge_code_id INTEGER,
    note_location_id INTEGER,
    note_committed INTEGER,
    outcome_rating character varying(20)
);



--
-- Name: group_notes_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE group_notes_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: group_notes_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE group_notes_rec_id_seq OWNED BY group_notes.rec_id;


--
-- Name: group_notes_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('group_notes_rec_id_seq', 1, FALSE);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE groups (
    rec_id INTEGER NOT NULL,
    name character varying(255),
    description text,
    active INTEGER DEFAULT 1 NOT NULL,
    DEFAULT_note text
);



--
-- Name: groups_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE groups_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: groups_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE groups_rec_id_seq OWNED BY groups.rec_id;


--
-- Name: groups_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('groups_rec_id_seq', 1, FALSE);


--
-- Name: insurance_charge_code_association; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE insurance_charge_code_association (
    rec_id INTEGER NOT NULL,
    rolodex_id INTEGER,
    valid_data_charge_code_id INTEGER,
    acceptable BOOLEAN DEFAULT TRUE NOT NULL,
    dollars_per_unit numeric(6,2),
    max_units_allowed_per_encounter INTEGER,
    max_units_allowed_per_day INTEGER
);



--
-- Name: TABLE insurance_charge_code_association; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE insurance_charge_code_association IS 'Mental Health insurance payers joined with charge codes - overrides DEFAULTs in valid_data_charge_code';


--
-- Name: insurance_charge_code_association_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE insurance_charge_code_association_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: insurance_charge_code_association_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE insurance_charge_code_association_rec_id_seq OWNED BY insurance_charge_code_association.rec_id;


--
-- Name: insurance_charge_code_association_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('insurance_charge_code_association_rec_id_seq', 1, FALSE);


--
-- Name: lookup_associations; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE lookup_associations (
    rec_id INTEGER NOT NULL,
    lookup_table_id INTEGER,
    lookup_item_id INTEGER,
    lookup_group_id INTEGER
);



--
-- Name: lookup_associations_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE lookup_associations_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: lookup_associations_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE lookup_associations_rec_id_seq OWNED BY lookup_associations.rec_id;


--
-- Name: lookup_associations_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('lookup_associations_rec_id_seq', 1, FALSE);


--
-- Name: lookup_group_entries; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE lookup_group_entries (
    rec_id INTEGER NOT NULL,
    group_id INTEGER,
    item_id INTEGER
);



--
-- Name: lookup_group_entries_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE lookup_group_entries_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: lookup_group_entries_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE lookup_group_entries_rec_id_seq OWNED BY lookup_group_entries.rec_id;


--
-- Name: lookup_group_entries_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('lookup_group_entries_rec_id_seq', 1, FALSE);


--
-- Name: lookup_groups; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE lookup_groups (
    rec_id INTEGER NOT NULL,
    parent_id INTEGER,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL,
    "system" INTEGER DEFAULT 0 NOT NULL
);



--
-- Name: lookup_groups_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE lookup_groups_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: lookup_groups_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE lookup_groups_rec_id_seq OWNED BY lookup_groups.rec_id;


--
-- Name: lookup_groups_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('lookup_groups_rec_id_seq', 2, TRUE);


--
-- Name: migration_information; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

--CREATE TABLE migration_information (
    --version INTEGER NOT NULL,
    --date INTEGER NOT NULL
--);



--
-- Name: personnel; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE personnel (
    staff_id INTEGER NOT NULL,
    unit_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    "security" character varying(10),
    fname character(15),
    lname character(15),
    addr character(40),
    city character(40),
    state character(40),
    zip_code character(10),
    ssn character(11),
    dob DATE,
    home_phone character(14),
    work_phone character(14),
    next_kin character(50),
    job_title character(45),
    date_employ DATE,
    race character varying(25),
    sex character varying(25),
    marital_status character varying(25),
    super_visor INTEGER,
    over_time character(1),
    with_hold INTEGER,
    us_citizen character(8),
    super_visor_2 INTEGER,
    cdl character(1),
    admin_id INTEGER,
    credentials character(15),
    work_fax character(14),
    prefs text,
    work_hours character varying(25),
    hours_week INTEGER,
    rolodex_treaters_id INTEGER,
    productivity_week double precision,
    productivity_month double precision,
    productivity_year double precision,
    productivity_last_update timestamp without time zone,
    "login" character varying(128),
    "password" character(128),
    home_page_TYPE character varying(255),
    supervisor_id INTEGER,
    work_phone_ext character varying(10),
    name_suffix character varying(10),
    mname character varying(25),
    taxonomy_code character varying(30),
    medicaid_provider_number character varying(30),
    medicare_provider_number character varying(30),
    national_provider_id character varying(80)
);



--
-- Name: TABLE personnel; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE personnel IS 'Staff Data: Basic Demographics';


--
-- Name: personnel_lookup_associations; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE personnel_lookup_associations (
    rec_id INTEGER NOT NULL,
    staff_id INTEGER,
    lookup_group_id INTEGER,
    sticky INTEGER DEFAULT 0 NOT NULL
);



--
-- Name: personnel_lookup_associations_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE personnel_lookup_associations_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: personnel_lookup_associations_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE personnel_lookup_associations_rec_id_seq OWNED BY personnel_lookup_associations.rec_id;


--
-- Name: personnel_lookup_associations_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('personnel_lookup_associations_rec_id_seq', 1, FALSE);


--
-- Name: personnel_staff_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE personnel_staff_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: personnel_staff_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE personnel_staff_id_seq OWNED BY personnel.staff_id;


--
-- Name: personnel_staff_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('personnel_staff_id_seq', 1, TRUE);


--
-- Name: prognote; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE prognote (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    staff_id INTEGER NOT NULL,
    goal_id INTEGER NOT NULL,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    note_header character varying(40),
    note_body text,
    writer character varying(80),
    audit_trail text,
    data_entry_id INTEGER,
    charge_code_id INTEGER,
    note_location_id INTEGER,
    note_committed INTEGER,
    outcome_rating character varying(20),
    billing_status character varying(80) DEFAULT 'Unbilled'::character varying,
    created timestamp without time zone,
    modified timestamp without time zone,
    group_id INTEGER,
    unbillable_per_writer BOOLEAN DEFAULT FALSE,
    bill_manually BOOLEAN DEFAULT FALSE,
    previous_billing_status character varying(255)
);



--
-- Name: TABLE prognote; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE prognote IS 'Patient Clinical Notes';


--
-- Name: prognote_bounced; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE prognote_bounced (
    rec_id INTEGER NOT NULL,
    prognote_id INTEGER NOT NULL,
    bounced_by_staff_id INTEGER NOT NULL,
    bounce_date date DEFAULT (now())::date NOT NULL,
    bounce_message text NOT NULL,
    response_date DATE,
    response_message text
);



--
-- Name: TABLE prognote_bounced; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE prognote_bounced IS 'Progress notes which have been sent FROM the billing cycle back to the writer for correction.';


--
-- Name: prognote_bounced_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE prognote_bounced_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: prognote_bounced_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE prognote_bounced_rec_id_seq OWNED BY prognote_bounced.rec_id;


--
-- Name: prognote_bounced_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('prognote_bounced_rec_id_seq', 1, FALSE);


--
-- Name: prognote_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE prognote_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: prognote_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE prognote_rec_id_seq OWNED BY prognote.rec_id;


--
-- Name: prognote_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('prognote_rec_id_seq', 1, FALSE);


--
-- Name: rolodex; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE rolodex (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    generic INTEGER DEFAULT 0 NOT NULL,
    name character varying(80),
    fname character varying(50),
    lname character varying(50),
    credentials character varying(255),
    addr character varying(75),
    addr_2 character varying(50),
    city character varying(50),
    state character varying(50),
    post_code character varying(25),
    phone character varying(25),
    phone_2 character varying(25),
    comment_text text,
    client_id INTEGER,
    claims_processor_id INTEGER,
    edi_id character varying(80),
    edi_name character varying(35),
    edi_indicator_code character varying(2)
);



--
-- Name: rolodex_contacts; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE rolodex_contacts (
    rec_id INTEGER NOT NULL,
    rolodex_id INTEGER NOT NULL
);



--
-- Name: rolodex_contacts_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE rolodex_contacts_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: rolodex_contacts_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE rolodex_contacts_rec_id_seq OWNED BY rolodex_contacts.rec_id;


--
-- Name: rolodex_contacts_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('rolodex_contacts_rec_id_seq', 1, FALSE);


--
-- Name: rolodex_dental_insurance; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE rolodex_dental_insurance (
    rec_id INTEGER NOT NULL,
    rolodex_id INTEGER NOT NULL
);



--
-- Name: rolodex_dental_insurance_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE rolodex_dental_insurance_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: rolodex_dental_insurance_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE rolodex_dental_insurance_rec_id_seq OWNED BY rolodex_dental_insurance.rec_id;


--
-- Name: rolodex_dental_insurance_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('rolodex_dental_insurance_rec_id_seq', 1, FALSE);


--
-- Name: rolodex_employment; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE rolodex_employment (
    rec_id INTEGER NOT NULL,
    rolodex_id INTEGER NOT NULL
);



--
-- Name: rolodex_employment_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE rolodex_employment_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: rolodex_employment_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE rolodex_employment_rec_id_seq OWNED BY rolodex_employment.rec_id;


--
-- Name: rolodex_employment_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('rolodex_employment_rec_id_seq', 1, FALSE);


--
-- Name: rolodex_medical_insurance; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE rolodex_medical_insurance (
    rec_id INTEGER NOT NULL,
    rolodex_id INTEGER NOT NULL
);



--
-- Name: rolodex_medical_insurance_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE rolodex_medical_insurance_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: rolodex_medical_insurance_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE rolodex_medical_insurance_rec_id_seq OWNED BY rolodex_medical_insurance.rec_id;


--
-- Name: rolodex_medical_insurance_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('rolodex_medical_insurance_rec_id_seq', 1, FALSE);


--
-- Name: rolodex_mental_health_insurance; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE rolodex_mental_health_insurance (
    rec_id INTEGER NOT NULL,
    rolodex_id INTEGER NOT NULL
);



--
-- Name: rolodex_mental_health_insurance_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE rolodex_mental_health_insurance_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: rolodex_mental_health_insurance_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE rolodex_mental_health_insurance_rec_id_seq OWNED BY rolodex_mental_health_insurance.rec_id;


--
-- Name: rolodex_mental_health_insurance_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('rolodex_mental_health_insurance_rec_id_seq', 1, FALSE);


--
-- Name: rolodex_prescribers; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE rolodex_prescribers (
    rec_id INTEGER NOT NULL,
    rolodex_id INTEGER NOT NULL
);



--
-- Name: rolodex_prescribers_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE rolodex_prescribers_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: rolodex_prescribers_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE rolodex_prescribers_rec_id_seq OWNED BY rolodex_prescribers.rec_id;


--
-- Name: rolodex_prescribers_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('rolodex_prescribers_rec_id_seq', 1, FALSE);


--
-- Name: rolodex_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE rolodex_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: rolodex_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE rolodex_rec_id_seq OWNED BY rolodex.rec_id;


--
-- Name: rolodex_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('rolodex_rec_id_seq', 1, FALSE);


--
-- Name: rolodex_referral; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE rolodex_referral (
    rec_id INTEGER NOT NULL,
    rolodex_id INTEGER NOT NULL
);



--
-- Name: rolodex_referral_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE rolodex_referral_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: rolodex_referral_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE rolodex_referral_rec_id_seq OWNED BY rolodex_referral.rec_id;


--
-- Name: rolodex_referral_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('rolodex_referral_rec_id_seq', 1, FALSE);


--
-- Name: rolodex_release; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE rolodex_release (
    rec_id INTEGER NOT NULL,
    rolodex_id INTEGER NOT NULL
);



--
-- Name: rolodex_release_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE rolodex_release_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: rolodex_release_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE rolodex_release_rec_id_seq OWNED BY rolodex_release.rec_id;


--
-- Name: rolodex_release_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('rolodex_release_rec_id_seq', 1, FALSE);


--
-- Name: rolodex_treaters; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE rolodex_treaters (
    rec_id INTEGER NOT NULL,
    rolodex_id INTEGER NOT NULL
);



--
-- Name: rolodex_treaters_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE rolodex_treaters_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: rolodex_treaters_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE rolodex_treaters_rec_id_seq OWNED BY rolodex_treaters.rec_id;


--
-- Name: rolodex_treaters_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('rolodex_treaters_rec_id_seq', 1, FALSE);


--
-- Name: schedule_appointments; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE schedule_appointments (
    rec_id INTEGER NOT NULL,
    schedule_availability_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    confirm_code_id INTEGER,
    noshow boolean,
    fax boolean,
    chart boolean,
    payment_code_id INTEGER,
    auth_number text,
    notes text,
    appt_time time without time zone NOT NULL,
    staff_id INTEGER NOT NULL
);



--
-- Name: TABLE schedule_appointments; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE schedule_appointments IS 'Appointments associated with a client AND schedule availability entry';


--
-- Name: schedule_appointments_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE schedule_appointments_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: schedule_appointments_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE schedule_appointments_rec_id_seq OWNED BY schedule_appointments.rec_id;


--
-- Name: schedule_appointments_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('schedule_appointments_rec_id_seq', 1, FALSE);


--
-- Name: schedule_availability; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE schedule_availability (
    rec_id INTEGER NOT NULL,
    rolodex_id INTEGER NOT NULL,
    location_id INTEGER NOT NULL,
    date date NOT NULL
);



--
-- Name: TABLE schedule_availability; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE schedule_availability IS 'Availability of doctors per location per date';


--
-- Name: schedule_availability_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE schedule_availability_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: schedule_availability_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE schedule_availability_rec_id_seq OWNED BY schedule_availability.rec_id;


--
-- Name: schedule_availability_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('schedule_availability_rec_id_seq', 1, FALSE);


--
-- Name: schedule_type_associations; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE schedule_type_associations (
    rec_id INTEGER NOT NULL,
    rolodex_id INTEGER NOT NULL,
    schedule_type_id INTEGER NOT NULL
);



--
-- Name: TABLE schedule_type_associations; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE schedule_type_associations IS 'Associating schedule types AND doctors (rolodex objects)';


--
-- Name: schedule_type_associations_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE schedule_type_associations_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: schedule_type_associations_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE schedule_type_associations_rec_id_seq OWNED BY schedule_type_associations.rec_id;


--
-- Name: schedule_type_associations_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('schedule_type_associations_rec_id_seq', 1, FALSE);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE sessions (
    id character(32) NOT NULL,
    a_session bytea NOT NULL
);



--
-- Name: TABLE sessions; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE sessions IS 'User login sessions';


--
-- Name: similar_rolodex; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE similar_rolodex (
    rolodex_id INTEGER NOT NULL,
    matching_ids character varying,
    modified timestamp without time zone
);



--
-- Name: transaction; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE "transaction" (
    rec_id INTEGER NOT NULL,
    billing_service_id INTEGER NOT NULL,
    billing_payment_id INTEGER NOT NULL,
    paid_amount numeric(18,2) NOT NULL,
    paid_units INTEGER NOT NULL,
    claim_status_code INTEGER,
    patient_responsibility_amount numeric(18,2),
    payer_claim_control_number character varying(30),
    paid_charge_code character varying(48),
    submitted_charge_code_if_applicable character varying(48),
    remarks text,
    entered_in_error BOOLEAN DEFAULT FALSE,
    refunded BOOLEAN DEFAULT FALSE
);



--
-- Name: TABLE "transaction"; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE "transaction" IS 'Claims Submission Transactions';


--
-- Name: transaction_deduction; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE transaction_deduction (
    rec_id INTEGER NOT NULL,
    transaction_id INTEGER NOT NULL,
    amount numeric(18,2) NOT NULL,
    units INTEGER,
    group_code character varying(2),
    reason_code character varying(5) NOT NULL
);



--
-- Name: TABLE transaction_deduction; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE transaction_deduction IS 'Deductions FROM transactions';


--
-- Name: transaction_deduction_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE transaction_deduction_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: transaction_deduction_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE transaction_deduction_rec_id_seq OWNED BY transaction_deduction.rec_id;


--
-- Name: transaction_deduction_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('transaction_deduction_rec_id_seq', 1, FALSE);


--
-- Name: transaction_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE transaction_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: transaction_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE transaction_rec_id_seq OWNED BY "transaction".rec_id;


--
-- Name: transaction_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('transaction_rec_id_seq', 1, FALSE);


--
-- Name: tx_goals; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE tx_goals (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    staff_id INTEGER NOT NULL,
    plan_id INTEGER NOT NULL,
    medicaid INTEGER,
    start_date DATE,
    end_date DATE,
    goal text,
    goal_stat character varying(4),
    goal_header text,
    goal_name character varying(250),
    problem_description text,
    eval text,
    comment_text text,
    goal_code INTEGER,
    rstat INTEGER,
    serv text,
    audit_trail text,
    active INTEGER DEFAULT 1
);



--
-- Name: TABLE tx_goals; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE tx_goals IS 'Patient Treatment Goals';


--
-- Name: tx_goals_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE tx_goals_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: tx_goals_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE tx_goals_rec_id_seq OWNED BY tx_goals.rec_id;


--
-- Name: tx_goals_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('tx_goals_rec_id_seq', 1, FALSE);


--
-- Name: tx_plan; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE tx_plan (
    rec_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    chart_id character varying(16),
    staff_id INTEGER NOT NULL,
    start_date DATE,
    end_date DATE,
    period character varying(25),
    esof_id INTEGER,
    esof_date DATE,
    esof_name character varying(50),
    esof_note character varying(255),
    asSETs text,
    debits text,
    case_worker character varying(65),
    src_worker character varying(65),
    supervisor character varying(65),
    meets_dsm4 INTEGER,
    needs_selfcare INTEGER,
    needs_skills INTEGER,
    needs_support INTEGER,
    needs_adl INTEGER,
    needs_focus INTEGER,
    active INTEGER DEFAULT 1
);



--
-- Name: TABLE tx_plan; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE tx_plan IS 'Patient Treatment Plans';


--
-- Name: tx_plan_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE tx_plan_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: tx_plan_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE tx_plan_rec_id_seq OWNED BY tx_plan.rec_id;


--
-- Name: tx_plan_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('tx_plan_rec_id_seq', 1, FALSE);


--
-- Name: v_contacts; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW v_contacts AS
    SELECT rc.rec_id AS rolodex_contacts_id, r.rec_id AS rolodex_id, r.rec_id, r.dept_id, r.generic, r.name, r.fname, r.lname, r.credentials, r.addr, r.addr_2, r.city, r.state, r.post_code, r.phone, r.phone_2, r.comment_text, r.client_id, r.claims_processor_id, r.edi_id, r.edi_name, r.edi_indicator_code FROM (rolodex r JOIN rolodex_contacts rc ON ((r.rec_id = rc.rolodex_id)));



--
-- Name: v_client_contacts; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW v_client_contacts AS
    SELECT cc.rec_id AS client_contacts_id, cc.comment_text AS cc_comment_text, cc.client_id AS contact_for_client_id, cc.contact_type_id, c.rolodex_contacts_id, c.rolodex_id, c.rec_id, c.dept_id, c.generic, c.name, c.fname, c.lname, c.credentials, c.addr, c.addr_2, c.city, c.state, c.post_code, c.phone, c.phone_2, c.comment_text, c.client_id, c.claims_processor_id, c.edi_id, c.edi_name, c.edi_indicator_code FROM (client_contacts cc JOIN v_contacts c ON ((cc.rolodex_contacts_id = c.rolodex_contacts_id)));



--
-- Name: v_treaters; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW v_treaters AS
    SELECT rt.rec_id AS rolodex_treaters_id, r.rec_id AS rolodex_id, r.rec_id, r.dept_id, r.generic, r.name, r.fname, r.lname, r.credentials, r.addr, r.addr_2, r.city, r.state, r.post_code, r.phone, r.phone_2, r.comment_text, r.client_id, r.claims_processor_id, r.edi_id, r.edi_name, r.edi_indicator_code FROM (rolodex r JOIN rolodex_treaters rt ON ((r.rec_id = rt.rolodex_id)));



--
-- Name: v_client_treaters; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW v_client_treaters AS
    SELECT ct.rec_id AS client_treaters_id, ct.client_id AS treater_for_client_id, ct.last_visit, ct.start_date, ct.end_date, ct.start_time, ct.treater_agency, ct.treater_licence, ct.treater_type_id, ct.audit_trail, ct.active, t.rolodex_treaters_id, t.rolodex_id, t.rec_id, t.dept_id, t.generic, t.name, t.fname, t.lname, t.credentials, t.addr, t.addr_2, t.city, t.state, t.post_code, t.phone, t.phone_2, t.comment_text, t.client_id, t.claims_processor_id, t.edi_id, t.edi_name, t.edi_indicator_code FROM (client_treaters ct JOIN v_treaters t ON ((ct.rolodex_treaters_id = t.rolodex_treaters_id)));



--
-- Name: v_emergency_contacts; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW v_emergency_contacts AS
    SELECT vcc.client_contacts_id, vcc.cc_comment_text, vcc.contact_for_client_id, vcc.contact_type_id, vcc.rolodex_contacts_id, vcc.rolodex_id, vcc.rec_id, vcc.dept_id, vcc.generic, vcc.name, vcc.fname, vcc.lname, vcc.credentials, vcc.addr, vcc.addr_2, vcc.city, vcc.state, vcc.post_code, vcc.phone, vcc.phone_2, vcc.comment_text, vcc.client_id, vcc.claims_processor_id, vcc.edi_id, vcc.edi_name, vcc.edi_indicator_code FROM v_client_contacts vcc WHERE (vcc.contact_type_id = 3);



--
-- Name: valid_data_abuse; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_abuse (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_abuse; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_abuse IS 'Valid Substance Abuse Codes';


--
-- Name: valid_data_abuse_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_abuse_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_abuse_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_abuse_rec_id_seq OWNED BY valid_data_abuse.rec_id;


--
-- Name: valid_data_abuse_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_abuse_rec_id_seq', 3, TRUE);


--
-- Name: valid_data_adjustment_group_codes; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_adjustment_group_codes (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(1024),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_adjustment_group_codes; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_adjustment_group_codes IS 'Adjustment Group Codes';


--
-- Name: valid_data_adjustment_group_codes_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_adjustment_group_codes_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_adjustment_group_codes_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_adjustment_group_codes_rec_id_seq OWNED BY valid_data_adjustment_group_codes.rec_id;


--
-- Name: valid_data_adjustment_group_codes_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_adjustment_group_codes_rec_id_seq', 5, TRUE);


--
-- Name: valid_data_charge_code; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_charge_code (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL,
    min_allowable_time INTEGER,
    max_allowable_time INTEGER,
    minutes_per_unit INTEGER,
    dollars_per_unit numeric(6,2),
    max_units_allowed_per_encounter INTEGER,
    max_units_allowed_per_day INTEGER,
    cost_calculation_method character varying(30),
    CONSTRAINT valid_data_charge_code_cost_calculation_method_check CHECK (((cost_calculation_method)::text = ANY ((ARRAY['Per Session'::character varying, 'Dollars per Unit'::character varying, 'Pro Rated Dollars per Unit'::character varying])::text[])))
);



--
-- Name: TABLE valid_data_charge_code; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_charge_code IS 'CPT Code Descriptions';


--
-- Name: valid_data_charge_code_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_charge_code_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_charge_code_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_charge_code_rec_id_seq OWNED BY valid_data_charge_code.rec_id;


--
-- Name: valid_data_charge_code_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_charge_code_rec_id_seq', 3, TRUE);


--
-- Name: valid_data_claim_adjustment_codes; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_claim_adjustment_codes (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(1024),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_claim_adjustment_codes; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_claim_adjustment_codes IS 'EDI 835 Claim Adjustment Reason Codes -- updated 6/30/06 -- complete list http://www.wpc-edi.com/codes/claimadjustment';


--
-- Name: valid_data_claim_adjustment_codes_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_claim_adjustment_codes_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_claim_adjustment_codes_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_claim_adjustment_codes_rec_id_seq OWNED BY valid_data_claim_adjustment_codes.rec_id;


--
-- Name: valid_data_claim_adjustment_codes_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_claim_adjustment_codes_rec_id_seq', 250, TRUE);


--
-- Name: valid_data_claim_status_codes; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_claim_status_codes (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_claim_status_codes; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_claim_status_codes IS 'Electronic Claims code for the status of the claim';


--
-- Name: valid_data_claim_status_codes_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_claim_status_codes_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_claim_status_codes_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_claim_status_codes_rec_id_seq OWNED BY valid_data_claim_status_codes.rec_id;


--
-- Name: valid_data_claim_status_codes_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_claim_status_codes_rec_id_seq', 17, TRUE);


--
-- Name: valid_data_confirmation_codes; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_confirmation_codes (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_confirmation_codes; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_confirmation_codes IS 'Confirmation codes';


--
-- Name: valid_data_confirmation_codes_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_confirmation_codes_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_confirmation_codes_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_confirmation_codes_rec_id_seq OWNED BY valid_data_confirmation_codes.rec_id;


--
-- Name: valid_data_confirmation_codes_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_confirmation_codes_rec_id_seq', 7, TRUE);


--
-- Name: valid_data_contact_type; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_contact_TYPE (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_contact_type; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_contact_TYPE IS 'Contact Types';


--
-- Name: valid_data_contact_type_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_contact_type_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_contact_type_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_contact_type_rec_id_seq OWNED BY valid_data_contact_type.rec_id;


--
-- Name: valid_data_contact_type_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_contact_type_rec_id_seq', 11, TRUE);


--
-- Name: valid_data_dsm4; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_dsm4 (
    axis INTEGER,
    name character varying(8),
    level_num INTEGER,
    category INTEGER,
    hdr INTEGER,
    description character varying(255),
    rec_id INTEGER NOT NULL,
    dept_id INTEGER DEFAULT 1001 NOT NULL,
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_dsm4; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_dsm4 IS 'DSM IV Detail';


--
-- Name: valid_data_dsm4_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_dsm4_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_dsm4_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_dsm4_rec_id_seq OWNED BY valid_data_dsm4.rec_id;


--
-- Name: valid_data_dsm4_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_dsm4_rec_id_seq', 561, TRUE);


--
-- Name: valid_data_element_errors; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_element_errors (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(1024),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_element_errors; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_element_errors IS 'EDI 997 Data Element Syntax Error Codes';


--
-- Name: valid_data_element_errors_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_element_errors_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_element_errors_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_element_errors_rec_id_seq OWNED BY valid_data_element_errors.rec_id;


--
-- Name: valid_data_element_errors_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_element_errors_rec_id_seq', 10, TRUE);


--
-- Name: valid_data_employability; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_employability (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: valid_data_employability_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_employability_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_employability_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_employability_rec_id_seq OWNED BY valid_data_employability.rec_id;


--
-- Name: valid_data_employability_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_employability_rec_id_seq', 1, FALSE);


--
-- Name: valid_data_functional_group_ack_codes; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_functional_group_ack_codes (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(1024),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_functional_group_ack_codes; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_functional_group_ack_codes IS 'EDI 997 Functional Group Acknowledge Codes';


--
-- Name: valid_data_functional_group_ack_codes_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_functional_group_ack_codes_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_functional_group_ack_codes_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_functional_group_ack_codes_rec_id_seq OWNED BY valid_data_functional_group_ack_codes.rec_id;


--
-- Name: valid_data_functional_group_ack_codes_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_functional_group_ack_codes_rec_id_seq', 7, TRUE);


--
-- Name: valid_data_functional_group_errors; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_functional_group_errors (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(1024),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_functional_group_errors; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_functional_group_errors IS 'EDI 997 Functional Group Syntax Error Codes';


--
-- Name: valid_data_functional_group_errors_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_functional_group_errors_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_functional_group_errors_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_functional_group_errors_rec_id_seq OWNED BY valid_data_functional_group_errors.rec_id;


--
-- Name: valid_data_functional_group_errors_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_functional_group_errors_rec_id_seq', 19, TRUE);


--
-- Name: valid_data_groupnote_templates; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_groupnote_templates (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description text,
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_groupnote_templates; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_groupnote_templates IS 'Group Note Templates';


--
-- Name: valid_data_groupnote_templates_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_groupnote_templates_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_groupnote_templates_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_groupnote_templates_rec_id_seq OWNED BY valid_data_groupnote_templates.rec_id;


--
-- Name: valid_data_groupnote_templates_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_groupnote_templates_rec_id_seq', 1, FALSE);


--
-- Name: valid_data_housing_complex; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_housing_complex (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_housing_complex; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_housing_complex IS 'Housing Complexes';


--
-- Name: valid_data_housing_complex_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_housing_complex_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_housing_complex_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_housing_complex_rec_id_seq OWNED BY valid_data_housing_complex.rec_id;


--
-- Name: valid_data_housing_complex_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_housing_complex_rec_id_seq', 1, FALSE);


--
-- Name: valid_data_income_sources; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_income_sources (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_income_sources; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_income_sources IS 'Income Sources (SSI, SSD, Wages)';


--
-- Name: valid_data_income_sources_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_income_sources_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_income_sources_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_income_sources_rec_id_seq OWNED BY valid_data_income_sources.rec_id;


--
-- Name: valid_data_income_sources_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_income_sources_rec_id_seq', 1, TRUE);


--
-- Name: valid_data_insurance_relationship; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_insurance_relationship (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL,
    code character varying(2) NOT NULL
);



--
-- Name: TABLE valid_data_insurance_relationship; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_insurance_relationship IS 'Electronic Claims code for Patient''s Relationship to Insured';


--
-- Name: valid_data_insurance_relationship_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_insurance_relationship_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_insurance_relationship_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_insurance_relationship_rec_id_seq OWNED BY valid_data_insurance_relationship.rec_id;


--
-- Name: valid_data_insurance_relationship_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_insurance_relationship_rec_id_seq', 26, TRUE);


--
-- Name: valid_data_insurance_type; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_insurance_TYPE (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(1024),
    active INTEGER DEFAULT 1 NOT NULL,
    code character varying(3) NOT NULL
);



--
-- Name: TABLE valid_data_insurance_type; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_insurance_TYPE IS 'Insurance Type Codes';


--
-- Name: valid_data_insurance_type_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_insurance_type_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_insurance_type_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_insurance_type_rec_id_seq OWNED BY valid_data_insurance_type.rec_id;


--
-- Name: valid_data_insurance_type_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_insurance_type_rec_id_seq', 15, TRUE);


--
-- Name: valid_data_interchange_ack_codes; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_interchange_ack_codes (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(1024),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_interchange_ack_codes; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_interchange_ack_codes IS 'EDI TA1 Interchange Acknowledgment Codes';


--
-- Name: valid_data_interchange_ack_codes_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_interchange_ack_codes_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_interchange_ack_codes_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_interchange_ack_codes_rec_id_seq OWNED BY valid_data_interchange_ack_codes.rec_id;


--
-- Name: valid_data_interchange_ack_codes_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_interchange_ack_codes_rec_id_seq', 3, TRUE);


--
-- Name: valid_data_interchange_note_codes; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_interchange_note_codes (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(1024),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_interchange_note_codes; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_interchange_note_codes IS 'EDI TA1 Interchange Note Codes';


--
-- Name: valid_data_interchange_note_codes_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_interchange_note_codes_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_interchange_note_codes_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_interchange_note_codes_rec_id_seq OWNED BY valid_data_interchange_note_codes.rec_id;


--
-- Name: valid_data_interchange_note_codes_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_interchange_note_codes_rec_id_seq', 32, TRUE);


--
-- Name: valid_data_language; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_language (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_language; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_language IS 'Valid Language Type Codes';


--
-- Name: valid_data_language_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_language_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_language_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_language_rec_id_seq OWNED BY valid_data_language.rec_id;


--
-- Name: valid_data_language_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_language_rec_id_seq', 4, TRUE);


--
-- Name: valid_data_legal_location; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_legal_location (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_legal_location; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_legal_location IS 'Legal Location Lookup';


--
-- Name: valid_data_legal_location_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_legal_location_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_legal_location_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_legal_location_rec_id_seq OWNED BY valid_data_legal_location.rec_id;


--
-- Name: valid_data_legal_location_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_legal_location_rec_id_seq', 1, TRUE);


--
-- Name: valid_data_legal_status; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_legal_status (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_legal_status; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_legal_status IS 'Legal Status Lookup';


--
-- Name: valid_data_legal_status_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_legal_status_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_legal_status_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_legal_status_rec_id_seq OWNED BY valid_data_legal_status.rec_id;


--
-- Name: valid_data_legal_status_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_legal_status_rec_id_seq', 1, TRUE);


--
-- Name: valid_data_letter_templates; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_letter_templates (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description text,
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_letter_templates; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_letter_templates IS 'PCP Letter Templates';


--
-- Name: valid_data_letter_templates_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_letter_templates_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_letter_templates_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_letter_templates_rec_id_seq OWNED BY valid_data_letter_templates.rec_id;


--
-- Name: valid_data_letter_templates_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_letter_templates_rec_id_seq', 1, FALSE);


--
-- Name: valid_data_level_of_care; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_level_of_care (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    visit_frequency INTEGER,
    visit_interval character varying(20),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_level_of_care; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_level_of_care IS 'Valid Level of Care';


--
-- Name: valid_data_level_of_care_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_level_of_care_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_level_of_care_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_level_of_care_rec_id_seq OWNED BY valid_data_level_of_care.rec_id;


--
-- Name: valid_data_level_of_care_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_level_of_care_rec_id_seq', 1, FALSE);


--
-- Name: valid_data_living_arrangement; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_living_arrangement (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_living_arrangement; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_living_arrangement IS 'Patient Living Arrangement Status Codes';


--
-- Name: valid_data_living_arrangement_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_living_arrangement_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_living_arrangement_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_living_arrangement_rec_id_seq OWNED BY valid_data_living_arrangement.rec_id;


--
-- Name: valid_data_living_arrangement_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_living_arrangement_rec_id_seq', 1, FALSE);


--
-- Name: valid_data_marital_status; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_marital_status (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL,
    is_married boolean
);



--
-- Name: TABLE valid_data_marital_status; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_marital_status IS 'Valid Marital Status Codes';


--
-- Name: valid_data_marital_status_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_marital_status_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_marital_status_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_marital_status_rec_id_seq OWNED BY valid_data_marital_status.rec_id;


--
-- Name: valid_data_marital_status_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_marital_status_rec_id_seq', 2, TRUE);


--
-- Name: valid_data_medication; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_medication (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_medication; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_medication IS 'Valid Medication Names';


--
-- Name: valid_data_medication_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_medication_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_medication_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_medication_rec_id_seq OWNED BY valid_data_medication.rec_id;


--
-- Name: valid_data_medication_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_medication_rec_id_seq', 1, TRUE);


--
-- Name: valid_data_payment_codes; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_payment_codes (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_payment_codes; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_payment_codes IS 'Payment types';


--
-- Name: valid_data_payment_codes_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_payment_codes_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_payment_codes_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_payment_codes_rec_id_seq OWNED BY valid_data_payment_codes.rec_id;


--
-- Name: valid_data_payment_codes_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_payment_codes_rec_id_seq', 19, TRUE);


--
-- Name: valid_data_print_header; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_print_header (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description text,
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: valid_data_print_header_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_print_header_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_print_header_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_print_header_rec_id_seq OWNED BY valid_data_print_header.rec_id;


--
-- Name: valid_data_print_header_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_print_header_rec_id_seq', 1, TRUE);


--
-- Name: valid_data_prognote_billing_status; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_prognote_billing_status (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(80),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_prognote_billing_status; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_prognote_billing_status IS 'Progress Note Billing Stati';


--
-- Name: valid_data_prognote_billing_status_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_prognote_billing_status_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_prognote_billing_status_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_prognote_billing_status_rec_id_seq OWNED BY valid_data_prognote_billing_status.rec_id;


--
-- Name: valid_data_prognote_billing_status_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_prognote_billing_status_rec_id_seq', 1, TRUE);


--
-- Name: valid_data_prognote_location; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_prognote_location (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL,
    facility_code character varying(2)
);



--
-- Name: TABLE valid_data_prognote_location; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_prognote_location IS 'Note Writing Location';


--
-- Name: valid_data_prognote_location_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_prognote_location_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_prognote_location_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_prognote_location_rec_id_seq OWNED BY valid_data_prognote_location.rec_id;


--
-- Name: valid_data_prognote_location_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_prognote_location_rec_id_seq', 1, TRUE);


--
-- Name: valid_data_prognote_templates; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_prognote_templates (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description text,
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_prognote_templates; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_prognote_templates IS 'Note Writing Templates';


--
-- Name: valid_data_prognote_templates_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_prognote_templates_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_prognote_templates_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_prognote_templates_rec_id_seq OWNED BY valid_data_prognote_templates.rec_id;


--
-- Name: valid_data_prognote_templates_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_prognote_templates_rec_id_seq', 1, FALSE);


--
-- Name: valid_data_program; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_program (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    number INTEGER,
    active INTEGER DEFAULT 1 NOT NULL,
    is_referral INTEGER DEFAULT 0 NOT NULL,
    addr character varying(255),
    city character varying(50),
    state character varying(50),
    zip character varying(10)
);



--
-- Name: TABLE valid_data_program; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_program IS 'Valid Treatment Programs';


--
-- Name: valid_data_program_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_program_rec_id_seq
    START WITH 3
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_program_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_program_rec_id_seq OWNED BY valid_data_program.rec_id;


--
-- Name: valid_data_program_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_program_rec_id_seq', 3, FALSE);


--
-- Name: valid_data_race; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_race (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: valid_data_race_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_race_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_race_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_race_rec_id_seq OWNED BY valid_data_race.rec_id;


--
-- Name: valid_data_race_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_race_rec_id_seq', 4, TRUE);


--
-- Name: valid_data_release; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_release (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_release; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_release IS 'Release of Information Descriptions';


--
-- Name: valid_data_release_bits; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_release_bits (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description text,
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: valid_data_release_bits_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_release_bits_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_release_bits_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_release_bits_rec_id_seq OWNED BY valid_data_release_bits.rec_id;


--
-- Name: valid_data_release_bits_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_release_bits_rec_id_seq', 1, FALSE);


--
-- Name: valid_data_release_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_release_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_release_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_release_rec_id_seq OWNED BY valid_data_release.rec_id;


--
-- Name: valid_data_release_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_release_rec_id_seq', 13, TRUE);


--
-- Name: valid_data_religion; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_religion (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_religion; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_religion IS 'Valid Religion Type Codes';


--
-- Name: valid_data_religion_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_religion_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_religion_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_religion_rec_id_seq OWNED BY valid_data_religion.rec_id;


--
-- Name: valid_data_religion_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_religion_rec_id_seq', 4, TRUE);


--
-- Name: valid_data_remittance_remark_codes; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_remittance_remark_codes (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(1024),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_remittance_remark_codes; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_remittance_remark_codes IS 'EDI 835 Remittance Advice Remark Codes -- updated 7/31/06 -- complete list http://www.wpc-edi.com/codes/remittanceadvice';


--
-- Name: valid_data_remittance_remark_codes_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_remittance_remark_codes_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_remittance_remark_codes_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_remittance_remark_codes_rec_id_seq OWNED BY valid_data_remittance_remark_codes.rec_id;


--
-- Name: valid_data_remittance_remark_codes_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_remittance_remark_codes_rec_id_seq', 657, TRUE);


--
-- Name: valid_data_rolodex_roles; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_rolodex_roles (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: valid_data_rolodex_roles_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_rolodex_roles_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_rolodex_roles_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_rolodex_roles_rec_id_seq OWNED BY valid_data_rolodex_roles.rec_id;


--
-- Name: valid_data_rolodex_roles_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_rolodex_roles_rec_id_seq', 9, TRUE);


--
-- Name: valid_data_schedule_types; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_schedule_types (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    schedule_interval INTEGER,
    schedule_multiplier INTEGER DEFAULT 1 NOT NULL,
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_schedule_types; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_schedule_types IS 'Valid Schedule Type';


--
-- Name: valid_data_schedule_types_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_schedule_types_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_schedule_types_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_schedule_types_rec_id_seq OWNED BY valid_data_schedule_types.rec_id;


--
-- Name: valid_data_schedule_types_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_schedule_types_rec_id_seq', 2, TRUE);


--
-- Name: valid_data_segment_errors; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_segment_errors (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(1024),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_segment_errors; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_segment_errors IS 'EDI 997 Segment Syntax Error Codes';


--
-- Name: valid_data_segment_errors_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_segment_errors_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_segment_errors_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_segment_errors_rec_id_seq OWNED BY valid_data_segment_errors.rec_id;


--
-- Name: valid_data_segment_errors_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_segment_errors_rec_id_seq', 8, TRUE);


--
-- Name: valid_data_sex; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_sex (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_sex; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_sex IS 'Valid Sex/Gender Codes';


--
-- Name: valid_data_sex_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_sex_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_sex_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_sex_rec_id_seq OWNED BY valid_data_sex.rec_id;


--
-- Name: valid_data_sex_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_sex_rec_id_seq', 2, TRUE);


--
-- Name: valid_data_sexual_identity; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_sexual_identity (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_sexual_identity; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_sexual_identity IS 'Valid Sexual Identity Codes';


--
-- Name: valid_data_sexual_identity_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_sexual_identity_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_sexual_identity_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_sexual_identity_rec_id_seq OWNED BY valid_data_sexual_identity.rec_id;


--
-- Name: valid_data_sexual_identity_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_sexual_identity_rec_id_seq', 1, TRUE);


--
-- Name: valid_data_termination_reasons; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_termination_reasons (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: valid_data_termination_reasons_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_termination_reasons_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_termination_reasons_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_termination_reasons_rec_id_seq OWNED BY valid_data_termination_reasons.rec_id;


--
-- Name: valid_data_termination_reasons_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_termination_reasons_rec_id_seq', 1, TRUE);


--
-- Name: valid_data_transaction_handling; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_transaction_handling (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_transaction_handling; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_transaction_handling IS 'Electronic Claims code for how the payment is sent with the 835';


--
-- Name: valid_data_transaction_handling_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_transaction_handling_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_transaction_handling_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_transaction_handling_rec_id_seq OWNED BY valid_data_transaction_handling.rec_id;


--
-- Name: valid_data_transaction_handling_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_transaction_handling_rec_id_seq', 3, TRUE);


--
-- Name: valid_data_transaction_set_ack_codes; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_transaction_set_ack_codes (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(1024),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_transaction_set_ack_codes; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_transaction_set_ack_codes IS 'EDI 997 Transaction Set Acknowledgement Codes';


--
-- Name: valid_data_transaction_set_ack_codes_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_transaction_set_ack_codes_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_transaction_set_ack_codes_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_transaction_set_ack_codes_rec_id_seq OWNED BY valid_data_transaction_set_ack_codes.rec_id;


--
-- Name: valid_data_transaction_set_ack_codes_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_transaction_set_ack_codes_rec_id_seq', 6, TRUE);


--
-- Name: valid_data_transaction_set_errors; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_transaction_set_errors (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(1024),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_transaction_set_errors; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_transaction_set_errors IS 'EDI 997 Transaction Set Syntax Error Codes';


--
-- Name: valid_data_transaction_set_errors_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_transaction_set_errors_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_transaction_set_errors_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_transaction_set_errors_rec_id_seq OWNED BY valid_data_transaction_set_errors.rec_id;


--
-- Name: valid_data_transaction_set_errors_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_transaction_set_errors_rec_id_seq', 21, TRUE);


--
-- Name: valid_data_treater_types; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_treater_types (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    active INTEGER DEFAULT 1 NOT NULL
);



--
-- Name: TABLE valid_data_treater_types; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE valid_data_treater_types IS 'Valid Treater Types';


--
-- Name: valid_data_treater_types_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_treater_types_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_treater_types_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_treater_types_rec_id_seq OWNED BY valid_data_treater_types.rec_id;


--
-- Name: valid_data_treater_types_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_treater_types_rec_id_seq', 2, TRUE);


--
-- Name: valid_data_valid_data; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE valid_data_valid_data (
    rec_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    name character varying(255),
    description character varying(255),
    readonly INTEGER DEFAULT 0,
    active INTEGER DEFAULT 1 NOT NULL,
    extra_columns character varying(255)
);



--
-- Name: valid_data_valid_data_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE valid_data_valid_data_rec_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: valid_data_valid_data_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE valid_data_valid_data_rec_id_seq OWNED BY valid_data_valid_data.rec_id;


--
-- Name: valid_data_valid_data_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('valid_data_valid_data_rec_id_seq', 47, TRUE);


--
-- Name: validation_prognote; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE validation_prognote (
    rec_id INTEGER NOT NULL,
    validation_set_id INTEGER,
    prognote_id INTEGER,
    rolodex_id INTEGER,
    payer_validation BOOLEAN DEFAULT FALSE NOT NULL,
    force_valid boolean
);



--
-- Name: TABLE validation_prognote; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE validation_prognote IS 'List of prognotes being validated in a single cycle';


--
-- Name: validation_prognote_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE validation_prognote_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: validation_prognote_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE validation_prognote_rec_id_seq OWNED BY validation_prognote.rec_id;


--
-- Name: validation_prognote_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('validation_prognote_rec_id_seq', 1, FALSE);


--
-- Name: validation_result; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE validation_result (
    rec_id INTEGER NOT NULL,
    validation_prognote_id INTEGER,
    validation_rule_id INTEGER,
    pass BOOLEAN DEFAULT TRUE NOT NULL
);



--
-- Name: TABLE validation_result; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE validation_result IS 'Results of validation on group of prognotes in validation_prognote';


--
-- Name: validation_result_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE validation_result_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: validation_result_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE validation_result_rec_id_seq OWNED BY validation_result.rec_id;


--
-- Name: validation_result_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('validation_result_rec_id_seq', 1, FALSE);


--
-- Name: validation_rule; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE validation_rule (
    rec_id INTEGER NOT NULL,
    name character varying(255) NOT NULL,
    rule_SELECT text,
    rule_from text,
    rule_where text,
    rule_order text,
    selects_pass BOOLEAN DEFAULT TRUE NOT NULL,
    error_message character varying(255) NOT NULL,
    scope character varying(20) DEFAULT 'system'::character varying NOT NULL
);



--
-- Name: TABLE validation_rule; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE validation_rule IS 'List of rules to validate progress notes for billing';


--
-- Name: validation_rule_last_used; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE validation_rule_last_used (
    rec_id INTEGER NOT NULL,
    validation_rule_id INTEGER,
    rolodex_id INTEGER
);



--
-- Name: TABLE validation_rule_last_used; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE validation_rule_last_used IS 'If AND how validation rules were last used.';


--
-- Name: validation_rule_last_used_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE validation_rule_last_used_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: validation_rule_last_used_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE validation_rule_last_used_rec_id_seq OWNED BY validation_rule_last_used.rec_id;


--
-- Name: validation_rule_last_used_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('validation_rule_last_used_rec_id_seq', 1, FALSE);


--
-- Name: validation_rule_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE validation_rule_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: validation_rule_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE validation_rule_rec_id_seq OWNED BY validation_rule.rec_id;


--
-- Name: validation_rule_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('validation_rule_rec_id_seq', 1, FALSE);


--
-- Name: validation_SET; Type: TABLE; Schema: public; Owner: ryan; Tablespace: 
--

CREATE TABLE validation_SET (
    rec_id INTEGER NOT NULL,
    creation_date date DEFAULT ('now'::text)::date NOT NULL,
    from_date date DEFAULT ('now'::text)::date NOT NULL,
    to_date date DEFAULT ('now'::text)::date NOT NULL,
    staff_id INTEGER NOT NULL,
    billing_cycle_id INTEGER,
    step INTEGER DEFAULT 1 NOT NULL,
    status character varying(20)
);



--
-- Name: TABLE validation_SET; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON TABLE validation_SET IS 'Parent of a list of prognotes in validation_prognote';


--
-- Name: validation_set_rec_id_seq; Type: SEQUENCE; Schema: public; Owner: ryan
--

CREATE SEQUENCE validation_set_rec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;



--
-- Name: validation_set_rec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ryan
--

ALTER SEQUENCE validation_set_rec_id_seq OWNED BY validation_SET.rec_id;


--
-- Name: validation_set_rec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ryan
--

SELECT pg_catalog.SETval('validation_set_rec_id_seq', 1, FALSE);


--
-- Name: view_bill_manually_prognotes; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW view_bill_manually_prognotes AS
    SELECT prognote.rec_id, prognote.client_id, prognote.staff_id, prognote.goal_id, prognote.start_date, prognote.end_date, prognote.note_header, prognote.note_body, prognote.writer, prognote.audit_trail, prognote.data_entry_id, prognote.charge_code_id, prognote.note_location_id, prognote.note_committed, prognote.outcome_rating, prognote.billing_status, prognote.created, prognote.modified, prognote.group_id, prognote.unbillable_per_writer, prognote.bill_manually FROM prognote WHERE ((prognote.bill_manually = TRUE) AND ((prognote.billing_status IS NULL) OR ((prognote.billing_status)::text <> 'BilledManually'::text)));



--
-- Name: VIEW view_bill_manually_prognotes; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON VIEW view_bill_manually_prognotes IS 'Prognotes which have been marked for manual billing, but which have not yet finished going through the manual billing process.';


--
-- Name: view_billing_service_required_provider_ids; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW view_billing_service_required_provider_ids AS
    SELECT billing_service.rec_id, claims_processor.requires_rendering_provider_ids FROM billing_service, billing_claim, billing_file, rolodex, claims_processor WHERE ((((billing_service.billing_claim_id = billing_claim.rec_id) AND (billing_claim.billing_file_id = billing_file.rec_id)) AND (billing_file.rolodex_id = rolodex.rec_id)) AND (rolodex.claims_processor_id = claims_processor.rec_id));



--
-- Name: VIEW view_billing_service_required_provider_ids; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON VIEW view_billing_service_required_provider_ids IS 'Billing services, whether the payer they were billed to requires rendering provider IDs';


--
-- Name: view_billings_by_prognote; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW view_billings_by_prognote AS
    SELECT date(billing_file.submission_date) AS billed_date, billing_service.billed_amount, prognote.rec_id AS prognote_id, billing_claim.insurance_rank, billing_service.rec_id AS billing_service_id, billing_payment.payment_date AS paid_date, "transaction".paid_amount, "transaction".refunded FROM ((((((billing_file JOIN billing_claim ON ((billing_file.rec_id = billing_claim.billing_file_id))) JOIN billing_service ON ((billing_claim.rec_id = billing_service.billing_claim_id))) JOIN billing_prognote ON ((billing_prognote.billing_service_id = billing_service.rec_id))) JOIN prognote ON ((billing_prognote.prognote_id = prognote.rec_id))) LEFT JOIN "transaction" ON (((billing_service.rec_id = "transaction".billing_service_id) AND (("transaction".entered_in_error <> TRUE) OR ("transaction".entered_in_error IS NULL))))) LEFT JOIN billing_payment ON (("transaction".billing_payment_id = billing_payment.rec_id))) WHERE ((billing_file.submission_date)::text > (0)::text);



--
-- Name: VIEW view_billings_by_prognote; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON VIEW view_billings_by_prognote IS 'All billings by prognote';


--
-- Name: view_service_first_prognote; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW view_service_first_prognote AS
    SELECT DISTINCT ON (billing_service.rec_id) billing_service.rec_id AS billing_service_id, prognote.rec_id, prognote.client_id, prognote.staff_id, prognote.goal_id, prognote.start_date, prognote.end_date, prognote.note_header, prognote.note_body, prognote.writer, prognote.audit_trail, prognote.data_entry_id, prognote.charge_code_id, prognote.note_location_id, prognote.note_committed, prognote.outcome_rating, prognote.billing_status, prognote.created, prognote.modified, prognote.group_id, prognote.unbillable_per_writer, prognote.bill_manually FROM billing_service, billing_prognote, prognote WHERE ((billing_prognote.billing_service_id = billing_service.rec_id) AND (billing_prognote.prognote_id = prognote.rec_id)) ORDER BY billing_service.rec_id, prognote.start_date;



--
-- Name: VIEW view_service_first_prognote; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON VIEW view_service_first_prognote IS 'The first prognote (earliest) for each billing_service.';


--
-- Name: view_client_billings; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW view_client_billings AS
    SELECT billing_claim.client_id, date(billing_file.submission_date) AS billed_date, billing_service.billed_amount, billing_file.rolodex_id, first_prognote.rec_id AS prognote_id, billing_service.rec_id AS billing_service_id FROM (((billing_file JOIN billing_claim ON ((billing_file.rec_id = billing_claim.billing_file_id))) JOIN billing_service ON ((billing_claim.rec_id = billing_service.billing_claim_id))) JOIN view_service_first_prognote first_prognote ON ((billing_service.rec_id = first_prognote.billing_service_id))) WHERE (billing_claim.insurance_rank = 1);



--
-- Name: VIEW view_client_billings; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON VIEW view_client_billings IS 'All billings by client';


--
-- Name: view_client_payments; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW view_client_payments AS
    SELECT billing_claim.client_id, billing_payment.payment_date AS paid_date, "transaction".paid_amount, billing_payment.rolodex_id, billing_service.rec_id AS billing_service_id FROM (((billing_payment JOIN "transaction" ON ((billing_payment.rec_id = "transaction".billing_payment_id))) JOIN billing_service ON (("transaction".billing_service_id = billing_service.rec_id))) JOIN billing_claim ON ((billing_service.billing_claim_id = billing_claim.rec_id))) WHERE ((("transaction".entered_in_error <> TRUE) OR ("transaction".entered_in_error IS NULL)) AND (("transaction".refunded <> TRUE) OR ("transaction".refunded IS NULL)));



--
-- Name: VIEW view_client_payments; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON VIEW view_client_payments IS 'All payments by client';


--
-- Name: view_client_placement; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW view_client_placement AS
    SELECT DISTINCT ON (client_placement_event.client_id) client_placement_event.rec_id, client_placement_event.client_id, client_placement_event.dept_id, client_placement_event.program_id, client_placement_event.level_of_care_id, client_placement_event.staff_id, client_placement_event.event_date, client_placement_event.input_date, client_placement_event.input_by_staff_id, client_placement_event.is_intake, client_placement_event.level_of_care_locked FROM client_placement_event ORDER BY client_placement_event.client_id, client_placement_event.event_date DESC, client_placement_event.rec_id DESC;



--
-- Name: VIEW view_client_placement; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON VIEW view_client_placement IS 'Current client placement';


--
-- Name: view_client_writeoffs; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW view_client_writeoffs AS
    SELECT c.client_id, bpay.payment_date, COALESCE(billings.billings_total, (0)::numeric) AS billings_total, payments.payments_total, (COALESCE(billings.billings_total, (0)::numeric) - payments.payments_total) AS balance FROM ((((((client c JOIN billing_claim bclaim ON ((bclaim.client_id = c.client_id))) JOIN billing_service bserv ON ((bserv.billing_claim_id = bclaim.rec_id))) JOIN "transaction" t ON ((t.billing_service_id = bserv.rec_id))) JOIN billing_payment bpay ON ((t.billing_payment_id = bpay.rec_id))) LEFT JOIN (SELECT cb.billing_service_id, sum(cb.billed_amount) AS billings_total FROM view_client_billings cb GROUP BY cb.billing_service_id) billings ON ((bserv.rec_id = billings.billing_service_id))) LEFT JOIN (SELECT cp.billing_service_id, sum(cp.paid_amount) AS payments_total FROM view_client_payments cp GROUP BY cp.billing_service_id) payments ON ((bserv.rec_id = payments.billing_service_id))) WHERE (bserv.rec_id IN (SELECT billing_service.rec_id FROM billing_service, billing_prognote, prognote WHERE (((billing_service.rec_id = billing_prognote.billing_service_id) AND (billing_prognote.prognote_id = prognote.rec_id)) AND ((prognote.billing_status)::text = 'Unbillable'::text))));



--
-- Name: VIEW view_client_writeoffs; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON VIEW view_client_writeoffs IS 'All clients with unbillable balances';


--
-- Name: view_identical_prognotes; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW view_identical_prognotes AS
    SELECT p.rec_id AS source_rec_id, identical.rec_id, identical.client_id, identical.staff_id, identical.goal_id, identical.start_date, identical.end_date, identical.note_header, identical.note_body, identical.writer, identical.audit_trail, identical.data_entry_id, identical.charge_code_id, identical.note_location_id, identical.note_committed, identical.outcome_rating, identical.billing_status, identical.created, identical.modified, identical.group_id, identical.unbillable_per_writer, identical.bill_manually FROM (prognote p JOIN prognote identical ON (((((p.client_id = identical.client_id) AND (date(p.start_date) = date(identical.start_date))) AND (p.charge_code_id = identical.charge_code_id)) AND (p.note_location_id = identical.note_location_id))));



--
-- Name: VIEW view_identical_prognotes; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON VIEW view_identical_prognotes IS 'Prognotes which have identical business keys (client, DATE, charge_code AND location) but which are not the same row.';


--
-- Name: view_prognote_billed; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW view_prognote_billed AS
    SELECT billing_prognote.prognote_id FROM billing_prognote, billing_service WHERE ((billing_prognote.billing_service_id = billing_service.rec_id) AND (billing_service.billed_amount > (0)::numeric));



--
-- Name: VIEW view_prognote_billed; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON VIEW view_prognote_billed IS 'Prognotes that have been billed (are in a billing_service WHERE billed_amount > 0)';


--
-- Name: view_prognote_insurances; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW view_prognote_insurances AS
    SELECT prognote.rec_id AS prognote_id, client_insurance.rec_id AS client_insurance_id, client_insurance.rank, rolodex.rec_id AS rolodex_id, client_insurance_authorization.rec_id FROM prognote, client_insurance, client_insurance_authorization, rolodex_mental_health_insurance, rolodex WHERE ((((((((prognote.client_id = client_insurance.client_id) AND ((client_insurance.carrier_type)::text = 'mental health'::text)) AND (date(prognote.start_date) >= client_insurance.start_date)) AND ((client_insurance.end_date IS NULL) OR (date(prognote.start_date) <= client_insurance.end_date))) AND (client_insurance_authorization.client_insurance_id = client_insurance.rec_id)) AND ((prognote.start_date >= client_insurance_authorization.start_date) AND (prognote.start_date <= client_insurance_authorization.end_date))) AND (client_insurance.rolodex_insurance_id = rolodex_mental_health_insurance.rec_id)) AND (rolodex_mental_health_insurance.rolodex_id = rolodex.rec_id)) ORDER BY prognote.rec_id;



--
-- Name: VIEW view_prognote_insurances; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON VIEW view_prognote_insurances IS 'Insurances that can be billed for this prognote.';


--
-- Name: view_transaction_deductions; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW view_transaction_deductions AS
    SELECT transaction_deduction.transaction_id, COALESCE(sum(transaction_deduction.amount), (0)::numeric) AS deductions FROM transaction_deduction GROUP BY transaction_deduction.transaction_id;



--
-- Name: VIEW view_transaction_deductions; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON VIEW view_transaction_deductions IS 'Deductions FROM transactions, summed by transaction';


--
-- Name: view_unpaid_billed_services; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW view_unpaid_billed_services AS
    SELECT billing_service.rec_id FROM billing_service WHERE ((NOT (billing_service.rec_id IN (SELECT "transaction".billing_service_id FROM "transaction" WHERE (("transaction".entered_in_error <> TRUE) OR ("transaction".entered_in_error IS NULL))))) AND (billing_service.billed_amount > (0)::numeric));



--
-- Name: VIEW view_unpaid_billed_services; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON VIEW view_unpaid_billed_services IS 'billing_services which have been billed, but have no valid transactions.';


--
-- Name: view_unpaid_billed_prognotes; Type: VIEW; Schema: public; Owner: ryan
--

CREATE VIEW view_unpaid_billed_prognotes AS
    SELECT billing_prognote.prognote_id, count(*) AS unpaid_services FROM (billing_service JOIN billing_prognote ON ((billing_prognote.billing_service_id = billing_service.rec_id))) WHERE (billing_service.rec_id IN (SELECT view_unpaid_billed_services.rec_id FROM view_unpaid_billed_services)) GROUP BY billing_prognote.prognote_id;



--
-- Name: VIEW view_unpaid_billed_prognotes; Type: COMMENT; Schema: public; Owner: ryan
--

COMMENT ON VIEW view_unpaid_billed_prognotes IS 'Prognotes which have one or more unpaid billing_service lines associated with them.';


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE billing_claim ALTER COLUMN rec_id SET DEFAULT nextval('billing_claim_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE billing_cycle ALTER COLUMN rec_id SET DEFAULT nextval('billing_cycle_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE billing_file ALTER COLUMN rec_id SET DEFAULT nextval('billing_file_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE billing_payment ALTER COLUMN rec_id SET DEFAULT nextval('billing_payment_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE billing_prognote ALTER COLUMN rec_id SET DEFAULT nextval('billing_prognote_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE billing_service ALTER COLUMN rec_id SET DEFAULT nextval('billing_service_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE claims_processor ALTER COLUMN rec_id SET DEFAULT nextval('claims_processor_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_allergy ALTER COLUMN rec_id SET DEFAULT nextval('client_allergy_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_assessment ALTER COLUMN rec_id SET DEFAULT nextval('client_assessment_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_contacts ALTER COLUMN rec_id SET DEFAULT nextval('client_contacts_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_diagnosis ALTER COLUMN rec_id SET DEFAULT nextval('client_diagnosis_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_discharge ALTER COLUMN rec_id SET DEFAULT nextval('client_discharge_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_employment ALTER COLUMN rec_id SET DEFAULT nextval('client_employment_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_income ALTER COLUMN rec_id SET DEFAULT nextval('client_income_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_income_metadata ALTER COLUMN rec_id SET DEFAULT nextval('client_income_metadata_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_inpatient ALTER COLUMN rec_id SET DEFAULT nextval('client_inpatient_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_insurance ALTER COLUMN rec_id SET DEFAULT nextval('client_insurance_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_insurance_authorization ALTER COLUMN rec_id SET DEFAULT nextval('client_insurance_authorization_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_insurance_authorization_request ALTER COLUMN rec_id SET DEFAULT nextval('client_insurance_authorization_request_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_legal_history ALTER COLUMN rec_id SET DEFAULT nextval('client_legal_history_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_letter_history ALTER COLUMN rec_id SET DEFAULT nextval('client_letter_history_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_medication ALTER COLUMN rec_id SET DEFAULT nextval('client_medication_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_placement_event ALTER COLUMN rec_id SET DEFAULT nextval('client_placement_event_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_referral ALTER COLUMN rec_id SET DEFAULT nextval('client_referral_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_release ALTER COLUMN rec_id SET DEFAULT nextval('client_release_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_scanned_record ALTER COLUMN rec_id SET DEFAULT nextval('client_scanned_record_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_treaters ALTER COLUMN rec_id SET DEFAULT nextval('client_treaters_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE client_verification ALTER COLUMN rec_id SET DEFAULT nextval('client_verification_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE config ALTER COLUMN rec_id SET DEFAULT nextval('config_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE ecs_file_downloaded ALTER COLUMN rec_id SET DEFAULT nextval('ecs_file_downloaded_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE group_attendance ALTER COLUMN rec_id SET DEFAULT nextval('group_attendance_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE group_members ALTER COLUMN rec_id SET DEFAULT nextval('group_members_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE group_notes ALTER COLUMN rec_id SET DEFAULT nextval('group_notes_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE groups ALTER COLUMN rec_id SET DEFAULT nextval('groups_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE insurance_charge_code_association ALTER COLUMN rec_id SET DEFAULT nextval('insurance_charge_code_association_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE lookup_associations ALTER COLUMN rec_id SET DEFAULT nextval('lookup_associations_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE lookup_group_entries ALTER COLUMN rec_id SET DEFAULT nextval('lookup_group_entries_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE lookup_groups ALTER COLUMN rec_id SET DEFAULT nextval('lookup_groups_rec_id_seq'::regclass);


--
-- Name: staff_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE personnel ALTER COLUMN staff_id SET DEFAULT nextval('personnel_staff_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE personnel_lookup_associations ALTER COLUMN rec_id SET DEFAULT nextval('personnel_lookup_associations_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE prognote ALTER COLUMN rec_id SET DEFAULT nextval('prognote_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE prognote_bounced ALTER COLUMN rec_id SET DEFAULT nextval('prognote_bounced_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE rolodex ALTER COLUMN rec_id SET DEFAULT nextval('rolodex_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE rolodex_contacts ALTER COLUMN rec_id SET DEFAULT nextval('rolodex_contacts_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE rolodex_dental_insurance ALTER COLUMN rec_id SET DEFAULT nextval('rolodex_dental_insurance_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE rolodex_employment ALTER COLUMN rec_id SET DEFAULT nextval('rolodex_employment_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE rolodex_medical_insurance ALTER COLUMN rec_id SET DEFAULT nextval('rolodex_medical_insurance_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE rolodex_mental_health_insurance ALTER COLUMN rec_id SET DEFAULT nextval('rolodex_mental_health_insurance_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE rolodex_prescribers ALTER COLUMN rec_id SET DEFAULT nextval('rolodex_prescribers_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE rolodex_referral ALTER COLUMN rec_id SET DEFAULT nextval('rolodex_referral_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE rolodex_release ALTER COLUMN rec_id SET DEFAULT nextval('rolodex_release_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE rolodex_treaters ALTER COLUMN rec_id SET DEFAULT nextval('rolodex_treaters_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE schedule_appointments ALTER COLUMN rec_id SET DEFAULT nextval('schedule_appointments_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE schedule_availability ALTER COLUMN rec_id SET DEFAULT nextval('schedule_availability_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE schedule_type_associations ALTER COLUMN rec_id SET DEFAULT nextval('schedule_type_associations_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE "transaction" ALTER COLUMN rec_id SET DEFAULT nextval('transaction_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE transaction_deduction ALTER COLUMN rec_id SET DEFAULT nextval('transaction_deduction_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE tx_goals ALTER COLUMN rec_id SET DEFAULT nextval('tx_goals_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE tx_plan ALTER COLUMN rec_id SET DEFAULT nextval('tx_plan_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_abuse ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_abuse_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_adjustment_group_codes ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_adjustment_group_codes_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_charge_code ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_charge_code_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_claim_adjustment_codes ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_claim_adjustment_codes_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_claim_status_codes ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_claim_status_codes_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_confirmation_codes ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_confirmation_codes_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_contact_TYPE ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_contact_type_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_dsm4 ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_dsm4_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_element_errors ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_element_errors_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_employability ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_employability_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_functional_group_ack_codes ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_functional_group_ack_codes_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_functional_group_errors ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_functional_group_errors_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_groupnote_templates ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_groupnote_templates_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_housing_complex ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_housing_complex_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_income_sources ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_income_sources_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_insurance_relationship ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_insurance_relationship_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_insurance_TYPE ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_insurance_type_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_interchange_ack_codes ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_interchange_ack_codes_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_interchange_note_codes ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_interchange_note_codes_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_language ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_language_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_legal_location ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_legal_location_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_legal_status ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_legal_status_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_letter_templates ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_letter_templates_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_level_of_care ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_level_of_care_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_living_arrangement ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_living_arrangement_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_marital_status ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_marital_status_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_medication ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_medication_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_payment_codes ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_payment_codes_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_print_header ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_print_header_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_prognote_billing_status ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_prognote_billing_status_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_prognote_location ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_prognote_location_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_prognote_templates ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_prognote_templates_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_program ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_program_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_race ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_race_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_release ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_release_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_release_bits ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_release_bits_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_religion ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_religion_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_remittance_remark_codes ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_remittance_remark_codes_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_rolodex_roles ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_rolodex_roles_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_schedule_types ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_schedule_types_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_segment_errors ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_segment_errors_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_sex ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_sex_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_sexual_identity ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_sexual_identity_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_termination_reasons ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_termination_reasons_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_transaction_handling ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_transaction_handling_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_transaction_set_ack_codes ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_transaction_set_ack_codes_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_transaction_set_errors ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_transaction_set_errors_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_treater_types ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_treater_types_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE valid_data_valid_data ALTER COLUMN rec_id SET DEFAULT nextval('valid_data_valid_data_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE validation_prognote ALTER COLUMN rec_id SET DEFAULT nextval('validation_prognote_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE validation_result ALTER COLUMN rec_id SET DEFAULT nextval('validation_result_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE validation_rule ALTER COLUMN rec_id SET DEFAULT nextval('validation_rule_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE validation_rule_last_used ALTER COLUMN rec_id SET DEFAULT nextval('validation_rule_last_used_rec_id_seq'::regclass);


--
-- Name: rec_id; Type: DEFAULT; Schema: public; Owner: ryan
--

ALTER TABLE validation_SET ALTER COLUMN rec_id SET DEFAULT nextval('validation_set_rec_id_seq'::regclass);


--
-- Data for Name: billing_claim; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY billing_claim (rec_id, billing_file_id, staff_id, client_id, client_insurance_id, insurance_rank, client_insurance_authorization_id) FROM stdin;
\.


--
-- Data for Name: billing_cycle; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY billing_cycle (rec_id, creation_date, staff_id, step, status) FROM stdin;
\.


--
-- Data for Name: billing_file; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY billing_file (rec_id, billing_cycle_id, group_control_number, SET_control_number, purpose, "type", is_production, submission_date, rolodex_id, edi) FROM stdin;
\.


--
-- Data for Name: billing_payment; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY billing_payment (rec_id, edi_filename, interchange_control_number, is_production, transaction_handling_code, payment_amount, payment_method, payment_date, payment_number, payment_company_id, interchange_date, date_received, entered_by_staff_id, rolodex_id, edi) FROM stdin;
\.


--
-- Data for Name: billing_prognote; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY billing_prognote (rec_id, billing_service_id, prognote_id) FROM stdin;
\.


--
-- Data for Name: billing_service; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY billing_service (rec_id, billing_claim_id, billed_amount, billed_units, line_number) FROM stdin;
\.


--
-- Data for Name: claims_processor; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY claims_processor (rec_id, interchange_id_qualifier, interchange_id, code, name, primary_id, clinic_trading_partner_id, clinic_submitter_id, requires_rendering_provider_ids, template_837, password_active_days, password_expires, password_min_char, username, "password", sftp_host, sftp_port, dialup_number, put_directory, get_directory, send_personnel_id, send_production_files) FROM stdin;
\.


--
-- Data for Name: client; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client (client_id, chart_id, aka, post_code, phone, phone_2, email, sex, race, marital_status, substance_abuse, alcohol_abuse, gambling_abuse, religion, acct_id, county, language_spoken, sexual_identity, state_specific_id, edu_level, working, section_eight, comment_text, has_declaration_of_mh_treatment, declaration_of_mh_treatment_date, addr_2, city, state, prev_addr, prev_addr_2, prev_city, prev_state, prev_post_code, is_veteran, is_citizen, consent_to_treat, addr, living_arrangement, renewal_date, dont_call, dob, ssn, mname, fname, lname, name_suffix) FROM stdin;
\.


--
-- Data for Name: client_allergy; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_allergy (rec_id, client_id, allergy, created, active) FROM stdin;
\.


--
-- Data for Name: client_assessment; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_assessment (rec_id, client_id, staff_id, chart_id, start_date, end_date, admit_reason, refer_reason, social_environ, audit_trail, esof_id, esof_date, esof_name, esof_note, danger_others, danger_self, chemical_abuse, side_effects, sharps_disposal, alert_medical, alert_other, alert_note, physical_abuse, special_diet, history_birth, history_child, history_milestone, history_school, history_social, history_sexual, history_dating, medical_strengths, medical_limits, history_diag, illness_past, illness_family, history_dental, nutrition_needs, appearance, manner, orientation, functional, mood, affect, mood_note, relevant, coherent, tangential, circumstantial, blocking, neologisms, word_salad, perseveration, echolalia, delusions, hallucination, suicidal, homicidal, obsessive, thought_content, psycho_motor, speech_tone, impulse_control, speech_flow, memory_recent, memory_remote, judgement, insight, intelligence, present_problem, psych_history, homeless_history, social_portrait, work_history, social_skills, mica_history, social_strengths, financial_status, legal_status, military_history, spiritual_orient) FROM stdin;
\.


--
-- Data for Name: client_contacts; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_contacts (rec_id, client_id, rolodex_contacts_id, contact_type_id, comment_text, active) FROM stdin;
\.


--
-- Data for Name: client_diagnosis; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_diagnosis (rec_id, client_id, diagnosis_date, diagnosis_1a, diagnosis_1b, diagnosis_1c, diagnosis_2a, diagnosis_2b, diagnosis_3, diagnosis_4, diagnosis_5_highest, diagnosis_5_current, comment_text) FROM stdin;
\.


--
-- Data for Name: client_discharge; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_discharge (rec_id, client_id, chart_id, staff_name, physician, initial_diag_id, final_diag_id, admit_note, history_clinical, history_psych, history_medical, discharge_note, after_care, addr, addr_2, city, state, post_code, phone, ref_agency, ref_cont, ref_date, sent_summary, sent_psycho_social, sent_mental_stat, sent_tx_plan, sent_other, sent_to, sent_physical, esof_id, esof_date, esof_name, esof_note, last_contact_date, termination_notice_sent_date, client_contests_termination, education, income, employment_status, employability_factor, criminal_justice, termination_reason, "committed", client_placement_event_id, audit_trail) FROM stdin;
\.


--
-- Data for Name: client_employment; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_employment (rec_id, client_id, rolodex_employment_id, job_title, supervisor, work_phone, start_date, end_date, comment_text, active) FROM stdin;
\.


--
-- Data for Name: client_group; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_group (unit_id, dept_id, track_id, staff_id, start_date, group_site, group_note, attendance, input_by, timer, group_category) FROM stdin;
\.


--
-- Data for Name: client_income; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_income (rec_id, client_id, source_type_id, start_date, end_date, income_amount, account_id, certification_date, recertification_date, has_direct_deposit, is_recurring_income, comment_text) FROM stdin;
\.


--
-- Data for Name: client_income_metadata; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_income_metadata (rec_id, client_id, self_pay, rep_payee, bank_account, css_id) FROM stdin;
\.


--
-- Data for Name: client_inpatient; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_inpatient (rec_id, client_id, start_date, end_date, hospital, addr, htype, voluntary, state_hosp, reason, comments) FROM stdin;
\.


--
-- Data for Name: client_insurance; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_insurance (rec_id, client_id, rolodex_insurance_id, rank, carrier_type, carrier_contact, insurance_name, insurance_id, insured_name, insured_addr, insured_city, insured_state, insured_postcode, insured_phone, insured_group, insured_dob, insured_sex, insured_employer, other_plan, other_name, other_group, other_dob, other_sex, other_employer, other_plan_name, co_pay_amount, deductible_amount, license_required, comment_text, start_date, end_date, insured_group_id, insured_relationship_id, insured_fname, insured_lname, insured_mname, insured_name_suffix, insured_addr2, patient_insurance_id, insurance_type_id) FROM stdin;
\.


--
-- Data for Name: client_insurance_authorization; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_insurance_authorization (rec_id, client_insurance_id, allowed_amount, code, "type", start_date, end_date, capitation_amount, capitation_last_date) FROM stdin;
\.


--
-- Data for Name: client_insurance_authorization_request; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_insurance_authorization_request (rec_id, client_id, start_date, end_date, form, provider_agency, "location", diagnosis_primary, diagnosis_secondary, ohp, medicare, general_fund, ohp_id, medicare_id, general_fund_id, date_requested, client_insurance_authorization_id) FROM stdin;
\.


--
-- Data for Name: client_legal_history; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_legal_history (rec_id, client_id, status_id, location_id, reason, start_date, end_date, comment_text) FROM stdin;
\.


--
-- Data for Name: client_letter_history; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_letter_history (rec_id, client_id, rolodex_relationship_id, relationship_role, letter_type, letter, sent_date, print_header_id) FROM stdin;
\.


--
-- Data for Name: client_medication; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_medication (rec_id, client_id, start_date, end_date, medication, dosage, frequency, rolodex_treaters_id, "location", inject_date, instructions, num_refills, no_subs, audit_trail, quantity, notes, print_header_id, print_date) FROM stdin;
\.


--
-- Data for Name: client_placement_event; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_placement_event (rec_id, client_id, dept_id, program_id, level_of_care_id, staff_id, event_date, input_date, input_by_staff_id, is_intake, level_of_care_locked) FROM stdin;
\.


--
-- Data for Name: client_referral; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_referral (rec_id, client_id, rolodex_referral_id, agency_contact, agency_type, active, client_placement_event_id) FROM stdin;
\.


--
-- Data for Name: client_release; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_release (rec_id, client_id, rolodex_id, standard, release_list, print_date, renewal_date, print_header_id, release_from, release_to, active) FROM stdin;
\.


--
-- Data for Name: client_scanned_record; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_scanned_record (rec_id, client_id, filename, description, created, created_by) FROM stdin;
\.


--
-- Data for Name: client_treaters; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_treaters (rec_id, client_id, rolodex_treaters_id, last_visit, start_date, end_date, start_time, treater_agency, treater_licence, treater_type_id, audit_trail, active) FROM stdin;
\.


--
-- Data for Name: client_verification; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY client_verification (rec_id, client_id, apid_num, verif_date, rolodex_treaters_id, created, staff_id) FROM stdin;
\.


--
-- Data for Name: config; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY config (rec_id, dept_id, name, value) FROM stdin;
1	1001	mime_type	text/html
2	1001	form_method	post
3	1001	logout_time	240
4	1001	logout_inactive	525600
5	1001	edit_prognote	1
6	1001	prognote_min_duration_minutes	1
7	1001	prognote_max_duration_minutes	480
8	1001	prognote_bounce_grace	3
9	1001	org_name	Our Clinic
10	1001	org_tax_id	123-45-6789
11	1001	org_national_provider_id	1234567890
12	1001	org_taxonomy_code	101Y00000X
13	1001	org_street1	123 4th Street, 101
14	1001	org_street2	
15	1001	org_city	Portland
16	1001	org_state	OR
17	1001	org_zip	97215
18	1001	cp_credentials_expire_warning	10
19	1001	show_revision	1
20	1001	edi_contact_staff_id	1
21	1001	org_medicaid_provider_number	000000
22	1001	org_medicare_provider_number	R000000
23	1001	ohp_rolodex_id	1014
24	1001	medicare_rolodex_id	1015
25	1001	generalfund_rolodex_id	1016
26	1001	medicaid_rolodex_id	1013
27	1001	pdf_move_x	-2
28	1001	pdf_move_y	5
29	1001	modem_port	/dev/modem
30	1001	silent_modem	0
31	1001	clinic_first_appointment	8:00
32	1001	clinic_last_appointment	16:30
33	1001	notification_send_as	admin@clinic.com
34	1001	appointment_template	1002
35	1001	renewal_template	1001
36	1001	notification_days	7
37	1001	default_mail_template	1003
\.


--
-- Data for Name: ecs_file_downloaded; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY ecs_file_downloaded (rec_id, claims_processor_id, name, date_received) FROM stdin;
\.


--
-- Data for Name: group_attendance; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY group_attendance (rec_id, group_note_id, client_id, "action", prognote_id) FROM stdin;
\.


--
-- Data for Name: group_members; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY group_members (rec_id, group_id, client_id, active) FROM stdin;
\.


--
-- Data for Name: group_notes; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY group_notes (rec_id, group_id, staff_id, start_date, end_date, note_body, data_entry_id, charge_code_id, note_location_id, note_committed, outcome_rating) FROM stdin;
\.


--
-- Data for Name: groups; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY groups (rec_id, name, description, active, DEFAULT_note) FROM stdin;
\.


--
-- Data for Name: insurance_charge_code_association; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY insurance_charge_code_association (rec_id, rolodex_id, valid_data_charge_code_id, acceptable, dollars_per_unit, max_units_allowed_per_encounter, max_units_allowed_per_day) FROM stdin;
\.


--
-- Data for Name: lookup_associations; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY lookup_associations (rec_id, lookup_table_id, lookup_item_id, lookup_group_id) FROM stdin;
\.


--
-- Data for Name: lookup_group_entries; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY lookup_group_entries (rec_id, group_id, item_id) FROM stdin;
\.


--
-- Data for Name: lookup_groups; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY lookup_groups (rec_id, parent_id, name, description, active, "system") FROM stdin;
\.


--
-- Data for Name: migration_information; Type: TABLE DATA; Schema: public; Owner: ryan
--

--COPY migration_information (version, date) FROM stdin;
--400	1217520566
--\.


--
-- Data for Name: personnel; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY personnel (staff_id, unit_id, dept_id, "security", fname, lname, addr, city, state, zip_code, ssn, dob, home_phone, work_phone, next_kin, job_title, date_employ, race, sex, marital_status, super_visor, over_time, with_hold, us_citizen, super_visor_2, cdl, admin_id, credentials, work_fax, prefs, work_hours, hours_week, rolodex_treaters_id, productivity_week, productivity_month, productivity_year, productivity_last_update, "login", "password", home_page_type, supervisor_id, work_phone_ext, name_suffix, mname, taxonomy_code, medicaid_provider_number, medicare_provider_number, national_provider_id) FROM stdin;
\.


--
-- Data for Name: personnel_lookup_associations; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY personnel_lookup_associations (rec_id, staff_id, lookup_group_id, sticky) FROM stdin;
\.


--
-- Data for Name: prognote; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY prognote (rec_id, client_id, staff_id, goal_id, start_date, end_date, note_header, note_body, writer, audit_trail, data_entry_id, charge_code_id, note_location_id, note_committed, outcome_rating, billing_status, created, modified, group_id, unbillable_per_writer, bill_manually, previous_billing_status) FROM stdin;
\.


--
-- Data for Name: prognote_bounced; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY prognote_bounced (rec_id, prognote_id, bounced_by_staff_id, bounce_date, bounce_message, response_date, response_message) FROM stdin;
\.


--
-- Data for Name: rolodex; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY rolodex (rec_id, dept_id, generic, name, fname, lname, credentials, addr, addr_2, city, state, post_code, phone, phone_2, comment_text, client_id, claims_processor_id, edi_id, edi_name, edi_indicator_code) FROM stdin;
\.


--
-- Data for Name: rolodex_contacts; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY rolodex_contacts (rec_id, rolodex_id) FROM stdin;
\.


--
-- Data for Name: rolodex_dental_insurance; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY rolodex_dental_insurance (rec_id, rolodex_id) FROM stdin;
\.


--
-- Data for Name: rolodex_employment; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY rolodex_employment (rec_id, rolodex_id) FROM stdin;
\.


--
-- Data for Name: rolodex_medical_insurance; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY rolodex_medical_insurance (rec_id, rolodex_id) FROM stdin;
\.


--
-- Data for Name: rolodex_mental_health_insurance; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY rolodex_mental_health_insurance (rec_id, rolodex_id) FROM stdin;
\.


--
-- Data for Name: rolodex_prescribers; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY rolodex_prescribers (rec_id, rolodex_id) FROM stdin;
\.


--
-- Data for Name: rolodex_referral; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY rolodex_referral (rec_id, rolodex_id) FROM stdin;
\.


--
-- Data for Name: rolodex_release; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY rolodex_release (rec_id, rolodex_id) FROM stdin;
\.


--
-- Data for Name: rolodex_treaters; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY rolodex_treaters (rec_id, rolodex_id) FROM stdin;
\.


--
-- Data for Name: schedule_appointments; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY schedule_appointments (rec_id, schedule_availability_id, client_id, confirm_code_id, noshow, fax, chart, payment_code_id, auth_number, notes, appt_time, staff_id) FROM stdin;
\.


--
-- Data for Name: schedule_availability; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY schedule_availability (rec_id, rolodex_id, location_id, date) FROM stdin;
\.


--
-- Data for Name: schedule_type_associations; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY schedule_type_associations (rec_id, rolodex_id, schedule_type_id) FROM stdin;
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY sessions (id, a_session) FROM stdin;
\.


--
-- Data for Name: similar_rolodex; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY similar_rolodex (rolodex_id, matching_ids, modified) FROM stdin;
\.


--
-- Data for Name: transaction; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY "transaction" (rec_id, billing_service_id, billing_payment_id, paid_amount, paid_units, claim_status_code, patient_responsibility_amount, payer_claim_control_number, paid_charge_code, submitted_charge_code_if_applicable, remarks, entered_in_error, refunded) FROM stdin;
\.


--
-- Data for Name: transaction_deduction; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY transaction_deduction (rec_id, transaction_id, amount, units, group_code, reason_code) FROM stdin;
\.


--
-- Data for Name: tx_goals; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY tx_goals (rec_id, client_id, staff_id, plan_id, medicaid, start_date, end_date, goal, goal_stat, goal_header, goal_name, problem_description, eval, comment_text, goal_code, rstat, serv, audit_trail, active) FROM stdin;
\.


--
-- Data for Name: tx_plan; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY tx_plan (rec_id, client_id, chart_id, staff_id, start_date, end_date, period, esof_id, esof_date, esof_name, esof_note, asSETs, debits, case_worker, src_worker, supervisor, meets_dsm4, needs_selfcare, needs_skills, needs_support, needs_adl, needs_focus, active) FROM stdin;
\.


--
-- Data for Name: valid_data_abuse; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_abuse (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_adjustment_group_codes; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_adjustment_group_codes (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_charge_code; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_charge_code (rec_id, dept_id, name, description, active, min_allowable_time, max_allowable_time, minutes_per_unit, dollars_per_unit, max_units_allowed_per_encounter, max_units_allowed_per_day, cost_calculation_method) FROM stdin;
\.


--
-- Data for Name: valid_data_claim_adjustment_codes; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_claim_adjustment_codes (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_claim_status_codes; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_claim_status_codes (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_confirmation_codes; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_confirmation_codes (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_contact_type; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_contact_TYPE (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_dsm4; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_dsm4 (axis, name, level_num, category, hdr, description, rec_id, dept_id, active) FROM stdin;
\.


--
-- Data for Name: valid_data_element_errors; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_element_errors (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_employability; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_employability (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_functional_group_ack_codes; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_functional_group_ack_codes (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_functional_group_errors; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_functional_group_errors (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_groupnote_templates; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_groupnote_templates (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_housing_complex; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_housing_complex (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_income_sources; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_income_sources (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_insurance_relationship; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_insurance_relationship (rec_id, dept_id, name, description, active, code) FROM stdin;
\.


--
-- Data for Name: valid_data_insurance_type; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_insurance_TYPE (rec_id, dept_id, name, description, active, code) FROM stdin;
\.


--
-- Data for Name: valid_data_interchange_ack_codes; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_interchange_ack_codes (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_interchange_note_codes; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_interchange_note_codes (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_language; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_language (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_legal_location; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_legal_location (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_legal_status; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_legal_status (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_letter_templates; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_letter_templates (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_level_of_care; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_level_of_care (rec_id, dept_id, name, description, visit_frequency, visit_interval, active) FROM stdin;
\.


--
-- Data for Name: valid_data_living_arrangement; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_living_arrangement (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_marital_status; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_marital_status (rec_id, dept_id, name, description, active, is_married) FROM stdin;
\.


--
-- Data for Name: valid_data_medication; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_medication (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_payment_codes; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_payment_codes (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_print_header; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_print_header (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_prognote_billing_status; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_prognote_billing_status (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_prognote_location; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_prognote_location (rec_id, dept_id, name, description, active, facility_code) FROM stdin;
\.


--
-- Data for Name: valid_data_prognote_templates; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_prognote_templates (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_program; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_program (rec_id, dept_id, name, description, number, active, is_referral, addr, city, state, zip) FROM stdin;
\.


--
-- Data for Name: valid_data_race; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_race (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_release; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_release (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_release_bits; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_release_bits (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_religion; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_religion (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_remittance_remark_codes; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_remittance_remark_codes (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_rolodex_roles; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_rolodex_roles (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_schedule_types; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_schedule_types (rec_id, dept_id, name, description, schedule_interval, schedule_multiplier, active) FROM stdin;
\.


--
-- Data for Name: valid_data_segment_errors; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_segment_errors (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_sex; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_sex (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_sexual_identity; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_sexual_identity (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_termination_reasons; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_termination_reasons (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_transaction_handling; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_transaction_handling (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_transaction_set_ack_codes; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_transaction_set_ack_codes (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_transaction_set_errors; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_transaction_set_errors (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_treater_types; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_treater_types (rec_id, dept_id, name, description, active) FROM stdin;
\.


--
-- Data for Name: valid_data_valid_data; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY valid_data_valid_data (rec_id, dept_id, name, description, readonly, active, extra_columns) FROM stdin;
1	1001	valid_data_groupnote_templates	Group note templates	0	1	\N
2	1001	valid_data_abuse	Drug abuse	0	1	\N
4	1001	valid_data_contact_type	Contact types	0	1	\N
5	1001	valid_data_housing_complex	Housing complex	0	1	\N
6	1001	valid_data_income_sources	Income sources	0	1	\N
7	1001	valid_data_language	Language	0	1	\N
8	1001	valid_data_legal_location	Legal status location	0	1	\N
9	1001	valid_data_legal_status	Legal status type	0	1	\N
11	1001	valid_data_medication	Medications	0	1	\N
13	1001	valid_data_prognote_billing_status	Progress note billing stati	0	1	\N
14	1001	valid_data_prognote_templates	Progress note templates	0	1	\N
15	1001	valid_data_race	Race	0	1	\N
16	1001	valid_data_release	Release information	0	1	\N
17	1001	valid_data_religion	Religions	0	1	\N
18	1001	valid_data_rolodex_roles	Rolodex roles	1	1	\N
19	1001	valid_data_sex	Sex	0	1	\N
20	1001	valid_data_sexual_identity	Sexual identity	0	1	\N
21	1001	valid_data_treater_types	Treater types	0	1	\N
22	1001	valid_data_living_arrangement	Living arrangement codes	0	1	\N
23	1001	valid_data_termination_reasons	Termination reasons	0	1	\N
24	1001	valid_data_employability	Employability factors	0	1	\N
25	1001	valid_data_letter_templates	General letter templates	0	1	\N
26	1001	valid_data_print_header	Printed Headers	0	1	\N
27	1001	valid_data_release_bits	Release Letter Language	0	1	\N
29	1001	valid_data_level_of_care	Level of Care	0	1	visit_frequency, visit_interval
12	1001	valid_data_prognote_location	Progress note locations	0	1	facility_code
3	1001	valid_data_charge_code	Charge codes	0	1	min_allowable_time, max_allowable_time, minutes_per_unit, dollars_per_unit, max_units_allowed_per_encounter, max_units_allowed_per_day, cost_calculation_method
30	1001	valid_data_insurance_relationship	Insurance Relationships	0	1	code
31	1001	valid_data_insurance_type	EDI 835 Insurance Types, for Other Subscriber Info SBR05	0	1	code
28	1001	valid_data_program	Programs	0	1	number, is_referral, addr, city, state, zip
10	1001	valid_data_marital_status	Marital status	0	1	is_married
32	1001	valid_data_transaction_handling	EDI 835 payment handling	0	1	\N
33	1001	valid_data_claim_status_codes	EDI 835 claim status	0	1	\N
34	1001	valid_data_claim_adjustment_codes	EDI 835 Claim Adjustment Reason Codes	0	1	\N
35	1001	valid_data_remittance_remark_codes	EDI 835 Remittance Advice Remark Codes	0	1	\N
36	1001	valid_data_adjustment_group_codes	EDI 835 Adjustment Group Codes	0	1	\N
37	1001	valid_data_segment_errors	EDI 997 Segment Syntax Error Codes	0	1	\N
38	1001	valid_data_element_errors	EDI 997 Data Element Syntax Error Codes	0	1	\N
39	1001	valid_data_transaction_set_ack_codes	EDI 997 Transaction Set Acknowledgement Codes	0	1	\N
40	1001	valid_data_transaction_set_errors	EDI 997 Transaction Set Syntax Error Codes	0	1	\N
41	1001	valid_data_functional_group_ack_codes	EDI 997 Functional Group Acknowledge Codes	0	1	\N
42	1001	valid_data_functional_group_errors	EDI 997 Functional Group Syntax Error Codes	0	1	\N
43	1001	valid_data_interchange_ack_codes	EDI TA1 Interchange Acknowledgment Codes	0	1	\N
44	1001	valid_data_interchange_note_codes	EDI TA1 Interchange Note Codes	0	1	\N
45	1001	valid_data_schedule_types	Schedule Types	0	1	schedule_interval,schedule_multiplier
46	1001	valid_data_confirmation_codes	Appointment confirmation codes	0	1	\N
47	1001	valid_data_payment_codes	Appointment payment codes	0	1	\N
48	1001	valid_data_dsm4	DSM IV Details	0	1	axis,level_num,category,hdr
\.

ALTER SEQUENCE valid_data_valid_data_rec_id_seq RESTART WITH 49;

--
-- Data for Name: validation_prognote; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY validation_prognote (rec_id, validation_set_id, prognote_id, rolodex_id, payer_validation, force_valid) FROM stdin;
\.


--
-- Data for Name: validation_result; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY validation_result (rec_id, validation_prognote_id, validation_rule_id, pass) FROM stdin;
\.


--
-- Data for Name: validation_rule; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY validation_rule (rec_id, name, rule_select, rule_from, rule_where, rule_order, selects_pass, error_message, scope) FROM stdin;
\.


--
-- Data for Name: validation_rule_last_used; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY validation_rule_last_used (rec_id, validation_rule_id, rolodex_id) FROM stdin;
\.


--
-- Data for Name: validation_SET; Type: TABLE DATA; Schema: public; Owner: ryan
--

COPY validation_SET (rec_id, creation_date, from_date, to_date, staff_id, billing_cycle_id, step, status) FROM stdin;
\.


--
-- Name: billing_claim_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY billing_claim
    ADD CONSTRAINT billing_claim_pkey PRIMARY KEY (rec_id);


--
-- Name: billing_cycle_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY billing_cycle
    ADD CONSTRAINT billing_cycle_pkey PRIMARY KEY (rec_id);


--
-- Name: billing_file_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY billing_file
    ADD CONSTRAINT billing_file_pkey PRIMARY KEY (rec_id);


--
-- Name: billing_payment_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY billing_payment
    ADD CONSTRAINT billing_payment_pkey PRIMARY KEY (rec_id);


--
-- Name: billing_prognote_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY billing_prognote
    ADD CONSTRAINT billing_prognote_pkey PRIMARY KEY (rec_id);


--
-- Name: billing_service_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY billing_service
    ADD CONSTRAINT billing_service_pkey PRIMARY KEY (rec_id);


--
-- Name: claims_processor_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY claims_processor
    ADD CONSTRAINT claims_processor_pkey PRIMARY KEY (rec_id);


--
-- Name: client_allergy_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_allergy
    ADD CONSTRAINT client_allergy_pkey PRIMARY KEY (rec_id);


--
-- Name: client_assessment_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_assessment
    ADD CONSTRAINT client_assessment_pkey PRIMARY KEY (rec_id);


--
-- Name: client_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_contacts
    ADD CONSTRAINT client_contacts_pkey PRIMARY KEY (rec_id);


--
-- Name: client_diagnosis_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_diagnosis
    ADD CONSTRAINT client_diagnosis_pkey PRIMARY KEY (rec_id);


--
-- Name: client_discharge_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_discharge
    ADD CONSTRAINT client_discharge_pkey PRIMARY KEY (rec_id);


--
-- Name: client_employment_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_employment
    ADD CONSTRAINT client_employment_pkey PRIMARY KEY (rec_id);


--
-- Name: client_income_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_income_metadata
    ADD CONSTRAINT client_income_metadata_pkey PRIMARY KEY (rec_id);


--
-- Name: client_income_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_income
    ADD CONSTRAINT client_income_pkey PRIMARY KEY (rec_id);


--
-- Name: client_inpatient_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_inpatient
    ADD CONSTRAINT client_inpatient_pkey PRIMARY KEY (rec_id);


--
-- Name: client_insurance_authorization_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_insurance_authorization
    ADD CONSTRAINT client_insurance_authorization_pkey PRIMARY KEY (rec_id);


--
-- Name: client_insurance_authorization_request_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_insurance_authorization_request
    ADD CONSTRAINT client_insurance_authorization_request_pkey PRIMARY KEY (rec_id);


--
-- Name: client_insurance_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_insurance
    ADD CONSTRAINT client_insurance_pkey PRIMARY KEY (rec_id);


--
-- Name: client_legal_history_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_legal_history
    ADD CONSTRAINT client_legal_history_pkey PRIMARY KEY (rec_id);


--
-- Name: client_letter_history_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_letter_history
    ADD CONSTRAINT client_letter_history_pkey PRIMARY KEY (rec_id);


--
-- Name: client_medication_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_medication
    ADD CONSTRAINT client_medication_pkey PRIMARY KEY (rec_id);


--
-- Name: client_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client
    ADD CONSTRAINT client_pkey PRIMARY KEY (client_id);


--
-- Name: client_placement_event_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_placement_event
    ADD CONSTRAINT client_placement_event_pkey PRIMARY KEY (rec_id);


--
-- Name: client_referral_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_referral
    ADD CONSTRAINT client_referral_pkey PRIMARY KEY (rec_id);


--
-- Name: client_release_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_release
    ADD CONSTRAINT client_release_pkey PRIMARY KEY (rec_id);


--
-- Name: client_scanned_record_filename_unique; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_scanned_record
    ADD CONSTRAINT client_scanned_record_filename_unique UNIQUE (filename);


--
-- Name: client_scanned_record_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_scanned_record
    ADD CONSTRAINT client_scanned_record_pkey PRIMARY KEY (rec_id);


--
-- Name: client_treaters_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_treaters
    ADD CONSTRAINT client_treaters_pkey PRIMARY KEY (rec_id);


--
-- Name: client_verification_business_key; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_verification
    ADD CONSTRAINT client_verification_business_key UNIQUE (client_id, apid_num);


--
-- Name: client_verification_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY client_verification
    ADD CONSTRAINT client_verification_pkey PRIMARY KEY (rec_id);


--
-- Name: config_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY config
    ADD CONSTRAINT config_pkey PRIMARY KEY (rec_id);


--
-- Name: ecs_file_downloaded_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY ecs_file_downloaded
    ADD CONSTRAINT ecs_file_downloaded_pkey PRIMARY KEY (rec_id);


--
-- Name: group_attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY group_attendance
    ADD CONSTRAINT group_attendance_pkey PRIMARY KEY (rec_id);


--
-- Name: group_members_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY group_members
    ADD CONSTRAINT group_members_pkey PRIMARY KEY (rec_id);


--
-- Name: group_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY group_notes
    ADD CONSTRAINT group_notes_pkey PRIMARY KEY (rec_id);


--
-- Name: groups_name_key; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_name_key UNIQUE (name);


--
-- Name: groups_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (rec_id);


--
-- Name: insurance_charge_code_association_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY insurance_charge_code_association
    ADD CONSTRAINT insurance_charge_code_association_pkey PRIMARY KEY (rec_id);


--
-- Name: lookup_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY lookup_associations
    ADD CONSTRAINT lookup_associations_pkey PRIMARY KEY (rec_id);


--
-- Name: lookup_group_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY lookup_group_entries
    ADD CONSTRAINT lookup_group_entries_pkey PRIMARY KEY (rec_id);


--
-- Name: lookup_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY lookup_groups
    ADD CONSTRAINT lookup_groups_pkey PRIMARY KEY (rec_id);


--
-- Name: personnel_lookup_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY personnel_lookup_associations
    ADD CONSTRAINT personnel_lookup_associations_pkey PRIMARY KEY (rec_id);


--
-- Name: personnel_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY personnel
    ADD CONSTRAINT personnel_pkey PRIMARY KEY (staff_id);


--
-- Name: prognote_bounced_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY prognote_bounced
    ADD CONSTRAINT prognote_bounced_pkey PRIMARY KEY (rec_id);


--
-- Name: prognote_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY prognote
    ADD CONSTRAINT prognote_pkey PRIMARY KEY (rec_id);


--
-- Name: rolodex_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY rolodex_contacts
    ADD CONSTRAINT rolodex_contacts_pkey PRIMARY KEY (rec_id);


--
-- Name: rolodex_dental_insurance_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY rolodex_dental_insurance
    ADD CONSTRAINT rolodex_dental_insurance_pkey PRIMARY KEY (rec_id);


--
-- Name: rolodex_employment_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY rolodex_employment
    ADD CONSTRAINT rolodex_employment_pkey PRIMARY KEY (rec_id);


--
-- Name: rolodex_medical_insurance_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY rolodex_medical_insurance
    ADD CONSTRAINT rolodex_medical_insurance_pkey PRIMARY KEY (rec_id);


--
-- Name: rolodex_mental_health_insurance_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY rolodex_mental_health_insurance
    ADD CONSTRAINT rolodex_mental_health_insurance_pkey PRIMARY KEY (rec_id);


--
-- Name: rolodex_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY rolodex
    ADD CONSTRAINT rolodex_pkey PRIMARY KEY (rec_id);


--
-- Name: rolodex_prescribers_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY rolodex_prescribers
    ADD CONSTRAINT rolodex_prescribers_pkey PRIMARY KEY (rec_id);


--
-- Name: rolodex_referral_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY rolodex_referral
    ADD CONSTRAINT rolodex_referral_pkey PRIMARY KEY (rec_id);


--
-- Name: rolodex_release_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY rolodex_release
    ADD CONSTRAINT rolodex_release_pkey PRIMARY KEY (rec_id);


--
-- Name: rolodex_treaters_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY rolodex_treaters
    ADD CONSTRAINT rolodex_treaters_pkey PRIMARY KEY (rec_id);


--
-- Name: schedule_appointments_business_key; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY schedule_appointments
    ADD CONSTRAINT schedule_appointments_business_key UNIQUE (schedule_availability_id, client_id, appt_time);


--
-- Name: schedule_appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY schedule_appointments
    ADD CONSTRAINT schedule_appointments_pkey PRIMARY KEY (rec_id);


--
-- Name: schedule_availability_business_key; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY schedule_availability
    ADD CONSTRAINT schedule_availability_business_key UNIQUE (rolodex_id, location_id, date);


--
-- Name: schedule_availability_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY schedule_availability
    ADD CONSTRAINT schedule_availability_pkey PRIMARY KEY (rec_id);


--
-- Name: schedule_type_associations_business_key; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY schedule_type_associations
    ADD CONSTRAINT schedule_type_associations_business_key UNIQUE (rolodex_id, schedule_type_id);


--
-- Name: schedule_type_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY schedule_type_associations
    ADD CONSTRAINT schedule_type_associations_pkey PRIMARY KEY (rec_id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: similar_rolodex_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY similar_rolodex
    ADD CONSTRAINT similar_rolodex_pkey PRIMARY KEY (rolodex_id);


--
-- Name: transaction_deduction_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY transaction_deduction
    ADD CONSTRAINT transaction_deduction_pkey PRIMARY KEY (rec_id);


--
-- Name: transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY "transaction"
    ADD CONSTRAINT transaction_pkey PRIMARY KEY (rec_id);


--
-- Name: tx_goals_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY tx_goals
    ADD CONSTRAINT tx_goals_pkey PRIMARY KEY (rec_id);


--
-- Name: tx_plan_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY tx_plan
    ADD CONSTRAINT tx_plan_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_abuse_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_abuse
    ADD CONSTRAINT valid_data_abuse_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_adjustment_group_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_adjustment_group_codes
    ADD CONSTRAINT valid_data_adjustment_group_codes_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_charge_code_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_charge_code
    ADD CONSTRAINT valid_data_charge_code_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_claim_adjustment_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_claim_adjustment_codes
    ADD CONSTRAINT valid_data_claim_adjustment_codes_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_claim_status_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_claim_status_codes
    ADD CONSTRAINT valid_data_claim_status_codes_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_confirmation_codes_business_key; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_confirmation_codes
    ADD CONSTRAINT valid_data_confirmation_codes_business_key UNIQUE (dept_id, name);


--
-- Name: valid_data_confirmation_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_confirmation_codes
    ADD CONSTRAINT valid_data_confirmation_codes_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_contact_type_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_contact_type
    ADD CONSTRAINT valid_data_contact_type_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_dsm4_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_dsm4
    ADD CONSTRAINT valid_data_dsm4_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_element_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_element_errors
    ADD CONSTRAINT valid_data_element_errors_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_employability_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_employability
    ADD CONSTRAINT valid_data_employability_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_functional_group_ack_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_functional_group_ack_codes
    ADD CONSTRAINT valid_data_functional_group_ack_codes_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_functional_group_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_functional_group_errors
    ADD CONSTRAINT valid_data_functional_group_errors_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_groupnote_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_groupnote_templates
    ADD CONSTRAINT valid_data_groupnote_templates_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_housing_complex_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_housing_complex
    ADD CONSTRAINT valid_data_housing_complex_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_income_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_income_sources
    ADD CONSTRAINT valid_data_income_sources_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_insurance_relationship_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_insurance_relationship
    ADD CONSTRAINT valid_data_insurance_relationship_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_insurance_type_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_insurance_type
    ADD CONSTRAINT valid_data_insurance_type_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_interchange_ack_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_interchange_ack_codes
    ADD CONSTRAINT valid_data_interchange_ack_codes_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_interchange_note_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_interchange_note_codes
    ADD CONSTRAINT valid_data_interchange_note_codes_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_language_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_language
    ADD CONSTRAINT valid_data_language_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_legal_location_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_legal_location
    ADD CONSTRAINT valid_data_legal_location_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_legal_status_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_legal_status
    ADD CONSTRAINT valid_data_legal_status_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_letter_templates_name_key; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_letter_templates
    ADD CONSTRAINT valid_data_letter_templates_name_key UNIQUE (name);


--
-- Name: valid_data_letter_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_letter_templates
    ADD CONSTRAINT valid_data_letter_templates_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_level_of_care_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_level_of_care
    ADD CONSTRAINT valid_data_level_of_care_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_living_arrangement_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_living_arrangement
    ADD CONSTRAINT valid_data_living_arrangement_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_marital_status_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_marital_status
    ADD CONSTRAINT valid_data_marital_status_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_medication_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_medication
    ADD CONSTRAINT valid_data_medication_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_payment_codes_business_key; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_payment_codes
    ADD CONSTRAINT valid_data_payment_codes_business_key UNIQUE (dept_id, name);


--
-- Name: valid_data_payment_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_payment_codes
    ADD CONSTRAINT valid_data_payment_codes_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_print_header_name_key; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_print_header
    ADD CONSTRAINT valid_data_print_header_name_key UNIQUE (name);


--
-- Name: valid_data_print_header_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_print_header
    ADD CONSTRAINT valid_data_print_header_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_prognote_billing_status_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_prognote_billing_status
    ADD CONSTRAINT valid_data_prognote_billing_status_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_prognote_location_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_prognote_location
    ADD CONSTRAINT valid_data_prognote_location_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_prognote_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_prognote_templates
    ADD CONSTRAINT valid_data_prognote_templates_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_program_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_program
    ADD CONSTRAINT valid_data_program_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_race_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_race
    ADD CONSTRAINT valid_data_race_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_release_bits_name_key; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_release_bits
    ADD CONSTRAINT valid_data_release_bits_name_key UNIQUE (name);


--
-- Name: valid_data_release_bits_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_release_bits
    ADD CONSTRAINT valid_data_release_bits_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_release_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_release
    ADD CONSTRAINT valid_data_release_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_religion_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_religion
    ADD CONSTRAINT valid_data_religion_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_remittance_remark_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_remittance_remark_codes
    ADD CONSTRAINT valid_data_remittance_remark_codes_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_rolodex_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_rolodex_roles
    ADD CONSTRAINT valid_data_rolodex_roles_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_schedule_types_business_key; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_schedule_types
    ADD CONSTRAINT valid_data_schedule_types_business_key UNIQUE (dept_id, name);


--
-- Name: valid_data_schedule_types_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_schedule_types
    ADD CONSTRAINT valid_data_schedule_types_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_segment_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_segment_errors
    ADD CONSTRAINT valid_data_segment_errors_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_sex_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_sex
    ADD CONSTRAINT valid_data_sex_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_sexual_identity_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_sexual_identity
    ADD CONSTRAINT valid_data_sexual_identity_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_termination_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_termination_reasons
    ADD CONSTRAINT valid_data_termination_reasons_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_transaction_handling_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_transaction_handling
    ADD CONSTRAINT valid_data_transaction_handling_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_transaction_set_ack_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_transaction_set_ack_codes
    ADD CONSTRAINT valid_data_transaction_set_ack_codes_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_transaction_set_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_transaction_set_errors
    ADD CONSTRAINT valid_data_transaction_set_errors_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_treater_types_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_treater_types
    ADD CONSTRAINT valid_data_treater_types_pkey PRIMARY KEY (rec_id);


--
-- Name: valid_data_valid_data_name_key; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_valid_data
    ADD CONSTRAINT valid_data_valid_data_name_key UNIQUE (name);


--
-- Name: valid_data_valid_data_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY valid_data_valid_data
    ADD CONSTRAINT valid_data_valid_data_pkey PRIMARY KEY (rec_id);


--
-- Name: validation_prognote_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY validation_prognote
    ADD CONSTRAINT validation_prognote_pkey PRIMARY KEY (rec_id);


--
-- Name: validation_result_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY validation_result
    ADD CONSTRAINT validation_result_pkey PRIMARY KEY (rec_id);


--
-- Name: validation_rule_last_used_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY validation_rule_last_used
    ADD CONSTRAINT validation_rule_last_used_pkey PRIMARY KEY (rec_id);


--
-- Name: validation_rule_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY validation_rule
    ADD CONSTRAINT validation_rule_pkey PRIMARY KEY (rec_id);


--
-- Name: validation_set_pkey; Type: CONSTRAINT; Schema: public; Owner: ryan; Tablespace: 
--

ALTER TABLE ONLY validation_SET
    ADD CONSTRAINT validation_set_pkey PRIMARY KEY (rec_id);


--
-- Name: index_prognote_bounced_prognote_id; Type: INDEX; Schema: public; Owner: ryan; Tablespace: 
--

CREATE INDEX index_prognote_bounced_prognote_id ON prognote_bounced USING btree (prognote_id);


--
-- Name: index_prognote_client_id; Type: INDEX; Schema: public; Owner: ryan; Tablespace: 
--

CREATE INDEX index_prognote_client_id ON prognote USING btree (client_id);


--
-- Name: index_prognote_start_data; Type: INDEX; Schema: public; Owner: ryan; Tablespace: 
--

CREATE INDEX index_prognote_start_data ON prognote USING btree (start_date);


--
-- Name: index_validation_prognote_prognote_id; Type: INDEX; Schema: public; Owner: ryan; Tablespace: 
--

CREATE INDEX index_validation_prognote_prognote_id ON validation_prognote USING btree (prognote_id);


--
-- Name: index_validation_result_validation_prognote_id; Type: INDEX; Schema: public; Owner: ryan; Tablespace: 
--

CREATE INDEX index_validation_result_validation_prognote_id ON validation_result USING btree (validation_prognote_id);


--
-- Name: master_patient_index; Type: INDEX; Schema: public; Owner: ryan; Tablespace: 
--

CREATE UNIQUE INDEX master_patient_index ON client USING btree (ssn);


--
-- Name: prognote_client_id_index; Type: INDEX; Schema: public; Owner: ryan; Tablespace: 
--

CREATE INDEX prognote_client_id_index ON prognote USING btree (client_id);


--
-- Name: rolodex_lname_index; Type: INDEX; Schema: public; Owner: ryan; Tablespace: 
--

CREATE INDEX rolodex_lname_index ON rolodex USING btree (lname);


--
-- Name: rolodex_name_index; Type: INDEX; Schema: public; Owner: ryan; Tablespace: 
--

CREATE INDEX rolodex_name_index ON rolodex USING btree (name);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_treaters
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_diagnosis
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_discharge
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_inpatient
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_medication
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY prognote
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY tx_plan
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY tx_goals
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_contacts
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_employment
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_income
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_income_metadata
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_insurance
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_legal_history
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_letter_history
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_referral
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_release
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY rolodex
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_allergy
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_assessment
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY schedule_appointments
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_verification
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_scanned_record
    ADD CONSTRAINT "$1" FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: client_contacts_rolodex_contacts_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_contacts
    ADD CONSTRAINT client_contacts_rolodex_contacts_id_fkey FOREIGN KEY (rolodex_contacts_id) REFERENCES rolodex_contacts(rec_id);


--
-- Name: client_discharge_to_client_placement_event_on_cpe_id; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_discharge
    ADD CONSTRAINT client_discharge_to_client_placement_event_on_cpe_id FOREIGN KEY (client_placement_event_id) REFERENCES client_placement_event(rec_id);


--
-- Name: client_placement_event_to_tracker_on_client_id; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_placement_event
    ADD CONSTRAINT client_placement_event_to_tracker_on_client_id FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: client_referral_to_client_placement_event_on_cpe_id; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_referral
    ADD CONSTRAINT client_referral_to_client_placement_event_on_cpe_id FOREIGN KEY (client_placement_event_id) REFERENCES client_placement_event(rec_id);


--
-- Name: client_scanned_record_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_scanned_record
    ADD CONSTRAINT client_scanned_record_created_by_fkey FOREIGN KEY (created_by) REFERENCES personnel(staff_id);


--
-- Name: client_treaters_rolodex_treaters_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_treaters
    ADD CONSTRAINT client_treaters_rolodex_treaters_id_fkey FOREIGN KEY (rolodex_treaters_id) REFERENCES rolodex_treaters(rec_id);


--
-- Name: client_verification_rolodex_treaters_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_verification
    ADD CONSTRAINT client_verification_rolodex_treaters_id_fkey FOREIGN KEY (rolodex_treaters_id) REFERENCES rolodex_treaters(rec_id);


--
-- Name: client_verification_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_verification
    ADD CONSTRAINT client_verification_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES personnel(staff_id);


--
-- Name: must_reference_billing_claim; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY billing_service
    ADD CONSTRAINT must_reference_billing_claim FOREIGN KEY (billing_claim_id) REFERENCES billing_claim(rec_id);


--
-- Name: must_reference_billing_cycle; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY billing_file
    ADD CONSTRAINT must_reference_billing_cycle FOREIGN KEY (billing_cycle_id) REFERENCES billing_cycle(rec_id);


--
-- Name: must_reference_billing_cycle; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY billing_claim
    ADD CONSTRAINT must_reference_billing_cycle FOREIGN KEY (billing_file_id) REFERENCES billing_file(rec_id);


--
-- Name: must_reference_billing_payment; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY "transaction"
    ADD CONSTRAINT must_reference_billing_payment FOREIGN KEY (billing_payment_id) REFERENCES billing_payment(rec_id);


--
-- Name: must_reference_billing_service; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY billing_prognote
    ADD CONSTRAINT must_reference_billing_service FOREIGN KEY (billing_service_id) REFERENCES billing_service(rec_id);


--
-- Name: must_reference_billing_service; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY "transaction"
    ADD CONSTRAINT must_reference_billing_service FOREIGN KEY (billing_service_id) REFERENCES billing_service(rec_id);


--
-- Name: must_reference_charge_code; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY insurance_charge_code_association
    ADD CONSTRAINT must_reference_charge_code FOREIGN KEY (valid_data_charge_code_id) REFERENCES valid_data_charge_code(rec_id);


--
-- Name: must_reference_claims_processor; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY ecs_file_downloaded
    ADD CONSTRAINT must_reference_claims_processor FOREIGN KEY (claims_processor_id) REFERENCES claims_processor(rec_id);


--
-- Name: must_reference_claims_processor; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY rolodex
    ADD CONSTRAINT must_reference_claims_processor FOREIGN KEY (claims_processor_id) REFERENCES claims_processor(rec_id);


--
-- Name: must_reference_client; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_insurance_authorization_request
    ADD CONSTRAINT must_reference_client FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: must_reference_client; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY billing_claim
    ADD CONSTRAINT must_reference_client FOREIGN KEY (client_id) REFERENCES client(client_id);


--
-- Name: must_reference_client_insurance; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_insurance_authorization
    ADD CONSTRAINT must_reference_client_insurance FOREIGN KEY (client_insurance_id) REFERENCES client_insurance(rec_id);


--
-- Name: must_reference_client_insurance; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY billing_claim
    ADD CONSTRAINT must_reference_client_insurance FOREIGN KEY (client_insurance_id) REFERENCES client_insurance(rec_id);


--
-- Name: must_reference_client_insurance_authorization; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_insurance_authorization_request
    ADD CONSTRAINT must_reference_client_insurance_authorization FOREIGN KEY (client_insurance_authorization_id) REFERENCES client_insurance_authorization(rec_id);


--
-- Name: must_reference_client_insurance_authorization; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY billing_claim
    ADD CONSTRAINT must_reference_client_insurance_authorization FOREIGN KEY (client_insurance_authorization_id) REFERENCES client_insurance_authorization(rec_id);


--
-- Name: must_reference_insurance_relationship; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_insurance
    ADD CONSTRAINT must_reference_insurance_relationship FOREIGN KEY (insured_relationship_id) REFERENCES valid_data_insurance_relationship(rec_id);


--
-- Name: must_reference_insurance_type; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY client_insurance
    ADD CONSTRAINT must_reference_insurance_TYPE FOREIGN KEY (insurance_type_id) REFERENCES valid_data_insurance_type(rec_id);


--
-- Name: must_reference_personnel; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY validation_SET
    ADD CONSTRAINT must_reference_personnel FOREIGN KEY (staff_id) REFERENCES personnel(staff_id);


--
-- Name: must_reference_personnel; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY billing_cycle
    ADD CONSTRAINT must_reference_personnel FOREIGN KEY (staff_id) REFERENCES personnel(staff_id);


--
-- Name: must_reference_personnel; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY billing_claim
    ADD CONSTRAINT must_reference_personnel FOREIGN KEY (staff_id) REFERENCES personnel(staff_id);


--
-- Name: must_reference_personnel; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY billing_payment
    ADD CONSTRAINT must_reference_personnel FOREIGN KEY (entered_by_staff_id) REFERENCES personnel(staff_id);


--
-- Name: must_reference_personnel; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY prognote_bounced
    ADD CONSTRAINT must_reference_personnel FOREIGN KEY (bounced_by_staff_id) REFERENCES personnel(staff_id);


--
-- Name: must_reference_prognote; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY validation_prognote
    ADD CONSTRAINT must_reference_prognote FOREIGN KEY (prognote_id) REFERENCES prognote(rec_id);


--
-- Name: must_reference_prognote; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY billing_prognote
    ADD CONSTRAINT must_reference_prognote FOREIGN KEY (prognote_id) REFERENCES prognote(rec_id);


--
-- Name: must_reference_prognote; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY prognote_bounced
    ADD CONSTRAINT must_reference_prognote FOREIGN KEY (prognote_id) REFERENCES prognote(rec_id);


--
-- Name: must_reference_rolodex; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY validation_rule_last_used
    ADD CONSTRAINT must_reference_rolodex FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: must_reference_rolodex; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY validation_prognote
    ADD CONSTRAINT must_reference_rolodex FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: must_reference_rolodex; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY billing_file
    ADD CONSTRAINT must_reference_rolodex FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: must_reference_rolodex; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY billing_payment
    ADD CONSTRAINT must_reference_rolodex FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: must_reference_rolodex; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY insurance_charge_code_association
    ADD CONSTRAINT must_reference_rolodex FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: must_reference_transaction; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY transaction_deduction
    ADD CONSTRAINT must_reference_transaction FOREIGN KEY (transaction_id) REFERENCES "transaction"(rec_id);


--
-- Name: must_reference_validation_prognote; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY validation_result
    ADD CONSTRAINT must_reference_validation_prognote FOREIGN KEY (validation_prognote_id) REFERENCES validation_prognote(rec_id) ON DELETE CASCADE;


--
-- Name: must_reference_validation_rule; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY validation_rule_last_used
    ADD CONSTRAINT must_reference_validation_rule FOREIGN KEY (validation_rule_id) REFERENCES validation_rule(rec_id) ON DELETE CASCADE;


--
-- Name: must_reference_validation_rule; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY validation_result
    ADD CONSTRAINT must_reference_validation_rule FOREIGN KEY (validation_rule_id) REFERENCES validation_rule(rec_id);


--
-- Name: must_reference_validation_set_id; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY validation_prognote
    ADD CONSTRAINT must_reference_validation_set_id FOREIGN KEY (validation_set_id) REFERENCES validation_SET(rec_id) ON DELETE CASCADE;


--
-- Name: rolodex_contacts_rolodex_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY rolodex_contacts
    ADD CONSTRAINT rolodex_contacts_rolodex_id_fkey FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: rolodex_dental_insurance_rolodex_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY rolodex_dental_insurance
    ADD CONSTRAINT rolodex_dental_insurance_rolodex_id_fkey FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: rolodex_employment_rolodex_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY rolodex_employment
    ADD CONSTRAINT rolodex_employment_rolodex_id_fkey FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: rolodex_medical_insurance_rolodex_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY rolodex_medical_insurance
    ADD CONSTRAINT rolodex_medical_insurance_rolodex_id_fkey FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: rolodex_mental_health_insurance_rolodex_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY rolodex_mental_health_insurance
    ADD CONSTRAINT rolodex_mental_health_insurance_rolodex_id_fkey FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: rolodex_prescribers_rolodex_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY rolodex_prescribers
    ADD CONSTRAINT rolodex_prescribers_rolodex_id_fkey FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: rolodex_referral_rolodex_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY rolodex_referral
    ADD CONSTRAINT rolodex_referral_rolodex_id_fkey FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: rolodex_release_rolodex_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY rolodex_release
    ADD CONSTRAINT rolodex_release_rolodex_id_fkey FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: rolodex_treaters_rolodex_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY rolodex_treaters
    ADD CONSTRAINT rolodex_treaters_rolodex_id_fkey FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: schedule_appointments_confirm_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY schedule_appointments
    ADD CONSTRAINT schedule_appointments_confirm_code_id_fkey FOREIGN KEY (confirm_code_id) REFERENCES valid_data_confirmation_codes(rec_id);


--
-- Name: schedule_appointments_payment_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY schedule_appointments
    ADD CONSTRAINT schedule_appointments_payment_code_id_fkey FOREIGN KEY (payment_code_id) REFERENCES valid_data_payment_codes(rec_id);


--
-- Name: schedule_appointments_schedule_availability_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY schedule_appointments
    ADD CONSTRAINT schedule_appointments_schedule_availability_id_fkey FOREIGN KEY (schedule_availability_id) REFERENCES schedule_availability(rec_id);


--
-- Name: schedule_appointments_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY schedule_appointments
    ADD CONSTRAINT schedule_appointments_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES personnel(staff_id);


--
-- Name: schedule_availability_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY schedule_availability
    ADD CONSTRAINT schedule_availability_location_id_fkey FOREIGN KEY (location_id) REFERENCES valid_data_prognote_location(rec_id);


--
-- Name: schedule_availability_rolodex_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY schedule_availability
    ADD CONSTRAINT schedule_availability_rolodex_id_fkey FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: schedule_type_associations_rolodex_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY schedule_type_associations
    ADD CONSTRAINT schedule_type_associations_rolodex_id_fkey FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: schedule_type_associations_schedule_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY schedule_type_associations
    ADD CONSTRAINT schedule_type_associations_schedule_type_id_fkey FOREIGN KEY (schedule_type_id) REFERENCES valid_data_schedule_types(rec_id);


--
-- Name: similar_rolodex_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ryan
--

ALTER TABLE ONLY similar_rolodex
    ADD CONSTRAINT similar_rolodex_fkey FOREIGN KEY (rolodex_id) REFERENCES rolodex(rec_id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: billing_claim; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE billing_claim FROM PUBLIC;
GRANT ALL ON TABLE billing_claim TO PUBLIC;


--
-- Name: billing_cycle; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE billing_cycle FROM PUBLIC;
GRANT ALL ON TABLE billing_cycle TO PUBLIC;


--
-- Name: billing_file; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE billing_file FROM PUBLIC;
GRANT ALL ON TABLE billing_file TO PUBLIC;


--
-- Name: billing_payment; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE billing_payment FROM PUBLIC;
GRANT ALL ON TABLE billing_payment TO PUBLIC;


--
-- Name: billing_prognote; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE billing_prognote FROM PUBLIC;
GRANT ALL ON TABLE billing_prognote TO PUBLIC;


--
-- Name: billing_service; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE billing_service FROM PUBLIC;
GRANT ALL ON TABLE billing_service TO PUBLIC;


--
-- Name: claims_processor; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE claims_processor FROM PUBLIC;
GRANT ALL ON TABLE claims_processor TO PUBLIC;


--
-- Name: client_allergy; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_allergy FROM PUBLIC;
GRANT ALL ON TABLE client_allergy TO PUBLIC;


--
-- Name: client_assessment; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_assessment FROM PUBLIC;
GRANT ALL ON TABLE client_assessment TO PUBLIC;


--
-- Name: client_contacts; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_contacts FROM PUBLIC;
GRANT ALL ON TABLE client_contacts TO PUBLIC;


--
-- Name: client_diagnosis; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_diagnosis FROM PUBLIC;
GRANT ALL ON TABLE client_diagnosis TO PUBLIC;


--
-- Name: client_discharge; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_discharge FROM PUBLIC;
GRANT ALL ON TABLE client_discharge TO PUBLIC;


--
-- Name: client_employment; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_employment FROM PUBLIC;
GRANT ALL ON TABLE client_employment TO PUBLIC;


--
-- Name: client_group; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_group FROM PUBLIC;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE client_group TO PUBLIC;


--
-- Name: client_income; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_income FROM PUBLIC;
GRANT ALL ON TABLE client_income TO PUBLIC;


--
-- Name: client_income_metadata; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_income_metadata FROM PUBLIC;
GRANT ALL ON TABLE client_income_metadata TO PUBLIC;


--
-- Name: client_inpatient; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_inpatient FROM PUBLIC;
GRANT ALL ON TABLE client_inpatient TO PUBLIC;


--
-- Name: client_insurance; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_insurance FROM PUBLIC;
GRANT ALL ON TABLE client_insurance TO PUBLIC;


--
-- Name: client_insurance_authorization; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_insurance_authorization FROM PUBLIC;
GRANT ALL ON TABLE client_insurance_authorization TO PUBLIC;


--
-- Name: client_insurance_authorization_request; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_insurance_authorization_request FROM PUBLIC;
GRANT ALL ON TABLE client_insurance_authorization_request TO PUBLIC;


--
-- Name: client_legal_history; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_legal_history FROM PUBLIC;
GRANT ALL ON TABLE client_legal_history TO PUBLIC;


--
-- Name: client_letter_history; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_letter_history FROM PUBLIC;
GRANT ALL ON TABLE client_letter_history TO PUBLIC;


--
-- Name: client_medication; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_medication FROM PUBLIC;
GRANT ALL ON TABLE client_medication TO PUBLIC;


--
-- Name: client_placement_event; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_placement_event FROM PUBLIC;
GRANT ALL ON TABLE client_placement_event TO PUBLIC;


--
-- Name: client_referral; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_referral FROM PUBLIC;
GRANT ALL ON TABLE client_referral TO PUBLIC;


--
-- Name: client_release; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_release FROM PUBLIC;
GRANT ALL ON TABLE client_release TO PUBLIC;


--
-- Name: client_scanned_record; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_scanned_record FROM PUBLIC;
GRANT ALL ON TABLE client_scanned_record TO PUBLIC;


--
-- Name: client_treaters; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_treaters FROM PUBLIC;
GRANT ALL ON TABLE client_treaters TO PUBLIC;


--
-- Name: client_verification; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE client_verification FROM PUBLIC;
GRANT ALL ON TABLE client_verification TO PUBLIC;


--
-- Name: config; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE config FROM PUBLIC;
GRANT ALL ON TABLE config TO PUBLIC;


--
-- Name: ecs_file_downloaded; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE ecs_file_downloaded FROM PUBLIC;
GRANT ALL ON TABLE ecs_file_downloaded TO PUBLIC;


--
-- Name: insurance_charge_code_association; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE insurance_charge_code_association FROM PUBLIC;
GRANT ALL ON TABLE insurance_charge_code_association TO PUBLIC;


--
-- Name: lookup_associations; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE lookup_associations FROM PUBLIC;
GRANT ALL ON TABLE lookup_associations TO PUBLIC;


--
-- Name: lookup_group_entries; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE lookup_group_entries FROM PUBLIC;
GRANT ALL ON TABLE lookup_group_entries TO PUBLIC;


--
-- Name: lookup_groups; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE lookup_groups FROM PUBLIC;
GRANT ALL ON TABLE lookup_groups TO PUBLIC;


--
-- Name: personnel; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE personnel FROM PUBLIC;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE personnel TO PUBLIC;


--
-- Name: personnel_lookup_associations; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE personnel_lookup_associations FROM PUBLIC;
GRANT ALL ON TABLE personnel_lookup_associations TO PUBLIC;


--
-- Name: prognote; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE prognote FROM PUBLIC;
GRANT ALL ON TABLE prognote TO PUBLIC;


--
-- Name: prognote_bounced; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE prognote_bounced FROM PUBLIC;
GRANT ALL ON TABLE prognote_bounced TO PUBLIC;


--
-- Name: rolodex; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE rolodex FROM PUBLIC;
GRANT ALL ON TABLE rolodex TO PUBLIC;


--
-- Name: rolodex_contacts; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE rolodex_contacts FROM PUBLIC;
GRANT ALL ON TABLE rolodex_contacts TO PUBLIC;


--
-- Name: rolodex_dental_insurance; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE rolodex_dental_insurance FROM PUBLIC;
GRANT ALL ON TABLE rolodex_dental_insurance TO PUBLIC;


--
-- Name: rolodex_employment; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE rolodex_employment FROM PUBLIC;
GRANT ALL ON TABLE rolodex_employment TO PUBLIC;


--
-- Name: rolodex_medical_insurance; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE rolodex_medical_insurance FROM PUBLIC;
GRANT ALL ON TABLE rolodex_medical_insurance TO PUBLIC;


--
-- Name: rolodex_mental_health_insurance; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE rolodex_mental_health_insurance FROM PUBLIC;
GRANT ALL ON TABLE rolodex_mental_health_insurance TO PUBLIC;


--
-- Name: rolodex_prescribers; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE rolodex_prescribers FROM PUBLIC;
GRANT ALL ON TABLE rolodex_prescribers TO PUBLIC;


--
-- Name: rolodex_referral; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE rolodex_referral FROM PUBLIC;
GRANT ALL ON TABLE rolodex_referral TO PUBLIC;


--
-- Name: rolodex_release; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE rolodex_release FROM PUBLIC;
GRANT ALL ON TABLE rolodex_release TO PUBLIC;


--
-- Name: rolodex_treaters; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE rolodex_treaters FROM PUBLIC;
GRANT ALL ON TABLE rolodex_treaters TO PUBLIC;


--
-- Name: schedule_appointments; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE schedule_appointments FROM PUBLIC;
GRANT ALL ON TABLE schedule_appointments TO PUBLIC;


--
-- Name: schedule_availability; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE schedule_availability FROM PUBLIC;
GRANT ALL ON TABLE schedule_availability TO PUBLIC;


--
-- Name: schedule_type_associations; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE schedule_type_associations FROM PUBLIC;
GRANT ALL ON TABLE schedule_type_associations TO PUBLIC;


--
-- Name: sessions; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE sessions FROM PUBLIC;
GRANT ALL ON TABLE sessions TO PUBLIC;


--
-- Name: similar_rolodex; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE similar_rolodex FROM PUBLIC;
GRANT ALL ON TABLE similar_rolodex TO PUBLIC;


--
-- Name: transaction; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE "transaction" FROM PUBLIC;
GRANT ALL ON TABLE "transaction" TO PUBLIC;


--
-- Name: transaction_deduction; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE transaction_deduction FROM PUBLIC;
GRANT ALL ON TABLE transaction_deduction TO PUBLIC;


--
-- Name: tx_goals; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE tx_goals FROM PUBLIC;
GRANT ALL ON TABLE tx_goals TO PUBLIC;


--
-- Name: tx_plan; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE tx_plan FROM PUBLIC;
GRANT ALL ON TABLE tx_plan TO PUBLIC;


--
-- Name: valid_data_abuse; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_abuse FROM PUBLIC;
GRANT ALL ON TABLE valid_data_abuse TO PUBLIC;


--
-- Name: valid_data_adjustment_group_codes; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_adjustment_group_codes FROM PUBLIC;
GRANT ALL ON TABLE valid_data_adjustment_group_codes TO PUBLIC;


--
-- Name: valid_data_charge_code; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_charge_code FROM PUBLIC;
GRANT ALL ON TABLE valid_data_charge_code TO PUBLIC;


--
-- Name: valid_data_claim_adjustment_codes; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_claim_adjustment_codes FROM PUBLIC;
GRANT ALL ON TABLE valid_data_claim_adjustment_codes TO PUBLIC;


--
-- Name: valid_data_claim_status_codes; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_claim_status_codes FROM PUBLIC;
GRANT ALL ON TABLE valid_data_claim_status_codes TO PUBLIC;


--
-- Name: valid_data_confirmation_codes; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_confirmation_codes FROM PUBLIC;
GRANT ALL ON TABLE valid_data_confirmation_codes TO PUBLIC;


--
-- Name: valid_data_contact_type; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_contact_TYPE FROM PUBLIC;
GRANT ALL ON TABLE valid_data_contact_TYPE TO PUBLIC;


--
-- Name: valid_data_dsm4; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_dsm4 FROM PUBLIC;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE valid_data_dsm4 TO PUBLIC;


--
-- Name: valid_data_element_errors; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_element_errors FROM PUBLIC;
GRANT ALL ON TABLE valid_data_element_errors TO PUBLIC;


--
-- Name: valid_data_employability; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_employability FROM PUBLIC;
GRANT ALL ON TABLE valid_data_employability TO PUBLIC;


--
-- Name: valid_data_functional_group_ack_codes; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_functional_group_ack_codes FROM PUBLIC;
GRANT ALL ON TABLE valid_data_functional_group_ack_codes TO PUBLIC;


--
-- Name: valid_data_functional_group_errors; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_functional_group_errors FROM PUBLIC;
GRANT ALL ON TABLE valid_data_functional_group_errors TO PUBLIC;


--
-- Name: valid_data_groupnote_templates; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_groupnote_templates FROM PUBLIC;
GRANT ALL ON TABLE valid_data_groupnote_templates TO PUBLIC;


--
-- Name: valid_data_housing_complex; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_housing_complex FROM PUBLIC;
GRANT ALL ON TABLE valid_data_housing_complex TO PUBLIC;


--
-- Name: valid_data_income_sources; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_income_sources FROM PUBLIC;
GRANT ALL ON TABLE valid_data_income_sources TO PUBLIC;


--
-- Name: valid_data_insurance_relationship; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_insurance_relationship FROM PUBLIC;
GRANT ALL ON TABLE valid_data_insurance_relationship TO PUBLIC;


--
-- Name: valid_data_insurance_type; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_insurance_TYPE FROM PUBLIC;
GRANT ALL ON TABLE valid_data_insurance_TYPE TO PUBLIC;


--
-- Name: valid_data_interchange_ack_codes; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_interchange_ack_codes FROM PUBLIC;
GRANT ALL ON TABLE valid_data_interchange_ack_codes TO PUBLIC;


--
-- Name: valid_data_interchange_note_codes; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_interchange_note_codes FROM PUBLIC;
GRANT ALL ON TABLE valid_data_interchange_note_codes TO PUBLIC;


--
-- Name: valid_data_language; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_language FROM PUBLIC;
GRANT ALL ON TABLE valid_data_language TO PUBLIC;


--
-- Name: valid_data_legal_location; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_legal_location FROM PUBLIC;
GRANT ALL ON TABLE valid_data_legal_location TO PUBLIC;


--
-- Name: valid_data_legal_status; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_legal_status FROM PUBLIC;
GRANT ALL ON TABLE valid_data_legal_status TO PUBLIC;


--
-- Name: valid_data_letter_templates; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_letter_templates FROM PUBLIC;
GRANT ALL ON TABLE valid_data_letter_templates TO PUBLIC;


--
-- Name: valid_data_level_of_care; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_level_of_care FROM PUBLIC;
GRANT ALL ON TABLE valid_data_level_of_care TO PUBLIC;


--
-- Name: valid_data_living_arrangement; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_living_arrangement FROM PUBLIC;
GRANT ALL ON TABLE valid_data_living_arrangement TO PUBLIC;


--
-- Name: valid_data_marital_status; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_marital_status FROM PUBLIC;
GRANT ALL ON TABLE valid_data_marital_status TO PUBLIC;


--
-- Name: valid_data_medication; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_medication FROM PUBLIC;
GRANT ALL ON TABLE valid_data_medication TO PUBLIC;


--
-- Name: valid_data_payment_codes; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_payment_codes FROM PUBLIC;
GRANT ALL ON TABLE valid_data_payment_codes TO PUBLIC;


--
-- Name: valid_data_print_header; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_print_header FROM PUBLIC;
GRANT ALL ON TABLE valid_data_print_header TO PUBLIC;


--
-- Name: valid_data_prognote_billing_status; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_prognote_billing_status FROM PUBLIC;
GRANT ALL ON TABLE valid_data_prognote_billing_status TO PUBLIC;


--
-- Name: valid_data_prognote_location; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_prognote_location FROM PUBLIC;
GRANT ALL ON TABLE valid_data_prognote_location TO PUBLIC;


--
-- Name: valid_data_prognote_templates; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_prognote_templates FROM PUBLIC;
GRANT ALL ON TABLE valid_data_prognote_templates TO PUBLIC;


--
-- Name: valid_data_program; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_program FROM PUBLIC;
GRANT ALL ON TABLE valid_data_program TO PUBLIC;


--
-- Name: valid_data_race; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_race FROM PUBLIC;
GRANT ALL ON TABLE valid_data_race TO PUBLIC;


--
-- Name: valid_data_release; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_release FROM PUBLIC;
GRANT ALL ON TABLE valid_data_release TO PUBLIC;


--
-- Name: valid_data_release_bits; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_release_bits FROM PUBLIC;
GRANT ALL ON TABLE valid_data_release_bits TO PUBLIC;


--
-- Name: valid_data_religion; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_religion FROM PUBLIC;
GRANT ALL ON TABLE valid_data_religion TO PUBLIC;


--
-- Name: valid_data_remittance_remark_codes; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_remittance_remark_codes FROM PUBLIC;
GRANT ALL ON TABLE valid_data_remittance_remark_codes TO PUBLIC;


--
-- Name: valid_data_rolodex_roles; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_rolodex_roles FROM PUBLIC;
GRANT ALL ON TABLE valid_data_rolodex_roles TO PUBLIC;


--
-- Name: valid_data_schedule_types; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_schedule_types FROM PUBLIC;
GRANT ALL ON TABLE valid_data_schedule_types TO PUBLIC;


--
-- Name: valid_data_segment_errors; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_segment_errors FROM PUBLIC;
GRANT ALL ON TABLE valid_data_segment_errors TO PUBLIC;


--
-- Name: valid_data_sex; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_sex FROM PUBLIC;
GRANT ALL ON TABLE valid_data_sex TO PUBLIC;


--
-- Name: valid_data_sexual_identity; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_sexual_identity FROM PUBLIC;
GRANT ALL ON TABLE valid_data_sexual_identity TO PUBLIC;


--
-- Name: valid_data_termination_reasons; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_termination_reasons FROM PUBLIC;
GRANT ALL ON TABLE valid_data_termination_reasons TO PUBLIC;


--
-- Name: valid_data_transaction_handling; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_transaction_handling FROM PUBLIC;
GRANT ALL ON TABLE valid_data_transaction_handling TO PUBLIC;


--
-- Name: valid_data_transaction_set_ack_codes; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_transaction_set_ack_codes FROM PUBLIC;
GRANT ALL ON TABLE valid_data_transaction_set_ack_codes TO PUBLIC;


--
-- Name: valid_data_transaction_set_errors; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_transaction_set_errors FROM PUBLIC;
GRANT ALL ON TABLE valid_data_transaction_set_errors TO PUBLIC;


--
-- Name: valid_data_treater_types; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_treater_types FROM PUBLIC;
GRANT ALL ON TABLE valid_data_treater_types TO PUBLIC;


--
-- Name: valid_data_valid_data; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE valid_data_valid_data FROM PUBLIC;
GRANT ALL ON TABLE valid_data_valid_data TO PUBLIC;


--
-- Name: validation_prognote; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE validation_prognote FROM PUBLIC;
GRANT ALL ON TABLE validation_prognote TO PUBLIC;


--
-- Name: validation_result; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE validation_result FROM PUBLIC;
GRANT ALL ON TABLE validation_result TO PUBLIC;


--
-- Name: validation_rule; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE validation_rule FROM PUBLIC;
GRANT ALL ON TABLE validation_rule TO PUBLIC;


--
-- Name: validation_rule_last_used; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE validation_rule_last_used FROM PUBLIC;
GRANT ALL ON TABLE validation_rule_last_used TO PUBLIC;


--
-- Name: validation_SET; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE validation_SET FROM PUBLIC;
GRANT ALL ON TABLE validation_SET TO PUBLIC;


--
-- Name: view_bill_manually_prognotes; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE view_bill_manually_prognotes FROM PUBLIC;
GRANT ALL ON TABLE view_bill_manually_prognotes TO PUBLIC;


--
-- Name: view_billing_service_required_provider_ids; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE view_billing_service_required_provider_ids FROM PUBLIC;
GRANT ALL ON TABLE view_billing_service_required_provider_ids TO PUBLIC;


--
-- Name: view_billings_by_prognote; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE view_billings_by_prognote FROM PUBLIC;
GRANT ALL ON TABLE view_billings_by_prognote TO PUBLIC;


--
-- Name: view_service_first_prognote; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE view_service_first_prognote FROM PUBLIC;
GRANT ALL ON TABLE view_service_first_prognote TO PUBLIC;


--
-- Name: view_client_billings; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE view_client_billings FROM PUBLIC;
GRANT ALL ON TABLE view_client_billings TO PUBLIC;


--
-- Name: view_client_payments; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE view_client_payments FROM PUBLIC;
GRANT ALL ON TABLE view_client_payments TO PUBLIC;


--
-- Name: view_client_placement; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE view_client_placement FROM PUBLIC;
GRANT ALL ON TABLE view_client_placement TO PUBLIC;


--
-- Name: view_client_writeoffs; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE view_client_writeoffs FROM PUBLIC;
GRANT ALL ON TABLE view_client_writeoffs TO PUBLIC;


--
-- Name: view_identical_prognotes; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE view_identical_prognotes FROM PUBLIC;
GRANT ALL ON TABLE view_identical_prognotes TO PUBLIC;


--
-- Name: view_prognote_billed; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE view_prognote_billed FROM PUBLIC;
GRANT ALL ON TABLE view_prognote_billed TO PUBLIC;


--
-- Name: view_prognote_insurances; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE view_prognote_insurances FROM PUBLIC;
GRANT ALL ON TABLE view_prognote_insurances TO PUBLIC;


--
-- Name: view_transaction_deductions; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE view_transaction_deductions FROM PUBLIC;
GRANT ALL ON TABLE view_transaction_deductions TO PUBLIC;


--
-- Name: view_unpaid_billed_services; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE view_unpaid_billed_services FROM PUBLIC;
GRANT ALL ON TABLE view_unpaid_billed_services TO PUBLIC;


--
-- Name: view_unpaid_billed_prognotes; Type: ACL; Schema: public; Owner: ryan
--

REVOKE ALL ON TABLE view_unpaid_billed_prognotes FROM PUBLIC;
GRANT ALL ON TABLE view_unpaid_billed_prognotes TO PUBLIC;


--
-- PostgreSQL database dump complete
--

