select m_messageid as message, count(l_personid) as total_likes, foreign_likes, (p_firstname || ' ' || p_lastname) as first_liker, first_foreign_like_date as like_date
from public.message, public.likes, public.person, LATERAL (
	select count(foreignlikes.l_personid) as foreign_likes from public.likes as foreignlikes where foreignlikes.l_messageid = m_messageid and foreignlikes.l_personid not in (
		(select k_person2id as known_personid from public.knows where k_person1id = m_creatorid)
		UNION
		(select friendknows.k_person2id as known_personid
		from public.knows as authorknows, public.knows as friendknows
		where authorknows.k_person1id = m_creatorid and friendknows.k_person1id = authorknows.k_person2id)
	)
), LATERAL (
	select foreignlikes.l_creationdate as first_foreign_like_date from public.likes as foreignlikes where foreignlikes.l_messageid = m_messageid and foreignlikes.l_personid not in (
		(select k_person2id as known_personid from public.knows where k_person1id = m_creatorid)
		UNION
		(select friendknows.k_person2id as known_personid
		from public.knows as authorknows, public.knows as friendknows
		where authorknows.k_person1id = m_creatorid and friendknows.k_person1id = authorknows.k_person2id)
	)
	ORDER BY foreignlikes.l_creationdate ASC
	LIMIT 1
), LATERAL (
	select foreignlikes.l_personid as first_foreign_personid from public.likes as foreignlikes where foreignlikes.l_messageid = m_messageid and foreignlikes.l_personid not in (
		(select k_person2id as known_personid from public.knows where k_person1id = m_creatorid)
		UNION
		(select friendknows.k_person2id as known_personid
		from public.knows as authorknows, public.knows as friendknows
		where authorknows.k_person1id = m_creatorid and friendknows.k_person1id = authorknows.k_person2id)
	)
	ORDER BY foreignlikes.l_creationdate ASC
	LIMIT 1
)
where m_messageid = l_messageid and m_length > 100 and p_personid = first_foreign_personid
group by m_messageid, foreign_likes, p_firstname || ' ' || p_lastname, first_foreign_like_date
having count(l_personid) >= 20 and (foreign_likes::float / count(l_personid)) >= 0.5
ORDER BY (foreign_likes::float / count(l_personid)) DESC;
