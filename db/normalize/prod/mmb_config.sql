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
		'SME15819',
		NULL,
		'172.31.3.39',
		'rsync',
		'/home/prod/hhm_data_acquisition/files',
		NULL,
		NULL,
		NULL,
		'SME15819',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME15819',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		0,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME15819',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		ARRAY ['mmb_edu2'],
		6
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
		'SME10571',
		NULL,
		'172.31.2.27',
		'rsync',
		'/home/prod/hhm_data_acquisition/files',
		NULL,
		NULL,
		NULL,
		'SME10571',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME10571',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		0,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME10571',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		0
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
		'SME01422',
		NULL,
		'172.31.3.11',
		'rsync',
		'/home/prod/hhm_data_acquisition/files',
		NULL,
		NULL,
		NULL,
		'SME01422',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME01422',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		0,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME01422',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		0
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
		'SME11246',
		NULL,
		'172.31.0.12',
		'rsync',
		'/home/prod/hhm_data_acquisition/files',
		NULL,
		NULL,
		NULL,
		'SME11246',
		'avante',
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME11246',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		7
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
		'SME15812',
		NULL,
		'172.31.3.38',
		'rsync',
		'/home/prod/hhm_data_acquisition/files/SME15812',
		NULL,
		NULL,
		NULL,
		'SME15812',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME15812',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		1,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME15812',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		7
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
		'SME15815',
		NULL,
		'172.31.0.19',
		'rsync',
		'/home/prod/hhm_data_acquisition/files/SME15815',
		NULL,
		NULL,
		NULL,
		'SME15815',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME15815',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		3,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME15815',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		7
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
		'SME15820',
		NULL,
		'172.31.3.47',
		'rsync',
		'/home/prod/hhm_data_acquisition/files/SME15820',
		NULL,
		NULL,
		NULL,
		'SME15820',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME15820',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		1,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME15820',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		7
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
		'SME10255',
		NULL,
		'25.48.16.48',
		'rsync',
		'/home/prod/hhm_data_acquisition/files/SME10255',
		NULL,
		NULL,
		NULL,
		'SME10255',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME10255',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		4,
		NULL
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
		'SME01897',
		NULL,
		'172.31.2.19',
		'rsync',
		'/home/prod/hhm_data_acquisition/files/SME01897',
		NULL,
		NULL,
		NULL,
		'SME01897',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME01897',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_D'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		3,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME01897',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		6
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
		'SME01107',
		NULL,
		'172.31.2.12',
		'rsync',
		'/home/prod/hhm_data_acquisition/files/SME01107',
		NULL,
		NULL,
		NULL,
		'SME01107',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME01107',
		'v2_rdu_9600',
		NULL,
		ARRAY [
        'RE_SIEMENS_OR_CODE',
        'RE_SIEMENS_FIELD_CURRENT',
        'RE_SIEMENS_HOST_TIME_DATE',
        'RE_SIEMENS_SUP_TIME',
        'RE_SIEMENS_MSUP',
        'RE_SIEMENS_MAG_SN',
        'RE_SIEMENS_MAG_REV',
        'RE_SIEMENS_HE_PARAMS',
        'RE_SIEMENS_EIS_STATUS',
        'RE_SIEMENS_SELF_TEST',
        'RE_SIEMENS_BATTERY_STATUS',
        'RE_SIEMENS_SH_STATUS',
        'RE_SIEMENS_BATTERY_VOLTS',
        'RE_SIEMENS_PRESS_HTR',
        'RE_SIEMENS_COMPRESSOR_STATUS',
        'RE_SIEMENS_COLDHEAD',
        'RE_SIEMENS_SHIELD_SENSOR',
        'RE_SIEMENS_TURRET',
        'RE_SIEMENS_CARBON_R_S1_S2',
        'RE_SIEMENS_CARBON_R_S3_S4',
        'RE_SIEMENS_SWT_HTR',
        'RE_SIEMENS_QUH_HTR',
        'RE_SIEMENS_MAG_PSI_A',
        'RE_SIEMENS_AVG_PWR',
        'RE_SIEMENS_ERDU_STATUS',
        'RE_SIEMENS_ERDU_BUTTONS',
        'RE_SIEMENS_TESTS',
        'RE_SIEMENS_HE_VALUES_UNIFIED'
      ],
		-- regex
		ARRAY ['mmb_siemens'],
		-- tables
		NULL,
		5,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME01107',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		6
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
		'SME01890',
		NULL,
		'10.50.70.11',
		'rsync',
		'/home/prod/hhm_data_acquisition/files/SME01890',
		NULL,
		NULL,
		NULL,
		'SME01890',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME01890',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		3,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME01890',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		7
	);

