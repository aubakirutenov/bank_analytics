-- Every code used in staging must have a label in seeds/berka_codes.csv.
-- Returns the missing codes; the test passes when it returns 0 rows.

SELECT 'k_symbol' AS code_column, t.k_symbol AS code
FROM {{ ref('stg_trans') }} t
WHERE t.k_symbol IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM {{ ref('berka_codes') }} c
      WHERE c.code_column = 'k_symbol' AND c.code = t.k_symbol
  )

UNION

SELECT 'k_symbol', s.k_symbol
FROM {{ ref('stg_standing_order') }} s
WHERE s.k_symbol IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM {{ ref('berka_codes') }} c
      WHERE c.code_column = 'k_symbol' AND c.code = s.k_symbol
  )

UNION

SELECT 'trans.operation', t.operation
FROM {{ ref('stg_trans') }} t
WHERE t.operation IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM {{ ref('berka_codes') }} c
      WHERE c.code_column = 'trans.operation' AND c.code = t.operation
  )