UPDATE personnel SET password_expired = 0 WHERE staff_id = 1;
UPDATE personnel SET password_set = NOW() WHERE staff_id = 1;
