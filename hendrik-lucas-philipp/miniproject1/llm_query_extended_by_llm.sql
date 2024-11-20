WITH message_likes AS (
    SELECT
        m.m_messageid,
        m.m_creatorid,
        COUNT(DISTINCT l.l_personid) AS total_likes
    FROM
        message m
        JOIN likes l ON m.m_messageid = l.l_messageid
    WHERE
        m.m_length > 100
    GROUP BY
        m.m_messageid,
        m.m_creatorid
    HAVING
        COUNT(DISTINCT l.l_personid) >= 20
),
known_people AS (
    -- The creator themselves
    SELECT
        m.m_creatorid AS c_id,
        m.m_creatorid AS known_person_id
    FROM
        message_likes m
    UNION
    -- The creator's friends
    SELECT
        m.m_creatorid AS c_id,
        k1.k_person2id AS known_person_id
    FROM
        message_likes m
        JOIN knows k1 ON k1.k_person1id = m.m_creatorid
    UNION
    -- Friends of the creator's friends
    SELECT
        m.m_creatorid AS c_id,
        k2.k_person2id AS known_person_id
    FROM
        message_likes m
        JOIN knows k1 ON k1.k_person1id = m.m_creatorid
        JOIN knows k2 ON k2.k_person1id = k1.k_person2id
),
likes_with_foreign_flag AS (
    SELECT
        ml.m_messageid,
        ml.total_likes,
        l.l_personid,
        l.l_creationdate,
        CASE WHEN kp.known_person_id IS NULL THEN 1 ELSE 0 END AS is_foreign
    FROM
        message_likes ml
        JOIN likes l ON l.l_messageid = ml.m_messageid
        LEFT JOIN known_people kp ON kp.c_id = ml.m_creatorid AND kp.known_person_id = l.l_personid
),
aggregated_likes AS (
    SELECT
        m_messageid,
        total_likes,
        SUM(is_foreign) AS foreign_likes
    FROM
        likes_with_foreign_flag
    GROUP BY
        m_messageid,
        total_likes
    HAVING
        SUM(is_foreign) * 2 >= total_likes
),
foreign_likes AS (
    SELECT
        l.m_messageid,
        l.l_personid,
        l.l_creationdate
    FROM
        likes_with_foreign_flag l
    WHERE
        l.is_foreign = 1
),
first_foreign_like AS (
    SELECT
        fl.m_messageid,
        fl.l_personid,
        fl.l_creationdate,
        ROW_NUMBER() OVER (PARTITION BY fl.m_messageid ORDER BY fl.l_creationdate) AS rn
    FROM
        foreign_likes fl
),
first_foreign_liker AS (
    SELECT
        ffl.m_messageid,
        p.p_firstname || ' ' || p.p_lastname AS full_name,
        ffl.l_creationdate
    FROM
        first_foreign_like ffl
        JOIN person p ON p.p_personid = ffl.l_personid
    WHERE
        ffl.rn = 1
)
SELECT
    al.m_messageid,
    al.total_likes,
    al.foreign_likes,
    ffl.full_name AS first_foreign_liker_name,
    ffl.l_creationdate AS first_foreign_like_time
FROM
    aggregated_likes al
    LEFT JOIN first_foreign_liker ffl ON ffl.m_messageid = al.m_messageid
ORDER BY
    CAST(al.foreign_likes AS FLOAT) / al.total_likes DESC;
