-- Populate forum table
COPY forum FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/forum_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate forum_person table
COPY forum_person FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/forum_hasMember_person_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate forum_tag table
COPY forum_tag FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/forum_hasTag_tag_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate organisation table
COPY organisation FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/static/organisation_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate person table
COPY person FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/person_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate person_email table
COPY person_email FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/person_email_emailaddress_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate person_tag table
COPY person_tag FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/person_hasInterest_tag_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate knows table
COPY knows ( k_person1id, k_person2id, k_creationdate) FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/person_knows_person_0_0.csv' WITH DELIMITER '|' CSV HEADER;
COPY knows ( k_person2id, k_person1id, k_creationdate) FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/person_knows_person_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate likes table
COPY likes FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/person_likes_post_0_0.csv' WITH DELIMITER '|' CSV HEADER;
COPY likes FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/person_likes_comment_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate person_language table
COPY person_language FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/person_speaks_language_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate person_university table
COPY person_university FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/person_studyAt_organisation_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate person_company table
COPY person_company FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/person_workAt_organisation_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate place table
COPY place FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/static/place_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate message_tag table
COPY message_tag FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/post_hasTag_tag_0_0.csv' WITH DELIMITER '|' CSV HEADER;
COPY message_tag FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/comment_hasTag_tag_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate tagclass table
COPY tagclass FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/static/tagclass_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate tag table
COPY tag FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/static/tag_0_0.csv' WITH DELIMITER '|' CSV HEADER;

CREATE TABLE country AS
    SELECT city.pl_placeid AS ctry_city, ctry.pl_name AS ctry_name
    FROM place city, place ctry
    WHERE city.pl_containerplaceid = ctry.pl_placeid
      AND ctry.pl_type = 'country';

-- Populate posts and comments tables, union them into message
COPY post FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/post_0_0.csv' WITH DELIMITER '|' CSV HEADER;
COPY comment FROM '/app/sql/social_network-sf0.1-CsvMergeForeign-StringDateFormatter/dynamic/comment_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Note: to distinguish between "post" and "comment" records:
--   - m_c_replyof IS NULL for all "post" records
--   - m_c_replyof IS NOT NULL for all "comment" records
CREATE TABLE message AS
    SELECT m_messageid, m_ps_imagefile, m_creationdate, m_locationip, m_browserused, m_ps_language, m_content, m_length, m_creatorid, m_locationid, m_ps_forumid, NULL AS m_c_replyof
    FROM post
    UNION ALL
    SELECT m_messageid, NULL, m_creationdate, m_locationip, m_browserused, NULL, m_content, m_length, m_creatorid, m_locationid, NULl, coalesce(m_replyof_post, m_replyof_comment)
    FROM comment;

DROP TABLE post;
DROP TABLE comment;
