SELECT
    system_id,
    host_ip,
    debian_server_path,
    acquisition_script,
    user_id
FROM
    config.acquisition
WHERE
    acqu_point = 'althea_vm';