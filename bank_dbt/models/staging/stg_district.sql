SELECT
    a1 AS district_id,
    a2 AS district_name,
    a3 AS region,
    a4 AS inhabitants,
    a5 AS municipalities_lt_500,
    a6 AS municipalities_500_1999,
    a7 AS municipalities_2000_9999,
    a8 AS municipalities_gt_10000,
    a9 AS cities,
    a10	AS urban_ratio,
    a11	AS avg_salary,
    NULLIF(TRIM(a12), '?')::numeric AS unemployment_rate_1995, 
    a13 AS unemployment_rate_1996,
    a14 AS entrepreneurs_per_1000,
    NULLIF(TRIM(a15), '?')::int AS crimes_1995, 
    a16	AS crimes_1996
FROM {{ source('berka', 'district') }}