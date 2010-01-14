-- Templates should be generic e-mail templates.
ALTER TABLE client_notification_template RENAME TO email_templates;
ALTER TABLE client_notification_template_rec_id_seq RENAME TO email_templates_rec_id_seq;
ALTER TABLE email_templates DROP type;
ALTER TABLE email_templates ADD COLUMN subject_attach INTEGER;
ALTER TABLE email_templates ADD COLUMN message_attach INTEGER;
ALTER TABLE email_templates ADD COLUMN clinic_attach BOOLEAN;

CREATE TABLE email (
    rec_id          SERIAL NOT NULL PRIMARY KEY,
    sender_id       INTEGER NOT NULL,
    subject         TEXT,
    body            TEXT,
    send_date       TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT      sender_id_personnel_staff_id_fk 
                        FOREIGN KEY (sender_id) 
                        REFERENCES personnel(staff_id)
);


CREATE TABLE notification_renewal (
    rec_id          SERIAL NOT NULL PRIMARY KEY,
    client_id       INTEGER NOT NULL,
    renewal_date    DATE NOT NULL,
    email_id        INTEGER,
    CONSTRAINT      email_id_email_rec_id_fk 
                        FOREIGN KEY (email_id) 
                        REFERENCES email(rec_id),
    CONSTRAINT      client_id_client_client_id_fk 
                        FOREIGN KEY (client_id) 
                        REFERENCES client(client_id)
);

CREATE TABLE notification_appointment (
    rec_id          SERIAL NOT NULL PRIMARY KEY,
    client_id       INTEGER NOT NULL,
    appointment_id  INTEGER NOT NULL,
    email_id        INTEGER,
    CONSTRAINT      email_id_email_rec_id_fk 
                        FOREIGN KEY (email_id) 
                        REFERENCES email(rec_id),
    CONSTRAINT      client_id_client_client_id_fk 
                        FOREIGN KEY (client_id) 
                        REFERENCES client(client_id),
    CONSTRAINT      appointment_id_schedule_appointments_rec_id_fk 
                        FOREIGN KEY (appointment_id) 
                        REFERENCES schedule_appointments(rec_id)
);

-- Recipients are clients, AND there can be multiple recipients to a message
-- Thus recipient-message associations shoudl be stored seperately.
CREATE TABLE email_recipients (
    rec_id          SERIAL NOT NULL PRIMARY KEY,
    email_id        INTEGER NOT NULL,
    client_id       INTEGER NOT NULL,
    CONSTRAINT      email_id_email_rec_id_fk 
                        FOREIGN KEY (email_id) 
                        REFERENCES email(rec_id),
    CONSTRAINT      client_id_client_client_id_fk 
                        FOREIGN KEY (client_id) 
                        REFERENCES client(client_id)
);

CREATE TABLE notification_email_association (
    rec_id              SERIAL NOT NULL PRIMARY KEY,
    email_id            INTEGER,
    notification_id     INTEGER,
    notification_class  VARCHAR(255),
    CONSTRAINT          email_id_email_rec_id_fk 
                            FOREIGN KEY (email_id) 
                            REFERENCES email(rec_id)
    -- Need a way to constrain to specified class's table for notifications.                        
);

--INSERT INTO config ( dept_id, name, value ) VALUES ( '1001', 'DEFAULT_mail_template', '1003' );
