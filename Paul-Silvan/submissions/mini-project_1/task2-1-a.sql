select m_messageid, total_likes, foreign_likes,CONCAT(p_firstname, ' ', p_lastname) as first_liker, like_date 
FROM (
select m_messageid, total_likes, foreign_likes, like_date
from message
left join lateral (
  select l_messageid, count(*) as foreign_likes, min(l_creationdate) as like_date
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
where m_length>100 and total_likes>19 and foreign_likes>=cast(total_likes AS float)/2)
join likes ON m_messageid = l_messageid and l_creationdate = like_date
join person ON l_personid = p_personid
order by (foreign_likes/cast(total_likes as float)) desc;
