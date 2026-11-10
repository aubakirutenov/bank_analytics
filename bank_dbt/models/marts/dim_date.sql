-- dim_date: the calendar dimension.
-- Grain: one row per calendar day, from the earliest to the latest date used
-- anywhere in the data (account openings, transactions, loans, cards).
-- Every date in a fact table points here, so Power BI can group by year,
-- quarter and month without date functions in the report.

WITH all_dates AS (
    -- Collect every date that a fact or dimension can refer to.
    SELECT opened_date AS d FROM {{ ref('stg_account') }}
    UNION ALL
    SELECT trans_date FROM {{ ref('stg_trans') }}
    UNION ALL
    SELECT granted_date FROM {{ ref('stg_loan') }}
    UNION ALL
    SELECT issued_date FROM {{ ref('stg_card') }}
),

bounds AS (
    SELECT MIN(d) AS first_day, MAX(d) AS last_day
    FROM all_dates
),

days AS (
    -- One row per day between the bounds, with no gaps,
    -- so days without any transaction still exist in the calendar.
    SELECT generate_series(first_day, last_day, INTERVAL '1 day')::date AS date_day
    FROM bounds
)

SELECT
    date_day,                                          -- primary key
    EXTRACT(YEAR FROM date_day)::int     AS year,
    EXTRACT(QUARTER FROM date_day)::int  AS quarter,
    EXTRACT(MONTH FROM date_day)::int    AS month,
    TO_CHAR(date_day, 'Mon')             AS month_name,  -- Jan, Feb, ...
    TO_CHAR(date_day, 'YYYY-MM')         AS year_month,  -- label for monthly charts
    DATE_TRUNC('month', date_day)::date  AS month_start, -- sortable month key
    EXTRACT(ISODOW FROM date_day)::int   AS day_of_week, -- 1 = Monday, 7 = Sunday
    EXTRACT(ISODOW FROM date_day) IN (6, 7) AS is_weekend
FROM days
