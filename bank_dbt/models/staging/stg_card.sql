SELECT
    card_id,
    disp_id,
    type AS card_type,
    TO_DATE('19' || LEFT(issued, 6) , 'YYYYMMDD') AS issued_date
FROM {{ source('berka', 'card') }}