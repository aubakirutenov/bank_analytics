SELECT
    account_id,
    district_id,
    frequency,
    TO_DATE('19' || date::TEXT, 'YYYYMMDD') AS opened_date
FROM {{ source('berka', 'account') }}