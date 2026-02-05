
INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point, file_version)
VALUES (
	'SME01118',
	'10.3.15.254',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01118',
	NULL,
	'siemens_80_data_grab.sh',
	1,
	NULL,
	NULL,
	NULL,
	'win_10'
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01118',
	'Application.log',
	'Application',
	ARRAY['re_v1'], -- regex
	ARRAY['siemens_mri'], -- tables
	NULL,
	NULL
);

-->
-->


INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point, file_version)
VALUES (
	'SME01101',
	'10.180.42.251',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01101',
	NULL,
	'siemens_80_data_grab.sh',
	1,
	NULL,
	NULL,
	NULL,
	'win_10'
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01101',
	'Application.log',
	'Application',
	ARRAY['re_v1'], -- regex
	ARRAY['siemens_mri'], -- tables
	NULL,
	NULL
);

-->
-->


INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point, file_version)
VALUES (
	'SME12753',
	'10.121.175.251',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME12753',
	NULL,
	'siemens_80_data_grab.sh',
	1,
	NULL,
	NULL,
	NULL,
	'win_10'
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME12753',
	'Application.log',
	'Application',
	ARRAY['re_v1'], -- regex
	ARRAY['siemens_mri'], -- tables
	NULL,
	NULL
);

-->
-->

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point, file_version)
VALUES (
	'SME16343',
	'10.35.11.213',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME16343',
	NULL,
	'siemens_443_data_grab.sh',
	1,
	NULL,
	NULL,
	NULL,
	'win_10'
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16343',
	'Application.log',
	'Application',
	ARRAY['re_v1'], -- regex
	ARRAY['siemens_mri'], -- tables
	NULL,
	NULL
);

-->
-->

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point, file_version)
VALUES (
	'SME01918',
	'10.30.5.1',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01918',
	NULL,
	'siemens_443_data_grab.sh',
	1,
	NULL,
	NULL,
	NULL,
	'win_10'
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01918',
	'Application.log',
	'Application',
	ARRAY['re_v1'], -- regex
	ARRAY['siemens_mri'], -- tables
	NULL,
	NULL
);

-->
-->

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point, file_version)
VALUES (
	'SME01131',
	'10.121.111.218',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01131',
	NULL,
	'siemens_443_data_grab.sh',
	1,
	NULL,
	NULL,
	NULL,
	'win_10'
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01131',
	'Application.log',
	'Application',
	ARRAY['re_v1'], -- regex
	ARRAY['siemens_mri'], -- tables
	NULL,
	NULL
);

-->
-->

UPDATE 
	config.acquisition
SET
	host_ip = '10.177.61.18',
	debian_server_path = '/home/prod/hhm_data_acquisition/files/SME01136',
	acquisition_script = 'siemens_80_data_grab.sh',
	run_group = 1,
	file_version = 'win_10'
WHERE 
	system_id = 'SME01136';

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01136',
	'Application.log',
	'Application',
	ARRAY['re_v1'], -- regex
	ARRAY['siemens_mri'], -- tables
	NULL,
	NULL
);


-->
-->

UPDATE 
	config.acquisition
SET
	host_ip = '10.55.121.239',
	debian_server_path = '/home/prod/hhm_data_acquisition/files/SME01109',
	acquisition_script = 'siemens_80_data_grab.sh',
	run_group = 1,
	file_version = 'win_10'
WHERE 
	system_id = 'SME01109';

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01109',
	'Application.log',
	'Application',
	ARRAY['re_v1'], -- regex
	ARRAY['siemens_mri'], -- tables
	NULL,
	NULL
);

-->
-->

UPDATE 
	config.acquisition
SET
	host_ip = '10.3.61.250',
	debian_server_path = '/home/prod/hhm_data_acquisition/files/SME01135',
	acquisition_script = 'siemens_443_data_grab.sh',
	run_group = 1,
	file_version = 'win_10'
WHERE 
	system_id = 'SME01135';

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01135',
	'Application.log',
	'Application',
	ARRAY['re_v1'], -- regex
	ARRAY['siemens_mri'], -- tables
	NULL,
	NULL
);

--> 02/04/26
-->

UPDATE 
	config.acquisition
SET
	host_ip = '10.209.112.31',
	debian_server_path = '/home/prod/hhm_data_acquisition/files/SME21915',
	acquisition_script = 'siemens_80_data_grab.sh',
	run_group = 1,
	file_version = 'win_10'
WHERE 
	system_id = 'SME21915';

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME21915',
	'Application.log',
	'Application',
	ARRAY['re_v1'], -- regex
	ARRAY['siemens_mri'], -- tables
	NULL,
	NULL
);