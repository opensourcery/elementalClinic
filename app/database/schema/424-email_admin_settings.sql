--This has changed, as well it should be part of base-sys

DELETE FROM config WHERE name = 'notification_days';
DELETE FROM config WHERE name = 'renewal_template';
DELETE FROM config WHERE name = 'appointment_template';
DELETE FROM config WHERE name = 'notification_send_as';
DELETE FROM config WHERE name = 'default_mail_template';

ALTER TABLE notification_renewal ADD COLUMN days INTEGER; 
ALTER TABLE notification_appointment ADD COLUMN days INTEGER; 
