-- dim_district: demographic data per district.
-- Grain: one row per district (77 districts in 8 regions).
-- Used for the regional questions: accounts, balances and bad loans by
-- district and region, next to salary and unemployment.

SELECT
    district_id,                -- primary key
    district_name,
    region,
    inhabitants,
    municipalities_lt_500,
    municipalities_500_1999,
    municipalities_2000_9999,
    municipalities_gt_10000,
    cities,
    urban_ratio,                -- % of inhabitants living in cities
    avg_salary,
    unemployment_rate_1995,     -- NULL for Jeseník (missing in the source)
    unemployment_rate_1996,
    -- Change in unemployment between the two years, in percentage points.
    -- NULL where the 1995 value is missing.
    unemployment_rate_1996 - unemployment_rate_1995 AS unemployment_change,
    entrepreneurs_per_1000,
    crimes_1995,                -- NULL for Jeseník (missing in the source)
    crimes_1996
FROM {{ ref('stg_district') }}
