WITH messages AS (SELECT message.m_messageid, message.m_creatorid
                  FROM message,
                       likes
                  WHERE message.m_length > 100
                    AND message.m_messageid = likes.l_messageid
                  GROUP BY message.m_messageid, message.m_creatorid
                  HAVING (COUNT(likes.l_messageid) >= 20)),
     creator_friends AS (SELECT k1.k_person1id as creator_id, k1.k_person2id as person_id
                         FROM knows as k1,
                              knows as k2
                         WHERE k1.k_person1id = k2.k_person2id
                           AND k2.k_person1id = k1.k_person2id),
     creator_friends_knows AS (SELECT f.creator_id, k.k_person2id
                               FROM creator_friends as f,
                                    knows as k
                               WHERE f.person_id = k.k_person1id),
     creator_knows AS (SELECT m.m_creatorid, k.k_person2id
                       FROM knows as k,
                            messages as m
                       WHERE k.k_person1id = m.m_creatorid),
     foreign_likes AS
         (SELECT fl.fl_messageid                                as fl_messageid,
                 fl.fl_like_count                               as fl_like_count,
                 person.p_firstname || ' ' || person.p_lastname as name,
                 fl.creation_date                               as creation_date
          FROM likes,
               person,
               (SELECT m.m_messageid         as fl_messageid,
                       COUNT(l.l_messageid)  as fl_like_count,
                       MIN(l.l_creationdate) as creation_date
                FROM likes as l
                         JOIN messages m ON l.l_messageid = m.m_messageid
                         LEFT JOIN creator_knows ck ON ck.m_creatorid = m.m_creatorid AND l.l_personid = ck.k_person2id
                         LEFT JOIN creator_friends_knows cfk
                                   ON cfk.creator_id = m.m_creatorid AND l.l_personid = cfk.k_person2id
                WHERE m.m_messageid = l.l_messageid
                  AND ck.k_person2id IS NULL
                  AND cfk.k_person2id IS NULL
                GROUP BY m.m_messageid) as fl
          WHERE fl.fl_messageid = likes.l_messageid
            AND likes.l_creationdate = fl.creation_date
            AND likes.l_personid = person.p_personid)
        ,
     all_likes as (SELECT m.m_messageid AS al_messageid, COUNT(l.l_messageid) AS al_count
                   FROM messages AS m,
                        likes AS l
                   WHERE m.m_messageid = l.l_messageid
                   GROUP BY m.m_messageid)
SELECT m.m_messageid, al.al_count, fl.fl_like_count, fl.name, fl.creation_date
FROM messages as m,
     all_likes as al,
     foreign_likes as fl
WHERE m.m_messageid = al.al_messageid
  AND m.m_messageid = fl.fl_messageid
  AND 2.0 * fl.fl_like_count >= al.al_count
ORDER BY 1.0 * fl.fl_like_count / al.al_count DESC;
