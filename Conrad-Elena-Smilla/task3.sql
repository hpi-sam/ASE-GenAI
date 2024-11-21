EXPLAIN
SELECT 
    like_count.m_messageid, 
    total_likes, 
    foreign_likes, 
    first_foreign_person.p_firstname || ' ' || first_foreign_person.p_lastname AS first_foreign_person_name
FROM 
    (SELECT 
         COUNT(*) AS total_likes, 
         m_messageid 
     FROM 
         (SELECT * FROM message WHERE m_length > 100) messages 
     INNER JOIN 
         likes ON messages.m_messageid = likes.l_messageid 
     GROUP BY 
         m_messageid) AS like_count 
INNER JOIN  
    (SELECT DISTINCT ON (m_messageid) 
         m_messageid, 
         COUNT(*) OVER (PARTITION BY m_messageid) AS foreign_likes, 
         l_personid AS first_foreign_person_id
     FROM  
         (SELECT * FROM message WHERE m_length > 100) messages
     INNER JOIN 
         likes ON messages.m_messageid = likes.l_messageid 
     WHERE 
         l_personid NOT IN (SELECT k_person2id FROM knows WHERE k_person1id = m_creatorid) 
         AND l_personid NOT IN (SELECT k2.k_person2id 
                                FROM knows k1, knows k2 
                                WHERE k1.k_person1id = m_creatorid 
                                  AND k1.k_person2id = k2.k_person1id)
     ORDER BY 
         m_messageid, l_creationdate) AS foreign_like_count 
ON 
    like_count.m_messageid = foreign_like_count.m_messageid
INNER JOIN 
    person AS first_foreign_person 
ON 
    foreign_like_count.first_foreign_person_id = first_foreign_person.p_personid
WHERE 
    like_count.total_likes >= 20 
    AND foreign_likes >= total_likes / 2 
ORDER BY 
    ((100 * foreign_likes) / (total_likes)) DESC;
    