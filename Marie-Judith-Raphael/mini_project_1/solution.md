# Mini Project

by Marie, Raphael and Judith

All LLM solutions presented in this mini project have been developed using GPT 4.o from [OpenAI](chat.openai.com)

## Task 1: Query development

Find all messages longer than 100 characters that have been liked by at least 20 people.
Only consider messages where at least half of the likes are from people that are foreign to the message’s creator, with a foreigner being a person that neither the creator nor any of their friends know.
For each message, return the message’s id, the total number of likes and the number of foreign likes. Sort the returned messages by the ratio of foreign likes from highest to lowest.

### 1.1 Manual

**Find all messages longer than 100 characters that have been liked by at least 20
people.**

```sql
SELECT message.m_messageid, COUNT(*) as like_count
FROM message 
JOIN likes ON message.m_messageid = likes.l_messageid 
WHERE m_length > 100 
GROUP BY message.m_messageid 
HAVING COUNT(*) >= 20;
```

**Only consider messages where at least half of the likes are from people that are foreign to the message’s creator, with a foreigner being a person that neither the creator nor any of their friends know.**

- all message creators

    ```sql
    SELECT DISTINCT m_creatorid
    FROM message;
    ```

- friends of creators

    ```sql
    SELECT creators.m_creatorid, knows.k_person2id
    FROM knows,
        (SELECT DISTINCT m_creatorid
        FROM message) AS creators
    WHERE knows.k_person1id = creators.m_creatorid;
    ```

- creators and all their non-foreigners

    ```sql
    SELECT DISTINCT m_creatorid, k_person2id AS non_foreigner_id
    FROM (
        SELECT creators.m_creatorid, d2_knows.k_person2id
        FROM knows AS d_knows, knows AS d2_knows,
            (SELECT DISTINCT m_creatorid
            FROM message) AS creators
        WHERE creators.m_creatorid = d_knows.k_person1id
            AND d_knows.k_person2id = d2_knows.k_person1id
        UNION
        SELECT creators.m_creatorid, d_knows.k_person2id
        FROM knows AS d_knows, knows AS d2_knows,
            (SELECT DISTINCT m_creatorid
            FROM message) AS creators
        WHERE creators.m_creatorid = d_knows.k_person1id
            AND d_knows.k_person2id = d2_knows.k_person1id
        ) AS non_foreigners;
    ```

- messages with more then 20 likes and longer then 100 character, with their likers and their creators

    ```sql
    SELECT message_likes_count.m_messageid, 
        message_likes_count.like_count, 
        message_likes_count.m_creatorid,
        likes.l_personid
    FROM (
        SELECT message.m_messageid, COUNT(*) as like_count, message.m_creatorid
        FROM message, likes
        WHERE m_length > 100 AND message.m_messageid = likes.l_messageid 
        GROUP BY message.m_messageid, message.m_creatorid
        HAVING COUNT(*) >= 20
    ) AS message_likes_count, likes 
    WHERE message_likes_count.m_messageid = likes.l_messageid
    ```

- putting it all together


