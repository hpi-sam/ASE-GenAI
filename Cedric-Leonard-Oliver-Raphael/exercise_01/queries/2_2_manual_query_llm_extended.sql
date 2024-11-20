WITH known_people AS (
    SELECT
        k_person1id AS personid,
        k_person2id AS known_personid
    FROM
        public.knows
    UNION
    SELECT
        authorknows.k_person1id AS personid,
        friendknows.k_person2id AS known_personid
    FROM
        public.knows AS authorknows
    JOIN
        public.knows AS friendknows ON friendknows.k_person1id = authorknows.k_person2id
),
message_likes AS (
    SELECT
        m.m_messageid,
        m.m_creatorid,
        COUNT(l.l_personid) AS total_likes,
        COUNT(CASE WHEN kp.known_personid IS NULL THEN 1 END) AS foreign_likes
    FROM
        public.message m
    JOIN
        public.likes l ON l.l_messageid = m.m_messageid
    LEFT JOIN
        known_people kp ON kp.personid = m.m_creatorid AND kp.known_personid = l.l_personid
    WHERE
        m.m_length > 100
    GROUP BY
        m.m_messageid,
        m.m_creatorid
    HAVING
        COUNT(l.l_personid) >= 20 AND
        COUNT(CASE WHEN kp.known_personid IS NULL THEN 1 END)::float / COUNT(l.l_personid) >= 0.5
),
first_foreign_liker AS (
    SELECT
        l.l_messageid,
        l.l_personid,
        l.l_creationdate,
        ROW_NUMBER() OVER (PARTITION BY l.l_messageid ORDER BY l.l_creationdate) AS rn
    FROM
        public.likes l
    JOIN
        message_likes ml ON ml.m_messageid = l.l_messageid
    LEFT JOIN
        known_people kp ON kp.personid = ml.m_creatorid AND kp.known_personid = l.l_personid
    WHERE
        kp.known_personid IS NULL
)
SELECT
    ml.m_messageid AS message,
    ml.total_likes,
    ml.foreign_likes,
    p.p_firstname || ' ' || p.p_lastname AS first_foreign_liker_name,
    ffl.l_creationdate AS first_foreign_like_time
FROM
    message_likes ml
JOIN
    first_foreign_liker ffl ON ffl.l_messageid = ml.m_messageid AND ffl.rn = 1
JOIN
    public.person p ON p.p_personid = ffl.l_personid
ORDER BY
    (ml.foreign_likes::float / ml.total_likes) DESC;
