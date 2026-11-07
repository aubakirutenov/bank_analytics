SELECT
    disp_id,
    client_id,
    account_id,
    type AS disp_type
FROM {{ source('berka', 'disp') }}