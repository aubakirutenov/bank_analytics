-- Drop the raw tables first, so the script can be run again
DROP TABLE IF EXISTS raw.account;
DROP TABLE IF EXISTS raw.trans;
DROP TABLE IF EXISTS raw.card;
DROP TABLE IF EXISTS raw.client;
DROP TABLE IF EXISTS raw.disp;
DROP TABLE IF EXISTS raw.district;
DROP TABLE IF EXISTS raw.loan;
DROP TABLE IF EXISTS raw.standing_order;

CREATE TABLE raw.account (
	account_id  integer,
	district_id integer,
	frequency text,
	date integer
);

CREATE TABLE raw.trans (
	trans_id integer,
	account_id integer,
	date integer,
	type text,
	operation text,
	amount numeric,
	balance numeric,
	k_symbol text,
	bank text,
	account text
);

CREATE TABLE raw.card (
	card_id integer,
	disp_id integer,
	type text,
	issued text -- 'YYMMDD 00:00:00', converted in staging
);

CREATE TABLE raw.client (
	client_id integer,
	birth_number text,
	district_id integer
);

CREATE TABLE raw.disp (
	disp_id integer,
	client_id integer,
	account_id integer,
	type text
);

CREATE TABLE raw.district (
	A1 integer,
	A2 text,
	A3 text,
	A4 integer,
	A5 integer,
	A6 integer,
	A7 integer,
	A8 integer,
	A9 integer,
	A10 numeric,
	A11 integer,
	A12 text, -- '?' for one district (missing), converted in staging
	A13 numeric,
	A14 integer,
	A15 text, -- '?' for one district (missing), converted in staging
	A16 integer
);

CREATE TABLE raw.loan (
	loan_id integer,
	account_id integer,
	date integer,
	amount numeric,
	duration integer,
	payments numeric,
	status text
);

CREATE TABLE raw.standing_order ( -- source file order.csv; "order" is a reserved word
	order_id integer,
	account_id integer,
	bank_to text,
	account_to text,
	amount numeric,
	k_symbol text
);