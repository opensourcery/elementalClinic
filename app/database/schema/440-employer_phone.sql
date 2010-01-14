INSERT INTO phone( client_id, phone_number, active, phone_type )
    SELECT      ce.client_id, work_phone,   TRUE,   'Work: ' || r.name
    FROM  client_employment AS ce
    JOIN rolodex_employment AS re ON( re.rec_id = ce.rolodex_employment_id )
    JOIN            rolodex AS r  ON (re.rolodex_id = r.rec_id)
    WHERE work_phone IS NOT NULL;

ALTER TABLE client_employment DROP COLUMN work_phone;
