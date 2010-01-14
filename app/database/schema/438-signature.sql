ALTER TABLE prognote ADD COLUMN digital_signature TEXT;
ALTER TABLE prognote ADD COLUMN digital_signer INTEGER REFERENCES personnel( staff_id );
ALTER TABLE prognote ADD CONSTRAINT signer CHECK(
    ( digital_signature IS NOT NULL AND digital_signer IS NOT NULL )
    OR
    ( digital_signature IS NULL OR digital_signer IS NULL )
);

