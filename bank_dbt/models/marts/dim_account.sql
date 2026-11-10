-- dim_account: one row per account, with its owner and statement frequency.
-- Grain: one row per account (4,500).
--
-- Why there is no bridge table between accounts and clients:
-- disp links clients and accounts many-to-many in theory, but the data has
-- exactly one OWNER per account (4,500 owners for 4,500 accounts). So the owner
-- can be stored as a column here (owner_client_id). Authorised users
-- (disponents) are counted, and remain available in dim_client.

WITH owners AS (
    SELECT account_id, client_id AS owner_client_id
    FROM {{ ref('stg_disp') }}
    WHERE disp_type = 'OWNER'
),

disponents AS (
    SELECT account_id, COUNT(*) AS disponent_count
    FROM {{ ref('stg_disp') }}
    WHERE disp_type = 'DISPONENT'
    GROUP BY account_id
),

account_cards AS (
    -- Cards on any disposition of the account (owner's or disponent's).
    SELECT d.account_id, COUNT(*) AS card_count
    FROM {{ ref('stg_disp') }} d
    JOIN {{ ref('stg_card') }} c ON c.disp_id = d.disp_id
    GROUP BY d.account_id
),

frequency_labels AS (
    -- English labels for the Czech statement-frequency codes, from the seed.
    SELECT code, english
    FROM {{ ref('berka_codes') }}
    WHERE code_column = 'account.frequency'
)

SELECT
    a.account_id,                                     -- primary key
    a.district_id,                                    -- branch district
    a.opened_date,
    a.frequency                       AS statement_frequency_code,
    f.english                         AS statement_frequency,
    o.owner_client_id,
    COALESCE(dp.disponent_count, 0)   AS disponent_count,
    COALESCE(dp.disponent_count, 0) > 0 AS has_disponent,
    COALESCE(ac.card_count, 0)        AS card_count
FROM {{ ref('stg_account') }} a
LEFT JOIN owners o            ON o.account_id = a.account_id
LEFT JOIN disponents dp       ON dp.account_id = a.account_id
LEFT JOIN account_cards ac    ON ac.account_id = a.account_id
LEFT JOIN frequency_labels f  ON f.code = a.frequency
