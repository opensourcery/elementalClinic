CREATE TABLE access_log (
    rec_id          SERIAL NOT NULL PRIMARY KEY,
    logged          TIMESTAMP NOT NULL DEFAULT NOW(),
    from_session    INTEGER,
    object_id       INTEGER,
    object_type     TEXT,
    staff_id        INTEGER,
    CONSTRAINT      staff_id_personnel_staff_id_fk
                        FOREIGN KEY (staff_id)
                        REFERENCES personnel(staff_id)
);

CREATE TABLE security_log (
    rec_id          SERIAL NOT NULL PRIMARY KEY,
    logged          TIMESTAMP NOT NULL DEFAULT NOW(),
    login           TEXT NOT NULL,
    action          TEXT NOT NULL
);

