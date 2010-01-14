--
-- Please see database/437-439-PERMISSIONS-SCHEMA-README for more information
--

-- Cascade personnel deletes to their memberships.
ALTER TABLE personnel_role DROP CONSTRAINT personnel_role_staff_id_fkey;
ALTER TABLE personnel_role ADD FOREIGN KEY (staff_id) REFERENCES personnel(staff_id) ON DELETE CASCADE;

--Create a new table to handle memberships properly

-- We need the sequence to start after the most recent entry in
-- personnel_role_member so that we can insert those values preserving rec_id.
-- Without this the trigger would spawn conflicting permissions (duplicate
-- rec_id)
-- The +10 is for testdata-jazz which brings in memberships w/ rec_id instead
-- of bumping the sequence.
CREATE SEQUENCE role_membership_rec_id_seq;
SELECT setval( 'role_membership_rec_id_seq', (nextval('personnel_role_member_rec_id_seq') + 10));

--Create the table
CREATE TABLE role_membership(
    rec_id         INTEGER UNIQUE NOT NULL PRIMARY KEY DEFAULT nextval('role_membership_rec_id_seq'),
    role_id        INTEGER NOT NULL REFERENCES personnel_role( rec_id ) ON DELETE CASCADE,
    member_id      INTEGER NOT NULL REFERENCES personnel_role( rec_id ) ON DELETE CASCADE,
    direct_cause   INTEGER REFERENCES role_membership( rec_id ) ON DELETE CASCADE,
    indirect_cause INTEGER REFERENCES role_membership( rec_id ) ON DELETE CASCADE,
    -- Roles should not be members of themselves.
    CHECK( member_id != role_id ),
    CHECK( direct_cause != indirect_cause ),
    -- Duplicates are pointless.
    UNIQUE( role_id, member_id, direct_cause, indirect_cause )
);


--Create a trigger to keep the memberships table synchronised whenever a
--membership is added.

CREATE LANGUAGE plpgsql;

-- When a membership is added:
CREATE FUNCTION add_membership()
RETURNS TRIGGER
AS $populate_indirect$
DECLARE
    membership RECORD;
    cause RECORD;
    direct INTEGER DEFAULT NEW.direct_cause;
    recurse RECORD;
    existing RECORD;
BEGIN
    SELECT INTO recurse DISTINCT role_id, member_id
                FROM role_membership
                WHERE role_id = NEW.member_id AND member_id = NEW.role_id;

    IF recurse IS NOT NULL THEN
        RAISE EXCEPTION 'Recursive membership detected! Role: % and Member: %', NEW.role_id, NEW.member_id;
    END IF;

    --direct should be the new records direct_cause, or the new record itself (rec_id)
    --direct is the rec_id of the membership that kicked off the chain
    IF direct IS NULL THEN direct := NEW.rec_id; END IF;

    -- For all memberships for which our new parent is the member
    FOR membership IN SELECT rec_id, role_id FROM role_membership
                               WHERE member_id = NEW.role_id
    LOOP
        --Make us a member as well
        --The membership were on is the indirect cause of the new membership
        SELECT INTO existing * FROM role_membership WHERE role_id = membership.role_id
                                                      AND member_id = NEW.member_id
                                                      AND direct_cause = direct
                                                      AND indirect_cause = membership.rec_id;
        IF existing IS NULL THEN
            INSERT INTO role_membership( role_id, member_id, direct_cause, indirect_cause )
               VALUES( membership.role_id, NEW.member_id, direct, membership.rec_id );
        END IF;
    END LOOP;

    -- For all memberships who are members of NEW.member_id
    FOR membership IN SELECT * FROM role_membership
                               WHERE role_id = NEW.member_id
    LOOP
        -- new item is the indirect cause
        -- membership tells us who the new member will be
        -- cause should be the link between the member and new parent
        FOR cause IN SELECT * FROM role_membership
                              WHERE member_id = membership.member_id
                                AND role_id = NEW.member_id
        LOOP
            SELECT INTO existing * FROM role_membership WHERE role_id = NEW.role_id
                                                          AND member_id = membership.member_id
                                                          AND direct_cause = cause.rec_id
                                                          AND indirect_cause = NEW.rec_id;
            IF existing IS NULL THEN
                INSERT INTO role_membership( role_id, member_id, direct_cause, indirect_cause )
                   VALUES( NEW.role_id, membership.member_id, cause.rec_id, NEW.rec_id );
            END IF;
        END LOOP;
    END LOOP;

    RETURN NULL;
