# Reflection Task 1

## Prior Knowledge
* 2 team members only with basic SQL knowledge who did not use this knowledge for multiple years
* 1 team member intermediate SQL knowledge. While many of the concepts were known the member had no experience with complex queries.

## Task 1.1

### Steps
- First create query without foreign like count. This was easy and only took a few minutes.
- Then add foreign like count

### Time & Difficulty
- First we did not notice that the foreign like count includes friends of friends.
- It took a long time to get the idea with the SQL Case expression to get the foreign like count. This was the most difficult part.
- We also made a lot of mistakes until we got the correct join for the foreign like count.
- Further we forgot to cast the sum the foreign like count to float to get the correct ratio.
- Difficult task (took about 2 hours)

## Task 1.2

- Usage of Copilot Chat with the Claude 3.5 Sonnet (Preview) model because:
  - Easy to give context through code/files
  - Claude yields better and faster results (from my experience)

#### Steps

- Open the create_tables.sql file (specification of which tables are in the database)
- Copy the query/task description description from the PDF
- Set the reference file and the query description into context (one short sentence)
- Review the LLM response

#### Time & Difficulty

- Time to get the correct query: <1 minute
- Time to understand/review the LLM response and check correctness: 10-20 minutes
- Very easy task

#### Interaction with the LLM

- Quality of LLM response was very good
  - Precise description of intent and resulting query
  - Clean code
- Explanation of the query was precise, easy to understand
- Had to prompt only once to get the correct query (no misunderstandings)
