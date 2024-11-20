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
    -- Count total likes per message and filter messages with at least 20 likes
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
    -- Identify foreign likes and count them per message
    SELECT
        l.l_messageid,
        l.l_personid,
        l.l_creationdate,
        COUNT(l.l_personid) OVER (PARTITION BY l.l_messageid) AS foreign_likes
    FROM
        likes l
    JOIN
        message m ON l.l_messageid = m.m_messageid
    LEFT JOIN
        KnownPeople kp ON kp.creator = m.m_creatorid AND kp.known_person = l.l_personid
    WHERE
        kp.known_person IS NULL
),
FilteredMessages AS (
    -- Filter messages longer than 100 characters and ensure at least half of the likes are foreign
    SELECT
        m.m_messageid,
        ml.total_likes,
        COUNT(fl.l_personid) AS foreign_likes
    FROM
        message m
    JOIN
        MessageLikes ml ON m.m_messageid = ml.l_messageid
    JOIN
        ForeignLikes fl ON m.m_messageid = fl.l_messageid
    WHERE
        m.m_length > 100
    GROUP BY
        m.m_messageid, ml.total_likes
    HAVING
        COUNT(fl.l_personid) >= (ml.total_likes / 2)
),
FirstForeignLike AS (
    -- Get the first foreign like for each message using ROW_NUMBER
    SELECT
        fl.l_messageid,
        fl.l_personid,
        fl.l_creationdate,
        ROW_NUMBER() OVER (PARTITION BY fl.l_messageid ORDER BY fl.l_creationdate) AS rn
    FROM
        ForeignLikes fl
),
FirstForeignLikerDetails AS (
    -- Retrieve the details of the first foreign liker
    SELECT
        ffl.l_messageid,
        p.p_firstname || ' ' || p.p_lastname AS full_name,
        ffl.l_creationdate AS like_creation_time
    FROM
        FirstForeignLike ffl
    JOIN
        person p ON ffl.l_personid = p.p_personid
    WHERE
        ffl.rn = 1
)
-- Final result: Return message details along with the first foreign liker information
SELECT
    fm.m_messageid,
    fm.total_likes,
    fm.foreign_likes,
    CAST(fm.foreign_likes AS DECIMAL) / fm.total_likes AS foreign_like_ratio,
    ffl.full_name AS first_foreign_liker,
    ffl.like_creation_time
FROM
    FilteredMessages fm
JOIN
    FirstForeignLikerDetails ffl ON fm.m_messageid = ffl.l_messageid
ORDER BY
    foreign_like_ratio DESC;
