WITH parsed AS (
    SELECT
        client_id,
        district_id,
        SUBSTRING(birth_number, 1, 2)::INT AS yy,
        SUBSTRING(birth_number, 3, 2)::INT AS mm_raw,
        SUBSTRING(birth_number, 5, 2)::INT AS dd
    FROM {{ source('berka', 'client') }}
)

SELECT
    client_id,
    district_id,
    CASE WHEN mm_raw > 50 THEN 'F' ELSE 'M' END AS gender,
    MAKE_DATE(
        1900 + yy,
        CASE WHEN mm_raw > 50 THEN mm_raw - 50 ELSE mm_raw END,
        dd
    ) AS birth_date
FROM parsed