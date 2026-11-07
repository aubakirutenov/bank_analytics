SELECT
    loan_id,
    account_id,
    TO_DATE('19' || date::TEXT, 'YYYYMMDD') AS granted_date,
    amount,
    duration,
    payments AS monthly_instalment,
    status
FROM {{ source('berka', 'loan') }}