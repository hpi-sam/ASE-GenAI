# Reflection ASE - Mini Project 1

Cedric Lorenz, Leonard Dreessen, Oliver Hess, and Raphael Reimann

# Overall SQL query experience

Experience-wise our team mostly relies on having visited basic database lectures (DBS1 and DBS2) during the bachelors, as well as Big Data Systems during the masters.

Regarding, query development some of us also got some experience working with ORM (object relational mapper) frameworks, which essentially hide manual query development in day-to-day development.

# Task 1 - Query Development

## Manual

Manual development started with analyzing the given schema in regards to the requested analytical query.
Progress was made by implementing smaller subparts and iteratively testing them on the database in order to observe their results and runtime.
For faster feedback on subresults, we sometimes used "LIMIT 1" or count statements to get a feeling whether we are on the right track.

When combining the individual parts of the overall query, the postgres query parser was quite helpful.
At first, we included a subquery in the from-statement that accessed columns from the outer query context.
That is not something that works right out of the box, so the query parser suggested to use the "LATERAL" keyword ("to reference that column, you must mark this subquery with LATERAL").

Overall, manually developing the initial query was quite complex and consisted of a lot of small implement-and-test cycles which increased time-consuption.
Also, if a small step made wasn't resulting in the expected output, motivation for continuing the development decreased.

Execution results were equivalent to the published ground truth, but for comparing the overall quality of the written query we do not really have clear metrics.
Readability is highly subjective, but one could evaluate the number of joins and compare it to other solutions.
In retrospect, maybe one could have used some index-information for evaluating if accessing specific columns (and joining on them) is maybe faster than on other columns.

## LLM

Generating the query with an LLM was different than manually writing it. We provided the task description and the schema information as additional context to the LLM. Prompt engineering was minimal here but experience on how to write prompts and to work with LLMs is important and cannot be neglected. We then ran the resulting queries directly against the database to see if the generated SQL code was syntactically correct. We basically checked the result first as a sanity check and then started to understand the query in detail, which is very much different from manually creating the query.

One minor adjustment was to follow up to the LLM and prompt it to create a optimized version of the query since the original query took a lot of time to run. Other than that, no adjustments to the query were needed.

Generating the query was a lot more time efficient since understanding a complex query was easier than coming up with the query on our own. However, since we started from an existing solution, we also felt that this approach might be more error prone because it is tempting to forget about edge cases.

This approach is semi-automatic automation, since the output and the queries had to be manually checked by us.

# Task 2 - Query Extension

## Manually extending the manual developed query

Again, for manually extending the query, having a look on the needed schema parts was necessary.
Also, the query parser helped us by indicating missing group-by fields for example.

We solved the extension by naively including more subqueries for querying the requested information.

Comparing the difficulty with the initial, manual development, extending was much simpler because we had to iterate through very few implement-and-test cycles.

## Extending the manually developed query with LLM

To extend the manually developed query, we provided the original task, the current manual query, the additional extension requirement, and the schema of the database to the LLM.

The LLM generated extension was quick and correct. The resulting query was easier to understand, working with common table expression concepts and structured formatting.

Again, we had to check the output more thoroughly but the process of extending the query was simpler than doing it manually.

## Extending the LLM query

Extending the LLM-generated query with an LLM was even easier since we could just give the extension requirement to the LLM as a follow-up prompt to the original generated message. This is enabled by ChatGPT.com and not LLMs in general but it made the development experience even easier. Again, we had to check the output more thoroughly but the process of extending the query was simpler than doing it manually.

In general, this approach already enabled fast iteration but there was still context-switching needed between generating the query and executing it (which we did locally from VSCode). Ideally the context is preserved in a single place that enables access to the database to iterate on the queries and its results and access to the LLM.

# Task 3 - Execution Plans

In comparison to the results of the LLM for tasks 1-2 it is more challenging for the LLM to come up with an accurate result here. The LLM clearly states that it made an approximation because of missing details about the DBMS like data about like data distribution and indexes. As a result it leaves all cost estimations per operation out. Moreover, the whole execution plan varies a lot compared to the database result. 

The LLM offers broad explanations of the main steps it identified for the execution plan, however it is barely comprehensible due to the following reasons: 1) Since the query itself is very complex, even the PostgreSQL output is hard to understand without visualization. 2) The LLM seems to struggle to correctly emulate PostgreSQL's output leading to a result which is not parsable for tools as explain.dalibo.com . The missing DBMS details may contribute partially to such a result. Albeit, to correctly mimic outputs with a measurement character seems to be way harder for broadly trained LLMs like ChatGPT.
