-- 05_export_powerbi.sql
-- Exports the marts as CSV files for Power BI (Power BI in the browser cannot
-- connect to a local PostgreSQL, so the data goes in as files via OneDrive).
-- Run from the repository root, after `dbt build`:
--   psql -U aubakir.u -d bank -f sql/05_export_powerbi.sql
-- The files go to data/powerbi/ (ignored by Git: data/ is in .gitignore).
-- true/false columns are exported as 1/0, which Power BI reads as numbers.

\copy (SELECT * FROM bank_dev.fact_loans) TO 'data/powerbi/fact_loans.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT * FROM bank_dev.agg_monthly_activity) TO 'data/powerbi/agg_monthly_activity.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT account_id, district_id, opened_date, statement_frequency_code, statement_frequency, owner_client_id, disponent_count, has_disponent::int AS has_disponent, card_count FROM bank_dev.dim_account) TO 'data/powerbi/dim_account.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT client_id, gender, birth_date, age_at_end_1998, age_group, district_id, account_id, account_role, card_type, card_issued_date, has_card::int AS has_card FROM bank_dev.dim_client) TO 'data/powerbi/dim_client.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT * FROM bank_dev.dim_district) TO 'data/powerbi/dim_district.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT date_day, year, quarter, month, month_name, year_month, month_start, day_of_week, is_weekend::int AS is_weekend FROM bank_dev.dim_date) TO 'data/powerbi/dim_date.csv' WITH (FORMAT csv, HEADER true)
