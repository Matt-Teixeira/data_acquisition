INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00445',
	'172.16.30.48',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00445',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00445',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00445',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00446',
	'172.16.30.137',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00446',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00446',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00446',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00782',
	'10.50.49.82',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00782',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00782',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00782',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00786',
	'10.50.10.81',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00786',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00786',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00786',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01227',
	'10.50.48.21',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01227',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01227',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01227',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME02548',
	'10.50.48.110',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME02548',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME02548',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME02548',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME02535',
	'10.200.128.193',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME02535',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME02535',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME02535',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME02552',
	'172.16.112.240',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME02552',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME02552',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME02552',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME07852',
	'10.20.152.42',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME07852',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME07852',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME07852',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME07855',
	'172.16.144.69',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME07855',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME07855',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME07855',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME07860',
	'172.16.144.93',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME07860',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME07860',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME07860',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME07862',
	'172.16.104.129',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME07862',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME07862',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME07862',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME11259',
	'10.75.163.238',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME11259',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11259',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11259',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME11532',
	'10.75.163.135',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME11532',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11532',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11532',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME11925',
	'10.75.163.82',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME11925',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11925',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11925',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME11927',
	'10.75.22.235',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME11927',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11927',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11927',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00886',
	'10.233.120.22',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00886',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00886',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00886',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00888',
	'10.233.120.24',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00888',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00888',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00888',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00892',
	'10.232.33.30',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00892',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00892',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00892',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME11722',
	'192.168.101.141',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME11722',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11722',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11722',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00508',
	'192.168.50.21',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00508',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00508',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00508',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00509',
	'192.168.50.22',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00509',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00509',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00509',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00510',
	'192.168.50.25',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00510',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00510',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00510',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00511',
	'192.168.50.82',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00511',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00511',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00511',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01387',
	'172.22.21.220',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01387',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01387',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01387',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01388',
	'172.22.21.221',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01388',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01388',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01388',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01389',
	'172.22.21.242',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01389',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01389',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01389',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01391',
	'172.18.21.237',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01391',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01391',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01391',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01392',
	'172.18.21.225',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01392',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01392',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01392',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01393',
	'172.18.21.233',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01393',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01393',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01393',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01394',
	'172.18.21.229',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01394',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01394',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01394',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01396',
	'172.19.13.239',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01396',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01396',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01396',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01397',
	'172.22.21.231',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01397',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01397',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01397',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME02531',
	'10.200.128.195',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME02531',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME02531',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME02531',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME08325',
	'10.111.10.41',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME08325',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08325',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME08325',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00444',
	'172.16.30.49',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00444',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00444',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00444',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME07761',
	'172.16.116.17',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME07761',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME07761',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME07761',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME11530',
	'10.75.163.100',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME11530',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11530',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11530',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME17160',
	'129.109.252.30',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME17160',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17160',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17160',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-->
-->

UPDATE config.acquisition 
SET credentials_group = '12'
WHERE system_id = 'SME13488';

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME13488',
	'10.75.163.199',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME13488',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME13488',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME13488',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME13529',
	'10.75.22.249',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME13529',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME13529',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME13529',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME13641',
	'10.200.48.61',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME13641',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME13641',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME13641',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00467',
	'192.168.51.60',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00467',
	'11',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00467',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00467',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME14784',
	'192.168.236.5',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME14784',
	'11',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME14784',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME14784',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00349',
	'10.20.108.188',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00349',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00349',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00349',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00529',
	'170.53.68.139',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00529',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00529',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00529',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00530',
	'170.53.68.142',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00530',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00530',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00530',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00819',
	'10.57.62.135',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00819',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00819',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00819',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00848',
	'10.189.65.28',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00848',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00848',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00848',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01390',
	'172.18.21.239',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01390',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01390',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01390',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME01398',
	'172.22.21.233',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME01398',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01398',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME01398',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME11677',
	'10.153.80.23',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME11677',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11677',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11677',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME11713',
	'10.153.80.10',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME11713',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11713',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11713',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME11723',
	'192.168.101.20',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME11723',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11723',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11723',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME11724',
	'192.168.101.52',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME11724',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11724',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME11724',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME14220',
	'10.60.187.12',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME14220',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME14220',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME14220',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME16076',
	'10.144.233.17',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME16076',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16076',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME16076',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME18580',
	'10.5.19.22',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME18580',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME18580',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME18580',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME18532',
	'10.128.131.240',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME18532',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME18532',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME18532',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME18533',
	'10.128.130.241',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME18533',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME18533',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME18533',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME18529',
	'10.0.99.3',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME18529',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME18529',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME18529',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-->
-->

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME18979',
	'100.68.20.116',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME18979',
	'12',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME18979',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME18979',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);

-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME17003',
	'10.40.124.47',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME17003',
	'11',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17003',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME17003',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);


-- >
-- >

INSERT INTO config.acquisition(system_id, host_ip, mmb_ip, protocal, debian_server_path, credentials_group, acquisition_script, run_group, host, user_id, acqu_point)
VALUES (
	'SME00527',
	'10.20.170.93',
	NULL,
	'lftp',
	'/home/prod/hhm_data_acquisition/files/SME00527',
	'11',
	'phil_cv_21.sh',
	1,
	NULL,
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00527',
	'EventLog.txe',
	'EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog'], -- tables
	NULL,
	NULL
);

INSERT INTO config.log (system_id, file_name, dir_name, regex_models, pg_tables, column_name, agg)
VALUES(
	'SME00527',
	'lod_EventLog.txe',
	'lod_EventLog',
	ARRAY['eventlog'], -- regex
	ARRAY['philips_cv_eventlog', 'lod'], -- tables
	NULL,
	NULL
);