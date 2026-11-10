# Bank Analytics

An end-to-end BI project on real, anonymized data from a Czech bank (1993–1998): PostgreSQL, a tested dbt star schema, and a Power BI dashboard on loan risk and client activity.

**[Open the dashboard (Power BI)](https://app.powerbi.com/view?r=eyJrIjoiMGE1MDA1MTUtNjA2Ny00MTI2LWFkMmUtYzBhNjI2MDkyYWM1IiwidCI6IjJiNTFhNGIzLTQ0M2YtNDQwNi04Y2E0LTE5MDU2YTc5YTQ0NCIsImMiOjh9)**

## Key findings

1. **Bigger loans go bad more often.** The bad-loan rate rises with the amount: 7.5 % under 100k CZK, 9.4 % at 100–200k, 17.5 % at 200–300k, 20.7 % above 300k. Loans above 200k go bad 2–3× as often as loans under 100k.
2. **An overdraft before the loan is a near-certain warning sign, but a rare one.** All 27 loans on accounts that had a negative balance before the loan went bad (100 %), against 7.5 % for the other 655. The overdrafts came 15 to 404 days before the loan, so this is not data leakage. But only 27 of the 76 bad loans (36 %) had such a warning: an overdraft check alone would miss two thirds of them.
3. **Duration and age are not drivers.** The bad-loan rate is 8.4–12.3 % for every loan duration and 9.6–13.8 % for every age group, with no clear pattern.
4. **Regions differ, but on small numbers.** From 15.8 % (west Bohemia) to 1.6 % (north Bohemia); each region has only 1–18 bad loans, so the ranking is unstable.
5. **The bank grew mostly through new accounts.** Accounts grew about fourfold (1,139 at the end of 1993 → 4,500 by 1997); transactions per year grew from 28,205 (1993) to 322,277 (1998). Cash dominated (41 % of all transactions); card payments were under 1 %.

Results show associations, not causes. 682 loans and 76 bad loans are a small sample.

## Dataset

The Berka dataset (PKDD'99 Discovery Challenge), prepared by Petr Berka and Marta Sochorová: 8 tables from a Czech bank. Downloaded from [Kaggle](https://www.kaggle.com/datasets/marceloventura/the-berka-dataset) (CC0); table descriptions in the [Guide to the Financial Data Set](https://is.vsfs.cz/publication/1423/en/Guide-to-the-Financial-Data-Set/Berka).

| Table | Rows | Content |
|---|---|---|
| account | 4,500 | Accounts: branch district, statement frequency, opening date |
| client | 5,369 | Clients: birth number (encodes birth date and gender), district |
| disp | 5,369 | Links clients to accounts (owner or authorised user) |
| trans | 1,056,320 | Transactions with the balance after each one |
| standing_order | 6,471 | Standing payment orders (source file order.csv) |
| loan | 682 | Loans: amount, duration, monthly payment, status A–D |
| card | 892 | Cards: junior, classic, gold |
| district | 77 | Demographics per district: population, salary, unemployment, crime |

A loan counts as **bad** when its status is B (finished, not paid back) or D (running, client in debt).

## How it is built

```
CSV files ─► PostgreSQL raw ─► dbt staging (8 views) ─► dbt marts (star schema) ─► CSV ─► Power BI
```

1. **Raw layer** (`sql/`): the files are loaded as they are with re-runnable `\copy` scripts and checked against the source row counts.
2. **dbt** (`bank_dbt/`): staging models fix types and codes (YYMMDD dates, the birth number, empty codes); marts build a star schema with `fact_loans`, `fact_transactions`, a monthly activity summary, and dimensions for account, client, district and date. 120 tests: keys, relationships, accepted values, row counts kept from staging, and money totals that match. Details in [bank_dbt/README.md](bank_dbt/README.md).
3. **No data leakage:** the account-history columns in `fact_loans` use only transactions dated before the loan, because later transactions show the result of a bad loan, not its warning signs.
4. **Power BI:** the marts are exported to CSV (`sql/05_export_powerbi.sql`), modelled as a star with single-direction relationships, and every measure was checked against SQL (`sql/06_powerbi_reference.sql`): 682 loans, 76 bad, 11.14 %, and each breakdown match exactly.

## Data quality findings

- **Fees booked as cash withdrawals:** statement fees (155,832 rows) and penalty interest (1,577) carry the operation code for a cash withdrawal, although no cash moves. They are classed as bank entries, not cash. The first model got this wrong; the tests passed, and a check of the channel breakdown against the data found it.
- **Empty codes in three forms:** the payment-type code is missing in 50.7 % of transactions, stored as `''`, `' '` or NULL; staging turns all three into NULL.
- **Birth number:** women have 50 added to the birth month; staging decodes gender and birth date from it.
- **Missing district values:** one district (Jeseník) has `'?'` for 1995 unemployment and crime; they become NULL and are flagged by warning tests instead of failing the build.

## Tools

PostgreSQL, SQL, dbt Core, Power BI, Git, DBeaver.

## How to reproduce

1. Download the 8 CSV files into `data/raw/` (the folder is in .gitignore).
2. Create the database and load the raw layer from the repo root:
   ```
   createdb -U postgres bank
   psql -U postgres -d bank -f sql/01_create_raw.sql
   psql -U postgres -d bank -f sql/02_load_raw.sql
   ```
3. Build and test the models: `cd bank_dbt && dbt build` (expected: 0 errors, 2 warnings for the known Jeseník gap).
4. Export the marts for Power BI: `psql -U postgres -d bank -f sql/05_export_powerbi.sql`.

## Repo contents

- `sql/01_create_raw.sql`, `sql/02_load_raw.sql`, `sql/03_raw_checks.sql`: raw layer, load and checks.
- `sql/04_mart_checks.sql`: validation of the marts against the raw tables, independent of dbt.
- `sql/05_export_powerbi.sql`: CSV export for Power BI.
- `sql/06_powerbi_reference.sql`: reference numbers for every Power BI measure.
- `bank_dbt/`: the dbt project (staging, marts, seed, tests).