-->
-->
UPDATE
	config.acquisition
SET
	mmb_ip = '172.31.3.11',
	protocal = 'rsync',
	host = 'SME01123',
	user_id = 'avante'
WHERE
	system_id = 'SME01123'
INSERT INTO
	config.mag (
		system_id,
		file_name,
		dir_name,
		regex_models,
		pg_tables,
		column_name,
		schedule,
		agg
	)
VALUES
	(
		'SME01123',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		4,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME01123',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		7
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
		'SME13572',
		NULL,
		'25.76.110.154',
		'rsync',
		'/home/prod/hhm_data_acquisition/files/SME13572',
		NULL,
		NULL,
		NULL,
		'SME13572',
		'jdis',
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
		schedule,
		agg
	)
VALUES
	(
		'SME13572',
		'v2_rdu_9600',
		NULL,
		ARRAY [
        'RE_SIEMENS_OR_CODE',
        'RE_SIEMENS_FIELD_CURRENT',
        'RE_SIEMENS_HOST_TIME_DATE',
        'RE_SIEMENS_SUP_TIME',
        'RE_SIEMENS_LVQD',
        'RE_SIEMENS_MSUP',
        'RE_SIEMENS_MAG_SN',
        'RE_SIEMENS_MAG_REV',
        'RE_SIEMENS_HE_VALUES_UNIFIED',
        'RE_SIEMENS_EIS_STATUS',
        'RE_SIEMENS_SELF_TEST',
        'RE_SIEMENS_BATTERY_STATUS',
        'RE_SIEMENS_SH_STATUS',
        'RE_SIEMENS_BATTERY_VOLTS',
        'RE_SIEMENS_PRESS_HTR',
        'RE_SIEMENS_COMPRESSOR_STATUS',
        'RE_SIEMENS_COLDHEAD',
        'RE_SIEMENS_SHIELD_SENSOR',
        'RE_SIEMENS_TURRET',
        'RE_SIEMENS_CCR_S1_S2',
        'RE_SIEMENS_CCR_S3_S4',
        'RE_SIEMENS_SWT_HTR',
        'RE_SIEMENS_QUH_HTR',
        'RE_SIEMENS_MAG_PSI_A',
        'RE_SIEMENS_AVG_PWR',
        'RE_SIEMENS_ERDU_STATUS',
        'RE_SIEMENS_ERDU_BUTTONS',
        'RE_SIEMENS_TESTS'
      ],
		-- regex
		ARRAY ['mmb_siemens'],
		-- tables
		NULL,
		1,
		NULL
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
		'SME12029',
		NULL,
		'172.31.2.41',
		'rsync',
		'/home/prod/hhm_data_acquisition/files/SME12029',
		NULL,
		NULL,
		NULL,
		'SME12029',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME12029',
		'v2_rdu_9600',
		NULL,
		ARRAY [
        'RE_SIEMENS_OR_CODE',
        'RE_SIEMENS_FIELD_CURRENT',
        'RE_SIEMENS_HOST_TIME_DATE',
        'RE_SIEMENS_TEST_TIME',
        'RE_SIEMENS_LVQD',
        'RE_SIEMENS_MAG_SN',
        'RE_SIEMENS_HE_PARAMS',
        'RE_SIEMENS_HE_VALUES_UNIFIED',
        'RE_SIEMENS_FIELD',
        'RE_SIEMENS_SELF_TEST',
        'RE_SIEMENS_BATTERY_STATUS',
        'RE_SIEMENS_SH_STATUS',
        'RE_SIEMENS_BATTERY_VOLTS',
        'RE_SIEMENS_PRESS_HTR',
        'RE_SIEMENS_COMPRESSOR_STATUS',
        'RE_SIEMENS_PRESS_SW_STATUS',
        'RE_SIEMENS_COLDHEAD',
        'RE_SIEMENS_SHIELD_LINK_BORE',
        'RE_SIEMENS_TURRET',
        'RE_SIEMENS_CCR_S1_S2',
        'RE_SIEMENS_CCR_S3_S4',
        'RE_SIEMENS_SWT_HTR',
        'RE_SIEMENS_QUH_HTR',
        'RE_SIEMENS_MAG_PSI_A',
        'RE_SIEMENS_AVG_PWR',
        'RE_SIEMENS_EPM',
        'RE_SIEMENS_ERDU_STATUS',
        'RE_SIEMENS_ERDU_STATUS_ARRAY',
        'RE_SIEMENS_TESTS',
        'RE_SIEMENS_I_BTN'
      ],
		-- regex
		ARRAY ['mmb_siemens'],
		-- tables
		NULL,
		5,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME12029',
		'v2_edu2',
		ARRAY ['RE_EDU2_ROOM_PROBE_HUM_TEMP'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		6
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
		'SME16617',
		NULL,
		'10.251.197.46',
		'rsync',
		'/home/prod/hhm_data_acquisition/files/SME16617',
		NULL,
		NULL,
		NULL,
		'SME16617',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME16617',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		1,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME16617',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		ARRAY ['mmb_edu2'],
		7
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
		'SME16339',
		NULL,
		'10.75.9.42',
		'rsync',
		'/home/prod/hhm_data_acquisition/files/SME16339',
		NULL,
		NULL,
		NULL,
		'SME16339',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME16339',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		5,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME16339',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		7
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
		'SME16340',
		NULL,
		'10.75.9.196',
		'rsync',
		'/home/prod/hhm_data_acquisition/files/SME16340',
		NULL,
		NULL,
		NULL,
		'SME16340',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME16340',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		4,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME16340',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		6
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
		'SME16341',
		NULL,
		'10.35.158.191',
		'rsync',
		'/home/prod/hhm_data_acquisition/files/SME16341',
		NULL,
		NULL,
		NULL,
		'SME16341',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME16341',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		3,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME16341',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		7
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
		'SME16342',
		NULL,
		'10.35.12.108',
		'rsync',
		'/home/prod/hhm_data_acquisition/files/SME16342',
		NULL,
		NULL,
		NULL,
		'SME16342',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME16342',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		2,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME16342',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		7
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
		'SME16268',
		NULL,
		'172.31.2.56',
		'rsync',
		'/home/prod/hhm_data_acquisition/files',
		NULL,
		NULL,
		NULL,
		'SME16268',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME16268',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		5,
		NULL
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
		'SME16270',
		NULL,
		'172.31.2.62',
		'rsync',
		'/home/prod/hhm_data_acquisition/files',
		NULL,
		NULL,
		NULL,
		'SME16270',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME16270',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		5,
		NULL
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
		'SME16266',
		NULL,
		'172.31.2.21',
		'rsync',
		'/home/prod/hhm_data_acquisition/files',
		NULL,
		NULL,
		NULL,
		'SME16266',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME16266',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_B'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		5,
		NULL
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
		'SME16267',
		NULL,
		'172.31.2.49',
		'rsync',
		'/home/prod/hhm_data_acquisition/files',
		NULL,
		NULL,
		NULL,
		'SME16267',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME16267',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		5,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME16267',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		7
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
		'SME16272',
		NULL,
		'172.31.0.20',
		'rsync',
		'/home/prod/hhm_data_acquisition/files',
		NULL,
		NULL,
		NULL,
		'SME16272',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME16272',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_B'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		5,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME16272',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		7
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
		'SME16266',
		NULL,
		'172.31.2.21',
		'rsync',
		'/home/prod/hhm_data_acquisition/files',
		NULL,
		NULL,
		NULL,
		'SME16266',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME16266',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_A'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		5,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME16266',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		7
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
		acqu_point
	)
VALUES
	(
		'SME16932',
		'10.46.211.160',
		NULL,
		'ssh',
		'/home/prod/hhm_data_acquisition/files/SME16932',
		'7',
		'ge_cv_22.sh',
		1,
		NULL,
		NULL,
		NULL
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
		'SME16932',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
		NULL,
		NULL
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
		'SME10815',
		NULL,
		'170.232.106.98',
		'rsync',
		'/home/prod/hhm_data_acquisition/files',
		NULL,
		NULL,
		NULL,
		'SME10815',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME10815',
		'v2_rdu_9600',
		NULL,
		ARRAY [
        'RE_SIEMENS_MSUP_META',
        'RE_SIEMENS_OR_CODE',
        'RE_SIEMENS_FIELD_CURRENT',
        'RE_SIEMENS_HOST_TIME_DATE',
        'RE_SIEMENS_TEST_TIME',
        'RE_SIEMENS_LVQD',
        'RE_SIEMENS_HE_PARAMS',
        'RE_SIEMENS_HE_VALUES_UNIFIED',
        'RE_SIEMENS_HE_STATUS',
        'RE_SIEMENS_EIS_STATUS',
        'RE_SIEMENS_FIELD',
        'RE_SIEMENS_SELF_TEST',
        'RE_SIEMENS_BATTERY_STATUS',
        'RE_SIEMENS_SH_STATUS',
        'RE_SIEMENS_BATTERY_VOLTS',
        'RE_SIEMENS_PRESS_HTR',
        'RE_SIEMENS_COMPRESSOR_STATUS',
        'RE_SIEMENS_COMPRESSOR_VALUE',
        'RE_SIEMENS_PRESS_SW_STATUS',
        'RE_SIEMENS_COLDHEAD',
        'RE_SIEMENS_SHIELD_LINK_BORE',
        'RE_SIEMENS_TURRET',
        'RE_SIEMENS_CCR_S1_S2',
        'RE_SIEMENS_CCR_S3_S4',
        'RE_SIEMENS_SWT_HTR',
        'RE_SIEMENS_QUH_HTR',
        'RE_SIEMENS_MAG_PSI_A',
        'RE_SIEMENS_AVG_PWR',
        'RE_SIEMENS_ERDU_STATUS',
        'RE_SIEMENS_ERDU_STATUS_ARRAY',
        'RE_SIEMENS_TESTS',
        'RE_SIEMENS_I_BTN'
      ],
		-- regex
		ARRAY ['mmb_siemens'],
		-- tables
		NULL,
		1,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME10815',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		-- regex
		ARRAY ['mmb_edu2'],
		-- tables
		6
	);

-->
-->
UPDATE
	config.acquisition
SET
	mmb_ip = '10.254.15.228',
	host = 'SME10229',
	user_id = 'avante'
WHERE
	system_id = 'SME10229';

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME10229',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		ARRAY ['mmb_edu2'],
		6
	);

