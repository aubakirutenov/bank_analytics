-- dim_client: one row per client, with age, account role and card.
-- Grain: one row per client (5,369).
--
-- Why the card lives here and not in its own table:
-- every client has exactly one disposition (a link to one account), and every
-- disposition has at most one card. So a client has at most one card, and the
-- card is simply an attribute of the client. If a client ever had two
-- dispositions, the joins below would duplicate the client, and the unique
-- test on client_id would fail.

WITH client_age AS (
    SELECT
        client_id,
        district_id,
        gender,
        birth_date,
        -- Age when the data ends (1998-12-31), not today:
        -- the data is a snapshot of 1993-1998.
        DATE_PART('year', AGE(DATE '1998-12-31', birth_date))::int AS age_at_end_1998
    FROM {{ ref('stg_client') }}
),

client_card AS (
    -- The client's disposition (owner or authorised user of one account)
    -- and the card issued on it, if any.
    SELECT
        d.client_id,
        d.account_id,
        d.disp_type,
        c.card_type,
        c.issued_date AS card_issued_date
    FROM {{ ref('stg_disp') }} d
    LEFT JOIN {{ ref('stg_card') }} c ON c.disp_id = d.disp_id
)

SELECT
    a.client_id,                              -- primary key
    a.gender,
    a.birth_date,
    a.age_at_end_1998,
    CASE
        WHEN a.age_at_end_1998 < 18 THEN 'under 18'
        WHEN a.age_at_end_1998 < 25 THEN '18-24'
        WHEN a.age_at_end_1998 < 35 THEN '25-34'
        WHEN a.age_at_end_1998 < 45 THEN '35-44'
        WHEN a.age_at_end_1998 < 55 THEN '45-54'
        WHEN a.age_at_end_1998 < 65 THEN '55-64'
        ELSE '65+'
    END AS age_group,
    a.district_id,                            -- where the client lives
    cc.account_id,                            -- the client's account
    cc.disp_type AS account_role,             -- OWNER or DISPONENT
    cc.card_type,                             -- classic / junior / gold, NULL = no card
    cc.card_issued_date,
    cc.card_type IS NOT NULL AS has_card
FROM client_age a
LEFT JOIN client_card cc ON cc.client_id = a.client_id
