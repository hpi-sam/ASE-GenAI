# Manual Query Extended

[https://chatgpt.com/share/673ca699-2dc8-8010-8a78-b37197f0406a](https://chatgpt.com/share/673ca699-2dc8-8010-8a78-b37197f0406a)

### User

I am working on the following task:

"Find all messages longer than 100 characters that have been liked by at least 20
people. Only consider messages where at least half of the likes are from people that
are foreign to the message’s creator, with a foreigner being a person that neither the
creator nor any of their friends know. For each message, return the message’s id, the
total number of likes and the number of foreign likes. Sort the returned messages by
the ratio of foreign likes from highest to lowest."
This is my current query which was manually created by me:

```
select m_messageid as message, count(l_personid) as total_likes, foreign_likes
from public.message, public.likes, LATERAL (
	select count(foreignlikes.l_personid) as foreign_likes from public.likes as foreignlikes where foreignlikes.l_messageid = m_messageid and foreignlikes.l_personid not in (
		(select k_person2id as known_personid from public.knows where k_person1id = m_creatorid)
		UNION
		(select friendknows.k_person2id as known_personid
		from public.knows as authorknows, public.knows as friendknows
		where authorknows.k_person1id = m_creatorid and friendknows.k_person1id = authorknows.k_person2id)
	)
)
where m_messageid = l_messageid and m_length > 100
group by m_messageid, foreign_likes
having count(l_personid) >= 20 and (foreign_likes::float / count(l_personid)) >= 0.5
ORDER BY (foreign_likes::float / count(l_personid)) DESC;
```

Now extend this manual query with this additional requirement:
"For each message, also return the full name of the first foreign person who liked the
message and the time when they created the like."

This is the schema of the database:

```
create table post (
    m_messageid bigint not null,
    m_ps_imagefile varchar,
    m_creationdate timestamp with time zone not null,
    m_locationip varchar not null,
    m_browserused varchar not null,
    m_ps_language varchar,
    m_content text,
    m_length int not null,
    m_creatorid bigint not null,
    m_ps_forumid bigint,
    m_locationid bigint not null
);

create table comment (
    m_messageid bigint not null,
    m_creationdate timestamp with time zone not null,
    m_locationip varchar not null,
    m_browserused varchar not null,
    m_content text,
    m_length int not null,
    m_creatorid bigint not null,
    m_locationid bigint not null,
    m_replyof_post bigint,
    m_replyof_comment bigint
);

create table forum (
   f_forumid bigint not null,
   f_title varchar not null,
   f_creationdate timestamp with time zone not null,
   f_moderatorid bigint not null
);

create table forum_person (
   fp_forumid bigint not null,
   fp_personid bigint not null,
   fp_joindate timestamp with time zone not null
);

create table forum_tag (
   ft_forumid bigint not null,
   ft_tagid bigint not null
);

create table organisation (
   o_organisationid bigint not null,
   o_type varchar not null,
   o_name varchar not null,
   o_url varchar not null,
   o_placeid bigint not null
);

create table person (
   p_personid bigint not null,
   p_firstname varchar not null,
   p_lastname varchar not null,
   p_gender varchar not null,
   p_birthday date not null,
   p_creationdate timestamp with time zone not null,
   p_locationip varchar not null,
   p_browserused varchar not null,
   p_placeid bigint not null
);

create table person_email (
   pe_personid bigint not null,
   pe_email varchar not null
);


create table person_tag (
   pt_personid bigint not null,
   pt_tagid bigint not null
);

create table knows (
   k_person1id bigint not null,
   k_person2id bigint not null,
   k_creationdate timestamp with time zone not null
);

create table likes (
   l_personid bigint not null,
   l_messageid bigint not null,
   l_creationdate timestamp with time zone not null
);

create table person_language (
   plang_personid bigint not null,
   plang_language varchar not null
);

create table person_university (
   pu_personid bigint not null,
   pu_organisationid bigint not null,
   pu_classyear int not null
);

create table person_company (
   pc_personid bigint not null,
   pc_organisationid bigint not null,
   pc_workfrom int not null
);

create table place (
   pl_placeid bigint not null,
   pl_name varchar not null,
   pl_url varchar not null,
   pl_type varchar not null,
   pl_containerplaceid bigint -- null for continents
);

create table country (
    ctry_city bigint not null,
    ctry_name varchar not null
);

create table message (
    m_messageid bigint not null,
    m_ps_imagefile varchar,
    m_creationdate timestamp with time zone not null,
    m_locationip varchar not null,
    m_browserused varchar not null,
    m_ps_language varchar,
    m_content text,
    m_length int not null,
    m_creatorid bigint not null,
    m_locationid bigint not null,
    m_ps_forumid bigint,
    m_c_replyof bigint
);

create table message_tag (
   mt_messageid bigint not null,
   mt_tagid bigint not null
);

create table tagclass (
   tc_tagclassid bigint not null,
   tc_name varchar not null,
   tc_url varchar not null,
   tc_subclassoftagclassid bigint -- null for the root tagclass (Thing)
);

create table tag (
   t_tagid bigint not null,
   t_name varchar not null,
   t_url varchar not null,
   t_tagclassid bigint not null
);
```

### LLM

To extend your original query with the additional requirement of returning the full name and like creation time of the first foreign person who liked each message, you can use Common Table Expressions (CTEs) to structure your query. Here's how you can modify your query:

```sql
WITH known_people AS (
    SELECT
        k_person1id AS personid,
        k_person2id AS known_personid
    FROM
        public.knows
    UNION
    SELECT
        authorknows.k_person1id AS personid,
        friendknows.k_person2id AS known_personid
    FROM
        public.knows AS authorknows
    JOIN
        public.knows AS friendknows ON friendknows.k_person1id = authorknows.k_person2id
),
message_likes AS (
    SELECT
        m.m_messageid,
        m.m_creatorid,
        COUNT(l.l_personid) AS total_likes,
        COUNT(CASE WHEN kp.known_personid IS NULL THEN 1 END) AS foreign_likes
    FROM
        public.message m
    JOIN
        public.likes l ON l.l_messageid = m.m_messageid
    LEFT JOIN
        known_people kp ON kp.personid = m.m_creatorid AND kp.known_personid = l.l_personid
    WHERE
        m.m_length > 100
    GROUP BY
        m.m_messageid,
        m.m_creatorid
    HAVING
        COUNT(l.l_personid) >= 20 AND
        COUNT(CASE WHEN kp.known_personid IS NULL THEN 1 END)::float / COUNT(l.l_personid) >= 0.5
),
first_foreign_liker AS (
    SELECT
        l.l_messageid,
        l.l_personid,
        l.l_creationdate,
        ROW_NUMBER() OVER (PARTITION BY l.l_messageid ORDER BY l.l_creationdate) AS rn
    FROM
        public.likes l
    JOIN
        message_likes ml ON ml.m_messageid = l.l_messageid
    LEFT JOIN
        known_people kp ON kp.personid = ml.m_creatorid AND kp.known_personid = l.l_personid
    WHERE
        kp.known_personid IS NULL
)
SELECT
    ml.m_messageid AS message,
    ml.total_likes,
    ml.foreign_likes,
    p.p_firstname || ' ' || p.p_lastname AS first_foreign_liker_name,
    ffl.l_creationdate AS first_foreign_like_time
FROM
    message_likes ml
JOIN
    first_foreign_liker ffl ON ffl.l_messageid = ml.m_messageid AND ffl.rn = 1
JOIN
    public.person p ON p.p_personid = ffl.l_personid
ORDER BY
    (ml.foreign_likes::float / ml.total_likes) DESC;
```

**Explanation:**

1. **`known_people` CTE**: This CTE compiles a list of all people known to each person, including their direct friends and friends of friends.
2. **`message_likes` CTE**: This CTE filters messages longer than 100 characters and calculates the total likes and foreign likes for each message, applying the specified conditions.
3. **`first_foreign_liker` CTE**: This CTE identifies the first foreign liker for each message by ordering the likes based on the creation date and selecting those likers who are not known to the message creator.
4. **Final `SELECT` Statement**: Joins the above CTEs to fetch the required information, including the full name of the first foreign liker and the time when they created the like, and sorts the results as specified.

This query efficiently incorporates the additional requirement while maintaining the original functionality.
