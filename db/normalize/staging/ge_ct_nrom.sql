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
		'SME00896',
		'10.87.143.223',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME00896',
		'1',
		'ge_ct_22.sh',
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
		'SME00896',
		'gesys_RDMCOPCT.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME01091',
		'10.87.143.205',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME01091',
		'1',
		'ge_ct_22.sh',
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
		'SME01091',
		'gesys_RDMCCT_2.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME01091',
		'gesys_RE36A1600120YC.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME01091',
		'gesys_ct99.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME00847',
		'10.189.19.63',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME00847',
		'1',
		'ge_ct_22.sh',
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
		'SME00847',
		'gesys_ct99.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME00847',
		'gesys_mcvct.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME01429',
		'172.19.13.208',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME01429',
		'1',
		'ge_ct_22.sh',
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
		'SME01429',
		'gesys_CRDCT01.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME01431',
		'172.17.17.206',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME01431',
		'1',
		'ge_ct_22.sh',
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
		'SME01431',
		'gesys_LRDCT01.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME01432',
		'172.17.31.213',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME01432',
		'1',
		'ge_ct_22.sh',
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
		'SME01432',
		'gesys_LRDCT02.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME01433',
		'10.136.23.201',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME01433',
		'1',
		'ge_ct_22.sh',
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
		'SME01433',
		'gesys_HRDCT01.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME01434',
		'172.18.46.33',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME01434',
		'1',
		'ge_ct_22.sh',
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
		'SME01434',
		'gesys_BRDCT01.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME01176',
		'10.60.70.33',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME01176',
		'2',
		'ge_ct_22.sh',
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
		'SME01176',
		'gesys__oc0.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME01435',
		'172.18.46.33',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME01435',
		'2',
		'ge_ct_22.sh',
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
		'SME01435',
		'gesys_BRDCT01.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME00897',
		'10.87.143.204',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME00897',
		'1',
		'ge_ct_22.sh',
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
		'SME00897',
		'gesys_BRDCT01.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME14521',
		'10.75.10.247',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME14521',
		'2',
		'ge_ct_22.sh',
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
		'SME14521',
		'gesys_ct07.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME14522',
		'10.35.12.123',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME14522',
		'3',
		'ge_ct_22.sh',
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
		'SME14522',
		'gesys_ct04.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME12413',
		'10.20.32.39',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME12413',
		'2',
		'ge_ct_22.sh',
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
		'SME12413',
		'gesys_GEOPT660CT1.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME12451',
		'10.64.88.60',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME12451',
		'2',
		'ge_ct_22.sh',
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
		'SME12451',
		'gesys_CTSEN.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME12451',
		'gesys_ct99.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME12412',
		'167.171.56.43',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME12412',
		'2',
		'ge_ct_22.sh',
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
		'SME12412',
		'gesys_gect1.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME12408',
		'10.20.32.61',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME12408',
		'1',
		'ge_ct_22.sh',
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
		'SME12408',
		'gesys_GEBSCT1.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME12446',
		'10.193.14.204',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME12446',
		'2',
		'ge_ct_22.sh',
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
		'SME12446',
		'gesys_GE-OPTIMA64.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME12411',
		'10.120.5.213',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME12411',
		'2',
		'ge_ct_22.sh',
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
		'SME12411',
		'gesys_phrgect4.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME12450',
		'10.64.68.24',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME12450',
		'1',
		'ge_ct_22.sh',
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
		'SME12450',
		'gesys_ct_eso.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME12445',
		'10.210.148.7',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME12450',
		'1',
		'ge_ct_22.sh',
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
		'SME12445',
		'gesys_GECT1.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME12444',
		'10.195.18.212',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME12444',
		'3',
		'ge_ct_22.sh',
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
		'SME12444',
		'gesys_GECT1.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME12443',
		'10.184.14.203',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME12443',
		'2',
		'ge_ct_22.sh',
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
		'SME12443',
		'gesys_CT_GE_BEH_2.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME12409',
		'10.20.32.34',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME12409',
		'1',
		'ge_ct_22.sh',
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
		'SME12409',
		'gesys_QUORTUGECTIC.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME12449',
		'10.41.11.70',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME12449',
		'1',
		'ge_ct_22.sh',
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
		'SME12449',
		'gesys_QUORTUGECTIC.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17371',
		'10.146.9.140',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17371',
		'1',
		'ge_ct_22_v2.sh',
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
		'SME17371',
		'gesys_NBCT1.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17371',
		'gesys_nbls.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17371',
		'gesys_nbct1.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17373',
		'10.146.184.43',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17373',
		'1',
		'ge_ct_22.sh',
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
		'SME17373',
		'gesys_MIHCCT_INIH.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17379',
		'10.146.9.138',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17379',
		'1',
		'ge_ct_22.sh',
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
		'SME17379',
		'gesys_ct03.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17379',
		'gesys_ct99.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17379',
		'gesys_NBCT2.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17379',
		'gesys_RE36A1700208YC.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME01430',
		'172.22.23.200',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME01430',
		'1',
		'ge_ct_22.sh',
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
		'SME01430',
		'gesys_GRDCT02.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME16618',
		'10.251.201.15',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME16618',
		'19',
		'ge_ct_22.sh',
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
		'SME16618',
		'gesys_svct.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17155',
		'129.109.254.94',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17155',
		'3',
		'ge_ct_22.sh',
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
		'SME17155',
		'gesys_ucl1.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17157',
		'129.109.254.70',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17157',
		'1',
		'ge_ct_22.sh',
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
		'SME17157',
		'gesys_utc4.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17158',
		'129.109.252.147',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17158',
		'3',
		'ge_ct_22.sh',
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
		'SME17158',
		'gesys_VLCT.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17159',
		'129.109.252.171',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17159',
		'1',
		'ge_ct_22.sh',
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
		'SME17159',
		'gesys_LCCERGECT1.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17162',
		'10.189.248.12',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17162',
		'1',
		'ge_ct_22.sh',
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
		'SME17162',
		'gesys_CLCRADGECT2.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17164',
		'10.189.248.9',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17164',
		'1',
		'ge_ct_22.sh',
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
		'SME17164',
		'gesys_BACT1.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17164',
		'gesys_CLCRADGECT1.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17366',
		'10.146.75.90',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17366',
		'19',
		'ge_ct_21.sh',
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
		'SME17366',
		'gesys_pet_tmc.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17367',
		'10.146.148.200',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17367',
		'19',
		'ge_ct_21.sh',
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
		'SME17367',
		'gesys_pet_I65.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17368',
		'10.146.148.145',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17368',
		'1',
		'ge_ct_22.sh',
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
		'SME17368',
		'gesys_65ct.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17370',
		'10.146.16.60',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17370',
		'1',
		'ge_ct_22.sh',
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
		'SME17370',
		'gesys_ct99.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17370',
		'gesys_SLCT_SL.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17376',
		'10.46.210.46',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17376',
		'1',
		'ge_ct_22.sh',
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
		'SME17376',
		'gesys_ct99.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
	--10.46.210.44
	(
		'SME17377',
		'10.46.210.44',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17377',
		'2',
		'ge_ct_22.sh',
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
		'SME17377',
		'gesys_ct03.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17378',
		'10.146.20.60',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17378',
		'1',
		'ge_ct_22.sh',
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
		'SME17378',
		'gesys_bay41.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17378',
		'gesys_ct99.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17378',
		'gesys_FEDCT_FED.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17378',
		'gesys_FEDCT.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME00821',
		'10.106.1.14',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME00821',
		'7',
		'ge_ct_22.sh',
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
		'SME00821',
		'gesys_PFRT16.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME00875',
		'10.60.63.191',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME00875',
		'19',
		'ge_ct_22.sh',
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
		'SME00875',
		'gesys_ctrt.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME00881',
		'10.60.63.148',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME00881',
		'3',
		'ge_ct_22.sh',
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
		'SME00881',
		'gesys_PWCT16N.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME01075',
		'10.189.19.66',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME01075',
		'3',
		'ge_ct_22.sh',
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
		'SME01075',
		'gesys_mchdct.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME10120',
		'10.3.18.50',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME10120',
		'3',
		'ge_ct_22.sh',
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
		'SME10120',
		'gesys_ge_ct.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME11228',
		'10.128.137.195',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME11228',
		'3',
		'ge_ct_22.sh',
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
		'SME11228',
		'gesys_ct99.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME11230',
		'10.128.127.197',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME11230',
		'3',
		'ge_ct_22.sh',
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
		'SME11230',
		'gesys_foct.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME12504',
		'10.0.107.11',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME12504',
		'3',
		'ge_ct_22.sh',
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
		'SME12504',
		'gesys_ct01.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME12504',
		'gesys_ct99.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME15218',
		'10.128.63.20',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME15218',
		'3',
		'ge_ct_22.sh',
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
		'SME15218',
		'gesys_ct01.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME15218',
		'gesys_ct99.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME17153',
		'129.109.253.137',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME17153',
		'3',
		'ge_ct_22.sh',
		1,
		NULL,
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
		'SME00882',
		'10.3.54.242',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME00882',
		'3',
		'ge_ct_22.sh',
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
		'SME00882',
		'gesys_gect.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
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
		'SME18536',
		'10.0.99.20',
		NULL,
		'lftp',
		'/home/staging/hhm_data_acquisition/files/SME18536',
		'3',
		'ge_ct_22.sh',
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
		'SME18536',
		'gesys_ct01.log',
		'gesys',
		ARRAY ['block', 'sub_block'],
		ARRAY ['ge_ct_gesys'],
		NULL,
		NULL
	);