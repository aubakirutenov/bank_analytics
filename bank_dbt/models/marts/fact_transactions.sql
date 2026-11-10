-- fact_transactions: every account transaction, ready for analysis.
-- Grain: one row per transaction (1,056,320), same as stg_trans.
-- Keys to the dimensions: account_id, owner_client_id, district_id, trans_date.
--
-- The owner and district are copied from dim_account onto every row, so in
-- Power BI each dimension connects directly to the fact (a star), and the
-- dimensions never need relationships to each other.

WITH labels AS (
    -- Czech code -> English label, from the seed.
    SELECT code_column, code, english
    FROM {{ ref('berka_codes') }}
)

SELECT
    t.trans_id,                                    -- primary key
    t.account_id,
    a.owner_client_id,
    a.district_id,                                 -- the account's branch district
    t.trans_date,

    -- Direction of the money. PRIJEM = money in; VYDAJ and VYBER = money out.
    t.type AS type_code,
    CASE WHEN t.type = 'PRIJEM' THEN 'credit' ELSE 'debit' END AS direction,

    t.amount,                                      -- always positive in the source
    -- Signed amount: + for money in, - for money out.
    -- SUM(signed_amount) is the net change of the balance.
    CASE WHEN t.type = 'PRIJEM' THEN t.amount ELSE -t.amount END AS signed_amount,
    t.balance AS balance_after,                    -- balance after this transaction

    -- How the money moved.
    t.operation AS operation_code,
    op.english  AS operation,
    -- Order matters: CASE stops at the first match. Bank entries go first,
    -- because the source books fees and penalty interest with operation VYBER
    -- (cash withdrawal), although no cash moves. Checked in sql/04_mart_checks.sql:
    -- VYBER + SLUZBY 155,832 rows, VYBER + SANKC. UROK 1,577 rows.
    CASE
        WHEN t.k_symbol IN ('UROK', 'SANKC. UROK', 'SLUZBY')     THEN 'bank'      -- interest, penalty interest, fees
        WHEN t.operation IN ('VKLAD', 'VYBER')                   THEN 'cash'
        WHEN t.operation IN ('PREVOD Z UCTU', 'PREVOD NA UCET')  THEN 'transfer'
        WHEN t.operation = 'VYBER KARTOU'                        THEN 'card'
    END AS channel,     -- no ELSE: an unknown combination stays NULL and fails the not_null test

    -- What the payment was for (interest, pension, insurance, loan ...).
    t.k_symbol  AS k_symbol_code,
    ks.english  AS payment_purpose,

    t.partner_bank,
    t.partner_account
FROM {{ ref('stg_trans') }} t
JOIN {{ ref('dim_account') }} a ON a.account_id = t.account_id
-- LEFT JOINs: rows without a code must stay. The seed has one row per
-- (code_column, code), so these joins never duplicate transactions.
LEFT JOIN labels op ON op.code_column = 'trans.operation' AND op.code = t.operation
LEFT JOIN labels ks ON ks.code_column = 'k_symbol'        AND ks.code = t.k_symbol