-->
-->
UPDATE
	config.edu
SET
	file_name = 'v2_edu2',
	regex_models = ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
	pg_tables = ARRAY ['mmb_edu2'],
WHERE
	system_id = 'SME10230';

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
		'SME10815',
		NULL,
		'170.232.106.98',
		'rsync',
		'/home/staging/hhm_data_acquisition/files',
		NULL,
		NULL,
		NULL,
		'SME10815',
		'avante',
		NULL
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
		'SME10231',
		NULL,
		'172.31.0.14',
		'rsync',
		'/home/prod/hhm_data_acquisition/files',
		NULL,
		NULL,
		NULL,
		'SME10231',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME10231',
		'v2_rdu_9600',
		NULL,
		ARRAY [
        	'RE_SIEMENS_MSUP_META',
            'RE_SIEMENS_HOST_TIME_DATE',
            'RE_SIEMENS_SUP_TIME',
            'RE_SIEMENS_LVQD',
            'RE_SIEMENS_MAG_REV',
            'RE_SIEMENS_HE_PARAMS',
            'RE_SIEMENS_HE_STATUS',
            'RE_SIEMENS_MAG_SN',
            'RE_SIEMENS_SELF_TEST',
            'RE_SIEMENS_SH_STATUS',
            'RE_SIEMENS_BATTERY_VOLTS',
            'RE_SIEMENS_COMPRESSOR_STATUS',
            'RE_SIEMENS_TURRET',
            'RE_SIEMENS_SWT_HTR',
            'RE_SIEMENS_MAG_PSI_A',
            'RE_SIEMENS_AVG_PWR',
            'RE_SIEMENS_ERDU_BUTTONS',
            'RE_SIEMENS_TESTS',
            'RE_SIEMENS_PRESS_HTR',
            'RE_SIEMENS_COLDHEAD',
            'RE_SIEMENS_SHIELD_SENSOR',
            'RE_SIEMENS_CARBON_R_S1_S2',
            'RE_SIEMENS_QUH_HTR',
            'RE_SIEMENS_OR_CODE',
            'RE_SIEMENS_FIELD_CURRENT',
            'RE_SIEMENS_MSUP',
            'RE_SIEMENS_BATTERY_STATUS',
            'RE_SIEMENS_CARBON_R_S3_S4',
            'RE_SIEMENS_HE_VALUES_UNIFIED'
      ],
		-- regex
		ARRAY ['mmb_siemens'],
		-- tables
		NULL,
		1,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME10231',
		'v2_edu',
		ARRAY ['RE_EDU_ROOM_PROBE',
            'RE_EDU_TEMP_PROBE'],
		-- regex
		ARRAY ['edu.v1'],
		-- tables
		6
	);


