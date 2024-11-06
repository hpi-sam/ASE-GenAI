# Query Plan (own Query)

## Generated with DBeaver

- essentially the EXPLAIN keyword with COSTS option

![DBeaver Query Plan Explanation](./dbeaver-query-plan1.png)

- most impactful is Nested Loop Join with costs jumping up to 45M
- likely not removable, as sometime it needs to be called
	- also removed 36M rows! Therefore, increases performance of other
	operators

## Generated with ChatGPT

```txt
ID	Operation	Table	Index/Join Condition	Filter	Rows (Estimate)
1	Sort			ORDER BY (foreign_likes / total_likes) DESC	1000
2	Nested Loop Join				1000
3	├── Nested Loop Join				5000
4	│ ├── Filtered Aggregate	message	m_length >= 100		2000
5	│ │ ├── Join	likes	m.m_messageid = l.l_messageid		50000
6	│ │ │ └── Filtered Join	person	Exclude friends of m_creatorid	Based on knows subquery	10000
7	│ └── Hash Join	total_likes	l.mid = r.mid	total_likes >= 20 and foreign_likes * 2 >= total_likes	5000
8	├── Nested Loop Join	likes l2	r.mid = l2.l_messageid and r.min_date = l2.l_creationdate		2000
9	└── Hash Join	person p2	r2.l_personid = p2.p_personid		1000
```

- way to broad
- AI tries to stay general even if I asked for very specific details
	- long living problem of addressing the needs of the user --> cannot be
	solved perfectly

## Reflection

Creating the query plan with ChatGPT was less than helpful. First, ChatGPT
tried to optimize my query when I asked for a query plan. This is not helpful,
when I don't know about possible suboptimal parts of the query. When I asked
explicitly for the EXPLAIN keyword, ChatGPT gave me what I needed. However,
that required me to know this keyword and it just created an already existing
function of PostgreSQL. I wouldn't have needed ChatGPT for that, but could have
done that with any tool. Using the automation from the tool directly also gave
me much more comprehensible output that I also more trusted. AI is known for
not being perfectly correct. Therefore, those details might simply be wrong.
Why would it be right here?

Also, it was harder to understand the output of the LLM, as it provided very
little information (e.g., column "rows" --> is that about how many rows are
removed?) so I had big trouble understanding the output.

## Queries with ChatGPT for the Query Plan

> Explain the following SQL query with a query plan.
>
> ```sql
> select mid, foreign_likes, total_likes, min_date, p2.p_firstname || ' ' || p2.p_lastname as name
> from (
> 	select mid, foreign_likes, total_likes, min_date, l_personid 
> 		from (
> 		select l.mid, foreign_likes, total_likes, min_date
> 		from (
> 			select COUNT(m.l_personid) as foreign_likes, m.m_messageid as mid, MIN(m.l_creationdate) as min_date
> 			from (
> 				select * from message m
> 				join likes l
> 				on m.m_messageid = l.l_messageid
> 			) m
> 			where m.m_length >= 100 and l_personid in (
> 				select p.p_personid as pid from person p 
> 				where p.p_personid not in (
> 					select k.k_person2id as pid from knows k 
> 					where k.k_person1id = m.m_creatorid 
> 						union
> 					select k.k_person1id as pid from knows k
> 					where k.k_person2id = m.m_creatorid 
> 						union
> 					select m.m_creatorid 
> 				)
> 			)
> 			group by m.m_messageid
> 		) l
> 		join (
> 			select m.m_messageid as mid, COUNT(l.l_personid) as total_likes
> 			from message m 
> 			join likes l 
> 			on m.m_messageid = l.l_messageid
> 			group by m.m_messageid
> 		) r
> 		on l.mid = r.mid
> 		where total_likes >= 20 and foreign_likes * 2 >= total_likes
> 	) r join likes l2
> 	on r.mid = l2.l_messageid and r.min_date = l2.l_creationdate
> ) r2 join person p2
> on r2.l_personid = p2.p_personid
> order by (cast(foreign_likes as float) / cast(total_likes as float)) desc;
> ```

