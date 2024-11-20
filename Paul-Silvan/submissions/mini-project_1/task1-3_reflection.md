# Reflections Mini Project 1

## Task 1

The team has a solid experience of writing SQL queries, but does not write them frequently. Simple concepts like `GROUP BY` and `ORDER BY` were known by heart, concepts like sub queries have been used before and could easily be recalled into memory with external sources. Common Table Expressions were known, but not well understood.

There were many more steps needed to develop the query manually, like

- understanding the query task in detail
- getting known to the schema, with focus on the relevant tables
- dividing the issue into smaller issues appropriate for handling in SQL
- implementing sub issues in separate/growing SQL statements 
  - using reference material to look up concepts again
- linking and refining individual SQL queries into one
- comparing own solution with example
- reiteratively adapting query to find and fix errors

In contrast, using the LLM was straight forward:

- copying schema and query task into ChatGPT
- comparing output to example solution
- understanding SQL query and query task to point out misunderstandings from the query task
- reiteratively pointing out errors until the result is correct

Solving the task via an LLM was much simpler. It required less knowledge about SQL and less upfront research. The necessary concepts in the LLM solution were directly explained by the LLM or could be asked within the context.  
Using the LLM was also much faster. The manual development took multiple hours, while using the LLM was a matter of minutes, maybe 15-30mins. This might be skewed by already having gained a very good understanding of the task and schema after having it solved manually, yet the time saving would be significant. The is due to the manual development being from scratch, by hand, without any automation. Moreover, the excellent quality of the initial and first refined LLM solution. In total, I made 5 prompts to the LLM, with only 3 of them actually giving instructions to how to change the SQL query in order to make it correct.  
The LLM also produced the more efficient query. On the given data set, the LLM query was maybe four times as fast, compared to the manual query.  
Development with the LLM still required us to understand the SQL query in order to specifically point out errors that happened due to misunderstandings of the task.