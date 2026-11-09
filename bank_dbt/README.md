# bank_dbt

dbt project for the Berka dataset: real, anonymized data from a Czech bank, 1993–1998. It turns the raw tables in PostgreSQL into cleaned, typed and tested staging models, which are the base for the marts and the loan-risk analysis.

**Status (Nov 9, 2026):** staging layer complete. 8 staging views, 1 seed, 62 tests. Marts are next.

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

Expected result: `PASS=69 WARN=2 ERROR=0 TOTAL=71`. The two warnings are a known gap in the source (see Data notes).

## Models

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

## Open questions

- 21,881 transactions have an empty partner bank but a filled partner account: to investigate before the marts use these columns.

## Next steps

1. Marts: dimensions for account, client and district; facts for transactions and loans.
2. Loan-risk analysis using only transactions before each loan's date, to avoid data leakage.
3. Power BI report on top of the marts.
