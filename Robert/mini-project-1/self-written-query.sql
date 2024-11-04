select l.mid, foreign_likes, total_likes
from (
	select COUNT(m.l_personid) as foreign_likes, m.m_messageid as mid
	from (
		select * from message m
		join likes l
		on m.m_messageid = l.l_messageid
	) m
	where m.m_length >= 100 and l_personid in (
		select p.p_personid as pid from person p 
		where p.p_personid not in (
				select k.k_person2id as pid from knows k 
				where k.k_person1id = m.m_creatorid 
			union
				select k.k_person1id as pid from knows k
				where k.k_person2id = m.m_creatorid 
			union
				select m.m_creatorid 
		)
	)
	group by m.m_messageid
) l
join (
	select m.m_messageid as mid, COUNT(l.l_personid) as total_likes
	from message m 
	join likes l 
	on m.m_messageid = l.l_messageid
	group by m.m_messageid
) r
on l.mid = r.mid
where total_likes >= 20 and foreign_likes * 2 >= total_likes;
