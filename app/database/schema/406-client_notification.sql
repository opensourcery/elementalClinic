CREATE TABLE client_notification (
    rec_id          serial NOT NULL primary key,
    client_id       INTEGER,
    event_id        INTEGER,
    event_date      DATE,
    date_sent       DATE,
    template_id     INTEGER,
    TYPE            VARCHAR(12) NOT NULL,
    CHECK           (TYPE IN ( 'appointment', 'renewal' ))
);

ALTER TABLE client ADD COLUMN send_notifications BOOLEAN DEFAULT 'FALSE';

CREATE TABLE client_notification_template (
    rec_id          serial NOT NULL primary key,
    name            VARCHAR(255) NOT NULL,
    TYPE            VARCHAR(12) NOT NULL,
    CHECK           (TYPE IN ( 'appointment', 'renewal' )),
    
    --These will be replaced into the email template
    subject         VARCHAR(255) NOT NULL,
    message         text NOT NULL
);

--INSERT INTO config ( dept_id, name, value ) VALUES ( '1001', 'notification_send_as', 'admin@clinic.com' );
--INSERT INTO config ( dept_id, name, value ) VALUES ( '1001', 'appointment_template', '1002' );
--INSERT INTO config ( dept_id, name, value ) VALUES ( '1001', 'renewal_template', '1001' );
--INSERT INTO config ( dept_id, name, value ) VALUES ( '1001', 'notification_days', '7' );


