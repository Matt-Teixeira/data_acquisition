INSERT INTO
    config.acquisition(
        system_id,
        host_ip,
        mmb_ip,
        protocal,
        debian_server_path,
        credentials_group,
        acquisition_script,
        run_group,
        host,
        user_id,
        acqu_point,
        host_path,
        cerb_file
    )
VALUES
    (
        'SME01441',
        '10.10.10.3',
        NULL,
        'lftp',
        '/home/prod/hhm_data_acquisition/files/SME01441',
        '17',
        'siemens_cerb.sh',
        1,
        NULL,
        NULL,
        NULL,
        'C027932/SHIP013/SME01441',
        'error_A1_'
    );

INSERT INTO
    config.log (
        system_id,
        file_name,
        dir_name,
        regex_models,
        pg_tables,
        column_name,
        agg
    )
VALUES
    (
        'SME01441',
        'Evtlog.txt',
        'Evtlog',
        ARRAY ['cv_bulk', 'cv_groups'],
        ARRAY ['siemens_cv'],
        NULL,
        NULL
    );

-- >
-- >
INSERT INTO
    config.acquisition(
        system_id,
        host_ip,
        mmb_ip,
        protocal,
        debian_server_path,
        credentials_group,
        acquisition_script,
        run_group,
        host,
        user_id,
        acqu_point,
        host_path,
        cerb_file
    )
VALUES
    (
        'SME00817',
        '10.10.10.3',
        NULL,
        'lftp',
        '/home/prod/hhm_data_acquisition/files/SME00817',
        '17',
        'siemens_cerb.sh',
        1,
        NULL,
        NULL,
        NULL,
        'C0137/SHIP009/SME00817',
        'error.log_A1_'
    );

INSERT INTO
    config.log (
        system_id,
        file_name,
        dir_name,
        regex_models,
        pg_tables,
        column_name,
        agg
    )
VALUES
    (
        'SME00817',
        'Evtlog.txt',
        'Evtlog',
        ARRAY ['cv_bulk', 'cv_groups'],
        ARRAY ['siemens_cv'],
        NULL,
        NULL
    );

-- >
-- >
INSERT INTO
    config.acquisition(
        system_id,
        host_ip,
        mmb_ip,
        protocal,
        debian_server_path,
        credentials_group,
        acquisition_script,
        run_group,
        host,
        user_id,
        acqu_point,
        host_path,
        cerb_file
    )
VALUES
    (
        'SME00853',
        '10.10.10.3',
        NULL,
        'lftp',
        '/home/prod/hhm_data_acquisition/files/SME00853',
        '17',
        'siemens_cerb.sh',
        1,
        NULL,
        NULL,
        NULL,
        'C0137/SHIP020/SME00853',
        'Errors_A1_'
    );

INSERT INTO
    config.log (
        system_id,
        file_name,
        dir_name,
        regex_models,
        pg_tables,
        column_name,
        agg
    )
VALUES
    (
        'SME00853',
        'Evtlog.txt',
        'Evtlog',
        ARRAY ['cv_bulk', 'cv_groups'],
        ARRAY ['siemens_cv'],
        NULL,
        NULL
    );

-- >
-- >
INSERT INTO
    config.acquisition(
        system_id,
        host_ip,
        mmb_ip,
        protocal,
        debian_server_path,
        credentials_group,
        acquisition_script,
        run_group,
        host,
        user_id,
        acqu_point,
        host_path,
        cerb_file
    )
VALUES
    (
        'SME01445',
        '10.10.10.3',
        NULL,
        'lftp',
        '/home/prod/hhm_data_acquisition/files/SME01445',
        '17',
        'siemens_cerb.sh',
        1,
        NULL,
        NULL,
        NULL,
        'C027932/SHIP04/SME01445',
        'Error_Log_A1_'
    );

INSERT INTO
    config.log (
        system_id,
        file_name,
        dir_name,
        regex_models,
        pg_tables,
        column_name,
        agg
    )
VALUES
    (
        'SME01445',
        'Evtlog.txt',
        'Evtlog',
        ARRAY ['cv_bulk', 'cv_groups'],
        ARRAY ['siemens_cv'],
        NULL,
        NULL
    );

-- >
-- >
INSERT INTO
    config.acquisition(
        system_id,
        host_ip,
        mmb_ip,
        protocal,
        debian_server_path,
        credentials_group,
        acquisition_script,
        run_group,
        host,
        user_id,
        acqu_point,
        host_path,
        cerb_file
    )
