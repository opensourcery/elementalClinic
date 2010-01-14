--
-- phone table
--

CREATE TABLE phone (
    rec_id       serial         NOT NULL,
    client_id    INTEGER,
    rolodex_id   INTEGER,
    phone_number VARCHAR(25)    NOT NULL, -- matches client table phone column
    message_ok   BOOLEAN        DEFAULT TRUE,
    call_ok      BOOLEAN        DEFAULT TRUE,
    primary_entry      BOOLEAN        DEFAULT FALSE,
    active       BOOLEAN        DEFAULT TRUE,
    phone_TYPE   VARCHAR(255),
    PRIMARY KEY (rec_id),
    CHECK ((client_id IS NULL AND rolodex_id IS NOT NULL) OR (rolodex_id IS NULL AND client_id IS NOT NULL))
);

--
-- slurp old data into phone table
--

INSERT INTO phone (client_id, phone_number) SELECT client_id, phone FROM client WHERE phone IS NOT NULL;
INSERT INTO phone (rolodex_id, phone_number) SELECT rec_id, phone FROM rolodex WHERE phone IS NOT NULL;

update phone SET primary_entry=TRUE;

INSERT INTO phone (client_id, phone_number) SELECT client_id, phone_2 FROM client WHERE phone_2 IS NOT NULL;
INSERT INTO phone (rolodex_id, phone_number) SELECT rec_id, phone_2 FROM rolodex WHERE phone_2 IS NOT NULL;


--
-- remove old columns AND DROP VIEWs temporarily
--

DROP VIEW v_client_treaters;
DROP VIEW v_treaters;
DROP VIEW v_emergency_contacts;
DROP VIEW v_client_contacts;
DROP VIEW v_contacts;

ALTER TABLE client DROP COLUMN phone;
ALTER TABLE client DROP COLUMN phone_2;
ALTER TABLE rolodex DROP COLUMN phone;
ALTER TABLE rolodex DROP COLUMN phone_2;

--
-- address table
--

CREATE TABLE address (
    rec_id       serial       NOT NULL,
    client_id    INTEGER,
    rolodex_id   INTEGER,
    address1     VARCHAR(255),
    address2     VARCHAR(255), 
    city         VARCHAR(255),
    state        VARCHAR(50),
    post_code    VARCHAR(10),
    county       VARCHAR(255),
    primary_entry      BOOLEAN      DEFAULT FALSE,
    active       BOOLEAN      DEFAULT TRUE,
    PRIMARY KEY (rec_id),
    CHECK ((client_id IS NULL AND rolodex_id IS NOT NULL) OR (rolodex_id IS NULL AND client_id IS NOT NULL))
);

--
-- slurp old data into address table
--

INSERT INTO address (client_id, address1, address2, city, state, post_code, county)
    SELECT client_id, prev_addr, prev_addr_2, prev_city, prev_state, prev_post_code, county FROM client;

update address SET active=FALSE;

INSERT INTO address (client_id, address1, address2, city, state, post_code, county) 
    SELECT client_id, addr, addr_2, city, state, post_code, county FROM client;

INSERT INTO address (rolodex_id, address1, address2, city, state, post_code) 
    SELECT rec_id, addr, addr_2, city, state, post_code FROM rolodex; 

update address SET primary_entry=TRUE WHERE active=TRUE;
--
-- drop old columns
--

ALTER TABLE client DROP COLUMN addr;
ALTER TABLE client DROP COLUMN addr_2;
ALTER TABLE client DROP COLUMN city;
ALTER TABLE client DROP COLUMN state;
ALTER TABLE client DROP COLUMN county;
ALTER TABLE client DROP COLUMN post_code;
ALTER TABLE client DROP COLUMN prev_addr;
ALTER TABLE client DROP COLUMN prev_addr_2;
ALTER TABLE client DROP COLUMN prev_city;
ALTER TABLE client DROP COLUMN prev_state;
ALTER TABLE client DROP COLUMN prev_post_code;
ALTER TABLE rolodex DROP COLUMN addr;
ALTER TABLE rolodex DROP COLUMN addr_2;
ALTER TABLE rolodex DROP COLUMN city;
ALTER TABLE rolodex DROP COLUMN state;
ALTER TABLE rolodex DROP COLUMN post_code;

-- FIXME I think the views will need to be rewritten FROM the bottom up.
