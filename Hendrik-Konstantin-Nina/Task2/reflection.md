# Reflection Task 1

## Task 2.1

### Steps

- First tried to use the query from Task 1.1 and modify it to get the correct result.
- We first did not look at the results from task 1.2 as these we solve by another team member.
- This resulted in a very complex query that was not working and hard to understand.
- We then looked at the results from task 1.2 and saw that the concept of the WITH clause was used to break down the query into smaller parts.
- We then used this concept to break down the query from 1.1 into smaller parts and build it up step by step.
- Then we modified the query as described in the task description to get the correct result.
- The only more difficult part was to add the row number to each foreign Like over the creation date.

### Time & Difficulty

- It took overall about 2,5 hours to get the correct query.
- We first tried for about 45 minutes to modify the query from task 1.1, without looking at the results from task 1.2.
- It was very difficult, and it became cleat that even an experienced SQL developer would probably task multiple hours to get the correct query.
- After looking at the results from task 1.2 it was much easier to get the correct query.
- We spent around 1 hour to refactor the query from task 1.1 into smaller parts using the WITH clause.
- After this it took about 45 minutes to get the correct query.

## Task 2.2

- Again, usage of Copilot Chat with the Claude 3.5 Sonnet (Preview) model

### Steps

- Have the create_tables.sql file (specification of which tables are in the database) and the query_1-2.sql file (query from previous task) open
- Copy the new query/task description description from the PDF
- Set context (Short comment that query needs to be extended)
- Review the LLM response

### Time & Difficulty

- Time to get the correct query: ~2 minutes
- Time to understand/review the LLM response and check correctness: ~2 minutes
- Again, very easy task

### Interaction with the LLM

- Quality of LLM response was very good
  - Again, precise description of intent
  - Made plan on how to change the query
  - Clean code
  - Summarized main code changes to the query
- Explanation of the query was precise, easy to understand
- Had to prompt only once to get the correct query (no misunderstandings)

### Iterative Query Development Process

- Using the LLM to generate initial query drafts based on task descriptions
- Iteratively refining the query with the LLM's assistance
- Breaking down complex queries into manageable parts
- Continuously reviewing and validating the LLM's output to ensure accuracy and correctness
- Let the LLM explain and document query changes
- Can significantly reduce development time and can improve the quality of the final query (if supervised correctly)
- Integration into IDE's for faster interaction time, streamline process (Copilot Chat / Copilot Edits)
  - Allows for more complex/broader tasks and changes (e.g. add table xxx with columns yyy and include in query zzz)
