BEGIN;

-- Drop old static tables
DROP TABLE IF EXISTS log.ge_ct_gesys CASCADE;

DROP TABLE IF EXISTS log.ge_cv_syserror CASCADE;

DROP TABLE IF EXISTS log.ge_mri_gesys CASCADE;

DROP TABLE IF EXISTS log.philips_cv_eventlog CASCADE;

DROP TABLE IF EXISTS log.siemens_cv CASCADE;

DROP TABLE IF EXISTS log.siemens_mri CASCADE;

DROP TABLE IF EXISTS log.siemens_ct CASCADE;

DROP TABLE IF EXISTS log.philips_ct_eal CASCADE;

DROP TABLE IF EXISTS log.philips_ct_events CASCADE;

DROP TABLE IF EXISTS log.philips_mri_logcurrent CASCADE;

DROP TABLE IF EXISTS log.stt_magnet CASCADE;

DROP TABLE IF EXISTS mag.philips_mri_rmmu_history CASCADE;

DROP TABLE IF EXISTS mag.philips_mri_rmmu_magnet CASCADE;

DROP TABLE IF EXISTS mag.philips_mri_rmmu_short CASCADE;

DROP TABLE IF EXISTS mag.philips_mri_rmmu_long CASCADE;

DROP TABLE IF EXISTS logfile_event_history_metadata CASCADE;

DROP TABLE IF EXISTS mag.philips_mri_json;

DROP TABLE IF EXISTS mag.philips_mri_monitoring_data;

DROP TABLE IF EXISTS mag.philips_mri_monitoring_data_agg;

DROP TABLE IF EXISTS alert.offline;

--CREATE SCHEMA log;
--CREATE SCHEMA mag;
ROLLBACK;

BEGIN;

CREATE TABLE IF NOT EXISTS logfile_event_history_metadata (
    id BIGSERIAL,
    system_id TEXT,
    host_datetime TIMESTAMP WITH TIME ZONE,
    name TEXT,
    value TEXT,
    CONSTRAINT pk_logfile_event_history_metadata PRIMARY KEY (id, system_id)
);

