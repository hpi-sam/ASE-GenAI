-- Written by Robert
-- Runs for about 30s
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

-- Written by ChatGPT
-- Runs for about 90s - 120s (slower than Robert's query)
WITH TotalLikes AS (
    SELECT 
        m.m_messageid,
        COUNT(l.l_personid) AS total_likes
    FROM 
        message m
    JOIN 
        likes l ON m.m_messageid = l.l_messageid
    WHERE 
        m.m_length > 100
    GROUP BY 
        m.m_messageid
    HAVING 
        COUNT(l.l_personid) >= 20
),
ForeignLikes AS (
    SELECT 
        l.l_messageid,
        COUNT(l.l_personid) AS foreign_likes
    FROM 
        likes l
    JOIN 
        message m ON l.l_messageid = m.m_messageid
    LEFT JOIN 
        knows k ON (l.l_personid = k.k_person1id AND k.k_person2id = m.m_creatorid)
                  OR (l.l_personid = k.k_person2id AND k.k_person1id = m.m_creatorid)
    LEFT JOIN 
        knows k2 ON k.k_person1id = m.m_creatorid OR k.k_person2id = m.m_creatorid
    WHERE 
        k.k_person1id IS NULL AND k.k_person2id IS NULL
        AND k2.k_person1id IS NULL AND k2.k_person2id IS NULL
    GROUP BY 
        l.l_messageid
)
SELECT 
    t.m_messageid,
    t.total_likes,
    f.foreign_likes
FROM 
    TotalLikes t
JOIN 
    ForeignLikes f ON t.m_messageid = f.l_messageid
WHERE 
    f.foreign_likes >= t.total_likes / 2
ORDER BY 
    CAST(f.foreign_likes AS FLOAT) / t.total_likes DESC;

