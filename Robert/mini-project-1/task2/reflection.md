# Reflection on Task 2

## Process of Iterative Development

Adding a further feature to the script was a high effort. I had to get back
into the code and think about more. I tried having more JOINS, but that would
have decreased performance by a lot. After about an hour of work, I figured out
how to do it by hand, but the code become much more complex. With each new
feature, it would become more complex to add stuff.

On the other hand, updating the ChatGPT-written code was very simple. I just
"told" ChatGPT the new specification and five minutes later it was implemented
and up and running. However, the ChatGPT implementation is still much slower.
Overall, the process was far easier using the LLM.

## Queries for ChatGPT

(continuing the conversation from task 1)

Me:
> How change the request for the following: For each message, also return the full name of the first foreign person who liked the message and the time when they created the like.

ChatGPT:
> To include the full name of the first foreign person who liked each message and the timestamp when they created the like, we need to modify the query to join the person table and incorporate the l_creationdate from the likes table. Here's how you can adjust the SQL query:
>
> ```sql
> WITH TotalLikes AS (
>     SELECT 
>         m.m_messageid,
>         COUNT(l.l_personid) AS total_likes
>     FROM 
>         message m
>     JOIN 
>         likes l ON m.m_messageid = l.l_messageid
>     WHERE 
>         m.m_length > 100
>     GROUP BY 
>         m.m_messageid
>     HAVING 
>         COUNT(l.l_personid) >= 20
> ),
> ForeignLikes AS (
>     SELECT 
>         l.l_messageid,
>         l.l_personid,
>         l.l_creationdate,
>         COUNT(*) OVER (PARTITION BY l.l_messageid) AS foreign_likes,
>         ROW_NUMBER() OVER (PARTITION BY l.l_messageid ORDER BY l.l_creationdate) AS rn
>     FROM 
>         likes l
>     JOIN 
>         message m ON l.l_messageid = m.m_messageid
>     LEFT JOIN 
>         knows k ON (l.l_personid = k.k_person1id AND k.k_person2id = m.m_creatorid)
>                   OR (l.l_personid = k.k_person2id AND k.k_person1id = m.m_creatorid)
>     LEFT JOIN 
>         knows k2 ON k.k_person1id = m.m_creatorid OR k.k_person2id = m.m_creatorid
>     WHERE 
>         k.k_person1id IS NULL AND k.k_person2id IS NULL
>         AND k2.k_person1id IS NULL AND k2.k_person2id IS NULL
> )
> SELECT 
>     t.m_messageid,
>     t.total_likes,
>     f.foreign_likes,
>     p.p_firstname || ' ' || p.p_lastname AS first_foreigner_name,
>     f.l_creationdate AS first_like_time
> FROM 
>     TotalLikes t
> JOIN 
>     (SELECT * FROM ForeignLikes WHERE rn = 1) f ON t.m_messageid = f.l_messageid
> JOIN 
>     person p ON f.l_personid = p.p_personid
> WHERE 
>     f.foreign_likes >= t.total_likes / 2
> ORDER BY 
>     CAST(f.foreign_likes AS FLOAT) / t.total_likes DESC;
> ```
>
> Explanation:
> TotalLikes CTE: Same as before, filtering messages with more than 100 characters and at least 20 likes.
> ForeignLikes CTE: Adds ROW_NUMBER() to find the first foreign like per message and counts foreign likes.
> Main Query:
> Joins person to fetch the foreign liker’s full name (p_firstname, p_lastname).
> Filters for the first foreign liker (rn = 1) and returns their name and the time they liked the message.
> Orders the results by the ratio of foreign likes.
> ```
>
> This query now returns the message ID, total likes, foreign likes, the name of the first foreign liker, and the time of their like.
