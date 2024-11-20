# Reflections Mini Project 1

## Task 2

Steps for the manual extension of the queries:

- adding relevant bits of data into subqueries of tables that are already queried
- looking at what information/tables still need to be incorporated
- joining different tables into the existing query
- reiterating until the query looks like the example output

In contrast, using the LLM was straight forward:

- copying schema, old query task, query to expand and the new query task into ChatGPT
- comparing output to example solution
- understanding SQL query and query task to point out misunderstandings from the query task
- (reiteratively pointing out errors until the result is correct)

Solving the task via an LLM was much simpler. It required less knowledge about SQL and less upfront research. The necessary concepts in the LLM solution were directly explained by the LLM or could be asked within the context.  
Using the LLM was also much faster. The manual development took 1-2 hours, while using the LLM was a matter of a few minutes at max (under 5).
For the extension of our manually developed query, ChatGPT'S solution worked on the first try, while the extension of their own solution needed one more prompt due to an obvious error.  
In terms of efficiency the LLM extension and our own extension of the manually developed query perform roughly at the same speed. However, the LLM query extended by the LLM is 60% faster than these two solutions, while the manual extension of the manual query is by far the slowest performing query. This might be due to the fact that while extending the manually developed query took quite some time, when extending the LLM query we used the same method used for the first extension rather than figuring out a way to extend it specifically for the LLM query making the solution less specialized and therefore less efficient.  
This time the LLM task needed (nearly) no further input from us and the where it needed it might be also solvable without understanding the code but just pointing out discrepancies in the output. The specific error the LLM made was not giving the names of the foreign people commenting by the first timestamp but rather alphabetically which was quickly fixed by pointing it out (we also mentioned the line of code responsible for this but it seems to also work by just pointing out the discrepancy without understanding the code). Since this approach produced efficient and correct queries in faster time, integrating it holistically in query development seems reasonable. Query development goes through several phases such as initial development/theorising of a query, refining it until it produces adequate outcomes, optimizing it and extending it to further task. In all of these steps an LLM might be consulted and after human adjustments move into the next step. And this cycle could then continue until the human is content with the results or decides to intervene with their own expertise in a more involved way.