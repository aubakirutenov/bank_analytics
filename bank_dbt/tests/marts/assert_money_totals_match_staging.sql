-- Money must not be lost or counted twice between staging and the marts.
-- Compares the total amount and the net amount (money in minus money out)
-- of transactions, and the total loan amount.
-- Returns one row per total that differs; passes when it returns 0 rows.

WITH mart_trans AS (
    SELECT SUM(amount) AS total_amount, SUM(signed_amount) AS net_amount
    FROM {{ ref('fact_transactions') }}
),

staging_trans AS (
    SELECT SUM(amount) AS total_amount,
           SUM(CASE WHEN type = 'PRIJEM' THEN amount ELSE -amount END) AS net_amount
    FROM {{ ref('stg_trans') }}
),

mart_loans AS (
    SELECT SUM(amount) AS total_amount FROM {{ ref('fact_loans') }}
),

staging_loans AS (
    SELECT SUM(amount) AS total_amount FROM {{ ref('stg_loan') }}
)

SELECT 'transactions: total amount' AS check_name, m.total_amount AS mart_value, s.total_amount AS staging_value
FROM mart_trans m, staging_trans s
WHERE m.total_amount <> s.total_amount

UNION ALL

SELECT 'transactions: net amount', m.net_amount, s.net_amount
FROM mart_trans m, staging_trans s
WHERE m.net_amount <> s.net_amount

UNION ALL

SELECT 'loans: total amount', m.total_amount, s.total_amount
FROM mart_loans m, staging_loans s
WHERE m.total_amount <> s.total_amount