END;
$populate_indirect$ LANGUAGE plpgsql;

CREATE TRIGGER add_membership
       AFTER INSERT ON role_membership
       FOR EACH ROW EXECUTE PROCEDURE add_membership();

-- When a membership is deleted - Should cascade :-)
-- XXX What about update, never happens in app, but someone might get stupid?

--bring values over from old table, trigger will sync them for us.
INSERT INTO role_membership( rec_id, role_id, member_id ) SELECT rec_id, role_id, member_id FROM personnel_role_member;
DROP TABLE personnel_role_member;

--Create some views to make finding what we need easier

--All memberships
CREATE VIEW role_member AS
    SELECT DISTINCT role_id, member_id FROM role_membership;

--Only direct memberships
CREATE VIEW direct_role_member AS 
    SELECT rec_id, role_id, member_id
      FROM role_membership
      WHERE direct_cause IS NULL AND indirect_cause IS NULL;

--Only indirect memberships
CREATE VIEW indirect_role_member AS 
    SELECT rec_id, role_id, member_id
      FROM role_membership
      WHERE direct_cause IS NOT NULL AND indirect_cause IS NOT NULL;

-- Make it easier to find permissions for groups
ALTER TABLE personnel_role_group_permission RENAME TO direct_group_permission;
ALTER TABLE personnel_role_group_permission_rec_id_seq RENAME TO direct_group_permission_rec_id_seq;

-- Cascade deletes
ALTER TABLE direct_group_permission DROP CONSTRAINT personnel_role_group_permission_group_id_fkey;
ALTER TABLE direct_group_permission DROP CONSTRAINT personnel_role_group_permission_role_id_fkey;
ALTER TABLE direct_group_permission ADD FOREIGN KEY (group_id) REFERENCES groups(rec_id) ON DELETE CASCADE;
ALTER TABLE direct_group_permission ADD FOREIGN KEY (role_id) REFERENCES personnel_role(rec_id) ON DELETE CASCADE;

--View to see indirect group permissions
CREATE VIEW indirect_group_permission AS
    SELECT DISTINCT m.member_id AS role_id,
                    d.group_id,
                    m.rec_id AS cause
      FROM role_membership AS m
      JOIN direct_group_permission as d
        on( m.role_id = d.role_id );

--View to see all group permissions
CREATE VIEW group_permission AS
    SELECT role_id, group_id, cause FROM indirect_group_permission
     UNION
    SELECT role_id, group_id, NULL AS cause FROM direct_group_permission;

--View to see client permissions granted by group
CREATE VIEW group_to_client_permission AS
    SELECT g.role_id, g.group_id, m.client_id
      FROM group_permission AS g
      JOIN group_members AS m
        ON( g.group_id = m.group_id );

--Make it easier to find permissions for clients
--Table holds direct
ALTER TABLE personnel_role_client_permission RENAME TO direct_client_permission;
ALTER TABLE personnel_role_client_permission_rec_id_seq RENAME TO direct_client_permission_rec_id_seq;

-- Cascade deletes
ALTER TABLE direct_client_permission DROP CONSTRAINT personnel_role_client_permission_client_id_fkey;
ALTER TABLE direct_client_permission DROP CONSTRAINT personnel_role_client_permission_role_id_fkey;
ALTER TABLE direct_client_permission ADD FOREIGN KEY (client_id) REFERENCES client(client_id) ON DELETE CASCADE;
ALTER TABLE direct_client_permission ADD FOREIGN KEY (role_id) REFERENCES personnel_role(rec_id) ON DELETE CASCADE;

--View to see indirect client permissions
CREATE VIEW indirect_client_permission AS
    SELECT m.member_id AS role_id,
           d.client_id
      FROM role_member AS m
      JOIN direct_client_permission AS d
        ON( m.role_id = d.role_id );

--View to see coordinator based permissions
CREATE VIEW coordinator_client_permission AS
    SELECT p.rec_id AS role_id,
           e.client_id,
           e.rec_id AS event_id
      FROM client_placement_event AS e
      JOIN personnel_role AS p
        ON ( p.staff_id = e.staff_id );

--View to see all client permissions
CREATE VIEW client_permission AS
    SELECT * FROM indirect_client_permission
     UNION
    SELECT role_id, client_id FROM direct_client_permission
     UNION
    SELECT role_id, client_id FROM group_to_client_permission
     UNION
    SELECT role_id, client_id FROM coordinator_client_permission;

