select like_count.m_messageid, total_likes, foreign_likes from 
    (select count(*) total_likes, m_messageid from (select * from message where m_length > 100) messages 
    inner join likes on messages.m_messageid=likes.l_messageid group by m_messageid) as like_count 
    inner join  
        (select count(*) foreign_likes, m_messageid from  (select * from message where m_length > 100) messages
        inner join likes on messages.m_messageid=likes.l_messageid where 
        l_personid not in (select k_person2id from knows where k_person1id = m_creatorid) and
        l_personid not in (select k2.k_person2id from knows k1, knows k2 where k1.k_person1id = m_creatorid and k1.k_person2id=k2.k_person1id)
        group by m_messageid)
    as foreign_like_count 
    on like_count.m_messageid=foreign_like_count.m_messageid
where like_count.total_likes>=20 and foreign_likes >= total_likes/2 order by ((100*foreign_likes)/(total_likes)) desc;
