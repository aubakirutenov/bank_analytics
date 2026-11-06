TRUNCATE raw.account, raw.card, raw.client, raw.disp, raw.district, raw.loan, raw.standing_order, raw.trans;

\copy raw.account FROM 'data/raw/account.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';')
\copy raw.card FROM 'data/raw/card.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';')
\copy raw.client FROM 'data/raw/client.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';')
\copy raw.disp FROM 'data/raw/disp.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';')
\copy raw.district FROM 'data/raw/district.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';')
\copy raw.loan FROM 'data/raw/loan.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';')
\copy raw.standing_order FROM 'data/raw/order.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';')
\copy raw.trans FROM 'data/raw/trans.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';')
