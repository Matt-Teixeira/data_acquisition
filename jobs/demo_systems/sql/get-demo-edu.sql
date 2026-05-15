SELECT
    sys.id,
    ac.mmb_ip,
    ac.host,
    ac.user_id,
    ac.vpn,
    json_build_object(
        'system_id',
        edu.system_id,
        'file_name',
        edu.file_name,
        'regex_models',
        edu.regex_models,
        'pg_tables',
        edu.pg_tables,
        'schedule',
        edu.schedule
    ) AS config
FROM
    systems sys
    JOIN config.acquisition ac ON sys.id = ac.system_id
    JOIN config.edu edu ON sys.id = edu.system_id
WHERE
    sys.id IN ('SME21922','SME11221','SME01136','SME18368')
    AND
    sys.process_edu IS TRUE
    AND
    NOT (sys.manufacturer = 'Philips' AND sys.modality = 'MRI')
GROUP BY
    sys.id,
    ac.system_id,
    edu.system_id,
    edu.file_name,
    edu.regex_models,
    edu.pg_tables,
    edu.schedule;
