ALTER TABLE personnel ADD COLUMN password_set DATE NOT NULL DEFAULT NOW();
ALTER TABLE personnel ADD COLUMN password_expired integer DEFAULT 0;

INSERT INTO config( name, value, dept_id ) VALUES( 'password_expiration_days', 0, 1001 );
