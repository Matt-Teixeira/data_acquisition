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

--> GE_CT
-- Connecting              SME00897
-- Timed Out               SME00847
-- Network Hang Code: 124  SME17366 SME17367
--> 'SME17367', 'SME00897', 'SME00847', 'SME17366'
-- SME01433 TEST FOR CRED SWITCH UP

--> GE_CV
-- Connecting              
-- Timed Out               
-- Network Hang Code: 124  
--> 