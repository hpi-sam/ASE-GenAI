# LLM Chat History

Usage of Copilot Chat with the Claude 3.5 Sonnet (Preview) model.

**Prompt**:

For the given tables, write a query for the following task:

Find all messages longer than 100 characters that have been liked by at least 20 people. Only consider messages where at least half of the likes are from people that are foreign to the message’s creator, with a foreigner being a person that neither the creator nor any of their friends know. For each message, return the message’s id, the total number of likes and the number of foreign likes. Sort the returned messages by the ratio of foreign likes from highest to lowest.

_Reference Files: create_tables.sql_

**Response**:

Let me break this down step by step:

1. First, find messages longer than 100 chars
2. Count likes per message (need at least 20)
3. For each message:
   - Find creator's friends (from knows table)
   - Find people who know creator's friends
   - Identify foreign likes (people not in above groups)
   - Calculate ratio of foreign likes
4. Filter for messages where foreign likes ≥ total likes/2
5. Sort by foreign likes ratio

```sql
WITH message_likes AS (
    SELECT
        l_messageid,
        COUNT(*) as total_likes,
        m_creatorid
    FROM likes
    JOIN message ON m_messageid = l_messageid
    GROUP BY l_messageid, m_creatorid
    HAVING COUNT(*) >= 20
),
creator_network AS (
    SELECT DISTINCT
        m_creatorid as creator_id,
        k2.k_person2id as network_person
    FROM message_likes
    JOIN knows k1 ON m_creatorid = k1.k_person1id  -- direct friends
    LEFT JOIN knows k2 ON k1.k_person2id = k2.k_person1id  -- friends of friends
),
foreign_likes AS (
    SELECT
        l.l_messageid,
        COUNT(*) as foreign_like_count
    FROM likes l
    JOIN message m ON l.l_messageid = m.m_messageid
    LEFT JOIN creator_network cn
        ON m.m_creatorid = cn.creator_id
        AND l.l_personid = cn.network_person
    WHERE cn.network_person IS NULL
        AND l.l_personid != m.m_creatorid
    GROUP BY l_messageid
)
SELECT
    m.m_messageid,
    ml.total_likes,
    fl.foreign_like_count,
    CAST(fl.foreign_like_count AS FLOAT) / ml.total_likes as foreign_ratio
FROM message m
JOIN message_likes ml ON m.m_messageid = ml.l_messageid
JOIN foreign_likes fl ON m.m_messageid = fl.l_messageid
WHERE LENGTH(m.m_content) > 100
    AND fl.foreign_like_count >= ml.total_likes/2.0
ORDER BY foreign_ratio DESC;
```