CREATE TABLE IF NOT EXISTS log.siemens_mri(
    id BIGSERIAL PRIMARY KEY,
    system_id TEXT,
    host_state TEXT,
    host_date DATE,
    host_time TIME,
    source_group TEXT,
    type_group INT,
    text_group TEXT,
    domain_group TEXT,
    id_group INT,
    month TEXT,
    day INT,
    year INT,
    host_datetime TIMESTAMP WITH TIME ZONE,
    status BOOLEAN DEFAULT FALSE,
    capture_datetime TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS log.siemens_ct(
    id BIGSERIAL PRIMARY KEY,
    system_id TEXT,
    host_state TEXT,
    host_date DATE,
    host_time TIME,
    source_group TEXT,
    type_group INT,
    text_group TEXT,
    domain_group TEXT,
    id_group INT,
    month TEXT,
    day INT,
    year INT,
    host_datetime TIMESTAMP WITH TIME ZONE,
    status BOOLEAN DEFAULT FALSE,
    capture_datetime TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS log.siemens_cv(
    id BIGSERIAL PRIMARY KEY,
    system_id VARCHAR(10),
    source TEXT,
    domain TEXT,
    type TEXT,
    id_group TEXT,
    dow TEXT,
    month TEXT,
    day INT,
    year INT,
    time TIME,
    TEXT TEXT,
    host_datetime TIMESTAMP WITH TIME ZONE,
    status BOOLEAN DEFAULT FALSE,
    capture_datetime TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS log.ge_mri_gesys(
    id BIGSERIAL PRIMARY KEY,
    system_id TEXT,
    epoch INT,
    record_number_concurrent INT,
    misc_param_1 INT,
    month VARCHAR(4),
    day INT,
    host_date TEXT,
    host_time TIME,
    year INT,
    message_number INT,
    misc_param_2 INT,
    type TEXT,
    data_1 TEXT,
    num_1 INT,
    server TEXT,
    task_id TEXT,
    task_epoc INT,
    object TEXT,
    exception_class TEXT,
    severity TEXT,
    function TEXT,
    psd TEXT,
    coil TEXT,
    scan TEXT,
    message TEXT,
    sr INT,
    en INT,
    host_datetime TIMESTAMP WITH TIME ZONE,
    status BOOLEAN DEFAULT FALSE,
    capture_datetime TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS log.ge_ct_gesys(
    id BIGSERIAL PRIMARY KEY,
    system_id TEXT,
    epoch INT,
    record_number_concurrent INT,
    misc_param_1 INT,
    month VARCHAR(4),
    day INT,
    host_date TEXT,
    host_time TIME,
    year INT,
    message_number INT,
    misc_param_2 INT,
    type TEXT,
    data_1 TEXT,
    num_1 INT,
    date_2 TEXT,
    host TEXT,
    ermes_number INT,
    exception_class TEXT,
    severity TEXT,
    file TEXT,
    line_number INT,
    scan_type TEXT,
    warning TEXT,
    end_msg TEXT,
    message TEXT,
    sr INT,
    en INT,
    host_datetime TIMESTAMP WITH TIME ZONE,
    status BOOLEAN DEFAULT FALSE,
    capture_datetime TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS log.ge_cv_syserror(
    id BIGSERIAL PRIMARY KEY,
    system_id TEXT,
    sequencenumber INT,
    host_date DATE,
    host_time TEXT,
    subsystem VARCHAR(8),
    errorcode INT,
    errortext TEXT,
    exam INT,
    exceptioncategory VARCHAR(10),
    application TEXT,
    majorfunction TEXT,
    minorfunction TEXT,
    fru TEXT,
    viewinglevel INT,
    rootcause INT,
    repeatcount INT,
    debugtext TEXT,
    sourcefile TEXT,
    sourceline INT,
    host_datetime TIMESTAMP WITH TIME ZONE,
    status BOOLEAN DEFAULT FALSE,
    capture_datetime TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS log.philips_ct_eal(
    id BIGSERIAL PRIMARY KEY,
    system_id TEXT,
    host_date TEXT,
    host_time TEXT,
    controller TEXT,
    data_type TEXT,
    log_number TEXT,
    tm_stamp TEXT,
    err_type TEXT,
    err_number TEXT,
    vxw_err_no TEXT,
    file TEXT,
    line TEXT,
    param_1 TEXT,
    param_2 TEXT,
    info TEXT,
    eal_time TEXT,
    host_datetime TIMESTAMP WITH TIME ZONE,
    status BOOLEAN DEFAULT FALSE,
    capture_datetime TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS log.philips_ct_events(
    id BIGSERIAL PRIMARY KEY,
    system_id TEXT,
    type TEXT,
    level TEXT,
    module TEXT,
    time_stamp TEXT,
    host_date TEXT,
    host_time TEXT,
    message TEXT,
    eal TEXT,
    event_time TEXT,
    host_datetime TIMESTAMP WITH TIME ZONE,
    status BOOLEAN DEFAULT FALSE,
    capture_datetime TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS log.philips_ct_eal_events(
    id BIGSERIAL PRIMARY KEY,
    system_id TEXT,
    host_date TEXT,
    host_time TEXT,
    controller TEXT,
    data_type TEXT,
    log_number TEXT,
    tm_stamp TEXT,
    err_type TEXT,
    err_number TEXT,
    vxw_err_no TEXT,
    file TEXT,
    line TEXT,
    param_1 TEXT,
    param_2 TEXT,
    info TEXT,
    eal_time TEXT,
    type TEXT,
    level TEXT,
    module TEXT,
    time_stamp TEXT,
    message TEXT,
    eal TEXT,
    event_time TEXT,
    host_datetime TIMESTAMP WITH TIME ZONE,
    status BOOLEAN DEFAULT FALSE,
    capture_datetime TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS mag.philips_mri_rmmu_history(
    id BIGSERIAL PRIMARY KEY,
    system_id TEXT,
    Line INT,
    Time INT,
    Stat INT,
    AvgPwr INT,
    MinPwr INT,
    MaxPwr INT,
    MinPr INT,
    MaxPr INT,
    LHe1 INT,
    LHe2 INT,
    DPS INT,
    TALM INT,
    PALM INT,
    CRes INT,
    system_reference_number INT,
    hospital_name TEXT,
    host_datetime TIMESTAMP WITH TIME ZONE,
    status BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS mag.philips_mri_rmmu_magnet(
    id BIGSERIAL PRIMARY KEY,
    system_id TEXT,
    system_reference_number TEXT,
    hospital_name TEXT,
    serial_number_magnet TEXT,
    serial_number_meu TEXT,
    lineno INT,
    year INT,
    mo INT,
    dy INT,
    hr INT,
    mn INT,
    ss INT,
    hs INT,
    event TEXT,
    data TEXT,
    descr TEXT,
    host_datetime TIMESTAMP WITH TIME ZONE,
    status BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS log.philips_mri_logcurrent(
    id BIGSERIAL PRIMARY KEY,
    system_id TEXT,
    host_date DATE,
    host_time TIME,
    row_type TEXT,
    event_type TEXT,
    subsystem TEXT,
    code_1 TEXT,
    code_2 TEXT,
    group_1 TEXT,
    message TEXT,
    packets_created TEXT,
    data_created_value TEXT,
    size_copy_value TEXT,
    data_8 TEXT,
    reconstructor TEXT,
    magnet_meu text,
    host_datetime TIMESTAMP WITH TIME ZONE,
    status BOOLEAN DEFAULT FALSE,
    capture_datetime TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS mag.philips_mri_rmmu_short(
    id BIGSERIAL PRIMARY KEY,
    system_id TEXT,
    system_reference_number TEXT,
    hospital_name TEXT,
    serial_number_magnet TEXT,
    serial_number_meu TEXT,
    lineno INT,
    year INT,
    mo INT,
    dy INT,
    hr INT,
    mn INT,
    ss INT,
    hs INT,
    AvgPwr_value INT,
    MinPwr_value INT,
    MaxPwr_value INT,
    AvgAbs_value INT,
    AvgPrMbars_value INT,
    MinPrMbars_value INT,
    MaxPrMbars_value INT,
    LHePct_value INT,
    LHe2_value INT,
    DiffPressureSwitch_state varchar(2),
    TempAlarm_state varchar(2),
    PressureAlarm_state varchar(2),
    Cerr_state varchar(2),
    CompressorReset_state varchar(2),
    Chd_value INT,
    Cpr_value INT,
    host_datetime TIMESTAMP WITH TIME ZONE,
    status BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS mag.philips_mri_rmmu_long(
    id BIGSERIAL PRIMARY KEY,
    system_id TEXT,
    system_reference_number TEXT,
    hospital_name TEXT,
    serial_number_magnet TEXT,
    serial_number_meu TEXT,
    lineno INT,
    year INT,
    mo INT,
    dy INT,
    hr INT,
    mn INT,
    ss INT,
    hs INT,
    dow_value INT,
    AvgPwr_value INT,
    MinPwr_value INT,
    MaxPwr_value INT,
    AvgAbs_value INT,
    AvgPrMbars_value INT,
    MinPrMbars_value INT,
    MaxPrMbars_value INT,
    LHePct_value INT,
    LHe2_value INT,
    DiffPressureSwitch_state varchar(2),
    TempAlarm_state varchar(2),
    PressureAlarm_state varchar(2),
    Cerr_state varchar(2),
    CompressorReset_state varchar(2),
    Chd_value INT,
    Cpr_value INT,
    host_datetime TIMESTAMP WITH TIME ZONE,
    status BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS log.stt_magnet(
    id BIGSERIAL PRIMARY KEY,
    system_id TEXT,
    host_date DATE,
    host_time TIME,
    header_1 TEXT,
    header_2 TEXT,
    category TEXT,
    status_value numeric,
    test_result_2 TEXT,
    test_result TEXT,
    message TEXT,
    host_datetime TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS log.philips_cv_eventlog(
    id BIGSERIAL PRIMARY KEY,
    system_id TEXT,
    category TEXT,
    host_date DATE,
    host_time TIME,
    error_type TEXT,
    num_1 INT,
    technical_event_id INT,
    description TEXT,
    channel_id TEXT,
    module TEXT,
    source TEXT,
    line INT,
    memo TEXT,
    subsystem_number INT,
    thread_name TEXT,
    message TEXT,
    host_datetime TIMESTAMP WITH TIME ZONE,
    status BOOLEAN DEFAULT FALSE,
    capture_datetime TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS mag.philips_mri_json(
    capture_time TIMESTAMP WITH TIME ZONE,
    system_id TEXT,
    monitoring_data jsonb,
    process_success BOOLEAN DEFAULT false,
    CONSTRAINT pk_philips_mri_json PRIMARY KEY (system_id, capture_time)
);

CREATE TABLE IF NOT EXISTS mag.philips_mri_monitoring_data(
    system_id TEXT,
    host_datetime TIMESTAMP WITH TIME ZONE,
    date TEXT,
    tech_room_humidity_value DECIMAL,
    -- [%] (0=sensor not connected or broken)
    tech_room_temp_value DECIMAL,
    -- [C](0=sensor not connected or broken)
    cryo_comp_comm_error_state DECIMAL,
    -- 0=OK, > 0 = alarm bool
    cryo_comp_press_alarm_state DECIMAL,
    -- (minutes) [0=OK, > 0 = alarm]
    cryo_comp_temp_alarm_state DECIMAL,
    -- (minutes) [0=OK, > 0 = alarm]
    cryo_comp_malf_value DECIMAL,
    -- (minutes) [-1=Cable error, 0=OK, > 0 = alarm in minutes)]
    helium_level_value DECIMAL,
    -- [%]
    long_term_boil_off_value DECIMAL,
    -- (-1 = stuck_probe) [ml/h]
    mag_dps_status_value DECIMAL,
    -- (minutes) [0=OK,  >0 =Alarm status]
    quenched_state DECIMAL,
    -- [0=No;1=Yes
    monitor_magnet_pressure_value DECIMAL,
    he_psi_avg_value DECIMAL,
    CONSTRAINT pk_philips_mri_monitoring_data PRIMARY KEY (system_id, host_datetime)
);

CREATE TABLE IF NOT EXISTS mag.philips_mri_monitoring_data_agg(
    system_id TEXT,
    date TEXT,
    capture_datetime TIMESTAMP WITH TIME ZONE,
    host_datetime TIMESTAMP WITH TIME ZONE,
    tech_room_humidity_value DECIMAL,
    -- [%] (0=sensor not connected or broken)
    tech_room_temp_value DECIMAL,
    -- [C](0=sensor not connected or broken)
    cryo_comp_comm_error_state DECIMAL,
    -- 0=OK, > 0 = alarm bool
    cryo_comp_press_alarm_state DECIMAL,
    -- (minutes) [0=OK, > 0 = alarm]
    cryo_comp_temp_alarm_state DECIMAL,
    -- (minutes) [0=OK, > 0 = alarm]
    cryo_comp_malf_value DECIMAL,
    -- (minutes) [-1=Cable error, 0=OK, > 0 = alarm in minutes)]
    helium_level_value DECIMAL,
    -- [%]
    long_term_boil_off_value DECIMAL,
    -- (-1 = stuck_probe) [ml/h]
    mag_dps_status_value DECIMAL,
    -- (minutes) [0=OK,  >0 =Alarm status]
    quenched_state DECIMAL,
    -- [0=No;1=Yes
    monitor_magnet_pressure_value DECIMAL,
    he_psi_avg_value DECIMAL,
    CONSTRAINT pk_philips_mri_monitoring_data_agg PRIMARY KEY (system_id, capture_datetime)
);

ROLLBACK;

BEGIN;

CREATE
OR REPLACE FUNCTION upsert_philips_mri_monitoring_data() RETURNS TRIGGER AS $ $ BEGIN
INSERT INTO
    mag.philips_mri_monitoring_data (
        system_id,
        host_datetime,
        date,
        tech_room_humidity_value,
        tech_room_temp_value,
        cryo_comp_comm_error_state,
        cryo_comp_press_alarm_state,
        cryo_comp_temp_alarm_state,
        cryo_comp_malf_value,
        helium_level_value,
        long_term_boil_off_value,
        mag_dps_status_value,
        quenched_state,
        monitor_magnet_pressure_value,
        he_psi_avg_value
    )
VALUES
    (
        NEW.system_id,
        NEW.host_datetime,
        NEW.date,
        NEW.tech_room_humidity_value,
        NEW.tech_room_temp_value,
        NEW.cryo_comp_comm_error_state,
        NEW.cryo_comp_press_alarm_state,
        NEW.cryo_comp_temp_alarm_state,
        NEW.cryo_comp_malf_value,
        NEW.helium_level_value,
        NEW.long_term_boil_off_value,
        NEW.mag_dps_status_value,
        NEW.quenched_state,
        NEW.monitor_magnet_pressure_value,
        NEW.he_psi_avg_value
    ) ON CONFLICT (system_id, host_datetime) DO
UPDATE
SET
    date = COALESCE(excluded.date, philips_mri_monitoring_data.date),
    tech_room_humidity_value = COALESCE(
        excluded.tech_room_humidity_value,
        philips_mri_monitoring_data.tech_room_humidity_value
    ),
    tech_room_temp_value = COALESCE(
        excluded.tech_room_temp_value,
        philips_mri_monitoring_data.tech_room_temp_value
    ),
    cryo_comp_comm_error_state = COALESCE(
        excluded.cryo_comp_comm_error_state,
        philips_mri_monitoring_data.cryo_comp_comm_error_state
    ),
    cryo_comp_press_alarm_state = COALESCE(
        excluded.cryo_comp_press_alarm_state,
        philips_mri_monitoring_data.cryo_comp_press_alarm_state
    ),
    cryo_comp_temp_alarm_state = COALESCE(
        excluded.cryo_comp_temp_alarm_state,
        philips_mri_monitoring_data.cryo_comp_temp_alarm_state
    ),
    cryo_comp_malf_value = COALESCE(
        excluded.cryo_comp_malf_value,
        philips_mri_monitoring_data.cryo_comp_malf_value
    ),
    helium_level_value = COALESCE(
        excluded.helium_level_value,
        philips_mri_monitoring_data.helium_level_value
    ),
    long_term_boil_off_value = COALESCE(
        excluded.long_term_boil_off_value,
        philips_mri_monitoring_data.long_term_boil_off_value
    ),
    mag_dps_status_value = COALESCE(
        excluded.mag_dps_status_value,
        philips_mri_monitoring_data.mag_dps_status_value
    ),
    quenched_state = COALESCE(
        excluded.quenched_state,
        philips_mri_monitoring_data.quenched_state
    ),
    monitor_magnet_pressure_value = COALESCE(
        excluded.monitor_magnet_pressure_value,
        philips_mri_monitoring_data.monitor_magnet_pressure_value
    ),
    he_psi_avg_value = COALESCE(
        excluded.he_psi_avg_value,
        philips_mri_monitoring_data.he_psi_avg_value
    );

RETURN NULL;

END;

$ $ LANGUAGE plpgsql;

CREATE TRIGGER philips_mri_monitoring_data_upsert_trigger
AFTER
INSERT
    ON mag.philips_mri_monitoring_data_agg FOR EACH ROW EXECUTE FUNCTION upsert_philips_mri_monitoring_data();

CREATE TRIGGER philips_mri_monitoring_data_upsert_update_trigger
AFTER
UPDATE
    ON mag.philips_mri_monitoring_data_agg FOR EACH ROW EXECUTE FUNCTION upsert_philips_mri_monitoring_data();

ROLLBACK;

-- Alerts
CREATE TABLE IF NOT EXISTS alert.offline_mmb_conn(
    system_id VARCHAR(8) PRIMARY KEY,
    capture_datetime TIMESTAMP WITH TIME zone,
    inserted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS alert.offline_hhm_conn(
    system_id VARCHAR(8) PRIMARY KEY,
    capture_datetime TIMESTAMP WITH TIME zone,
    inserted_at TIMESTAMPTZ DEFAULT NOW()
);

-- >> INDEXES
BEGIN;

-- log.siemens_mri
CREATE INDEX idx_siemens_mri_id_datetime_desc ON log.siemens_mri(system_id, host_datetime desc);

-- log.siemens_ct;
CREATE INDEX idx_siemens_ct_id_datetime_desc ON log.siemens_ct(system_id, host_datetime desc);

-- log.siemens_cv;
CREATE INDEX idx_siemens_cv_id_datetime_desc ON log.siemens_cv(system_id, host_datetime desc);

-- log.ge_mri_gesys;
CREATE INDEX idx_ge_mri_gesys_id_datetime_desc ON log.ge_mri_gesys(system_id, host_datetime desc);

-- log.ge_ct_gesys;
CREATE INDEX idx_ge_ct_gesys_id_datetime_desc ON log.ge_ct_gesys(system_id, host_datetime desc);

-- log.ge_cv_syserror;
CREATE INDEX idx_ge_cv_syserror_id_datetime_desc ON log.ge_cv_syserror(system_id, host_datetime desc);

-- log.philips_ct_eal;
CREATE INDEX idx_philips_ct_eal_id_datetime_desc ON log.philips_ct_eal(system_id, host_datetime desc);

-- log.philips_ct_events;
CREATE INDEX idx_philips_ct_events_id_datetime_desc ON log.philips_ct_events(system_id, host_datetime desc);

-- mag.philips_mri_rmmu_magnet;
CREATE INDEX idx_philips_mri_rmmu_magnet_id_datetime_desc ON mag.philips_mri_rmmu_magnet(system_id, host_datetime desc);

-- log.philips_mri_logcurrent;
CREATE INDEX idx_philips_mri_logcurrent_id_datetime_desc ON log.philips_mri_logcurrent(system_id, host_datetime desc);

-- mag.philips_mri_rmmu_short;
CREATE INDEX idx_philips_mri_rmmu_short_id_datetime ON mag.philips_mri_rmmu_short(system_id, host_datetime);

CREATE INDEX idx_philips_mri_rmmu_short_system_id ON mag.philips_mri_rmmu_short(system_id);

CREATE INDEX idx_philips_mri_rmmu_short_datetime ON mag.philips_mri_rmmu_short(host_datetime);

-- mag.philips_mri_rmmu_long;
CREATE INDEX idx_philips_mri_rmmu_long_id_datetime ON mag.philips_mri_rmmu_long(system_id, host_datetime);

CREATE INDEX idx_philips_mri_rmmu_long_system_id ON mag.philips_mri_rmmu_long(system_id);

CREATE INDEX idx_philips_mri_rmmu_long_datetime ON mag.philips_mri_rmmu_long(host_datetime);

-- log.philips_cv_eventlog;
CREATE INDEX idx_philips_cv_eventlog_id_datetime ON log.philips_cv_eventlog(system_id, host_datetime);

CREATE INDEX idx_philips_cv_eventlog_system_id ON log.philips_cv_eventlog(system_id);

CREATE INDEX idx_philips_cv_eventlog_datetime ON log.philips_cv_eventlog(host_datetime);

-- mag.philips_mri_monitor;
CREATE INDEX idx_philips_mri_json_system_id ON mag.philips_mri_json(system_id, capture_time);

-- mag.philips_mri_monitoring_data;
CREATE INDEX idx_philips_mri_monitoring_data_id_datetime ON mag.philips_mri_monitoring_data(system_id, host_datetime);

CREATE INDEX idx_philips_mri_monitoring_data_system_id ON mag.philips_mri_monitoring_data(system_id);

CREATE INDEX idx_philips_mri_monitoring_data_datetime ON mag.philips_mri_monitoring_data(host_datetime);

ROLLBACK;