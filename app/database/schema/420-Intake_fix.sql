CREATE TABLE intake_assessment (
    rec_id              SERIAL NOT NULL PRIMARY KEY,
    client_id           INTEGER NOT NULL,
    medications         TEXT,
    special_needs       TEXT,
    presenting_problem  TEXT,
    CONSTRAINT          client_id_client_client_id_fk 
                        FOREIGN KEY (client_id) 
                        REFERENCES client(client_id)
);
