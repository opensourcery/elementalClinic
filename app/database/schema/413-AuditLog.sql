-- Audit Log

-- Table for the events that are recorded.
CREATE TABLE auditlog (
    rec_id     SERIAL PRIMARY KEY,
    event_time TIMESTAMP NOT NULL,
    class      VARCHAR(255),
    object_id  INTEGER,
    staff_id   INTEGER NOT NULL,
    CONSTRAINT staff_id_personnel_staff_id_fk FOREIGN KEY (staff_id) REFERENCES personnel(staff_id)
);

-- Values for when an event is changes to an object.
CREATE TABLE auditlog_values (
    rec_id    SERIAL PRIMARY KEY,
    event_id  INTEGER NOT NULL,
    -- Cannot be 'NOT NULL' because we might change to or from an empty value.
    old_value text,
    new_value text,
    CONSTRAINT event_id_auditlog_rec_id_fk FOREIGN KEY (event_id) REFERENCES auditlog(rec_id)
)
