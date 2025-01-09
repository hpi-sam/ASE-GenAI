-- Get all friends and friends of friends
WITH KnownRelationships AS (SELECT DISTINCT k1.k_person1id AS person_id,
                                            k2.k_person2id AS known_person_id
                            FROM knows k1
                                     LEFT JOIN knows k2 ON k1.k_person2id = k2.k_person1id
                            UNION
                            SELECT DISTINCT k1.k_person1id,
                                            k1.k_person2id
                            FROM knows k1),
     -- Get all likes from people who are not friends or friends of friends
     ForeignLikes AS (SELECT m.m_messageid,
                             l.l_personid     AS liker_id,
                             l.l_creationdate AS like_date,
                             ROW_NUMBER()        OVER (PARTITION BY m.m_messageid ORDER BY l.l_creationdate) AS rn
                      FROM message m
                               JOIN likes l ON m.m_messageid = l.l_messageid
                               LEFT JOIN KnownRelationships kr
                                         ON m.m_creatorid = kr.person_id AND l.l_personid = kr.known_person_id
                      WHERE kr.known_person_id IS NULL),
     -- ROW_NUMBER() in ForeignLikes is used to get the first foreign liker
     -- return the name and date of the first foreign liker
     FirstForeignLiker AS (SELECT fl.m_messageid,
                                  CONCAT(p.p_firstname, ' ', p.p_lastname) AS first_foreign_liker_name,
                                  fl.like_date                             AS first_foreign_like_date
                           FROM ForeignLikes fl
                                    JOIN person p ON fl.liker_id = p.p_personid
                           WHERE fl.rn = 1),
     -- Collect relevant stats for each message
     MessageStats AS (SELECT m.m_messageid,
                             COUNT(l.l_messageid)                                        AS total_likes,
                             SUM(CASE WHEN kr.known_person_id IS NULL THEN 1 ELSE 0 END) AS foreign_like_count
                      FROM message m
                               JOIN likes l ON m.m_messageid = l.l_messageid
                               LEFT JOIN KnownRelationships kr
                                         ON m.m_creatorid = kr.person_id AND l.l_personid = kr.known_person_id
                      WHERE m.m_length > 100
                      GROUP BY m.m_messageid)
-- Combine the WITH subqueries to final query
SELECT ms.m_messageid AS message_id,
       ms.total_likes,
       ms.foreign_like_count,
       ffl.first_foreign_liker_name,
       ffl.first_foreign_like_date
FROM MessageStats ms
         JOIN FirstForeignLiker ffl ON ms.m_messageid = ffl.m_messageid
WHERE ms.total_likes >= 20
  AND ms.foreign_like_count >= ms.total_likes / 2
ORDER BY CAST(ms.foreign_like_count AS FLOAT) / ms.total_likes DESC;