```sql
SELECT raw_results.m_messageid, 
        raw_results.like_count, 
        raw_results.like_count_foreigner, 
        (raw_results.like_count_foreigner::float / raw_results.like_count) AS ratio
FROM (
        SELECT non_foreigners.m_creatorid, 
        messages_likes_person.m_messageid,
        messages_likes_person.like_count,
        SUM(CASE WHEN messages_likes_person.l_personid = non_foreigners.k_person2id THEN 1 ELSE 0 END) AS like_count_friend,
        messages_likes_person.like_count - SUM(CASE WHEN messages_likes_person.l_personid = non_foreigners.k_person2id THEN 1 ELSE 0 END) AS like_count_foreigner
    FROM
        (
            SELECT creators.m_creatorid, d2_knows.k_person2id
            FROM knows AS d_knows, knows AS d2_knows,
                (SELECT DISTINCT m_creatorid
                FROM message) AS creators
            WHERE creators.m_creatorid = d_knows.k_person1id
                AND d_knows.k_person2id = d2_knows.k_person1id
            UNION
            SELECT creators.m_creatorid, d_knows.k_person2id
            FROM knows AS d_knows, knows AS d2_knows,
                (SELECT DISTINCT m_creatorid
                FROM message) AS creators
            WHERE creators.m_creatorid = d_knows.k_person1id
                AND d_knows.k_person2id = d2_knows.k_person1id
        ) AS non_foreigners
    FULL OUTER JOIN
        (
            SELECT message_likes_count.m_messageid, 
                message_likes_count.like_count, 
                message_likes_count.m_creatorid,
                likes.l_personid
            FROM (
                SELECT message.m_messageid, COUNT(*) as like_count, message.m_creatorid
                FROM message, likes
                WHERE m_length > 100 AND message.m_messageid = likes.l_messageid 
                GROUP BY message.m_messageid, message.m_creatorid
                HAVING COUNT(*) >= 20
            ) AS message_likes_count, likes 
            WHERE message_likes_count.m_messageid = likes.l_messageid
        ) AS messages_likes_person 
    ON messages_likes_person.m_creatorid = non_foreigners.m_creatorid
    WHERE NOT messages_likes_person.m_messageid IS NULL
    GROUP BY messages_likes_person.m_messageid, non_foreigners.m_creatorid, messages_likes_person.like_count
    ) AS raw_results
WHERE (raw_results.like_count_foreigner::float / raw_results.like_count) >= 0.5
ORDER BY ratio DESC;
```

### 1.2 ChatGPT

Iterative approach lead to nothing, second new chat resulted in this:

```sql
WITH LikeCounts AS (
    SELECT 
        l.l_messageid AS message_id,
        COUNT(*) AS total_likes
    FROM 
        likes l
    JOIN 
        message m ON l.l_messageid = m.m_messageid
    WHERE 
        m.m_length > 100
    GROUP BY 
        l.l_messageid
    HAVING 
        COUNT(*) >= 20
),
ForeignLikes AS (
    SELECT 
        l.l_messageid AS message_id,
        COUNT(*) AS foreign_likes
    FROM 
        likes l
    JOIN 
        message m ON l.l_messageid = m.m_messageid
    LEFT JOIN 
        knows k1 ON k1.k_person1id = m.m_creatorid AND k1.k_person2id = l.l_personid
    LEFT JOIN 
        knows k2 ON k2.k_person1id = l.l_personid AND k2.k_person2id = m.m_creatorid
    LEFT JOIN 
        knows mutual ON (mutual.k_person1id = m.m_creatorid AND mutual.k_person2id IN 
                         (SELECT k.k_person2id FROM knows k WHERE k.k_person1id = l.l_personid))
    WHERE 
        m.m_length > 100
        AND k1.k_person2id IS NULL 
        AND k2.k_person1id IS NULL 
        AND mutual.k_person1id IS NULL
    GROUP BY 
        l.l_messageid
)
SELECT 
    lc.message_id,
    lc.total_likes,
    fl.foreign_likes
FROM 
    LikeCounts lc
JOIN 
    ForeignLikes fl ON lc.message_id = fl.message_id
WHERE 
    fl.foreign_likes >= (lc.total_likes / 2)
ORDER BY 
    (fl.foreign_likes::float / lc.total_likes) DESC;
```

### 1.3 Reflection

- How much experience in query development did the team have?
    > Medium
- Which steps did the query development involve in each subtask?
    > Manual: Find Solution for each part of the sentences
    > ChatGPT: Tried to generate the whole solution at once and then iterate or regenerate
- How time-consuming and difficult was the development? 
    > Manual: Very time consuming and difficult
    > ChatGPT: Just frustrating, knowing the correct solution already
- How was the quality of the resulting implementation?
    > Manual: Quite good, certainly not of the very highest standard but efficient and readable
    > ChatGPT: Quite alright, contained SQL language features we did not know existed, was thus a little more readable but also a lot slower
