-- 06_powerbi_reference.sql
-- Reference numbers for checking the Power BI measures.
-- Run in DBeaver, write the results down, then compare them with the
-- card and table visuals in Power BI. Every measure must match exactly.

-- 1. Headline numbers (cards).
SELECT COUNT(*)                         AS loans,
       SUM(is_bad)                      AS bad_loans,
       ROUND(100.0 * AVG(is_bad), 2)    AS bad_loan_rate_pct,
       SUM(amount)                      AS loan_amount,
       ROUND(AVG(amount), 2)            AS avg_loan_amount
FROM bank_dev.fact_loans;

-- 2. Bad-loan rate by loan duration (months).
SELECT duration, COUNT(*) AS loans, SUM(is_bad) AS bad_loans,
       ROUND(100.0 * AVG(is_bad), 2) AS bad_loan_rate_pct
FROM bank_dev.fact_loans
GROUP BY duration
ORDER BY duration;

-- 3. Bad-loan rate by amount band.
SELECT amount_band, COUNT(*) AS loans, SUM(is_bad) AS bad_loans,
       ROUND(100.0 * AVG(is_bad), 2) AS bad_loan_rate_pct
FROM bank_dev.fact_loans
GROUP BY amount_band
ORDER BY amount_band;

-- 4. Bad-loan rate by negative balance before the loan.
SELECT had_negative_balance_before_loan, COUNT(*) AS loans, SUM(is_bad) AS bad_loans,
       ROUND(100.0 * AVG(is_bad), 2) AS bad_loan_rate_pct
FROM bank_dev.fact_loans
GROUP BY had_negative_balance_before_loan
ORDER BY had_negative_balance_before_loan;

-- 5. Bad-loan rate by region (via the loan's district).
SELECT d.region, COUNT(*) AS loans, SUM(l.is_bad) AS bad_loans,
       ROUND(100.0 * AVG(l.is_bad), 2) AS bad_loan_rate_pct
FROM bank_dev.fact_loans l
JOIN bank_dev.dim_district d ON d.district_id = l.district_id
GROUP BY d.region
ORDER BY bad_loan_rate_pct DESC;

-- 6. Bad-loan rate by the owner's age group (age at the end of 1998).
SELECT c.age_group, COUNT(*) AS loans, SUM(l.is_bad) AS bad_loans,
       ROUND(100.0 * AVG(l.is_bad), 2) AS bad_loan_rate_pct
FROM bank_dev.fact_loans l
JOIN bank_dev.dim_client c ON c.client_id = l.owner_client_id
GROUP BY c.age_group
ORDER BY c.age_group;

-- 7. Activity per year (from the monthly summary).
SELECT EXTRACT(YEAR FROM month_start)::int AS year,
       SUM(transactions)  AS transactions,
       SUM(total_amount)  AS volume,
       SUM(net_amount)    AS net_flow
FROM bank_dev.agg_monthly_activity
GROUP BY 1
ORDER BY 1;