-->
-->
UPDATE
	config.acquisition
SET
	mmb_ip = '10.254.7.228',
	host = 'SME10232',
	user_id = 'avante'
WHERE
	system_id = 'SME10232';

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME10232',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		ARRAY ['mmb_edu2'],
		7
	);

-->
-->
UPDATE
	config.acquisition
SET
	mmb_ip = '10.2.103.228',
	host = 'SME10239',
	user_id = 'avante'
WHERE
	system_id = 'SME10239';

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME10239',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		ARRAY ['mmb_edu2'],
		6
	);


-->
-->
UPDATE
	config.edu
SET
	file_name = 'v2_edu2',
	regex_models = ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
	pg_tables = ARRAY ['mmb_edu2'],
WHERE
	system_id = 'SME10242';

-->
-->
UPDATE
	config.edu
SET
	file_name = 'v2_edu2',
	regex_models = ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
	pg_tables = ARRAY ['mmb_edu2'],
WHERE
	system_id = 'SME10243';

-->
-->
INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME10252',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		ARRAY ['mmb_edu2'],
		7
	);


-->
-->
UPDATE
	config.edu
SET
	file_name = 'v2_edu2',
	regex_models = ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
	pg_tables = ARRAY ['mmb_edu2']
WHERE
	system_id = 'SME10253';


