# Miniproject 1 Reflection

## Initial Query Development (Task 1)

Our team started with low to medium of SQL experience, which provided an interesting baseline for comparing manual versus LLM-assisted query development.

Our manual development process followed these steps:
1. Started with basic query components
2. Gradually increased complexity through nesting
3. Iteratively tested and improved the query
4. Generated a query with an LLM
5. Analyzed both approaches and their results, got some inspiration from the LLM query to improve the manual query

Key findings:
- The LLM-generated query demonstrated superior performance (approximately 10x faster)
- LLM produced correct results on first attempt with proper schema context and plain copy of task description
- The LLM solution showed better code readability

## Query Extension (Task 2)

When extending the queries for additional requirements:
- LLM-generated code proved more maintainable and adaptable
- Manual query performance degraded significantly (>5 minute execution time)
- Iterative LLM prompting emerged as the most effective development strategy
- LLM provided better assistance than traditional documentation for SQL optimization questions

We personally prefer the chat interaction with the LLM for query development, as it allows for iterative improvement of the query as well as fast and comprehensive explanations. This experience suggests that LLM-assisted query development can significantly improve both development efficiency and query performance. 