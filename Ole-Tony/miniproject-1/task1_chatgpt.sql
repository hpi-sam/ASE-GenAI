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
)
-- Final selection sorted by the ratio of foreign likes
SELECT 
    em.message_id,
    em.total_likes,
    em.foreign_likes
FROM EligibleMessages em
ORDER BY CAST(em.foreign_likes AS FLOAT) / em.total_likes DESC;
