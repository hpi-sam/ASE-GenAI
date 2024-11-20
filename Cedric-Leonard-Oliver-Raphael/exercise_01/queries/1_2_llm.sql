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
    -- Step 2: Get all likers for the selected messages
    SELECT
        ml.m_messageid,
        ml.m_creatorid,
        l.l_personid AS liker_id
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
foreign_likes AS (
    -- Step 4: Calculate the number of foreign likes for each message
    SELECT
        l.m_messageid,
        COUNT(DISTINCT l.liker_id) AS foreign_like_count
    FROM
        likers l
    LEFT JOIN
        connected_likers cl ON cl.m_messageid = l.m_messageid AND cl.liker_id = l.liker_id
    WHERE
        cl.liker_id IS NULL  -- Likers not connected within two hops
    GROUP BY
        l.m_messageid
)
-- Step 5: Select messages where at least half of the likes are from foreigners
SELECT
    ml.m_messageid,
    ml.total_likes,
    COALESCE(fl.foreign_like_count, 0) AS foreign_likes
FROM
    message_likes ml
LEFT JOIN
    foreign_likes fl ON fl.m_messageid = ml.m_messageid
WHERE
    COALESCE(fl.foreign_like_count, 0) >= ml.total_likes / 2.0
ORDER BY
    (COALESCE(fl.foreign_like_count, 0)::FLOAT / ml.total_likes) DESC;
