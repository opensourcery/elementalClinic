-- Table for the roles. A role is either a system role, or a clinician role.
-- System roles are like groups that clinician roles are members of.
-- System roles can be members of system roles as well
CREATE TABLE personnel_role(
    rec_id SERIAL NOT NULL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    staff_id INTEGER REFERENCES personnel( staff_id ) UNIQUE,
    system_role BOOLEAN NOT NULL DEFAULT FALSE,
    has_homepage BOOLEAN NOT NULL DEFAULT FALSE,
    special_name TEXT UNIQUE DEFAULT NULL,
    -- Enforce that the role can be one or the other, not both.
    CHECK(
        (system_role AND staff_id IS NULL)
        or
        (staff_id IS NOT NULL AND NOT system_role)
    )
);

-- Membership table, tracks which roles are members of other roles.
-- To assign a user to a role that users clinician role becomes a member
CREATE TABLE personnel_role_member(
    rec_id SERIAL NOT NULL PRIMARY KEY,
    role_id INTEGER REFERENCES personnel_role( rec_id ) NOT NULL,
    member_id INTEGER REFERENCES personnel_role( rec_id ) NOT NULL,
    -- Make sure duplicate memberships do not occur.
    UNIQUE( role_id, member_id ),
    -- Roles should not be members of themselves.
    CHECK( member_id != role_id )
);

-- Client permissions table. Associate a role with the ability to access a
-- specific client.
CREATE TABLE personnel_role_client_permission(
    rec_id SERIAL NOT NULL PRIMARY KEY,
    role_id INTEGER REFERENCES personnel_role( rec_id ) NOT NULL,
    client_id INTEGER REFERENCES client( client_id ) NOT NULL,
    -- Prevent duplicates
    UNIQUE( role_id, client_id )
);

-- Group permissions table. Associate a role with the ability to access a
-- specific group.
CREATE TABLE personnel_role_group_permission(
    rec_id SERIAL NOT NULL PRIMARY KEY,
    role_id INTEGER REFERENCES personnel_role( rec_id ) NOT NULL,
    group_id INTEGER REFERENCES groups( rec_id ) NOT NULL,
    -- Prevent duplicates
    UNIQUE( role_id, group_id )
);

-- Special Roles

-- Admin role (id 1)
INSERT INTO personnel_role( name, system_role, special_name )
        VALUES( 'admin', TRUE, 'admin' );

-- Client role (id 2)
INSERT INTO personnel_role( name, system_role, special_name )
        VALUES( 'all clients', TRUE, 'all_clients' );

-- Group role (id 3)
INSERT INTO personnel_role( name, system_role, special_name )
        VALUES( 'all groups', TRUE, 'all_groups' );

-- Admins have the client role
INSERT INTO personnel_role_member( role_id, member_id )
        VALUES( 2, 1 );

-- Admins have the group role
INSERT INTO personnel_role_member( role_id, member_id )
        VALUES( 3, 1 );

-- Copy old roles
INSERT INTO personnel_role( name, system_role )
    SELECT DISTINCT( a.name ),TRUE
        FROM security_role as a
            LEFT JOIN
             personnel_role as b
            ON ( a.name = b.name )
        WHERE b.name IS NULL;

-- Copy old roles from personnel as well if there are more here.
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

-- Preserve that all current clinicians can view all clients
INSERT INTO personnel_role_member( member_id, role_id )
    SELECT rec_id, 2
        FROM personnel_role
        WHERE staff_id IS NOT NULL;

-- Map the old staff->role pairs to memberships where the individual role for
-- each staff member is a member of the specified role role.
INSERT INTO personnel_role_member( role_id, member_id )
    SELECT a.rec_id, c.rec_id
        FROM personnel_role AS a, -- Bring it in once to find the role we will be member of
             personnel_security_role AS b,
             personnel_role AS c -- Bring it in again to find the role that is the staff member.
        WHERE a.name = b.role_name AND c.staff_id = b.staff_id;

-- Remove old tables.
DROP TABLE personnel_security_role;
DROP TABLE security_role;