VALUES
    (
        'SME08929',
        '10.10.10.3',
        NULL,
        'lftp',
        '/home/prod/hhm_data_acquisition/files/SME08929',
        '17',
        'siemens_cerb.sh',
        1,
        NULL,
        NULL,
        NULL,
        'C0162/SHIP045/SME08929',
        'ERRORS_A1_'
    );

INSERT INTO
    config.log (
        system_id,
        file_name,
        dir_name,
        regex_models,
        pg_tables,
        column_name,
        agg
    )
VALUES
    (
        'SME08929',
        'Evtlog.txt',
        'Evtlog',
        ARRAY ['cv_bulk', 'cv_groups'],
        ARRAY ['siemens_cv'],
        NULL,
        NULL
    );

-- >
-- >
INSERT INTO
    config.acquisition(
        system_id,
        host_ip,
        mmb_ip,
        protocal,
        debian_server_path,
        credentials_group,
        acquisition_script,
        run_group,
        host,
        user_id,
        acqu_point,
        host_path,
        cerb_file
    )
VALUES
    (
        'SME08930',
        '10.10.10.3',
        NULL,
        'lftp',
        '/home/prod/hhm_data_acquisition/files/SME08930',
        '17',
        'siemens_cerb.sh',
        1,
        NULL,
        NULL,
        NULL,
        'C0162/SHIP044/SME08930',
        'ERRORS_A1_'
    );

INSERT INTO
    config.log (
        system_id,
        file_name,
        dir_name,
        regex_models,
        pg_tables,
        column_name,
        agg
    )
VALUES
    (
        'SME08930',
        'Evtlog.txt',
        'Evtlog',
        ARRAY ['cv_bulk', 'cv_groups'],
        ARRAY ['siemens_cv'],
        NULL,
        NULL
    );

-- >
-- >
INSERT INTO
    config.acquisition(
        system_id,
        host_ip,
        mmb_ip,
        protocal,
        debian_server_path,
        credentials_group,
        acquisition_script,
        run_group,
        host,
        user_id,
        acqu_point,
        host_path,
        cerb_file
    )
VALUES
    (
        'SME08931',
        '10.10.10.3',
        NULL,
        'lftp',
        '/home/prod/hhm_data_acquisition/files/SME08931',
        '17',
        'siemens_cerb.sh',
        1,
        NULL,
        NULL,
        NULL,
        'C0162/SHIP045/SME08931',
        'ERRORS_A1_'
    );

INSERT INTO
    config.log (
        system_id,
        file_name,
        dir_name,
        regex_models,
        pg_tables,
        column_name,
        agg
    )
VALUES
    (
        'SME08931',
        'Evtlog.txt',
        'Evtlog',
        ARRAY ['cv_bulk', 'cv_groups'],
        ARRAY ['siemens_cv'],
        NULL,
        NULL
    );

-- >
-- >
INSERT INTO
    config.acquisition(
        system_id,
        host_ip,
        mmb_ip,
        protocal,
        debian_server_path,
        credentials_group,
        acquisition_script,
        run_group,
        host,
        user_id,
        acqu_point,
        host_path,
        cerb_file
    )
VALUES
    (
        'SME08932',
        '10.10.10.3',
        NULL,
        'lftp',
        '/home/prod/hhm_data_acquisition/files/SME08932',
        '17',
        'siemens_cerb.sh',
        1,
        NULL,
        NULL,
        NULL,
        'C0162/SHIP044/SME08932',
        'errors_A1_'
    );

INSERT INTO
    config.log (
        system_id,
        file_name,
        dir_name,
        regex_models,
        pg_tables,
        column_name,
        agg
    )
VALUES
    (
        'SME08932',
        'Evtlog.txt',
        'Evtlog',
        ARRAY ['cv_bulk', 'cv_groups'],
        ARRAY ['siemens_cv'],
        NULL,
        NULL
    );

-- >
-- >
INSERT INTO
    config.acquisition(
        system_id,
        host_ip,
        mmb_ip,
        protocal,
        debian_server_path,
        credentials_group,
        acquisition_script,
        run_group,
        host,
        user_id,
        acqu_point,
        host_path,
        cerb_file
    )
VALUES
    (
        'SME08933',
        '10.10.10.3',
        NULL,
        'lftp',
        '/home/prod/hhm_data_acquisition/files/SME08933',
        '17',
        'siemens_cerb.sh',
        1,
        NULL,
        NULL,
        NULL,
        'C0162/SHIP044/SME08933',
        'error_A1_'
    );

INSERT INTO
    config.log (
        system_id,
        file_name,
        dir_name,
        regex_models,
        pg_tables,
        column_name,
        agg
    )