ChatGPT:
> To understand this complex SQL query and its query plan, let’s break it down into parts. The query appears to perform the following key steps:
> 
> Identify messages with specific characteristics:
> 
> m.m_length >= 100 filters messages that are longer than or equal to 100 characters.
> total_likes >= 20 filters messages with at least 20 likes.
> The ratio of "foreign likes" (likes from people not directly connected to the message creator) to total_likes must be at least 50%.
> Calculate foreign and total likes:
> 
> A foreign like is defined as a like from someone who is not directly connected (using the knows relationship) to the creator of the message (m_creatorid).
> Both the count of foreign likes (foreign_likes) and total likes (total_likes) are calculated and filtered accordingly.
> Determine the earliest like date (min_date) for each message that meets the criteria.
> 
> Join data to retrieve the name of the user who first liked the message:
> 
> The name of the user who liked the message on min_date is fetched by joining with the person table.
> Order results by the ratio of foreign likes to total likes in descending order.
> 
> Detailed Step-by-Step Breakdown and Query Plan Analysis
> Step 1: Core Message and Like Information (Innermost Subquery)
> sql
> Code kopieren
> select * from message m
> join likes l
> on m.m_messageid = l.l_messageid
> Purpose: This joins the message table with the likes table on message_id, producing a combination of all messages with their associated likes.
> Query Plan Considerations: Using an index on m_messageid and l_messageid would optimize this join. This could lead to a hash join or nested loop join, depending on the dataset size and indexes available.
> Step 2: Filtering for Foreign Likes
> ```sql
> Code kopieren
> where m.m_length >= 100 and l_personid in (
> 	select p.p_personid as pid from person p 
> 	where p.p_personid not in (
> 		select k.k_person2id as pid from knows k 
> 		where k.k_person1id = m.m_creatorid 
> 			union
> 		select k.k_person1id as pid from knows k
> 		where k.k_person2id = m.m_creatorid 
> 			union
> 		select m.m_creatorid 
> 	)
> )
> ```
> Purpose: Filters likes to include only those from people who do not know the message creator. This is done by excluding the person_id values found in the knows relationships with m_creatorid.
> Query Plan Considerations: The query here includes a complex series of subqueries and unions. For efficiency, indexes on knows.k_person1id, knows.k_person2id, and m_creatorid are crucial. Using a hash anti-join or a NOT IN strategy can optimize exclusion joins.
> Step 3: Calculate Foreign Likes and Min Date
> sql
> Code kopieren
> select COUNT(m.l_personid) as foreign_likes, m.m_messageid as mid, MIN(m.l_creationdate) as min_date
> from (previous join results) m
> group by m.m_messageid
> Purpose: Counts foreign likes and determines the earliest like date for each message.
> Query Plan Considerations: A GROUP BY operation is used here, which would benefit from an index on l_personid and l_creationdate. This operation could lead to a hashing aggregation, especially if data volumes are large.
> Step 4: Join with Total Likes
> ```sql
> Code kopieren
> join (
> 	select m.m_messageid as mid, COUNT(l.l_personid) as total_likes
> 	from message m 
> 	join likes l 
> 	on m.m_messageid = l.l_messageid
> 	group by m.m_messageid
> ) r on l.mid = r.mid
> where total_likes >= 20 and foreign_likes * 2 >= total_likes
> ```
> Purpose: Joins the filtered messages with the total likes count and applies further filtering for messages with at least 20 total likes and a high ratio of foreign likes.
> Query Plan Considerations: This join can benefit from indexes on mid in both subqueries. Additionally, the filters on total_likes and foreign_likes suggest an efficient filtering strategy using either bitmap indexes or indexed views if supported.
> Step 5: Identify User with First Like Date
> ```sql
> Code kopieren
> join likes l2 on r.mid = l2.l_messageid and r.min_date = l2.l_creationdate
> ```
> Purpose: This step identifies the user who liked the message first by joining on min_date.
> Query Plan Considerations: Efficient joining here would likely involve using an index on l_creationdate to quickly locate the first like.
> Step 6: Retrieve and Format User’s Name
> ```sql
> Code kopieren
> join person p2 on r2.l_personid = p2.p_personid
> select p2.p_firstname || ' ' || p2.p_lastname as name
> ```
> Purpose: Joins with the person table to get the name of the user who gave the first like.
> Query Plan Considerations: An index on p_personid would be beneficial to speed up this join.
> Step 7: Order by Foreign Like Ratio
> sql
> Code kopieren
> order by (cast(foreign_likes as float) / cast(total_likes as float)) desc;
> Purpose: Orders the final result by the ratio of foreign likes to total likes in descending order.
> Query Plan Considerations: Sorting by a calculated column may require sorting in memory unless indexes are available to support this calculation directly.
> Summary of the Query Plan
> Joins and Filtering: The query involves multiple levels of nested joins, primarily between message, likes, and person tables, and complex subqueries that compute both foreign and total likes.
> Indexing: To optimize this query, indexes on message_id, person_id, creation_date, and columns used in where clauses are essential.
> Aggregation and Grouping: The query has aggregation (COUNT, MIN) operations, which would likely use hashing aggregation or indexed views if possible.
> Ordering: Sorting by a calculated column (foreign likes ratio) may add significant overhead if not indexed or precomputed in a view.

Me:
> Show me what the output of the EXPLAIN keyword for my query would be