--View to see all client permissions w/ cause
CREATE VIEW client_permission_map AS
    SELECT role_id, client_id, 'direct' AS reason, rec_id AS id
      FROM direct_client_permission
     UNION
    SELECT m.member_id AS role_id,
           d.client_id,
           'membership' AS reason,
           coalesce(m.direct_cause, m.rec_id) AS id
      FROM role_membership AS m
      JOIN direct_client_permission AS d
        ON (m.role_id = d.role_id)
     UNION
    SELECT role_id, client_id, 'group' AS reason, group_id AS id
      FROM group_to_client_permission
     UNION
    SELECT role_id, client_id, 'coordinator' AS reason, event_id AS id
      FROM coordinator_client_permission;

--Same as above, but filter system roles.
CREATE VIEW client_user_role_map AS
    SELECT m.role_id, m.client_id, m.reason, m.id, p.staff_id
      FROM client_permission_map AS m
      JOIN personnel_role AS p
        ON ( m.role_id = p.rec_id )
        WHERE p.system_role = FALSE;

--Get rid of all_clients special case in code by leveraging database.
--This adds access to every client for role 2 (all_clients)
INSERT INTO direct_client_permission( client_id, role_id ) SELECT client_id, '2' FROM client;
--This adds access to every group for role 3 (all_groups)
INSERT INTO direct_group_permission( group_id, role_id ) SELECT rec_id, '3' FROM groups;

--Trigger to keep all_clients in sync.

CREATE FUNCTION add_client()
RETURNS TRIGGER
AS $add_client$
DECLARE
    all_clients RECORD;
BEGIN
    SELECT INTO all_clients * FROM personnel_role WHERE special_name = 'all_clients';
    INSERT INTO direct_client_permission( role_id, client_id ) VALUES( all_clients.rec_id, NEW.client_id );
    RETURN NULL;
END;
$add_client$ LANGUAGE plpgsql;

CREATE TRIGGER add_client
       AFTER INSERT ON client
       FOR EACH ROW EXECUTE PROCEDURE add_client();

--Trigger to keep all_groups in sync.

CREATE FUNCTION add_group()
RETURNS TRIGGER
AS $add_group$
DECLARE
    all_groups RECORD;
BEGIN
    SELECT INTO all_groups * FROM personnel_role WHERE special_name = 'all_groups';
    INSERT INTO direct_group_permission( role_id, group_id ) VALUES( all_groups.rec_id, NEW.rec_id );
    RETURN NULL;
END;
$add_group$ LANGUAGE plpgsql;

CREATE TRIGGER add_group
       AFTER INSERT ON groups
       FOR EACH ROW EXECUTE PROCEDURE add_group();

-- Add group permissions for current group memberships
INSERT INTO direct_group_permission( role_id, group_id )
    SELECT DISTINCT c.role_id, m.group_id
      FROM group_members AS m
      JOIN client_permission AS c
        ON( m.client_id = c.client_id )
    EXCEPT SELECT role_id, group_id
             FROM direct_group_permission;

-- Do it again for depth
INSERT INTO direct_group_permission( role_id, group_id )
    SELECT DISTINCT c.role_id, m.group_id
      FROM group_members AS m
      JOIN client_permission AS c
        ON( m.client_id = c.client_id )
    EXCEPT SELECT role_id, group_id
             FROM direct_group_permission;

-- Trigger to maintain group permissions
CREATE FUNCTION add_group_member()
RETURNS TRIGGER
AS $add_group_member$
DECLARE
    existing RECORD;
    association RECORD;
BEGIN
    -- Find all roles associated with the client
    FOR association IN SELECT role_id, client_id
                         FROM client_permission
                        WHERE client_id = NEW.client_id
    LOOP
        -- See if the role already has group permissions
        SELECT INTO existing *
          FROM direct_group_permission
         WHERE group_id = NEW.group_id
           AND role_id = association.role_id;
        IF existing IS NULL THEN
            -- Add group permissions if none already exist.
            INSERT INTO direct_group_permission( role_id, group_id )
                   VALUES( association.role_id, NEW.group_id );
        END IF;
    END LOOP;
    RETURN NULL;
END;
$add_group_member$ LANGUAGE plpgsql;

CREATE TRIGGER add_group_member
       AFTER INSERT ON group_members
       FOR EACH ROW EXECUTE PROCEDURE add_group_member();
