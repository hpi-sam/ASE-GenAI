# Reflection on Task 1

## How much knowledge was required?

For developing a solution myself, I had to have a lot of knowledge. I had to
know SQL and set logic. It took me about two hours to create my solution that I
finally came up with. This could not have been done by unexperienced persons.

However, finding a solution with ChatGPT was quite convenient. I uploaded the
`schema.sql` and added the request from the PDF. Adding a sentence that I need
an SQL statement to solve the request was sufficient to get a solution. 

In the end, it was far easier finding a solution with an AI.

## How good are the results?

The performance of my own solution was much faster (30s vs. 90s) compared to
the ChatGPT solution. However, that might simply do not play a role depending
on the specific use case. Also, fine-tuning might have lead to similar results.

## Readability

My own implementation was not as readable as the solution of ChatGPT. ChatGPT
gave a well-formatted, easy-to-read query that anybody would understand. My
implementation is really hard to understand. Therefore, my implementation would
need further work on readability.

## Correctness

Both solutions seemed to result in the correct solutions, but ChatGPT spotted
the sorting requirement. I did not spot it, as after working for two hours, I
simply overread it, as my head was about to explode. When looking at ChatGPTs
results, it just got back to my head. So, in this rare case, ChatGPT was more
correct.

## Queries for ChatGPT

(`schema.sql` attached to chat)

Me:
> Using the given file, write a SQL statement that returns the following request: Find all messages longer than 100 characters that have been liked by at least 20 people. Only consider messages where at least half of the likes are from people that are foreign to the message’s creator, with a foreigner being a person that neither the creator nor any of their friends know. For each message, return the message’s id, the total number of likes and the number of foreign likes. Sort the returned messages by the ratio of foreign likes from highest to lowest.

ChatGPT:
> To help with your request, I'll first examine the contents of the uploaded schema.sql file to understand the database structure. Let's start by inspecting the file.
> 
> The schema.sql file provides the database structure with several relevant tables. For the requested SQL query, the following tables are important:
> 
> message: Stores details of messages including m_messageid, m_length, and m_creatorid.
> likes: Captures who liked a message (l_personid, l_messageid).
> knows: Represents the social connections between people (k_person1id, k_person2id).
> person: Contains details about people (p_personid).
> Steps for the SQL query:
> Identify messages longer than 100 characters.
> Count total likes per message.
> Determine the foreign likes per message. A foreign like occurs when the liker does not know the creator, nor any of the creator's friends.
> Filter for messages with at least 20 total likes and where at least half are foreign likes.
> Return the message ID, total likes, foreign likes, and sort by the ratio of foreign likes.
> Let's construct the SQL query based on this logic. ​​
> 
> Here is the SQL statement to achieve the requested query:
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
>         COUNT(l.l_personid) AS foreign_likes
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
>     GROUP BY 
>         l.l_messageid
> )
> SELECT 
>     t.m_messageid,
>     t.total_likes,
>     f.foreign_likes
> FROM 
>     TotalLikes t
> JOIN 
>     ForeignLikes f ON t.m_messageid = f.l_messageid
> WHERE 
>     f.foreign_likes >= t.total_likes / 2
> ORDER BY 
>     CAST(f.foreign_likes AS FLOAT) / t.total_likes DESC;
> ```
> Explanation:
> TotalLikes CTE: Filters messages longer than 100 characters, counting likes and ensuring at least 20 likes.
> ForeignLikes CTE: Counts likes from users who are not the creator or a friend of the creator.
> Main Query: Combines the results, filtering for messages with at least half foreign likes, and sorts by the ratio of foreign likes.
> This query leverages common table expressions (CTEs) to simplify and structure the complex logic.


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

(continuing the above conversation)

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
