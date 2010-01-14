alter table prognote alter column created set default to_timestamp( (now())::text, 'YYYY-MM-DD HH24:MI:SS' );