-->
-->
INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME10254',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		ARRAY ['mmb_edu2'],
		7
	);

-->
-->
UPDATE
	config.edu
SET
	file_name = 'v2_edu2',
	regex_models = ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
	pg_tables = ARRAY ['mmb_edu2']
WHERE
	system_id = 'SME12489';


-->
-->
INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME16268',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		ARRAY ['mmb_edu2'],
		7
	);


-->
-->
INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME16270',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		ARRAY ['mmb_edu2'],
		7
	);


-->
-->
INSERT INTO
	config.mag (
		system_id,
		file_name,
		dir_name,
		regex_models,
		pg_tables,
		column_name,
		schedule,
		agg
	)
VALUES
	(
		'SME11246',
		'v2_rdu_9600',
		NULL,
		ARRAY [
        	'RE_SIEMENS_MSUP_META',
            'RE_SIEMENS_HOST_TIME_DATE',
            'RE_SIEMENS_TEST_TIME',
            'RE_SIEMENS_LVQD',
            'RE_SIEMENS_MAG_SN',
            'RE_SIEMENS_HE_PARAMS',
            'RE_SIEMENS_FIELD',
            'RE_SIEMENS_SELF_TEST',
            'RE_SIEMENS_SH_STATUS',
            'RE_SIEMENS_BATTERY_VOLTS',
            'RE_SIEMENS_COMPRESSOR_STATUS',
            'RE_SIEMENS_COMPRESSOR_VALUE',
            'RE_SIEMENS_PRESS_SW_STATUS',
            'RE_SIEMENS_ERDU_STATUS',
            'RE_SIEMENS_EPM',
            'RE_SIEMENS_AVG_PWR',
            'RE_SIEMENS_MAG_PSI_A',
            'RE_SIEMENS_SWT_HTR',
            'RE_SIEMENS_CCR_S3_S4',
            'RE_SIEMENS_TURRET',
            'RE_SIEMENS_SHIELD_LINK_BORE',
            'RE_SIEMENS_I_BTN',
            'RE_SIEMENS_QUH_HTR',
            'RE_SIEMENS_ERDU_STATUS_ARRAY',
            'RE_SIEMENS_OR_CODE',
            'RE_SIEMENS_FIELD_CURRENT',
            'RE_SIEMENS_MSUP',
            'RE_SIEMENS_CCR_S1_S2',
            'RE_SIEMENS_HE_VALUES_UNIFIED'
      ],
		-- regex
		ARRAY ['mmb_siemens'],
		-- tables
		NULL,
		1,
		NULL
	);

