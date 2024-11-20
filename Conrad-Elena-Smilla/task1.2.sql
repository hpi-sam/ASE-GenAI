WITH KnownPeople AS (
    -- Get all known people for each message creator (direct friends and friends of friends)
    SELECT
        k1.k_person1id AS creator,
        k2.k_person2id AS known_person
    FROM
        knows k1
    JOIN
        knows k2 ON k1.k_person2id = k2.k_person1id

    UNION

    SELECT
        k1.k_person2id AS creator,
        k1.k_person1id AS known_person
    FROM
        knows k1
),
MessageLikes AS (
    -- Count total likes per message and filter messages with more than 20 likes
    SELECT
        l.l_messageid,
        COUNT(l.l_personid) AS total_likes
    FROM
        likes l
    GROUP BY
        l.l_messageid
    HAVING
        COUNT(l.l_personid) >= 20
),
ForeignLikes AS (
    -- Count foreign likes per message
    SELECT
        l.l_messageid,
        COUNT(l.l_personid) AS foreign_likes
    FROM
        likes l
    JOIN
        message m ON l.l_messageid = m.m_messageid
    LEFT JOIN
        KnownPeople kp ON kp.creator = m.m_creatorid AND kp.known_person = l.l_personid
    WHERE
        kp.known_person IS NULL
    GROUP BY
        l.l_messageid
),
FilteredMessages AS (
    -- Filter messages longer than 100 characters, join with likes data, and ensure at least half of the likes are foreign
    SELECT
        m.m_messageid,
        ml.total_likes,
        fl.foreign_likes
    FROM
        message m
    JOIN
        MessageLikes ml ON m.m_messageid = ml.l_messageid
    JOIN
        ForeignLikes fl ON m.m_messageid = fl.l_messageid
    WHERE
        m.m_length > 100
        AND fl.foreign_likes >= (ml.total_likes / 2)
)
-- Final result: Calculate the ratio of foreign likes and sort
SELECT
    m_messageid,
    total_likes,
    foreign_likes,
    CAST(foreign_likes AS DECIMAL) / total_likes AS foreign_like_ratio
FROM
    FilteredMessages
ORDER BY
    foreign_like_ratio DESC;
