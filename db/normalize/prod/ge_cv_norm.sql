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
		'SME00865',
		'10.121.151.228',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME00865',
		'7',
		'ge_cv_21.sh',
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
		'SME00865',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME01442',
		'172.19.13.249',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME01442',
		'7',
		'ge_cv_21.sh',
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
		'SME01442',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME16934',
		'10.45.1.165',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME16934',
		'7',
		'ge_cv_21.sh',
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
		'SME16934',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME16938',
		'10.45.1.203',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME16938',
		'7',
		'ge_cv_21.sh',
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
		'SME16938',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME14285',
		'10.189.248.13',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME14285',
		'7',
		'ge_cv_21.sh',
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
		'SME14285',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME17163',
		'10.189.248.17',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME17163',
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
		'SME17163',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME16933',
		'10.45.1.140',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME16933',
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
		'SME16933',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME16937',
		'10.46.211.64',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME16937',
		'7',
		'ge_cv_21.sh',
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
		'SME16937',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME16935',
		'10.45.1.160',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME16935',
		'7',
		'ge_cv_21.sh',
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
		'SME16935',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME11929',
		'165.100.10.1',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME11929',
		'7',
		'ge_cv_21.sh',
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
		'SME11929',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME16939',
		'10.59.46.12',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME16939',
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
		'SME16939',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME16932',
		'10.46.211.160',
		NULL,
		'lftp',
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
		'SME00569',
		'10.232.26.120',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME00569',
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
		'SME00569',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME00843',
		'10.108.123.240',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME00843',
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
		'SME00843',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME00872',
		'10.150.115.223',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME00872',
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
		'SME00872',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME00898',
		'10.108.123.250',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME00898',
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
		'SME00898',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME16931',
		'10.45.1.201',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME16931',
		'7',
		'ge_cv_21.sh',
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
		'SME16931',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME02412',
		'156.72.132.84',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME02412',
		'7',
		'ge_cv_21.sh',
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
		'SME02412',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME08640',
		'156.72.131.153',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME08640',
		'7',
		'ge_cv_21.sh',
		2,
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
		'SME08640',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
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
		acqu_point
	)
VALUES
	(
		'SME20849',
		'10.45.1.130',
		NULL,
		'lftp',
		'/home/prod/hhm_data_acquisition/files/SME08640',
		'7',
		'ge_cv_22_2.sh',
		2,
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
		'SME20849',
		'sysError.log',
		'sysError',
		ARRAY ['sys_error'],
		ARRAY ['ge_cv_syserror'],
		NULL,
		NULL
	);