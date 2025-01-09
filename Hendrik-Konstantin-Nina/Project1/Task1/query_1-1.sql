select m.m_messageid                                               as message_id,
       count(l.l_messageid)                                        as total_likes,
       sum(case when kp.known_person_id is null then 1 else 0 end) as foreign_like_count
from message m
         join
     likes l on m.m_messageid = l.l_messageid
         left join (select distinct k1.k_person1id as creator_id,
                                    k2.k_person2id as known_person_id
                    from knows k1
                             left join
                         knows k2 on k1.k_person2id = k2.k_person1id
                    union
                    select distinct k1.k_person1id,
                                    k1.k_person2id
                    from knows k1) kp
                   on
                       m.m_creatorid = kp.creator_id
                           and l.l_personid = kp.known_person_id
where m.m_length > 100
group by m.m_messageid
having count(l.l_messageid) >= 20
   and sum(case when kp.known_person_id is null then 1 else 0 end) >= count(l.l_messageid) / 2
order by cast(sum(case when kp.known_person_id is null then 1 else 0 end) as float) / count(l.l_messageid) desc;