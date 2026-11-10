# bank_dbt

dbt project for the Berka dataset: real, anonymized data from a Czech bank, 1993–1998. It turns the raw tables in PostgreSQL into cleaned, typed and tested staging models, and those into a tested star schema for the loan-risk analysis and Power BI.

**Status (Nov 10, 2026):** staging and marts complete. 8 staging views, 7 mart tables, 1 seed, 120 tests. Power BI dashboard published (see the main README).

## Stack

- PostgreSQL (database `bank`; raw tables in schema `raw`, dbt output in `bank_dev`)
- dbt Core 1.12 with dbt-postgres 1.11
- Raw layer loaded by the SQL scripts in the repository root (`sql/01_create_raw.sql`, `sql/02_load_raw.sql`, `sql/03_raw_checks.sql`)

## How to run

The connection profile `bank_analytics` lives in `~/.dbt/profiles.yml`, outside the repository, so no credentials reach Git.

```bash
cd bank_dbt
dbt debug    # checks the connection and the project
dbt build    # loads the seed, builds every model and runs every test
```

Expected result: `PASS=134 WARN=2 ERROR=0 TOTAL=136`. The two warnings are a known gap in the source (see Data notes).

## Star schema (marts)

```
                    dim_date
                       |
  dim_client --- fact_transactions --- dim_account
       \               |                  /
        \--------- fact_loans ----------/
                       |
                  dim_district
```

Both facts carry the keys of every dimension they use (account, owner, district, date), so each dimension connects directly to the facts and no dimension connects to another one.

| Table | Grain | Rows | Key decisions |
| --- | --- | --- | --- |
| fact_transactions | one row per transaction | 1,056,320 | `signed_amount` (+ money in, − money out); `channel` = bank / cash / transfer / card; English labels from the seed |
| fact_loans | one row per loan | 682 | `is_bad` (1 for status B or D, so AVG = bad-loan rate); owner's age at the loan; account history **before** the loan only (no data leakage) |
| dim_account | one row per account | 4,500 | owner as a column instead of a bridge table, because every account has exactly one owner |
| dim_client | one row per client | 5,369 | age at 1998-12-31 and age group; role on the account; card (a client has at most one) |
| dim_district | one row per district | 77 | demographics plus the change in unemployment 1995–1996 |
| agg_monthly_activity | one row per month, district, channel and direction | 33,813 | transaction summary for the Power BI activity charts; a test checks it still contains every transaction |
| dim_date | one row per day | from the first to the last date in the data | year, quarter, month, weekday |

Checked in `sql/04_mart_checks.sql` against the raw tables, independently of dbt: row counts and money totals match; 76 of 682 loans (11.1 %) are bad; all 892 cards belong to account owners; every loan has transaction history before it (shortest 102 days, average 398).

## Staging models

| Model | Source table | Rows | What staging does |
| --- | --- | --- | --- |
| stg_account | account | 4,500 | YYMMDD integer date → `opened_date` |
| stg_trans | trans | 1,056,320 | date → `trans_date`; empty codes → NULL; `bank`/`account` → `partner_bank`/`partner_account` |
| stg_loan | loan | 682 | date → `granted_date`; `payments` → `monthly_instalment` |
| stg_client | client | 5,369 | `birth_number` decoded into `gender` and `birth_date` |
| stg_disp | disp | 5,369 | `type` → `disp_type` |
| stg_card | card | 892 | text date with a time part → `issued_date`; `type` → `card_type` |
| stg_district | district | 77 | A1–A16 renamed to readable names; `'?'` → NULL |
| stg_standing_order | standing_order | 6,471 | `bank_to`/`account_to` → `partner_bank`/`partner_account`; empty codes → NULL |
| berka_codes (seed) | seeds/berka_codes.csv | 21 | Czech codes with Czech and English labels |

All staging models are views: they are read only by dbt and stay one-to-one with their source table (same row count, no joins, no business logic).

## Tests

Marts:

- **Grain:** `assert_marts_keep_staging_grain` checks that every mart has the same row count as its staging model (catches fan-out and dropped rows).
- **Money:** `assert_money_totals_match_staging` checks that total and net transaction amounts and the total loan amount match staging.
- **Dates:** `assert_loans_granted_after_account_opened` checks that no loan predates its account.
- **Summary:** `assert_monthly_activity_matches_fact` checks that the monthly summary has the same transaction count and amount as fact_transactions.
- **Keys and relationships:** every fact key points to an existing dimension row; `owner_client_id` is not null and unique in dim_account (one owner per account, one account per owner).

Staging:

- **Keys:** every primary key is unique and not null.
- **Relationships:** transactions, loans, dispositions and standing orders link to accounts; dispositions link to clients; cards link to dispositions; accounts and clients link to districts. 0 orphans.
- **Accepted values** on every code column (transaction type, statement frequency, loan status, gender, disposition type, card type, region, standing-order code).
- **Singular test** `tests/assert_codes_have_labels.sql`: every code used in staging has a label in the seed.
- Tests chosen from the data: one card per disposition and one loan per account were checked with `COUNT(*) = COUNT(DISTINCT key)` before adding `unique`.

## Data notes

- **Dates** are YYMMDD integers in the source. They are converted with an explicit century (`TO_DATE('19' || date::text, 'YYYYMMDD')`) so the database never guesses it.
- **Birth number:** text in YYMMDD form, where women have 50 added to the month. All 5,369 values have 6 characters. Result: 2,724 men (born 1911–1986) and 2,645 women (born 1914–1987). The youngest clients were about 11 years old when the data ends, so ages are computed as of 1998-12-31, not today.
- **Empty codes:** `k_symbol` in transactions is missing in 50.7 % of rows, stored in three forms (`''`, `' '`, NULL). `NULLIF(TRIM(col), '')` turns all of them into NULL. Standing orders have 1,379 orders without a code.
- **District 69 (Jeseník)** has no 1995 unemployment rate and no 1995 crime count (`'?'` in the source). Both become NULL; their `not_null` tests use `severity: warn`, so the gap is documented without failing the build.
- **Generic column names** (`type`) get the entity as a prefix (`disp_type`, `card_type`), so they don't collide when marts join the tables. Transactions and standing orders use the same names for the partner bank and account.
- **Checked facts:** every account has exactly one owner (4,500 owners + 869 disponents = 5,369 clients, each client appears once); loan status A 203, B 31, C 403, D 45, so 76 of 682 loans (11.1 %) are bad (B + D).

- **Channel:** the source books statement fees (SLUZBY, 155,832 rows) and penalty interest (SANKC. UROK, 1,577 rows) with operation VYBER (cash withdrawal), although no cash moves. The channel CASE checks these codes first, so they count as `bank`, not `cash`. The first version got this wrong; the tests passed, and the error was found by checking the channel breakdown against the data.

## Open questions

- 21,881 transactions have an empty partner bank but a filled partner account: to investigate before using these columns.
- 2,811 SIPO and 23 POJISTNE payments are booked as cash withdrawals (VYBER); they stay in `cash`, because the source gives no other information.

## Next steps

1. Deeper loan-risk analysis on the pre-loan columns of fact_loans (average balance, monthly income).