- How helpful was the LLM in general and the additional explanations it provided (if any)?
    > The LLM was very helpful in finding modern SQL features, but without the ability to test the queries itself, it had difficulty iterating to a correct solution. The explanations were only superficial and did not help with understanding.
- How often did you have to prompt the LLM and were there any misunderstandings (on your side or the LLM’s)?
    > It did not understand the friends of friends concept at first. When the query was wrong, it was not able to correct its mistake even when hinted in the direction of the correct solution. In the end a completeley new chat was required to force it to regenerate its response.
- What degree of automation did the tools you used for query development achieve on their own and in combination?
    > When starting the new conversation ChatGPT was able to immediately generate a correct (although slow) result. This did not require specific promting and worked completely autonomously.

## Task 2: Query Extension

For each message, also return the full name of the first foreign person who liked the message and the time when they created the like.

### Task 2.1

#### Own Query

It is pretty much impossible to adjust our own query structure to accomodate the new requirements.
Therefor, we rewrote our first manual solution to use the structure of the ChatGPT solution.
And extended it with the new requirements.

```sql
WITH friends AS (
    SELECT creators.m_creatorid, d2_knows.k_person2id AS friendid
    FROM knows AS d_knows, knows AS d2_knows,
        (SELECT DISTINCT m_creatorid
        FROM message) AS creators
    WHERE creators.m_creatorid = d_knows.k_person1id
        AND d_knows.k_person2id = d2_knows.k_person1id
    UNION
    SELECT creators.m_creatorid, d_knows.k_person2id
    FROM knows AS d_knows, knows AS d2_knows,
        (SELECT DISTINCT m_creatorid
        FROM message) AS creators
    WHERE creators.m_creatorid = d_knows.k_person1id
        AND d_knows.k_person2id = d2_knows.k_person1id
), messages_likes_person AS (
    SELECT message_likes_count.m_messageid,
        message_likes_count.like_count, 
        message_likes_count.m_creatorid,
        likes.l_personid AS likerid,
        likes.l_creationdate
    FROM (
        SELECT message.m_messageid, COUNT(*) as like_count, message.m_creatorid
        FROM message, likes
        WHERE m_length > 100 AND message.m_messageid = likes.l_messageid 
        GROUP BY message.m_messageid, message.m_creatorid
        HAVING COUNT(*) >= 20
    ) AS message_likes_count, likes 
    WHERE message_likes_count.m_messageid = likes.l_messageid
), full_join AS (
    SELECT friends.m_creatorid, 
        messages_likes_person.m_messageid,
        messages_likes_person.like_count,
        messages_likes_person.likerid,
        friends.friendid
    FROM friends
    FULL OUTER JOIN messages_likes_person
    ON messages_likes_person.m_creatorid = friends.m_creatorid
    WHERE NOT messages_likes_person.m_messageid IS NULL
), anti_joined AS (
    SELECT DISTINCT(j1.m_messageid),
        j1.m_creatorid, 
        j1.like_count,
        j1.likerid AS foreign_liker_id
    FROM full_join j1
    LEFT JOIN full_join j2
    ON j1.m_messageid = j2.m_messageid
    AND j1.m_creatorid = j2.m_creatorid
    AND j1.likerid = j2.friendid
    WHERE j2.friendid IS NULL
    ORDER BY j1.m_messageid
), counted_foreign_likes AS (
    SELECT anti_joined.m_messageid,
        anti_joined.like_count,
        COUNT(DISTINCT anti_joined.foreign_liker_id) AS foreign_like_count
    FROM anti_joined
    GROUP BY anti_joined.m_messageid, anti_joined.like_count
), min_date_like_person AS (
    SELECT DISTINCT ON (anti_joined.m_messageid) anti_joined.m_messageid, 
        CONCAT(person.p_firstname, ' ', person.p_lastname) as first_liker,
        likes.l_creationdate
    FROM anti_joined, likes, person
    WHERE likes.l_personid = anti_joined.foreign_liker_id
    AND likes.l_messageid = anti_joined.m_messageid
    AND person.p_personid = likes.l_personid
    ORDER BY anti_joined.m_messageid, likes.l_creationdate
)
SELECT counted_foreign_likes.m_messageid,
    counted_foreign_likes.like_count,
    counted_foreign_likes.foreign_like_count,
    min_date_like_person.l_creationdate,
    min_date_like_person.first_liker,
    (counted_foreign_likes.foreign_like_count::float / counted_foreign_likes.like_count) AS ratio
FROM min_date_like_person, counted_foreign_likes
WHERE min_date_like_person.m_messageid = counted_foreign_likes.m_messageid
AND (counted_foreign_likes.foreign_like_count::float / counted_foreign_likes.like_count) >= 0.5 
ORDER BY ratio DESC;
```

