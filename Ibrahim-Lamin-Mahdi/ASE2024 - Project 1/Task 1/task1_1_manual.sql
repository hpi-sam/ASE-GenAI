-- create table knows (
--    k_person1id bigint not null,
--    k_person2id bigint not null,
--    k_creationdate timestamp with time zone not null
-- );

-- create table likes (
--    l_personid bigint not null,
--    l_messageid bigint not null,
--    l_creationdate timestamp with time zone not null
-- );


-- create table message (
--     m_messageid bigint not null,
--     m_ps_imagefile varchar,
--     m_creationdate timestamp with time zone not null,
--     m_locationip varchar not null,
--     m_browserused varchar not null,
--     m_ps_language varchar,
--     m_content text,
--     m_length int not null,
--     m_creatorid bigint not null,
--     m_locationid bigint not null,
--     m_ps_forumid bigint,
--     m_c_replyof bigint
-- );

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
    SELECT l.l_messageid
    FROM likes l
    INNER JOIN message m ON l.l_messageid = m.m_messageid
    WHERE NOT EXISTS (
        SELECT 1 FROM creator_not_foreign_knows WHERE k_person2id = l.l_personid
    )
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
    ml.foreign_likes_count / ml.likes_count::float AS foreign_likes_ratio
FROM message m
INNER JOIN message_likes ml ON m.m_messageid = ml.m_messageid
WHERE m.m_length > 100
    AND ml.likes_count >= 20
    AND ml.foreign_likes_count::decimal >= ml.likes_count / 2
ORDER BY foreign_likes_ratio DESC;