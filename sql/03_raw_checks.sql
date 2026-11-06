-- k_symbol by kind of value: NULL 10, '' 481,871, filled 574,439 (sum = 1,056,320 rows)
SELECT
    COUNT(*) FILTER (WHERE k_symbol IS NULL) AS null_cnt,
    COUNT(*) FILTER (WHERE k_symbol = '') AS empty_cnt,
    COUNT(*) FILTER (WHERE k_symbol IS NOT NULL AND k_symbol <> '') AS filled_cnt
FROM raw.trans;

-- the "filled" group still hides ' ' (a space): 53,433 rows, so 50.7% of k_symbol is missing
SELECT k_symbol, COUNT(*) FROM raw.trans GROUP BY k_symbol ORDER BY 2 DESC;

-- CRLF check: no '\r' left at the end of the last column. Result: 0
SELECT count(*) FROM raw.trans WHERE account LIKE '%' || chr(13);

-- '' vs ' ': length 0 = 481,871, length 1 = 53,433
SELECT length(k_symbol), COUNT(*) FROM raw.trans WHERE k_symbol IN ('', ' ') GROUP BY 1;

-- Row counts after the load (all match the source): account 4,500, card 892, client 5,369, disp 5,369,
-- district 77, loan 682, standing_order 6,471, trans 1,056,320
SELECT 'account' AS table_name, COUNT(*) AS row_count FROM raw.account
UNION ALL
SELECT 'card', COUNT(*) FROM raw.card
UNION ALL
SELECT 'client', COUNT(*) FROM raw.client
UNION ALL
SELECT 'disp', COUNT(*) FROM raw.disp
UNION ALL
SELECT 'district', COUNT(*) FROM raw.district
UNION ALL
SELECT 'loan', COUNT(*) FROM raw.loan
UNION ALL
SELECT 'standing_order', COUNT(*) FROM raw.standing_order
UNION ALL
SELECT 'trans', COUNT(*) FROM raw.trans;