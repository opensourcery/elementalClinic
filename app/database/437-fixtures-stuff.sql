
-- Copy old roles
INSERT INTO personnel_role( name, system_role )
    SELECT DISTINCT(role_name),TRUE
        FROM personnel_security_role as a
            LEFT JOIN
             personnel_role as b
            ON ( a.role_name = b.name )
        WHERE b.name IS NULL;


-- Create a role per staff member
INSERT INTO personnel_role( name, staff_id, system_role )
    SELECT a.staff_id,a.staff_id,FALSE
        FROM personnel as a
            LEFT JOIN
             personnel_role as b
            ON ( a.staff_id = b.staff_id )
        WHERE b.staff_id IS NULL;

-- Map the old staff->role pairs to memberships where the individual role for
-- each staff member is a member of the specified role role.
INSERT INTO personnel_role_member( role_id, member_id )
    SELECT a.rec_id, c.rec_id
        FROM personnel_role AS a, -- Bring it in once to find the role we will be membber of
             personnel_security_role AS b,
             personnel_role AS c -- Bring it in again to find the role that is the staff member.
        WHERE a.name = b.role_name AND c.staff_id = b.staff_id;

-- Bye-Bye.
-- DROP TABLE personnel_security_role;


