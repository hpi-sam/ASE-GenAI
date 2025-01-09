# Task 3: Query Execution
Link to visualization [here](https://explain.dalibo.com/plan/c5298f95ga5g2b9b)

```
Sort  (cost=778408.19..778408.20 rows=4 width=72)
   Sort Key: ((((sum(CASE WHEN (kr_1.known_person_id IS NULL) THEN 1 ELSE 0 END)))::double precision / ((count(l_1.l_messageid)))::double precision)) DESC
   CTE knownrelationships
     ->  Unique  (cost=311642.62..321942.58 rows=1373328 width=16)
           ->  Sort  (cost=311642.62..315075.94 rows=1373328 width=16)
                 Sort Key: k1.k_person1id, k2.k_person2id
                 ->  Append  (cost=113579.99..148166.02 rows=1373328 width=16)
                       ->  HashAggregate  (cost=113579.99..140669.04 rows=1370513 width=16)
                             Group Key: k1.k_person1id, k2.k_person2id
                             Planned Partitions: 32
                             ->  Merge Left Join  (cost=5083.08..25781.50 rows=1370513 width=16)
                                   Merge Cond: (k1.k_person2id = k2.k_person1id)
                                   ->  Sort  (cost=2541.54..2611.90 rows=28146 width=16)
                                         Sort Key: k1.k_person2id
                                         ->  Seq Scan on knows k1  (cost=0.00..461.46 rows=28146 width=16)
                                   ->  Sort  (cost=2541.54..2611.90 rows=28146 width=16)
                                         Sort Key: k2.k_person1id
                                         ->  Seq Scan on knows k2  (cost=0.00..461.46 rows=28146 width=16)
                       ->  HashAggregate  (cost=602.19..630.34 rows=2815 width=16)
                             Group Key: k1_1.k_person1id, k1_1.k_person2id
                             ->  Seq Scan on knows k1_1  (cost=0.00..461.46 rows=28146 width=16)
   ->  Hash Join  (cost=456418.75..456465.57 rows=4 width=72)
         Hash Cond: (p.p_personid = fl.liker_id)
         ->  Seq Scan on person p  (cost=0.00..35.28 rows=1528 width=20)
         ->  Hash  (cost=456418.70..456418.70 rows=4 width=40)
               ->  Merge Join  (cost=453564.59..456418.70 rows=4 width=40)
                     Merge Cond: (fl.m_messageid = m_1.m_messageid)
                     ->  Subquery Scan on fl  (cost=240240.05..242907.65 rows=410 width=24)
                           Filter: (fl.rn = 1)
                           ->  WindowAgg  (cost=240240.05..241881.65 rows=82080 width=32)
                                 Run Condition: (row_number() OVER (?) <= 1)
                                 ->  Sort  (cost=240240.05..240445.25 rows=82080 width=24)
                                       Sort Key: m.m_messageid, l.l_creationdate
                                       ->  Merge Anti Join  (cost=221621.61..233540.37 rows=82080 width=24)
                                             Merge Cond: ((m.m_creatorid = kr.person_id) AND (l.l_personid = kr.known_person_id))
                                             ->  Sort  (cost=30678.45..30952.05 rows=109440 width=32)
                                                   Sort Key: m.m_creatorid, l.l_personid
                                                   ->  Hash Join  (cost=12908.74..18896.94 rows=109440 width=32)
                                                         Hash Cond: (l.l_messageid = m.m_messageid)
                                                         ->  Seq Scan on likes l  (cost=0.00..1798.40 rows=109440 width=24)
                                                         ->  Hash  (cost=7923.44..7923.44 rows=286744 width=16)
                                                               ->  Seq Scan on message m  (cost=0.00..7923.44 rows=286744 width=16)
                                             ->  Sort  (cost=190943.16..194376.48 rows=1373328 width=16)
                                                   Sort Key: kr.person_id, kr.known_person_id
                                                   ->  CTE Scan on knownrelationships kr  (cost=0.00..27466.56 rows=1373328 width=16)
                     ->  GroupAggregate  (cost=213324.54..213508.13 rows=742 width=24)
                           Group Key: m_1.m_messageid
                           Filter: ((count(l_1.l_messageid) >= 20) AND (sum(CASE WHEN (kr_1.known_person_id IS NULL) THEN 1 ELSE 0 END) >= (count(l_1.l_messageid) / 2)))
                           ->  Sort  (cost=213324.54..213341.23 rows=6676 width=24)
                                 Sort Key: m_1.m_messageid
                                 ->  Merge Right Join  (cost=202501.75..212900.46 rows=6676 width=24)
                                       Merge Cond: ((kr_1.person_id = m_1.m_creatorid) AND (kr_1.known_person_id = l_1.l_personid))
                                       ->  Sort  (cost=190943.16..194376.48 rows=1373328 width=16)
                                             Sort Key: kr_1.person_id, kr_1.known_person_id
                                             ->  CTE Scan on knownrelationships kr_1  (cost=0.00..27466.56 rows=1373328 width=16)
                                       ->  Sort  (cost=11558.58..11575.27 rows=6676 width=32)
                                             Sort Key: m_1.m_creatorid, l_1.l_personid
                                             ->  Hash Join  (cost=8858.94..11134.50 rows=6676 width=32)
                                                   Hash Cond: (l_1.l_messageid = m_1.m_messageid)
                                                   ->  Seq Scan on likes l_1  (cost=0.00..1798.40 rows=109440 width=16)
                                                   ->  Hash  (cost=8640.30..8640.30 rows=17491 width=16)
                                                         ->  Seq Scan on message m_1  (cost=0.00..8640.30 rows=17491 width=16)
                                                               Filter: (m_length > 100)
 JIT:
   Functions: 87
   Options: Inlining true, Optimization true, Expressions true, Deforming true
(66 rows)
```
We used the `EXPLAIN` command to get the execution plan of the query from Task 2.1.
The execution plan shows the steps the database takes to execute the query.
The query is quite complex and involves multiple subqueries and joins.
We can first see that the CTE known relationships is used to find the friends of friends with an estimated cost of 311642.62.
This is done at the beginning as the result is used in multiple places.
When looking at the dalibo visualization we can see, that the most expensive operations (e.g. Sort) are often done in the beginning or directly following a join.
Overall it can be seen that many of the steps are reordered and are not executed in the order they are written in the query.