SELECT
    COUNT(*) FILTER (WHERE k_symbol IS NULL) AS null_cnt,
    COUNT(*) FILTER (WHERE k_symbol = '') AS empty_cnt,
    COUNT(*) FILTER (WHERE k_symbol IS NOT NULL AND k_symbol <> '') AS filled_cnt
FROM raw.trans;

SELECT k_symbol, COUNT(*) FROM raw.trans GROUP BY k_symbol ORDER BY 2 DESC;

SELECT count(*) FROM raw.trans WHERE account LIKE '%' || chr(13);

SELECT length(k_symbol), COUNT(*) FROM raw.trans WHERE k_symbol IN ('', ' ') GROUP BY 1;