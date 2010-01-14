-- Table needs a primary key
-- ALTER TABLE dsm4 ALTER COLUMN rec_id SET NOT NULL;
-- ALTER TABLE dsm4 ADD PRIMARY KEY( rec_id );
-- Table is empty and unused in the tests, and it lacks a primary key, which breaks the database exporter
DROP TABLE client_group;
