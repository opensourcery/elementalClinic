-- Test data refelects this being the ID of the valid_data item, however column type is varchar
ALTER TABLE client ALTER COLUMN living_arrangement TYPE integer USING living_arrangement::integer;
ALTER TABLE client ADD CONSTRAINT client_living_arrangement_valid_data_living_arrangement_rec_id_fk 
                        FOREIGN KEY (living_arrangement) 
                        REFERENCES valid_data_living_arrangement(rec_id);
