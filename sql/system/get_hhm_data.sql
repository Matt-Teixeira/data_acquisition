SELECT
    sys.id,
    sys.manufacturer,
    sys.modality,
    ac.host_ip,
    ac.vpn,
    ac.acqu_point,
    ac.debian_server_path,
    ac.credentials_group,
    ac.acquisition_script,
    ac.host_path,
    ac.cerb_file
FROM
    systems sys
    JOIN config.acquisition ac ON sys.id = ac.system_id
WHERE
    manufacturer = $1
    AND modality LIKE $2
    AND process_log = true;