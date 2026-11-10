-- agg_monthly_activity: transactions summarised for the activity charts.
-- Grain: one row per month, district, channel and direction.
--
-- Why an aggregate: fact_transactions has 1,056,320 rows. Power BI in the
-- browser loads the data from CSV files, and a summary of a few tens of
-- thousands of rows answers the trend and region questions just as well.
-- The loan analysis does not need it: it uses fact_loans directly.

SELECT
    DATE_TRUNC('month', trans_date)::date AS month_start,   -- key to dim_date (first day of the month)
    district_id,                                              -- the account's branch district
    channel,                                                  -- bank / cash / transfer / card
    direction,                                                -- credit / debit
    COUNT(*)                     AS transactions,
    COUNT(DISTINCT account_id)   AS active_accounts,          -- do not add up across rows: one account can be in several rows
    SUM(amount)                  AS total_amount,
    SUM(signed_amount)           AS net_amount
FROM {{ ref('fact_transactions') }}
GROUP BY 1, 2, 3, 4