-->
-->
INSERT INTO
	config.mag (
		system_id,
		file_name,
		dir_name,
		regex_models,
		pg_tables,
		column_name,
		schedule,
		agg
	)
VALUES
	(
		'SME10844',
		'v2_rdu_9600',
		NULL,
		ARRAY [
        	'RE_SIEMENS_MSUP_META',
            'RE_SIEMENS_HOST_TIME_DATE',
            'RE_SIEMENS_TEST_TIME',
            'RE_SIEMENS_LVQD',
            'RE_SIEMENS_MAG_SN',
            'RE_SIEMENS_HE_PARAMS',
            'RE_SIEMENS_HE_STATUS',
            'RE_SIEMENS_FIELD',
            'RE_SIEMENS_SELF_TEST',
            'RE_SIEMENS_SH_STATUS',
            'RE_SIEMENS_BATTERY_VOLTS',
            'RE_SIEMENS_COMPRESSOR_STATUS',
            'RE_SIEMENS_COMPRESSOR_VALUE',
            'RE_SIEMENS_PRESS_SW_STATUS',
            'RE_SIEMENS_SHIELD_LINK_BORE',
            'RE_SIEMENS_TURRET',
            'RE_SIEMENS_CCR_S3_S4',
            'RE_SIEMENS_SWT_HTR',
            'RE_SIEMENS_MAG_PSI_A',
            'RE_SIEMENS_AVG_PWR',
            'RE_SIEMENS_EPM',
            'RE_SIEMENS_ERDU_STATUS',
            'RE_SIEMENS_I_BTN',
            'RE_SIEMENS_QUH_HTR',
            'RE_SIEMENS_ERDU_STATUS_ARRAY',
            'RE_SIEMENS_OR_CODE',
            'RE_SIEMENS_MSUP',
            'RE_SIEMENS_FIELD_CURRENT',
            'RE_SIEMENS_CCR_S1_S2',
            'RE_SIEMENS_HE_VALUES_UNIFIED'
      ],
		-- regex
		ARRAY ['mmb_siemens'],
		-- tables
		NULL,
		1,
		NULL
	);

-->
-->
INSERT INTO systems(id, site_id, manufacturer, modality, model, show_on_website, cus_sys_id, process_edu, process_mag)
VALUES (
	'SME16909',
	'C008408',
	'GE',
	'MRI',
	'1.5T HDX',
	TRUE,
	'DI33-173'
	TRUE,
	TRUE,
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
		'SME16909',
		NULL,
		'172.31.2.20',
		'rsync',
		'/home/prod/hhm_data_acquisition/files',
		NULL,
		NULL,
		NULL,
		'SME15819',
		'avante',
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
		schedule,
		agg
	)
VALUES
	(
		'SME16909',
		'v3_ge_mm3',
		NULL,
		ARRAY ['RE_GE_MM3_E'],
		-- regex
		ARRAY ['mmb_ge_mm3'],
		-- tables
		NULL,
		5,
		NULL
	);

INSERT INTO
	config.edu (
		system_id,
		file_name,
		regex_models,
		pg_tables,
		schedule
	)
VALUES
	(
		'SME16909',
		'v2_edu2',
		ARRAY ['RE_EDU2_COMP_VIB', 'RE_EDU2_ROOM_PROBE_HUM_TEMP', 'RE_EDU2_TEMP_PROBE_TEMPS'],
		ARRAY ['mmb_edu2'],
		7
	);

	{RE_EDU2_TEMP_PROBE_TEMPS,RE_EDU2_COMP_VIB,RE_EDU2_ROOM_PROBE_HUM_TEMP}