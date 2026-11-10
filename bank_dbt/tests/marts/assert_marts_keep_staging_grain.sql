-- Every mart built from one staging model must keep its grain:
-- the same number of rows as its source.
-- More rows = a join duplicated rows (fan-out).
-- Fewer rows = an inner join dropped rows without a match.
-- Returns one row per broken model; passes when it returns 0 rows.

WITH counts AS (
    SELECT 'dim_account' AS model,
           (SELECT COUNT(*) FROM {{ ref('dim_account') }}) AS mart_rows,
           (SELECT COUNT(*) FROM {{ ref('stg_account') }}) AS staging_rows
    UNION ALL
    SELECT 'dim_client',
           (SELECT COUNT(*) FROM {{ ref('dim_client') }}),
           (SELECT COUNT(*) FROM {{ ref('stg_client') }})
    UNION ALL
    SELECT 'dim_district',
           (SELECT COUNT(*) FROM {{ ref('dim_district') }}),
           (SELECT COUNT(*) FROM {{ ref('stg_district') }})
    UNION ALL
    SELECT 'fact_transactions',
           (SELECT COUNT(*) FROM {{ ref('fact_transactions') }}),
           (SELECT COUNT(*) FROM {{ ref('stg_trans') }})
    UNION ALL
    SELECT 'fact_loans',
           (SELECT COUNT(*) FROM {{ ref('fact_loans') }}),
           (SELECT COUNT(*) FROM {{ ref('stg_loan') }})
)

SELECT model, mart_rows, staging_rows
FROM counts
WHERE mart_rows <> staging_rows
