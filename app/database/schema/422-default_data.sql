-- Allow us to specify if a lookup table can have a default set.
ALTER TABLE valid_data_valid_data ADD has_default INTEGER;

-- Add is_default to race, language, nationality
ALTER TABLE valid_data_race ADD is_default INTEGER;
ALTER TABLE valid_data_language ADD is_default INTEGER;
ALTER TABLE valid_data_nationality ADD is_default INTEGER;

-- Tell valid_data the tables have defaults.
UPDATE valid_data_valid_data SET has_default = 1 WHERE name = 'valid_data_race';
UPDATE valid_data_valid_data SET has_default = 1 WHERE name = 'valid_data_language';
UPDATE valid_data_valid_data SET has_default = 1 WHERE name = 'valid_data_nationality';
