WITH message_creator_knows AS (
    SELECT k.k_person2id
    FROM message m
    INNER JOIN knows k ON m.m_creatorid = k.k_person1id
),
creator_knows_knows AS (
    SELECT k.k_person2id
    FROM message_creator_knows ck
    INNER JOIN knows k ON ck.k_person2id = k.k_person1id
),
creator_not_foreign_knows AS (
    SELECT k_person2id FROM message_creator_knows
    UNION ALL
    SELECT k_person2id FROM creator_knows_knows
),
foreign_likes AS (
    SELECT 
        l.l_messageid,
        l.l_personid,
        l.l_creationdate
    FROM likes l
    INNER JOIN message m ON l.l_messageid = m.m_messageid
    WHERE NOT EXISTS (
        SELECT 1 FROM creator_not_foreign_knows WHERE k_person2id = l.l_personid
    )
),
first_foreign_like AS (
    SELECT DISTINCT ON (l_messageid)
        fl.l_messageid,
        fl.l_personid,
        fl.l_creationdate
    FROM foreign_likes fl
    ORDER BY fl.l_messageid, fl.l_creationdate ASC
),
message_likes AS (
    SELECT 
        m.m_messageid,
        COUNT(l.l_messageid) AS likes_count,
        COUNT(fl.l_messageid) AS foreign_likes_count
    FROM message m
    LEFT JOIN likes l ON m.m_messageid = l.l_messageid
    LEFT JOIN foreign_likes fl ON m.m_messageid = fl.l_messageid
    GROUP BY m.m_messageid
)
SELECT 
    m.m_messageid,
    ml.likes_count,
    ml.foreign_likes_count,
    ml.foreign_likes_count / ml.likes_count::float AS foreign_likes_ratio,
    p.p_firstname || ' ' || p.p_lastname AS first_foreign_liker_fullname,
    ffl.l_creationdate AS first_foreign_like_time
FROM message m
INNER JOIN message_likes ml ON m.m_messageid = ml.m_messageid
LEFT JOIN first_foreign_like ffl ON m.m_messageid = ffl.l_messageid
LEFT JOIN person p ON ffl.l_personid = p.p_personid
WHERE m.m_length > 100
    AND ml.likes_count >= 20
    AND ml.foreign_likes_count::decimal >= ml.likes_count / 2
ORDER BY foreign_likes_ratio DESC;
