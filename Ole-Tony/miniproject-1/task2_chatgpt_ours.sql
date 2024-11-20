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
        l.l_messageid = c.message_id AND l.l_personid = c.person_id
    WHERE
        c.person_id IS NULL
    GROUP BY 
        l.l_messageid
),
FirstForeignLike AS (
    SELECT DISTINCT ON (l.l_messageid)
        l.l_messageid AS message_id,
        l.l_personid AS person_id,
        l.l_creationdate AS like_time
    FROM
        likes AS l
    LEFT JOIN
        Connections AS c
    ON
        l.l_messageid = c.message_id AND l.l_personid = c.person_id
    WHERE
        c.person_id IS NULL
    ORDER BY 
        l.l_messageid, l.l_creationdate ASC
)
SELECT
    fm.m_messageid AS message_id,
    fm.total_likes,
    fl.foreign_likes,
    p.p_firstname || ' ' || p.p_lastname AS foreign_person_fullname,
    ffl.like_time AS first_foreign_like_time
FROM
    FilteredMessages AS fm
JOIN
    ForeignLikes AS fl
ON
    fl.message_id = fm.m_messageid
JOIN
    FirstForeignLike AS ffl
ON
    fm.m_messageid = ffl.message_id
JOIN
    person AS p
ON
    ffl.person_id = p.p_personid
WHERE
    fl.foreign_likes >= fm.total_likes / 2
ORDER BY
    fl.foreign_likes::float / fm.total_likes DESC;
