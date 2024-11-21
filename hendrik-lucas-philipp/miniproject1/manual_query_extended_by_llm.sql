WITH messages AS (
    SELECT
        message.m_messageid,
        message.m_creatorid
    FROM
        message
        JOIN likes ON message.m_messageid = likes.l_messageid
    WHERE
        message.m_length > 100
    GROUP BY
        message.m_messageid,
        message.m_creatorid
    HAVING
        COUNT(likes.l_messageid) >= 20
),
creator_friends AS (
    SELECT
        k1.k_person1id AS creator_id,
        k1.k_person2id AS person_id
    FROM
        knows AS k1
        JOIN knows AS k2 ON k1.k_person1id = k2.k_person2id
    WHERE
        k2.k_person1id = k1.k_person2id
),
creator_friends_knows AS (
    SELECT
        f.creator_id,
        k.k_person2id
    FROM
        creator_friends AS f
        JOIN knows AS k ON f.person_id = k.k_person1id
),
creator_knows AS (
    SELECT
        m.m_creatorid,
        k.k_person2id
    FROM
        knows AS k
        JOIN messages AS m ON k.k_person1id = m.m_creatorid
),
foreign_likes AS (
    SELECT
        m.m_messageid AS fl_messageid,
        l.l_personid,
        l.l_creationdate
    FROM
        likes AS l
        JOIN messages m ON l.l_messageid = m.m_messageid
        LEFT JOIN creator_knows ck ON ck.m_creatorid = m.m_creatorid AND l.l_personid = ck.k_person2id
        LEFT JOIN creator_friends_knows cfk ON cfk.creator_id = m.m_creatorid AND l.l_personid = cfk.k_person2id
    WHERE
        ck.k_person2id IS NULL
        AND cfk.k_person2id IS NULL
),
foreign_like_counts AS (
    SELECT
        fl.fl_messageid,
        COUNT(*) AS f_like_count
    FROM
        foreign_likes fl
    GROUP BY
        fl.fl_messageid
),
first_foreign_likes AS (
    SELECT
        fl.fl_messageid,
        fl.l_personid,
        fl.l_creationdate,
        ROW_NUMBER() OVER (PARTITION BY fl.fl_messageid ORDER BY fl.l_creationdate) AS rn
    FROM
        foreign_likes fl
),
all_likes AS (
    SELECT
        m.m_messageid AS al_messageid,
        COUNT(l.l_messageid) AS al_count
    FROM
        messages AS m
        JOIN likes AS l ON m.m_messageid = l.l_messageid
    GROUP BY
        m.m_messageid
)
SELECT
    m.m_messageid,
    al.al_count,
    flc.f_like_count,
    p.p_firstname || ' ' || p.p_lastname AS first_foreign_liker_name,
    ffl.l_creationdate AS first_foreign_like_time
FROM
    messages AS m
    JOIN all_likes AS al ON m.m_messageid = al.al_messageid
    JOIN foreign_like_counts AS flc ON m.m_messageid = flc.fl_messageid
    JOIN first_foreign_likes ffl ON m.m_messageid = ffl.fl_messageid AND ffl.rn = 1
    JOIN person p ON ffl.l_personid = p.p_personid
WHERE
    2.0 * flc.f_like_count >= al.al_count
ORDER BY
    (1.0 * flc.f_like_count) / al.al_count DESC;