#### ChatGPT Query

The same as the other because, we combined the ChatGPT code with our manual solution almost 50/50.
Thus rewriting the ChatGPT code would also lead to this solution.

### Task 2.2

Even after a lot of prompting ChatGPT was not able to provide a satifactory solution in both cases.

#### ChatGPT Query from Own Result of Task 1

```sql
WITH creator_non_foreigners AS (
    -- Step 1: Identify all non-foreigners (friends and friends-of-friends) for each creator
    SELECT creators.m_creatorid, d2_knows.k_person2id
    FROM knows AS d_knows
    JOIN knows AS d2_knows ON d_knows.k_person2id = d2_knows.k_person1id
    JOIN (SELECT DISTINCT m_creatorid FROM message) AS creators 
        ON creators.m_creatorid = d_knows.k_person1id
    
    UNION

    SELECT creators.m_creatorid, d_knows.k_person2id
    FROM knows AS d_knows
    JOIN (SELECT DISTINCT m_creatorid FROM message) AS creators 
        ON creators.m_creatorid = d_knows.k_person1id
),
message_likes AS (
    -- Step 2: Count total likes for messages longer than 100 characters with at least 20 likes
    SELECT 
        message.m_messageid, 
        COUNT(*) AS like_count, 
        message.m_creatorid
    FROM message
    JOIN likes ON message.m_messageid = likes.l_messageid
    WHERE message.m_length > 100
    GROUP BY message.m_messageid, message.m_creatorid
    HAVING COUNT(*) >= 20
),
message_likes_detailed AS (
    -- Step 3: Expand message likes with liker details
    SELECT 
        message_likes.m_messageid, 
        message_likes.like_count, 
        message_likes.m_creatorid, 
        likes.l_personid,
        likes.l_creationdate
    FROM message_likes
    JOIN likes ON message_likes.m_messageid = likes.l_messageid
),
raw_results AS (
    -- Step 4: Calculate foreign and friend-like counts, and find the first foreign like
    SELECT 
        detailed.m_messageid,
        detailed.like_count,
        detailed.m_creatorid,
        SUM(CASE WHEN detailed.l_personid = non_foreigners.k_person2id THEN 1 ELSE 0 END) AS like_count_friend,
        detailed.like_count - SUM(CASE WHEN detailed.l_personid = non_foreigners.k_person2id THEN 1 ELSE 0 END) AS like_count_foreigner,
        MIN(CASE 
            WHEN detailed.l_personid != non_foreigners.k_person2id THEN detailed.l_creationdate 
            ELSE NULL 
        END) AS first_foreign_like_time,
        MIN(CASE 
            WHEN detailed.l_personid != non_foreigners.k_person2id THEN detailed.l_personid 
            ELSE NULL 
        END) AS first_foreign_liker_id
    FROM creator_non_foreigners AS non_foreigners
    FULL OUTER JOIN message_likes_detailed AS detailed 
        ON detailed.m_creatorid = non_foreigners.m_creatorid
    WHERE detailed.m_messageid IS NOT NULL
    GROUP BY detailed.m_messageid, detailed.m_creatorid, detailed.like_count
),
first_foreign_details AS (
    -- Step 5: Retrieve full name of the first foreign liker
    SELECT 
        raw.m_messageid,
        raw.like_count,
        raw.like_count_foreigner,
        raw.first_foreign_like_time,
        raw.first_foreign_liker_id,
        p.p_firstname || ' ' || p.p_lastname AS first_foreign_liker_name
    FROM raw_results AS raw
    LEFT JOIN person p ON raw.first_foreign_liker_id = p.p_personid
    WHERE (raw.like_count_foreigner::float / raw.like_count) >= 0.5
)
-- Final selection and sorting
SELECT 
    ffd.m_messageid, 
    ffd.like_count, 
    ffd.like_count_foreigner, 
    (ffd.like_count_foreigner::float / ffd.like_count) AS ratio,
    ffd.first_foreign_liker_name,
    ffd.first_foreign_like_time
FROM first_foreign_details AS ffd
ORDER BY ratio DESC;
```

