SELECT
    sys.id,
    sys.manufacturer,
    sys.modality,
    ac.host_ip,
    ac.vpn,
    ac.acqu_point,
    ac.debian_server_path,
    ac.credentials_group,
    ac.acquisition_script
FROM
    systems sys
    JOIN config.acquisition ac ON sys.id = ac.system_id
WHERE
    sys.manufacturer = 'Philips'
    AND sys.modality LIKE 'MRI'
    AND ac.acqu_point = 'host'
    AND (
        sys.process_mag IS TRUE
        OR sys.process_log IS TRUE
    );

-- SME10251 is an mmb, but acqu_point set to host for testing: removing current rsync process.