# Reflection on Task 1

## How much knowledge was required?

For developing a solution myself, I had to have a lot of knowledge. I had to
know SQL and set logic. It took me about two hours to create my solution that I
finally came up with. This could not have been done by unexperienced persons.

However, finding a solution with ChatGPT was quite convenient. I uploaded the
`schema.sql` and added the request from the PDF. Adding a sentence that I need
an SQL statement to solve the request was sufficient to get a solution. 

In the end, it was far easier finding a solution with an AI.

## How good are the results?

The performance of my own solution was much faster (30s vs. 90s) compared to
the ChatGPT solution. However, that might simply do not play a role depending
on the specific use case. Also, fine-tuning might have lead to similar results.

## Readability

My own implementation was not as readable as the solution of ChatGPT. ChatGPT
gave a well-formatted, easy-to-read query that anybody would understand. My
implementation is really hard to understand. Therefore, my implementation would
need further work on readability.

## Correctness

Both solutions seemed to result in the correct solutions, but ChatGPT spotted
the sorting requirement. I did not spot it, as after working for two hours, I
simply overread it, as my head was about to explode. When looking at ChatGPTs
results, it just got back to my head. So, in this rare case, ChatGPT was more
correct.

# Reflection on Task 2

## Process of Iterative Development

Adding a further feature to the script was a high effort. I had to get back
into the code and think about more. I tried having more JOINS, but that would
have decreased performance by a lot. After about an hour of work, I figured out
how to do it by hand, but the code become much more complex. With each new
feature, it would become more complex to add stuff.

On the other hand, updating the ChatGPT-written code was very simple. I just
"told" ChatGPT the new specification and five minutes later it was implemented
and up and running. However, the ChatGPT implementation is still much slower.
Overall, the process was far easier using the LLM.
