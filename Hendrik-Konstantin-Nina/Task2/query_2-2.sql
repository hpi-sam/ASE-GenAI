WITH message_likes AS (
    SELECT
        l_messageid,
        COUNT(*) as total_likes,
        m_creatorid
    FROM likes
    JOIN message ON m_messageid = l_messageid
    GROUP BY l_messageid, m_creatorid
    HAVING COUNT(*) >= 20
),
creator_network AS (
    SELECT DISTINCT
        m_creatorid as creator_id,
        k2.k_person2id as network_person
    FROM message_likes
    JOIN knows k1 ON m_creatorid = k1.k_person1id  -- direct friends
    LEFT JOIN knows k2 ON k1.k_person2id = k2.k_person1id  -- friends of friends
),
foreign_likes AS (
    SELECT
        l.l_messageid,
        COUNT(*) as foreign_like_count
    FROM likes l
    JOIN message m ON l.l_messageid = m.m_messageid
    LEFT JOIN creator_network cn
        ON m.m_creatorid = cn.creator_id
        AND l.l_personid = cn.network_person
    WHERE cn.network_person IS NULL
        AND l.l_personid != m.m_creatorid
    GROUP BY l_messageid
),
first_foreign_like AS (
    SELECT DISTINCT ON (l.l_messageid)
        l.l_messageid,
        l.l_personid,
        l.l_creationdate,
        p.p_firstname || ' ' || p.p_lastname as liker_name
    FROM likes l
    JOIN message m ON l.l_messageid = m.m_messageid
    JOIN person p ON l.l_personid = p.p_personid
    LEFT JOIN creator_network cn
        ON m.m_creatorid = cn.creator_id
        AND l.l_personid = cn.network_person
    WHERE cn.network_person IS NULL
        AND l.l_personid != m.m_creatorid
    ORDER BY l.l_messageid, l.l_creationdate
)
SELECT
    m.m_messageid,
    ml.total_likes,
    fl.foreign_like_count,
    CAST(fl.foreign_like_count AS FLOAT) / ml.total_likes as foreign_ratio,
    ffl.liker_name as first_foreign_liker,
    ffl.l_creationdate as first_foreign_like_time
FROM message m
JOIN message_likes ml ON m.m_messageid = ml.l_messageid
JOIN foreign_likes fl ON m.m_messageid = fl.l_messageid
JOIN first_foreign_like ffl ON m.m_messageid = ffl.l_messageid
WHERE LENGTH(m.m_content) > 100
    AND fl.foreign_like_count >= ml.total_likes/2.0
ORDER BY foreign_ratio DESC;