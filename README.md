# Bank Analytics

An end-to-end BI project on anonymized data from a Czech bank (1993–1998): accounts, clients, transactions, loans, and cards. I load the raw files into PostgreSQL and check them; the next steps are a tested dbt model and a Power BI dashboard on loan risk and client behavior.

## Dataset
The Berka dataset (PKDD'99 Discovery Challenge), prepared by Petr Berka and Marta Sochorová: 8 tables from a Czech bank. Downloaded from [Kaggle](https://www.kaggle.com/datasets/marceloventura/the-berka-dataset) (CC0); table descriptions in the [Guide to the Financial Data Set](https://is.vsfs.cz/publication/1423/en/Guide-to-the-Financial-Data-Set/Berka).

| Table | Rows | Content |
|---|---|---|
| account | 4,500 | Accounts: branch district, statement frequency, opening date |
| client | 5,369 | Clients: birth number (encodes birth date and gender), district |
| disp | 5,369 | Links clients to accounts (owner or user) |
| trans | 1,056,320 | Transactions with the balance after each one |
| standing_order | 6,471 | Standing payment orders (source file order.csv) |
| loan | 682 | Loans: amount, duration, monthly payment, status A–D |
| card | 892 | Cards: junior, classic, gold |
| district | 77 | Demographics per district: population, average salary, unemployment, crime |

## Tools
PostgreSQL, SQL, psql, DBeaver, Git. Next: dbt Core and Power BI.

## Business questions
1. **Which loans go bad, and what do they have in common?** The share of bad loans (status B: finished but not paid back; D: running, client in debt) by loan amount, duration, client age and gender, and district unemployment.
2. **Do clients with bad loans behave differently before they get the loan?** Average balance, negative balances and regularity of incoming payments, using only transactions before the loan date.
3. **Who are the bank's clients, and who holds which card?** Age, gender and district of clients, and how junior, classic and gold card holders differ.
4. **How did activity develop from 1993 to 1998?** Monthly number and volume of transactions by type (credit or withdrawal) and channel (cash or transfer), and the average balance.
5. **Which regions matter most?** Accounts, average balance and bad-loan share by district and region, compared with average salary and unemployment.

Results show associations, not causes. Loan groups are small (682 loans in total), so groups below a minimum size are not compared.

## Data notes
- The files are named .csv but use `;` as the delimiter, and have Windows line endings (CRLF).
- Dates are stored as YYMMDD numbers (930101 = 1993-01-01); card.issued also carries a time ('931107 00:00:00'). Both are loaded as they are and converted in staging.
- Codes are in Czech without diacritics (PRIJEM = příjem, incoming payment; VYBER = výběr, withdrawal; UROK = úrok, interest).
- trans.k_symbol (payment type) is missing in 50.7% of rows, in three forms: empty string (481,871), a single space (53,433) and NULL (10).
- One district (Jeseník) has '?' for unemployment and crime in 1995 (columns A12 and A15), so these columns are loaded as text.

## How to reproduce
1. Download the 8 CSV files into `data/raw/` (the folder is in .gitignore).
2. Create the database: `createdb -U postgres bank`
3. From the repo root:
   ```
   psql -U postgres -d bank -f sql/01_create_raw.sql
   psql -U postgres -d bank -f sql/02_load_raw.sql
   ```
4. Run `sql/03_raw_checks.sql` to check row counts and data quality.

## Repo contents
- `sql/01_create_raw.sql`: creates the schema `raw` and the 8 raw tables (re-runnable).
- `sql/02_load_raw.sql`: loads the CSV files with psql `\copy` (re-runnable).
- `sql/03_raw_checks.sql`: row counts, missing values in k_symbol, line-ending check.

## Status
In progress, started November 2026. Done: raw layer loaded and checked. Next: dbt staging and marts with tests, then a Power BI dashboard.
