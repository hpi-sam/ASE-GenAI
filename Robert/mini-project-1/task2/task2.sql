-- Written by Robert Richter
select mid, foreign_likes, total_likes, min_date, p2.p_firstname || ' ' || p2.p_lastname as name
from (
	select mid, foreign_likes, total_likes, min_date, l_personid 
		from (
		select l.mid, foreign_likes, total_likes, min_date
		from (
			select COUNT(m.l_personid) as foreign_likes, m.m_messageid as mid, MIN(m.l_creationdate) as min_date
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
		where total_likes >= 20 and foreign_likes * 2 >= total_likes
	) r join likes l2
	on r.mid = l2.l_messageid and r.min_date = l2.l_creationdate
) r2 join person p2
on r2.l_personid = p2.p_personid
order by (cast(foreign_likes as float) / cast(total_likes as float)) desc;

-- Written by ChatGPT
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
        l.l_personid,
        l.l_creationdate,
        COUNT(*) OVER (PARTITION BY l.l_messageid) AS foreign_likes,
        ROW_NUMBER() OVER (PARTITION BY l.l_messageid ORDER BY l.l_creationdate) AS rn
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
)
SELECT 
    t.m_messageid,
    t.total_likes,
    f.foreign_likes,
    p.p_firstname || ' ' || p.p_lastname AS first_foreigner_name,
    f.l_creationdate AS first_like_time
FROM 
    TotalLikes t
JOIN 
    (SELECT * FROM ForeignLikes WHERE rn = 1) f ON t.m_messageid = f.l_messageid
JOIN 
    person p ON f.l_personid = p.p_personid
WHERE 
    f.foreign_likes >= t.total_likes / 2
ORDER BY 
    CAST(f.foreign_likes AS FLOAT) / t.total_likes DESC;


