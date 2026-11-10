-- 04_mart_checks.sql
-- Manual validation of the dbt marts (schema bank_dev) against the raw tables
-- (schema raw), written in plain SQL, independent of dbt.
-- Run each query in DBeaver after `dbt build`; the expected result is in the comment.

-- 1. Row counts: each mart has the same number of rows as its raw table.
--    Expected: every "difference" is 0.
SELECT 'account' AS tbl, (SELECT COUNT(*) FROM raw.account) AS raw_rows,
       (SELECT COUNT(*) FROM bank_dev.dim_account) AS mart_rows,
       (SELECT COUNT(*) FROM raw.account) - (SELECT COUNT(*) FROM bank_dev.dim_account) AS difference
UNION ALL
SELECT 'client', (SELECT COUNT(*) FROM raw.client), (SELECT COUNT(*) FROM bank_dev.dim_client),
       (SELECT COUNT(*) FROM raw.client) - (SELECT COUNT(*) FROM bank_dev.dim_client)
UNION ALL
SELECT 'district', (SELECT COUNT(*) FROM raw.district), (SELECT COUNT(*) FROM bank_dev.dim_district),
       (SELECT COUNT(*) FROM raw.district) - (SELECT COUNT(*) FROM bank_dev.dim_district)
UNION ALL
SELECT 'trans', (SELECT COUNT(*) FROM raw.trans), (SELECT COUNT(*) FROM bank_dev.fact_transactions),
       (SELECT COUNT(*) FROM raw.trans) - (SELECT COUNT(*) FROM bank_dev.fact_transactions)
UNION ALL
SELECT 'loan', (SELECT COUNT(*) FROM raw.loan), (SELECT COUNT(*) FROM bank_dev.fact_loans),
       (SELECT COUNT(*) FROM raw.loan) - (SELECT COUNT(*) FROM bank_dev.fact_loans);

-- 2. Money totals: transactions and loans, raw vs mart.
--    Expected: both differences are 0.
SELECT
    (SELECT SUM(amount) FROM raw.trans)                       AS raw_trans_amount,
    (SELECT SUM(amount) FROM bank_dev.fact_transactions)      AS mart_trans_amount,
    (SELECT SUM(amount) FROM raw.trans)
      - (SELECT SUM(amount) FROM bank_dev.fact_transactions)  AS trans_difference,
    (SELECT SUM(amount) FROM raw.loan)                        AS raw_loan_amount,
    (SELECT SUM(amount) FROM bank_dev.fact_loans)             AS mart_loan_amount,
    (SELECT SUM(amount) FROM raw.loan)
      - (SELECT SUM(amount) FROM bank_dev.fact_loans)         AS loan_difference;

-- 3. Loan outcomes. Expected: A 203, B 31, C 403, D 45; bad loans 76 of 682 = 11.1 %.
SELECT status, status_description, COUNT(*) AS loans, SUM(is_bad) AS bad_loans
FROM bank_dev.fact_loans
GROUP BY status, status_description
ORDER BY status;

SELECT COUNT(*) AS loans, SUM(is_bad) AS bad_loans,
       ROUND(100.0 * AVG(is_bad), 1) AS bad_loan_pct
FROM bank_dev.fact_loans;

-- 4. What is in each channel? Checks the CASE in fact_transactions.
--    Expected: 'bank' holds only UROK, SANKC. UROK and SLUZBY; no fees in 'cash'.
SELECT channel, operation_code, k_symbol_code, COUNT(*) AS transactions
FROM bank_dev.fact_transactions
GROUP BY channel, operation_code, k_symbol_code
ORDER BY channel, transactions DESC;

-- 5. Owners and disponents. Expected: 4,500 accounts, 4,500 with an owner,
--    869 disponents in total.
SELECT COUNT(*) AS accounts,
       COUNT(owner_client_id) AS accounts_with_owner,
       SUM(disponent_count) AS disponents
FROM bank_dev.dim_account;

-- 6. Cards by account role. Shows whether cards go only to owners.
--    Expected total: 892 cards.
SELECT account_role, card_type, COUNT(*) AS clients
FROM bank_dev.dim_client
WHERE has_card
GROUP BY account_role, card_type
ORDER BY account_role, card_type;

-- 7. Pre-loan history. How many loans have no transactions before the loan date?
--    These loans have NULL average balance and must be handled in the analysis.
SELECT COUNT(*) FILTER (WHERE pre_loan_trans_count = 0) AS loans_without_history,
       MIN(account_age_days_at_loan) AS min_account_age_days,
       ROUND(AVG(account_age_days_at_loan)) AS avg_account_age_days
FROM bank_dev.fact_loans;
