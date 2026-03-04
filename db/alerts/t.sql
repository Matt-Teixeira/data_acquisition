BEGIN;

UPDATE alert.models SET 
enabled         = FALSE,
last_update     = NOW(),
last_updated_by = '<email>'
WHERE           id IN 
(
    SELECT
        am.id
        FROM    systems         sys 
        JOIN    sites           sit
        ON      sit.id          = sys.site_id
        JOIN    customers       cus
        ON      cus.id          = sit.customer_id
        JOIN    alert.models    am
        ON      am.system_id    = sys.id
        WHERE   cus.id          = 'C0137'
        AND     am.user_id      = 'default'
        AND     pg_table        = 'alert.offline_hhm_conn'
);

-- VERIFY QUERY
SELECT
        cus.id      cus_id,
        sit.id      site_id,
        sys.id      sys_id,
        sys.manufacturer,
        sys.modality,
        sys.model,
        sys.show_on_website,
        am.id,
        am.field_name_alias,
        am.operator
FROM    systems         sys 
JOIN    sites           sit
ON      sit.id          = sys.site_id
JOIN    customers       cus
ON      cus.id          = sit.customer_id
JOIN    alert.models    am
ON      am.system_id    = sys.id
WHERE   cus.id          = 'C0137'
AND     am.user_id      = 'default'
AND     pg_table        = 'alert.offline_hhm_conn'
ORDER BY    sit.id, sys.id, sys.manufacturer, sys.modality;

-- ROLLBACK;
COMMIT;
 