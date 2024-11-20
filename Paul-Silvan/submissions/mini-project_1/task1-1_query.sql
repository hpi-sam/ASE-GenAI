select m_messageid, total_likes, foreign_likes
from message
left join lateral (
  select l_messageid, count(*) as foreign_likes
  from likes
  where
    l_personid not in (
      select level1friend.k_person2id
      from knows as level1friend
      where level1friend.k_person1id=m_creatorid) and
    l_personid not in (
      select level2friend.k_person2id as friendfriendid
      from knows as level2friend
      where level2friend.k_person1id in (
        select level1friend.k_person2id
        from knows as level1friend
        where level1friend.k_person1id=m_creatorid))
  group by l_messageid
) fl on message.m_messageid=fl.l_messageid
left join (
  select l_messageid, count(*) as total_likes
  from likes
  group by l_messageid
) tl on message.m_messageid=tl.l_messageid
where m_length>100 and total_likes>19 and foreign_likes>=cast(total_likes AS float)/2
order by (foreign_likes/cast(total_likes as float)) desc;