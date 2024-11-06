CREATE TABLE customers AS
SELECT
    *
FROM
    dblink(
        'dbname=prod user=avantehs_admin@avantehs password=V84%=qbbT=vY_VFgk:34}7Bwd!7w$Gbf host=avantehs.postgres.database.azure.com',
        'SELECT * FROM customers'
    ) AS t1(id varchar(50), name text);

CREATE TABLE sites AS
SELECT
    *
FROM
    dblink(
        'dbname=prod user=avantehs_admin@avantehs password=V84%=qbbT=vY_VFgk:34}7Bwd!7w$Gbf host=avantehs.postgres.database.azure.com',
        'SELECT * FROM sites'
    ) AS t1(
        id varchar(50),
        customer_id varchar(50),
        name text,
        state text,
        city varchar(50),
        street_address varchar(100),
        zip varchar(10),
        coords point,
        time_zone_id text
    );

CREATE TABLE systems AS
SELECT
    *
FROM
    dblink(
        'dbname=prod user=avantehs_admin@avantehs password=V84%=qbbT=vY_VFgk:34}7Bwd!7w$Gbf host=avantehs.postgres.database.azure.com',
        'SELECT * FROM systems'
    ) AS t1(
        id varchar(50),
        site_id varchar(50),
        manufacturer varchar(50),
        modality varchar(50),
        model varchar(50),
        serial_number varchar(50),
        software_version varchar(50),
        room varchar(50),
        mmb_config jsonb,
        hhm_config jsonb,
        hhm_file_config jsonb,
        show_on_website bool,
        cus_sys_id varchar(50),
        process_edu bool,
        process_mag bool,
        process_log bool,
        ip_address inet
    );

CREATE TABLE config.mag AS
SELECT
    *
FROM
    dblink(
        'dbname=prod user=avantehs_admin@avantehs password=V84%=qbbT=vY_VFgk:34}7Bwd!7w$Gbf host=avantehs.postgres.database.azure.com',
        'SELECT * FROM config.mag'
    ) AS t1(
        system_id text,
        file_name text,
        dir_name text,
        regex_models _text,
        pg_tables _text,
        column_name text,
        schedule int4,
        agg text,
        last_updated_by text,
        last_updated_at timestamptz
    );

CREATE TABLE config.log AS
SELECT
    *
FROM
    dblink(
        'dbname=prod user=avantehs_admin@avantehs password=V84%=qbbT=vY_VFgk:34}7Bwd!7w$Gbf host=avantehs.postgres.database.azure.com',
        'SELECT * FROM config.log'
    ) AS t1(
        system_id text,
        file_name text,
        dir_name text,
        regex_models _text,
        pg_tables _text,
        column_name text,
        agg text,
        last_updated_by text,
        last_updated_at timestamptz
    );