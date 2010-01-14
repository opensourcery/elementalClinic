--create table client_assessment (
--    rec_id serial primary key,
--    assessment_date date NOT NULL DEFAULT current_date,
--    client_id integer NOT NULL,
--    template_id integer NOT NULL,
--    start_date date NOT NULL DEFAULT current_date,
--    end_date date NOT NULL DEFAULT (current_date + INTERVAL '1 year'),
--    staff_id integer not null,
--    CONSTRAINT client_assessment_client_id_fkey FOREIGN KEY (client_id) REFERENCES client(client_id),
--    CONSTRAINT client_assessment_assessment_template_id_fkey FOREIGN KEY (template_id) REFERENCES assessment_templates(rec_id)
--);
--
--create table client_assessment_field (
--    rec_id serial primary key,
--    client_assessment_id integer NOT NULL,
--    template_field_id integer NOT NULL,
--    value text,
--    -- Only one entree per field in each assessment 
--    UNIQUE(client_assessment_id, template_field_id),
--    CONSTRAINT client_assessment_rec_id_fk FOREIGN KEY (client_assessment_id) REFERENCES client_assessment(rec_id),
--    CONSTRAINT client_assessment_field_template_field_id_fkey FOREIGN KEY (template_field_id) REFERENCES assessment_template_fields(rec_id)
--);

ALTER TABLE assessment_templates ADD COLUMN is_intake BOOLEAN;
ALTER TABLE assessment_templates ADD COLUMN intake_start TIMESTAMP;
ALTER TABLE assessment_templates ADD COLUMN intake_end TIMESTAMP;

CREATE FUNCTION migrate_assessments(count BIGINT) RETURNS VOID AS $$
DECLARE
    template     RECORD;
    section      RECORD;
    meds         RECORD;
    special      RECORD;
    presenting   RECORD;
    intake       RECORD;
    assessment   RECORD;
BEGIN
    IF count < 1 THEN
        RETURN;
    END IF;

    INSERT INTO assessment_templates( name, staff_id, intake_start, intake_end, is_intake )
                              VALUES( 'Intake Migrations', 1, NOW(), NOW(), 1);
    SELECT INTO template
                rec_id FROM assessment_templates
                      WHERE name = 'Intake Migrations';

    INSERT INTO assessment_template_sections( label, position, assessment_template_id )
                                      VALUES( 'Intake', 1, template.rec_id );
    SELECT INTO section rec_id FROM assessment_template_sections
                              WHERE label = 'Intake'
                                AND assessment_template_id = template.rec_id;

    INSERT INTO assessment_template_fields( label, position, field_type, assessment_template_section_id )
                        VALUES( 'Why are you here today?', 1, 'text::words', section.rec_id );
    SELECT INTO presenting rec_id FROM assessment_template_fields
                                 WHERE label = 'Why are you here today?'
                                   AND assessment_template_section_id = section.rec_id;

    INSERT INTO assessment_template_fields( label, position, field_type, assessment_template_section_id )
                        VALUES( 'Do you have any special needs?', 2, 'text::words', section.rec_id );
    SELECT INTO special rec_id FROM assessment_template_fields
                              WHERE label = 'Do you have any special needs?'
                                AND assessment_template_section_id = section.rec_id;

    INSERT INTO assessment_template_fields( label, position, field_type, assessment_template_section_id )
                        VALUES( 'What are your current or regular medications?', 3, 'text::words', section.rec_id );
    SELECT INTO meds rec_id FROM assessment_template_fields
                           WHERE label = 'What are your current or regular medications?'
                             AND assessment_template_section_id = section.rec_id;

    --For each record in the intake table where theres data
    FOR intake IN SELECT i.rec_id, i.client_id, i.staff_id, i.medications, i.special_needs, i.presenting_problem,
                         COALESCE( e.input_date, e.event_date ) AS intake_date
        FROM client_intake AS i
        JOIN client_placement_event AS e ON( i.client_placement_event_id = e.rec_id )
        WHERE medications   IS NOT NULL
           OR special_needs IS NOT NULL
           OR presenting_problem IS NOT NULL
    LOOP
      --Create an assessment
      INSERT INTO client_assessment( client_id, template_id, staff_id, assessment_date, start_date, end_date )
           VALUES( intake.client_id, template.rec_id, intake.staff_id, intake.intake_date, intake.intake_date, intake.intake_date );
      SELECT INTO assessment rec_id FROM client_assessment
                                   WHERE client_id = intake.client_id
                                     AND staff_id = intake.staff_id
                                     AND template_id = template.rec_id
                                   ORDER BY rec_id DESC;

      --Create the 3 fields.
      INSERT INTO client_assessment_field( client_assessment_id, template_field_id, value )
                           VALUES( assessment.rec_id, meds.rec_id, intake.medications );
      INSERT INTO client_assessment_field( client_assessment_id, template_field_id, value )
                           VALUES( assessment.rec_id, special.rec_id, intake.special_needs );
      INSERT INTO client_assessment_field( client_assessment_id, template_field_id, value )
                           VALUES( assessment.rec_id, presenting.rec_id, intake.presenting_problem );

      UPDATE client_intake SET assessment_id = assessment.rec_id
                         WHERE rec_id = intake.rec_id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE client_intake ADD COLUMN assessment_id INTEGER REFERENCES client_assessment( rec_id );

SELECT migrate_assessments(count( rec_id ))
    FROM client_intake
   WHERE medications   IS NOT NULL
      OR special_needs IS NOT NULL
      OR presenting_problem IS NOT NULL;

ALTER TABLE client_intake DROP COLUMN medications;
ALTER TABLE client_intake DROP COLUMN special_needs;
ALTER TABLE client_intake DROP COLUMN presenting_problem;