#### ChatGPT Query from ChatGPT Result of Task 1

```sql
WITH LikeCounts AS (
    SELECT 
        l.l_messageid AS message_id,
        COUNT(*) AS total_likes
    FROM 
        likes l
    JOIN 
        message m ON l.l_messageid = m.m_messageid
    WHERE 
        m.m_length > 100
    GROUP BY 
        l.l_messageid
    HAVING 
        COUNT(*) >= 20
),
ForeignLikes AS (
    SELECT 
        l.l_messageid AS message_id,
        COUNT(*) AS foreign_likes,
        MIN(l.l_creationdate) AS first_foreign_like_time
    FROM 
        likes l
    JOIN 
        message m ON l.l_messageid = m.m_messageid
    LEFT JOIN 
        knows k1 ON k1.k_person1id = m.m_creatorid AND k1.k_person2id = l.l_personid
    LEFT JOIN 
        knows k2 ON k2.k_person1id = l.l_personid AND k2.k_person2id = m.m_creatorid
    LEFT JOIN 
        knows mutual ON (mutual.k_person1id = m.m_creatorid AND mutual.k_person2id IN 
                         (SELECT k.k_person2id FROM knows k WHERE k.k_person1id = l.l_personid))
    WHERE 
        m.m_length > 100
        AND k1.k_person2id IS NULL 
        AND k2.k_person1id IS NULL 
        AND mutual.k_person1id IS NULL
    GROUP BY 
        l.l_messageid
),
FirstForeignLiker AS (
    SELECT DISTINCT ON (l.l_messageid)
        l.l_messageid AS message_id,
        p.p_firstname || ' ' || p.p_lastname AS first_foreign_liker_name,
        l.l_creationdate AS first_foreign_like_time
    FROM 
        likes l
    JOIN 
        message m ON l.l_messageid = m.m_messageid
    JOIN 
        person p ON p.p_personid = l.l_personid
    LEFT JOIN 
        knows k1 ON k1.k_person1id = m.m_creatorid AND k1.k_person2id = l.l_personid
    LEFT JOIN 
        knows k2 ON k2.k_person1id = l.l_personid AND k2.k_person2id = m.m_creatorid
    LEFT JOIN 
        knows mutual ON (mutual.k_person1id = m.m_creatorid AND mutual.k_person2id IN 
                         (SELECT k.k_person2id FROM knows k WHERE k.k_person1id = l.l_personid))
    WHERE 
        m.m_length > 100
        AND k1.k_person2id IS NULL 
        AND k2.k_person1id IS NULL 
        AND mutual.k_person1id IS NULL
    ORDER BY 
        l.l_messageid, l.l_creationdate
)
SELECT 
    lc.message_id,
    lc.total_likes,
    fl.foreign_likes,
    ffl.first_foreign_liker_name,
    ffl.first_foreign_like_time
FROM 
    LikeCounts lc
JOIN 
    ForeignLikes fl ON lc.message_id = fl.message_id
JOIN 
    FirstForeignLiker ffl ON lc.message_id = ffl.message_id
WHERE 
    fl.foreign_likes >= (lc.total_likes / 2)
ORDER BY 
    (fl.foreign_likes::float / lc.total_likes) DESC;
```

