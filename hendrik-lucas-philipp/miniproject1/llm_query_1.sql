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
friends AS (
    SELECT
        k1.k_person1id AS person_id,
        k1.k_person2id AS friend_id
    FROM
        knows k1
        JOIN knows k2 ON k1.k_person1id = k2.k_person2id
        AND k1.k_person2id = k2.k_person1id
    WHERE
        k1.k_person1id IN (SELECT m_creatorid FROM message_likes)
),
known_people AS (
    SELECT
        m.m_creatorid AS c_id,
        m.m_creatorid AS known_person_id
    FROM
        message_likes m
    UNION
    SELECT
        k.k_person1id AS c_id,
        k.k_person2id AS known_person_id
    FROM
        knows k
    WHERE
        k.k_person1id IN (SELECT m_creatorid FROM message_likes)
    UNION
    SELECT
        f.person_id AS c_id,
        k.k_person2id AS known_person_id
    FROM
        friends f
        JOIN knows k ON k.k_person1id = f.friend_id
),
likes_with_known AS (
    SELECT
        m.m_messageid,
        m.total_likes,
        l.l_personid,
        CASE
            WHEN kp.known_person_id IS NULL THEN 1
            ELSE 0
        END AS is_foreign
    FROM
        message_likes m
        JOIN likes l ON l.l_messageid = m.m_messageid
        LEFT JOIN known_people kp ON kp.c_id = m.m_creatorid
        AND kp.known_person_id = l.l_personid
)
SELECT
    m_messageid,
    total_likes,
    foreign_likes
FROM
    (
        SELECT
            m_messageid,
            total_likes,
            SUM(is_foreign) AS foreign_likes,
            CAST(SUM(is_foreign) AS FLOAT) / total_likes AS foreign_ratio
        FROM
            likes_with_known
        GROUP BY
            m_messageid,
            total_likes
        HAVING
            SUM(is_foreign) * 2 >= total_likes
    ) sub
ORDER BY
    foreign_ratio DESC;

