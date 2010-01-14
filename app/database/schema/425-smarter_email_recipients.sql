ALTER TABLE email_recipients ALTER COLUMN client_id DROP NOT NULL;
ALTER TABLE email_recipients ADD COLUMN email_address TEXT;
ALTER TABLE email_recipients ADD CHECK (
    (client_id IS NULL AND email_address IS NOT NULL) OR
    (email_address IS NULL AND client_id IS NOT NULL)
);
