-- fact_loans: one row per loan, with its outcome and the account's history
-- before the loan was granted.
-- Grain: one row per loan (682), same as stg_loan. At most one loan per account.
-- Keys to the dimensions: account_id, owner_client_id, district_id, granted_date.
--
-- Main question: which loans go bad, and did those accounts look different
-- before the loan?
--
-- Data leakage rule: the pre-loan columns use ONLY transactions dated before
-- granted_date. Transactions after the loan show the consequences of a bad
-- loan (missed payments, negative balance), not its warning signs, so using
-- them would make the analysis look better than it really is.

WITH pre_loan AS (
    SELECT
        l.loan_id,
        COUNT(*)                                        AS pre_loan_trans_count,
        COUNT(DISTINCT DATE_TRUNC('month', t.trans_date)) AS pre_loan_active_months,
        ROUND(AVG(t.balance), 2)                        AS pre_loan_avg_balance,
        MIN(t.balance)                                  AS pre_loan_min_balance,
        COUNT(*) FILTER (WHERE t.balance < 0)           AS pre_loan_negative_balance_count,
        COALESCE(SUM(t.amount) FILTER (WHERE t.type = 'PRIJEM'), 0) AS pre_loan_credit_total
    FROM {{ ref('stg_loan') }} l
    JOIN {{ ref('stg_trans') }} t
      ON t.account_id = l.account_id
     AND t.trans_date < l.granted_date          -- the leakage rule
    GROUP BY l.loan_id
)

SELECT
    l.loan_id,                                     -- primary key
    l.account_id,
    a.owner_client_id,
    a.district_id,
    l.granted_date,

    -- Loan terms
    l.amount,
    l.duration,                                    -- months
    l.monthly_instalment,

    -- Outcome
    l.status,
    CASE l.status
        WHEN 'A' THEN 'finished, paid back'
        WHEN 'B' THEN 'finished, not paid back'
        WHEN 'C' THEN 'running, OK so far'
        WHEN 'D' THEN 'running, client in debt'
    END AS status_description,
    CASE WHEN l.status IN ('A', 'B') THEN 1 ELSE 0 END AS is_finished,
    -- 1/0 instead of true/false, so AVG(is_bad) is the bad-loan rate.
    CASE WHEN l.status IN ('B', 'D') THEN 1 ELSE 0 END AS is_bad,

    -- Client and account at the moment of the loan
    DATE_PART('year', AGE(l.granted_date, c.birth_date))::int AS owner_age_at_loan,
    l.granted_date - a.opened_date AS account_age_days_at_loan,

    -- Account history before the loan (see the leakage rule above).
    -- COALESCE: an account with no earlier transactions gets 0, not NULL.
    COALESCE(p.pre_loan_trans_count, 0)            AS pre_loan_trans_count,
    COALESCE(p.pre_loan_active_months, 0)          AS pre_loan_active_months,
    p.pre_loan_avg_balance,
    p.pre_loan_min_balance,
    COALESCE(p.pre_loan_negative_balance_count, 0) AS pre_loan_negative_balance_count,
    -- Average money in per active month; NULLIF avoids division by zero.
    ROUND(p.pre_loan_credit_total / NULLIF(p.pre_loan_active_months, 0), 2)
                                                   AS pre_loan_avg_monthly_credit
FROM {{ ref('stg_loan') }} l
JOIN {{ ref('dim_account') }} a ON a.account_id = l.account_id
JOIN {{ ref('dim_client') }}  c ON c.client_id  = a.owner_client_id
LEFT JOIN pre_loan p            ON p.loan_id    = l.loan_id
