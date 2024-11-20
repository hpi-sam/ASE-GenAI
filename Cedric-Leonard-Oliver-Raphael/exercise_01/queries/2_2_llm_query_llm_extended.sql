EXPLAIN
WITH message_likes AS (
    -- Step 1: Get messages longer than 100 characters with at least 20 likes
    SELECT
        m.m_messageid,
        m.m_creatorid,
        COUNT(DISTINCT l.l_personid) AS total_likes
    FROM
        message m
    JOIN
        likes l ON l.l_messageid = m.m_messageid
    WHERE
        m.m_length > 100
    GROUP BY
        m.m_messageid,
        m.m_creatorid
    HAVING
        COUNT(DISTINCT l.l_personid) >= 20
),
likers AS (
    -- Step 2: Get all likers for the selected messages, including like creation date
    SELECT
        ml.m_messageid,
        ml.m_creatorid,
        l.l_personid AS liker_id,
        l.l_creationdate
    FROM
        message_likes ml
    JOIN
        likes l ON l.l_messageid = ml.m_messageid
),
connected_likers AS (
    -- Step 3: Find likers connected to the creator within two hops
    SELECT DISTINCT
        l.m_messageid,
        l.liker_id
    FROM
        likers l
    WHERE
        l.liker_id = l.m_creatorid  -- The liker is the creator
    UNION
    -- Direct friends
    SELECT DISTINCT
        l.m_messageid,
        l.liker_id
    FROM
        likers l
    JOIN
        knows k ON (k.k_person1id = l.m_creatorid AND k.k_person2id = l.liker_id)
               OR (k.k_person2id = l.m_creatorid AND k.k_person1id = l.liker_id)
    UNION
    -- Friends of friends
    SELECT DISTINCT
        l.m_messageid,
        l.liker_id
    FROM
        likers l
    JOIN
        knows k1 ON (k1.k_person1id = l.m_creatorid)
    JOIN
        knows k2 ON (k2.k_person1id = k1.k_person2id AND k2.k_person2id = l.liker_id)
    UNION
    SELECT DISTINCT
        l.m_messageid,
        l.liker_id
    FROM
        likers l
    JOIN
        knows k1 ON (k1.k_person2id = l.m_creatorid)
    JOIN
        knows k2 ON (k2.k_person2id = k1.k_person1id AND k2.k_person1id = l.liker_id)
),
foreign_likers AS (
    -- Step 4: List all foreign likers with their like creation dates
    SELECT
        l.m_messageid,
        l.liker_id,
        l.l_creationdate
    FROM
        likers l
    LEFT JOIN
        connected_likers cl ON cl.m_messageid = l.m_messageid AND cl.liker_id = l.liker_id
    WHERE
        cl.liker_id IS NULL  -- Likers not connected within two hops
),
foreign_likes_counts AS (
    -- Step 5: Calculate the number of foreign likes per message
    SELECT
        fl.m_messageid,
        COUNT(DISTINCT fl.liker_id) AS foreign_like_count
    FROM
        foreign_likers fl
    GROUP BY
        fl.m_messageid
),
first_foreign_liker AS (
    -- Step 6: Get the first foreign liker per message
    SELECT
        fl.m_messageid,
        fl.liker_id,
        fl.l_creationdate
    FROM (
        SELECT
            fl.m_messageid,
            fl.liker_id,
            fl.l_creationdate,
            ROW_NUMBER() OVER (PARTITION BY fl.m_messageid ORDER BY fl.l_creationdate ASC) AS rn
        FROM
            foreign_likers fl
    ) fl
    WHERE
        fl.rn = 1
),
person_names AS (
    -- Step 7: Get full names of persons
    SELECT
        p.p_personid,
        p.p_firstname,
        p.p_lastname
    FROM
        person p
)
-- Final Step: Select messages with required details
SELECT
    ml.m_messageid,
    ml.total_likes,
    COALESCE(flc.foreign_like_count, 0) AS foreign_likes,
    CONCAT(pn.p_firstname, ' ', pn.p_lastname) AS first_foreign_liker_name,
    ffl.l_creationdate AS first_foreign_like_time
FROM
    message_likes ml
LEFT JOIN
    foreign_likes_counts flc ON flc.m_messageid = ml.m_messageid
LEFT JOIN
    first_foreign_liker ffl ON ffl.m_messageid = ml.m_messageid
LEFT JOIN
    person_names pn ON pn.p_personid = ffl.liker_id
WHERE
    COALESCE(flc.foreign_like_count, 0) >= ml.total_likes / 2.0
ORDER BY
    (COALESCE(flc.foreign_like_count, 0)::FLOAT / ml.total_likes) DESC;
