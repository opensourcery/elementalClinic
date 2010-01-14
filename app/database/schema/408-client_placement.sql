--
-- client_intake - intake event records for a client -- see client_placement_event
--

CREATE TABLE client_intake (
    rec_id serial primary key,
    client_id INTEGER NOT NULL,
    client_placement_event_id INTEGER NOT NULL,
    step INTEGER NOT NULL DEFAULT 0,
    referral_id INTEGER,
    active BOOLEAN DEFAULT TRUE,
    staff_id INTEGER,
    medications VARCHAR(255),
    special_needs VARCHAR(255),
    presenting_problem VARCHAR(255),
    CONSTRAINT client_intake_referral_id_fk FOREIGN KEY (referral_id) REFERENCES client_referral(rec_id),
    CONSTRAINT client_intake_client_placement_event_fk FOREIGN KEY (client_placement_event_id) REFERENCES client_placement_event(rec_id),
    CONSTRAINT client_intake_client_fk FOREIGN KEY (client_id) REFERENCES client(client_id)
);

ALTER TABLE client_placement_event ADD COLUMN intake_id INTEGER;
ALTER TABLE client_placement_event ADD COLUMN discharge_id INTEGER;

INSERT INTO client_intake (client_id, client_placement_event_id, staff_id) 
    SELECT client_id, rec_id, input_by_staff_id 
    FROM client_placement_event
    WHERE is_intake = 1 
        AND rec_id NOT IN (SELECT client_placement_event_id FROM client_referral);

INSERT INTO client_intake (client_id, client_placement_event_id, referral_id) 
    SELECT client_id, client_placement_event_id, rec_id 
        FROM client_referral 
        WHERE client_placement_event_id IS NOT NULL;

update client_intake SET staff_id=client_placement_event.input_by_staff_id 
    FROM client_placement_event, client_referral
    WHERE client_intake.referral_id = client_referral.rec_id
          AND client_intake.client_placement_event_id = client_placement_event.rec_id
          AND client_referral.client_placement_event_id = client_placement_event.rec_id;

update client_placement_event SET intake_id=client_intake.rec_id 
    FROM client_intake 
    WHERE client_intake.client_placement_event_id = client_placement_event.rec_id;

update client_placement_event SET discharge_id=client_discharge.rec_id 
    FROM client_discharge 
    WHERE client_discharge.client_placement_event_id = client_placement_event.rec_id;

--
-- This view needs to be recreated so we can drop is_intake AND input_by_staff_id
--

DROP VIEW view_client_placement;

ALTER TABLE client_placement_event DROP COLUMN is_intake;
ALTER TABLE client_placement_event DROP COLUMN input_by_staff_id;

CREATE VIEW view_client_placement AS
    SELECT DISTINCT ON (client_placement_event.client_id) client_placement_event.rec_id, client_placement_event.client_id, client_placement_event.dept_id, client_placement_event.program_id, client_placement_event.level_of_care_id, client_placement_event.staff_id, client_placement_event.event_date, client_placement_event.input_date, client_placement_event.level_of_care_locked
    FROM client_placement_event
    ORDER BY client_placement_event.client_id, client_placement_event.event_date
    DESC, client_placement_event.rec_id DESC;
