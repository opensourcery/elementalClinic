create table assessment_templates (
    rec_id serial primary key,
    name varchar(255) not null,
    created_date date default current_date,
    staff_id integer not null,
    active_start timestamp,
    active_end timestamp,
    UNIQUE(name),
    CONSTRAINT staff_id_personnel_staff_id_fk FOREIGN KEY (staff_id) REFERENCES personnel(staff_id)
);

create table assessment_template_sections (
    rec_id serial primary key,
    label varchar(255) not null,
    position integer not null,
    assessment_template_id integer not null,
    UNIQUE(label, position, assessment_template_id),
    CONSTRAINT assessment_template_id_assessment_template_rec_id_fk FOREIGN KEY (assessment_template_id) REFERENCES assessment_templates(rec_id)
);

create table assessment_template_fields (
    rec_id serial primary key,
    label varchar(255) not null,
    choices text,
    position integer not null,
    field_type varchar(255) default 'text::words',
    assessment_template_section_id integer not null,
    UNIQUE(label, position, assessment_template_section_id),
    CONSTRAINT assessment_template_section_id_assessment_template_section_rec_id_fk FOREIGN KEY (assessment_template_section_id) REFERENCES assessment_template_sections(rec_id)
);

-- base-sys brings in data with low rec_id, sequence needs to be past them
ALTER SEQUENCE assessment_templates_rec_id_seq RESTART WITH 10;
ALTER SEQUENCE assessment_template_sections_rec_id_seq RESTART WITH 100;
ALTER SEQUENCE assessment_template_fields_rec_id_seq RESTART WITH 100;

-- Save the old client assessment table for migrations.
ALTER TABLE client_assessment RENAME TO client_assessment_old;
ALTER TABLE client_assessment_rec_id_seq RENAME TO client_assessment_old_rec_id_seq;

create table client_assessment (
    rec_id serial primary key,
    assessment_date date NOT NULL DEFAULT current_date,
    client_id integer NOT NULL,
    template_id integer NOT NULL,
    start_date date NOT NULL DEFAULT current_date,
    end_date date NOT NULL DEFAULT (current_date + INTERVAL '1 year'),
    staff_id integer not null,
    CONSTRAINT client_assessment_client_id_fkey FOREIGN KEY (client_id) REFERENCES client(client_id),
    CONSTRAINT client_assessment_assessment_template_id_fkey FOREIGN KEY (template_id) REFERENCES assessment_templates(rec_id)
);

create table client_assessment_field (
    rec_id serial primary key,
    client_assessment_id integer NOT NULL,
    template_field_id integer NOT NULL,
    value text,
    -- Only one entree per field in each assessment 
    UNIQUE(client_assessment_id, template_field_id),
    CONSTRAINT client_assessment_rec_id_fk FOREIGN KEY (client_assessment_id) REFERENCES client_assessment(rec_id),
    CONSTRAINT client_assessment_field_template_field_id_fkey FOREIGN KEY (template_field_id) REFERENCES assessment_template_fields(rec_id)
);
