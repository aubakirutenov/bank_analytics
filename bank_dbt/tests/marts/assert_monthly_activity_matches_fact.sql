-- The monthly summary must contain every transaction exactly once:
-- the same number of transactions and the same total amount as the fact table.
-- Returns a row when the totals differ; passes when it returns 0 rows.

WITH summary AS (
    SELECT SUM(transactions) AS transactions, SUM(total_amount) AS total_amount
    FROM {{ ref('agg_monthly_activity') }}
),

fact AS (
    SELECT COUNT(*) AS transactions, SUM(amount) AS total_amount
    FROM {{ ref('fact_transactions') }}
)

SELECT s.transactions AS summary_transactions, f.transactions AS fact_transactions,
       s.total_amount AS summary_amount,       f.total_amount AS fact_amount
FROM summary s, fact f
WHERE s.transactions <> f.transactions
   OR s.total_amount <> f.total_amount
