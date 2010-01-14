-- all these sorts of sequences need to be owned by the primary key column that
-- uses them so that fixture loading can find and reset them

ALTER SEQUENCE client_client_id_seq OWNED BY client.client_id;
