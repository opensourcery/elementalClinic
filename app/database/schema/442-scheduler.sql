CREATE FUNCTION migration_add_scheduler() RETURNS VOID AS $$
DECLARE
    scheduler   RECORD;
    existing    RECORD;
BEGIN
    -- If we have less than 4 roles then we don't have base-system yet,
    -- scheduler will be inserted there
    SELECT INTO existing COUNT(rec_id) AS total FROM personnel_role;
    IF existing.total < 4 THEN
        RETURN;
    END IF;

    INSERT INTO personnel_role( name, system_role, special_name )
                        VALUES( 'scheduler', TRUE, 'schedule' ) ;
END;
$$ LANGUAGE plpgsql;

SELECT migration_add_scheduler();