VALUES
    (
        'SME08933',
        'Evtlog.txt',
        'Evtlog',
        ARRAY ['cv_bulk', 'cv_groups'],
        ARRAY ['siemens_cv'],
        NULL,
        NULL
    );

-- >
-- >
INSERT INTO
    config.acquisition(
        system_id,
        host_ip,
        mmb_ip,
        protocal,
        debian_server_path,
        credentials_group,
        acquisition_script,
        run_group,
        host,
        user_id,
        acqu_point,
        host_path,
        cerb_file
    )
VALUES
    (
        'SME08934',
        '10.10.10.3',
        NULL,
        'lftp',
        '/home/prod/hhm_data_acquisition/files/SME08934',
        '17',
        'siemens_cerb.sh',
        1,
        NULL,
        NULL,
        NULL,
        'C0162/SHIP044/SME08934',
        'error_A1_'
    );

INSERT INTO
    config.log (
        system_id,
        file_name,
        dir_name,
        regex_models,
        pg_tables,
        column_name,
        agg
    )
VALUES
    (
        'SME08934',
        'Evtlog.txt',
        'Evtlog',
        ARRAY ['cv_bulk', 'cv_groups'],
        ARRAY ['siemens_cv'],
        NULL,
        NULL
    );

-->
-->
-->
-->

INSERT INTO
    config.acquisition(
        system_id,
        host_ip,
        mmb_ip,
        protocal,
        debian_server_path,
        credentials_group,
        acquisition_script,
        run_group,
        host,
        user_id,
        acqu_point,
        host_path,
        cerb_file
    )
VALUES
    (
        'SME00543',
        '10.10.10.3',
        NULL,
        'lftp',
        '/home/prod/hhm_data_acquisition/files/SME00543',
        '17',
        'siemens_cerb.sh',
        1,
        NULL,
        NULL,
        NULL,
        'C0183/SHIP002/SME00543',
        'error.log_A1_'
    );

INSERT INTO
    config.log (
        system_id,
        file_name,
        dir_name,
        regex_models,
        pg_tables,
        column_name,
        agg
    )
VALUES
    (
        'SME00543',
        'Evtlog.txt',
        'Evtlog',
        ARRAY ['cv_bulk', 'cv_groups'],
        ARRAY ['siemens_cv'],
        NULL,
        NULL
    );

--> DEMO SYSTEM 11/10/2026
-->

INSERT INTO
    config.acquisition(
        system_id,
        host_ip,
        mmb_ip,
        protocal,
        debian_server_path,
        credentials_group,
        acquisition_script,
        run_group,
        host,
        user_id,
        acqu_point,
        host_path,
        cerb_file
    )
VALUES
    (
        'SME10007',
        '172.31.3.120',
        NULL,
        'lftp',
        '/home/prod/hhm_data_acquisition/files/SME10007',
        '<hhm_credentials id for avante@172.31.3.120>', -- set by go-live SQL below
        'siemens_cv_logfiles_zip.sh',
        1,
        NULL,
        'avante',
        'host',
        '/srv/ftp/arts',
        'XA160418_'
    );


INSERT INTO
    config.log (
        system_id,
        file_name,
        dir_name,
        regex_models,
        pg_tables,
        column_name,
        agg
    )
VALUES
    (
        'SME10007',
        'AppEventLog.txt',
        'Event_Logs',
        ARRAY ['cv_app_event_line'],
        ARRAY ['siemens_cv'],
        NULL,
        NULL
    );

-- > SME10007 GO-LIVE
-- > Artis pushes XA160418_<yyyy_mm_dd>_LogFiles.zip to avante@172.31.3.120:/srv/ftp/arts.
-- > siemens_cv_logfiles_zip.sh mirrors the zips and extracts *_AppEventLog.txt flat
-- > into debian_server_path for hhm_rpp_siemens (cv_app_event_line).
-- > Credentials: avante / avante (encrypted with util/encrypt). Row 24 (avante/mmb)
-- > has a different password, so this box gets its own row.
-- > Explicit id: hhm_credentials_id_seq was behind max(id) (last_value 2), so a
-- > default insert hit a pkey collision.
INSERT INTO
    hhm_credentials (id, user_num, pass_num, manufacturer, modality, user_enc, password_enc)
VALUES
    ('25', '2', '2', 'avante', 'arts', '71c3549a9139e73ea21ed4e32ff482e3', '71c3549a9139e73ea21ed4e32ff482e3');

UPDATE
    config.acquisition
SET
    credentials_group = '25',
    acquisition_script = 'siemens_cv_logfiles_zip.sh'
WHERE
    system_id = 'SME10007';

-- get_hhm only selects systems with process_log = true
UPDATE systems SET process_log = true WHERE id = 'SME10007';
