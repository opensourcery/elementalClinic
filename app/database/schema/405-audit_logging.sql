create table audit_log (
    rec_id          serial not null primary key,
    staff_id        integer,
    query_params    varchar(255),
    op              varchar(255) not null,
    controller      varchar(255) not null,
    note            varchar(255),
    client_id       varchar(255),
    log_time        timestamp not null default localtimestamp
);
