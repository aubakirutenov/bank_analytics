-- A loan can only be granted on an existing account.
-- A loan dated before its account's opening date would point to a date error
-- in the source or in the date conversion.
-- Returns the broken loans; passes when it returns 0 rows.

SELECT loan_id, account_id, granted_date, account_age_days_at_loan
FROM {{ ref('fact_loans') }}
WHERE account_age_days_at_loan < 0
