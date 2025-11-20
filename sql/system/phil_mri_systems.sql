/* SELECT
 sys.id,
 sys.manufacturer,
 sys.modality,
 ac.mmb_ip,
 ac.acqu_point,
 ac.debian_server_path,
 ac.user_id,
 ac.host,
 json_agg(
 json_build_object(
 'system_id',
 mag.system_id,
 'dir_name',
 mag.dir_name,
 'file_name',
 mag.file_name
 )
 ) AS mag_data
 FROM
 systems sys
 JOIN config.acquisition ac ON sys.id = ac.system_id
 JOIN config.mag mag ON sys.id = mag.system_id
 WHERE
 sys.manufacturer = 'Philips'
 AND sys.modality LIKE 'MRI'
 AND ac.acqu_point = 'mmb'
 GROUP BY
 sys.id,
 ac.system_id; */
SELECT
    sys.id,
    sys.manufacturer,
    sys.modality,
    ac.mmb_ip,
    ac.acqu_point,
    ac.debian_server_path,
    ac.user_id,
    ac.host,
    json_agg(
        json_build_object(
            'system_id',
            mag.system_id,
            'dir_name',
            mag.dir_name,
            'file_name',
            mag.file_name
        )
    ) AS mag_data,
    json_build_object(
        'system_id',
        log.system_id,
        'dir_name',
        log.dir_name,
        'file_name',
        log.file_name
    ) AS log_config
FROM
    systems sys
    JOIN config.acquisition ac ON sys.id = ac.system_id
    JOIN config.mag mag ON sys.id = mag.system_id
    JOIN config.log log ON sys.id = log.system_id
WHERE
    sys.manufacturer = 'Philips'
    AND sys.modality LIKE 'MRI'
    AND ac.acqu_point = 'mmb'
GROUP BY
    sys.id,
    ac.system_id,
    log.system_id,
    log.file_name,
    log.dir_name;