### 2.3 Reflection

- How much experience in query development did the team have?
    > Medium
- Which steps did the query development involve in each subtask?
    > Manual: rewrite the entire query and then accomodate new feature for own query. Our query from task 1 cannot accomodate the new requirement easily, since we are finding all non-foreigners of a creator but not all foreigners.
    > ChatGPT: promted it to incoporate the new requirements into the existing query (in the existing chat for the task 1 ChatGPT solution)
- How time-consuming and difficult was the development? 
    > Manual: Very time consuming and difficult, since we had to rewrite the query
    > ChatGPT: A bit simpler than in task, since we knew the trick with the new conversation already
- How was the quality of the resulting implementation?
    > Manual: Very good, a lot better than task 1, more readable and considerably faster than the ChatGPT result.
    > ChatGPT: Quite alright, just a lot slower than our manual solution. ChatGPT tries to mix naming conventions for some reason. It rename tables in Joins which make the query shorter than ours.
- How helpful was the LLM in general and the additional explanations it provided (if any)?
    > The LLM was very helpful in finding minimal examples for a few SQL patterns, which were very useful for the manual rewrite. It tought us how to antijoin and how the with statement worked. 
- How often did you have to prompt the LLM and were there any misunderstandings (on your side or the LLM’s)?
    > It did not understand the concept of the first foreign person, that liked the message at first. It was not fixable, even after trying several times with different prompts
- What degree of automation did the tools you used for query development achieve on their own and in combination?
    > for manual no automation, for ChatGPT it was semi-automation, since we had to prompt it.
- How could automation as provided by the LLM be integrated holistically into an iterative query development process?
    > It is good for explaining general concepts, rewriting SQL queries, creating minimal examples. Maybe simpler SQL tasks are also doable for the LLM without further prompting. An iterative process would maybe consist of first asking ChatGPT for that and afterwards combining the results to an final query manually. Asking ChatGPT for the entire result and trying to fix it afterwards is really hard and pointless.

## Task 3: Query Execution

### Task 3.1

```text
  QUERY PLAN

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=638724839.50..638724872.83 rows=13333 width=72)
   Sort Key: ((((count(DISTINCT anti_joined.foreign_liker_id)))::double precision / (anti_joined.like_count)::double precision)) DESC
   CTE full_join
     ->  Merge Left Join  (cost=513457.96..7619263.71 rows=470529861 width=40)
           Merge Cond: (message.m_creatorid = message_1.m_creatorid)
           ->  Sort  (cost=19410.95..19497.29 rows=34536 width=32)
                 Sort Key: message.m_creatorid
                 ->  Hash Join  (cost=14861.55..16807.65 rows=34536 width=32)
                       Hash Cond: (message.m_messageid = likes_1.l_messageid)
                       ->  HashAggregate  (cost=11166.15..11250.73 rows=2256 width=24)
                             Group Key: message.m_messageid, message.m_creatorid
                             Filter: (count(*) >= 20)
                             ->  Hash Join  (cost=8844.92..11115.40 rows=6767 width=16)
                                   Hash Cond: (likes_2.l_messageid = message.m_messageid)
                                   ->  Seq Scan on likes likes_2  (cost=0.00..1792.40 rows=109440 width=8)
                                   ->  Hash  (cost=8623.30..8623.30 rows=17730 width=16)
                                         ->  Seq Scan on message  (cost=0.00..8623.30 rows=17730 width=16)
                                               Filter: ((m_messageid IS NOT NULL) AND (m_length > 100))
                       ->  Hash  (cost=1792.40..1792.40 rows=109440 width=16)
                             ->  Seq Scan on likes likes_1  (cost=0.00..1792.40 rows=109440 width=16)
           ->  Materialize  (cost=494047.02..548544.34 rows=2724866 width=16)
                 ->  Unique  (cost=494047.02..514483.51 rows=2724866 width=16)
                       ->  Sort  (cost=494047.02..500859.18 rows=2724866 width=16)
                             Sort Key: message_1.m_creatorid, d2_knows.k_person2id
                             ->  Append  (cost=13810.88..109647.44 rows=2724866 width=16)
                                   ->  Merge Join  (cost=13810.88..34387.23 rows=1362433 width=16)
                                         Merge Cond: (d_knows.k_person2id = d2_knows.k_person1id)
                                         ->  Sort  (cost=11269.34..11339.29 rows=27980 width=16)
                                               Sort Key: d_knows.k_person2id
                                               ->  Hash Join  (cost=8667.14..9202.72 rows=27980 width=16)
                                                     Hash Cond: (d_knows.k_person1id = message_1.m_creatorid)
                                                     ->  Seq Scan on knows d_knows  (cost=0.00..461.46 rows=28146 width=16)
                                                     ->  Hash  (cost=8650.28..8650.28 rows=1349 width=8)
                                                           ->  HashAggregate  (cost=8623.30..8636.79 rows=1349 width=8)
                                                                 Group Key: message_1.m_creatorid
                                                                 ->  Seq Scan on message message_1  (cost=0.00..7906.44 rows=286744 width=8)
                                         ->  Sort  (cost=2541.54..2611.90 rows=28146 width=16)
                                         
```

