SELECT
    order_id,
    account_id,
    amount,
    bank_to AS partner_bank,
    account_to AS partner_account,
    NULLIF(TRIM(k_symbol), '') AS k_symbol
FROM {{ source('berka', 'standing_order') }}