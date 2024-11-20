EXPLAIN ANALYZE
WITH
    message_likes AS (
        SELECT
            l_messageid AS message_id,
            COUNT(*) AS total_likes
        FROM
            likes
        GROUP BY
            l_messageid
        HAVING
            COUNT(*) >= 20
    ),
    creator_friends AS (
        -- Direct friends of the message creator
        SELECT
            k_person2id AS friend_id,
            k_person1id AS creator_id
        FROM
            knows
    ),
    friends_of_friends AS (
        -- Friends of the creator's friends
        SELECT
            k.k_person2id AS person_id,
            cf.creator_id
        FROM
            knows k
        JOIN creator_friends cf ON k.k_person1id = cf.friend_id
    ),
    extended_network AS (
        -- Union of direct friends and friends of friends
        SELECT
            friend_id AS person_id,
            creator_id
        FROM
            creator_friends
        UNION
        SELECT
            person_id,
            creator_id
        FROM
            friends_of_friends
    ),
    foreign_likes AS (
        SELECT
            l.l_messageid AS message_id,
            l.l_personid AS foreign_person_id,
            l.l_creationdate AS like_time
        FROM
            likes l
        JOIN message m ON l.l_messageid = m.m_messageid
        LEFT JOIN extended_network en ON en.person_id = l.l_personid
            AND en.creator_id = m.m_creatorid
        WHERE
            en.person_id IS NULL -- The liker is not in the extended network of the creator
    ),
    first_foreign_likes AS (
        SELECT DISTINCT ON (fl.message_id)
            fl.message_id,
            fl.foreign_person_id,
            fl.like_time
        FROM
            foreign_likes fl
        ORDER BY
            fl.message_id, fl.like_time ASC
    ),
    foreign_like_counts AS (
        SELECT
            fl.message_id,
            COUNT(*) AS foreign_likes
        FROM
            foreign_likes fl
        GROUP BY
            fl.message_id
    ),
    filtered_messages AS (
        SELECT
            ml.message_id,
            ml.total_likes,
            flc.foreign_likes,
            ffl.foreign_person_id,
            ffl.like_time AS first_foreign_like_time
        FROM
            message_likes ml
        JOIN foreign_like_counts flc ON ml.message_id = flc.message_id
        JOIN first_foreign_likes ffl ON ml.message_id = ffl.message_id
        WHERE
            flc.foreign_likes >= ml.total_likes / 2
    )
SELECT
    fm.message_id,
    fm.total_likes,
    fm.foreign_likes,
    p.p_firstname || ' ' || p.p_lastname AS first_foreign_liker_name,
    fm.first_foreign_like_time
FROM
    filtered_messages fm
JOIN message m ON fm.message_id = m.m_messageid
JOIN person p ON fm.foreign_person_id = p.p_personid
WHERE
    m.m_length > 100
ORDER BY
    (fm.foreign_likes::decimal / fm.total_likes) DESC;
