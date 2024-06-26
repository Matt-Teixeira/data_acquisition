-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01138',
	'10.150.124.247',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01138',
	'15',
	'phil_mri_data_grab_3.sh',
	1,
	NULL,
	NULL,
	'host'
);

INSERT INTO
	config.mag (
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
		'SME01138',
		'STT_MAGNET.txt',
		'stt_magnet',
		ARRAY ['stt_magnet'],
		-- regex
		ARRAY ['stt_magnet'],
		-- tables
		NULL,
		NULL
	);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01138',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01138',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01138',
	'rmmu_long',
	'rmmu_long',
	ARRAY['rmmu_long_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_long'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01138',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01138',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01138',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01138',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01138',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01138',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01138',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01138',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01138',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01138',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01138',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01138',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01139',
	'10.150.160.18',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01139',
	'15',
	'phil_mri_data_grab_6.sh',
	2,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01139',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01139',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01139',
	'rmmu_long',
	'rmmu_long',
	ARRAY['rmmu_long_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_long'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01139',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01139',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01139',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01139',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01139',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01139',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01139',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01139',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01139',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01139',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME15805',
	NULL,
	'172.31.3.51',
	'rsync',
	'/home/prod/hhm_data_acquisition/files/SME15805',
	NULL,
	NULL,
	3,
	'SME15805',
	'avante',
	'mmb'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15805',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15805',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15805',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15805',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15805',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15805',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15805',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15805',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15805',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15805',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point, alt_data_source)
VALUES (
	'SME15809',
	NULL,
	'172.31.3.50',
	'rsync',
	'/home/prod/hhm_data_acquisition/files/SME15809',
	NULL,
	NULL,
	4,
	'SME15809',
	'avante',
	'mmb',
	'[{"type": "he_level", "pg_table": "stt_magnet"}]'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15809',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15809',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15809',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15809',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15809',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15809',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15809',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME15811',
	NULL,
	'172.31.3.49',
	'rsync',
	'/home/prod/hhm_data_acquisition/files/SME15811',
	NULL,
	NULL,
	5,
	'SME15811',
	'avante',
	'mmb'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15811',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15811',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15811',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15811',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15811',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15811',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15811',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15811',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15811',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15811',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15811',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15811',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME15816',
	NULL,
	'172.31.0.25',
	'rsync',
	'/home/prod/hhm_data_acquisition/files/SME15816',
	NULL,
	NULL,
	1,
	'SME15816',
	'avante',
	'mmb'
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15816',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15816',
	'HELIUM_LEVEL.DAT',
	'monitoring',
	ARRAY['HELIUM_LEVEL'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME15802',
	NULL,
	'172.31.3.52',
	'rsync',
	'/home/prod/hhm_data_acquisition/files/SME15802',
	NULL,
	NULL,
	2,
	'SME15802',
	'avante',
	'mmb'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15802',
	'rmmu',
	'rmmu',
	ARRAY['rmmu', 'rmmu_meta_data_history', 'rmmu_file_date'], -- regex
	ARRAY['philips_mri_rmmu_history'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15802',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15802',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15802',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15802',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15802',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15802',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15802',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15802',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15802',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15802',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15802',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15802',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15802',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME15822',
	NULL,
	'172.31.3.55',
	'rsync',
	'/home/prod/hhm_data_acquisition/files/SME15822',
	NULL,
	NULL,
	3,
	'SME15822',
	'avante',
	'mmb'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15822',
	'rmmu',
	'rmmu',
	ARRAY['rmmu', 'rmmu_meta_data_history', 'rmmu_file_date'], -- regex
	ARRAY['philips_mri_rmmu_history'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15822',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15822',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15822',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15822',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15822',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15822',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15822',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15822',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15822',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15822',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15822',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15822',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15822',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME15823',
	NULL,
	'172.31.0.21',
	'rsync',
	'/home/prod/hhm_data_acquisition/files/SME15823',
	NULL,
	NULL,
	4,
	'SME15823',
	'avante',
	'mmb'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15823',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15823',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15823',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15823',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15823',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15823',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15823',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15823',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15823',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15823',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15823',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15823',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15823',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15823',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15823',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15823',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME08284',
	'10.193.26.201',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME08284',
	'15',
	'phil_mri_data_grab_1.sh',
	5,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08284',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08284',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08284',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08284',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08284',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08284',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08284',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08284',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08284',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08284',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08284',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08284',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08284',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME08285',
	'10.20.32.35',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME08285',
	'15',
	'phil_mri_data_grab_2.sh',
	1,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08285',
	'rmmu',
	'rmmu',
	ARRAY['rmmu', 'rmmu_meta_data_history', 'rmmu_file_date'], -- regex
	ARRAY['philips_mri_rmmu_history'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08285',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08285',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08285',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08285',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08285',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08285',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08285',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08285',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08285',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08285',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08285',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08285',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08285',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME10234',
	'10.141.164.214',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME10234',
	'15',
	'phil_mri_data_grab_6.sh',
	2,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10234',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10234',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10234',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10234',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10234',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10234',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10234',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10234',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10234',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10234',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10234',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10234',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01142',
	'10.79.13.201',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01142',
	'15',
	'phil_mri_data_grab_5.sh',
	3,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01142',
	'rmmu',
	'rmmu',
	ARRAY['rmmu', 'rmmu_meta_data_history', 'rmmu_file_date'], -- regex
	ARRAY['philips_mri_rmmu_history'], -- tables
	NULL,
	NULL
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01142',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01142',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01142',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01142',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01142',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01142',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01142',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01142',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01142',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01142',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01142',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01142',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01142',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01142',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01142',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01402',
	'172.20.231.229',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01402',
	'15',
	'phil_mri_data_grab_3.sh',
	4,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01402',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01402',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01402',
	'rmmu_long',
	'rmmu_long',
	ARRAY['rmmu_long_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_long'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01402',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01402',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01402',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01402',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01402',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01402',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01402',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01402',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01402',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01402',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01402',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01402',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01402',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01424',
	'172.27.22.64',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01424',
	'15',
	'phil_mri_data_grab_3.sh',
	5,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01424',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01424',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01424',
	'rmmu_long',
	'rmmu_long',
	ARRAY['rmmu_long_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_long'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01424',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01424',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01424',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01424',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01424',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01424',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01424',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01424',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01424',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01424',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01424',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01424',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01424',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01403',
	'172.20.51.247',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01403',
	'15',
	'phil_mri_data_grab_3.sh',
	1,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01403',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01403',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01403',
	'rmmu_long',
	'rmmu_long',
	ARRAY['rmmu_long_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_long'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01403',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01403',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01403',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01403',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01403',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01403',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01403',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01403',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01403',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01403',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01403',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01403',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01403',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01404',
	'172.28.39.243',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01404',
	'15',
	'phil_mri_data_grab_3.sh',
	2,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01404',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01404',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01404',
	'rmmu_long',
	'rmmu_long',
	ARRAY['rmmu_long_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_long'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01404',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01404',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01404',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01404',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01404',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01404',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01404',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01404',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01404',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01404',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01404',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01404',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01404',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01405',
	'172.28.39.244',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01405',
	'15',
	'phil_mri_data_grab_3.sh',
	3,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01405',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01405',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01405',
	'rmmu_long',
	'rmmu_long',
	ARRAY['rmmu_long_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_long'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01405',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01405',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01405',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01405',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01405',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01405',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01405',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01405',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01405',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01405',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01405',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01405',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01405',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01399',
	'172.18.47.206',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01399',
	'15',
	'phil_mri_data_grab_3.sh',
	4,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01399',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01399',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01399',
	'rmmu_long',
	'rmmu_long',
	ARRAY['rmmu_long_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_long'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01399',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01399',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01399',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01399',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01399',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01399',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01399',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01399',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01399',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01399',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01399',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01399',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01399',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01406',
	'10.132.7.211',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01406',
	'15',
	'phil_mri_data_grab_4.sh',
	5,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01406',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01406',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01406',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01406',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01406',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01406',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01406',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01406',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01406',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01406',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01406',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01406',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME15581',
	NULL,
	'172.31.3.62',
	'rsync',
	'/home/prod/hhm_data_acquisition/files/SME15581',
	NULL,
	NULL,
	1,
	'SME15581',
	'avante',
	'mmb'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15581',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15581',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15581',
	'rmmu_long',
	'rmmu_long',
	ARRAY['rmmu_long_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_long'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15581',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15581',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15581',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15581',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15581',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15581',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15581',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15581',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15581',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15581',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15581',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME15581',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME10657',
	'10.135.13.200',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME10657',
	'15',
	'phil_mri_data_grab_3.sh',
	2,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10657',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10657',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10657',
	'rmmu_long',
	'rmmu_long',
	ARRAY['rmmu_long_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_long'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10657',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10657',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10657',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10657',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10657',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10657',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10657',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10657',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10657',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10657',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10657',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10657',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10657',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME16433',
	'172.24.122.18',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME16433',
	'15',
	'phil_mri_data_grab_7.sh',
	3,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'rmmu',
	'rmmu',
	ARRAY['rmmu', 'rmmu_meta_data_history', 'rmmu_file_date'], -- regex
	ARRAY['philips_mri_rmmu_history'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16433',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME16410',
	'172.16.98.27',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME16410',
	'15',
	'phil_mri_data_grab_3.sh',
	4,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16410',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16410',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16410',
	'rmmu_long',
	'rmmu_long',
	ARRAY['rmmu_long_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_long'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16410',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16410',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16410',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16410',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16410',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16410',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16410',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16410',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16410',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16410',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16410',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16410',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16410',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME16411',
	'172.16.105.59',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME16411',
	'15',
	'phil_mri_data_grab_4.sh',
	5,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16411',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16411',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16411',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16411',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16411',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16411',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16411',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16411',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16411',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16411',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16411',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16411',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16411',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point, alt_data_source)
VALUES (
	'SME16414',
	'172.16.205.30',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME16414',
	'15',
	'phil_mri_data_grab_8.sh',
	1,
	NULL,
	NULL,
	'host',
	'[{"type": "he_level", "pg_table": "stt_magnet"}]'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16414',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16414',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16414',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16414',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16414',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16414',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16414',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16414',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16414',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16414',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16414',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16414',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16414',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16414',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16414',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16414',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME16415',
	'172.16.160.48',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME16415',
	'15',
	'phil_mri_data_grab_4.sh',
	2,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16415',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16415',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16415',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16415',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16415',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16415',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16415',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16415',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16415',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16415',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16415',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16415',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME16421',
	'172.24.114.84',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME16421',
	'15',
	'phil_mri_data_grab_6.sh',
	3,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16421',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16421',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16421',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16421',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16421',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16421',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16421',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16421',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16421',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16421',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16421',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16421',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME16422',
	'172.16.38.98',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME16422',
	'15',
	'phil_mri_data_grab_6.sh',
	4,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'rmmu_long',
	'rmmu_long',
	ARRAY['rmmu_long_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_long'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16422',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME10251',
	'10.29.9.70',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME10251',
	'15',
	'phil_mri_data_grab_8.sh',
	5,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'rmmu',
	'rmmu',
	ARRAY['rmmu', 'rmmu_meta_data_history', 'rmmu_file_date'], -- regex
	ARRAY['philips_mri_rmmu_history'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10251',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME16434',
	'172.16.19.67',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME16434',
	'15',
	'phil_mri_data_grab_4.sh',
	1,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16434',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16434',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16434',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16434',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16434',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16434',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16434',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16434',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16434',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16434',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16434',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16434',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);

-->
-->

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME17384',
	'10.146.20.47',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME17384',
	'15',
	'phil_mri_data_grab_3.sh',
	1,
	NULL,
	NULL,
	'host'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'rmmu_long',
	'rmmu_long',
	ARRAY['rmmu_long_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_long'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'monitor_magnet_pressure.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'monitor_magnet_pressure_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17384',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point, alt_data_source)
VALUES (
	'SME10229',
	'10.254.23.20',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME10229',
	'15',
	'phil_mri_data_grab_4.sh',
	5,
	NULL,
	NULL,
	'host',
	'[{"type": "he_level", "pg_table": "stt_magnet"}]'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10229',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10229',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10229',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10229',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10229',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10229',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10229',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10229',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10229',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10229',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10229',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10229',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point, alt_data_source)
VALUES (
	'SME10232',
	'10.10.3.33',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME10232',
	'15',
	'phil_mri_data_grab_4.sh',
	1,
	NULL,
	NULL,
	'host',
	'[{"type": "he_level", "pg_table": "stt_magnet"}]'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10232',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10232',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10232',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10232',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10232',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10232',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10232',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10232',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10232',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10232',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10232',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10232',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point, alt_data_source)
VALUES (
	'SME10239',
	'10.2.3.163',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME10239',
	'15',
	'phil_mri_data_grab_4.sh',
	2,
	NULL,
	NULL,
	'host',
	'[{"type": "he_level", "pg_table": "stt_magnet"}]'
);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10239',
	'STT_MAGNET.txt',
	'stt_magnet',
	ARRAY['stt_magnet'], -- regex
	ARRAY['stt_magnet'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10239',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10239',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10239',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10239',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10239',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10239',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10239',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10239',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10239',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10239',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME10239',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);

-->
-->

UPDATE
	config.acquisition
SET
	system_id = 'SME16432',
	host_ip = '172.16.38.111',
	debian_server_path = '/home/prod/hhm_data_acquisition/files/SME16432',
	credentials_group = '15',
	acquisition_script = 'phil_mri_data_grab_3.sh',
	run_group = 1,
	acqu_point = 'host'
WHERE 
	system_id = 'SME16432';

INSERT INTO
	config.mag (
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
		'SME16432',
		'STT_MAGNET.txt',
		'stt_magnet',
		ARRAY ['stt_magnet'],
		-- regex
		ARRAY ['stt_magnet'],
		-- tables
		NULL,
		NULL
	);

INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16432',
	'rmmu_magnet',
	'rmmu_magnet',
	ARRAY['rmmu_magnet_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_magnet'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16432',
	'rmmu_short',
	'rmmu_short',
	ARRAY['rmmu_short_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_short'], -- tables
	NULL,
	NULL
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16432',
	'rmmu_long',
	'rmmu_long',
	ARRAY['rmmu_long_re', 'rmmu_meta_data'], -- regex
	ARRAY['philips_mri_rmmu_long'], -- tables
	NULL,
	NULL
);
INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16432',
	'logcurrent.log',
	'logcurrent',
	ARRAY['mri_logcurrent'], -- regex
	ARRAY['philips_mri_logcurrent'], -- tables
	NULL,
	NULL
);
-- > MONITORING
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16432',
	'monitor_System_HumTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_HumTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_humidity_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16432',
	'monitor_System_TempTechRoom.dat',
	'monitoring',
	ARRAY['monitor_System_TempTechRoom'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'tech_room_temp_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16432',
	'monitor_cryocompressor_cerr.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_cerr'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_comm_error_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16432',
	'monitor_cryocompressor_palm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_palm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_press_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16432',
	'monitor_cryocompressor_talm.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_talm'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_temp_alarm_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16432',
	'monitor_cryocompressor_time_status.dat',
	'monitoring',
	ARRAY['monitor_cryocompressor_time_status'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'cryo_comp_malf_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16432',
	'monitor_magnet_helium_level_value.dat',
	'monitoring',
	ARRAY['monitor_magnet_helium_level_value'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'helium_level_value',
	'min'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16432',
	'monitor_magnet_lt_boiloff.dat',
	'monitoring',
	ARRAY['monitor_magnet_lt_boiloff'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'long_term_boil_off_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16432',
	'monitor_magnet_pressure_dps.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_dps'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'mag_dps_status_value',
	'max'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16432',
	'monitor_magnet_quench.dat',
	'monitoring',
	ARRAY['monitor_magnet_quench'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'quenched_state',
	'bool'
);
INSERT INTO config.mag (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16432',
	'monitor_magnet_pressure_avg.dat',
	'monitoring',
	ARRAY['monitor_magnet_pressure_avg'], -- regex
	ARRAY['philips_mri_json', 'philips_mri_monitoring_data'], -- tables
	'he_psi_avg_value',
	'max'
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
		acqu_point
	)
VALUES
	(
		'SME18368',
		NULL,
		'172.31.3.58',
		'rsync',
		'/home/prod/hhm_data_acquisition/files/SME18368',
		NULL,
		NULL,
		2,
		'SME18368',
		'avante',
		'mmb'
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
		'SME18368',
		'logcurrent.log',
		'logcurrent',
		ARRAY ['mri_logcurrent'],
		-- regex
		ARRAY ['philips_mri_logcurrent'],
		-- tables
		NULL,
		NULL
	);

INSERT INTO
	config.mag (
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
		'SME18368',
		'rmmu',
		'rmmu',
		ARRAY ['rmmu', 'rmmu_meta_data_history', 'rmmu_file_date'],
		-- regex
		ARRAY ['philips_mri_rmmu_history'],
		-- tables
		NULL,
		NULL
	);

INSERT INTO
	config.mag (
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
		'SME18368',
		'STT_MAGNET.txt',
		'stt_magnet',
		ARRAY ['stt_magnet'],
		-- regex
		ARRAY ['stt_magnet'],
		-- tables
		NULL,
		NULL
	);

INSERT INTO
	config.mag (
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
		'SME18368',
		'rmmu_magnet',
		'rmmu_magnet',
		ARRAY ['rmmu_magnet_re', 'rmmu_meta_data'],
		-- regex
		ARRAY ['philips_mri_rmmu_magnet'],
		-- tables
		NULL,
		NULL
	);

INSERT INTO
	config.mag (
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
		'SME18368',
		'rmmu_short',
		'rmmu_short',
		ARRAY ['rmmu_short_re', 'rmmu_meta_data'],
		-- regex
		ARRAY ['philips_mri_rmmu_short'],
		-- tables
		NULL,
		NULL
	);

-- > MONITORING
INSERT INTO
	config.mag (
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
		'SME18368',
		'monitor_System_HumTechRoom.dat',
		'monitoring',
		ARRAY ['monitor_System_HumTechRoom'],
		-- regex
		ARRAY ['philips_mri_json', 'philips_mri_monitoring_data'],
		-- tables
		'tech_room_humidity_value',
		'max'
	);

INSERT INTO
	config.mag (
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
		'SME18368',
		'monitor_System_TempTechRoom.dat',
		'monitoring',
		ARRAY ['monitor_System_TempTechRoom'],
		-- regex
		ARRAY ['philips_mri_json', 'philips_mri_monitoring_data'],
		-- tables
		'tech_room_temp_value',
		'max'
	);

INSERT INTO
	config.mag (
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
		'SME18368',
		'monitor_cryocompressor_cerr.dat',
		'monitoring',
		ARRAY ['monitor_cryocompressor_cerr'],
		-- regex
		ARRAY ['philips_mri_json', 'philips_mri_monitoring_data'],
		-- tables
		'cryo_comp_comm_error_state',
		'bool'
	);

INSERT INTO
	config.mag (
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
		'SME18368',
		'monitor_cryocompressor_palm.dat',
		'monitoring',
		ARRAY ['monitor_cryocompressor_palm'],
		-- regex
		ARRAY ['philips_mri_json', 'philips_mri_monitoring_data'],
		-- tables
		'cryo_comp_press_alarm_state',
		'bool'
	);

INSERT INTO
	config.mag (
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
		'SME18368',
		'monitor_cryocompressor_talm.dat',
		'monitoring',
		ARRAY ['monitor_cryocompressor_talm'],
		-- regex
		ARRAY ['philips_mri_json', 'philips_mri_monitoring_data'],
		-- tables
		'cryo_comp_temp_alarm_state',
		'bool'
	);

INSERT INTO
	config.mag (
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
		'SME18368',
		'monitor_cryocompressor_time_status.dat',
		'monitoring',
		ARRAY ['monitor_cryocompressor_time_status'],
		-- regex
		ARRAY ['philips_mri_json', 'philips_mri_monitoring_data'],
		-- tables
		'cryo_comp_malf_value',
		'max'
	);

INSERT INTO
	config.mag (
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
		'SME18368',
		'monitor_magnet_helium_level_value.dat',
		'monitoring',
		ARRAY ['monitor_magnet_helium_level_value'],
		-- regex
		ARRAY ['philips_mri_json', 'philips_mri_monitoring_data'],
		-- tables
		'helium_level_value',
		'min'
	);

INSERT INTO
	config.mag (
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
		'SME18368',
		'monitor_magnet_lt_boiloff.dat',
		'monitoring',
		ARRAY ['monitor_magnet_lt_boiloff'],
		-- regex
		ARRAY ['philips_mri_json', 'philips_mri_monitoring_data'],
		-- tables
		'long_term_boil_off_value',
		'max'
	);

INSERT INTO
	config.mag (
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
		'SME18368',
		'monitor_magnet_pressure_dps.dat',
		'monitoring',
		ARRAY ['monitor_magnet_pressure_dps'],
		-- regex
		ARRAY ['philips_mri_json', 'philips_mri_monitoring_data'],
		-- tables
		'mag_dps_status_value',
		'max'
	);

INSERT INTO
	config.mag (
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
		'SME18368',
		'monitor_magnet_quench.dat',
		'monitoring',
		ARRAY ['monitor_magnet_quench'],
		-- regex
		ARRAY ['philips_mri_json', 'philips_mri_monitoring_data'],
		-- tables
		'quenched_state',
		'bool'
	);

INSERT INTO
	config.mag (
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
		'SME18368',
		'monitor_magnet_pressure_avg.dat',
		'monitoring',
		ARRAY ['monitor_magnet_pressure_avg'],
		-- regex
		ARRAY ['philips_mri_json', 'philips_mri_monitoring_data'],
		-- tables
		'he_psi_avg_value',
		'max'
	);

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
		acqu_point
	)
VALUES
	(
		'SME18338',
		'192.168.31.153',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME18338',
		'15',
		'phil_mri_data_grab_9.sh',
		3,
		NULL,
		NULL,
		'host'
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
		'SME18338',
		'logcurrent.log',
		'logcurrent',
		ARRAY ['mri_logcurrent'],
		-- regex
		ARRAY ['philips_mri_logcurrent'],
		-- tables
		NULL,
		NULL
	);

INSERT INTO
	config.mag (
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
		'SME18338',
		'STT_MAGNET.txt',
		'stt_magnet',
		ARRAY ['stt_magnet'],
		-- regex
		ARRAY ['stt_magnet'],
		-- tables
		NULL,
		NULL
	);