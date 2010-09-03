CREATE TABLE by_state (
    rec_id              SERIAL PRIMARY KEY,
    rolodex_id          INTEGER REFERENCES rolodex(rec_id),
    state               TEXT    NOT NULL,

    -- A license id to practice medicine in a state
    license             TEXT,

    UNIQUE(rolodex_id, state)
);

COMMENT ON TABLE by_state IS 'Per-state information for a rolodex entry';
