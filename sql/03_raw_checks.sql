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
