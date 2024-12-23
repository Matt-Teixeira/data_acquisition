UPDATE systems -- NEW
SET hhm_config = '{"file_path": "/home/staging/hhm_data_acquisition/files/SME10229", "modality": "MRI", "run_group": 1, "data_acqu": "host", "data_acquisition": {"script": "phil_mri_data_grab_4.sh", "hhm_credentials_group": "15"}}',
hhm_file_config = '[
{"logcurrent": {"query": "logcurrent", "file_name": "logcurrent.log", "pg_table": "philips_mri_logcurrent", "parsers": ["mri_logcurrent"]}},
{"stt_magnet": {"query": "stt_magnet", "file_name": "STT_MAGNET.txt", "pg_table": "stt_magnet", "parsers": ["stt_magnet"]}},
{"monitoring": [
    {"file_name": "monitor_System_HumTechRoom.dat", "parsers": ["monitor_System_HumTechRoom"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "tech_room_humidity_value"},
    {"file_name": "monitor_System_TempTechRoom.dat", "parsers": ["monitor_System_TempTechRoom"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "tech_room_temp_value"},
    {"file_name": "monitor_cryocompressor_cerr.dat", "parsers": ["monitor_cryocompressor_cerr"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "cryo_comp_comm_error_state"},
    {"file_name": "monitor_cryocompressor_palm.dat", "parsers": ["monitor_cryocompressor_palm"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "cryo_comp_press_alarm_state"},
    {"file_name": "monitor_cryocompressor_talm.dat", "parsers": ["monitor_cryocompressor_talm"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "cryo_comp_temp_alarm_state"},
    {"file_name": "monitor_cryocompressor_time_status.dat", "parsers": ["monitor_cryocompressor_time_status"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "cryo_comp_malf_value"},
    {"file_name": "monitor_magnet_helium_level_value.dat", "parsers": ["monitor_magnet_helium_level_value"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "min", "column": "helium_level_value"},
    {"file_name": "monitor_magnet_lt_boiloff.dat", "parsers": ["monitor_magnet_lt_boiloff"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "long_term_boil_off_value"},
    {"file_name": "monitor_magnet_pressure_dps.dat", "parsers": ["monitor_magnet_pressure_dps"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "mag_dps_status_value"},
    {"file_name": "monitor_magnet_quench.dat", "parsers": ["monitor_magnet_quench"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "quenched_state"}
    ]}
]'
WHERE id = 'SME10229';

UPDATE systems -- NEW
SET hhm_config = '{"file_path": "/home/staging/hhm_data_acquisition/files/SME10232", "modality": "MRI", "run_group": 1, "data_acqu": "host", "data_acquisition": {"script": "phil_mri_data_grab_4.sh", "hhm_credentials_group": "15"}}',
hhm_file_config = '[
{"logcurrent": {"query": "logcurrent", "file_name": "logcurrent.log", "pg_table": "philips_mri_logcurrent", "parsers": ["mri_logcurrent"]}},
{"stt_magnet": {"query": "stt_magnet", "file_name": "STT_MAGNET.txt", "pg_table": "stt_magnet", "parsers": ["stt_magnet"]}},
{"monitoring": [
    {"file_name": "monitor_System_HumTechRoom.dat", "parsers": ["monitor_System_HumTechRoom"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "tech_room_humidity_value"},
    {"file_name": "monitor_System_TempTechRoom.dat", "parsers": ["monitor_System_TempTechRoom"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "tech_room_temp_value"},
    {"file_name": "monitor_cryocompressor_cerr.dat", "parsers": ["monitor_cryocompressor_cerr"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "cryo_comp_comm_error_state"},
    {"file_name": "monitor_cryocompressor_palm.dat", "parsers": ["monitor_cryocompressor_palm"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "cryo_comp_press_alarm_state"},
    {"file_name": "monitor_cryocompressor_talm.dat", "parsers": ["monitor_cryocompressor_talm"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "cryo_comp_temp_alarm_state"},
    {"file_name": "monitor_cryocompressor_time_status.dat", "parsers": ["monitor_cryocompressor_time_status"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "cryo_comp_malf_value"},
    {"file_name": "monitor_magnet_helium_level_value.dat", "parsers": ["monitor_magnet_helium_level_value"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "min", "column": "helium_level_value"},
    {"file_name": "monitor_magnet_lt_boiloff.dat", "parsers": ["monitor_magnet_lt_boiloff"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "long_term_boil_off_value"},
    {"file_name": "monitor_magnet_pressure_dps.dat", "parsers": ["monitor_magnet_pressure_dps"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "mag_dps_status_value"},
    {"file_name": "monitor_magnet_quench.dat", "parsers": ["monitor_magnet_quench"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "quenched_state"}
    ]}
]'
WHERE id = 'SME10232';

UPDATE systems -- NEW
SET hhm_config = '{"file_path": "/home/staging/hhm_data_acquisition/files/SME10239", "modality": "MRI", "run_group": 1, "data_acqu": "host", "data_acquisition": {"script": "phil_mri_data_grab_4.sh", "hhm_credentials_group": "15"}}',
hhm_file_config = '[
{"logcurrent": {"query": "logcurrent", "file_name": "logcurrent.log", "pg_table": "philips_mri_logcurrent", "parsers": ["mri_logcurrent"]}},
{"stt_magnet": {"query": "stt_magnet", "file_name": "STT_MAGNET.txt", "pg_table": "stt_magnet", "parsers": ["stt_magnet"]}},
{"monitoring": [
    {"file_name": "monitor_System_HumTechRoom.dat", "parsers": ["monitor_System_HumTechRoom"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "tech_room_humidity_value"},
    {"file_name": "monitor_System_TempTechRoom.dat", "parsers": ["monitor_System_TempTechRoom"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "tech_room_temp_value"},
    {"file_name": "monitor_cryocompressor_cerr.dat", "parsers": ["monitor_cryocompressor_cerr"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "cryo_comp_comm_error_state"},
    {"file_name": "monitor_cryocompressor_palm.dat", "parsers": ["monitor_cryocompressor_palm"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "cryo_comp_press_alarm_state"},
    {"file_name": "monitor_cryocompressor_talm.dat", "parsers": ["monitor_cryocompressor_talm"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "cryo_comp_temp_alarm_state"},
    {"file_name": "monitor_cryocompressor_time_status.dat", "parsers": ["monitor_cryocompressor_time_status"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "cryo_comp_malf_value"},
    {"file_name": "monitor_magnet_helium_level_value.dat", "parsers": ["monitor_magnet_helium_level_value"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "min", "column": "helium_level_value"},
    {"file_name": "monitor_magnet_lt_boiloff.dat", "parsers": ["monitor_magnet_lt_boiloff"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "long_term_boil_off_value"},
    {"file_name": "monitor_magnet_pressure_dps.dat", "parsers": ["monitor_magnet_pressure_dps"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "mag_dps_status_value"},
    {"file_name": "monitor_magnet_quench.dat", "parsers": ["monitor_magnet_quench"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "quenched_state"}
    ]}
]'
WHERE id = 'SME10239';


UPDATE systems -- NEW
SET hhm_config = '{"file_path": "/home/prod/hhm_data_acquisition/files/SME19342", "modality": "MRI", "run_group": 1, "data_acqu": "host", "data_acquisition": {"script": "phil_mri_data_grab_4.sh", "hhm_credentials_group": "15"}}',
hhm_file_config = '[
{"logcurrent": {"query": "logcurrent", "file_name": "logcurrent.log", "pg_table": "philips_mri_logcurrent", "parsers": ["mri_logcurrent"]}},
{"stt_magnet": {"query": "stt_magnet", "file_name": "STT_MAGNET.txt", "pg_table": "stt_magnet", "parsers": ["stt_magnet"]}},
{"monitoring": [
    {"file_name": "monitor_System_HumTechRoom.dat", "parsers": ["monitor_System_HumTechRoom"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "tech_room_humidity_value"},
    {"file_name": "monitor_System_TempTechRoom.dat", "parsers": ["monitor_System_TempTechRoom"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "tech_room_temp_value"},
    {"file_name": "monitor_cryocompressor_cerr.dat", "parsers": ["monitor_cryocompressor_cerr"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "cryo_comp_comm_error_state"},
    {"file_name": "monitor_cryocompressor_palm.dat", "parsers": ["monitor_cryocompressor_palm"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "cryo_comp_press_alarm_state"},
    {"file_name": "monitor_cryocompressor_talm.dat", "parsers": ["monitor_cryocompressor_talm"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "cryo_comp_temp_alarm_state"},
    {"file_name": "monitor_cryocompressor_time_status.dat", "parsers": ["monitor_cryocompressor_time_status"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "cryo_comp_malf_value"},
    {"file_name": "monitor_magnet_helium_level_value.dat", "parsers": ["monitor_magnet_helium_level_value"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "min", "column": "helium_level_value"},
    {"file_name": "monitor_magnet_lt_boiloff.dat", "parsers": ["monitor_magnet_lt_boiloff"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "long_term_boil_off_value"},
    {"file_name": "monitor_magnet_pressure_dps.dat", "parsers": ["monitor_magnet_pressure_dps"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "mag_dps_status_value"},
    {"file_name": "monitor_magnet_quench.dat", "parsers": ["monitor_magnet_quench"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "quenched_state"}
    ]}
]'
WHERE id = 'SME19342';

UPDATE systems -- NEW
SET hhm_config = '{"file_path": "/home/prod/hhm_data_acquisition/files/SME19341", "modality": "MRI", "run_group": 1, "data_acqu": "host", "data_acquisition": {"script": "phil_mri_data_grab_4.sh", "hhm_credentials_group": "15"}}',
hhm_file_config = '[
{"logcurrent": {"query": "logcurrent", "file_name": "logcurrent.log", "pg_table": "philips_mri_logcurrent", "parsers": ["mri_logcurrent"]}},
{"stt_magnet": {"query": "stt_magnet", "file_name": "STT_MAGNET.txt", "pg_table": "stt_magnet", "parsers": ["stt_magnet"]}},
{"rmmu": {"query": "rmmu", "dir_name": "rmmu", "pg_table": "philips_mri_rmmu_history", "parsers": ["rmmu", "rmmu_meta_data_history", "rmmu_file_date"]}},
{"rmmu_magnet": {"query": "rmmu_magnet", "dir_name": "rmmu_magnet", "pg_table": "philips_mri_rmmu_magnet", "parsers": ["rmmu_magnet_re", "rmmu_meta_data"]}},
{"rmmu_short": {"query": "rmmu_short", "dir_name": "rmmu_short", "pg_table": "philips_mri_rmmu_short", "parsers": ["rmmu_short_re", "rmmu_meta_data"]}},
{"monitoring": [
    {"file_name": "monitor_System_HumTechRoom.dat", "parsers": ["monitor_System_HumTechRoom"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "tech_room_humidity_value"},
    {"file_name": "monitor_System_TempTechRoom.dat", "parsers": ["monitor_System_TempTechRoom"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "tech_room_temp_value"},
    {"file_name": "monitor_cryocompressor_cerr.dat", "parsers": ["monitor_cryocompressor_cerr"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "cryo_comp_comm_error_state"},
    {"file_name": "monitor_cryocompressor_palm.dat", "parsers": ["monitor_cryocompressor_palm"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "cryo_comp_press_alarm_state"},
    {"file_name": "monitor_cryocompressor_talm.dat", "parsers": ["monitor_cryocompressor_talm"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "cryo_comp_temp_alarm_state"},
    {"file_name": "monitor_cryocompressor_time_status.dat", "parsers": ["monitor_cryocompressor_time_status"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "cryo_comp_malf_value"},
    {"file_name": "monitor_magnet_helium_level_value.dat", "parsers": ["monitor_magnet_helium_level_value"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "min", "column": "helium_level_value"},
    {"file_name": "monitor_magnet_lt_boiloff.dat", "parsers": ["monitor_magnet_lt_boiloff"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "long_term_boil_off_value"},
    {"file_name": "monitor_magnet_pressure_dps.dat", "parsers": ["monitor_magnet_pressure_dps"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "max", "column": "mag_dps_status_value"},
    {"file_name": "monitor_magnet_quench.dat", "parsers": ["monitor_magnet_quench"], "pg_tables": ["philips_mri_json", "philips_mri_monitoring_data"], "aggregation": "bool", "column": "quenched_state"}
    ]}
]'
WHERE id = 'SME19341';