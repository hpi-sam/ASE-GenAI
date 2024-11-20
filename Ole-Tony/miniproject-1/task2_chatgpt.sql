WITH FilteredMessages AS (
    -- Filter messages by length
    SELECT 
        m.m_messageid AS message_id,
        m.m_creatorid AS creator_id
    FROM message m
    WHERE 
        m.m_length > 100
),
LikesWithForeignCheck AS (
    -- Check if each like is from a foreign person
    SELECT 
        l.l_messageid AS message_id,
        l.l_personid AS liker_id,
        l.l_creationdate AS like_date,
        CASE 
            WHEN NOT EXISTS (
                SELECT 1
                FROM knows k1
                WHERE 
                    (k1.k_person1id = l.l_personid AND k1.k_person2id = fm.creator_id)
                    OR (k1.k_person2id = l.l_personid AND k1.k_person1id = fm.creator_id)
            ) 
            AND NOT EXISTS (
                SELECT 1
                FROM knows k2
                WHERE 
                    (k2.k_person1id IN (
                        SELECT k3.k_person2id
                        FROM knows k3
                        WHERE k3.k_person1id = fm.creator_id
                    ) AND k2.k_person2id = l.l_personid)
                    OR (k2.k_person2id IN (
                        SELECT k3.k_person2id
                        FROM knows k3
                        WHERE k3.k_person1id = fm.creator_id
                    ) AND k2.k_person1id = l.l_personid)
            ) THEN 1 ELSE 0
        END AS is_foreign
    FROM likes l
    JOIN FilteredMessages fm ON l.l_messageid = fm.message_id
),
LikesAggregated AS (
    -- Aggregate likes for each message
    SELECT 
        lwfc.message_id,
        COUNT(*) AS total_likes,
        SUM(lwfc.is_foreign) AS foreign_likes
    FROM LikesWithForeignCheck lwfc
    GROUP BY lwfc.message_id
),
EligibleMessages AS (
    -- Filter messages that meet the remaining criteria
    SELECT 
        la.message_id,
        la.total_likes,
        la.foreign_likes
    FROM LikesAggregated la
    WHERE 
        la.total_likes >= 20
        AND la.foreign_likes >= la.total_likes / 2
),
FirstForeignLiker AS (
    -- Identify the first foreign liker for each message
    SELECT DISTINCT ON (lwfc.message_id)
        lwfc.message_id,
        lwfc.liker_id,
        lwfc.like_date
    FROM LikesWithForeignCheck lwfc
    WHERE lwfc.is_foreign = 1
    ORDER BY lwfc.message_id, lwfc.like_date ASC
)
-- Final result combining all required information
SELECT 
    em.message_id,
    em.total_likes,
    em.foreign_likes,
    CONCAT(p.p_firstname, ' ', p.p_lastname) AS first_foreign_liker_name,
    ff.like_date AS first_foreign_like_time
FROM EligibleMessages em
JOIN FirstForeignLiker ff ON em.message_id = ff.message_id
JOIN person p ON ff.liker_id = p.p_personid
ORDER BY CAST(em.foreign_likes AS FLOAT) / em.total_likes DESC;
