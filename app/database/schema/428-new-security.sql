CREATE TABLE security_role (
  name VARCHAR(40) NOT NULL PRIMARY KEY
);

CREATE TABLE personnel_security_role (
  staff_id INTEGER NOT NULL REFERENCES personnel(staff_id),
  role_name VARCHAR(40) NOT NULL REFERENCES security_role(name),
  PRIMARY KEY (staff_id, role_name)
);
