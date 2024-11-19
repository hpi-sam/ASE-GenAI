WITH FilteredMessages AS (
    SELECT 
        m.m_messageid, 
        m.m_creatorid,
        COUNT(l.l_personid) AS total_likes
    FROM 
        message AS m
    JOIN 
        likes AS l 
    ON 
        m.m_messageid = l.l_messageid
    WHERE 
        m.m_length > 100
    GROUP BY 
        m.m_messageid, m.m_creatorid
    HAVING 
        COUNT(l.l_personid) >= 20
),
Friends AS (
    SELECT 
        fm.m_messageid, 
        fm.m_creatorid,
        k.k_person2id AS friend_id
    FROM 
        FilteredMessages AS fm
    JOIN 
        knows AS k 
    ON 
        k.k_person1id = fm.m_creatorid
),
Connections AS (
    SELECT 
    	f.m_messageid AS message_id,
        k.k_person2id AS person_id
    FROM 
        Friends AS f
    JOIN 
        knows AS k 
    ON 
        k.k_person1id = f.friend_id
    UNION 
    SELECT 
    	f.m_messageid AS message_id,
        f.friend_id AS person_id
    FROM 
        Friends AS f
),
ForeignLikes AS (
    SELECT
    	l.l_messageid AS message_id,
    	COUNT(l.l_personid) AS foreign_likes
    FROM
        likes AS l
    LEFT JOIN
    	Connections AS c
    ON
	l.l_messageid = c.message_id AND l.l_personid=c.person_id
    WHERE
    	c.person_id IS NULL
    GROUP BY 
        l.l_messageid
),
RelevantMessages AS (
    SELECT
	fl.message_id,
	fm.total_likes,
	fl.foreign_likes
    FROM
	ForeignLikes AS fl,
	FilteredMessages AS fm
    WHERE
   	fl.message_id=fm.m_messageid AND fl.foreign_likes >= fm.total_likes / 2
),
FirstForeignLikes AS (
    SELECT
        sfl.message_id,
        rm.total_likes,
        rm.foreign_likes,
        sfl.first_liker,
        sfl.like_date
    FROM
	(SELECT DISTINCT ON (l.l_messageid) 
            l.l_messageid AS message_id,
            l.l_personid AS first_liker,
            l.l_creationdate AS like_date
        FROM
            likes l
	LEFT JOIN
	    Connections c 
	ON
	    l.l_messageid = c.message_id 
        AND
            l.l_personid = c.person_id
	WHERE
            c.person_id IS NULL AND
            l.l_messageid IN (SELECT message_id FROM ForeignLikes)
    	ORDER BY
            l.l_messageid, l.l_creationdate
	) AS sfl
    JOIN
        RelevantMessages AS rm
    ON
        sfl.message_id=rm.message_id
)
SELECT
    ffl.message_id,
    ffl.total_likes,
    ffl.foreign_likes,
    CONCAT(p.p_firstname, ' ', p.p_lastname) AS first_liker,
    ffl.like_date
FROM
    FirstForeignLikes AS ffl
JOIN
    person AS p
ON
    ffl.first_liker=p.p_personid
ORDER BY
    foreign_likes::float / total_likes DESC