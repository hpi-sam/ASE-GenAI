select m_messageid as message, count(l_personid) as total_likes, foreign_likes
from public.message, public.likes, LATERAL (
	select count(foreignlikes.l_personid) as foreign_likes from public.likes as foreignlikes where foreignlikes.l_messageid = m_messageid and foreignlikes.l_personid not in (
		(select k_person2id as known_personid from public.knows where k_person1id = m_creatorid)
		UNION
		(select friendknows.k_person2id as known_personid
		from public.knows as authorknows, public.knows as friendknows
		where authorknows.k_person1id = m_creatorid and friendknows.k_person1id = authorknows.k_person2id)
	)
)
where m_messageid = l_messageid and m_length > 100
group by m_messageid, foreign_likes
having count(l_personid) >= 20 and (foreign_likes::float / count(l_personid)) >= 0.5
ORDER BY (foreign_likes::float / count(l_personid)) DESC;