Visualization for own query from task 2:

- [visualization](https://explain.dalibo.com/plan/25c952486b3g3f51)
- [extended visualization](https://explain.dalibo.com/plan/23h6ac208h793852)

ChatGPT created example:

- [here](https://explain.dalibo.com/plan/45g7fe93a92b65c8)

We need to submit additional to the query the schema of the database and also rowcounts for each table.

```sql
WITH tbl AS
  (SELECT table_schema,
          TABLE_NAME
   FROM information_schema.tables
   WHERE TABLE_NAME not like 'pg_%'
     AND table_schema in ('public'))
SELECT table_schema,
       TABLE_NAME,
       (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from %I.%I', table_schema, TABLE_NAME), FALSE, TRUE, '')))[1]::text::int AS rows_n
FROM tbl
ORDER BY rows_n DESC;
```

Visualization for ChatGPT query from task 2
[visualization](https://explain.dalibo.com/plan/b28d8h43ca9d0603)

[extended visualization](https://explain.dalibo.com/plan/cg2a9f7he734d8d9)

### Task 3.2

- Is the execution plan generated by the LLM plausible?
    > The plans for the single realtions like friends or message_likes_person looks pretty plausible. There is second friends realtion which just consist of a nested loop join but no scans are done on the real tables which makes no sense. The plan that should produce the result also looks wrong. There is a scan on table which is not created by the other plans and does not exist. Furthermore the scans should be replaced by results of the query plan results of the other tables (there is no connection line between these tables). So in total the plan is not very plausible.
- How helpful were additional explanations provided by the LLM (if any)?
    > The LLM ask for the schema and also statistics about the tables which should be very helpful for a better generation of the query plans. Further explantions they give were first more about what the query exactly does an not about the query plan itself. After some clarifications we get a query plan and also explanations about the EXPLAIN command, an example visualizer and operation/task descriptions (used in the plan). 
- To what degree is query execution already automated in PostgreSQL?
    > Query execution is more or less fully automated. We can just write our queries and give it to postgres and postgres give us the result. Also the query plans for the execution can be generated. In PostgreSQL shell you just get a written form of it (which is hard to read for humans) but with use of tools like the provided visulizer or pgadmin the visualization could be easily generated or is done automatically.
- Are there any fundamental differences between the query development tasks from Tasks 1 and 2 and the creation of a query execution plan that may have implications regarding automation?
    > For the query generation in task 1 and 2 we just need the schema with the relations between the different tables and attributes. For the query execution plan we need a lot of knowledge about the real data, like row counts of the tables, unique value in each tables and other statistics. Otherwise it would not be possible to do create a realistic execution plan. 
