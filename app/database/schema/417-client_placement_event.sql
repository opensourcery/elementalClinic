ALTER TABLE client_placement_event ADD constraint no_null_program_dept CHECK(
    program_id IS NULL OR dept_id IS NOT NULL
);
