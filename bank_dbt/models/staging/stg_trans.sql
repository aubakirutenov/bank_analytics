SELECT
    trans_id,
    account_id,
    type,
    amount,
    balance,
    TO_DATE('19' || date::TEXT, 'YYYYMMDD') AS trans_date,
    NULLIF(TRIM(operation), '') AS operation,
    NULLIF(TRIM(k_symbol), '') AS k_symbol,
    NULLIF(TRIM(bank), '') AS partner_bank,
    account AS partner_account
FROM {{ source('berka', 'trans') }}