ChatGPT:
> The EXPLAIN keyword in SQL provides information on the execution plan the database engine would use to execute a query. It varies slightly by database (e.g., PostgreSQL, MySQL, Oracle), but in general, it details the sequence of operations the database will perform, the indexes used, joins, and filters applied.
> 
> Here’s an approximate breakdown of what the output of EXPLAIN for this complex query could look like in a typical relational database like PostgreSQL or MySQL. To make it more readable, we'll break down the major parts of the query plan and illustrate a representative output that might be expected. Please note that the actual EXPLAIN output will vary depending on the specific data, indexing, and database system.
> 
> Approximate EXPLAIN Output
> ```sql
> EXPLAIN 
> select mid, foreign_likes, total_likes, min_date, p2.p_firstname || ' ' || p2.p_lastname as name
> from (
> 	select mid, foreign_likes, total_likes, min_date, l_personid 
> 		from (
> 		select l.mid, foreign_likes, total_likes, min_date
> 		from (
> 			select COUNT(m.l_personid) as foreign_likes, m.m_messageid as mid, MIN(m.l_creationdate) as min_date
> 			from (
> 				select * from message m
> 				join likes l
> 				on m.m_messageid = l.l_messageid
> 			) m
> 			where m.m_length >= 100 and l_personid in (
> 				select p.p_personid as pid from person p 
> 				where p.p_personid not in (
> 					select k.k_person2id as pid from knows k 
> 					where k.k_person1id = m.m_creatorid 
> 						union
> 					select k.k_person1id as pid from knows k
> 					where k.k_person2id = m.m_creatorid 
> 						union
> 					select m.m_creatorid 
> 				)
> 			)
> 			group by m.m_messageid
> 		) l
> 		join (
> 			select m.m_messageid as mid, COUNT(l.l_personid) as total_likes
> 			from message m 
> 			join likes l 
> 			on m.m_messageid = l.l_messageid
> 			group by m.m_messageid
> 		) r
> 		on l.mid = r.mid
> 		where total_likes >= 20 and foreign_likes * 2 >= total_likes
> 	) r join likes l2
> 	on r.mid = l2.l_messageid and r.min_date = l2.l_creationdate
> ) r2 join person p2
> on r2.l_personid = p2.p_personid
> order by (cast(foreign_likes as float) / cast(total_likes as float)) desc;
> ```
> Representative EXPLAIN Output (Approximate)
> ID	Operation	Table	Index/Join Condition	Filter	Rows (Estimate)
> 1	Sort			ORDER BY (foreign_likes / total_likes) DESC	1000
> 2	Nested Loop Join				1000
> 3	├── Nested Loop Join				5000
> 4	│ ├── Filtered Aggregate	message	m_length >= 100		2000
> 5	│ │ ├── Join	likes	m.m_messageid = l.l_messageid		50000
> 6	│ │ │ └── Filtered Join	person	Exclude friends of m_creatorid	Based on knows subquery	10000
> 7	│ └── Hash Join	total_likes	l.mid = r.mid	total_likes >= 20 and foreign_likes * 2 >= total_likes	5000
> 8	├── Nested Loop Join	likes l2	r.mid = l2.l_messageid and r.min_date = l2.l_creationdate		2000
> 9	└── Hash Join	person p2	r2.l_personid = p2.p_personid		1000
> Explanation of Each Row in EXPLAIN Output
> Sort: Final sorting operation based on the ratio (foreign_likes / total_likes) DESC.
> 
> Nested Loop Join: This join retrieves the final result set after matching rows between the main subquery (r2) and the person table for name information.
> 
> Nested Loop Join (Inner): Joins the two primary subqueries (l and r) on the message ID to bring together foreign likes, total likes, and min_date.
> 
> Filtered Aggregate: Performs aggregation to calculate foreign_likes and min_date for each message. The condition m_length >= 100 filters the messages.
> 
> Join (Message and Likes): Joins message and likes to create a combined view of all messages and their likes, which is subsequently filtered for non-friend likes (foreign likes).
> 
> Filtered Join (Person and Knows): Filters out people who know the creator from the foreign likes calculation by joining the person table and excluding using knows.
> 
> Hash Join: A join between the aggregated foreign likes data and total likes subquery based on the message ID. It filters results by total_likes >= 20 and ensures that foreign_likes is at least half of total_likes.
> 
> Nested Loop Join with Likes (Earliest Like Date): Joins with the likes table again to identify the user who liked each message at the earliest date (min_date).
> 
> Hash Join with Person: Final join to retrieve the name of the user who gave the first like on each message.
> 
> Notes on Optimization Suggestions
> This query plan could benefit from:
> 
> Indexes on message_id, person_id, creation_date, and the columns involved in filtering (m_length, l_personid).
> Materialized Views: Precomputed aggregations, especially for foreign and total likes, could make this more efficient.
> Hash Joins for large table joins (if supported by the database) over nested loop joins, especially on the largest subqueries.
> The actual output might differ significantly based on specific database configurations, indexes, and optimizations available.
